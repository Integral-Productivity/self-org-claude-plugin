# 25. The plugin may draft and circulate governance proposals, but never originates one or objects for a person

Date: 2026-11-15

## Status

Proposed (2026-11-15). Kraig Parkinson chose on 2026-11-15 to have this ADR
drafted, after the 2026-11-14 assessment of the plugin's constitutional
guidance. The ADR is accepted when its PR merges.

Supersedes the "Why Governance is Read-Only" rationale in
`skills/self-org-ai-governance/references/glassfrog-api-constraints.md`.
Builds on [ADR-0011](0011-separate-tension-readiness-from-tension-disposition.md)
(a proposal is a disposition of a ready tension) and
[ADR-0023](0023-route-every-sensed-gap-as-a-tension-through-one-intake.md).
Provenance: #447 (stale reference), #448 (routes), #449 (proposal review).

## Context

The plugin's API reference says no governance change can be made through the
API, and that a drafted proposal can only reach a meeting by hand. Its rationale
is principled: governance is a human practice, and an API path would bypass the
objection process.

The premise is no longer true. GlassFrog Extended exposes `create_proposal`
(a draft anchored to a tension), `propose_proposal` (circulate it outside a
meeting), `respond_to_proposal`, and `withdraw_proposal`. GlassFrog's official
MCP exposes `applyGovernanceChanges`, a direct structure change where the web
app would allow it without a proposal.

Constitution v5.0 also makes asynchronous processing a first-class route, not
a workaround. 5.3 lets any Circle Member share a written Proposal in a channel
the Secretary allows. Every other Circle Member can then raise Objections, and
any of them can ask to move it to a meeting. The objection process is not
bypassed by circulating a proposal: it is the same process, run in writing.

What the old rationale protected is still worth protecting. A proposal must
come from a Proposer's own Role (5.3.1(a)). An objection must come from a Role
the Objector represents (5.3.2(b)). Neither can be delegated to a tool.

## Decision

1. **The plugin may draft a proposal** with `create_proposal`, on behalf of a
   named person, for a tension that one of that person's Roles holds.
2. **The plugin may circulate it** with `propose_proposal`, only after that
   person confirms the exact proposal text and changes, one proposal at a time,
   in the same session. Circulating notifies the circle, so it is treated as an
   outward-facing write.
3. **The plugin may make a direct structure change** with
   `applyGovernanceChanges` only where GlassFrog allows it without a proposal,
   and only after the same per-change confirmation.
4. **The plugin never originates a proposal.** A pattern the plugin detects is
   surfaced as an observation. It becomes a tension only when a person names it
   (ADR-0023), and a proposal only when that person asks for one.
5. **The plugin never responds to a proposal for a person.** It does not call
   `respond_to_proposal` unless that person, in that session, asks for the
   specific response (`no_objection` or `bring_to_meeting`) on that specific
   proposal. It never raises or records an objection on anyone's behalf.
6. **Review is read-only.** A proposal review or objection pre-check gives
   advice to the Proposer. It writes nothing.

## Alternatives rejected

- **Keep governance read-only.** This keeps a rule whose premise is false and
  blocks a route the Constitution provides. Users would circulate proposals by
  hand and lose the plugin's well-formedness checks at the point of writing.
- **Let the plugin circulate proposals without per-proposal confirmation.**
  A circulated proposal notifies the circle and starts a response deadline.
  That is an outward act in the person's name, so it needs their explicit
  approval each time.
- **Let the plugin answer `no_objection` by default for a person who fills an
  affected Role.** This would turn silence into consent that the person did not
  give, and v5.0 already provides a Policy-set time limit (5.3) for that case.

## Consequences

- `glassfrog-api-constraints.md` "Hard Boundaries" is rewritten (#447).
- `/propose-*` (#161) and the proposal review command (#449) build on this ADR.
- The `self-org-coach` subagent stays read-only; its `disallowedTools` already
  lists the proposal write tools.
- The eval stub needs the proposal tools in its write log, so the "no write
  without confirmation" ordering check covers them.
- `respond_to_proposal` cannot record an Objection. The plugin must say so and
  explain that `bring_to_meeting` withdraws the proposal under 5.3 unless a
  Policy says otherwise.

## Not decided here

- Which commands carry these writes, and their names (#159, #161).
- Whether the plugin may circulate a proposal for an AI agent that fills a Role.
