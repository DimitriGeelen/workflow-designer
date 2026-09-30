---
id: T-937
name: "Why do agents generate operator decisions faster than any human answers them,
  and which of the 51 open rulings should never have been escalated"
description: >
  Inception: Why do agents generate operator decisions faster than any human answers
  them, and which of the 51 open rulings should never have been escalated

status: work-completed
workflow_type: inception
current_node: frw_11_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-09-29T21:44:42Z
last_update: 2026-09-30T14:43:51Z
date_finished: 2026-09-30T14:43:51Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): BOTH fields below are now ESTIMATED
# automatically from this task's own text. Do not pre-fill them.
#
# They used to ship with `target_blast_radius: 3` and `voi_score: 0.5` already
# filled in, and that default was doing real damage: int(round(0.5*5)) == 2, and
# an ABSENT voi_score also scored 2, so "nobody assessed this" and "someone
# judged it middling" were the same number. 42 of 45 inceptions ranked on a
# value no person had chosen, and because 2 is mid-range they sorted ahead of
# measured work. T-624 tried to fix it with a warning printed right here; 28
# days later the figure had not moved by one, because a comment is not a gate.
# Deleting the default IS the gate.
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no
# automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
# Anything without `_source: human` is treated as the estimator's own and is
# freely recomputed. There is no third state, deliberately: an "unknown
# provenance" value is exactly the ambiguity this replaced.
#
# target_blast_radius — int 0..9. Anticipated component count of the build work
#   this inception would authorise on GO; substitutes for the absent
#   components: list in the F8 cost formula (040).
#   Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem
#   (M), 7=multi-arc (L), 9=framework-wide (XL).
# voi_score — float 0..1. Value of Information: expected value of RESOLVING
#   this question, independent of build cost. Higher when the answer affects
#   many tasks or unblocks a strategic decision.
bvp_scores_proposed:
  - ts: '2026-09-29T21:45:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 1
      D2: 1
      D3: 1
      D4: 1
      F-RECALL: 1
      F2: 1
      F4: 1
      F3: 1
      F1: 1
    rationale: D1=1 (voi:no-leverage-signal (measured low, not unassessed)); 
      D2=1 (voi:no-leverage-signal (measured low, not unassessed)); D3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); D4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F-RECALL=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F2=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F1=1 
      (voi:no-leverage-signal (measured low, not unassessed))
    rubric_sha: e4a00f38e801
---

# T-937: Why do agents generate operator decisions faster than any human answers them, and which of the 51 open rulings should never have been escalated

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that a material share of the operator's 51 open rulings are escalations of questions a
prior ruling in `decisions.yaml` already covers — so the agent is asking for decisions that have
been made,
we will achieve a lower operator decision load by naming that class and stopping the escalation,
rather than by answering the backlog faster.
We will know that we are successful when we see, over a random sample of 15 of the 51 read one by
one against `decisions.yaml`, **at least 4 that a named existing ruling would have settled** — each
recorded as `IW-2 hit: <criterion> -> <ruling id>` in the research artifact so the mapping is
checkable by someone who was not in the room.

<!-- THE FALSIFICATION IS THE POINT, and it is deliberately reachable. 3 or fewer hits out of 15
     means escalation discipline is NOT the defect: the 51 are genuinely the operator's, no
     agent-side fix exists, and the honest deliverable is a statement of the real decision load plus
     a NO-GO. I expect that outcome to be at least as likely as the hypothesis holding — two attempts
     this week to find an agent-side fix for this queue already failed (T-932 refuted on measurement,
     T-933's delegation refused by the verb twice), and T-872 reached the same conclusion on
     2026-09-26 from different evidence: "they are requests for rulings, and delegation.py is right
     to leave them human."

     4/15 is the threshold rather than a proportion invented to be easy: below that, a "class" would
     be two or three individual cases, and naming a class from three instances is how a rule gets
     written that immediately over-fires. 15 is the sample size a 60-minute manual read supports —
     and the read must be manual, because today's regex attempts at exactly this question produced 21
     false positives by matching the Steps block instead of the verdict. -->


## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

- **IW-1: Is this a rate or a one-off accumulation?** Over a 90-day window, are operator criteria being
  created faster than they are ticked — or is the backlog a spike that has stopped growing? Everything
  else depends on the answer: a stalled pile and a rising tide want different remedies.
  confidence: 2
  disposition: answered
  rationale: Stock count of open operator criteria in .tasks/active/: 34 on 2026-07-06, 84 on 2026-09-28, ~+4/week net. It IS a rate, but mild, and one week went -46 so batch clearing works.
- **IW-2: Could any material share of the 51 rulings have been settled under a ruling that ALREADY
  exists?** This is the load-bearing question. If yes, the defect is escalation discipline and it is
  ours. If ~none map to a prior ruling, then the criteria are irreducibly the operator's and no
  agent-side fix exists — in which case saying so plainly is the deliverable.
  confidence: 1
  disposition: answered
  rationale: NO, and this falsifies the hypothesis. 1 of a reproducible 15-sample (seed 937) was arguably settleable by an existing ruling, threshold was 4. Escalation discipline is not the defect; no agent-side fix of the kind this task sought exists.
- **IW-3: Is the backlog concentrated in a few task shapes or spread evenly?** A concentration admits a
  targeted fix; an even spread does not. Grouping by workflow_type, arc and originating family answers it.
  confidence: 2
  disposition: dissolved
  rationale: Not concentrated in task shapes, which is what spike 3 was designed to test. The apparent concentration was 12 identical template-generated criteria, and that turned out to be 12 genuinely undecided inceptions at DEFER rather than a template defect (my claim, withdrawn at AEF inbox @19). The question as framed has no answer worth spiking.
- **IW-4: Does age indicate neglect, or correct prioritisation?** A 42-day median was measured before. If
  the oldest criteria are also the lowest unblock score, the ordering is working and age is not evidence
  of a problem. If the oldest are HIGH-value, that is a different and worse finding.
  confidence: 1
  disposition: answered
  rationale: Age measures when someone last sat down with the queue, not per-item neglect: the -46 week shows clearing happens in bursts rather than FIFO. A 42-day median sampled during a quiet stretch overstates neglect.
- **IW-5: Is there a settling mechanism other than one human answering serially?** Standing rulings over
  classes, a default with an objection window, a reviewer authority that does not exist today. Asked last
  and deliberately: it is only worth exploring if IW-2 comes back negative, and proposing new authority
  before establishing that the current authority is saturated would be building a bypass looking for a
  reason (PD-302).
  confidence: 0
  disposition: deferred
  rationale: Not explored, by design: it was gated on IW-2 returning positive and IW-2 returned negative. Proposing a new settling authority when the existing authority is not saturated would be a bypass looking for a reason (PD-302). If it is ever opened it is a separate inception and the operator's to open.
## Exploration Plan

Three spikes, one question each, no build artefacts. Ordered so a negative result on spike 2 makes
spike 3 unnecessary. Research artifact is `docs/reports/T-937-operator-decision-production-rate.md`,
written BEFORE the research and updated as each spike lands (C-001).

1. **Rate** (time-box 30 min). Criteria created vs ticked per week, 90-day window, from git history of
   `.tasks/`. Answers IW-1 and IW-4. Cheap and mechanical, and it decides whether this is a rate problem
   at all — so it runs first and a negative result here is a NO-GO for the whole task.
2. **Escalation reason** (time-box 60 min). Read a sample of the 51 against `decisions.yaml` and the
   learnings register: did a ruling already cover it? Answers IW-2. **Manual reading, not a regex.** The
   regex attempts of 2026-09-29 produced 21 false positives by matching the Steps block instead of the
   verdict, and one of them would have offered 21 sovereign decisions to a reviewer. A classifier is the
   wrong instrument for "is this already ruled on".
3. **Shape** (time-box 30 min). Group the 51 by workflow_type, arc and originating family. Answers IW-3.
   Only runs if spike 1 shows a rate problem and spike 2 shows the criteria are genuinely the operator's.

IW-5 is not spiked. If IW-2 returns negative it becomes the subject of a separate inception, because
proposing a new settling authority is a bigger question than this task's time-box and is the operator's
to open.

## Technical Constraints

- The only history available is git over `.tasks/`. A criterion "created" is a `- [ ]` line appearing in
  a commit; "ticked" is it becoming `- [x]`. Both are inferable but neither is recorded as an event, so
  the rate is a reconstruction and its error bars must be stated rather than implied.
- Task files are renamed on completion (`active/` → `completed/`), so any per-file history needs
  `--follow` or the count breaks silently at the rename.
- `[REVIEW]`-prefixed criteria can only be ticked by the operator, so a tick is a reliable signal of a
  human act. That is the one clean measurement available here and the rate spike should lean on it.
- **The corpus moves under the measurement.** Anything asserted must be pinned to a commit range, not to
  "today" — the same rot that took T-885's verification red for ten hours (T-3326).

## Scope Fence

**IN:** why the rate is what it is; whether any share of the 51 was avoidable; what the operator's real
decision load is.

**OUT, explicitly:**
- Answering any of the 51. That is the operator's, and a separate sitting.
- Reclassifying, re-prefixing or delegating any criterion. Two attempts this week established the
  criteria are correct; a third would be thrash.
- Proposing new authority. Any such finding is a proposal for the operator to rule on (PD-302), and
  IW-5 is deliberately unspiked until IW-2 is settled.
- Building anything. No mechanism, no check, no gate. If the exploration produces a GO, implementation
  is separate build tasks filed on this task's evidence.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** NO-GO on the premise this task was opened to test, and nothing to build.

**Rationale:** The exploration ran and answered its load-bearing question negatively. IW-2 asked
whether a material share of the operator's open rulings could have been settled under a ruling that
already exists; the threshold was 4 of a reproducible 15-sample and the result was 1, arguably 0.
Escalation discipline is not why the queue grows, so there is no agent-side mechanism to build. That
outcome was written into the hypothesis as reachable precisely so this recommendation could be made
without inventing a fix to look useful — and T-872 reached the same conclusion from different evidence
on 2026-09-26.

What the exploration DID establish is worth keeping without a build task: the queue grows about +4 per
week net (34 open on 2026-07-06, 84 on 2026-09-28), it is cleared in bursts rather than FIFO, and one
week in August went -46 — so the backlog is unattended rather than unclearable. The remedy is a sitting
with the docket, which already exists and needs no mechanism.

**Evidence:**
- Stock measurement, immune to the rename blindness that broke the first attempt: 34 -> 84 over twelve
  weeks. The flow measurement produced "1801 created / 104 ticked / answer rate 0.06" and was WRONG —
  a task completion is a `git mv`, which shows in a diff as a rename with no content lines, so the
  method counted arrivals and was blind to departures. Recorded because that figure would otherwise
  have been quoted onward as a fact about the corpus when it is a fact about the method.
- IW-2 read by hand over 15 criteria (random.seed(937), reproducible). A keyword-overlap aid put
  PD-308 top for 11 of 15 because PD-308 is simply long text — third failure this week of a scoring
  heuristic on this exact question, and the reason the read was manual.
- Two structural claims made during this work were WITHDRAWN after checking properly: a 54-criterion
  denominator gap in the delegation boundary (real divergence: 3, AEF inbox @13) and a template defect
  that was me not reading one line above where I stopped grepping (AEF inbox @19). Both are recorded
  in this artifact rather than edited out.
- One finding stands and went upstream: any AEF metric deriving rates from `.tasks/` git diffs has the
  rename blindness (AEF inbox @18, ask b, not withdrawn).

**What this does NOT recommend:** IW-5 — whether a settling mechanism other than one human answering
serially should exist — was deliberately left unspiked because it was gated on IW-2 returning positive.
Opening it is the operator's, as a separate inception. Proposing new authority while the existing
authority is not saturated would be a bypass looking for a reason (PD-302).

**Rationale:**

DEFER because the exploration has not run, not because the question is doubtful. What is already measured: 79 open operator criteria across 70 active tasks, of which 51 ask for a ruling, 24 for a review and 4 for an act, with zero delegable to a reviewer (tools/_t872-decision-docket.py, 2026-09-29). An earlier task here measured a median unanswered-AC age of 42 days and concluded we are asking too much and that is ours to fix rather than theirs. The docket made that legible and did not change it. What is NOT yet evidenced is the production rate, the escalation reason per item, or whether any material share of the 51 could have been settled by the agent under a ruling that already exists - and those three are the whole question. A recommendation before the spikes would be a guess wearing a verdict's clothes.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

**Decision**: NO-GO

**Rationale**: NO-GO. IW-2's load-bearing question was answered negatively: 1 of a reproducible 15-sample (threshold 4) could have been settled under an existing ruling. Escalation discipline is therefore not why the queue grows, and there is no agent-side mechanism to build. The measurements stand and are not discarded: roughly +4/week net growth, cleared in bursts rather than FIFO, one week in August at -46. The backlog is unattended rather than unclearable; the remedy is a sitting with the docket that already exists.

**Date**: 2026-09-30T14:43:50Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-29T21:45:34Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-30T14:43:50Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** NO-GO
- **Rationale:** NO-GO. IW-2's load-bearing question was answered negatively: 1 of a reproducible 15-sample (threshold 4) could have been settled under an existing ruling. Escalation discipline is therefore not why the queue grows, and there is no agent-side mechanism to build. The measurements stand and are not discarded: roughly +4/week net growth, cleared in bursts rather than FIFO, one week in August at -46. The backlog is unattended rather than unclearable; the remedy is a sitting with the docket that already exists.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-aa81f6a1
- **Timestamp:** 2026-09-30T14:43:52Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-c5058a48
- **Timestamp:** 2026-09-30T14:43:52Z
- **Overall:** CONFIRMED
- **Claims:** 1

| Claim | Type | Status |
|-------|------|--------|
| `T-872` | task | ✓ pass |

### 2026-09-30T14:43:51Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: NO-GO
