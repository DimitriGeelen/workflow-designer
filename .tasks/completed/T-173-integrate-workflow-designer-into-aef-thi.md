---
id: T-173
name: "Integrate Workflow Designer into AEF (this repo stays source of truth)"
description: >
  Inception: Integrate Workflow Designer into AEF (this repo stays source of truth)

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-10T05:39:40Z
last_update: '2026-08-16T12:33:41Z'
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
  confidence: 3
  disposition: answered
  rationale: CONFIRMED by operator GO (2026-07-10T09:53:46Z, rationale "phase-1 unit = single-file editor"). Phase-1 = single-file editor (authoring-only); server/corpus/bridge/validator deferred to phase-2 pending demand.
- **IW-4: How is the dependency cycle avoided** (832 vendors AEF; AEF would reference 832)?
  confidence: 3
  disposition: answered
  rationale: AEF references a pinned *build artifact*, never a recursive source pull. Because it's the release (not source), the 832-vendors-AEF / AEF-references-832 cycle never closes. Agreed offset 17.
- **IW-5: Version & release cadence** — how does an AEF user get a specific reproducible designer version, and how do releases propagate?
  confidence: 2
  disposition: answered
  rationale: 832 cuts versioned releases; AEF pins a specific version; a release bump propagates when AEF re-pins. Couples to IW-2 (M3). Release-pipeline discipline is a phase-1 build-task detail.
- **IW-6: Bidirectional flow** — how do improvements discovered on the AEF side reach 832 (upstream), and how does AEF pull updates? (operator-raised, post-GO)
  confidence: 3
  disposition: answered
  rationale: TWO directions. (a) PULL (832→AEF): M3 re-pin — AEF bumps to a new 832 release (see IW-2/IW-5). (b) IMPROVEMENTS (AEF→832): AEF NEVER patches its vendored copy (would fork-drift, break C1/C2); it files improvements UPSTREAM to 832 via the proven cross-agent termlink channel (same path as this T-173 collaboration + ring20 RCA offsets 11–12). 832 implements + releases; AEF re-pins. A documented bidirectional protocol is a REQUIRED deliverable of the build tasks (both sides), not optional.

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

**Recommendation:** GO — mechanism **M3 + `fw designer`**, phase-1 unit = single-file editor.

**Rationale:**

Exploration complete; the two-agent design work converged. The designer becomes part of AEF's surface
area **without breaking the hard constraints**: 832 stays source of truth (C1) and future development
continues here (C2) because AEF vendors a *pinned build artifact* of 832's release — never 832's source.
That artifact reference (not a recursive source pull) keeps the 832-vendors-AEF / AEF-references-832
dependency cycle from ever closing (IW-4), which is exactly why submodule/subtree (M1/M2) were rejected.
The path is bounded, scoped, testable, and reversible (matches the GO criteria): 832 files one
release-build task; AEF files one `fw designer` task. Phase-1 ships the self-contained single-file
editor (authoring only); project persistence/versioning (Flask server + corpus) is a clearly-scoped
phase-2 deferred pending real demand.

**Operator still owns:** the GO/NO-GO itself, and IW-3 (confirm phase-1 = single-file editor, or direct
the fuller editor+server+corpus unit now).

**Evidence:**

- Design-space survey + joint recommendation: `docs/reports/T-173-aef-integration-inception.md`
  (M1–M5 evaluated; Joint recommendation + Dialogue Log + IW resolution).
- Cross-agent convergence: DM topic `dm:d1993c2c3ec44c94:…` — kickoff (offset 16), concurrence (offset 17).
- IW-1/IW-2/IW-4/IW-5 answered (see `## Open Questions`); IW-3 surfaced to operator.
- AEF collaborator: `aef` / `tl-uhqt63fb` / `/opt/999-Agentic-Engineering-Framework`.

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

**Rationale**: Exploration complete; the two-agent design work converged. The designer becomes part of AEF's surface
area **without breaking the hard constraints**: 832 stays source of truth (C1) and future development
continues here (C2) because AEF vendors a *pinned build artifact* of 832's release — never 832's source.
That artifact reference (not a recursive source pull) keeps the 832-vendors-AEF / AEF-references-832
dependency cycle from ever closing (IW-4), which is exactly why submodule/subtree (M1/M2) were rejected.
The path is bounded, scoped, testable, and reversible (matches the GO criteria): 832 files one
release-build task; AEF files one `fw designer` task. Phase-1 ships the self-contained single-file
editor (authoring only); project persistence/versioning (Flask server + corpus) is a clearly-scoped
phase-2 deferred pending real demand.

**Date**: 2026-07-18T09:15:34Z

## Updates

### 2026-07-10 — GO recorded + bidirectional flow (IW-6) [workflow-designer agent]
- **Operator recorded GO** (Decision section, 2026-07-10T09:53:46Z). Mechanism = M3 + `fw designer`;
  phase-1 unit = single-file editor. Decision verified persisted (not the Watchtower false-success bug):
  `fw inception status` shows GO; `## Decision` on disk.
- **Operator raised IW-6 (bidirectional flow)** post-GO. Answered: PULL = M3 re-pin (832→AEF);
  IMPROVEMENTS = upstream-to-832 via the cross-agent termlink channel, AEF never patches its vendored
  copy. Documented bidirectional protocol is a required deliverable of both build tasks.
- **Post-GO plan (inception discipline — build under NEW task IDs, not T-173):**
  1. File the 832-side release build task (cut versioned single-file release + release mechanism +
     documented pull + documented upstream-improvement path).
  2. Notify the AEF agent GO landed → it files the `fw designer` build task on the AEF side.
  3. Neither side builds before its own task's ACs are written (G-020).

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

### 2026-07-10T09:53:46Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Exploration complete; the two-agent design work converged. The designer becomes part of AEF's surface
area **without breaking the hard constraints**: 832 stays source of truth (C1) and future development
continues here (C2) because AEF vendors a *pinned build artifact* of 832's release — never 832's source.
That artifact reference (not a recursive source pull) keeps the 832-vendors-AEF / AEF-references-832
dependency cycle from ever closing (IW-4), which is exactly why submodule/subtree (M1/M2) were rejected.
The path is bounded, scoped, testable, and reversible (matches the GO criteria): 832 files one
release-build task; AEF files one `fw designer` task. Phase-1 ships the self-contained single-file
editor (authoring only); project persistence/versioning (Flask server + corpus) is a clearly-scoped
phase-2 deferred pending real demand.

### 2026-07-10T13:30Z — phase-1 mechanism VERIFIED LIVE end-to-end [delivery]
- **Both build tasks landed:** 832-side release (T-174, release 0.1.0) complete; AEF-side `fw designer`
  phase-1 (T-2521, under GO'd T-2520) built + verified live by the AEF agent.
- **832 delivered the build (Direction-1 PULL, executed as a push):** the AEF session is boundary-blocked
  (T-559) from pulling `/opt/832`, so 832 pushed `dist/aef-workflow-designer-0.1.0.html` over the termlink
  file_send channel to session `tl-uhqt63fb` (transfer `xfer-mcp-3173253`, 394110 bytes,
  sha256 `d0e0177cffd3cdd86f99710d4ee98cc17ee7be2bf0153c5b68a3f3feccb0317d`).
- **AEF `fw designer sync` verified + installed** the pinned copy read-only; `GET /designer` on the AEF
  Watchtower (`:3001`) flipped from the "not yet vendored" placeholder to the live editor.
- **End-to-end fidelity proven (not by proxy):** the served `/designer` bytes are **byte-identical** to
  832's source — served sha256 == pin sha256 == `d0e0177c…0317d`, 394110 bytes. The whole loop
  (832 builds → deliver → sha256-verify → serve read-only ≡ source) is closed and observed on real infra.
- **Constraints held:** 832 remains SoT (C1); AEF vendors a pinned artifact, never forks (the sync guard
  rejects any non-pin sha256); dependency cycle stays open (IW-4). The T-173 mechanism (M3 + `fw designer`)
  is realised. Phase-2 (server/corpus/tenancy) remains the arc `designer-authoring-surface` program (T-175).

### 2026-07-10T15:50Z — VISUAL VERIFICATION (renders, not just serves) [visual-verification]
- **Method:** Playwright loaded the AEF-served page `http://192.168.10.107:3001/designer` (the vendored
  copy, NOT a local file), screenshot read by the agent. Evidence:
  `docs/reports/assets/T-173-designer-live-render.png`.
- **Rendered output confirmed:** the editor DRAWS the AEF `investigate` workflow across three swimlanes —
  HUMAN SOVEREIGNTY (Human review & route → Ready), FRAMEWORK AUTHORITY (Investigation requested → Load
  context → Write report → Abandoned), AGENT·INITIATIVE (Decompose → Fan-out ⊕ → 3 parallel searches →
  Join ⊕ → Synthesize → Sufficient? ⊗ with `insufficient·loop` back-edge). Full palette, populated node
  inspector (id `investigate`, source `agents/dispatch/investigate.md`), toolbar all render; labels legible.
- **Console:** only the two benign 404s (`/api/health` backend-absent + `favicon.ico`) — no font/CDN or
  scripting errors. Confirms the "authors offline / degrades without a backend" claim on the served copy.
- **Conclusion:** phase-1 integration verified at the pixel level, not just HTTP 200 / byte-identity. The
  vendored 0.1.0 is a working editor on AEF infra.

### 2026-07-18T09:15:34Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Exploration complete; the two-agent design work converged. The designer becomes part of AEF's surface
area **without breaking the hard constraints**: 832 stays source of truth (C1) and future development
continues here (C2) because AEF vendors a *pinned build artifact* of 832's release — never 832's source.
That artifact reference (not a recursive source pull) keeps the 832-vendors-AEF / AEF-references-832
dependency cycle from ever closing (IW-4), which is exactly why submodule/subtree (M1/M2) were rejected.
The path is bounded, scoped, testable, and reversible (matches the GO criteria): 832 files one
release-build task; AEF files one `fw designer` task. Phase-1 ships the self-contained single-file
editor (authoring only); project persistence/versioning (Flask server + corpus) is a clearly-scoped
phase-2 deferred pending real demand.
