---
name: async-tactical
description: >
  Read-only async Tactical briefing for one Holacracy circle, built for runs where no one is present: scheduled tasks, cloud routines, or a person who wants the Tactical picture without holding the meeting. Use when asked to "run tactical async", "run the async tactical for <circle>", "prep tactical without a meeting", or when a scheduled prompt asks for a circle's Tactical review. Resolves the actor and circle from GlassFrog, reads the circle's roles, checklist items, metrics, unprocessed tensions, projects and actions, flags stale and blocked projects, and returns one briefing with a gap marker for every section it could not read. It never writes to GlassFrog and never stops to ask a question; every suggested write is named as a command for a person to run later. For live, in-meeting Secretary capture, the user types /self-org:tactical instead.
status: draft
version: 0.1.0
---
# Async Tactical briefing

This skill produces a **Tactical briefing** for one circle without a meeting and without a person in the loop. It is the read-only, model-invocable twin of `/self-org:tactical`. That command primes live Secretary capture, writes tensions as they surface, and is user-only (`disable-model-invocation: true`, #464). A scheduled run cannot type a slash command, so it starts this skill instead (#504).

The Tactical Meeting's job is to sync on recurring work (checklists, metrics), share project updates, and triage tensions (Constitution v5.0 S.3.2). An async run cannot triage, because triage needs the people who fill the roles. It prepares everything that comes before triage and names what is waiting for the people.

## Rules for an unattended run

1. **Draft only.** Do not call any GlassFrog write tool: no tension, project, action, note, tag, metric or checklist write. A sensed tension is written into the briefing as a candidate, not filed. This is the constitutional safeguard in `../shared/actor-and-role-resolution.md` (section "Scheduled Routines: Context Encoding at Creation Time") and ADR-0003.
2. **Never wait for an answer.** No one is present. Where an interactive skill would ask, choose the reading the evidence supports, state the choice in one line in the briefing, and continue. If the circle cannot be resolved at all, return a short briefing that says what was tried and what the caller must supply next time. Do not end the run with a question.
3. **Never invent data.** GlassFrog exposes no meeting-occurrence data and no last-touched timestamp for a project. Do not state a last-meeting date or a "last updated" time you did not read. A section you could not read gets a gap marker, not a guess.
4. **Name follow-ups as commands for a person.** For example: "Run `/self-org:project-sweep Delivery Circle` to re-energize or archive the stale project." Do not start a user-only command yourself.

## Inputs

- **Circle** (required in practice): a circle name, a GlassFrog role id, or a GlassFrog URL. A scheduled prompt should carry it, with the circle id, per the routine preamble in `../shared/actor-and-role-resolution.md`.
- **Roles of interest** (optional): roles the caller wants named, for example the role that owns the circle's metrics and backlog. Use them to attribute findings; do not narrow the read to them.

## Procedure

### Step 1 -- Resolve actor and circle

Follow `../shared/actor-and-role-resolution.md` Step 1 and Step 2 exactly, including the bounded, paged roster call. Then resolve the circle:

- If the input carries a role id or URL, resolve it with `glassfrog_get_role` (see `../shared/glassfrog-id-and-url-resolution.md`). An id the caller gave wins over a name match.
- If the input carries only a name, match it against the circles of the roles the actor fills. One match: use it. Several: take the one where the actor fills Circle Lead or Secretary, and say so in the briefing. None: go to the degradation rules below.

Open the briefing with `Operating as **<Role> of <Circle>** (async, read-only)`. If the actor fills no role in the circle, say `Observing <Circle> (async, read-only)` instead; reading is still allowed.

### Step 2 -- Read the circle's roles

Call `glassfrog_list_sub_roles` on the circle to get every role in it. If that tool is unavailable, fall back to the roster from Step 1: the roles whose parent is the circle. Say in the briefing that the view then covers only the roles the actor fills.

### Step 3 -- Read circle state

For each role in the circle, read what the server offers. Each read is independent: one failure does not stop the others.

| Section | Tools |
|---|---|
| Checklist items | `glassfrog_list_role_checklist_items` |
| Metrics | `glassfrog_list_role_metrics` |
| Unprocessed tensions | `glassfrog_list_role_tensions` per role. `glassfrog_list_subrole_tensions` on the circle returns direct children only, so do not rely on it alone. |
| Projects | `glassfrog_list_role_projects` per role, or `glassfrog_list_subrole_projects` on the circle |
| Next actions | `glassfrog_list_role_actions` per role, matched to projects by parent project id |

### Step 4 -- Flag stale and blocked projects

Apply the staleness heuristic that `/self-org:project-sweep` owns (`../../commands/project-sweep.md`, "Apply the staleness heuristic"), with its meaning from `../shared/project-well-formedness.md`:

- **stale:** a `current` project with no attached next action. An old `created_at` (default 90 days) raises confidence and is shown, but never trips `stale` on its own.
- **blocked:** a project with status `waiting`. Present it as waiting on something, not as neglected.
- **exempt:** `someday` and `scheduled` projects are never flagged. A project with a live next action is never stale.

Say that staleness is inferred from age and the missing next action, because GlassFrog has no last-touched timestamp. A slow, long-horizon project can look the same as an abandoned one; the people at the next Tactical decide which it is.

### Step 5 -- Compose the briefing

Use this shape. Keep each line short. Put the items that need a person first.

```
# Async Tactical briefing: <Circle> -- <date>
Operating as **<Role> of <Circle>** (async, read-only)

## Needs a person
- <stale or blocked project, overdue metric, or tension that needs a decision>
  Why: <signal> -- Next: <command for a person to run, or the question for the meeting>

## Checklist review
<items by role, with frequency; or "No checklist items on this circle's roles"; or the gap marker>

## Metrics review
<metrics by role, with frequency and owner role; or "None"; or the gap marker>

## Project updates
Stale:   <project> (<role>) -- no next action; created <date> (~<age>) -- inferred
Blocked: <project> (<role>) -- status waiting
Moving:  <count> projects with a live next action

## Candidate agenda items (for triage in the meeting)
- <tension, role> -- why it belongs on the agenda

## Gaps in this briefing
- <section> -- <what could not be read and why>

## Suggested follow-ups (a person runs these)
- /self-org:project-sweep <circle>
- /self-org:tension-triage
- /self-org:tactical <circle>   (to hold the live meeting)
```

Annotate a candidate agenda item only when the reason is not obvious: give the source signal and the role or constitutional reason. A checklist item that is simply due needs no annotation.

### Step 6 -- Deliver

Return the briefing as the session's output. That is the delivery for a scheduled run: the scheduler or the person who reads the run collects it from there. Do not write the briefing to GlassFrog, and do not write it to a shared drive unless the caller's prompt names a location the run can write to. Some role drives let the connector create only dated files; an unattended run that fails to save must still return the briefing.

## Degradation

- **GlassFrog not connected:** return a briefing that says so, lists the sections that could not be built, and names the next step for a person (connect GlassFrog Extended). Do not fabricate a briefing from memory.
- **Circle not resolved:** return a short briefing with what was tried (the name or id given, the circles found on the actor's roles) and what the next scheduled prompt must carry: the circle's GlassFrog id.
- **Partial reads:** build every section you can read. Give each section you cannot read a gap marker with the reason (for example, "metrics: tool not offered by this GlassFrog server").

## What this skill does NOT do

- It does not run the live meeting, capture tensions, or record outputs. That is `/self-org:tactical` with the `self-org-secretary` skill.
- It does not triage tensions or projects. Triage needs a person; the briefing lists candidates.
- It does not archive, re-energize or edit anything. It names `/self-org:project-sweep` for that.
- It does not schedule itself. A scheduler (a scheduled cloud task or the `scheduled-tasks` MCP, ADR-0006) starts it with a prompt that names the circle.
