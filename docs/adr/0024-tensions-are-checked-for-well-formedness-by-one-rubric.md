# 24. Tensions are checked for well-formedness by one rubric

Date: 2026-11-06

## Status

Proposed (2026-11-06). Kraig Parkinson asked for the checks on 2026-11-06 ("start
the checks"). The ADR is accepted when this PR merges.

Extends [ADR-0011](0011-separate-tension-readiness-from-tension-disposition.md)
(readiness is separate from disposition): this ADR defines what "well-formed"
means on the readiness side, and does not touch disposition.

## Context

`/self-org:tension-triage` says it decides whether a tension is "well-formed",
but no file defined the word. `skills/shared/triage-gates.md` checks whether a
tension belongs in governance (authority already held, role versus person,
venue, supersession, attribution). It does not check whether the body says
anything a reader can act on. Capture Step 4 had four drafting guidelines and
no check.

The body matters more than its length suggests. The GlassFrog API has no label
and no "why" field, so the body is the whole record. When a governance change
processes a tension, the tension is that change's only recorded reason. A thin
body is therefore a governance change with no "why".

The project side already has the shape this needs:
`skills/shared/project-well-formedness.md` is one rubric, loaded by every
project surface, that teaches with a drafted fix and never blocks.

## Decision

1. **One rubric.** `skills/shared/tension-well-formedness.md` defines seven
   checks, T1-T7: gap stated, concrete instance, felt by the role, one tension,
   not a disguised proposal, topic first, and structural (a pointer to
   `triage-gates.md` Step 2, not a copy). Capture, triage, and the lint all cite
   it, so "well-formed" means one thing.
2. **A soft gate.** Capture runs the rubric inside Step 4, after the gates, and
   shows the one or two failing checks with a drafted fix in the confirmation.
   Triage uses it as the standard for `[e] edit body`. Neither ever refuses to
   file or decides a disposition.
3. **Judgments from Jev, decisions in code.** `scripts/tension-lint.py` checks
   T6 and the 1-5000 character bound in code. It asks Jev, TypeSafe's System One
   model, one atomic Noul question for each of T1-T5. Code holds the thresholds
   (0.7 yes, 0.3 no, between is unsettled) and the decision table that turns the
   answers into `pass`, `teach`, or `ask`. A failed API call exits 2 and is never
   read as a "no".
4. **Python, with the TypeSafe Python SDK** (`typesafe-sdk`). The repo's scripts
   are Python and bash, with no Node toolchain in CI. The SDK import is lazy and
   the answer source is injected, so the offline suite runs without the SDK, a
   key, or the network.

Placement fit: Strong — tension readiness already lives in this plugin
(`triage-gates.md`, `/self-org:tension-triage`), and the rubric is the twin of
`project-well-formedness.md` in the same `skills/shared/` folder.

## Alternatives rejected

- **Inline rules in `tension-capture-flow.md`.** Triage and the lint would each
  need their own copy, and the copies would drift.
- **A general LLM-graded judge over the whole rubric.** One opaque score per
  body cannot say which check failed, and its decision logic cannot be tested.
  One calibrated probability per check, with the decision in code, can.
- **A hard block at capture.** Capture must stay cheap. A body that fails a
  check is still better filed than lost; triage can improve it later.

## Consequences

- **Data boundary.** A live lint run sends the tension body and the sensing
  role's name to a third party, `api.typesafe.ai`. It sends only when a person
  runs the script on that body. Capture and triage never call it. The script's
  help text says so, and it should run only after `triage-gates.md` Step 2, so a
  person tension is never sent.
- **Thresholds are unprobed.** 0.7 and 0.3 are TypeSafe's starting values. They
  need a probe on representative, hard, and negative tensions before anyone
  relies on the lint's `ask` band.
- **Live use needs setup.** A `TYPESAFE_API_KEY`, the `typesafe-sdk` package,
  and network access to `api.typesafe.ai`. CI runs only the offline suite,
  `scripts/tension-lint.test.sh`.
- **Check outcomes are findings, not tags.** `pass`, `teach`, and `ask` avoid
  the reserved `needs-*` and `ready-for-*` names (`skills-lint.sh` check 11).

## Not decided here

- Whether tension text may go to TypeSafe for every circle, or only for circles
  the person running the lint fills.
- Running the lint in CI against the live API, or from inside a meeting on a
  GlassFrog draft.
