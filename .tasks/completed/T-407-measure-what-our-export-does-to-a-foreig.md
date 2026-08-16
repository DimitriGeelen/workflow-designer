---
id: T-407
name: "Measure what our export does to a foreign producer identity (AEF rail 491 seam
  question)"
description: >
  Measure what our export does to a foreign producer identity (AEF rail 491 seam question)

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T10:19:04Z
last_update: '2026-08-16T12:33:56Z'
date_finished: 2026-08-09T10:22:49Z
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
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-407: Measure what our export does to a foreign producer identity (AEF rail 491 seam question)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A probe drives the REAL editor (parse then build, real browser) on a REAL
      third-party document that carries a foreign `exporter` on `<definitions>`, and
      reports what the exported bytes carry. Source reading does not satisfy this: the
      whole of T-361 is that a constant and an emitter can agree with each other about
      something untrue of the produced artifact.
      — `tools/_t407-exporter-passthrough-cdp.mjs`, input `simple.bpmn` (real Camunda
      Modeler output per PROVENANCE.md). Measured:
      `exporter="camunda modeler" exporterVersion="2.6.0"` in →
      `exporter="aef-workflow-designer"` out.
- [x] The probe carries a CONTROL on its input — it refuses to report unless the input
      genuinely carries a foreign producer identity. Without it, an "we overwrite"
      verdict is equally consistent with an input that never had one, and the probe
      would prove nothing about overwriting.
      — control asserts a non-ours `exporter` on the input; exit 2 with the input's
      attributes printed if absent, so a fixture re-pin that dropped it cannot leave
      the probe silently measuring nothing.
- [x] All three outcomes are distinguished and named in the output (`ours-only`,
      `theirs-kept`, `absent`), not collapsed into pass/fail — the question AEF asked
      is which of them we do, so a boolean answer would discard the answer.
      — verdict `ours-only`.
- [x] The measured verdict is reported to AEF on the rail, stated as measured, with our
      recommendation on their two options and its reasoning. — rail 492.
- [x] Whether this should be codified into the frozen mapping standard is flagged for
      the operator, NOT decided here — `docs/standards/aef-bpmn-mapping-v1.md` is silent
      on `exporter` (verified: zero matches) and is not editable under agent control.
      — flagged in `## Operator decision needed` below and in rail 492 §4.

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

# --- T-407 commands ---
# The probe itself. Its own exit code is the verdict (0 = ours-only), so no chaining
# and the errexit note below cannot apply. Exit 2 if the input control fails.
node tools/_t407-exporter-passthrough-cdp.mjs
# The control's precondition, asserted independently of the probe: if a fixture re-pin
# ever drops the foreign exporter, the probe would be measuring an overwrite of nothing.
grep -q 'exporter="camunda modeler"' tests/fixtures/third-party/simple.bpmn
# The frozen standard is still silent on exporter. If this line ever fails, the operator
# has ruled and this task's "not decided here" framing is out of date.
! grep -q "exporter" docs/standards/aef-bpmn-mapping-v1.md

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
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

## Operator decision needed — NOT taken here

`docs/standards/aef-bpmn-mapping-v1.md` (Part I, frozen) is **silent on `exporter`** —
zero matches. Both projects now have a measured position on it and they agree, which is
exactly when a convention is cheap to write down and expensive to leave implicit.

**What is settled by measurement, and needs no ruling:** `exporter` means *who wrote
these bytes*. Ours overwrites a foreign one (this task); AEF's round-trip reconstructs
`<definitions>` and carries nothing across (their T-2884); every third-party emitter in
our corpus uses it that way (PROVENANCE.md).

**What needs the operator:** whether that goes into a v1.1 delta, and in what words. The
standard is not editable under agent control, and a mapping-standard change is a seam
commitment rather than a code change. Related open item: AEF asked whether they should
begin stamping their own — my recommendation is yes (rail 492), but if it lands in the
standard it stops being a recommendation and becomes a requirement on them.

## Decisions

### 2026-08-09 — measure our own behaviour before recommending theirs

- **Chose:** answer AEF's rail-491 question with a probe through the real editor rather
  than by reading `buildBpmnXml`.
- **Why:** the emitter writes `exporter` unconditionally and a code read would have given
  the same answer in a minute. But T-361 is the incident where a constant and an emitter
  agreed with each other about a sentence false outside the process, and AEF have twice
  now declined to hand me an inferred answer (their 485, their 487). Sending them a
  reasoned-from-source answer to a question they answered with a probe would be trading
  down on the standard of evidence they set.
- **Rejected — reason from the source.** Cheaper, and would have been correct this time,
  which is precisely what makes it a bad habit to form.
- **Bonus the probe caught that a code read would have skipped:** their
  `exporterVersion="2.6.0"` is dropped, not replaced. So we do not merely overwrite the
  producer field, we reconstruct the whole `<definitions>` attribute set — the same
  mechanism AEF measured on their side (`parse_map` records two fields, `emit_map`
  writes a fresh element). Neither of us designed that jointly.

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

### 2026-08-09T10:19:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-407-measure-what-our-export-does-to-a-foreig.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-10d965da
- **Timestamp:** 2026-08-09T10:22:50Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T10:22:49Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
