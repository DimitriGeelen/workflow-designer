---
id: T-1215
name: "Plain bpmn:task from third-party maps is re-emitted as-is (T-337 foreignTag),
  but AEF's intake does not support bpmn:task"
description: >
  AEF msg 0917b9b0 (2026-10-19): bpmn:task (a plain task) is not a supported node
  type in AEF's tools/corpus_spec.py. The designer imports a third-party plain task
  as a foreignTag node (drawn as a serviceTask rectangle, T-337) and re-emits <bpmn:task>
  verbatim, so such a map would not pass AEF's intake. Options to decide: (a) AEF
  accepts bpmn:task; (b) the designer offers to convert it to a supported type on
  import, with a notice (never silently); (c) leave it and say so in the export notice.
  Ask AEF which they prefer; a conversion changes semantics and needs the operator
  or the reviewer.

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-19T12:37:49Z
last_update: 2026-10-20T09:52:48Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-20T09:52:48Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 3
      D2: 3
      D3: 3
      D4: 3
      F-RECALL: 3
      F2: 3
      F4: 3
      F3: 3
      F1: 3
    rationale: D1=3 (voi:decision-with-alternatives~'go/no-go'); D2=3 
      (voi:decision-with-alternatives~'go/no-go'); D3=3 
      (voi:decision-with-alternatives~'go/no-go'); D4=3 
      (voi:decision-with-alternatives~'go/no-go'); F-RECALL=3 
      (voi:decision-with-alternatives~'go/no-go'); F2=3 
      (voi:decision-with-alternatives~'go/no-go'); F4=3 
      (voi:decision-with-alternatives~'go/no-go'); F3=3 
      (voi:decision-with-alternatives~'go/no-go'); F1=3 
      (voi:decision-with-alternatives~'go/no-go')
    rubric_sha: e4a00f38e801
---

# T-1215: Plain bpmn:task from third-party maps is re-emitted as-is (T-337 foreignTag), but AEF's intake does not support bpmn:task

## AEF (msg abc0de1e, 2026-10-19)

AEF is willing to take option (a): on our decision they file the intake side as a TYPE_TO_TAG addition with
round-trip, like callActivity in T-4374. That makes (a) cheap on their side, the main unknown behind the DEFER.

**Evidence (corrected 2026-10-20; the 2026-10-19 version said 5/11 and cited 68 "model-written" maps, both wrong — see
A-1):** 8 of the 11 third-party fixtures (`tests/fixtures/third-party/`) carry a plain `bpmn:task`, and our own
authoring kit's example is one (AUTHORING.md:65; 12 in its calibration clean map). Plain task is common, including in
what our kit teaches. That points to (a): AEF accepts `bpmn:task` round-trip. Converting it in the designer (b) would
rewrite the very maps the kit invites.

## Problem Statement

A plain `<bpmn:task>` (BPMN's untyped activity) is what bpmn.io and most authors write by default. The designer keeps it
through a save (T-337 foreignTag: drawn as a task, re-emitted as `bpmn:task`), but AEF's intake (`tools/corpus_spec.py`)
does not accept `bpmn:task`, so such a map cannot be promoted into AEF's corpus. Who: anyone who brings a third-party
map, and the other models that write maps with our authoring kit. Why now: AEF raised it (msg 0917b9b0) while maps
from outside are starting to reach their corpus.

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

We believe that AEF's intake accepting `bpmn:task` with a round trip (option a), while the designer keeps re-emitting it
unchanged,
we will achieve third-party and kit-authored maps reaching AEF's corpus without the designer rewriting what their
authors wrote.
We will know that we are successful when we see a map containing `<bpmn:task>`, saved by the designer, pass AEF's intake
and come back from `corpus_spec` with every `bpmn:task` still a `bpmn:task` (AEF's TYPE_TO_TAG test, as for callActivity in
T-4374), and no conversion code in the designer.

## Assumptions

- A-1: plain `bpmn:task` is common in the maps that reach AEF. **Validated:** 8 of the 11 third-party fixtures carry one
  (6 prefixed bpmn:/bpmn2:, 2 unprefixed); our own authoring kit's example is a `bpmn:task`
  (docs/authoring-kit/AUTHORING.md:65), and its calibration clean map carries 12. (Corrected 2026-10-20 per reviewer
  amber: the first count, 5/11, missed unprefixed tasks, and the "68 maps other models wrote with our kit" claim was
  false — those files are copies of our two calibration fixtures, which the models reviewed, not wrote.)
- A-2: accepting it is cheap on AEF's side. **Validated:** AEF msg abc0de1e — a TYPE_TO_TAG addition with round trip,
  like callActivity in T-4374, filed on our decision.
- A-3: converting it in the designer (option b) changes meaning. **Holds:** `bpmn:task` says "an activity of no stated
  kind"; turning it into serviceTask or userTask invents an executor the author did not name, and rewrites exactly the
  maps our kit invites authors to write.

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

- **IW-1: How common is plain `bpmn:task` in what reaches AEF?**
  confidence: 3
  disposition: answered
  rationale: 8/11 third-party fixtures (re-counted 2026-10-20, prefixed and unprefixed); the kit's own example
  (AUTHORING.md:65) and 12 plain tasks in its calibration clean map.
- **IW-2: Is accepting it cheap on AEF's side?**
  confidence: 3
  disposition: answered
  rationale: AEF msg abc0de1e: TYPE_TO_TAG addition with round trip, like T-4374, on our decision.
- **IW-3: Should the designer convert it instead (option b), or only say so on export (option c)?**
  confidence: 2
  disposition: answered
  rationale: no. (b) invents an executor and rewrites authors' maps (A-3); (c) leaves the map unpromotable. (a) needs
  no designer change: it already keeps `bpmn:task` (T-337).

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: which of (a) AEF accepts, (b) designer converts, (c) export notice; the evidence for it. OUT: AEF's intake change
itself (their task, filed on our decision); any designer conversion code (not proposed).

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] Go/no-go on the exploration findings (reviewer-judged, `fw reviewer judge T-1215 --criterion 1`; an intake-compatibility choice between AEF accepting bpmn:task and the designer converting it; the reviewer may escalate)
  **Steps:**
  1. Run: `fw task review T-1215` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO (on option a) if:**
- plain `bpmn:task` is common in what reaches AEF (it is: A-1), and
- AEF can accept it with a round trip at bounded cost (it can: A-2)

**NO-GO if:**
- AEF would only accept a conversion, or plain tasks were rare enough that an export notice (c) costs less

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

**Recommendation:** GO (option a: AEF accepts `bpmn:task` with a round trip; the designer changes nothing)

**Rationale:** (Filed DEFER for two evidence gaps; both are closed, 2026-10-19.) Plain `bpmn:task` is common in what
reaches AEF (8/11 third-party fixtures; our kit's own example is one), and AEF can accept it cheaply (TYPE_TO_TAG with round
trip, like callActivity in T-4374). Converting it in the designer would invent an executor the author did not name and
rewrite the maps our own kit invites; an export notice would leave those maps unpromotable. The designer already keeps
`bpmn:task` through a save (T-337), so (a) needs no change on our side.

**Evidence:**
- AEF msg 0917b9b0 (the problem) and abc0de1e (option a cheap, filed on our decision).
- Re-count 2026-10-20: tests/fixtures/third-party, 8/11 carry a plain task (6 prefixed, 2 unprefixed);
  docs/authoring-kit/AUTHORING.md:65 (the kit's example); 12 plain tasks in the kit's calibration clean map.
  (Corrected per reviewer amber; the earlier 5/11 and "68 model-written maps" were wrong.)
- T-337: foreignTag round trip keeps `bpmn:task` byte-identical (third-party goldens).

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

<!-- Filled at completion via: fw inception decide T-1215 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-20T09:52:48Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
