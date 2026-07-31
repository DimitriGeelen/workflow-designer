---
id: T-317
name: "Rule parity: W-GW-AMBIGUOUS is missing from the BPMN validator, so the designer's own dialect gets the weaker rule set"
description: >
  T-309's GO decision named rule parity as a prerequisite of the first surfacing slice, not a follow-up. The designer speaks BPMN, but W-GW-AMBIGUOUS (exclusiveGateway with more than one unconditioned outgoing edge) exists only on the YAML Validator; the XmlValidator has E-XML-GW-OUTGOING but no ambiguity rule. Confirmed by mutation on 2026-07-31: stripping all 5 conditionExpression elements out of examples/aef-processes/rendered/inception-review.bpmn leaves it VALID with no findings. So surfacing the validator in the editor today would surface the weaker set and would specifically not answer the gateway question that prompted the inception. Deliverable is the XML-side rule plus the fixture-suite cases and a corpus sweep confirming no existing map lights up.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T11:26:47Z
last_update: 2026-07-31T11:27:11Z
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

# T-317: Rule parity: W-GW-AMBIGUOUS is missing from the BPMN validator, so the designer's own dialect gets the weaker rule set

## Context

Prerequisite carved out of T-309 (inception, GO 2026-07-29). Building under the inception
id would violate inception discipline, so this is its own build task with one deliverable.

The designer speaks BPMN. `Validator` (YAML) carries `W-GW-AMBIGUOUS`; `XmlValidator` (BPMN)
does not. Surfacing "the validator" in the editor today would therefore surface the weaker
rule set, and would specifically fail to answer the gateway question that prompted T-309.

Confirmed by mutation rather than by reading, 2026-07-31: stripping all 5
`<bpmn:conditionExpression>` elements from `examples/aef-processes/rendered/inception-review.bpmn`
leaves the validator reporting `VALID -- no findings`, exit 0.

Semantics are already settled on the YAML side and are NOT being re-litigated here
(`tools/validate-workflow.py:326`): at most one outgoing edge of an `exclusiveGateway` may
be unconditioned — that one is the default branch; two or more means the runtime has no
defined choice. Severity WARN, matching the YAML rule and matching the house position that
a defensible reading usually exists and authority over the map belongs to the author.

Rule id is `W-XML-GW-AMBIGUOUS`, following the established namespacing (our ids are
severity-prefixed, the XML class carries the `XML` infix, and the fixture-suite contract is
`<RULE-ID>.<ext>`). The bare token `gw_ambiguous` goes in the MESSAGE so a grep joins both
toolchains, exactly as done for `W-XML-LANE-GEOMETRY` in T-312.

## Acceptance Criteria

### Agent
- [x] Teeth FIRST: the gap is recorded as a reproducible pre-change measurement — a BPMN map
      with 2+ unconditioned outgoing edges on an `exclusiveGateway` validates clean before the
      change. A rule whose absence was never demonstrated is not a rule anyone can trust.
- [x] `XmlValidator` emits `W-XML-GW-AMBIGUOUS` when an `exclusiveGateway` has more than one
      outgoing `sequenceFlow` carrying no `bpmn:conditionExpression`, naming the gateway and
      the count.
- [x] Semantics match the YAML rule exactly: exactly one unconditioned outgoing edge is the
      default and is SILENT; two or more warn. Verified at the boundary (1 -> silent, 2 -> warn),
      because an off-by-one here would flag every well-formed gateway in the corpus.
- [x] Severity is WARN, not ERROR — it must not hard-fail promoted peer bytes we are forbidden
      to edit, which is the mistake T-312 avoided and was vindicated on day one for.
- [x] Fixture-suite cases added under the `<RULE-ID>.<ext>` naming contract, and
      `tests/run-validator-tests.sh` stays green with its leg count recorded.
- [x] Corpus sweep: every rendered BPMN map plus every shared fixture re-validated, with the
      finding count stated. A non-zero count is a result to report, not a reason to weaken
      the rule.
- [x] Bridge suite green (`0 failed`) — the rendered corpus round-trips through this validator,
      so a new rule that fires on corpus bytes would break it.
- [x] No YAML-path behaviour change: the existing `W-GW-AMBIGUOUS` findings on the YAML corpus
      are identical before and after.

## Verification

python3 tests/test_t317_gw_ambiguous_parity.py
bash tests/run-validator-tests.sh > /tmp/.t317-val 2>&1
grep -qE "^== summary: [0-9]+ passed, 0 failed ==$" /tmp/.t317-val
bash tests/run-bridge-tests.sh > /tmp/.t317-bridge 2>&1
grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$" /tmp/.t317-bridge


## Evidence

**The gap, demonstrated before it was closed.** Stripping all 5
`<bpmn:conditionExpression>` elements out of
`examples/aef-processes/rendered/inception-review.bpmn` left the validator reporting
`VALID -- no findings`, exit 0. After the change the same bytes report two
`W-XML-GW-AMBIGUOUS` findings (`frw_2_recommendation` 2 flows, `hum_2_decision` 3 flows)
while the unmutated original stays clean.

**Boundary pinned in both directions.** One unconditioned outgoing edge is the default
branch and is SILENT (`tests/fixtures/valid/gw-single-default.xml`); two warn; three warn
naming all three witnesses. The silent side is the one that matters — a rule written as
">= 1" instead of "> 1" would flag every well-formed gateway in the corpus while the warn
fixture kept passing.

**Two true positives on day one, neither of them planted.**

1. `tests/fixtures/aef-overlay/draft-knowledge-leveling-v3.bpmn` — AEF's pinned, un-editable
   bytes. `fw_gw_ready` fans FOUR outgoing flows, none conditioned. Same fixture that already
   carries the T-312 inversion and the T-313 overflows; this is a third independent defect on
   it. Reported to AEF.
2. `tests/fixtures/valid/investigate.bpmn` — OURS, and the more interesting one. It is the
   BPMN twin of `investigate.workflow.yaml`, whose two gateway edges carry
   `${findings.confidence >= 0.7}` and `${findings.confidence < 0.7}`. The hand-transcribed
   BPMN twin had dropped BOTH, leaving a gateway no runtime can resolve, in a file sitting in
   `fixtures/valid/` asserting itself clean. Nothing could detect the drift while the YAML
   rule had no BPMN counterpart — the parity gap was hiding a live instance of itself.
   Repaired by restoring both conditions from the YAML twin.

The rule was NOT weakened to accommodate either. The one design question it raised —
whether a branch carrying a `name` and an `aef:decisionInput` but no `conditionExpression`
should count as conditioned — was answered by measurement rather than by taste: 0 of 113
exclusiveGateway outgoing edges in the live YAML corpus carry a label without a condition,
and both the bridge (`yaml-to-bpmn.py:343`) and the designer
(`aef-workflow-designer.html:9540`) emit `conditionExpression`. So the dialect is
unambiguous and `investigate.bpmn` was an outlier, not a precedent.

**Counted tolerance re-derived, and its count assertion made live.** The admitted set on
AEF's v3 goes 3 -> 4: 1 geometry + 2 capacity + 1 gw-ambiguous. The count had been asserted
only in T-312's Verification block — which, T-312 being completed, never runs again. So the
half of the tolerance that made it a tolerance rather than a suppression list had quietly
stopped being enforced. Moved into `tests/test_dead_leg_census.py` with the arithmetic
written out, and proven RED by bumping the constant to 5.

**Corpus sweep: 43 maps, 1 hit** (the AEF fixture). Our own 24 rendered maps and both shared
seam fixtures are clean, so the rule adds no noise to anything we author.

**Suites:** validator `== summary: 38 passed, 0 failed ==` (was 36, +2 fixtures); bridge
`61 passed, 0 failed` (was 60, +1 leg).

**T-316 caught this task's own new test file** as an orphan before it was wired — one day
after that guard shipped, on a real file rather than a synthetic one.


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

### 2026-07-31T11:26:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-317-rule-parity-w-gw-ambiguous-is-missing-fr.md
- **Context:** Initial task creation

### 2026-07-31T11:27:11Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
