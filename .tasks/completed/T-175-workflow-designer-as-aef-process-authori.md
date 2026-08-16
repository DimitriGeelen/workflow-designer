---
id: T-175
name: "Workflow Designer as AEF process-authoring surface (framing + decomposition)"
description: >
  Inception: Workflow Designer as AEF process-authoring surface (framing + decomposition)

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: ["arc:designer-authoring-surface"]
components: []
related_tasks: []
created: 2026-07-10T10:42:06Z
last_update: '2026-08-16T13:57:17Z'
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:41Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:17Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-175: Workflow Designer as AEF process-authoring surface (framing + decomposition)

## Problem Statement

Turn the Workflow Designer into AEF's **visual process-authoring surface**: drawing a process *proposes*
governed work (forward), and existing AEF work / code is *rendered back* as an editable process map
(reverse) — over a portable BPMN⇄task-YAML standard, tenant-neutral, for both AEF dogfood and downstream
apps. This framing inception locks the architecture (IW-1..7, resolved with the operator) and decomposes
the program (IW-8) with the AEF agent. Full detail:
`docs/reports/T-175-designer-authoring-surface-inception.md`. Sits above the T-173 phase-1 beachhead.

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

<!-- IW-1..IW-7 resolved in operator dialogue 2026-07-10 (see docs/reports/T-175-*.md
     §Dialogue Log). IW-8 (decomposition) is the framing inception's remaining question,
     to be closed with the AEF agent in the joint design pass. -->

- **IW-1: Direction of authority** — is a drawn diagram generative, a projection, or round-trip?
  confidence: 3
  disposition: answered
  rationale: Round-trip, TASKS CANONICAL. Diagram PROPOSES governed work; never silently authors (sovereignty + "nothing without a task"). Operator dialogue 2026-07-10.
- **IW-2: The vocabulary bridge** — how rigidly do node types map to framework concepts?
  confidence: 3
  disposition: answered
  rationale: Explicit canonical mapping (e.g. userTask→human task, serviceTask→agent build task, gateway→gate/decision, subProcess→arc, lane→owner). The mapping IS the contract + portability standard. Operator dialogue.
- **IW-3: Forward trigger + sovereignty gate** — how does a drawn process become governed work?
  confidence: 3
  disposition: answered
  rationale: AEF agent translates + ENRICHES the diagram into a proposed task/inception graph (ACs, types, ownership, decomposition); human approves the BATCH in ONE sovereignty gate; then tasks are created. Operator dialogue.
- **IW-4: Reverse discovery — first target** — what counts as "a process" in code, and where do we start?
  confidence: 3
  disposition: answered
  rationale: Start with AEF's OWN process record (task graph + fabric + decisions + episodic) — deterministic dogfood. Arbitrary source-code parsing deferred to a later target. Operator dialogue.
- **IW-5: Collaboration channels + concurrency** — how do human and agents co-design without stalling or conflict?
  confidence: 3
  disposition: answered
  rationale: TWO channels — agent↔agent = termlink; human↔framework = BROWSER (designer web app). Async + turn-based. Concurrency via FINE-GRAINED claim/lease (per node/lane/sub-process, TTL auto-release) so both work different regions at once; reuses termlink's claim primitive. Operator correction + dialogue.
- **IW-6: Tenancy sequencing** — dogfood-first or both audiences at once?
  confidence: 3
  disposition: answered
  rationale: BOTH audiences from the start → build TENANT-NEUTRAL from day one (no hardcoded AEF-internal assumptions), validate on AEF as the first tenant. Operator dialogue (operator chose broader option over my dogfood-first lean).
- **IW-7: Portability guardrail (Directive 4)** — standard contract or couple to this designer?
  confidence: 3
  disposition: answered
  rationale: STANDARD BPMN⇄task/inception-YAML contract AS the interface + THIS designer as the blessed REFERENCE implementation. Framework talks to the format, not the tool. Operator dialogue.
- **IW-8: Decomposition** — what child inceptions does this program split into, and in what order?
  confidence: 3
  disposition: deferred
  rationale: PROGRAM (arc: designer-authoring-surface). 5 children scoped to per-child GO/NO-GO in `docs/reports/T-175-child-decomposition.md` (2026-07-11): (1) mapping standard [keystone, GO-ready — strawman converged, T-177 emission shipped, uid verified], (2) forward bridge, (3) reverse discovery, (4) collaboration+concurrency, (5) hosting+tenancy — with ownership split (832 vs AEF) + sequencing. Recommendation: GO 1 now, GO 2 next, DEFER 3–5 (each with a revisit trigger). Disposition stays `deferred` pending the operator's sovereign per-child GO — the framing inception's deliverable is produced; ratification is the operator's downstream action.

## Exploration Plan

The architecture (IW-1..7) is resolved; this inception's remaining work is to close **IW-8
(decomposition)** and validate the three assumptions. Steps:

1. **Keystone strawman (DONE)** — `docs/reports/T-175-mapping-strawman.md`: concrete BPMN⇄AEF mapping
   (forward + reverse) + mismatches + assumptions A-001..A-003. De-risks that child-1 is tractable.
2. **Joint design pass with the AEF agent (IN FLIGHT)** — thread T-175 (DM offset 19). Validate A-002/A-003
   against AEF's actual model (can it *receive* a BPMN-derived graph? is the record structured enough for
   reverse?), confirm/sequence the 5-child decomposition, split per-child ownership (832 vs AEF).
3. **Converge the decomposition** — fold the AEF agent's answers into the artifact; finalise the child list
   + order + ownership.
4. **Operator hand-off** — present the scoped child inceptions for GO/NO-GO. Each child then gets its own
   inception → build tasks. No build under T-175.

Time-box: bounded by the AEF agent's async availability; no code in this inception.

## Technical Constraints

- **Browser hosting (IW-5/IW-6):** the human channel is a served browser app, so the designer must run
  hosted (not just file://). Any device-API-free authoring works over plain HTTP on localhost/LAN; a
  public deployment needs HTTPS. Multi-tenant serving is an AEF-side concern (child-5).
- **Concurrency substrate (IW-5):** the claim/lease reuses termlink's claim primitive — availability of
  that primitive in the hosted context must be confirmed (termlink is agent-side; the browser lease may
  need a server-mediated bridge).
- **Portability (IW-7):** the contract is BPMN + `aef:` extension attributes ⇄ task/inception YAML — both
  open, text, diffable. No proprietary format; any conformant editor can drive the loop.
- **Cross-repo:** 832 = SoT for the designer/mapping-reference-editor; AEF hosts the surface + owns the
  framework-concept half of the mapping. Coordinated over termlink (thread T-175), per T-173's model.

## Scope Fence

**IN:** lock the architecture (IW-1..7); decompose into child inceptions (IW-8) with the AEF agent;
produce a scoped set of child inceptions for operator GO/NO-GO.
**OUT:** any build (children get their own inceptions → build tasks after GO); the phase-1 editor embed
(that's T-173/T-174, proceeding independently); resolving the child inceptions themselves.

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

**Recommendation:** DEFER

**Rationale:**

Framing inception: lock the designer-as-framework-surface architecture (7 decisions resolved with operator) and decompose into child inceptions; co-design with the AEF agent before any build.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

## Decisions

### 2026-07-11 — IW-8 per-child go/no-go (operator sovereign decision)
- **Chose:** **GO child-1 (mapping standard) + child-2 (forward bridge); DEFER child-3 (reverse discovery), child-4 (collaboration/concurrency), child-5 (hosting/tenancy).**
- **Why:** Operator ratified the recommended split (`docs/reports/T-175-child-decomposition.md`). Funds the primary value path (contract + draw→governed work); parks reverse/live-coedit/multi-tenancy behind their revisit triggers.
- **Realization:** child-1 → 832-led build task (formalize the converged mapping standard, G-3/tier/AC-seed provisional pending AEF ruling). child-2 → AEF-led; 832 tracks its support (emission spec + fixtures). child-3/4/5 → captured, `horizon: later`, with revisit triggers.
- **Rejected:** GO-all (all-or-nothing umbrella, framework-discouraged); DEFER-all (stalls the keystone that's ~90% done).

## Decision

**Decision**: GO

**Rationale**: Framing inception: lock the designer-as-framework-surface architecture (7 decisions resolved with operator) and decompose into child inceptions; co-design with the AEF agent before any build.

**Date**: 2026-07-10T15:48:48Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-10T10:42:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-10T15:48:48Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Framing inception: lock the designer-as-framework-surface architecture (7 decisions resolved with operator) and decompose into child inceptions; co-design with the AEF agent before any build.
