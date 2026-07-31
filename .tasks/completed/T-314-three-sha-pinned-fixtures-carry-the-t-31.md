---
id: T-314
name: "Three sha-pinned fixtures carry the T-310 lane inversion the new rule found"
description: >
  T-312's lane_geometry rule fired on three sha-pinned fixtures the day it landed, all true positives. (1) tests/fixtures/aef-bpmn/inception-gonogo.bpmn (T-206 shared promote fixture): declares 'human' first, draws hum_1_inception at y=300 below both agent nodes at y=120 — wholesale inversion. (2) tests/fixtures/aef-bpmn/two-lane-joint.bpmn (T-208): same shape, 1/1 and 3/3 crossing. (3) tests/fixtures/aef-overlay/draft-knowledge-leveling-v3.bpmn (T-304, AEF-owned bytes pinned at b82668c8): wholesale inversion, 5/5 and 11/11 nodes cross — strictly larger than the two-node swap AEF reported on v8. None were repaired under T-312: (1) and (2) are sha-pinned and shared with AEF's consumer test so repair is a coordinated re-pin, and (3) is AEF's bytes which we never edit — that one is an upstream report, not our fix. The three contract tests now admit W-XML-LANE-GEOMETRY as a KNOWN, PRINTED exception (a NOTE line every run) so the tolerance cannot rot into a blind spot. This task closes the tolerance: repair ours, re-pin with AEF, and drop the exception.

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
created: 2026-07-30T20:25:02Z
last_update: 2026-07-31T10:45:28Z
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

# T-314: Three sha-pinned fixtures carry the T-310 lane inversion the new rule found

## Context

T-312's `lane_geometry` rule found three true positives on day one, all in
sha-pinned fixtures. Two are ours to repair; one is not.

**Ours (this task repairs them).** `inception-gonogo` (T-206) and
`two-lane-joint` (T-208) each declare `human` as the FIRST lane and then draw the
human node BELOW the agent nodes. Under the rule this is a **wholesale inversion**
— every node on both sides crosses — which by AEF's own classification makes the
repair a **laneSet reorder: zero-semantic**. No membership changes, no node moves,
no authority is redecided. It is the declaration order that was wrong.

Worth stating plainly, because it was the uncomfortable part of the T-312 finding:
AEF diagnosed this authoring defect in *their generator* — treating framework or
agent verbs as the visual spine on the top row while the laneSet declares someone
else first. We then found we had done the same thing **by hand**, in the fixture we
handed them as the producer contract. It is not peer-specific and it is not
generator-specific; it is what happens when you draw the picture first and write
the laneSet afterwards.

**Not ours (stays admitted).** AEF's `draft-knowledge-leveling` v3, pinned at
b82668c8 as the T-304 census fixture, carries the same inversion plus both lane
overflows found by T-313. Those bytes are theirs; we never edit them. They remain
a **counted, printed** tolerance.

**Coordination.** `inception-gonogo` is the SHARED byte-identical artifact AEF's
consumer test pins (T-559 producer-contract half), so re-pinning moves a sha they
hold. Asked at rail 342; answered at 343 and re-confirmed at 344: **re-pin
whenever suits us, it is a no-op on their side.** So this is unblocked, and the
timing was always ours.

**The tolerance must shrink when the reason for it does.** After this repair only
AEF's fixture should still print a note. A tolerance that outlives its cause is
indistinguishable from a suppression list — the count assertion has to come down
from 5 to 3, or the mechanism stops meaning anything.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `inception-gonogo` and `two-lane-joint` are repaired by **laneSet reorder only** — the `<bpmn:lane>` elements are re-ordered so declaration order matches drawn order, and nothing else about either file changes
- [x] The repair is proven zero-semantic, not asserted: for both fixtures, every node's `flowNodeRef` lane membership, every `aef:position`, every `aef:uid`, and the full node/edge sets are IDENTICAL before and after — diffed mechanically against the pre-repair bytes, not eyeballed
- [x] Both fixtures validate CLEAN under `tools/validate-workflow.py` afterwards — no `W-XML-LANE-GEOMETRY`, and no new finding of any rule introduced by the reorder
- [x] **Cumulative-boundary check (T-312's caveat, and the reason a reorder is not automatically safe):** lane bands are cumulative heights, so swapping lanes of UNEQUAL height moves every boundary below the swap. Both fixtures are re-checked for `W-XML-LANE-CAPACITY` after the reorder — a lane that fitted before must still fit
- [x] The pinned shas are updated at every site that holds them, found by search rather than by memory, and each updated pin carries the reason inline so the next reader sees why the bytes moved
- [x] The counted tolerance SHRINKS to match its remaining cause: `W-XML-LANE-GEOMETRY` is removed from the admitted set in `tests/test_promote_contract.py` and `tests/test_two_lane_joint_contract.py`, which no longer need it, and stays only in `tests/test_dead_leg_census.py` where AEF's un-editable bytes still require it
- [x] The note-count assertion in T-312's Verification comes down from 5 to 3 (census only: 1 geometry + 2 capacity), and the arithmetic is written down so a future reader can tell a legitimate change from a silent one
- [x] Teeth: the reorder is shown to be the thing that fixed it — the pre-repair bytes still produce `W-XML-LANE-GEOMETRY` under the current validator, so the green is attributable to the fixture change and not to a rule that stopped firing
- [x] Bridge suite, validator suite and geometry sweep all stay green with the new bytes (**50/0** — 49 before, +1 for this task's own new `test_t314_fixture_repin` leg; 36/0; 24 clean)
- [x] AEF is told on the rail that the re-pin has landed, with the new shas, so their consumer test can re-pin in lockstep — the coordination half of the T-559 producer contract, not an afterthought

## Verification

# both repaired fixtures validate CLEAN — no geometry, no capacity, nothing else
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/inception-gonogo.bpmn 2>&1); echo "$out" | grep -q "VALID.*no findings"
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/two-lane-joint.bpmn 2>&1); echo "$out" | grep -q "VALID.*no findings"
# the repair was ZERO-SEMANTIC, and stays that way. The pre/post byte diff was
# run once at repair time (Evolution records the result); the durable half — the
# semantic facts the reorder was proven not to touch, plus the order it DID
# change — is pinned by a real test file with its own bridge leg, deliberately
# not by an inline blob and deliberately not against `git show HEAD~1` (right
# exactly once; every later run silently compares something else).
python3 tests/test_t314_fixture_repin.py
# the counted tolerance shrank with its cause: census only (AEF's un-editable v3)
out=$(bash tests/run-bridge-tests.sh 2>&1); [ "$(echo "$out" | grep -c 'NOTE (known')" -eq 3 ]
# and neither repaired contract test admits an exception any more.
# Anchored on the CODE form of the exclusion, not on the bare rule token: both
# files now discuss the removed exception in prose, so a bare-token grep is
# satisfied by the comment explaining the absence — the exact prose-in-the-
# haystack failure this arc has hit three times (T-311 harnesses, T-312's span
# scan, here). AEF's formulation is the rule: anchor on a structural literal
# that cannot occur in prose.
grep -q '!= "W-XML-LANE-GEOMETRY"' tests/test_promote_contract.py && exit 1 || true
grep -q '!= "W-XML-LANE-GEOMETRY"' tests/test_two_lane_joint_contract.py && exit 1 || true
# suites green with the new bytes
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "50 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "36 passed, 0 failed"
# the new shas are the ones actually pinned
[ "$(sha256sum tests/fixtures/aef-bpmn/inception-gonogo.bpmn | cut -d' ' -f1)" = "bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab" ]
[ "$(sha256sum tests/fixtures/aef-bpmn/two-lane-joint.bpmn | cut -d' ' -f1)" = "2ba55eedbd90ae7805fa9ad3c8a7037913b4788dfc8c7db2ae9f3953d6d7bf7f" ]

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

### 2026-07-31 — repaired, re-pinned, tolerance closed

**The zero-semantic claim was measured, once, and here is the result.** Both
fixtures diffed pre/post on flowNodeRef membership, every `aef:position`, every
`aef:uid`, the full sequenceFlow source/target set, every `laneMeta` height, and
the process child-element set: **all identical, both files.** The only delta is
the order of the two `<bpmn:lane>` elements.

    inception-gonogo   093858400716… -> bbfbc5ec4835…   4314 B (size unchanged)
    two-lane-joint     efb53839bfdd… -> 2ba55eedbd90…   5491 B (size unchanged)

**The cumulative-boundary caveat did not bite, and I checked rather than assumed.**
T-312's warning is that swapping lanes of unequal height moves every band boundary
below the swap, so a reorder is not automatically safe. Both lanes are height 160
in both files, so no boundary moved — confirmed by re-running the capacity rule
afterwards, which is the check that would have caught it if I were wrong.

**Teeth on the repair.** "The finding went away" is not evidence by itself. The
PRE-repair bytes still produce `W-XML-LANE-GEOMETRY` under the CURRENT validator,
one finding each, so the green is attributable to the fixture change and not to a
rule that quietly stopped firing.

**The tolerance was deleted, not left standing.** Both contract tests had an
admitted, printed exception for their own fixture; both are gone, and the
suite-wide count came down 5 → 3. Three is now exactly AEF's v3 — one geometry
plus two capacity, on bytes we are not free to edit. A 4th still fails the build.

**A third instance of the prose-in-the-haystack class, in my own verification.**
The line asserting "this test no longer admits the exception" grepped for the bare
token `W-XML-LANE-GEOMETRY` — which now appears in the *comment explaining that the
exception was removed*. The check was satisfied by its own explanation. Re-anchored
on the code form `!= "W-XML-LANE-GEOMETRY"`, which cannot occur in prose, and
teeth-checked both directions: it fires on a synthetic exclusion line and passes on
the repaired files. AEF's formulation is the durable statement of this and I have
adopted it verbatim — *immune checks anchor on a structural literal that cannot
occur in prose; exposed ones match a loose pattern that occurs in prose naturally.*
This arc has now hit the class three times (T-311 harnesses counting elements their
fixtures' comments quoted, T-312's span scan, this).

**One verification line was rewritten for durability rather than correctness.** The
zero-semantic check originally read the pre-repair bytes via `git show HEAD~1:`.
That is right exactly once — on any later run HEAD~1 means a different commit and
the check silently becomes a comparison of something else against itself. Replaced
with recorded literals (membership map, heights, expected declaration order), which
is revision-independent and pins the durable half: not "it changed nothing that
day" but "these facts still hold".

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

### 2026-07-30T20:25:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-314-three-sha-pinned-fixtures-carry-the-t-31.md
- **Context:** Initial task creation

### 2026-07-31T10:35:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
