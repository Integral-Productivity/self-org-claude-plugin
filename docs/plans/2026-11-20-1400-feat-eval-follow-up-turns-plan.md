---
title: "feat: scripted follow-up turns in behavioural eval cases"
type: feat
status: active
date: 2026-11-20
origin: https://github.com/Integral-Productivity/self-org-claude-plugin/issues/497
---

# feat: scripted follow-up turns in behavioural eval cases

## Summary

Let a behavioural eval case declare `follow_up_turns`: user messages the runner
sends, in order, after each turn ends. The runner resumes the same session with
`claude -p <turn> --resume <session_id>` in the same sandbox. Both legs get the
same turns. Project-triage eval 1 uses the field to answer the type-to-write
picker, so its write assertions measure something again.

## Problem frame

Graded run 44477285609 showed both legs of project-triage eval 1 stop at the
per-project confirmation. The write log stayed empty, so the #427 assertions
(the role-note pass record and its ordering) passed or failed on nothing
(evidence: #433 comment 7030007577). Since #464/#466, writes start only from a
confirmation the user gives after the draft is shown. A single `claude -p` turn
cannot give one.

## Requirements

- R1. A case file may carry `follow_up_turns`, a non-empty list of non-empty
  strings. `load_case_file` refuses any other shape.
- R2. The runner sends each turn, in order, to the same session after the
  previous turn ends, in the same sandbox (config dir and cwd).
- R3. Both legs (with_skill and without_skill) get the same turns.
- R4. A failed turn (no events, `is_error`, timeout, no `session_id`) stops the
  remaining turns and fails the run as an execution error.
- R5. The existing execution-failure rules hold over the whole session: shape
  on the first init event, contamination over every turn, and "no tool calls
  at all" is still a failure.
- R6. The transcript shows each follow-up user turn, so the grader sees what
  the user said.
- R7. Cost and token figures count every turn, not only the last.
- R8. A case without the field runs exactly as before (one invocation, same
  events, same cost record shape).
- R9. Offline coverage in `run-behavioural-eval.test.sh`, with a mutation case
  that proves the runner really sends the turns.
- R10. `--validate-only` keeps working, and validates the new field.

## Key technical decisions

- KTD1. The eval answers the picker with a scripted follow-up turn.
  (session-settled: user-approved — chosen over making the skill accept a
  confirmation given in advance in the prompt: keeps the #464/#466
  type-to-write safeguard.)
- KTD2. The same follow-up turns go to both legs.
  (session-settled: user-approved — chosen over with_skill only: the control
  must get the same chance to write, or the delta measures the turn, not the
  plugin.)
- KTD3. Transport is `--resume <session_id>` with `-p`, not stream-json input.
  Each turn is one more process with the same flags. The session store lives in
  `CLAUDE_CONFIG_DIR`, so the sandbox is kept until the last turn. Stream-json
  input would need the runner to detect "turn ended, waiting" mid-stream; the
  `result` event at process exit already marks that.
- KTD4. Turns are sent unconditionally, in order. The runner does not try to
  detect whether the model asked a question. A surplus turn after the work is
  done costs one short model turn; a missing turn leaves writes unmeasured.
- KTD5. Multi-turn cost is summed across the turns' `result` events (numbers
  recursively; first non-number value kept) and the record gets `"turns": N`.
  A single-turn run keeps its verbatim, unsummed record (R8).
- KTD6. The per-turn timeout is the existing `--timeout`; the whole session can
  take up to `(1 + turns) × timeout`.
- KTD7. Eval 1's turns say "Yes, apply your recommended key for this one." five
  times (three project writes, one possible survivor route, one pass-record
  note). Words, not a bare letter, because the walk order is the model's and
  the key differs per project (`[w]`, `[c]`, `[a]`).

## Assumptions

- The CLI emits `session_id` on the init and result events of a `-p`
  stream-json run, and `--resume <id>` with `-p` continues that session from
  the store under `CLAUDE_CONFIG_DIR` (`claude --help` lists `-r, --resume`).
  The first real graded run checks this; the offline fake models it.
- A follow-up turn given in words after the draft is shown counts as the
  per-project confirmation the command requires (`commands/project-triage.md`
  "Draft, show, then write one project at a time").

## Implementation units

- U1. **Case schema.** `load_case_file` validates `follow_up_turns`.
  `evals/README.md` documents the field next to `extra_tools`.
  Test: a case with `follow_up_turns: "w"` or `[""]` is refused.
- U2. **Runner.** `execute(..., follow_ups=())` runs the first turn, then each
  follow-up with `--resume`, keeping the sandbox. A per-turn error check stops
  the loop. A synthetic `follow_up` event marks each turn for the transcript.
  `render_transcript` renders it. `usage_tokens`/`raw_usage` sum across turns.
  `run_once` passes the case's turns.
  Tests: §17 in the suite — a two-turn fake plan whose writes happen only in
  turn 2; the write log holds them, the transcript names the turn, cost counts
  both turns, both legs got the turn, the resumed call reused the first
  session's config dir. A turn that fails stops the run with an execution
  error. A case without the field emits one invocation.
- U3. **Fake executor.** On `--resume <id>`, the fake checks that its session
  file exists in `CLAUDE_CONFIG_DIR` (else an `is_error` result, as the real
  CLI does for an unknown session), reads the turn index, and replays
  `leg["turns"][index]`. It emits `session_id` on init and result.
- U4. **Mutation case.** Mutate the runner so it skips follow-up turns; the
  §17 write assertion must go red.
- U5. **Eval 1.** Add `follow_up_turns` to project-triage eval 1.

## Risks

- The graded budget (`scripts/eval-graded-budget.sh`) prices each leg at a flat
  minutes-per-execution rate. Eval 1 now runs six turns per leg, so the first
  graded run may take longer than the budget assumes. Residual: measure on the
  next graded run and file a follow-up if the budget needs a per-turn term.
- If the real CLI's resume behaviour differs from the fake, the first graded
  run fails eval 1 with an execution error rather than a vacuous pass (R4).

## Verification

`bash scripts/skills-lint.sh`, `bash scripts/run-behavioural-eval.test.sh`,
and `python3 scripts/run-behavioural-eval.py --out /tmp/probe --validate-only
--case evals/cases/project-triage/evals.json`.
