---
id: T-762
name: "Audit remediation cycle 3: re-run verifies cycle 2, and finds the audit lost
  its own baseline"
description: >
  Audit remediation cycle 3: re-run verifies cycle 2, and finds the audit lost its
  own baseline

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T09:36:29Z
last_update: '2026-09-21T20:25:09Z'
date_finished: 2026-09-21T09:43:40Z
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
cost_estimate_proposed:
  - ts: '2026-09-21T20:25:09Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/audits/2026-09-21.yaml,build/gallery/designer.html,docs/reports/T-762-cycle3-findings.md,src/aef-workflow-designer.html);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-762: Audit remediation cycle 3: re-run verifies cycle 2, and finds the audit lost its own baseline

## Context

Container for cycle 3 of the audit-remediation mandate, under arc-003. Cycle 3 is
the mandate's verification step: *"Verification of a task is the re-run of the audit
in the next cycle, not your own assertion that it is fixed."*

The re-run verified cycle 2's diagnosis. It also produced three findings that only a
comparison between cycles could produce — and one of them is that the comparison
itself was nearly impossible, because the cycle-2 record no longer exists.

### The re-run

```
.agentic-framework/bin/fw audit          # full, 19 sections, default 600s timeout
  Pass 176 / Warn 29 / Fail 1
  elapsed 121s   (cycle 2: 687s)

.agentic-framework/bin/fw audit --section oe-daily
  exit 1, elapsed 18s                    (cycle 2: 578s)
```

**Nothing was fixed to achieve this.** No code changed. The same section, on the same
day, ran 32× faster because T-744 and T-755 completed and pushed T-093 out of
CTL-013's three-task recency window. The four test suites in T-093's `## Verification`
block simply stopped being run.

That is a clean mechanical confirmation of T-755's causal chain — the chain predicted
exactly this — and it is simultaneously three new findings.

### Findings

- **RA-052 (T-763)** — `.context/audits/2026-09-21.yaml` was overwritten by this
  cycle's same-scope run before it had ever been committed. T-677 states that earlier
  runs live in git history; nothing enforces commit-before-next-run, so the only
  full-coverage baseline this project ever produced is gone. `git log` on that path
  is empty.
- **RA-053 (T-764)** — CTL-013's three-task window silently retired RA-047. The audit
  no longer mentions T-093 at all, while the condition RA-047 reported —
  `diff src/aef-workflow-designer.html build/gallery/designer.html` — is unchanged
  and still fails. A warning that disappears because its subject aged out of a window
  is not evidence that anything was repaired.
- **RA-054 (T-765)** — the audit's runtime is a function of which three tasks happen
  to have completed most recently, not of the project. 18s versus 578s for the same
  section, same day. With a 600s self-kill downstream (RA-046), completing one task
  whose verification block runs test suites can push the whole audit past its own
  kill threshold with no warning.

RA-053 and RA-054 share a root cause — CTL-013 evaluating completed tasks'
verification blocks over a three-item recency window — and are kept as separate
records per the one-finding-one-task rule.

### Correction to cycle 2's margin claim

Cycle 2 recorded that oe-daily "clears the 600s self-kill by 22 seconds". That framing
was wrong, and this cycle shows why: the margin is not a property of the audit. It is
a property of the recency window's contents, and it moves by an order of magnitude
without anyone touching the audit.

## Acceptance Criteria

### Agent
- [x] The re-run's counts, elapsed time and exact command are recorded, and its
      coverage is stated — the same self-description cycle 2 established.
- [x] Cycle 2's diagnosis is verified by the re-run rather than by assertion: the
      predicted cause of the 687s runtime is confirmed or refuted with measurements.
- [x] Findings in = tasks out. Every finding in the re-run is reconciled to a task
      record, the count of unreconciled findings is zero, and the three findings the
      cross-cycle comparison produced each get their own task.
- [x] The disappearance of RA-047 from the audit is shown to be a windowing artifact
      and not a repair: the underlying condition is measured and reported unchanged.
- [x] This cycle's audit record is committed, so the baseline survives the next
      same-scope run. This preserves the instance; the general defect stays open as
      RA-052 because preventing recurrence requires a ruling, not a commit.
- [x] New tasks are scored with `fw bvp estimate` and parked or worked strictly by
      the value boundary. No score is adjusted upward by the producer and no BVP
      calibration parameter is touched.

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
         1. Run `bin/fw reviewer T-762`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-762 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
# Legs are location-independent (T-744's encoded a transient path and went red when
# a task moved from active/ to completed/ while its AC was still true).
# OBS-332: never call `fw audit` from here. Reading a saved record is permitted.

test -f docs/reports/T-762-cycle3-findings.md
grep -qE 'unreconciled \.+ 0' docs/reports/T-762-cycle3-findings.md
grep -q 'Coverage is 19 of 19 sections' docs/reports/T-762-cycle3-findings.md
grep -q 'Pass 176 / Warn 29 / Fail 1' docs/reports/T-762-cycle3-findings.md
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-76[345]-*.md' | xargs grep -l '^arc_id: arc-003' | wc -l)" -eq 3
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-76[345]-*.md' | xargs grep -l 'Verbatim tool output' | wc -l)" -eq 3
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-76[345]-*.md' | xargs grep -l '^bvp_scores_proposed:' | wc -l)" -eq 3
grep -q 'sections: "all"' .context/audits/2026-09-21.yaml
! diff -q src/aef-workflow-designer.html build/gallery/designer.html >/dev/null 2>&1
! grep -q 'T-093' .context/audits/2026-09-21.yaml

# T-669 drain (PD-308: appended, nothing above altered). Companion leg(s) proving the absence
# assertion(s) above could have found something: each greps THE SAME STRING where it IS
# present, so a mis-spelled pattern goes red instead of passing vacuously.
grep -q 'T-093' .agentic-framework/.vendor-divergence.yaml

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
     fw inception decide T-762 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T09:36:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-762-audit-remediation-cycle-3-re-run-verifie.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cbc8403c
- **Timestamp:** 2026-09-21T09:43:41Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 60
     - evidence: `! diff -q src/aef-workflow-designer.html build/gallery/designer.html >/dev/null 2>&1`

### 2026-09-21T09:43:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
