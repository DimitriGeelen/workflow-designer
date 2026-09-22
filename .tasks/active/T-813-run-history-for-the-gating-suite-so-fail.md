---
id: T-813
name: "Run-history for the gating suite so failure AGE stops being unknowable (F-03)"
description: >
  Value review T-742 F-03: the bridge suite runs 131 passed / 7 failed, exit 1, 742s, and NOTHING schedules it. No test-run artefact exists anywhere in the tree, so the age of the 7 failures is unknowable — the review's words: 'UNMEASURED, not zero'. That absence is also why F-09's golden drift has no knowable age. F-03's recommendation is a caller that re-executes on a schedule PLUS an exit-trap appending the summary line and exit code to a run-history file. Build the run-history half: it is self-contained, it makes age measurable immediately, and it is the prerequisite for anyone trusting a schedule later. Do NOT install a scheduler: cron lives outside the project boundary (T-559) and background installation requires explicit operator instruction.

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
created: 2026-09-22T13:25:28Z
last_update: 2026-09-22T13:25:28Z
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

# T-813: Run-history for the gating suite so failure AGE stops being unknowable (F-03)

## Context

Value review T-742 **F-03**, consequence 3 — *"the mechanism by which every other finding
stays undetected."*

Measured there: one clean end-to-end run gives `bridge round-trip: 131 passed, 7 failed`,
**exit 1, 742 s**. CI is a single `!PushRepository` job with **no command step of any kind**.
And: *"No test-run artefact exists anywhere in the tree, so the age of the 7 failures is
unknowable — UNMEASURED, not zero."* The same absence is why **F-09**'s golden drift has no
datable age either.

F-03 recommends two things: a caller that re-executes on a schedule, **and** an exit-trap
appending the summary and exit code to a run-history file. **This task builds the second.**
The first is not mine — see Decisions.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The runner appends one record per run — timestamp, pass count, fail count, exit code, duration, HEAD sha — to a tracked run-history file
- [x] It records on EVERY exit path, including a failing run and an interrupted one: a history that only captures green runs answers the opposite of the question being asked
- [x] The record is written by an exit trap, not by a line after the last check, so an early `exit` or a signal cannot skip it
- [x] A reader reports the age of the current failure state from that history — the number F-03 calls "UNMEASURED, not zero" becomes a date
- [x] The reader distinguishes NO HISTORY from ZERO FAILURES: an empty file must not read as healthy
- [x] CONTROL: the trap is proven to fire on a failing run and on an interrupt, by driving both in a throwaway copy
- [x] The suite's own pass/fail behaviour is unchanged — exit code identical, no leg added, removed or reordered
- [x] NO scheduler is installed. The cron line is handed to the operator as a copy-pasteable command and left for them (T-559 boundary, and background installation requires explicit instruction)


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-813 legs. Each line's exit code is its own verdict; no chaining. ---
# The recorder must be installed IN the runner, as a trap, on all three signals.
grep -q '_t813_record' tests/run-bridge-tests.sh
grep -qE "^trap '_t813_record" tests/run-bridge-tests.sh
grep -qE "trap '_t813_record 143" tests/run-bridge-tests.sh
# The once-only guard: without it an interrupted run writes two rows.
grep -q '_T813_RECORDED' tests/run-bridge-tests.sh
# Green, RED and INTERRUPTED all recorded; empty history reads as could-not-measure.
./tools/_t813-history-trap-controls.sh
# The reader must exist and be runnable. Exit 3 (no history) is a legitimate state, so this
# leg accepts 0 or 3 and fails on anything else — a crash must not pass as "no history yet".
bash -c 'python3 tools/_t813-suite-age.py >/dev/null 2>&1; rc=$?; test "$rc" -eq 0 -o "$rc" -eq 3'
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

### 2026-09-22 — build the run-history half; do NOT install the scheduler

- **Chose:** the exit-trap recorder and a reader. Left the schedule to the operator.
- **Why not install cron:** `/etc/cron.d/` is outside the project root and **T-559** forbids
  Bash writing there; separately the operator's standing instruction is *"Background
  installation by D-Volt is none, only unless explicitly instructed."* Installing a recurring
  job that runs a 12-minute suite is exactly the kind of thing that instruction exists for.
- **Why the recorder is still worth building alone:** it makes the age measurable the first
  time anyone runs the suite by hand, and it is the prerequisite for trusting a schedule
  later — a scheduled suite with no history would still answer "how long has this been red?"
  with silence.
- **The operator's command, if wanted** (writes outside the project; theirs to run):
  `sudo tee /etc/cron.d/832-bridge-suite <<< '17 4 * * * root cd /opt/832-Workflow-designer && bash tests/run-bridge-tests.sh >/dev/null 2>&1'`

### 2026-09-22 — an exit trap, not a line at the end of the script

- **Chose:** `trap ... EXIT` plus explicit INT and TERM handlers, chained onto the runner's
  pre-existing `rm -rf "$TMP"` cleanup.
- **Why:** the runs most worth recording are exactly the ones a tail-of-script recorder
  drops — a leg that calls `exit`, a Ctrl-C at minute nine, a future scheduler's timeout. And
  the file would still *look* like a clean history, so the gap would be invisible.
- **Chained, not replaced:** bash keeps one handler per signal. A second `trap ... EXIT`
  would have silently discarded the temp-dir cleanup and leaked a directory per run.

### 2026-09-22 — the control found a double-record, and a bash behaviour worth writing down

- **What the control caught:** the INTERRUPTED branch wrote **two** rows. The signal handler
  re-raises so the process dies with the right status, which lets the EXIT trap fire as well.
  Two rows per interrupted run would have doubled the run count and made "how long has it
  been red" answerable only by a human noticing the pairs. Fixed with a once-only guard.
- **Found by driving it, not by reading it.** A control that only exercised a green run would
  have passed, and would also have passed against the naive tail-of-script recorder this
  design was chosen over.
- **Bash behaviour recorded in the control, not worked around:** a signal is deferred until
  the running foreground command returns. The synthetic sleeps, so the handler fires when the
  sleep ends. That is bash, not a defect, and it is benign for the real suite whose legs are
  seconds long — a TERM is handled at the next leg boundary. The control waits the command
  out rather than pretending signals are instantaneous.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-813 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T13:25:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-813-run-history-for-the-gating-suite-so-fail.md
- **Context:** Initial task creation
