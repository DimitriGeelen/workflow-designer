---
id: T-1322
name: "Generic per-element passthrough: a save keeps the BPMN content the designer
  does not model"
description: >
  Inception: Generic per-element passthrough: a save keeps the BPMN content the designer
  does not model

status: work-completed
workflow_type: inception
current_node: frw_end_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-10-28T08:24:02Z
last_update: 2026-10-28T09:26:16Z
date_finished: 2026-10-28T09:26:16Z
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
  - ts: '2026-10-28T08:25:28Z'
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

# T-1322: Generic per-element passthrough: a save keeps the BPMN content the designer does not model

## Problem Statement

Someone opens a BPMN file made in another tool (Camunda Modeler, bpmn.io, Zeebe) in the designer and saves it. One
save silently drops content the designer does not model: vendor attributes and extensions (F1), standard semantics
such as a gateway's `default` flow, script bodies and multi-instance (F2), annotations and process documentation (F5),
imported DI geometry (F6), subprocess nesting (F8), nested lanes (F9), comments (F11), and more (ring20 cloud job C,
`docs/reports/T-2466-cloud-job-C-bughunt.md`, F1-F13). The result still validates, and no notice is shown. Two findings
were narrow enough to fix alone (T-1265 condition language, T-1268 unknown aef node elements). The other 11 share one
cause: import reads NAMED content, and export writes only from state. So every new allowlist entry fixes one element.
The question for the operator: what should a save do with content the designer does not model?
Research artifact: `docs/reports/T-1322-third-party-passthrough.md`.

## Hypothesis

We believe that a generic per-element passthrough (each element keeps the attributes and children the designer does not
read, written back in place; elements it cannot place are kept at process level),
we will achieve saves that change only what the person edited in a third-party file.
We will know that we are successful when we see the T-2466 job C files a-f re-saved unedited differ from their source
only in the DI and aef additions (tools/_t423-additive-export-guard.py's rule), and F1, F2, F5, F10 and F11 each close
with a red-on-old harness.

## Assumptions

- A-1: The dropped classes occur in real modeler files often enough to matter (to measure: the third-party fixtures in
  the repo and the T-2466 job C inputs).
- A-2: Keeping unread content per element is cheaper than one allowlist entry per element, and stays correct when the
  person edits that element (rename, retype, move lane, delete).
- A-3: Some classes cannot be kept in place without modelling them (F6 DI geometry, F8 subprocess nesting, F9 nested
  lanes), and need either a model or a warning.

## Open Questions

- **IW-1: Which of F1-F13 are fixable by an unread-content passthrough, and which need modelling or a warning?**
  confidence: 2
  disposition: answered
  rationale: report §3 — keepable unread: F1, F2, F5, F7 rest, F11 (5 of 11); need a model: F6, F8, F9; decisions of their own: F3, F4; out of scope F12, F13. The one blocker for A is references by id (closed BPMN IDREF set, rewritten through the export's id map).
- **IW-2: How often does each class occur in the third-party files we hold?**
  confidence: 3
  disposition: answered
  rationale: report §2, measured in the real editor (T-1322-evidence/classify-losses.out): 7 of 11 third-party fixtures lose non-DI content on one unedited save; foreign elements 300, BPMN attributes 39, BPMN children 35, foreign attributes 8, comments 1. The job C inputs are not in the repo (cloud session), so not measured.
- **IW-3: What does a kept element do when the person changes its element (retype task to gateway, delete, change lane)?**
  confidence: 2
  disposition: answered
  rationale: report §4 A — rides its element on rename and lane move; a retype that changes the BPMN tag drops the attributes the new tag does not allow, with a notice; delete removes it; a kept process-level element whose reference dangles is dropped, with a notice. Desk answer, to be proven by slice 1's harness.

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

## Exploration Plan

1. Classify F1-F13 as: fixed, keepable unread (passthrough), needs a model, or warn-only (desk work, 30 min).
2. Measure how often each class occurs in the third-party BPMN files the repo holds, with a read-only scan script
   (30 min).
3. Write the three options with cost, risk and what each does on edit, and a recommendation (30 min).
No designer code is written in this inception.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: what a save does with third-party content the designer does not model; the 11 open job C findings.
OUT: maps the designer or the YAML bridge wrote (they round-trip today, guarded by the corpus legs); making the designer
EDIT vendor content (Camunda forms etc.); T-1270 (library id collision) and T-1271 (node order), which are behaviour
choices of their own.

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
  **Why you:** direction — whether the designer becomes lossless for files from other tools (and spends three build slices on it) is product direction; and `fw inception decide` is operator-only
  **Steps:**
  1. Run: `fw task review T-1322` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- At least 4 of the 11 open findings are keepable unread by one mechanism, and the measured third-party files carry them
- The mechanism has a defined behaviour on every edit of its element (IW-3), and maps the designer wrote are byte-unchanged

**NO-GO if:**
- Most open findings need a model of their own (passthrough would fix little), or the files we hold rarely carry them
- Kept content goes stale or invalid on common edits, so a passthrough would write wrong BPMN instead of less BPMN

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

**Recommendation:** GO (option A, generic per-element passthrough, with option C's open notice for what A cannot keep)

**Rationale:**

Measured in the real editor, 7 of the 11 third-party fixtures lose non-DI content on one unedited save: 383 items. Most
are vendor extensions (300, from Bizagi, CaseAgile and Zeebe), then standard BPMN semantics (a gateway's default flow,
isInterrupting, loop characteristics, annotations). Each of the last six fixes added one name to what is read, and the
vendor share alone is three vocabularies that a name-by-name fix (B) would never finish. One mechanism, already in the
code for io children and unknown aef node elements (`keptElementXml`, T-1243/T-1268), fixes 5 of the 11 open findings
(F1, F2, F5, F7 rest, F11). Its one real cost is references by id, which the export's existing id map can rewrite.
What it cannot keep (F6 geometry, F8 subprocess nesting, F9 nested lanes) needs models of its own. Until each has one,
an open notice (C) says what a save will drop, so nothing is lost silently. Maps the designer or the bridge wrote carry
nothing unread, so they do not change.

**Evidence:**

- `docs/reports/T-1322-third-party-passthrough.md` §2 (table per file), §3 (finding by fix), §4 (options), §5 (slices)
- `docs/reports/T-1322-evidence/classify-losses.out`: census over 16 files, designer at 1547b7681
- T-1268 scan: 0 unknown aef node elements in any repo .bpmn (no designer-written map moves)
- Side finding: `tools/_t356-third-party-fidelity-cdp.mjs`'s positive control reads HARNESS BROKEN (filed T-1323)

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

**Rationale**: Operator (job 099): GO on option A, a generic per-element passthrough for the BPMN content the designer does not model, with option C's open notice for what A cannot keep (F6 geometry, F8 subprocess nesting, F9 nested lanes). Evidence: docs/reports/T-1322-third-party-passthrough.md, 7 of 11 third-party fixtures lose 383 non-DI items on one unedited save. Build in three slices (per-element; process-level with reference rewrite; comments + notice); F3/F4 ids and F6/F8/F9 models are separate decisions.

**Date**: 2026-10-28T09:26:15Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-28T08:25:27Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-28T09:26:15Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator (job 099): GO on option A, a generic per-element passthrough for the BPMN content the designer does not model, with option C's open notice for what A cannot keep (F6 geometry, F8 subprocess nesting, F9 nested lanes). Evidence: docs/reports/T-1322-third-party-passthrough.md, 7 of 11 third-party fixtures lose 383 non-DI items on one unedited save. Build in three slices (per-element; process-level with reference rewrite; comments + notice); F3/F4 ids and F6/F8/F9 models are separate decisions.

### 2026-10-28T09:26:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO

## Reviewer Verdict (v1.5)

- **Scan ID:** R-48cfc253
- **Timestamp:** 2026-10-28T09:26:17Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-f37d503f
- **Timestamp:** 2026-10-28T09:26:17Z
- **Overall:** CONFIRMED
- **Claims:** 6

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-1322-third-party-passthrough.md` | file | ✓ pass |
| `docs/reports/T-1322-evidence/classify-losses.out` | file | ✓ pass |
| `tools/_t356-third-party-fidelity-cdp.mjs` | file | ✓ pass |
| `T-1243` | task | ✓ pass |
| `T-1268` | task | ✓ pass |
| `T-1323` | task | ✓ pass |
