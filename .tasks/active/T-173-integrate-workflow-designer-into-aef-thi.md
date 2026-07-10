---
id: T-173
name: "Integrate Workflow Designer into AEF (this repo stays source of truth)"
description: >
  Inception: Integrate Workflow Designer into AEF (this repo stays source of truth)

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-10T05:39:40Z
last_update: 2026-07-10T05:42:46Z
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

# T-173: Integrate Workflow Designer into AEF (this repo stays source of truth)

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

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

- **IW-1: Does AEF already have a plugin/component/tool-registration mechanism the designer can plug into** (component cards, a `fw <tool>` route, a plugins dir)?
  confidence: 2
  disposition: answered
  rationale: AEF agent (DM offset 17) — designer plugs in as a `fw designer` route serving a pinned vendored build. The `fw <route>` mechanism exists; no new plugin subsystem needed for phase-1.
- **IW-2: What reference/sync mechanism keeps 832 as source of truth** — git submodule, subtree, released artifact, or mirror-sync?
  confidence: 2
  disposition: answered
  rationale: M3 — 832 publishes a versioned single-file build; AEF pulls a pinned version. Agreed with AEF agent (offset 17). Submodule/subtree rejected (reintroduce the dep cycle, couple histories).
- **IW-3: What is the integration unit** — single-file editor only, or editor + server + corpus + bridge/validator?
  confidence: 2
  disposition: deferred
  rationale: OPERATOR'S PICK. Joint recommendation = phase-1 single-file editor (authoring-only), server/corpus deferred to phase-2 (project persistence/versioning needs the Flask server). Surfaced to operator; awaiting confirmation.
- **IW-4: How is the dependency cycle avoided** (832 vendors AEF; AEF would reference 832)?
  confidence: 3
  disposition: answered
  rationale: AEF references a pinned *build artifact*, never a recursive source pull. Because it's the release (not source), the 832-vendors-AEF / AEF-references-832 cycle never closes. Agreed offset 17.
- **IW-5: Version & release cadence** — how does an AEF user get a specific reproducible designer version, and how do releases propagate?
  confidence: 2
  disposition: answered
  rationale: 832 cuts versioned releases; AEF pins a specific version; a release bump propagates when AEF re-pins. Couples to IW-2 (M3). Release-pipeline discipline is a phase-1 build-task detail.

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

Exploration not yet started. Integration spans two repos and two agents (this designer repo + the AEF framework, worked by the AEF agent) and is an architecture/ownership decision with portability lock-in implications (submodule vs subtree vs package vs fw plugin vs vendored mirror; sync direction). Hard constraint: this repo remains the source of truth and future development continues here. Needs a design pass + AEF-agent collaboration + operator GO before any integration code.

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

### 2026-07-10T05:41:14Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-10 — collaboration state [workflow-designer agent]
- **Done:** Inception framed; C-001 artifact `docs/reports/T-173-aef-integration-inception.md`
  (M1–M5 mechanisms, IW-1..IW-5); committed+pushed (4e2a94e).
- **AEF agent:** `aef` / `tl-uhqt63fb` / `/opt/999-Agentic-Engineering-Framework`. Kickoff delivered
  via signed DM on topic `dm:d1993c2c3ec44c94:d1993c2c3ec44c94` (thread T-173, offset 16) AND injected
  into its session (twice). NOTE: all local sessions share one ed25519 fingerprint → the "DM" is a
  shared-identity topic, not point-to-point.
- **Blocker seen + cleared:** AEF agent hit its Claude session limit (was working its own T-2519),
  reset ~11:10 Berlin; re-nudged after reset. **Still no reply as of wrap-up.**
- **NEXT SESSION:** (1) Read DM topic above for an AEF reply after offset 16 (use a TARGETED read —
  `recent_dm`/`channel_state_since` — NOT `termlink_output`; the aef terminal buffer is ~785K chars and
  blows context). (2) Fold IW-1/IW-2 answers into the artifact Dialogue Log + update IW dispositions.
  (3) Operator still owes **IW-3** (integration unit: single-file editor only, or editor+server+corpus+
  bridge+validator). (4) Then write a joint recommendation for operator GO/NO-GO; no build before GO.
- **Leading hypothesis to confirm with AEF agent:** hybrid M3+M4 — 832 cuts a versioned release; AEF
  references that pinned version as a first-class component. Keeps 832 as SoT, avoids the dep cycle.

### 2026-07-10 — CONVERGED: joint recommendation ready for operator [workflow-designer agent]
- **Outcome:** Two-agent design work complete. Both agents concur on **M3 + `fw designer`** (832
  publishes a versioned single-file build; AEF vendors a pinned copy and serves it via `fw designer`).
  My concurrence posted to the AEF agent (DM offset 17). Nothing remains to resolve between the agents.
- **IW dispositions:** IW-1/IW-2/IW-4/IW-5 → answered (see above). IW-3 → operator's pick; joint
  recommendation = phase-1 single-file editor (authoring), server/corpus deferred to phase-2.
- **Artifact updated:** `docs/reports/T-173-aef-integration-inception.md` — Joint recommendation section
  + Dialogue Log entries + IW resolution.
- **AWAITING OPERATOR:** GO/NO-GO + IW-3 confirmation. Record via:
  `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-173 go --rationale 'M3 + fw designer; phase-1 unit = single-file editor' --i-am-human`
  On GO: I file the 832-side release build task; the AEF agent files the `fw designer` build task.
  **Neither side builds before GO.**
