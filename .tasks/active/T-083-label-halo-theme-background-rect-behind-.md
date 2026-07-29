---
id: T-083
name: "Label halo: theme-background rect behind edge labels and id badges"
description: >
  Paint a theme-surface halo rect (getBBox-sized, small padding) behind edge labels and node id badges so text stays legible when a line must pass under it. Cheap, catches the residue the placement pass (edge-label task) cannot move. From context-memory evaluation 2026-07-04.

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
created: 2026-07-04T13:52:07Z
last_update: 2026-07-04T15:23:12Z
date_finished: 2026-07-04T15:22:40Z
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

# T-083: Label halo: theme-background rect behind edge labels and id badges

## Context

T-082 gave edge labels a measured, bbox-hugging theme-background halo. Node id badges (`.node-id-badge`, e.g. "prj_2_add") still have none — when an edge segment or a strict-best edge label lands on one, both texts turn to mush (context-memory residual: "3+ applications -> graduate" x prj_2_add). This task paints a getBBox-sized halo rect behind every node id badge, inserted after all placement passes so it hugs the FINAL badge position.

## Acceptance Criteria

### Agent
- [x] Every rendered node id badge has a theme-background halo rect sized from its measured getBBox (+2px pad), inserted beneath the text in the same group, added AFTER the node-label and edge-label placement passes (so moved badges keep a correct halo)
      Evidence: `addIdBadgeHalos()` called last in renderNodes (after adjustLabelPlacements + adjustEdgeLabelPlacements); browser structural check: context-memory 12/12, verification-gate 15/15, task-lifecycle 15/15 badges have a preceding rect fully containing the text bbox.
- [x] Edge labels keep their T-082 measured halo (`data-elr` rect repositioned from final bbox, fill var(--bg)) — no regression
      Evidence: T-082 code path untouched; verification-gate screenshot shows edge labels on halo pads masking crossing lines.
- [x] Rendering-only change: editor XML build stays STABLE (buildBpmnXml(parse(X)) === X) on context-memory + 2 control maps; zero serialization lines in the diff
      Evidence: STABLE on context-memory, verification-gate, task-lifecycle with renderAll interleaved.
- [x] All suites green (bridge, validator, parity x6, geometry sweep); gallery copy synced (diff -q clean)
      Evidence: bridge 31/31, validator 34/34, parity 6/6 PASS, geometry sweep 24 clean, gallery-synced.
- [x] Visual verification: element screenshots at spots where lines/labels pass under badges (context-memory prj_2_add residual, verification-gate mid-chain), read and inspected — badge text legible over the halo, no oversized rect artifacts
      Evidence: .playwright-mcp/t083-badge-halo-zoom.png (prj_2_add wins the contested pixels over the "graduate" label tail; all prj_*/epi_* badges crisp), t083-verification-gate-midchain.png (frw_* badges legible, edge labels on pads; residual mush is node-label-vs-node-label, out of scope).

### Human
- [ ] [REVIEW] Badges and edge labels stay legible where lines must pass under them
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view context-memory
  2. Look at "3+ applications -> graduate" / prj_2_add and the verification-gate mid gateway chain
  **Expected:** Text sits on a small background pad that masks the line beneath; no large blank boxes
  **If not:** Note map + badge; screenshot the spot

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

grep -q "function addIdBadgeHalos" src/aef-workflow-designer.html
grep -q "addIdBadgeHalos();" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305)
python3 tests/test_editor_bridge_structured_parity.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
test -f .playwright-mcp/t083-badge-halo-zoom.png
test -f .playwright-mcp/t083-verification-gate-midchain.png

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

### 2026-07-04 — Badges win contested pixels (z-order by construction)
- **Chose:** Badge halos live in gNodes (above gEdges), so where a residual edge label still touches a badge, the badge's pad masks the label tail — one text fully legible instead of two texts mashed.
- **Why:** Id badges are the anchor for referencing nodes in reviews/YAML; they must always be readable. The clipped edge-label tail is the strict-best residue T-082 documented; density work (T-084/T-085) is the real fix for those corridors.
- **Rejected:** SVG paint-order/stroke halos on the text itself — heavier visual noise in the mono theme and inconsistent rendering across font stacks; a second placement pass for badges — badges must stay glued to their node, they cannot move.

## Visual Verification

Screenshots in .playwright-mcp/ (element capture, read and inspected):
- t083-badge-halo-zoom.png — context-memory: all prj_*/epi_* badges on crisp pads; the T-082 residual now renders badge-first
- t083-verification-gate-midchain.png — densest corridor: frw_* badges legible, edge labels on pads masking crossing lines, no rect artifacts

## Recommendation

**Recommendation:** GO
**Rationale:** Every id badge corpus-wide now sits on a measured theme-background pad, closing the "text turns to mush where a line must pass under it" class the placement pass cannot fix; render-only, zero serialization impact, all suites green.
**Evidence:**
- Structural browser check: 42/42 badges (3 maps) haloed with containing rects; round-trip STABLE x3
- Suites: bridge 31/31, validator 34/34, parity 6/6, geometry sweep 24 clean
- Screenshots above, read and inspected

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T13:52:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-083-label-halo-theme-background-rect-behind-.md
- **Context:** Initial task creation

### 2026-07-04T15:19:40Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04T15:22:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-38995700
- **Timestamp:** 2026-07-29T13:13:32Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
