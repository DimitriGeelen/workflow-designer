---
id: T-681
name: "EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all"
description: >
  Inception: EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all

status: captured
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
created: 2026-09-05T14:17:12Z
last_update: 2026-09-05T14:17:12Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
                                  # ⚠ CHANGE THIS TOO (T-625). Measured 2026-08-29: 38 of 41 inceptions still carried this
                                  # exact 3, the same 38 that carried voi_score: 0.5. Between them the two fields fix the
                                  # task's ENTIRE BVP position — value and cost — so leaving both planted means the
                                  # ranking is the template's opinion, not anyone's. The 3 is a placeholder, not a guide.
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
                                  # ⚠ CHANGE THIS (T-624). For an inception voi_score IS the entire BVP composite: the
                                  # estimator skips per-driver scoring and derives all nine drivers from this one number
                                  # (estimator.py _score_inception_voi). Leaving 0.5 does not score the task, it abstains —
                                  # and an abstention is printed as a confident BVP 126 that no reader can tell from a real
                                  # score. Measured 2026-08-29: 38 of 41 inceptions still carried this exact default, so the
                                  # entire hv-lc quadrant ranked as one flat tie. `python3 tools/_t624-voi-provenance.py`
                                  # reports which tasks were ever deliberately scored. The 0.5 below is a placeholder that
                                  # exists only to satisfy the schema gate (PL-167) — it is not a recommendation.
---

# T-681: EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-681 -->

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
  1. Run: `fw task review T-681` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Recommendation:** GO

**Rationale:**

GO, scoped to Arc 2's Designer-owned half ONLY: prove the browser/editor cannot reach execution, secret, or ledger authority. Of the six undecomposed arcs, five have a Designer column depending on an AEF artefact that does not exist yet (Arc 1 registry/ledger, Arc 3 action catalogue, Arc 5 prompt/context envelope, Arc 6 router; Arc 4 needs the projection API, and its one independent slice - diagram-to-Fabric navigation - already shipped as T-611). Arc 2's Designer column is the exception: it is a falsifiable claim about OUR OWN code, provable today with nothing from the counterparty. It is also the only one whose value survives an Arc-0 that never exits, because an isolation proof is evidence the operator can act on regardless of whether AEF attests. Recommending AGAINST opening Arcs 1/3/5/6 now: decomposing work whose inputs are counterparty-blocked manufactures a backlog that measures as progress and cannot move.

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

<!-- Filled at completion via: fw inception decide T-681 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->
