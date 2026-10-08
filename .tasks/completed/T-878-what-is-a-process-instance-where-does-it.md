---
id: T-878
name: "What is a process instance, where does its identity live, and what binds it
  to real governed work"
description: >
  arc-005 S2/B4. ONE QUESTION: what is an instance here? Must produce the storage
  home, the identity scheme, whether the binding is authored or derived, and two-way
  resolution (given T-873 name its template and current node; given a template list
  its live instances). Tasks stay canonical per T-175 IW-1 — an instance binds to
  the task graph, it does not become it. Do not file build tasks under this id; on
  GO they are filed separately and in the same session (this project's measured GO-to-successor
  decay is 26 of 30).

status: work-completed
workflow_type: inception
target_blast_radius: 3
voi_score: 0.5
owner: agent
horizon: null
arc_id: process-instances
tags: [arc:process-instances]
components: []
related_tasks: [T-880, T-881]
created: 2026-09-26T22:42:30Z
last_update: 2026-09-27T22:44:54Z
date_finished: 2026-09-27T22:44:54Z
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
  - ts: '2026-09-26T23:10:11Z'
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

# T-878: What is a process instance, where does its identity live, and what binds it to real governed work

## Problem Statement

When we say `T-873` is an instance of `task-lifecycle`, what object is that, where does it
live, and what makes the claim true? SD-10 raised it in July 2026 and it was never decided —
`DISPOSITION-2026-07-28.md` records "no binding, no instance files, no gated setter". Project
goals G3 and G4 both sit behind the answer. Full artifact:
`docs/reports/T-878-process-instance-identity.md`.

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

We believe that if a process instance carries its own identity and records which template it instantiates,
we will achieve an answer to "what process is this task following, and which step is it on" that comes from the system rather than from a person who remembers.
We will know that we are successful when we see a single command, run against at least 3 real task ids drawn from .tasks/active, that returns the template id and the current node id for each — and returns an explicit "no instance" for a task that has none, rather than an empty string or a guess.

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

- **IW-1: Does anything in the tree ALREADY bind a real entity to a process template?**
  confidence: 3
  disposition: answered
  rationale: No. Three candidates checked, all negative: the designer registry binds workflow refs to workflows (off-page connectors), no task field points at a map (workflow_type is a category), and update-task.sh:249 is guarded on .context/designer/projects/aef-task-lifecycle/meta.json which is ABSENT — control: sibling audit-process/meta.json exists, so the path shape is right and the name is wrong. That hint has never executed here. See docs/reports/T-878-process-instance-identity.md F1.Asked first and deliberately, because a yes collapses most of this inception. SD-10 says
  "no binding, no instance files, no gated setter" — but that was written 2026-07-28 and the
  designer registry (`web/designer_registry.py`, `fw bpmn claim`) binds a ghost uuid to a live
  project, which is binding-shaped. Whether that is an instance binding or a different thing
  wearing similar clothes is the first thing to measure.

- **IW-2: Where does instance state live?**
  confidence: 3
  disposition: answered
  rationale: State beside the entity it describes, not in a parallel store. Only the non-derivable half (current node) needs recording at all. A parallel store is a join to keep in sync, and the corpus already has one whose naming drifted out of alignment (F1).Candidates: a file per instance under `.context/`; a single registry keyed by entity id;
  or derived on demand from state the task system already holds. Derived is cheapest and
  needs no new writer — it is only available if the current node can be computed rather than
  recorded.

- **IW-3: What is the instance identity — minted, or an existing identifier?**
  confidence: 3
  disposition: answered
  rationale: Existing identifier, not minted. T-873 is already stable, unique, human-legible and referenced corpus-wide; a minted uuid would be a second id for one object and a join to drift. Assumption A2 came back FALSE.Minting a uuid is the obvious move and may be the wrong one: `T-873` is already a stable,
  unique, human-legible identifier that the whole corpus references. A second id for the same
  thing is a join to maintain and a thing to drift.

- **IW-4: Is the binding authored or derived?**
  confidence: 3
  disposition: answered
  rationale: Both, split by half. Template is DERIVABLE from workflow_type (closed set, one template per entity kind). Node position is NOT: task-lifecycle has 15 lane-prefixed node ids against ~5 task statuses with no mapping table in the tree, so it must be recorded. F2/F3.Authored means someone writes "T-873 instantiates task-lifecycle" and it can be wrong or
  absent. Derived means the system infers it from what the task already is — which is only
  possible if `workflow_type` (or similar) maps onto a template deterministically.

- **IW-5: What does resolution return for an entity with no instance?**
  confidence: 3
  disposition: answered
  rationale: An explicit "no instance", and THREE states not two — no instance / template known, node unknown / fully resolved. The middle state is the common case for every task predating the mechanism, and collapsing it into either neighbour is how the call site starts guessing.Named as its own question because it is where this class of feature usually rots: an empty
  string, a null, or a guess are all indistinguishable from "not modelled" at the call site.
  The hypothesis commits to an explicit "no instance", and that has to survive design.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

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
- [x] Assumptions tested — A1 HELD (and more strongly than stated), A2 FALSE (no minting needed), A3 HALF FALSE (template derivable, node not). Two of three inverted; artifact: docs/reports/T-878-process-instance-identity.md §2
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

**Recommendation:** GO — on the REDUCED scope the findings identify, not the scope this was filed with.

**Rationale:** Two of three assumptions came back FALSE, both in the cheap direction. (A2) No new identifier is needed: `T-873` is already stable, unique, human-legible and referenced corpus-wide, and minting a uuid beside it would be a second id for one object. (A3) Half the binding needs no authoring at all — "which template" is derivable from `workflow_type`, a closed set with one template per entity kind. What genuinely remains is ONE new thing: a recorded current-node per entity, and it is needed because `task-lifecycle` carries 15 lane-prefixed node ids (`frw_1_task`, `agt_1_write`, `hum_1_human`, …) against roughly five task statuses, with no mapping table anywhere in the tree. Position cannot be computed; it has to be recorded.

That is materially smaller than SD-10's framing of "instance files, identity scheme, gated setter", and smaller than what arc-005's scope assumed when it filed T-880 and T-881. Those two should be REWRITTEN against this finding rather than adapted — their own bodies already say a different design means rewrite, not adapt.

WHAT A NO-GO WOULD HAVE LOOKED LIKE, so the GO is not reflexive: had the node ids corresponded to task statuses, resolution would have been a query over data the task system already holds, no instance object would have been needed, and the honest answer would have been NO-GO on building anything. I checked for that first. It is not there.

**Evidence:**
- Three binding candidates checked, all negative. The designer registry binds workflow refs to workflows (off-page connectors), not entities to templates; no task frontmatter field points at a map.
- `update-task.sh:249` — the one hairline I had cited twice as existing — is guarded on `.context/designer/projects/aef-task-lifecycle/meta.json`, which is ABSENT. Positive control: sibling `audit-process/meta.json` exists, so the path shape is right and only the name is wrong. That hint has never executed in this project, and SD-10's "no binding" is therefore more completely true than I represented it.
- 15 map node ids vs ~5 task statuses, no mapping table in the tree.
- `workflow_type` is a closed set and the corpus holds a template per entity kind.

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

**Decision**: GO

**Rationale**: Recommendation: GO — on the REDUCED scope the findings identify, not the scope this was filed with.

Rationale: Two of three assumptions came back FALSE, both in the cheap direction. (A2) No new identifier is needed: `T-873` is already stable, unique, human-legible and referenced corpus-wide, and minting a uuid beside it would be a second id for one object. (A3) Half the binding needs no authoring at all — "which template" is derivable from `workflow_type`, a closed set with one template per entity kind. What genuinely remains is ONE new thing: a recorded current-node per entity, and it is needed because `task-lifecycle` carries 15 lane-prefixed node ids (`frw_1_task`, `agt_1_write`, `hum_1_human`, …) against roughly five task statuses, with no mapping table anywhere in the tree. Position cannot be computed; it has to be recorded.

That is materially smaller than SD-10's framing of "instance files, identity scheme, gated setter", and smaller than what arc-005's scope assumed when it filed T-880 and T-881. Those two should be REWRITTEN against this finding rather than adapted — their own bodies already say a different design means rewrite, not adapt.

WHAT A NO-GO WOULD HAVE LOOKED LIKE, so the GO is not reflexive: had the node ids corresponded to task statuses, resolution would have been a query over data the task system already holds, no instance object would have been needed, and the honest answer would have been NO-GO on building anything. I checked for that first. It is not there.

Evidence:
- Three binding candidates checked, all negative. The designer registry binds workflow refs to workflows (off-page connectors), not entities to templates; no task frontmatter field points at a map.
- `update-task.sh:249` — the one hairline I had cited twice as existing — is guarded on `.context/designer/projects/aef-task-lifecycle/meta.json`, which is ABSENT. Positive control: sibling `audit-process/meta.json` exists, so the path shape is right and only the name is wrong. That hint has never executed in this project, and SD-10's "no binding" is therefore more completely true than I represented it.
- 15 map node ids vs ~5 task statuses, no mapping table in the tree.
- `workflow_type` is a closed set and the corpus holds a template per entity kind.

**Date**: 2026-09-27T22:44:53Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-26T23:57:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-27T22:44:53Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO — on the REDUCED scope the findings identify, not the scope this was filed with.

Rationale: Two of three assumptions came back FALSE, both in the cheap direction. (A2) No new identifier is needed: `T-873` is already stable, unique, human-legible and referenced corpus-wide, and minting a uuid beside it would be a second id for one object. (A3) Half the binding needs no authoring at all — "which template" is derivable from `workflow_type`, a closed set with one template per entity kind. What genuinely remains is ONE new thing: a recorded current-node per entity, and it is needed because `task-lifecycle` carries 15 lane-prefixed node ids (`frw_1_task`, `agt_1_write`, `hum_1_human`, …) against roughly five task statuses, with no mapping table anywhere in the tree. Position cannot be computed; it has to be recorded.

That is materially smaller than SD-10's framing of "instance files, identity scheme, gated setter", and smaller than what arc-005's scope assumed when it filed T-880 and T-881. Those two should be REWRITTEN against this finding rather than adapted — their own bodies already say a different design means rewrite, not adapt.

WHAT A NO-GO WOULD HAVE LOOKED LIKE, so the GO is not reflexive: had the node ids corresponded to task statuses, resolution would have been a query over data the task system already holds, no instance object would have been needed, and the honest answer would have been NO-GO on building anything. I checked for that first. It is not there.

Evidence:
- Three binding candidates checked, all negative. The designer registry binds workflow refs to workflows (off-page connectors), not entities to templates; no task frontmatter field points at a map.
- `update-task.sh:249` — the one hairline I had cited twice as existing — is guarded on `.context/designer/projects/aef-task-lifecycle/meta.json`, which is ABSENT. Positive control: sibling `audit-process/meta.json` exists, so the path shape is right and only the name is wrong. That hint has never executed in this project, and SD-10's "no binding" is therefore more completely true than I represented it.
- 15 map node ids vs ~5 task statuses, no mapping table in the tree.
- `workflow_type` is a closed set and the corpus holds a template per entity kind.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c7c14f97
- **Timestamp:** 2026-09-27T22:44:55Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-5
     - evidence: `IW-5 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-0d9d3ee9
- **Timestamp:** 2026-09-27T22:44:55Z
- **Overall:** CONTRADICTED
- **Claims:** 5

| Claim | Type | Status |
|-------|------|--------|
| `T-873` | task | ✓ pass |
| `.context/designer/projects/aef-task-lifecycle/meta.json` | file | ✗ fail — file not found at PROJECT_ROOT |
| `audit-process/meta.json` | file | ✗ fail — file not found at PROJECT_ROOT |
| `T-880` | task | ✓ pass |
| `T-881` | task | ✓ pass |

### 2026-09-27T22:44:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
