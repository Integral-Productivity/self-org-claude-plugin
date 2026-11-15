# Governance Meeting Facilitation -- v5.0

Source: the rules quoted here are excerpts from the [Holacracy Constitution v5.0](https://www.holacracy.org/constitution/5-0/), quoted from [HolacracyOne's repository at commit cc93b0b](https://github.com/holacracyone/Holacracy-Constitution/blob/cc93b0b/Holacracy-Constitution.md) (ADR-0026), by HolacracyOne, LLC, licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Integral Productivity LLC selected, reformatted, and annotated the excerpts and wrote the facilitation scripts. Because of the ShareAlike term, this file is licensed under CC BY-SA 4.0, not under the repository's MIT license. See [NOTICE](../../../NOTICE).

Block quotes are the Constitution's wording. Everything else is facilitation guidance. Section numbers are v5.0; a v4.1 number is labelled "v4.1".

A Governance meeting is the circle's structural evolution mechanism. Its purpose is to process proposed changes to the circle's governance: roles, accountabilities, domains, and policies. Every change adopted in governance must survive an objection-based validity test -- this is what gives governance decisions their constitutional authority.

**Typical duration**: 60-120 minutes. A meeting with three or four substantive proposals may take the full two hours.

**The Facilitator's core job in governance**: Protect the process. The integrative decision-making (IDM) process is not a parliamentary debate -- it is a structured sequence designed to surface the wisdom distributed across role-fillers and integrate objections rather than overrule them. Every departure from the sequence erodes that protection.

---

## Pre-Meeting Preparation

Before the meeting, load:
```
glassfrog_get_role(circle_id, include: ["sub_roles", "assignments", "policies"]) -> all roles, people, policies
glassfrog_list_roles(circle_id) -> full role inventory for cross-reference
glassfrog_list_people          -> attendee identification
```

If the user has prepared governance proposals in advance, review them for:
- Constitutional validity (does the proposal fit within governance? Is it a role/accountability/domain/policy change?)
- Potential overlap with existing governance (would this conflict with another role's domain or accountability?)
- Clarity (can the proposal be stated in one or two sentences?)

Present the loaded context before beginning:
> "I've loaded the [Circle Name] Governance structure. [N] roles, [R] role-fillers present. Any proposals prepared in advance? [If yes, list them.] Ready to begin?"

---

## Meeting Format -- Step by Step

### Step 1: Check-In Round

Same as Tactical -- each person shares briefly, one at a time, uninterrupted. See `tactical-meeting.md` for full facilitation script.

---

### Time Out (at any point)

v5.0 has no "administrative concerns" step. The meeting process is check-in, agenda building and processing, and closing (S.5.4.3). Logistics and process questions go into a Time Out:

> At any point during this process, a participant may request a "Time Out" pause. The Facilitator may choose to grant or deny this request. During the Time Out, participants may discuss administrative issues or the rules of this Constitution. They may not use the Time Out to work towards the resolution of a Tension, Proposal, or Objection.

**Facilitation script** (when someone raises a hard stop, a remote-join issue, or a process question):
> "Let's take a short Time Out for that. [Handle it.] Time Out over -- back to [where we were]."

If the Time Out turns into work on a Tension or a Proposal, end it: "That's agenda work -- add it as an item."

---

### Step 2: Agenda Building

**What it is**: Anyone in the circle can add a tension to the governance agenda. As in Tactical, this is not the time to discuss tensions -- just to surface them.

**Facilitation script**:
> "Let's build the agenda. What tensions does anyone want to process today? Just a word or two to identify the topic -- we'll hear the full proposal when we process each item."

Go around until the agenda is complete.

**The Facilitator's role during agenda building**:
- Do not evaluate whether tensions belong in governance yet -- that happens during processing
- If someone describes a very detailed proposal: "Hold the details -- we'll hear them when we process your item"
- If someone raises a tactical-level tension (information, project): note it and suggest it could wait for tactical or be addressed after the meeting

---

### Step 3: Process Each Agenda Item

This is the heart of the governance meeting. Each agenda item follows the **Integrative Decision Making (IDM)** process -- six phases that must be followed in order.

For each item, announce: "[Name], your tension is next. Please share your proposal."

---

#### Phase A: Present the Proposal

**What happens**: The proposer describes their tension and their proposed governance change.

**Facilitation script**:
> "[Name], please share your proposal. What's the tension you're sensing, and what change are you proposing to address it?"

**What a valid governance proposal looks like**:
- Creates, modifies, or removes a role (including its name, purpose, accountabilities, domains)
- Creates, modifies, or removes a policy
- Moves a role from one circle to another
- Dissolves a role into another

**What is NOT a governance proposal**:
- A request for someone to do something (that's a tactical tension)
- A strategy suggestion (that goes to the Lead Link)
- A personal grievance or interpersonal issue

A proposal to change how the circle runs its meetings *is* governance when it is a Policy. A Policy may add to the Governance Meeting process if it does not conflict with Article 5 (S.5.4.3), may replace or amend the Tactical process (S.3.2), and may change another default rule only where the Constitution explicitly allows it (S.5.2.1(d)). Process it like any other proposal.

If the proposal is outside governance scope, name it: "This sounds like [tactical/strategic] rather than a governance change. Would you like to address it differently, or is there a governance version of this tension?"

**Is the proposal valid?** The Constitution sets three requirements:

> For a Proposal to be valid, the Proposer must be able to:
>
> - **(a)** describe a Tension that the Proposal would address for one of the Proposer's Roles; and
> - **(b)** share an example of an actual past or present situation illustrating that Tension; and
> - **(c)** give a reasonable explanation of how the Proposal would have reduced the Tension in that example.
>
> If at any point it becomes clear to the Facilitator that a Proposal does not meet these criteria, the Facilitator must discard the Proposal. (S.5.3.1)

**Facilitation script** (only when one of the three is unclear):
> "Which of your roles feels this tension? Can you give one real example, past or present? How would this proposal have helped in that example?"

If the Proposer cannot answer, discard the proposal and say why: "Without [a role's tension / a real example / how it would have helped], I have to set this proposal aside (S.5.3.1). You can bring it back when you have one."

**After the proposer finishes**: Optionally ask, "Do you need anything to make this proposal more concrete before we move on?" Then proceed.

---

#### Phase B: Clarifying Questions

**What happens**: Anyone can ask the proposer factual questions to understand the proposal better. No reactions, opinions, or disguised reactions are allowed.

**Facilitation script**:
> "Clarifying questions. Anyone can ask [Name] a question to understand the proposal better -- but not to react to it. [Name], you can also say 'not specified' if a question is about something your proposal intentionally leaves open."

Go around the group. Each person may ask one question (or pass), then the proposer answers. Continue rounds until no more questions.

**What to watch for**:
- A question that is actually a reaction: "Have you considered that this might cause [problem]?" -> That's a reaction. "Please hold that for the reaction round."
- A question that asks the proposer to justify their tension: not your job to justify it, just to state it.
- The proposer getting drawn into a long explanation. Keep answers brief.

---

#### Phase C: Reaction Round

**What happens**: Each person (except the proposer) shares their reaction to the proposal. This is the moment for concerns, enthusiasm, disagreements, and perspectives. The proposer remains silent.

**Facilitation script**:
> "Reaction round. Each person shares their reaction to this proposal -- what you're thinking, what concerns you, or what you appreciate about it. [Name] [the proposer], please hold your reactions for now. Who would like to start?"

Go around the group. Each person speaks once, uninterrupted.

**Rules**:
- The proposer does NOT respond during reactions -- note this explicitly if they start to
- No cross-talk between reactors
- Passing is allowed
- This is the one moment in the process where opinions and concerns are freely expressed -- it matters

**Facilitation note**: Reactions are data for the proposer, not a vote. The proposer is about to decide whether to amend -- they should listen, not defend.

---

#### Phase D: Amend and Clarify

**What happens**: The proposer may modify their proposal based on what they heard. They may also clarify what they intended. The proposer speaks; everyone else listens.

**Facilitation script**:
> "Amend and clarify. [Name], based on what you heard, you may modify your proposal or clarify your intention. What, if anything, are you changing?"

**Key point**: The proposer is not required to incorporate reactions. The proposal is theirs to amend as they see fit. The objection round is the check that follows.

**After the proposer speaks**: If the proposal changed significantly, briefly restate the updated proposal to confirm everyone heard the same thing.

---

#### Phase E: Objection Round

**What happens**: The Facilitator asks each person in turn whether they have an objection to the (possibly amended) proposal. This is the constitutional validity test.

**Facilitation script**:
> "Objection round. I'll ask each person: do you see any reason why adopting this proposal would cause harm or move us backwards? I'll test anything that sounds like an objection."

Ask each person: "[Name], do you have an objection?"

Response options:
- "No objection" -> move to the next person
- "I have an objection" -> test the objection (see below)
- "I'm not sure" -> test it as if it were an objection

**Include the proposer** -- they can object to their own proposal if they realize a problem during the meeting.

**Always include the Lead Link and the Facilitator themselves** in the objection round (the Facilitator should test their own view too).

---

##### Testing an Objection

The Facilitator may capture a concern as an objection without testing it, or test it (S.5.4.5(e)). The Facilitator must test it if any Circle Member asks (S.5.3.4(a)). These are the criteria:

> A concern about adopting a Proposal only counts as an Objection if the Objector can provide a reasonable argument for why it meets **all** of the following criteria:
>
> - **(a)** The Proposal would reduce the capacity of the Circle to enact its Purpose or Accountabilities.
> - **(b)** The Proposal would limit the Objector's capacity to enact the Purpose or an Accountability of a Role the Objector represents in the Circle, even if the Objector filled no other Roles in the Organization.
> - **(c)** The concern does not already exist even in the absence of the Proposal. Thus, a new Tension would be created specifically by adopting the Proposal.
> - **(d)** The Proposal would necessarily cause the impact, or, if it might cause the impact, the Circle wouldn't have an adequate opportunity to adapt before significant harm could result.
>
> However, regardless of the above criteria, a concern always counts as an Objection if adopting the Proposal would violate a rule in this Constitution. (S.5.3.2)

And the limit on the Facilitator's judgment:

> When assessing responses, the Facilitator may only judge whether the Objector presented arguments for each criteria using logical reasoning. The Facilitator may not judge on the basis of an argument's accuracy or the importance of addressing it. (S.5.3.3)

**First, check for a Constitution violation.** Ask: "Would adopting this proposal break a rule in the Constitution?" If the Objector says yes, it counts as an objection without the four tests. If you doubt the claim, ask the Secretary to rule (S.5.3.3): "Secretary, would adopting this violate the Constitution?" If the Secretary rules that it would not, you must dismiss the objection. Otherwise, capture it.

**Otherwise, ask one question per criterion, in order.** Stop at the first criterion with no reasoned argument.

1. **(a) Circle capacity** -- "How would this proposal reduce the circle's capacity to enact its purpose or accountabilities?"
2. **(b) Your role** -- "Which role that you represent here would it limit, and how?" A concern held only as a person, with no role the Objector represents, fails here.
3. **(c) New tension** -- "Is this created by adopting the proposal, or does it exist already without it?" A tension that exists already is something to bring as your own agenda item.
4. **(d) Necessary, or no chance to adapt** -- "Would the proposal necessarily cause this? If it only might, why couldn't we adapt before significant harm?" An anticipated harm counts when the Objector argues the circle could not adapt in time. Do not discard an objection only because the harm has not happened yet. (The "present data, not anticipated" test is v4.1 3.2.4; v5.0 replaced it.)

**What you judge, and what you do not.** You judge only whether each answer is a logical argument for that criterion. You do not judge whether it is true, or whether it matters enough (S.5.3.3). "I think it's a bad idea" or "there might be a better way" is not an argument for (a) to (d). "If this passes, the Billing role loses the domain it needs to send invoices, and we invoice weekly, so we could not adapt before customers go unbilled" is an argument for all four, even if you think it is wrong.

**If a criterion has no argument**: discard it and name the criterion: "I didn't hear how [criterion] applies, so this doesn't count as an objection (S.5.3.2). It may still be a tension worth its own agenda item."

**If the objection is valid**: Announce it clearly. "That's a valid objection. We'll move into integration." Do not process multiple objections at once -- resolve one, then re-run the objection round.

**If all objections are invalid**: Announce the proposal is adopted. "No valid objections -- this proposal is adopted. [Pause for a moment of acknowledgment.] Let's note the governance change for the Secretary."

---

#### Phase F: Integration

**What happens** (S.5.4.5(f)): the Facilitator takes each objection, one at a time. The participants brainstorm an amendment that resolves it. The objection is resolved when the Objector confirms the amended proposal would not trigger it, and the Proposer confirms it still addresses their tension. When all objections are resolved, go back to the objection round with the amended proposal.

**Facilitation script**:
> "Let's integrate [Objector]'s objection. Everyone may suggest amendments. [Objector], what change would resolve your objection and still address [Proposer]'s tension?"

**The rules of integration (S.5.3.4)**, in facilitation terms:
- **(a)** If any Circle Member asks, test the objection. If it fails the criteria, discard it.
- **(b)** The Objector must try to find an amendment that resolves the objection and still addresses the Proposer's tension. If the Objector is not making a good-faith attempt, deem the objection abandoned and drop it.
- **(c)** Anyone may ask the Proposer clarifying questions about the tension or its examples. If the Proposer is not answering in good faith, deem the proposal dropped.
- **(d)** The Objector may suggest an amended proposal and argue why it resolves the tension. On the Objector's request, the Proposer must argue why the amendment would fail to resolve the tension in at least one of their examples (they may add an example). If the Proposer is unable or unwilling, deem the proposal dropped.

**Facilitation guidance**:
- Keep the focus on amending the proposal, not relitigating the tension.
- If no integration emerges, use (b) to (d) to move it to a result rather than deferring by default. The Proposer may still withdraw the proposal.
- After all objections are resolved, re-run Phase E (Objection Round) for the amended proposal: an amendment can raise new objections.

---

#### After Each Item Is Adopted

Take a brief moment to acknowledge the governance change before moving to the next agenda item. This doesn't need to be elaborate -- a simple "This proposal is adopted" and a note to the Secretary is sufficient. In Holacracy, governance adoption is real: the moment it is adopted, the structure is live.

Log for the Secretary: the exact change (role added/modified, accountability added, domain defined, policy created), the proposer, and the date.

---

### Step 4: Closing Round

Same as Tactical -- each person shares a brief reflection, uninterrupted. See `tactical-meeting.md` for full facilitation script.

---

## Post-Meeting Actions

After the meeting:

1. **Produce the governance record** -- list of proposals processed, with outcomes (adopted, rejected, deferred)
2. **Flag Secretary actions** -- for each adopted proposal, specify exactly what needs to be entered into GlassFrog (role name changes, new accountabilities, new domains, new policies). The API cannot do this -- it must be done through the GlassFrog UI.
3. **Note deferred tensions** -- any tensions raised but not processed, formatted for a future governance meeting agenda

---

## Common Facilitation Challenges

**"Can't we just decide this without the full process?"**: No. The IDM process is what gives governance changes their constitutional authority. Bypassing it means the change is not constitutionally adopted. You can run through the process quickly for simple proposals, but you cannot skip phases.

**A proposal is unclear**: If after Phase A and Phase B the proposal is still ambiguous, ask: "Before we move to reactions, can you restate the proposal in one sentence?" The Facilitator has the authority to ask for this clarity.

**The reaction round becomes a debate**: If reactors start responding to each other rather than simply sharing their reactions, redirect: "Let's keep this as individual reactions -- save the conversation for after the meeting."

**The same objection keeps coming back**: If an objector keeps raising a concern in different words and still gives no reasoned argument for one of the four criteria, name the gap: "I still haven't heard how [criterion] applies, so I'm setting this aside (S.5.3.2)." Judge only the logic of the argument, never whether you agree with it (S.5.3.3).

**Someone tries to make a counter-proposal**: Counter-proposals are not part of the IDM process. If someone wants to propose something different, they can add it to the agenda for the same or a future governance meeting.

**The proposer withdraws the proposal**: A proposer can withdraw their proposal at any time before adoption. If this happens mid-objection-round, acknowledge it and move to the next agenda item.

**Time runs out**: If the meeting is running long, check in with the group: "We have [N] items remaining and [X] minutes. Should we defer remaining items to the next governance meeting, or would you like to continue?" Defer rather than rush the process.
