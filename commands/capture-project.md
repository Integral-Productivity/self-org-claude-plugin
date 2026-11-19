---
description: Deprecated alias for /self-org:commit-project. Runs it and names the new command once. Removed in 2.0.0.
argument-hint: [same arguments as /self-org:commit-project]
disable-model-invocation: true
---

# /self-org:capture-project — deprecated

This command has been renamed to **`/self-org:commit-project`**.

## What to do

1. Tell the user, once, in a single line:

   > `/self-org:capture-project` is now `/self-org:commit-project` — running it for you.

   Say it once and move on. Do not explain the rename and do not ask whether to proceed.

2. Run [`commands/commit-project.md`](./commit-project.md) with `$ARGUMENTS` passed through unchanged.

## Why the rename

Command names follow one rule by act type ([ADR-0028](../docs/adr/0028-commands-are-named-by-act-type.md)): an authority act starts with its authority verb, and a backlog walk starts with the work item it walks. The old name is kept as an alias because it shipped on the `stable` branch that both install channels track. It is removed in 2.0.0.
