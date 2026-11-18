---
title: Graded Eval Cadence and Cache-Aware Budget - Plan
type: fix
date: 2026-11-18
artifact_contract: ce-unified-plan/v1
product_contract_source: ce-plan-bootstrap
execution: code
---

# Graded Eval Cadence and Cache-Aware Budget - Plan

---

## Goal Capsule

- **Objective:** A maintainer who changes a skill gets a behavioural measurement of it by the next morning, and a weekly measurement with run-to-run variance, without paying for model calls on nights when nothing the evals measure has changed.
- **Means:** a nightly run at `runs=1` and a weekly run at `runs=3` (KTD1), a budget check that prices only the legs the cache will not skip (KTD2), and a skip when that count is zero (KTD3).
- **Authority:** issue #467 and the maintainer's three decision-card answers of 2026-11-18. ADR-0012 still governs the tiers: nothing here moves a paid check onto pull requests.
- **Execution profile:** one PR. A new runner flag, one new offline-tested shell script with its suite wired into `scripts-test.yml`, and edits to `skills-eval.yml`. Test it like code (CLAUDE.md § Testing the skills).
- **Stop conditions:** stop and report if computing the fresh-leg count needs anything the graded job does not already have before the eval step (an API key, a model turn). Stop if a change would add a second `timeout-minutes:` to `skills-eval.yml`.
- **Finish and ship:** `lfg` opens the PR with `hold-for-review`; the maintainer merges.

---

## Product Contract

### Summary

The nightly graded eval has refused its own default `runs=3` every night since about 2026-10-09, because the case count grew from 4 to 10 and the wall-clock ceiling fell to 2. Fix it by running nightly at one run and weekly at three, by pricing only the legs that will execute, and by skipping the job when no leg would execute.

### Problem Frame

The `graded` job derives a `runs` ceiling as `(timeout − overhead) ÷ (minutes per execution × evals × configs)`. With 10 evals that is `80 ÷ 40 = 2`. Both the schedule and the dispatch default to 3, so every nightly run exits in about 40 seconds with an error and no model call. Nothing has measured a skill change since then, and #173 and #433 wait on a working run.

The ceiling also prices every leg as fresh, although the change-aware cache (`--cache-index`) skips legs whose key has not changed. On a night with no change, the guard can refuse a run that would execute nothing, and a run that does execute nothing produces no `grading.json` for the aggregator.

### Requirements

- R1. A scheduled nightly run uses `runs=1`.
- R2. A scheduled weekly run uses `runs=3`, on a day the nightly does not run, so the two never queue behind each other.
- R3. A `workflow_dispatch` run keeps its `runs` input, default 3.
- R4. The `runs` ceiling is computed from the number of legs that will execute (cache misses), not from every leg.
- R5. When no leg would execute, the job reports a skip in a notice and the step summary, runs none of the eval, aggregate, report, upload or cache-push steps, and exits green.
- R6. The existing guards still hold: the spend cap of 10, the single `timeout-minutes:`, the integer check on `runs`, the session-shape probe, and the pinned model.
- R7. The budget decision is testable offline, with a mutation case per check.

### Scope Boundaries

- No change to which model runs, to the grader, or to the cache key inputs.
- No re-seed of `evals/benchmark.json`.
- No change to the 7-day cache expiry.

### Deferred to Follow-Up Work

- Re-seed `evals/benchmark.json` on all 10 evals from one `runs=3` dispatch after this merges (issue #467 acceptance list).
- Pin the Claude Code CLI version in the graded job. The CLI version is a cache-key input and the job installs the latest CLI each night, so a new CLI release invalidates every leg. Until it is pinned, R5's skip fires only on nights with no CLI release.
- Replace `MINUTES_PER_EXECUTION=2` with a value measured from the last run's `run_metadata.json` (the 2026-08-17 baseline shows 216 s per with_skill execution).

### Sources

- Issue #467; analysis doc "self-org eval thresholds and cost" (2026-11-18).
- `.github/workflows/skills-eval.yml`, `scripts/run-behavioural-eval.py` (`compute_cache_key`, `cache_entry_is_usable`, `main`).

---

## Planning Contract

### Key Technical Decisions

- KTD1. Two cron entries select the depth: `0 7 * * 1-6` runs nightly at `runs=1`, `0 7 * * 0` runs weekly at `runs=3`. The job reads `github.event.schedule` to tell them apart. (session-settled: user-approved — chosen over raising `timeout-minutes` to about 150 to keep `runs=3` nightly, and over sharding cases into a job matrix: restores a nightly signal at about a third of the cost and keeps the variance read where the baseline needs it.)
- KTD2. "Relevant change" is decided by the existing cache key, not by a path list or a last-success SHA. A new runner flag `--plan-only` computes each leg's key exactly as the graded loop does and prints the count of legs that would execute. The key already hashes skills, shared references, commands, agents, cases, fixtures, the stub, the runner, `runs`, the model and the CLI version, and `cache-key-completeness-check.sh` guards that list. A path list would be a second definition that could drift from the first.
- KTD3. When the fresh-leg count is zero, skip the rest of the job with a notice and green exit, on every event, not only the nightly. (session-settled: user-approved — chosen over running every night and relying on the per-leg cache alone: most nights have no relevant change, so a run adds cost and no signal.) Applying it to dispatch too is a consequence, not a new choice: a run with zero fresh legs writes no `grading.json` and the aggregator has nothing to read.
- KTD4. The budget arithmetic moves out of the workflow heredoc into `scripts/eval-graded-budget.sh`, so it is testable offline (R7), the same move #204 made for the report step. It has two subcommands, because `runs` is a cache-key input and must be known before the fresh legs are counted: `resolve` takes the event, the schedule string, the weekly cron and the dispatch input and prints `runs=` (rows 1-4); `decide` takes `runs`, the fresh-leg count and the workflow path and prints `action=run|skip` (rows 5-8), or exits 1 with the arithmetic on refusal. The workflow passes `--plan-only` the resolved `runs` and the same `--model`, `--case` and config arguments the eval step uses, so the keys match.
- KTD5. `timeout-minutes` rises from 90 to 150, still one key. With every leg fresh, `runs=3` needs about 120 minutes by the current constant, so at 90 the weekly run (R2) and the dispatch default (R3) would refuse every time: the weekly keys never match the nightly's, so the weekly run never warms its own cache. The nightly cost does not change, because the budget check prices only `runs=1` legs on schedule nights. (session-settled: user-approved — chosen on a decision card on 2026-11-18 over keeping 90 and dropping the weekly runs=3 depth.)

### High-Level Technical Design

Directional only. The budget script's decision, in order:

| Step | Condition | Result |
|---|---|---|
| | **`resolve`** | |
| 1 | event is `schedule` and schedule is the weekly cron | runs = 3 |
| 2 | event is `schedule` (any other cron) | runs = 1 |
| 3 | otherwise | runs = dispatch input, default 3 |
| 4 | runs not a positive integer | exit 1 |
| | **`decide`** | |
| 5 | not exactly one `timeout-minutes:` in the workflow | exit 1 |
| 6 | fresh legs = 0 | action = skip, exit 0 |
| 7 | runs × fresh legs × minutes per execution > timeout − overhead, or runs > 10 | exit 1 with the arithmetic |
| 8 | otherwise | action = run |

Fresh legs are counted per (case, config) at the resolved `runs`, because `runs` is a key input: the nightly and weekly populations never share entries.

Job order after this change: checkout, key check, node, CLI install, session-shape probe, aggregator fetch, cache-index checkout, **plan (runner `--plan-only` then budget script)**, then the eval, aggregate, report, upload and push steps gated on `action == run`.

### Assumptions

- The fresh-leg count can be computed after the CLI install and before any model call: `claude --version` needs no API key, and `compute_cache_key` reads only files.
- A weekly run at `runs=3` with 10 evals and every leg fresh needs about `3 × 20 × 2 = 120` minutes by the current constant. It fits the 140-minute budget that KTD5 gives.

### Open Questions

- Risk carried by the deferred `MINUTES_PER_EXECUTION` follow-up: the 2026-08-17 baseline measured 216 s per with_skill execution, not 120 s. A nightly with all 20 legs fresh may then run past the 40 minutes the guard predicts. At 150 minutes the job still has room; the first nightly after merge is the measurement.

---

## Implementation Units

### U1. Runner `--plan-only` flag

- **Goal:** print how many legs the graded loop would execute, without executing any.
- **Requirements:** R4, R5 (KTD2).
- **Files:** `scripts/run-behavioural-eval.py`, `scripts/run-behavioural-eval.test.sh`.
- **Approach:** a flag that requires `--cache-index`, walks the same (case, config) loop, computes the key and applies `cache_entry_is_usable`, and prints one JSON line `{"fresh_legs": N, "cached_legs": M, "runs": R}`. It never creates `--out` subdirectories, never writes the index, and never calls `run_once`. Without `--cache-index` every leg counts as fresh.
- **Execution note:** test first.
- **Test scenarios:**
  - An index with a fresh, successful entry for the only leg prints `fresh_legs: 0` and the CLI is invoked once (`--version`).
  - An empty index prints `fresh_legs` equal to legs × configs.
  - An entry older than `--cache-max-age-days` counts as fresh.
  - An entry with `successful: false` counts as fresh.
  - The index file is byte-identical after the run, and no `eval-*` directory exists.
  - `--plan-only` without `--cache-index` counts every leg fresh.
  - Mutation: a plan-only that ignores `cache_entry_is_usable` fails the age scenario.
- **Verification:** `bash scripts/run-behavioural-eval.test.sh`.

### U2. Budget script

- **Goal:** one offline-tested place that resolves `runs`, refuses an over-budget run, and decides skip.
- **Requirements:** R1–R7 (KTD1, KTD3, KTD4).
- **Files:** `scripts/eval-graded-budget.sh`, `scripts/eval-graded-budget.test.sh`, `.github/workflows/scripts-test.yml`.
- **Approach:** the decision table above. Two subcommands (KTD4). `resolve` flags: `--event`, `--schedule`, `--weekly-cron`, `--runs-input`. `decide` flags: `--runs`, `--fresh-legs`, `--workflow`. Constants `MINUTES_PER_EXECUTION=2`, `OVERHEAD_MINUTES=10`, `SPEND_CAP=10` move here from the workflow with their comments. Output `key=value` lines.
- **Test scenarios:** one per decision row, plus: nightly with 20 fresh legs runs at 1; weekly with 20 fresh legs runs at 3 under a 150-minute fixture; weekly with 20 fresh legs refuses with the arithmetic under a 90-minute fixture; dispatch `runs=abc` refuses; two `timeout-minutes:` in a fixture workflow refuses; fresh 0 on dispatch skips; runs 11 refuses on the spend cap. Each check has a mutation case that removes only that check and proves the suite fails.
- **Verification:** `bash scripts/eval-graded-budget.test.sh`; `bash scripts/test-wiring-check.sh` passes with the new suite wired.

### U3. Workflow wiring

- **Goal:** the graded job uses U1 and U2 and gates the paid steps on the decision.
- **Requirements:** R1–R6.
- **Files:** `.github/workflows/skills-eval.yml`, `evals/README.md` (cadence note).
- **Approach:** add the weekly cron; add a "Plan the graded run" step after the cache-index checkout that runs the budget script's `resolve`, then `--plan-only` at that `runs` with the eval step's model and case arguments, then `decide`, and writes `runs` and `action` to its outputs; on `skip`, write the notice and step summary; gate the eval, aggregate, report, upload and push steps on `action == 'run'`; remove the inline arithmetic from the eval step and pass `--runs` from the plan step's output. Raise the one `timeout-minutes:` to 150 (KTD5); keep exactly one.
- **Test expectation:** covered by U2's suite and a wiring assertion in `scripts/eval-graded-budget.test.sh` that the workflow has both crons, calls the budget script, and gates the eval step on its output (read the YAML, as `eval-cost.test.sh` § 12 does).
- **Verification:** `bash scripts/eval-graded-budget.test.sh`; `bash scripts/eval-cost.test.sh` still passes its workflow-order guard.

---

## Verification Contract

- `bash scripts/run-behavioural-eval.test.sh`
- `bash scripts/eval-graded-budget.test.sh`
- `bash scripts/eval-cost.test.sh`, `bash scripts/eval-report.test.sh`
- `bash scripts/test-wiring-check.sh`, `bash scripts/cache-key-completeness-check.test.sh`
- `bash scripts/skills-lint.sh`, `shellcheck` at the pinned version on the new scripts when available locally
- `python3 scripts/run-behavioural-eval.py --out /tmp/probe --validate-only --no-session-probe --case evals/cases/*/evals.json` (each case)

No graded run is part of this PR. The first nightly after merge is the live check.

---

## Definition of Done

- All Verification Contract commands pass.
- The workflow has two crons, one `timeout-minutes:`, and no inline runs arithmetic.
- The PR body states the KTD5 timeout change, the CLI-pin follow-up and the measured-minutes risk.
- No experimental or abandoned code remains in the diff.
