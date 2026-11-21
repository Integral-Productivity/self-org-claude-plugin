---
title: Unattended Role-Grounding Branch - Plan
type: fix
date: 2026-11-20
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Unattended Role-Grounding Branch - Plan

---

## Goal Capsule

- **Objective:** A session that cannot complete role grounding (nobody present to answer, or a failed `glassfrog_get_me`) has a satisfiable instruction, and a reader of its transcript can tell "grounding was unavailable" from "grounding was skipped".
- **Means:** an unattended branch in `skills/shared/actor-and-role-resolution.md` that turns every "ask the user" step into one line naming the gap, then proceeds in a defined `unbound` state (KTD1, KTD2); both SessionStart directive forms point at it (KTD3).
- **Authority:** issues #284 and #334; the maintainer decision comment on #284 (2026-11-19) and the #334 acceptance criteria. ADR-0008 governs the directive (A3 first-line pin, invariant 4 no-question rule).
- **Execution profile:** one change set. Prose edits to one shared reference, two heredoc edits in one hook, new assertions in the hook's suite, one ADR amendment. Test first.
- **Stop conditions:** stop if the change would alter the directive's first line or the conditional form's first line, or would put a question mark in any SessionStart output.
- **Finish and ship:** commit locally on the session branch; the daily bug-bash run verifies and opens the PR with `hold-for-review`; the maintainer merges.

---

## Product Contract

### Summary

The role-grounding directive asks every session to resolve and announce a role. Its only fallback paths end in a question to the user. In an unattended session, or when `glassfrog_get_me` fails, nobody can answer, so the session either skips grounding silently or carries an open loop. Give those sessions a defined, stated outcome: `unbound`.

### Problem Frame

- #284: in a non-interactive session the directive has no satisfiable path. The resolution procedure's fallbacks (Step 1 failed `glassfrog_get_me`, Step 3 several matching circles, "When GlassFrog Data Is Unavailable") all ask the user. Proceeding without grounding is indistinguishable in the transcript from forgetting to ground.
- #334: neither directive form says what to do when `glassfrog_get_me` is listed but the call fails (expired claude.ai connector token, server error). A session may improvise a question, which ADR-0008 invariant 4 forbids.

### Requirements

- R1. The shared reference defines `unbound`: what it permits and what it forbids (for example, no GlassFrog writes that act from a role), and the one-line statement that marks it.
- R2. Step 1 (failed `glassfrog_get_me`) has an unattended branch: one line naming that grounding failed, no retry loop, no question, proceed unbound.
- R3. Step 3 (several matching circles) has an unattended branch: one line naming the ambiguity, proceed unbound.
- R4. "When GlassFrog Data Is Unavailable" has an unattended branch: one line naming the gap, proceed unbound.
- R5. Both directive forms (unconditional and conditional) in `hooks-handlers/session-start.sh` say that a failed `glassfrog_get_me` call means one line, no retry, no question, carry on unbound, and point at the unattended branch.
- R6. Both directive forms keep their first lines byte-identical (ADR-0008 A3, G16, G40) and contain no question mark (G22, `assert_conditional`).
- R7. `hooks-handlers/session-start.test.sh` asserts the unattended wording on both paths.
- R8. The interactive path is unchanged: when a person is present and a skill (not the session-start directive) runs the procedure, its existing asks remain.
- R9. ADR-0008 records that the body change closes and reopens the behaviour (`resolve+announce`) window; the delivery window survives.

### Scope Boundaries

- In: the shared reference, the two heredocs, the hook suite, ADR-0008 amendment.
- Out: a pre-declared default role (env var or config) — #339's job (settled decision 1).
- Out: changing `scripts/grounding-readout.sh` or the readout's bucket logic; first lines do not change, so the readout needs no change.
- Out: detecting unattended execution in the hook. The hook has no such signal (ADR-0008 A5/A7 record the search); the directive states the branch as a condition the session evaluates.

### Deferred to Follow-Up Work

- Measuring how often sessions state `unbound` (a readout bucket). Not required by either issue.

### Sources

- Issue #284 and its 2026-11-15 and 2026-11-19 comments; issue #334.
- `docs/adr/0008-*.md` A3, A5, A7; `docs/adr/0027-*.md` (binding sequence).

---

## Planning Contract

### Key Technical Decisions

- **KTD1 (session-settled, user-directed):** on an unattended path every "ask" becomes "name the gap in one line and proceed unbound". Rejected: a default-role env var (#339 owns that).
- **KTD2 (session-settled, user-approved):** a failed `glassfrog_get_me` means one line, no retry, no question, carry on — on the session-start directive path regardless of whether a person is present, because the directive fires before anyone has spoken and ADR-0008 invariant 4 forbids a question there. A skill a person invokes later still follows its interactive Step 1 ask (R8).
- **KTD3 (session-settled, user-directed):** first lines of both heredocs stay byte-identical; ADR-0008 gets amendment A8 recording the behaviour-window reopening.
- **KTD4 (planning):** "unattended" is defined in the reference as: no person can answer in this session (scheduled routine, headless or pipeline run, a session that started from a trigger), or you cannot tell. When unsure, treat as unattended — an unasked question costs less than an unanswered one.
- **KTD5 (planning):** the `unbound` line has a fixed lead, `Operating **unbound**:`, so it parallels `Operating as **Role of Circle**` and is greppable in transcripts. Directive text must avoid `?`.

### Assumptions

- The existing G-series numbering continues: new assertions are G41 onward.
- The shared reference carries no `version:` frontmatter; if `skills-lint.sh`'s version check maps shared-file changes to loading skills, bump those skills' versions as the lint directs.

### Open Questions

- None blocking.

---

## Implementation Units

### U1. Failing tests (test first)

- **Files:** `hooks-handlers/session-start.test.sh`
- **Scenarios:**
  - G41: authenticated path directive mentions a failed `glassfrog_get_me`, `no retry`, `unbound`, and names the unattended branch of the reference.
  - G42: conditional path (no credentials store) carries the same wording, still passes `assert_conditional` (no `?`).
  - G43: the reference file defines `unbound` (a heading containing "Unbound") and has an "unattended" branch in Step 1, Step 3 and the GlassFrog-unavailable section.
  - G16 and G40 still pass unchanged.
- Run the suite and confirm G41-G43 fail before U2/U3.

### U2. Shared reference

- **Files:** `skills/shared/actor-and-role-resolution.md`
- Add a "Unattended Sessions and the Unbound State" section (definition of unattended per KTD4; `unbound` permits/forbids; the one-line form per KTD5; how to leave it).
- Step 1, Step 3 table, and the unavailable section each gain an "Unattended:" line pointing at that section. Interactive wording stays.
- Update the "What the plugin does NOT do" bullet so it does not contradict the unattended branch.

### U3. Directive forms

- **Files:** `hooks-handlers/session-start.sh`
- Add one sentence to each heredoc body (not the first line) per R5. No `?`.

### U4. ADR-0008 amendment

- **Files:** `docs/adr/0008-*.md`
- Add A8 (2026-11-20, #284/#334): what changed, why, and that the behaviour window closes and reopens while the delivery window survives.

---

## Verification Contract

- `bash hooks-handlers/session-start.test.sh` passes (G1-G43).
- `bash scripts/skills-lint.sh` and `bash scripts/skills-lint.test.sh` pass.
- `shellcheck --severity=style -x -P scripts scripts/*.sh scripts/lib/*.sh` (0.11.0) passes; also run it on the two hook files.
- `bash scripts/grounding-readout.test.sh` (if present) passes, proving the marker derivation still works.

## Definition of Done

- R1-R9 met, suites green, one local commit (`fix:` Conventional Commit) referencing #284 and #334.
