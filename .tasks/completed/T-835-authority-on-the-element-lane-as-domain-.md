---
id: T-835
name: "Authority on the element, lane as domain: the mechanism T-685 GO'd and nobody
  filed"
description: >
  Authority on the element, lane as domain: the mechanism T-685 GO'd and nobody filed

status: work-completed
workflow_type: design
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-23T11:53:35Z
last_update: 2026-09-26T22:17:09Z
date_finished: 2026-09-26T22:17:09Z
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
  - ts: '2026-09-23T11:54:15Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 2
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=2 (prose:seam-namespace); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-26T09:06:31Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 2
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 
      (L1:keyword=lane,L1:keyword=flownoderef); F3=2 
      (L2:keyword=aef-bpmn,L2:path=docs/standards/aef-*.md~docs/standards/aef-bpmn-mapping-v1.md);
      F1=3 (L1:keyword=designer,L1:keyword=bpmn)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-23T11:54:16Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:docs/standards/aef-bpmn-mapping-v1.md); 
      tier=3 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-835: Authority on the element, lane as domain: the mechanism T-685 GO'd and nobody filed

## Context

T-685 ("Should authority live in the box (tier + owner) with the lane meaning domain")
was decided **GO on 2026-09-08**, naming the mechanism "the operator variable". No
successor task was filed for fifteen days. This is that successor.

Deliverable: `docs/reports/T-835-authority-on-the-element.md` — a mechanism, its costs,
and the downstream effects, with T-685's three measurements RE-DERIVED rather than
inherited. No ruling is taken, the frozen standard is not edited, and no production code
changes under this id.

**Two of T-685's four sub-claims did not survive re-derivation** (§2 of the report):
"nothing detects it" was false when written — `W-LANE-NO-OWNER` fires 7 warnings and
existed at the commit before the GO — and "27 tier-1" is an undercount of 53 against a
corpus that is byte-identical to its state at the GO. Neither reverses the direction; the
argument that survives is stronger than the one that was made, and it is in §3.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] T-685's GO is quoted and its three measurements RE-DERIVED rather than inherited — the ruling is 15 days old and this task's own standard is that a design must not rest on stale measurement: (a) `context-memory.bpmn`'s domain lanes at `authority="none"`, a value absent from the standard's collapse map, (b) the count of flowNodeRefs with no derivable owner that nothing currently detects, (c) how many corpus maps already carry `aef:meta tier` on elements
- [x] The proposed mechanism is stated concretely: WHAT carries authority on the element, what `tier` means if it is that carrier, and what a lane means once it is a domain. A design that says "move it to the element" without naming the carrier is a direction, not a mechanism
- [x] The frozen-standard impact is stated precisely and NOT acted on: v1.1 **deliberately removed** the node-level `owner` override to make the lane the sole authority-of-record, and O-3's compile-time sovereignty-lane enforcement is written against the lane. `docs/standards/aef-bpmn-mapping-v1.md` Part I is NOT edited by the agent under any circumstance
- [x] The downstream unblocks are NAMED AND CHECKED, not asserted: for T-358 and T-341, state exactly which blocking criterion dissolves under the new model and which survives. T-341's `lanes[0]`-is-positional defect and T-358's `E-XML-LANES-EMPTY` both appear to be consequences of lane-as-authority; "appear to be" is not good enough for a task that exists to unblock them
- [x] `E-XML-LANES-EMPTY` is re-examined against the new model. Today it fires because §3 needs a lane to carry authority; if authority moves, the rule's rationale moves with it and the rule must be re-justified or retired — not left firing on a premise that no longer holds
- [x] Put to AEF on the rail. The standard is frozen and theirs, their importer does not fabricate, and they hold the collapse map this changes. A mechanism we design alone and they cannot carry is not a mechanism
- [x] The operator's ruling is SURFACED, not taken. T-685 named this "the operator variable" in those words; this task produces the proposal and the costs, and stops
- [x] No production change is made under this task id — no exporter, importer, validator or corpus edit. On a ruling, separate build tasks are filed
- [x] The filing gap itself is recorded: T-685 GO'd on 2026-09-08 and produced no successor for 15 days, the same shape as T-213 (diagram-kind, GO'd 2026-07-21, still unbuilt). Two GO decisions with no build task behind them is a pattern in how decisions are discharged, not two coincidences

## Verification` instead of a Human AC here. Only keep [REVIEW] if
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
         1. Run `bin/fw reviewer T-835`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-835 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── T-835 legs ──────────────────────────────────────────────────────────────
test -f docs/reports/T-835-authority-on-the-element.md
grep -qF 'M1 — element declares, lane defaults' docs/reports/T-835-authority-on-the-element.md
grep -qF 'M2 — element only' docs/reports/T-835-authority-on-the-element.md
grep -qF 'M0' docs/reports/T-835-authority-on-the-element.md
# AC3/AC8 — the frozen standard and production code are UNCHANGED by this task
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md
git diff --quiet HEAD -- tools/validate-workflow.py tools/bpmn-cli.py examples/aef-processes/rendered
# AC1 (a') — controlled absence. The first version of this leg greped a DIFFERENT string
# (\bsovereignty\b) in the same file as its control, and the close gate refused it: that
# proves the file is readable, not that \bnone\b is a pattern capable of matching. The gate
# was right. The control now greps the SAME pattern where it IS present, so a broken regex
# fails the control instead of passing the assertion.
# Shape matters too: as a single `A && ! B` line the gate still refused, because it
# scans PER LINE for a negation and looks for a SIBLING line carrying the same pattern.
# Two legs, exactly as the gate's own message prints them.
grep -qE '\bnone\b' examples/aef-processes/rendered/context-memory.bpmn
! grep -qE '\bnone\b' docs/standards/aef-bpmn-mapping-v1.md
# AC1 (b') — pinned to the immutable pre-GO commit, so this cannot rot with the corpus
git show b09993376a5dc3bb8bec2510ca3181578456c545:tools/validate-workflow.py > /tmp/.t835-prego 2>&1 && grep -q 'W-LANE-NO-OWNER' /tmp/.t835-prego
# AC1 (a) — property, not a live count (T-3326)
grep -q 'authority="none"' examples/aef-processes/rendered/context-memory.bpmn
# AC6 — the downstream tasks were NOT advanced: their [REVIEW] criteria stay unticked
grep -qF -- '- [ ] [REVIEW]' .tasks/active/T-358-importer-fabricates-lane-and-pool-struct.md
grep -qF -- '- [ ] [REVIEW]' .tasks/active/T-341-an-unresolvable-flownoderef-silently-rea.md

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
     fw inception decide T-835 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-23T11:53:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-835-authority-on-the-element-lane-as-domain-.md
- **Context:** Initial task creation

### 2026-09-23T11:54:49Z — status-update [task-update-agent]
- **Change:** horizon: now → now

## Reviewer Verdict (v1.5)

- **Scan ID:** R-108d4b84
- **Timestamp:** 2026-09-26T22:17:10Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-26T22:17:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
