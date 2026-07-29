---
id: T-085
name: "View density + label visibility/size controls in editor settings"
description: >
  Operator request 2026-07-04 (forwarded scoping message): extend the T-075 settings page with view controls. (1) Density tight/normal/wide scaling node-to-node spacing inside lanes (scales ROW_PITCH/tidy-rows from T-079; default lane heights possibly later slice). (2) Show/hide checkboxes per label class: lane labels, node id sub-labels, edge labels, pool header. (3) Global label size S/M/L affecting lane + node labels. Config in localStorage first slice (per-workflow YAML override = later slice). Companion to T-084 label-fit ladder.

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
created: 2026-07-04T14:04:33Z
last_update: 2026-07-04T21:54:23Z
date_finished: 2026-07-04T21:52:46Z
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

# T-085: View density + label visibility/size controls in editor settings

## Context

Operator scoping message 2026-07-04: extend the T-075 settings modal with view controls. Slice 1 (this task): (1) density tight/normal/wide scaling the T-079 row-pitch heuristic (`ROW_PITCH` consumers: `laneRowYs`, `tidyLane`, drag row-snap, lane inspector row count); (2) show/hide per label class — lane labels, node id badges, edge labels, pool-header title — rendering-only, geometry unchanged; (3) global label size S/M/L for node + lane labels, with all measured passes (T-084 lane-fit ladder, T-082 edge-label placement, T-083 badge halos) re-measuring at the new size. Config in localStorage (per-workflow YAML override = later slice). Extends T-084's `labelPrefs`/"Labels" settings-section pattern.

## Acceptance Criteria

### Agent
- [x] Density pref (`viewPrefs.density`: tight/normal/wide, default normal, localStorage `aefViewPrefs`) scales the effective row pitch (~72/96/125 model px); `laneRowYs`, `tidyLane`, drag row-snap, and the lane inspector row count all follow the scaled pitch. Browser evidence: a tall lane reports more rows at tight than at wide; tidy of the same lane yields different row Ys per density. Stored node geometry is NOT mutated by changing the pref alone.
      Evidence: rowPitch() = ROW_PITCH x {0.75,1,1.3}; all consumers route through laneRowYs. Corpus sweep: tight > wide row count on 67/67 lanes. context-memory project lane (250px): 3 rows tight vs 2 rows wide; tidyLane moved 6 nodes to visibly different Ys per density (screenshots). geomStable=true after setViewPref tight->normal round-trip.
- [x] Per-class visibility toggles (default all shown, persisted): lane labels, node id badges, edge labels (text + data-elr halo), pool-header title. Toggling off removes only those text/halo elements on re-render — lane header band, pool band, and all geometry unchanged. Browser evidence: selector counts drop to 0 for the hidden class and return on re-enable; other classes unaffected.
      Evidence: context-memory baseline lane 6/pool 1/ids 12/edge 6+6 halos; each toggle-off zeroed exactly its own class (edge toggle also removed all 6 data-elr halos), others untouched; full restore matched baseline.
- [x] Global label size S/M/L (default M, persisted) scales `.node-label` and lane-label font size via a root attribute + CSS; render passes re-run so lane-fit ladder, edge-label placement, and badge halos are re-measured at the new size (halos still contain their text bboxes at S and L).
      Evidence: computed .node-label font-size 10px/11px/12.5px at S/M/L (svg[data-lsize] CSS); at size L all 12/12 badge halos still contain their text bboxes. Lane-fit ladder shrink steps switched to inline style so they beat the size CSS (see Decisions + T-088).
- [x] Settings modal gains the new controls; `syncSettingsUI` syncs all of them; listeners apply immediately (re-render); Reset restores density normal, all classes shown, size M, laneFit on.
      Evidence: new "View" section (density select) + extended "Labels" section (size select + 4 checkboxes); sync/listeners/reset wired symmetrically with the T-075 pattern; screenshot t085-settings-modal.png read and inspected.
- [x] Rendering-only for visibility/size: editor XML build stability x1===x2 (with renderAll interleaved) with labels hidden and size L active; zero serialization-function lines in the diff.
      Evidence: STABLE on context-memory with showIds/showEdge off + size L; diff touches only render/CSS/settings code, no buildBpmnXml/parseBpmnXml lines.
- [x] All suites green (bridge 31, validator 34, parity x6, geometry sweep 24 clean); gallery copy synced (diff -q clean).
      Evidence: bridge 31/31, validator 34/34, parity OK, geometry sweep 24 clean; gallery synced. Corpus lane-label invariant re-verified post-change: 0/67 overflow (25 wrapped / 1 ellipsized / 0 shrunk under now-honest shrink rendering).
- [x] Visual verification: element screenshots — settings modal with new controls, a map with id badges + edge labels hidden, same map at size L, a tidied lane at tight vs wide — read and inspected; no clipped/overlapping artifacts introduced.
      Evidence: .playwright-mcp/t085-{settings-modal,labels-hidden,size-l,tidy-tight,tidy-wide}.png, all read. One cosmetic fix during inspection: density select clipped its option text -> select.settings-num width rule. Known interplay documented: size L amplifies the pre-existing node-label rect overflow (T-087, operator-raised).

### Human
- [ ] [REVIEW] View controls feel right on real maps
  **Steps:**
  1. Open http://192.168.10.107:8834/ and open any dense map (e.g. verification-gate)
  2. Open Settings — try density tight/normal/wide, hide/show each label class, switch label size S/M/L
  3. Reload the page — confirm your choices stuck
  **Expected:** Diagram stays stable while toggling (nothing jumps except the toggled labels); size L stays legible without labels colliding badly; settings persist across reload
  **If not:** Note the control + map; screenshot the spot

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

grep -q "let viewPrefs" src/aef-workflow-designer.html
grep -q "function rowPitch" src/aef-workflow-designer.html
grep -q "data-lsize" src/aef-workflow-designer.html
grep -q "set-label-size" src/aef-workflow-designer.html
grep -q "set-show-edge" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305)
python3 tests/test_editor_bridge_structured_parity.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
test -f .playwright-mcp/t085-settings-modal.png
test -f .playwright-mcp/t085-labels-hidden.png
test -f .playwright-mcp/t085-size-l.png
test -f .playwright-mcp/t085-tidy-tight.png
test -f .playwright-mcp/t085-tidy-wide.png

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

### 2026-07-04 — Density scales the row-pitch heuristic, never stored geometry
- **Chose:** `viewPrefs.density` scales `rowPitch()` consumed by laneRowYs (and thus tidy, drag row-snap, lane inspector). Changing the pref moves nothing; tidy remains the explicit, human-triggered mutation that adopts the new pitch.
- **Why:** A view preference that silently re-layouts the document would violate the render-only seam (same discipline as T-084's rejected lane auto-grow) and make the toggle destructive.
- **Rejected:** Re-layout on density change (mutates document from a settings toggle); scaling default lane heights (deferred later slice per operator scoping).

### 2026-07-04 — Visibility hides text, never bands
- **Chose:** Toggles remove only text/halo elements (lane label text, id badge text, edge label + data-elr halo, pool title). Lane header band and pool band always render.
- **Why:** The bands are interaction affordances (lane click target, resize grip anchor) and structural landmarks; hiding them would change hit-geometry, not just ink.
- **Rejected:** Collapsing the 60px lane header / 32px pool header when hidden — that is geometry, shifts every lane, and belongs to a layout feature, not a label toggle.

### 2026-07-04 — Label size via CSS keyed off svg[data-lsize]; ladder steps moved to inline style
- **Chose:** S/M/L as CSS rules on a root data attribute; the lane-fit ladder's explicit shrink steps switched from font-size ATTRIBUTE to inline STYLE so measured shrink always beats both `.lane-label` and the size rules.
- **Why:** SVG presentation attributes lose to any CSS rule — probe confirmed a `font-size="8px"` attribute computes to 10px under `.lane-label` while `style="font-size:8px"` computes to 8px. This also uncovered that T-084's shrink tier had been a silent no-op (registered as T-088).
- **Rejected:** Per-element font-size attributes for the size pref (defeated by class CSS); duplicating three sized class variants (rule explosion).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Visual Verification

Screenshots in .playwright-mcp/ (element capture, read and inspected):
- t085-settings-modal.png — View section (density select) + extended Labels section (size select, 4 visibility checkboxes); no clipping after the select-width fix
- t085-labels-hidden.png — context-memory with id badges + edge labels hidden: visibly calmer, lane/pool labels and geometry untouched
- t085-size-l.png — same map at size L: labels legible, badge halos re-measured and intact (also shows the pre-existing T-087 node-label overflow, amplified at L)
- t085-tidy-tight.png / t085-tidy-wide.png — project lane (250px) tidied onto 3 rows at tight vs 2 rows at wide; 6 nodes moved in each case

## Recommendation

**Recommendation:** GO
**Rationale:** The full operator scoping slice is delivered: density scaling for tidy/snap/inspector, per-class label visibility, global S/M/L label size — all render-only, persisted editor-locally, integrated into the existing settings modal, and verified by measurement across the 24-map corpus.
**Evidence:**
- Visibility: each class zeroes and restores independently (context-memory counts)
- Size: computed 10/11/12.5px; 12/12 badge halos contain text at L; lane-fit invariant re-verified 0/67 overflow corpus-wide
- Density: tight > wide rows on 67/67 lanes; tidy adopts the pitch (3 vs 2 rows, screenshots); stored geometry provably untouched
- XML build STABLE with labels hidden + size L; suites: bridge 31/31, validator 34/34, parity OK, geometry 24 clean
- Bonus find: T-084's shrink tier was a silent no-op (CSS beats presentation attrs) — fixed here via inline style, RCA tracked as T-088

## Updates

### 2026-07-04T14:04:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-085-view-density--label-visibilitysize-contr.md
- **Context:** Initial task creation

### 2026-07-04T21:37:12Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04T21:52:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4c0b2e37
- **Timestamp:** 2026-07-29T13:13:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **cross-project-blast** (medium) — Cross-project or cross-repo change
     - matched: `all consumers`
