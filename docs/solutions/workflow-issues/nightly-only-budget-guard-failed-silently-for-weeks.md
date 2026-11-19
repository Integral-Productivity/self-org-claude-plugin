---
title: "A budget guard that ran only in the nightly job refused every run for six weeks"
date: 2026-11-19
category: workflow-issues
module: evals
problem_type: workflow_issue
component: tooling
symptoms:
  - "The nightly graded eval failed in about 40 seconds, every night, from about 2026-10-09"
  - "The failure was a refusal from the job's own runs ceiling, not a test or model error"
  - "No skill change was measured by the graded tier in that time"
root_cause: untested_logic_in_ci_only_path
resolution_type: code_change
severity: high
related_components:
  - skills-eval-workflow
  - eval-graded-budget
tags:
  - github-actions
  - evals
  - budget
  - cost
---

# A budget guard that ran only in the nightly job refused every run for six weeks

## Problem

`.github/workflows/skills-eval.yml` checked, inline in a `run:` block, that
`runs <= (timeout - 10) / (2 min x evals x 2)`. The case count grew from 4 to
10, the ceiling fell to 2, and the schedule kept asking for 3. Every nightly run
refused itself in about 40 seconds. The arithmetic only ever executed on the
nightly schedule, against a secret no PR job holds, so no PR that added a case
could see that it broke the guard.

## Fix (#467, PR #468)

- The arithmetic moved into `scripts/eval-graded-budget.sh` (`resolve` and
  `decide` subcommands), with an offline, mutation-checked suite,
  `scripts/eval-graded-budget.test.sh`, run on every PR by `scripts-test.yml`.
- The guard prices only legs that will execute: `run-behavioural-eval.py
  --plan-only` counts cache misses with the same `leg_cache_decision` the loop
  uses.
- Cadence: nightly runs=1, Sunday runs=3, timeout 150 minutes.

## Lesson

Logic that lives only in a scheduled or secret-holding job is untested logic.
If a workflow computes a decision (a budget, a threshold, a skip), put the
computation in a script with an offline suite that runs per PR, and keep the
workflow to wiring. A wiring test (here, case 12) then checks the workflow calls
the script with the right inputs.

## When to apply

Any scheduled workflow, nightly job or `workflow_dispatch`-only path that makes
a decision from inputs that PRs can change, such as a case count, a file list or
a constant.
