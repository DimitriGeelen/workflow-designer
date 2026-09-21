---
id: T-769
name: "SQ-4 design: recorded check exemptions as SUBSTITUTED assertions, not suppressions"
description: >
  Design the exemption mechanism the operator ruled for: an exempted item is asserted
  against a different correct state rather than skipped, and every exemption must
  be able to go red.

status: captured
workflow_type: design
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T10:37:00Z
last_update: '2026-09-21T20:24:53Z'
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
bvp_scores_proposed:
  - ts: '2026-09-21T10:38:09Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/decisions.yaml,build/gallery/designer.html,src/aef-workflow-designer.html);
      tier=3 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-769: SQ-4 design: recorded check exemptions as SUBSTITUTED assertions, not suppressions

## Context

### The ruling

**SQ-4 — Can a check carry a recorded exemption? → YES.** Operator, 2026-09-21, with
the semantics supplied by their own example:

> *"Check if all doors are closed, unlocked with the exemption of the emergency exit
> door that needs always to be opened from the inside."*

That example decides the design, and decides it more sharply than the question was
filed. **An exemption is not permission to skip an item. It is a statement that the
item has a different correct state, which the check then asserts.** The emergency exit
is not unchecked — it is checked against an inverted predicate. Weld it shut and the
check fires.

### Three candidate semantics

| | Semantics | Verdict |
|---|---|---|
| Suppression | "skip this item" | **Rejected.** Exactly what `audit.sh:5228` already does to the deployment section: invisible rather than not-applicable. An invisible check can never report that its own exemption expired. |
| Acknowledgement | "check it, report it, classify as accepted" | Visible, and better than suppression — but still cannot detect that the *reason* stopped being true. |
| **Substitution** | "this item's correct state is different — assert that instead" | **Adopted.** Coverage is redirected, never reduced. |

### The acceptance test that keeps this honest

**An exemption must be able to go red.** An exemption that can never fail is
suppression wearing a costume. Every exemption is therefore an assertion with a
falsifiable negative, not an entry on a mute list.

### The three worked cases

- **RA-047 / T-756 — T-093 gallery mirror.** Expected state is not *"identical"*. It is
  ***"diverged, and T-102/T-105 still open"***. This is the case that proves the design:
  today's check goes **GREEN if someone rebuilds `build/gallery/`** — the one action
  this project forbids. The current check actively rewards the prohibited remedy. A
  substitution check goes red on the rebuild, which is the behaviour actually wanted.
- **RA-050 / T-759 — T-250.** Expected state: the exploration record lives in the task
  file with non-empty sections, which T-706 measured (Recommendation Evidence 1012
  characters, Problem Statement 738, Open Questions 1198). Assert that. T-706's
  existing red leg — which fires if the forbidden `docs/reports/` document appears —
  is already half of the substituted assertion.
- **RA-051 / T-760 — T-587.** **Not an exemption at all.** The check has a hardcoded
  `docs/reports/` path and cannot see a 19,876-byte artifact in `docs/research/`. A
  bug, and it must not be dressed as an exemption — doing so would hide a defect
  behind a mechanism built for legitimate cases.

Distinguishing case three from cases one and two is itself part of the design: a
mechanism that makes it easy to exempt a check is a mechanism that makes it easy to
stop fixing checks.

### Open design questions for this task

1. Where an exemption lives — beside the evidence in the task file, or in a central
   register that can be counted and expired.
2. What it must carry: the ruling task that authorised it, the substituted assertion,
   and the condition under which it stops applying.
3. How the audit reports exemptions so they stay countable rather than accumulating
   silently.

### Root-cause links

Cases: RA-047/T-756, RA-050/T-759, RA-051/T-760. Ruling: SQ-4, recorded by T-766. Related: RA-049/T-758, whose silent-skip guard is the anti-pattern this design exists to avoid.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The three semantics are recorded with the rationale for adopting substitution, so a later reader cannot quietly re-implement suppression under the same name.
- [ ] The mechanism specifies what an exemption must carry — authorising ruling, the substituted assertion, and its expiry or recheck condition — and where it lives, with the trade-off between task-local and central-register stated rather than assumed.
- [ ] The must-be-able-to-go-red test is expressed as something mechanically checkable, not as advice. An exemption whose assertion cannot fail is rejected by construction.
- [ ] The RA-047 case is carried through end to end as the worked example, including the fact that today's check goes green on the forbidden gallery rebuild — that inversion is the strongest argument for the design and must survive into the specification.
- [ ] RA-051 is explicitly classified as a bug and NOT as an exemption candidate, with the reason stated: a mechanism that makes exempting cheap makes fixing checks optional.
- [ ] This task produces the design only. No check is modified and no exemption is created under it — implementing an exemption mechanism changes what the audit asserts, which is a separate decision with its own review.

<!-- No Human ACs: the operator has already ruled on the question behind this
     task, and what remains is agent-verifiable. Adding an empty Human section
     would lengthen a review queue already 67 deep (SQ-3) with nothing to review.

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
         1. Run `bin/fw reviewer T-769`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-769 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

grep -q 'SQ-4' .context/project/decisions.yaml
! diff -q src/aef-workflow-designer.html build/gallery/designer.html >/dev/null 2>&1

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
     fw inception decide T-769 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T10:37:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-769-sq-4-design-recorded-check-exemptions-as.md
- **Context:** Initial task creation
