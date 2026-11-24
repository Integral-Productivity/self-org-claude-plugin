---
title: "Keychain tests (G27 and on) fail where python3 cannot posix_spawn with setsid"
date: 2026-11-22
last_updated: 2026-11-23
category: test-failures
module: grounding-hook
problem_type: test_failure
component: tooling
symptoms:
  - "`bash hooks-handlers/session-start.test.sh` fails at G27: an authenticated glassfrog entry in the Keychain must let the directive through (#318)"
  - "The same failure on `origin/main`, so it is not caused by the branch under test"
  - "CI (ubuntu-latest) passes the same commit"
root_cause: incomplete_setup
resolution_type: environment_setup
severity: low
related_components:
  - session-start-hook
  - keychain-credential-probe
tags:
  - python
  - posix-spawn
  - setsid
  - cloud-container
  - local-only-failure
  - fail-closed
---

# Keychain tests (G27 and on) fail where python3 cannot posix_spawn with setsid

> **Resolved in the hook by #525 (2026-11-23).** `keychain_item()` now retries the spawn with `setpgroup=0` when `setsid` raises `NotImplementedError`, and catches a spawn that still fails on purpose, so the file store is consulted. G27b and G27c in `session-start.test.sh` hold this on every interpreter through a `sitecustomize` shim. The interpreter workaround below is needed only on a branch cut before that fix.

## Problem

In some Linux containers the SessionStart hook's test suite fails at G27, on every branch including `main`. The cause is the interpreter, not the plugin: the hook's credential probe spawns `security` with `os.posix_spawnp(..., setsid=True)`, and that Python build cannot honour `setsid`.

## Symptoms

- `bash hooks-handlers/session-start.test.sh` stops at G27 with the #318 message.
- `git stash` or a checkout of `origin/main` gives the same failure, so it looks like a regression that is already on `main`.
- CI on `ubuntu-latest` is green on the same commit.

## What Didn't Work

- Reading the failure as a regression in the change under test. The failure reproduces on `main`, so the diff is not the cause.
- Looking at the Keychain stub in the test (`$STUB_BIN/security`). The stub is never reached: the spawn fails before it runs.

## Solution

Check the interpreter first:

```bash
python3 -c "import os; os.posix_spawnp('true', ['true'], os.environ, setsid=True)"
# NotImplementedError: posix_spawnp: setsid unavailable on this platform
```

If that raises, put an interpreter that supports it first on `PATH` for the test run only. In the 2026-11 cloud containers, `/usr/local/bin/python3` (3.13) raised and `/usr/bin/python3.12` did not:

```bash
mkdir -p /tmp/py && ln -sf /usr/bin/python3.12 /tmp/py/python3
PATH=/tmp/py:$PATH bash hooks-handlers/session-start.test.sh
```

The interpreter versions are this session's observation, not a rule: test the interpreter, do not assume one by version number.

## Why This Works

`keychain_item()` in `hooks-handlers/session-start.sh` catches only `OSError` around the `posix_spawnp` call. `NotImplementedError` is not an `OSError`, so it escapes, the embedded Python script exits non-zero, and the hook takes the no-credential path: it emits the conditional directive. G27 expects the unconditional directive, so it fails. With an interpreter that supports `setsid`, the spawn reaches the stub and G27 passes.

The hook fails closed here: a session on such an interpreter gets the conditional directive, not a false claim of authentication. That is the safe direction, which is why this is a test-environment problem and not a production defect.

## Prevention

- Before you treat a G27-or-later failure as a regression, run the one-line interpreter check above.
- The open question this entry first recorded (should `keychain_item()` catch `NotImplementedError`?) was decided in #525: yes, on purpose, with a `setpgroup=0` retry first so the timeout can still kill the whole process group.
