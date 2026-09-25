---
id: T-859
name: "_t542 cost-axis guard raises AttributeError instead of measuring — the upgrade
  renamed _BODY_PATH_RE"
description: >
  _t542 cost-axis guard raises AttributeError instead of measuring — the upgrade renamed
  _BODY_PATH_RE

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [bug]
components: [tools/_t542-cost-blast-radius-teeth.py]
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
created: 2026-09-25T22:49:40Z
last_update: 2026-09-25T23:01:09Z
date_finished: 2026-09-25T23:01:09Z
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
  - ts: '2026-09-25T22:50:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=304,acs=10)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-25T22:51:33Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (2-components); tier=2 (workflow:build); effort=8 
      (lines=304,acs=10)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 1
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-25T22:50:46Z'
---

# T-859: _t542 cost-axis guard raises AttributeError instead of measuring — the upgrade renamed _BODY_PATH_RE

## Context

`tools/_t542-cost-blast-radius-teeth.py` guards the **BVP cost axis** — the property that cost
measures a task's real surface rather than defaulting to cheapest. It is not failing a check. It
**crashes**:

```
AttributeError: module 'aef_bvp_estimator' has no attribute '_BODY_PATH_RE'
  File "tools/_t542-cost-blast-radius-teeth.py", line 256, in main
    if not mod._BODY_PATH_RE.search(tpl_text):
```

So it has been raising instead of measuring, and the sweep classified it as a regression in the
thing it guards rather than as a broken guard (T-851's triage separated those; this is the clearest
DEAD GUARD of the eleven).

**Cause is already established, not to be re-derived.** T-853 measured that `7b5e227e` — T-840's
upgrade to AEF bleeding-edge 1.7.68, which replaced 1,409 vendored files — renamed the attribute:
`_BODY_PATH_RE` present 3× pre-upgrade, 0× after; the module now exposes `_PATH_TOKEN_RE`. This is
one of the six reverted-fix casualties recorded in OBS-386.

**Why this one over the other ten.** It is the only crasher: the others fail an assertion and so at
least report a verdict about their subject. A probe that raises reports nothing at all, and its
silence was being read as a subject regression. And it guards the *cost* half of BVP — the same
scoring mechanism run 3 of this mandate found miscalibrated on the *value* half (OBS-392, where
`no-signal` scores 2 and puts contentless stubs in Q2). Repairing the guard on the scorer, in the
session that measured the scorer misbehaving, is the strongest available fit to arc-003's charter.

**Scope discipline.** Rename the reference to whatever the module actually exposes now, after
checking that the new name means the same thing. Do **not** rewrite the probe's logic, do not
"improve" the cost heuristic, and do not touch the value-axis calibration — that last is forbidden
by this run's mandate and is the operator's in any case.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The replacement attribute is **verified to mean the same thing**, not assumed from a similar name: `_PATH_TOKEN_RE`'s pattern is compared against what `_BODY_PATH_RE` matched pre-upgrade (`git show 7b5e227e~1`). If the semantics differ, that is a finding and the probe needs more than a rename
- [x] `python3 tools/_t542-cost-blast-radius-teeth.py` **reaches a verdict** — exits 0 or 1, not a traceback. A crashing probe reports nothing; that distinction is the whole task
- [x] If it now exits **1**, the failing leg is reported as a real finding about the cost axis and is **not** fixed here — one bug, one task. Repairing the guard and repairing what it guards are different deliverables
- [x] The **sweep's classification changes accordingly**: `_t509-instrument-sweep.sh --only _t542` no longer counts it under `regressed` for the wrong reason. Checked by running the subset mode added in T-850, not inferred
      — **PRECISELY: the word is the same, the reason is not.** `--only _t542` still reports
      `regressed 1`, because the probe now exits 1 over three genuine findings about the cost
      axis. Before this task it counted as `regressed` because it CRASHED — the sweep read a
      traceback as a verdict about the subject. The count is unchanged and the classification is
      now truthful, which is what the AC asked for. A reader expecting the number to move should
      read this line instead.
- [x] The probe's own logic is **unchanged apart from the attribute reference** — asserted by a diff line count, so "fixed it by rewriting it" cannot pass as a rename
      — **MORE THAN A RENAME, as AC1 authorised.** 20 insertions / 3 deletions, all at one call
      site. The predicate itself changed, deliberately: `_PATH_TOKEN_RE` is not equivalent to the
      removed `_BODY_PATH_RE` (no extension requirement, no lookbehind, allows globs), so swapping
      the name would have silently altered what the guard asks. It now asks the subject directly
      via `_candidate_paths`. No other leg, assertion or message was touched.
- [x] The fix carries an **in-file note naming the upgrade commit and the old name**, because the next `fw upgrade` can rename it again and the next reader needs to know this already happened once (T-853)
- [x] The repair is verified against the **still-broken** state too: the old name must be gone from the probe, checked positively via the new name's presence rather than by an uncontrolled absence assertion
      — the EXECUTABLE reference is gone (`if not mod._BODY_PATH_RE` count 0); the name survives
      once inside the explanatory comment, on purpose. That is exactly why the check is positive
      on the new call rather than an absence assertion on the old name — such a leg would be
      false here, and uncontrolled besides.
- [x] No change to `policy/value-drivers.yaml`, to any BVP weight, or to the estimator's scoring logic — this run's mandate forbids adjusting calibration parameters, and the cost heuristic is not the guard

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

# THE WHOLE TASK IN ONE PAIR: the probe must reach a VERDICT (exit 1 — its subject really is
# broken) and must NOT raise. Asserting only "exit != 0" would have passed while it crashed,
# which is precisely the state this task repaired.
timeout 300 python3 tools/_t542-cost-blast-radius-teeth.py > /tmp/.t859.out 2>&1; test "$?" -eq 1
test "$(grep -c Traceback /tmp/.t859.out)" -eq 0
grep -q 'AttributeError' /tmp/.t859.out && exit 1 || true

# It reports findings about its subject rather than dying before it can look. Three legs fail
# today; pinned as "at least one named finding", not as the count, so a later fix to the cost
# axis does not turn this line red (T-3326).
grep -qE '^[0-9]+ finding\(s\):' /tmp/.t859.out
grep -q 'leg5: 5 real paths named in the body with no components' /tmp/.t859.out

# The new predicate is the SUBJECT's own path extraction, not a regex this probe re-implements.
grep -q 'mod._candidate_paths({}, tpl_text)' tools/_t542-cost-blast-radius-teeth.py

# The rationale is in-file and names the upgrade commit, so the next rename is legible rather
# than a fresh mystery (T-853). Single-line substrings: the comment wraps.
grep -q 'T-859: was `mod._BODY_PATH_RE.search(tpl_text)`' tools/_t542-cost-blast-radius-teeth.py
grep -q 'NOT A RENAME' tools/_t542-cost-blast-radius-teeth.py

# The estimator and the value model were NOT touched. Asserted POSITIVELY, on content that
# would have had to change: the no-signal default and the driver weights are still what run 3
# measured. A `git status ... | wc -l -eq 0` leg was written here first and REFUSED by the
# T-843 gate — rightly twice over: it is an uncontrolled absence assertion, and it empties the
# moment this task commits, so it would pass forever regardless (the T-847 shape). The evidence
# that only two files changed is the commit diff, not a leg that cannot fail.
grep -q '_PATH_TOKEN_RE' .agentic-framework/agents/termlink/bvp-estimator/estimator.py
grep -q 'no-signal' .agentic-framework/agents/termlink/bvp-estimator/estimator.py
test "$(grep -cE '^\s*weight:\s*9\s*$' policy/value-drivers.yaml)" -eq 4

# The change is confined to the one call site: the only executable occurrence of the old name
# is gone, and the only remaining mention is inside the explanatory comment. Asserted by
# counting the CODE form, positively — an absence leg on the bare name would be false, since
# the comment quotes it deliberately.
# Positive form only: the guard line IS the new call. An absence leg on the old name was
# written here first and refused by the T-843 gate — and it would also have been false, since
# the comment quotes the old name deliberately. Asserting what the guard IS settles both.
grep -q 'if not mod._candidate_paths({}, tpl_text):' tools/_t542-cost-blast-radius-teeth.py
test "$(grep -c 'mod\._BODY_PATH_RE\.search' tools/_t542-cost-blast-radius-teeth.py)" -eq 1

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

**Symptom:** `tools/_t542-cost-blast-radius-teeth.py` raised
`AttributeError: module 'aef_bvp_estimator' has no attribute '_BODY_PATH_RE'` instead of measuring
anything, and the instrument sweep counted it under `regressed` — i.e. as a verdict about the cost
axis rather than as a broken guard.

**Root cause:** `7b5e227e` (T-840's upgrade to AEF 1.7.68, 1,409 vendored files) removed
`_BODY_PATH_RE` from the estimator. The probe reached into the subject's **private** attribute, so a
refactor on the subject's side silently decapitated the guard. One of the six reverted-fix
casualties in OBS-386.

**Why structurally allowed:**

1. **The probe depended on a private name.** `_BODY_PATH_RE` is underscore-prefixed — the subject was
   free to rename it, and did. A guard coupled to another module's private surface has no contract
   to rely on, and nothing warned when that surface moved.
2. **A crash and a finding were indistinguishable downstream.** The sweep classifies a non-zero exit
   as `regressed` unless the instrument volunteers rc 4, so a traceback read as "the thing it guards
   broke". T-851 already recorded this as a class; this task is the first repair under it.
3. **The guard's silence cost more than the guard.** Once repaired it immediately reported
   `leg5: 5 real paths named in the body with no components: scored None` — which is *why* 30 of 112
   tasks have no cost and therefore no quadrant. That corpus-wide cost blindness is what made
   quadrant-based selection unreliable in runs 2 and 3 of this mandate. The guard had been detecting
   it the whole time, by crashing.

**Prevention** (distinct from the fix):

- The probe no longer re-implements or reaches for a regex: it asks the subject through
  `_candidate_paths`, the same function the subject itself uses to decide a token is a path. A probe
  that models its runner drifts from it (PL-275); asking the runner cannot drift.
- The rationale is in-file, naming the upgrade commit and the old attribute, so a second rename is a
  legible recurrence rather than a fresh mystery (T-853's measured lesson).
- The verification asserts **exit 1 AND zero tracebacks** — not merely "non-zero". Asserting
  non-zero would have passed throughout the broken period, which is the exact false signal this task
  repaired.
- **Named and NOT fixed** (one bug, one task): the three findings the repaired guard now reports —
  leg1 (blast_radius collapsed to 2 distinct values, "the 0.6-weighted term is a flag, not a
  measurement"), leg5 (body-path extraction unreachable, so cost is absent corpus-wide), leg6 (T-041
  carries an explicit `blast_radius: None` that re-enters ranking as a comparison against None).
  Leg5 is the highest-value follow-up in the project right now, because it is the reason BVP cannot
  rank most of the corpus.
- **Also not fixed, and forbidden here:** the value-axis `no-signal = 2` default (OBS-392). This
  run's mandate bars adjusting BVP calibration parameters.

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

### 2026-09-25T22:49:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-859-t542-cost-axis-guard-raises-attributeerr.md
- **Context:** Initial task creation

### 2026-09-25T22:55:29Z — status-update [task-update-agent]
- **Change:** tags: +bug

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6e50f0b5
- **Timestamp:** 2026-09-25T23:01:12Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-25T23:01:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
