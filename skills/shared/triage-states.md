# Triage States -- Shared Reference

This is the closed list of triage states the plugin may write onto a GlassFrog project. A state is a **route**: it says what the project needs next before anyone can act on it. It is not a quality verdict. The quality verdicts (`needs-outcome`, `needs-next-action`, and the rest) live in `skills/shared/project-well-formedness.md` and are never written as tags. See [ADR-0018](../../docs/adr/0018-separate-project-readiness-from-project-quality.md) for the split and [ADR-0019](../../docs/adr/0019-the-triage-state-vocabulary-lives-in-the-plugin.md) for why the list lives here.

Loaded by:

- `/self-org:project-triage`, the only surface that writes these states. Its gates and routing live in `./project-triage-gates.md`.
- Any surface that reads a project's triage state, such as a queue of `ready-for-agent` work.

## Step 1 -- The closed list

A project carries **at most one** of these tags. No tag means the project has never been triaged.

| State | Meaning | Who acts next |
|---|---|---|
| `needs-triage` | Not yet assessed, or reopened because something moved | the triager |
| `needs-info` | A named role or party must answer a recorded question before anyone can act | the role or party the note line names |
| `ready-for-agent` | Well enough formed that an AI agent filler can take the next action | an agent filler |
| `ready-for-human` | Well enough formed, but the next action needs a person | a human filler |

**`needs-info` and status.** The project stays `current` when the owner role must answer, and moves to `waiting` when another role, circle, or outside party must (ADR-0022). The tag is the same in both cases, so one tag lists the whole queue.

**Archive is not a state.** A project that fails a reality gate (done, duplicate, superseded, owner role gone) leaves the list through its GlassFrog `status` (`archived`, or `completed` when the outcome exists), with the reason in its note. `/self-org:project-sweep` already archives this way.

The names match the hand-set tags already found on live projects and the issue-triage labels in `docs/agents/triage-labels.md`, so one vocabulary covers both.

## Step 2 -- Refuse any other name before the write

Before any `glassfrog_set_project_tags` call that sets a triage state:

1. Compare the state name to the table in Step 1, character for character. Lowercase, hyphens, no plural, no prefix.
2. If it is not in the table, **refuse the write** and say which name was refused. Do not pick the nearest match, and never create a tag (`glassfrog_create_tag`) to make a write succeed.

**Why:** the four states are **org tags**. Roles, projects and actions share one org-tag list, and `glassfrog_set_project_tags` links only names already on that list ([ADR-0029](../../docs/adr/0029-triage-states-are-org-tags-created-by-glassfrog-config.md)). A misspelled state (a stray plural `s` on `ready-for-agent`) now fails with "No org tag is named" and writes nothing. A wrong name that *is* an org tag, such as a role tag, would still be linked, so this check stays.

**Who creates them:** this file names the states; `glassfrog-config` imports the names and creates the org tags (its ADR 0007). If a write fails with "No org tag is named" for a name in the Step 1 table, the org tag is missing in GlassFrog: say so, keep the state as a draft, and point to `glassfrog-config`. Do not create the tag from here.

## Step 3 -- Keep the project's other org tags

`glassfrog_set_project_tags` replaces the project's whole **org-tag** set: the array sent becomes every org tag on the project, and `[]` clears them. Older **string tags**, written by the GlassFrog web app before tags moved to org tags, are not org tags. The tool cannot send, list or remove them, and a string-tag name in the array fails the whole call with "No org tag is named". So a state change is a read-modify-write over org tags only:

1. Read the project's current org tags. Use the `org_tags` array of the last `glassfrog_set_project_tags` response for this project in this session. Before the first write, read the project's `tags` with `glassfrog_get_project` and the org-tag names with `glassfrog_list_tags` (read once per pass), and keep only the names that are on the org-tag list, compared without case.
2. Remove any name that is in the Step 1 table.
3. Add the one new state.
4. Send the result. Never send a name from the response's `string_tags`.

Never send only the new state. That removes every org tag the project's owner set for another reason.

**Older string tags stay.** A project can keep a string tag that names a state, for example a hand-set `ready-for-human`, next to the org tag this command writes. The API cannot remove it, so leave it in place and do not count it: when a project shows more than one state name, the route on its last triage note line wins, and the org tag in the last response's `org_tags` confirms it. List each leftover state string tag in the pass summary, so a person can remove it in the GlassFrog web app.

The live argument is `tag_names`. Every state write also appends a dated reason line to the project note, before the tag write; the format and the order are in `./project-triage-gates.md` Step 6.

## Changing the list

Add, rename, or remove a state only by editing the Step 1 table, in the same pull request as every surface that reads or writes it. `scripts/skills-lint.sh` check 11 fails any shipped file that names a `needs-*` or `ready-for-*` state found in neither this table nor the rubric's state table, and fails a name that appears in both. Renaming a live state also needs a migration of the tags already on projects, which this list cannot do for you.
