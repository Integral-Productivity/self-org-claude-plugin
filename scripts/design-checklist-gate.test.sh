#!/usr/bin/env bash
# Regression tests for scripts/design-checklist-gate.sh.
#
# Run: bash scripts/design-checklist-gate.test.sh
# No framework -- plain asserts. Exits non-zero on first failure.
#
# The gate is the CI half of the design checklist (#465): a pull request that
# changes a command, skill or subagent must tick the checklist box in its body.
# Its failure mode is silence -- a gate that always passes merges green -- so
# every "must fail" case below is paired with a "must pass" case that differs
# in one detail, and the exit code is asserted exactly, not only as non-zero.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$HERE/design-checklist-gate.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CASES=0

fail() { echo "FAIL: $*" >&2; exit 1; }

# $1 = expected exit, $2 = label, $3 = body text, $4 = changed paths (newline-separated)
expect() {
  printf '%s' "$3" > "$TMP/body"
  printf '%s\n' "$4" > "$TMP/changed"
  local rc=0
  bash "$GATE" --body-file "$TMP/body" --changed-file "$TMP/changed" >"$TMP/out" 2>&1 || rc=$?
  [ "$rc" = "$1" ] || { cat "$TMP/out" >&2; fail "$2: expected exit $1, got $rc"; }
  CASES=$((CASES + 1))
}

TICKED='- [x] Checked against docs/plugin-design-checklist.md'
UNTICKED='- [ ] Checked against docs/plugin-design-checklist.md'

# 1. No command, skill or subagent changed: no box needed.
expect 0 "docs-only change" "no box here" $'README.md\nscripts/foo.sh'

# 2. A command changed and the box is ticked.
expect 0 "command changed, box ticked" "Summary"$'\n'"$TICKED" "commands/sense-tension.md"

# 3. The same change with the box unticked fails.
expect 1 "command changed, box unticked" "Summary"$'\n'"$UNTICKED" "commands/sense-tension.md"

# 4. The same change with no box at all fails.
expect 1 "command changed, no box" "Summary only" "commands/sense-tension.md"

# 5. A skill file, a shared reference and a subagent each count as a surface.
expect 1 "skill changed, no box" "x" "skills/self-org-secretary/SKILL.md"
expect 1 "shared reference changed, no box" "x" "skills/shared/decision-keys.md"
expect 1 "subagent changed, no box" "x" "agents/tension-capture.md"

# 6. GitHub renders [X] as ticked too.
expect 0 "uppercase X" "- [X] Checked against docs/plugin-design-checklist.md" "agents/tension-capture.md"

# 7. A ticked box that names something else does not count.
expect 1 "ticked box for another file" "- [x] Checked against README.md" "commands/context.md"

# 8. A path that only contains a surface name does not count as a surface.
expect 0 "lookalike path" "x" $'docs/commands/notes.md\nevals/skills/x.json'

# 9. Usage errors exit 2, never 0.
rc=0; bash "$GATE" >/dev/null 2>&1 || rc=$?
[ "$rc" = 2 ] || fail "no arguments: expected exit 2, got $rc"
rc=0; bash "$GATE" --body-file "$TMP/nope" --changed-file "$TMP/changed" >/dev/null 2>&1 || rc=$?
[ "$rc" = 2 ] || fail "missing body file: expected exit 2, got $rc"
CASES=$((CASES + 2))

echo "design-checklist-gate.test.sh: $CASES cases passed"
