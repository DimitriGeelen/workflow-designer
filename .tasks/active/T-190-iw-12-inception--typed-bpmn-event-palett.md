---
id: T-190
name: "IW-12: inception — typed BPMN event palette (error/timer/message + boundary events)"
description: >
  AEF IW-12 design finding (T-2523). 0.2.0 palette has only plain start/end; issues->boundary-error, horizon/cron->timer, dispatch/pickup->message are undiagrammable. Inception-scale (new node subtypes + aef serialization + bridge parity + mapping rows + DI). Operator prioritization (arc-scale).

status: captured
workflow_type: inception
owner: human
horizon: later
tags: []
components: []
related_tasks: []
created: 2026-07-11T16:56:46Z
last_update: 2026-07-11T16:56:46Z
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

# T-190: IW-12: inception — typed BPMN event palette (error/timer/message + boundary events)

## Problem Statement

AEF design finding IW-12 (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offset 20): the 0.2.0
event palette has only plain start/end. AEF first-class concepts map onto BPMN *typed* events
but can't be expressed: `status:issues` → error / boundary-error event; `horizon` + cron
scheduling → timer event; `dispatch`/`pickup`/bus hand-offs → message event. Without typed
events, AEF error paths, scheduled triggers, and cross-agent hand-offs flatten into plain
tasks — losing exactly the semantics the mapping contract exists to preserve. 832-side read
(offset 24): AGREED, real gap, 832 (SoT) build call; but inception-scale, not a quick build —
new node subtypes + aef: serialization + bridge parity (`yaml-to-bpmn.py`) + a mapping-standard
row per typed event + DI rendering. Initial set: error, timer, message, incl. boundary-on-
task/subProcess. The T-187/T-188 round-trip guards will cover the new serialization the moment
it lands.

**AEF operator RATIFIED this framing** (offset 25, 2026-07-11). Related ratified ruling that
constrains the inception representation: **G-3 — the go/no-go gateway is CONSTITUTIVE, not
decorative**; the permitted lightweight inception form is a COLLAPSED subProcess with the
gateway implied at the boundary (NOT a gateway-less task-node). That collapsed-subProcess
carrier already exists 832-side as T-081 (`aef:scopeOf` marker), so the typed-event work should
target it so editor + forward-compiler agree. **Prioritization is Dimitri's call** (arc-scale);
agent must NOT start the inception without operator GO.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->
