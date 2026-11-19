#!/usr/bin/env bash
#
# design-checklist-gate.sh -- fail a pull request that changes a command, skill
# or subagent unless its body ticks the design-checklist box.
#
# Run:  bash scripts/design-checklist-gate.sh --body-file <f> --changed-file <f>
#         --body-file     the pull request body, as text
#         --changed-file  the changed paths, one per line
# Exit: 0 pass, 1 box missing or unticked, 2 usage or input error.
#
# WHY THIS EXISTS
# ---------------
# CLAUDE.md asks contributors to check a changed surface against
# docs/plugin-design-checklist.md (#465). An instruction alone drifts: nothing
# notices when it is skipped. This gate makes the step visible in every pull
# request that needs it. It cannot prove the reader did the check; it proves
# the author claimed it, in the place a reviewer reads. The items a machine can
# check are lint checks in skills-lint.sh instead.
#
# The body is untrusted text. It is read from a file, never interpolated into
# a command.
set -euo pipefail

usage() { echo "usage: $0 --body-file <file> --changed-file <file>" >&2; exit 2; }

BODY="" CHANGED=""
while [ $# -gt 0 ]; do
  case "$1" in
    --body-file) [ $# -ge 2 ] || usage; BODY="$2"; shift 2 ;;
    --changed-file) [ $# -ge 2 ] || usage; CHANGED="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$BODY" ] && [ -n "$CHANGED" ] || usage
[ -f "$BODY" ] || { echo "design-checklist-gate: body file not found: $BODY" >&2; exit 2; }
[ -f "$CHANGED" ] || { echo "design-checklist-gate: changed-file not found: $CHANGED" >&2; exit 2; }

surfaces="$(grep -E '^(commands|agents|skills)/' "$CHANGED" || true)"
if [ -z "$surfaces" ]; then
  echo "design-checklist-gate: no command, skill or subagent changed; no box needed."
  exit 0
fi

if grep -qE '^[[:space:]]*[-*][[:space:]]+\[[xX]\][[:space:]].*plugin-design-checklist\.md' "$BODY"; then
  echo "design-checklist-gate: box ticked for:"
  printf '%s\n' "$surfaces" | sed 's/^/  /'
  exit 0
fi

echo "::error::This pull request changes a command, skill or subagent, but its body does not tick the design-checklist box."
echo "Changed surfaces:"
printf '%s\n' "$surfaces" | sed 's/^/  /'
echo "Check each one against docs/plugin-design-checklist.md, then tick this line in the pull request body:"
echo "  - [x] Checked against docs/plugin-design-checklist.md"
exit 1
