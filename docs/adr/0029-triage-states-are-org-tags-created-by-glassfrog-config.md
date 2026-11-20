# 29. Triage states are org tags, created by glassfrog-config

Date: 2026-11-20

## Status

Accepted (2026-11-20, Kraig Parkinson: chose the split on glassfrog-mcp-server #290)

Amends [ADR-0019](0019-the-triage-state-vocabulary-lives-in-the-plugin.md): the plugin
still owns the list of state names, but it no longer relies on GlassFrog creating a tag
from a name. `glassfrog-config` creates the org tags.

## Context

ADR-0019 assumed that `glassfrog_set_project_tags` creates any tag name it is sent. That
was true of the old write path, which used the GlassFrog web app's session and wrote
**string tags**.

On 2026-11-20 the GlassFrog MCP server moved project and action tag writes to the v5 tag
endpoints (its ADR 0015, PR #292). Those endpoints link only **org tags**, which an admin
creates first. Org tags are one list shared with role tags. Three things followed:

1. A state name with no org tag fails with "No org tag is named" and writes nothing.
2. Full replace now covers org tags only. Older string tags cannot be listed, linked or
   removed through the API, and naming one in `tag_names` fails the whole call.
3. Triage Step 3 sent the project's full `tags` back, which mixes string tags and org
   tags. Every state write on a project with a string tag therefore failed.

`/self-org:project-triage` was broken in production from the merge of PR #292 until the
change this ADR records.

## Decision

1. The plugin keeps the closed list (`skills/shared/triage-states.md` Step 1). It is the
   source that `glassfrog-config` imports (that repository's ADR 0007).
2. `glassfrog-config` creates each state as an org tag and checks it for collisions with
   the other org tags. The plugin never calls `glassfrog_create_tag` to make a write
   succeed.
3. Step 3's read-modify-write runs over org tags only: start from the last response's
   `org_tags`, or from the project's `tags` filtered by `glassfrog_list_tags`. Never send
   a string tag.
4. A leftover string tag that names a state is left in place and ignored. When a project
   shows more than one state, the last triage note line decides, as it already does when
   a tag write failed (ADR-0022 and `project-triage-gates.md` Step 6). The pass summary
   lists such tags so a person can remove them in the web app.

## Consequences

- A typo in a state name now fails loudly instead of creating a stray tag. Step 2's
  refusal stays, because a wrong name that is a real org tag would still be linked.
- Adding or renaming a state now needs three changes in order: this file's table,
  `glassfrog-config`'s import with a new org tag, then any migration of existing tags.
- Tag writes need admin access in GlassFrog. A non-admin triager gets drafts only for the
  tag, while the note line and status still write.
- Projects can show a state twice, or two states, until the string-tag backfill in
  glassfrog-mcp-server #290 (phases 4 to 6) runs.
