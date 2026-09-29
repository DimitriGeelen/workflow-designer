---
id: T-882
name: "Advance validates against the template and refuses an illegitimate transition"
description: >
  arc-005 S3/B8. CONTINGENT on T-878 AND T-879 GO. The refusal is the deliverable,
  not the advance — an advance that only ever succeeds demonstrates no guard.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:process-instances]
components: [examples/aef-processes/template-binding.yaml, tools/instance-node.py, tools/_t880-instance-node-teeth.sh]
related_tasks: [T-880, T-881, T-878, T-879]
arc_id: process-instances
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-26T22:43:18Z
last_update: 2026-09-29T00:04:19Z
date_finished: 2026-09-29T00:04:19Z
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
bvp_scores_proposed: []
cost_estimate_proposed:
  - ts: '2026-09-28T23:58:47Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (3-components); tier=2 (workflow:build); effort=8 
      (lines=287,acs=10)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 2
  F3: 4
  F1: 3
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T23:58:47Z'
---

# T-882: Advance validates against the template and refuses an illegitimate transition

## Context

**arc-005 S3 / manifest item B8. Unblocked by T-878 GO and T-879 GO (both 2026-09-27); S2 closed 2026-09-29 (T-880 records a node, T-881 resolves both ways).** This slice adds the one thing G4 ("execution is observable and guarded") needs first: a move that the template can refuse.

**What exists.** `tools/instance-node.py set <T-XXX> <node>` writes `current_node:` into the entity's frontmatter and refuses a node that is not in the entity's bound template(s) — membership only. It knows nothing about ORDER: `set T-9984 frw_2_build` on an entity standing on `frw_11_task` (the end event) succeeds today, and T-880's own suite pins that as a control. The template of record, `examples/aef-processes/rendered/task-lifecycle.bpmn`, carries 15 flow nodes and **18 `sequenceFlow`s**; nothing reads the flows.

**What this task delivers: a verb that moves a position ONLY along a flow the template carries, and refuses everything else.**

- `advance <T-XXX> <node>` — legal iff the bound template that contains the entity's current node has a `sequenceFlow` from current → target. Otherwise `REFUSED-TRANSITION`, exit 1, naming the current node, the target, the template FILE and the legal successors. Single hop: an entity three nodes behind advances three times, each validated.
- **From NO-POSITION an instance starts at the start:** `advance` onto the template's `startEvent` is legal; onto any other node is refused, naming the start event.
- **`set` becomes placement-only.** From NO-POSITION it still places anywhere — that is the backfill path for the 178+15 live entities that predate this mechanism (T-878 IW-5, measured under T-881). On an entity that already has a position it is `REFUSED-PLACED`: "position already recorded; move it with advance". This is what makes the guard real — without it, `set` is a bypass beside `advance` and the refusal is decoration.
- Gateways: every `exclusiveGateway` in both bound templates branches on outgoing flows, so any ONE outgoing flow is a legal transition and the other branch is not "skipped", it is not taken. No token semantics for `parallelGateway`/`inclusiveGateway` (present only in `harvest-pipeline` and `audit-process`, which nothing binds to); the tool treats a sequenceFlow as a legal single-token transition and its docstring says so.
- Legitimacy is READ from the artefact's `sequenceFlow` elements — no successor table is written into the tool. If the artefact is re-rendered with a different flow, the answer changes with it.

**Explicitly not here (one task = one deliverable).**
- *Audit-log landing* of the refusal — T-883. The refusal is emitted through a single `refuse()` path so T-883 has one hook, not four.
- *The skipped human gateway* (V7 leg 2): `frw_9_human → frw_10_finalize` is a legal flow BY STRUCTURE; whether it was legitimate depends on the gateway's condition (human-owned with unchecked Human ACs), which is task state, not template structure. T-882 guards structure. The condition evaluator belongs with T-883's second leg.
- *Making the framework the writer* (OBS-433): `update-task.sh`'s own transitions calling `advance` for the node they ARE (`frw_3_start`, `frw_8_partial`, `frw_10_finalize`, `frw_11_task`). Filed as its own task at close; until then the live corpus's 193 NO-POSITION records are untouched by this task.

## Acceptance Criteria

### Agent
- [x] **A legal transition is recorded.** A fixture standing on `frw_3_start` advances to `agt_2_perform` with exit 0; `current_node:` reads `agt_2_perform` afterwards and appears exactly once in the frontmatter.
- [x] **An out-of-order advance is refused and changes nothing.** The same fixture advancing to `frw_10_finalize` exits 1 with a line beginning `REFUSED-TRANSITION` that names the current node, the target, the template file (`examples/aef-processes/rendered/task-lifecycle.bpmn`) and the legal successor(s); the frontmatter still reads `frw_3_start`.
- [x] **Backwards and past-the-end are refused for the same reason.** `agt_2_perform → frw_3_start` (no such flow) and `frw_11_task → anything` (end event, no outgoing flow) both exit 1 with `REFUSED-TRANSITION`; the end-event refusal says the successor set is empty.
- [x] **An exclusive gateway admits either branch and nothing else.** From `frw_5_outcome`, `frw_4_enter` and `agt_3_request` are each legal (exit 0), and `frw_6_run` — two hops away — is refused.
- [x] **From NO-POSITION an instance starts at the start.** `advance` onto `frw_1_task` from no recorded position exits 0; `advance` onto `frw_3_start` from no recorded position exits 1 and the refusal names `frw_1_task`.
- [x] **`set` is placement, and placement is one-shot.** `set` onto a mid-flow node from NO-POSITION still succeeds (the backfill path); `set` on an entity that already has a position exits 1 with `REFUSED-PLACED` and the record is unchanged — so no verb in the tool moves a recorded position except along a flow. T-880's control `set_replaces_not_duplicates` is rewritten to this contract (recorded in Evolution) and T-880's and T-881's suites are green under it, including their mutation runs.
- [x] **An inception moves within one template.** An inception fixture on `hum_1_record` advances to `hum_2_decision` (inception-lifecycle) with exit 0; from `hum_2_decision` to `frw_10_finalize` (a real node, in task-lifecycle) is `REFUSED-TRANSITION`.
- [x] **Legitimacy is read from the artefact, not from the tool.** Control first (PL-328): the pattern for a lane-prefixed node id hits in the rendered artefact; the same pattern hits NOWHERE in the tool's non-comment, non-docstring code. And the mutation run below proves the successor check is the thing doing the refusing.
- [x] **Teeth.** `tools/_t882-advance-teeth.sh` runs the controls first, then the gate cases, and `--mutation` disables the successor check at a named anchor: every control must stay green (else `MUTATION SETUP BROKEN`) and every refusal case must go red (else `MUTATION FAILED`).
- [x] **The live corpus is not moved by this task.** `roundtrip` reports `ROUNDTRIP-OK` for both bound templates after the change, and the task's diff writes no `current_node:` line under `.tasks/` (fixtures live under `mktemp`).

### Human
_None._ Every criterion is a deterministic shell check (T-1811 prefix-routing rule); the one human-visible half of this slice — seeing the refusal on the map — is T-884's deliverable.

## Verification

# T-882 teeth: controls first, gate cases, then the mutation run must kill every refusal. Property-pinned, no live counts (T-3326).
out=$(bash tools/_t882-advance-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t882-advance-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# The S2 suites stay green under the new set contract, mutation runs included.
out=$(bash tools/_t880-instance-node-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t880-instance-node-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
out=$(bash tools/_t881-resolution-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t881-resolution-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# Legitimacy comes from the artefact. Control first (PL-328): the node-id pattern hits in the artefact...
grep -qE 'id="(frw|agt|hum)_[0-9]+_[a-z]+"' examples/aef-processes/rendered/task-lifecycle.bpmn
# ...and nowhere in the tool's code once comments and the module docstring are stripped.
out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))"); ! echo "$out" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b'
# The live corpus was not moved: both bound templates still round-trip.
out=$(python3 tools/instance-node.py roundtrip 2>&1); echo "$out" | grep -q '^ROUNDTRIP-OK task-lifecycle' && echo "$out" | grep -q '^ROUNDTRIP-OK inception-lifecycle' && ! echo "$out" | grep -q 'ROUNDTRIP-FAIL'
python3 -m py_compile tools/instance-node.py
bash -n tools/_t882-advance-teeth.sh

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
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

### 2026-09-29 — the guard needed `set` to give something up
- **What changed:** The design as filed was "add a verb that validates". Building it showed that an `advance` beside an order-blind `set` is decoration: any hop `advance` refuses, `set` performs. So `set` lost re-placement — it is now one-shot placement for the entities that predate the mechanism, and `REFUSED-PLACED` afterwards. That broke a T-880 control (`set_replaces_not_duplicates` pinned frw_11_task → frw_2_build, an end event hopping back to a gateway — precisely the transition S3 exists to refuse); the control was rewritten to the new contract, not deleted, and T-880's mutation run is still a kill. Second thing learned: the template's exclusive gateways make "either branch" trivially right, but the V7 *skipped human gateway* is not a structural question at all — `frw_9_human → frw_10_finalize` is a legal flow; whether it was legitimate is a condition on task state. T-882 guards structure only, and says so.
- **Plan impact:** T-883's second leg needs a condition evaluator (human-owned + unchecked Human ACs at `frw_9_human`), not just a log line — that is more than "land the refusal in the audit log" and should be scoped as such. T-884 gets `template_flows()` for free (it will want successors to draw the refused edge).
- **Triggered:** Filed the framework-as-writer task (OBS-433's fix) so the guard is exercised by the transitions that actually move entities; until then every live record is either NO-POSITION or stale. **One error of mine, recorded:** while demonstrating the refusal live on T-880 I also ran the *legal* hop (`frw_6_run → frw_7_all`) intending a dry look — the tool has no dry-run and it wrote into `.tasks/completed/`. Confirmed the diff was that one line and restored the file from HEAD. AC 10 held at close because of the revert, not because I was careful; the gate that refused the same class of write in round 1 (`check-active-task`) did not fire on a python-driven write under a different focus, and that is filed as an observation rather than relied on.


## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

- **Chose:** `set` is placement-only (first position; `REFUSED-PLACED` thereafter) and `advance` is the only mover, single hop, along the artefact's `sequenceFlow`s; from NO-POSITION `advance` lands only on a `startEvent`.
- **Why:** the refusal is the deliverable; a mover with a free setter beside it refuses nothing. Single hop keeps every transition validated and keeps the surface one verb. The start rule is what "an instance starts at the start" means; the placement path exists because 193 live entities are mid-life with nothing recorded (T-878 IW-5), and re-deriving their prefix is not this task's problem.
- **Rejected:** (a) `set --force` / `--reset` for re-placement — a logged bypass on the very guard being introduced, before anything even calls it; if a real need appears it comes with its own task and its own audit line (T-883's domain). (b) Multi-hop `advance A..B` with path search — hides which hop was validated and invites "advance to the end". (c) Token semantics for parallel/inclusive gateways — no bound template has one; documented as a stated limitation instead of speculative code.


## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-26T22:43:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-882-advance-validates-against-the-template-a.md
- **Context:** Initial task creation

### 2026-09-28T23:57:18Z — status-update [task-update-agent]
- **Change:** horizon: later → now
- **Reason:** T-874 filed this 'CONTINGENT on T-878 AND T-879 GO'; both are recorded GO (T-878 2026-09-27, T-879 2026-09-27) and S2 (T-880, T-881) closed 2026-09-29. The contingency the horizon encoded is met — procAsFit round 2 selection: G4 via arc-005 S3.

### 2026-09-28T23:58:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5ad21a82
- **Timestamp:** 2026-09-29T00:04:31Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 12
     - evidence: `out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];prin`

### 2026-09-29T00:04:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
