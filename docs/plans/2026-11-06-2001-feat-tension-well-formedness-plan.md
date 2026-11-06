---
title: Tension Well-Formedness Rubric and Jev Lint - Plan
type: feat
date: 2026-11-06
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Tension Well-Formedness Rubric and Jev Lint - Plan

---

## Goal Capsule

- **Objective:** A person who reads only a tension's body can tell what gap the role feels, see one concrete instance of it, and know why it matters to the role, so the tension can be processed and can serve as the "why" of any governance change it produces.
- **Means:** one shared rubric, `skills/shared/tension-well-formedness.md` (KTD1), applied as a soft teaching gate at capture and as the standard for `[e] edit body` in triage (KTD3), plus an offline-tested lint that asks Jev one atomic Noul per check and decides in code (KTD2, KTD4).
- **Authority:** the proposal at `/mnt/project-files/tension-well-formedness/proposal.md` (Kraig: "start the checks", 2026-11-06). ADR-0011 still bounds triage to readiness. `triage-gates.md` keeps its five gates and their numbering.
- **Execution profile:** one PR. Markdown rubric and two caller edits, one Python lint script with an offline bash test suite wired into `scripts-test.yml`, one eval scenario plus cases, one ADR. Test it like code (CLAUDE.md § Testing the skills).
- **Stop conditions:** stop and report if wiring the rubric into the capture flow would change the numbering of any `tension-capture-flow.md` or `triage-gates.md` step that other files cite (lint check 2 guards this). Stop if the Python SDK surface named in KTD4 differs from what the installed package exposes.
- **Finish and ship:** `lfg` opens the PR; Kraig merges.

---

## Product Contract

### Summary

Define "well-formed" for a tension in one shared rubric with seven checks, T1 to T7. Capture and triage use it to teach and draft a fix, never to block. A lint script runs the same checks on a tension body: simple checks in code, judgment checks as Jev Noul questions, and a decision table in code that turns the answers into pass, teach, or ask.

### Problem Frame

`/self-org:tension-triage` says it decides whether a tension is "well-formed", but no file defines that word. `triage-gates.md` checks authority, role versus person, venue, supersession, and attribution, not whether the body says anything a reader can act on. Capture Step 4 has four drafting guidelines but no check. Thin tensions therefore enter the backlog and sit there, and a governance change processed from one has no recorded "why".

### Requirements

**Rubric**

- R1. `skills/shared/tension-well-formedness.md` defines seven checks with a one-line test each: T1 gap stated (now versus could be), T2 concrete instance, T3 felt by the role (impact on its purpose or accountabilities), T4 one tension only, T5 not a disguised proposal, T6 topic first, T7 structural (a pointer to `triage-gates.md` Step 2, not a copy).
- R2. Every finding is a teaching finding with a drafted fix. The rubric never blocks capture and never produces a disposition (ADR-0011).
- R3. The rubric applies the "When the gates feel heavy" rule: surface only the checks that fail, and only the one or two that matter most.

**Callers**

- R4. Capture runs the rubric after `triage-gates.md` Steps 1 and 2 and before the body is shown for confirmation; a failed check shows the missing element and a drafted fix in the confirmation block.
- R5. `/self-org:tension-triage` names the failing checks when a body is not ready, and `[e] edit body` drafts its replacement to pass them.

**Lint**

- R6. A lint script reads one tension body and returns, per check, a verdict of `pass`, `teach`, or `ask`, plus an overall verdict.
- R7. T6 (topic first) and the length bound (1-5000 characters) are checked in code; T1-T5 are Jev Noul questions; T7 stays with the triage gate and is not linted.
- R8. A failed or refused API call is reported as an error with a non-zero exit, never as a `teach` or a `no`.
- R9. Question wording lives in one module section; thresholds and the decision table live in code.
- R12. Data boundary: the lint sends a tension body to TypeSafe only when a person runs it on that body. Capture and triage never call it. Its help text and the ADR state that the body and role name leave the machine for `api.typesafe.ai`. Run it only after `triage-gates.md` Step 2, so a person tension is never sent.
- R13. T6 (topic first) in code is a narrow structural rule, not a judgment: the first sentence is at most 200 characters and does not open with a narrative lead-in from a short fixed list ("I ", "We ", "So ", "Lately", "Recently"). A failure is `teach`. The capture and triage agents still judge T6 themselves; the code rule only catches the clear cases.

**Evidence**

- R10. An eval scenario holds four tension shapes: well-formed, thin (no instance), blended (two gaps), and proposal-in-disguise; eval cases assert that triage names the right failing check for each and leaves the well-formed one alone.
- R11. An ADR records the rubric and the Jev lint decision.

### Scope Boundaries

- Live probing of Jev against real tensions is deferred: `api.typesafe.ai` is blocked from this environment and no `TYPESAFE_API_KEY` exists. Thresholds stay at the TypeSafe skill's starting values until probed.
- Not built: running the lint in CI against the live API (needs a secret and spends money per PR; a nightly job can come later); running the lint from inside the capture subagent (the subagent reasons over the rubric itself; the lint is a separate, scriptable surface); a hard block on capture (settled, KTD3).

#### Deferred to Follow-Up Work

- Live probe of the five Noul questions on representative, hard, and negative tensions, then a threshold review.
- An in-meeting check of a GlassFrog draft (governance-decisions issue #14) can call this lint once a key is available.

---

## Planning Contract

### Key Technical Decisions

- KTD1. One shared rubric file, the twin of `project-well-formedness.md`, cited by capture, triage, and the lint (session-settled: user-approved — chosen over inline rules inside `tension-capture-flow.md`: one definition of "well-formed" across every surface).
- KTD2. Judgments from Jev, decisions in code: one atomic Noul per check, thresholds 0.7 (yes) and 0.3 (no), the band between is `ask` (session-settled: user-directed — chosen over a general LLM-graded rubric judge: calibrated, auditable judgments with logic testable in code).
- KTD3. Soft gate that teaches with a drafted fix (session-settled: user-approved — chosen over a hard block on capture: capture must stay cheap).
- KTD4. Python, using the `typesafe-sdk` package (0.7.5, verified from its wheel: `TypeSafeClient().system_one(state, questions={name: Noul(instructions=..., criteria={"true": ..., "false": ...})})`, answers at `.nouls[name].noul`, key from `TYPESAFE_API_KEY`, errors subclass `TypeSafeError`). The repo's scripts are Python and bash with no Node toolchain; adding Node for one script would add a runtime to CI. The SDK import is lazy and the client is injected, so the offline suite runs without the package installed.
- KTD5. Check outcome names are `pass`, `teach`, `ask`. They avoid the `needs-*` and `ready-for-*` prefixes that lint check 11 reserves for the triage-state list and the project rubric.
- KTD6. Rubric check IDs are `T1`-`T7`, mirroring the project rubric's `A1`-`B3` style, so callers cite them stably.

### High-Level Technical Design

Decision table per check (directional):

| Check | Source | yes (p ≥ 0.7) | between | no (p ≤ 0.3) |
|---|---|---|---|---|
| T1 gap stated | Noul | pass | ask | teach |
| T2 concrete instance | Noul | pass | ask | teach |
| T3 felt by the role | Noul | pass | ask | teach |
| T4 more than one gap | Noul (true = problem) | teach | ask | pass |
| T5 proposal with no gap | Noul (true = problem) | teach | ask | pass |
| T6 topic first | code | — | — | — |
| length 1-5000 | code | — | — | — |

Overall: any `teach` → `teach`; else any `ask` → `ask`; else `pass`. An API error ends the run with an error before any verdict is printed.

---

## Implementation Units

### U1. Eval scenario and cases (BDD first)

**Goal:** State the expected behavior before the rubric exists.
**Requirements:** R10.
**Dependencies:** none.
**Files:** `evals/scenarios/tension-well-formedness.json`, `evals/fixtures/glassfrog/tension-well-formedness.json` (generated), `evals/cases/tension-triage/evals.json`.
**Approach:**
1. Author a synthetic org (follow `evals/scenarios/blended-tension.json`) with four unprocessed tensions on roles the actor fills: well-formed, thin, two-gap, proposal-in-disguise.
2. Generate the fixture with `scripts/glassfrog-fixture-gen.py`.
3. Add one eval to the tension-triage cases: per tension, assertions on which rubric check the response names, plus the `no_writes` floor.
**Patterns to follow:** existing scenarios and the tension-triage case shape (`assertions[].discriminating`, `check.kind: no_writes`).
**Test scenarios:**
- The thin tension is flagged for a missing concrete instance (T2).
- The two-gap tension is flagged as holding more than one tension (T4).
- The proposal-in-disguise tension is flagged as a fix with no stated gap (T5).
- The well-formed tension is not sent back for an edit.
- No GlassFrog write is issued without per-item confirmation.
**Verification:** `bash scripts/evals-harness.test.sh` passes with the new fixture.

### U2. Shared rubric and caller wiring

**Goal:** One definition of well-formed, used by capture and triage.
**Requirements:** R1-R5.
**Dependencies:** U1.
**Files:** `skills/shared/tension-well-formedness.md` (new), `skills/shared/tension-capture-flow.md`, `commands/tension-triage.md`, `agents/tension-capture.md`, `CLAUDE.md` (shared-reference list).
**Approach:**
1. Write the rubric in the project rubric's shape: grounding, the seven checks each with a test, teaching behavior, the light-touch rule, what it does not do.
2. Capture flow: add the rubric as a soft check inside Step 4 (drafting), so no step is renumbered; show any failing check and its drafted fix in the Step 6 confirmation block.
3. Triage: cite the rubric as the standard for "well-formed" and for `[e] edit body`.
4. Add the file to CLAUDE.md's shared-reference notes.
**Patterns to follow:** `skills/shared/project-well-formedness.md`, `project-capture-flow.md` Family A soft gate.
**Test scenarios:** Test expectation: covered by `skills-lint.sh` (paths, step citations, orphans) and by U1's eval cases.
**Verification:** `bash scripts/skills-lint.sh` is clean; no cited step number changed.

### U3. Jev lint script and offline suite

**Goal:** Run the rubric's checks on a tension body from the command line.
**Requirements:** R6-R9, R12, R13.
**Dependencies:** U2 (check IDs and wording).
**Files:** `scripts/tension-lint.py` (new), `scripts/tension-lint.test.sh` (new), `.github/workflows/scripts-test.yml`.
**Approach:**
1. One module section holds the five Noul questions with true and false criteria, keyed by check ID.
2. Code checks length and topic-first, builds one `system_one` request with all five questions over a state of `{"tension_body": ..., "sensing_role": ...}`, maps probabilities through the decision table, prints JSON.
3. A `--fake-answers <json>` input replaces the client for tests; `--dry-run` prints the request payload without sending it.
4. Any exception from the client exits 2 with the error on stderr.
**Execution note:** write the bash suite first against the fake-answers seam.
**Patterns to follow:** existing `scripts/*.test.sh` suites and their wiring in `scripts-test.yml` (`test-wiring-check.sh` enforces it).
**Test scenarios:**
- All five probabilities clearly yes (T4 and T5 clearly no) gives overall `pass`.
- T2 at 0.1 gives T2 `teach` and overall `teach`.
- T1 at 0.5 gives T1 `ask` and overall `ask` when nothing teaches.
- T4 at 0.9 (two gaps) gives `teach`.
- An empty body and a body over 5000 characters fail in code without any API request.
- A client error exits 2 and prints no verdict.
- `--dry-run` prints five Noul questions and the state and sends nothing.
- Boundary: exactly 0.7 and exactly 0.3 map to yes and no.
- T6: a body whose first sentence is over 200 characters gives T6 `teach`; one that opens "Lately," gives `teach`; "Vendor approval stalls on Operations Circle. ..." gives `pass`.
- `--help` names `api.typesafe.ai` as where the body is sent.
**Verification:** `bash scripts/tension-lint.test.sh` passes offline; `bash scripts/test-wiring-check.sh` passes.

### U4. ADR

**Goal:** Record the decision.
**Requirements:** R11.
**Dependencies:** U2, U3.
**Files:** `docs/adr/0024-tensions-are-checked-for-well-formedness-by-one-rubric.md`.
**Approach:** context, decision (KTD1-KTD4), alternatives rejected, consequences (unprobed thresholds, key and network needed for live use, the R12 data boundary: tension text goes to a third party only on a person's explicit run).
**Test scenarios:** Test expectation: none -- documentation.
**Verification:** follows the ADR-0023 format.

---

## Verification Contract

- `bash scripts/skills-lint.sh --base origin/main`
- `bash scripts/skills-lint.test.sh`
- `bash scripts/evals-harness.test.sh`
- `bash scripts/test-wiring-check.sh`
- `bash scripts/tension-lint.test.sh`
- Graded behavioural eval runs nightly; not run here.

## Definition of Done

- All Verification Contract commands pass locally.
- No step number cited elsewhere changed.
- The lint never makes a network call in the test suite.
- No abandoned-attempt code in the diff.

### Assumptions

- The `typesafe-sdk` 0.7.5 surface read from its wheel matches the live API; not probed.
- The 0.7 / 0.3 thresholds are starting values from the TypeSafe skill, not tuned.

### Deferred / Open Questions

- Open (for Kraig, not blocking the build): is sending tension text to TypeSafe acceptable for every circle, or only for circles he fills? R12 limits sending to an explicit run; a wider policy is his call.
