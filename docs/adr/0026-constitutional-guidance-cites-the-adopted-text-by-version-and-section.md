# 26. Constitutional guidance cites the adopted text, pinned by version and section

Date: 2026-11-15

## Status

Proposed (2026-11-15). Kraig Parkinson chose on 2026-11-15 to have this ADR
drafted, after the 2026-11-14 assessment of the plugin's constitutional
guidance. The ADR is accepted when its PR merges.

Provenance: #446. Related: #330 (v4.1 role terms in v5.0 files).

## Context

On 2026-11-14 the plugin's objection and proposal rules were checked against
the Constitution v5.0 text. Two of the four objection criteria in
`skills/self-org-secretary/references/constitutional-reference.md` are not in
the Constitution. The Facilitator's "speculative harm" test discards objections
that v5.0 5.3.2(d) accepts; its wording is v4.1 3.2.4(c). Most `S.x.y` section
numbers point to the wrong section, so a reader cannot check them.

The file says it holds CC BY-SA 4.0 excerpts of v5.0, but these lines are
paraphrase. The errors survived because nothing compares a citation with the
text it cites. The plugin learned the same lesson for its own files:
`skills-lint.sh` check 2 asserts that every `` `X.md` Step N `` citation names a
heading that exists.

## Decision

1. **One pinned source.** Constitutional guidance cites Constitution v5.0 from
   [HolacracyOne's repository at commit cc93b0b](https://github.com/holacracyone/Holacracy-Constitution/blob/cc93b0b/Holacracy-Constitution.md).
   Where an organization's GlassFrog serves its own adopted text
   (`glassfrog_getOrgRule`), a live session prefers that text and says so.
2. **Quote rules, do not paraphrase them.** A rule that decides validity
   (proposal requirements, objection criteria, objection testing, integration,
   Policy scope) is quoted from the pinned text with its section number. A
   plain-language summary may follow the quote, marked as a summary.
3. **Section numbers are checked.** A pinned list of v5.0 section numbers
   lives under `evals/`. A new `skills-lint.sh` check fails any shipped
   `S.x.y` or "v5.0 x.y" citation that is not on the list, with its mutation
   case, as CLAUDE.md requires for every check.
4. **Version is explicit.** A file that teaches a v4.1 rule for contrast labels
   it "v4.1" at the point of use. Unlabelled rules are v5.0.

## Alternatives rejected

- **Fix the text once, add no check.** The same drift caused the errors, and
  CLAUDE.md records that stated rules without a check were violated anyway.
- **Copy the whole Constitution into the repo.** It is large, it would need its
  own ShareAlike notice, and most of it is never cited. A pinned link plus
  quoted rules and a section list is enough to check citations.
- **Cite only the organization's live text.** It is not available offline or in
  CI, and the public repo must not carry live-org data (ADR-0017).

## Consequences

- #446 rewrites the objection and proposal rules to quotes and fixes the
  numbers; the new lint check guards them.
- A change to the pinned commit is a deliberate edit to one list, reviewed in a
  PR.
- `constitutional-reference.md` then matches its own licence statement.

## Not decided here

- Whether to support organizations that run v4.1 beyond the existing "note the
  discrepancy and ask" rule in `self-org-facilitator`.
