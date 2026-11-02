# Website lane — backlog and review notes

Open work owned by this lane, newest first. The lane's boundary is *what a
browser renders* — see `planur-app/docs/session-lanes.md`. Schema, RLS,
repositories and migrations stay with `tutor`/`platform` even when the symptom
shows up in a browser.

This file exists because `portal-redesign-plan.md` belongs to the app chat now,
and two lanes editing one 100 KB document is a collision waiting to happen.

---

## 2026-10-12 — /tutors never mentions the free trial, and the one offer it does make is wrong  ⬜ OPEN

**Filed by the app/tutor lane. Everything below is website copy, so it is this
lane's to fix — the product side is already built and needs no change.**

Owner is pushing the tutor market and asked what a new tutor is actually offered.
Tracing it from the live site through to the product found two copy problems on
`/tutors`, one of which actively misleads.

### 1. 🔴 The trial is invisible

The product has a **self-serve 14-day trial: no card, no sales call, granted
instantly.** `/tutors` does not mention it anywhere — I grepped the page for
`trial` and the only hit is an unrelated code comment.

What the page offers instead: **"Talk to us"** as the primary CTA, "See what it
does" as secondary, and "Tutor log in" in the header. So the only advertised way
in is a conversation, while the thing that needs no conversation goes unmentioned.

A tutor can only discover the trial by signing up, then navigating to
**Practice & plan** — an owner-only screen inside the app.

### 2. 🔴 The offer the page DOES make contradicts the product

`site/tutors/index.html`, the `#talk` band:

> **"Try it with one real batch. For one month."**

The product grants **14 days**, from `start_trial()`'s `p_days default 14`.
Anyone accepting that offer expects roughly twice what the button gives them.

**Two honest ways to close it** — this is a judgement call for the owner, not a
copy tweak, so please raise it rather than picking one:
- change the page to say 14 days, or
- keep "one month" as a *human* arrangement — the band is a "talk to us" ask,
  and an operator can set a longer trial by hand — but then the page should not
  imply it is the same thing as the self-serve button.

### Verified product limits, for writing accurate copy

Read from `plan_limit`, **re-checked 2026-10-13 after migrations 149 and 150**:

| | **Free** (default, permanent) | **Trial** — the Pro band, 14 days |
|---|---|---|
| Students | **5** | 75 |
| Storage | **100 MB** | 5 GB |
| AI practice tests / month | 2 | 30 |
| Staff logins | 1 (the tutor alone) | 2 |
| Email sends / month | **0** | 1,000 |

⚠️ **An earlier version of this note said Free was 10 students and 500 MB.
That was true for two days and is now wrong.** 149 (2026-10-12) cut it to
5 students / 50 MB and 150 raised the storage to 100 MB the same day; both are
applied on staging and prod. **Re-read `plan_limit` before writing any number
into copy** — this tier has moved three times in a fortnight.

**Safe and true to say:**
- The trial needs **no card** and there is nothing to cancel.
- Nothing is deleted when it ends — the practice returns to Free and keeps every
  student, mark, invoice and register.
- **Free is permanent**, with no card ever required.
- One trial **per account**.

⚠️ **Do not say the trial "converts" to a paid plan.** It cannot — there is no
card. That exact claim was live in `site/terms/index.html` and was corrected on
2026-10-10; please don't reintroduce it in marketing copy.

⚠️ Two things are switched **off** on Free rather than merely capped, so avoid
implying a free tutor gets a reduced version of them: **parent/student email
reminders do not send at all** (`email_sends_per_month: 0`), and **no colleague
can be added** (`team_cap: 1`).

### ⬜ Two promises that MUST appear on the pricing page when prices are published

Owner decided both on 2026-10-13. They are commitments, not marketing lines, so
the page is where they have to live — a promise made in a chat and not on the
page is not a promise.

1. **"The price you join on is the price you keep, for as long as your
   subscription stays active."** A cancel-and-return gets current pricing.
2. **"Any price rise is announced three months in advance."** The owner framed
   rises as inflation-linked.

Both are safe to state plainly. They are also genuinely unusual in this market
and worth their space — neither TutorBird nor TutorCruncher commits to either.

⚠️ Do not write these until prices are actually published; a price-protection
promise with no visible price reads as filler.

### 🔴 Constraints that must hold

- **No prices on this page.** Standing owner rule, and the page already carries
  it as a comment at the top. This note is not a reason to break it.
- **Prices are decided but Stripe is on the old figures** — Starter £11.99 /
  Pro £19.99 / Practice £34.99 agreed 2026-10-10, while the live Payment Links
  still charge £12.50 / £25 / £40 (`planur-app/docs/tutor-stripe-config.md`).
  `plan_prices.dart` is deliberately left empty for this reason. **Publishing any
  price before the links move would quote one figure and charge another.**
- **Don't promise in-app purchase on iPhone.** The tutor iOS build is
  `BillingChannel.none` under App Store Guideline 3.1.3(f) — it shows no prices
  and no route to paying, and a link out would itself be the violation. "Subscribe
  in your browser" is the accurate framing.

### Not this lane

- Trial discoverability **inside** the app (it sits behind an owner-only screen).
  App/tutor lane; raise it there if the website starts sending traffic to it.
- `site/terms/index.html`'s trial clause — already fixed and committed.

### Context the owner may want decided first

✅ **Largely settled by 149/150.** This paragraph originally warned that Free —
then 10 students and 500 MB — was generous enough that a small tutor might never
trial or pay. At **5 students and 100 MB** that risk is much smaller: Free is now
an on-ramp, not a destination.

Which also suggests the better thing to advertise. **Planur is the only one of
the three with a permanent free tier** — TutorBird and TutorCruncher both have
none (TutorBird offers a 30-day trial, TutorCruncher starts at £25/month). So
*"start free, no card, no deadline"* is a true and distinctive claim, and a
stronger opener than a trial length.

⚠️ **But do not claim a trial advantage: TutorBird's free trial is 30 days and
ours is 14.** The honest contrast is the deadline, not the duration — theirs
expires, ours does not. And Free sends **no** parent reminders at all
(`email_sends_per_month: 0`), which is the feature TutorBird markets hardest, so
Free cannot be described as "the whole product, smaller".

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
