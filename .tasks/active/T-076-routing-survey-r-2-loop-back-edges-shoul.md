---
id: T-076
name: "Routing survey R-2: loop-back edges should route around the periphery, not through the body corridor"
description: >
  Survey finding R-2 (docs/reports/T-041-routing-readability-survey.md): loop/detour edges cut through the diagram body. Route loop-backs around the content periphery (above/below all nodes in their x-range) with lane-clamp respected. Render-only, orthoLoopBack area.

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
created: 2026-07-04T10:20:19Z
last_update: 2026-07-04T11:02:07Z
date_finished: 2026-07-04T11:00:40Z
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

# T-076: Routing survey R-2: loop-back edges should route around the periphery, not through the body corridor

## Context

Survey R-2 (docs/reports/T-041-routing-readability-survey.md): loop-back cross-bars cut through the diagram body and label band. Root cause located in `orthoLoopBack()` (src/aef-workflow-designer.html ~2801): (a) detour bands are anchored to source/target *boxes* only — `belowMin = lowestBottom + 18` — but id badges/labels extend the visual footprint below the box (tasks ~+14px, events/gateways ~+28px), so the bar runs through text; (b) candidate Ys never extend beyond the src/tgt band, so when the corridor is crowded the scorer picks the least-bad body route instead of the content periphery; (c) `nodesIntersectingCorridor()` scores box crossings with a flat 20px margin, blind to the type-dependent label zone. Render-only fix: type-aware visual-bottom accounting plus periphery candidates (below/above ALL nodes overlapping the corridor x-range), lane-clamp respected, existing scoring keeps the choice.

## Acceptance Criteria

### Agent
- [x] `orthoLoopBack` computes detour bands from a type-aware visual bottom (`nodeVisualBottom`) that includes the label/badge zone (label-below types get a larger allowance than tasks), for source, target, AND path scoring — evidence: nodeVisualBottom() (tasks +16, events/gateways/links +30) feeds belowMin, loopPathCrossings, corridorSplit
- [x] Periphery candidates exist: a below-candidate clear of ALL nodes overlapping the corridor x-range and an above-candidate above them, clamped to the vertical union of the lanes the edge connects (lane-clamp respected; skipped when the band can't fit) — evidence: pBelow/pAbove candidates + laneA/laneB union clamp in orthoLoopBack
- [x] The task-lifecycle R-2 symptom is gone: "gate failed — rework" (e_12) rerouted from a mid-body bar at y=488 to the content periphery at y=652, rising into the target's E side — verified by element screenshots t076-before-tl-zoom.png / t076-after-tl-zoom.png, both READ per visual protocol. (healing-loop's "advisory drop through the gateway's own label" rescoped to T-077 — see Decisions: the drop and the label share the same centre-x by construction; no routing change can separate them, only label placement can)
- [x] Corpus regression sweep (all 20 rendered gallery maps, before/after vs HEAD baseline): git-commit-flow leg regression found and fixed via whole-path scoring; final state ≤ baseline everywhere (audit-process −1 label clash, others identical or equal-count reshuffles in the dense R-3 maps, confirmed visually neutral via t076-eel-*.png / t076-hp-*.png); zero page errors on all 20
- [x] Render-only proven: `buildBpmnXml(state)` byte-identical before/after on task-lifecycle (15126 = 15126 bytes), auto detourY never persisted
- [x] User-set `detourY` drag still honored and now clamps clear of source/target label text — trusted-input (real page.mouse) drag test: down-drag clamps at 670 (laneBot−12), up-drag clamps at 646 (label-aware belowMin; old code would have allowed 642, through the badge text); bridge suite 31/31

### Human
- [ ] [REVIEW] Loop-backs read as calm periphery detours on the live gallery
  **Steps:**
  1. Open http://192.168.10.107:8834/ and open the task-lifecycle map
  2. Follow the "gate failed — rework" return edge from "All gates pass?" back to "Perform the work" — it should swing below the content and re-enter from the right
  3. Spot-check a couple of dense maps (audit-process, git-commit-flow) for loops that cut through boxes or label text
  **Expected:** Loop cross-bars run around the content (above/below the nodes in their span), not through node labels or the mid-diagram band. (healing-loop's drop through its own gateway label is known and deferred to T-077 — label placement, not routing)
  **If not:** Note which map/edge still cuts through and screenshot it

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

grep -q "nodeVisualBottom" src/aef-workflow-designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/.t076-check.js && node --check /tmp/.t076-check.js
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "bridge round-trip: 31 passed, 0 failed"
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

### 2026-07-04 — healing-loop "advisory drop" symptom rescoped to T-077
- **Chose:** Treat the survey's second R-2 example (edge drop through "Human acts on the advice?" gateway's own label) as a label-placement problem, not a routing problem; moved to T-077's scope.
- **Why:** The S-anchor and the below-label are both centred on the node's centre-x by construction — every S-exit/S-entry on a label-below node crosses its own label. No detour choice can separate them; only moving the label (or a text halo) can.
- **Rejected:** Jogging the stub sideways around the label (ugly double-corner at every gateway exit); suppressing S anchors on label-below nodes (breaks topologically correct vertical flow).

### 2026-07-04 — whole-path scoring instead of bar-only corridor scoring
- **Chose:** Score loop candidates by `loopPathCrossings` (both vertical legs + horizontal bar, label-aware) instead of the old bar-only `nodesIntersectingCorridor`.
- **Why:** Bar-only scoring let candidates win whose legs plowed through boxes: first sweep showed git-commit-flow e13 flipping to an "empty" above-band whose legs crossed two tasks (0→2 box crossings). Whole-path scoring restored the tight below detour and also removed a pre-existing label clash on audit-process.
- **Rejected:** Post-hoc validation with polylineCrossesNodes + fallback (adds a second code path; scoring all three segments up front is one mechanism).

### 2026-07-04 — interior-band penalty + periphery candidates, long-backhaul trigger at 300px
- **Chose:** Add periphery candidates (clear of ALL corridor nodes) and a +10 interior penalty when corridor content sits on both sides of a candidate bar; reroute backward edges (span > 300px) via loop-back only when their natural mid-bar is interior.
- **Why:** R-2's core: bars that touch nothing still read as body cuts when content flanks both sides. The 300px threshold plus interior check keeps short backhauls and already-peripheral bars on their natural direct routes (19 of 20 corpus maps unchanged).
- **Rejected:** Rerouting all backward edges unconditionally (would churn many fine renders); scoring edge-to-edge crossings (R-3 channel-separation territory, separate survey finding).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Recommendation

**Recommendation:** GO

**Rationale:** The named R-2 body-cut is gone and a 20-map before/after corpus sweep shows the change is equal or better everywhere — the one regression the new scoring initially introduced (git-commit-flow loop legs through two task boxes) was caught by the sweep and fixed via whole-path scoring before commit. Render-only is proven byte-identical, so zero bridge-seam exposure.

**Evidence:**
- task-lifecycle e_12 rerouted from mid-body bar y=488 to content periphery y=652 (.playwright-mcp/t076-before-tl-zoom.png vs t076-after-tl-zoom.png, both READ per visual protocol)
- 20-map sweep vs HEAD baseline: audit-process −1 label clash, git-commit-flow clean after fix, all others identical or visually-neutral equal-count reshuffles (t076-eel-*.png, t076-hp-*.png); zero page errors
- buildBpmnXml(state) byte-identical before/after on task-lifecycle (15126 = 15126)
- tests/run-bridge-tests.sh: bridge round-trip 31 passed, 0 failed; geometry sweep 24 clean
- Trusted-input (real page.mouse) detourY drag: down-clamp 670 (laneBot−12), up-clamp 646 (label-aware floor — old code allowed 642, through badge text)
- Residual explicitly scoped out: healing-loop own-label drop → T-077 (label placement); dense-map bundle clutter → survey R-3

## Updates

### 2026-07-04T10:20:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-076-routing-survey-r-2-loop-back-edges-shoul.md
- **Context:** Initial task creation

### 2026-07-04T10:43:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-04T10:43:06Z — status-update [task-update-agent]
- **Change:** horizon: now → now

### 2026-07-04T11:00:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cbb0583f
- **Timestamp:** 2026-07-27T21:20:09Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **cross-project-blast** (medium) — Cross-project or cross-repo change
     - matched: `ALL nodes`
