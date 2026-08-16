---
id: T-255
name: "Pool right-edge resize handle: authored page-width floor (mirror lane-height
  resize on the horizontal axis)"
description: >
  Pool right-edge resize handle: authored page-width floor (mirror lane-height resize
  on the horizontal axis)

status: work-completed
workflow_type: build
owner: human
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-26T19:49:17Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-26T20:07:37Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/check-corpus-geometry.sh,tests/run-bridge-tests.sh,tests/test_designer_render.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-255: Pool right-edge resize handle: authored page-width floor (mirror lane-height resize on the horizontal axis)

## Context

Operator request 2026-07-26 ("scale the horizontal end of a page, same as swimming lane but on the horizontal end; must not break existing features"). Today lane heights are authored (per-lane `height`, ns-resize drag handle) but the pool's right edge is purely content-derived via `contentRightEdge()` (T-043: max of POOL_WIDTH floor and rightmost node + 60px). Feature = an ew-resize drag handle on the pool's right edge backed by a persisted authored width that acts as a FLOOR inside `contentRightEdge()` — never a replacement — so the T-043 never-clip guarantee and every downstream consumer (viewBox/syncCanvasSize, T-251 zoom, thumbnails, Clean-layout auto-fit assumption) are structurally unaffected. Persistence mirrors `aef:laneMeta height`: optional `pageWidth` attribute on `aef:workflowMeta` (additive-only, emitted only when set — same pattern as `uuid`, zero seam surface for AEF). Dragging the edge at/inside the natural content edge clears the authored floor (snap back to auto-fit).

## Acceptance Criteria

### Agent
- [x] Dragging the new pool right-edge handle rightward grows the pool/page width; the authored width persists as `state.workflowMeta.pageWidth` and survives renderAll (same re-apply path as everything else: `contentRightEdge()` reads it) — Evidence: suite leg t255-pool-width probes w1 (real CDP drag +300px → pageWidth set, edge = POOL_X + pageWidth, nodes untouched) and w2 (renderAll → identical) PASS
- [x] Floor-not-replacement invariant: authored width can never crop content — with nodes past the authored edge, the pool still encloses rightmost node + margin (T-043 preserved); dragging the handle inward is clamped at the natural content edge and dragging to/inside it clears `pageWidth` (auto-fit restored, no attribute emitted) — Evidence: probe w4 (node pushed past authored edge → edge grew beyond it; restored after) and w5 (real inward drag → pageWidth null, edge back to natural, no attribute in export) PASS
- [x] Round-trip: `buildBpmnXml` emits `pageWidth` on `aef:workflowMeta` only when set (additive-only); import parses it back; export→import preserves the authored width; maps without the attribute behave byte-identically to today (no `pageWidth` in export of an untouched map) — Evidence: probe w0 (untouched map: no attribute) and w3 (attribute emitted when set; parseBpmnXml round-trip preserves value) PASS
- [x] One undo entry per resize gesture (T-132 pattern): Ctrl+Z after a resize restores the prior width — Evidence: probe w6 (undo() after the clearing drag restores the authored width) PASS
- [x] No regression to existing pointer interactions: rubber-band selection, node drag, lane-height resize, and T-251 zoom/pan legs all still green — full editor-behavior suite passes with a new t255-pool-width leg driving the handle via real CDP mouse events — Evidence: suite 7/7 legs PASS (jump-no-poison, same-map-edit-restore, t237-classification, t240-uuid-resolve, t245-view-chrome, t249-canvas-nav, t255-pool-width)
- [x] Standing gates green: bridge tests 37/37, corpus geometry 24 clean, render gate PASS — Evidence: bridge "37 passed, 0 failed" (one prior run had a chromium-startup flake in _typed-events-cdp.mjs — "webSocketDebuggerUrl of undefined" before page load; passed standalone and in full rerun, not a content failure); geometry "24 clean, 0 new-fail"; render gate "PASS: designer render-check (0.5.0)"
- [x] Visual verification: element-level screenshots of the handle (rest + during-drag highlight) and canvas before/after widen, read and confirmed (single dark theme — app is dark-only) — Evidence: see ## Visual Verification

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

- [x] [REVIEW] Dragging the page's right edge feels natural and useful
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered%2Fharvest-pipeline.bpmn (the gallery already serves this build — sha-verified)
  2. Hover the thin right border of the pool (the page's right edge) — cursor becomes ↔ and a small accent grip appears at mid-height
  3. Drag it to the right: the page widens with empty space (the diagram re-fits smaller); release, edit nodes, confirm the width sticks
  4. Drag the edge back left past the last node: the page snaps back to auto-fit (hugging the content again)
  5. Ctrl+Z after a resize: the previous width returns
  **Expected:** the gesture feels like the lane-height drag, just horizontal; widening never moves your nodes; dragging inward can never cut nodes off
  **If not:** note what felt wrong (hit zone too thin? snap-back surprising? re-fit zoom jarring?) — reply here or on /review/T-255

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# pool-resize handle + pageWidth plumbing present in source
grep -q "pool-resize-handle" src/aef-workflow-designer.html
grep -q "pageWidth" src/aef-workflow-designer.html
# full editor-behavior suite (incl. new t255-pool-width leg) — exit 0 only when all legs pass
# (suite emits JSON with lowercase "pass": true — no uppercase PASS marker to grep; the exit code IS the verdict)
node tools/_editor-behavior-verify-cdp.mjs > /tmp/.t255suite 2>&1
# bridge tests
bash tests/run-bridge-tests.sh > /tmp/.t255bridge 2>&1
# corpus geometry unaffected (24 maps clean)
bash tests/check-corpus-geometry.sh > /tmp/.t255geom 2>&1
# render gate
python3 tests/test_designer_render.py > /tmp/.t255render 2>&1

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Recommendation

**Recommendation:** GO
**Rationale:** Exact horizontal mirror of an affordance the operator already uses daily (lane-height drag), implemented as a floor inside the single function every width consumer reads (`contentRightEdge()`), with additive-only serialization — untouched maps export byte-identically and AEF ignores unknown attributes (zero seam surface). The one open judgment is feel (hit-zone width, snap-back-to-auto behavior, fit-zoom re-scale while dragging) — exactly what the Human [REVIEW] AC checks at the sha-verified gallery URL.
**Evidence:**
- Suite 7/7 legs incl. new t255-pool-width driving the handle with real trusted CDP input (probes w0–w6: baseline no-attr, drag grows, render survival, round-trip, T-043 floor invariant, inward-clear, undo restore)
- bridge 37/37, corpus geometry 24 clean, render gate PASS (P-011 re-ran all of these green, 6/6)
- 4 screenshots read (`.playwright-mcp/t255-*.png`): grip renders in lane-grip visual language; widened canvas spans correctly; cleared state pixel-identical to baseline
- Implementation commit dda0587; live at http://192.168.10.107:8834/designer.html (served copy sha == src, verified over HTTP)

## Visual Verification

Screenshots produced by `tools/_t255-visual-shots.mjs` (hermetic sidecar, dark-only app = single mode), all READ and confirmed:
- `.playwright-mcp/t255-handle-active.png` — 4× zoom of the right-edge grip in its active (accent) state on the pool border; same visual language as lane grips, no artifacts
- `.playwright-mcp/t255-canvas-before.png` — baseline canvas at fit
- `.playwright-mcp/t255-canvas-widened.png` — authored width +900: pool/header/lanes/add-lane strip all span the new width, content re-fits smaller, no clipping or misalignment
- `.playwright-mcp/t255-canvas-cleared.png` — pageWidth cleared: pixel-identical to baseline (auto-fit restored)

## Decisions

### 2026-07-26 — resize tracking listener level
- **Chose:** window-level mousemove (like the T-251 pan handlers), with client-px→svg-px conversion via the screen-CTM scale captured at drag START
- **Why:** at fit zoom the pool's right edge sits at the canvas-wrap boundary — any rightward drag leaves the svg immediately, so the svg-level mousemove (where lane resize lives) never fires; proven with an instrumented trusted-input probe (svg-mm absent, win-mm present). Live-CTM conversion would feed the drag's own viewBox growth back into the mapping (accelerating resize); the captured scale keeps client↔svg mapping constant per gesture
- **Rejected:** svg-level mousemove (first implementation — failed the suite leg exactly this way); live clientToSvg per move (feedback loop)

### 2026-07-26 — persistence location and semantics
- **Chose:** optional `pageWidth` attribute on `aef:workflowMeta` (pool-relative width, floor semantics inside contentRightEdge(), null = auto-fit, emitted only when set)
- **Why:** mirrors the proven `aef:laneMeta height` round-trip and the `uuid` additive-only pattern — untouched maps export byte-identically, AEF's parser ignores additions (zero seam surface); floor-not-replacement preserves the T-043 never-clip guarantee for every consumer of contentRightEdge()
- **Rejected:** BPMN DI bounds (the editor doesn't emit a DI section at all today — inventing one for this is a far bigger contract change); a replacement width (could crop content, breaking T-043)

### 2026-07-26 — undo integration
- **Chose:** pushHistory() at resize-gesture start (one undo entry per drag, T-132 pattern)
- **Why:** node drags and Clean already do this; the XML snapshot now round-trips pageWidth so undo restores it structurally
- **Rejected:** strict parity with lane-height resize (which predates T-132 and records no history) — matching a known gap would spread it

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-26T19:49:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-255-pool-right-edge-resize-handle-authored-p.md
- **Context:** Initial task creation

### 2026-07-26T20:07:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6e0b6c3e
- **Timestamp:** 2026-07-29T13:13:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
