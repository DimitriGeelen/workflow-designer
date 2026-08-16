---
id: T-315
name: "Import reconcile answers an under-declared lane height by moving nodes; growing
  the band preserves the authored layout"
description: >
  Import reconcile answers an under-declared lane height by moving nodes; growing
  the band preserves the authored layout

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T08:44:51Z
last_update: '2026-08-16T14:33:26Z'
date_finished: 2026-07-31T09:01:00Z
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
  - ts: '2026-08-16T12:33:49Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); 
      F4=1 (prose:routing/geometry-incidental); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/lane-capacity-large-spill.bpmn,tests/fixtures/aef-bpmn/lane-position-conflict.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-315: Import reconcile answers an under-declared lane height by moving nodes; growing the band preserves the authored layout

## Context

T-313 built the DETECTION half (`W-XML-LANE-CAPACITY`): a lane whose declared
members' occupancy extent exceeds its declared `<aef:laneMeta height>`. This task
is the designer half — what the editor should DO about such a map on import.

**What it does today, and why that is the wrong repair for this class.** T-310's
import reconcile (src ~9823) tests each node's CENTRE against the band it lands in:

    if (findLane(n.lane) && laneAtY(n.y + def.h / 2) !== n.lane) → n.y = laneCenterY(n.lane)

That is the right answer when the map contradicts itself about **who** — a node
declared in lane A but drawn inside lane B's band. It is the wrong answer when the
map does not disagree about ownership at all: when a lane's own declared members
simply spill past its own bottom edge, the defect is an **under-declared height**.
There, moving the nodes fixes the symptom by destroying an authored layout, when
growing the band preserves every position and changes no semantics whatsoever.

**Why the two cases separate cleanly — this is T-313's composition result, not a
heuristic.** Bands tile the axis contiguously in declaration order from
`POOL_Y + POOL_HEADER`, so heights are the only free variable. A set of heights
that contains every lane's members exists **exactly when** the lanes are
ordering-clean (`lane_geometry`). So:

| | ordering-clean | ordering-dirty |
|---|---|---|
| **lane over-spills its height** | a pure height solve exists — grow the band, move nothing | no set of heights can fix it; it is a real membership/authority conflict |

The rule therefore has a precondition it can actually test, not a guess.

**Governance: this must not move the ground under T-310's open operator review.**
T-310 is partial-complete with three unchecked `[REVIEW]` ACs, and the second one
asks the operator precisely: *"is 'declared membership wins' the right default?"*,
offering them the binary **move the node** vs **flag it and keep the pixels**.
T-315 is a third option they were never shown — for the height subclass only,
neither move nor merely flag, but **grow the band**, which satisfies both horns.

That question stays theirs. This task must not pre-empt it, and provably does not:
the fixture the operator is asked to load, `lane-position-conflict.bpmn`, is a
two-node SWAP — ordering-dirty — and by the composition result above no lane height
can repair it. So the review fixture's behaviour is untouched by construction, and
an AC pins that as an observed fact rather than an argument. What this change does
is strictly REMOVE cases from the moved-nodes set: maps that were only ever
mis-drawn because a band was too short.

**Do not compute the fix from cumulative band boundaries.** T-312's origin-freeness
trap applies in reverse here: the growth amount comes from the lane's OWN members
(`extent` vs declared `height`), never from reconstructed band edges. Growing lane
*i* moves every boundary below it, so the pass must resize all lanes from their own
members BEFORE any node is tested against a band — resize-then-reconcile, never
interleaved.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] On import, a lane whose declared members' extent exceeds its declared height has its height grown to the Clean fixpoint (`extent + 2*LANE_FIT_MARGIN`) **before** the T-310 centre-test reconcile runs, so nodes that were only out-of-band because the band was too short are never moved
- [x] The growth pass is gated on the map being ordering-clean (T-312's `lane_geometry` predicate, evaluated in-editor over declared lane membership). On an ordering-dirty map it does nothing and T-310's reconcile behaves exactly as it does today — the composition result, enforced in code rather than assumed
- [x] The growth amount is derived from the lane's own members only (`max botOf − min topOf`), never from reconstructed band boundaries; all lanes are resized before any node is tested against a band (resize-then-reconcile, not interleaved)
- [x] **T-310's open-review fixture is provably unaffected:** loading `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` produces byte-identical node positions, the same "2 nodes moved back" notice, and identical lane heights before and after this change — pinned by a CDP assertion, not by inspection
- [x] A map that is ordering-clean and has an under-declared lane loads with **zero** nodes moved and the lane grown instead — verified on `tests/fixtures/aef-bpmn/lane-capacity-large-spill.bpmn` (agent lane h=260, extent 567), whose four node y-values are unchanged after load
- [x] Round-trip safety: re-exporting a map whose lanes were grown emits the NEW heights and otherwise byte-identical bytes — the grown height is a real edit to the model, not a render-time fudge that silently reverts on save
- [x] The operator is told what happened, in the same notice channel T-310 uses: a map whose bands were grown says so, with the lane name(s) and the growth in px — a silent geometry change on load is the failure mode this AC exists to prevent
- [x] Teeth (PL-061): every new CDP assertion is shown RED against the pre-change build — a rule that only ever passes is not evidence
- [x] Existing suites stay green: bridge **49/0** (48 before this task; the +1 is this task's own new leg, not a pre-existing test changing behaviour), validator 36/0, geometry sweep 24 clean, and the T-312 counted-tolerance note count still exactly 5 — unchanged, because this task admits no new exceptions
- [x] Visual verification (CLAUDE.md §Visual Verification for UI Changes): element-level screenshots of the canvas after loading both fixtures, READ with the Read tool, confirming grown bands contain their nodes and no node sits past a band edge — DOM-rect math alone does not close this

## Visual Verification

Four element-level canvas screenshots, all READ (not merely captured), covering
both fixtures on both builds. Sidecar-served working source in an isolated
browser; `docs/screenshots/t315-*.png`.

| shot | what it shows |
|---|---|
| `t315-spill-before.png` | **the defect.** Pre-change build, ordering-clean spill map: the three agent nodes are crushed onto adjacent rows — authored y 87/300/600 becomes 87/160/174 — and `recorded` is dragged from 700 to 404. The notice says "3 nodes were drawn outside their declared lane — moved back into place". The membership is now correct and the drawing is destroyed. |
| `t315-spill-after.png` | **the repair.** Same map, this build: the Agent band is tall enough to hold its content, all four nodes sit exactly where their author left them, every node is inside the band it claims, and the notice reads "1 lane could not fit its own content — band grown, no nodes moved: Agent · Initiative (+331px)". |
| `t315-swap-before.png` | T-310's review fixture on the pre-change build — the baseline the operator's open `[REVIEW]` ACs are written against. |
| `t315-swap-after.png` | the same fixture on this build. **Pixel-identical** to the baseline: both bands still 160, the two swapped nodes still reconciled, the T-310 sentence unchanged and no grow clause added. |

The before/after pair on the spill map is the whole argument for this task in one
picture: both builds end with every node in its declared lane, and only one of
them still shows the diagram the author drew.

## Verification

python3 tests/test_t315_lane_grow_on_import.py
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "49 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "36 passed, 0 failed"
# the counted tolerance from T-312/T-313 is untouched by this change
out=$(bash tests/run-bridge-tests.sh 2>&1); [ "$(echo "$out" | grep -c 'NOTE (known')" -eq 5 ]
# occupancy has ONE definition — a second copy would let Clean and import fight
# over the same lane height on every load (G-009 copy-paste class)
[ "$(grep -c 'const laneBotOf' src/aef-workflow-designer.html)" -eq 1 ]
# the grow pass is gated on ordering, and stands down rather than doing a partial job
grep -q 'if (Math.max(...upper.map(laneTopOf)) >= Math.min(...lower.map(laneTopOf))) return \[\];' src/aef-workflow-designer.html
# resize-then-reconcile: the grow call precedes the centre-test loop in the parse tail
python3 -c "s=open('src/aef-workflow-designer.html').read(); g=s.index('_laneGrowReport = growUnderDeclaredLanes'); r=s.index('if (findLane(n.lane) && laneAtY('); raise SystemExit(0 if g < r else 1)"
# the visual evidence exists and is committed, not just captured in a session
for f in spill-before spill-after swap-before swap-after; do test -s "docs/screenshots/t315-$f.png" || exit 1; done

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-31T08:44:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-315-import-reconcile-answers-an-under-declar.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b5e60970
- **Timestamp:** 2026-07-31T09:02:44Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#4 (Agent)** — **T-310's open-review fixture is provably unaffected:** loading `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` produces byte-identical node positions, the same "2 nodes moved back" notice, and 
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/fixtures/aef-bpmn/lane-position-conflict.bpmn in: **T-310's open-review fixture is provably unaffected:** loading `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` produces byte-identical node pos`
- **AC#5 (Agent)** — A map that is ordering-clean and has an under-declared lane loads with **zero** nodes moved and the lane grown instead — verified on `tests/fixtures/aef-bpmn/lane-capacity-large-spill.bpmn` (agent lan
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/fixtures/aef-bpmn/lane-capacity-large-spill.bpmn in: A map that is ordering-clean and has an under-declared lane loads with **zero** nodes moved and the lane grown instead — verified on `tests/fixtures/a`

### 2026-07-31T09:01:00Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
