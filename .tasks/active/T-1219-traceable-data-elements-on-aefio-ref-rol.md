---
id: T-1219
name: "Traceable data elements on aef:io (ref, role, cardinality, business types, keep unknown aef: attributes) for aef-greenfield-test T-276"
description: >
  Inception: Traceable data elements on aef:io (ref, role, cardinality, business types, keep unknown aef: attributes) for aef-greenfield-test T-276

status: captured
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-19T16:56:20Z
last_update: 2026-10-19T16:56:20Z
date_finished: null
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
---

# T-1219: Traceable data elements on aef:io (ref, role, cardinality, business types, keep unknown aef: attributes) for aef-greenfield-test T-276

## Problem Statement

aef-greenfield-test (their T-276, owner GO 2026-10-19) generates each step's inputs and outputs from its ontology as
traceable fields (`system:Object.field`, e.g. `sfdc:Opportunity.OwnerId`) and wants them on `aef:input`/`aef:output`
as `ref`, `role`, `cardinality` and a business data type. The designer's save writes only `name`, `type`, `required`,
so anything else is destroyed on the first save: the consumer cannot round-trip its own maps through the designer.
Why now: the consumer is building the generator this month and asked before we build anything.

## Hypothesis

We believe that keeping unknown `aef:` attributes on `aef:input`/`aef:output` through open and save, and adding
designer fields only for what AEF's v1.1 revision (T-4415) defines,
we will achieve a designer that round-trips a consumer's traceable data elements without inventing a dialect of its own.
We will know that we are successful when we see `tools/_t1220-io-extra-attrs-cdp.mjs` green in the bridge suite (an
input carrying ref/role/cardinality/dataType plus an unknown attribute saves them back unchanged, twice) and no
designer field for those attributes exists before T-4415 is ruled on.

## Assumptions

- A-1: AEF does not object to the designer preserving attributes it does not define. **Validated** (AEF msg 42018c4e).
- A-2: the new fields belong in the shared standard, not in a designer-only extension. **Validated** (AEF filed T-4415
  for mapping-v1.1, msg 42018c4e; adopted the requester's counter-points, msg e9f02fa0).
- A-3: preserving the attributes changes no committed map. **Validated**: no `.bpmn`/`.golden`/`.xml` in the repo
  carries an attribute beyond name/type/required on aef:input/aef:output (survey, T-1220).

## Open Questions

- **IW-1: Does the standard allow unknown `aef:` attributes on `aef:input`/`aef:output`, and does our validator flag them?**
  confidence: 3
  disposition: answered
  rationale: v1 does not define them, but AEF has no objection to preserving them (msg 42018c4e); built as T-1220,
  which adds no validator rule.
- **IW-2: Which of ref/role/cardinality/dataType does AEF want in the standard, and in what shape?**
  confidence: 3
  disposition: answered
  rationale: all four, as optional attributes, dataType separate from type, role per input/output (AEF T-4415,
  msgs 42018c4e, e9f02fa0); the revision itself is AEF's operator's ruling.
- **IW-3: What does the designer show for them (panel fields, read-only, hover)?**
  confidence: 1
  disposition: deferred
  rationale: waits for AEF's operator to rule on T-4415; a build task is filed when the ruling exists. The CURIE
  prefix → URL map for the hover link is in v1.1 scope (msg 53eb5724).

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

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: whether and how the designer keeps and later shows traceable data elements on `aef:io`; the round-trip property
(built as T-1220). OUT: defining the attributes (AEF's v1.1, T-4415); any validator rule for them; the requester's
ontology and generator; reading `aef:io` in AEF's compiler (part of T-4415).

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
- [ ] Go/no-go judged by an independent reviewer, who may escalate to the operator (inception-decision class,
  reviewer-judgeable per `fw task delegate T-1219 --dry-run`). Any change to the frozen standard is decided with AEF, not here.
  **Steps:**
  1. Run: `fw reviewer judge T-1219 --criterion 1` (or `fw task review T-1219` to read recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The round-trip half can be built without interpreting anything and without changing committed maps (it was: T-1220)
- The field half has an owner and a path in the shared standard (it has: AEF T-4415)

**NO-GO if:**
- AEF objected to preserving undefined attributes, or wanted the fields kept out of the standard (neither happened)
- Supporting the fields would force a designer-only dialect

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

(Filed: GO on exploring. Updated 2026-10-19 once exploration finished.) The question was whether 832 should support
traceable data elements on `aef:io` for a consumer that generates them from its ontology. The answer splits in two,
and both halves are settled with the parties who own them. Keeping unknown `aef:` attributes through a save is a
round-trip property the designer should have anyway; AEF has no objection ("preserving is not interpreting"), so it
was built as T-1220 and is planned for 0.24.0 (T-1223, not yet released). The new fields themselves (`ref`, `role`, `cardinality`, `dataType`) belong
in the shared standard, not in 832 alone: AEF filed inception T-4415 for a mapping-v1.1 revision, adopted the
requester's three counter-points, and put a CURIE prefix → URL map in scope. 832 builds designer fields only after
AEF's operator rules on T-4415; that build task is filed when the ruling exists.

**Evidence:**

- AEF msg 42018c4e: v1 does not define extra attributes on aef:input/aef:output; no objection to preserving them now;
  AEF's intake already carries aef:io verbatim (T-4387); their compiler does not read aef:io today.
- AEF msg e9f02fa0: T-4415 adopts dataType string/boolean, currencyCode vs amount, role per input/output; revised set
  id | reference | string | boolean | date | datetime | decimal | amount | currencyCode | percent | picklist.
- AEF msg 53eb5724: the CURIE prefix → URL template map is in v1.1 scope (validation and our hover link).
- T-1220 (44ba28d0): extras kept in order, escaped; guard 6/6, red before the fix; no committed map changes.
- aef-greenfield-test msg 615dbee9: aligns its BusinessDataTypeScheme to the revised set; waits for the T-1220 release.
- Research artifact: docs/reports/T-1219-traceable-aef-io.md (dialogue log of all of the above).

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

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

<!-- Filled at completion via: fw inception decide T-1219 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->
