---
title: Count unbound sessions as their own bucket in the grounding readout
date: 2026-11-23
type: feat
status: active
origin: https://github.com/Integral-Productivity/self-org-claude-plugin/issues/520
issues: [520]
product_contract_source: ce-plan-bootstrap
---

# Count unbound sessions as their own bucket in the grounding readout

## Goal Capsule

- Objective: the grounding experiment can tell a session that honestly said it could not ground from one that ignored the directive, so its results describe what sessions did.
- Means: `scripts/grounding-readout.sh` reports every session in exactly one grounding outcome (grounded, unbound, silent), split by how the directive reached it.
- Scope: the readout script, its test suite, and its consumers' suites staying green.
- Out of scope: the SessionStart hook and the directive text (ADR-0008 A3, A8); the fire-rate alarm's verdict logic; the session log (#71).

## Problem Frame

Since PR #519, a session that starts role resolution and cannot finish it writes one `Operating **unbound**: <gap>` line (`skills/shared/actor-and-role-resolution.md`, "Unattended Sessions and the Unbound State"). The readout counts only `Operating as **<role> of <circle>**` (`ANNOUNCE_RE`), so an unbound session and a silent session both read as "not announced". ADR-0008 A8 says an unbound line must not count as an announcement, and that the readout does not count it today. Issue #520 also carries #284's acceptance criterion 2: "unavailable" must be distinguishable from "skipped".

## Product Contract

- R1. Each scanned session falls in exactly one grounding outcome: **grounded** (a real role announcement), **unbound** (an `Operating **unbound**:` line and no role announcement), or **silent** (neither).
- R2. An `Operating **unbound**:` line never matches the announce pattern and never counts as grounded.
- R3. The outcome counts are reported per delivery path: directive fired, conditional form, and no directive record.
- R4. The readout states plainly what it cannot separate: a silent session after a conditional record is either "no GlassFrog tool was listed" or "a tool was listed and the session did not comply" (ADR-0008 A8).
- R5. The baseline note says it was taken on the old two-bucket measure (announced or not).
- R6. Existing JSON fields keep their names and meaning; new fields are additions. `grounding-fire-rate-check.sh` and other consumers keep working.
- R7. The in-repo cohort line reports the unbound count too.

## Planning Contract

Key technical decisions:

- KTD1. Third bucket, not a side count. session-settled: user-directed (Kraig, 2026-11-22, #520). Rejected: a separate count beside the headline. Reason: maintainer chose the bucket.
- KTD2. Baseline note names its measure. session-settled: user-directed (Kraig, 2026-11-22, #520). Rejected: leaving it unchanged. Reason: the measure changed.
- KTD3. No hook or directive change. session-settled: user-directed (Kraig, 2026-11-21, ADR-0008 A8). Rejected: an unbound line on the no-tool branch. Reason: the conditional record is that case's evidence.
- KTD4. Precedence when one session has both lines: grounded wins. A session can go unbound and later leave that state when `glassfrog_get_me` succeeds ("Leaving unbound" in the shared reference), then announce a role. Counting it as grounded keeps the buckets exclusive and keeps `resolve_announce` unchanged, so the delivery and behaviour windows (ADR-0008 A3, A4) stay comparable. The JSON adds `unbound_line.count` (every session with the line, whatever its outcome) so that case stays visible. Conflict call-out on KTD1: the brief says an unbound session is "never grounded"; this plan reads that as "an unbound line never makes a session grounded" (R2), which holds. A session that later announced a real role is grounded by its announcement, not by the unbound line.
- KTD5. Detect the unbound line with the same provenance rules as the announcement: assistant-emitted text only, skipping sidechain records and text that echoes the directive marker. Pattern: `Operating \*\*unbound\*\*:` (case-insensitive), anchored on the bold form and the colon so prose such as "operating unbound" or the reference's own quoted examples read from a file never score. A placeholder guard matches the announce path's `is_placeholder`: a match whose gap text (after the colon) is empty or contains `<`, `>`, `[`, `]`, `{` or `}` is a quoted template, not a stated gap, and does not score.
- KTD6. #284 AC2 is met as far as the transcript allows. Fired + unbound and conditional + unbound mean the session stated a gap in its grounding: a tool failure, several matching roles with nothing picking one, a named role that does not exist, or a role skill with no connector. That is distinguishable from silent. The readout does not split the gap's causes, and the table row and `limits` note say so; neither labels the bucket "unavailable" or "tool failed". Conditional + silent stays ambiguous, and the readout says so in a `limits` note in JSON and one line in the table. No inference fills that gap.
- KTD7. Leave CLAUDE.md "Measuring whether the grounding directive fired" unchanged: it describes delivery, `--since-start` and the in-repo line, none of which changes meaning. (Open area resolved.)

## Implementation Units

- U1. Tests first in `scripts/grounding-readout.test.sh`, new section 15 (sections 13 and 14 already exist):
  - 15a. A fired session with an unbound line and no announcement: outcome unbound, not grounded, not silent; `resolve_announce.count` unchanged.
  - 15b. A conditional-record session with an unbound line: unbound under the conditional column.
  - 15c. A conditional-record session with no line: silent under the conditional column, and the JSON `limits` note names the A8 ambiguity; the table shows the one-line limit.
  - 15d. A session with both an unbound line and a later real announcement: grounded; `unbound_line.count` counts it.
  - 15d2. A session that announces first and states an unbound line later: grounded, and `unbound_line.count` still counts it (guards the scan early exit).
  - 15e. An unbound line that is read (file-read attachment, or a sidechain record) or echoed with the marker does not score.
  - 15e2. An assistant that quotes the template `Operating **unbound**: <the gap, in one clause>.` stays silent (placeholder guard).
  - 15f. Pattern isolation: run the announce pattern over `Operating **unbound**: glassfrog_get_me failed (401)` and assert no match (R2), through the readout itself (a session with only that line scores zero announcements).
  - 15g. Baseline note in both outputs mentions the two-bucket measure.
  - 15h. The in-repo cohort reports its unbound count.
  - 15i. Outcome counts sum to sessions in each column (exclusivity).
  Confirm each fails on the current script before U2.
- U2. `scripts/grounding-readout.sh`: add `UNBOUND_RE` with the placeholder guard, return an `unbound` flag from `scan()` and add it to the early-exit condition so a line after the announcement is still read, tally `outcomes` per delivery path (fired / conditional / none) and `unbound_line`, add JSON fields `grounding_outcome` and `unbound_line` and `limits`, add a table block "grounding outcome" with the three rows and the limit line, update `BASELINE_NOTE` and the header comment's WHAT IT COUNTS list, add in-repo unbound.
- U3. Mutation check: for each new test, a targeted mutant of the script (drop the unbound branch, let unbound count as announce, break precedence, drop the limit note, revert the baseline note, drop the in-repo field) must fail the suite; restore after each.

## Verification Contract

- `bash scripts/grounding-readout.test.sh` passes; new cases fail against `origin/main`'s script.
- `bash scripts/grounding-fire-rate-check.test.sh`, `bash scripts/plugin-version-skew-check.test.sh`, `bash scripts/test-wiring-check.test.sh` pass (readout consumers).
- `bash hooks-handlers/session-start.test.sh`, `scripts/skills-lint.sh`, `scripts/skills-lint.test.sh`, `evals-harness.test.sh`, `run-behavioural-eval.test.sh`, `eval-report.test.sh`, `eval-cost.test.sh` pass.
- shellcheck 0.11.0 `--severity=style -x -P scripts scripts/*.sh scripts/lib/*.sh`: clean.
- PATH has the python3.12 shim first (the session-start suite's G27 needs it locally; CI is unaffected).

## Assumptions

- The fire-rate alarm keeps its verdict on delivery only; whether it should also watch the unbound rate is #527.
- Headless run: no scoping confirmation was shown; these assumptions stand in for it.

## Deferred / Open Questions

- Alarms on the unbound or announce rate: #527.
- Separating "no tool" from "ignored" after a conditional record needs a structured session record (#71).

## Definition of Done

R1 to R7 hold, every new test is mutation-checked, all suites listed above pass, and the commit says "Refs #520".
