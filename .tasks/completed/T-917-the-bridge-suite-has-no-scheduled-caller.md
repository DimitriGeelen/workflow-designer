---
id: T-917
observation: OBS-256
name: "THE BRIDGE SUITE HAS NO SCHEDULED CALLER. 94 legs, the standing evidence that
  the AEF seam is intact, and nothing runs it: no cron, no git hook, no CI. Measured
  2026-08-15 by searching the whole tree for 'run-bridge-tests' — every hit is prose
  or episodic memory. Subtract an agent choosing to type the command and it does not
  execute. Surfaced by AEF's question at rail 11919 ('subtract the tests, and is anything
  left calling it?'), asked about their own subsystem; the same question turned on
  my tree gives a worse answer than theirs, because their subsystem at least had health
  checks executing against it. THIS COMPOUNDS WITH TWO PROPERTIES ALREADY RECORDED
  AND NOT ACTED ON. (1) The suite is not deterministic under repetition — four consecutive
  runs on an unchanged tree gave 79/2, 80/1, then 82/0 twice, and the differing leg
  was never identified by name. (2) It launches a browser per CDP probe and gains
  a probe roughly every task, so cost grows one browser launch per task; wall-clock
  went 103s to 168s when 24 instruments were wired in T-509. Unrun plus non-deterministic
  plus growing interact specifically: with no scheduled baseline, the first person
  to run it after a gap cannot separate a real red from the flake, and the cheapest
  reading of a lone red is 'flake' — the dangerous direction. NOT FIXED HERE and deliberately
  not started: installing a scheduled caller means /etc/cron.d, which is outside the
  project boundary and therefore an operator action, and the honest fix may be to
  make the suite cheap and deterministic FIRST rather than to schedule something that
  will be dismissed. Needs an operator decision on which comes first. — CORRECTED
  2026-08-15 by T-526, and the correction matters more than the original. (a) THIS
  OBSERVATION WAS FACTUALLY WRONG when filed: the claim that the differing leg 'was
  never identified by name' was true of OBS-250 (08:59Z) but had ceased to be true
  at 11:51Z, when OBS-255 localised the flake to _t358-teeth.py case 5 — seven hours
  before this entry asserted the question was still open. The same false claim was
  carried to AEF at rail 11924 and corrected to them at rail 11929. The cause is structural,
  not careless: this inbox has no cross-referencing, so nothing links entries on the
  same subject and nothing flags a new entry that reopens a resolved one; both read
  as 'pending' and the contradiction is invisible, with OBS-250 and OBS-255 four entries
  apart in the same file. (b) The 168s cost figure is STALE BY ROUGHLY 2x: measured
  305-315s, mean 309s, across five runs. (c) Measured determinism is worse than 'a
  flake': 2 of 5 runs red on TWO DIFFERENT legs, neither reproducing, red rate 40%
  and per-leg reproducibility zero. (d) The blocking sub-defect is now named — 66
  report FAIL calls against 4 show_output calls, so 62 legs discard the evidence of
  their own failure, and 6 of the 10 CDP legs (all of them AEF-seam conformance probes)
  redirect to /dev/null. Both failures in the measurement were uninvestigable from
  their own output. Whether the non-determinism is instrument-side or subject-side
  CANNOT be answered until that is fixed, which is why it is the prerequisite rather
  than the flake itself."
description: >
  Promoted from observation OBS-256

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
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
created: 2026-09-28T13:27:41Z
last_update: 2026-09-28T22:14:38Z
date_finished: 2026-09-28T22:14:38Z
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
  - ts: '2026-09-28T22:10:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-917: THE BRIDGE SUITE HAS NO SCHEDULED CALLER. 94 legs, the standing evidence that the AEF seam is intact, and nothing runs it: no cron, no git hook, no CI. Measured 2026-08-15 by searching the whole tree for 'run-bridge-tests' — every hit is prose or episodic memory. Subtract an agent choosing to type the command and it does not execute. Surfaced by AEF's question at rail 11919 ('subtract the tests, and is anything left calling it?'), asked about their own subsystem; the same question turned on my tree gives a worse answer than theirs, because their subsystem at least had health checks executing against it. THIS COMPOUNDS WITH TWO PROPERTIES ALREADY RECORDED AND NOT ACTED ON. (1) The suite is not deterministic under repetition — four consecutive runs on an unchanged tree gave 79/2, 80/1, then 82/0 twice, and the differing leg was never identified by name. (2) It launches a browser per CDP probe and gains a probe roughly every task, so cost grows one browser launch per task; wall-clock went 103s to 168s when 24 instruments were wired in T-509. Unrun plus non-deterministic plus growing interact specifically: with no scheduled baseline, the first person to run it after a gap cannot separate a real red from the flake, and the cheapest reading of a lone red is 'flake' — the dangerous direction. NOT FIXED HERE and deliberately not started: installing a scheduled caller means /etc/cron.d, which is outside the project boundary and therefore an operator action, and the honest fix may be to make the suite cheap and deterministic FIRST rather than to schedule something that will be dismissed. Needs an operator decision on which comes first. — CORRECTED 2026-08-15 by T-526, and the correction matters more than the original. (a) THIS OBSERVATION WAS FACTUALLY WRONG when filed: the claim that the differing leg 'was never identified by name' was true of OBS-250 (08:59Z) but had ceased to be true at 11:51Z, when OBS-255 localised the flake to _t358-teeth.py case 5 — seven hours before this entry asserted the question was still open. The same false claim was carried to AEF at rail 11924 and corrected to them at rail 11929. The cause is structural, not careless: this inbox has no cross-referencing, so nothing links entries on the same subject and nothing flags a new entry that reopens a resolved one; both read as 'pending' and the contradiction is invisible, with OBS-250 and OBS-255 four entries apart in the same file. (b) The 168s cost figure is STALE BY ROUGHLY 2x: measured 305-315s, mean 309s, across five runs. (c) Measured determinism is worse than 'a flake': 2 of 5 runs red on TWO DIFFERENT legs, neither reproducing, red rate 40% and per-leg reproducibility zero. (d) The blocking sub-defect is now named — 66 report FAIL calls against 4 show_output calls, so 62 legs discard the evidence of their own failure, and 6 of the 10 CDP legs (all of them AEF-seam conformance probes) redirect to /dev/null. Both failures in the measurement were uninvestigable from their own output. Whether the non-determinism is instrument-side or subject-side CANNOT be answered until that is fixed, which is why it is the prerequisite rather than the flake itself.

## Context

**Outcome: the MONITOR is scheduled, the SUITE deliberately is not — and the measurement says why.**

OBS-256's claim is confirmed: `run-bridge-tests` appears in fabric cards, tests, tools, episodics
and learnings, and in **zero** schedulers. But reading the run history T-813 already records turned
a one-line fix into a refusal.

### What `tests/.run-history.tsv` says (12 runs, 2026-09-22 → 09-27)

| exit | passed | failed | secs |
|---|---|---|---|
| 1 | 131 | 7 | 784 |
| 1 | 133 | 10 | 810 |
| 1 | 142 | 9 | 1045 |
| **143** | 120 | 21 | 600 |
| **0** | **71** | **9** | **205** |
| **0** | **71** | **9** | **200** |
| 1 | 121 | 30 | 703 |
| 1 | 122 | 29 | 687 |
| **143** | 102 | 14 | 558 |
| 1 | 120 | 31 | 680 |
| 1 | 119 | 32 | 650 |
| **143** | 116 | 28 | 687 |

Three facts, each of which alone would make a schedule the wrong move:

1. **RED on all 12 runs**, 7 → 32 failures, since recording began. A nightly job would be red on
   day one and every day after — OBS-293's rail that teaches readers to ignore it.
2. **Two runs exited 0 while reporting 9 failures.** The suite's last line is `[ "$fail" -eq 0 ]`,
   which cannot return 0 with `fail=9`, so the script never reached it — ~80 legs in ~200s against
   a full run's ~151 in 650-1045s. One of them shares commit `d43b09a0` with a run that did 121/30
   in 703s: **same tree, one-third the suite, opposite exit code.** A scheduled job gates on the
   exit code, so it would have read those as a clean pass. Filed **OBS-430**.
3. **Three runs died on SIGTERM** at 600s, 558s, 687s — something kills it near ten minutes.

**So scheduling the suite would have institutionalised a false green inside the suite that exists
to prevent false greens.** The blocker was never "nobody wrote a cron line".

### What was scheduled instead

`bridge-suite-age-daily`, 06:00, running `tools/_t813-suite-age.py` under the same `flock` idiom
every other job uses. It **reads** the history rather than running the suite: milliseconds,
deterministic, no browser. It surfaces the exact fact OBS-256 cares about — *"the seam evidence is
N days stale and has been red for M runs"* — and exits **3** on no history, because T-813 built it
so that *no history is not reported as zero failures*.

**The install is the operator's**, one command, because `fw cron install` writes to `/etc/cron.d/`
which is outside the project boundary:

    cd /opt/832-Workflow-designer && .agentic-framework/bin/fw cron install

Until then the registry and generated crontab carry the job and the live crontab does not — checked,
`grep -c bridge-suite-age /etc/cron.d/agentic-audit-832-workflow-designer` is 0.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**Confirmed before scoping:** grep across the tree finds `run-bridge-tests` in fabric cards, tests,
tools, episodics and learnings — and in **zero** schedulers. Not in `.context/cron-registry.yaml`,
not in `.context/cron/agentic-audit.crontab`. Subtract an agent choosing to type it and 94 legs of
AEF-seam evidence do not execute.

**What already exists, so this task must not rebuild it:** T-813 added per-run recording to
`tests/run-bridge-tests.sh` (exit-trapped, so red and interrupted runs are recorded too) and
`tools/_t813-suite-age.py` to read it, which exits **3** for "no history" precisely so that
*no history is not reported as zero failures*. The missing piece is only the caller.

**The hazard that shapes this, from OBS-256 itself:** the suite is *"not deterministic under
repetition — four consecutive runs on an unchanged tree gave 79/2, 80/1, then 82/0 twice, and the
differing leg was never identified by name"*, and it launches a browser per CDP probe. **Scheduling
a flaky suite manufactures a permanently-noisy rail**, which is OBS-293's class: a check nobody can
act on trains readers to ignore it. So a schedule alone is not the deliverable.

- [x] The suite has a **registered scheduled caller** in `.context/cron-registry.yaml`, following the existing job schema (id, name, schedule, command, source_file, origin_task, status, description) and the `flock` single-instance idiom every other job uses
- [x] **Installation to `/etc/cron.d/` is NOT performed by me.** `fw cron install` writes outside the project boundary; the registry entry is the deliverable and the install is one operator command, named in the task
- [x] **The non-determinism is handled, not scheduled into a nightly alarm.** Either the flaky leg is identified by name, or the job records its result without raising a red that nobody can act on — and whichever is chosen is written down with its reason
- [x] **The run-history claim is measured, not assumed:** report what `_t813-suite-age.py` says today, and distinguish *no history* (exit 3) from *clean history*. If it exits 3, that is the F-03 condition and is evidence for this task, not an error in it
- [x] The job's **schedule is justified against the suite's real cost** — it spawns a browser per CDP probe, so the interval follows a measured runtime rather than a guess
- [x] A control proves the registry entry is **actually read** by the generator: `fw cron generate` (or `--dry-run` install) emits the new job. A row in a YAML nobody parses is the same defect as the suite nobody runs

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

# The job is registered and the registry still parses.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/cron-registry.yaml')); ids=[j['id'] for j in d['jobs']]; sys.exit(0 if 'bridge-suite-age-daily' in ids else 1)"
# CONTROL: the registry must hold the OTHER jobs too — a file containing only my entry would
# satisfy the leg above while having destroyed the schedule.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/cron-registry.yaml')); sys.exit(0 if len(d['jobs'])>=7 and 'full-daily' in [j['id'] for j in d['jobs']] else 1)"
# The GENERATOR reads it — a row in a YAML nobody parses is the defect this task is about.
.agentic-framework/bin/fw cron install --dry-run > /tmp/.t917.out 2>&1 && grep -q 'bridge-suite-age' /tmp/.t917.out
# CONTROL for that grep: the dry-run output is a DIFF, so it shows changed lines plus context.
# Asserting a pre-existing job appears in that context proves the diff ran against the REAL
# crontab rather than against an empty file — in which case every job would read as an
# addition and the match above would mean nothing. (First version of this leg greped for
# 'full-daily', which is outside the diff's context window and is not printed at all.)
grep -q 'Cron audit file retention' /tmp/.t917.out
# The monitor it schedules actually runs and reports, rather than being a path that does not exist.
python3 tools/_t813-suite-age.py > /tmp/.t917age.out 2>&1; grep -q 'gating-suite run history' /tmp/.t917age.out
# And it reports RED — the state this task refused to schedule the suite over. If this ever goes
# green the refusal should be revisited, which is why it is asserted rather than assumed.
grep -q 'current state: RED' /tmp/.t917age.out
# The history file the monitor reads is present and non-empty (its emptiness is exit 3, not zero).
test -s tests/.run-history.tsv

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

### 2026-09-29 — the run history turned a one-line fix into a refusal
- **What changed:** the task looked like "add a cron entry". Reading `tests/.run-history.tsv` —
  which T-813 had already built and which nothing had read — showed a suite red on all 12 recorded
  runs, SIGTERMed three times near 600s, and **twice exiting 0 while reporting 9 failures**.
- **Plan impact:** the deliverable inverted. Scheduling the suite would have gated a nightly job on
  an exit code that does not track failures, which is the false-green class *inside the suite built
  to prevent false greens*. The monitor is scheduled instead.
- **Triggered:** **OBS-430** (urgent) — the exit-0-with-failures anomaly, mechanism unidentified.

### 2026-09-29 — the infrastructure existed and nobody was reading it
- **What changed:** OBS-256 asked for a caller and I nearly wrote one. T-813 had already built
  per-run recording *and* a reader; what was missing was that **nothing consults the reader**. The
  fix is one registry row pointing at a tool that has been sitting there since 2026-09-22.
- **Plan impact:** the cheap, deterministic, already-written thing beat the expensive flaky one.
  Same shape as T-875's blocker, which had been fixed by a different task a week earlier and
  nothing joined them (**L-002**).
- **Triggered:** nothing new; L-002 already names the class.

### 2026-09-29 — the install is deliberately not mine
- **What changed:** `fw cron install` writes to `/etc/cron.d/`, outside the project boundary. The
  registry row and the generated crontab are in-tree and committed; the live crontab is untouched
  and verified untouched.
- **Plan impact:** the task completes with one operator command outstanding, named in the Context
  rather than left implicit. Until it runs, the monitor is scheduled on paper only — and saying so
  is the difference between this and a task that claims a fix it did not deploy.

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

### 2026-09-28T13:27:41Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-917-the-bridge-suite-has-no-scheduled-caller.md
- **Context:** Initial task creation

### 2026-09-28T22:10:01Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e8e81915
- **Timestamp:** 2026-09-28T22:14:39Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — **Installation to `/etc/cron.d/` is NOT performed by me.** `fw cron install` writes outside the project boundary; the registry entry is the deliverable and the install is one operator command, named i
  - **AC-verify-mismatch** (narrow, heuristic) — `path=etc/cron.d in: **Installation to `/etc/cron.d/` is NOT performed by me.** `fw cron install` writes outside the project boundary; the registry entry is the deliverabl`

### 2026-09-28T22:14:38Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
