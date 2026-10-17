"""Derive every brand asset from the master logo.

    PYTHONPATH=../planur-app/docs/sales/pylibs python3 tools/make_logo_assets.py \
        docs/brand/Planur-Logo_Oct2026.jpeg site/assets

⚠️ Pillow is NOT installed in the system python on this machine. It lives in
`../planur-app/docs/sales/pylibs` (vendored there for the deck build), so the
PYTHONPATH above is part of the command, not an optional nicety — without it
this fails on the import line and nothing is written.

🔴 After re-running: bump STAMP in tools/sync_partials.py and re-run that too,
or `_headers` caches the OLD artwork for a year and the deploy shows nothing.

🔴 Kept in the repo so the next logo arrives as a re-run rather than an
archaeology exercise. Source: docs/brand/Planur-Logo_Oct2026.jpeg.

Three facts about the source drive everything here:
  · it is a JPEG on PURE WHITE, so the background is removed by un-premultiply
    rather than by keying — compositing the result back over white reproduces
    the original pixel exactly, which keying does not;
  · the 'p' descender runs to y=597 while "FOR TUTORS" starts at y=589, so the
    two OVERLAP vertically. A horizontal cut either clips the descender or
    drags the tagline along; the wordmark is therefore cropped tall and the
    tagline's own column range erased;
  · the supplied lockup is STACKED (459x484). At a nav height of 40px that
    renders "FOR TUTORS" about 4px tall. The tutor lockup is re-set
    horizontally from the same elements so the tagline survives.
"""
import sys
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2].rstrip('/') + '/'

GLYPH = (544, 143, 938, 436)     # mark: P + figure + rising line + star
WORD  = (479, 455, 936, 599)     # "planur", cropped PAST the descender
TAG   = (574, 588, 880, 627)     # "FOR TUTORS", its own column range
TAG_X0, TAG_Y0 = 560, 588        # erase this corner out of WORD


def unmatte(img):
    """White ground -> alpha, un-premultiplied so colours stay true."""
    img = img.convert('RGB'); w, h = img.size
    out = Image.new('RGBA', (w, h)); sp, op = img.load(), out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = sp[x, y]
            a = 255 - min(r, g, b)
            if a <= 2:
                op[x, y] = (0, 0, 0, 0); continue
            f = a / 255.0; inv = (1 - f) * 255
            op[x, y] = (max(0, min(255, round((r - inv) / f))),
                        max(0, min(255, round((g - inv) / f))),
                        max(0, min(255, round((b - inv) / f))), a)
    return out


def square(img, size, pad=0.10, white=False):
    side = int(max(img.size) * (1 + 2 * pad))
    c = Image.new('RGBA', (side, side), (255, 255, 255, 255) if white else (0, 0, 0, 0))
    c.alpha_composite(img, ((side - img.width) // 2, (side - img.height) // 2))
    return c.resize((size, size), Image.LANCZOS)


im = Image.open(SRC).convert('RGB')
glyph = unmatte(im.crop(GLYPH))
word = unmatte(im.crop(WORD))
wp = word.load()
for y in range(TAG_Y0 - WORD[1], word.height):
    for x in range(TAG_X0 - WORD[0], word.width):
        wp[x, y] = (0, 0, 0, 0)
tag = unmatte(im.crop(TAG))

# ── The mark, and the tab icons ──────────────────────────────────────────
# 🔴 THE HEADER MARK IS TRANSPARENT; EVERY TAB ICON IS NOT. Found 2026-10-12:
# the mark's ink is dark navy, so a transparent favicon on a DARK tab strip —
# Chrome and Safari in dark mode, which is most people — left nothing visible
# at all. A browser paints the tab's own background behind a favicon and never
# a page colour, so the icon has to carry its own ground. The apple-touch icon
# already did, for the same reason on iOS.
#
# ⚠️ Do NOT "tidy" these onto the transparent path. planur-mark.png sits in the
# nav of a page whose own background is light or dark by theme, and THAT one
# must stay transparent or it renders as a white box in dark mode. The two
# cases genuinely differ: one composites over a page we control, the other over
# chrome we do not.
# 🔴 EVERY SQUARE SLOT IS THE P ALONE — owner, 2026-10-18, after comparing
# three crops: *"i liked the middle one as it was simple"*.
#
# The reasoning the 32px icon already carried, now applied consistently. The
# mark is 394x293, so `square()` sizes its canvas on the WIDTH — which the
# rising line sets, not the P. The P then fills a square it only reaches about
# 74% of, before padding. That is exactly the reported fault: *"the Aero going
# quite too far on the right making actual logo look very small"*.
#
# ⚠️ WE DID NOT SHORTEN THE LINE, and could not: the master is a JPEG with no
# vector source (docs/brand/Planur-Logo_Oct2026.jpeg), and pixel-editing an
# anti-aliased mark would look worse than leaving it. So the fix is to stop
# letting the line decide how big the P renders, which is the same outcome.
#
# 🔴 THE NAV MARK IS THE WORST CASE, not an afterthought: `.logo-mark` renders
# at 1.15em — roughly 18-20px, SMALLER than the 32px favicon this file already
# calls mush. It was still using the full wide mark.
#
# The line and star are not lost: they survive wherever there is width for
# them — the tutor lockup, planur-logo.svg and both OG cards below.
p = glyph.crop((0, 0, 152, glyph.height))
p = p.crop(p.getbbox())

square(p, 192).save(OUT + 'planur-mark.png')
square(p, 192, pad=0.10, white=True).convert('RGB').save(OUT + 'planur-favicon-192.png')
square(p, 512, pad=0.10, white=True).convert('RGB').save(OUT + 'planur-favicon-512.png')
# iOS composites this on an opaque tile, so it keeps a white ground.
square(p, 180, pad=0.10, white=True).convert('RGB').save(OUT + 'planur-apple-touch-icon.png')
square(p, 32, pad=0.06, white=True).convert('RGB').save(
    OUT + 'planur-favicon-32.png')

# ── The tutor lockup, re-set horizontally ────────────────────────────────
H = 160                                   # 4x its ~40px display height
g = glyph.resize((round(glyph.width * H / glyph.height), H), Image.LANCZOS)
wh = round(H * 0.52); wd = word.resize((round(word.width * wh / word.height), wh), Image.LANCZOS)
th = round(H * 0.115); tg = tag.resize((round(tag.width * th / tag.height), th), Image.LANCZOS)
gap = round(H * 0.13); lead = round(H * 0.05)
lock = Image.new('RGBA', (g.width + gap + max(wd.width, tg.width), H), (0, 0, 0, 0))
lock.alpha_composite(g, (0, 0))
top = (H - (wd.height + lead + tg.height)) // 2
lock.alpha_composite(wd, (g.width + gap, top))
lock.alpha_composite(tg, (g.width + gap, top + wd.height + lead))
lock.crop(lock.getbbox()).save(OUT + 'planur-lockup-tutors.png')

# ── The share card (og:image) ────────────────────────────────────────────
# 1200x630 is the size every platform crops from, and a page without one is
# shared as a bare grey rectangle. These /tools pages exist to BE shared — a
# calculator passed between teachers in a staffroom chat is the whole
# acquisition model — so the card is not decoration here.
#
# It carries the plain mark and wordmark, never "FOR TUTORS": one card serves
# every page, and the tutor lockup is reserved for the tutor page (owner,
# 2026-10-11). No strapline either, because the platforms draw the page title
# directly beneath the image and a second one reads as a stutter.
CARD_W, CARD_H = 1200, 630
card = Image.new('RGB', (CARD_W, CARD_H), (255, 255, 255))
ch = 150                                   # mark height on the card
cg = glyph.resize((round(glyph.width * ch / glyph.height), ch), Image.LANCZOS)
cwh = round(ch * 0.62)
cwd = word.resize((round(word.width * cwh / word.height), cwh), Image.LANCZOS)
cgap = round(ch * 0.16)
row_w = cg.width + cgap + cwd.width
x0 = (CARD_W - row_w) // 2
card.paste(cg, (x0, (CARD_H - cg.height) // 2), cg)
card.paste(cwd, (x0 + cg.width + cgap, (CARD_H - cwd.height) // 2), cwd)
card.save(OUT + 'planur-og-card.png')

# The tutor page gets the tagline lockup, and ONLY the tutor page — owner,
# 2026-10-11: "just keep the logo with Planur, and use Planur for Tutors only
# for tutor page." Same rule as the nav, applied to the share card.
lk = Image.open(OUT + 'planur-lockup-tutors.png')
tcard = Image.new('RGB', (CARD_W, CARD_H), (255, 255, 255))
th2 = 190
lk = lk.resize((round(lk.width * th2 / lk.height), th2), Image.LANCZOS)
tcard.paste(lk, ((CARD_W - lk.width) // 2, (CARD_H - lk.height) // 2), lk)
tcard.save(OUT + 'planur-og-card-tutors.png')

print('written to', OUT)
