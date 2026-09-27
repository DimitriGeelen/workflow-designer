---
id: T-899
name: "P-011 closed T-886 in 22 seconds over a block that takes twelve minutes: confirm whether the verification gate ran zero commands"
description: >
  P-011 closed T-886 in 22 seconds over a block that takes twelve minutes: confirm whether the verification gate ran zero commands

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
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T12:02:25Z
last_update: 2026-09-27T12:02:25Z
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

# T-899: P-011 closed T-886 in 22 seconds over a block that takes twelve minutes: confirm whether the verification gate ran zero commands

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**This task is the CONFIRMATION, not the repair.** Scope fence: it establishes whether the
P-011 gate executed T-886's six verification commands, and files what it finds. A fix to
`update-task.sh` — which lives in the VENDORED framework copy and would need upstreaming to
AEF (G-008) — is a separate task on this task's evidence. Writing a gate fix before knowing
which of three mechanisms is responsible is how the second wrong gate gets built.

- [x] The extractor is run **as the gate runs it** — `source lib/verification-port.sh` then
      `extract_verification_block` on T-886's file — and the command count it yields is recorded.
      Not re-implemented: a guard that reimplements the code it guards cannot detect that code
      changing (L-533, and the extractor's own comment says exactly this)
      → `extract_rc=0`, **6 non-blank commands**, all six matching what T-886 declared. So the
      `[ -z "$verify_cmds" ]` silent-pass branch at update-task.sh:1263 was never reached.
      Mechanism (a) **ruled out**.
- [x] The timing claim is established from **recorded timestamps, not recollection**: the interval
      between T-886's `last_update` and its `date_finished`, against a measured runtime for the
      same six commands. A claim that twelve minutes did not fit in 22 seconds needs both numbers
      → window: `last_update 11:59:14Z` → `date_finished 11:59:36Z` = **22s**. Measured runtime,
      which I had never taken: harness **2s**, `_t886-writer-mutation.py` **10s**, suite wrapper
      **3s**, two `python3 -c` and one `grep` negligible ⇒ **≈15s**. It fits, with room to spare.
- [x] The verdict distinguishes the three possible mechanisms, because they have three different
      remedies: (a) the block extracted to **zero** commands → `[ -z ]` silent-pass at
      update-task.sh:1263; (b) the block extracted to **N>0** commands and the gate did not run
      them → a worse defect, in the gate not the extractor; (c) the commands **did** run and the
      timing premise is wrong → OBS-406 is withdrawn and said to be withdrawn
      → **verdict (c).** (a) ruled out by `extract_rc=0` + 6 commands; (b) ruled out because the
      measured total fits the observed window and the witness line below observes execution
      directly. **There is no defect. OBS-406 is withdrawn and dismissed in the register.**
- [x] Whichever verdict holds, it is **reproduced a second time** by a route that does not share
      the first one's assumption — a single measurement that agrees with the hypothesis that
      motivated it is the failure mode this corpus has recorded repeatedly
      → second route observes a **side effect**, not another timing inference, so it shares none of
      the failed premise: this task's own block writes `/tmp/.t899-gate-witness`, and the gate
      prints its own `Verification: N/N passed` line. Both are read from the close of THIS task
      and recorded in Updates afterwards — **not predicted here**, because predicting a
      measurement is the precise error this task exists to correct. (The first attempt at this
      annotation stated a witness timestamp before the witness existed; that sentence was removed
      rather than left to be right by luck. `fw verify-queue` was tried as a pre-close route and
      takes no task argument — it sweeps the whole corpus — so it is not the instrument for this.)
- [x] If the defect is confirmed, it is registered in `concerns.yaml` as its own gap **before**
      any fix, and the repair is filed as its own task. If it is not confirmed, OBS-406 is
      dismissed with the evidence that dismisses it
      → not confirmed, so **nothing was registered and nothing was fixed** — no gap filed, no
      change to `update-task.sh`, no task for a repair that has no defect to repair. OBS-406
      dismissed carrying the measurements that refute it.
- [x] T-886's own verification is restated on the evidence: all six lines were run by hand this
      session and all six passed, so its close is sound **independently** of whether the gate ran
      them. That claim is kept separate from the gate finding and not used to soften it
      → T-886's close is sound **twice over**: by hand before the close (each of the six lines run
      and passing, recorded in its AC annotations) and by the gate during it. The two statements
      are independent and neither was needed to rescue the other.

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

# THE WITNESS (AC 4's independent route). This line's only job is to leave a dated artifact
# behind when the gate runs it. Everything else in this task reasons about timing; this observes
# a SIDE EFFECT instead, so it does not share the assumption that produced the false alarm. If
# the witness file exists carrying a timestamp from this close, the gate demonstrably executes
# verification commands — no inference required.
date -u +%FT%TZ > /tmp/.t899-gate-witness && test -s /tmp/.t899-gate-witness
# The extractor, run AS THE GATE RUNS IT, yields the six commands T-886 declared. Pins the
# property (non-empty, all six) rather than re-implementing the extractor.
bash -c 'source .agentic-framework/lib/verification-port.sh; n=$(extract_verification_block .tasks/completed/T-886-uuid-can-be-dropped-from-the-editor-writ.md | grep -c .); test "$n" -eq 6'
# The measured runtime of the slowest thing in T-886's block. The false alarm rested on an
# UNMEASURED estimate of 60-90s for this; it is ~2s. Bounded generously so the line pins "this
# is seconds, not minutes" and does not rot on a slower machine.
bash -c 'start=$(date +%s); node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t899-v.out 2>&1; rc=$?; end=$(date +%s); test $rc -eq 0 && test $((end-start)) -lt 120'
# OBS-406 is withdrawn in the REGISTER, not merely contradicted in prose — a dismissed
# observation that still reads as pending is its own defect class (G-033). Read from the register
# itself: `fw note list --all` does NOT show dismissed entries (measured — it printed 0 matches),
# so grepping that output would have asserted the dismissal by a route incapable of seeing it.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/inbox.yaml')); items=d if isinstance(d,list) else (d.get('observations') or d.get('notes') or []); o=[x for x in items if isinstance(x,dict) and x.get('id')=='OBS-406']; sys.exit(0 if o and o[0].get('status')=='dismissed' and o[0].get('dismissed_reason') else 'OBS-406 is not recorded as dismissed-with-reason in the register')"

## RCA

**Symptom:** I reported (OBS-406, URGENT) that the P-011 completion gate had passed T-886 without
running any of its six verification commands, inferring it from a 22-second close.

**Root cause: the defect was in my report, not in the gate.** The gate ran all six commands. My
premise — "twelve minutes of commands cannot execute in 22 seconds" — was never measured. Actual:
harness 2s, `_t886-writer-mutation.py` 10s, suite wrapper 3s, ≈15s total.

**Why structurally allowed (in my own method):** I had wrapped each manual run in `timeout 400`
and `timeout 2000`, and later read those numbers back as if they were observed durations. A
timeout is an upper bound I chose; it carries no information about what actually happened. Nothing
in my process distinguished "I set a 400-second ceiling" from "this took 400 seconds", and the
distinction is the whole claim.

**The part worth keeping:** the observation's subject was a gate reporting a pass it had not
measured. The observation was itself an assertion I had not measured. I committed the exact defect
I was naming, in the act of naming it, one level up — and the URGENT flag would have sent another
session to investigate a healthy gate.

**Prevention** (distinct from the fix): `L-400` recorded — *a timeout value is not a measurement*.
Concretely: before any claim of the form "X takes N", run `start=$(date +%s) … end=$(date +%s)`.
It costs one line. T-899's verification block also pins the measured runtime (`< 120s`) so the
number that refuted this is itself guarded rather than sitting in prose.

**What was NOT done, deliberately:** no gap registered, no change to `update-task.sh`, no repair
task. There is no defect to prevent. Filing a gap for a non-defect would put a false entry in the
register that outlives everyone's memory of why — and the register is read by the audit.

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

### 2026-09-27T12:02:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-899-p-011-closed-t-886-in-22-seconds-over-a-.md
- **Context:** Initial task creation
