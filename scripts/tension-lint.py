#!/usr/bin/env python3
"""Lint one tension body against skills/shared/tension-well-formedness.md.

    scripts/tension-lint.py --role "Vendor Steward" < body.txt
    scripts/tension-lint.py --role "Vendor Steward" --body "Supplier renewals ..."

DATA BOUNDARY: this script sends the tension body and the sensing role's name
to TypeSafe (https://api.typesafe.ai) to ask Jev, TypeSafe's System One model,
five yes/no questions. It sends nothing until a person runs it on a body. Run it
only after triage-gates.md Step 2, so a person tension is never sent.
Capture and triage never call it. See docs/adr/0024-*.md.

Judgments come from Jev; decisions are made here, in code:

- T6 (topic first) and the 1-5000 character length bound are checked in code.
  A body that fails the length bound is never sent.
- T1-T5 are one atomic Noul question each. Each answer is a probability that
  the statement is true. At or above YES the answer is yes, at or below NO it
  is no, and between the two it is unsettled.
- The decision table below turns each answer into pass, teach, or ask.
  Overall: any teach -> teach; else any ask -> ask; else pass.
- A failed API call exits 2 with the error on stderr. It is never a "no".

Output is JSON on stdout. Exit 0 for any verdict, 2 for an error.

Testing seams: --fake-answers <json> replaces the API with a fixed mapping of
check ID to probability; --dry-run prints the request and sends nothing.
Requires the `typesafe-sdk` package and TYPESAFE_API_KEY for a live run only.
"""
from __future__ import annotations

import argparse
import json
import re
import sys

RUBRIC = "skills/shared/tension-well-formedness.md"
API_HOST = "api.typesafe.ai"
MAX_BODY = 5000
MAX_FIRST_SENTENCE = 200
# A whole first word only: "I'm" and "We're" match, "IT" and "In" do not.
NARRATIVE_LEAD_IN = re.compile(r"(I|We|So|Lately|Recently)\b")

# Starting thresholds from the TypeSafe skill; not yet tuned on probe data.
YES = 0.7
NO = 0.3

# ---------------------------------------------------------------------------
# Question wording: the only place it lives. Keyed by rubric check ID.
# `problem_if_true` marks the inverted checks, where "true" is the defect.
# ---------------------------------------------------------------------------
QUESTIONS = {
    "T1": {
        "instructions": "The tension body states both the current reality the role experiences and what could be different.",
        "true": "The body says what is now and what could be.",
        "false": "The body states only a complaint, only a wish, or neither.",
        "problem_if_true": False,
    },
    "T2": {
        "instructions": "The tension body contains at least one concrete, checkable instance of the gap: when, where, or what happened.",
        "true": "A reader could check that a specific described event or example happened.",
        "false": "The body speaks only in generalities such as 'often', 'slow', or 'keeps happening'.",
        "problem_if_true": False,
    },
    "T3": {
        "instructions": "The tension body says how the gap affects the sensing role's purpose or accountabilities.",
        "true": "The body links the gap to the role's purpose or to one of its accountabilities.",
        "false": "The body does not say why the gap matters to the role.",
        "problem_if_true": False,
    },
    "T4": {
        "instructions": "The tension body describes more than one separate gap, where each could be resolved without the other.",
        "true": "The body holds two or more independent gaps.",
        "false": "The body holds a single gap, even if it has several symptoms.",
        "problem_if_true": True,
    },
    "T5": {
        "instructions": "The tension body is a proposed solution with no stated gap.",
        "true": "Removing the proposed fix would leave no gap in the body.",
        "false": "The body states a gap; any fix it suggests is extra.",
        "problem_if_true": True,
    },
}

FIXES = {
    "T1": 'Add the missing half: "Now ___; it could be ___."',
    "T2": "Ask for one dated example and add it.",
    "T3": "Name the accountability or purpose the gap touches.",
    "T4": "Split into two bodies, one gap each.",
    "T5": 'Draft the gap the proposal answers; keep the proposal as "Suggested fix: ..." after it.',
    "T6": "Move the topic into the first sentence.",
}


class LintError(Exception):
    """An error that must end the run without a verdict."""


def first_sentence(body: str) -> str:
    text = body.strip()
    for i, ch in enumerate(text):
        if ch in ".!?\n" and (i + 1 == len(text) or text[i + 1] in " \n\t"):
            return text[: i + 1].strip()
    return text


def check_topic_first(body: str) -> dict:
    """T6 in code: a narrow structural rule, not a judgment."""
    sentence = first_sentence(body)
    if len(sentence) > MAX_FIRST_SENTENCE:
        return {"verdict": "teach", "reason": f"first sentence is {len(sentence)} characters (limit {MAX_FIRST_SENTENCE})"}
    lead = NARRATIVE_LEAD_IN.match(body.lstrip())
    if lead:
        return {"verdict": "teach", "reason": f"first sentence opens with a narrative lead-in ({lead.group(1)!r})"}
    return {"verdict": "pass", "reason": "first sentence is short and opens on the topic"}


def decide(check: str, p: float) -> str:
    """Decision table: probability -> pass/teach/ask for one Noul check."""
    if not isinstance(p, (int, float)) or isinstance(p, bool) or not 0.0 <= p <= 1.0:
        raise LintError(f"{check}: answer {p!r} is not a probability in [0, 1]")
    answer = "yes" if p >= YES else "no" if p <= NO else "unsettled"
    if answer == "unsettled":
        return "ask"
    defect = (answer == "yes") == QUESTIONS[check]["problem_if_true"]
    return "teach" if defect else "pass"


def overall(verdicts: list[str]) -> str:
    if "teach" in verdicts:
        return "teach"
    if "ask" in verdicts:
        return "ask"
    return "pass"


def build_request(body: str, role: str) -> dict:
    return {
        "state": {"tension_body": body, "sensing_role": role},
        "questions": {
            cid: {
                "type": "noul",
                "instructions": q["instructions"],
                "criteria": {"true": q["true"], "false": q["false"]},
            }
            for cid, q in QUESTIONS.items()
        },
    }


def ask_jev(request: dict, model: str | None) -> dict:
    """Live call. Lazy import so the offline suite needs no SDK."""
    try:
        from typesafe_sdk import Noul, TypeSafeClient
    except ImportError as exc:
        raise LintError("the typesafe-sdk package is not installed (pip install typesafe-sdk)") from exc
    questions = {
        cid: Noul(instructions=q["instructions"], criteria=q["criteria"])
        for cid, q in request["questions"].items()
    }
    try:
        result = TypeSafeClient().system_one(request["state"], questions=questions, model=model)
        return {cid: result.nouls[cid].noul for cid in questions}
    except Exception as exc:  # any SDK, network, auth, or shape error
        raise LintError(f"TypeSafe request failed: {type(exc).__name__}: {exc}") from exc


def lint(body: str, role: str, answers_source) -> dict:
    if not body.strip():
        raise LintError("tension body is empty (the API requires 1-5000 characters)")
    if len(body) > MAX_BODY:
        raise LintError(f"tension body is {len(body)} characters (the API allows at most {MAX_BODY})")
    answers = answers_source(build_request(body, role))
    checks = {}
    for cid in QUESTIONS:
        if cid not in answers:
            raise LintError(f"no answer returned for {cid}")
        checks[cid] = {"verdict": decide(cid, answers[cid]), "probability": answers[cid]}
    checks["T6"] = check_topic_first(body)
    for cid, result in checks.items():
        if result["verdict"] != "pass":
            result["fix"] = FIXES[cid]
    return {
        "rubric": RUBRIC,
        "overall": overall([c["verdict"] for c in checks.values()]),
        "checks": checks,
        "note": "T7 (structural) is triage-gates.md Step 2 and is not linted.",
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=f"Lint one tension body against {RUBRIC}. "
        f"A live run sends the body and role name to {API_HOST} (TypeSafe's Jev model).",
    )
    parser.add_argument("--role", required=True, help="name of the sensing role")
    parser.add_argument("--body", help="tension body; read from stdin when omitted")
    parser.add_argument("--model", default=None, help="TypeSafe model (default: the SDK default, jev-latest)")
    parser.add_argument("--fake-answers", metavar="JSON", help="test seam: map of check ID to probability; no API call")
    parser.add_argument("--dry-run", action="store_true", help="print the request that would be sent; send nothing")
    args = parser.parse_args(argv)
    body = args.body if args.body is not None else sys.stdin.read()

    if args.dry_run:
        print(json.dumps({"would_send_to": API_HOST, **build_request(body, args.role)}, indent=2))
        return 0

    if args.fake_answers is not None:
        fake = json.loads(args.fake_answers)
        if isinstance(fake, dict) and "error" in fake:
            def source(_request):
                raise LintError(f"TypeSafe request failed: {fake['error']}")
        else:
            def source(_request):
                return fake
    else:
        def source(request):
            return ask_jev(request, args.model)

    try:
        report = lint(body, args.role, source)
    except LintError as exc:
        print(f"tension-lint: error: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
