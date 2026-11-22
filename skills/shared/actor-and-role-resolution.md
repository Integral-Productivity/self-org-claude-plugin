# Holacracy Actor and Role Resolution -- Shared Reference

This document is shared across all holacracy skills. It defines how a skill resolves *who* is operating (the **actor**) and *which* role + circle they are operating from (the **role context**) before performing any work.

Holacracy depends on the role/soul distinction: a person *energizes* a role but is not identical to it. The same person can fill many roles across many circles. An AI agent can also be a role-filler in its own right. A skill that doesn't know which role context it's operating in will produce ungrounded, generic work. This document is the procedure that prevents that.

Load this when a role skill begins a session, when a scheduled routine fires and needs to assert its acting role, when a slash command starts that depends on actor identity, or when ambiguity arises mid-conversation about which role's authority is in play.

---

## The Actor Model

A skill always operates on behalf of exactly **one actor per session**. The actor is either:

- **A person.** A human Partner of the Holacracy-governed organization. Most interactive sessions have a human actor.
- **An AI agent.** A first-class actor type in GlassFrog (queryable via `glassfrog_list_agents`, `glassfrog_get_agent`). AI agents can be assigned to roles via `glassfrog_assign_actor_to_role`, exactly like people. Most scheduled routines have an agent actor.

This is not just terminology -- GlassFrog's data model treats people and agents as distinct entities. Routines that fire under an AI agent identity produce work attributed to that agent in audit trails, separately from any human's work.

### Where the actor identity comes from

| Invocation context | How the actor is resolved |
|---|---|
| Interactive session, user is logged into Claude with their GlassFrog credentials | `glassfrog_get_me` returns the human actor. This is the default. |
| Interactive session, user is helping a different person | User states the actor explicitly: "I'm helping Alex prep for tactical." The skill operates as if the actor is Alex (Observer/Advisor mode -- see below). |
| Scheduled routine fires | The routine's prompt declares the acting AI agent at creation time. The skill trusts that declaration and operates as that agent. If `glassfrog_get_me` then fails, the declaration is unverified: see [A routine's declared role](#a-routines-declared-role). |
| Slash command invoked | Same resolution as the underlying session context. `/self-org:context` is the explicit override. |

### What the plugin does NOT do

- The plugin does **not auto-create** AI agents in GlassFrog. AI agents must already exist (registered in the GlassFrog UI) and be assigned to the relevant role before any routine references them.
- The plugin does **not persist** resolved actor identity across sessions. Each interactive session resolves fresh via `glassfrog_get_me`; each scheduled routine carries its identity in its own prompt.
- The plugin does **not** assume the human is the actor when GlassFrog is unavailable. It names the limitation: "I don't have live actor data -- who should I treat as the actor for this session?" In an unattended session it names the limitation and proceeds **unbound** instead of asking (see [Unattended Sessions and the Unbound State](#unattended-sessions-and-the-unbound-state)).

---

## The Role-Context Resolution Procedure

When a role skill is invoked, run this procedure **before** producing any role-specific output. It costs at most two tool calls and dramatically improves the grounded quality of every subsequent response.

### Step 1 -- Confirm actor identity

If actor identity has not yet been resolved this session:

1. Call `glassfrog_get_me` — **without** `include_roles`. If it returns a person/agent, that is the actor. Note the actor name and id. (`include_roles: true` embeds the whole roster and overflows the tool-result limit for any actor filling more than a handful of roles; see Step 2.)
2. If `glassfrog_get_me` fails or returns nothing, ask the user: "Which actor should I treat as the basis for this session? (your own GlassFrog identity, or someone you're supporting?)"

If GlassFrog is not connected at all, name the constraint: "I don't have live GlassFrog data, so I'm working from what you tell me. Whose role-context should I treat as primary?"

**Unattended:** if the session is unattended, or the session-start role-grounding directive sent you here, a failed or empty `glassfrog_get_me` gets one line and nothing more: no retry loop and no question. Write `Operating **unbound**: glassfrog_get_me failed (<the error, in a few words>), so no role is resolved.` and carry on with the work. A role skill or routine that runs with no GlassFrog connector writes the Step 5 line instead. The session-start directive writes no line when no `glassfrog_get_me` tool is listed (ADR-0008 A8). See [Unattended Sessions and the Unbound State](#unattended-sessions-and-the-unbound-state).

### Step 2 -- Load the actor's role roster (bounded)

Call `glassfrog_list_my_roles` (or, if operating on behalf of someone else, the appropriate filtered `list_roles` query for that person). This returns every role the actor currently fills.

**Page it. Do not call it unbounded.** Each role object embeds its full `accountabilities`, `domains`, `fillers`, and `tags` — roughly 1.5 KB per role. The default `per_page` is 100, so for a Partner filling ~60 roles the response runs past 90 KB and is rejected for exceeding the tool-result limit. The same is true of `glassfrog_get_me(include_roles: true)`, which returned **124,801 characters** for one real actor and failed outright. Both are the *obvious* way to make the call and both cost you the turn.

```
glassfrog_list_my_roles(per_page: 10)
  -> { items: [...], pagination: { has_next_page, next_cursor } }
glassfrog_list_my_roles(per_page: 10, cursor: <next_cursor>)   # repeat while has_next_page
```

Stop paging as soon as the target role is found — for a role skill with a specific target (Secretary, Rep Link), that is usually the first page or two, not the whole roster.

**Resolving the circle name.** A role object carries `parent_role_id` but **no circle name**, so the roster alone cannot produce `Operating as **Role of Circle**`. The parent id refers to another role — the circle — so map it to that role's `name`:

- If the parent is already in a page you have fetched, read its `name` directly.
- Otherwise call `glassfrog_get_role(<parent_role_id>)` for just that one id.

A circle is itself a role (`has_subroles: true`), which is why this is an id→role lookup rather than a separate circle endpoint.

**Deferred tools.** In harnesses where MCP tools are loaded on demand, `glassfrog_*` must be fetched before the first call or it fails with a validation error rather than a permissions error. Load the two you need in a single lookup — `glassfrog_get_me`, `glassfrog_list_my_roles` — rather than one at a time.

### Step 3 -- Resolve to a single role + circle

The skill's purpose narrows the resolution. For example, `self-org-secretary` cares only about roles named "Secretary" (or sub-circle Secretary equivalents). For each role skill, there is a target role name.

Apply the **silent-when-obvious + ascertain-vs-ask + announce-the-result** policy:

| Situation | Action |
|---|---|
| Actor fills the target role in exactly one circle | Proceed silently with that circle. Announce the resolved context in the first response: "Operating as **Secretary of [Circle Name]**." |
| Actor fills the target role in multiple circles | Ask: "You hold [Role] in [Circle A], [Circle B], and [Circle C]. Which one is this about?" Then proceed. |
| Actor does not fill the target role anywhere | Name it clearly. Offer Advisor or Observer mode: "You don't currently fill the [Role] role in any circle. Do you want to (a) explore how the role works, (b) prepare for taking on the role, or (c) advise someone else who fills it?" |
| The named role does not exist in the organization at all | **Do not fall through to Observer mode.** Run Step 3a below. A role the user speaks of as real but that governance has never created is a different condition from a role they simply do not fill, and it needs a different answer. |
| The user named the circle in their prompt | Use it as the resolution signal. Validate against the actor's role roster: if it's a circle the actor fills the role in, use it silently; if not, name the mismatch. |
| User explicitly overrides via `/self-org:context` | Use the override. Announce the override is active. |
| No target role: the session-start directive sent you here, or the request names no role | Resolve from the roster and from what the session names. The actor fills exactly one role: announce it. The prompt names a role or circle the actor fills: use it. Otherwise do not ask: write `Operating **unbound**: <actor> fills <N> roles, and nothing in this session picks one.` A person can name the role later (see [Leaving unbound](#unattended-sessions-and-the-unbound-state)). This row never asks, in an attended session too, because the directive must not ask a question (ADR-0008 invariant 4). |

**Unattended:** every row above that asks the user becomes one line and no question. Several matching circles: `Operating **unbound**: <Role> is filled in <Circle A> and <Circle B>, and nothing in this session picks one.` The actor fills the target role nowhere: `Operating **unbound**: <actor> does not fill <Role> in any circle.` Then carry on. Do not pick a circle silently; a guessed circle is a wrong attribution that looks clean. See [Unattended Sessions and the Unbound State](#unattended-sessions-and-the-unbound-state).

### Step 3a -- When the named role does not exist

People refer to roles they intend to have, roles that were discussed in a Governance Meeting but never filed, and roles that exist only in a pending proposal -- all in the same possessive voice they use for roles they actually fill. "My Legal Steward role" is as likely to mean *the role we agreed to create* as *the role I hold*.

The Step 3 table's "does not fill the target role anywhere" row assumes the role exists and the actor is outside it. When the role does not exist, that row's Observer/Advisor offer is the wrong response: it invites the user to "explore how the role works" for a role that has no governance to explore.

**Distinguish the two conditions before answering.** The roster search in Step 2 tells you the actor does not fill the role; it does not tell you whether the role exists. Confirm existence separately, and only then look for the reason it is missing:

1. **Confirm non-existence.** Search the organization, not just the actor's roster: `glassfrog_search(query: "<role name>")`. A role that exists but is filled by someone else returns here and is an ordinary Observer/Advisor case.
2. **Look for pending governance.** The same `glassfrog_search` call surfaces actions, projects, tensions, and proposals whose text names the role. A hit means the role is *in flight* -- someone already sensed this gap and it is queued, not forgotten. Report the specific item and the role that holds it.
3. **Answer with the governance state, not a refusal.** Name what exists and what does not, in that order:

   > "There is no ● [Role] role in GlassFrog. The closest thing is an open action under ● [Holder] to create it -- filed [date], still `current`. Until that goes through Governance, [work] has no role to attach to."

4. **Offer the two real paths, in order of cost.** (a) Proceed now under the nearest existing role whose Purpose and Accountabilities actually cover the work, naming the compromise. (b) File the governance proposal first, then attach the work to the new role. Let the user choose; do not pick silently.
5. **If the user proceeds under a substitute role, say so in the record.** Whatever the skill files -- project, action, tension -- carries a line naming the intended role, the substitute used, and why. Otherwise the record shows a clean attribution that was never clean, and the next reader cannot tell a deliberate compromise from a mistake.

**Unattended:** items 1 and 2 still run, because they are read-only searches. Item 4 has nobody to choose, so it becomes one line and no question: `Operating **unbound**: <Role> does not exist in GlassFrog.` Add the in-flight item and its holder when item 2 found one. Do not take either path, and do not proceed under a substitute role. File no project, action or tension for the work; draft it instead, and name the missing role in the draft. See [Unattended Sessions and the Unbound State](#unattended-sessions-and-the-unbound-state).

**Why this earns its place.** The failure is silent and it corrupts the governance record rather than the conversation. A skill that files a project under a plausible-looking role because the named one was missing produces an artifact that looks correct in GlassFrog forever. Catching it costs one search call at resolution time.

### Step 4 -- Announce the resolved context (always)

Every response that uses the resolved context names it in the opening lines. Examples:

- "Operating as **Secretary of Operations Circle**. Pulling the checklist and metrics now..."
- "I'm treating this as **Lead Link of the Product Circle** work. Strategy on file says..."
- "**Observer mode** -- you don't currently fill Rep Link anywhere, so I'll explain how this role normally operates..."

This is non-negotiable. Without the announcement, the user has no way to catch a wrong resolution before the skill's output is built on it.

### Step 5 -- Validate context didn't go stale

If the same session continues past a major turn (e.g., the user pivots to a different topic), re-validate before continuing: a quick `glassfrog_list_my_roles` confirms the actor still fills the role. Governance can change between turns. If the actor no longer fills the role, name it and re-resolve.

---

## Three Engagement Modes (Where Resolved Context Lands)

Once the actor and role are resolved, the skill operates in one of three modes from `self-org-ai-governance` SKILL.md. The mode determines what the skill *does* with the resolved context.

| Mode | Actor relationship | Example |
|---|---|---|
| **Observer** | Actor does NOT fill the target role. Skill explains/analyzes from outside. | User exploring what Rep Link does before standing for election. |
| **Advisor** | Actor fills the role and is making a decision themselves. Skill augments. | Lead Link asking "should I assign Robin to this role?" |
| **Actor** | The actor IS the role and Claude is producing work that fulfills its accountabilities. Human reviews and acts. | Secretary asking the skill to draft tactical meeting capture. Scheduled routines almost always operate in this mode. |

Resolution does not pick the mode -- the user's intent does. But the announcement should make the mode visible: "Operating as **Lead Link of Product Circle (Advisor)** -- I'll surface considerations rather than make a recommendation."

---

## Scheduled Routines: Context Encoding at Creation Time

When the agentic capability (v0.3+) creates a scheduled routine via `mcp__scheduled-tasks__create_scheduled_task`, the routine's prompt **must encode** the resolved context. There is no shared memory the routine can read at fire time -- the prompt is the only carrier of identity.

The required preamble for every routine prompt:

```
You are firing as a scheduled Holacracy routine.

Acting actor: [Agent name] (GlassFrog agent id: [id])
Acting role: [Role name]
Acting circle: [Circle name] (GlassFrog circle id: [id])
Accountability being energised: [accountability text from governance]
Output channel: [Slack channel / file path / notification]

Constitutional safeguard: Draft only. Do not file proposals, assign people, issue
constitutional rulings, or modify governance. Produce output for human review.

[Then the routine-specific task...]
```

The plugin prefix `self-org/` appears in the routine's task title so the SessionStart hook can filter to its own routines without scanning every scheduled task on the system. Example title: `self-org/secretary/pre-tactical-prep/operations-circle`. Titles that still use the pre-1.0 prefix `holacracy/` are also accepted (ADR-0020).

---

## When GlassFrog Data Is Unavailable

A skill can still operate without GlassFrog, but it must:

1. **Name the limitation in the announcement**: "GlassFrog isn't connected, so I don't have live role data. I'll work from what you've told me."
2. **Ask the user to declare the context**: "Whose role should I treat as primary? In which circle?"
3. **Not silently assume** the human is the actor or that the canonical role definition matches their current accountabilities.

This is the same pattern as the existing `self-org-ai-governance` SKILL.md "Required: GlassFrog MCP Tools" section -- it doesn't refuse to operate, it names the constraint.

**Unattended:** skip step 2. Nobody can declare the context, so write `Operating **unbound**: GlassFrog is not available in this session, so no role is resolved.` and carry on. Step 3 still holds: an unbound session assumes no actor and no role.

This branch is for a role skill or a routine that runs this procedure. The session-start conditional directive does not send a session here when no `glassfrog_get_me` tool is listed. That session makes no GlassFrog call and writes no unbound line. The conditional directive in its transcript is the record that grounding was not available.

---

## Unattended Sessions and the Unbound State

Every "ask the user" step above assumes someone can answer. Some sessions have nobody: a scheduled routine, a headless or pipeline run, a session started by a trigger, an agent working alone. A question there is never answered, so the session either stalls on it or drops grounding without a word, and a reader of the transcript cannot tell that from forgetting.

**When a session is unattended.** Treat the session as unattended when no person can answer in it, or when you cannot tell. An unasked question costs less than an unanswered one. The session-start role-grounding directive fires before anyone has spoken, so a `glassfrog_get_me` failure on that path takes the unattended branch even when a person later turns up. A role skill a person invokes during the session follows the interactive asks above. A session that has no `glassfrog_get_me` tool and runs no role skill never starts this procedure, so it writes no unbound line.

**The rule.** On an unattended path, every ask becomes one line that names the gap, and the session proceeds **unbound**. No retry loop, and no question.

**The line.** It always starts the same way, so it parallels `Operating as **Role of Circle**` and can be found in a transcript:

> Operating **unbound**: <the gap, in one clause>.

Write it once, in the opening lines, where the role announcement would have gone.

**What unbound permits.** Work that needs no role's authority: reading, analysis, code, drafts, and read-only GlassFrog calls.

**What unbound forbids.**

- Claiming a role. Do not write `Operating as ...`, and do not attribute output to a role. The one exception is a routine's declared role, which may author drafts (see [A routine's declared role](#a-routines-declared-role)).
- GlassFrog writes that act from a role: tensions, projects, actions, proposals, notes, tags, checklist items, metrics, goal updates. Draft them as text instead, and say which role they would need.
- Picking a role or circle by guess, so the record shows a binding that never happened.

**Leaving unbound.** A session leaves the state when a person names the role, or when resolution later succeeds (for example, a reconnected connector). Announce the new context in the usual way (Step 4). Do not file anything retroactively under a role chosen after the fact without saying so.

### A routine's declared role

A scheduled routine declares its acting role in its prompt (see [Scheduled Routines](#scheduled-routines-context-encoding-at-creation-time)). When `glassfrog_get_me` succeeds, the routine operates as that role in the usual way. When it fails, nothing confirms the declaration. The session stays unbound, but it keeps the declared role as the author of its drafts:

> Operating **unbound**: glassfrog_get_me failed (<the error>); drafts are attributed to <declared Role of Circle>, unverified.

It drafts as that role and writes nothing to GlassFrog, even where a policy would let the role write unattended. A write needs a verified binding.

A pre-declared default role, which would let an unattended session bind without a GlassFrog call, is a separate mechanism and is not part of this procedure.

---

## Cross-Skill Load Guide

This document is referenced from multiple holacracy skills. The relevant sections depend on the skill context:

| If you're working in... | Most relevant sections |
|---|---|
| `self-org-facilitator` | Steps 1-4 (resolution); Engagement Modes (Facilitator is Actor in meetings, Advisor outside) |
| `self-org-secretary` | Steps 1-5 (especially Step 5 re: meeting-day staleness); Scheduled Routines preamble |
| `self-org-lead-link` | Steps 1-4; Engagement Modes (most Lead Link work is Actor or Advisor) |
| `self-org-rep-link` | Steps 1-4; Engagement Modes (Rep Link mostly Advisor when carrying tensions) |
| `self-org-ai-governance` | All sections -- this skill is the operating frame; resolution is foundational |
| `self-org-policy-steward` (v0.4) | Steps 1-4; resolution may target a circle scope rather than a single role |
| `self-org-circle-member` (v0.4) | Steps 1-3 (often the actor fills many roles in the circle; resolve circle scope, then list all roles the actor fills there) |
| Scheduled routines (v0.3+) | Scheduled Routines section is the canonical prompt-preamble spec |
| `/self-org:context` slash command | Whole document -- this command is the user's surface for the resolution machinery |
