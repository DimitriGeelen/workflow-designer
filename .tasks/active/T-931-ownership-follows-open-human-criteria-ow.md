---
id: T-931
name: "Ownership follows open Human criteria: owner reverts to agent when none are
  open, and the shape is counted so it cannot silently accumulate"
description: >
  Operator ruling 2026-09-29. owner: agent human is a sovereignty claim only while
  a Human acceptance criterion is actually open. R-033 makes the field sticky forever,
  and fw task delegate (D-626) converts CRITERIA and never touches the owner field,
  so a task created the framework's own documented way (--owner human, per lib/init.sh:926
  and lib/setup.sh:421/481) with no Human criteria becomes permanently operator-only
  with nothing for the delegation mechanism to grip. Measured: 112 active tasks are
  owner: human, 35 of those have zero real Human criteria, and 3 of those have every
  Agent AC ticked too (T-708, T-723, T-885) - a rubber-stamp queue with nothing to
  judge. The audit has been reporting the aggregate for days as 'the D-626 delegation
  reaches nothing'. Ownership must follow the criteria automatically.

status: started-work
workflow_type: build
current_node: frw_3_start
owner:
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
created: 2026-09-29T15:43:39Z
last_update: 2026-09-29T15:46:10Z
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
  - ts: '2026-09-29T15:44:32Z'
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
      F1: 1
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=1 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-931: Ownership follows open Human criteria: owner reverts to agent when none are open, and the shape is counted so it cannot silently accumulate

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**The two shapes go in different places on purpose.** The ACTOR (the thing that writes the
`owner:` field) and the DETECTOR (the thing that counts the shape) must not share a home, and
neither may live on cron. See `## Decisions` for the placement argument.

- [ ] **The predicate is one function with one definition of "open Human criterion", and it is
      proven to READ CORRECTLY before anything is allowed to write on its verdict.** Measured
      hazard: a naive count of `- [ ]` lines under `### Human` returns 2 for T-885, which has
      none — both hits are the template's own `[REVIEW]`/`[REVIEWER]` examples inside an HTML
      comment. I hit this live while measuring. Any predicate that misreads a real open criterion
      as absent will strip a genuine human claim, which is the one outcome that must be impossible
- [ ] **Both directions proven, the negative one first.** With one open Human criterion present the
      predicate must NOT fire — asserted over the awkward shapes that exist in this corpus:
      criteria inside vs outside comments, `[REVIEW]` / `[REVIEWER]` / `[RUBBER-STAMP]` prefixes,
      indented checkboxes, and a `### Human` section that is comment-only. A one-directional proof
      is what lets a flip look correct while removing sovereignty
- [ ] **The actor lives in `update-task.sh`, beside the existing owner writer, not anywhere else.**
      `update-task.sh:2356` already sets `owner: human` on the partial-complete transition. The
      revert is its symmetric half and belongs in the same writer, so the field has ONE owner in
      code. It fires on the status transition, and its write is audited by name the way R-033's
      refusal is (`fw_instance_refused` is the model — a reason, a rule id, a node)
- [ ] **`fw task delegate` reports the class so the operator has a deliberate verb.** Today
      `--dry-run` on T-885 prints `0 open Human criteria … owner: human (unchanged)` — the verb
      cannot see the shape it is the surface for. It must name it, and `fw reviewer surface` must
      count it alongside reviewer-closeable / agent-self / operator-only
- [ ] **The detector lives in `fw audit`, and an empty candidate set FAILS rather than passing.**
      Per T-3105, "no tasks in this shape" must be reported as NOT EVALUATED with its reason, never
      as a PASS that asserts coverage the check does not have. This is the half that runs on cron
- [ ] **The actor never runs unattended.** No cron entry, no hook, no sweep writes the `owner:`
      field. Asserted mechanically, not promised in prose: a check that greps the deployed crontab
      and the hook configuration for the actor's entry point and fails if it appears
- [ ] **The 35 existing tasks are reported, not silently converted.** The backfill is one explicit
      operator-run command with a `--dry-run` that lists every id and its predicate verdict first.
      A bulk ownership change across 35 tasks is not something a mechanism does on its own
      initiative, even under a ruling that says the field is stale
- [ ] **Upstreamed to AEF.** This is vendored framework code (`.agentic-framework/`), so the change
      affects every project on AEF, not just this one (G-008). AEF is told, with the measurement

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

### 2026-09-29 — where the two shapes live

- **Chose:** ACTOR in `update-task.sh` beside `:2356` (+ the class surfaced in `fw task delegate`);
  DETECTOR in `fw audit`, which is what cron already runs. Cron runs the detector and NEVER the actor.
- **Why:** the `owner:` field should have exactly one writer in code. `:2356` already sets
  `owner: human` on the partial-complete transition — precisely when a Human criterion becomes open.
  The revert is the same rule read backwards, so it belongs in the same function, fires on the same
  transition, and is audited the same way. Splitting it into a second writer elsewhere is how two
  mechanisms end up disagreeing about who owns a task. `fw task delegate` is the operator's ratified
  delegation surface (D-626) and already has `--dry-run`; it should be able to SEE the class it is
  the surface for, which today it cannot.
- **Rejected — the actor on cron.** This is the important rejection. An unattended sweep that
  strips `owner: human` across the corpus is the single most dangerous placement available: if the
  predicate is wrong, sovereignty is removed from N tasks with nobody watching, and the first
  symptom is a task closing that the operator wanted to see. Attended-only is not caution, it is the
  property that makes the ruling safe to implement. A detector on cron has the opposite risk profile
  — it can only over-report.
- **Rejected — a PreToolUse/PostToolUse hook.** Fires on unrelated tool calls, so the write would be
  triggered by activity that has nothing to do with the task's criteria changing. Also B-005 blocks
  the agent from writing `.claude/settings.json`, and a side door around that is not on the table.
- **Rejected — the actor inside `fw audit`.** An audit that repairs what it measures can no longer
  report honestly on it: the next run reads clean because the previous run wrote. Measure and
  mutate stay separate.

### 2026-09-29 — CORRECTION: the parser is fine, and the real mechanism is the unticked filter

The entry below this one was written before I ran the framework's own parser, and its central
number is wrong about the thing that matters. Recorded rather than edited away, because the
correction is the finding.

- **What I claimed:** 160 tasks carry a `### Human` section and 126 would be misread, because a
  naive count of `- [ ]` under `### Human` returns 2 for T-885 (both the template's `[REVIEW]` /
  `[REVIEWER]` examples inside an HTML comment).
- **What is true:** that describes the throwaway regex I measured with (`^\s*-\s*\[.\]`), NOT the
  production predicate. `tools/_t770-delegation-boundary.py` uses `AC_RE = ^- \[([ xX])\]` —
  anchored at column 0, no leading whitespace. The template examples are indented, so they never
  match. Run against T-885 it returns exactly the right answer: **6 Agent ACs, all ticked, 0 Human
  ACs.** The comment hazard is real for anyone writing a new scanner and is NOT a defect in this one.
- **Why it matters:** I nearly specified comment-stripping repair for a parser that does not need
  it, while missing the mechanism that actually hides these tasks.

- **THE REAL MECHANISM (measured).** `_t770` line 354: `if args.unticked_only or not args.task:
  rows = [r for r in rows if not r["ticked"]]`. A corpus-wide scan silently drops every TICKED
  criterion. T-885, T-708 and T-723 each classify as `OPERATOR-ONLY / owner-human` when scanned
  individually — but every one of their criteria is ticked, so the corpus view emits zero rows for
  them. That is why all three are absent from all 406 rows.
  The surface is therefore answering "which OPEN criteria could be delegated", which is a fair
  question, while nobody anywhere asks "which tasks are blocked with nothing left open". That second
  set IS the rubber-stamp queue, and it is unmeasurable by construction. `fw reviewer surface`
  prints `OK` over it.
- **Consequence for this task:** drop the comment-stripping work. Build instead (a) the `owner-human`
  carve-out change, (b) a corpus view that can see a fully-ticked blocked task, (c) the actor,
  (d) the detector. The negative-direction proof is still required — it is just proving something
  different from what the entry below assumed.

- **THE NUMBERS I GAVE THE OPERATOR WERE ALSO WRONG, AND LOW.** Measured by the real predicate
  (`tools/_t931-ownership.py`, 11/11 teeth) over 176 active tasks:

  | | |
  |---|---|
  | `owner: human` | 112 |
  | OWNER-JUSTIFIED — at least one OPEN Human criterion, a live claim | 67 |
  | **OWNER-STALE** — no open Human criterion | **45** |
  | …no Human criteria ever written | 35 |
  | …every Human criterion ticked (so the human already judged) | 10 |
  | **rubber-stamp queue** — stale AND every Agent AC ticked | **13** |

  I told the operator "35 and 3". The 3 was wrong because my naive regex counted the template's
  commented examples as open Human criteria, hiding all ten tasks whose Human ACs the human had
  ALREADY TICKED. Those are the worst cases in the set: the judgement was exercised, and the task
  stayed shut anyway.

- **THE AUDIT HAS BEEN REPORTING THE SYMPTOM FOR WEEKS.** 10 of the 13 — T-041, T-101, T-102,
  T-105, T-293, T-309, T-357, T-681, T-708, T-723 — are CTL-029 items ("has all Agent ACs ticked
  but status='started-work' — completable, not closed"), several recurring 6 times in the 14-day
  trend. CTL-029 sees the symptom and prescribes closing the task; it cannot say WHY the task will
  not close, because the blocker is a frontmatter field and no check reads it. The detector this
  task adds is the missing half of a control that has been firing, correctly and uselessly, for a
  month.

### 2026-09-29 — the predicate is the whole risk, and its likely failure is silence
<!-- SUPERSEDED IN PART by the correction above: the 126-task figure describes my measuring regex,
     not tools/_t770-delegation-boundary.py. The reasoning about proving the negative direction
     first still holds and is why the error surfaced before anything was written. -->


- **Chose:** prove the predicate READS correctly before letting it write, negative direction first.
- **Why:** measured across active tasks — **160 carry a `### Human` section, and for 126 of them
  stripping HTML comments changes the count.** T-885 is the clean example: a naive count of `- [ ]`
  under `### Human` returns 2, and both hits are the template's own `[REVIEW]`/`[REVIEWER]` examples
  inside a comment. The task has zero real criteria.
  The direction of that error is what makes it insidious. The naive count is too HIGH, and those
  phantom criteria are unchecked, so a naive predicate concludes "a Human criterion is open" and
  declines to flip. The mechanism would then sit inert over 126 tasks while reporting nothing wrong
  — a false silence, not a false write. The dangerous direction (missing a REAL open criterion and
  flipping anyway) needs its own proof and does not follow from the same test.
- **Rejected — reusing an existing extractor without re-proving it.** `lib/section-extract.sh`
  already does anchored first-wins AC extraction (T-3148) and is the right thing to build on, but
  "it is already used elsewhere" is not evidence that it handles the comment-only `### Human`
  section. That gets its own control leg.
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

### 2026-09-29T15:43:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-931-ownership-follows-open-human-criteria-ow.md
- **Context:** Initial task creation

### 2026-09-29T15:44:31Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
