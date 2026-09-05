# Data Processing Agreement — schools

**DRAFT · NOT FOR SIGNATURE.** Written 2026-09-05 by the website lane so the
promise in the privacy notice has something behind it. It has **not** been
reviewed by a solicitor, and it allocates liability for children's personal
data. Do not send this to a school as a document to sign; send it to a lawyer
first. The clauses most likely to need changing are marked ⚠️.

**Why it exists:** `/privacy?app=school` §11 already tells schools —

> The full **Data Processing Agreement** — the one your legal team will want,
> with the Article 28 / DPDP processor terms in full, the sub-processor list as
> an annex and the security schedule — is signed with you at onboarding.

That page is deployed. Until this document exists and is reviewed, that sentence
is a promise we cannot keep, and no school should be onboarded.

**Two laws, one document.** UK/EU schools need Article 28 UK GDPR / EU GDPR
terms. Indian schools need the DPDP Act 2023, where the school is the **Data
Fiduciary** and Planur the **Data Processor**, and where children's data carries
its own duties. Rather than maintain two contracts, the terms below are written
to satisfy both, with the DPDP-specific points called out.

---

## 1. Parties and role

**The School** is the **Controller** (UK/EU GDPR) and **Data Fiduciary** (DPDP
Act 2023) of the student and staff personal data it enters into Planur.

**Planur** is the **Processor** (UK/EU) and **Data Processor** (DPDP). Planur
processes that data **only on the School's documented instructions**, and use of
the Planur software constitutes those instructions for the purposes described in
Annex A.

⚠️ Planur is a trading name of a UK entity; the legal name, company number and
registered address must be inserted before signature.

## 2. Subject matter, duration, nature and purpose

| | |
|---|---|
| **Subject matter** | Provision of the Planur school management software |
| **Duration** | The term of the School's subscription, plus the deletion window in §9 |
| **Nature and purpose** | Storing and presenting timetables, classes, enrolment, attendance, assessment marks, fees and school communications; and providing pupils and parents access to their own records |
| **Types of personal data** | See Annex A |
| **Categories of data subject** | Pupils (including children), parents and guardians, teaching and administrative staff |

## 3. The School's obligations

The School warrants that:

- it has a lawful basis for the personal data it enters, and for pupils this
  includes the basis on which the school acts for children in its care;
- 🔴 where the School has been configured with `consent_basis =
  institution_attested`, it confirms it holds consent or another lawful basis
  for each pupil under its own authority, and does not rely on Planur obtaining
  parental consent individually. **This setting can only be applied by Planur
  and only against a signed agreement** — it is the operative fact this document
  records;
- it has issued its own privacy information to pupils, parents and staff;
- its instructions to Planur will not put Planur in breach of applicable law.

⚠️ Indian schools: the DPDP Act requires **verifiable parental consent** for
children under 18, with narrow exemptions for educational institutions. Whether
`institution_attested` is sufficient for a given school is a question for
counsel, not for this document. See `docs/india-dpdp-*` in the app repo for the
current position and the 2027 deadline.

## 4. Planur's obligations (Article 28(3))

Planur shall:

- **(a)** process personal data only on documented instructions, including for
  transfers, unless required by law — in which case it will inform the School
  first, unless the law forbids it;
- **(b)** ensure persons authorised to process the data are under a duty of
  confidence;
- **(c)** implement the technical and organisational measures in Annex B;
- **(d)** engage no sub-processor without the School's authorisation — Annex C
  is the list as at the date of signature, and the School authorises those.
  Planur will give **30 days' notice** of any addition, during which the School
  may object and, if the objection cannot be resolved, terminate without
  penalty;
- **(e)** assist the School in responding to data-subject requests, taking
  account of the nature of the processing;
- **(f)** assist with security, breach notification and impact assessments;
- **(g)** on termination, delete or return the data at the School's choice — see
  §9;
- **(h)** make available the information needed to demonstrate compliance and
  allow audits — see §8.

## 5. Security

Planur shall implement the measures in **Annex B** and shall not materially
reduce them during the term.

## 6. Personal data breach

### 6.1 Notification

Planur will notify the School without undue delay, and in any event within **48
hours of becoming aware** of a personal data breach affecting the School's
personal data.

### 6.2 What "becoming aware" means

Planur becomes aware when it has a reasonable degree of certainty **both** that a
security incident has occurred **and** that the incident has led to personal data
being accidentally or unlawfully destroyed, lost, altered, disclosed, or accessed
without authorisation.

A suspicion, an unverified alert, or an anomaly still under investigation is not
awareness. Planur will investigate any such indication promptly and in good
faith, and the 48 hours run from the point at which that investigation
establishes that a breach has occurred.

### 6.3 What the first notice must contain

So far as known at the time: the nature of the breach; the categories and
approximate number of data subjects and records affected; the likely
consequences; and the measures taken or proposed. Planur will also give a
contact point for further information.

Where not all of that is available, Planur will provide what it has and supply
the remainder in phases without undue further delay. **An initial notice
containing less than the full set is compliance with 6.1, not a breach of it.**

### 6.4 Incidents the School reports to us

Where the School reports a suspected incident, Planur will acknowledge it within
**1 working day** and report the outcome of its investigation within **5 working
days** — or immediately, if the investigation engages 6.1.

### 6.5 Who notifies the regulator

The School is the controller, so notification to a supervisory authority or to
affected individuals is the School's decision and the School's act. Planur will
not make such a notification on the School's behalf unless instructed to in
writing, and will provide the information the School reasonably needs to make
its own.

⚠️ **Why 48 and not 72.** The School's own regulatory clock is 72 hours from its
awareness. A processor that uses all 72 leaves the controller none. 48 is a
commitment rather than a legal minimum — the minimum is "without undue delay" —
and it is achievable because it runs from awareness (6.2), not from occurrence.

🔴 **What this clause does not do, and cannot.** It governs *notification*, not
*detection*. Planur has no 24/7 monitoring (Annex B says so plainly), so a breach
may go unnoticed for some time; 6.2 is what makes the commitment honest rather
than aspirational, and 6.4 is what makes the School part of the detection
surface. Do not let this clause imply a detection capability we do not have.

## 7. Data subject requests

Planur will not respond directly to a request from a pupil, parent or member of
staff about School data, other than to direct them to the School, and will pass
the request on **within 3 working days**.

## 8. Audit

Planur will provide, on request and no more than once a year, its security
documentation and written answers to the School's reasonable questions. On-site
audit is available where a supervisory authority requires it, at the School's
cost and on reasonable notice.

⚠️ Planur holds **no** ISO 27001, SOC 2 or Cyber Essentials certification today.
Do not imply otherwise in a schedule or a sales conversation.

## 9. Return and deletion

On termination the School may export its data — see the year-end export in Annex
A. Planur will delete the School's personal data within **90 days** of
termination, except where retention is required by law.

### 9.1 Dormancy — decided 2026-09-05

🔴 Planur's platform cascade-deletes a dormant account, with no soft delete and
no recovery. **For schools the period is 36 months**, not the 24 that applies to
individual and tutor accounts — owner's decision, 2026-09-05, on the grounds
that a school's year is longer than anyone else's. It is a standard term, not
one varied per customer.

**What makes it acceptable, and what must therefore be built:** before an
account is deleted, its records are extracted and returned to the school. A
school does not lose its data; it stops being stored by us.

⬜ **NOT BUILT.** Until it is, §9.1 describes an intention, not a behaviour, and
this document must not be signed with it in the present tense. Owner has marked
it not urgent, which is fine — but it and the signature cannot both wait.

A school that must retain records for a statutory period beyond 24 months should
say so in writing, so a retention hold can be applied instead.

⚠️ Raise this with every school before signature. It remains the clause most
likely to cause a dispute later, export or no export.

#### 🔴 Three things whoever builds the export must not get wrong

*(platform lane — the sweep is `inactivity-sweep`, migrations 063/064)*

1. **The mailbox is dormant by definition.** That is *why* the account is being
   deleted. Emailing a file of children's personal data to an address nobody has
   opened in two years is a breach waiting to happen — the recipient may have
   left the school entirely. **Send a time-limited authenticated download link,
   not an attachment**, and send the first warning long before the deadline
   (21 months, not 24) while someone may still be reading.
2. **A staging table of extracted data is a shadow copy of deleted records.**
   If it outlives the deletion it defeats the deletion, and contradicts the
   privacy notice's "no soft-delete and no recovery". It needs its own short,
   enforced retention and a purge — decided when it is created, not afterwards.
3. **This overlaps the year-end export already designed** (§5A.8 of the app
   repo's portal-redesign plan). Build one export with two triggers, not two
   exports. A second one will diverge from the first within a quarter.

## 10. International transfers

The School's data is stored in the **EU** (Annex C). Where a sub-processor
processes data outside the UK/EEA, Planur relies on the UK IDTA, the EU Standard
Contractual Clauses or an equivalent recognised mechanism.

⚠️ Some AI providers listed in Annex C process outside the EU. If a school
requires EU-only processing, the AI features must be disabled for that school —
which is not currently a per-school setting. **Do not promise it before
`plan_entitlement` can express it.**

## 11. Liability, term, governing law

⚠️ Deliberately left for counsel. Liability caps, indemnities, term and
governing law are the clauses where a template does real damage.

---

## Annex A — the data, and what Planur does with it

| Category | Examples |
|---|---|
| Pupil identity | Name, class/section, enrolment history, admission and leaving dates |
| Pupil contact | Parent or guardian name, email and phone — **restricted to the school's owner and administrator roles; teachers cannot access it** |
| Attendance | Daily and per-session registers, absences and reasons |
| Assessment | Marks, grades and progress; class aggregates are banded and never ranked |
| Fees | Invoices, amounts, payment status. **No card details** — Planur never receives them |
| Staff | Name, email, role, and the classes they hold |
| Communications | Notices, reminders and messages sent through the platform |

**Year-end export:** the School may export its records for its own retention.
⚠️ Not yet built — see the plan's §5A.8. Do not describe it in the present tense
until it is.

## Annex B — technical and organisational measures

Accurate as at 2026-09-05. Verified against the codebase, not aspirational.

- **Encryption in transit** — TLS on all connections.
- **Encryption at rest** — database encryption by the hosting provider; on
  pupils' own devices the local database is encrypted with SQLCipher, keyed from
  the device's secure hardware store.
- **Access control** — role-based, enforced in the database by row-level
  security rather than in the application. A teacher can reach only their own
  classes; contact details and financial records are restricted to owner and
  administrator roles; those restrictions hold even against a direct API call.
- **Separation** — each school's data is isolated by tenant, with the tenancy
  enforced by database constraint rather than by application code.
- **Authentication** — email one-time codes; no passwords are stored.
- **Least privilege** — staff accounts are created by the school, and roles are
  assignable only by the owner or an administrator.
- **Audit** — an append-only record of privileged actions, readable only by the
  school's owner tier.
- **Backups** — by the hosting provider, retained per its standard policy.

⚠️ Not in place, and not to be implied: penetration testing, a formal ISMS,
24/7 monitoring, and any certification.

⚠️ **How a breach would actually be detected today**, stated plainly because
clause 6.2 depends on it: platform provider security advisories, the append-only
privileged-action log reviewed periodically, provider alerting on authentication
error rates — and a report from the School or a user, which for a team of this
size is a realistic route and is why clause 6.4 exists.

## Annex C — sub-processors

As published in the privacy notice at the date of signature:

| Sub-processor | Purpose | Location |
|---|---|---|
| Supabase Inc. | Database, authentication, sync | EU |
| Google Firebase | Push notifications | Global |
| Mistral AI | AI features | EU |
| Groq, Anthropic, Google (Gemini) | AI features | Outside EU |
| Stripe | Subscription payment | Global |
| Hosting provider | Website and app delivery | Global |

None of the AI providers use school data to train models.

⚠️ RevenueCat and Google Play / Apple appear in the privacy notice for **student
app** subscriptions and are not part of a school's processing; ipapi.co
(geolocation) likewise. Confirm before including or excluding them.

---

## Before this goes to a school

1. Solicitor review — particularly §11, §6's 48 hours, and §3's DPDP position.
2. Insert the legal entity, company number and registered address.
3. Decide whether §9's 24-month dormancy deletion is acceptable to schools, or
   whether schools need a different retention default.
4. Publish a customer-facing version at `schools.theplanur.co.uk/dpa` once
   reviewed — schools expect to read it before a conversation, not after.
