/* ============================================================================
   Planur — shared behaviour for theplanur.co.uk
   ----------------------------------------------------------------------------
   No dependencies, no external requests. Everything here is progressive
   enhancement: with this file blocked, every page is still fully readable and
   every form still tells the visitor how to reach us.

   Exposes window.Planur = { callEdgeFunction, setErr, validEmail, looksAutomated,
                             initModal, initAppSwitch }
   ========================================================================== */
(function () {
  'use strict';

  var LOADED_AT = Date.now();

  /* ── Supabase Edge Functions ───────────────────────────────────────────────
     No keys here — credentials live server-side inside the functions.

     🔴 EVERYTHING IS ON STAGING UNTIL THE CUTOVER — AND THAT IS DELIBERATE.
     Owner, 2026-09-12: the soft launch runs on staging for the first two
     schools; once they confirm the features, Planur launches and migrates to
     prod. Prod is empty and nobody is watching it, so an enquiry sent there
     would be worse than one sent to staging: the team would never see it.

     The tutor portal served from this same site at /tutors/app/ is built with
     the staging dart-defines, so pointing this file at prod would also split
     the site in half — a visitor enquiring in one project and signing in to
     another.

     ⚠️ For a few hours on 2026-09-12 this DID point at prod. It was written to
     fix the opposite bug (the file named staging unconditionally, with no way
     to ever change it) before the staging soft launch was known here. The
     mechanism was right and the target was wrong.

     ── AT CUTOVER: FLIP ONE BOOLEAN ─────────────────────────────────────────
     Set GO_LIVE_ON_PROD = true, rebuild, redeploy. Do it in the same change as
     the tutor web rebuild against config/prod.json — the two must move
     together or the split above is exactly what you get.

     Kept as a hostname switch rather than a bare constant because dist/ is
     assembled by tools/build_site.sh from these exact files: after the flip,
     localhost and Netlify previews still write to staging, so the preview the
     README prescribes can never touch the live enquiry table.

     Project refs, not keys: both already ship inside the published apps and in
     every request URL they make. `contact-submit` is deployed on both projects
     with verify_jwt off, which is what lets an anonymous visitor call it.     */
  var GO_LIVE_ON_PROD = true;   // flipped 2026-10-14, with the prod web cutover

  var LIVE_HOSTS = ['theplanur.co.uk', 'www.theplanur.co.uk'];
  var IS_LIVE = GO_LIVE_ON_PROD && LIVE_HOSTS.indexOf(location.hostname) !== -1;

  var PROJECT_ID = IS_LIVE ? 'hjjgbqkvhaqamkkrvvvc' : 'uvhcnikrlhfwbkdzbntb';
  var FN_BASE = 'https://' + PROJECT_ID + '.supabase.co/functions/v1';

  function callEdgeFunction(name, payload) {
    return fetch(FN_BASE + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).then(function (res) {
      return res.json().catch(function () { return {}; }).then(function (data) {
        if (!res.ok) throw new Error(data.error || res.statusText);
        return data;
      });
    });
  }

  /* ── Form helpers ────────────────────────────────────────────────────────── */
  function setErr(groupId, el, show) {
    var group = document.getElementById(groupId);
    if (group) group.classList.toggle('has-error', show);
    if (el) el.classList.toggle('error', show);
  }

  function validEmail(v) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v); }

  /* Two cheap, dependency-free spam checks. A captcha would mean an external
     request, which this site does not make.
       1. A honeypot field a person never sees and never fills.
       2. Time on page — nobody completes a real form in under three seconds.
     A hit is dropped silently (the sender still sees success) because telling a
     bot why it failed only helps it.                                          */
  function looksAutomated(form) {
    var hp = form.querySelector('.hp input');
    if (hp && hp.value.trim() !== '') return true;
    return (Date.now() - LOADED_AT) < 3000;
  }

  /* Clear the error state as soon as someone starts fixing a field. */
  function wireLiveClear(form) {
    form.querySelectorAll('input, select, textarea').forEach(function (el) {
      el.addEventListener('input', function () {
        el.classList.remove('error');
        var g = el.closest('.form-group');
        if (g) g.classList.remove('has-error');
      });
    });
  }

  /* ── Nav shadow on scroll ────────────────────────────────────────────────── */
  function initNav() {
    var navbar = document.getElementById('navbar');
    if (!navbar) return;
    var onScroll = function () {
      navbar.classList.toggle('scrolled', window.scrollY > 20);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* ── Site menu (hamburger) ───────────────────────────────────────────────────
     <details> already opens and closes; this adds what it lacks: close on an
     outside click or Escape, and mark the link for the page you are on. */
  function initSiteMenu() {
    var menu = document.querySelector('.site-menu');
    if (!menu) return;
    // The bare domain is served from /tutors/ by a rewrite, so "/" is that page.
    var norm = function (p) { p = p.replace(/\/+$/, ''); return p === '' ? '/tutors' : p; };
    var here = norm(location.pathname);
    menu.querySelectorAll('a[href]').forEach(function (a) {
      if (norm(a.pathname) === here) a.setAttribute('aria-current', 'page');
    });
    document.addEventListener('click', function (e) {
      if (menu.open && !menu.contains(e.target)) menu.open = false;
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && menu.open) {
        menu.open = false;
        var s = menu.querySelector('summary');
        if (s) s.focus();
      }
    });
  }

  /* ── Reveal-on-scroll ────────────────────────────────────────────────────── */
  function initFadeIn() {
    var targets = document.querySelectorAll('.fade-in');
    if (!targets.length) return;
    if (!('IntersectionObserver' in window)) {
      targets.forEach(function (el) { el.classList.add('visible'); });
      return;
    }
    var obs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); }
      });
    }, { threshold: 0.12 });
    targets.forEach(function (el) { obs.observe(el); });
  }

  /* ── Student / Tutor selector ─────────────────────────────────────────────
     Used by /privacy, /terms, /delete-account and /support, which are one
     document each covering both apps.

     Which side shows first is taken from, in order:
       ?app=tutor           ← the URL each app store listing points at
       #tutor / #tutors / #tutor-app
       otherwise: student

     Switching rewrites ?app= in place so the URL stays shareable, and never
     adds a history entry (Back should leave the page, not undo a toggle).     */
  function initAppSwitch() {
    var sw = document.querySelector('.app-switch');
    if (!sw) return;

    var buttons = [].slice.call(sw.querySelectorAll('button[data-app]'));
    if (!buttons.length) return;

    /* Which audiences does THIS page actually have? Only the ones with a button.
       ⚠️ Without this check, ?app=school on a page that has no school variant
       (/support, /terms) would hide every app-specific block and leave the page
       looking empty — the show/hide rule in planur.css hides anything that does
       not name the selected app. Resolve, then fall back to something real. */
    function has(app) {
      return buttons.some(function (b) { return b.dataset.app === app; });
    }

    function wanted() {
      var q = new URLSearchParams(location.search).get('app');
      var h = (location.hash || '').toLowerCase();
      var want = 'student';
      if (q === 'school' || q === 'schools') want = 'school';
      else if (q === 'tutor' || q === 'tutors') want = 'tutor';
      else if (q === 'student') want = 'student';
      else if (h.indexOf('school') !== -1) want = 'school';
      else if (h.indexOf('tutor') !== -1) want = 'tutor';
      if (has(want)) return want;
      // Schools are served by the tutor product, so with no school tab a school
      // link belongs on the tutor view rather than the student one.
      if (want === 'school' && has('tutor')) return 'tutor';
      return has('student') ? 'student' : buttons[0].dataset.app;
    }

    function apply(app, pushUrl) {
      document.documentElement.setAttribute('data-app', app);
      buttons.forEach(function (b) {
        b.setAttribute('aria-pressed', String(b.dataset.app === app));
      });
      if (pushUrl && window.history && history.replaceState) {
        var url = new URL(location.href);
        url.searchParams.set('app', app);
        history.replaceState(null, '', url.pathname + url.search + url.hash);
      }
    }

    buttons.forEach(function (b) {
      b.addEventListener('click', function () { apply(b.dataset.app, true); });
    });

    apply(wanted(), false);
  }

  /* ── Contact modal ───────────────────────────────────────────────────────── */
  function initModal(overlayId, openerSelector) {
    var overlay = document.getElementById(overlayId);
    if (!overlay) return null;
    var closeBtn = overlay.querySelector('.modal-close');
    var lastFocus = null;

    function open() {
      lastFocus = document.activeElement;
      overlay.classList.add('open');
      document.body.style.overflow = 'hidden';
      var first = overlay.querySelector('input, textarea, button');
      if (first) first.focus();
    }
    function close() {
      overlay.classList.remove('open');
      document.body.style.overflow = '';
      if (lastFocus && lastFocus.focus) lastFocus.focus();
    }

    if (openerSelector) {
      document.querySelectorAll(openerSelector).forEach(function (a) {
        a.addEventListener('click', function (e) { e.preventDefault(); open(); });
      });
    }
    if (closeBtn) closeBtn.addEventListener('click', close);
    overlay.addEventListener('click', function (e) { if (e.target === overlay) close(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && overlay.classList.contains('open')) close();
    });

    return { open: open, close: close };
  }

  /* ── Cookie consent ───────────────────────────────────────────────────────
     Two categories: "necessary" (always on) and "marketing" (opt-in).
     Consent stored in localStorage; checked by Planur.marketingOk() before
     any future marketing script (FB pixel, Google Ads tag) loads.           */
  var CONSENT_KEY = 'planur_cookie_consent';

  function getConsent() {
    try { var v = localStorage.getItem(CONSENT_KEY); return v ? JSON.parse(v) : null; }
    catch (_) { return null; }
  }

  function saveConsent(marketing) {
    try { localStorage.setItem(CONSENT_KEY, JSON.stringify({ marketing: !!marketing, t: Date.now() })); }
    catch (_) { /* private browsing */ }
  }

  function marketingOk() {
    var c = getConsent();
    return !!(c && c.marketing);
  }

  function dismissBanner() {
    var el = document.getElementById('planur-cookies');
    if (el) el.remove();
  }

  function injectBanner() {
    if (getConsent()) return;

    var css =
      '#planur-cookies{position:fixed;bottom:0;left:0;right:0;z-index:9999;' +
      'display:flex;justify-content:center;padding:16px;pointer-events:none;}' +
      '#planur-cookies .cc-box{pointer-events:auto;background:var(--text-dark,#1a2332);' +
      'color:#fff;border-radius:16px;padding:22px 26px;max-width:520px;width:100%;' +
      'box-shadow:0 8px 32px rgba(0,0,0,.25);font-family:inherit;line-height:1.6;}' +
      '#planur-cookies h3{margin:0 0 4px;font-size:1.05rem;font-weight:800;}' +
      '#planur-cookies .cc-lead{font-size:.88rem;color:rgba(255,255,255,.78);margin:0 0 14px;}' +
      '#planur-cookies .cc-toggle{display:flex;align-items:center;gap:10px;' +
      'font-size:.86rem;margin:0 0 16px;color:rgba(255,255,255,.85);}' +
      '#planur-cookies .cc-toggle label{cursor:pointer;display:flex;align-items:center;gap:8px;}' +
      '#planur-cookies .cc-pill{display:inline-block;font-size:.72rem;font-weight:700;' +
      'background:rgba(255,255,255,.13);padding:2px 8px;border-radius:99px;margin-left:6px;' +
      'color:rgba(255,255,255,.5);}' +
      '#planur-cookies .cc-switch{position:relative;width:38px;height:22px;flex-shrink:0;}' +
      '#planur-cookies .cc-switch input{opacity:0;width:0;height:0;}' +
      '#planur-cookies .cc-switch span{position:absolute;inset:0;background:rgba(255,255,255,.2);' +
      'border-radius:22px;transition:background .2s;cursor:pointer;}' +
      '#planur-cookies .cc-switch span::after{content:"";position:absolute;left:3px;top:3px;' +
      'width:16px;height:16px;background:#fff;border-radius:50%;transition:transform .2s;}' +
      '#planur-cookies .cc-switch input:checked+span{background:var(--sage,#6b9e7e);}' +
      '#planur-cookies .cc-switch input:checked+span::after{transform:translateX(16px);}' +
      '#planur-cookies .cc-btns{display:flex;gap:10px;flex-wrap:wrap;}' +
      '#planur-cookies .cc-btn{border:none;border-radius:10px;padding:10px 20px;' +
      'font-size:.88rem;font-weight:700;cursor:pointer;transition:transform .15s;}' +
      '#planur-cookies .cc-btn:hover{transform:translateY(-1px);}' +
      '#planur-cookies .cc-accept{background:var(--sage,#6b9e7e);color:#fff;}' +
      '#planur-cookies .cc-necessary{background:rgba(255,255,255,.12);color:#fff;}';

    var style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);

    var wrap = document.createElement('div');
    wrap.id = 'planur-cookies';
    wrap.setAttribute('role', 'dialog');
    wrap.setAttribute('aria-label', 'Cookie preferences');
    wrap.innerHTML =
      '<div class="cc-box">' +
        '<h3>🍪 We baked some cookies</h3>' +
        '<p class="cc-lead">The essential ones keep the site running — they’re not optional, ' +
          'a bit like homework. The marketing ones help us show you relevant ads, ' +
          'and you’re the boss of those.</p>' +
        '<div class="cc-toggle">' +
          '<span>Necessary</span><span class="cc-pill">always on</span>' +
        '</div>' +
        '<div class="cc-toggle">' +
          '<label class="cc-switch"><input type="checkbox" id="cc-mkt"><span></span></label>' +
          '<span>Marketing — <em>help us find more tutors like you</em></span>' +
        '</div>' +
        '<div class="cc-btns">' +
          '<button class="cc-btn cc-accept" id="cc-all">Accept all</button>' +
          '<button class="cc-btn cc-necessary" id="cc-save">Save my choices</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(wrap);

    document.getElementById('cc-all').addEventListener('click', function () {
      saveConsent(true);
      dismissBanner();
    });
    document.getElementById('cc-save').addEventListener('click', function () {
      saveConsent(document.getElementById('cc-mkt').checked);
      dismissBanner();
    });
  }

  /* ── Boot ────────────────────────────────────────────────────────────────── */
  function boot() {
    initNav();
    initSiteMenu();
    initFadeIn();
    initAppSwitch();
    injectBanner();
    document.querySelectorAll('form[data-live-clear]').forEach(wireLiveClear);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  window.Planur = {
    callEdgeFunction: callEdgeFunction,
    setErr: setErr,
    validEmail: validEmail,
    looksAutomated: looksAutomated,
    wireLiveClear: wireLiveClear,
    initModal: initModal,
    initAppSwitch: initAppSwitch,
    marketingOk: marketingOk
  };
})();
