#!/usr/bin/env bash
# Offline, mutation-checked suite for scripts/eval-graded-budget.sh: the
# decision that sets how many runs the graded eval job makes, refuses a run
# that cannot finish inside the job's timeout, and skips a night on which no
# leg would execute.
#
# Each check has two cases: an input that only that check catches, and a
# mutant with only that check removed, on which the same input must stop
# being caught. The second half proves the check is load-bearing rather than
# incidentally covered by another. The mutant builder's exit status is checked
# and self-tested against an absent target, because a builder that silently
# produced no mutant would make every mutation case pass vacuously.
#
# The last section reads .github/workflows/skills-eval.yml to check that the
# graded job actually calls this script and gates its paid steps on it. The
# graded job needs an API key and a long run, so the alternative is finding a
# wiring mistake on a paid nightly.

# shellcheck disable=SC2016  # mutation targets are literal script text, never expanded
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SCRIPT="$HERE/eval-graded-budget.sh"
WF="$REPO/.github/workflows/skills-eval.yml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }
CASES=0
pass() { CASES=$((CASES + 1)); }

WEEKLY="0 7 * * 0"
NIGHTLY="0 7 * * 1-6"

# A workflow fixture with exactly one timeout. $1 = path, $2 = minutes,
# $3 = how many timeout-minutes lines to write.
write_workflow() {
  local i
  : > "$1"
  for ((i = 0; i < $3; i++)); do
    printf 'jobs:\n  j%d:\n    timeout-minutes: %s\n' "$i" "$2" >> "$1"
  done
}
write_workflow "$TMP/wf-150.yml" 150 1
write_workflow "$TMP/wf-90.yml" 90 1
write_workflow "$TMP/wf-two.yml" 150 2

# Runs a subcommand; stdout to $TMP/out, stderr to $TMP/err; echoes the exit code.
run() {  # $1 = script, rest = args
  local s="$1"; shift
  bash "$s" "$@" >"$TMP/out" 2>"$TMP/err"
  echo $?
}
field() { sed -n "s/^$1=//p" "$TMP/out"; }

# Builds a mutant of the script with one literal replaced. Fails loudly when
# the target is absent, so a refactor cannot leave a mutation case vacuous.
make_mutant() {  # $1 = name, $2 = literal to replace, $3 = replacement
  local dst="$TMP/mut-$1.sh"
  MUT_OLD="$2" MUT_NEW="$3" python3 - "$SCRIPT" "$dst" <<'PY' || return 1
import os, pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
text = src.read_text()
mutated = text.replace(os.environ["MUT_OLD"], os.environ["MUT_NEW"])
if mutated == text:
    print(f"mutation target not found: {os.environ['MUT_OLD'][:70]!r}", file=sys.stderr)
    raise SystemExit(1)
dst.write_text(mutated)
PY
  echo "$dst"
}

# 0. The mutant builder fails on an absent target.
make_mutant selftest 'this literal is not in the script' 'x' >/dev/null 2>&1 \
  && fail "make_mutant built a mutant from an absent target; every mutation case would be vacuous"
pass

# ---------------------------------------------------------------------------
# resolve: which runs this event gets.
# ---------------------------------------------------------------------------

# 1. The weekly cron runs at 3.
RC="$(run "$SCRIPT" resolve --event schedule --schedule "$WEEKLY" --weekly-cron "$WEEKLY")"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "resolve failed on the weekly cron"; }
[ "$(field runs)" = "3" ] || fail "the weekly cron did not resolve to runs=3: $(cat "$TMP/out")"
MUT="$(make_mutant weekly '[ "$SCHEDULE" = "$WEEKLY_CRON" ]' 'false')" || fail "could not build the weekly mutant"
run "$MUT" resolve --event schedule --schedule "$WEEKLY" --weekly-cron "$WEEKLY" >/dev/null
[ "$(field runs)" = "3" ] && fail "mutation case is vacuous: removing the weekly match still gave runs=3"
pass

# 1b. The weekly cron uses a 6-day cache age. Its runs=3 entries are refreshed
#     only by the weekly run, so they are about 7 days old next Sunday; at the
#     runner's 7-day default about half of those Sundays would skip.
run "$SCRIPT" resolve --event schedule --schedule "$WEEKLY" --weekly-cron "$WEEKLY" >/dev/null
[ "$(field max_age_days)" = "6" ] || fail "the weekly cron did not resolve to max_age_days=6: $(cat "$TMP/out")"
MUT="$(make_mutant weeklyage 'MAX_AGE=$WEEKLY_CACHE_MAX_AGE_DAYS' ':')" || fail "could not build the weekly-age mutant"
run "$MUT" resolve --event schedule --schedule "$WEEKLY" --weekly-cron "$WEEKLY" >/dev/null
[ "$(field max_age_days)" = "6" ] && fail "mutation case is vacuous: the weekly still resolved to max_age_days=6"
pass

# 2. Any other schedule runs at 1, whatever the dispatch default says.
RC="$(run "$SCRIPT" resolve --event schedule --schedule "$NIGHTLY" --weekly-cron "$WEEKLY" --runs-input 3)"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "resolve failed on the nightly cron"; }
[ "$(field runs)" = "1" ] || fail "the nightly cron did not resolve to runs=1: $(cat "$TMP/out")"
[ "$(field max_age_days)" = "7" ] || fail "the nightly did not keep the 7-day cache age: $(cat "$TMP/out")"
MUT="$(make_mutant nightly 'RUNS=$NIGHTLY_RUNS' 'RUNS=$RUNS_INPUT')" || fail "could not build the nightly mutant"
run "$MUT" resolve --event schedule --schedule "$NIGHTLY" --weekly-cron "$WEEKLY" --runs-input 3 >/dev/null
[ "$(field runs)" = "1" ] && fail "mutation case is vacuous: the nightly ignored its own depth and still gave runs=1"
pass

# 3. A dispatch keeps its input, and defaults to 3 when the input is empty.
run "$SCRIPT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input 2 >/dev/null
[ "$(field runs)" = "2" ] || fail "a dispatch did not keep runs=2: $(cat "$TMP/out")"
run "$SCRIPT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input "" >/dev/null
[ "$(field runs)" = "3" ] || fail "an empty dispatch input did not default to runs=3: $(cat "$TMP/out")"
[ "$(field max_age_days)" = "7" ] || fail "a dispatch did not keep the 7-day cache age: $(cat "$TMP/out")"
pass

# 4. runs must be a positive integer.
RC="$(run "$SCRIPT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input abc)"
[ "$RC" = "1" ] || fail "runs=abc was not refused (exit $RC)"
grep -q "positive integer" "$TMP/err" || fail "the refusal of runs=abc did not say why: $(cat "$TMP/err")"
RC="$(run "$SCRIPT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input 0)"
[ "$RC" = "1" ] || fail "runs=0 was not refused (exit $RC)"
MUT="$(make_mutant integer "''|*[!0-9]*|0*)" "__never__)")" || fail "could not build the integer mutant"
RC="$(run "$MUT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input abc)"
[ "$RC" = "1" ] && grep -q "positive integer" "$TMP/err" \
  && fail "mutation case is vacuous: runs=abc was still refused as a non-integer"
MUT="$(make_mutant leadingzero "''|*[!0-9]*|0*)" "''|*[!0-9]*)")" || fail "could not build the leading-zero mutant"
RC="$(run "$MUT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input 0)"
[ "$RC" = "1" ] && fail "mutation case is vacuous: runs=0 was still refused without the leading-zero branch"
pass

# 5. The spend cap: runs above 10 is refused before any model call.
RC="$(run "$SCRIPT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input 11)"
[ "$RC" = "1" ] || fail "runs=11 was not refused on the spend cap (exit $RC)"
grep -q "spend cap" "$TMP/err" || fail "the runs=11 refusal did not name the spend cap: $(cat "$TMP/err")"
MUT="$(make_mutant spendcap '[ "$RUNS" -gt "$SPEND_CAP" ]' 'false')" || fail "could not build the spend-cap mutant"
RC="$(run "$MUT" resolve --event workflow_dispatch --weekly-cron "$WEEKLY" --runs-input 11)"
[ "$RC" = "1" ] && fail "mutation case is vacuous: runs=11 was still refused without the spend cap"
pass

# ---------------------------------------------------------------------------
# decide: run, skip, or refuse.
# ---------------------------------------------------------------------------

# 6. Zero fresh legs skips, on any event, and exits 0.
RC="$(run "$SCRIPT" decide --runs 3 --fresh-legs 0 --workflow "$TMP/wf-150.yml")"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "zero fresh legs did not exit 0"; }
[ "$(field action)" = "skip" ] || fail "zero fresh legs did not skip: $(cat "$TMP/out")"
MUT="$(make_mutant skip '[ "$FRESH_LEGS" -eq 0 ]' 'false')" || fail "could not build the skip mutant"
run "$MUT" decide --runs 3 --fresh-legs 0 --workflow "$TMP/wf-150.yml" >/dev/null
[ "$(field action)" = "skip" ] && fail "mutation case is vacuous: zero fresh legs still skipped"
pass

# 7. The nightly with every leg fresh (10 evals x 2 configs) runs at 1.
RC="$(run "$SCRIPT" decide --runs 1 --fresh-legs 20 --workflow "$TMP/wf-150.yml")"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "a fresh nightly at runs=1 was refused"; }
[ "$(field action)" = "run" ] || fail "a fresh nightly at runs=1 did not run: $(cat "$TMP/out")"
pass

# 8. The weekly with every leg fresh runs at 3 under 150 minutes, and is
#    refused, with the arithmetic, under 90.
RC="$(run "$SCRIPT" decide --runs 3 --fresh-legs 20 --workflow "$TMP/wf-150.yml")"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "a fresh weekly at runs=3 did not fit 150 minutes"; }
[ "$(field action)" = "run" ] || fail "a fresh weekly at runs=3 did not run: $(cat "$TMP/out")"
RC="$(run "$SCRIPT" decide --runs 3 --fresh-legs 20 --workflow "$TMP/wf-90.yml")"
[ "$RC" = "1" ] || fail "a fresh weekly at runs=3 was not refused under 90 minutes (exit $RC)"
if ! grep -q "120min" "$TMP/err" || ! grep -q "80min" "$TMP/err"; then
  fail "the refusal did not show the arithmetic (120min needed, 80min usable): $(cat "$TMP/err")"
fi
MUT="$(make_mutant budget '[ "$NEEDED" -gt "$BUDGET" ]' 'false')" || fail "could not build the budget mutant"
RC="$(run "$MUT" decide --runs 3 --fresh-legs 20 --workflow "$TMP/wf-90.yml")"
[ "$RC" = "1" ] && fail "mutation case is vacuous: the over-budget run was still refused"
pass

# 9. The budget prices only fresh legs: a runs=3 dispatch with half the legs
#    cached fits 90 minutes.
RC="$(run "$SCRIPT" decide --runs 3 --fresh-legs 10 --workflow "$TMP/wf-90.yml")"
[ "$RC" = "0" ] || { cat "$TMP/err"; fail "runs=3 with 10 fresh legs was refused under 90 minutes"; }
[ "$(field action)" = "run" ] || fail "runs=3 with 10 fresh legs did not run: $(cat "$TMP/out")"
pass

# 10. Exactly one timeout-minutes, or the budget cannot know which job it reads.
RC="$(run "$SCRIPT" decide --runs 1 --fresh-legs 1 --workflow "$TMP/wf-two.yml")"
[ "$RC" = "1" ] || fail "two timeout-minutes were not refused (exit $RC)"
grep -q "exactly one timeout-minutes" "$TMP/err" || fail "the refusal did not name the cause: $(cat "$TMP/err")"
MUT="$(make_mutant onetimeout '[ "$TIMEOUTS" -ne 1 ]' 'false')" || fail "could not build the one-timeout mutant"
RC="$(run "$MUT" decide --runs 1 --fresh-legs 1 --workflow "$TMP/wf-two.yml")"
[ "$RC" = "1" ] && grep -q "exactly one timeout-minutes" "$TMP/err" \
  && fail "mutation case is vacuous: two timeouts were still refused"
pass

# 11. A fresh-leg count that is not an integer is a usage error, never a skip.
RC="$(run "$SCRIPT" decide --runs 1 --fresh-legs "" --workflow "$TMP/wf-150.yml")"
[ "$RC" = "2" ] || fail "an empty fresh-leg count did not exit 2 (exit $RC, out: $(cat "$TMP/out"))"
MUT="$(make_mutant freshint 'case "$FRESH_LEGS" in '"''"'|*[!0-9]*) usage ;; esac' ':')" \
  || fail "could not build the fresh-leg integer mutant"
RC="$(run "$MUT" decide --runs 1 --fresh-legs "" --workflow "$TMP/wf-150.yml")"
[ "$RC" = "2" ] && fail "mutation case is vacuous: an empty fresh-leg count still exited 2"
pass

# ---------------------------------------------------------------------------
# 12. The graded job is wired to this script. Read, not executed.
# ---------------------------------------------------------------------------
python3 - "$WF" <<'PY' || fail "skills-eval.yml is not wired to eval-graded-budget.sh as expected"
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
def need(cond, msg):
    if not cond:
        print(f"FAIL: {msg}")
        raise SystemExit(1)
crons = re.findall(r'^\s*-\s*cron:\s*"([^"]+)"', text, re.M)
need(sorted(crons) == sorted(["0 7 * * 1-6", "0 7 * * 0"]),
     f"expected the nightly and weekly crons, found {crons}")
weekly = re.search(r'^\s*WEEKLY_CRON="([^"]+)"', text, re.M)
need(weekly and weekly.group(1) in crons,
     "the plan step's WEEKLY_CRON does not match a cron entry; the weekly run would resolve to runs=1")
need(len(re.findall(r'^\s*timeout-minutes:', text, re.M)) == 1,
     "expected exactly one timeout-minutes")
need("eval-graded-budget.sh resolve" in text, "the graded job does not call the budget script's resolve")
need("eval-graded-budget.sh decide" in text, "the graded job does not call the budget script's decide")
need("--plan-only" in text, "the graded job does not count fresh legs with --plan-only")
need("MINUTES_PER_EXECUTION=" not in text, "the workflow still carries inline runs arithmetic")
# Every paid or output step is gated on the plan's decision.
steps = re.split(r'\n      - (?=name:|uses:)', text)
def step(name):
    for s in steps:
        if s.startswith(f"name: {name}\n"):
            return s
    need(False, f"step {name!r} not found")
for name in ("Run the behavioural evals", "Aggregate", "Report against the committed baseline",
             "Push the updated eval cache index", "Upload the benchmark"):
    body = step(name)
    m = re.search(r"^        if: (.+)$", body, re.M)
    need(m and "steps.plan.outputs.action == 'run'" in m.group(1),
         f"step {name!r} is not gated on steps.plan.outputs.action == 'run'")
run = step("Run the behavioural evals")
need("steps.plan.outputs.runs" in run, "the eval step does not take runs from the plan step")
# The plan and the eval must judge cache age by the same limit, or the plan
# could count a leg as cached that the eval then runs (or the reverse).
need("steps.plan.outputs.max_age_days" in run and "--cache-max-age-days" in run,
     "the eval step does not take the cache age limit from the plan step")
plan_body = step("Plan the graded run")
need(re.search(r"--plan-only[^\n]*--cache-max-age-days", plan_body),
     "the plan step does not pass the resolved cache age limit to --plan-only")
plan = text.find("id: plan")
need(plan > text.find("name: Prepare the eval-cache-index checkout"),
     "the plan step must run after the cache-index checkout")
need(plan < text.find("name: Run the behavioural evals"),
     "the plan step must run before the evals")
PY
pass

echo "eval-graded-budget.test.sh: $CASES cases passed"
