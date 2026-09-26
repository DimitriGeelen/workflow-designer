---
id: T-862
name: "Handover Suggested First Action is non-carrying: regeneration overwrites hand-enrichment
  with a one-line stub"
description: >
  OBS-383. handover.sh generates the Suggested First Action as a single line 'Continue
  T-XXX: <name>' with no carry-forward. Any hand-enrichment of that section has a
  shelf life of exactly one regeneration. Measured four times on 2026-09-25/26; instance
  four replaced a 71-line/4982-char enriched section with 7 lines, one commit apart.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [handover, false-green, arc:arc-003]
components: [tests/run-bridge-tests.sh, tools/_t536-status-desync-teeth.py, tools/_t862-handover-carry-teeth.sh]
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
created: 2026-09-26T00:24:55Z
last_update: 2026-09-26T00:39:25Z
date_finished: 2026-09-26T00:39:25Z
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
  - ts: '2026-09-26T00:27:01Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=337,acs=9)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-26T00:29:28Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (3-components); tier=2 (workflow:build); effort=8 
      (lines=337,acs=9)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-26T00:27:14Z'
---

# T-862: Handover Suggested First Action is non-carrying: regeneration overwrites hand-enrichment with a one-line stub

## Context

OBS-383. `handover.sh:1394-1490` emits the `## Suggested First Action` section as a single
generated line — `Continue {tid}: {tname}` — chosen by a candidate sort over active tasks.
There is no carry-forward and no enrichment source. Every hand-improvement to that section
therefore has a shelf life of exactly one regeneration.

Measured four times across 2026-09-25/26, each time the same shape. Instance four is the
cleanest evidence because the two files sit one commit apart with the focus task unchanged:

| file | commit | SFA size |
|---|---|---|
| `S-2026-0926-0154.md` (hand-enriched) | `cfc7e9ed` | 71 lines / 4,982 chars |
| `S-2026-0926-0201.md` (regenerated)   | `f98bf459` | 7 lines |

Focus was `T-737` in both. Nothing about the situation changed between them except that the
generator ran.

This is the session's central false-green class, applied to the handover itself: the document
LOOKS complete — every section present, zero `[TODO]` markers — while the one section a next
session actually acts on has been emptied. A reader cannot distinguish "the author had nothing
more to say" from "the author's words were discarded".

OBS-383 records three candidate fixes. This task implements (a) — carry forward — because it is
the only one that is pure data preservation and so commits to no architecture. (b) sourcing the
section from the focus task's body relocates authority over handover content and is a Sovereign
question, deliberately not taken here. (c) a refusal check detects the loss without preventing
it, and is subsumed by the teeth instrument below.

## Acceptance Criteria

### Agent
- [x] `handover.sh` locates the predecessor handover (the file `LATEST.md` pointed at before this run) and extracts its `## Suggested First Action` section
- [x] When the focus task is UNCHANGED and the predecessor's section is richer than the generated one-liner, the predecessor's content is carried into the new handover instead of being replaced by the stub
- [x] Carried content is labelled with its origin session id and the age of the content, so a reader can tell carried-forward from freshly-generated and judge staleness themselves — carrying silently would replace one false-green with another
- [x] When the focus task CHANGES between handovers, the section is regenerated and NOT carried: a plan written for a different task must never be presented as this task's next step
- [x] When the predecessor's section is itself the bare one-line stub, nothing is carried and no provenance label is emitted (no provenance noise on content that has none)
- [x] `tools/_t862-handover-carry-teeth.sh` exercises all four behaviours above, and its `--mutation` mode reports `MUTATION SETUP BROKEN` when its CONTROL SET goes red rather than reading a broken harness as a clean kill
- [x] End-to-end on real files: a regeneration whose predecessor is the enriched `S-2026-0926-0154.md` preserves >4,000 chars in the section, where the unpatched generator preserves 0

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

# The suite itself. Guarded both ways (T-2738): a trailing "FAIL 0" alone would
# survive a run that printed per-case FAILs, so the absence of case-level FAIL
# lines is asserted over the same capture that supplies the positive match.
out=$(bash tools/_t862-handover-carry-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$' && ! echo "$out" | grep -q '^  FAIL'
# Both mutations. Either one alone is satisfiable by a wrong implementation:
# "never carry" is the bug, "always carry" is worse than the bug. MUTATION OK is
# printed only when the dependent cases died AND the control cases survived.
out=$(bash tools/_t862-handover-carry-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK (carrying stripped)'
out=$(bash tools/_t862-handover-carry-teeth.sh --mutation-overfire 2>&1); echo "$out" | grep -q 'MUTATION OK (focus guard stripped)'
# The subject still parses, and the teeth can still reach it. Both markers are
# load-bearing: extraction is anchored on them, and without this line a rename
# would leave the suite exiting 4 with nobody reading the 4.
bash -n .agentic-framework/agents/handover/handover.sh
grep -q '^# ── SUGGESTED FIRST ACTION CARRY-FORWARD (T-862, OBS-383) ──' .agentic-framework/agents/handover/handover.sh
grep -q '^# ── end T-862 carry-forward ──$' .agentic-framework/agents/handover/handover.sh
# The sweep discovers it, so it is re-run by something other than this task.
out=$(bash tools/_t509-instrument-sweep.sh --only _t862 2>&1); echo "$out" | grep -q 'SWEEP PASS'

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

**Symptom:** A hand-enriched `## Suggested First Action` is replaced by the one-line stub
`Continue T-XXX: <name>` at the next handover generation. Measured four times on 2026-09-25/26;
instance four lost 4,982 chars one commit after they were written, focus task unchanged.

**Root cause:** The section is GENERATED, never READ. `handover.sh:1394-1490` computes a single
line from a candidate sort over active tasks and writes it unconditionally. The generator has no
notion of a predecessor and no notion that the section it is about to overwrite might contain
something it did not author. It is not thin — it is non-carrying.

**Why structurally allowed:** The handover is assembled by concatenation, so every section is
authored fresh each run and the whole file is treated as derived output. That is true of the
sections fed by git and by the task register, and it is false of exactly one section — the only
one a human or agent is invited to improve. Nothing in the pipeline distinguishes a derived
section from an authored one, so the destructive write looks identical to the 20 harmless ones.
Compounding it, the loss is silent by construction: the regenerated file passes every existing
completeness check, because a stub is present and a stub is not missing. There is no check
anywhere that compares a handover to its predecessor, so the defect could only ever be caught by
a reader who happened to remember what the previous file said.

**Prevention:** distinct from the fix. The fix carries content forward; the prevention is
`tools/_t862-handover-carry-teeth.sh`, whose over-firing control asserts the inverse property —
that a CHANGED focus task still regenerates — so the instrument cannot be satisfied by a
carry-everything implementation that would be worse than the bug. The provenance label is the
second prevention: it makes a carried section self-describing, so a stale carry is visible to
the reader instead of reading as fresh authorship.

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

### 2026-09-26 — the fix is chosen for what it does NOT decide

- **What changed:** OBS-383 offered three candidates and I had been reading them as three
  competing fixes. They are not peers. (a) carry-forward is data preservation; (b) sourcing the
  section from the focus task's body is a relocation of authority over handover content; (c) a
  refusal check is detection. Only (b) is architectural, and it is the one I applied BY HAND
  under T-737 — which is why it felt like the natural choice and why choosing it here would have
  been deciding a Sovereign question to keep momentum.
- **Plan impact:** scope narrows to (a) plus the teeth. (b) is surfaced as a Sovereign question
  rather than implemented. (c) is absorbed into the instrument instead of shipping as a gate.
- **Triggered:** SQ recorded in the handback — "should the Suggested First Action be authored in
  the handover at all, or rendered from the focus task's body?"

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

### 2026-09-26T00:24:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-862-handover-suggested-first-action-is-non-c.md
- **Context:** Initial task creation

### 2026-09-26T00:30:21Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b7fab5ba
- **Timestamp:** 2026-09-26T00:39:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-26T00:39:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
