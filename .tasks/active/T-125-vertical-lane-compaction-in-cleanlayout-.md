---
id: T-125
name: "Vertical lane-compaction in cleanLayout: fit each lane to its content height
  and remove empty inter-lane bands (the dominant rule from operator correction pairs
  1-3)"
description: >
  Vertical lane-compaction in cleanLayout: fit each lane to its content height and
  remove empty inter-lane bands (the dominant rule from operator correction pairs
  1-3)

status: captured
workflow_type: build
owner: human
horizon: later
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-06T09:06:43Z
last_update: 2026-08-23T10:24:08Z
date_finished:
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
  - ts: '2026-08-16T12:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:32:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 4
      F3: 2
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=4 
      (prose:routing-structural); F3=2 (prose:seam-namespace); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/check-corpus-geometry.sh,tests/run-bridge-tests.sh,tests/test_t125_lane_compaction.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-125: Vertical lane-compaction in cleanLayout: fit each lane to its content height and remove empty inter-lane bands (the dominant rule from operator correction pairs 1-3)

## Context

Track-B rule #1 from the T-122 operator correction pairs (see T-122 ## Decisions +
## Correction pairs). Pairs 1–3 (task-lifecycle, promotion-pipeline, arc-lifecycle)
share one dominant delta: the human halves the diagram height by shrinking every
lane to fit its content — my auto-layout gives lanes large content-independent
heights and parks rows at lane edges, producing empty inter-lane bands and ~450px
cross-lane verticals. Mechanism identified in Pair 3: `laneHeight = contentExtent
+ padding`, place the row within the fitted lane. Node x-positions unchanged in
all three pairs — this rule is vertical-only.

Scope guard (T-122 RCA): this is a cleanLayout EDITOR rule only — no re-bake, no
writes to examples/*.workflow.yaml or rendered/ (the clobber class cannot recur
under this task). Baking the compacted layouts into the corpus is T-101's call,
operator-sequenced.

## Acceptance Criteria

### Agent
- [x] Lane-compaction pass in cleanLayout: after the pass, each lane's height fits
      its content extent plus bounded padding (no content-independent uniform or
      inflated lane heights); node rows sit within the fitted lane, not parked at a
      far lane edge.
- [x] Empty inter-lane bands removed: lanes stack with a bounded inter-lane gap;
      on the three correction-pair maps (task-lifecycle, promotion-pipeline,
      arc-lifecycle) total diagram height after Clean is measurably reduced vs the
      pre-rule Clean output, and max cross-lane edge vertical span shrinks.
- [x] Vertical-only: node x-positions are unchanged by the compaction pass
      (matches all three correction pairs).
- [x] Guarded corpus-wide: headless measurement over all 24 corpus maps shows no
      new node-cuts, no new lane-band straddles, no new node overlaps vs baseline;
      corpus geometry sweep stays clean.
- [x] Regression leg: compaction assertions land in the bridge-suite (headless
      harness leg), full suite green.
- [x] No corpus writes: diff touches src/ + tests/ + tools/ harness only — zero
      changes under examples/ and rendered/ (T-122 clobber guard); zero seam
      surface (no aef:* / BPMN-emit / MANIFEST changes).

### Human
- [x] [REVIEW] Compacted layouts match your correction taste (pairs 1–3)
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
     and run Clean layout (toolbar) — compare against your hand-corrected version
     (your image #9): AGENT row snug under FRAMEWORK, no empty band
  2. Repeat for ?load=rendered/promotion-pipeline.bpmn and
     ?load=rendered/arc-lifecycle.bpmn — each should come out roughly half the
     old auto-height, rows inside fitted lanes
  **Expected:** No giant empty lane bands; cross-lane edges are short hops; nothing
  feels cramped (padding still breathes)
  **If not:** Note which map and which lane is still too deep/too tight — the
  padding and gap constants are single knobs

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
         1. Run `bin/fw reviewer T-125`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-125 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# T-125 lane compaction: pass present in src, harness + suite leg registered, 24-map sweep green.
grep -q 'compactLanesFit' src/aef-workflow-designer.html
grep -q 'test_t125_lane_compaction' tests/run-bridge-tests.sh
# 7-leg 24-map CDP harness via the pytest wrapper (L-387-safe: wrapper captures output).
python3 tests/test_t125_lane_compaction.py
# T-122 clobber guard: this task never writes the corpus (drift predating 2026-07-28 excluded).
bash tests/check-corpus-geometry.sh

## Visual Verification

- Three pair-map post-Clean screenshots (canvas-level, dark theme), READ 2026-07-28:
  task-lifecycle / promotion-pipeline / arc-lifecycle all render with lanes hugging
  content, rows inside fitted bands, cross-lane edges as short hops, no empty
  inter-lane bands, no clipped nodes or labels. Promotion-pipeline's "Warn early
  promotion" satellite sits roughly inline (Pair 2's secondary delta). Published:
  http://192.168.10.107:8834/t125-task-lifecycle-clean.png
  http://192.168.10.107:8834/t125-promotion-pipeline-clean.png
  http://192.168.10.107:8834/t125-arc-lifecycle-clean.png

## Decisions

### 2026-07-28 — Fit mechanism: canonical row-line solver, not extent+pad
- **Chose:** compactLanesFit solves for lane height h and line index i0 such that
  non-stack rows land exactly ON laneRowYs' derived grid (round(h/96)===n, pitch
  h/n minimal, 12px containment of fixed per-row overhangs incl. stacks + below-
  shape labels); stacks ride their nearest row rigidly.
- **Why:** tidyLane snaps nodes to a grid DERIVED from lane.height — a naive
  extent+pad fit re-grids every pass and 2-cycles (measured 16/24 maps never
  reached the bake fixpoint); a coarse 96-multiple quantization inflated trim
  maps (arc-lifecycle +26%). The solver output is an exact fixpoint of the grid
  by construction: corpus converges in ≤3 iterations, total height 76% of
  baseline, pair maps 61–79%.
- **Rejected:** extent+pad fit (diverges); ROW_PITCH-multiple quantization
  (inflates); loosening tidyLane's snap to a tolerance (regresses gross-import
  tidying, larger blast radius).

### 2026-07-28 — Empty lanes collapse to a slim band (80px)
- **Chose:** lanes with zero nodes shrink to min(height, 80).
- **Why:** Pair 2's "tall empty band" class; 80 stays visible/labeled/resizable.
- **Rejected:** leaving empty lanes untouched (keeps dead vertical space Clean
  exists to remove); deleting them (structure is the operator's call).

### 2026-07-28 — Per-lane measure-after-move revert
- **Chose:** a lane whose placement would add any node intersection reverts
  wholesale (positions + height untouched).
- **Why:** PD-030 pattern; re-pitching rows to h/n can theoretically squeeze a
  satellite into an attached stack — reverted lanes are trivially stable.

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-06T09:06:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-125-vertical-lane-compaction-in-cleanlayout-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2999d4c4
- **Timestamp:** 2026-07-29T13:13:38Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
### 2026-07-27T22:11:53Z — status-update [task-update-agent]
- **Change:** owner: agent → human

### 2026-08-23T10:24:08Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)
