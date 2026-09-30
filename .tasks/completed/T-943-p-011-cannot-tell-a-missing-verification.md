---
id: T-943
name: "P-011 cannot tell a missing Verification heading from a malformed one, and the T-574 probe that would catch it is anchored to a source line that moved"
description: >
  P-011 cannot tell a missing Verification heading from a malformed one, and the T-574 probe that would catch it is anchored to a source line that moved

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh, tools/_t574-p011-block-locator-teeth.py]
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
created: 2026-09-30T12:52:58Z
last_update: 2026-09-30T13:07:40Z
date_finished: 2026-09-30T13:07:40Z
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

# T-943: P-011 cannot tell a missing Verification heading from a malformed one, and the T-574 probe that would catch it is anchored to a source line that moved

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

**A local fix to a vendored file was silently reverted by a framework upgrade, and the guard
that would have caught it has been shouting into an ungated suite for five days.**

| | |
|---|---|
| 2026-08-22 `b17e49fa` | T-575 lands T-574's fix in the **vendored** `update-task.sh`: an exact-heading locator (`_v_exact`) plus a `COULD NOT READ THE BLOCK` refusal |
| 2026-09-25 `7b5e227e` | *"T-840: upgraded to AEF bleeding-edge 1.7.68"* overwrites the file. `_v_exact`, `_v_why` and the refusal string: **0 occurrences** afterwards |
| 2026-09-30 | found, by running the suite |

T-840's own commit message records that the upgrade regressed the mandated commit spelling. This
was a **second regression in the same upgrade**, and nobody looked for it. The root cause is not
the upgrade: it is that T-574/T-575 fixed OUR COPY and never landed the fix upstream, so every
re-vendor reverts it. That will happen again on the next upgrade unless AEF carries it.

**What is actually broken.** T-3232 later added a genuinely better contract in
`lib/verification-port.sh` — `extract_verification_block` returns 2 when it cannot READ the
block, which update-task.sh refuses on, and the comment correctly argues the gate should not
re-check the heading because "a guard that reimplements the code it guards cannot detect that
code being fixed or re-broken". That reasoning is sound and this task does not undo it.

But rc=2 only covers the *undecodable bytes* case. The *unmatched heading* case returns empty
with rc=0 — **byte-identical to a task that legitimately has no Verification section.** Measured
directly against the live function:

| fixture | rc | bytes |
|---|---|---|
| well-formed | 0 | 4 |
| no section at all | 0 | 0 |
| `## Verification` glued to an AC line (the real T-572 shape) | **0** | **0** |
| `## Verification (P-011)` | **0** | **0** |

Both malformed fixtures contained `false` — a command that would have BLOCKED completion had it
run. The awk anchor in `verification-port.sh:205` is the only exact-heading match anywhere in the
framework, and nothing cross-checks it.

**Severity: latent, not live.** 941 of 941 task files carry an exact heading, because the template
supplies it, so no task is in this state today and no close made today was a silent pass — the
dry runs visibly reported 5/5 and 8/8. It matters because T-572's original trigger was
*automated tooling* splicing the heading (an `s.index()` matching a backticked mention of it),
which recurs from a tool bug rather than from anyone's typo.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **`extract_verification_block` distinguishes "no heading" from "heading-like line present
      but unmatched"** with a third return code, keeping the exit code as the entire contract.
      It must NOT reintroduce a heading check inside update-task.sh — T-3232's argument against a
      guard that reimplements the code it guards still holds
      → `rc=3`, added inside the shared helper. update-task.sh gained only an exit-code branch.
- [x] **The detection does not fire on a prose mention.** A task body that references
      `` `## Verification` `` mid-sentence while having a proper heading, or while genuinely
      having no section, must stay rc=0. "Heading-like" means a line that starts with `##` and
      names Verification, or a line that ENDS with the heading (the glue shape) — not any
      occurrence of the substring
      → two over-fire controls in `_t943-heading-states.sh`, both rc=0. A bare substring test
      would have refused a large and legitimate slice of this corpus.
- [x] **update-task.sh refuses on the new code** with a message that names the file, says zero
      commands would have run, and states the bypass. Proven by driving the real function, not
      by reading the code
      → `t572-refused` leg drives the real `run_verification_commands` against the real lib and
      gets rc=1 + `COULD NOT READ THE BLOCK`.
- [x] **Both directions, against the live function:** well-formed still runs its commands and
      reports the count; genuinely-absent still passes through; both malformed shapes now refuse.
      The absent-vs-malformed pair is the whole defect and gets its own assertion
      → 7/7 in `_t943-heading-states.sh`, rc 0/0/3/3 across the four states. Also restored the
      zero-count announcement: the absent path was returning in SILENCE, which is the literal
      sentence in T-574's title ("0 legs run reads identical to all legs passed"), and it went
      out with the same re-vendor.
- [x] **The T-574 probe tests the CONTRACT, not a source line.** Re-anchored to
      `lib/verification-port.sh` so a legitimate refactor cannot blind it again, with its
      control-first and targeted-mutant discipline intact. `python3
      tools/_t574-p011-block-locator-teeth.py` exits 0 rather than ABORT
      → **13/13, rc=0.** Restructured rather than re-anchored: 6 behavioural legs with NO source
      anchors run first and unconditionally, then 7 mutation legs that need anchors. A moved
      anchor now reports a failing leg saying the discrimination proof is unavailable, while the
      behavioural legs still answer whether the protection works. Proven by pointing the probe at
      a doctored lib: old code printed one ABORT line and nothing else; new code names
      `t572-refused` and `absent-vs-malformed` as red and exits 1.
      Two further defects of my own, found while doing it: the refusal paths `exit 1`, so the
      harness never echoed `GATE_RC` and every refusing fixture read as rc=None ≠ 1 — the probe
      would have gone red on a working gate and blamed the gate; and my first draft dropped the
      no-op-mutation guard, so a dead patch would have reddened the subject instead of the
      harness (PL-339). Both fixed and asserted.
- [x] **Reported upstream to AEF,** because the fix lives in a vendored file and the measured
      root cause is a re-vendor reverting a local change. Without this the next upgrade reverts
      it a second time and the only difference will be that the probe now works
      → `aef-install-findings` **@39**, as a `[PICKUP REQUEST]` in that channel's house format,
      carrying `from_project: 832-Workflow-designer` (the T-420 attribution gate refused the
      first attempt for omitting it — 239 of 245 content envelopes on that rail carry no
      producer label, so the gate is right about the class).
      Three framework-side fixes suggested, only the first applied here. The one named as most
      wanted is **not** our patch: a re-vendor that overwrites a locally-modified framework file
      should say so per file. That covers every future instance of this class, including the
      ones nobody has written a guard for. Also asked them the question this project cannot
      answer — whether the refusal was ever upstream at all, because if it was not, every other
      consumer that vendored this gate is in the state we were in and has no probe to find out.

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

# The probe runs and PASSES rather than ABORTing. 13 legs: 6 behavioural (no source
# anchors, so they survive a refactor or a re-vendor) + 7 mutation legs proving the
# fixtures discriminate, each with a no-op guard so a dead patch names the harness.
python3 tools/_t574-p011-block-locator-teeth.py
# The three states the gate must not conflate, asserted directly against the live
# function rather than through the gate's output. Order is the assertion: absent and
# malformed must not return the same thing, which is the entire defect.
bash tools/_t943-heading-states.sh
# The new return code is reachable from the caller, and the caller refuses on it.
grep -q 'extract_rc" -eq 3' .agentic-framework/agents/task-create/update-task.sh
# The corpus is not in the refused state, so this fix opens no existing close.
# Stated POSITIVELY (T-843 refused the negation, correctly): `grep -L ... -eq 0` passes
# vacuously if the GLOB matches nothing — a broken path and a clean corpus produce the
# same green. So assert a non-empty denominator first, then that every file in it carries
# the heading. Compares two counts rather than pinning either, so it does not rot as tasks
# are added (T-3326).
test "$(ls .tasks/active/*.md .tasks/completed/*.md | wc -l)" -gt 0
test "$(grep -l '^## Verification[[:space:]]*$' .tasks/active/*.md .tasks/completed/*.md | wc -l)" -eq "$(ls .tasks/active/*.md .tasks/completed/*.md | wc -l)"

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

### 2026-09-30T12:52:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-943-p-011-cannot-tell-a-missing-verification.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-22892304
- **Timestamp:** 2026-09-30T13:07:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-30T13:07:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
