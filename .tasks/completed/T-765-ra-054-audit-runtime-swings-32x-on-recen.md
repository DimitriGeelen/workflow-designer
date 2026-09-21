---
id: T-765
name: "RA-054: audit runtime swings 32x on recency-window membership, with a 600s
  self-kill downstream"
description: >
  The audit's runtime is set by which tasks sit in CTL-013's recency window, not by
  the project, and a self-kill waits at 600s.

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
created: 2026-09-21T09:38:08Z
last_update: 2026-09-21T09:42:14Z
date_finished: 2026-09-21T09:42:14Z
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
  - ts: '2026-09-21T09:39:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 3
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=3 (prose:routing-defect-class); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T09:40:16Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:.agentic-framework/agents/audit/audit.sh); 
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-765: RA-054: audit runtime swings 32x on recency-window membership, with a 600s self-kill downstream

## Context

### Verbatim tool output

```
# same section, same day, no code change
cycle 2:  fw audit --section oe-daily            578s
cycle 3:  fw audit --section oe-daily             18s   (exit 1)

# same audit, full scope
cycle 2:  FW_AUDIT_TIMEOUT=3000 fw audit         687s   Pass 175 / Warn 31 / Fail 1
cycle 3:  fw audit                               121s   Pass 176 / Warn 29 / Fail 1

# audit.sh:306, 346 — the self-kill that 687s ran into
AUDIT_TIMEOUT="${FW_AUDIT_TIMEOUT:-600}"
( ... sleep "$AUDIT_TIMEOUT" && kill -TERM $ ... ) &
```

### The invariant that is not held

The audit's runtime is not a property of the project, its size, or how much work
is outstanding. It is set by which three tasks happen to sit at the head of
`completed/` by mtime, because CTL-013 `eval`s their `## Verification` blocks —
and a verification block may contain anything, including four full test suites.

Measured across two cycles on the same day with no code change: **18s versus
578s** for the same section, a factor of 32.

Variance alone would be a performance nuisance. What makes it a defect is what
sits downstream: a 600s watchdog that SIGTERMs the audit's own process group and
emits no summary and no interpretable exit code when it fires (RA-046/T-755).
So completing one ordinary task — whose verification block happens to run test
suites — can push the whole audit past its own kill threshold, silently, with no
relationship to the change that did it. That failure mode is not hypothetical:
it is OBS-358, which stood unexplained from 2026-09-20 until cycle 2.

Cycle 2 framed this as 'oe-daily clears the self-kill by 22 seconds'. **That was
wrong and is corrected here:** there is no stable margin to clear. The number
moves by an order of magnitude on task-completion order, and the margin is not a
property of the audit at all.

### Root-cause links

Same root cause as RA-053/T-764; kept separate per the one-finding-one-task rule. Parent: RA-046/T-755, which localised the 687s-vs-600s collision. Corrects a claim made in cycle 2's record.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The variance is quantified from measurements recorded in this arc, not estimated: the same section at 578s and at 18s, same day, no code change, with the commands that produced each.
- [x] The mechanism is stated: CTL-013 evals arbitrary shell drawn from the verification blocks of whichever three tasks are most recent, so the audit's cost is unbounded by anything the audit itself controls.
- [x] The interaction with the 600s self-kill is stated as the actual hazard, and cycle 2's 'clears by 22 seconds' framing is explicitly corrected rather than quietly dropped.
- [x] Whether CTL-013 should time-box or sandbox what it evals, and whether the watchdog should report rather than kill silently, are filed as Sovereign questions. Neither is decided here and NO timeout value is changed under agent initiative — raising FW_AUDIT_TIMEOUT would hide the variance rather than measure it.

<!-- No Human ACs: this finding record carries no step a human can execute until
     the Sovereign question it raises is answered. An empty Human section would
     lengthen a review queue already 67 deep (SQ-3) with nothing to review.

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
         1. Run `bin/fw reviewer T-765`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-765 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

grep -q 'FW_AUDIT_TIMEOUT:-600' .agentic-framework/agents/audit/audit.sh
grep -qE 'sleep "\$AUDIT_TIMEOUT" && kill -TERM' .agentic-framework/agents/audit/audit.sh
grep -q 'CTL-013 OE: Verification Gate' .agentic-framework/agents/audit/audit.sh

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
     fw inception decide T-765 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T09:38:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-765-ra-054-audit-runtime-swings-32x-on-recen.md
- **Context:** Initial task creation

### 2026-09-21T09:41:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-dec3c653
- **Timestamp:** 2026-09-21T09:42:14Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T09:42:14Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
