---
id: T-697
name: "RA-001: one watched source file has no fabric component card"
description: >
  Audit WARN (cycle 1, 2026-09-16): Fabric registration invariant not held — 1 of
  371 files matching watch-patterns.yaml has no component card.

status: work-completed
workflow_type: build
owner: claude
horizon: null
tags: [arc-003, audit-remediation, RA-001]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:24:00Z
last_update: 2026-09-16T13:35:17Z
date_finished: 2026-09-16T13:35:17Z
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
  - ts: '2026-09-16T13:30:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:48Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:tools/_t423-di-schema-validate.py); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-697: RA-001: one watched source file has no fabric component card

## Context

**Finding RA-001** - cycle 1, 2026-09-16. Source: fw audit. Severity: WARN.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[WARN] Fabric: 373 registered, 1 unregistered (of 371 watched - 100% covered, cards flat since earlier today (373))
       Evidence: 1 file(s) matching watch-patterns.yaml have no component card; registered is unchanged while the watch set moves, so any change in the unregistered count is tree growth, not carding activity
       Mitigation: Run: fw fabric scan
```

**The invariant that is not held:**

The fabric is meant to be a complete structural map of every significant file. The invariant is: every file matching watch-patterns.yaml has a component card. It does not hold. `fw fabric drift` names the file: tools/_t423-di-schema-validate.py - a tool a previous session created and never registered. Because blast-radius is computed from cards, an unregistered file is invisible to impact analysis: changing it reports no downstream consumers, which is indistinguishable from having none.

**Root-cause siblings:** T-699 (RA-003)

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `fw fabric drift` reports `unregistered: 0`
- [x] tools/_t423-di-schema-validate.py has a component card under .fabric/components/
- [x] The card states at least one depends_on or depended_by edge, so registration does not merely satisfy the count while leaving the file invisible to impact analysis

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
         1. Run `bin/fw reviewer T-697`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-697 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

out=$(.agentic-framework/bin/fw fabric drift 2>&1); echo "$out" | grep -q "unregistered: 0"

## RCA

**Root cause of RA-001:** `tools/_t423-di-schema-validate.py` was created by an earlier
session for T-423 and never registered. Nothing in the create-a-tool path calls
`fw fabric register`, so registration depends on the author remembering — which is the
same capture-without-application shape as FP-011.

**What the fix exposed — two sub-findings, recorded because they are not RA-001:**

1. **`fw fabric register` mints a card that passes the registration check while staying
   invisible to impact analysis.** The card it created had `purpose: "TODO: describe what
   this component does"` and `depends_on: []` / `depended_by: []`. `fw fabric drift`
   immediately reported `unregistered: 0` — the count was satisfied by a card that says
   nothing. This is RA-002's defect (78 edgeless cards) reproducing at the moment of
   creation, which explains why the edgeless count is flat across audits: the registration
   verb is a source of edgeless cards, not only a cure for unregistered ones.

2. **Writing `depended_by:` on a card is inert.** After filling both edge lists by hand,
   `fw fabric deps` reported `Depended by: (none found — may need card enrichment)`. The
   reverse index is built from *other* cards' `depends_on:`, so a `depended_by:` entry on
   the card itself is read by nobody. The real edge had to be declared from the caller's
   side — `tests/run-bridge-tests.sh`'s card. A field that is written, saved, and never
   read is worse than an absent one: it reads as a declared edge to every human who opens
   the file.

Neither sub-finding is fixed here. Both are structural and belong to whoever rules on
RA-002 (T-698).

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

### 2026-09-16 — the registration verb is itself a source of the defect RA-002 reports
- **What changed:** At filing this looked like one forgotten file. Running the fix showed
  that `fw fabric register` produces a card with a TODO purpose and zero edges, and that
  `fw fabric drift` reports `unregistered: 0` the moment that card exists. Registration and
  usefulness are separate properties and only the first is checked. Separately, the
  `depended_by:` field on a card turned out to be inert — `fw fabric deps` builds the
  reverse index from other cards' `depends_on:`, so the edge had to be added to
  `tests/run-bridge-tests.sh`'s card before it resolved.
- **Plan impact:** AC3 ("states at least one edge") was written expecting it to follow
  automatically from registering. It did not, and satisfying it honestly required editing a
  second card. The AC was the right one to have written — the two-AC version of this task
  would have closed green with an empty card.
- **Triggered:** Two sub-findings recorded in this task's RCA and routed to T-698 (RA-002),
  which is the task that owns the edgeless-card population. Not fixed here — the repair is
  a change to a framework verb's behaviour and is a scope question, not a remediation step.

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
     fw inception decide T-697 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:24:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-697-ra-001-one-watched-source-file-has-no-fa.md
- **Context:** Initial task creation

### 2026-09-16T13:32:34Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5d1f35a6
- **Timestamp:** 2026-09-16T13:35:21Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — tools/_t423-di-schema-validate.py has a component card under .fabric/components/
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t423-di-schema-validate.py in: tools/_t423-di-schema-validate.py has a component card under .fabric/components/`

### 2026-09-16T13:35:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
