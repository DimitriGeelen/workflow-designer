---
id: T-263
name: "Save-to-project target binding: workflowMeta id wins over dialog project-id
  input (AEF observation, rail 225)"
description: >
  AEF rail 225 observation during 0.7.0 eventDef verify: they loaded a scratch COPY
  of a map whose workflowMeta id still named the original; Save-to-project bound the
  write target from workflowMeta id and wrote onto the ORIGINAL project. Editing the
  dialog's project-id input (synthetically) did not rebind — may be synthetic-event
  artifact (real keystroke might work) or may be workflowMeta-id-wins by design. One
  question: which field is authoritative for the save target, and does the dialog
  input actually rebind on real input? Go/no-go on a fix.

status: work-completed
workflow_type: inception
owner: agent
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-27T20:22:54Z
last_update: '2026-08-16T12:33:46Z'
date_finished: 2026-07-27T20:45:33Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-263: Save-to-project target binding: workflowMeta id wins over dialog project-id input (AEF observation, rail 225)

## Problem Statement

AEF (rail 225/228, their T-2632): saving a scratch copy carrying the original's
workflowMeta id overwrote the original project's workflow; editing "the dialog's
project-id input" did not rebind. Exploration = code read + CDP probe
(tools/_t263-save-target-cdp.mjs); findings + GO recommendation in
docs/reports/T-263-save-target-binding.md. Ruling owed to AEF on the rail.

## Recommendation

**Recommendation:** GO

**Rationale:** The peer's overwrite incident is real and fully explained:
workflowMeta-id-wins IS the design (the meta id is the document identity per the
T-224 slug/uuid model, and no save dialog carries a target input), but the one field
that redirects the save target fails silently in three ways, and saveToProject never
warns when the target differs from where the document was loaded. A small,
zero-seam-surface UX-guard build task converts the silent overwrite into an informed
choice without introducing a second identity authority.

**Evidence:**
- saveToProject POSTs `id = state.workflowMeta.id` unconditionally (src :7930/:7954); the save modal is note-only — confirmed end-to-end vs a stubbed /api/save (probe leg4, postedId === metaIdAtSave).
- The props ID field rebinds state for BOTH synthetic (value+input event) and real (CDP insertText) edits — probe legs 1+2; the peer's H1 (synthetic-events artifact) and H2 (dead UI) are both refuted as stated.
- Collision with an existing library key → silent no-op: 0 alerts, 0 toasts, field reverts on re-render (probe leg3; renameActiveWorkflow :2588 returns false, caller :5043 just re-renders).
- Successful rename re-renders the props panel and destroys the focused input mid-typing (probe leg2, sameElementFocused=false; field() commits on every input event :5645).
- Probe harness: tools/_t263-save-target-cdp.mjs (5 legs, isolated chromium vs served editor); full findings: docs/reports/T-263-save-target-binding.md.

**Fix shape on GO (one build task):** (1) visible collision feedback at the ID field;
(2) ID-field commit-on-blur/Enter instead of per-keystroke; (3) saveToProject confirm
when the load source names a different map than workflowMeta.id.

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

- **IW-1: What does the Save-to-project code path actually bind as the write target — the dialog's project-id input, the document's workflowMeta id, or some precedence between them?**
  confidence: 3
  disposition: answered
  rationale: "saveToProject POSTs id = state.workflowMeta.id unconditionally (src :7930/:7954); NO save dialog carries a target input (promptSaveNote is note-only); the props-panel ID field (:5040) is the only target-changing UI. Probe leg4 confirmed at runtime (stubbed /api/save)."

- **IW-2: Does editing the dialog's project-id field with REAL keystrokes rebind the save target (H1: peer's synthetic value+input/change events just didn't reach editor state), or is the field dead UI at save time (H2)?**
  confidence: 3
  disposition: answered
  rationale: "BOTH work: probe leg1 (synthetic value+input event) AND leg2 (CDP Input.insertText, trusted) rebound state.workflowMeta.id. H1-as-stated and H2 both refuted — but two SILENT failure modes present as 'didn't rebind': collision → silent revert (leg3: 0 alerts/toasts), and successful rename → panel re-render dumps focus mid-typing (leg2: sameElementFocused=false). tools/_t263-save-target-cdp.mjs."

- **IW-3: If workflowMeta-id-wins is the current behavior, is it defensible as design (meta is the document identity) or is it a footgun (scratch copies silently overwrite originals — the peer's exact incident)? What is the minimal fix shape if not?**
  confidence: 2
  disposition: answered
  rationale: "Design is defensible (meta id IS document identity, T-224 model) but under-guarded: fix shape = collision feedback + ID-field commit-on-blur/Enter + save-target-vs-load-source mismatch confirm. GO recommendation in docs/reports/T-263-save-target-binding.md."

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

1. **Code read (30 min):** locate the save-to-project dialog + submit handler in
   src/aef-workflow-designer.html; trace where the target project id / workflow id
   comes from at POST time. Answers IW-1 statically.
2. **CDP probe (45 min):** load a copy-with-original-meta-id document, open the save
   dialog, edit the project-id field via real key events (Input.dispatchKeyEvent /
   insertText — NOT synthetic value+events), submit against a sidecar capture server,
   and observe which target the POST names. Answers IW-2, reproduces or refutes the
   peer incident end-to-end.
3. **Ruling draft:** IW-3 from 1+2; recommendation GO (fix task) / NO-GO (document as
   design + protocol-doc note); post ruling on the rail either way.

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

<!-- REQUIRED before fw inception decide. Write your recommendation here (T-974).
     Watchtower reads this section — if it's empty, the human sees nothing.
     Format:
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence from exploration)
     **Evidence:**
     - Finding 1
     - Finding 2
-->

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

**Rationale**: Recommendation: GO

Rationale: The peer's overwrite incident is real and fully explained:
workflowMeta-id-wins IS the design (the meta id is the document identity per the
T-224 slug/uuid model, and no save dialog carries a target input), but the one field
that redirects the save target fails silently in three ways, and saveToProject never
warns when the target differs from where the document was loaded. A small,
zero-seam-surface UX-guard build task converts the silent overwrite into an informed
choice without introducing a second identity authority.

Evidence:
- saveToProject POSTs `id = state.workflowMeta.id` unconditionally (src :7930/:7954); the save modal is note-only — confirmed end-to-end vs a stubbed /api/save (probe leg4, postedId === metaIdAtSave).
- The props ID field rebinds state for BOTH synthetic (value+input event) and real (CDP insertText) edits — probe legs 1+2; the peer's H1 (synthetic-events artifact) and H2 (dead UI) are both refuted as stated.
- Collision with an existing library key → silent no-op: 0 alerts, 0 toasts, field reverts on re-render (probe leg3; renameActiveWorkflow :2588 returns false, caller :5043 just re-renders).
- Successful rename re-renders the props panel and destroys the focused input mid-typing (probe leg2, sameElementFocused=false; field() commits on every input event :5645).
- Probe harness: tools/_t263-save-target-cdp.mjs (5 legs, isolated chromium vs served editor); full findings: docs/reports/T-263-save-target-binding.md.

Fix shape on GO (one build task): (1) visible collision feedback at the ID field;
(2) ID-field commit-on-blur/Enter instead of per-keystroke; (3) saveToProject confirm
when the load source names a different map than workflowMeta.id.

**Date**: 2026-07-27T20:45:33Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-27T20:30:27Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-27T20:45:33Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale: The peer's overwrite incident is real and fully explained:
workflowMeta-id-wins IS the design (the meta id is the document identity per the
T-224 slug/uuid model, and no save dialog carries a target input), but the one field
that redirects the save target fails silently in three ways, and saveToProject never
warns when the target differs from where the document was loaded. A small,
zero-seam-surface UX-guard build task converts the silent overwrite into an informed
choice without introducing a second identity authority.

Evidence:
- saveToProject POSTs `id = state.workflowMeta.id` unconditionally (src :7930/:7954); the save modal is note-only — confirmed end-to-end vs a stubbed /api/save (probe leg4, postedId === metaIdAtSave).
- The props ID field rebinds state for BOTH synthetic (value+input event) and real (CDP insertText) edits — probe legs 1+2; the peer's H1 (synthetic-events artifact) and H2 (dead UI) are both refuted as stated.
- Collision with an existing library key → silent no-op: 0 alerts, 0 toasts, field reverts on re-render (probe leg3; renameActiveWorkflow :2588 returns false, caller :5043 just re-renders).
- Successful rename re-renders the props panel and destroys the focused input mid-typing (probe leg2, sameElementFocused=false; field() commits on every input event :5645).
- Probe harness: tools/_t263-save-target-cdp.mjs (5 legs, isolated chromium vs served editor); full findings: docs/reports/T-263-save-target-binding.md.

Fix shape on GO (one build task): (1) visible collision feedback at the ID field;
(2) ID-field commit-on-blur/Enter instead of per-keystroke; (3) saveToProject confirm
when the load source names a different map than workflowMeta.id.

### 2026-07-27T20:45:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
