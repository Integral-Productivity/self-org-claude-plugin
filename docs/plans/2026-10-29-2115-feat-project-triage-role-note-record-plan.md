---
title: Project Triage Pass Record as a Role Note - Plan
type: feat
date: 2026-10-29
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Project Triage Pass Record as a Role Note - Plan

---

## Goal Capsule

- **Objective:** A role holder who opens a role in GlassFrog can see what the last triage pass did to that role's projects, and why, without looking in a second tool.
- **Means:** `/self-org:project-triage` gains an end-of-pass step that drafts one role note per triaged role and writes it with `glassfrog_create_role_note` on confirmation (KTD1 to KTD4).
- **Authority:** Issue #427. ADR-0018 still bounds what triage may judge; ADR-0019 and ADR-0022 still bound what it writes on a project.
- **Execution profile:** markdown command and shared reference, the eval stub, one eval case file, and the existing offline suites. Test it like code (CLAUDE.md § Testing the skills).
- **Stop conditions:** stop and report if `glassfrog_create_role_note` is missing from `evals/glassfrog-tools.tsv` (lint check 9 would fail). After the first graded run that includes the new assertions, read their `without_skill` result and relabel any `discriminating: true` assertion that passed there.
- **Finish and ship:** `lfg` opens the PR with `Closes #427`; Kraig merges.

---

## Product Contract

### Summary

At the end of a triage pass that wrote at least one project, draft one GlassFrog role note per role whose projects were written, show it, and write it on confirmation. The note is the pass record. A drive file is at most a copy. A pass with no project writes writes no note.

### Problem Frame

`/self-org:project-triage` leaves a note line on each project it routes, but no record of the pass as a whole. Scheduled triage runs fill that gap with a markdown report in a shared drive, which role holders do not see when they look at the role in GlassFrog, and which the next triager must find in another tool (#427).

### Requirements

- R1. After the walk, for each role with at least one confirmed project write in this pass, triage drafts one role note.
- R2. Title: `<YYYY-MM-DD HH:MM local> — project triage`, from a real clock at draft time.
- R3. Body (markdown): scope (projects read, already triaged and skipped, newly triaged); one table row per walked project (project link, state or status applied, why, follow-ups); findings; observations.
- R4. The draft is shown and written only on the user's confirmation, one role at a time, like every other write in the command.
- R5. A pass with no confirmed project writes writes no note. A role with no confirmed writes gets no note.
- R6. A role the actor does not fill gets its note as a draft for the owner, never a write (the command's "write only what the actor owns" rule).
- R7. An unattended run writes the note only where its routine's policy allows that write, as for the state tag; otherwise the note stays a draft in the run's report.
- R8. A drafted follow-up action names no person, unless that person holds knowledge outside the role.
- R9. A drive file, if any, is a copy of the note, never the record.
- R10. `self-org-coach` keeps `glassfrog_create_role_note` disallowed.

### Key Decisions

- **The pass record is a GlassFrog role note.** (session-settled: user-directed — chosen over a markdown report in a shared drive: the record stays with the role in the system of record.) Governs R1, R9.
- **Fixed title and body shape.** (session-settled: user-directed — chosen over a free-form summary: issue #427 specifies it.) Governs R2, R3.
- **Draft, show, write on confirmation; no note without writes.** (session-settled: user-directed — chosen over auto-write: matches the command's safeguard.) Governs R4, R5.
- **Unattended runs follow routine policy.** (session-settled: user-directed.) Governs R7.
- **Follow-ups name no person.** (session-settled: user-directed.) Governs R8.
- **Coach stays read-only.** (session-settled: user-directed — chosen over granting the tool to the coach: the coach is read-only.) Governs R10.

### Scope Boundaries

- No change to the per-project note line, the write pair, or the state list.
- No new lint check; no change to `agents/self-org-coach.md`.
- No update of an earlier pass's note: each pass writes a new note.
- Considered and not built: one note for the whole pass across roles. A note lives on one role, and role holders look at their own role.

### Deferred to Follow-Up Work

- A routine that runs project triage unattended does not exist in this repo yet; R7 states the rule it must follow.

### Sources

- Issue #427.
- `commands/project-triage.md` — steps 6 to 8 and the safeguard.
- `skills/shared/project-triage-gates.md` Step 6 — note-line clock rule the title reuses.
- `skills/shared/agentic-routines.md` — routines draft for human review.
- `glassfrog-mcp-server/src/tools/notes.ts` — `glassfrog_create_role_note(role_id, title, body, view)`.

---

## Planning Contract

### Key Technical Decisions

- KTD1. A new step 8 "Record the pass on each role" sits after the write step and before the summary, which becomes step 9. Nothing cites the command's step numbers (checked by grep), so renumbering is safe.
- KTD2. The record format is defined once, in a new `### The pass record` subsection under Step 6 of `skills/shared/project-triage-gates.md`, next to the note line it summarises. The command cites it.
- KTD3. "Findings" replaces the issue's "lens findings". Triage runs no critic lens (ADR-0018), so the section holds the rubric Family A findings named during the pass, any `[r]` hand-off to `/self-org:review-project`, and its result when known. Conflict call-out: the issue asks for "lens findings"; workable as a findings section, and a lens finding appears only when an `[r]` review produced one.
- KTD4. The note is written once per role after that role's project writes, with `glassfrog_create_role_note(role_id, title, body)`, no `view` (GlassFrog default). Project links use the project's `web_url` when present.
- KTD5. The eval stub accepts `glassfrog_create_role_note` as a write, so eval 1 can check off the write log that a note is written on the Operations Steward role after the project writes. Eval 0 already asserts `no_writes`, which covers "no note without writes".

### Assumptions

- The live API accepts a markdown table in a note body (the tool documents `body` as markdown).

---

## Implementation Units

### U1. Pass record format and the new command step

**Goal:** The command drafts and writes a role note per triaged role.

**Requirements:** R1 to R9; KTD1 to KTD4.

**Dependencies:** none.

**Files:**
- `skills/shared/project-triage-gates.md`
- `commands/project-triage.md`

**Approach:**
1. Gates Step 6: add `### The pass record` with title rule, body template, the no-writes rule, the owner rule, and the follow-up naming rule; add a row to the outputs table.
2. Command: frontmatter description gains one clause; new step 8; summary becomes step 9 and reports notes written and drafted; safeguard text and Behaviour gain the record rule and the unattended rule.

**Test scenarios:**
- Lint check 1 resolves any new backticked path; check 2 resolves any new `Step N` citation; check 9 finds `glassfrog_create_role_note` in the inventory.

**Verification:** `bash scripts/skills-lint.sh` clean.

### U2. Stub and eval coverage

**Goal:** The role-note write is checked mechanically.

**Requirements:** R1, R4, R5; KTD5.

**Dependencies:** U1.

**Files:**
- `evals/stub/glassfrog_stub.py`
- `evals/cases/project-triage/evals.json`

**Approach:**
1. Add `glassfrog_create_role_note` to `WRITE_TOOLS` and its id prefix to the create branch.
2. Eval 1: add `write_present` for a role note on the Operations Steward role, and `write_ordering` with the supplier-sheet tag write before the note. Update the file's `note`.

**Test scenarios:**
- `bash scripts/run-behavioural-eval.test.sh` and `bash scripts/evals-harness.test.sh` pass.
- The stub records a `glassfrog_create_role_note` call in its write log (covered by the runner suite's stub path).

**Verification:** offline suites green.
