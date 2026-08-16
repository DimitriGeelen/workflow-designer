---
id: T-312
name: "Mirror AEF's lane/geometry agreement check as a validator rule"
description: >
  Promised to AEF at rail 335. Their fw corpus lint gained a check that needs neither
  band origin nor lane heights: for each map, the y-ranges of nodes grouped by DECLARED
  lane must not overlap, and must run in laneSet declaration order. Run over their
  11 maps it found 4 failures (draft-exception-handling v3 12/13 nodes and draft-task-creation
  v3 14 nodes wholesale-inverted, aef-session-lifecycle v1 PROMOTED with 3 agent-declared
  nodes overflowing the human band, draft-knowledge-leveling v8 with the 2 nodes T-310
  predicted). T-310 fixed the designer half by reconciling at import, but our VALIDATOR
  still cannot see this class - tools/validate-workflow.py is purely structural, which
  is why both toolchains passed every affected map. This is the second geometry-vs-structure
  finding in a row (T-310, T-311) and the strongest argument that geometry-vs-declaration
  wants to be a first-class rule rather than a rendering of the existing structural
  rule set. Note for T-309: surfacing the CURRENT validator in the designer would
  have shown a clean bill of health on maps misreporting authority on nearly every
  node.

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
created: 2026-07-29T22:05:10Z
last_update: '2026-08-16T12:33:49Z'
date_finished: 2026-07-30T20:28:28Z
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
      D2: 3
      D3: 0
      D4: 4
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=0 (no-signal); D4=4 
      (body:cross-machine); F-RECALL=0 (no-signal); F-AUTONOMY=0 (no-signal); 
      F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-312: Mirror AEF's lane/geometry agreement check as a validator rule

## Context

T-310 fixed the DESIGNER half of the lane/geometry disagreement (reconcile at import
in favour of the declared lane). This task fixes the VALIDATOR half: today
`tools/validate-workflow.py` is purely structural and has no opinion about geometry,
which is why every affected map passed both toolchains.

**AEF's predicate** (rail 334), which needs neither band origin nor lane heights and
is therefore portable across our two renderers: *for each map, the y-ranges of nodes
grouped by DECLARED lane must not overlap, and must run in laneSet declaration order.*

Run over their 11 maps it found 4 failures, in three distinct shapes:

| Map | Shape |
|---|---|
| draft-exception-handling v3 | wholesale inversion, 12 of 13 nodes |
| draft-task-creation v3 | wholesale inversion, 14 nodes |
| aef-session-lifecycle v1 (**PROMOTED**) | partial overflow — 3 agent-declared nodes inside the human band, not a swap |
| draft-knowledge-leveling v8 | two-node swap (exactly the pair T-310 predicted) |

**Convergence, not reinvention — SETTLED WORDING RECEIVED (rail 339).** Adopt verbatim,
do not paraphrase:

> For lanes in laneSet DECLARATION order, the y-ranges of nodes grouped by DECLARED
> lane must be strictly ordered and non-overlapping.
> Evaluate only when: >=2 lanes, >=2 lanes populated, and EVERY node positioned.
> Otherwise SKIP (do not pass) — an unevaluable map must not report clean.
> Report per violating ADJACENT lane pair, naming the extremal witness pair:
> the upper lane's lowest-drawn node and the lower lane's highest-drawn node.
> Equal y counts as a crossing (two nodes on one row cannot be in two bands).
> Distinguish repair shape by crossing counts: 100% of both sides => wholesale
> inversion => laneSet reorder (zero-semantic). A subset => placement or stale
> membership on the named nodes => authority call, not a layout call.

**Reference implementation:** `tools/corpus_lint.py::lane_geometry`, with 16 both-ways
tests in `tests/unit/test_corpus_lint_lane_geometry.py` (their tree), including a
wide-gap case that pins bands-must-not-be-reconstructed.

**The trap to avoid, learned from their failure not ours.** Do NOT reconstruct band
boundaries from cumulative lane heights. It needs an origin the map does not store;
AEF tried anchoring at the topmost node and produced **7 phantom mismatches** on
draft-trigger-handling, which is clean under the predicate above. This is the obvious
wrong move from where we sit, because our entire geometry stack (`laneTop`,
`laneCenterY`, `laneAtY`, `poolHeight`) walks cumulative heights from
`POOL_Y + POOL_HEADER`. The predicate is deliberately origin-free — keep it that way.

**Also from their retraction (rail 338):** they built a containment/feasibility variant
first and retracted it one message later. Closed bands (`O+top <= y <= O+top+h`) let a
node sitting exactly on a shared boundary satisfy BOTH adjacent bands, waving through
the precise defect the ordering rule catches. Half-open fixes it but then adds ZERO
detection over ordering across all 11 of their maps, with strictly worse diagnostics
(an interval instead of the witness pair). **Build the ordering rule, not the
containment rule.** If containment is ever implemented, it must be half-open —
`[top, top+h)` — which is what our own `laneAtY` already does.

**Why this earns a rule rather than a designer-side check:** the designer already
repairs this on import (T-310), but repair only happens where the designer is in the
loop. Maps flow between us as bytes and get promoted without ever being opened. The
validator is the surface both sides actually run over untouched files.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A new rule in `tools/validate-workflow.py` implements the predicate: per map, group nodes by DECLARED lane (`flowNodeRef`), compute each group's y-range from `<aef:position>`, and report when two groups' ranges overlap OR when the ranges do not run in laneSet declaration order
      — `XmlValidator._check_lane_geometry`, called from `validate()` after `_check_iw9_authority`. Groups are built from `flowNodeRef` in laneSet declaration order; ranges from `<aef:position>` y via `_node_y`. Adjacent populated pairs only (sufficient by transitivity, since each populated group has min <= max — proven by the 3-lane test: 3 inverted lanes yield 2 findings, not 3).
- [x] The rule degrades honestly rather than guessing: maps where nodes carry no `<aef:position>` (y absent, or the hand-authored `y=0` convention the designer treats as "unpositioned") are SKIPPED, not reported clean and not reported failing — geometry that does not exist cannot disagree with anything
      — `_node_y` returns None for a missing `<aef:position>`, a missing/unparseable `y`, AND for `y == 0` (the designer's sentinel: src:9710-9713 defaults an absent position to y=0, src:9805 patches it to the lane centre). A map with any unpositioned flow node emits `I-XML-LANE-GEOMETRY-SKIP` — a new INFO severity that never affects the exit code — whose text ends "this map is SKIPPED by lane_geometry, not passed by it". Fixture: `tests/fixtures/aef-bpmn/lane-geometry-unpositioned.bpmn`.
- [x] Rule id and message text match AEF's `fw corpus lint::lane_geometry` — their settled wording arrived at rail 339 and is quoted verbatim in Context above, so there is no divergence left to record. Any deviation from it is a defect in this task, not a local choice
      — Predicate and message wording adopted verbatim; the docstring quotes their text unaltered. One deliberate, disclosed deviation on the ID only: our validator's rule ids are severity-prefixed (`E-*`/`W-*`/`I-*`) and every harness and fixture-naming contract in the repo depends on that, so the rule is `W-XML-LANE-GEOMETRY` and the bare token `lane_geometry` is carried INSIDE the message, keeping `grep lane_geometry` a working cross-toolchain join. Recorded in Decisions and reported on the rail rather than made silently.
- [x] The report names the **extremal witness pair** (upper lane's lowest-drawn node, lower lane's highest-drawn node) per violating ADJACENT lane pair — not a count, not an interval. This is what resolved knowledge-leveling v8 to exactly `kl_dormant`/`kl_healing` from bytes alone, and it is why the ordering rule beat the containment variant AEF retracted
      — `max(upper, key=y)` / `min(lower, key=y)`; ties resolve in declaration order because both keep the first extremum. Tested positively (the pair IS named) and negatively (non-extremal nodes are NOT named). On the T-310 fixture it names exactly `agt_2_act`/`frw_1_check`, the known conflicting pair.
- [x] Crossing counts drive the repair-shape hint: 100% of both sides → wholesale inversion → "reorder the laneSet, zero-semantic"; a subset → "placement or stale membership on the named nodes — authority call, not a layout call". A rule that says *what to do* is the difference between this and a finding nobody actions
      — `cross_up`/`cross_lo` counted against the opposite lane's extremum; both-100% → "wholesale inversion: reorder the laneSet (zero-semantic repair)", otherwise "placement or stale membership on the named nodes: an authority call, not a layout call". Counts are printed (`2/2 and 2/2`, `1/2 and 1/4`) so the classification is auditable, not just asserted.
- [x] Equal y counts as a crossing (two nodes on one row cannot be in two bands)
      — the guard is `if ys[up_lowest] < ys[lo_highest]: continue`, i.e. STRICT; equal y falls through to the finding. Directly tested (`two_lane([100], [100])` → 1 finding).
- [x] Band boundaries are NOT reconstructed from cumulative heights anywhere in the implementation — the predicate is origin-free by design, and reconstructing produced 7 phantom mismatches on AEF's side
      — the rule never reads `laneMeta/@height` or `POOL_Y`. Two independent guards: a behavioural one (a 4860px inter-lane gap stays clean — a height-walking implementation would place the lower band far above y=5000 and report a phantom) and a source-level one (the rule body is extracted and asserted to contain no height read).
- [x] Positive fixture: `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` (already in-tree from T-310, and the canonical instance of this class) is reported FAILING by the new rule
      — fires with witness pair `agt_2_act` (y=300) / `frw_1_check` (y=100), counts `2/2 and 1/2`, classified as an authority call. Exit 1.
- [x] All three of AEF's observed shapes are covered by fixtures, not just the swap: wholesale inversion, partial overflow (the promoted-map shape), and the two-node swap. Partial overflow is the one a naive "are the lanes in the right order" check misses
      — shape 1 wholesale inversion: `tests/fixtures/warn/W-XML-LANE-GEOMETRY.xml` (2/2 and 2/2). shape 2 partial overflow: `tests/fixtures/aef-bpmn/lane-geometry-partial-overflow.bpmn` (1/2 and 1/4). shape 3 two-node swap: the T-310 fixture. The partial-overflow fixture is built so a naive summary-statistic check PASSES it — human centroid 105 vs agent centroid 185, medians 105 vs 117.5, both correctly ordered — and the test asserts that arithmetic explicitly, so the fixture proves what it claims rather than asserting it.
- [x] Zero false positives on the clean corpus: all 24 maps in `examples/aef-processes/rendered/` pass the new rule (they were verified lane/geometry-consistent as part of T-310's byte-identity work)
      — sweep: `total=24 evaluated-clean=24 geom-warn=0 skipped=0`. The zero-skipped half matters as much as the zero-warn half: all 24 were actually EVALUATED, so "24/24 clean" is not quietly resting on maps the rule declined to judge.
- [x] Teeth (PL-061): the rule is proven to go RED by running it against the positive fixtures, and the negative case is proven by the 24-map sweep — a rule that only ever passes is not evidence
      — the pre-change validator (`git show HEAD:tools/validate-workflow.py`) reports all three positive fixtures `VALID -- no findings`, exit 0: the class really was invisible. Running the new test module against that pre-change build fails **25 assertions**; against the current build, 0. Teeth proven both directions.
- [x] Validator suite gains a leg for the new rule and stays green (currently 34/0); bridge suite unaffected (currently 46/0)
      — validator suite **35/0** (the `warn/W-XML-LANE-GEOMETRY.xml` fixture registers automatically under the filename==rule-id contract); bridge suite **47/0** with the new T-312 leg; corpus geometry sweep 24 clean. The bridge suite did NOT stay untouched on the first run — see Evolution.

<!-- No Human section: every criterion in this task is deterministic
     (a rule fires or it does not, a suite is green or it is not), so there
     is no taste judgment to route to the operator. The one judgment call
     that DID arise — whether to repair three sha-pinned fixtures the rule
     caught — was not folded in here; it is filed as T-314, where the
     coordinated re-pin with AEF belongs. -->


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

python3 tests/test_t312_lane_geometry.py
bash tests/run-validator-tests.sh
bash tests/run-bridge-tests.sh
# each of the three shapes fires, and is classified correctly
out=$(python3 tools/validate-workflow.py tests/fixtures/warn/W-XML-LANE-GEOMETRY.xml 2>&1); echo "$out" | grep -q "wholesale inversion"
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/lane-geometry-partial-overflow.bpmn 2>&1); echo "$out" | grep -q "hum_2_gate"
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/lane-position-conflict.bpmn 2>&1); echo "$out" | grep -q "agt_2_act"
# an unevaluable map is SKIPPED, not passed
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/lane-geometry-unpositioned.bpmn 2>&1); echo "$out" | grep -q "not passed by it"
# zero false positives AND zero silent skips across the 24-map rendered corpus
n=0; s=0; for f in examples/aef-processes/rendered/*.bpmn; do out=$(python3 tools/validate-workflow.py "$f" 2>&1); if echo "$out" | grep -q "W-XML-LANE-GEOMETRY"; then n=$((n+1)); fi; if echo "$out" | grep -q "I-XML-LANE-GEOMETRY-SKIP"; then s=$((s+1)); fi; done; [ "$n" -eq 0 ] && [ "$s" -eq 0 ]
# the predicate stays origin-free — no band reconstruction from lane heights.
# (the test module proves this structurally by scanning the rule body for a
# height read; this line only pins the intent marker, so keep both)
grep -q "deliberately ORIGIN-FREE" tools/validate-workflow.py
# the known fixture exceptions stay VISIBLE (printed), not silently tolerated.
# 3 = dead-leg-census only (AEF's pinned v3: 1 geometry + 2 capacity, on bytes we
# are not free to edit). Was 5 until T-314 repaired the two 832-owned fixtures by
# zero-semantic laneSet reorder — promote-contract and two-lane-joint now validate
# CLEAN and admit nothing at all, so their exceptions were DELETED rather than
# left standing. A tolerance that outlives its cause is a suppression list.
# A 4th note means a fixture joined the tolerated set silently, which is the
# actual failure mode this line exists to catch.
out=$(bash tests/run-bridge-tests.sh 2>&1); [ "$(echo "$out" | grep -c 'NOTE (known')" -eq 3 ]

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

### 2026-07-30 — the rule found three true positives in our own pinned fixtures

- **What changed:** the AC said "bridge suite unaffected". It was affected — the
  first full run went 43/3. All three failures were TRUE POSITIVES, not false
  alarms, and all three are in sha-pinned fixtures:
  1. `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` (T-206 shared promote
     fixture): declares `human` first, draws `hum_1_inception` at y=300 below
     both agent nodes at y=120 — wholesale inversion.
  2. `tests/fixtures/aef-bpmn/two-lane-joint.bpmn` (T-208): same shape,
     1/1 and 3/3 crossing.
  3. `tests/fixtures/aef-overlay/draft-knowledge-leveling-v3.bpmn` (T-304,
     AEF's own bytes pinned at b82668c8): wholesale inversion, **5/5 and 11/11
     nodes cross**.
  Finding (3) is bigger than what AEF reported: they described knowledge-leveling
  as a two-node swap (on v8). Their pinned v3 is FULLY inverted. Our own two
  fixtures show the same authoring habit AEF diagnosed in their generator —
  drawing the visual spine on the top row while declaring the other lane first —
  so this is a shared authoring defect, not a peer-specific one.
- **Plan impact:** none of the three could be repaired under this task. (1) and
  (2) are sha-pinned and shared with AEF's consumer test, so repair is a
  coordinated re-pin; (3) is AEF's bytes, which we never edit — that one is an
  upstream report, not our fix. The three contract tests now admit
  `W-XML-LANE-GEOMETRY` as a narrow exception that **prints a NOTE line every
  run**, so the tolerance is loud rather than silent, and a Verification command
  asserts exactly three such notes exist (a fourth would mean a new fixture
  quietly joined the exception).
- **Triggered:** T-314 filed (repair ours, coordinate the re-pin, report theirs,
  then drop the exception).

### 2026-07-30 — scope probe: the YAML form does not need this today

- **What changed:** the canonical YAML form carries `lanes` (ordered) and node
  `x`/`y`, so the same predicate applies to it with no extra machinery. I ran it
  over the YAML corpus as a measurement rather than expanding scope:
  **25 maps, 24 evaluable, 0 violating, 0 skipped, 1 out of scope (single lane).**
- **Plan impact:** extending the rule to the YAML validator would be a no-op
  today. Not done — the task specced the BPMN seam form, which is what travels
  between the two projects. Recorded so a future decision starts from data.
- **Triggered:** nothing. Deliberately not filed as a task; measurement only.

## Decisions

### 2026-07-30 — WARN, not ERROR

- **Chose:** `W-XML-LANE-GEOMETRY` is a WARN (exit 1), not an ERROR (exit 2).
- **Why:** the map is not ambiguous — declared membership wins (T-310), so there
  is always a defensible reading. What is broken is that a human reading the
  picture and a tool reading `flowNodeRef` get different answers about who is
  responsible. That is serious but not structurally invalid. The choice was
  immediately vindicated: the rule fired on three PINNED fixtures on day one, all
  true positives, none unilaterally repairable. At ERROR severity it would have
  hard-failed a peer's promoted bytes we are contractually forbidden to edit.
- **Rejected:** ERROR (blocks on maps whose repair needs cross-project
  coordination); INFO (would make a real authority misreport invisible).

### 2026-07-30 — a new INFO severity for SKIP-not-PASS

- **Chose:** added an `INFO` severity, used only by `I-XML-LANE-GEOMETRY-SKIP`,
  which never affects the exit code. `render_text` keeps both the `VALID` and
  `no findings` tokens intact so existing greps across the harnesses are unmoved.
- **Why:** AEF's predicate says an unevaluable map must SKIP, not pass. Our
  validator had only ERROR and WARN, so "could not evaluate" and "evaluated and
  clean" were indistinguishable — exactly the false green the rule exists to
  prevent. A note makes the difference observable without inventing a failure.
- **Rejected:** silently returning (indistinguishable from a pass — the whole
  defect); emitting a WARN (an unpositioned map is not defective, and every
  hand-authored map would warn forever).
- **Scope guard:** the note fires ONLY when a map makes an ordering claim it
  cannot back up (>=2 populated lanes, some node unpositioned). Fewer than two
  populated lanes is out of scope, not unevaluable — there is no ordering claim
  to check — and stays silent, so single-lane maps do not gain permanent noise.

### 2026-07-30 — rule id namespaced, `lane_geometry` carried in the message

- **Chose:** rule id `W-XML-LANE-GEOMETRY`, with AEF's bare token `lane_geometry`
  embedded in the message text.
- **Why:** the AC asked for AEF's id and message. The message wording is theirs
  verbatim. The bare id could not be: every rule in this validator is
  severity-prefixed, the fixture suite's contract is literally
  `<RULE-ID>.<ext>` filenames, and `exit_code`/`render_text` group on that
  convention. Embedding the token keeps `grep lane_geometry` a working join
  across both toolchains, which is what the AC was protecting.
- **Rejected:** using the bare `lane_geometry` id (breaks the repo-wide id
  convention and the fixture-naming contract); paraphrasing their message (the
  AC forbids it, and divergent phrasings of the same finding is exactly the
  reinvention this task existed to avoid).

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

### 2026-07-29T22:05:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-312-mirror-aefs-lanegeometry-agreement-check.md
- **Context:** Initial task creation

### 2026-07-29T22:07:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3c781c16
- **Timestamp:** 2026-07-30T20:30:07Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 42
     - evidence: `n=0; s=0; for f in examples/aef-processes/rendered/*.bpmn; do out=$(python3 tools/validate-workflow.py "$f" 2>&1); if echo "$out" | grep -q "W-XML-LANE-GEOMETRY"; then n=$((n+1)); fi; if echo "$out" |`

### 2026-07-30T20:28:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
