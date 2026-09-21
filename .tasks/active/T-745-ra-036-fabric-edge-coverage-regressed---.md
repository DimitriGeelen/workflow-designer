---
id: T-745
name: "RA-036: fabric edge coverage regressed - 78 of 379 cards carry no dependency
  edges"
description: >
  Regression of RA-002/T-698, which was closed. The audit structure section reports
  [WARN] Fabric: 78/379 cards have no edges.

status: issues
workflow_type: refactor
owner: agent
horizon: now
tags: [audit-remediation, cycle-1]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T07:58:42Z
last_update: '2026-09-21T20:24:53Z'
date_finished:
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
  - ts: '2026-09-21T08:00:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:01:03Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 5
    rationale: blast_radius=absent (no-signal); tier=3 (no-signal); effort=5 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/concerns.yaml,.fabric/components/tools-_t774-create-task-substitution-probe.yaml);
      tier=3 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-745: RA-036: fabric edge coverage regressed - 78 of 379 cards carry no dependency edges

## Context

### Verbatim tool output

```
[WARN] Fabric: 78/379 cards have no edges
       Evidence: Graph coverage below target
       Mitigation: Run: fw fabric enrich
```

### The invariant that is not held

The component fabric claims to be a structural topology map, but 78 of 379 cards assert no relationship in either direction. A card with no edges contributes nothing to `fw fabric deps`, `impact` or `blast-radius` — the three reads the fabric exists to serve. Coverage of *registration* (379/379) is being reported as if it were coverage of *topology*, which it is not.

### Root-cause links

Regression of RA-002 (T-698, work-completed). Sibling: RA-003/T-699 (fabric drift).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The check's threshold is the thing that is wrong, and it is filed rather than moved.**
      Satisfied through this criterion's own escape clause, not through a PASS.

      Two findings, both measured:

      1. **The check is not in `--section structure`.** That section runs 12 checks and none
         is the fabric-edge check; the warning is emitted elsewhere in `audit.sh`. The AC's
         premise was wrong, which is recorded rather than quietly corrected.
      2. **The check cannot pass in this project.** Its bound is absolute —
         `fabric_unenriched -gt 10` warns — so against 394 cards it demands 97.5% edge
         coverage. The measured structural floor is **41**: of 78 edgeless cards, 41
         reference a path under `.agentic-framework/`, and those edges are DETECTED and then
         discarded, because registration of a vendored target is refused:

         ```
         REJECT: vendored framework copy — .agentic-framework/bin/fw
           Register the upstream framework file instead:
           fw fabric register bin/fw
         ```

         `bin/fw` does not exist at a vendored consumer's root, so the remedy the rejection
         names is unavailable and the dependency is permanently unrepresentable. 41 >= 10.

      **Threshold not moved. No card marked `standalone: true`. No non-component
      registered.** Filed as **G-074**, whose closure condition requires the check to reach
      PASS without either of those two moves.
- [ ] **FAILED — twice, and deliberately not forced to green a third time.**

      | point | edgeless | cards |
      |---|---|---|
      | cycle-1 baseline | 78 | 379 |
      | T-698 close (2026-09-16) | 73 | — |
      | **this run, start** | **83** | 386 |
      | after `fw fabric enrich` (attempt 1) | 79 | 390 |
      | after registering 4 real detected edge targets + enrich (attempt 2) | **78** | 394 |

      Command: `python3 -c` over `.fabric/components/*.yaml`, counting cards where
      `len(depends_on) + len(depended_by) == 0`.

      The criterion requires **strictly** lower than 78. 78 is not. **Failed by one.**

      **Why there is no third attempt.** The remaining headroom is not topology, it is
      bookkeeping: registering files that are not really components, or marking cards
      `standalone: true`. Either would move the number without changing the graph, which is
      the exact move AC1 forbids. Two attempts, both honest, both short — recorded as a
      failure rather than closed by the means available.

      What the two attempts DID buy, and it is not nothing: **+30 real edges**, and the
      discard count fell 169 -> 148. Four genuinely-depended-upon targets now have cards.
      The count moved 83 -> 78 while the population grew by 8 cards.
- [x] **Both, and the second is the mechanism.**

      **T-698's closure condition could not prevent recurrence.** Its three ACs were: count
      strictly below 78; `fw fabric enrich` run and output recorded; residue enumerated by
      name. All three are **level** checks on a snapshot. None constrains the RATE at which
      new edgeless cards appear. T-698 drained the pool and left the tap open — the same
      shape as L-302 (*fix the generator before shipping the detector*), one layer out: it
      fixed the mess, not the thing producing it.

      **New cards have been added edgeless since — including four by me, today.** The
      population went 379 -> 386 between T-698's close and this run's start, and 73 -> 83.
      `fw fabric register` creates a card and the enricher runs separately, so a tool
      registered and never enriched is edgeless by default.

      Checked against myself first: `_t770` (2 edges) and `_t771` (3) are fine, while
      `_t774`, `_t775`, `_t776` and `_t777` are all at zero — registered this session. They
      are **still** at zero after two enrich passes, and that is the diagnostic that
      explains the whole class: their only dependencies are `create-task.sh` and `fw`, both
      vendored, both permanently unregisterable. They can never carry an edge.

      So the regression is not drift to be swept up periodically. Every instrument this
      project builds against its own framework arrives permanently edgeless, and the metric
      rises monotonically with the number of instruments. That is G-074.


## Failure mode (recorded per the autonomous mandate)

**AC2 failed on two attempts and the task is parked, not closed.**

- Attempt 1 — `fw fabric enrich`: 83 -> 79. Only 2 edges added on the first pass; 169
  discarded against 79 unregistered targets.
- Attempt 2 — register the four highest-multiplicity REAL detected edge targets, re-enrich:
  79 -> 78. +30 edges total, discards 169 -> 148.
- Target: strictly < 78. Short by one.

**The wall is structural, not effort.** 41 of the 78 remaining edgeless cards depend only on
vendored framework paths, whose edges the fabric detects and then discards by design. No
amount of further enrichment reaches the target; only bookkeeping would, and AC1 forbids it.

**Not attempted, and why:** marking cards `standalone: true` (the check honours that flag and
excludes them from the denominator) would take the count under 78 immediately. It is the
cleanest available route to green and it is not taken, because it changes what is counted
rather than what is true — and an agent that relaxes the check it is failing has certified
its own work.

**Disposition:** parked at `issues`. AC1 and AC3 are met; AC2 is met only if G-074 is ruled
on, because the target is unreachable while the check's denominator includes a class of card
that cannot carry an edge.

## Verification

python3 -c "import os,yaml; D='.fabric/components'; n=sum(1 for f in os.listdir(D) if f.endswith('.yaml') and not ((lambda c: (c.get('depends_on') or [])+(c.get('depended_by') or []))(yaml.safe_load(open(os.path.join(D,f),encoding='utf-8')) or {}))); print('edgeless', n); assert n <= 78, 'edgeless count regressed above the cycle-1 baseline'"
python3 -c "import yaml; c=yaml.safe_load(open('.context/project/concerns.yaml'))['concerns']; assert any(x.get('id')=='G-074' for x in c if isinstance(x,dict)), 'G-074 missing'"
grep -q 'standalone' .fabric/components/tools-_t774-create-task-substitution-probe.yaml && exit 1 || exit 0

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
     fw inception decide T-745 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:58:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-745-ra-036-fabric-edge-coverage-regressed---.md
- **Context:** Initial task creation

test "$(cd /opt/832-Workflow-designer && .agentic-framework/bin/fw fabric drift 2>&1 | grep -c 'no fabric card')" -ge 0

### 2026-09-21T15:19:53Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-21T15:26:48Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** AC2 failed twice: edgeless count 83 -> 79 -> 78, target strictly < 78. The wall is structural — 41 of 78 remaining edgeless cards depend only on vendored framework paths whose edges the fabric detects and then discards by design. G-074 filed; threshold not moved, no card marked standalone.
