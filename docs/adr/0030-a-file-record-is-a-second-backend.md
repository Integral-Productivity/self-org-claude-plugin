# 30. A file-based org record is a second backend behind the governance-data seam

Date: 2026-11-21

Provenance: [#510](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/510)

## Status

Accepted (2026-11-20, Kraig Parkinson). Amends [ADR-0005](0005-holacracy-identity-glassfrog-as-first-connector-behind-a-seam.md). Review 90 days after the first circle runs from files; that start date is recorded here when it is known.

## Context

Every plugin command assumes that GlassFrog holds the org record. ADR-0005 put
GlassFrog behind a governance-data seam so that another backend could come in
later, but no second backend was planned.

Demand for one now exists. An outside Holacracy practitioner, not part of
Integral Productivity, declined GlassFrog because its cost was higher than the
value they expected. They asked to keep their org record in local files and to
use the plugin with it. This is the only confirmed external demand for a
record other than GlassFrog. Per ADR-0017, this repository records the lesson
and not the person.

Two things block that request:

1. **STRATEGY.md rules it out.** Its "Not working on" list said the plugin does
   not build its own governance record-keeping system and connects to existing
   ones instead. A file record kept by the user reads as such a system.
2. **The seam has worn away.** About 50 shipped files name `glassfrog_*` tools
   directly, so a command cannot be pointed at a different backend without an
   edit.

A self-org ontology was already planned outside this repository, and a spike
lifted markdown frontmatter to RDF through a JSON-LD context and validated it
with SHACL shapes. It passed 4 of 4 cases on a synthetic scenario, and it found
gaps: domains need identifiers, role fillers need a membership model, and
tension status and timestamps are not mapped yet.

## Decision

1. **A file-based org record is a second backend.** It sits behind the same
   seam as GlassFrog, and GlassFrog stays the first backend. Files do not
   become the native record, and GlassFrog does not become an adapter.
2. **The file record is an open format that the user owns.** It is plain
   files in a folder the user controls, readable and editable without the
   plugin.
3. **The `/self-org/` ontology defines the format.** The ontology is a JSON-LD
   context plus SHACL shapes. It lives in a separate `self-org-ontology`
   repository, and the plugin pins a version of it. Its alignment targets are
   W3C ORG, ValueFlows and Murmurations. The prefix carries no trademark
   (ADR-0020).
4. **The user sees only markdown.** The user reads and writes markdown with
   frontmatter. The ontology check runs without the user seeing JSON-LD or
   SHACL.
5. **A file backend gives the plugin no new authority.** A governance change
   written to a file counts only after a human adopts it, exactly as with
   GlassFrog. The plugin may draft and circulate a proposal file, and it never
   originates or adopts governance ([ADR-0025](0025-the-plugin-may-draft-and-circulate-proposals-but-never-originates-or-objects.md)).
6. **STRATEGY.md rules out a hosted record-keeping system only.** The plugin
   still does not run a service that holds org records for users.

## Alternatives rejected

- **Files become the native record, and GlassFrog becomes an adapter.** This
  changes every command and every test for one user's need. A second backend
  meets that need with a smaller change.
- **A trial ADR with no strategy change.** The plugin would build against a
  strategy line that forbids the work, and nothing would show when the trial
  ended.
- **The eval stub as the file backend, under the same `glassfrog_*` names.**
  This breaks the tool-name lint, the tool inventory, the coach's tool grants
  and the eval runner, and the stub copies live API defects on purpose.

## Consequences

**Tests of the decision.**

- **Leading test:** the first consumer runs one circle from files with the
  plugin, with no GlassFrog, for 90 days. The 90 days start on the day that
  circle first runs from files, not on the decision date, so the test measures
  whether files work for that user and not how fast the build went.
- **Lagging test:** the same plugin commands give the same answers on the file
  backend and on GlassFrog, checked by one conformance suite.
- **If the leading test fails,** this ADR is superseded and STRATEGY.md returns
  to its earlier line. Supersession must write "Superseded by" in this ADR's
  Status section: lint check 20 then fails while STRATEGY.md still links this
  ADR, so the revert cannot be forgotten.

**Follow-on work**, each tracked as an issue:

- The governance-data verb contract that every backend serves (#511).
- The file MCP server that reads and writes the markdown record (#512).
- Replacing direct `glassfrog_*` names in shipped files with contract verbs,
  first for the commands the first consumer runs (#513).
- An export from GlassFrog to files, with provenance (#514).
- One conformance suite for every backend (#515).
- SessionStart detection of a file record (#516).
- Creating the `self-org-ontology` repository (#517).

The leading test needs #511, #512 and the first part of #513. The lagging test
needs #515.

**Risk.** The metawork ontology track schedules a review on 2027-01-02 of
whether parallel ontology tracks cost results. The `/self-org/` track starts
inside that window, so its first ADR should name this ADR's consumer and
90-day tests as its own.

## Not decided here

- The ontology's classes and shapes, the registration of `/self-org/` in the
  ontology registry, and what happens to the reserved `/holacracy/` prefix.
  These belong to the ontology repository's first ADR (#517).
- Any app built on the file record.
