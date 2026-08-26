---
id: T-605
name: "Input-fidelity census still expects documentation to be dropped, so T-602's fix leaves a red driver"
description: >
  Input-fidelity census still expects documentation to be dropped, so T-602's fix leaves a red driver

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T20:28:14Z
last_update: 2026-08-26T20:31:42Z
date_finished: 2026-08-26T20:31:42Z
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

# T-605: Input-fidelity census still expects documentation to be dropped, so T-602's fix leaves a red driver

## Context

`tools/_t338-input-fidelity-cdp.mjs` is RED on master. Its `EXPECTED_CONTENT` baseline still
says `'documentation': 'CONTENT-DROPPED'`, but T-602 (a6eb86ce) fixed documentation
round-trip, so it now measures `CONTENT-PRESERVED`.

The census is behaving exactly as designed. Its own failure text says so:

    CONTENT-PRESERVED where DROPPED was expected is good news the guard must not
    absorb — update EXPECTED_CONTENT deliberately.

That refusal is the point: a census that silently absorbed an improvement would also silently
absorb a regression the day the value moved back. But it means a landed fix left a red driver
in the tree and nobody reconciled the baseline — the improvement was made and not finished.

"Deliberately" is the whole job here. Flipping the constant to make the red go away is
precisely the failure mode the message is written to prevent. The flip is only legitimate if
the preservation is verified to be real and the baseline records WHY it moved, so the next
reader can tell a ratified improvement from a rubber-stamped one.

Found while sweeping driver health under T-604; kept out of that task because folding a
baseline change into an attach-race sweep would have hidden both.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The preservation is INDEPENDENTLY confirmed before the baseline moves — documentation
      content measured surviving import→export by a check that is not the census itself, so
      the flip rests on evidence rather than on the census agreeing with itself
- [x] `EXPECTED_CONTENT['documentation']` is `CONTENT-PRESERVED`, and carries an inline
      rationale naming T-602 and its commit, so the baseline change is traceable and cannot
      read as a silent absorb
- [x] `node tools/_t338-input-fidelity-cdp.mjs` exits 0 — the driver is green on master again
- [x] The ratchet is proven to still bite: a poison arm that reverts T-602's emit turns the
      census RED on `documentation`, confirming the new expectation constrains behaviour
      rather than merely describing it
- [x] No other row in `EXPECTED_CONTENT` or `EXPECTED_ROOT` was touched — the change is
      scoped to the one carrier T-602 actually fixed, verified by diff
- [x] The census has no self-test to lean on — checked, not assumed — so independence is
      shown instead by diffing the FULL verdict row set before and after the flip and
      confirming `documentation` is the only row that moves

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


node tools/_t338-input-fidelity-cdp.mjs

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


**Symptom:** `tools/_t338-input-fidelity-cdp.mjs` exited 1 on master, reporting
"accepted-element content behaviour changed for 'documentation' — expected CONTENT-DROPPED,
measured CONTENT-PRESERVED".

**Root cause:** not a defect in the census or the designer. T-602 (a6eb86ce) fixed
bpmn:documentation round-trip, and the census's `EXPECTED_CONTENT` baseline still encoded the
old broken behaviour as the expectation. The improvement landed; the baseline that described
the pre-improvement world did not move with it.

**Why structurally allowed:** the census deliberately refuses to auto-absorb a verdict change
in the good direction, printing "good news the guard must not absorb — update EXPECTED_CONTENT
deliberately". That refusal is correct and must stay: a census that silently accepted an
improvement would also silently accept the regression that moved the value back. But nothing
routed that instruction to anyone. T-602 completed, its own verifier was green, and the
tripwire it tripped in a NEIGHBOURING driver was invisible from inside T-602 — the driver is
not in T-602's `## Verification` block, so no gate ran it and no handover mentioned it. The
gap is that a fix which improves fidelity has no mechanism telling it which baselines it just
invalidated.

**Prevention:**
- Baseline reconciled with an inline rationale naming T-602 and its commit, so a future reader
  can distinguish a ratified improvement from a rubber-stamped one.
- Ratchet proven to still bite: with `T338_DESIGNER_SRC` pointed at an editor with T-602's
  emit reverted, the row goes red against the NEW expectation. The flip constrains behaviour
  rather than merely describing it — which is the only thing that makes flipping it safe.
- Residual, registered not fixed: there is still no mechanism that tells a landing fix which
  neighbouring baselines it invalidates. The next fidelity improvement will redden a driver
  the same way. Filed as OBS-317 rather than hidden behind this reconciliation.

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


- **Reconcile the baseline, do not weaken the census.** The alternative — dropping
  `documentation` from `EXPECTED_CONTENT` so it can never drift again — would have made the
  red go away permanently and cost the ratchet. The row is the thing that will catch the
  regression; removing it to silence a stale expectation trades a one-line edit for a
  permanent blind spot.
- **The flip rests on an INDEPENDENT measurement, not on the census.**
  `tools/_t602-documentation-roundtrip.mjs` measures round-tripped text, id, textFormat,
  element count and child ORDER. The census agreeing with itself would have proven nothing;
  this is the same "the test and its subject must be the same object" rule applied to a
  baseline change.
- **Verified the poison arm on the OLD code, not just the new expectation.** Reverting T-602's
  emit turns the row red. Without that step the flip would have been indistinguishable from
  rubber-stamping whatever the tree currently does — the exact failure the census's own error
  message warns against.
- **Zero of 30 verdict rows moved.** That is the expected result and worth stating plainly:
  the editor did not change, so no MEASUREMENT changed; only the EXPECTATION did. A row moving
  here would have meant the flip had side effects.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-26T20:28:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-605-input-fidelity-census-still-expects-docu.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3710b631
- **Timestamp:** 2026-08-26T20:31:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T20:31:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
