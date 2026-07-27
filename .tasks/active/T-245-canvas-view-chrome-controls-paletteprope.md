---
id: T-245
name: "Canvas view-chrome controls: palette/properties hide-show toggles + fullscreen focus mode"
description: >
  Operator enhancement request: more canvas real estate. (1) Per-panel toggle buttons hide/show the left palette and right properties panel individually (persisted in editor settings); (2) a focus/presentation button hides header+palette+properties AND requests browser fullscreen — diagram auto-fills freed space via the existing T-043 viewBox fit. Floating exit affordance + Esc restores. No inception needed: no new files/subsystem, well-understood UI pattern; residual choices are in-task Decisions.

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
created: 2026-07-23T09:41:04Z
last_update: 2026-07-23T09:51:35Z
date_finished: 2026-07-23T09:51:07Z
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

# T-245: Canvas view-chrome controls: palette/properties hide-show toggles + fullscreen focus mode

## Context

Operator enhancement request (2026-07-23). The canvas SVG already auto-fits content to its container (T-043 viewBox + preserveAspectRatio meet), so "zoom to fill the screen" and "hide the menus" share one mechanism: hiding chrome frees pixels the diagram immediately reflows into. Deliverable: per-panel hide/show toggles (palette left, properties right) + a focus/presentation mode that hides header+palette+properties and requests browser fullscreen, with a floating exit affordance and Esc restore. Fullscreen API requires a user gesture (button click qualifies) and can be denied — focus mode must degrade gracefully to chrome-hiding only.

## Acceptance Criteria

### Agent
- [x] Toggle buttons exist for the left palette and the right properties panel; each click hides/shows only its own panel and the canvas reflows to use the freed width (no dead whitespace band where the panel was) — *suite leg t245-view-chrome probes vc1 (canvasW 660→880) and vc3 (→980); grid track dropped via body.vc-no-* main rules, not just display:none*
- [x] Panel visibility persists across reload via the existing editor-settings persistence mechanism (same store the ⚙ Settings page uses) — *paletteHidden/propsHidden added to aefViewPrefs with typeof-boolean validation; probe vc2 = still hidden after nav*
- [x] A focus-mode button hides header + palette + properties in one click and attempts `requestFullscreen` (failure tolerated — chrome-hiding still applies); a floating exit affordance is visible in focus mode and restores all chrome; Esc also exits (native fullscreen exit is detected and restores chrome) — *probe vc5/vc6; suite runs headless where requestFullscreen is DENIED (no user activation) — leg passing proves the graceful-degradation path; fullscreenchange listener restores chrome on browser-native exit*
- [x] Focus mode is transient: after exit + reload, chrome is back (focus state NOT persisted); per-panel hidden states ARE respected independently of focus mode — *probe vc7 (focus → reload → header/palette back); focusMode is a plain let, never written to localStorage*
- [x] With the properties panel hidden, selecting a node does not silently strand the operator: the properties panel auto-reveals (or an equivalent explicit affordance) so node editing remains reachable — *revealPropsForSelection() at onNodeClick plain-click, onEdgeClick, and palette-create; probe vc4 = real MouseEvent click on #g-nodes g reveals props and clears the pref*
- [x] G-010 standing suite extended with a view-chrome leg (toggle hides panel / focus hides all three / exit restores / persistence round-trip) and the full suite passes; full bridge test suite still green — *suite 5/5 legs PASS incl. new t245-view-chrome (8 probe states); bridge round-trip 37/37, geometry sweep 24 clean*

### Human
- [ ] [REVIEW] The view-chrome controls feel right
  **Steps:**
  1. Run `cd /opt/832-Workflow-designer && ls .playwright-mcp/t245-*.png` — screenshots exist for: panels visible, palette hidden, properties hidden, focus mode
  2. Open the served editor (Watchtower URL /designer or gallery server), click the palette and properties toggle buttons, then the focus-mode button; press Esc
  **Expected:** Toggles read clearly (obvious which panel they control, state visible), focus mode fills the screen with the diagram, the floating exit is findable without instruction, Esc gets you back to normal
  **If not:** Note which affordance was unclear or mispositioned — button glyphs/labels and the exit placement are cheap to change

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

# T-245 markers present in the editor source
# (markup button + JS wiring = exactly 2 in the HTML; the third reference lives in the suite file)
test "$(grep -c 'btn-focus-mode' src/aef-workflow-designer.html)" -ge 2
test "$(grep -c 'revealPropsForSelection' src/aef-workflow-designer.html)" -ge 4
test "$(grep -c 'vc-exit' src/aef-workflow-designer.html)" -ge 4
# Full standing editor-behavior suite (incl. new t245-view-chrome leg) must pass
out=$(node tools/_editor-behavior-verify-cdp.mjs 2>&1); python3 -c "import json,sys; v=json.loads(sys.argv[1]); assert v['pass'], [l['leg'] for l in v['legs'] if not l['pass']]; assert any(l['leg']=='t245-view-chrome' for l in v['legs'])" "$out"
# Visual verification artifacts exist
test -s .playwright-mcp/t245-all-visible.png && test -s .playwright-mcp/t245-palette-hidden.png && test -s .playwright-mcp/t245-props-hidden.png && test -s .playwright-mcp/t245-focus-mode.png

## Visual Verification

Element/viewport screenshots taken via the hermetic sidecar+CDP harness (isolated headless chromium, G-006-safe) and READ back:

- `.playwright-mcp/t245-all-visible.png` — baseline: ◧ ◨ ⛶ buttons in header beside +, all chrome present
- `.playwright-mcp/t245-palette-hidden.png` — palette gone, ◧ shows pressed (accent), diagram reflowed wider, no dead band
- `.playwright-mcp/t245-props-hidden.png` — properties gone, ◨ pressed, canvas widened right
- `.playwright-mcp/t245-focus-mode.png` — header/palette/properties all hidden, diagram fills viewport, floating "⛶ Exit focus" top-right (semi-transparent until hover)

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
**Rationale:** All six agent ACs verified with structural evidence — behaviors are probed through the real buttons (element clicks, not internal setters) in the standing G-010 suite, the four visual states were screenshotted and read, and no regression appeared anywhere in the bridge seam. The only open judgment is taste: button glyphs (◧ ◨ ⛶), pressed-state styling, and the floating exit's placement — all cheap to adjust if they read wrong.
**Evidence:**
- `tools/_editor-behavior-verify-cdp.mjs` 5/5 legs PASS incl. new `t245-view-chrome` (8 probe states: baseline / hide / persist-across-reload / props-hide / auto-reveal-on-selection / focus / exit-restore / focus-transient-after-reload)
- `tests/run-bridge-tests.sh`: 37/37 round-trip, geometry sweep 24 clean — the feature is pure view chrome, zero document/seam surface
- Screenshots read: `.playwright-mcp/t245-{all-visible,palette-hidden,props-hidden,focus-mode}.png` — no dead band where panels were, diagram reflows via the T-043 fit, exit affordance visible in focus mode
- Persistence uses the existing `aefViewPrefs` localStorage store (same seam as T-108 view prefs — editor-local, never enters the document)

## Decisions

### 2026-07-23 — Focus mode transience
- **Chose:** Focus mode is a transient presentation state (plain runtime flag), never persisted; per-panel hidden states ARE persisted (aefViewPrefs).
- **Why:** Reloading into a chrome-less editor with no visible way back is a stranding hazard; a presentation state is an intent for *this* viewing, not a preference. Panel visibility, by contrast, is a genuine workspace preference.
- **Rejected:** Persisting focus mode (stranding risk outweighs convenience); persisting nothing (operator would re-hide panels every session).

### 2026-07-23 — Auto-reveal semantics for hidden properties panel
- **Chose:** An explicit click-selection (node, edge, palette-create) un-hides the properties panel by clearing the pref (persisted); auto-reveal is suppressed in focus mode.
- **Why:** Selecting something is an unambiguous "I want to edit this" signal — the panel hidden at that moment is a dead end (same dead-affordance class as AEF's T-2613 bare-catch observation). Suppressed in focus mode because presentation intent wins there and exit restores everything anyway.
- **Rejected:** One-shot reveal without clearing the pref (panel would vanish again on next reload mid-editing — surprising); reveal keyed inside renderProperties() (fires on every render, would make hiding impossible while anything is selected).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-23T09:41:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-245-canvas-view-chrome-controls-paletteprope.md
- **Context:** Initial task creation

### 2026-07-23T09:51:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-161275f0
- **Timestamp:** 2026-07-27T21:20:21Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
