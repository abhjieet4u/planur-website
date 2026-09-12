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

     🔴 THE LIVE SITE MUST POST TO PROD. Until 2026-09-12 this file named the
     STAGING project unconditionally, so every "Talk to us" from theplanur.co.uk
     — the only conversion path on /schools and /tutors — landed in the test
     database, where nothing triages it. The sender still saw "we'll come back
     within one working day".

     Chosen by HOSTNAME rather than by a build-time swap, because dist/ is
     assembled by tools/build_site.sh from these exact files and a constant
     edited at deploy time is a constant somebody eventually forgets. The real
     host posts to prod; localhost, Netlify previews and anything else keep
     using staging, so the preview the README prescribes cannot write to the
     live enquiry table.

     Project refs, not keys: both already ship inside the published apps and in
     every request URL they make. `contact-submit` is deployed on both projects
     with verify_jwt off, which is what lets an anonymous visitor call it.     */
  var LIVE_HOSTS = ['theplanur.co.uk', 'www.theplanur.co.uk'];
  var IS_LIVE = LIVE_HOSTS.indexOf(location.hostname) !== -1;

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

  /* ── Boot ────────────────────────────────────────────────────────────────── */
  function boot() {
    initNav();
    initFadeIn();
    initAppSwitch();
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
    initAppSwitch: initAppSwitch
  };
})();
