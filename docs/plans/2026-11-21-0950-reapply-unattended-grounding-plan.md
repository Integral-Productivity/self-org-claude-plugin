---
title: Re-apply the unattended-grounding fix and pin its prose
date: 2026-11-21
type: fix
status: active
origin: https://github.com/Integral-Productivity/self-org-claude-plugin/issues/284
issues: [284, 334]
---

# Re-apply the unattended-grounding fix and pin its prose

## Goal Capsule

- Outcome: a session that cannot finish role grounding has an instruction it can carry out (one `Operating **unbound**:` line, no question), and the test suite fails if that prose is weakened.
- Scope: re-apply commits b71428e and 1e064ad (reverted before PR #505 merged), add G43 pins for the prose mutants that survived the last verification, and date A7 and A8 in the ADR-0008 status banner.
- Out of scope: a pre-declared default role (#339); any change to the directive first lines.

## Product Contract

- R1. When `glassfrog_get_me` is listed but fails, both directive forms say: one line, no retry, no question, then carry on unbound (#334).
- R2. In an unattended session, Step 1, Step 3 and the GlassFrog-unavailable section of `skills/shared/actor-and-role-resolution.md` each turn their ask into one unbound line (#284).
- R3. `unbound` is defined: what it permits and what it forbids.
- R4. A session with no GlassFrog tool stays silent; it writes no unbound line (ADR-0008 A8).
- R5. The interactive asks stay unchanged beside the unattended branches.

## Planning Contract

Key technical decisions:

- KTD1. Re-apply b71428e and 1e064ad by cherry-pick, so the history keeps their original content and authorship. session-settled: user-directed (Kraig, 2026-11-21, #284). Rejected: rewriting the fix from scratch. Reason: it met every acceptance criterion in round-2 verification.
- KTD2. No-tool branch stays silent. session-settled: user-directed (Kraig, 2026-11-21, ADR-0008 A8 accepted). Rejected: an unbound line on every no-GlassFrog session. Reason: the conditional record (A5) is the evidence.
- KTD3. Directive first lines stay byte-identical. session-settled: user-directed (ADR-0008 A3). Rejected: rewording. Reason: the readout marker depends on it.
- KTD4. Pin prose by exact text, not by word, as G43 already does for the asks. Each new pin is checked by its mutant: the suite must fail with the mutant and pass without it.
- KTD5. A8 is dated 2026-11-21, the day it is accepted and re-applied; the banner lists A7 (2026-10-08) and A8 (2026-11-21).

## Implementation Units

- U1. Cherry-pick b71428e and 1e064ad onto `claude/project-thread-a0uo0g` as two commits. Reword b71428e's "Closes #284 / Closes #334" lines to "Refs #284 #334" so no commit closes an issue before verification. Keep their original Co-Authored-By and Claude-Session trailers. The earlier plan file `docs/plans/2026-11-20-1800-fix-unattended-grounding-plan.md` ships with b71428e as its record.
- U2. Test first: write the mutants of `skills/shared/actor-and-role-resolution.md` and confirm each survives the current suite: (a) delete the "What unbound permits" paragraph; (b) delete the "What unbound forbids" block; (c) change Step 3's unattended branch to "pick the first circle silently"; (d) delete Step 1's not-connected question "Whose role-context should I treat as primary?"; (e) delete Step 1's unattended clause "no retry loop and no question". Also try Step 3's and the unavailable section's `Operating **unbound**:` lines; pin every mutant that survives (at least these five).
- U3. Add G43 pins in `hooks-handlers/session-start.test.sh` for each surviving mutant. Re-run each mutant: the suite must now fail on it.
- U4. ADR-0008: change the A8 heading date from 2026-11-20 to 2026-11-21, and make the banner read "Amended 2026-08-04, 2026-09-03, 2026-10-02, 2026-10-06, 2026-10-08 and 2026-11-21".
- U5. Run the verification contract and commit with "Refs #284 #334".

## Verification Contract

- `bash hooks-handlers/session-start.test.sh` passes. The fix's test file, run against `origin/main`'s `session-start.sh` and `actor-and-role-resolution.md`, fails at G41-G43.
- Environment note: this container's default `python3` (3.13 at /usr/local/bin) has no `posix_spawn` setsid, so G27 fails here on `origin/main` too. Run the suite with `/usr/bin/python3.12` first on `PATH`. CI (ubuntu-latest) is unaffected.
- Each U2 mutant fails the suite after U3 (mutation check, recorded in the commit message).
- `bash scripts/skills-lint.sh` and `bash scripts/skills-lint.test.sh` pass.
- The offline suites in CLAUDE.md pass: `evals-harness.test.sh`, `run-behavioural-eval.test.sh`, `eval-report.test.sh`, `eval-cost.test.sh`.
- shellcheck 0.11.0 `--severity=style -x -P scripts scripts/*.sh scripts/lib/*.sh` is clean, and the hook files are clean too.
- The directive opening marker lines (`**self-org plugin: role-grounding directive**` and `**self-org plugin: role-grounding check (conditional directive)**`) are byte-identical to `origin/main`.

## Deferred / Open Questions

- None. Document review (lite) findings were applied in place.

## Definition of Done

- U1-U5 done, committed locally on the branch, no push (the caller pushes after independent verification).
- No commit message says "Closes".
