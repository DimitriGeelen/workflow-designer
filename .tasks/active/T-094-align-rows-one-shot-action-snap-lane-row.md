---
id: T-094
name: "Align rows one-shot action: snap lane row-mates to median centre-y"
description: >
  T-092 GO Phase A option 6: 168 same-lane node pairs sit 1-14px off each other's centre-y (mixed node heights 64/42/28 make top-aligned placements wavy; task-lifecycle 26, verification-gate 25 pairs). Add an Align-rows one-shot action (Clean toolbar menu) that snaps each lane row's members to the row median centre-y. Undoable; mutates geometry only on explicit action (PD-044).

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
created: 2026-07-04T23:21:34Z
last_update: 2026-07-04T23:41:13Z
date_finished: 2026-07-04T23:40:35Z
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

# T-094: Align rows one-shot action: snap lane row-mates to median centre-y

## Context

T-092 GO, Phase A option 6 (docs/reports/T-092-routing-layout-survey.md, Finding 3): mixed node heights (task 64 / gateway ~48 / event 36) leave 168 same-lane node pairs with centre-y 1-14px apart — chains read wavy (task-lifecycle 26, verification-gate 25 pairs). Drag-snap (T-074) only helps during a drag; nothing re-aligns existing geometry. Add a one-shot Align-rows action that snaps each lane's row-cluster to its median centre-y.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] An explicit "⇥ Align rows" button sits in the lane properties panel alongside "⇤ Tidy rows" — one click; geometry is mutated ONLY by this explicit action (`alignRowsLane` has a single caller: the button's onclick; PD-044 holds)
- [x] Action semantics implemented as specified: per lane, chain-cluster nodes whose sorted centre-y neighbours sit <=14px apart; clusters of >=2 snap to the cluster median centre-y; branch-stack members (T-093 `branchStacksInLane`) excluded — their y belongs to the pitch logic
- [x] Single-step undo: shares `lastTidy`/`undoTidy` with Tidy; Playwright-verified on task-lifecycle (framework lane, 5 moved, restored=true byte-compare of all node ys)
- [x] Measured (24-map Playwright sweep): row near-miss pairs 168 → 26, with ALL 26 residuals being pairs involving branch-stack members (excluded by design; non-stack near-misses = 0). 63 nodes moved corpus-wide; rect-overlap count unchanged on every map (0→0; measure-after-move guard reverts any cluster whose flattening would pile nodes up)
- [x] Suites green: bridge "31 passed, 0 failed", validator "34 passed, 0 failed", parity "OK:", geometry "24 clean"; export untouched unless the button is clicked
- [x] Gallery synced: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`

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

- [ ] [REVIEW] Aligned chains read straight, nothing looks displaced
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  2. Click the "framework" lane header, then "⇥ Align rows" in the panel
  3. Look at the main gateway/task chain; press Ctrl+Z once and confirm it returns
  **Expected:** The chain's boxes and diamonds sit on one visual centre line after aligning; Ctrl+Z restores the previous wobble
  **If not:** Screenshot the lane and note which node sits off-line

## Visual Verification

- `.playwright-mcp/t094-tasklifecycle-aligned.png` — task-lifecycle after Align rows: main chain (Build-ready? -> Start work -> Outcome? -> gate battery -> All gates pass? -> Finalize) on one straight centre line, lower row aligned too; READ and confirmed
- `.playwright-mcp/t094-lane-panel-align-btn.png` — lane properties panel: "⇥ Align rows" next to "⇤ Tidy rows" in Order section; READ and confirmed

## Recommendation

**Recommendation:** GO

**Rationale:** Phase A option 6 delivered as scoped: one-shot per-lane action zeroes every non-stack row near-miss on the corpus with no overlap regressions, shares Tidy's single-step undo, and stored geometry moves only on explicit click.

**Evidence:**
- 24-map sweep: near-miss pairs 168 → 26, all 26 residuals involve branch-stack members (T-093's domain; non-stack = 0); 63 nodes moved; overlaps 0 → 0
- Undo Playwright-verified (restored=true); suites bridge 31/31, validator 34/34, parity OK, geometry 24 clean
- Screenshots read: .playwright-mcp/t094-{tasklifecycle-aligned,lane-panel-align-btn}.png

## Verification

out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
grep -q "alignRowsLane" src/aef-workflow-designer.html
grep -q "Align rows" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
test -f .playwright-mcp/t094-tasklifecycle-aligned.png
test -f .playwright-mcp/t094-lane-panel-align-btn.png

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

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-07-05 — Per-lane button beside Tidy, not a global Clean menu
- **Chose:** "⇥ Align rows" lives in the lane properties panel next to "⇤ Tidy rows", sharing lastTidy/undoTidy.
- **Why:** Same interaction contract as the existing document-mutating action (explicit, per-lane, Ctrl+Z single-step revert) — no new undo machinery; the one-click-everything surface is exactly T-095 (Clean composite), which iterates lanes.
- **Rejected:** New global toolbar menu now (duplicates T-095's scope); auto-align on load/render (violates PD-044 — render passes never mutate stored geometry).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T23:21:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-094-align-rows-one-shot-action-snap-lane-row.md
- **Context:** Initial task creation

### 2026-07-04T23:35:25Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T23:40:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
