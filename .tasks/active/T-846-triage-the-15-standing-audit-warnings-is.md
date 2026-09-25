---
id: T-846
name: "Triage the 15 standing audit warnings: is each claim true here, and is each named remedy runnable"
description: >
  Triage the 15 standing audit warnings: is each claim true here, and is each named remedy runnable

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
created: 2026-09-25T11:20:02Z
last_update: 2026-09-25T11:20:02Z
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

# T-846: Triage the 15 standing audit warnings: is each claim true here, and is each named remedy runnable

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **All 15 WARN rows from the latest audit are enumerated, and the denominator is stated.**
      Not "the ones I noticed" — the full list, extracted mechanically from
      `.context/audits/2026-09-25.yaml`, so coverage is a fact rather than an impression.

- [x] **Each row is answered against BOTH questions, individually.** (a) *Is the claim true in
      this project?* (b) *Is the named remedy runnable as written?* Both answers recorded per
      row with the evidence that produced them. A row that passes both is still recorded — a
      triage that only lists failures cannot be distinguished from one that stopped early.

- [x] **Each row gets one of four verdicts**, and the counts are reported:
      `ACTIONABLE` (claim true, remedy runs) · `UNRUNNABLE-REMEDY` (claim true, remedy cannot
      be followed as written) · `MISLEADING-CLAIM` (the warning asserts more than it knows —
      should be NOT EVALUATED) · `STALE` (no longer true).

- [x] **The worked example is carried to a conclusion, not just diagnosed.** The unit-suite row
      has three separate defects already measured: it reports `runner_exit=0` over 0 bats and 0
      pytest files (a pass over nothing); its text implies invisible reds where the corpus does
      not exist at all (`.agentic-framework/tests` is absent from the vendored tree); its named
      remedy `agents/audit/unit-suite.sh` is not executable; and when forced it writes to
      `.agentic-framework/.context/audits/unit-suite/` while the audit reads
      `.context/audits/unit-suite/`, so following the remedy never clears the warning. Each
      claim re-verified here rather than carried over on trust.

- [x] **Nothing in `.agentic-framework/` is changed under this task.** This is a triage, not a
      fix round: 15 warnings' worth of upstream edits in one task is exactly the unscoped
      building G-020 exists to stop. Findings are filed and routed; fixes are separate tasks
      with their own ACs. Verified by `git diff` over the vendored tree being empty.

- [x] **Every finding is filed where an instrument can see it**, not left in this task's prose.
      Observations for ours, a single AEF post for theirs — PL-145: a ruling filed as prose is
      invisible to every instrument that looks for rulings, and the same is true of findings.

- [x] **A report is written to `docs/reports/` with the full 15-row table**, so the next reader
      does not re-derive the triage from a commit message.

- [x] **The hit rate is stated plainly, including if it is low.** I predicted a high rate from
      four accidental finds. If the systematic sweep returns mostly ACTIONABLE, that prediction
      was wrong and the record says so — a triage that confirms the warnings are fine is a
      useful result, not a failed task.

#### Recorded result

**9 ACTIONABLE · 4 UNRUNNABLE · 2 MISLEADING-AND-UNRUNNABLE. 6 of 15 defective (40%). No row was
STALE**, so that verdict category went unused — recorded because an unused category in a scheme
I invented is worth noticing rather than quietly dropping.

**MY PREDICTION WAS WRONG AND THE REASON IS THE USEFUL PART.** I proposed this sweep on the
strength of four accidental finds — "four for four" — and implied a high hit rate. It is 40%.
The accidental finds were **selection-biased**: I hit exactly the defective rows because those
were the rows I tried to *act* on, and a mitigation only reveals itself as unrunnable when
someone runs it. Nine rows are fine and I had never touched one of them. **Accumulating incidents
does not substitute for a sweep, and it systematically overestimates the defect rate** — which is
the opposite of the error I have been making all session and worth the same weight.

**The cross-cutting finding is more valuable than any single row, and it corrects me.** Four of
the fifteen are *permanently* vacuous here — honestly labelled `NOT EVALUATED: candidate set
empty`, which is the pattern I spent this morning advocating, and correct — but empty because of
this project's **layout**, not a transient state. They will warn daily forever. So honest
labelling fixes the *lying* problem and not the *noise* problem, and 27% of the standing warning
count is now rails that cannot fire. That is OBS-293's erosion through the honest door. The
proposal is a fourth value: `NOT_APPLICABLE`, declared per project, reported once, excluded from
the total (OBS-381).

**One leg of mine was written across twelve lines and collapsed before rehearsal** — P-011 is
line-oriented (T-2991). Second time today. Caught by knowing the trap rather than by the gate,
which is the first time today that has been the order.


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

# ── T-846 legs ────────────────────────────────────────────────────────────────
# Positive assertions throughout, and each pins a MEASUREMENT this triage made rather than a
# summary of it — a leg that greps my own conclusions proves only that I wrote them down.

# The report exists and carries the full table, the verdict tally, and the honest miss.
R=docs/reports/T-846-audit-warning-triage.md; grep -q '9 ACTIONABLE' "$R" && grep -q '6 of 15 defective' "$R" && grep -q 'My prediction was wrong' "$R"

# DENOMINATOR: the audit really does hold 15 WARN rows, so "all 15" is a fact not a claim.
# ONE LINE — P-011 is line-oriented and I wrote this as twelve on the first pass, for the
# second time today (T-2991). Caught by knowing the trap, not by the gate.
test "$(python3 -c "import yaml;d=yaml.safe_load(open('.context/audits/2026-09-25.yaml'));r=lambda o:[x for v in (o.values() if isinstance(o,dict) else o if isinstance(o,list) else []) for x in ([v] if isinstance(v,dict) and 'level' in v and 'check' in v else r(v) if isinstance(v,(dict,list)) else [])];print(sum(1 for x in r(d) if str(x.get('level','')).upper()=='WARN'))")" -eq 15

# DEFECT 1 re-measured, both halves: bin/fw is absent here AND four mitigations name it.
test ! -e bin/fw
test "$(grep -c 'bin/fw' .context/audits/2026-09-25.yaml)" -ge 4

# DEFECT 2 re-measured: the unit-suite remedy is not executable, and the corpus it would scan
# does not exist in the vendored tree. Both are why it reports exit 0 over nothing.
test ! -x .agentic-framework/agents/audit/unit-suite.sh
test ! -d .agentic-framework/tests

# DEFECT 3 re-measured: bleeding-edge is NOT merged into master, so the remedy's first clause
# (git branch -d, for merged branches) cannot apply to the finding that produced it.
test -z "$(git branch --merged master | grep bleeding-edge)" && git rev-parse --verify --quiet bleeding-edge >/dev/null

# THE CROSS-CUTTING FINDING re-measured, not just asserted: the four vacuous rails are vacuous
# because the directories are absent, which is a layout fact and not a transient one.
test ! -d web/templates && test ! -d web/blueprints
test "$(find web lib -name '*.py' 2>/dev/null | wc -l)" -eq 0

# NOTHING IN THE VENDORED TREE WAS CHANGED. The task's central boundary — this was a triage,
# not a fix round.
git diff --quiet HEAD -- .agentic-framework/

# Both findings are filed where an instrument can see them, not left as prose (PL-145).
grep -q 'OBS-380' .context/inbox.yaml && grep -q 'OBS-381' .context/inbox.yaml

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

### 2026-09-25T11:20:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-846-triage-the-15-standing-audit-warnings-is.md
- **Context:** Initial task creation
