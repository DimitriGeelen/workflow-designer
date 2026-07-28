---
id: T-277
name: "Ratify process-level conformance key and stateKind carrier convention (AEF T-2652)"
description: >
  Inception: Ratify process-level conformance key and stateKind carrier convention (AEF T-2652)

status: captured
workflow_type: inception
owner: human
horizon: later
tags: []
components: []
related_tasks: []
created: 2026-07-28T10:03:10Z
last_update: 2026-07-28T10:05:00Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-277: Ratify process-level conformance key and stateKind carrier convention (AEF T-2652)

## Problem Statement

AEF's T-2652 inception (rail 268) generalizes their map-conformance rail beyond aef-task-lifecycle.
Two of its questions touch the 832 schema surface and would need 832 ratification (T-213 kind=
precedent) if their design lands on in-map declaration:

- **conformance= on aef:workflowMeta** (map self-describes its conforms-against source): NOT
  round-trip-safe today — import reads a fixed 8-key allowlist (src:9263) and export re-synthesizes
  from known keys (src:9111); an unratified attr silently drops on the first editor save.
- **stateKind= on node aef:meta** (disambiguate state= across task-status / decision-outcome /
  budget-ladder carriers): import ingests all attrs verbatim (src:9341) but export re-emits from a
  17-key allowlist (src:8979) — state= itself round-trips, a new stateKind= would drop.

Advisory answer with these facts + leans posted at rail 270. PARKED (DEFER, horizon later):
AEF's current lean is registry-operative, which needs zero 832 change. **Promote this task only
when AEF pings the T-2652 thread with a GO for in-map declaration** — then the operator decides
ratification of both additive keys (pattern: kind= T-213, uuid T-224, pageWidth T-255 — one key
into both allowlists, absent = not emitted, untouched maps export byte-identically).

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

**Recommendation:** DEFER

**Rationale:**

AEF T-2652 (rail 268) is design-stage: their lean is registry-operative (zero 832 schema change). Ratification only becomes live if their inception lands on in-map declaration. Technical facts already answered on-rail: aef:workflowMeta unknown attrs drop on editor save (8-key allowlist src:9263 / re-synthesis src:9111); node aef:meta state= round-trips but new attrs drop (17-key allowlist src:8979). Lean if promoted: additive conformance= on workflowMeta (kind=/pageWidth pattern) + additive stateKind= in metaKeys, absent = task-status.

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

### 2026-07-28T10:03:29Z — status-update [task-update-agent]
- **Change:** horizon: now → later

### 2026-07-28T10:45:00Z — rail confirmation [agent]
- AEF T-2652 went GO **registry-operative** (rail 272; their T-2654 shipped: tools/conformance-registry.yaml + primitive dispatch, transition-table leg migrated behavior-preserving). AEF explicitly: "keep T-277 PARKED — current direction needs zero 832-side work." They will ping the T-2652 thread if/when slice 5 (in-map conformance= mirror + stateKind= ratification) becomes worth taking to the operator, likely after vocabulary-set rails (slices 2-3) prove the multi-kind carrier need. Promote condition unchanged.
