"""Derive every brand asset from the master logo.

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
square(glyph, 192).save(OUT + 'planur-mark.png')
square(glyph, 192).save(OUT + 'planur-favicon-192.png')
square(glyph, 512).save(OUT + 'planur-favicon-512.png')
# iOS composites this on an opaque tile, so it keeps a white ground.
square(glyph, 180, pad=0.14, white=True).convert('RGB').save(OUT + 'planur-apple-touch-icon.png')

# 🔴 32px is the P ALONE. The full mark at 32px is mush: the rising line and
# star push the P down to about 14px and the figure inside it disappears. A tab
# icon nobody can read is not an updated tab icon. Larger sizes keep the whole
# mark, which is ordinary responsive-favicon practice.
p = glyph.crop((0, 0, 152, glyph.height))
square(p.crop(p.getbbox()), 32, pad=0.06).save(OUT + 'planur-favicon-32.png')

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

print('written to', OUT)
