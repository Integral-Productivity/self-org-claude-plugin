# 28. Commands are named by act type

Date: 2026-11-18

## Status

Proposed (2026-11-18). Kraig Parkinson chose the hybrid shape on 2026-11-18 ([#462](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/462)). The ADR is accepted when this PR merges.

Reconciles [#159](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/159) (rename the dispatch family by authority class). Does not change [ADR-0011](0011-separate-tension-readiness-from-tension-disposition.md) or [ADR-0018](0018-separate-project-readiness-from-project-quality.md); it renames surfaces those ADRs describe.

## Context

At plugin 1.7.2 the 14 command names used four shapes:

- verb-noun: `capture-tension`, `capture-project`, `review-project`, `check-authority`, `audit-portfolio`
- noun-verb: `tension-triage`, `project-triage`
- noun-noun: `stalled-project-sweep`, `supersession-sweep`
- bare noun: `context`, `governance`, `tactical`, `routines`

Typing `/self-org:` grouped work neither by object nor by verb, so each row of `docs/surface-map.md` was scattered across the slash menu (design critique, 2026-11-18).

Two schemes competed:

1. **Noun-first** (#462 proposal): `tension-capture`, `tension-triage`, `project-review`. One work item's commands sort together and match the surface map. It hides the authority each act draws on.
2. **Verb-first by authority class** (#159): `/sense-tension`, `/commit-project`, `/define-metric`, `/propose-*`. The verb varies because the authority check varies, so the name makes the check legible before it runs. It scatters one work item's commands.

The two schemes describe different kinds of command. A command that makes one new work item is an act of authority, and #159's verb names the authority. A command that walks existing items of one type is a maintenance pass over a backlog, and its object is what the user looks for.

## Decision

Name each command by its act type.

| Act type | What it does | Shape | Commands |
|---|---|---|---|
| **Authority act** | Makes or decides one work item under one authority class. | `<verb>-<work item>`, verb from #159 (`sense`, `commit`, `define`, `propose`, `file`) or #160 (`process`) | `sense-tension`, `commit-project`; planned: `commit-action` (#161), `process-tension` (#160) |
| **Backlog walk** | Walks existing items of one type, one decision per item. | `<work item>-<walk>`, walk from `triage`, `sweep`, `review`, `audit` | `tension-triage`, `tension-sweep`, `project-triage`, `project-review`, `project-sweep`, `portfolio-audit` |
| **Session or reference** | Primes a meeting or session, or answers a question. No work item. | Its existing name | `context`, `governance`, `tactical`, `routines`, `check-authority` |

`portfolio` names a circle's checklist items and metrics together, as the `checklist-metric-audit` skill already does.

### Renames in this change

| Old name | New name | Act type |
|---|---|---|
| `capture-tension` | `sense-tension` | authority act |
| `capture-project` | `commit-project` | authority act |
| `supersession-sweep` | `tension-sweep` | backlog walk |
| `stalled-project-sweep` | `project-sweep` | backlog walk |
| `review-project` | `project-review` | backlog walk |
| `audit-portfolio` | `portfolio-audit` | backlog walk |

Each old name stays as a deprecated alias command (the `process-inbox` pattern from ADR-0011). An alias tells the user the new name once and runs the new command. **The aliases are removed in 2.0.0.**

### Enforcement

`scripts/skills-lint.sh` check 18 fails a command file whose name fits no row of the table above, unless its description starts with `Deprecated alias for /self-org:`. A new command that fits no row needs this ADR amended first.

### Out of scope

- Renaming the subagents (`tension-capture`, `project-capture`) and the shared flow files (`tension-capture-flow.md`, `project-capture-flow.md`). #159 lists them; they are internal names and stay with #159.
- Renaming the `checklist-metric-audit` skill. Skill names are a separate surface.
- The planned `policy:` command namespace (#103).

## Consequences

- A user who knows the work item finds its walks together: every tension walk starts `tension-` and every project walk starts `project-`. A user who knows the act finds its authority verb first: `sense-` or `commit-`.
- #159's verbs ship for the two commands that exist. #159 stays open for the subagent and flow-file renames and for the planned commands.
- Two shapes remain, by design. The rule is the act type, and the lint check makes a third shape fail.
- Renames are a `feat:` change because the aliases keep the old names working. Removing the aliases in 2.0.0 is the breaking change.
- Old names stay in ADRs, plans, ideation documents and the changelog. Those record the decision as it stood.
