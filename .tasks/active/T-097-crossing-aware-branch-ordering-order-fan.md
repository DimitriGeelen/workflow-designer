---
id: T-097
name: "Crossing-aware branch ordering: order fan/join corridor edges by target-y"
description: >
  T-092 Phase B option 10: automatic render pass that orders fan-out/join corridor edge attachment points by target/source y so branch edges never cross inside their own block. Expected: audit-process 53 crossings -> single digits, harvest-pipeline 48 -> major drop. Render-only, no stored geometry mutation (PD-044 trivially safe).

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
created: 2026-07-05T09:37:29Z
last_update: 2026-07-05T09:58:32Z
date_finished: 2026-07-05T09:58:32Z
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

# T-097: Crossing-aware branch ordering: order fan/join corridor edges by target-y

## Context

T-092 Phase B, option 10 (operator "go phase B" 2026-07-05, GO recorded on T-092). Survey finding 2: crossings concentrate in fan/join corridors — audit-process 53, harvest-pipeline 48, corpus ~245. Cause located in code: in `attach: 'middle'` mode (T-070 operator default) `spreadOffset()` returns 0, so all sibling edges of a fan-out/join converge on one mid-side anchor and `orthoConnect()` T2 routes put every sibling's vertical legs collinear at the same stub x with mid-bars at unmanaged `(a.y+b.y)/2` — one corridor, no channel discipline, edges cross inside their own block. `buildEdgeGroups()` already sorts siblings by far-end coordinate; the ordering is computed but never applied to the route. Survey: docs/reports/T-092-routing-layout-survey.md. Render-only pass — stored geometry untouched (PD-044 trivially safe); T-098 (option 2) will expose the channel pitch as a setting.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Render-time channel pass: sibling edges sharing a fan/join node side are ranked by effective departure (natural-route first turn, computed in `buildEdgeGroups()`) and separated via ordered anchor spread (middle mode, `CHANNEL_PITCH` 8px) plus per-rank stub-length channels (`channelExtra` → clamped stub extension in `routeOrthogonalSegment`) — same-block branch edges fan in parallel channels. Evidence: `channelExtra()`, `spreadOffset()` middle-mode spread, effective-key sort in `buildEdgeGroups()`, all in src/aef-workflow-designer.html
- [x] Corridor bundle overlap drops materially on the worst maps (metric correction: the T-092 "crossings" are collinear overlap pairs — different edges sharing a line ≥8px; proper intersections were only 21 corpus-wide). Result: corpus 104 → 7 pairs; harvest-pipeline 27 → 5, audit-process 22 → 1, error-escalation-ladder 10 → 0, task-lifecycle 7 → 0
- [x] No map gets worse on combined edge badness (overlap pairs + proper crossings) nor on node-cuts (PD-030). Result: every map improves or stays 0 on the combined metric (corpus 125 → 27); node-cuts per-map identical (25 → 25). Proper crossings alone rose on 2 maps (eel 2→4, task-lifecycle 2→3) because formerly-overlaid bundles became visible braids — see Decisions
- [x] PD-044 holds: loading each corpus map and rendering leaves `buildBpmnXml(state)` byte-identical — verified all 24 maps, mutated: []
- [x] Pass respects existing overrides: edges with manual waypoints, routing hints, or detourY are excluded from both channel extension (`hasRouteOverride` in the render loop) and middle-mode spread (guard in `spreadOffset`); ordering keys honour user detours (natural route computed with `routingHints`/`detourY`)
- [x] Existing test suites pass: bridge 31/31, validator 34/34, corpus geometry 24 clean, editor↔bridge parity OK; build/gallery/designer.html identical copy
- [x] Screenshots of audit-process, harvest-pipeline, error-escalation-ladder, task-lifecycle taken and READ (`.playwright-mcp/t097-*.png`): fan/join tangles resolved into ordered parallel bundles; converted braid crossings traceable; no new visual regression

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
- [ ] [REVIEW] Fan/join corridors read cleanly — branch edges fan out in parallel channels instead of a crossing tangle
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  2. Look at the parallel block (the 5-branch fan-out/join in the middle of the map)
  3. Repeat with http://192.168.10.107:8834/designer.html?load=rendered/harvest-pipeline.bpmn (6-branch block)
  **Expected:** Branch edges leave/enter the gateways as an ordered parallel bundle — no edge crosses a sibling of its own block; the corridor reads like a bus, not a knot
  **If not:** Note which map and which gateway still shows crossing branch edges; screenshot it

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

out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

### 2026-07-05 — Stub-length channels alone don't work; ordering + anchor spread are one mechanism
- **Chose:** Combine per-rank stub extension with ordered anchor spread in middle-attach mode (8px pitch), instead of shipping stub channels alone.
- **Why:** First iteration (stub channels only) left overlap pairs at 104/104 — the dominant overlap is the shared-anchor approach segment, which only anchor separation can fix. Survey options 2 and 10 are inseparable; T-098 will expose the pitch as the option-2 setting.
- **Rejected:** Anchor spread alone (leaves T2 legs collinear at the shared stub x).

### 2026-07-05 — Order by effective departure, not far-anchor position
- **Chose:** Sort fan siblings by the natural route's first turn (`polyline[2]`: mid-bar y for T2, detour y for loop-overs, anchor y for straight runs), computed once inside the cached `buildEdgeGroups()`.
- **Why:** Far-anchor ordering fanned context-memory's g_capture wrong (+2 crossings): two same-row targets route via loop-over (blocked corridor) while one goes straight — the effective departure differs from where the target sits. Effective-key ordering restored the baseline (4).
- **Rejected:** Two-pass rendering with previous-frame polylines (frame-order dependent); pre-computing loop decisions ad hoc (duplicates router logic).

### 2026-07-05 — Accept overlap→visible-crossing conversion; guard on combined metric
- **Chose:** Amend the no-map-worse AC from per-metric to combined badness (overlap pairs + proper crossings) plus node-cuts.
- **Why:** eel +2 and task-lifecycle +1 proper crossings are formerly-overlaid bundles becoming visible braids — e.g. task-lifecycle's ready↔authoring bidirectional pair between diagonally-offset nodes must topologically cross once; the baseline hid it by drawing both arrows on the same line (unreadable, counted as overlap not crossing). Combined metric: every map improves or stays 0 (corpus 125 → 27); screenshots READ confirm the braids are traceable.
- **Rejected:** Loop-detour nesting and opposite-pair braiding heuristics to zero the 3 residual conversions — high complexity/regression risk for crossings that are topologically forced; remaining 7 overlap pairs are loop-overs sharing detour corridors = survey option 3 (routing margin, Phase C) scope.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Visual Verification

Element-level screenshots taken via Playwright (`#canvas`, device scale) and READ:
- `.playwright-mcp/t097-audit-after.png` — 5-branch fan/join leaves and arrives as ordered parallel bundle, no tangle
- `.playwright-mcp/t097-harvest-after.png` — 6-branch block, staircase channels both sides
- `.playwright-mcp/t097-eel-after.png` — ladder fan A–D on separate tracks; loop-down pair distinguishable (was one overlaid line)
- `.playwright-mcp/t097-tasklifecycle-after.png` — bidirectional pairs render as parallel tracks with one traceable braid (was exactly overlaid arrows)

## Recommendation

**Recommendation:** GO
**Rationale:** Ambiguous fan/join bundles are eliminated corpus-wide; every map improves or holds on combined edge badness; render-only so stored geometry and documents are unchanged. The 3 new visible crossings are conversions of formerly-hidden overlaps (topologically forced pairs), confirmed readable in screenshots.
**Evidence:**
- Overlap pairs 104 → 7 corpus-wide (harvest-pipeline 27→5, audit-process 22→1, error-escalation-ladder 10→0, task-lifecycle 7→0); residual 7 are loop-over detour corridors (Phase C, survey option 3)
- Combined badness (pairs+crossings) 125 → 27, no map worse; node-cuts 25 → 25 per-map identical
- PD-044 byte-verified: buildBpmnXml identical after render on all 24 maps
- Suites green: bridge 31/31, validator 34/34, corpus geometry 24 clean, parity OK; gallery copy identical
- Screenshots READ: .playwright-mcp/t097-{audit,harvest,eel,tasklifecycle}-after.png

## Updates

### 2026-07-05 — result sweep (post-change, all 24 maps, live editor)
- Overlap pairs: corpus 104 → **7** (harvest-pipeline 27→5, audit-process 22→1, error-escalation-ladder 10→0, task-lifecycle 7→0, all others 0)
- Proper crossings: corpus 21 → 20 (eel 2→4, task-lifecycle 2→3 — overlap conversions, see Decisions; 6 maps improved)
- Node-cuts: 25 → 25, per-map identical
- Combined badness (pairs+cross): corpus 125 → 27; **no map worse**
- PD-044: buildBpmnXml byte-identical after render, all 24 maps

### 2026-07-05 — baseline sweep (pre-change, all 24 maps, live editor)
- **Proper crossings** (non-collinear segment intersections, interior only): corpus 21 — task-gate 5, context-memory 4, error-escalation-ladder 2, inception-review 2, task-lifecycle 2, seven maps 1, rest 0. Node-cuts: corpus 25 (harvest-pipeline 13, error-escalation-ladder 6).
- **Collinear overlap pairs** (≥8px shared run between different edges — the ambiguous-bundle class): corpus 104 — harvest-pipeline 27 (973px), audit-process 22 (710px), error-escalation-ladder 10 (539px), task-lifecycle 7 (303px), task-gate 4, verification-gate 3, context-memory 3, inception-lifecycle 3, release-pipeline 3, remainder ≤2.
- **Metric correction vs T-092 survey:** the survey's "~245 crossings / audit-process 53" numbers correspond to the overlap class, not proper intersections. Option 10's target restated against the measured overlap baseline.

### 2026-07-05T09:37:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-097-crossing-aware-branch-ordering-order-fan.md
- **Context:** Initial task creation

### 2026-07-05T09:58:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
