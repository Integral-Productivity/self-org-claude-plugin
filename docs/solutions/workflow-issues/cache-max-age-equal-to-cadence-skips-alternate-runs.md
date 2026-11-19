---
title: "A cache max age equal to the run cadence makes the weekly run skip on alternate weeks"
date: 2026-11-19
category: workflow-issues
module: evals
problem_type: workflow_issue
component: tooling
symptoms:
  - "A weekly job that refreshes its own cache entries sometimes plans zero fresh legs and skips"
  - "Whether it skips depends on minutes of start-time jitter, not on any change"
root_cause: boundary_condition
resolution_type: code_change
severity: medium
related_components:
  - skills-eval-workflow
  - eval-graded-budget
  - run-behavioural-eval
tags:
  - github-actions
  - cache
  - schedule
  - evals
---

# A cache max age equal to the run cadence makes the weekly run skip on alternate weeks

## Problem

The graded eval reuses a leg's result while its cache entry is younger than
`--cache-max-age-days` (default 7). The Sunday runs=3 entries are refreshed
only by the Sunday run, so the next Sunday finds them about 7 days old. A
scheduled run starts a few minutes late or early, so the entry is sometimes just
under 7 days and counts as fresh. On those Sundays the plan step saw every leg
as cached and skipped the weekly variance run. About half the Sundays would
have measured nothing.

Found by the correctness review of PR #468 (P2) and fixed in the same PR.

## Fix

`scripts/eval-graded-budget.sh resolve` prints `max_age_days`: 6 on the weekly
cron, 7 otherwise. The plan step and the eval step both pass it as
`--cache-max-age-days`, so they judge age by the same limit. Test case 16e2
checks an entry 6 days 23 hours old at both limits; budget case 1b and wiring
case 12 carry mutants.

## Lesson

When a job is the only writer of the cache entries it reads, its max age must be
strictly shorter than its own cadence, with margin for schedule jitter. An age
limit equal to the cadence sits on the boundary and flips on start-time noise.
Also make every step that judges freshness read the same limit from one source.

## When to apply

Any scheduled job with an age-based cache or a "skip if recent" rule:
compare the age limit with the interval between the runs that refresh it.
