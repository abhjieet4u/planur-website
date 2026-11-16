#!/usr/bin/env bash
# =============================================================================
# Planur website — assemble the publishable folder
# -----------------------------------------------------------------------------
#   ./tools/build_site.sh                    → dist/          (the LIVE site)
#   FLAVOUR=staging ./tools/build_site.sh    → dist-staging/  (the staging copy,
#                                               marked noindex)
#
# Output: dist/  — drag the CONTENTS of THIS folder into Netlify. Never drag
# site/ on its own again.
#
# 🔴 FOR A DEPLOY, RUN tools/build_all.sh INSTEAD (2026-11-04). This script
# assembles whatever app bundles are lying in the shared build folders and does
# not check which database they talk to — so after a staging build it will
# happily assemble a live dist/ pointed at staging. build_all.sh builds staging
# first and prod LAST, and verifies each assembly against the right project.
#
# WHY THIS EXISTS
# Two Flutter apps are served from the same domain — the tutor app at
# /tutors/app/ and the student read-only app at /app/. Netlify's drag-and-drop
# deploy REPLACES the whole site, so dragging site/ by itself would silently
# delete both and every tutor would get a 404 on login. This script builds one
# folder containing all three, so there is only ever one thing to drag.
#
# The apps are built separately, from the planur-app repo:
#     cd ../planur-app/tutor_app && ./tools/build_web.sh staging /tutors/app/
#     cd ../planur-app            && ./tools/build_web.sh staging /app/
# The --base-href MUST match the folder or the app loads a blank page from the
# wrong asset paths. This script checks both and refuses to assemble otherwise.
#
# The student app is OPTIONAL: set SKIP_STUDENT=1 to assemble without it. The
# tutor app is not — tutors are already using it.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
TUTOR_BUILD="${TUTOR_BUILD:-../planur-app/tutor_app/build/web}"
STUDENT_BUILD="${STUDENT_BUILD:-../planur-app/build/web}"

# ── Two sites, two folders ──────────────────────────────────────────────────
# FLAVOUR=staging assembles the STAGING site into dist-staging/ and marks the
# whole thing noindex. Anything else assembles the live site into dist/ as
# before, so every existing instruction still works unchanged.
#
# 🔴 WHY A SEPARATE FOLDER AND NOT A REBUILD EACH TIME: both sites are deployed
# by dragging a folder. One folder for both means the second drag ships whatever
# the first build left behind, and Netlify reports success either way — which is
# precisely how four deploys in a row shipped the same stale bundle on
# 2026-09-08. Two folders cannot be confused with each other.
FLAVOUR="${FLAVOUR:-prod}"
if [[ "$FLAVOUR" == "staging" ]]; then
  DIST="dist-staging"
else
  DIST="dist"
fi

# 🔴 A drifted page must not be deployable. Every page shares its favicon links,
# its statutory footer line and the ?v= cache stamp; `sync_partials.py --check`
# proves they are all in step before anything is assembled. Deploys are a
# metered, finite resource here — spending one on a site where a single page
# still points at last month's logo is the failure this prevents.
#
# When building from a worktree (SITE_OVERRIDE), the check runs against the
# worktree's copy — cd there so ROOT resolves to it.
if [[ -n "${SITE_OVERRIDE:-}" ]]; then
  echo "▸ Checking shared blocks (from worktree)"
  ( cd "$SITE_OVERRIDE" && python3 tools/sync_partials.py --check ) || {
    echo
    echo "✗ Refusing to assemble. The merged branch has drifted partials."
    exit 1
  }
else
  echo "▸ Checking shared blocks"
  python3 tools/sync_partials.py --check || {
    echo
    echo "✗ Refusing to assemble. Run tools/sync_partials.py and rebuild."
    exit 1
  }
fi

# SITE_OVERRIDE lets build_all.sh point at a worktree's site/ for prod builds,
# so the static pages come from the merged branch, not the working tree.
SITE_SRC="${SITE_OVERRIDE:+${SITE_OVERRIDE}/site}"
SITE_SRC="${SITE_SRC:-site}"
if [[ ! -d "$SITE_SRC" ]]; then
  echo "✗ Site source not found: $SITE_SRC"
  exit 1
fi

echo "▸ Assembling $DIST (from ${SITE_SRC})"
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$SITE_SRC/." "$DIST"/

if [[ ! -d "$TUTOR_BUILD" ]]; then
  echo
  echo "✗ No tutor web build at $TUTOR_BUILD"
  echo "  Build it first:"
  echo "      cd ../planur-app/tutor_app && ./tools/build_web.sh /tutors/app/"
  echo
  echo "  Refusing to assemble a dist/ without it — publishing that would take"
  echo "  the tutor login offline."
  exit 1
fi

# The base href is the difference between a working app and a blank page.
if ! grep -q '<base href="/tutors/app/">' "$TUTOR_BUILD/index.html"; then
  echo
  echo "✗ $TUTOR_BUILD was not built for /tutors/app/"
  grep -o '<base href="[^"]*">' "$TUTOR_BUILD/index.html" | sed 's/^/    found: /'
  echo "  Rebuild:  cd ../planur-app/tutor_app && ./tools/build_web.sh /tutors/app/"
  exit 1
fi

# Without this the app dies during plugin registration — see the file's header.
if ! grep -q 'passkeys-stub.js' "$TUTOR_BUILD/index.html"; then
  echo "✗ passkeys-stub.js missing from the tutor build — the app would not boot." >&2
  exit 1
fi

mkdir -p "$DIST/tutors/app"
cp -R "$TUTOR_BUILD/." "$DIST/tutors/app"/

# Netlify only reads _redirects and _headers from the PUBLISH ROOT. The copies
# inside the app build are inert there, and leaving them invites someone to edit
# the wrong file. The equivalent rules live in site/_headers.
rm -f "$DIST/tutors/app/_redirects" "$DIST/tutors/app/_headers"

# ── Student web app (read-only) ─────────────────────────────────────────────
STUDENT_LINE="    student web app →  (not included)"
if [[ "${STUDENT_ON_SUBDOMAIN:-0}" == "1" ]]; then
  # Lives on its own subdomain (build_app_site.sh); this site only redirects —
  # or, with no URL for this environment, leaves /app/ to the Coming soon page.
  echo "▸ Student web app is on its own subdomain — not embedded at /app/"
  STUDENT_LINE="    student web app →  ${STUDENT_SITE_URL:-(subdomain URL not set — /app/ shows Coming soon)}"
elif [[ "${SKIP_STUDENT:-0}" == "1" ]]; then
  echo "▸ Skipping the student web app (SKIP_STUDENT=1)"
elif [[ ! -d "$STUDENT_BUILD" ]]; then
  echo
  echo "✗ No student web build at $STUDENT_BUILD"
  echo "  Build it first:"
  echo "      cd ../planur-app && ./tools/build_web.sh staging /app/"
  echo "  Or assemble without it:  SKIP_STUDENT=1 ./tools/build_site.sh"
  exit 1
else
  if ! grep -q '<base href="/app/">' "$STUDENT_BUILD/index.html"; then
    echo
    echo "✗ $STUDENT_BUILD was not built for /app/"
    grep -o '<base href="[^"]*">' "$STUDENT_BUILD/index.html" | sed 's/^/    found: /'
    echo "  Rebuild:  cd ../planur-app && ./tools/build_web.sh staging /app/"
    exit 1
  fi
  if ! grep -q 'passkeys-stub.js' "$STUDENT_BUILD/index.html"; then
    echo "✗ passkeys-stub.js missing from the student build — it would not boot." >&2
    exit 1
  fi
  # A build made from lib/main.dart would compile and then die opening a Drift
  # database that cannot exist in a browser. The read-only notice is only in
  # the web entry point, so it is a cheap proof the right -t was used.
  if ! grep -rqs "read-only view" "$STUDENT_BUILD"/*.js; then
    echo "✗ $STUDENT_BUILD looks like a lib/main.dart build, not lib/main_web.dart." >&2
    echo "  Rebuild:  cd ../planur-app && ./tools/build_web.sh staging /app/" >&2
    exit 1
  fi
  mkdir -p "$DIST/app"
  cp -R "$STUDENT_BUILD/." "$DIST/app"/
  rm -f "$DIST/app/_redirects" "$DIST/app/_headers"
  STUDENT_LINE="    student web app →  $DIST/app/"
fi

# ── Apps on their own subdomain: this site only REDIRECTS to them ──────────
# parent.theplanur.co.uk (parent_app) and, once switched, student.theplanur.co.uk
# are separate Netlify sites assembled by build_app_site.sh. Pages here keep
# linking to the stable paths /parents/app/ and /app/; the redirect is written
# only when build_all.sh passes the subdomain's URL, i.e. once it is live.
# Until then /parents/app/ has no file and no rule, so Netlify serves 404.html —
# the "Coming soon" page with Contact us (owner, 2026-11-15) — never a dead
# hostname.
PARENT_LINE="    parent portal   →  /parents/app/ shows Coming soon (not live)"
if [[ -n "${PARENT_SITE_URL:-}" ]]; then
  printf '\n# Parent portal → its own subdomain (added by build_site.sh)\n/parents/app/*  %s:splat  301\n' \
    "${PARENT_SITE_URL%/}/" >> "$DIST/_redirects"
  PARENT_LINE="    parent portal   →  redirect /parents/app/* → $PARENT_SITE_URL"
fi
if [[ "${STUDENT_ON_SUBDOMAIN:-0}" == "1" ]]; then
  # Drop the SPA fallback for the embedded app (first match wins, so it would
  # swallow the redirect), then send /app/* to the subdomain.
  python3 - "$DIST/_redirects" <<'PY'
import re, sys
p = sys.argv[1]
lines = open(p).read().splitlines()
open(p, "w").write("\n".join(l for l in lines
                            if not re.match(r"^/app/\*\s+/app/index\.html\s+200", l)) + "\n")
PY
  if [[ -n "${STUDENT_SITE_URL:-}" ]]; then
    printf '\n# Student web app → its own subdomain (added by build_site.sh)\n/app/*  %s:splat  301\n' \
      "${STUDENT_SITE_URL%/}/" >> "$DIST/_redirects"
  fi
fi

# ── 🔴 The staging site must never be indexed ───────────────────────────────
# It is a BYTE-FOR-BYTE copy of the marketing pages on a second host. Left
# crawlable, it competes with the real site for its own search terms — two of
# our pages fighting over one query suppresses both, which is the same reason
# the third attendance article was dropped. The canonical tags already point at
# theplanur.co.uk, which helps, but noindex is what actually settles it.
#
# Netlify reads _headers only from the publish root, so writing it here is
# enough — and it is written AFTER site/ is copied, so it overwrites rather
# than merges.
if [[ "$FLAVOUR" == "staging" ]]; then
  printf '# Staging copy — not for search engines.\nUser-agent: *\nDisallow: /\n' \
    > "$DIST/robots.txt"
  cat >> "$DIST/_headers" <<'HDR'

# ── Staging build (FLAVOUR=staging) ─────────────────────────────────────────
# Added by tools/build_site.sh. A header, not just robots.txt: robots.txt asks
# a crawler not to FETCH a page, which leaves it able to list a URL it has
# merely heard about. X-Robots-Tag is the one that keeps it out of results.
/*
  X-Robots-Tag: noindex, nofollow
HDR
  # Android App Links: the live host claims the app. A staging copy claiming it
  # too would let staging URLs open the real installed app.
  rm -f "$DIST/assetlinks.json"
fi

echo
echo "✓ $DIST ready  ($(du -sh "$DIST" | cut -f1))"
echo "    marketing site  →  $DIST/"
echo "    tutor web app   →  $DIST/tutors/app/"
echo "$STUDENT_LINE"
echo "$PARENT_LINE"
echo
echo "  Drag the CONTENTS of $DIST into Netlify."
if [[ "$FLAVOUR" == "staging" ]]; then
  echo "  → the STAGING Netlify site, not the live one. This folder is marked"
  echo "    noindex and its apps talk to the STAGING database."
  echo "  Then check on the staging host: the pages load, /tutors/app/ shows the"
  echo "  tutor sign-in, and the amber STAGING banner is visible in the app."
else
  echo "  → the LIVE site. Then check: theplanur.co.uk loads, /tutors/app/ shows"
  echo "  the tutor sign-in, and /app/ shows the student sign-in."
fi
