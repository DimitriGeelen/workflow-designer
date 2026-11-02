---
id: T-1363
name: "How the designer represents what real cross-system workflows carry: instructions,
  screen states, documents (BPMN data objects), state changes as triggers, system-to-system
  data exchange (from WT-01, generalised)"
description: >
  Inception: How the designer represents what real cross-system workflows carry: instructions,
  screen states, documents (BPMN data objects), state changes as triggers, system-to-system
  data exchange (from WT-01, generalised)

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-11-01T20:38:40Z
last_update: 2026-11-01T21:27:04Z
date_finished:
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
  - ts: '2026-11-01T20:41:08Z'
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

# T-1363: How the designer represents what real cross-system workflows carry: instructions, screen states, documents (BPMN data objects), state changes as triggers, system-to-system data exchange (from WT-01, generalised)

## Problem Statement

Greenfield's WT-01 ("Walkthrough to-be verkoop", 25 steps, 36 io; T-1361) describes a real sales process across
Salesforce, Tacton CPQ, a connector, a gateway and Novis. About a third of its io contracts are not data: screen states
("opportunity zichtbaar met tabblad CPQ"), instructions ("Klikt op tabblad CPQ", "opdracht: definitieve offerte"),
documents (quote PDF, signed PDF) and a system event (TactonEvent). The operator (2026-11-01): instructions belong in a
workflow ("a workflow is also an instruction for people"); a signed PDF is a state change, a trigger point; ask
greenfield to explain the process and its system-to-system data exchange "so you understand how we need to shape this
workflow designer to really support that kind of development", and generalise it to other projects. Today the designer
keeps BPMN data objects/stores on save but does not show them, and has no first-class view of state-change triggers.

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

We believe that the designer showing what cross-system maps already carry in standard BPMN and the project's
ontology (documents with their state, state-change triggers by kind, each attribute's value rule from the field
catalog), and checking a map against that catalog, while AEF owns the few linking terms (T-4991),
we will achieve maps of real multi-system processes that a person can read and a tool can check without free-text io,
and that carry over to other projects.
We will know that we are successful when we see greenfield's final WT-01 (wt01-io-v12) open in a released designer
with (a) 0 free-text io, (b) both conditional triggers drawn with the condition marker, (c) every document drawn with
its dataState, (d) every catalogued fieldRef showing its value rule, and (e) the validator's catalog check reporting
0 field-object mismatches.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1363 -->
- **A1: The non-data io (instructions, screen states, documents, state changes, system events) fit standard BPMN
  elements without a new modelling language.** Tested: rules A-F applied to all 36 WT-01 io (greenfield's wt01-io-v11
  and v12). The result validates with 0 errors and every count survives a save. HOLDS.
- **A2: How a value is built belongs to the attribute's definition (SHACL shape in the producer's ontology), not to
  each io.** Tested: greenfield harvested 86 of 105 shapes from the systems' own metadata, and moved its type-level
  enums and patterns out of the map (14 → 8 aef:expect). Harvesting corrected a hand-typed picklist. HOLDS.
- **A3: Linking each attribute to its object makes a cheap check that finds real errors.** Tested: greenfield's
  field-entity = io-typeRef self-check found 15 real mismatches in its own map, and 832's script check found the same
  class. HOLDS.
- **A4: The pattern is general, not WT-01-specific.** Partly tested: greenfield states all seven needs as general, the
  operator asked for generalisation, and AEF took the vocabulary up as T-4991. It has not yet been checked on a second
  project's map. OPEN (see IW-3).

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
- **IW-1: How does the WT-01 process actually run — who does what in which system, what crosses between systems (object, means, trigger), which documents exist and which state changes start the next step?**
  confidence: 3
  disposition: answered
  rationale: greenfield's owner-approved practice case (msg 6914e504), then its final map wt01-io-v12 (sha 67d145d9…) in the practice-case order. 832 reviewed every io against the catalog (T-1361): 0 errors on 0.35.0 rules, clean apart from two by-design cases.
- **IW-2: Which BPMN primitives already carry each kind — instructions (bpmn:documentation), screen states, documents (dataObject / dataStore + associations), state-change triggers (message/signal/conditional events) — and which needs an AEF extension?**
  confidence: 3
  disposition: answered
  rationale: The non-data needs map onto standard BPMN, all kept on save:
    - instructions and screen states: bpmn:documentation lines;
    - documents: dataObjectReference with dataState;
    - triggers: message and conditional catch events;
    - user-started system action: a click step followed by a system step.
  Shown so far: documentation, events (named; conditional/signal with their marker since 0.36.0, T-1366) and value
  rules (T-1365). Not yet drawn: data objects. Needing an AEF term: decision/proof status, keys between systems and the
  user-started action as one term (AEF T-4991). See the report's table.
- **IW-3: What generalises beyond WT-01 to other projects (a reusable pattern for cross-system workflows), and what is WT-01-specific?**
  confidence: 2
  disposition: answered
  rationale: General: the seven needs, which greenfield states as general and which the operator asked to generalise; rules A-F; the value-rule split (catalog/shape, aef:expect, field role); the field-object check. WT-01-specific: the systems, the trampolines and the Novis gaps. Confidence 2, not 3: no second project's map has been checked yet. That is a condition of the GO (first build task's test map is not WT-01's).
- **IW-4: Should the cross-system primitives (document + state, state change as trigger, user-started system action, key between systems, decision/proof status, attribute value rules) be a small shared workflow-design vocabulary reusing BPMN, SHACL and PROV-O — and who owns which part (ontocraft unchanged for building ontologies; AEF the vocabulary and spec; 832 the ontology↔map bridge: catalog from ontology incl. SHACL, validator checks, designer display, an authoring-kit skill)?**
  confidence: 2
  disposition: answered
  rationale: Operator 2026-11-01 agreed the split (ontocraft unchanged; AEF owns the vocabulary and spec; 832 builds the bridge). AEF filed it as T-4991, and whether AEF owns it is AEF's operator's call, outside this decision. SHACL names agreed with greenfield and AEF (msgs 32e76d28, 4150db95). 832's bridge is partly built (T-1365, in 0.36.0); this decision covers only 832's part.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->
Done 2026-11-01..02, in dialogue with greenfield (T-1361) and AEF, all recorded in the report's dialogue log:
1. greenfield's practice case (IW-1);
2. per-io rules A-F applied to all 36 io and measured in the designer (IW-2);
3. value rules as SHACL shapes in the producer's ontology (A2);
4. the field-object check (A3);
5. three review rounds on wt01-io-v11/v12;
6. two designer changes, shipped in 0.36.0 (T-1365, T-1366).

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->
- Client data (WT-01, the practice case, the catalog rows) stays out of this repo, in ignored build/peer-data/. Tests
  and evidence use synthetic fixtures.
- Saves stay byte-identical except where a change says otherwise (T-1366 renamed one id word, announced to AEF).
- The value rules come through the existing catalog contract (T-1312); the designer never edits them.

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->
- **In:** what 832's designer and validator do with standard BPMN and the field catalog.
- **Out:**
  - the shared vocabulary itself (AEF T-4991);
  - an ontology for AEF in general (AEF's operator);
  - changes to ontocraft;
  - editing ontologies or value rules in the designer.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated *(IW-1 answered from the practice case and the final map)*
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested *(A1–A3 hold; A4 partly, made a condition of the GO)*
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale *(GO for 832's part, with two bounded builds B1/B2 and three conditions)*

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Why you:** direction — whether the designer takes on documents, state-change triggers and value rules (and which part AEF owns) is product direction; and `fw inception decide` is operator-only
  **Steps:**
  1. Run: `fw task review T-1363` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Each of greenfield's seven needs maps onto a BPMN element the designer already keeps, or onto a term AEF owns, and
  every gap on 832's side is a bounded build (display or check, no new modelling language).
- A real map proves it end to end: WT-01 converted, validated and saved without loss.
- The 832 builds are testable on synthetic fixtures and change a save only where they say so.

**NO-GO if:**
- The needs require a new modelling language or a designer redesign.
- The pattern holds only for WT-01 (nothing general to build).
- The value of the remaining builds does not justify them, given what 0.36.0 already shows.

**Evaluation (2026-11-02):**
- **GO 1, met:** see IW-2. Needs 1, 2, 6, 7 are standard BPMN. Needs 4, 5 and the term for need 3 are AEF's (T-4991).
  832's gaps are two bounded builds (below).
- **GO 2, met:** wt01-io-v12, 0 errors, every count kept on save (greenfield on 0.35.0, msg 8f386e96).
- **GO 3, met** for what is built (T-1365 and T-1366: synthetic fixtures, legs 222/223, a save changed only as
  announced). It is planned the same way for the rest.
- **NO-GO:** none applies. Generality is not yet proven on a second map; that is A4, made a condition below rather
  than a reason to stop.

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

**Recommendation:** GO, for 832's part only: show and check what cross-system maps already carry. The shared vocabulary
stays with AEF (T-4991).

**Rationale:**

The exploration answered its question with a real map. Greenfield's WT-01, a sales process across five systems, fits
standard BPMN plus the mapping v1.1 io once instructions, screen states, documents, triggers and system events are
written by rules A-F, and value rules live in the producer's ontology. What was missing on 832's side was display and
checking, not modelling. Two of those gaps are already closed in 0.36.0:
- conditional and signal triggers shown by kind (T-1366);
- value rules in the io panel (T-1365).

Two bounded gaps remain, each a display or a check on standard data:
- **B1: draw documents** (data objects with their dataState and associations; today kept but invisible, need 1);
- **B2: a catalog check in the validator**: a field's object must equal its io's typeRef, and an aef:expect must not
  contradict the attribute's shape (error) or merely repeat it (warning), per T-4415 C. This is A3's check, which found
  15 real errors in WT-01.

Everything else waits for AEF's vocabulary (T-4991): decision and proof status per step (need 4), keys between systems
(need 5), and the user-started system action (need 3). Until then the interim forms stay (Decision:, Keys:, Open: lines;
match rows; the click step plus system step pattern).

**Conditions of the GO:**
1. B1 and B2 are separate build tasks, each tested on a synthetic fixture that is not WT-01 (this tests A4).
2. No designer build on needs 3, 4 or 5 before AEF's T-4991 decides.
3. Client data never enters the repo.

**Evidence:**

- Research artifact: `docs/reports/T-1363-cross-system-workflow-primitives.md` (findings, the needs table, the
  measurements, the dialogue log).
- WT-01 conversion and reviews: T-1361. Final map wt01-io-v12 sha 67d145d9…: 0 errors on 0.35.0 rules, and the catalog
  cross-check is clean apart from two by-design cases. The map is kept in ignored build/peer-data/greenfield/.
- Value rules as SHACL shapes: greenfield harvested 86 of 105 from the systems' metadata (msg 0d0d8631). One correction
  of a hand-typed picklist.
- Field-object check: 15 real mismatches found and fixed (msg ef1f148e).
- Shipped: designer 0.36.0 (job 117, tag designer-v0.36.0 on 37f992fe4) with T-1366 (leg 222) and T-1365 (leg 223),
  both reviewer-green.
- Greenfield on 0.35.0 in its real setup: WORKS, every count kept on save (msg 8f386e96).
- AEF: vocabulary inception T-4991 (msg 4150db95); 0.36.0 re-pin T-5015 (msg 89a7bd06).

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

<!-- Filled at completion via: fw inception decide T-1363 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-01T20:41:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
