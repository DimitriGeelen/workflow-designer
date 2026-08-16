---
id: T-551
name: "the instrument sweep discards every probe's output, so a reproduction of the intermittent-failure class yields an integer and nothing else"
description: >
  the instrument sweep discards every probe's output, so a reproduction of the intermittent-failure class yields an integer and nothing else

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
created: 2026-08-16T19:48:33Z
last_update: 2026-08-16T19:48:33Z
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

# T-551: the instrument sweep discards every probe's output, so a reproduction of the intermittent-failure class yields an integer and nothing else

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

`tools/_t509-instrument-sweep.sh` runs every teeth script as

```sh
timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1
```

so the only thing that survives a run is an exit code. T-548 taught that sweep to classify
those codes honestly — regressed / did-not-finish / abstained / passed. It cannot say anything
about *which leg* failed, because the sentence naming the leg was discarded microseconds after
it was written.

That is now the binding constraint on a real, recurring problem. Three instruments have shown
the same signature of green standalone and red only inside a full run:

| instrument | seen | standalone afterwards |
|---|---|---|
| `_t523-nesting-teeth.py` | rc=1 in the suite, 2026-08-16 | 9/9 green, 7.32s |
| `_t366-uid-shape-teeth.py` | rc=2 in the sweep, 2026-08-16 | rc=0, three attempts |
| `_t344-watch-set-denominator.sh` leg 2 | one red | 8/8 green, twice |

Three failures, zero bytes of evidence retained from any of them, while each prints named legs
when run by hand. `_t523` alone prints nine.

This task does not attempt to fix the flakiness. It makes the next occurrence diagnosable.
Fixing first would be worse than useless: with roughly nine runs in ten passing anyway, a
"fix" could not be distinguished from an ordinary green.

## Measured

Seven full sweeps were run after the capture landed. The population is 38 runnable probes
(37 plus this task's own teeth); a sweep costs ~105s.

| run | purpose | rc | note |
|---|---|---|---|
| 1 | first run after wiring `_t551` | 0 | 38/38, tree byte-identical |
| 2 | timing measurement | **1** | **output discarded by my own `> /dev/null`** |
| 3 | immediate re-run | 0 | 38/38, tree byte-identical |
| 4–7 | deliberate hunt, output kept | 0,0,0,0 | no reproduction |

**Run 2 is the finding, and it is the bad kind.** It is the fourth sighting of the
standalone-green / sweep-red class (OBS-265, OBS-269) and the first since a capture existed to
explain it. The capture worked. I destroyed the report anyway, by timing the sweep with
`bash tools/_t509-instrument-sweep.sh > /dev/null 2>&1` — four minutes after landing the fix
whose entire subject is not discarding that output. The next run was green, so that
reproduction is unrecoverable.

The mechanism generalises and is registered as OBS-270: the sweep writes each probe's output
into its own stdout/stderr, so any caller that discards those discards the capture. Exactly one
standing caller preserves it — the bridge suite writes each leg to `$TMP/leg-*.out` and prints
it on failure. Every ad-hoc invocation is a place the evidence can still be lost, and ad-hoc
invocations are what one uses while hunting a flake.

Four deliberate hunt runs with output kept produced nothing, which is consistent with the rate
and settles nothing: 1 in 7 here against T-543's rule-of-three bound of ~9% per run over 33
observations. The honest summary is that the instrument is now able to explain the next
occurrence, and that it has not yet had the chance.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each probe's stdout and stderr are captured per-probe rather than sent to `/dev/null`,
      and the captured text is **printed for any non-zero exit** — regression, timeout and
      abstention alike, since an abstention's reasoning is its entire output
- [x] Output is captured for **passing** probes too and discarded only after the verdict is
      known, so that a probe which passes while printing something alarming is not invisible
      by construction
- [x] The sweep's four exit codes and their wording are **unchanged** — `_t548`'s teeth pin
      both, and this task must not buy diagnosis by weakening classification
- [x] Captured output is **bounded** so one pathological probe cannot bury the report, with the
      truncation stated in the output rather than silent
- [x] The capture is **proven to work by driving a real failure**: a synthetic probe that fails
      with a known message is run through the real sweep, and that message appears in the
      sweep's own output
- [x] Temporary capture files are removed on every exit path, and the repository is
      byte-identical after a sweep run
- [x] `_t548-sweep-classification-teeth.py` still passes all six legs

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

# The capture is proven by driving the REAL sweep over synthetic probes with known exit codes
# and known sentinels (7 legs, ~3s). Mutation-verified: 5 of the 7 go red against the
# reconstructed pre-T-551 redirect.
python3 tools/_t551-sweep-capture-teeth.py
# Classification is unchanged: this task must not buy diagnosis by weakening T-548's verdicts.
python3 tools/_t548-sweep-classification-teeth.py
# The run loop writes to the per-probe capture file, and no probe is redirected to /dev/null.
grep -qF 'timeout "$TIMEOUT" "$runner" "tools/$f" > "$cap" 2>&1' tools/_t509-instrument-sweep.sh
test "$(grep -c '> /dev/null 2>&1' tools/_t509-instrument-sweep.sh)" = "0"
# The regression sentence stays on ONE line: _t548 REFUSES and _t364 goes red if the literal
# phrase cannot be found in the sweep's source. I broke both by wrapping it for line width.
test "$(grep -c 'a real regression in the thing it guards' tools/_t509-instrument-sweep.sh)" = "2"
# Standing caller. An instrument with no caller is the population this sweep exists to fix.
grep -q '_t551-sweep-capture-teeth.py' tests/run-bridge-tests.sh
#
# The FULL sweep is deliberately NOT a verification line. It takes ~105s, and during this task
# it went rc=1 on one run in six with no reproduction on any other — the intermittent class
# this task exists to make diagnosable. Gating completion on a coin flip is what T-543 argued
# against, and the argument is stronger here because the flake is the subject.

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

**Symptom:** three instruments — `_t523-nesting-teeth.py` (rc=1), `_t366-uid-shape-teeth.py`
(rc=2) and `_t344-watch-set-denominator.sh` leg 2 — have failed only inside a full sweep and
passed every standalone attempt afterwards. Each occurrence produced one integer and nothing
else, so each had to be re-hunted from scratch, and none of them could be: for this class,
re-running the probe directly is precisely what does not reproduce it.

**Root cause:** `tools/_t509-instrument-sweep.sh` ran every probe as
`timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1`. Classification was therefore the
most the sweep could ever report, because the sentence naming the failing leg was destroyed
microseconds after it was written. T-548 made the classification honest; honesty about which
of four buckets an integer falls into is still an integer.

**Why structurally allowed:** the redirect was correct for the question the sweep was first
built to answer — "did anything regress" — and nothing distinguishes *running* an instrument
from *preserving its finding*. No gate anywhere asserts that a red suite leg carries evidence,
so the omission could not surface as a failure; it surfaced only as three investigations that
went nowhere. The sweep's own closing advice, "Run it directly for its own output", made the
gap look like it had a remedy, which is why it survived T-548's rewrite of the same code: I
read that sentence as a workaround rather than as an admission, and it is unsatisfiable for
the exact class of failure where the output matters.

**Prevention:** `tools/_t551-sweep-capture-teeth.py`, wired into the bridge suite, drives the
REAL sweep over synthetic probes and requires each probe's own sentinel to reach the sweep's
report for all three non-zero classes, bounded, with the bound stated, silent on green, and
leaving no capture directories behind. Mutation-verified: 5 of its 7 legs go red against the
reconstructed pre-T-551 redirect, so the green is a measurement rather than a description.

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

### 2026-08-16 — where the capture lives

- **Chose:** a `mktemp -d` capture directory per sweep run, one file per probe, removed by a
  `trap ... EXIT INT TERM`.
- **Why:** the sweep's hermeticity is an asserted property — T-509's header records that
  running all 24 probes left `git status` byte-identical, and the bridge suite still checks
  it. A diagnostic that writes into the tree would have traded that away for convenience.
  Re-measured after this change: byte-identical across three sweep runs, zero leftover
  capture directories, and leg 7 of the new teeth asserts the second half over six runs.
- **Rejected:** writing captures under `.context/working/` (survives the run, and would be
  read later — but it puts sweep debris into a tracked-adjacent directory and makes the
  hermeticity claim conditional); keeping everything in bash variables (a pathological probe's
  output then lives in memory with no bound, and `$(...)` strips trailing newlines, so the
  report would misstate what the probe printed).

### 2026-08-16 — the tail, not the head, and the bound is said out loud

- **Chose:** keep the last `T509_CAPTURE_LINES` (default 30) lines and print
  `--- last 30 of N lines from <probe> ---` whenever N exceeds the bound.
- **Why:** these probes print per-leg lines and then a summary, so the verdict and the legs
  that produced it are both at the end. A silently clipped report is how a reader ends up
  confident about the wrong evidence — the same shape T-550 had just repaired one file over,
  where a stale anchor bound to a plausible-looking wrong line.
- **Rejected:** unbounded output (one pathological probe buries the report, and the report
  then stops being read, which is the defect again one level up); head-first truncation
  (keeps the banner and throws away the verdict).

### 2026-08-16 — capture on green too, and what that does and does not buy

- **Chose:** capture every probe including passing ones, and delete the file only after the
  verdict is known (`0) pass=$((pass + 1)); rm -f "$cap";;`).
- **Why:** the alternative decides in advance whose output is worth keeping, using the exit
  code — which is the assumption the whole task is about. One uniform path also means a future
  keep-everything mode is a deleted `rm`, not new plumbing.
- **Honest limit:** nothing reads a passing probe's capture today, so AC2's stated benefit —
  "a probe which passes while printing something alarming is not invisible by construction" —
  is structural, not realised. The time dimension of that case is covered (the HEADROOM
  WARNING names a probe at ≥75% of its budget while it is still passing); the content
  dimension is not. Registered rather than quietly ticked.
- **Rejected:** adding a heuristic that scans a passing probe's output for alarming shapes —
  that invents a classifier nobody asked for, and a wrong one would relabel green runs.

### 2026-08-16 — a load-bearing sentence, discovered by breaking it

- **Chose:** keep `These are hermetic and leave the repo untouched, so a red here is a real
  regression in the thing it guards.` on a single source line, with a comment saying why.
- **Why:** `_t548-sweep-classification-teeth.py` REFUSES outright if it cannot find that
  literal phrase in the sweep's source, and `_t364-tie-guard-teeth.py` goes red. I split it
  across two `echo` calls for line width and broke both within one run. A verification line
  now pins the count at 2 (the comment and the `echo`).
- **Rejected:** loosening the two probes to tolerate a wrapped sentence — they are asserting
  that the regression claim is withheld from timeouts and abstentions, which is T-548's whole
  finding; weakening a guard to fit my formatting is the trade this week's work keeps arguing
  against.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-16T19:48:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-551-the-instrument-sweep-discards-every-prob.md
- **Context:** Initial task creation
