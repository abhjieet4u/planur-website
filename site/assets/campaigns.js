/* ═══════════════════════════════════════════════════════════════════════════
   Seasonal offers — the campaign framework (owner, 2026-11-17)
   ═══════════════════════════════════════════════════════════════════════════
   One list below, one small engine after it. A campaign switches itself ON at
   `start` and OFF at `end`, in the visitor's browser, so nobody has to deploy
   or remember anything on the day. Outside every campaign the site is exactly
   as normal.

   TO ADD OR CHANGE AN OFFER
     1. Add or edit an entry in CAMPAIGNS (copy an existing one).
     2. Dates are UTC instants. The UK is on GMT (= UTC) from late October to
        late March, so "00:00Z" is UK midnight then; in summer subtract an hour.
        `end` is EXCLUSIVE: the first moment the offer is over.
     3. The code must already exist in Stripe and be valid for the whole window
        (check its expiry and redemption limit there). Checkout accepts codes;
        annual Payment Links do not, so say "monthly plan".
     4. Bump STAMP in tools/sync_partials.py and run it, so browsers fetch the
        new file. Deploy.
     5. Preview any campaign before its dates: add ?campaign=<theme> to any
        page (e.g. /tutors/pricing/?campaign=christmas). ?campaign=off hides
        whichever one is live. The preview is per page view only.

   RULES (house rules, see the Website Blueprint)
     - No prices in a banner. Name the offer, the code and the end date.
     - Tutor pages only: students, parents and legal pages never show an offer.
     - One campaign at a time; windows must not overlap.

   THEMES live in /assets/planur.css under html[data-campaign-theme="<theme>"]
   and apply only on the pages listed in `themeOn`. Add a new theme there.
   ═══════════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  // Pages that may show an offer banner (path prefixes; '/' alone = home).
  var TUTOR_PAGES = ['/', '/tutors/', '/help/', '/faq/', '/tools/', '/about/',
                     '/countries/', '/support/'];

  var CAMPAIGNS = [
    {
      id: 'blackfriday-2026',
      theme: 'blackfriday',
      start: '2026-11-23T00:00:00Z',   // Monday 23 November, UK midnight
      end:   '2026-12-01T00:00:00Z',   // over after Monday 30 November (Cyber Monday)
      label: 'Black Friday',
      message: '3 months free on any monthly plan',
      code: 'PLANURFREE3',
      note: 'New subscriptions only. Ends Monday 30 November.',
      cta: { text: 'See plans', href: '/tutors/pricing/' },
      bannerOn: TUTOR_PAGES,
      themeOn: ['/tutors/pricing/']
    },
    {
      id: 'christmas-2026',
      theme: 'christmas',
      start: '2026-12-15T00:00:00Z',   // Tuesday 15 December
      end:   '2027-01-05T00:00:00Z',   // three weeks: over after Monday 4 January
      label: 'Christmas offer',
      message: '3 months free on any monthly plan',
      code: 'PLANURFREE3',
      note: 'New subscriptions only. Ends 4 January.',
      cta: { text: 'See plans', href: '/tutors/pricing/' },
      bannerOn: TUTOR_PAGES,
      themeOn: ['/tutors/pricing/']
    }
  ];

  // ── Engine ──────────────────────────────────────────────────────────────
  function pathMatches(list, path) {
    for (var i = 0; i < list.length; i++) {
      var p = list[i];
      if (p === '/' ? path === '/' : path.indexOf(p) === 0) return true;
    }
    return false;
  }

  function pick() {
    var forced = null;
    try { forced = new URLSearchParams(location.search).get('campaign'); } catch (e) {}
    if (forced === 'off') return null;
    if (forced) {
      for (var j = 0; j < CAMPAIGNS.length; j++) if (CAMPAIGNS[j].theme === forced) return CAMPAIGNS[j];
    }
    var now = Date.now();
    for (var i = 0; i < CAMPAIGNS.length; i++) {
      var c = CAMPAIGNS[i];
      if (now >= Date.parse(c.start) && now < Date.parse(c.end)) return c;
    }
    return null;
  }

  function dismissed(c) {
    try { return localStorage.getItem('planur-offer-closed') === c.id; } catch (e) { return false; }
  }
  function dismiss(c) {
    try { localStorage.setItem('planur-offer-closed', c.id); } catch (e) {}
  }

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text) n.textContent = text;
    return n;
  }

  function banner(c) {
    var bar = el('section', 'promo-bar');
    bar.setAttribute('aria-label', c.label + ' offer');
    var inner = el('div', 'promo-inner container');
    var copy = el('p', 'promo-text');
    copy.appendChild(el('strong', 'promo-label', c.label + ':'));
    copy.appendChild(document.createTextNode(' ' + c.message + ' with code '));
    var code = el('code', 'promo-code', c.code);
    copy.appendChild(code);
    copy.appendChild(document.createTextNode('. '));
    copy.appendChild(el('span', 'promo-note', c.note));
    inner.appendChild(copy);

    var actions = el('div', 'promo-actions');
    var btn = el('button', 'promo-copy', 'Copy code');
    btn.type = 'button';
    btn.addEventListener('click', function () {
      var done = function () { btn.textContent = 'Copied'; setTimeout(function () { btn.textContent = 'Copy code'; }, 2000); };
      var fallback = function () {
        var r = document.createRange(); r.selectNodeContents(code);
        var s = window.getSelection(); s.removeAllRanges(); s.addRange(r);
        btn.textContent = 'Press Ctrl+C';
      };
      try { navigator.clipboard.writeText(c.code).then(done, fallback); } catch (e) { fallback(); }
    });
    actions.appendChild(btn);
    if (c.cta && location.pathname.indexOf(c.cta.href) !== 0) {
      var a = el('a', 'promo-cta', c.cta.text + ' →');
      a.href = c.cta.href;
      actions.appendChild(a);
    }
    var close = el('button', 'promo-close', '×');
    close.type = 'button';
    close.setAttribute('aria-label', 'Hide this offer');
    close.addEventListener('click', function () { dismiss(c); bar.remove(); });
    actions.appendChild(close);
    inner.appendChild(actions);
    bar.appendChild(inner);
    return bar;
  }

  function run() {
    var c = pick();
    if (!c) return;
    var path = location.pathname;
    var root = document.documentElement;
    root.setAttribute('data-campaign', c.id);
    if (pathMatches(c.themeOn || [], path)) root.setAttribute('data-campaign-theme', c.theme);
    if (pathMatches(c.bannerOn || [], path) && !dismissed(c)) {
      var b = banner(c);
      b.classList.add('promo-' + c.theme);
      // After the skip link, so keyboard users still reach it first.
      var skip = document.querySelector('.skip-link');
      document.body.insertBefore(b, skip ? skip.nextSibling : document.body.firstChild);
    }
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
  else run();
})();
