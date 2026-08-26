---
id: T-601
name: "Side-placed labels have no pool or lane boundary awareness"
description: >
  adjustLabelPlacements() scores candidate placements against edge segments, node boxes and other label texts only. The pool rect and the lane bands are not obstacles, so a label beside a node at the pool's left edge is scored CLEAN while sitting on top of the lane header and outside the pool (reproduced in .context/working/t600-wrap-off.png and still visible, narrowed, in t600-wrap-on.png). T-600 wrapped the text, which shortens the overrun; it does not clamp the placement. Fix: add the pool interior as a containment constraint to bboxScore, so a placement that leaves the pool scores worse than the default below placement.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T17:38:45Z
last_update: 2026-08-26T19:23:32Z
date_finished: null
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

# T-601: Side-placed labels have no pool or lane boundary awareness

## Context

`adjustLabelPlacements()` scores a candidate placement with `bboxScore()` (:3469), which
counts exactly two obstacle families: rendered edge segments (`segCrossings`) and other
nodes' shape boxes (`nodeOverlaps`). The pool outline, the pool header band and the
per-lane header strip are drawn by `renderPool()` (:2910) and are invisible to the scorer.
So a placement lying on top of the lane header, spilling out of the pool, or straddling a
lane divider scores a clean **0** and is kept.

This is the unfixed half of the operator's own 2026-08-26 report. Their screenshot showed
`run halted - operator kill switch` running across the lane divider; T-600 made it WRAP,
which narrows the overrun but cannot clamp it, because the placement scorer still cannot
see the furniture it is overrunning. T-600's own visual verification recorded the residual:
the off-state capture measured 263px against a 165px cap, "running left across the lane
header and out of the pool".

Crossing a lane divider is not merely untidy. A lane encodes WHO acts (the authority band,
`AUTHORITY_COLOR[lane.authority]`), so a label rendered over the neighbouring lane visually
attributes a step to the wrong actor. That is a claim about what the diagram MEANS, not a
cosmetic complaint.

Geometry is all reachable from the scorer without threading new state: `POOL_X`, `POOL_Y`,
`POOL_HEADER`, `LANE_HEADER`, `contentRightEdge()`, `poolHeight()` and `getLanes()` are
module scope, and lane bands stack from `POOL_Y + POOL_HEADER` by `lane.height`.

## Acceptance Criteria

### Agent
- [x] `bboxScore()` counts a placement overlapping the LANE HEADER strip as contested
- [x] It counts a placement straddling a lane divider — a rect spanning two lane bands — as contested, because a label over the next lane attributes the step to the wrong actor
- [x] It counts a placement leaving the pool (left of `POOL_X`, right of the content edge, below the pool, or up into the pool header band) as contested
- [x] A label lying wholly inside its own lane body still scores ZERO from the new term, so the T-105 contract that uncontested labels keep their default placement holds and the existing corpus does not reflow
- [x] The operator's reported case is measured, not argued: a below-label on a node at the pool's left edge no longer overlaps the lane header after the pass runs
- [x] The new legs assert GEOMETRY (measured rects against measured furniture), not counts of how many labels moved
- [x] `node tools/_t601-lane-boundary.mjs --self-test` passes, with a poison arm FAITHFUL to the pre-T-601 scorer (the whole pool term removed, not merely one clause disabled) failing the pool legs

### Human
- [ ] [REVIEW] Labels stay inside the lane they belong to, and the map is no less readable for it
  **Steps:**
  1. Open the designer and load a map with a node near the pool's left edge carrying a long name
  2. Look at whether any event/gateway label sits on the grey lane header strip or crosses a lane divider
  3. Compare against the T-600 screenshots in `.context/working/`
  **Expected:** No label overlaps the lane header strip or extends into a neighbouring lane; labels with nowhere clean to go sit below their shape as before, rather than in a worse position
  **If not:** Screenshot the offending label, note which lane it belongs to and which one it overlaps

## Visual Verification

Element-level captures of the operator's own reported case, produced by the same harness
that measures it (`node tools/_t601-lane-boundary.mjs --shots .context/working`), so the
image and the numbers come from one build. Both were READ, not merely captured.

- `.context/working/t601-before.png` — the pre-T-601 build. The wrapped label runs LEFT
  across the vertical `HUMAN SOVEREIGNTY` lane header and past the pool border, obscuring
  the header text; the `frw_1_investigation` id badge sits on the lane divider, reaching
  into the lane below. This is the operator's screenshot reproduced from source.
- `.context/working/t601-after.png` — current build. The block is placed right of the
  circle, clear of the header strip, inside its own band, badge above the divider. The
  lane header text is legible again.

Honest trade visible in the after image: the label now overlaps the outgoing connector.
The scorer counted that crossing and still judged it cheaper than sitting on the lane
header — which is the intended ordering, since the header overlap also mis-attributes the
step to the wrong actor. It is a trade, not a free win.

A first capture attempt clipped the wrong region entirely (the node palette) because the
clip was computed from viewBox arithmetic. It was discarded rather than filed: a screenshot
of the wrong region is worse than no screenshot, because it still looks like evidence. The
clip is now the union of real `getBoundingClientRect()` values.

## Decisions

- **Three changes, not one.** Making the scorer pool-aware was necessary and not
  sufficient: measured, the label did not move at all, because the pass tries only right
  and left and then RESTORES the default. A scorer that knows the placement is bad but has
  no way to act on it changes nothing. So the fallback now keeps the strictly best
  candidate, and `place()` clamps a side-placed stack into the node's own lane band.
- **Ties keep the default.** The original rule ("rather than trade one collision for
  another") was right while every obstacle was an edge or a node box and the candidates
  were interchangeable. Pool furniture makes them comparable, so only a STRICTLY better
  candidate wins and an unimproved label never moves for nothing. That is also what keeps
  the corpus from reflowing.
- **The containment leg was retargeted rather than kept green.** Its first scenario (a node
  at the pool's left edge) never actually left the pool, so the leg passed under the poison
  arm and asserted nothing. It now uses a node at the pool floor, where the default label
  falls past the border and a side placement fits — a case the pass can genuinely satisfy.
- **The control was made decisive.** The no-reflow leg first ran against a node whose own
  edges and neighbours contested it, so it was asserting the opposite of what it claimed.
  It now runs with a single node and no edges: nothing can contest it except the pool
  furniture, which is exactly the thing under test.
- **NOT fixed, and captured separately:** `contentRightEdge()` encloses the right-most node
  BOX, not its label, so the pool border can be drawn tighter than the content it contains.
  A label on the right-most node then overhangs with nowhere better to go. That is a pool
  sizing defect, not a placement defect, and merging it here would have hidden it.

## Recommendation

**Recommendation:** GO

**Rationale:** The mechanical claims are measured against measured furniture and proven
failable. What remains is the one thing only the operator can judge: whether the map reads
BETTER now. The pass buys lane containment by accepting other collisions, and that trade is
a matter of taste on real maps, not something a leg can settle.

**Evidence:**
- `node tools/_t601-lane-boundary.mjs --self-test` -> PASS, 5 live legs, 3 proven failable.
- The poison arm restores ALL THREE parts of the fix. A one-part poison would have left the
  other two live and the legs would have gone green on broken code. T-603 shipped exactly
  that mistake earlier today and its self-test caught it; the same discipline was applied
  here from the start.
- Both control legs (no-reflow, furniture integrity) stay GREEN under the poison, proving
  they are independent of the thing being poisoned rather than moving with it.
- Before and after screenshots read, not just captured (see Visual Verification).

**What a NO-GO means:** the fallback ordering is one line — ties already keep the default,
so preferring the default more aggressively is a small change, and the scorer term can stay
either way.

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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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

node tools/_t601-lane-boundary.mjs
node tools/_t601-lane-boundary.mjs --self-test

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

### 2026-08-26T17:38:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-601-side-placed-labels-have-no-pool-or-lane-.md
- **Context:** Initial task creation

### 2026-08-26T19:23:32Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-08-26T19:23:32Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
