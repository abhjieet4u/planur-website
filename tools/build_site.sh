#!/usr/bin/env bash
# =============================================================================
# Planur website — assemble the publishable folder
# -----------------------------------------------------------------------------
#   ./tools/build_site.sh
#
# Output: dist/  — drag the CONTENTS of THIS folder into Netlify. Never drag
# site/ on its own again.
#
# WHY THIS EXISTS
# The tutor web app is served from the same domain, at /tutors/app/. Netlify's
# drag-and-drop deploy REPLACES the whole site, so dragging site/ by itself
# would silently delete the tutor app and every tutor would get a 404 on login.
# This script builds one folder containing both, so there is only ever one thing
# to drag.
#
# The tutor app is built separately, from the planur-app repo:
#     cd ../planur-app/tutor_app && ./tools/build_web.sh /tutors/app/
# The --base-href MUST be /tutors/app/ or the app loads a blank page from the
# wrong asset paths. This script checks that and refuses to assemble otherwise.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
TUTOR_BUILD="${TUTOR_BUILD:-../planur-app/tutor_app/build/web}"
DIST="dist"

echo "▸ Assembling $DIST"
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R site/. "$DIST"/

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

echo
echo "✓ $DIST ready  ($(du -sh "$DIST" | cut -f1))"
echo "    marketing site  →  $DIST/"
echo "    tutor web app   →  $DIST/tutors/app/"
echo
echo "  Drag the CONTENTS of $DIST into Netlify."
echo "  Then check: theplanur.co.uk loads, and /tutors/app/ shows the sign-in screen."
