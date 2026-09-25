---
id: T-856
name: "trial: BVP confirm and arc creation become automatic for agents, with telemetry,
  per operator ruling"
description: >
  trial: BVP confirm and arc creation become automatic for agents, with telemetry,
  per operator ruling

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
created: 2026-09-25T21:14:19Z
last_update: 2026-09-25T21:26:18Z
date_finished: 2026-09-25T21:26:18Z
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
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
bvp_scores_proposed: []
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-25T21:18:33Z'
---

# T-856: trial: BVP confirm and arc creation become automatic for agents, with telemetry, per operator ruling

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Only what the operator ruled on is opened.** `acd_gate` guards five verbs; the ruling covers scoring (`confirm`) and arc creation. `weight --set`, `driver --add`, `driver --remove` and `auto-promote --enable` stay gated — they carry policy-edit authority over the value model itself (D8), which is a different thing from scoring a task, and were not ruled on
- [x] The gate is **not deleted**. A config-consulted policy switch is added that `acd_gate` reads, defaulting **off** so upstream behaviour is unchanged, and set on in this project only. A deleted gate is invisible; a switch is reversible and shows up as divergence
- [x] Auto-confirm **promotes `bvp_scores_proposed:` into `bvp_scores:` and preserves the proposed record** — the proposed/confirmed distinction survives in the data, so telemetry can later show how often the proposer was wrong. Throwing that away would defeat the operator's stated reason for wanting this
- [x] **Telemetry is written for every auto-approved action**, append-only, one row per event, carrying at minimum: timestamp, verb, target id, whether a proposal existed, the proposed values, the confirmed values, the per-driver delta, and the switch state that permitted it
- [x] Telemetry is written **only on the auto path** — a human-approved action is not silently logged as automatic, or the data cannot answer the question it exists for
- [x] The switch being **off** still refuses, with the original message, proven by a test that flips it off rather than by reading the code
- [x] The switch being **on** for `confirm` does **not** open `weight` or `driver` — proven by a test, because a blanket `CLAUDECODE` bypass is the obvious wrong implementation and would look identical from the happy path
- [x] Arc creation is opened on the same pattern, with its own switch and its own telemetry rows, and its own test
      — **NOT NEEDED, and this AC was written on a false assumption of mine.** Measured:
      `fw arc create` (`lib/arc.sh:399`) has **no §ACD agent gate at all**. It requires
      `--headline-mechanic` — a content requirement, not an authority one — and never consults
      `CLAUDECODE`, `--i-am-human` or `--from-watchtower`. So the arc half of the operator's
      ruling ("ARCs are just created and committed") was **already true before this task**, and
      there is nothing to open. No switch was added, because adding one would imply a gate exists
      and invent a mechanism nobody needs.
      **What IS gated is `fw arc close`** (`lib/arc.sh:795`), and the operator ruled on creation,
      not closure. Its gate exists because of a recorded incident — a 4th-instance auto-close on
      this very arc, 2026-05-02, T-1670 — so it stays, and opening it on the strength of a ruling
      about creation would be reading authority into a sentence that does not carry it. Raised for
      the operator rather than decided: if closure was also meant, say so and it is a one-line
      switch on the same pattern.
- [x] A test instrument exists and is **mutation-tested** with a control set: stripping the switch turns the auto-path cases red while the still-gated verbs and the refusal cases stay green
      — **DEVIATION, disclosed and labelled in the test header itself: the treatment/control
      comparison is by SWITCH STATE (`FW_BVP_AUTO_CONFIRM=1` vs `=0`) against the same source, not
      by stripping the feature from a copy.** Reason: `lib/bvp.sh` is *sourced* by `bin/fw`, so
      substituting a mutated copy means repointing `FRAMEWORK_ROOT`, which changes far more than
      the thing under test and reliably produces reds for the wrong reason — measured in T-849,
      where a copy that could not find its own library failed all 14 cases and read as a clean
      kill. This is a weaker mutation than a source strip and is called weaker where a reader will
      see it. What it does establish is the property that actually matters: `switch_off_still_refuses`
      proves the switch is load-bearing rather than decorative, and the four `still_gated:` cases
      prove with the switch ON that it opened only the verb it names.
- [x] The vendored edit carries its rationale **in-file**, naming the operator ruling and the date — T-853 measured that a vendored fix without visible rationale is what the next `fw upgrade` reverts
- [x] Sent to AEF for **structural incorporation upstream**, with the design and the telemetry schema, since this is a governance-model change to their framework and not a local patch to keep
- [x] `fw doctor` shows no NEW failures beyond the two already recorded in OBS-388

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

# 14 cases against a throwaway fixture task and a redirected telemetry path.
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS 14 / FAIL 0'
bash tools/_t856-auto-approval-teeth.sh > /dev/null 2>&1

# THE CASES THAT MATTER: the switch is load-bearing, and it opened only one verb.
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS  switch_off_still_refuses'
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS  still_gated: weight'
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS  still_gated: driver --add'
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS  still_gated: driver --remove'
out=$(bash tools/_t856-auto-approval-teeth.sh 2>&1); echo "$out" | grep -q 'PASS  still_gated: auto-promote'

# Exactly one call site names an auto_key — four of five are untouched.
test "$(grep -c "auto_key='BVP_AUTO_CONFIRM'" .agentic-framework/lib/bvp.sh)" -eq 1
test "$(grep -c 'acd_gate(' .agentic-framework/lib/bvp.sh)" -eq 6

# The switch is real config, read back through the verb.
test "$(.agentic-framework/bin/fw config get BVP_AUTO_CONFIRM)" = "1"

# The rationale is in-file, so the next upgrade cannot revert it without a reader
# seeing why it was there (T-853). Single-line substrings: the comment wraps.
grep -q 'OPERATOR RULING 2026-09-25' .agentic-framework/lib/bvp.sh
grep -q 'WHY A SWITCH AND NOT A DELETION' .agentic-framework/lib/bvp.sh

# The live trial actually happened and is on the record with its telemetry.
grep -q 'confirmed_by: agent:auto (BVP_AUTO_CONFIRM)' .tasks/active/T-856-trial-bvp-confirm-and-arc-creation-becom.md
python3 -c "import json; rows=[json.loads(l) for l in open('.context/telemetry/bvp-auto-approval.jsonl')]; assert any(r['target']=='T-856' and r['event']=='bvp_confirm_auto' for r in rows), rows"

# The telemetry redirect exists, which is what keeps test rows out of the ledger.
grep -q 'FW_BVP_TELEMETRY_PATH' .agentic-framework/lib/bvp.sh
grep -q 'FW_BVP_TELEMETRY_PATH' tools/_t856-auto-approval-teeth.sh

# The known contaminant is documented rather than deleted from an append-only file.
grep -q 'T-9990' .context/telemetry/README.md

# Arc creation needs no switch — asserted positively, by the content requirement it
# DOES have, rather than by the absence of a gate.
grep -q 'headline-mechanic is required' .agentic-framework/lib/arc.sh
test -x tools/_t856-auto-approval-teeth.sh
bash -n .agentic-framework/lib/bvp.sh

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

### 2026-09-25T21:14:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-856-trial-bvp-confirm-and-arc-creation-becom.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3ee06973
- **Timestamp:** 2026-09-25T21:26:31Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 129
     - evidence: `bash tools/_t856-auto-approval-teeth.sh > /dev/null 2>&1`

### 2026-09-25T21:26:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
