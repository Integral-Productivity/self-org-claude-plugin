---
title: "A quoted ${var//pat/\"$rep\"} keeps its quotes on macOS /bin/bash"
date: 2026-11-23
category: build-errors
module: grounding-hook
problem_type: runtime_error
component: tooling
symptoms:
  - "A hook's output carries literal double quotes around a substituted value on a Mac, but not in CI or a Linux container"
  - "A path spliced into hook text with ${var//pat/\"$rep\"} does not resolve on macOS"
root_cause: platform_difference
resolution_type: code_fix
severity: medium
related_components:
  - session-start-hook
tags:
  - bash
  - bash-3.2
  - macos
  - pattern-substitution
  - portability
---

# A quoted `${var//pat/"$rep"}` keeps its quotes on macOS /bin/bash

## Problem

The SessionStart hook runs under `#!/usr/bin/env bash`. On a stock Mac that is `/bin/bash` 3.2. While fixing #524, the hook first spliced the plugin path into the directive with `"${grounding//@RESOLUTION_DOC@/"$RESOLUTION_DOC"}"`. Every test passed on bash 5, but on bash 4.2 and earlier the inner quotes are not removed, so the directive cited `` `"/path/to/actor-and-role-resolution.md"` ``, a path that names nothing.

The quotes looked necessary: bash 5.2 treats an unquoted `&` in the replacement as the matched text, so `"${s//pat/$rep}"` breaks for a value with `&` in it. Each version's fix is the other version's bug.

## Solution

Avoid the replacement string. When the placeholder appears once, splice with prefix and suffix removal, which has the same meaning on every bash version:

```bash
grounding="${grounding%%@RESOLUTION_DOC@*}${RESOLUTION_DOC}${grounding#*@RESOLUTION_DOC@}"
```

## Prevention

- Test bash 3.2 behavior on Linux with `BASH_COMPAT=42`. It reproduces the pre-4.3 quote handling, so the hook test runs G1b under it too.
- Distrust any `${var//pat/rep}` in a script that runs on a user's Mac. Check it at `BASH_COMPAT=42` and on bash 5.2 with an `&` in the value.
