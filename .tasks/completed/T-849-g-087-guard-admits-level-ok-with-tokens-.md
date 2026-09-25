---
id: T-849
name: "G-087 guard admits level ok with tokens 0 — the zero door is the one that opens on every compaction"
description: >
  G-087 guard admits level ok with tokens 0 — the zero door is the one that opens on every compaction

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [bug]
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
created: 2026-09-25T14:09:54Z
last_update: 2026-09-25T14:32:47Z
date_finished: 2026-09-25T14:32:47Z
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

# T-849: G-087 guard admits level ok with tokens 0 — the zero door is the one that opens on every compaction

## Context

`checkpoint.sh budget` is the sanctioned safe reader for `.context/working/.budget-status` —
CLAUDE.md and the `/resume` skill both point agents at it *instead of* a raw `cat`, because
G-087 (field report 001-CashWeb T-222) recorded that a raw read can return a plausible
`{"level":"ok","tokens":0}` indistinguishable from a healthy session. T-3241 built the guard.

**The guard has three rejection tests and none of them is about the count.** Reading
`checkpoint.sh:639-645`: writer self-marked `unknown`, age past `BUDGET_STATUS_MAX_AGE`, and
`session_id` mismatch. A cache written **fresh, by this very session**, carrying `tokens: 0`
passes all three and prints `level: ok`.

**Measured today, twice, two minutes apart.** At 12:56 this reader printed
`level: ok / tokens: 0 / age_seconds: 51`. Two minutes later the same command printed
`level: unknown / reason: cache is 109s old / raw_tokens: 96832`, and `checkpoint.sh status`
put the truth at **98,461** context tokens. So the guard reported a healthy zero against a
true ~96K — the stale door and the foreign-session door are shut, and the **zero** door was
left open. That is the door that opens **on every compaction**, which is precisely when an
agent runs `/resume` and asks for the gauge.

**It cost a real recommendation, not a hypothetical one.** Acting on `ok / 0` plus the previous
session's remembered figure, I told the operator this session was at ~74% and advised deferring
the 55-leg drain. The honest number was 12% of an 800K cap with 711K headroom. The false green
did not cause a crash; it caused **the wrong call, stated confidently.**

**The discriminator was already in the file, unused.** The same write carries
`baseline_tokens: 88847` — what the session had paid before its first turn — so `tokens: 0`
beside it is not merely suspicious, it is **arithmetically impossible**. This is the
differential control that `_t560`'s own header has twice deferred, available here for free.

Same class as T-841…T-848: a check that cannot distinguish *measured healthy* from
*measured nothing*. The fix is to stop conflating them (T-3105's NOT EVALUATED, applied to a
gauge instead of an audit row).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `checkpoint.sh budget` reports `level: unknown` when the cache carries `tokens: 0`, and the reason names the zero explicitly rather than blaming age or session
- [x] When `baseline_tokens` is present and non-zero, the reason states the **contradiction** (tokens below a baseline the session had already paid) rather than the generic no-measurement wording
- [x] A non-integer, `null`, or absent `tokens` also reports `level: unknown` — a level without a count is not a gauge
- [x] A non-zero `tokens` **below** a non-zero `baseline_tokens` reports `level: unknown` — the same impossibility, caught for counts other than zero
- [x] A healthy cache (fresh, this session, `tokens` above baseline) still reports `level: ok` with its token count and headroom fields — the fix does not turn the gauge off
- [x] `raw_level:` / `raw_tokens:` passthrough is preserved on every new rejection path, so a reader can still see what the cache claimed
- [x] A test instrument exists, is executable, and every case is **mutation-tested**: reverting the patch turns the new cases RED (a test that passes against unpatched code proves nothing — PL-206)
- [x] The instrument runs against **fixture caches in the scratchpad**, never against the live `.budget-status`, and never writes to it
- [x] `bash -n` passes on the edited script and `checkpoint.sh budget` still runs against the live cache without a traceback
- [x] The vendored edit is recorded for upstream (G-008) — the observation is filed and the fix is described in the commit, since the gap id is AEF's and not minted locally

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

# The suite: 14 cases against fixture caches in a temp CONTEXT_DIR. Exit code IS
# the verdict (the script ends on [ "$FAIL" -eq 0 ]) and the pass marker is
# asserted too, so a suite that dies before printing cannot read as green.
out=$(bash tools/_t849-budget-zero-token-tests.sh 2>&1); echo "$out" | grep -q 'PASS 14 / FAIL 0'
bash tools/_t849-budget-zero-token-tests.sh > /dev/null 2>&1

# TEETH. Strips the T-849 block from a copy and requires the 8 dependent cases to
# go red while the 6 control cases stay green. Without the second half this leg
# would have passed on a mutated copy that could not source lib/paths.sh — all 14
# red for the wrong reason, which is what it did on first write.
out=$(bash tools/_t849-budget-zero-token-tests.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
out=$(bash tools/_t849-budget-zero-token-tests.sh --mutation 2>&1); echo "$out" | grep -q '6 control cases stayed green'

# The mutation run must exhibit the ACTUAL bug, not merely fail somehow: the
# unpatched guard prints a healthy level beside a zero and beside a null.
out=$(bash tools/_t849-budget-zero-token-tests.sh --mutation 2>&1); echo "$out" | grep -q 'got: level: ok tokens: 0'
out=$(bash tools/_t849-budget-zero-token-tests.sh --mutation 2>&1); echo "$out" | grep -q 'got: level: ok tokens: None'

# The patched guard, exercised directly rather than through the suite, on a
# fixture cache — the shape measured at 12:56 today must now read unknown.
D=$(mktemp -d); mkdir -p "$D/working"; printf 'session_id: S-VERIFY\n' > "$D/working/session.yaml"; printf '{"level": "ok", "tokens": 0, "timestamp": %s, "session_id": "S-VERIFY", "baseline_tokens": 88847}' "$(date +%s)" > "$D/working/.budget-status"; out=$(CONTEXT_DIR="$D" .agentic-framework/agents/context/checkpoint.sh budget 2>&1); rm -rf "$D"; echo "$out" | grep -q 'impossible, a session cannot hold fewer tokens'

# The script itself parses, and the live read still works end to end.
bash -n .agentic-framework/agents/context/checkpoint.sh
out=$(.agentic-framework/agents/context/checkpoint.sh budget 2>&1); echo "$out" | grep -q '^level: '

# The patch is present and says why — a fix nobody can find the reason for gets
# reverted by the next upgrade. Both greps name strings that ARE in the file.
grep -q 'T-849 (closes the hole left in T-3241' .agentic-framework/agents/context/checkpoint.sh
grep -q 'a session cannot hold fewer tokens than it had paid' .agentic-framework/agents/context/checkpoint.sh

# The instrument is executable and the finding is on the record for upstream.
test -x tools/_t849-budget-zero-token-tests.sh
grep -q 'OBS-384' .context/inbox.yaml

# No mutated copy left behind in the vendored tree by the runs above. The `test -d`
# is SAME-LINE deliberately: a zero from `find` over a directory that does not
# exist is the vacuous pass that caught me in T-847, and `_t560` credits an
# existence control only on the same line, never from a sibling leg.
test -d .agentic-framework/agents/context && test "$(find .agentic-framework/agents/context -name '.t849-mutated-*.sh' | wc -l)" -eq 0

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

**Symptom:** `checkpoint.sh budget` — the reader CLAUDE.md and `/resume` both name as the
*safe* alternative to a raw `cat` — printed `level: ok / tokens: 0 / age_seconds: 51` while the
session actually held 98,461 tokens. Measured 2026-09-25T12:56, immediately after a compaction.

**Root cause:** the guard's rejection set was built from the three ways a cache can be *the
wrong cache* — self-marked unknown, too old, written by another session — and contains no test
of whether the number in it is *a number that could be true*. `tokens` was never read except to
print it. So a cache that is correctly addressed and perfectly fresh, carrying a count that
cannot be right, satisfies every test and is reported as a healthy measurement.

**Why structurally allowed:** three reinforcing reasons, and the third is the one that matters.

1. The guard was written from the field report's *causes* (staleness, session bleed) rather than
   from its *payload*. G-087's own summary names the payload literally — `{"level":"ok",
   "tokens":0}` — and the remediation never asserted over the zero.
2. Nothing tested the guard. There was no fixture harness, so "does it reject a zero" was never
   a question anyone could have answered without hand-building a cache.
3. **The hole is open exactly when the reader is used.** `budget` exists for `/resume`, and
   `/resume` runs after compaction, and compaction is when the cache holds a zero. A defect
   whose window coincides with its call site is not an edge case; it is the main path. The other
   three tests fire on sessions that are *unusual*. This one fires on every session that
   compacts, which by session 75,000 is most of them.

And the discriminator was already present and ignored: the same write carries `baseline_tokens`,
so `tokens: 0` beside `baseline_tokens: 88847` is arithmetically impossible, not merely odd. The
data needed to catch it was in the file being read. This is the *differential control* whose
absence `_t560`'s header has twice recorded as deferred — here it was free.

**Prevention** (distinct from the fix):

- `tools/_t849-budget-zero-token-tests.sh`, 14 cases over fixture caches, with `--mutation`:
  it strips the fix from a copy and requires the 8 dependent cases to go red **while the 6
  control cases stay green**. The second half is the prevention that matters — the first
  version of the harness put the mutated copy in a temp dir where it could not source
  `lib/paths.sh`, so all 14 cases failed and the run *looked* like a successful kill. A
  mutation test that goes red for the wrong reason proves exactly as little as a control whose
  stimulus never fires (PL-206), and nothing in the output distinguished the two until the
  control set was added.
- Two of the 14 cases assert the gauge still WORKS (`healthy_still_ok`,
  `healthy_no_baseline_still_ok`). A guard that answered `unknown` to everything would pass
  every other case here and be worse than the bug it fixes (OBS-293: a permanently red check
  trains its reader to ignore it). Saturation at the refusing end is not safety.
- The generalisation, not the special case: `tokens < baseline_tokens` is rejected for any
  count, not just zero. A guard that knew only about `0` would be defeated by a `1`.
- The fix carries its own reason in a comment naming the measurement and the date, because a
  vendored edit whose rationale is invisible gets reverted by the next `fw upgrade`.

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

### 2026-09-25T14:09:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-849-g-087-guard-admits-level-ok-with-tokens-.md
- **Context:** Initial task creation

### 2026-09-25T14:31:59Z — status-update [task-update-agent]
- **Change:** tags: +bug

## Reviewer Verdict (v1.5)

- **Scan ID:** R-dd4b234e
- **Timestamp:** 2026-09-25T14:33:01Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** yes
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 131
     - evidence: `bash tools/_t849-budget-zero-token-tests.sh > /dev/null 2>&1`

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -rf`

### 2026-09-25T14:32:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
