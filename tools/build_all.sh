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
#   SKIP_STUDENT=1 ./tools/build_all.sh   → leave the student web app out
#
# Then: drag dist-staging/ to the STAGING Netlify site, check it, and only then
# drag dist/ to the LIVE one. Full flow: ../planur-app/docs/tutor-web-deploy.md
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
  local dist="$1" want="$2" forbid="$3" label="$4" ok=1
  echo "▸ Verifying $dist ($label)"
  for app in tutors/app app; do
    local dir="$SITE_DIR/$dist/$app"
    if [[ ! -d "$dir" ]]; then
      if [[ "$app" == "app" && "${SKIP_STUDENT:-0}" == "1" ]]; then continue; fi
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

build_apps() {
  local env="$1"
  echo
  echo "════ Building both apps for $env ════"
  ( cd "$TUTOR_DIR" && ./tools/build_web.sh "$env" /tutors/app/ )
  if [[ "${SKIP_STUDENT:-0}" != "1" ]]; then
    ( cd "$APP_DIR" && ./tools/build_web.sh "$env" /app/ )
  fi
}

build_staging() {
  build_apps staging
  FLAVOUR=staging ./tools/build_site.sh
  verify_dist dist-staging "$STAGING_REF" "$PROD_REF" staging
}

build_prod() {
  # Prod is built from SCRATCH every time — never assembled from app folders
  # some earlier step may have left holding staging bundles.
  build_apps prod
  ./tools/build_site.sh
  verify_dist dist "$PROD_REF" "$STAGING_REF" prod
}

case "$MODE" in
  verify)
    rc=0
    [[ -d dist-staging ]] && { verify_dist dist-staging "$STAGING_REF" "$PROD_REF" staging || rc=1; }
    [[ -d dist ]] && { verify_dist dist "$PROD_REF" "$STAGING_REF" prod || rc=1; }
    exit $rc
    ;;
  staging) build_staging ;;
  prod)    build_prod ;;
  all)     build_staging; build_prod ;;
esac

echo
echo "✓ Done."
[[ "$MODE" == "all" || "$MODE" == "staging" ]] && \
  echo "  1. Drag the CONTENTS of dist-staging/ into the STAGING Netlify site and check it."
[[ "$MODE" == "all" || "$MODE" == "prod" ]] && \
  echo "  2. Then drag the CONTENTS of dist/ into the LIVE Netlify site."
echo "  The app build folders now hold $([[ $MODE == staging ]] && echo STAGING || echo PROD) bundles."
