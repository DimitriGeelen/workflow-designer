---
id: T-811
name: "Thirty authored corpus values still unreachable in the panel (T-810 census
  residue)"
description: >
  Residue from T-810, measured by tools/_t810-unreachable-values-census.py. After
  decisionOutputs was fixed (47 unreachable -> 30), the remainder is: endpoint on
  exclusiveGateway 11, endpoint on startEvent 7, emits on scriptTask 5, multiInstance
  3, aggregation 2, compensates 1, timer 1. THREE of those groups were never named
  by value review F-11 — the general census found them. The last four have no FIELD_META
  entry at all, so each needs a field definition rather than a one-line list edit.
  Separately, routingHint (9) and loopDetour (3) ride sequenceFlow, which has no editor
  node panel at all — a different problem, not in this scope.

status: started-work
workflow_type: inception
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-09-22T13:14:41Z
last_update: 2026-09-23T16:51:24Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
                                  # ⚠ CHANGE THIS TOO (T-625). Measured 2026-08-29: 38 of 41 inceptions still carried this
                                  # exact 3, the same 38 that carried voi_score: 0.5. Between them the two fields fix the
                                  # task's ENTIRE BVP position — value and cost — so leaving both planted means the
                                  # ranking is the template's opinion, not anyone's. The 3 is a placeholder, not a guide.
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
                                  # ⚠ CHANGE THIS (T-624). For an inception voi_score IS the entire BVP composite: the
                                  # estimator skips per-driver scoring and derives all nine drivers from this one number
                                  # (estimator.py _score_inception_voi). Leaving 0.5 does not score the task, it abstains —
                                  # and an abstention is printed as a confident BVP 126 that no reader can tell from a real
                                  # score. Measured 2026-08-29: 38 of 41 inceptions still carried this exact default, so the
                                  # entire hv-lc quadrant ranked as one flat tie. `python3 tools/_t624-voi-provenance.py`
                                  # reports which tasks were ever deliberately scored. The 0.5 below is a placeholder that
                                  # exists only to satisfy the schema gate (PL-167) — it is not a recommendation.
bvp_scores_proposed:
  - ts: '2026-09-23T16:49:20Z'
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
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-23T16:50:15Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=6 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-811: Thirty authored corpus values still unreachable in the panel (T-810 census residue)

## Problem Statement

Thirty values that a human authored into the corpus cannot be reached from the designer's
properties panel. The author can write them (they are in the `.bpmn` files, they survive
import, they round-trip on save) but cannot **see or change** them once the file is open.

For whom: the operator authoring a process in the designer — arc-001's whole premise is that
the Designer is AEF's authoring surface. A value the authoring surface cannot show is a value
the authoring surface does not actually own.

Why now: T-810 fixed `decisionOutputs` and took the count 47 → 30. The residue is not a tail
of one bug; it is **seven distinct groups**, and four of them have no `FIELD_META` entry at
all. That is the difference between a list edit and a field-definition design, which is what
makes this an inception rather than a build.

## Assumptions

- **A-1:** The 30 are authored intent, not import noise. If some are artefacts of the
  renderer rather than a human's authoring, the correct repair is to remove them from the
  corpus, not to make them editable. **Untested — IW-3 tests it.**
- **A-2:** `FIELD_META` is the right extension point. Four groups have no entry, so the
  question is whether adding four entries is sufficient or whether the panel's
  node-kind→field mapping is the actual constraint. **Untested — IW-1 tests it.**
- **A-3:** The count is stable. 30 is a measurement from `tools/_t810-unreachable-values-census.py`
  taken 2026-09-22. It is re-run in the Exploration Plan rather than carried forward as a
  remembered number (PL-175: a name in a coverage list is a CLAIM; only a value that varies
  is EVIDENCE).

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

- **IW-1: Is `FIELD_META` the unit of repair, or is the panel's node-kind→field mapping the
  actual constraint?** Three groups (`endpoint` on exclusiveGateway 11, `endpoint` on
  startEvent 7, `emits` on scriptTask 5) name an attribute the panel already knows; they are
  unreachable on *these node kinds*. Four groups (multiInstance 3, aggregation 2,
  compensates 1, timer 1) have no `FIELD_META` entry at all. If the first three are a mapping
  problem and the last four a definition problem, this is two repairs wearing one task id.
  confidence: 3
  disposition: answered
  rationale: Two repairs. 23/30 are mapping-class (field defined in FIELD_META, withheld by
    AEF_FIELDS[type]); 7/30 are definition-class. src/aef-workflow-designer.html:1909 (AEF_FIELDS)
    and :2021 (FIELD_META); table in docs/reports/T-811-unreachable-values-inception.md §S-3.

- **IW-2: Why did value review F-11 not name three of these seven groups?** F-11 enumerated
  the fields it believed were authored; the general census found three it never listed. Either
  F-11's chosen set was wrong at the time, or the corpus gained them afterwards. This matters
  beyond T-811: if a hand-enumerated review can miss a third of the population, every other
  finding that rests on F-11's list inherits the same blind spot (PL-288 — a chosen-set
  assertion cannot find what you forgot to choose).
  confidence: 2
  disposition: answered
  rationale: Mechanism is PL-288 — F-11 asserted over a hand-enumerated field list, the census
    asserts over the corpus population. Confidence 2 not 3: the entry DATE of the three missed
    groups was not established, so "F-11 was wrong then" vs "corpus moved after" stays open.

- **IW-3: Are the 18 `endpoint` values on exclusiveGateway and startEvent authored intent, or
  corpus noise?** `endpoint` is meaningful on a task that calls out. On a gateway or a start
  event it may be a copy-paste residue from corpus generation rather than anything a human
  meant. If it is noise, the correct repair is to delete it from the corpus — which would take
  30 unreachable values to 12 and change the recommendation entirely. This is the single
  highest-leverage question here and it is answered by reading the corpus, not by design.
  confidence: 3
  disposition: answered
  rationale: Authored intent, not noise. All 18 values unique, zero duplicates; startEvent(7)
    carries the trigger command (`fw release`, `fw harvest`), exclusiveGateway(11) carries a
    source citation for where the branch is implemented (`update-task.sh:1010-1026`). Full
    extraction in docs/reports/T-811-unreachable-values-inception.md §S-2. A-1 holds.

- **IW-4: Does the fix need a per-node-kind panel, or one generic "authored values not shown
  above" affordance?** A generic affordance would also cover the out-of-scope `sequenceFlow`
  residue (`routingHint` 9, `loopDetour` 3), which has no node panel at all — 12 more values
  for no extra mechanism. A per-kind panel is more precise and more code. The answer sets the
  blast radius, and therefore the cost half of this task's BVP position.
  confidence: 3
  disposition: dissolved
  rationale: The question presupposed no generic affordance exists. One does —
    src/aef-workflow-designer.html:6310 renders an "Other extensions · N" read-only section
    for every unoffered scalar. So the 30 are VISIBLE and read-only, not invisible; this
    task's own framing was overstated and is corrected in the artefact §S-3. Raised instead
    as SQ-2: is read-only sufficient? That is a UX judgement, outside PD-302 delegation.

## Exploration Plan

Time-boxed, evidence-first. Each spike answers one IW and writes its finding into
`docs/reports/T-811-unreachable-values-inception.md` (C-001: the artefact is the thinking
trail, not this task file).

1. **S-1 — re-measure (15 min, answers A-3).** Re-run `tools/_t810-unreachable-values-census.py`
   and record today's figure against the 2026-09-22 figure of 30. A moved number is itself a
   finding.
2. **S-2 — read the 18 (30 min, answers IW-3).** Pull every `endpoint` on an exclusiveGateway
   or startEvent out of the corpus with its surrounding element and judge authored-vs-noise
   per instance, not in aggregate.
3. **S-3 — read the panel (30 min, answers IW-1 and IW-4).** Locate `FIELD_META` and the
   node-kind→field mapping in `src/aef-workflow-designer.html`; establish whether the three
   mapping-class groups and the four definition-class groups need one mechanism or two.
4. **S-4 — diff F-11 against the census (15 min, answers IW-2).** Compare the F-11 field list
   to the census population and date the three it missed.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply? -->

- Single-file app: the panel lives in `src/aef-workflow-designer.html`; any field definition
  lands in the same file that the release pins by sha256 (G-007). A change here is a release,
  not a patch.
- `examples/aef-processes/rendered/` is a **seam artefact AEF pins against**. If IW-3 answers
  "noise", deleting corpus values is a cross-project change requiring AEF's agreement — it is
  not unilaterally ours, and that raises its cost well above the `S` this task currently reads.
- Visual verification is mandatory for any panel change (CLAUDE.md §Visual Verification):
  element screenshots across theme and density modes. On T-155's sibling scoping that was the
  majority of the cost, not the logic.

## Scope Fence

**IN:** the 30 values the census reports on node-bearing elements; whether each is authored
intent; what mechanism would make them reachable; a GO/NO-GO with a bounded successor.

**OUT:** `sequenceFlow` carriers (`routingHint` 9, `loopDetour` 3) — no node panel exists, a
different problem. **OUT:** building anything. This is an inception; no panel code is written
before a GO. **OUT:** editing the frozen standard `docs/standards/aef-bpmn-mapping-v1.md`.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-811` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

**GO if:**
- Every content-bearing unreachable group can be made editable without a dialect ruling —
  i.e. the field's existing label and hint are correct on the node kinds being added.
- The repair is expressible as `AEF_FIELDS` entries over fields already in `FIELD_META`,
  matching the T-618 / T-810 precedent, with no change to the frozen mapping standard.
- The values are authored content, so exposing them changes what an author can actually do.

**NO-GO if:**
- The content-bearing population concentrates in a field whose meaning varies by node kind,
  making a correct panel require a dialect decision this project does not own.
- Part of the counted population is empty, so the headline figure overstates the real gap.
- The fix would present a value under a label that misdescribes it on that node kind.

**Measured against these (S-5):** 18 of 24 content-bearing values are `endpoint`, which
carries three meanings; 6 of the counted 30 are empty; `FIELD_META.endpoint`'s hint is wrong
for the gateway group. **All three NO-GO conditions fire for the panel work.** The census
correction meets the GO conditions and is fenced as a separate item.

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

**Recommendation:** DEFER on the panel work · GO on one bounded instrument fix

Full evidence: `docs/reports/T-811-unreachable-values-inception.md` (S-1 … S-5).

**Rationale.** The pre-existing DEFER was half right, and the half it got right is
load-bearing. **Wrong:** "endpoint on exclusiveGateway (11) and startEvent (7) may be corpus
mistakes" — they are not; all 18 are unique, hand-authored and coherent (S-2). **Right:**
"determinism was safe because it is semantically type-neutral, and endpoint is not" — S-2
confirms it directly: `endpoint` means call-target on a task, trigger command on a start
event, and implementation citation on a gateway (`update-task.sh:1010-1026`).

A GO was drafted at S-3 ("23 of 30 are a three-line `AEF_FIELDS` edit") and **withdrawn at
S-5**, which measured content rather than presence:

- **24 of 30 carry content; 6 are empty elements.** `emits` on scriptTask (5) and
  `compensates` (1) are `<aef:… />` with nothing in them — there is nothing to make reachable.
  Corroborating: `emits` is offered on `endEvent`, where the corpus uses it **zero** times.
- **So the content-bearing mapping-class population is 18, and all 18 are `endpoint`** — the
  one overloaded field. No smaller scoping avoids the dialect question; the escape S-3 relied
  on does not exist.
- Shipping the field ships its label: `FIELD_META.endpoint` reads
  `hint: 'fw … | agent prompt | watchtower view'`, which is wrong for a gateway carrying a
  source citation. Editable-under-a-wrong-label is worse than read-only, not better.

**What changed is what the DEFER waits on** — from "are these corpus mistakes?" (answered,
no) to **SQ-1**: does the dialect sanction the three-way overload, and should the panel label
`endpoint` per node kind? 999-AEF is the counterparty and the mapping standard is frozen.

**Recommended now, needs no ruling:** `tools/_t810-unreachable-values-census.py` counts empty
elements as authored values, overstating the gap by 6 (30 vs 24). A probe that reports absent
content as present content does not stop informing, it **misinforms** (PL-332). Bounded, no
standard, no seam, no panel.

**Sovereign questions:** SQ-1 (endpoint overload — AEF's, frozen standard) · SQ-2 (is
read-only sufficient? UX judgement, outside PD-302 delegation) · SQ-3 (`timer` vs `timerSpec`
corpus/panel naming drift). Surfaced, not resolved.

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

<!-- Filled at completion via: fw inception decide T-811 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-23T16:51:24Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
