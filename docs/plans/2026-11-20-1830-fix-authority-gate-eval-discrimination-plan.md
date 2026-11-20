---
title: Authority-Gate Eval Discrimination - Plan
type: fix
date: 2026-11-20
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Authority-Gate Eval Discrimination - Plan

---

## Goal Capsule

- **Objective:** `tension-triage-0` (`authority-gate-fires-before-venue-routing`) can fail without the skill, while the skill's Step 1 authority gate (`skills/shared/triage-gates.md`) still reaches the right disposition.
- **Means:** a new synthetic scenario and fixture for eval 0 only, in which (a) the tension body is framed as a governance request and shares no key words with the role record, and (b) the prompt asks which meeting each tension should go to. The old fixture stays for eval 4 and the harness suite.
- **Authority:** issue #202 and the maintainer decision comment (2026-11-20): Option 1, raise the bar.
- **Execution profile:** one change set. Data and eval-case edits plus one generated fixture. No runner or stub change.
- **Stop conditions:** stop if the change would need a stub change that smooths a live-API defect, or real org data.
- **Finish and ship:** commit locally on the session branch; the daily bug-bash run verifies and opens the PR.

---

## Product Contract

### Summary

The case scored 5/5 in both arms on every graded run. #207 removed a tool-named domain; nothing changed. Make the case fail-able without the skill and keep the behaviour it tests.

### Problem Frame (evidence from the current files)

Two leaks survive #207:

1. **Lexical overlap between the tension and the role.** The tension says "restructure how intent is represented in the tool". Offer Design's accountability says "Deciding how product intent is represented in the roadmap tool". The answer is still reachable by string match, now against an accountability instead of a domain.
2. **The tension body hands over the conclusion.** "I have been holding it because it feels like the kind of change that ought to be agreed somewhere first" invites the reply "you do not need agreement". The prompt ("Walk me through what you find") does not pull the other way.

### Requirements

- R1. Eval 0 points at a new scenario and fixture: `evals/scenarios/authority-framed-as-governance.json` and its generated `evals/fixtures/glassfrog/authority-framed-as-governance.json`.
- R2. The authority-held tension reads as governance at first: it asks for a role or a policy, uses governance indicator phrasing from Step 3 ("no one owns", "we need a policy"), and proposes bringing it to a Governance Meeting.
- R3. The work the tension needs sits wholly inside a role the actor fills, through an accountability plus a domain, and the role record shares no content word with the tension body (no "roadmap", "intent", "tool", "represented").
- R4. The resolution does not constrain another role's domain, so a governance answer is wrong on the constitution and not a matter of taste (Article 1 action on an accountability; Article 4 domain control).
- R5. A genuinely governable tension stays in the fixture so the case still checks that the gate does not resolve everything (current assertion 4).
- R6. The prompt asks which meeting each tension should go to. It is natural language, identical across arms.
- R7. Assertions 1-4 are rewritten to name the new roles and tensions; they keep `discriminating: true`. Assertion 5 (`no_writes`) is unchanged.
- R8. `ground_truth` and the scenario `purpose` record the hypothesis, what #207 tried, and the next-graded-run test of it.
- R9. Eval 4 and `scripts/evals-harness.test.sh` keep `authority-already-held.json` unchanged.

### Scope Boundaries

- In: one new scenario, one generated fixture, eval 0 in `evals/cases/tension-triage/evals.json`.
- Out: `evals/benchmark.json` (re-seeded only from a real run), the stub, the runner, eval 4.
- Out: the post-run audit of `discriminating: true` claims (issue follow-on). Not required by the decision.

### Sources

- Issue #202 body and comments (2026-08-06, 2026-08-08, 2026-11-20).
- `skills/shared/triage-gates.md` Step 1 and Step 3 indicators.
- `evals/scenarios/authority-already-held.json` (records #207).

---

## Planning Contract

### Key Technical Decisions

- **KTD1 (session-settled, user-directed):** raise the bar; do not cut or reclassify.
- **KTD2 (session-settled, user-directed):** `no_writes` floor unchanged.
- **KTD3 (session-settled, user-directed):** synthetic data only (ADR-0017).
- **KTD4 (planning):** a new scenario rather than editing `authority-already-held`. Eval 4 and the harness suite read the old fixture; editing it would change two other measurements.
- **KTD5 (planning):** the discrimination hypothesis is framing pressure plus no lexical bridge. Without the skill, a model asked "which meeting" for a tension that asks for a policy and says "no one owns" tends to answer with a venue. With the skill, Step 1 runs before Step 3 and reads the role record first.
- **KTD6 (planning):** the authority must be unambiguous on a careful reading, so a correct answer is defined. The role holds a domain over the artifact and an accountability for its upkeep; the tension's remedy changes only that artifact.

### Assumptions

- The fixture generator accepts the new scenario without schema changes (same entity types as the old one).
- The leak-denylist scan in `evals-harness.test.sh` covers new files automatically.

### Open Questions

- Whether the delta is above zero is known only after the next graded run. If it is zero, reopen the decision (cut, or reclassify as a floor), per the maintainer comment.

---

## Implementation Units

### U1. Scenario and fixture

- **Files:** `evals/scenarios/authority-framed-as-governance.json` (new), `evals/fixtures/glassfrog/authority-framed-as-governance.json` (generated).
- Synthetic org with a distinct name. Roles: circle, Circle Lead (actor), a role the actor fills that holds a domain over a shared artifact (for example a "Planning Board Layout" style domain renamed so it does not echo the tension) and an upkeep accountability, plus one role the actor does not fill.
- Tensions: (1) authority-held, governance-framed, no word overlap with the role record; (2) genuinely governable (no role holds the decision).
- Generate with `python3 scripts/glassfrog-fixture-gen.py evals/scenarios/authority-framed-as-governance.json`.

### U2. Eval case

- **Files:** `evals/cases/tension-triage/evals.json` (eval 0 only).
- New `fixture`, prompt per R6, `ground_truth` per R8, assertions per R7.

### U3. Verification

- `bash scripts/evals-harness.test.sh`, `bash scripts/run-behavioural-eval.test.sh`, `bash scripts/skills-lint.sh --base origin/main`, `python3 scripts/run-behavioural-eval.py --validate-only` is optional (needs the CLI).

---

## Verification Contract

- The three suites pass with `PATH=/usr/bin:$PATH`.
- Regenerating the fixture is byte-identical (harness determinism loop).
- A word-overlap check by hand: no content word of the authority-held tension appears in that role's purpose, accountabilities, or domains.

## Definition of Done

- R1-R9 met, suites green, one local commit (`test(evals):`) referencing #202, rationale ready for the PR body.
