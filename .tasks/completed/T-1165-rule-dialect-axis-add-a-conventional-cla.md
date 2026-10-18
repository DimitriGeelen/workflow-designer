---
id: T-1165
name: "Rule-dialect axis: add a CONVENTIONAL class for predicates on properties the
  standard neither requires nor forbids (W-XML-DISCONNECTED)"
description: >
  Promoted from OBS-467 by T-1149 (observation triage, 2026-10-13). T-967 (active,
  line ~99) records the gap and proposes a fourth CONVENTIONAL class. No task owns
  building it, and grep for CONVENTIONAL outside inbox.yaml finds nothing. W-XML-DISCONNECTED
  is still classified UNIVERSAL. Original observation text is in .context/inbox.yaml
  under OBS-467.

status: work-completed
workflow_type: inception
current_node: frw_end_task
owner: agent
horizon: null
tags: [observations]
components: [tests/run-bridge-tests.sh, tools/_t842-commit-exemption-spelling-regression.sh]
related_tasks: [T-1200]
inception_decisions:
  - id: conventional-class
    text: "Option 1: a new CONVENTIONAL class derived from a cited RULE_BASIS (MUST/SHALL/REQUIRED found verbatim in mapping-v1, closed GROUNDS list)"
    ships_in: T-1200
created: 2026-10-13T16:21:23Z
last_update: 2026-10-18T09:00:52Z
date_finished: 2026-10-18T09:00:52Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-17T23:56:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1165: Rule-dialect axis: add a CONVENTIONAL class for predicates on properties the standard neither requires nor forbids (W-XML-DISCONNECTED)

## Problem Statement

The validator labels every rule on a dialect axis (UNIVERSAL / DIALECT-RELATIVE / PRESENTATIONAL), derived from what
the frozen standard (mapping-v1) says about the carrier a rule reads. OBS-467 (T-967): W-XML-DISCONNECTED fires on a
global graph property (more than one weakly-connected component) that the standard neither requires nor forbids, yet
the derivation calls it UNIVERSAL because sequenceFlow is a structure carrier. The authoring kit tells external
authors (AEF first) that "any conformant document satisfies" a UNIVERSAL rule, so a convention of ours is presented
as correctness: the 47-of-48 mistake again. Research artifact: `docs/reports/T-1165-conventional-dialect-class.md`.

## Hypothesis

<!-- Agent wording (2026-10-18), replacing the estimator draft; the operator may correct it. -->

We believe that deriving a CONVENTIONAL class for structure-only rules with no normative basis,
we will achieve an authoring kit that no longer presents our house graph-shape rules as universal truths to external authors.
We will know that we are successful when the axis test derives 13 rules CONVENTIONAL (tiers A+B in the artifact),
every remaining structure-only UNIVERSAL rule carries a citation the test resolves in the standard, and the kit's
CONFORMANCE.md prints those 13 as CONVENTIONAL.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1165 -->

- A-1: the standard is silent on graph shape. **Tested, holds**: §6 lists four conformance requirements, none about
  connectivity, events, reachability or balance (artifact F1).
- A-2: W-XML-DISCONNECTED is an isolated case. **Tested, false**: 31 of 63 rules read structure only, all UNIVERSAL;
  13 rest on nothing normative (artifact F2).
- A-3: the class can be derived without a new input. **Tested, false**: carrier class and polarity cannot express
  "the standard backs this property"; a checked per-rule citation is needed (artifact F3).

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

- **IW-1: Is UNIVERSAL actually wrong for W-XML-DISCONNECTED — is the frozen standard silent on flow-graph connectivity?**
  confidence: 3
  disposition: answered
  rationale: yes, wrong. mapping-v1 §6 (lines 123-129) defines conformance by four requirements, none about graph shape; §3 maps elements without requiring presence or connection; the kit's CONFORMANCE.md (job 030) prints the rule UNIVERSAL (artifact F1)
- **IW-2: How many current rules rest on a property the standard is silent about — one (W-XML-DISCONNECTED) or a population?**
  confidence: 3
  disposition: answered
  rationale: a population. RULE_CARRIERS: 31/63 rules read STRUCTURE only, all UNIVERSAL; 5 absence rules (tier A) + 8 graph heuristics (tier B) have no normative basis; 18 well-formedness rules (tier C) do. T-970/T-977 show the cost (artifact F2)
- **IW-3: Can CONVENTIONAL be DERIVED from an input the axis already has (T-323: derived, never asserted), or does it need a new declared input?**
  confidence: 2
  disposition: answered
  rationale: needs one new input, a per-rule normative citation checked verbatim against the standard file (the UNRATIFIED/_bullet pattern); a missing citation derives CONVENTIONAL. The test proves a citation exists, not that it is apt — stated limit (artifact F3)
- **IW-4: What changes for consumers (findings text, authoring kit, AEF's corpus) if a rule moves to CONVENTIONAL?**
  confidence: 3
  disposition: answered
  rationale: kit CONFORMANCE.md table and legend (re-calibration before the next release); AEF announcement names 13 class changes, no stored data, no migration; designer does not consume the axis yet (src line 10713); validator severity/messages unchanged (artifact F4)

## Exploration Plan

Research only (time-box: one session): read mapping-v1 §1-§6 for graph-shape requirements; measure the rule
population with the axis module's own tables (scratch script, not committed); trace every consumer of the class.
No prototype: the derivation change is small enough to scope from the code.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: whether the axis needs the class, its population, how to derive it, who is affected. OUT: changing any rule's
predicate or severity; the designer consuming the axis; building anything before a GO.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Why you:** direction — whether the validator's rule-dialect axis gains a CONVENTIONAL class changes how every rule is classified for map owners and for AEF; and `fw inception decide` is the operator's
  **Steps:**
  1. Run: `fw task review T-1165` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The standard is silent on the properties at issue (so UNIVERSAL is a false claim): **met**, F1
- The class can be derived from a checked input, not asserted (T-323): **met with a stated limit**, F3
- The build is bounded (one test, one generator, one legend), reversible (a label, no stored data) and assertable
  (13 moves, 18 citations): **met**, F2/F4

**NO-GO if:**
- A normative source backs graph shape after all (then UNIVERSAL is right): not found
- The fix requires changing rule predicates or the designer: not required
- The cost (kit re-calibration, AEF notice) exceeds the benefit: no, re-calibration already runs every release

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:** The standard is silent on graph shape (mapping-v1 §6), yet 31 of 63 rules derive UNIVERSAL from
structure alone, and 13 of them (W-XML-DISCONNECTED, the four start/end-event rules, and the eight reachability,
dead-end and parallel-gateway heuristics across both forms) rest on nothing normative. The kit therefore tells
external authors that our house rules are universal truths; T-970/T-977 show outsiders finding exactly that. Fix:
one new checked input (a per-rule citation the axis test resolves in the standard), CONVENTIONAL derived when it is
missing, kit regenerated and re-calibrated, the 13 changes named in the next AEF announcement. Bounded, reversible,
assertable. Option 1 (new CONVENTIONAL class) over option 2 (fold into DIALECT-RELATIVE): it keeps DIALECT-RELATIVE
meaning one checkable thing; option 2 is acceptable if the operator prefers fewer words for authors. Detail:
`docs/reports/T-1165-conventional-dialect-class.md`.

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

**Decision**: GO

**Rationale**: Operator 2026-10-18: GO, option 1 (new class CONVENTIONAL) with the review additions. mapping-v1 section 6 is silent on graph shape; 31/63 rules derive UNIVERSAL from structure alone, 13 with no normative basis. Build: per-rule citation verified against the standard (normative keyword, closed list of non-standard grounds), missing citation derives CONVENTIONAL; basis column in the kit; uncited well-formedness rules surface as findings; kit re-calibrated; 13 class changes and a v1.x note proposed to AEF. AEF (msg f1f5ef6f) and an independent reviewer both chose option 1. Bounded, reversible (a label, no stored data), assertable. Findings: docs/reports/T-1165-conventional-dialect-class.md

**Date**: 2026-10-18T09:00:50Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-17T23:56:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-10-18T09:00:50Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator 2026-10-18: GO, option 1 (new class CONVENTIONAL) with the review additions. mapping-v1 section 6 is silent on graph shape; 31/63 rules derive UNIVERSAL from structure alone, 13 with no normative basis. Build: per-rule citation verified against the standard (normative keyword, closed list of non-standard grounds), missing citation derives CONVENTIONAL; basis column in the kit; uncited well-formedness rules surface as findings; kit re-calibrated; 13 class changes and a v1.x note proposed to AEF. AEF (msg f1f5ef6f) and an independent reviewer both chose option 1. Bounded, reversible (a label, no stored data), assertable. Findings: docs/reports/T-1165-conventional-dialect-class.md

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f4a6b98f
- **Timestamp:** 2026-10-18T09:00:56Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-7a1e5fc7
- **Timestamp:** 2026-10-18T09:00:56Z
- **Overall:** CONFIRMED
- **Claims:** 3

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-1165-conventional-dialect-class.md` | file | ✓ pass |
| `T-970` | task | ✓ pass |
| `T-977` | task | ✓ pass |

### 2026-10-18T09:00:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
