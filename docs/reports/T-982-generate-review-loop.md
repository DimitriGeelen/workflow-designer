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
