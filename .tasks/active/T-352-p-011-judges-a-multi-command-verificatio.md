---
id: T-352
name: "P-011 judges a multi-command verification line on its last command alone (set -e suppressed in the gate's if-condition)"
description: >
  update-task.sh:1018 runs each verification command as 'if ( ...; eval "$cmd" ); then' — the subshell is the CONDITION of an if, so set -e (set at line 14) is suppressed inside it. A line of the form 'a; b' is therefore judged on b alone: a's failure is swallowed. The capture-then-grep shape the task template PRESCRIBES as the L-387 SIGPIPE remedy ('out=$(cmd 2>&1); echo "$out" | grep -q PAT') is exactly this shape, so the framework teaches it. PROVEN live: 'out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"' returns PASS under the gate's own construct on a document the validator exits 2 on and labels INVALID — grep -q VALID matches INVALID as a substring. Structural population: 332 of 1318 verification lines contain a top-level ';'. That is an upper bound, NOT a finding — most greps pin a zero-failure token and are safe. Members must be measured individually, not counted. Reported to AEF as their own finding reproducing here (their RAIL-403).

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:designer-authoring-surface, tooling, verification-gate]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T23:59:29Z
last_update: 2026-08-03T00:19:07Z
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

# T-352: P-011 judges a multi-command verification line on its last command alone (set -e suppressed in the gate's if-condition)

## Context

Found while writing T-351's verification block, and confirmed against AEF's RAIL-403 which
reported the same mechanism in their tree independently.

`update-task.sh:1018` runs each verification command as
`if ( unset …; cd "$PROJECT_ROOT" && eval "$cmd" ); then`. The subshell is the **condition of
an `if`**, so the `set -euo pipefail` at line 14 is suppressed inside it. A line of the form
`a; b` is therefore judged on `b` alone — `a`'s exit code is discarded.

This is not an exotic shape. The task template's own L-387 SIGPIPE hint **prescribes it**,
listed first and labelled "Safe pattern":
`out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"`. The framework teaches the defect.

**Proven live, through the gate's own construct** — not reasoned, and not by hand:
`out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"`
returns **PASS** on a document `validate-workflow.py` exits 2 on and labels `INVALID`, because
`grep -q "VALID"` matches `INVALID` as a substring. Two independent defects stacked; either
alone would have been survivable.

**The intuitive fix is a non-fix** (measured, with a positive control alongside):

| form | verdict on `a` fails / `b` succeeds | |
|---|---|---|
| `if ( eval "$cmd" )` | PASS | today's behaviour, wrong |
| `if ( set -e; eval "$cmd" )` | PASS | **still wrong** — the suppressed context is inherited |
| `if bash -c "set -eo pipefail; $cmd"` | FAIL | correct |

A line that *should* pass still passes under all three, so the third discriminates rather
than merely being stricter.

**Population sizing, deliberately not inflated:** 332 of 1318 verification lines carry a
top-level `;` and are structurally judged on their last command alone. **That is an upper
bound, not a finding.** Most pin a zero-failure token (`passed, 0 failed`) and are safe.
4 lines are proven false-green by execution so far. Counting the 332 as findings would be
an 80× overclaim.

**Why this is not fixed here:** the gate lives in `.agentic-framework/` (vendored). Changing
how every verification line in the project is evaluated is a framework-wide behaviour change
— G-008 upstream territory and the operator's ruling, not an agent's.

## Acceptance Criteria

### Agent
- [ ] **AC1 — the false green is reproduced by a committed harness, not by a paragraph.**
      A script constructs a document the validator rejects, runs the offending verification
      line through the gate's *own* construct (copied from `update-task.sh`, not
      approximated), and asserts the verdict is PASS. If the gate is later fixed, this
      harness must go red — it is the regression witness, so it must fail on the fix.
- [ ] **AC2 — the members are enumerated, not the count.** Every verification line whose
      grep clause can match its own command's failure output is listed by task id and line,
      with the failing output that satisfies it. Lines that merely *have* the `a; b` shape
      but pin a zero-failure token are reported separately and explicitly as NOT findings.
      The report states both numbers and says which is the finding.
- [ ] **AC3 — the non-fix is recorded with its control.** The `set -e`-in-subshell form is
      shown to still pass, beside a positive control proving the accepted form is not merely
      stricter. Without the control, "form C fails more" is not evidence that it is right.
- [ ] **AC4 — the point of teaching is fixed, or the reason it was not is written down.**
      The template hint that prescribes the capture-then-grep shape either gains a warning
      naming this behaviour, or the task records that the template is vendored and the
      change is the operator's. A defect the documentation teaches regenerates faster than
      it can be remediated.
- [ ] **AC5 — remedy proposed, not applied.** The `bash -c` wrapper is written up with its
      blast radius (every verification line in every task re-evaluated under real errexit;
      expect currently-green lines to go red, and that is the point). No edit to
      `.agentic-framework/` under agent authority — G-008 upstream, operator's call.

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-08-02T23:59:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-352-p-011-judges-a-multi-command-verificatio.md
- **Context:** Initial task creation

### 2026-08-03T00:17:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
