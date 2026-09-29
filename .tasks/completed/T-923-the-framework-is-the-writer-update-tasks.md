---
id: T-923
name: "The framework is the writer: update-task.sh transitions advance the instance
  node they ARE, through the T-882 guard"
description: >
  OBS-433 (T-880) and T-882's close. A recorded current_node goes stale at the next
  status transition because the agent is the writer and the framework is the mover.
  T-882 delivered the guarded advance; nothing calls it yet, so 193 live entities
  stay NO-POSITION and the one recorded node (T-880, frw_6_run in completed/) is wrong
  by four hops. Scope: update-task.sh's own transitions call 'instance-node.py advance'
  for the node they are — captured→started-work is frw_3_start, gate battery is frw_6_run,
  refusal at frw_7_all, partial-complete is frw_8_partial, finalize is frw_10_finalize
  then frw_11_task — and a refusal from the guard is surfaced, not swallowed. Open
  design question for the ACs: an entity at NO-POSITION cannot advance mid-flow by
  construction (T-882), so the first framework-driven move must either place (set)
  from NO-POSITION or walk the prefix from frw_1_task; choose and pin it. Sequenced
  with T-883 (refusals land in the audit log).

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: [arc:process-instances]
components: [tools/instance-node.py, tools/_t880-instance-node-teeth.sh, tools/_t882-advance-teeth.sh]
related_tasks: [T-882, T-880, T-881, T-883, T-884]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-29T00:03:16Z
last_update: 2026-09-29T06:59:29Z
date_finished: 2026-09-29T06:59:29Z
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
  - ts: '2026-09-29T00:16:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 4
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=4 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L3:path=examples/aef-processes/rendered/*~examples/aef-processes/rendered/task-lifecycle.bpmn);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-29T00:12:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (4-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=281,acs=10)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 0
  F3: 0
  F1: 1
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T00:12:14Z'
---

# T-923: The framework is the writer: update-task.sh transitions advance the instance node they ARE, through the T-882 guard

## Context

**arc-005, between S3 (T-882, the guard) and S4 (T-884, the picture). Origin OBS-433.** T-880 recorded a node; T-882 made the record move only along a template flow. Nothing calls either: every one of the 193 live instances measured under T-881 is NO-POSITION, and the single recorded node in the corpus (T-880, `frw_6_run`, in `completed/`) is four hops behind its own status. The agent is the writer and the framework is the mover, so every record is stale from the next transition on.

**This task makes the framework the writer.** `update-task.sh` performs the transitions the template draws — it IS `frw_3_start`, `frw_4_enter`, `frw_6_run`, `frw_8_partial`, `frw_10_finalize`/`frw_11_task` when it runs those blocks — so it records the node it is, through the T-882 guard, at the moment it acts.

**Shape.**
- `tools/instance-node.py walk <T-XXX> <node>` — the framework knows its TARGET node, not the agent-lane nodes between (after `frw_3_start` the agent is at `agt_2_perform`; nothing in the framework observes that). `walk` finds the shortest path over the template of record's `sequenceFlow`s and takes it one validated hop at a time, printing every `HOP a -> b`. No path → `REFUSED-TRANSITION`, nothing written. Already there → exit 0, nothing written. From NO-POSITION it starts at the `startEvent` of the template that contains the target — so a legacy entity's first framework-driven move walks its real prefix rather than being placed. Each hop goes through the same code as `advance` (`_advance_one`), so PD-345's rejection of a multi-hop *advance* stands: `walk` is the framework's verb, it shows every hop, and it cannot take a hop `advance` would refuse.
- `.agentic-framework/lib/instance-position.sh` — `fw_instance_node_for_transition <old> <new> [partial]` maps the six transitions `status-transitions.yaml` allows onto the nodes the framework is at; `fw_instance_walk <task> <node>` calls the tool and **never fails a close**: success is echoed as `position:` lines, a refusal is a `WARNING:` on stderr carrying the tool's own `REFUSED-TRANSITION` line with the record unchanged, NO-ENTITY/NO-TEMPLATE are silent (a `spike` is not an instance), and where the tool or the rendered artefact is absent the function is a silent no-op so the vendored framework keeps working in projects without the seam.
- `update-task.sh` call sites: the status write (`started-work` from captured → `frw_3_start`; from issues → `agt_2_perform`; `issues` → `frw_4_enter`), the start of the completion battery (`frw_6_run`), the two named gate refusals P-010 and P-011 (→ `agt_2_perform`, whose path passes `frw_7_all`), partial-complete (`frw_8_partial`), and finalize in both the fresh and the re-check path (`frw_11_task`, after the move so the record lands in `completed/`).

**Known limits, stated.** `started-work → captured` (pause) has no node: the template does not model a pause, so the position is left where it is — a template gap, not a wiring gap. Gate refusals other than P-010/P-011 (sovereignty, RCA, evolution, disposition, …) leave the record at `frw_6_run`: the battery ran and did not pass, which is true; the next transition walks from there. `fw inception decide` is `inception-lifecycle`'s writer and is not touched here.

**Live proof is this task itself:** it is driven `started-work → issues → started-work → work-completed` under the wiring, and its own record shows `frw_4_enter`, then `agt_2_perform`, then `frw_11_task` in `completed/`. And the one stale record in the corpus (T-880) is walked to where its status says it is, with the hops printed.

## Acceptance Criteria

### Agent
- [x] **`walk` takes the shortest legal path and shows every hop.** A fixture on `frw_3_start` walked to `frw_4_enter` exits 0, prints `HOP frw_3_start -> agt_2_perform`, `HOP agt_2_perform -> frw_5_outcome`, `HOP frw_5_outcome -> frw_4_enter` in that order, and the record reads `frw_4_enter` exactly once.
- [x] **`walk` refuses when no path exists and writes nothing.** A fixture on `frw_11_task` walked to `frw_4_enter` exits 1 with `REFUSED-TRANSITION` naming the template file; the record still reads `frw_11_task`.
- [x] **`walk` from NO-POSITION starts at the start.** A fixture with no position walked to `frw_3_start` prints hops beginning `HOP frw_1_task -> frw_2_build` and lands on `frw_3_start`; an inception fixture walked to `hum_2_decision` starts at `frw_1_inception` (the template containing the target).
- [x] **`walk` is idempotent and legitimacy is read from the artefact.** Walking to the node already recorded exits 0 and does not rewrite the file. With a temporary rendered dir whose `task-lifecycle.bpmn` lacks the `frw_2_build -> frw_3_start` flow, the NO-POSITION walk to `frw_3_start` is `REFUSED-TRANSITION` (no path), while the same walk against the real artefact succeeds — the control that proves the refusal came from the artefact, not the tool.
- [x] **The transition table names real nodes.** `fw_instance_node_for_transition` returns `frw_3_start` for captured→started-work, `agt_2_perform` for issues→started-work, `frw_4_enter` for →issues, `frw_8_partial` for →work-completed partial, `frw_11_task` for →work-completed, and the empty string for started-work→captured; every non-empty value is an `id=` in `examples/aef-processes/rendered/task-lifecycle.bpmn`.
- [x] **`fw_instance_walk` never fails the caller, and never hides a refusal.** Returns 0 in all four cases; on success stdout carries `position:` lines; on a refused walk stderr carries `WARNING:` and the tool's `REFUSED-TRANSITION` text and the record is unchanged; on NO-TEMPLATE it prints nothing; with the tool path absent it prints nothing and touches nothing.
- [x] **`update-task.sh` is wired at every named point and still parses.** It sources `lib/instance-position.sh` guarded with `|| true`; `fw_instance_walk` appears at ≥ 7 call sites (status write, battery start, P-010 refusal, P-011 refusal, partial, finalize fresh, finalize re-check); `bash -n` passes; the T-880 static pin (path exists, `frw_7_all` named) still holds.
- [x] **Teeth.** `tools/_t923-framework-writer-teeth.sh` pins all of the above against `mktemp` fixtures and a temporary rendered dir; `PASS n / FAIL 0`.
- [x] **Live: this task's own record is written by the framework.** Driven `started-work → issues → started-work` before close, `get T-923` reads `NODE frw_4_enter` then `NODE agt_2_perform` (each output pasted in `## Updates`); at close the framework walks it to `frw_11_task` in `completed/` (visible in the commit, not in P-011 — verification runs before the move).
- [x] **Live: the one stale record is corrected through the guard.** `walk T-880 frw_11_task` prints `HOP frw_6_run -> frw_7_all`, `-> frw_9_human`, `-> frw_10_finalize`, `-> frw_11_task` and `get T-880` reads `NODE frw_11_task task-lifecycle`; output pasted in `## Updates`, diff in the commit. Not in P-011 (PL-285: a leg pinned to a live task id invalidates itself).

### Human
_None._ Every criterion is a deterministic shell check; the human-visible half is T-884.

## Verification

# T-923 teeth: walk semantics, transition table, never-fail wrapper, wiring pins — all on mktemp fixtures (T-3326).
out=$(bash tools/_t923-framework-writer-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
# The S3 guard is unchanged in verdict: T-882's suite and its mutation run.
out=$(bash tools/_t882-advance-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t882-advance-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
out=$(bash tools/_t880-instance-node-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t881-resolution-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
# Wiring pins: sourced with a guard, ≥7 call sites, parses.
grep -qE 'source "\$FRAMEWORK_ROOT/lib/instance-position.sh".*\|\| true' .agentic-framework/agents/task-create/update-task.sh
test "$(grep -c 'fw_instance_walk ' .agentic-framework/agents/task-create/update-task.sh)" -ge 7
bash -n .agentic-framework/agents/task-create/update-task.sh
bash -n .agentic-framework/lib/instance-position.sh
python3 -m py_compile tools/instance-node.py
# The tool still carries no node id in code (T-882 AC 8 held): control in the artefact first.
grep -qE 'id="(frw|agt|hum)_[0-9]+_[a-z]+"' examples/aef-processes/rendered/task-lifecycle.bpmn
out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))"); ! echo "$out" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b'
# Both bound templates still round-trip.
out=$(python3 tools/instance-node.py roundtrip 2>&1); echo "$out" | grep -q '^ROUNDTRIP-OK task-lifecycle' && echo "$out" | grep -q '^ROUNDTRIP-OK inception-lifecycle' && ! echo "$out" | grep -q 'ROUNDTRIP-FAIL'

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

### 2026-09-29 — two templates share a node id, and the guard had not noticed
- **What changed:** The first inception walk went wrong in a way T-880 and T-882 could not see: `frw_3_start` is a node in BOTH `task-lifecycle` and `inception-lifecycle`, and the S3 core resolved "template of record" as *the first bound template containing the current node* — so an inception walking `inception-lifecycle` was judged by `task-lifecycle`'s flows at its third hop and refused. T-880's "a node is valid if it is in any bound template" was fine for membership and wrong for order. The core now consults every candidate template and takes the hop if any carries the flow, with the template a walk is on consulted first; the refusal lists legal successors per template. Second finding, smaller: T-880's control that pins the P-010 hint reads the FIRST `task-lifecycle node <x>` phrase in `update-task.sh`, and a comment I added earlier in the file matched with `<x> = it`. Reworded the comment rather than the control — the control is right to be literal. Third: T-882's mutation probe searched for the variable name I renamed in the refactor; updated the probe string, the anchor is unchanged.
- **Plan impact:** `walk` was filed as a design question ("place from NO-POSITION or walk the prefix") — resolved as *walk the prefix from the startEvent of the template that contains the target*, so a legacy entity's first framework move prints its real history (six hops for this task, from `frw_1_task` to `frw_4_enter`). The P-011 refusal hop and the battery-start hop mean a task refused by a gate now stands at `frw_6_run`/`agt_2_perform` rather than wherever it was; every later transition walks from there, which is what OBS-433 asked for.
- **Triggered:** Nothing new filed. Shared node ids across templates are worth a note for T-884 (the designer must draw the position on the RIGHT template when an inception is on `frw_3_start`) — recorded here, not as a task, because T-884's ACs are still placeholders and will be written against the tool as it now is.


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

### 2026-09-29 — the framework's verb is a walk, the agent's is a hop
- **Chose:** a separate `walk` verb for the framework (shortest path over the artefact's flows, every hop printed and each taken through the same core as `advance`), `advance` unchanged for a single hop; a refused walk is a `WARNING` and never fails the status change.
- **Why:** the framework knows its target node, not the agent-lane nodes in between; PD-345 rejected multi-hop *advance* because it hides which hop was validated — `walk` prints each one, so the objection does not apply. Status remains governed by `status-transitions.yaml`; the map records position. Making the map refuse a STATUS change is the `strict` rung SD-8 keeps out of scope, and it would also turn every legacy entity's first transition into a failure.
- **Rejected:** (a) `set` (placement) from NO-POSITION at the target node — cheaper, but the record would then say nothing about how the entity got there, and 193 entities would carry a position with no history; (b) a hop table in bash per transition — a successor table outside the artefact, the thing T-882 refused to have in the tool; (c) refusing the status change on a refused walk — `strict`, out of scope, and wrong for the legacy corpus.


## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-29T00:03:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-923-the-framework-is-the-writer-update-tasks.md
- **Context:** Initial task creation

### 2026-09-29T00:09:35Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-29T00:16:44Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** Live proof for AC 9: exercising the writer on this task itself (started-work -> issues -> started-work). Not a real blocker.

### 2026-09-29T00:16:59Z — status-update [task-update-agent]
- **Change:** status: issues → started-work
- **Reason:** Live proof for AC 9, second leg: issues -> started-work is agt_2_perform.

### 2026-09-29 — live evidence for AC 9 and AC 10 [agent]
- **AC 9, leg 1** (`fw task update T-923 --status issues`), framework output verbatim:
  ```
  Status:  started-work → issues
    position: START frw_1_task
    position: HOP frw_1_task -> frw_2_build
    position: HOP frw_2_build -> frw_3_start
    position: HOP frw_3_start -> agt_2_perform
    position: HOP agt_2_perform -> frw_5_outcome
    position: HOP frw_5_outcome -> frw_4_enter
    position: NODE frw_4_enter task-lifecycle (walked 6 hop(s), recorded in .tasks/active/T-923-the-framework-is-the-writer-update-tasks.md)
  ```
  `python3 tools/instance-node.py get T-923` → `NODE frw_4_enter task-lifecycle`
- **AC 9, leg 2** (`--status started-work`):
  ```
  Status:  issues → started-work
    position: HOP frw_4_enter -> agt_2_perform
    position: NODE agt_2_perform task-lifecycle (walked 1 hop(s), recorded in .tasks/active/T-923-the-framework-is-the-writer-update-tasks.md)
  ```
  `get T-923` → `NODE agt_2_perform task-lifecycle`. The third leg (`frw_11_task` in `completed/`) is written by the close itself and is visible in the commit.
- **AC 10** (`python3 tools/instance-node.py walk T-880 frw_11_task`), before: `NODE frw_6_run task-lifecycle`:
  ```
  HOP frw_6_run -> frw_7_all
  HOP frw_7_all -> frw_9_human
  HOP frw_9_human -> frw_10_finalize
  HOP frw_10_finalize -> frw_11_task
  NODE frw_11_task task-lifecycle (walked 4 hop(s), recorded in .tasks/completed/T-880-an-instance-record-exists-and-can-be-cre.md)
  ```
  after: `get T-880` → `NODE frw_11_task task-lifecycle`; the diff is one line.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f73a5777
- **Timestamp:** 2026-09-29T06:59:43Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 16
     - evidence: `out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];prin`

### 2026-09-29T06:59:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
