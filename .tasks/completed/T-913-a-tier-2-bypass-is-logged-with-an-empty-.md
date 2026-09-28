---
id: T-913
observation: OBS-423
name: "A Tier-2 bypass is logged with an EMPTY reason, because the logger takes no
  reason argument. Measured 2026-09-28: closing T-910 with --skip-sovereignty appended
  this to .context/working/.gate-bypass-log.yaml — timestamp 2026-09-28T10:49:48Z,
  task T-910, flag --skip-sovereignty, caller check_human_sovereignty, reason: ''.
  The call site is log_gate_bypass '--skip-sovereignty' 'check_human_sovereignty'
  (update-task.sh:112), two positional args, no third for a reason and no --reason
  flag anywhere on the verb. So the field exists in the record shape and can never
  be filled by the path that writes it. WHY THIS MATTERS RATHER THAN BEING COSMETIC:
  mandatory logging is what makes Tier 2 a sanctioned mechanism instead of a hole.
  A record that says a gate was bypassed but not why cannot distinguish an AUTHORISED
  bypass from an unauthorised one — and the same ledger already carries a 2026-08-08
  entry that exists precisely to document an unauthorised bypass ('No authorization
  was sought or given. Recorded per Tier-2 mandatory logging.'), with a full reason,
  because a human wrote that one by hand. The automated path produces the weaker record.
  THE AUTHORISATION FOR THIS ONE, since the ledger cannot hold it — operator, verbatim,
  2026-09-28: 'This is a Zero Human ACs review task. You should not even ask me.'
  T-910 carried 0/0 Human ACs and 6/6 Agent ACs with verification 10/10; the sovereignty
  gate fired on the owner field with no human criterion behind it. Remedy: give log_gate_bypass
  a reason parameter and have the --skip-* flags accept --reason, refusing the bypass
  when none is supplied — a bypass worth taking is a bypass worth explaining. Sibling
  of OBS-421/OBS-422."
description: >
  Promoted from observation OBS-423

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
created: 2026-09-28T11:31:03Z
last_update: 2026-09-28T22:07:56Z
date_finished: 2026-09-28T22:07:56Z
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
  - ts: '2026-09-28T22:04:39Z'
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

# T-913: A Tier-2 bypass is logged with an EMPTY reason, because the logger takes no reason argument. Measured 2026-09-28: closing T-910 with --skip-sovereignty appended this to .context/working/.gate-bypass-log.yaml — timestamp 2026-09-28T10:49:48Z, task T-910, flag --skip-sovereignty, caller check_human_sovereignty, reason: ''. The call site is log_gate_bypass '--skip-sovereignty' 'check_human_sovereignty' (update-task.sh:112), two positional args, no third for a reason and no --reason flag anywhere on the verb. So the field exists in the record shape and can never be filled by the path that writes it. WHY THIS MATTERS RATHER THAN BEING COSMETIC: mandatory logging is what makes Tier 2 a sanctioned mechanism instead of a hole. A record that says a gate was bypassed but not why cannot distinguish an AUTHORISED bypass from an unauthorised one — and the same ledger already carries a 2026-08-08 entry that exists precisely to document an unauthorised bypass ('No authorization was sought or given. Recorded per Tier-2 mandatory logging.'), with a full reason, because a human wrote that one by hand. The automated path produces the weaker record. THE AUTHORISATION FOR THIS ONE, since the ledger cannot hold it — operator, verbatim, 2026-09-28: 'This is a Zero Human ACs review task. You should not even ask me.' T-910 carried 0/0 Human ACs and 6/6 Agent ACs with verification 10/10; the sovereignty gate fired on the owner field with no human criterion behind it. Remedy: give log_gate_bypass a reason parameter and have the --skip-* flags accept --reason, refusing the bypass when none is supplied — a bypass worth taking is a bypass worth explaining. Sibling of OBS-421/OBS-422.

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**OBS-423 is partly wrong and this task corrects it.** It claimed `log_gate_bypass` "takes no reason
argument, so the field can never be filled by the path that writes it". True of its *parameters*,
false of its *behaviour*: it reads the global `$REASON` at `update-task.sh:96`, and `--reason` /
`-r` sets that global at `:1478`. The capability has been there all along.

**The real defect is narrower and worse:** a bypass may be taken without explaining it, and the
resulting record is **byte-identical to an explained one that happened to have an empty reason**.
The T-910 entry from earlier today reads `reason: ''` — indistinguishable from a logging failure,
from a tool that never supported reasons, and from a deliberate blank.

- [x] An unexplained bypass is recorded **distinguishably** — a named marker in the `reason` field, not an empty string. The audit question "how many bypasses were taken without explanation?" must be answerable by reading the ledger
- [x] The marker **names the remedy**: a reader of the record, and the operator at the moment of bypassing, both learn that `--reason` is what fills it
- [x] A bypass **with** a reason is unchanged — the reason is written verbatim, and the YAML single-quote escaping at `:88-96` still holds for apostrophes in operator text
- [x] Call sites that currently **smuggle a reason into the `caller` argument** (`:557`, `:988`) have a proper channel — an explicit reason parameter — without changing what they log today
- [x] **Non-blocking.** This records and warns; it does not refuse. Making an unexplained bypass *fail* changes blocking behaviour on eighteen call sites including env-var paths used by automation, and that deserves its own task and fresh judgement rather than being folded in at the end of a long session
- [x] **Proved by exercising the real logger**, not by reading it: run it with and without a reason and assert the ledger rows differ in the stated way. Append-only ledger — the test writes to a scratch copy, never to `.context/working/.gate-bypass-log.yaml`
- [x] Control set first, and every mutation asserted applied: a logger that fails to source writes nothing, which would read as "no unexplained bypasses found"

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

# The teeth, with the real ledger's hash pinned BEFORE the run so the unchanged-check is a
# measurement rather than a comparison of the file with itself.
LEDGER_SHA=$(sha256sum .context/working/.gate-bypass-log.yaml | cut -d' ' -f1) timeout 300 bash tools/_t913-bypass-reason-teeth.sh > /tmp/.t913.out 2>&1 && grep -q '^FAIL: 0' /tmp/.t913.out
# CONTROL (PL-328): 'FAIL: 0' is also what a suite that ran nothing prints.
grep -qE '^PASS: 1[0-9]$' /tmp/.t913.out
# CONTROL, stronger: the mutation must have been SCORED, not skipped as setup-broken.
grep -q 'REGRESSES to the empty string without the marker' /tmp/.t913.out
# And the ledger-unchanged leg must have EVALUATED, not reported NOT EVALUATED.
grep -q "the project's own bypass ledger is unchanged" /tmp/.t913.out
# The marker and the explained flag exist in the logger itself.
grep -q 'UNEXPLAINED — no reason given' .agentic-framework/agents/task-create/update-task.sh
grep -q 'explained: \$(\[ "\$_explained" -eq 1 \]' .agentic-framework/agents/task-create/update-task.sh
# The two call sites that smuggled a reason through the caller argument now use the 3rd parameter.
test "$(grep -c 'log_gate_bypass "--skip-render-review" "check_render_surface_human_ac" "\$SKIP_RENDER_REVIEW_REASON"' .agentic-framework/agents/task-create/update-task.sh)" -eq 1
test "$(grep -c 'log_gate_bypass "--scope-reduction-acknowledged" "check_task_pair_acd" "\$SCOPE_REDUCTION_ACK"' .agentic-framework/agents/task-create/update-task.sh)" -eq 1
# A syntactically broken update-task.sh breaks every task transition in the project.
bash -n .agentic-framework/agents/task-create/update-task.sh

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

### 2026-09-29 — OBS-423 was partly wrong, and reading the code before building found it
- **What changed:** OBS-423 (mine, filed hours earlier) claimed `log_gate_bypass` *"takes no reason
  argument, so the field can never be filled by the path that writes it"*. It reads the global
  `$REASON` at `:96`, and `--reason`/`-r` sets it at `:1478`. **The capability was always there.**
  I had inferred the absence from the call signature without reading the body — the same shape as
  OBS-421, where I inferred the completion path from the reassignment gate's error text.
- **Plan impact:** the fix got smaller and better aimed. Not *"add a reason parameter"* but *"make
  an unexplained bypass distinguishable from an explained one"* — which is the defect the T-910 row
  actually demonstrates, and which no amount of adding parameters would have fixed.
- **Triggered:** nothing filed; the correction lives in this task's ACs so a reader of OBS-423
  meets it.

### 2026-09-29 — scoped deliberately short of a refusal
- **What changed:** nothing; this is the decision. Making an unexplained bypass **fail** is the
  stronger fix and it changes blocking behaviour on **eighteen** call sites, several of them
  env-var paths that automation uses.
- **Plan impact:** this ships the recording half — marker, `explained:` flag, and a warning at the
  moment of bypassing. The refusal half is not folded in at the end of a long session after a day
  of gate work; it wants fresh judgement and its own teeth.
- **Triggered:** nothing filed yet — whether to refuse is a governance call, not an implementation
  one, and it is the operator's.

### 2026-09-29 — a tautology in a parameter default
- **What changed:** the "real ledger unchanged" leg read
  `${LEDGER_SHA:-$(sha256sum "$real" …)}` — so when the caller did not pin the hash first, it
  compared the file **to itself** and could not fail. It passed, which is how I noticed nothing.
- **Plan impact:** it now reports **NOT EVALUATED** when unpinned, and the verification block pins
  the hash before invoking the suite. A default that supplies the expected value is not a default,
  it is a way of deleting the assertion.
- **Triggered:** nothing new — T-3105, in a place I did not expect to find it.

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

### 2026-09-28T11:31:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-913-a-tier-2-bypass-is-logged-with-an-empty-.md
- **Context:** Initial task creation

### 2026-09-28T22:04:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-79a7dd1b
- **Timestamp:** 2026-09-28T22:07:58Z
- **Catalogue:** v1.3-seed
- **Overall:** FAIL
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **skip-as-pass** (severe, deterministic) @ Verification:line 14
     - evidence: `test "$(grep -c 'log_gate_bypass "--skip-render-review" "check_render_surface_human_ac" "\$SKIP_RENDER_REVIEW_REASON"' .agentic-framework/agents/task-create/update-task.sh)" -eq 1`

### 2026-09-28T22:07:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** T-913 closing: the recording half of the bypass-reason fix. This close needs no bypass, so no ledger row is expected from it.
