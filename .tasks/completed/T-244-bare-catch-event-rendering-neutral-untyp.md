---
id: T-244
name: "Bare catch-event rendering: neutral untyped glyph instead of dead link-catch
  UI"
description: >
  AEF rail 174 (their T-2613, operator-reported): a bare intermediateCatchEvent (no
  aef:link, no aef:eventDef) renders the link-catch UI with an empty target that can
  never bind — operator read it as a broken connector. Open question: should a bare
  catch render the link-catch UI with an empty disabled target, or a neutral untyped
  glyph? Low priority — AEF corpus no longer exercises the case (they typed all bare
  catches). One question, one go/no-go.

status: work-completed
workflow_type: inception
owner: agent
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-23T09:15:35Z
last_update: '2026-08-16T14:33:22Z'
date_finished: 2026-07-29T17:46:29Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:45Z'
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
  - ts: '2026-08-16T14:33:22Z'
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
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-244: Bare catch-event rendering: neutral untyped glyph instead of dead link-catch UI

## Problem Statement
A bare `intermediateCatchEvent` — no `aef:link`, no `aef:eventDef` — decodes to `linkEventCatch` and
renders the "← Handoff" UI with target fields that can never bind, because the source document has
no link to bind to. AEF's operator read exactly this as a broken connector on a healthy map (their
T-2613, rail 174). The reader is anyone opening a hand-authored map, a peer fixture, or a
partially-typed import. Now, because the analysis is cheap and the misread has already happened once.


## Assumptions
- The defect is presentational only — no data loss, no round-trip corruption. **Validated** (export
  emits `<aef:link>` only when a binding field is non-empty; round-trip byte-clean).
- Correcting it requires a new node type and therefore AEF dialect ratification. **Broken** — a
  rendering branch suffices.
- "Unbound" uniquely identifies a bare imported catch event. **Broken** — palette-created handoff
  nodes are equally unbound, and the distinction dies at save.
- Neither corpus currently contains a bare catch event. **Validated at filing** (AEF typed theirs
  upstream); re-check before any build.


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

- **IW-1: Should a bare `intermediateCatchEvent` (no `aef:link`, no `aef:eventDef`) render as the link-catch "← Handoff" UI, or as a neutral untyped glyph?**
  confidence: 3
  disposition: answered
  rationale: Neutral glyph, conditioned on session state (see IW-3). src:9347 fallback; consequences at src:7783/5662/1784

- **IW-2: Does correcting it require a new node type (a dialect change AEF must ratify), or only a rendering/property-panel branch with no schema surface?**
  confidence: 3
  disposition: answered
  rationale: Rendering branch suffices — no schema surface; aefExtensionXml conditional link guard + src:8985 prove round-trip safety

- **IW-3: Can "author placed a handoff and has not bound it yet" be distinguished from "bare imported catch event", and does that distinction survive a save/reload round trip?**
  confidence: 3
  disposition: answered
  rationale: Distinguishable in session, NOT across a save — dialect has no carrier for handoff intent (no empty aef:link emitted)

## Exploration Plan
Desk spike against the editor source, time-boxed to one session — no prototype needed because the
question is "what does the code do and what would changing it cost", not "does this work":
1. Locate the decode path that turns a bare `intermediateCatchEvent` into `linkEventCatch`. **Done** — src:9347.
2. Enumerate the presentational consequences (glyph, label, property schema). **Done** — src:5662, 7783, 1784.
3. Determine whether export re-injects anything, i.e. whether the defect can corrupt a document.
   **Done** — `aefExtensionXml` conditional guard; round-trip byte-clean.
4. Price both fix shapes (new node type vs rendering branch). **Done** — see research artifact.


## Technical Constraints
- Single-file editor (`src/aef-workflow-designer.html`); no build step, so the change is a direct
  source edit plus the corpus/bridge suites.
- The BPMN dialect is a **shared cross-project contract** — any change that alters exported bytes
  requires AEF ratification (precedent: `kind=` T-213, `uuid` T-224, `pageWidth` T-255). This is the
  constraint that makes path (b) preferable: it touches no exported byte.
- The dialect has **no carrier for authorial intent** on an unbound event, and adding one would
  itself be a ratifiable change — so any resolution must live in session state, not document state.
- Standing commitment to notify the AEF rail if catch-event rendering changes (rail 174/176).


## Scope Fence
**IN:** how a bare `intermediateCatchEvent` presents in the editor — glyph, label, and which
property fields are offered; the decode fallback at src:9347; the session-vs-document boundary for
handoff intent.

**OUT:** adding a node type to the dialect; any change to exported bytes; typed-event vocabulary
(`aef:eventDef` kinds — that is T-204's surface, already shipped); throw-side events; boundary
events; AEF's corpus (they fixed their instance upstream and own that side).


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

**Recommendation:** GO — scoped to a rendering branch (path b), explicitly NOT a new node type.

**Rationale:** The filing stub deferred against an unmeasured cost. Exploration priced it: root cause is a single fallback line (REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch', src:9347), the consequences are purely presentational (label src:7783, glyph src:5662, dead link property schema src:1784), and round-trip is byte-clean today because aefExtensionXml emits <aef:link> only when a binding field is non-empty. So the fix needs no schema change, no export change and no AEF ratification — an order of magnitude cheaper than the new-node-type shape the stub implicitly priced. Exploration also surfaced a wrinkle the stub could not see: palette-created handoff nodes are equally unbound, and the distinction does not survive a save because the dialect carries no authorial intent — resolved by holding intent in session state (handoff UI while live, neutral after reload), since a persisted marker would itself be a dialect change.

**Evidence:**
- src/aef-workflow-designer.html:9347 — fallback decode, the root cause
- src/aef-workflow-designer.html:5662, 7783, 1784 — glyph, label, dead property schema
- aefExtensionXml conditional `<aef:link>` guard + src:8985 export mapping — round-trip byte-clean, verified
- docs/reports/T-244-bare-catch-event-exploration.md — full exploration, IW-1/2/3 dispositions

**If GO:** implementation goes to a separate build task (Inception Discipline step 5) — rendering branch + regression test importing a bare catch event + courtesy note on the AEF rail.
**If DEFER:** revisit trigger is a bare intermediateCatchEvent appearing in any authored or imported map; the priced analysis is preserved.

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

**Rationale**: The filing stub deferred against an unmeasured cost. Exploration priced it: root cause is a single fallback line (REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch', src:9347), the consequences are purely presentational (label src:7783, glyph src:5662, dead link property schema src:1784), and round-trip is byte-clean today because aefExtensionXml emits <aef:link> only when a binding field is non-empty. So the fix needs no schema change, no export change and no AEF ratification — an order of magnitude cheaper than the new-node-type shape the stub implicitly priced. Exploration also surfaced a wrinkle the stub could not see: palette-created handoff nodes are equally unbound, and the distinction does not survive a save because the dialect carries no authorial intent — resolved by holding intent in session state (handoff UI while live, neutral after reload), since a persisted marker would itself be a dialect change.

**Date**: 2026-07-29T17:46:29Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2681b6e7
- **Timestamp:** 2026-07-29T17:46:30Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
## Recommendation Verdict (v1.0)

- **Scan ID:** RC-d38ac272
- **Timestamp:** 2026-07-29T17:46:30Z
- **Overall:** UNVERIFIED
- **Claims:** 0
- No verifiable claims found in ## Recommendation
### 2026-07-29T16:33:28Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-29T17:46:29Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** The filing stub deferred against an unmeasured cost. Exploration priced it: root cause is a single fallback line (REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch', src:9347), the consequences are purely presentational (label src:7783, glyph src:5662, dead link property schema src:1784), and round-trip is byte-clean today because aefExtensionXml emits <aef:link> only when a binding field is non-empty. So the fix needs no schema change, no export change and no AEF ratification — an order of magnitude cheaper than the new-node-type shape the stub implicitly priced. Exploration also surfaced a wrinkle the stub could not see: palette-created handoff nodes are equally unbound, and the distinction does not survive a save because the dialect carries no authorial intent — resolved by holding intent in session state (handoff UI while live, neutral after reload), since a persisted marker would itself be a dialect change.

### 2026-07-29T17:46:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
