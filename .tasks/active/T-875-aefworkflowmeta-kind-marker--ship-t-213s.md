---
id: T-875
name: "aef:workflowMeta kind marker — ship T-213's ratified enum so a map declares
  whether it is illustrative or actionable"
description: >
  arc-005 S1/B1. T-213 GO'd 2026-07-21 and was ratified by the operator (its [REVIEW]
  Human AC is ticked); 68 days later aef:workflowMeta still carries only version/uuid/title/schemaVersion/id/default
  and no kind. Ship the enum exactly as T-213 disposed it: closed {documentation,
  work-plan}, default UNSET so absent/unknown round-trips byte-identical, additive
  and frozen-v1 safe. Re-check the frozen-v1-safe claim rather than inherit it. Does
  NOT widen the enum to cover class/instance — that is arc-005 S2's question.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:process-instances]
components: []
related_tasks: []
arc_id: process-instances
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-26T22:41:33Z
last_update: 2026-09-28T08:44:10Z
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
bvp_scores_proposed: []
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 0
  F3: 4
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-26T23:10:59Z'
---

# T-875: aef:workflowMeta kind marker — ship T-213's ratified enum so a map declares whether it is illustrative or actionable

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] `aef:workflowMeta kind=` validates against a CLOSED enum of exactly `documentation` and `work-plan`; any other value is an error whose message names the allowed set
- [x] A map carrying no `kind` validates clean — UNSET is legal and is not a warning (T-213 IW-3: the marker stays an explicit author decision, no silent reclassification)
- [ ] Round-trip: a map with no `kind` is byte-identical through import→export. CONTROL: a map WITH `kind` also round-trips byte-identical, so a dead harness cannot read as a clean pass
- [x] T-213's "additive + frozen-v1 safe" claim is RE-DERIVED against `docs/standards/aef-bpmn-mapping-v1.md`, not inherited — cite the Part I clause that makes an additive `aef:workflowMeta` attribute conformant, or report that no such clause exists. The standard is frozen and is NOT edited
- [ ] A conformance case lands in the existing mapping-conformance suite, not in a new parallel harness
- [ ] **A5 recorded:** does this deliver arc purpose (A1) and project purpose? Answer and reason written in `## Decisions`, and the answer may be **no**
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

### 2026-09-26T22:41:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-875-aefworkflowmeta-kind-marker--ship-t-213s.md
- **Context:** Initial task creation

### 2026-09-26T23:11:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## 2026-09-27 — PARKED at AC3. The round-trip guard does not cover this attribute.

**Shipped and checked:**

- Module-scope `WORKFLOW_KINDS = {"documentation", "work-plan"}`, read by BOTH forms —
  one copy, per T-322 (a second copy of a governance vocabulary is how the two forms drift
  apart on the governance question itself).
- `E-WORKFLOW-KIND` (YAML) and `E-XML-WORKFLOW-KIND` (XML). Measured on real fixtures:
  no-kind → exit 0 · `kind="documentation"` → exit 0 · `kind="bogus"` → exit 2,
  `kind 'bogus' not in ['documentation', 'work-plan']`. Fixtures verified to actually
  differ first, so the two passes are not vacuous.
- Editor reader **and** writer (`src/aef-workflow-designer.html`). The writer was the real
  find: its `wmAttrs` list is fixed and had no `kind`, so an imported marker would have been
  silently dropped on first save — worse than absent, because it survives review and vanishes
  in use.
- **AC4 re-derived with a control.** `aef:workflowMeta` appears ZERO times in the frozen
  standard (control: `aef:uid` 8, `aef:meta` 7, `aef:position` 1, `aef:io` 1 — same grep
  shape, same file, same run). T-213's "frozen-v1 safe" holds, but NOT for the reason the
  word "additive" suggests: §1's two-class partition enumerates NODE-level attributes and
  §6's four conformance clauses never reach document-level metadata. **The standard has no
  document-level class at all** — a gap in the standard, and T-877's strongest content.

**Why AC3 is not closed, and it is not a near-miss.**

`tools/_roundtrip-serialization-cdp.mjs` passed with the new kind-carrying fixture
(`tests/fixtures/aef-bpmn/t875-kind-marker.bpmn`, 20 fixtures, pass: true). **That green was
vacuous and a mutation proved it.** Deleting the writer line entirely and re-running gave
`exit=0, pass: true` — the guard does not notice.

Not a broken harness. `checkDenominator()` derives its 36 keys from **`aef.*` accesses** —
dot accesses, metaKeys, bindFields — i.e. the NODE-level seam. `workflowMeta.kind` is
`wm.kind`. Document-level metadata is outside its denominator **by construction**, and so are
`uuid`, `pageWidth`, `tier_default` and `title`. The right guard, the wrong seam.

AC3 therefore needs its own instrument: a workflowMeta round-trip teeth with a mutation
control, which must also establish whether `kind`'s siblings were ever covered by anything.
That is a real question — four attributes may have been riding on no guard at all.

**State:** the marker validates and round-trips in the editor; nothing asserts that it keeps
round-tripping. Do not treat it as guarded. T-876 (corpus backfill) stays blocked behind this:
backfilling 24 seam artefacts with an attribute whose persistence nothing checks is the wrong
order.

### 2026-09-26T23:17:44Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** AC3 unclosable by the existing instrument: the round-trip guard derives its denominator from node-level aef.* accesses, so document-level workflowMeta attributes are outside its scope by construction. Proved by mutation — deleting the writer line still passes. Needs a dedicated workflowMeta round-trip teeth with a mutation control, which must also establish whether uuid/pageWidth/tier_default/title were ever covered by anything.

### 2026-09-28T08:44:04Z — issue-resolved [healing-agent]
- **Action:** Issue resolved via healing loop
- **Output:** Pattern FP-020 recorded
- **Mitigation:** T-886 built the instrument T-875's issues-reason said was missing, and nothing moved T-875 out of issues when it landed. The recorded blocker was: 'AC3 unclosable by the existing instrument: the round-trip guard derives its denominator from node-level aef.* accesses, so document-level workflowMeta attributes are outside its scope by construction. Proved by mutation - deleting the writer line still passes. Needs a dedicated workflowMeta round-trip teeth with a mutation control.' That instrument now exists: checkWmDenominator() derives the denominator FROM THE EMITTER (10 attributes, 0 unclassified) and the WM self-test mutates each attribute in its own wire carrier across the corpus. Measured this session: kind is LIVE, so suppressing it in the writer now moves the projection - the mutation control the reason asked for. AC3's byte-identity pair also holds: t875-kind-marker.bpmn (WITH kind) and two-lane-joint.bpmn (without) both report byteIdempotent true over 21 fixtures. T-910 extended the same discipline to aef:laneMeta. AC5 (conformance case in the existing mapping-conformance suite) and AC6 (A5 recorded in Decisions) remain and are ordinary work, not blockers. THE PATTERN: a task parked on a missing instrument stays parked after the instrument ships, because the thing that shipped it was a different task and nothing joins the two. T-886 did not know T-875 was waiting on it.
- **Context:** Resolution logged for future reference

### 2026-09-28T08:44:10Z — status-update [task-update-agent]
- **Change:** status: issues → started-work
