# planur-website

Public portal for **Planur**, served at **[theplanur.co.uk](https://theplanur.co.uk)** — covering
both products: the **Planur student app** and **Planur for Tutors**.

Plain static HTML — **no build step, no framework, no external network requests** (fonts are
self-hosted; there is no analytics, no tracking, no CDN, no captcha). Every page is hand-written
HTML that loads one shared same-origin stylesheet and one shared script.

## Structure

```
site/                        ← web root (deploy the CONTENTS of this folder)
├── index.html               Student marketing home                     → /
├── tutors/index.html        Planur for Tutors product page             → /tutors
├── tutors/download/…        Tutor app store redirect                   → /tutors/download
├── download/index.html      Student app store redirect                 → /download
├── invite/index.html        Student friend-invite landing              → /invite
├── support/index.html       Support + contact form (both products)     → /support
├── privacy/index.html       Privacy Notice (both products)             → /privacy
├── terms/index.html         Terms of Service (both products)           → /terms
├── delete-account/…         Account & data deletion (both products)    → /delete-account
├── tutors/login/…           "Not available yet" holding page          → /tutors/login
├── 404.html                 Themed not-found page (Netlify serves it automatically)
├── assets/planur.css        Shared palette, type, nav, footer, forms
├── assets/planur.js         Shared nav, reveal, app selector, form helpers
├── fonts/                   Self-hosted DM Sans (.woff2)
├── _redirects               App Links rewrite + tidy per-app aliases
├── robots.txt, sitemap.xml
└── assetlinks.json          Android App Links (student app; tutor app pending)
```

### One document, two products

`/privacy`, `/terms`, `/delete-account` and `/support` each cover **both apps in a single page**,
with a Student / Tutor selector:

| | Student | Tutor |
|---|---|---|
| Privacy | `/privacy` | `/privacy?app=tutor` |
| Terms | `/terms` | `/terms?app=tutor` |
| Deletion | `/delete-account` | `/delete-account?app=tutor` |
| Support | `/support` | `/support?app=tutor` |

`_redirects` also maps the nested form (`/tutors/privacy` → `/privacy?app=tutor`), so either shape
works in a store listing.

**The selector only hides.** Both versions are always present in the HTML; JavaScript adds
`data-app` to `<html>` and CSS hides the other side. With JS off — which is how some store
reviewers and crawlers read a page — everything is visible and complete. **Never move legal
content into JavaScript.**

## Per-app links for store publishing

Each app listing gets its own URLs:

| Store field | Student (`app.planur.student`) | Tutor (`app.planur.tutor`) |
|---|---|---|
| Website | `/` | `/tutors` |
| Install / share | `/download?ref=…` | `/tutors/download?ref=…` |
| Privacy policy | `/privacy` | `/privacy?app=tutor` |
| Terms / EULA | `/terms` | `/terms?app=tutor` |
| Support | `/support` | `/support?app=tutor` |
| Data deletion (Play) | `/delete-account` | `/delete-account?app=tutor` |

### The app links to these pages
The Planur app opens `/privacy` and `/terms` from Settings → About, and shares `/invite?ref=…` and
`/download?ref=…`. **Keep these paths stable** — renaming a folder breaks links already shipped in
the app.

## House rules for content

- **No prices** on the tutor pages. Plan bands and limits only.
- **LIVE / TESTING / NEXT** tags stay honest and never blur together.
- **No invented users, counts, avatars or testimonials.** Our own testing is not social proof.
- **No launch dates.**
- **No time-saving figures at all.** The "~11½ hours a month" model, the task-by-task table and
  the "<1 min per paper" figure are **not validated**, so they stay off the public site — not in a
  stat strip, not in a heading, not as an aside (owner's decision, 2026-08-17). They still live in
  the sales deck and exec summary, which are presented in person with the assumptions stated.
- **`/tutors` stays slim.** No full feature list, no roadmap, no plan bands or caps. Features may
  still be dropped after tutor conversations, and announcing them publicly first makes that
  expensive. Keep it at the depth of the student home page; the exec summary carries the detail.
- **iPhone and Android launch together.** Never write "Android today" or "iOS later" — commercially
  they arrive at the same time.
- **Stroke SVG icons, not emoji**, on the tutor pages. One inline `<symbol>` sprite per page, no
  icon fonts, no external requests.

## Nav, and the one coupling to remember

One row, split by meaning:

```
Planur. │ For students  For tutors            Tutor log in   [ Talk to us ]
└──────── where am I ────────┘                └──── do a thing ────┘
```

The product tabs sit against the brand behind a divider — a product switcher, not a call to
action — and the actions sit at the far right. **Three different treatments** so nothing reads as a
sibling of anything else: tabs are plain text with the active one underlined, "Tutor log in" is a
quiet text link, and the primary CTA is **the only button in the bar**. That is what stops a
student clicking "For tutors" and then reaching for a tutor login.

Written per page, no JavaScript. Student pages show only *Join the waitlist*; the four
both-audience pages (privacy, terms, deletion, support) show the tabs with neither active and no
actions at all. Below 720px the tabs drop to their own line under the brand; below 420px the
"Tutor log in" link is hidden — it is in every footer.

⚠️ **The nav is sticky, so `planur.css` reserves space above anchor targets** — and there are two
rules, because getting this wrong is visible either way:

- `:target,[id]{scroll-margin-top:86px}` (132px under 720px) — the fallback, roughly the nav
  height, for any anchor with no padding of its own.
- `#talk,#what,#features,#waitlist{scroll-margin-top:10px}` (72px under 720px) — the real link
  targets. Every one is a full-width band already carrying **74–96px of its own top padding**, so
  reserving the nav height on top of that left about a line of dead space above the heading.
  Ids beat `[id]` on specificity, so these win. Landing gap measured 43–72px.

Measured nav height: **68px desktop, 116px once the tabs wrap**. If the nav's height changes, both
sets of values need revisiting.

## Interactions on /tutors

Two sections are progressive-enhancement interactive, deliberately using different mechanics:

- **"What it does"** — native `<details>` cards that expand on click. Works with JavaScript off,
  keyboard-operable for free, text always in the DOM for crawlers.
- **"The fair question"** — flip cards: CSS `:hover` on pointer devices, click/tap and
  `:focus-visible` everywhere else (the only JS involved is a class toggle). Both faces stay in the
  DOM; `prefers-reduced-motion` swaps the rotation for a cross-fade.
- `/tutors` is **not** a web copy of `docs/sales/exec-summary.html`. The exec summary is the
  detailed document, handed over in a conversation; the page is the short public introduction.
  A claim that appears on **both** must agree — but most of the exec summary does not belong here.

## Editing the shared assets — bump the version stamp

Every page loads `/assets/planur.css?v=YYYYMMDD` and `/assets/planur.js?v=YYYYMMDD`. **When you edit
either file, bump that stamp on every page**, or returning visitors keep the cached copy. The
failure is not a slightly-stale page: class names change with the design, so old CSS against new
markup collapses the nav into a stack of plain links.

```bash
cd site
grep -rl 'planur.css?v=' --include='*.html' . | xargs sed -i '' 's/?v=[0-9]\{8\}/?v=20260901/g'
```

`_headers` is the other half — HTML is `no-cache` so the current stamp always reaches the browser,
and `/assets/*` is cached hard because the stamp is what busts it.

## Store links are switched OFF

Both apps are on Play **internal testing** with iOS unsubmitted, so a store link 404s for anyone
who isn't a listed tester. All three store pages — `/download`, `/tutors/download`, `/invite` —
therefore show a themed **"Not available yet"** state instead, and **do not auto-redirect**.

The waiting state is the **static HTML**, so it is what a visitor sees with JavaScript off too. The
script only ever *upgrades* the page, and only when its switch is on:

```js
var STORES_LIVE = false;   // top of the <script> in each of the three pages
```

**To go live:** set `STORES_LIVE = true` in all three, and fill `{{APPSTORE_ID}}` /
`{{TUTOR_APPSTORE_ID}}`. The iOS button stays disabled until its ID is filled even when live — a
broken store link is worse than a button that waits. **iPhone and Android launch together, so don't
switch one on early.**

## Tutor browser sign-in — the switch waiting to be flipped

`tutor.theplanur.co.uk` has **no DNS record**, so linking to it gives a browser-level "server not
found" — a page we can't theme, explain or redirect. Every **"Tutor log in"** link therefore points
at **`/tutors/login`**, a holding page we control that says the browser version isn't switched on
yet and sends people to the app.

Because that page exists, the browser claims elsewhere are written as *coming*, not *available*:
the `/tutors` hero fact, the "Phone or laptop" card, and the `/support` FAQ.

**When the tutor web app is live, three things flip together:**

1. Uncomment in `site/_redirects`: `/tutors/login  https://tutor.theplanur.co.uk  302`
2. Restore the browser claims on `/tutors` and `/support`.
3. Update `planur-app/docs/tutor-web-deploy.md`.

Doing (1) without (2) leaves the site under-selling a feature that works; doing (2) without (1)
sends tutors to a dead host. They go together.

## Local preview

```bash
cd site
python3 -m http.server 8080     # then open http://localhost:8080
```

Worth checking after any change: every internal link, both states of the app selector
(`?app=tutor`), the page with JavaScript disabled, and widths 360 / 768 / 1280.

## Deploy

Host-agnostic. Publish the **contents of `site/`** as the web root on any static host:

- **Publish / output directory:** `site`
- **Build command:** none (static)
- **Custom domain:** `theplanur.co.uk`

`_redirects` is Netlify/Cloudflare-Pages syntax. On a host that ignores it, the aliases stop
working (the canonical `?app=` URLs still do), and `/.well-known/assetlinks.json` must be served
another way.

## Outstanding

- **`{{APPSTORE_ID}}`** in `/download` and `/invite`, and **`{{TUTOR_APPSTORE_ID}}`** in
  `/tutors/download` — fill the numeric Apple App Store IDs at iOS launch. Until then the iOS
  button says "coming soon" instead of linking somewhere broken.
- **`assetlinks.json` covers the student app only.** To add the tutor app, append a second
  statement with `app.planur.tutor` and its **release SHA-256 signing fingerprint**:

  ```json
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "app.planur.tutor",
      "sha256_cert_fingerprints": ["<TUTOR RELEASE SHA-256>"]
    }
  }
  ```

- **`apple-app-site-association`** is not present — needs the Apple Team ID and bundle IDs.
- **Open Graph images** — pages set `og:title`/`og:description` but no `og:image` yet.
- **Real screenshots** for both apps would replace the illustrated mockups on `/` and `/tutors`.
- **Browser access for tutors is claimed and linked** (`https://tutor.theplanur.co.uk`, in the nav,
  the hero, a feature card and every footer). It is only true once the tutor web build is deployed
  there — **deploy that and its DNS BEFORE this site**, or those links 404. See
  `planur-app/docs/tutor-web-deploy.md`.
- **Legal review** — `/privacy` and `/terms` are drafted for global reach but are **not legal
  advice**. Each file lists what to check in an HTML comment at the top; the tutor
  controller/processor split and the business-liability clauses are new and need a look.
