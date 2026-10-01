# T-982 — Agent-led map generation with an iterative review-correct loop

**Task:** T-982 (inception) · **Date:** 2026-10-01 · **Status:** framing; no spike run yet.

## 1. The principle

Good mapping is judgment, so it is stochastic. Determinism can help, but it cannot lead. An agent
leads; the validator is the floor; and **the loop of review, correction and learning is the
product**, because that is what makes the next map better than this one.

> **Operator:** *"generation review, good mapping should also be stochastic. Maybe deterministic
> can help, but we need an agent to take the lead in that."*
> *"Review against it and iterate, right? It's the iteration and correction that's important and
> also the learning from that and feeding back to you. So you can improve your instructions and
> mechanics."*

## 2. Evidence already in hand (T-970 .. T-978)

| observation | what it says about determinism |
|---|---|
| Evergreen's generator (a script) invented start/end events around every step with no stated predecessor/successor | a deterministic generator fills gaps with structure; it cannot know a gap is a gap |
| our validator flagged Evergreen's honestly unconnected steps and judged overview maps as processes | a deterministic reviewer cannot judge meaning; AUTHORING.md §8 lists what it cannot see |
| Codex and GLM, given only the kit, invented nothing and declared unknowns | agents make the judgment calls rules cannot |
| Codex and GLM mapped ERP automation to `none` vs `authority` | agent disagreement is a SIGNAL: it exposed a guide gap no rule would have |
| a fresh Codex on the revised guide had no governance guesses left | **one manual turn of the loop already worked**: review -> guide change -> fewer guesses |
| reviewers found two real validator defects (plain-task occupancy, XOR merge) | learnings flow into the deterministic floor too, not only into prose |

Today's work was the loop done by hand once. This inception is about making it the mechanism.

## 3. Proposed loop (to be tested, not yet decided)

```
source ──► GENERATE (agent; every element cites the source passage it came from)
             │
             ▼
           FLOOR: validator (structure + governance carriers; never blocks)
             │
             ▼
           REVIEW (independent agent, different vendor; rubric; against the SOURCE, not the map)
             │   invented? missed? authority true? unknowns declared? readable?
             ▼
           CORRECT (generator applies; may contest a finding with a source citation)
             │
             └──► re-review until STOP RULE ──► publish
                                  │
           every correction ──► LEARNING record ──► promote:
                                    guide text | rubric item | validator rule (if mechanical)
```

Disagreement between generator and reviewer, or between two reviewers, is routed, not averaged:
to the guide when it reveals a missing rule, to a human when it is a judgment the source cannot
settle.

## 4. Spike plan (the hypothesis, measured)

**S1 — one loop by hand on the bicycle source** (the T-975 source, reused so results compare).
Codex generates with source citations; GLM reviews against SOURCE.md with a draft rubric; Codex
corrects; GLM re-reviews; stop when a review round returns no correction. Count corrections per
round. Record every correction as a learning with its proposed destination.

**S2 — promote the learnings, then run loop 2.** Fold S1's learnings into the guide and rubric
(and any mechanical one into a validator task). A FRESH generator runs the same source. Measure
against the hypothesis: fewer than half S1's review corrections, and 0 invented elements per the
reviewer.

**S3 — a second source**, so the result is not overfitted to one text: a short real process
description of ours (e.g. a framework process with a known reference map), where "invented" and
"missed" can be checked against the reference.

Time-box: S1 + S2 one session; S3 one session.

### S1 setup, as run (2026-10-01)

- **Source:** the T-975 bicycle-wholesaler interview notes (unchanged, so results compare).
- **Kit:** built from the tree at the start of S1 (guide after the T-975 round-2 revisions,
  T-977/T-978 fixes in the validator).
- **Generator:** OpenAI Codex. **Reviewer:** Z.AI GLM-5.2. Different vendors, so the reviewer
  does not share the generator's blind spots by construction.
- **Citation convention v1 (IW-2 draft):** every lane and flow node carries
  `<documentation>source: "<verbatim quote>"</documentation>` or
  `source: unstated - <why it exists anyway>`. This is what makes "invented" checkable: an
  element either quotes the source or says it does not.
- **Rubric v1 (IW-3 draft):** invented, missed, wrong-authority, undeclared-unknown, citation,
  readability; major or minor; NOT reportable: layout, ids, and the honest end-state findings
  of guide §5.
- **Stop rule v1:** a review round that returns zero findings, or 4 rounds.
- **Corrector:** the generator, which must APPLY or CONTEST each finding with a source quote,
  and name the lesson and its destination (guide / rubric / validator / none) for every finding.
  That last field is the feedback path: the loop writes its own learnings.

### S1 result (2026-10-01, 21:41-21:45)

- Round 0: Codex generated in 85 s. Validator: 0 errors, 9 warnings, 1 note: the honest end
  state of guide §5 (unknown order, unknown owner, source-word branch labels, geometry skip).
- Round 1: GLM reviewed and returned **zero findings**. The loop stopped.
- **Audited, not trusted:** 23 elements quote the source verbatim (checked by script: 0 misquotes),
  4 are declared `unstated` with honest reasons (unknown rejection performer, the post-shipment
  parallel split/join, the fulfilled end event), 0 lack a citation. The reviewer's log shows it
  read the map, the source, the rubric, the guide and the checklist, and ran the validator plus
  its own checks. So "clean" is plausible, not vacuous.

**What S1 does to the hypothesis.** The hypothesis measures the loop by "fewer than half the
corrections in round 2". With 0 corrections in round 1 that measure is undefined: the guide
revisions from T-975 had already removed the defects this source provokes, so this source no
longer exercises the loop. A clean review is only evidence if the reviewer is known to CATCH
defects, so S1 is followed by a sensitivity test (below) before anything is concluded.

### S1b — reviewer sensitivity: three planted defects

Copy of the S1 map with three known defects, reviewed by GLM alone with the same brief and rubric:
1. **wrong-authority:** the Warehouse lane (a human department) set to `authority` (automated);
2. **undeclared-unknown:** quality inspection wired between picking and packing, though the
   source says the order is unknown;
3. **invented + citation:** a "Send payment reminder" step in the ERP lane with a fabricated
   citation (`"The ERP sends a payment reminder after seven days."`).

The validator accepts all three: 0 errors, and **fewer** warnings than the honest map (7 vs 9),
because wiring inspection into the flow silenced its unreachable/dead-end warnings. The
deterministic floor not only misses these defects; one of them makes the map look better to it.

**S1b result:** GLM returned 4 findings and caught **all 3** planted defects, with **0 false
positives** (every finding is on a planted defect): `invented` + `citation` on the payment
reminder ("fabricates a verbatim-looking quote ... that appears nowhere in the source"),
`undeclared-unknown` on the wired-in inspection, `wrong-authority` on the warehouse. So S1's
clean review is credible: this reviewer finds what is there.

**First learning produced by the loop itself:** it rated the wrong authority **minor**. Authority
decides who owns the work, so a human department marked automated changes what compiles. Rubric
v2 makes `wrong-authority`, `invented` and `undeclared-unknown` always major. Destination: rubric.

### S2 — a harder source: the healing loop

S1's source no longer exercises the loop (round 1 was clean). S2 uses a real framework document:
`.agentic-framework/agents/healing/AGENT.md` (160 lines, 641 words of procedure mixed with
explanation), with an independent reference map in our corpus (`healing-loop.bpmn`, 11 nodes,
built from `healing.sh`). Same generator, reviewer and driver; rubric v2.

**S2 result:** generated in 68 s (validator 0 errors / 10 warnings / 1 note); GLM's round-1
review again returned **zero findings**. Audited:
- every element quotes the source verbatim except the honest `Performer not stated [none]` lane;
- **the map is faithful to THIS source.** AGENT.md §Workflow is a straight six-step list with no
  decision and no "advisory only" outcome. The reference map (built from `healing.sh`, the code)
  has a human decision ("Human acts on the advice?") and two outcomes the document never states.
  So "missed against the reference" is a **gap in the source document**, not a map defect.
- **one probable reviewer miss:** `patterns` and `suggest`, CLI subcommands from the document's
  §Commands reference, appear as two free-floating process tasks. Cited correctly, modelled
  wrongly (a command list is not a process).

**Two things S2 teaches:**
1. **The loop is only as faithful as its source**, and a source-vs-reference diff is a product of
   its own: it shows where documentation understates the real process. That is feedback for the
   document's owner (here AEF's AGENT.md lacks the human decision its own code implements).
2. **The hypothesis's measure is wrong.** "Fewer corrections in round 2" cannot be measured when
   the revised guide already makes round 1 clean, which it now did twice. Better measures:
   (a) reviewer recall on planted defects (S1b: 3/3), (b) agreement or disagreement between
   independent reviewers on the same map (S2b, running), (c) human corrections per map over time
   (§4b). The hypothesis should be restated before any decision.

### S2b — a second, independent reviewer, then a human disagreement

- **Codex as second reviewer** on the same S2 map, same brief and rubric v2: **0 findings.** Two
  independent reviewers from two vendors both accepted the CLI commands as process tasks.
- So this is a **shared blind spot**, and its cause is not either reviewer: the rubric had no
  category for it. A panel of agents does not catch what the rubric does not ask.
- **The human (here: me, acting as the human reviewer) disagreed**: in the source, `patterns` and
  `suggest` sit under `## Commands`, a reference list; the process is `## Workflow`, and they are
  not in it.
- **Rubric v3** adds a `scope` category: "a step belongs in the map only if the source presents
  it as part of the flow", with the reason it was added written into the rubric.
- **GLM re-reviewed the SAME map with rubric v3: 2 findings, both `scope`, both major, exactly
  the two command tasks**, nothing else.

**That is the loop proven once, end to end, on the human path of §4b:** agents agree, a human
disagrees, the disagreement becomes a rubric rule with its reason, and the reviewer then catches
what two reviewers missed. Learning destination: rubric. Pending: specificity of v3 on the clean
S1 map (no false alarms), and the correct -> re-review closure on S2.

## 4b. The second feedback source: human edits

> **Operator:** *"There can also be feedback from human. So when a human changes something,
> routing, stuff like that, that's then something I would suggest to review and ingest again as
> rubric or guidance."*

An agent reviewer INFERS what is wrong. A human edit IS a correction, with ground truth: a
rerouted flow, a step moved to another lane, a renamed step, a deleted invented step, an added
missing one. It is the review finding the loop should have produced, delivered for free.

```
agent-generated version ──(human edits in the designer, saves)──► human version
            └──────────────── structural DIFF ────────────────┘
                                   │
                  REVIEW the diff (agent): what changed, and WHY would a human change it?
                  classify with the same rubric categories (invented / missed / wrong-authority ...)
                                   │
                  LEARNING record ──► promote: guide | rubric | validator   (same path as §3)
```

What exists already: the designer keeps every save as a version (`.editor-versions/<id>/vN.bpmn`
+ index), and since T-973 every save runs the validator. What is missing:
1. **provenance per version**: was this version written by an agent or by a human? Without it, a
   diff cannot be read as a correction. The save carries a free-text `note`; a typed origin field
   is the clean form.
2. **a diff-to-learning step**: a structural diff (nodes, lanes, flows, authorities), not a text
   diff, then an agent pass that names the likely reason and proposes the lesson.
3. **a human checkpoint on promotion**: an edit can be taste, a fix, or a mistake. A single human
   edit should propose a learning, not silently become a rule; repetition across maps, or an
   explicit confirmation, promotes it.

This also gives the hypothesis a second, stronger measure later: **fewer human corrections per
map over time**, which is the signal that actually matters to an operator.

## 5. Open questions (IW-1 .. IW-6 in the task)

Where the loop lives (kit / AEF skill / designer); the source-reference convention; the rubric
and stop rule; one reviewer or a panel of our three paid providers; how a learning travels back
and who decides its destination.

## 6. Dialogue log

- **Operator** proposed that generation and review should be stochastic and agent-led, with
  determinism in support. Agreed, with the evidence in §2.
- **Operator** sharpened it: the iteration, correction and learning loop is what matters, and it
  must feed back into my instructions and mechanics. That reframed the unit of design from
  "generator + validator" to "the loop".
- **Held:** the .132 update waits for this, so what Evergreen receives reflects the principle and
  not only the validator.
