---
title: File-based self-org record as a second backend - Plan
type: docs
date: 2026-11-19
topic: file-record-strategy-adr
execution: code
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-brainstorm
---

# File-based self-org record as a second backend - Plan

## Goal Capsule

- **Objective:** A Holacracy practitioner who does not use GlassFrog can run their organization with the self-org plugin from plain files they own.
- **Means:** One strategy ADR that makes an open, user-owned file record a second backend behind the ADR-0005 seam, plus the matching STRATEGY.md edit.
- **Product authority:** This plan covers the decision only. The verb contract, the file MCP server, the GlassFrog export, the conformance suite, the SessionStart detection hook and the ontology content are later work (ideation ideas 2 to 7).
- **Execution profile:** One pull request on `claude/project-thread-ilai6v`, opened ready for review with a hold-for-review label. Auto-merge stays off after every push, because `claude/*` branches auto-merge on green CI and this PR changes strategy.
- **Who finishes:** Claude writes, tests and opens the PR. Kraig reviews and merges.
- **Stop conditions:** Stop and ask if the leak-denylist scan flags any file, if an open PR already claims ADR-0030, or if STRATEGY.md's record-keeping line differs from the text quoted in KTD3.
- **Open blockers:** None.

## Product Contract

### Summary

Write one ADR that amends ADR-0005: a file-based org record becomes a second backend beside GlassFrog, behind the same seam.
The file format is open and owned by the user, and the `/self-org/` ontology defines it in a new `self-org-ontology` repository.
STRATEGY.md stops ruling out every record format and rules out only a hosted record-keeping system.

### Problem Frame

Today every plugin command assumes GlassFrog.
A practitioner outside Integral Productivity declined GlassFrog because its cost was higher than the value they expected, and asked to organize through local files instead.
STRATEGY.md's "Not working on" list forbids the plugin from building its own governance record-keeping system, so the request has no approved path.
The ADR-0005 seam that would let a second backend in has worn away: about 50 shipped files name `glassfrog_*` tools directly.

### Requirements

**The decision**

- R1. The ADR amends ADR-0005 so that a file-based org record is a second backend behind the same seam, and GlassFrog stays the first backend.
- R2. The ADR states that the file record is an open format the user owns: plain files in a folder the user controls, readable without the plugin.
- R3. The ADR names the `/self-org/` ontology (a JSON-LD context plus SHACL shapes) as the definition of the file format.
- R4. The ADR states that the user writes and reads plain markdown with frontmatter, and the ontology check runs without the user seeing JSON-LD or SHACL.

**Strategy and authority**

- R5. STRATEGY.md's "Not working on" line about record-keeping changes to rule out a hosted record-keeping system only, and links the new ADR.
- R6. The ADR states that a file backend gives the plugin no new authority: governance changes in files still need human adoption under ADR-0025.

**Evidence and review**

- R7. The ADR names its first consumer as an outside practitioner who declined GlassFrog on cost, with no name or other identifying detail (ADR-0017).
- R8. The ADR sets a 90-day leading test: the first consumer runs one circle from files with the plugin and no GlassFrog.
- R9. The ADR sets a 90-day lagging test: the same plugin commands give the same answers on the file backend and on GlassFrog, checked by a conformance suite.
- R10. The ADR states what happens if the leading test fails: the ADR is superseded and STRATEGY.md returns to its earlier line.

**Consequences**

- R11. The ADR lists the follow-on work as consequences, each to be tracked as an issue: the verb contract, the file MCP server, removing direct `glassfrog_*` names from shipped files, the GlassFrog export, the conformance suite and the SessionStart detection hook.
- R12. The ADR states that the ontology lives in a new `self-org-ontology` repository and the plugin pins a version of it.

### Key Decisions

- KD1. Files are a second backend, not the native record (session-settled: user-approved — chosen over "files become the native record, GlassFrog an adapter" and over "trial ADR with no strategy change": smallest strategy change that meets the first consumer's need).
- KD2. The ontology prefix is `/self-org/` (session-settled: user-approved — chosen over the `/holacracy/` prefix ontology-hub reserves: ADR-0020 bars the trademark from shipped names).
- KD3. The ontology lives in its own `self-org-ontology` repository (session-settled: user-approved — chosen over keeping it inside the plugin repo: follows the ontology-hub and metawork-ontology pattern and serves a later Solid app).
- KD4. The first consumer is an outside practitioner who declined GlassFrog on cost (session-settled: user-approved — chosen over Integral Productivity dogfooding: this is the only confirmed external demand).
- KD5. The first consumer's use is the leading test and backend parity is the lagging test (session-settled: user-directed — the user picked both measures and named which leads).

### Acceptance Examples

- AE1. **Covers R5.** **Given** the merged ADR, **when** a reader opens STRATEGY.md "Not working on", **then** the record-keeping line rules out a hosted system only and links the ADR.
- AE2. **Covers R7.** **Given** the merged ADR, **when** `scripts/leak-denylist-scan.py` and a reviewer read it, **then** no person's name or org detail of the first consumer appears.
- AE3. **Covers R6.** **Given** a governance edit written to a file, **when** the ADR is applied, **then** the edit counts only after human adoption, as with GlassFrog.

### Scope Boundaries

- Not in scope: building the verb contract, the file MCP server, the export, the conformance suite or the hook.
- Not in scope: writing ontology classes or shapes, registering `/self-org/` in ontology-hub, or settling the reserved `/holacracy/` prefix. These belong to the ontology repository's first ADR.
- Not in scope: creating the `self-org-ontology` repository.
- Not in scope: Solid app work.

### Dependencies / Assumptions

- The first consumer can read and edit markdown files in a folder (assumption, not yet checked with them).
- metawork-ontology ADR-0003 asks every new ontology to name a consumer and a 90-day decision in its first ADR; R7 to R10 give the ontology repository those inputs.
- Risk: metawork-ontology ADR-0003 Amendment 1 schedules a 2027-01-02 review of whether parallel ontology tracks cost results. A new track started now falls inside that review.

### Outstanding Questions

- Resolved in planning: the ADR is ADR-0030 and ADR-0005's status gains an "Amended by" line (KTD1).
- Resolved in planning: the STRATEGY.md edit carries a fitness function, lint check 20 (KTD4).

### Sources / Research

- Ideation: docs/ideation/2026-11-19-file-based-self-org-record-ideation.html (idea 1).
- Ontology spike: a generic JSON-LD lift of markdown frontmatter, validated with SHACL, passed 4 of 4 cases on a scenario converted from evals/scenarios/authority-already-held.json. Gaps found: domains need identifiers, role fillers need a membership model, tension status and timestamps are not mapped.
- Holons (holons.io): no governance ontology; it aligns with ValueFlows and Murmurations, which stay alignment targets for the ontology.
- ADR-0005, ADR-0017, ADR-0020, ADR-0025; STRATEGY.md "Not working on".

---

## Planning Contract

Product Contract preservation: Product Contract unchanged. One pronoun in Dependencies / Assumptions became neutral wording, and the two deferred questions are now marked resolved.

### Key Technical Decisions

- KTD1. **The ADR is `docs/adr/0030-a-file-record-is-a-second-backend.md`, and ADR-0005's Status gains "Amended by ADR-0030".** ADR-0028 and ADR-0029 are on `main` and no open PR claims 0030. The amend wording follows ADR-0019 and ADR-0029: the new ADR opens its Status with "Amends ADR-0005: …" and the old ADR keeps "Accepted" and adds one "Amended by" line. Governs R1.
- KTD2. **The ADR is Accepted on the decision date. Its 90-day test starts on the day the first user runs a circle from files** (user-approved 2026-11-21, replacing "90 days from approval": the test should measure whether files work for that user, not how fast the build went). The Status line says "Review 90 days after the first circle runs from files". When that date is known, a one-line edit records the start and review dates. R10's supersede rule sits in the Consequences section. Governs R8, R9, R10.
- KTD3. **STRATEGY.md changes one line and adds no other text.** The current line reads "Building our own governance record-keeping system — we connect to existing ones (GlassFrog today) through a connector seam, not replace them." The new line rules out a hosted record-keeping service and links ADR-0030 by relative path. Governs R5.
- KTD4. **The fitness function is lint check 20: no ADR that STRATEGY.md links is Superseded** (session-settled: user-approved — chosen over no fitness function: Kraig's rule requires one for every key-reference edit, and this one makes R10's revert enforceable). It lives in `scripts/skills-lint.sh` beside checks 1 to 19, reads ADR links from STRATEGY.md, and fails when a linked ADR's Status section (from `## Status` to the next heading) contains the phrase "Superseded by". Unresolved links stay check 1's job, so check 20 does not repeat it. Repo Status lines open with "Accepted (...)" and append relationships, so a prefix test would miss real supersession. It extends the existing per-check pattern (`skipped N`, `finding N`) and adds no new script. Governs R5, R10.
- KTD5. **Follow-on work is tracked as 7 GitHub issues filed before the PR opens, and the ADR links them by number** (session-settled: user-approved — chosen over listing the work in prose only). The 6 R11 consequences get one issue each, and an eighth issue anchors this PR. Creating the `self-org-ontology` repository is the 7th issue, filed in this repo because the new repo does not exist yet. Governs R11, R12.
- KTD6. **The ideation file ships in the same PR as the ADR's source** (session-settled: user-approved — chosen over leaving it uncommitted). `docs/ideation/2026-11-19-file-based-self-org-record-ideation.html` is already staged. It must pass the leak-denylist scan like every other tracked file.

### Assumptions

- The ideation HTML holds no name of the first consumer. It was written before the name was known. U4 checks this with the scan and a text search.
- The `claude/*` auto-merge job re-enables auto-merge on each push, as seen on PR #419. The PR therefore needs the hold label at creation and auto-merge turned off after every push.

### Sequencing

Issues come first, because the ADR cites their numbers. The lint check comes before the STRATEGY.md edit, so the edit is proven by a check that already exists. The ADR and ADR-0005 change together, because each links the other.

---

## Implementation Units

### U0. Branch from current main

- **Goal:** work on the real check numbering and ADR list.
- **Approach:** `git fetch origin`, then create `claude/project-thread-ilai6v` from `origin/main`, carrying the staged ideation HTML and this plan file. The local `main` checkout is behind and stops at check 14 and ADR-0027.
- **Test scenarios:** `grep '# Check 19 --' scripts/skills-lint.sh` matches; `grep '# Check 20 --'` does not; `docs/adr/0029-*` exists and `docs/adr/0030-*` does not.

### U1. File the anchor issue and the 7 follow-on issues

- **Goal:** Every piece of follow-on work, and this PR itself, has a tracked issue number before any file changes.
- **Requirements:** R11, R12; KTD5.
- **Dependencies:** None.
- **Files:** None in the repo.
- **Approach:**
  1. File the anchor issue: decide that a file-based org record is a second backend (ADR-0030). It carries the `enhancement` label.
  2. File one issue each for the verb contract, the file MCP server, removing direct `glassfrog_*` names from shipped files, the GlassFrog export, the conformance suite, and the SessionStart detection hook.
  3. File one issue for creating the `self-org-ontology` repository, with the `/self-org/` prefix, KD3, and metawork-ontology ADR-0003's first-consumer rule in its body.
  4. Each follow-on issue links the anchor issue and the ideation idea it comes from. No issue names the first consumer.
- **Patterns to follow:** `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md` for labels. Follow-on issues start as `needs-triage`.
- **Test scenarios:** Test expectation: none -- issue filing changes no repo behavior.
- **Verification:** 8 issue numbers exist and each follow-on issue links the anchor issue.

### U2. Add lint check 20 and its mutation cases

- **Goal:** CI fails when STRATEGY.md links an ADR that is superseded.
- **Requirements:** R5, R10; KTD4.
- **Dependencies:** None.
- **Files:**
  - `scripts/skills-lint.sh` (new `check_strategy_adrs`, header `# Check 20 --`, call added after `check_design_checklist`)
  - `scripts/skills-lint.test.sh` (new cases for check 20)
  - `CLAUDE.md` (one clause in the § Testing the skills check list)
- **Approach:**
  1. Read relative links to `docs/adr/NNNN-*.md` from STRATEGY.md. A STRATEGY.md with no ADR links passes.
  2. For each link that resolves (check 1 covers links that do not), fail when its Status section contains "Superseded by".
  3. Report with `finding 20 STRATEGY.md "<message>"`, so the message names the ADR.
- **Execution note:** Write the failing mutation cases in `scripts/skills-lint.test.sh` first, then the check.
- **Patterns to follow:** check 19 (`check_design_checklist`) for shape, and its cases near `scripts/skills-lint.test.sh:791` for the test fixture style. CLAUDE.md requires that every check have a mutation case that fails with the check on and passes with `SKILLS_LINT_SKIP=20`.
- **Test scenarios:**
  - A STRATEGY.md linking an existing Accepted ADR passes check 20.
  - A STRATEGY.md linking an ADR whose Status reads "Accepted (2026-01-01). Superseded by ADR-0031." fails check 20, and the finding names the ADR.
  - A STRATEGY.md linking an ADR whose Status begins "Superseded by ADR-0031" fails check 20.
  - The same superseded fixture passes with `SKILLS_LINT_SKIP=20`, which proves no other check covers it.
  - An ADR whose Status begins "Accepted" and later says "Amended by" passes, because amendment is not supersession.
  - A STRATEGY.md with no ADR links passes.
- **Verification:** `bash scripts/skills-lint.test.sh` passes, and the new cases fail when the check body is removed.

### U3. Write ADR-0030 and amend ADR-0005

- **Goal:** The decision is recorded as an Accepted ADR that amends ADR-0005.
- **Requirements:** R1, R2, R3, R4, R6, R7, R8, R9, R10, R11, R12; KTD1, KTD2; KD1 to KD5.
- **Dependencies:** U1 (issue numbers).
- **Files:**
  - `docs/adr/0030-a-file-record-is-a-second-backend.md` (new)
  - `docs/adr/0005-holacracy-identity-glassfrog-as-first-connector-behind-a-seam.md` (Status gains one line)
- **Approach:**
  1. Use the ADR shape of ADR-0029: title, Date, Status, Context, Decision, Consequences.
  2. Status: "Accepted (<decision date>, Kraig Parkinson). Amends ADR-0005. Review 90 days after the first circle runs from files." Consequences also says that supersession must write "Superseded by" in Status, so check 20 can see it.
  3. Context cites the cost-based demand without a name (R7), the eroded seam (about 50 files name `glassfrog_*` tools), and the STRATEGY.md line it changes.
  4. Decision states R1 to R4 and R6, and names W3C ORG, ValueFlows and Murmurations as alignment targets for the ontology.
  5. Consequences states R8 to R10 and lists the R11 and R12 work with the U1 issue numbers.
  6. Write for a public reader in neutral wording, with no live-org detail (ADR-0017).
- **Patterns to follow:** `docs/adr/0029-triage-states-are-org-tags-created-by-glassfrog-config.md` for the amend shape; `docs/adr/0019-the-triage-state-vocabulary-lives-in-the-plugin.md` for the "Amended by" line.
- **Test scenarios:**
  - Covers AE2. The leak-denylist scan passes on the new ADR, and a text search for the first consumer's name finds nothing in the diff.
  - Covers AE3. The ADR's Decision section says file governance edits count only after human adoption under ADR-0025.
  - Lint check 1 resolves every relative link in both ADRs.
- **Verification:** `bash scripts/skills-lint.sh` passes, and ADR-0005 and ADR-0030 link each other.

### U4. Edit STRATEGY.md and add the ideation source

- **Goal:** STRATEGY.md rules out only a hosted record-keeping service and points to ADR-0030.
- **Requirements:** R5; KTD3, KTD6.
- **Dependencies:** U2, U3.
- **Files:**
  - `STRATEGY.md` (one line in "Not working on")
  - `docs/ideation/2026-11-19-file-based-self-org-record-ideation.html` (already staged)
- **Approach:**
  1. Replace the record-keeping line per KTD3, with a relative link to ADR-0030.
  2. Commit the staged ideation file unchanged unless the scan in Verification flags it.
- **Test scenarios:**
  - Covers AE1. STRATEGY.md's "Not working on" line rules out a hosted record-keeping service and links ADR-0030.
  - Check 20 passes on the real STRATEGY.md.
  - Appending "Superseded by ADR-0099" to ADR-0030's Status in a scratch copy makes check 20 fail, which proves the R10 revert is enforced on the real files.
- **Verification:** `bash scripts/skills-lint.sh` and `bash scripts/evals-harness.test.sh` pass with the edit and the ideation file tracked.

---

## Verification Contract

| Gate | Command | Proves |
|---|---|---|
| Static lint | `bash scripts/skills-lint.sh --base origin/main` | Links resolve, check 20 passes, no version-bump or legacy-name finding |
| Lint suite | `bash scripts/skills-lint.test.sh` | Check 20 is load-bearing (fails on mutants, passes when skipped) |
| Leak guard | `bash scripts/evals-harness.test.sh` | No tracked file carries a denylisted value (runs `scripts/leak-denylist-scan.py`) |
| Shell lint | `shellcheck --severity` as pinned in `.github/workflows/scripts-test.yml` | The new lint function meets the pinned shellcheck |
| CI | The PR's required checks, including "Design checklist" | The PR body ticks the design-checklist box or states why it does not apply |

No behavioural eval applies: no skill, command or agent changes.

---

## Definition of Done

- U1 to U4 are done and each Verification line holds.
- ADR-0030 is in `docs/adr/`, Accepted with a review date, and ADR-0005 says "Amended by ADR-0030".
- STRATEGY.md's record-keeping line links ADR-0030, and check 20 guards it.
- The PR is open, ready for review, assigned to Kraig, labelled hold-for-review, with auto-merge off and "Closes #<anchor issue>" in its body.
- The diff names no first consumer, and has no experimental or abandoned code.
- The plan file is committed with the PR.

## Review record

Lite document review, 2026-11-21 (coherence, feasibility and scope-guardian lenses, one reviewer). Four findings applied:

1. Check 20 no longer tests for missing ADR files. Check 1 already fails unresolved links, so a missing-file mutation case could not pass with `SKILLS_LINT_SKIP=20`.
2. Check 20 looks for "Superseded by" anywhere in the Status section, because repo Status lines start with "Accepted (...)".
3. New U0: branch from `origin/main`, because the local checkout is behind.
4. The ADR is dated by the decision date, not the unknown merge date.

Residual (not a plan defect): the R8 and R9 90-day tests depend on 4 unbuilt follow-on issues. If they slip, R10 triggers by default. This is a prioritization choice for Kraig.

5. 2026-11-21: Kraig chose to start the 90-day test on the day the first user runs a circle from files (KTD2 updated). This removes the residual risk above.
