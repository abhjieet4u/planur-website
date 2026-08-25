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

# ── Student web app (read-only) ─────────────────────────────────────────────
STUDENT_LINE="    student web app →  (not included)"
if [[ "${SKIP_STUDENT:-0}" == "1" ]]; then
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

echo
echo "✓ $DIST ready  ($(du -sh "$DIST" | cut -f1))"
echo "    marketing site  →  $DIST/"
echo "    tutor web app   →  $DIST/tutors/app/"
echo "$STUDENT_LINE"
echo
echo "  Drag the CONTENTS of $DIST into Netlify."
echo "  Then check: theplanur.co.uk loads, /tutors/app/ shows the tutor sign-in,"
echo "  and /app/ shows the student sign-in."
