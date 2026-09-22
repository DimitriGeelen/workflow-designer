---
id: T-817
name: "Wire four proven-working CDP probes into the gating suite (F-08 inventory closing part of F-07)"
description: >
  F-08 measured 118 instruments that read as standing guards with no live caller — coverage written, run once at task completion, never wired to anything that re-runs it. F-07 separately measured that the direct-manipulation surface is named by no gating leg. Those connect: several of the unwired instruments are CDP probes for exactly those gestures. Measured all 8 named probes rather than assuming. SIX target src/ directly; two need a served gallery whose build/gallery/designer.html is dated Aug 14, 39 days stale, and which I must not rebuild — serving it would test old bytes, the FP-009 defect. Of the six: FOUR PASS (respaceColumns spacing T-115, selection Align/Distribute T-134, edge Straighten T-137, save-target binding T-263) and TWO FAIL on real assertions (_endpoint-overlap expected e_11; _saveproject pass:false). Wire the four that pass so they cannot rot unobserved; file the two failures with the measurement rather than fixing blind.

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
created: 2026-09-22T14:45:06Z
last_update: 2026-09-22T14:45:06Z
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

# T-817: Wire four proven-working CDP probes into the gating suite (F-08 inventory closing part of F-07)

## Context

**F-07 and F-08 are the same hole from opposite sides.**

F-07: the direct-manipulation surface — click-to-place, node drag, connect mode, lane resize,
the 9-binding keyboard surface — is *"named by nothing"* across all 107 gating legs, while the
suite reports 131 passes. *"These are the gestures that are the editor; a regression in
click-to-place is invisible to 138 green legs."*

F-08: **118 instruments read as standing guards and nothing can re-run them** — *"coverage
that was written, ran once at task completion, and was never wired to anything that re-runs
it."* Several of those are CDP probes for exactly the gestures F-07 says are uncovered.

So the fix needed no new tests. It needed running the ones that exist and wiring the ones that
work — and finding out which is which is the substance, because a probe wired on the strength
of its filename is the F-08 condition with extra steps.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each of the four probes is invoked by `tests/run-bridge-tests.sh` as its own leg, following the `_t423` pattern already in the file (timeout, captured output, a FAIL message naming what broke and how to re-run it)
- [x] Each was RUN and observed to pass before being wired — no probe is wired on the strength of its filename or its task's claim
- [x] The unwired-guard census reflects the change: these four stop counting as having no live caller
- [x] The two failing probes and the two gallery-blocked ones are filed with their measured cause, not quietly skipped
- [x] CONTROL: a wired leg is proven to FAIL the suite when its probe fails, so the wiring is load-bearing rather than decorative
- [x] The suite's existing legs are untouched — no leg reordered, removed, or given a different timeout


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-817 legs. Each line's exit code is its own verdict; no chaining. ---
bash -n tests/run-bridge-tests.sh
./tools/_t817-wiring-controls.sh
# The four wired probes must each still pass on their own. Slow (real browser each), but
# these ARE the deliverable — wiring probes without re-running them is the defect being fixed.
timeout 180 node tools/_horizontal-spacing-verify-cdp.mjs
timeout 180 node tools/_selection-align-verify-cdp.mjs
timeout 180 node tools/_edge-straighten-verify-cdp.mjs
timeout 180 node tools/_t263-save-target-cdp.mjs
# The two RED probes must stay OUT of the runner until T-818 diagnoses them: wiring a red
# probe converts an unobserved failure into a permanently red leg (OBS-293).
bash -c 'test "$(grep -c "_endpoint-overlap-verify-cdp.mjs\|_saveproject-verify-cdp.mjs" tests/run-bridge-tests.sh)" = "0"'
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

### 2026-09-22 — run all eight before wiring any

- **Chose:** execute every named probe first, wire only what passed.
- **Why:** F-08's whole finding is instruments trusted on prose rather than execution — *"their
  WIRED verdict rests entirely on prose."* Wiring on the strength of a filename would have
  reproduced that defect while appearing to fix it.
- **What it found**, which assumption would have got wrong in three different ways:

| probe | result | disposition |
|---|---|---|
| `_horizontal-spacing` (T-115 respaceColumns) | PASS | wired |
| `_selection-align` (T-134 Align/Distribute) | PASS | wired |
| `_edge-straighten` (T-137 Straighten) | PASS | wired |
| `_t263-save-target` (T-263 binding) | PASS | wired |
| `_endpoint-overlap` | **FAIL** — expects `e_11` | T-818 |
| `_saveproject` | **FAIL** — `pass:false` | T-818 |
| `_autoload`, `_autosave` | blocked — need a served gallery | below |

### 2026-09-22 — the two red probes are filed, not wired

- **Why not wire them red:** it converts an unobserved failure into a permanently red leg, and
  **OBS-293** records that a leg which is always red teaches readers to rerun rather than to
  look. The silence would move, not end.
- **Why not fix them blind:** neither is an infrastructure error — both drive a real browser
  and name the offending element in JSON. Whether the *editor* regressed or the *expectation*
  went stale is not knowable from the tree, because nothing recorded when they went red. Same
  "UNMEASURED, not zero" shape F-03 named for the suite's own 7 failures.
- Filed as **T-818** with the measurement attached.

### 2026-09-22 — the two gallery probes stay blocked, and the reason is F-01's family

- `_autoload` and `_autosave` need a served gallery at `localhost:8834`, whose docroot is
  `build/gallery/`. That `designer.html` is dated **2026-08-14 — 39 days stale**, 953 KB
  against src's 997 KB.
- **Serving it would test old bytes** — precisely FP-009, *"a faithful test of old code."*
  Rebuilding it is not the agent's call. So they stay unwired, with the reason recorded in the
  runner rather than in a comment nobody reads.
- Worth noting: their failure message says *"editor did not finish loading"* when the real
  cause is *"nothing is serving"*. Two different conditions, one message — the same
  conflation class this session has hit repeatedly.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-817 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T14:45:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-817-wire-four-proven-working-cdp-probes-into.md
- **Context:** Initial task creation
