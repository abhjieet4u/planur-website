#!/usr/bin/env bash
# =============================================================================
# Planur — build BOTH sites in the one safe order: staging first, prod LAST
# -----------------------------------------------------------------------------
#   ./tools/build_all.sh            → dist-staging/ then dist/   (the normal run)
#   ./tools/build_all.sh staging    → dist-staging/ only
#   ./tools/build_all.sh prod       → dist/ only (rebuilds both apps for prod)
#   ./tools/build_all.sh verify     → builds NOTHING; checks the existing
#                                     dist-staging/ and dist/ point where they say
#
#   SKIP_STUDENT=1 ./tools/build_all.sh       → leave the student web app out
#   PARENT_LIVE=1 ./tools/build_all.sh        → parent portal live on PROD
#   STUDENT_SUBDOMAIN=1 ./tools/build_all.sh  → student app moves to its subdomain
#
# ── WHERE EACH APP LIVES (owner, 2026-11-16) ───────────────────────────────
#   theplanur.co.uk            marketing site + staff app at /tutors/app/
#   parent.theplanur.co.uk     parent portal   → dist-parent/   (own Netlify site)
#   student.theplanur.co.uk    student web app → dist-student/  (own Netlify site,
#                              once STUDENT_SUBDOMAIN=1; until then it stays
#                              embedded at theplanur.co.uk/app/ exactly as before)
# Subdomains are split by WHO SIGNS IN, not provider type: a nursery's or a
# school's parents use parent., their students student., staff the staff app.
#
# The main site keeps linking to /parents/app/ and /app/; build_site.sh adds the
# redirect to a subdomain only when it is live, so a link never lands on a
# hostname that does not exist yet — it lands on the not-found page (404.html) instead.
#
# 🔴 PARENT_LIVE=1 only once migrations 179–182 have run on prod. Staging always
# gets the parent site. For the STAGING main site to redirect to the staging
# subdomain sites, export PARENT_STAGING_URL / STUDENT_STAGING_URL (their
# *.netlify.app hosts); unset, staging's /parents/app/ shows Coming soon.
#
# Then: drag dist-staging/ to the STAGING Netlify site, check it, and only then
# drag dist/ to the LIVE one. Full flow: ../planur-app/docs/tutor-web-deploy.md
#
# 🔴 BOTH BUILDS USE THE MERGED BRANCH, NOT THE WORKING TREE
# The static site pages (site/) are checked out from origin/main into a
# temporary git worktree — for BOTH staging and prod. This guarantees the
# same code is tested on staging and deployed to prod, and prevents
# uncommitted or unmerged work from another session silently shipping.
# Workflow: commit → merge to main → push → build staging → test → build
# prod → deploy.
# The Flutter app builds (tutor_app, student app) always run from the current
# tree — they live in planur-app, not this repo, and are verified by project
# ref after assembly.
#
# 🔴 WHY THE ORDER IS FIXED, AND WHY THIS SCRIPT EXISTS
# Both environments build into the SAME folders — planur-app/tutor_app/build/web
# and planur-app/build/web — and build_site.sh assembles whatever is in them. It
# checks the base href and the passkeys stub, but NOT which database a bundle
# talks to. So "build prod, then build staging, then assemble prod" quietly
# ships a live site pointed at the staging database, and nothing complains.
# Found on 2026-11-02 and dodged by checksumming by hand. Building prod LAST
# means the shared folders always end on prod, and every assembly below is
# verified against the project ref it should — and must not — contain.
#
# The refs are read from the gitignored config/<env>.json files, never typed
# here, so this script cannot drift from the configuration the builds use.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
SITE_DIR="$(pwd)"
APP_DIR="$(cd ../planur-app && pwd)"
TUTOR_DIR="$APP_DIR/tutor_app"

MODE="${1:-all}"
case "$MODE" in
  all|staging|prod|verify) ;;
  *)
    echo "Usage: ./tools/build_all.sh [all|staging|prod|verify]"
    exit 1
    ;;
esac

# ── Project refs, from the configs the builds actually use ─────────────────
ref_of() {
  python3 - "$1" <<'PY'
import json, sys, urllib.parse
url = json.load(open(sys.argv[1])).get("SUPABASE_URL", "")
host = urllib.parse.urlparse(url).hostname or ""
print(host.split(".")[0])
PY
}

for f in "$TUTOR_DIR/config/staging.json" "$TUTOR_DIR/config/prod.json"; do
  [[ -f "$f" ]] || { echo "✗ Missing $f"; exit 1; }
done
STAGING_REF="$(ref_of "$TUTOR_DIR/config/staging.json")"
PROD_REF="$(ref_of "$TUTOR_DIR/config/prod.json")"

if [[ -z "$STAGING_REF" || -z "$PROD_REF" ]]; then
  echo "✗ Could not read a project ref from tutor_app/config/*.json"
  exit 1
fi
if [[ "$STAGING_REF" == "$PROD_REF" ]]; then
  echo "✗ staging.json and prod.json name the SAME project ($PROD_REF)."
  echo "  Refusing — one of them is wrong, and building both would hide it."
  exit 1
fi

# The student app has its own configs; they must agree with the tutor ones,
# or the two apps on one site would talk to different databases.
for env in staging prod; do
  sf="$APP_DIR/config/$env.json"
  if [[ "${SKIP_STUDENT:-0}" != "1" && -f "$sf" ]]; then
    want=$([[ $env == prod ]] && echo "$PROD_REF" || echo "$STAGING_REF")
    got="$(ref_of "$sf")"
    if [[ "$got" != "$want" ]]; then
      echo "✗ config/$env.json (student) points at $got, tutor points at $want."
      exit 1
    fi
  fi
done

# ── The check that build_site.sh does not make ─────────────────────────────
# Only the APP bundles are checked. The marketing site's planur.js names both
# refs on purpose — it picks one by host at run time — so it is not evidence.
verify_dist() {
  # verify_dist <dist> <want-ref> <forbid-ref> <label> <app dir under dist>...
  local dist="$1" want="$2" forbid="$3" label="$4" ok=1
  shift 4
  echo "▸ Verifying $dist ($label)"
  for app in "$@"; do
    local dir="$SITE_DIR/$dist/$app"
    if [[ ! -d "$dir" ]]; then
      echo "  ✗ $dist/$app is missing"; ok=0; continue
    fi
    # `|| true`: grep exits 1 on NO match — which for $forbid is the passing
    # case — and under `set -euo pipefail` that killed the whole run, silently,
    # right after "Verifying". `verify` mode never showed it because there the
    # call sits in `|| rc=1`, which switches errexit off (found 2026-11-04).
    local bad good
    bad=$( { grep -rhoE "$forbid" "$dir" --include='*.js' 2>/dev/null || true; } | wc -l | tr -d ' ')
    good=$( { grep -rhoE "$want" "$dir" --include='*.js' 2>/dev/null || true; } | wc -l | tr -d ' ')
    if [[ "$bad" != "0" ]]; then
      echo "  ✗ $dist/$app contains $bad reference(s) to the WRONG project ($forbid)"
      ok=0
    elif [[ "$good" == "0" ]]; then
      echo "  ✗ $dist/$app contains no reference to $want — not a $label build"
      ok=0
    else
      echo "  ✓ $dist/$app → $label only"
    fi
  done
  [[ $ok == 1 ]] || { echo "✗ $dist FAILED verification — do NOT deploy it."; return 1; }
}

# The app folders the MAIN site must carry for this environment.
main_site_apps() {
  echo "tutors/app"
  if [[ "${SKIP_STUDENT:-0}" != "1" && "${STUDENT_SUBDOMAIN:-0}" != "1" ]]; then echo "app"; fi
}

# 1 when this environment's site should carry the parent portal.
include_parent() {
  if [[ "$1" == "staging" || "${PARENT_LIVE:-0}" == "1" ]]; then echo 1; else echo 0; fi
}

student_on_subdomain() { [[ "${SKIP_STUDENT:-0}" != "1" && "${STUDENT_SUBDOMAIN:-0}" == "1" ]]; }

# The subdomain URL the MAIN site should redirect to, or empty (no redirect).
parent_url() {
  if [[ "$(include_parent "$1")" != "1" ]]; then echo ""; return; fi
  if [[ "$1" == "prod" ]]; then echo "https://parent.theplanur.co.uk/"; else echo "${PARENT_STAGING_URL:-}"; fi
}
student_url() {
  if ! student_on_subdomain; then echo ""; return; fi
  if [[ "$1" == "prod" ]]; then echo "https://student.theplanur.co.uk/"; else echo "${STUDENT_STAGING_URL:-}"; fi
}

# Folder suffix: dist-parent-staging/ vs dist-parent/.
sfx() { [[ "$1" == "staging" ]] && echo "-staging" || echo ""; }

build_apps() {
  local env="$1"
  echo
  echo "════ Building the web apps for $env ════"
  ( cd "$TUTOR_DIR" && ./tools/build_web.sh "$env" /tutors/app/ )

  if [[ "${SKIP_STUDENT:-0}" != "1" ]]; then
    if student_on_subdomain; then
      ( cd "$APP_DIR" && ./tools/build_web.sh "$env" / )
      ./tools/build_app_site.sh "$APP_DIR/build/web" "dist-student$(sfx "$env")" "$env" "read-only view"
    else
      ( cd "$APP_DIR" && ./tools/build_web.sh "$env" /app/ )
    fi
  fi

  if [[ "$(include_parent "$env")" == "1" ]]; then
    ( cd "$APP_DIR/parent_app" && ./tools/build_web.sh "$env" / )
    ./tools/build_app_site.sh "$APP_DIR/parent_app/build/web" "dist-parent$(sfx "$env")" "$env" "Planur for Parents"
  else
    echo "▸ Parent portal left out of $env (set PARENT_LIVE=1 once 179–182 are on prod)"
  fi
}

# Verify every folder this environment produced.
verify_env() {
  local env="$1" want="$2" forbid="$3" rc=0
  # shellcheck disable=SC2046
  verify_dist "dist$(sfx "$env")" "$want" "$forbid" "$env" $(main_site_apps) || rc=1
  if [[ "$(include_parent "$env")" == "1" ]]; then
    verify_dist "dist-parent$(sfx "$env")" "$want" "$forbid" "$env" . || rc=1
  fi
  if student_on_subdomain; then
    verify_dist "dist-student$(sfx "$env")" "$want" "$forbid" "$env" . || rc=1
  fi
  return $rc
}

# 🔴 Both staging and prod build the static site from the MERGED main branch,
# never the working tree. This guarantees the same code is tested on staging
# and deployed to prod, and prevents uncommitted work from shipping silently.
# The Flutter app builds still run from the current tree (they live in
# planur-app, not this repo, and are verified by project ref after assembly).
MAIN_BRANCH="main"

# Sets SITE_WORKTREE to the temp worktree path. Caller must clean up.
setup_site_worktree() {
  local label="$1"
  SITE_WORKTREE="$(mktemp -d "${TMPDIR:-/tmp}/planur-${label}-site.XXXXXX")"

  echo
  echo "▸ $label site: checking out $MAIN_BRANCH into temp worktree"

  git fetch origin "$MAIN_BRANCH" --quiet 2>/dev/null || true

  git worktree add --quiet "$SITE_WORKTREE" "origin/$MAIN_BRANCH" 2>/dev/null || {
    echo "✗ Could not create worktree from origin/$MAIN_BRANCH."
    echo "  Merge your changes to $MAIN_BRANCH and push before building."
    rm -rf "$SITE_WORKTREE"
    exit 1
  }

  local wt_head
  wt_head="$(git -C "$SITE_WORKTREE" log --oneline -1)"
  echo "  Building from: $wt_head"
}

cleanup_site_worktree() {
  git worktree remove --force "$SITE_WORKTREE" 2>/dev/null || rm -rf "$SITE_WORKTREE"
}

build_staging() {
  setup_site_worktree staging
  build_apps staging
  PARENT_SITE_URL="$(parent_url staging)" STUDENT_SITE_URL="$(student_url staging)" \
    STUDENT_ON_SUBDOMAIN="$(student_on_subdomain && echo 1 || echo 0)" \
    FLAVOUR=staging SITE_OVERRIDE="$SITE_WORKTREE" ./tools/build_site.sh
  cleanup_site_worktree
  verify_env staging "$STAGING_REF" "$PROD_REF"
}

build_prod() {
  setup_site_worktree prod
  build_apps prod
  PARENT_SITE_URL="$(parent_url prod)" STUDENT_SITE_URL="$(student_url prod)" \
    STUDENT_ON_SUBDOMAIN="$(student_on_subdomain && echo 1 || echo 0)" \
    SITE_OVERRIDE="$SITE_WORKTREE" ./tools/build_site.sh
  cleanup_site_worktree
  verify_env prod "$PROD_REF" "$STAGING_REF"
}

case "$MODE" in
  verify)
    rc=0
    [[ -d dist-staging ]] && { verify_env staging "$STAGING_REF" "$PROD_REF" || rc=1; }
    [[ -d dist ]] && { verify_env prod "$PROD_REF" "$STAGING_REF" || rc=1; }
    exit $rc
    ;;
  staging) build_staging ;;
  prod)    build_prod ;;
  all)     build_staging; build_prod ;;
esac

echo
echo "✓ Done."
if [[ "$MODE" == "all" || "$MODE" == "staging" ]]; then
  echo "  1. STAGING — drag the CONTENTS of each folder into its own staging Netlify site:"
  echo "       dist-staging/          → staging main site"
  [[ -d dist-parent-staging ]]  && echo "       dist-parent-staging/   → staging parent site"
  [[ -d dist-student-staging ]] && student_on_subdomain && echo "       dist-student-staging/  → staging student site"
  echo "     Check each one before going further."
fi
if [[ "$MODE" == "all" || "$MODE" == "prod" ]]; then
  echo "  2. PROD — the subdomain sites FIRST, the main site LAST (its redirects point at them):"
  [[ "$(include_parent prod)" == "1" ]] && echo "       dist-parent/   → parent.theplanur.co.uk"
  student_on_subdomain && echo "       dist-student/  → student.theplanur.co.uk"
  echo "       dist/          → theplanur.co.uk"
fi
echo "  The app build folders now hold $([[ $MODE == staging ]] && echo STAGING || echo PROD) bundles."
