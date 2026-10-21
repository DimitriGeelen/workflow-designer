---
id: T-1242
name: "Structured attributes on aef:io: the shape of each input and output (nested
  attributes, allowed values), plus source and target system"
description: >
  Inception: Structured attributes on aef:io: the shape of each input and output (nested
  attributes, allowed values), plus source and target system

status: work-completed
workflow_type: inception
current_node: frw_end_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-10-20T21:08:18Z
last_update: 2026-10-21T14:33:08Z
date_finished: 2026-10-21T14:33:08Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-20T21:09:24Z'
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

# T-1242: Structured attributes on aef:io: the shape of each input and output (nested attributes, allowed values), plus source and target system

## Problem Statement

A step's inputs and outputs (`aef:input` / `aef:output`) carry a name and one flat type (`string`, `list`, `object`,
`ref`, `task_id`), so an object or list says nothing about what is inside, and nothing says which system the data
comes from or goes to. The operator wants each io to carry its shape (named attributes with types, nesting, allowed
values) plus source and target system, shown per attribute in the designer, so pseudocode can name real fields
(operator, 2026-10-20). The mapping standard is AEF's (v1.1, AEF T-4415). Research and external advice:
`docs/reports/T-1242-structured-io-attributes.md`.

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that the designer reading, showing and saving the structured io of mapping v1.1 (AEF T-4415 GO, ruled
text DRAFT 2 at AEF f1f7c30dd: fieldRef / typeRef / schemaRef / conceptRef, role, operation, cardinality,
sourceSystem / targetSystem, aef:field, aef:expect, aef:example, aef:prefixes, mappingVersion),
we will achieve steps whose inputs and outputs name real fields, types and systems, so pseudocode and tests can be
generated from a map instead of from prose.
We will know that we are successful when we see greenfield's VZN-T1 v29 open and save with 0 bytes changed in its 43
io; a v1.1 example map using every construct of the ruled text (incl. operation=upsert with a role=match field, an
aef:field list path with aef:when, and aef:expect const/enum/minimum/absent) show each attribute and child in the io
panel and round-trip with 0 bytes changed; and 0 of the 54 tracked v1 maps here change a byte on open and save.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1242 -->

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

- **IW-1: Which form: nested aef:attr children (A), BPMN itemDefinition + structureRef to a schema (B), inline JSON
  Schema (C), or a named-type catalogue (D), or a mix?**
  confidence: 3
  disposition: answered
  rationale: AEF T-4415 GO (2026-10-21, ruled DRAFT 2 at f1f7c30dd): referenced named types (typeRef / schemaRef) lead;
  inline aef:attr deferred to v1.2; BPMN itemDefinition only as a documented prior-art mapping.
- **IW-2: How deep: one level or recursive; allowed values, formats, ranges in or out?**
  confidence: 3
  disposition: answered
  rationale: ruled text: structure lives in the referenced type (any depth); the step selects fields with aef:field
  (dot and [] list paths, aef:when for line kinds) and states step expectations with aef:expect (JSON Schema keywords:
  const, enum with child values, minimum/maximum, pattern ECMA-262, present/absent); type-level rules stay in the type.
- **IW-3: Source and target system: free text or a reference into a catalogue; on the io or on the step?**
  confidence: 3
  disposition: answered
  rationale: ruled text: sourceSystem / targetSystem are catalogue references on the io, a step default on aef:meta,
  and derivable from a declared prefix (aef:prefix system=...); never free text.
- **IW-4: How does this relate to T-1219's ref / dataType (business types)?**
  confidence: 3
  disposition: answered
  rationale: ruled text: fieldRef names one field, conceptRef carries business meaning (replaces dataType); v1 ref keeps
  its meaning except the kind=field read rule; v1 dataType tokens are informational only. T-1229's fields fold into
  this task's build slices.
- **IW-5: What must the designer show, and what must AEF's intake carry, so nothing is silently dropped?**
  confidence: 3
  disposition: answered
  rationale: readers preserve unknown attributes and children verbatim or refuse naming them (T-1220, T-1243 built;
  AEF T-4518 for corpus_spec); the designer shows every v1.1 attribute and child of an io, read-only first.
- **IW-6: What minimum shape lets a step's pseudocode name real fields?**
  confidence: 2
  disposition: answered
  rationale: fieldRef (or typeRef + aef:field) per io, role per field, operation per instance (update/upsert/delete need
  a role=match field); checked against greenfield's VZN-T1 v29 (43 io) and TRA-T1 v2. Join key between steps (ref) and
  typeRef version pinning stay open in AEF's build tasks.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN (build, after GO, as separate build tasks): slice 1 read, show and preserve every v1.1 io construct in the
designer (read-only in the io panel, byte-exact round trip); slice 2 edit the A attributes in the io editor (absorbs
T-1229); slice 3 edit aef:field / aef:expect children; slice 4 designer-side lint surfacing AEF's v1.1 lint rules.
Each slice: screenshots at 1024/1440/1920 plus an independent reviewer, release to AEF the day it is tagged.
OUT: inline aef:attr (v1.2), wildcard selections (not in v1.1), field-to-field transformations (producer's ontology),
the data-flow join key and typeRef version pinning (open in AEF's build tasks).

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
  **Why you:** tier0 — recording an inception's go/no-go (`fw inception decide`) is Tier 0, and the standard this
  changes is ruled by AEF's operator (T-4415) and then ours.
  **Steps:**
  1. Run: `fw task review T-1242` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

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

**Rationale:**

Updated 2026-10-21, after AEF's operator ruled T-4415 GO (AEF 69dd29362, d33d19d9f) on DRAFT 2 as of f1f7c30dd. 832
and greenfield both verified that exact text (sha256 bd461031…). The shape is settled:
- referenced named types (`typeRef` / `schemaRef`);
- `fieldRef` for a single field;
- `role` per field and `operation` per instance;
- systems as catalogue references, derivable from the prefix map;
- `aef:field` selection with list paths;
- `aef:expect` with JSON Schema keywords;
- old maps still valid.

The designer side is bounded: preservation is already built (T-1220, T-1243), and the build splits into four
reviewable slices (see Scope Fence), read-only first, each reversible. It was checked against the real producer's maps
(VZN-T1 v29, TRA-T1 v2). What stays open (the join key, typeRef versioning) is outside the designer's slice 1.

**Evidence:**
- AEF T-4415 GO, ruled text DRAFT 2 at AEF f1f7c30dd; a verified copy is kept outside git.
- 832 designer check (points 1-8) and producer checks (a-i, full maps) taken in: this report, sections "Check of AEF
  T-4415 draft 1" and the dialogue log.
- External advice (Codex, GLM-5.3), greenfield's view, AEF's view and synthesis: `docs/reports/T-1242-structured-io-attributes.md`.
- AEF msg 9fb1413f (T-4415 IW-1 addendum 752932d2a): referenced named types lead, inline is the fallback.
- Preservation, independent of the ruling: unknown aef: attributes kept (T-1220, done); unknown child elements of
  aef:io kept through a save (T-1243, built); AEF's intake keeps them too (AEF T-4518).

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

**Rationale**: AEF T-4415 GO (operator ruling 2026-10-21, ruled DRAFT 2 at AEF f1f7c30dd, verified by 832 and greenfield incl. full maps); operator asked to prioritise; build in four slices, read-only first

**Date**: 2026-10-21T14:33:07Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-20T21:09:23Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-21T14:33:07Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** AEF T-4415 GO (operator ruling 2026-10-21, ruled DRAFT 2 at AEF f1f7c30dd, verified by 832 and greenfield incl. full maps); operator asked to prioritise; build in four slices, read-only first

## Reviewer Verdict (v1.5)

- **Scan ID:** R-eeaac281
- **Timestamp:** 2026-10-21T14:33:09Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-6
     - evidence: `IW-6 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-23a4eea8
- **Timestamp:** 2026-10-21T14:33:09Z
- **Overall:** CONTRADICTED
- **Claims:** 5

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-1242-structured-io-attributes.md` | file | ✓ pass |
| `T-4415` | task | ✗ fail — no task file in .tasks/{active,completed}/ |
| `T-1220` | task | ✓ pass |
| `T-1243` | task | ✓ pass |
| `T-4518` | task | ✗ fail — no task file in .tasks/{active,completed}/ |

### 2026-10-21T14:33:08Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
