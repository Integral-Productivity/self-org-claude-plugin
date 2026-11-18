#!/usr/bin/env bash
# The graded eval job's budget decision, kept out of the workflow so that
# scripts/eval-graded-budget.test.sh can check every branch offline, on every
# PR. Embedded in the workflow, this arithmetic ran only on the nightly, and
# when the case count grew from 4 to 10 the nightly refused its own default
# (runs=3 against a ceiling of 2) every night for weeks with no other signal.
#
# Two subcommands, because `runs` is one of the cache key's inputs: it must be
# known before the runner can count which legs the cache will skip.
#
#   resolve --event E [--schedule S] --weekly-cron C [--runs-input N]
#       Prints runs=N. A scheduled run on the weekly cron gets WEEKLY_RUNS (a
#       variance read). Any other scheduled run gets NIGHTLY_RUNS (a cheap
#       signal on each change). Any other event keeps its dispatch input,
#       default 3. Refuses a value that is not a positive integer, or that is
#       above the spend cap.
#
#   decide --runs N --fresh-legs F --workflow PATH
#       Prints action=run or action=skip. F is the count of legs the change-
#       aware cache will not skip (run-behavioural-eval.py --plan-only). Zero
#       means nothing the evals measure has changed: skip, and pay for
#       nothing. Otherwise only the fresh legs are priced against the job's
#       one timeout-minutes, read from PATH so the two cannot drift apart, and
#       a run that cannot finish is refused with the arithmetic.
#
# Exit codes: 0 decided, 1 refused (the message says why), 2 usage error.

set -euo pipefail

NIGHTLY_RUNS=1
WEEKLY_RUNS=3
DEFAULT_DISPATCH_RUNS=3
# The flat cap that predates the wall-clock bound. It is a spend guard, and
# the wall-clock bound has not replaced it: a smaller case count must not
# quietly allow a 20-run dispatch.
SPEND_CAP=10
# Measured, not guessed: run 31053788703 spent ~36 minutes on 3 evals x 3 runs
# x 2 configs = 18 executions. The 2026-08-17 baseline measured ~216 s for a
# with_skill execution, so this is optimistic; replacing it with a value read
# from the last run is a follow-up listed on issue #467.
MINUTES_PER_EXECUTION=2
# Everything either side of the eval loop: checkout, node, the CLI install,
# the aggregator fetch, aggregate, report, upload, plus slack for a slow runner.
OVERHEAD_MINUTES=10

usage() {
  cat >&2 <<'EOF'
usage: eval-graded-budget.sh resolve --event E [--schedule S] --weekly-cron C [--runs-input N]
       eval-graded-budget.sh decide --runs N --fresh-legs F --workflow PATH
EOF
  exit 2
}

refuse() {
  echo "::error::$1" >&2
  shift
  local line
  for line in "$@"; do echo "$line" >&2; done
  exit 1
}

cmd_resolve() {
  local EVENT="" SCHEDULE="" WEEKLY_CRON="" RUNS_INPUT=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --event) EVENT="${2-}"; shift 2 ;;
      --schedule) SCHEDULE="${2-}"; shift 2 ;;
      --weekly-cron) WEEKLY_CRON="${2-}"; shift 2 ;;
      --runs-input) RUNS_INPUT="${2-}"; shift 2 ;;
      *) usage ;;
    esac
  done
  [ -n "$EVENT" ] && [ -n "$WEEKLY_CRON" ] || usage

  local RUNS
  if [ "$EVENT" = "schedule" ]; then
    if [ "$SCHEDULE" = "$WEEKLY_CRON" ]; then
      RUNS=$WEEKLY_RUNS
    else
      RUNS=$NIGHTLY_RUNS
    fi
  else
    RUNS="${RUNS_INPUT:-$DEFAULT_DISPATCH_RUNS}"
  fi

  case "$RUNS" in
    ''|*[!0-9]*|0*) refuse "runs must be a positive integer, got '$RUNS'." ;;
  esac
  if [ "$RUNS" -gt "$SPEND_CAP" ]; then
    refuse "runs=$RUNS is above the spend cap of $SPEND_CAP." \
      "The cap is a spend guard and holds whatever the timeout allows."
  fi
  echo "runs=$RUNS"
}

cmd_decide() {
  local RUNS="" FRESH_LEGS="" WORKFLOW=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --runs) RUNS="${2-}"; shift 2 ;;
      --fresh-legs) FRESH_LEGS="${2-}"; shift 2 ;;
      --workflow) WORKFLOW="${2-}"; shift 2 ;;
      *) usage ;;
    esac
  done
  # A count that did not arrive is a broken plan step, not "nothing changed":
  # reading it as zero would skip every night and report health it never measured.
  case "$RUNS" in ''|*[!0-9]*) usage ;; esac
  case "$FRESH_LEGS" in ''|*[!0-9]*) usage ;; esac
  [ -f "$WORKFLOW" ] || usage

  # Exactly one timeout-minutes, or this would silently price against the
  # wrong job's ceiling.
  local TIMEOUTS
  TIMEOUTS=$(grep -cE '^[[:space:]]*timeout-minutes:' "$WORKFLOW" || true)
  if [ "$TIMEOUTS" -ne 1 ]; then
    refuse "expected exactly one timeout-minutes in $WORKFLOW, found $TIMEOUTS." \
      "The runs budget is derived from it and cannot tell which job it belongs to."
  fi

  if [ "$FRESH_LEGS" -eq 0 ]; then
    echo "action=skip"
    return 0
  fi

  local TIMEOUT_MINUTES BUDGET NEEDED
  TIMEOUT_MINUTES=$(grep -E '^[[:space:]]*timeout-minutes:' "$WORKFLOW" | tr -dc '0-9')
  BUDGET=$((TIMEOUT_MINUTES - OVERHEAD_MINUTES))
  NEEDED=$((RUNS * FRESH_LEGS * MINUTES_PER_EXECUTION))
  echo "$FRESH_LEGS fresh legs x runs=$RUNS at ~${MINUTES_PER_EXECUTION}min each" \
       "= ${NEEDED}min of ${BUDGET}min usable (timeout-minutes: $TIMEOUT_MINUTES," \
       "minus ${OVERHEAD_MINUTES}min overhead)" >&2
  if [ "$NEEDED" -gt "$BUDGET" ]; then
    refuse "runs=$RUNS needs ~${NEEDED}min for $FRESH_LEGS fresh legs against a ${BUDGET}min budget." \
      "Raise timeout-minutes in $WORKFLOW, or dispatch with a lower runs, if this run is wanted."
  fi
  echo "action=run"
}

[ $# -ge 1 ] || usage
SUB="$1"; shift
case "$SUB" in
  resolve) cmd_resolve "$@" ;;
  decide) cmd_decide "$@" ;;
  *) usage ;;
esac
