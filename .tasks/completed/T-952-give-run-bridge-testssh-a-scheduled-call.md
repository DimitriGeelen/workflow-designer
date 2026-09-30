---
id: T-952
name: "Give run-bridge-tests.sh a scheduled caller with a failure-count ratchet"
description: >
  Give run-bridge-tests.sh a scheduled caller with a failure-count ratchet

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh, tools/_t952-audit-rail-teeth.sh, tools/_t952-bridge-baseline.txt, tools/_t952-bridge-suite-ratchet.py, tools/_t952-ratchet-teeth.sh]
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
created: 2026-09-30T18:25:00Z
last_update: 2026-09-30T19:09:27Z
date_finished: 2026-09-30T19:09:27Z
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

# T-952: Give run-bridge-tests.sh a scheduled caller with a failure-count ratchet

## Context

> ## SCOPE CORRECTED BEFORE ANY OF THIS WAS BUILT — read this first
>
> This task was filed to **give the suite a scheduled caller**. That is the wrong thing, and
> a prior task already decided so on better evidence than I had. `.context/cron-registry.yaml`
> records, under `bridge-suite-age-daily`:
>
> > *"T-917 chose the MONITOR over the suite itself: the suite takes 650-1045s, spawns a
> > browser per CDP probe, has been red for all 12 recorded runs, gets SIGTERMed near 600s,
> > and **has twice exited 0 while reporting 9 failures** (OBS-430). Scheduling that would
> > manufacture either a permanently-red rail or a false green; scheduling this surfaces the
> > same fact in milliseconds, deterministically."*
>
> Every clause of that is confirmed by what I measured independently while building:
> `tests/.run-history.tsv` carries **`rc=143` rows** — SIGTERM'd partial sweeps recording
> `73/16` and `64/12` — exactly the artefact T-917 predicted. And a suite that can exit 0
> while reporting failures cannot be the input to a gate.
>
> **So "link 4 is still open" was wrong.** Link 4 was closed by a decision, choosing a cheap
> deterministic monitor over an expensive unreliable one. I am not re-litigating it.
>
> **What IS open, and is what this task now delivers:** that monitor's verdict reaches
> `logger -t agentic-cron` and nothing else. `grep -c '_t813\|run-history'` on
> `agents/audit/audit.sh` is **0**. The only executable readers of the history are `_t813`
> itself and its own control script. So the framework knows how red and how stale the suite
> is, every single day, and tells no reader that anyone looks at — which is the *identical*
> shape to `_t517` before T-945: a correct detector with no delivery surface.
>
> The original acceptance criteria are struck through below rather than deleted, because the
> reasoning that produced them is the useful part.

---

**Original framing (WRONG — see above): "link 4 of the failure chain, the only one still open."**

The 1.7.68 re-vendor silently reverted at least five local fixes. `_t517` detected it
correctly; `_t517` was absent from `audit.sh` (fixed, T-945); `_t657` — the probe that
exists to catch exactly that absence — sat at `rc=3 COULD-NOT-MEASURE` and was **invoked by
nothing** (re-anchored, T-945). Every layer worked. The delivery between layers did not.

`tests/run-bridge-tests.sh` still **has no scheduled caller.** Verified four ways:
`/etc/cron.d`, `crontab -l`, `.git/hooks`, and a repo-wide grep across `*.sh`/`*.yaml`/`*.py`
— only historical mentions in `.context/episodic/`. Its own header already says so. So every
probe in it, including the six legs added today (T-943, T-657, T-949, T-301), runs only when
someone types the command. That is the state `_t517` was in for two months while being
correct.

**The suite is not green, and that is the design problem.** A completed run on 2026-09-30
measured **122 passed, 32 failed**. A scheduled caller that fails every night trains the
reader to ignore it — the decay this project has already been burned by twice (the 1362
merged count, the 27-item GO-scope warning). So the caller cannot simply be "run it and
report"; it needs a **failure-count ratchet**: today's count is the recorded floor, a rise
fails loudly, a fall tightens the floor.

Prior art in this repo for the exact shape: `tools/_t560-absence-baseline.txt` +
`_t560-absence-census.py` (currently red at 75 vs baseline 74), and today's
`tools/_t301-known-divergences.txt`.

**Runtime matters.** The suite takes roughly 13 minutes, so the cadence is nightly, not
every 15 minutes — and the caller must not be the thing that discovers it has no timeout
(a 120s cap would have falsely reported TIMEOUT earlier today; 900s is the measured-safe
figure).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The suite's current pass/fail counts are **measured by a completed run**, not carried
      over from the 122/32 figure above — and the measurement is taken from a run that
      reached its own summary line, because a count read from a partial log is how I
      reported 16 failures earlier today when the real number was 32.
      **Measured: `2026-09-30T18:50:16Z  125 passed  32 failed  rc=1  803s  cf4e503b`**,
      from a run that printed `bridge round-trip: 125 passed, 32 failed`. The three extra
      passes over the 13:57 run are the legs added today (T-949, T-301, plus their teeth via
      the T-509 sweep): **three new passes, zero new failures.**
- [x] `tools/_t952-bridge-suite-ratchet.py` reads `tests/.run-history.tsv`, takes the newest
      **completed** run, compares its failure count against a recorded baseline, and **fails
      only on a RISE**. A fall changes nothing automatically — it reports that the floor can
      be lowered, so tightening stays a decision with a commit behind it.
- [x] **Killed runs are discarded, loudly.** Only `rc` 0 or 1 describes a completed sweep.
      The `rc=143` rows in the live history record `16` and `12` failures from partial
      sweeps; a reader taking the newest row would announce a twenty-failure improvement
      against a floor of 32. This is the single most important behaviour in the tool.
- [x] **Cannot-measure is never a pass**: no history, no completed run, an unusable baseline,
      or a run older than 48h each exit non-zero with the reason named.
- [x] The ratchet has **teeth proven by fixtures** — rise, fall, exact-hold, killed-newest,
      all-killed, stale, missing history, garbled baseline, malformed row — driven by stubbed
      history files, never by waiting ~16 minutes for the real suite.
- [x] **The verdict reaches `fw audit`.** This is the actual gap: `grep -c '_t813\|run-history'`
      on `audit.sh` is 0 today, so the daily monitor's finding dies in syslog. An audit line
      surfaces suite redness and staleness where the existing 40-odd checks are already read.
      Registration buys reachability; the audit line buys detection (PL-363).
- [x] The audit line is **proven in both directions** against fixtures — red history produces
      a warning carrying the count, a held floor produces a pass, and a missing history
      produces NOT EVALUATED rather than a pass (T-3105).

~~- [ ] A **scheduled caller exists and is registered** — a `cron.d` entry whose log lands
      somewhere a human or the audit can read, with a timeout above the measured runtime.~~
      **WITHDRAWN.** T-917 decided against this on measured grounds (see the box above): a
      ~16-minute browser-spawning suite that gets SIGTERMed near 600s and has twice exited 0
      while reporting 9 failures would manufacture a permanently-red rail or a false green.
      The `rc=143` rows in the live history are that prediction already come true. No cron
      entry is added by this task, and `.context/cron-registry.yaml` is left untouched so the
      audit's registry/`/etc/cron.d` sync check keeps passing.

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

# --- T-952 -------------------------------------------------------------------
# The ratchet reads the real history and the floor holds.
python3 tools/_t952-bridge-suite-ratchet.py
# It BITES: 9 fixture legs. The load-bearing one is that a SIGTERM'd partial sweep
# (rc=143, 12 failures) is discarded rather than read as a 20-failure improvement.
bash tools/_t952-ratchet-teeth.sh
# The audit line carries the tool's own bytes, in both directions, with a mutation leg.
bash tools/_t952-audit-rail-teeth.sh
# The rail is actually IN audit.sh — this is the delivery that was missing, and audit.sh
# is the most-reverted file in the tree (17 local commits), so assert it positively.
grep -q 'check_bridge_suite_ratchet()' .agentic-framework/agents/audit/audit.sh
grep -q '^check_bridge_suite_ratchet$' .agentic-framework/agents/audit/audit.sh
bash -n .agentic-framework/agents/audit/audit.sh
# The baseline records a number AND a reason (the format requires the reason).
grep -qE '^32 \| Measured 2026-09-30' tools/_t952-bridge-baseline.txt
# The killed-run exclusion is present, not just tested — the rule that makes the tool safe.
grep -q 'COMPLETED_RCS' tools/_t952-bridge-suite-ratchet.py
# Both probers are reachable from the suite (PL-161, PL-363).
grep -q '_t952-ratchet-teeth.sh' tests/run-bridge-tests.sh
grep -q '_t952-audit-rail-teeth.sh' tests/run-bridge-tests.sh
bash -n tests/run-bridge-tests.sh
# The audit genuinely emits the line. Structure section only, to keep the gate quick;
# redirect-then-grep so the producing command's exit code stays in the verdict (L-387).
.agentic-framework/agents/audit/audit.sh --section structure > /tmp/.t952-audit.out 2>&1; grep -q 'Bridge suite:' /tmp/.t952-audit.out
# NO cron entry was added — the withdrawn AC, asserted so the withdrawal is structural
# and not just a paragraph. The registry must not mention a suite RUNNER.
#
# CONTROLLED, because the first version of this was `test "$(grep -c ...)" -eq 0` and the
# T-843/_t560 gate refused the close: rename the registry or mistype the pattern and the
# leg passes vacuously — a broken search and a satisfied assertion produce identical green.
# The companion below greps the SAME STRING somewhere it IS present, so the absence leg
# only means something because the search is demonstrably capable of succeeding.
# The control is tools/_t509-instrument-sweep.sh, which names the suite. NOT
# tests/run-bridge-tests.sh: the string "run-bridge-tests" does not appear INSIDE that
# file, so the obvious-looking control failed the moment it was run — which is the whole
# argument for controls, demonstrated on me twice in five minutes.
grep -q 'run-bridge-tests' tools/_t509-instrument-sweep.sh
! grep -q 'run-bridge-tests' .context/cron-registry.yaml

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

### 2026-09-30T18:25:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-952-give-run-bridge-testssh-a-scheduled-call.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-419cc5c0
- **Timestamp:** 2026-09-30T19:09:58Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-30T19:09:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
