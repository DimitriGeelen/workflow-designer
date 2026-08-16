---
id: T-249
name: "Canvas navigation for oversized workflows: zoom, scrollbars, drag-to-pan"
description: >
  Inception: Canvas navigation for oversized workflows: zoom, scrollbars, drag-to-pan

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-25T14:45:33Z
last_update: '2026-08-16T14:33:23Z'
date_finished: 2026-07-25T19:33:03Z
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
  - ts: '2026-08-16T14:33:23Z'
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
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-249: Canvas navigation for oversized workflows: zoom, scrollbars, drag-to-pan

## Problem Statement

Large workflows never overflow the page — the canvas fits everything via the every-render viewBox recompute + `preserveAspectRatio="meet"` (T-043), so oversized maps **shrink until illegible** with no way to view at working scale and move around. Operator request (2026-07-23): zoom to a readable scale, then navigate via native scrollbars AND drag-to-pan. Fit-to-view stays the default; navigation is the missing second mode.

## Assumptions

- A-018 (VALIDATED by spike): explicit-SVG-sizing zoom (viewBox untouched, element width/height = content × zoom, overflow:auto container) survives the every-render viewBox recompute and keeps all pointer paths CTM-correct. Evidence: 12/12 probes green, tools/_t249-spike-zoom-cdp.mjs.

## Open Questions

- **IW-1: Which zoom mechanism composes safely with render()'s every-render viewBox recompute — explicit SVG element sizing, viewBox windowing, or CSS transform?**
  confidence: 9
  disposition: answered
  rationale: Explicit SVG element sizing, via a syncCanvasSize wrapper (single integration point). Spike P1/P3/P4/P5 green against the unmodified shipping editor: zoom survives renderAll(), tracks content growth, fit-restore is byte-identical to today; CTM carries the zoom (ctmA=1.4999993 at 1.5). Alternatives never needed — mechanism 1 passed every probe.

- **IW-2: Which drag-to-pan gesture avoids collision with node-drag, marquee select, connect mode, and lane resize?**
  confidence: 8
  disposition: answered
  rationale: Capture-phase listener on .canvas-wrap gated by a pan flag (space-held) OR middle-mouse — stopPropagation preempts the svg-level rubber-band mousedown without touching any existing handler. Spike P7: pan moves scroll exactly, rubberBand never starts, selection untouched; P7b: middle-mouse pans with no mode key; P6: marquee still exact with the pan listener installed but inactive. Build: middle-mouse always on + space+drag alternative, one shared code path.

- **IW-3: Do secondary render consumers (thumbnails /api/thumb, export/save PNG, hermetic suite probes) stay unaffected by the chosen mechanism?**
  confidence: 8
  disposition: answered
  rationale: /api/thumb is server-side (untouched by construction); captureThumbnail() renders fine at zoom (P9, dims derive from getBBox = viewBox-space); suite renders never set zoom → fit path unchanged (P5). One-line build hardening: strip cloned inline style in captureThumbnail for byte-stable thumbnails.

- **IW-4: Does zoomed navigation compose with T-245 focus mode (fullscreen + zoom + scroll + pan simultaneously)?**
  confidence: 9
  disposition: answered
  rationale: Spike P8: focus mode + zoom 1.5 → zoom held, scrollbars live, Esc exits focus with zoom intact. canvas-wrap is the scroll container in both modes, as expected.

## Exploration Plan

One spike, timeboxed ~1h, in the hermetic sidecar harness (G-006-safe, throwaway docroot):
1. Prototype mechanism 1 (explicit SVG sizing + overflow:auto) against a deliberately oversized fixture map.
2. Probe: zoom in → scrollbars appear; click a node at 150% while scrolled → selection lands correctly (CTM check); renderAll() during zoom (drag a node) → zoom survives; snap guides/marquee/status overlay positions; Fit restores.
3. Trial pan gestures (IW-2) on the prototype; pick the least-colliding one.
4. Only if mechanism 1 fails structurally: compare CSS-transform variant.
Output: Findings in docs/reports/T-249-canvas-navigation.md + GO/NO-GO recommendation with the mechanism + gesture named.

## Technical Constraints

- Zoom is VIEW state — never serialized into the BPMN document (same seam principle as T-245's aefViewPrefs; zero contract surface).
- All pointer math must keep flowing through `clientToSvg`'s `getScreenCTM().inverse()` (T-071) — any mechanism that bypasses the CTM is disqualified.
- G-003 standing gap (pointer paths, 2 field bugs historically): the eventual build MUST add suite probes (zoomed click accuracy, scrollbar presence, fit-restore, pan-then-click).
- Ctrl+wheel must not fight native wheel-scroll of the overflow container; browser pinch-zoom (ctrl+wheel default) needs preventDefault only over the canvas.

## Scope Fence

**IN:** zoom controls (Fit / 100% / + / −), Ctrl+wheel zoom at cursor, native scrollbars past fit, drag-to-pan (gesture per IW-2), suite probes, T-245 focus-mode composition.
**OUT:** minimap/overview widget, touch/pinch gestures, per-map zoom persistence (session-only unless trivially free), any document-format change, any Python/server change.

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

**GO if:**
- A zoom mechanism survives the every-render viewBox recompute WITHOUT modifying render()'s existing behavior (fit stays default, restore byte-identical)
- Pointer paths (click, marquee, pan) proven CTM-correct at zoom+scroll with REAL trusted input (G-003 class), not synthetic dispatch
- A pan gesture coexists with rubber-band select, node-drag, and connect mode without editing existing handlers
- Secondary render consumers (/api/thumb, captureThumbnail, suite) demonstrably unaffected
- Focus mode (T-245) composes with zoom+scroll

**NO-GO if:**
- Every candidate mechanism requires restructuring render()/syncCanvasSize or forking pointer math off the CTM path
- Pan cannot be added without changing rubber-band/drag handler logic (regression surface on the 2-field-bug pointer pipeline)
- Zoom state leaks into serialization or secondary renders

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

All four open questions answered by the timeboxed spike (well under the 1h box), every GO criterion met, no NO-GO criterion triggered. Mechanism: explicit SVG element sizing via a syncCanvasSize wrapper — proven against the UNMODIFIED shipping editor with zero source edits, so the production diff is small, additive, and reversible (fit stays default; zoom is transient view state, never serialized). Pointer correctness — the G-003 risk that motivated inception — verified with real CDP trusted input at zoom+scroll (click, marquee, pan all CTM-exact). Build task should implement: zoom controls (Fit/100%/+/−), Ctrl+wheel-at-cursor, overflow:auto scrollbars, middle-mouse + space+drag pan (one shared capture-phase code path), overlay re-anchor, captureThumbnail clone-style strip, and promote spike probes P1–P8 into the G-010 standing suite.

**Evidence:**

- Spike harness + prototype: `tools/_t249-spike-zoom-cdp.mjs` (hermetic, G-006-safe, real trusted input)
- Verdict: 12/12 probes green (grow-fixture, P1 zoom-scrollbars, P2 ctm-click-zoomed-scrolled, P3 zoom-survives-render, P4 content-growth-tracked, P5 fit-restore, P6 marquee-at-zoom expected==selected, P7 pan-preempts-marquee, P7b middle-mouse-pan, P8 focus-mode-composes, P9 thumbnail-renders-at-zoom, P10 overlay observation)
- A-018 validated (fw assumption validate A-018, spike evidence recorded)
- Full findings: `docs/reports/T-249-canvas-navigation.md` §Findings
- Two scoped build findings, neither a blocker: status-overlay scrolls out of view when panned (re-anchor it); Ctrl+wheel-at-cursor arithmetic left to build (no structural risk — standard formula on exposed knobs)

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

**Rationale**: All four open questions answered by the timeboxed spike (well under the 1h box), every GO criterion met, no NO-GO criterion triggered. Mechanism: explicit SVG element sizing via a syncCanvasSize wrapper — proven against the UNMODIFIED shipping editor with zero source edits, so the production diff is small, additive, and reversible (fit stays default; zoom is transient view state, never serialized). Pointer correctness — the G-003 risk that motivated inception — verified with real CDP trusted input at zoom+scroll (click, marquee, pan all CTM-exact). Build task should implement: zoom controls (Fit/100%/+/−), Ctrl+wheel-at-cursor, overflow:auto scrollbars, middle-mouse + space+drag pan (one shared capture-phase code path), overlay re-anchor, captureThumbnail clone-style strip, and promote spike probes P1–P8 into the G-010 standing suite.

**Date**: 2026-07-25T19:33:03Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-25T14:46:11Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-25T19:33:03Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** All four open questions answered by the timeboxed spike (well under the 1h box), every GO criterion met, no NO-GO criterion triggered. Mechanism: explicit SVG element sizing via a syncCanvasSize wrapper — proven against the UNMODIFIED shipping editor with zero source edits, so the production diff is small, additive, and reversible (fit stays default; zoom is transient view state, never serialized). Pointer correctness — the G-003 risk that motivated inception — verified with real CDP trusted input at zoom+scroll (click, marquee, pan all CTM-exact). Build task should implement: zoom controls (Fit/100%/+/−), Ctrl+wheel-at-cursor, overflow:auto scrollbars, middle-mouse + space+drag pan (one shared capture-phase code path), overlay re-anchor, captureThumbnail clone-style strip, and promote spike probes P1–P8 into the G-010 standing suite.

### 2026-07-25T19:33:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
