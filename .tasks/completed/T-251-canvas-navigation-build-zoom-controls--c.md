---
id: T-251
name: "Canvas navigation build: zoom controls + Ctrl+wheel + scrollbars + drag-to-pan (T-249 GO)"
description: >
  Canvas navigation build: zoom controls + Ctrl+wheel + scrollbars + drag-to-pan (T-249 GO)

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-25T19:35:43Z
last_update: 2026-07-26T15:10:52Z
date_finished: 2026-07-25T19:45:54Z
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
---

# T-251: Canvas navigation build: zoom controls + Ctrl+wheel + scrollbars + drag-to-pan (T-249 GO)

## Context

Build authorized by T-249 inception GO (decision de35df3, spike 12/12 green — see
`docs/reports/T-249-canvas-navigation.md` §Findings and `tools/_t249-spike-zoom-cdp.mjs`).
Mechanism fixed by the spike: explicit SVG element sizing (inline style = viewBox × zoom)
applied from `syncCanvasSize()` (single integration point); `.canvas-wrap` becomes the
scroll container (`overflow:auto`) when zoomed; pan = capture-phase listener on the wrap
(middle-mouse always + space+drag), preempting rubber-band without modifying existing
handlers. Zoom is VIEW state — never serialized, fit stays the load default, fit-restore
must be byte-identical to today's behavior.

## Acceptance Criteria

### Agent
- [x] Header zoom controls: − / zoom% readout / + / Fit / 100%; buttons drive setZoom; readout live-updates; Fit restores exactly today's behavior (no inline size, overflow back to hidden) — suite leg9 z0/z1/z8 (readout fit→26%→fit, styleW empty at fit, aria-pressed tracks); screenshots t251-header-{fit,zoomed,fit-after}.png
- [x] Ctrl+wheel over the canvas zooms at the cursor (point under cursor stays put); preventDefault applies ONLY over the canvas (page/browser zoom untouched elsewhere); plain wheel still scrolls the zoomed container natively — leg9 z4b: real CDP mouseWheel modifiers=2, zf 0.2→0.224, anchor px drift 2.0 svg units (<3) on the overflowing axis; wheel listener guards on e.ctrlKey before any preventDefault
- [x] Past-fit zoom shows native scrollbars on .canvas-wrap; zoom survives renderAll() and content growth — leg9 z1 (scrollW 1023 > clientW 660), z3 (elW==vb×zf ±3 after node-move+renderAll); T-249 spike P4 proved content-growth tracking for the same mechanism
- [x] Drag-to-pan: middle-mouse always pans (leg9 z5: dSL 140, no rubber-band, no selection); space+drag pans via REAL key events (leg9 z6: pan-ready armed, dSL 120, multiSelect untouched); typing guard (INPUT/TEXTAREA/SELECT/contentEditable) on the Space handler; marquee byte-identical when pan not engaged (leg9 z2 click + spike P6)
- [x] Status overlay and clean-nudge pinned while scrolled — syncOverlayPin counter-translate; leg9 z7 visible=true; screenshot t251-canvas-zoomed-scrolled.png (Mode: select box bottom-left at scrollLeft 300)
- [x] captureThumbnail() independent of live zoom — clone.removeAttribute('style') before style inlining; diff touches only src/aef-workflow-designer.html + tools/_editor-behavior-verify-cdp.mjs + tools/_t251-visual-shots.mjs (no .py, no document format)
- [x] G-010 suite: new t249-canvas-nav leg, 6/6 legs PASS; bridge 37/37 PASS; geometry sweep 24 clean; render gate PASS (all run 2026-07-25 on this working tree)

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

### Human
- [x] [REVIEW] Zoom + pan feel right on a real oversized map
  **Steps:**
  1. Open the designer, load a large map (e.g. via Open project), zoom in with Ctrl+wheel or the + button until scrollbars appear
  2. Pan with middle-mouse drag and with space+drag; scroll with the scrollbars and plain wheel
  3. Click Fit — the whole map returns to fit-to-view exactly as before this change
  **Expected:** Zooming feels anchored under the cursor, panning is smooth, nothing selects while panning, Fit looks identical to the old behavior
  **If not:** Note which gesture felt wrong (zoom anchor drift / pan starting a selection box / Fit not restoring) — each is independently fixable

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

grep -q "btn-zoom-fit" src/aef-workflow-designer.html
grep -q "applyCanvasZoom" src/aef-workflow-designer.html
grep -q "t249-canvas-nav" tools/_editor-behavior-verify-cdp.mjs
# zoom must never be serialized: the BPMN builder must not mention zoomFactor
! grep -q "zoomFactor" <(sed -n '/function buildBpmnXml/,/^function /p' src/aef-workflow-designer.html)
node tools/_editor-behavior-verify-cdp.mjs > /tmp/.t251-suite.json 2>&1
python3 -c "import json; v=json.load(open('/tmp/.t251-suite.json')); assert v['pass'] and len(v['legs'])==6"
bash tests/check-corpus-geometry.sh > /tmp/.t251-geom.out 2>&1
bash tests/run-bridge-tests.sh > /tmp/.t251-bridge.out 2>&1
python3 tests/test_designer_render.py > /tmp/.t251-render.out 2>&1

## Visual Verification

Element-level screenshots (hermetic harness, tools/_t251-visual-shots.mjs), all READ and checked 2026-07-25:
- `.playwright-mcp/t251-header-fit.png` — zoom controls at fit ("fit" readout, ⤢ pressed) alongside T-245 toggles
- `.playwright-mcp/t251-header-zoomed.png` — "26%" readout, ⤢ un-pressed
- `.playwright-mcp/t251-canvas-zoomed-scrolled.png` — native horizontal scrollbar, content at scale, Mode overlay pinned bottom-left at scrollLeft=300
- `.playwright-mcp/t251-focus-zoomed.png` — focus mode full-bleed with zoom held, Exit-focus floating, overlay pinned
- `.playwright-mcp/t251-fit-restore.png` — fit after zoom identical to pre-change fit-to-view
- `.playwright-mcp/t251-header-fit-after.png` — readout back to "fit", ⤢ pressed again

## Recommendation

**Recommendation:** GO

**Rationale:** All seven agent ACs verified with standing-suite + real-trusted-input evidence; zero regressions across the four gates (behavior suite 6/6 incl. the 5 pre-existing legs, bridge 37/37, geometry 24 clean, render gate). Zoom is transient view state with zero seam surface (same class as T-245) — release-eligible whenever the operator wants to cut, no AEF coordination required beyond the usual announce.

**Evidence:** Suite verdicts in leg `t249-canvas-nav`; screenshots listed under Visual Verification; T-249 research artifact documents the mechanism rationale.

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

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-25T19:35:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-251-canvas-navigation-build-zoom-controls--c.md
- **Context:** Initial task creation

### 2026-07-25T19:45:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
