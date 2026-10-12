#!/usr/bin/env python3
"""Keep the blocks that every page shares actually identical.

    tools/sync_partials.py           rewrite the pages
    tools/sync_partials.py --check   fail if any page has drifted

── WHY THIS EXISTS, AND WHY IT IS NOT A TEMPLATE ENGINE ────────────────────
Every page under site/ is a standalone HTML file. That is deliberate: they can
be opened straight off disk, there is no build to run before you can look at
one, and `dist/` is the same plain files. The cost is duplication — adding one
footer line on 2026-10-11 touched EIGHT files, and stamping the brand images
touched FORTY-THREE urls by hand.

So this does not introduce placeholders the browser cannot render. It writes the
REAL content into the source files and can afterwards prove none of them has
drifted. Pages stay complete and previewable; the duplication becomes something
a machine maintains rather than something a person remembers.

🔴 THE NAV IS DELIBERATELY NOT HERE. /students links its logo to /students,
/tutors carries the "for tutors" lockup, and the legal pages use a bare mark.
They are three different navs for three different readers, and flattening them
into one partial would be worse markup justified by tidiness. Only what is
genuinely identical on every page belongs in `partials/`.

── THE STAMP ───────────────────────────────────────────────────────────────
`site/_headers` caches /assets/* for a YEAR, so replacing artwork under the same
filename changes nothing for a returning visitor unless the url changes with it.
Every reference carries `?v=<STAMP>`; this file is the one place that number
lives. Bump STAMP whenever a shared asset's CONTENT changes — css, js, or any
brand image — and re-run.
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

# 🔴 Bump on any change to planur.css, planur.js or a brand image.
STAMP = "20261012"

# Marked regions: name -> partial file. A page opts in by carrying the markers;
# a page without them is left alone, which is how /invite and the download
# landers keep their reduced chrome.
REGIONS = {
    "brand-icons":  ROOT / "partials" / "brand-icons.html",
    "footer-legal": ROOT / "partials" / "footer-legal.html",
}

STAMPED = re.compile(r'(/assets/[A-Za-z0-9._-]+\.(?:css|js|png|svg|jpg))\?v=[0-9A-Za-z._-]*')


def region_re(name: str) -> re.Pattern:
    return re.compile(
        rf"(<!-- planur:{name}:start -->\n)(.*?)(\s*<!-- planur:{name}:end -->)",
        re.S,
    )


def apply(text: str) -> str:
    for name, path in REGIONS.items():
        body = path.read_text().replace("__STAMP__", STAMP).rstrip("\n")
        text = region_re(name).sub(lambda m: m.group(1) + body + m.group(3), text)
    # Every stamped asset url, inside a region or not — the nav logo is not in a
    # partial but still must bust.
    text = STAMPED.sub(rf"\1?v={STAMP}", text)
    return text


def main() -> int:
    check = "--check" in sys.argv
    pages = sorted(ROOT.glob("site/**/*.html"))
    drifted, written = [], []
    for p in pages:
        before = p.read_text()
        after = apply(before)
        if before == after:
            continue
        (drifted if check else written).append(p.relative_to(ROOT))
        if not check:
            p.write_text(after)

    if check:
        if drifted:
            print("✗ pages have drifted from partials/ or carry a stale stamp:")
            for d in drifted:
                print("   ", d)
            print("\n  run tools/sync_partials.py to fix")
            return 1
        print(f"✓ {len(pages)} pages in step with partials/ (stamp {STAMP})")
        return 0

    print(f"stamp {STAMP} · {len(pages)} pages scanned · {len(written)} rewritten")
    for w in written:
        print("   ", w)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
