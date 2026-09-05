# Instructing a solicitor on the schools DPA

**Hold this until the school conversations are done** — owner, 2026-09-05, so the
document is instructed once rather than twice. Part 1 is what to bring back from
those conversations; Part 2 is the brief itself, which is ready to send as soon
as Part 1 is filled in.

Companion document: [`dpa-schools.md`](dpa-schools.md) — the draft under review.

---

# Part 1 — what to find out from the schools first

Ask these in the next few weeks. Each one changes the instruction, and several
change it a lot.

### 🔴 1. Do they have their own DPA template?

**Ask this first, and early in the conversation.** Schools, trusts, councils and
academy chains very often mandate their own processor agreement. If they do, the
job changes from *"review ours"* to *"review theirs and tell us what we cannot
accept"* — a different and usually more expensive piece of work, and one where
the risk sits the other way round.

If more than one school says yes, our draft becomes a fallback rather than the
main event, and the instruction should say so.

### 2. Which jurisdiction and which board?

India (DPDP Act 2023) or UK (UK GDPR), and for Indian schools the board — CBSE,
ICSE, or a state board. This decides whether the DPDP questions in Part 2 are
the main event or a footnote.

### 3. What statutory retention are they subject to?

Does anything oblige them to keep pupil records for a fixed number of years? If
so, our 36-month dormancy deletion is not merely unpopular, it is unusable
without the retention hold, and the contract must say how that is invoked.

### 4. Do they require EU-only or in-country processing?

Some will. Our AI providers include Groq, Anthropic and Google outside the EU.
There is **no per-school setting to disable AI features today** — do not promise
one. If a school insists, that becomes a build dependency before signature.

### 5. What breach-notification window do they expect?

Ours says 48 hours. Some institutional templates demand 24. ⚠️ There is no
on-call rota, so agreeing 24 would be agreeing to something we cannot reliably
do. Find out before the solicitor prices the clause.

### 6. Who actually signs, and do they need anything before that?

The principal, a trust, a management committee? And do they require a DPIA, a
completed security questionnaire, Cyber Essentials or ISO 27001? **We hold no
certification** — better to learn that it is a blocker now than after a legal
bill.

### 7. Will they accept the sub-processor list as it stands?

Annex C of the draft. Objections to a specific provider are common and are
easier to handle before the terms are settled.

---

## What to write down as you go

For each school: jurisdiction · board · own template Y/N · statutory retention ·
EU-only Y/N · breach window · signatory · certifications demanded ·
sub-processor objections.

Three or four schools' answers side by side is what turns this into one
instruction instead of three.

---

# Part 2 — the brief

*Send when Part 1 is filled in. Attach `dpa-schools.md` and the privacy notice
at https://theplanur.co.uk/privacy?app=school*

## Who we are

Planur is a UK-built school and tutoring management platform. Schools use it for
classes, attendance registers, assessment marks, fees and communication with
parents. Pupils and parents get read-only access to their own records.

We are pre-revenue with schools: **no school customer exists yet.** We are in
conversation with a small number of low-to-mid-tier Indian schools, and expect
UK schools later.

⚠️ Insert before sending: legal entity name, company number, registered address.

## What we are asking for

**A review, not a drafting exercise.** The attached draft is complete and
self-consistent; we need it made safe to sign and the deliberately-blank
commercial clauses filled.

We are **not** asking for: a privacy notice review (already published), employment
terms, or a general commercial review of our T&Cs.

## The specific questions

### A. Clause 11 — left blank on purpose

Liability cap, indemnities, term and governing law. We left these empty rather
than copy a template, because they are where a template does real damage. We
would like your drafting, proportionate to a small vendor processing children's
personal data for institutions.

### B. Clause 3 — the DPDP position, and it is the one that worries us

Our platform has a setting, `institution_attested`, by which a school confirms
it holds the lawful basis for its pupils under its own authority, rather than
Planur collecting verifiable parental consent pupil by pupil.

The DPDP Act 2023 requires verifiable parental consent for under-18s, with
exemptions for educational institutions. **Is that exemption wide enough to
support what clause 3 asserts?** If it is not, we need to know before any Indian
school is onboarded, because the alternative is a consent-collection flow we
have not built.

For UK schools the equivalent question is whether the school's public-task or
legitimate-interests basis is sufficient, and whether our reliance on the
school's warranty is reasonable.

### C. Clause 6 — breach notification, and the definition it turns on

We commit to 48 hours **from becoming aware**, to leave the school time inside
its own 72. We are a very small team with **no 24/7 monitoring**, so a breach
could go unnoticed for a period.

Clause 6.2 therefore defines "becoming aware" as requiring reasonable certainty
that an incident occurred *and* that personal data was compromised. Clause 6.4
commits us to investigating incidents the school reports.

**Is 6.2 a defensible definition, or will a school's advisers read it as an
escape hatch?** And is 48 hours the right figure given the absence of monitoring
— or should the obligation rest on "without undue delay" alone?

### D. Clause 9.1 — dormancy deletion

A school account unused for 36 months is deleted, with no recovery. Records are
extracted and returned to the school first.

⬜ **The export is not yet built.** Please tell us how to word this so it is not
a misrepresentation before it exists — or advise that it must not be signed
until it is.

### E. Annexes

Annex B (security measures) states plainly what we have and, explicitly, what we
do not: no penetration testing, no ISMS, no certification. Please confirm that
saying so is the right approach rather than a liability.

## Facts you will need

| | |
|---|---|
| Data subjects | Pupils including children, parents and guardians, school staff |
| Data | Names, class, enrolment history, attendance, assessment marks, fees, parent contact details |
| Special category | None collected today. ⚠️ Caste, income and disability certificates for Indian grant schemes are **designed but not built** — see §6 of our internal plan. Please flag what changes when they are. |
| Storage | EU (Supabase) |
| Sub-processors | Annex C |
| Payment | Stripe; we never receive card details |
| Certifications | **None** |
| Live school customers | **None** |

## Commercial

Please give a fee estimate before starting. If the answer to Part 1 question 1
is that schools will supply their own template, tell us what changes about scope
and cost.
