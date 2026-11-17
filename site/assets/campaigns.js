/* ═══════════════════════════════════════════════════════════════════════════
   Seasonal offers — the campaign framework (owner, 2026-11-17)
   ═══════════════════════════════════════════════════════════════════════════
   One list below, one small engine after it. A campaign switches itself ON at
   its start and OFF at its end, in the visitor's browser, so nobody has to
   deploy or remember anything on the day. Outside every campaign the site is
   exactly as normal.

   A campaign has two parts, and they end separately:
     · the SEASON — page theme and decorations (stars). Safe to repeat every
       year, so it can be `yearly`.
     · the OFFER — the banner with a code. It needs a code that is valid in
       Stripe, so it also stops at `offerUntil`. When a code lapses the season
       still shows, but no banner promises a discount that would be refused.

   TO ADD OR CHANGE AN OFFER
     1. Add or edit an entry in CAMPAIGNS (copy an existing one).
     2. Dates:
          start / end   one-off window, UTC instants. `end` is EXCLUSIVE.
          yearly        { start: 'MM-DD', end: 'MM-DD' } repeats every year,
                        UK midnight to UK midnight; `end` is EXCLUSIVE and may
                        fall in the next year (12-01 → 01-11).
        The UK is on GMT (= UTC) from late October to late March, so "00:00Z"
        is UK midnight then; in summer subtract an hour.
     3. `offerUntil`: the moment the code stops working in Stripe (check its
        expiry AND redemption limit there). Each year a yearly campaign needs a
        code renewed in Stripe and this date moved on, or the banner stays off.
        Checkout accepts codes; annual Payment Links do not, so say "monthly
        plan".
     4. Bump STAMP in tools/sync_partials.py and run it, so browsers fetch the
        new file. Deploy.
     5. Preview any campaign before its dates: add ?campaign=<theme> to any
        page (e.g. /tutors/pricing/?campaign=christmas). ?campaign=off hides
        whichever one is live and ends a preview. A preview lasts for that
        browser tab (sessionStorage), so you can click around; it shows the
        banner even when the code has lapsed.

   RULES (house rules, see the Website Blueprint)
     - No prices in a banner. Name the offer, the code and the end date.
     - Tutor pages only: students, parents and legal pages never show an offer.
     - One campaign at a time; windows must not overlap.
     - The banner stays on screen while the page scrolls, until the visitor
       closes it (owner, 2026-11-17). Closing is remembered per campaign.
     - SEO (owner, 2026-11-17): nothing here changes a page's HTML, title or
       headings. The banner is data-nosnippet, the stars are CSS-only and
       aria-hidden, and everything is placed before the first paint so the
       page does not shift. Keep it that way.

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
      offerUntil: '2026-12-01T00:00:00Z',
      label: 'Black Friday',
      message: '3 months free on any monthly plan',
      code: 'PLANURFREE3',
      note: 'New subscriptions only. Ends Monday 30 November.',
      cta: { text: 'See plans', href: '/tutors/pricing/' },
      bannerOn: TUTOR_PAGES,
      themeOn: ['/tutors/pricing/']
    },
    {
      // Every year, 1 December to 10 January (owner, 2026-11-17).
      id: 'christmas',
      theme: 'christmas',
      yearly: { start: '12-01', end: '01-11' },   // over after 10 January
      // PLANURFREE3 is valid to 31 January 2027 and has a redemption cap.
      // 🔴 Before December 2027: renew a code in Stripe, then move this on.
      offerUntil: '2027-02-01T00:00:00Z',
      label: 'Christmas offer',
      message: '3 months free on any monthly plan',
      code: 'PLANURFREE3',
      note: 'New subscriptions only. Ends 10 January.',
      cta: { text: 'See plans', href: '/tutors/pricing/' },
      bannerOn: TUTOR_PAGES,
      themeOn: ['/tutors/pricing/'],
      starsOn: ['/', '/tutors/', '/tutors/pricing/']   // exact pages
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
  function pathIs(list, path) {
    var clean = path.replace(/index\.html$/, '');
    for (var i = 0; i < list.length; i++) if (list[i] === clean) return true;
    return false;
  }

  // Is `now` inside the campaign's season?
  function inSeason(c, now) {
    if (c.yearly) {
      var d = new Date(now);
      var md = ('0' + (d.getUTCMonth() + 1)).slice(-2) + '-' + ('0' + d.getUTCDate()).slice(-2);
      var s = c.yearly.start, e = c.yearly.end;
      return s <= e ? (md >= s && md < e) : (md >= s || md < e);   // wraps the new year
    }
    return now >= Date.parse(c.start) && now < Date.parse(c.end);
  }

  function pick() {
    // A preview lasts for the browser tab, so you can click around the site;
    // it starts only from ?campaign=<theme> and ends at ?campaign=off or when
    // the tab closes.
    var forced = null;
    try { forced = new URLSearchParams(location.search).get('campaign'); } catch (e) {}
    try {
      if (forced) sessionStorage.setItem('planur-campaign-preview', forced);
      else forced = sessionStorage.getItem('planur-campaign-preview');
      if (forced === 'off') sessionStorage.removeItem('planur-campaign-preview');
    } catch (e) {}
    if (forced === 'off') return null;
    if (forced) {
      for (var j = 0; j < CAMPAIGNS.length; j++) {
        if (CAMPAIGNS[j].theme === forced) return { c: CAMPAIGNS[j], offer: true };
      }
    }
    var now = Date.now();
    for (var i = 0; i < CAMPAIGNS.length; i++) {
      var c = CAMPAIGNS[i];
      if (inSeason(c, now)) {
        return { c: c, offer: !c.offerUntil || now < Date.parse(c.offerUntil) };
      }
    }
    return null;
  }

  // A yearly campaign is closed per season, so last year's × doesn't hide it.
  function closeKey(c) {
    if (!c.yearly) return c.id;
    var d = new Date(), y = d.getUTCFullYear();
    if (d.getUTCMonth() < 6) y -= 1;   // January belongs to the season that began in December
    return c.id + '-' + y;
  }
  function dismissed(c) {
    try { return localStorage.getItem('planur-offer-closed') === closeKey(c); } catch (e) { return false; }
  }
  function dismiss(c) {
    try { localStorage.setItem('planur-offer-closed', closeKey(c)); } catch (e) {}
  }

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text) n.textContent = text;
    return n;
  }

  // The header sits below the banner while both stick to the top.
  function setBarHeight(px) {
    document.documentElement.style.setProperty('--promo-h', px + 'px');
  }

  function banner(c) {
    var bar = el('section', 'promo-bar');
    bar.setAttribute('aria-label', c.label + ' offer');
    // SEO: keep the offer out of search snippets; the page's own description
    // should describe the page, not a week-long promotion.
    bar.setAttribute('data-nosnippet', '');
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
    close.addEventListener('click', function () {
      dismiss(c);
      bar.remove();
      setBarHeight(0);
      document.documentElement.removeAttribute('data-promo');
    });
    actions.appendChild(close);
    inner.appendChild(actions);
    bar.appendChild(inner);
    return bar;
  }

  // Twinkling stars: a layer the full height of the page, so they scroll with
  // it (owner, 2026-11-17), and never take a click. Spread across the page.
  function stars() {
    var layer = el('div', 'campaign-stars');
    layer.setAttribute('aria-hidden', 'true');
    document.body.appendChild(layer);
    var fit = function () {
      layer.style.height = '0px';
      layer.style.height = document.documentElement.scrollHeight + 'px';
    };
    fit();
    if (window.ResizeObserver) new ResizeObserver(fit).observe(document.body);
    else window.addEventListener('resize', fit);
    var phone = window.innerWidth < 700;
    // About one star per screenful-slice of page, whatever its length.
    var n = Math.max(16, Math.min(220, Math.round(layer.offsetHeight / (phone ? 110 : 45))));
    for (var i = 0; i < n; i++) {
      // The star itself is CSS ::before — no text for a search engine to read.
      // Mostly five-pointed, with some six- and eight-pointed among them.
      var r = Math.random();
      var s = el('i', r < 0.6 ? null : (r < 0.85 ? 's6' : 's8'));
      // Spread across the whole width (owner, 2026-11-17).
      s.style.left = (Math.random() * 99).toFixed(2) + '%';
      s.style.top = (Math.random() * 100).toFixed(2) + '%';
      s.style.fontSize = (10 + Math.random() * (phone ? 8 : 12)).toFixed(1) + 'px';
      s.style.setProperty('--d', (2.2 + Math.random() * 3).toFixed(2) + 's');
      s.style.setProperty('--delay', (-Math.random() * 5).toFixed(2) + 's');
      layer.appendChild(s);
    }
  }

  function run() {
    var picked = pick();
    if (!picked) return;
    var c = picked.c;
    var path = location.pathname;
    var root = document.documentElement;
    root.setAttribute('data-campaign', c.id);
    if (pathMatches(c.themeOn || [], path)) root.setAttribute('data-campaign-theme', c.theme);
    if (c.starsOn && pathIs(c.starsOn, path)) stars();
    if (picked.offer && pathMatches(c.bannerOn || [], path) && !dismissed(c)) {
      var b = banner(c);
      b.classList.add('promo-' + c.theme);
      // After the skip link, so keyboard users still reach it first.
      var skip = document.querySelector('.skip-link');
      document.body.insertBefore(b, skip ? skip.nextSibling : document.body.firstChild);
      root.setAttribute('data-promo', 'on');
      var measure = function () { if (b.isConnected) setBarHeight(b.offsetHeight); };
      measure();
      if (window.ResizeObserver) new ResizeObserver(measure).observe(b);
      else window.addEventListener('resize', measure);
      // On a phone the small print folds away once the visitor scrolls, so
      // the banner and the header together take less of the screen.
      window.addEventListener('scroll', function () {
        b.classList.toggle('promo-compact', window.scrollY > 40);
      }, { passive: true });
    }
  }

  // The script tag sits at the end of <body>, so the page is already there:
  // run now, before the first paint, so the banner never pushes content down
  // after it is drawn (a layout shift counts against the page in search).
  if (document.body) run();
  else document.addEventListener('DOMContentLoaded', run);
})();
