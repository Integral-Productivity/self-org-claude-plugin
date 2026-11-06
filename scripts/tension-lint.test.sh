#!/usr/bin/env bash
# Regression suite for scripts/tension-lint.py.
#
# WHAT THIS GUARDS
# ----------------
# The decision logic of the tension lint: the thresholds, the decision table
# (including the two inverted checks, T4 and T5), the overall roll-up, the T6
# code rule, the length bound, and the rule that a failed API call is an error
# and never a "no". Jev's judgments are not tested here; they are replaced by
# --fake-answers, so this suite makes NO network call and needs no API key and
# no typesafe-sdk package. Live probing is separate, deferred work (ADR-0024).
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="${1:-$REPO/scripts/tension-lint.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1"; exit 1; }
CASES=0
pass() { CASES=$((CASES + 1)); }

GOOD_BODY="Vendor approval stalls on Operations Circle. Now requests wait three weeks for IT Governance; they could be answered in three days. On 2026-09-02 the Tool X rollout was blocked. This touches the role's accountability for onboarding suppliers."
ALL_PASS='{"T1":0.9,"T2":0.9,"T3":0.9,"T4":0.1,"T5":0.1}'

run() {  # $1 fake answers JSON, $2 body; writes $TMP/out, $TMP/err, sets RC
  python3 "$LINT" --role "Vendor Steward" --body "$2" --fake-answers "$1" >"$TMP/out" 2>"$TMP/err"
  RC=$?
}
field() {  # $1 python expression over `r`
  python3 -c "import json,sys; r=json.load(open('$TMP/out')); print($1)"
}
with() {  # $1 check ID, $2 probability -> ALL_PASS with one answer replaced
  python3 -c "import json; d=json.loads('$ALL_PASS'); d['$1']=$2; print(json.dumps(d))"
}

# 1. All five answers clearly good -> overall pass, every check pass.
run "$ALL_PASS" "$GOOD_BODY"
[ "$RC" = 0 ] || fail "1: exit $RC, stderr: $(cat "$TMP/err")"
[ "$(field 'r["overall"]')" = pass ] || fail "1: overall is not pass"
[ "$(field 'sorted({c["verdict"] for c in r["checks"].values()})')" = "['pass']" ] || fail "1: some check did not pass"
pass

# 2. T2 at 0.1 (no concrete instance) -> T2 teach, overall teach, with a fix.
run "$(with T2 0.1)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T2"]["verdict"]')" = teach ] || fail "2: T2 is not teach"
[ "$(field 'r["overall"]')" = teach ] || fail "2: overall is not teach"
[ "$(field '"fix" in r["checks"]["T2"]')" = True ] || fail "2: T2 teach has no drafted fix"
pass

# 3. T1 at 0.5 (unsettled) -> T1 ask, overall ask when nothing teaches.
run "$(with T1 0.5)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T1"]["verdict"]')" = ask ] || fail "3: T1 is not ask"
[ "$(field 'r["overall"]')" = ask ] || fail "3: overall is not ask"
pass

# 4. Inverted checks: T4 at 0.9 (two gaps) and T5 at 0.9 (proposal) -> teach.
run "$(with T4 0.9)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T4"]["verdict"]')" = teach ] || fail "4: T4 at 0.9 is not teach"
run "$(with T5 0.9)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T5"]["verdict"]')" = teach ] || fail "4: T5 at 0.9 is not teach"
pass

# 5. teach outranks ask in the roll-up.
run '{"T1":0.5,"T2":0.1,"T3":0.9,"T4":0.1,"T5":0.1}' "$GOOD_BODY"
[ "$(field 'r["overall"]')" = teach ] || fail "5: teach + ask did not roll up to teach"
pass

# 6. Boundaries: exactly 0.7 is yes, exactly 0.3 is no.
run "$(with T1 0.7)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T1"]["verdict"]')" = pass ] || fail "6: T1 at 0.7 is not yes/pass"
run "$(with T1 0.3)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T1"]["verdict"]')" = teach ] || fail "6: T1 at 0.3 is not no/teach"
run "$(with T4 0.7)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T4"]["verdict"]')" = teach ] || fail "6: inverted T4 at 0.7 is not yes/teach"
run "$(with T4 0.3)" "$GOOD_BODY"
[ "$(field 'r["checks"]["T4"]["verdict"]')" = pass ] || fail "6: inverted T4 at 0.3 is not no/pass"
pass

# 7. Length bound is checked in code, before any answer is requested. The fake
#    answers here are an error, so reaching the answer source would say so.
run '{"error":"should not be reached"}' ""
[ "$RC" = 2 ] || fail "7: empty body did not exit 2"
grep -q "empty" "$TMP/err" || fail "7: empty body error does not say empty"
grep -q "should not be reached" "$TMP/err" && fail "7: empty body reached the answer source"
LONG="$(python3 -c 'print("Vendor approval stalls. " + "x" * 5000)')"
run '{"error":"should not be reached"}' "$LONG"
[ "$RC" = 2 ] || fail "7: over-length body did not exit 2"
grep -q "should not be reached" "$TMP/err" && fail "7: over-length body reached the answer source"
pass

# 8. A client error exits 2, prints the error, and prints NO verdict.
run '{"error":"ConnectionError: blocked"}' "$GOOD_BODY"
[ "$RC" = 2 ] || fail "8: client error did not exit 2"
[ -s "$TMP/out" ] && fail "8: client error still printed a verdict"
grep -q "TypeSafe request failed" "$TMP/err" || fail "8: client error not reported on stderr"
pass

# 9. A missing or out-of-range answer is an error, not a verdict.
run '{"T1":0.9,"T2":0.9,"T3":0.9,"T4":0.1}' "$GOOD_BODY"
[ "$RC" = 2 ] || fail "9: missing T5 answer did not exit 2"
run "$(with T3 1.5)" "$GOOD_BODY"
[ "$RC" = 2 ] || fail "9: probability 1.5 did not exit 2"
pass

# 10. --dry-run prints five Noul questions and the state, and sends nothing.
python3 "$LINT" --role "Vendor Steward" --body "$GOOD_BODY" --dry-run >"$TMP/out" 2>"$TMP/err" \
  || fail "10: dry-run failed: $(cat "$TMP/err")"
[ "$(field 'len(r["questions"])')" = 5 ] || fail "10: dry-run does not show five questions"
[ "$(field 'sorted({q["type"] for q in r["questions"].values()})')" = "['noul']" ] || fail "10: a question is not a Noul"
[ "$(field 'r["state"]["sensing_role"]')" = "Vendor Steward" ] || fail "10: state lacks the sensing role"
[ "$(field 'r["would_send_to"]')" = api.typesafe.ai ] || fail "10: dry-run does not name the destination"
pass

# 11. T6 code rule.
run "$ALL_PASS" "$(python3 -c 'print("Vendor approval " + "and more detail " * 15 + "stalls. Rest.")')"
[ "$(field 'r["checks"]["T6"]["verdict"]')" = teach ] || fail "11: long first sentence is not T6 teach"
run "$ALL_PASS" "Lately, things on Operations Circle have been slow. On 2026-09-02 a request waited."
[ "$(field 'r["checks"]["T6"]["verdict"]')" = teach ] || fail "11: 'Lately' lead-in is not T6 teach"
run "$ALL_PASS" "We're stuck on vendor approvals. On 2026-09-02 a request waited."
[ "$(field 'r["checks"]["T6"]["verdict"]')" = teach ] || fail "11: \"We're\" lead-in is not T6 teach"
run "$ALL_PASS" "IT Governance approval stalls vendor onboarding. On 2026-09-02 a request waited."
[ "$(field 'r["checks"]["T6"]["verdict"]')" = pass ] || fail "11: a body opening on 'IT' is wrongly read as the lead-in 'I'"
run "$ALL_PASS" "$GOOD_BODY"
[ "$(field 'r["checks"]["T6"]["verdict"]')" = pass ] || fail "11: topic-first body is not T6 pass"
pass

# 12. --help names where the body is sent (data boundary, R12).
python3 "$LINT" --help 2>&1 | grep -q "api.typesafe.ai" || fail "12: --help does not name api.typesafe.ai"
pass

echo "tension-lint.test.sh: $CASES cases passed"
