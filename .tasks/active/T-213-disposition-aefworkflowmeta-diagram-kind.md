---
id: T-213
name: "Disposition: aef:workflowMeta diagram-kind marker (documentation|work-plan) — AEF T-2556"
description: >
  Scope + operator sign-off on whether to ratify AEF's additive-vocabulary proposal (rail offset 87, AEF T-2556): a diagram-kind marker in the 832-owned schema, e.g. aef:workflowMeta kind=documentation|work-plan. Motivation: a documentation diagram compiles to promotable work-plan skeletons with zero intent signal. Additive/frozen-v1 (absent marker = byte-identical). Disposition (ratify + attribute name/values, or decline) is an operator design call; if ratified, produce the byte-exact fixture per the AEF fixture loop and AEF wires compile-notice + promote-refusal on kind=documentation.

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-19T20:47:03Z
last_update: 2026-07-21T19:21:23Z
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

# T-213: Disposition: aef:workflowMeta diagram-kind marker (documentation|work-plan) — AEF T-2556

## Problem Statement

Corpus diagrams D1–D5 are **documentation** — framework processes drawn for humans. Nothing in the serialized BPMN distinguishes them from an actionable work-plan, so AEF-side `fw bpmn promote` mints real `owner:human` tasks from illustrative nodes. This is a **live defect**, not hypothetical: AEF's L-504 / T-2548–T-2549 records a joint fixture that promoted inception-marked documentation nodes straight into the task gate. AEF (rail offsets 87 → 125) proposes a 832-owned schema marker to carry author intent; disposition is ours (the vocabulary is 832-owned). Now, because the seam loop is closed and this is the next-largest open AEF-arc coordination item.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

- **IW-1: Should 832 ratify AEF's additive `aef:workflowMeta kind=` marker (T-2556) to carry documentation-vs-work-plan author intent?**
  confidence: 3
  disposition: answered
  rationale: Additive + frozen-v1 safe (absent/unknown kind → byte-identical both sides), closes a live defect (AEF L-504 / T-2548-9: documentation nodes promoted into the task gate). Agent recommends GO/ratify; operator holds the sovereign call. See `docs/reports/T-213-diagram-kind-marker-disposition.md`.

- **IW-2: Values — closed enum `{documentation, work-plan}` or open string?**
  confidence: 3
  disposition: answered
  rationale: Recommend closed enum — frozen-v1 discipline; an open vocabulary invites drift, and a third value (e.g. `template`) can be added later additively without moving a pin.

- **IW-3: 832-side default for new diagrams — UNSET vs `work-plan`?**
  confidence: 3
  disposition: answered
  rationale: Default UNSET so the marker stays an explicit author decision (no silent reclassification). Matches AEF's own recommendation (offset 125).

<!-- T-2190: every IW-N question must be disposed before --status work-completed.
     Never bare yes/no. Bypass: --skip-disposition-gate "rationale" / FW_SKIP_DISPOSITION_GATE=1. -->

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

**Recommendation:** GO — ratify as-is (agent read; ratification is the operator's sovereign call)

**Rationale:**

AEF's proposal (rail offset 125, their T-2556) is low-risk and well-shaped, and it closes a real live defect. The design meets every GO criterion — root cause identified (no intent signal in the serialized file), bounded/scoped/testable/reversible:
- **Additive + frozen-v1 safe.** One optional attribute on `aef:workflowMeta`: `kind="documentation" | "work-plan"`. Absent/unknown `kind` → **byte-identical today-behavior on both sides**. No other serialization change, so it cannot break the existing byte-pinned corpus (session-handover / dispatch-loop / offpage-seam) — those stay clean until deliberately re-marked.
- **Solves the defect at the right layer.** Intent lives in the 832-owned schema (where authoring happens), and AEF consumes it: `fw bpmn compile` adds one advisory on `kind=documentation` (skeletons unchanged); `fw bpmn promote` refuses `kind=documentation` (explicit override for the deliberate case). Regression tests pin both paths.
- **Author-decision default is correct.** New diagrams default UNSET (not `work-plan`), so the marker stays an explicit author choice — no silent reclassification, no bulk rewrite. The 5 corpus diagrams get re-marked `kind=documentation` via normal editor saves after ratification.

**Amendment options for the operator to weigh** (all viable; my default is ratify-as-is):
- Attribute name: `kind=` is concise and namespaced under `aef:workflowMeta`; no collision with existing attrs. Fine as-is.
- Values: enum `documentation | work-plan` vs open string. **Recommend closed enum** (frozen-v1: an open vocabulary invites drift; a third value can be added later additively without moving a pin).
- Could add a neutral third value later (e.g. `template`) — defer; not needed for the defect.

**Evidence:**

- Rail offset 125 (AEF T-2556 full proposal) + offset 87 (original) — `[[aef-integration-rail]]`.
- Live defect: AEF L-504 / T-2548–T-2549 (documentation nodes promoted into the task gate via a joint fixture).
- 832 owns the dialect; this mirrors the seam loop exactly — operator ratifies → 832 produces the byte-exact fixture (validate-clean → byte-pin → rail-inline) → AEF wires compile-notice + promote-refusal. Same producer-contract discipline as T-219.
- On ratify: spin a 832 build task for (a) `kind=` surfaced in the meta-edit UI (default UNSET) + (b) the byte-exact `kind=documentation` fixture; then re-mark the 5 corpus diagrams via normal saves. AEF builds their T-2556 legs only after our ratification.

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

### 2026-07-21T19:21:23Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
