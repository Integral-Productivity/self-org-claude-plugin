# 27. A session binds to a role and a work item, recorded from observed tool results

Date: 2026-11-15

## Status

Proposed (2026-11-15). Kraig Parkinson asked for this ADR on 2026-11-15 and decided where the record lives on the same day (section 6). The ADR is accepted when this PR merges.

Extends [ADR-0008](0008-session-injected-honest-grounding-directive.md). ADR-0008 makes the session *request* a role at start. This ADR defines what a session is bound to, how the binding is recorded, and how it is kept after start. It does not change ADR-0008's invariants. Amendment A9 of ADR-0008 is reserved for #340; A8 went to the unattended-grounding fix (#284, #334).

## Context

The plugin ships one hook, `SessionStart` (`hooks/hooks.json`). It injects a directive that asks the session to resolve and announce a role. An assessment on 2026-11-14 found these gaps:

1. **Role only.** Nothing asks for the work item: a tension, action, project, checklist item, metric, goal or proposal. A work item already names the role that owns it, so a binding to the work item also gives the role, with one read.
2. **Start only.** No hook fires after start. `actor-and-role-resolution.md` Step 5 ("re-validate on a pivot") is a manual instruction.
3. **No record.** The plugin does not persist the resolved context ("What the plugin does NOT do"). No later hook can compare a write against a binding, and the grounding readout must infer the binding from transcript text (#71).
4. **Lost on resume, compaction and subagents.** `SessionStart` re-fires with a from-zero request. Subagents (`tension-capture`, `project-capture`, `self-org-coach`) run the resolution again from zero.
5. **Split anchors.** Other plugins keep their own session anchor: the session-management ledger (`Anchor → Object`), reclaim-assistant (`declared_entity`), and GlassFrog's official MCP (`startSession(role_id, topic)`). None reads the others.

ADR-0008's hard constraint still applies: a hook has no MCP access at fire time. A hook cannot know the binding by asking GlassFrog. It can only see what tools returned (`PostToolUse`), what the session's files say, and what earlier hooks wrote.

## Decision

### 1. A binding has a fixed shape

```json
{
  "session_id": "<harness session id>",
  "actor_id":   "per_… | agt_…",
  "role_id":    "role_…",
  "circle_id":  "role_…",
  "work_item":  { "type": "tension|action|project|checklist_item|metric|goal|proposal", "id": "…" } | null,
  "source":     "work_item|declared|domain|asked|routine",
  "observed_at":"<ISO 8601>"
}
```

`work_item: null` is a valid binding: the session is bound to a role and to no single item. `unbound` is also a valid state, and it is stated in one line, never left silent.

### 2. Resolution order

The first match wins:

1. **Work item.** The prompt, thread brief or routine prompt names a work-item ID or URL. Read it; its owner role is the role.
2. **Declared role.** The repo `CLAUDE.md`, the project instructions or the thread brief carries a `GlassFrog role:` line (#339). Validate it against the actor's roster.
3. **Domain.** A role holds a domain that names the repo, drive or system being changed.
4. **Ask.** Only when a human turn is possible.
5. **Unbound.** Say so in one line and proceed. Never ask on an unattended path (ADR-0008 invariant 4; #284, #334).

### 3. The record is written from observed tool results

A `PostToolUse` hook records a binding only from what a GlassFrog tool returned (`glassfrog_get_me`, `glassfrog_get_role`, the work-item `get_*` tools, `startSession`). It never records what the model says it did. This keeps ADR-0008's first invariant: a component that cannot observe grounding never claims it. The record is local, keyed by `session_id`, and never committed to this repo (ADR-0017).

### 4. Later hooks read the record; they never block

| Hook | Use of the record |
|---|---|
| `SessionStart` with `source` = `resume` or `compact` | Re-inject the last binding instead of the from-zero request |
| `PreToolUse` on GlassFrog writes | If the target role differs from the bound role, or no binding exists, add context: name the boundary and mark a chapter |
| `SubagentStart` | Hand the binding to the subagent as its role hint |
| `UserPromptSubmit` | One line, only when the binding is stale or absent |
| `Stop` | One note if GlassFrog writes happened with no recorded binding |

Every hook warns or informs. None blocks. Every hook keeps ADR-0008's rules: fail-silent on error, never silent in output, no question.

### 5. The directive's first line does not change

The work-item step goes into the directive's body. Per ADR-0008 A3, this reopens the behaviour window and keeps the delivery window.

### 6. Where the record lives: self-org owns it; the session ledger is an optional partner

Decided by Kraig Parkinson on 2026-11-15. The session-management plugin is not always installed beside self-org, so self-org must work fully on its own and work well with that plugin when it is present.

- **Self-org always writes its own record.** A local JSONL file, keyed by `session_id`, outside any repository. Every self-org hook reads only this record. Self-org never needs another plugin to bind, restore or warn.
- **When the session ledger is present, self-org also feeds it.** Detection is local and fast: the ledger's directory exists for this session. If it does, the binding fills the ledger's `Anchor → Object` (the work item) and adds the role. If the Anchor already names a work item, self-org reads it as a resolution signal (rank 1 in section 2) and validates it, but never overwrites it.
- **When the ledger is absent, nothing degrades.** No warning and no question. The self-org record carries the full binding.
- **One seam.** The writer and the readers go through one small read/write layer. A later store (for example, GlassFrog's `startSession(role_id, topic)` for agent actors, #340) plugs in there. GlassFrog is not the primary store, because `startSession` returned `Not an agent` for a human connection on 2026-10-08.

Options considered: the session ledger as the only store (fails when that plugin is absent); a self-org file only (adds a fourth, unconnected anchor); GlassFrog only (agents only today). The decision combines the first two, with self-org's file as the floor.

## Consequences

- Grounding gains a second object, the work item, and the role follows from it in the common case.
- Later hooks have something to compare against. Remit warnings (#64) and drift reminders become possible without a per-turn detector (#67).
- The grounding readout can count bindings from the record, not from transcript text (#71). The transcript parse stays as a cross-check.
- Each new hook adds hot-path cost. `PreToolUse` and `UserPromptSubmit` must stay shell-only on the common path. ADR-0008 A6 measured about 25 ms per `python3` start.
- A remit warning that fires on legitimate cross-role work gets ignored (ADR-0008 A4). `PreToolUse` starts count-only for one window.

## What this ADR does NOT do

- It does not make any hook call GlassFrog.
- It does not block any tool call.
- It does not decide which role owns a work item when GlassFrog does not say; that stays with the resolution procedure.

## Implementation sequence

1. Question-free procedure on unattended paths (#284, #334).
2. `PostToolUse` recorder (#71).
3. Work-item step in the directive body (#451).
4. Restore on resume and compaction (#452).
5. `PreToolUse` remit warning (#64).
6. `SubagentStart` hand-off (#453).
7. Drift reminder and close check (#454).
8. Thread and project declarations (#339); agent actors through `startSession` (#340).
