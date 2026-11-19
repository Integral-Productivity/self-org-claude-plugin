---
module: design-checklist
date: 2026-11-19
problem_type: tooling_decision
component: development_workflow
severity: low
applies_when: "A contributor checklist (design, review, release) lives in docs and a reviewer worries that contributors will stop following it, or that the checklist will claim enforcement that no longer exists."
related_components:
  - skills-lint
  - ci
tags:
  - checklist
  - drift
  - ci-gate
  - pull-request-template
  - lint
---

## Problem

`docs/plugin-design-checklist.md` (#465) tells contributors to check every
changed command, skill, or subagent against 37 items. A reviewer asked how to
stop drift if the instruction is not followed, and suggested a git hook or CI.

There are two kinds of drift:

1. **Process drift.** Contributors stop reading the checklist.
2. **Claim drift.** The checklist says an item is "enforced by lint, check N",
   and check N is later renumbered or removed. The document still claims a
   guard that does not exist.

## What was chosen

- **A CI gate on the pull-request body** (`.github/workflows/design-checklist.yml`,
  `scripts/design-checklist-gate.sh`). A PR that changes `commands/`, `skills/`,
  or `agents/` fails unless its body has a ticked
  `- [x] Checked against docs/plugin-design-checklist.md`. The PR template
  carries the box. The workflow is a required check on `main`.
- **A lint check on the checklist itself** (`skills-lint.sh` check 19). It fails
  when the checklist names a lint check number that the script does not define.

## Why not a git hook

- A hook cannot verify that someone read a document either.
- `git commit --no-verify` skips it, and it runs only where it is installed.
- The lint already runs in CI on every PR, so a hook adds no coverage.

The PR-body box is also a claim, not proof. Its value is that it puts the claim
where the reviewer reads it, and makes skipping it an explicit act.

## Details worth reusing

- **The PR body is untrusted input.** Pass it through an `env:` variable and
  write it to a file. Never interpolate `${{ github.event.pull_request.body }}`
  into a `run:` script.
- **Trigger on `edited`.** Include `types: [opened, edited, synchronize, reopened]`
  so ticking the box re-runs the gate without a new push.
- **Compute changed files from the event SHAs:**
  `git diff --name-only "$BASE_SHA...$HEAD_SHA"` with `fetch-depth: 0`.
- **A gate blocks nothing until it is required.** Add the job name to the
  branch ruleset's required status checks, then read
  `GET /repos/{owner}/{repo}/rules/branches/main` to confirm it is listed.
- **Every new lint check needs its mutation case** in `skills-lint.test.sh`
  (fails on a seeded defect, passes with the check skipped).

## References

- #465, PR #480
- `CLAUDE.md`, "Design checklist"
