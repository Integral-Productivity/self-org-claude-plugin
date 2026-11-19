# Decision Keys -- Shared Reference

This is the one vocabulary for the letter keys in every per-item menu: the walk commands (`/self-org:tension-triage`, `/self-org:project-triage`, `/self-org:project-review`, `/self-org:project-sweep`, `/self-org:tension-sweep`) and the draft-and-confirm blocks of the capture flows (`./tension-capture-flow.md`, `./project-capture-flow.md`). Each key has **one meaning** across all of them.

Loaded by:

- Every command, skill, or subagent that shows a per-item letter menu. Cite this file next to the menu.
- `scripts/skills-lint.sh` check 15, which reads the table in Step 1.
- `scripts/skills-lint.sh` check 16, which fails a walk command that shows a letter menu and does not cite Step 3.

**Why:** a user who learns one walk carries its keys into the next. Before this file, `[a]` meant *archive* (a status change) in three walks and *apply* (a new action) in `/self-org:project-review`; `[c]` had three meanings and `[e]` had two ([#460](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/460)). A key that changes meaning between commands makes the wrong write.

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
| `[r]` | `review` | Name `/self-org:project-review <project>` for the user to run on this one project. The walk does not start it: the review is user-only (#464). | none |
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

## Step 3 -- Showing the menu in the picker

A walk shows each per-item decision in the host's multiple-choice question tool when the host offers one (`AskUserQuestion` in Claude Code, a decision card in other hosts). The letter-menu block that the walk writes out is the fallback for a host with no such tool. Both paths use the same keys with the same meanings, and neither path writes anything until the user chooses ([#461](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/461)).

**Why:** a picker cannot be mistyped, it shows the consequence of each choice, and the user does not have to read field names to decide. The host shows at most four options, so the walk chooses which keys come first.

1. **Above the picker**, show the verdict for this item and one sentence of reason. Keep field values, ids, and API call names out of this text. They go behind `show detail` (item 5).
2. **Option 1** is the walk's recommended key for this item. Its label is the key, the table label, and "(Recommended)", for example `[e] edit (Recommended)`. When the walk has no recommendation for this item, do not mark any option.
3. **Options 2 and 3** are the two other keys most likely to fit this item, for example `[d] defer` and `[a] archive`.
4. **Option 4** is `More options`. It opens a second picker with the rest of the walk's menu keys, then `show detail`. If more than four remain, the second picker shows three of them and `More options` again. `[q] quit` is always in the rest.
5. **`show detail`** is not a key and writes nothing. It shows the full fallback block for this item, then asks again with the same picker.
6. **Each option's description** is one line that says what the choice does to this item, taken from the Meaning column of Step 1. For example: "Sets this tension's status to archived."
7. **A typed answer** (the picker's free-text "Other") that is a key letter, such as `q`, counts as that key. Any other text is a question or an edit request, not a choice: answer it, then ask again.
8. **Fallback.** When the host has no question tool, show the walk's letter-menu block as it is written and read the key the user types.
