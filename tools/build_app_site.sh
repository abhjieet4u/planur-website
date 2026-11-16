#!/usr/bin/env bash
# =============================================================================
# Planur — assemble ONE web app as its own site, for its own subdomain
# -----------------------------------------------------------------------------
#   tools/build_app_site.sh <app-build-dir> <out-dir> <staging|prod> <title-marker>
#
#   e.g. tools/build_app_site.sh ../planur-app/parent_app/build/web dist-parent prod "Planur for Parents"
#
# Used by build_all.sh for the apps that live on their own subdomain:
#     parent.theplanur.co.uk   ← planur-app/parent_app
#     student.theplanur.co.uk  ← planur-app (lib/main_web.dart)   [once switched]
# The marketing site and the staff app stay on theplanur.co.uk (build_site.sh).
#
# Subdomains are split by WHO SIGNS IN, never by provider type: a nursery's or a
# school's parents use parent., their students student., and their staff the
# staff app (/tutors/app/ today). Do not add school./nursery. sites.
#
# Each output folder is dragged into ITS OWN Netlify site. Netlify replaces a
# whole site on every drag, which is exactly why each app gets its own folder.
# =============================================================================
set -euo pipefail

BUILD="${1:?app build dir}"
OUT="${2:?output dir}"
FLAVOUR="${3:?staging|prod}"
MARKER="${4:?title marker}"

cd "$(dirname "$0")/.."

if [[ ! -d "$BUILD" ]]; then
  echo "✗ No build at $BUILD" >&2
  exit 1
fi
if ! grep -q '<base href="/">' "$BUILD/index.html"; then
  echo "✗ $BUILD was not built for a domain root (base href must be /)." >&2
  grep -o '<base href="[^"]*">' "$BUILD/index.html" | sed 's/^/    found: /' >&2
  exit 1
fi
if ! grep -q 'passkeys-stub.js' "$BUILD/index.html"; then
  echo "✗ passkeys-stub.js missing from $BUILD — the app would not boot." >&2
  exit 1
fi
if ! grep -q "$MARKER" "$BUILD/index.html" "$BUILD"/*.js 2>/dev/null; then
  echo "✗ $BUILD does not look like the expected app (no \"$MARKER\")." >&2
  exit 1
fi

echo "▸ Assembling $OUT ($FLAVOUR)"
rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$BUILD/." "$OUT"/

# Single-page app: every path is the app. Netlify serves real files first, so
# this never shadows main.dart.js or the assets.
printf '/*  /index.html  200\n' > "$OUT/_redirects"

# The same rules site/_headers gives /tutors/app/ and /app/: Flutter does not
# fingerprint these three files, and a cached index.html can point at JS chunks
# that no longer exist — which reads as a broken app, not an old one. And an
# application is not a page to be found in search, on staging or prod.
cat > "$OUT/_headers" <<'HDR'
/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  X-Frame-Options: SAMEORIGIN
  X-Robots-Tag: noindex, nofollow

/index.html
  Cache-Control: no-cache
/flutter_bootstrap.js
  Cache-Control: no-cache
/flutter_service_worker.js
  Cache-Control: no-cache
HDR

if [[ "$FLAVOUR" == "staging" ]]; then
  printf 'User-agent: *\nDisallow: /\n' > "$OUT/robots.txt"
fi

echo "✓ $OUT ready  ($(du -sh "$OUT" | cut -f1))"
