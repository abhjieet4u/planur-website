# planur-website

Public marketing + legal/support website for **Planur**, served at
**[theplanur.co.uk](https://theplanur.co.uk)**.

Plain static HTML — **no build step, no framework, no external network requests**
(fonts are self-hosted; there is no analytics, no tracking, no CDN). Every page is a
single self-contained `.html` file.

## Structure

```
site/                     ← web root (deploy the CONTENTS of this folder)
├── index.html            Home / marketing page
├── privacy/index.html    Privacy Policy   → /privacy
├── terms/index.html      Terms of Service → /terms
├── delete-account/…      Account-deletion instructions → /delete-account
├── invite/index.html     Friend-invite landing / store redirect → /invite
├── download/index.html   App-download landing / store redirect → /download
└── fonts/                Self-hosted DM Sans (.woff2)
```

Each folder resolves to a clean URL via its `index.html` (e.g. `site/terms/index.html`
→ `https://theplanur.co.uk/terms`).

### The app links to these pages
The Planur app opens `/privacy` and `/terms` from Settings → About, and shares
`/invite?ref=…` and `/download?ref=…` links. Keep these paths stable — renaming a folder
breaks live links already shipped in the app.

## Local preview

No tooling required — serve the `site/` folder with any static server:

```bash
cd site
python3 -m http.server 8080     # then open http://localhost:8080
```

## Deploy

The site is host-agnostic. Publish the **contents of `site/`** as the web root on any
static host (Cloudflare Pages, Netlify, Vercel, GitHub Pages, S3 + CloudFront, etc.):

- **Publish / output directory:** `site`
- **Build command:** none (static)
- **Custom domain:** `theplanur.co.uk` (point DNS at the host; enable HTTPS)

Because pages live in subfolders with `index.html`, "clean URLs" work out of the box on
any host that serves `folder/` → `folder/index.html`.

## Pre-launch TODO

- **`/invite` and `/download`** redirect Android → Google Play now, but iOS is gated on a
  `{{APPSTORE_ID}}` placeholder in both files — fill the numeric Apple App Store ID once the
  iOS listing is live (the iOS redirect then auto-enables). The Play listing must also be
  **public** (not just internal testing) for either redirect to resolve.
- **Legal review:** `privacy` and `terms` are drafted for global reach (UK/EU, US, India,
  APAC, and worldwide) but are **not legal advice** — have them reviewed per market before
  public launch, especially India (DPDP under-18 parental consent) and US (COPPA). Each file
  has an HTML comment at the top listing items to confirm.
- If HTTPS **app deep links** (open the app instead of the web page) are wanted later, add
  `/.well-known/assetlinks.json` (Android, needs the app's SHA-256 signing fingerprint) and
  `apple-app-site-association` (iOS), and matching in-app routes.
