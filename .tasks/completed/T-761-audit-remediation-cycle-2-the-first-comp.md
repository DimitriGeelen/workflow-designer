---
id: T-761
name: "Audit remediation cycle 2: the first complete 19-section baseline and what
  it says about the checks"
description: >
  Audit remediation cycle 2: the first complete 19-section baseline and what it says
  about the checks

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T09:29:27Z
last_update: 2026-09-21T09:35:28Z
date_finished: 2026-09-21T09:35:28Z
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
  - ts: '2026-09-21T09:31:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=1 
      (prose:AEF seam-incidental); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
---

# T-761: Audit remediation cycle 2: the first complete 19-section baseline and what it says about the checks

## Context

Container for cycle 2 of the audit-remediation mandate, under arc-003. Cycle 1
(T-744) reconciled 32 findings into 32 task records against a baseline that was
section-scoped — that is, against a baseline nobody had ever measured the coverage
of.

Cycle 2's substance is that the baseline itself was wrong.

### What cycle 2 actually did

It ran the audit to completion for the first time in this project's records:

```
FW_AUDIT_TIMEOUT=3000 .agentic-framework/bin/fw audit
  exit=2   elapsed=687s   Pass 175 / Warn 31 / Fail 1
```

Every prior record in `.context/audits/` is either section-scoped or a truncated
full run. The reason is T-755/RA-046: the audit SIGTERMs its own PID after 600s
(`audit.sh:312`, `audit.sh:346`), and the complete run needs 687. It was failing
by 87 seconds against a limit it imposes on itself, emitting no summary and no
interpretable exit code — which is why OBS-358 recorded it as a hang.

### What the complete baseline says

Three findings that no section-scoped run, no cron run and no pre-push check had
ever surfaced. All three are defects **of the checks**, not of the project:

- **RA-049 (T-758)** — `audit.sh:5228` guards the deployment section with
  `[ -n "$SECTIONS" ] &&`. It is the only one of nineteen sections that does. A
  bare `fw audit` therefore runs 18 of the 19 sections it advertises, and
  RA-042…RA-045 are four FAILs that can never appear in an unqualified run.
- **RA-050 (T-759)** — the inception-artifact check warns on T-250. T-706 already
  ruled that the document must NOT be written and wrote a red verification leg to
  prevent it.
- **RA-051 (T-760)** — the same check warns on T-587, whose research artifact
  exists: `docs/research/executable-workflow/reflection-designer.md`, 19,876 bytes.
  The check looks only in `docs/reports/`.

### The class

RA-047, RA-050 and RA-051 are three instances of one shape: **a warning that a
recorded decision has made permanently unclearable.** Three is a class, not a
coincidence. Stated as a Sovereign question (SQ-4), not decided here.

## Acceptance Criteria

### Agent
- [x] The complete 19-section baseline is recorded with its counts, its elapsed
      time and the exact command that produced it — and the record states its own
      coverage, so no later cycle mistakes a partial baseline for a full one again.
- [x] Findings in = tasks out. Every finding the complete run produced that was not
      already owned by an existing task is reconciled to a task record, and the
      count of unreconciled findings is zero and is stated as such.
- [x] Each cycle-2 task (T-758, T-759, T-760) carries the verbatim tool output that
      produced its finding, a structural statement of the invariant that is not
      held, its root-cause links, real acceptance criteria, and verification legs
      that have been run.
- [x] Every open cycle-1 and cycle-2 remediation task is scored by
      `fw bvp estimate` and its quadrant recorded. No score is adjusted upward by
      the producer and no BVP calibration parameter is touched.
- [x] The delta against cycle 1 is stated: what closed, what is new, and what
      remains — with the reason each remaining item was not picked up.
- [x] Sovereign questions surfaced by cycle 2 are recorded in priority order and
      left undecided. Where a fix requires an architectural ruling, the task is
      parked and the question filed, not resolved under agent initiative.

<!-- No Human ACs: this container produces a reconciliation record, and every
     judgement it surfaces is filed as a Sovereign question rather than as a
     verification step. Adding an empty Human section would lengthen a review
     queue that is already 67 deep (SQ-3) with an item carrying nothing to review.

     Original template guidance retained below for the next editor.

     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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
         1. Run `bin/fw reviewer T-761`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-761 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#
# Legs below are location-independent on purpose (T-744's went red the moment a
# task moved from active/ to completed/, while its AC was still true — a leg that
# encodes a transient file location asserts the wrong thing).

test -f docs/reports/T-761-cycle2-findings.md
grep -qE 'unreconciled \.+ 0' docs/reports/T-761-cycle2-findings.md
grep -q 'Pass 175 / Warn 31 / Fail 1' docs/reports/T-761-cycle2-findings.md
grep -q 'Coverage is 19 of 19 sections' docs/reports/T-761-cycle2-findings.md
grep -q 'audit.sh:5228' docs/reports/T-761-cycle2-findings.md
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-75[89]-*.md' -o -maxdepth 1 -name 'T-760-*.md' | xargs grep -l '^arc_id: arc-003' | wc -l)" -eq 3
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-75[89]-*.md' -o -maxdepth 1 -name 'T-760-*.md' | xargs grep -l 'Verbatim tool output' | wc -l)" -eq 3
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-75[89]-*.md' -o -maxdepth 1 -name 'T-760-*.md' | xargs grep -l '^bvp_scores_proposed:' | wc -l)" -eq 3

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
     fw inception decide T-761 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T09:29:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-761-audit-remediation-cycle-2-the-first-comp.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2c424ba9
- **Timestamp:** 2026-09-21T09:35:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T09:35:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
