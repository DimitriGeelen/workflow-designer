---
id: T-079
name: "Adaptive alignment rows: sub-row snap lines in tall lanes + row-mate middle
  alignment"
description: >
  Operator feedback on T-074 snapping (2026-07-04, revisit-due-scan screenshot): single
  lane-centre snap line is too coarse in tall lanes — add sub-row alignment lines
  (~every 1.5x default box height) in lanes tall enough to hold multiple rows, and
  strengthen align-to-row-mates (snap dragged element's middle to the shared midline
  of nodes already forming a row). Operator asked for design playback before build
  — see T-078-era conversation.

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
created: 2026-07-04T11:22:30Z
last_update: '2026-08-16T12:33:35Z'
date_finished: 2026-07-04T12:55:01Z
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
---

# T-079: Adaptive alignment rows: sub-row snap lines in tall lanes + row-mate middle alignment

## Context

Operator feedback on T-074 snapping (2026-07-04, revisit-due-scan screenshot): a tall lane offers only ONE Y-snap line (lane centre) plus neighbour centres within 400px horizontal range — useless for lanes holding 2-3 natural rows. Design played back to operator 2026-07-04; **operator confirmed "1a 2b"**:

- **(1a) Sub-row snap lines, even division:** when a lane can hold 2+ rows, replace its single centre line with N evenly-spaced row lines; N from the operator's 1.5×-default-box-height rule (task h=64 → ~96px pitch → N = max(1, round(laneHeight/96))); lines at laneTop + (i+0.5)*laneHeight/N. Short lanes keep the single centre line. Dashed guide rendering as in T-074.
- **Row-mate middle alignment, whole lane:** drop the 400px horizontal limit for same-lane Y-candidates — dragged node's middle snaps to the shared midline of an existing row anywhere in the lane. Real rows outrank the theoretical sub-row lines when both are within tolerance.
- **(2b) ACTIVE "tidy lane" action** (operator explicitly chose the document-mutating variant): a command that nudges EXISTING nodes in a lane onto their nearest row line. NOT render-only — it rewrites node y-coordinates in the document, so it needs: explicit user trigger (button/menu, never automatic), participation in undo/dirty-state like a drag, and bridge round-trip + XML diff verification (only DI y-coordinates of moved nodes may change). Snap prefs (PD-017 pattern) stay in localStorage; tidy-lane RESULTS are document data by design.

## Acceptance Criteria

### Agent
- [x] (1a) Sub-row snap lines: a lane tall enough for 2+ rows (N = max(1, round(laneHeight/96)), effective when N≥2) offers N evenly-spaced Y-snap candidates at laneTop + (i+0.5)*laneHeight/N; a short lane (N==1) keeps exactly the single centre line as today. — EVIDENCE: task-lifecycle framework lane (h=260) → 3 rows [265.3, 352, 438.7]; trusted page.mouse drag from cy=392 to proposed 434 snapped to 438.667 with dashed `snap-guide snap-guide-lane` line at that y mid-drag, 0 guides after drop. Corpus-wide invariant: all 21 short lanes (N==1) across 24 maps return exactly [laneCenterY], 0 violations; 46 tall lanes get sub-rows.
- [x] Row-mate Y-snap across the whole lane: the 400px horizontal limit is removed for same-lane node-centre Y-candidates — EVIDENCE: trusted drag with mate 2000px away horizontally, mate midline 356 vs theoretical row 352, proposed cy=353 (row delta 1 < mate delta 3): node snapped to 356 with node-kind guide — row-mate wins even when the row line is nearer (bestNodeY || bestLaneY priority).
- [x] (2b) Tidy-lane action: explicit "⇤ Tidy rows" button in lane properties (never automatic) — EVIDENCE: real click on lane header + button; 11/11 scattered framework nodes moved onto rows (0 x-moves, 0 other-lane moves, offRow=[]); XML diff exactly 11 lines, all `aef:position` y-values (editor format carries geometry in aef:position; no DI section exists); real Ctrl+Z restored all positions, XML byte-identical to before; bridge suite on tidied doc: 31 passed 0 failed, geometry sweep 24 clean. In-browser parse→rebuild round-trip of tidied XML: y-values stable (single diff line is the PRE-EXISTING pool-participant drift, confirmed on fresh untidied doc — filed separately as T-080).
- [x] Corpus sweep: before/after render sweep over the gallery corpus — EVIDENCE: 24/24 maps geometry-identical (node positions + rendered polylines + label bboxes) between HEAD baseline and new build (static render path untouched by design); tidying ALL 3 lanes of pristine task-lifecycle (15 nodes moved) left collisions at 0 → 0.
- [x] JS syntax check passes (node --check on extracted script: SYNTAX-OK) and gallery copy refreshed (diff -q: GALLERY-IN-SYNC).

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
- [x] [REVIEW] Sub-row snapping and tidy-lane feel right in tall lanes
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn (or any map with a tall lane)
  2. Drag a task slowly up/down inside a tall lane — dashed row guides should appear at ~1.5-box-height intervals and the node should settle onto them gently
  3. Drag a node far horizontally from a row-mate, then vertically near its height — it should snap to the row-mate's midline even at long horizontal distance
  4. Invoke the tidy-lane action on a messy lane, then press Ctrl+Z
  **Expected:** Rows feel natural (not sticky, not too many lines); tidy nudges nodes onto rows without reordering or horizontal movement; one undo restores everything
  **If not:** Note which lane/map and what felt wrong (too sticky / wrong row count / tidy moved something it shouldn't); the row pitch (96px) and tolerance are tunable

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

grep -q "function laneRowYs" src/aef-workflow-designer.html
grep -q "function tidyLane" src/aef-workflow-designer.html
grep -q "function undoTidy" src/aef-workflow-designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/.t079-check.js && node --check /tmp/.t079-check.js
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
diff -q src/aef-workflow-designer.html build/gallery/designer.html

## Visual Verification

Element-level screenshots taken and READ (protocol §Visual Verification):
- `.playwright-mcp/t079-middrag-guide-zoom.png` — mid-drag zoomed viewBox: dashed accent guide rendering at the snapped sub-row (model y≈438.7, framework lane row 3 of 3), node under real mouse drag
- `.playwright-mcp/t079-props-tidy.png` — lane properties panel: "alignment rows · 3" info line and "⇤ Tidy rows" button rendered cleanly between Order info and Move up/down
No CSS was changed — guides reuse the T-074 `.snap-guide`/`.snap-guide-lane` styles; the button reuses `.btn btn-routing`.

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

### 2026-07-04 — Tidy-lane revert: scoped single-step Ctrl+Z, not a general undo stack
- **Chose:** `lastTidy` snapshot + Ctrl+Z single-step revert, invalidated by the next manual drag/tidy. Ctrl+Z is only claimed while a tidy is pending, so the shortcut stays free for a future general undo.
- **Why:** Build discovery: the editor has NO undo system at all — no drag, delete, or edit is undoable. "Participates in undo like a drag" therefore has no existing mechanism to participate in. A bulk mutation still needs an escape hatch; a scoped revert delivers that without a new subsystem.
- **Rejected:** (a) General undo stack — a new editor subsystem, clear scope creep for this task; belongs in its own scoped task if wanted. (b) No revert at all — a one-click 11-node mutation without escape violates Usability.

### 2026-07-04 — Row-mate precedence via candidate-source split
- **Chose:** Track `bestLaneY` (theoretical row lines) and `bestNodeY` (real node midlines) separately; final `bestY = bestNodeY || bestLaneY`.
- **Why:** Operator design ("real rows outrank the theoretical lines"): with a single best-delta comparison, a nearer theoretical line would beat a real row-mate — exactly the wrong bias. Verified: mate at delta 3 beats row line at delta 1.
- **Rejected:** Weighting deltas (e.g. node delta × 0.5) — implicit, tunable-forever; the hard precedence matches the stated design and is explainable.

### 2026-07-04 — Lane-reassign drop point follows rows
- **Chose:** The properties-panel lane selector now drops the node on the new lane's row line nearest its current centre (was: always lane centre).
- **Why:** With N≥2, the lane centre can sit BETWEEN rows — the old behaviour would park reassigned nodes exactly where nothing else aligns.
- **Rejected:** Keeping centre-drop — creates off-row nodes that the same feature's tidy action would immediately want to move.

## Recommendation

**Recommendation:** GO
**Rationale:** All five Agent ACs verified with trusted-input evidence (PL-006); static render path untouched and proven unchanged across the 24-map corpus; the tidy action mutates exactly the documented surface (aef:position y of moved nodes) and is revertible; the one anomaly found (pool-participant round-trip drift) is pre-existing and filed separately as T-080.
**Evidence:** Trusted-drag snap to non-centre row 438.667 with guide lifecycle; 2000px row-mate precedence test; tidy XML diff = 11 y-only lines with byte-identical Ctrl+Z restore; bridge suite 31/31 + geometry sweep 24 clean on tidied doc; 24/24 corpus geometry-identity vs HEAD baseline; screenshots t079-middrag-guide-zoom.png / t079-props-tidy.png (read and inspected).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T11:22:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-079-adaptive-alignment-rows-sub-row-snap-lin.md
- **Context:** Initial task creation

### 2026-07-04T12:40:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T12:55:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f39caf15
- **Timestamp:** 2026-07-29T13:13:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
