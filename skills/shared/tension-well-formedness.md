# Tension Well-Formedness -- Shared Reference

This is the canonical rubric for judging whether a GlassFrog **tension body** is clear enough to act on. It is the tension-side twin of `project-well-formedness.md`. Loaded by:

- `/self-org:capture-tension` and the `tension-capture` subagent -- the capture-time soft gate, run inside Step 4 of `./tension-capture-flow.md`, after the gates in Steps 1 and 2 of `./triage-gates.md`.
- `/self-org:tension-triage` -- the standard for "well-formed" and for the text that `[e] edit body` drafts.
- `scripts/tension-lint.py` -- the command-line lint, which checks T6 and the length bound in code and asks Jev (TypeSafe's System One model) one Noul question for each of T1-T5 ([ADR-0024](../../docs/adr/0024-tensions-are-checked-for-well-formedness-by-one-rubric.md)).

Every tension surface uses this file so "well-formed" means one thing across the plugin. The rubric **describes**; it never auto-acts. Any fix it implies is drafted for a human to confirm.

---

## Why the body matters (constitutional grounding)

A **tension** is the gap a role-filler senses between what is and what could be, in service of the role's purpose or accountabilities. The GlassFrog API has no label, no category, and no separate "why" field: the body is the whole record. A governance change that processes the tension has no other recorded reason for existing. So a body that a reader cannot act on is not only a slow tension; it is a governance change with no "why".

The test this rubric serves:

> **Substitution test for the body:** *"If a different person, who was not there, read only this body, could they tell what the gap is, check that it happened, and see why it matters to the role?"*

This file judges the **body**. Whether a tension belongs in governance at all (authority already held, role versus person, venue, supersession, attribution) is the job of `./triage-gates.md`. Run those gates first.

---

## The seven checks

Run T1-T7 on the body as written. Each check has one test.

**T1. Gap stated.** The body names what is (current reality) and what could be (the potential the role senses).

> *Test:* can you fill in "Now ___; it could be ___" from the body alone? If one half is missing, the gap is not stated. A complaint with no "could be" is half a tension.

**T2. Concrete instance.** The body gives at least one observable example: when, where, what happened.

> *Test:* could someone check that it happened? "On 2026-09-02 the storage supplier auto-renewed at a 20% higher rate" can be checked. "This keeps happening" and "it is slow" cannot.

**T3. Felt by the role.** The body names the sensing role, or makes it obvious, and says how the gap touches that role's purpose or accountabilities.

> *Test:* which accountability or purpose does this gap get in the way of? If the body cannot answer, the tension has no "why" for the governance change it may produce.

**T4. One tension.** The body holds one gap.

> *Test:* does the body describe two gaps that could each be resolved without the other ("... Also, the meeting keeps running over")? If yes, split it into two tensions. This is different from a *blended* tension (one gap with a structural half and a personal half), which `./triage-gates.md` Step 2 partitions.

**T5. Not a disguised proposal.** The gap comes first. A suggested fix may follow, marked as a suggestion.

> *Test:* remove the fix from the body. Is a tension still left? "Add a Queue Keeper role" with nothing else is a proposal with no stated gap. Keep the suggestion, and draft the gap it answers.

**T6. Topic first.** The first sentence names the topic, because a backlog reader scans first sentences only.

> *Test:* does the first sentence say what the tension is about, before the story? This is the front-load rule in `./tension-capture-flow.md` Step 4.

**T7. Structural.** The tension is about the role, not about the person filling it.

> *Test:* `./triage-gates.md` Step 2. This rubric points there and does not repeat it. A person tension never reaches T1-T6.

### Length

The body must be 1-5000 characters (an API constraint). Most well-formed tensions fit in two to four sentences.

---

## Teaching behavior

Every finding is a **teaching finding with a drafted fix**. The rubric never blocks capture and never decides what a tension becomes ([ADR-0011](../../docs/adr/0011-separate-tension-readiness-from-tension-disposition.md)): it only says whether the body is ready, and what would make it ready.

For each failing check, give:

1. the check (for example "T2, concrete instance"),
2. one line on why it matters, and
3. a drafted fix in the user's own words, or one question that gets the missing element ("When did this last happen?").

| Check fails | Drafted fix |
|---|---|
| T1 | Add the missing half: "Now ___; it could be ___." |
| T2 | Ask for one dated example and add it. |
| T3 | Name the accountability or purpose the gap touches. |
| T4 | Split into two bodies, one gap each. |
| T5 | Draft the gap the proposal answers; keep the proposal as "Suggested fix: ..." after it. |
| T6 | Move the topic into the first sentence. |

Preserve the user's words. Tensions are lived experience; the user's framing is data.

## When the rubric feels heavy

The "When the gates feel heavy" rule in `./triage-gates.md` applies here too. Run the checks **internally**. Surface only the checks that fail, and only the one or two that matter most for this body. A tension that passes is shown with no rubric comment at all. Capture must stay cheap: one missing element and a drafted fix, never a seven-item quiz.

## What this rubric does not do

- It does not decide disposition, venue, or authority. Those are `./triage-gates.md`.
- It does not write anything. Capture and triage write only on the user's per-item confirmation.
- It does not send a tension anywhere. Only `scripts/tension-lint.py` sends text to a third party (`api.typesafe.ai`), and only when a person runs it on that body.
- Check outcomes are `pass`, `teach`, or `ask`. They are findings, never tags, and they do not use the reserved `needs-*` or `ready-for-*` names (`./triage-states.md`).
