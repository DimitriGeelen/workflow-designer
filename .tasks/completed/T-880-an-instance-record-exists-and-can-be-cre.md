---
id: T-880
name: "An instance record exists and can be created against a template"
description: >
  arc-005 S2/B5. CONTINGENT on T-878 (instance-identity inception) returning GO. If
  T-878 returns NO-GO, or returns a design different from whatever anyone assumed
  here, this task is DELETED OR REWRITTEN — not adapted. It carries no design of its
  own on purpose: naming the storage home or identity scheme here would pre-commit
  the very thing T-878 exists to decide.

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: [arc:process-instances]
components:
  - tools/instance-node.py
  - tools/_t880-instance-node-teeth.sh
  - examples/aef-processes/template-binding.yaml
  - .agentic-framework/agents/task-create/update-task.sh
  - tools/README.md
related_tasks: []
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
created: 2026-09-26T22:43:11Z
last_update: 2026-09-28T23:05:29Z
date_finished: 2026-09-28T23:05:29Z
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
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 2
  F3: 3
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T22:59:00Z'
cost_estimate_proposed:
  - ts: '2026-09-28T23:04:30Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (5-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=315,acs=8)
    rubric_sha: e4a00f38e801
---

# T-880: An instance record exists and can be created against a template

## Context

**Rewritten 2026-09-28 against T-878's GO, not adapted to it** — T-880's own body reserved that:
a different design means rewrite. T-878 measured three assumptions and **two came back FALSE, both
in the cheap direction**, so what this task delivers is materially smaller than what it was filed
with.

| assumption | verdict | consequence for this task |
|---|---|---|
| A2 — an instance needs a new identifier | **FALSE** | `T-873` is already stable, unique, human-legible and referenced corpus-wide. Minting a uuid beside it would be a second id for one object. **The entity IS the instance.** No instance file, no identity scheme. |
| A3 — the template binding must be authored | **FALSE** | "which template" is DERIVABLE from `workflow_type`, a closed set with one template per entity kind. **Nothing to author.** |
| A1 — position can be computed from existing state | **FALSE** | The one thing that survives. |

**So this task delivers ONE new thing: a recorded current node per governed entity.**

**Why it must be recorded rather than computed** — re-measured under T-910's session rather than
inherited from the inception's prose:

- `examples/aef-processes/rendered/task-lifecycle.bpmn` carries **15 lane-prefixed flow nodes**
  (`frw_1_task`, `agt_1_write`, `hum_1_human`, `frw_2_build`, … — 1 start, 1 end, 2 serviceTask,
  1 userTask, 6 scriptTask, 4 exclusiveGateway).
- `update-task.sh`'s transition dispatch knows **3** statuses (`started-work`, `issues`,
  `work-completed`), ~5 counting `captured` and `partial-complete`.
- **There is no mapping table anywhere in the tree.** 15 into 5 does not divide, and nothing
  records which of the 15 an entity is on. Position is not derivable; it has to be written down.

**The template of record is `examples/aef-processes/rendered/<id>.bpmn`** — the AEF-pinned seam
artefact, not the editor snapshot and not the corpus YAML. This matters and was nearly a trap:
`examples/aef-processes/task-lifecycle.workflow.yaml` carries **zero** lane-prefixed node ids (its
ids are `c_sovereignty`, `c_acceptance`, …), while `.editor-versions/task-lifecycle/v3.bpmn` and
the rendered BPMN both carry the same 15. A current-node value pointing into the YAML would refer
to nodes that do not exist in the pinned artefact.

**A live defect this sits on top of.** `update-task.sh:249` guards on
`.context/designer/projects/aef-task-lifecycle/meta.json`, which **does not exist** — the
directory holds `audit-process/`, `t101-review-task-lifecycle/` and five others, but no
`aef-task-lifecycle/`. Positive control: `audit-process/meta.json` IS present, so the path shape
is right and only the name is wrong. That hint has therefore **never executed in this project**,
which makes T-878's "no binding exists" more completely true than the inception first represented
it. It is the natural hook point for this work and must be resolved rather than built beside.

**Unblocked by:** T-878 GO (2026-09-27). Arc slice S2 / manifest item B5.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
### Agent
- [x] A governed entity can carry a **recorded current node**, and the value is constrained to node ids that exist in its bound template. An arbitrary string is refused, naming the template it was checked against
- [x] The **template binding is DERIVED from `workflow_type`**, never authored — proving A3. The derivation names the file it resolved to, and resolves to `examples/aef-processes/rendered/<id>.bpmn` (the AEF-pinned artefact), not the editor snapshot and not the corpus YAML
- [x] **No new identifier is minted** — proving A2. The entity's existing id is the instance identity. A grep for a new uuid/instance-id field in the delivered surface returns nothing
- [x] `workflow_type` values with **no template** are a distinct, named state from entities that have a template and no recorded position. NOT EVALUATED is not PASSED (T-3105); the two must not collapse into one silent absence
- [x] The dead hint at `update-task.sh:249` is **resolved, not bypassed**: either repointed at a path that exists or removed with a reason. A verification leg proves the chosen branch — if repointed, that the guard now fires; if removed, that no caller depends on it
- [x] **Proved by mutation, with a control set that runs first.** Feed a node id absent from the template and the setter refuses naming it; feed a valid one and it is recorded. Every mutation is asserted applied before its result is scored, and a broken harness reports `MUTATION SETUP BROKEN` rather than scoring kills

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

## Verification

# T-880 teeth: controls first, then refusals. Property-pinned, no live corpus counts (T-3326).
out=$(bash tools/_t880-instance-node-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t880-instance-node-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# The derivation resolves to the AEF-pinned rendered artefact, not the YAML and not the editor snapshot.
python3 tools/instance-node.py bind build | grep -q '^examples/aef-processes/rendered/task-lifecycle.bpmn$'
# NO-TEMPLATE is its own state and its own exit code (3), distinct from NO-POSITION (0) and NO-ENTITY (2).
python3 tools/instance-node.py bind not-a-workflow-type; test $? -eq 3
# No new identifier field in the delivered surface (comments and docstring excluded — the prose names IW-3 on purpose).
# Control first (PL-328): the SAME pattern must hit where an identifier field really is written.
grep -qE "(uuid|instance_id|instanceId)['\":=]" examples/aef-processes/rendered/task-lifecycle.bpmn
! grep -vE '^\s*#' tools/instance-node.py | grep -qE "(uuid|instance_id|instanceId)['\":=]"
# The repointed hint guards on a file that exists and names a node that is in it.
test -f examples/aef-processes/rendered/task-lifecycle.bpmn && grep -q 'id="frw_7_all"' examples/aef-processes/rendered/task-lifecycle.bpmn && grep -q 'task-lifecycle node frw_7_all' .agentic-framework/agents/task-create/update-task.sh
bash -n .agentic-framework/agents/task-create/update-task.sh
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

### 2026-09-29 — built on the reduced scope, and the reduction held
- **What changed:** Nothing in T-878's F3 needed revisiting: the template half derived cleanly from `workflow_type` through a seven-row table, and the recorded half is one frontmatter line. What the build ADDED to the design is the inception case: an inception instantiates two templates (T-878 F3), so the binding is a list and a node is valid if it is in any bound template, with the reader naming which one it matched. A fourth reader state appeared that IW-5's three did not name: `NODE <id> STALE` — recorded, and no longer in any bound template because the artefact was re-rendered under it. Reported with exit 1 rather than folded into NO-POSITION.
- **Plan impact:** None to scope. The dead hint (update-task.sh) was REPOINTED, not removed: it now guards on the rendered artefact and names `frw_7_all` ("All gates pass?"), which is the gateway the AC refusal actually is. Proved live once on a throwaway fixture (rc=1, "Map: task-lifecycle node frw_7_all…" on stderr); the standing pin is static (path exists, node id is in it) because a dynamic leg would have to write into `.tasks/active/` on every verification run and left a `.context/locks/` file behind even in the one-off.
- **Triggered:** Nothing filed. The mutation run caught one classification of mine: `stale_recorded_node_reported` exercises the reader, which the mutant does not touch, so it belongs with the controls — the same correction T-866's suite records four times.

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-26T22:43:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-880-an-instance-record-exists-and-can-be-cre.md
- **Context:** Initial task creation

### 2026-09-27T22:49:06Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-09-28T22:58:48Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fab716b8
- **Timestamp:** 2026-09-28T23:05:33Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 5
     - evidence: `python3 tools/instance-node.py bind build | grep -q '^examples/aef-processes/rendered/task-lifecycle.bpmn$'`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 11
     - evidence: `! grep -vE '^\s*#' tools/instance-node.py | grep -qE "(uuid|instance_id|instanceId)['\":=]"`

### 2026-09-28T23:05:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
