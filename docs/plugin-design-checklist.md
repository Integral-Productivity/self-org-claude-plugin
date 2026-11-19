# Plugin design checklist

This checklist says what a well-designed command, skill, or subagent in this
plugin looks like. Use it when you add or change a surface, and when you review
a pull request that does.

The plugin is a CLI, a conversational agent, a tool set that a model chooses
from, and a product for people with attention, memory, and processing
differences. No single design system covers all four, so the checklist combines
six layers of published guidance. Each item names its source, says how to check
it, and says what enforces it.

Tracking issue: [#465](https://github.com/Integral-Productivity/self-org-claude-plugin/issues/465).

## How to use it

1. Find the items that apply to the surface you change. Most items apply to
   every command, skill, and subagent.
2. Items marked **lint** are enforced by `scripts/skills-lint.sh`. CI fails the
   pull request when they break. You do not check them by hand.
3. Items marked **manual** need a reader. Check them in review.
4. Items marked **lint candidate** can be checked by a machine but are not yet.
   A new lint check needs its mutation case in `scripts/skills-lint.test.sh`
   (see CLAUDE.md, "Do not add a check without adding its mutation case").
5. When an item does not fit a surface, say so in the pull request. Do not add
   work to satisfy an item that does not apply.

The **Pilot** column records the first pass over this plugin (2026-11-19), after
#460 to #464 merged. "Met" means every surface passed. A gap names the issue
that tracks it.

## Sources

| Layer | Source |
|---|---|
| 1. Platform rules | Anthropic: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [Claude Code skills](https://code.claude.com/docs/en/skills.md), [Plugins](https://code.claude.com/docs/en/plugins) |
| 2. Agent-tool design | Anthropic: [Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) |
| 3. CLI design | [Command Line Interface Guidelines](https://clig.dev/) (clig.dev) |
| 4. Command naming in other hosts | [VS Code command palette UX guidelines](https://code.visualstudio.com/api/ux-guidelines/command-palette); Slack [app design](https://docs.slack.dev/surfaces/app-design/) and [slash commands](https://docs.slack.dev/interactivity/implementing-slash-commands) |
| 5. Human-AI interaction | Microsoft, [Guidelines for Human-AI Interaction](https://www.microsoft.com/en-us/research/publication/guidelines-for-human-ai-interaction/) (G1 to G18); Google PAIR, [People + AI Guidebook](https://pair.withgoogle.com/guidebook) |
| 6. Cognitive accessibility | W3C, [Making Content Usable for People with Cognitive and Learning Disabilities](https://www.w3.org/TR/coga-usable/) (COGA, Working Group Note, 2021) |

Two limits on the sources. Microsoft says its guidelines are "not intended to be
used as a simple checklist" and were tested on graphical interfaces, so this
list takes only the ones that carry over to a chat and command surface. COGA is
supplemental guidance beyond WCAG; following it is not required for WCAG
conformance.

## 1. Platform rules

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| P1 | A command that writes to GlassFrog sets `disable-model-invocation: true`, so only the user starts it. The two triage walks are the stated exception. | Frontmatter | **lint**, check 17 | Met (#464) |
| P2 | A skill that holds background knowledge and is never started by a user sets `user-invocable: false`. | Manual | none | Met. All six skills are frames a user may start; none needs the flag. |
| P3 | Each model-invocable skill, subagent, and command has a short description, because every description sits in context on every turn. | Count characters | **lint**, check 8, upper limits only (**lint candidate**: a lower budget) | Gap. Subagent descriptions are 785 to 1,427 characters and skill descriptions about 900. Tracked in #288. |
| P4 | Names follow one pattern across the collection. | Name shape | **lint**, check 18 ([ADR-0028](adr/0028-commands-are-named-by-act-type.md)) | Met (#462) |
| P5 | A description says what the surface does and when to use it, key use case first, in the third person or as a "Use when" line. | Manual; trigger rates are measured by #172 | none | Met in form. Internal terms in one description: see A1. |
| P6 | `SKILL.md` stays under 500 lines. | Line count | **lint candidate** | Met. The six skills are 116 to 386 lines. |
| P7 | A skill links its reference files directly; references do not chain deeper than one level. | Manual | check 1 resolves paths but not depth | Accepted. Shared flow files load the rubric files they apply. Whether shared files travel with an uploaded skill is #373. |
| P8 | A reference file over 100 lines opens with a table of contents. | Line count and heading search | **lint candidate** | Gap. 26 of 29 such files have none. Tracked in #477. |
| P9 | One term per concept, used everywhere. | Glossary in `CONCEPTS.md` | **lint**, check 11 (triage states) and check 15 (menu keys) | Met for states and keys. Open prose gaps: #162 ("file" and "write"), #330 (v4.1 and v5.0 role names). |
| P10 | Behaviour is evaluated before instructions grow, on each model tier in use. | Eval cases in `evals/cases/` | nightly graded evals ([ADR-0012](adr/0012-test-the-skills-not-just-the-scaffolding.md)) | Partly met. Run health and baseline: #470, #173. |
| P11 | A batch or destructive change runs plan, validate, then apply. | Manual | per-item confirmation; eval write-log ordering checks | Met. Every write flow drafts, shows, and confirms before the write. |
| P12 | A choice offers a default with an escape hatch, not a long flat list. | Menu shape | **lint**, check 16 ([`decision-keys.md`](../skills/shared/decision-keys.md) Step 3) | Met (#461) |

## 2. Agent-tool design

These apply to commands, skills, and subagents because the model reads their
names and descriptions to decide what to load.

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| T1 | Expose few, high-impact surfaces; merge related steps into one. | Count of surfaces | none | Accepted. 20 command files, of which 7 are deprecated aliases that go in 2.0.0 (ADR-0028). |
| T2 | Namespace by service, then by resource. | Name shape | **lint**, check 18 | Met. The `self-org:` prefix, then the work item. |
| T3 | Show people names, not raw ids. | Manual, on walk cards and confirmations | none | Met. Walk cards and drafts name roles, circles, and projects. |
| T4 | An error says what happened and what to do next. | Manual | none | Met in the sampled flows (`context`, `sense-tension`). |
| T5 | Make implicit conventions explicit in the surface or a cited reference. | Manual | check 1 (cited paths resolve) | Met. Conventions live in `skills/shared/`. |

## 3. CLI design

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| C1 | Every command has help, and there is one place to start that lists what the plugin does. | README and command list | none | Gap. The README lists skills and shared references but has no command list by job and no start-here section. Tracked in #478. |
| C2 | Subcommands behave the same way: same keys, same picker, same naming. | Menus and names | **lint**, checks 15, 16, 18 | Met (#460 to #462) |
| C3 | Confirm before a dangerous act, and scale the confirmation to the danger. | Manual | per-item confirmation; check 17 | Met. Destructive edits (delete, merge) are confirmed one at a time. |
| C4 | Prompt only when a person is there to answer; a non-interactive session has a defined path. | Manual | none | Gap, tracked in #284 (grounding directive in a non-interactive session). |

## 4. Command naming in other hosts

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| N1 | Group commands under one category prefix. | Name shape | the host's `plugin:` prefix | Met |
| N2 | A name is descriptive, memorable, and keeps one meaning. A renamed command keeps an alias that names its successor. | Manual; alias stubs | **lint**, check 18; check 5 (referenced commands exist) | Met. Six aliases name their successors until 2.0.0. |

## 5. Human-AI interaction

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| H1 | Make clear what the system can do and how well (Microsoft G1, G2). | Manual | none | Partly met. `/self-org:context` shows identity and roles. No surface lists what the plugin does: see C1, #478. |
| H2 | Support efficient dismissal and correction (G8, G9). | Manual | none | Met. Every walk can quit at any item; every draft can be edited before the write. |
| H3 | Scope the service when in doubt (G10). | Manual | none | Met. `authority-boundaries.md` and `/self-org:check-authority`. |
| H4 | Make clear why the system did what it did (G11). | Picker layout | **lint**, check 16 | Met. The verdict and one sentence of reason sit above each picker. |
| H5 | Say what each choice will do before the user makes it. | Picker options | `decision-keys.md` Step 3 (one-line consequence per option) | Met |
| H6 | Tell users about changes (G18). | Alias text, CHANGELOG | release-please | Met. Aliases name the new command; the CHANGELOG records renames. |
| H7 | Explain for understanding, not completeness (PAIR). | Manual | none | See A1. |

## 6. Cognitive accessibility

| ID | Item | How to check | Enforced by | Pilot |
|---|---|---|---|---|
| A1 | Text a user reads uses plain words, not internal labels such as rubric family letters, flow code names, or step numbers. | Search descriptions and card templates | **lint candidate**: a short denylist of internal labels in `description:` lines | Gap. `commit-project`'s description names "Family A". Tracked in #479. |
| A2 | Processes do not rely on memory. | Menu keys and pickers | **lint**, checks 15 and 16 | Met (#460, #461) |
| A3 | Help users avoid mistakes and know how to correct them. | Manual | per-item confirmation | Met |
| A4 | Help users find what they need. | README, command list | none | Gap, same as C1 (#478). |
| A5 | Help users focus: one decision at a time. | Walk shape | none | Met. Walks show one item per decision. |

## Pilot record (2026-11-19)

**What changed before the pilot.** #460 to #464 gave the plugin one menu-key
vocabulary, a picker-first menu, user-only write commands, and one naming
shape. Each now has a lint check (15 to 18).

**What the pilot found.** Three new gaps, each filed as an issue: reference
files without a table of contents (P8, #477), no start-here surface (C1, A4,
#478), and internal labels in user-facing text (A1, #479). Four known gaps
were already tracked: #288, #284, #162, #330.

**What did not help.** Microsoft G16 ("convey the consequences of user
actions") is about how a user's action changes the AI's future behaviour, not
about the effect of a write, so H5 rests on clig.dev's confirmation guidance
instead. Microsoft G3 to G6 and G12 to G15 have no clear test for a command
surface and are left out.

**Next.** After the three gaps close, the plugin-neutral items (most of layers
1 to 4, H2 to H6, and A2 to A5) can move to a shared home that other plugins
cite. The GlassFrog- and Holacracy-specific items stay here. That move is a
separate issue, filed when this pilot is accepted.
