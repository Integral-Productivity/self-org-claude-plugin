# Decision Keys -- Shared Reference

This is the one vocabulary for the letter keys in every per-item menu: the walk commands (`/self-org:tension-triage`, `/self-org:project-triage`, `/self-org:review-project`, `/self-org:stalled-project-sweep`, `/self-org:supersession-sweep`) and the draft-and-confirm blocks of the capture flows (`./tension-capture-flow.md`, `./project-capture-flow.md`). Each key has **one meaning** across all of them.

Loaded by:

- Every command, skill, or subagent that shows a per-item letter menu. Cite this file next to the menu.
- `scripts/skills-lint.sh` check 15, which reads the table in Step 1.

**Why:** a user who learns one walk carries its keys into the next. Before this file, `[a]` meant *archive* (a status change) in three walks and *apply* (a new action) in `/self-org:review-project`; `[c]` had three meanings and `[e]` had two ([#460](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/460)). A key that changes meaning between commands makes the wrong write.

## Step 1 -- The keys

A menu line starts with the key and then the label in the second column, word for word. Text after the label (an object such as "false positive" or "A", a dash, the `->` call) is free. A key that is not in this table is not used in a menu.

| Key | Label | Meaning | Write |
|---|---|---|---|
| `[a]` | `archive` | Set the item's status to `archived`. | status change |
| `[c]` | `complete` | Set the project's status to `completed`. | status change |
| `[p]` | `mark processed` | Set the tension's status to `processed`. | status change |
| `[w]` | `write` | Write exactly the draft shown above: a note line, a tag, an action, a goal link, or the status the draft block names. Never `archived` or `completed`; those have their own keys. | the draft shown |
| `[u]` | `unstick` | Draft a next action for a stalled project, show it, and create it on confirmation. | new action |
| `[e]` | `edit` | Change the shown draft or body, then show it again before any write. | none until confirmed |
| `[m]` | `merge` | Fold one tension's specifics into another, then archive the first. | body change + status change |
| `[x]` | `exchange` | Swap the two items' roles in the pair and draft again. | none |
| `[h]` | `authority held` | Name the authority the role already holds; offer the conversion. | none until confirmed |
| `[r]` | `review` | Hand this one project to `/self-org:review-project`. | none |
| `[t]` | `route tension` | Hand this finding to the `tension-capture` subagent. | none until confirmed |
| `[v]` | `view draft` | Show an advisory draft that the user applies in GlassFrog. | none |
| `[y]` | `yes` | Confirm the block shown and write it. | the draft shown |
| `[n]` | `no` | Do not write this draft. | none |
| `[d]` | `defer` | No write for this item; it stays as it is. | none |
| `[k]` | `keep both` | No write for either item in the pair. | none |
| `[s]` | `skip` | No write for this finding or optional step. | none |
| `[q]` | `quit` | Stop the walk; every item not yet written stays as it is. | none |

## Step 2 -- Adding or changing a key

1. A new action gets a new key. Never give an existing key a second meaning, even in a command where the first meaning does not appear.
2. A key whose label names a status change (`archive`, `complete`, `mark processed`, `merge`) never creates or links anything. A key that creates or links (`write`, `unstick`, `yes`) never archives or completes.
3. Add the row here first, in the same PR as the menu that uses it. Check 15 fails a menu key or label that this table does not hold.
