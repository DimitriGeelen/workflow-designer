---
id: T-815
name: "The bridge suite rewrites a tracked fixture, and that fixture has been stale since T-690"
description: >
  Surfaced by T-813's first recorded suite run, not by a value-review finding. Running tests/run-bridge-tests.sh modifies tests/fixtures/exported/t423-carrier-witness.bpmn in the working tree: it regenerates the file with extensionElements before conditionExpression, while the committed copy has the opposite order. TWO separate defects. (1) STALENESS: the fixture was last committed 2026-08-23 (89bdecdc, T-423); the emitter ordering changed 2026-09-09 (66e04cff, T-690, 'extensionElements before conditionExpression'). So the tracked witness has disagreed with the emitter for 17 days and nothing reported it — a witness fixture that does not match what the emitter produces is not witnessing anything. (2) SIDE EFFECT ON A TRACKED FILE: a test suite that rewrites a committed file makes 'git status is clean' untrue after every run, which trains readers to ignore a dirty tree — and a dirty tree is how the retention-sweep deletions and the 1052 untracked files already hide. Decide per defect: regenerate and commit the fixture, and either make the suite write its witness to a scratch path or declare the regeneration intentional and gitignore it. Reverted rather than committed under T-813: it is not that task's change and the right disposition is a judgement, not a cleanup.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh, tools/_t813-history-trap-controls.sh, tools/_t813-suite-age.py, tools/_t815-witness-guard-controls.sh, tools/_t815-witness-ordering-guard.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T13:45:36Z
last_update: 2026-09-22T14:31:32Z
date_finished: 2026-09-22T14:31:32Z
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

# T-815: The bridge suite rewrites a tracked fixture, and that fixture has been stale since T-690

## Context

Surfaced by T-813's first recorded suite run, not by any value-review finding.

**CORRECTION TO THIS TASK'S OWN FILING.** I filed it naming *two* defects, and the second was
wrong. I called the suite rewriting a tracked file a defect; it is documented, intentional
behaviour — `tests/run-bridge-tests.sh:1247`:

> "It refreshes tests/fixtures/exported/t423-carrier-witness.bpmn on success. Exports are
> deterministic, so that file only moves when the emitter does — **and when it moves, it
> should**."

The witness is deliberately not a checked-in snapshot. `_t423-carrier-agreement-cdp.mjs`
exports all 24 maps through a real browser on every run, precisely so the artefact under test
is what the *current* source produces — *"wiring the guard against a checked-in witness would
make this leg green on a snapshot."* The refresh is the mechanism working.

**There is one defect, and it is the first one.** T-690 (`66e04cff`, 2026-09-09) changed the
emitter ordering to put `extensionElements` before `conditionExpression`. The witness was last
committed by T-423 (`89bdecdc`, 2026-08-23). So the emitter moved, the witness correctly moved
with it on the next run — and nobody committed it. The tracked copy has disagreed with the
emitter for **17 days**, and the only thing that noticed was a dirty `git status` after a
13-minute suite nobody schedules.

Regenerated: the diff is exactly 9 `conditionExpression` lines changing position. Same
content, T-690's ordering. Nothing else moved.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The regenerated fixture is compared against the committed one and the difference is explained, not merely refreshed — a witness that silently drifted once can drift again
- [x] The staleness is dated from the emitter change (T-690, `66e04cff`, 2026-09-09) against the fixture's last commit (T-423, `89bdecdc`, 2026-08-23), so the 17-day blind window is recorded rather than tidied away
- [x] ~~`git status` is clean immediately after a full suite run~~ **WITHDRAWN — the premise was wrong.** The refresh is documented, intentional behaviour and the witness is deliberately not a snapshot; a run that changes it is the mechanism working. Withdrawn rather than quietly dropped, because an AC written on a false premise is worth more as a correction than as a deletion.
- [x] Whichever disposition is chosen, something MECHANICAL prevents the next silent drift: a check that the committed witness matches what the emitter currently produces
- [x] CONTROL: that check is proven to fail when the witness and the emitter disagree, by making them disagree in a throwaway copy


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-815 legs. Each line's exit code is its own verdict; no chaining. ---
# The committed witness must satisfy the emitter's CURRENT ordering invariant (T-690).
# This is the check whose absence let the witness sit 17 days out of step.
python3 tools/_t815-witness-ordering-guard.py
# Controls in their own probe: live witness passes, an in-flow swap fails, and the REAL
# pre-T-690 bytes at 89bdecdc fail — the last replays the actual drift rather than a mutant.
./tools/_t815-witness-guard-controls.sh
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

### 2026-09-22 — I filed this naming two defects; one of them was not a defect

- **Withdrawn:** "the suite rewrites a tracked file" as a defect. It is documented,
  intentional behaviour — the witness is deliberately not a checked-in snapshot, because
  *"wiring the guard against a checked-in witness would make this leg green on a snapshot."*
  The refresh is the mechanism working.
- **Why say so rather than quietly drop it:** the AC is struck through in place. A filing
  written on a false premise is worth more as a visible correction than as a deletion — this
  is the fourth count or claim this session that measurement moved, and the pattern only
  teaches anything if the misses stay legible.
- **What remains is one real defect:** T-690 changed the emitter and nobody committed the
  witness it invalidated. 17 days.

### 2026-09-22 — a structural guard, not a re-export

- **Chose:** assert the ordering invariant directly on the committed bytes.
- **Why not "re-export and diff":** that needs a real browser and ~300s. A guard that
  expensive runs as rarely as the 742-second suite does — which is the condition being fixed,
  not a fix. This runs in milliseconds and catches the class that actually occurred.
- **Stated limit, not hidden:** it cannot catch every possible drift; only the emitter can.
  It catches this class, often enough to matter.
- **Vacuity guarded:** if no flow in the witness carries both children, the guard FAILS rather
  than passing over an unexercised invariant.

### 2026-09-22 — the control replays the real drift, and its stimulus took three attempts

- **Branch C uses the actual pre-T-690 bytes** at `89bdecdc`. The usual objection to git-ref
  fixtures — a `HEAD~N` mutant expires silently — does not apply to a pinned immutable sha,
  and the branch skips with a stated reason if the object is ever unreachable rather than
  passing on absence.
- **Branch B's stimulus failed twice first.** Swapping the first matching pair in the document
  spanned two different elements, so the guard correctly ignored it. Targeting the first
  sequence flow hit one of the 19 that carry no pair at all. Only the third attempt — the
  first flow that actually carries both — produced the condition the guard examines. Same
  lesson as T-809's control B, one file over: **a stimulus must fire where the subject
  looks.**

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-815 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T13:45:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-815-the-bridge-suite-rewrites-a-tracked-fixt.md
- **Context:** Initial task creation

### 2026-09-22T13:48:02Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f27a511d
- **Timestamp:** 2026-09-22T14:31:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T14:31:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
