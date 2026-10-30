# 23. Route every sensed gap as a tension through one intake

Date: 2026-10-30

## Status

Accepted (2026-10-30). Kraig Parkinson chose the option on 2026-10-30 and accepted
it by merging PR #429.

Extends [ADR-0007](0007-route-artifacts-by-live-glassfrog-domains-not-a-hardcoded-table.md)
(route by live domains) and [ADR-0021](0021-every-work-item-lifecycle-stage-has-a-command-or-a-tracked-gap.md)
(every lifecycle stage has a command or a tracked gap). It gives a design
direction to the missing process stage, `/self-org:process-tension` (#160).

## Context

People in an organization sense gaps of many kinds: a product idea, a process
problem, a client follow-up, a tool defect, unclear authority. In Holacracy, a
gap that a role senses is a tension, so every such item already qualifies as a
tension. The open question is where each one gets processed.

Three intake models were considered:

1. **Tension-only.** Every item goes through Holacracy outputs and the
   governance-data backlog. Meetings become a queue, and the backlog duplicates
   systems that already process the work, such as an issue tracker or a
   product-feedback tool.
2. **Separate channels.** One intake for each kind of feedback. The person must
   classify the item before they can submit it. Gaps in governance are skipped,
   and tracking is split across channels.
3. **One intake, tension first, then route.** Every item is captured as a
   tension. The plugin proposes how to process it and where it lives.

The plugin already has the parts for option 3: tension capture, the role-vs-person
partition in `skills/shared/triage-gates.md`, and the domain-based resolver in
`skills/shared/artifact-routing.md`. What is missing is the process stage and
the close of the loop.

## Decision

Option 3, inside the strategy's limits ("Not working on: automated tension
processing"; "Develop, don't replace").

1. **One intake.** Every sensed gap is captured as a tension, with the role it
   was sensed in. The person can use plain words. The plugin then shows the
   tension framing back, so the person learns it.
2. **Person and sensitive items leave first.** The existing role-vs-person
   partition runs before routing. The person half, and any item that is
   sensitive (safety, harassment, legal, health), go to a **handoff target** that
   the org configures locally. They never go to a shared backlog. The plugin
   ships no default target and stores no org data (ADR-0017).
3. **The plugin proposes, and the human decides.** Process-tension proposes one
   processing need (own action or project, a request to another role, an
   information request, a governance proposal, or an agenda item) and one home.
   The home is found by the ADR-0007 resolver, from the owning role's live
   domains and policies. The user confirms every route. Nothing is auto-filed.
4. **No hard-coded routing table.** If no role's domains name a home for the
   item, that is itself a governance tension. The fix is a domain or policy, not
   a plugin setting.
5. **The tension is the ledger.** The governance-data record of the tension
   links to each home. An item that fits two homes is split, and its parts are
   linked.
6. **The sensor closes the loop.** A tension is processed only when the person
   who sensed it confirms it is resolved, or explicitly drops it. A routine
   lists tensions with no linked home, and tensions whose home closed but which
   are still open.

## Consequences

**Easier**

- People have one way in, and they do not need a taxonomy to use it.
- Routing stays in sync with governance, because it reads live domains.
- The capture-to-processing ratio in STRATEGY.md becomes measurable per tension.

**Harder**

- Process-tension must state a processing need and a home that the user can
  check. A wrong proposal costs a confirmation round.
- Each org must configure a handoff target before person items can leave the
  flow. Until then, the plugin names the person half honestly and does not route
  it, as it does today.
- Writes to systems other than the governance-data backend (for example, an issue
  tracker) depend on the tools in the user's session. The plugin names the home
  and the user's tools file it.
- The closing routine adds one more routine. Check it against routine overlap
  (ADR-0015).

## Not decided here

- The command names and flags.
- The handoff-target config format.
- The eval cases. Tracked in #160.
