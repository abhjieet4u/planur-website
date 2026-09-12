# Website lane — backlog and review notes

Open work owned by this lane, newest first. The lane's boundary is *what a
browser renders* — see `planur-app/docs/session-lanes.md`. Schema, RLS,
repositories and migrations stay with `tutor`/`platform` even when the symptom
shows up in a browser.

This file exists because `portal-redesign-plan.md` belongs to the app chat now,
and two lanes editing one 100 KB document is a collision waiting to happen.

---

## 2026-09-12 — Go-live review of /schools and /tutors

Independent review before launch. Three blockers found; **all three fixed in
this commit.**

### Fixed

1. **🔴 The enquiry form posted to STAGING.** `site/assets/planur.js` named the
   staging project unconditionally, so every "Talk to us" from the live site —
   the only conversion path on either page — landed in the test database while
   the sender saw "we'll come back within one working day". Now chosen by
   hostname. Verified first that `contact-submit` is ACTIVE on prod with
   `verify_jwt: false`; repointing at an undeployed function would have been
   worse than the bug.

2. **🔴 /schools claimed students see the timetable on their phone.** They do
   not. 119's RLS permits it; nothing reads it. Moved to being-built, with a
   guard comment at the site.

3. **🔴 Export was promised and denied on the same page.** "Export it in full and
   go" versus "Year-end export and custody — not available today", with no
   export anywhere in the product. Reworded to what is actually true: we do it
   by hand, on request.

### Still open, NOT this lane

- **`practice.kind` / migration 128 on prod.** 128 §3 locks `kind` to service
  role — the school paywall. Confirmed applied on **staging** (two guard
  triggers). **Prod unverified** — the sandbox classifier blocked the query.
  Must be confirmed before anything gates on `kind`.
- **The `schoolOnly` nav gate** — see below.
- **DPA** — /schools says "a data processing agreement we sign with you at
  onboarding". The draft in `docs/legal/dpa-schools.md` is still marked NOT FOR
  SIGNATURE, has not been to a solicitor, and its §6 breach window is undecided.
  It has to exist before the first signature, not the first conversation.

### Observation for the app lane: tutors get the whole school product

`navAreasFor` in `tutor_app/lib/core/ui/nav_areas.dart` gates on ROLE only —
`adminOnly`, `officeOnly`, `financeOnly`, `manageOnly`. **There is no `kind`
check anywhere in that file**, and `features/timetable/` contains no `isSchool`
test at all.

128 §3's own comment says *"every school feature gates on `kind`"*. That is true
of the FIELDS (student records, branding, address) and not of the NAVIGATION. So
a solo tutor on free currently sees Timetable, Calendar, Schedules, Fee setup,
Staff and Reminders.

Owner's view, 2026-09-12: turn off **Timetable**, **Staff**, **Fee setup**
(heads / financial year / gapless receipt series) and **Schedules** for tutors;
keep **Calendar** and **Results**. One `schoolOnly` flag on `NavItem` plus one
clause in `navAreasFor`, mirroring the four role flags.

⚠️ Hiding a nav item is not access control — the routes stay reachable by URL.
Anything a tutor must genuinely not have needs RLS or a trigger as well.

---

## 2026-09-06 — Sign-in screen is full width  ⬜ STILL OPEN

**Owner:** *"the First log in page is still of full width which is not great,
rather better to have a graphics added on the left and the log in along with
logo in centre of remaining screen"*

**Where:** `planur-app/tutor_app/lib/features/auth/sign_in_screen.dart`
(re-checked 2026-09-12: still no width cap, still no split pane).

The form is centred but nothing caps its width, so on a 1400px browser the email
field and the Send code button stretch the full screen. It reads as an unstyled
form on a blank page — and it is the first thing a head teacher sees.

**Shape:** two panes above ~900px. Left, a graphic panel in brand tints, painted
in Flutter rather than an image (the app ships no image assets). Right, logo,
`signInProductName`, blurb and the form, capped at ~380px. Below the breakpoint,
today's layout with the same cap so a tablet stops stretching.

⚠️ `signInProductName` / `signInBlurb` must keep driving the wording — the school
door says "Planur for Schools", and that is cosmetic by design
(`core/config/entry_point.dart`). Nothing may gate on it.

---

## 2026-09-06 — Icons and colour across the marketing site  ⏸️ BLOCKED

**Owner:** *"use strategic icons with text heading in whole of the website, with
colours on the web… for both tutor and school site."*

**Check the premise first.** The pages already carry icons (35 SVGs on
`/schools`, 41 on `/tutors`) and `assets/planur.css` defines a full palette. So
this is not "add icons" — more likely the colour is defined and barely spent,
and the icons sit inside cards rather than on the section headings.

**Blocked on the owner** saying which page reads worst — `/schools`, `/tutors` or
the home page — so one can be done first and the direction judged before it is
applied to all three. Do not start the sweep until that is settled.
