---
id: T-1491
name: "Phases editing from the palette: add a phase or divider, name it, drag its
  boundary, choose its row"
description: >
  Inception: Phases editing from the palette: add a phase or divider, name it, drag
  its boundary, choose its row

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
waiting_on: agent
revisit_at: 2026-11-30
created: 2026-11-23T12:55:10Z
last_update: 2026-11-24T09:38:55Z
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
  - ts: '2026-11-24T09:38:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1491: Phases editing from the palette: add a phase or divider, name it, drag its boundary, choose its row

## Problem Statement

Since 0.47.0 the designer draws phases a file already carries (T-1473, read-only). Nobody can make or change them in
the designer: Greenfield draws them in another tool, and a map without groups has no way to get phases at all. The
operator (2026-11-24, in session): "I want to be able to delete them or switch them on and off and I want to be able
to add them myself … in the left panel these brackets I want to be able to add them and add the documentation …
configure them … drag them to the left, to the right, and the configuration where the phase ends and starts". The
operator also asked that the design be tried from a persona and a user story before building. For whom: a workshop
facilitator or process owner who structures a map into phases (Greenfield's owner; AEF authors). Why now: phases are
on screen since 0.47.0, Greenfield's report now uses them, and the next ask is to edit them.

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

We believe that letting a person add a phase row and phases from the left panel, name and document them, move a
phase's start and end, show or hide a row, and delete phases, all on the canvas,
we will achieve that a facilitator keeps a map's phases in the designer instead of in a separate drawing.
We will know that we are successful when we see the persona's user story (docs/reports/T-1491-phases-editing.md:
on a map without phases, make 'Fase' with 5 phases and a second row, document one phase, move one boundary, hide the
second row, delete one phase, save) completed in the designer with 0 steps outside it, and the saved file read back
by 0.47.0's reader (T-1473) with the same phases, names and boundaries.

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

- **IW-1: What must a person be able to do with phases, step by step, to finish the persona's user story?**
  confidence: 0
  disposition: open
  rationale: walkthrough of 0.47.0 as the persona, docs/reports/T-1491-phases-editing.md
- **IW-2: Does a boundary move freely (any x) or by whole steps (F4: a phase is a range of steps)?**
  confidence: 0
  disposition: open
  rationale: operator: "drag them to the left, to the right … where the phase ends and starts"
- **IW-3: Is "switch them on and off" a view setting (not saved) or part of the map (saved)?**
  confidence: 0
  disposition: open
  rationale: to settle from the user story
- **IW-4: Where does a phase's documentation live in the file, so other tools keep it and Greenfield's reader sees it?**
  confidence: 0
  disposition: open
  rationale: bpmn:documentation on the group is standard BPMN; to check against the kept-XML path (T-1326)
- **IW-5: What XML does a made phase write, and does AEF accept it in the maps it stores (T-1461 F6)?**
  confidence: 0
  disposition: open
  rationale: AEF to be asked with the exact XML before the build slice that writes it
- **IW-6: How do phases share the band above the pool with notes and row labels (T-1499, T-1498)?**
  confidence: 0
  disposition: open
  rationale: Greenfield's observations on 0.47.0, msg ee60b420

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
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Why you:** direction — whether phases become editable on the map (a new kind of thing a person adds, asked by Greenfield's owner) is the operator's call, as T-1461 was
  **Steps:**
  1. Run: `fw task review T-1491` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The persona walkthrough yields a bounded set of actions (IW-1) that splits into build slices of about one session
  each, every slice testable by a browser leg and screenshots
- What a made phase writes is standard BPMN that 0.47.0's reader (T-1473) and other tools read back unchanged (IW-4,
  IW-5), and maps without phases save byte-identically
- Boundaries, visibility and documentation each have one clear answer (IW-2, IW-3, IW-4)

**NO-GO if:**
- Editing phases would need the designer to move or reorder steps (phases must follow the steps, T-1461 F4)
- What a made phase writes cannot be read back the same by the drawing slice, or AEF refuses it in stored maps

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

**Recommendation:** EXPLORING

**Rationale:**

Greenfield msg 6ae1899a (2026-11-23): their owner's vote for editing phases from the left menu. T-1461 deferred editing as a separate decision; slice 1 (T-1473) draws phases read-only. Explored after T-1473 ships.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-23T12:55:36Z — status-update [task-update-agent]
- **Change:** horizon: now → later

### 2026-11-24T09:38:36Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-11-24T09:38:55Z — status-update [task-update-agent]
- **Change:** horizon: now → now
