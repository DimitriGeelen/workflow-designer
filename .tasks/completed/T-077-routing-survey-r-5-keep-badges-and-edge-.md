---
id: T-077
name: "Routing survey R-5: keep badges and edge labels out of edge channels"
description: >
  Survey finding R-5 (docs/reports/T-041-routing-readability-survey.md): node badges
  and edge labels collide with edge channels in dense areas. Detect label/edge overlap
  on the rendered polylines and nudge labels to free space. Render-only.

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
created: 2026-07-04T10:20:20Z
last_update: '2026-08-16T12:33:35Z'
date_finished: 2026-07-04T11:09:02Z
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
  - ts: '2026-08-16T12:33:35Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-077: Routing survey R-5: keep badges and edge labels out of edge channels

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

**Rescoped in from T-076 (2026-07-04):** the survey's healing-loop example ("advisory drop passes through the gateway's own label" — `Human acts on the advice?`, edges e_04/e_06 on rendered/healing-loop.bpmn) is structurally a label-placement problem, not routing: an S-anchor and the below-label are both centred on the node's centre-x, so every vertical S-exit/S-entry crosses its own label text. Candidate fixes live on the label side (offset the label sideways when an S-anchor edge exists, and/or a backing halo per survey R-1). T-076's Decisions section has the full rationale.

**Slice 1 (this task):** node-adjacent text vs edge channels — a render post-pass that detects rendered edge segments crossing a label-below node's text band and relocates that node's name+id block to the free side of the shape. Fixes the rescoped healing-loop symptom. Edge-label placement (the R-1 halo/offset for text ON edges) stays out of scope — file separately if survey evidence warrants.

## Acceptance Criteria

### Agent
- [x] A post-routing label pass relocates the below-shape name+id block of label-below nodes to the side of the shape when a rendered edge segment crosses the text band — evidence: `adjustLabelPlacements()` runs at end of renderNodes; placement is SELF-VERIFYING: it applies a candidate side, measures the real getBBox against polylines and node boxes, and keeps a side only when perfectly clean, else restores the default (first estimated-width version moved labels onto other edges — caught by the sweep, replaced by measure-after-move)
- [x] The rescoped healing-loop symptom is gone: "Human acts on the advice?" + hum_1_human relocated left of the diamond (anchor 'end' at x≈741), zero bbox/edge overlaps for that label; e_04/e_06 own-label hits eliminated (healing-loop 11→4 total, remaining 4 are pre-existing edge-label touches) — screenshot t077-hl-advice-after.png READ per visual protocol; bonus: "Advisory only" end-event label moved right of its circle
- [x] Corpus sweep (all 20 rendered maps, real getBBox vs segments, vs HEAD baseline): total overlaps 444 → 381 (−14%), **zero new hits** across all maps, every changed map strictly reduced (healing-loop 11→4, cross-host-dispatch 22→12, harvest 108→93, error-escalation 80→73), zero page errors
- [x] Render-only proven: `buildBpmnXml(state)` byte-identical before/after on healing-loop (10840 = 10840 bytes)
- [x] Bridge suite 31/31; geometry sweep 24 clean

### Human
- [x] [REVIEW] Relocated labels read naturally on the live gallery
  **Steps:**
  1. Open http://192.168.10.107:8834/ and open the healing-loop map
  2. Find the "Human acts on the advice?" gateway — its label should sit beside the diamond, clear of the vertical edge below it
  3. Skim two or three other maps (task-lifecycle, audit-process) for gateway/event labels that look awkwardly placed or orphaned from their shape
  **Expected:** Labels beside shapes still read as belonging to them; no label sits on top of an edge line or another node
  **If not:** Screenshot the awkward label and name the map/node

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

grep -q "adjustLabelPlacements" src/aef-workflow-designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/.t077-check.js && node --check /tmp/.t077-check.js
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
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

### 2026-07-04 — measure-after-move instead of estimated-width scoring
- **Chose:** The label pass applies a candidate placement, measures the REAL rendered getBBox against polylines/node boxes, and keeps the side only when perfectly clean; otherwise restores the default below placement.
- **Why:** The first version scored candidates with estimated character widths (6px/char sans, 5.4 mono); real font metrics diverged enough that "better" sides landed labels on other edges — the bbox corpus sweep showed net +5 overlaps on context-memory and 0-new-hit violations on 6 maps. Measuring the actual rendered result makes the decision metric identical to the verification metric.
- **Rejected:** Tighter width estimation (still an approximation, same failure class); accepting net-better-but-nonzero moves (trades one collision for another — a moved label on an edge reads worse than the familiar below placement).

### 2026-07-04 — relocate only to perfectly clean sides; contested-everywhere labels stay put
- **Chose:** If neither side of the shape is fully clear, keep the default below placement even though it is crossed.
- **Why:** Status quo is the baseline the operator already reads; a sideways label that still collides adds novelty without removing the defect. Guarantees the sweep invariant "zero new overlaps".
- **Rejected:** Least-bad-side placement (violates the invariant); multi-position search above/corners (more novelty for marginal gain — revisit only if the operator flags residuals).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Recommendation

**Recommendation:** GO

**Rationale:** The rescoped healing-loop symptom is fixed and the whole-corpus overlap count strictly improved with a hard zero-new-overlaps invariant — the pass only ever moves a label to a measured-clean position, so it cannot trade one collision for another. Render-only proven byte-identical; the estimated-width failure mode was caught by the sweep and replaced with measure-after-move before commit.

**Evidence:**
- healing-loop: "Human acts on the advice?" label now left of the diamond, clear of the e_04/e_06 vertical drops (.playwright-mcp/t077-hl-advice-after.png, READ); map total 11→4, remainder pre-existing
- 20-map bbox sweep vs HEAD: 444 → 381 overlaps, zero new hits, zero page errors
- buildBpmnXml byte-identical on healing-loop (10840 = 10840)
- tests/run-bridge-tests.sh: 31 passed, 0 failed; geometry sweep 24 clean
- Residual: overlaps where both sides are contested stay at status quo by design; edge-label (text-on-line) placement is out of slice-1 scope

## Updates

### 2026-07-04T10:20:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-077-routing-survey-r-5-keep-badges-and-edge-.md
- **Context:** Initial task creation

### 2026-07-04T11:02:40Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-04T11:09:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-761c49fd
- **Timestamp:** 2026-07-29T13:13:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
