---
id: T-1093
name: "Greenfield T-172 #4: Export menu — which formats (PDF, SVG, PNG 1x/2x/4x, Camunda-compatible
  BPMN 2.0 with DI, optional JPEG/GIF, steps-per-lane CSV/Markdown)"
description: >
  aef-greenfield-test T-172 item 4. Many formats, several independent deliverables:
  scope and order them (one build task per format) before building. Camunda Modeler
  5 / Camunda 7-8 must open the BPMN with layout, no required custom extensions.

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-08T08:38:37Z
last_update: '2026-11-15T09:04:46Z'
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-11-15T09:04:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 3
      D2: 3
      D3: 3
      D4: 3
      F-RECALL: 3
      F2: 3
      F4: 3
      F3: 3
      F1: 3
    rationale: D1=3 (voi:decision-with-alternatives~'go/no-go'); D2=3 
      (voi:decision-with-alternatives~'go/no-go'); D3=3 
      (voi:decision-with-alternatives~'go/no-go'); D4=3 
      (voi:decision-with-alternatives~'go/no-go'); F-RECALL=3 
      (voi:decision-with-alternatives~'go/no-go'); F2=3 
      (voi:decision-with-alternatives~'go/no-go'); F4=3 
      (voi:decision-with-alternatives~'go/no-go'); F3=3 
      (voi:decision-with-alternatives~'go/no-go'); F1=3 
      (voi:decision-with-alternatives~'go/no-go')
    rubric_sha: e4a00f38e801
---

# T-1093: Greenfield T-172 #4: Export menu — which formats (PDF, SVG, PNG 1x/2x/4x, Camunda-compatible BPMN 2.0 with DI, optional JPEG/GIF, steps-per-lane CSV/Markdown)

## Problem Statement

People and projects need to get workflows **out of** the designer in the formats their tools and readers use, and
**into** it from the tools they already have. Greenfield asked (their T-172 #4, 2026-10-08) for an export menu: PDF,
SVG, PNG at 1x/2x/4x, Camunda-compatible BPMN 2.0 with layout, optional JPEG/GIF, steps-per-lane CSV/Markdown. On
2026-11-15 the operator widened it to both directions:
- **Export:** BPMN, Camunda, PDF, Word, Visio, Mermaid, Excel, CSV.
- **Import:** Visio, BPMN, Camunda, Excel, CSV.
Operator, verbatim: "can we add export formats like bpmn camunda pdf word visio mermaid … think of it as an option and
then also we want to be able to import stuff like … visio bpmn camunda", "Maybe also Excel, good import and export
format", and CSV. Why now: O-5 (many projects, each with its own designer) means each project arrives with its own
tools; formats are how the designer meets them.

The inception answers ONE question: **which formats, in which direction, in what order, and with what fidelity
promise for each** (lossless, view-only, or lossy bridge), so each becomes its own small build task.

## Hypothesis

We believe that offering each requested format as an in-browser import or export with a stated fidelity promise,
we will achieve a designer that every project can bring its existing workflows into and take its maps out of, in the
tools it already uses,
We will know that we are successful when we see each requested format either built (its build task closed with a
round-trip or render test) or recorded as NO-GO with its reason, and no import that loses data without saying so.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1093 -->
- A1: the designer stays one standalone HTML file (PD-305); every format is produced/read in the browser, offline,
  with no service and no large runtime dependency, or the format is out.
- A2: BPMN 2.0 with DI is the one lossless interchange format (O-6); every other format is either a **view**
  (PDF, Word, PNG/SVG, Mermaid) or a **lossy bridge** (Visio, Excel, CSV) whose loss must be stated, never silent.
- A3: Camunda is "BPMN 2.0 that Camunda Modeler opens with layout and no required custom extensions", not a separate
  format; Camunda 7 vs 8 differ mainly in execution attributes, which the designer does not own.
- A4: Visio (.vsdx) is a zipped XML package readable and writable in the browser, but its shapes carry no BPMN
  semantics; import is shape-to-element mapping with stated loss.
- A5: Excel/CSV are tabular, one row per step (id, name, lane, type, inputs/outputs, next steps). Export is easy;
  import must rebuild flows and layout, so it needs auto-layout (Clean) and loses geometry.

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
- **IW-1: What does the designer already import and export today (formats, fidelity, where in the code)?**
  confidence: 0
  disposition: (open)
  rationale: (to measure in src/ and tools/)
- **IW-2: For each requested format, can it be produced/read in the browser, offline, inside one HTML file — and at
  what size cost?** (PDF, Word .docx, Visio .vsdx, Excel .xlsx, CSV, Mermaid, Camunda BPMN)
  confidence: 0
  disposition: (open)
  rationale: (spike per format: library or hand-written, bytes added)
- **IW-3: What is each format's fidelity promise: lossless (BPMN), view (PDF/Word/PNG/SVG/Mermaid), or lossy bridge
  (Visio/Excel/CSV), and what exactly is lost?**
  confidence: 0
  disposition: (open)
  rationale: (a loss table per format)
- **IW-4: Who needs which format first?** Greenfield asked for PDF/PNG/SVG/Camunda/CSV; the operator added Word,
  Visio, Mermaid, Excel and imports. AEF consumes BPMN only.
  confidence: 0
  disposition: (open)
  rationale: (ask Greenfield and AEF; the operator rules the order)
- **IW-5: For imports, how is a map with no layout or no BPMN semantics (Excel/CSV/Visio) turned into a valid,
  readable map?** (auto-layout through Clean; mapping table shape-to-element; validator run after import)
  confidence: 0
  disposition: (open)
  rationale: (spike on one Visio file and one spreadsheet)

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->
Research artifact: `docs/reports/T-1093-import-export-formats.md`. About two sessions in total.
1. **Inventory (1 h, IW-1):** what exists now (BPMN import/export, SVG, YAML bridge, the T-340 DI work).
2. **Feasibility spikes (2-3 h, IW-2/IW-5):** one small in-browser proof per new format, each measured in bytes added
   to the single file: CSV and Mermaid (hand-written), Excel (.xlsx is zipped XML), Word (.docx is zipped XML),
   PDF (print-to-PDF vs a library), Visio (.vsdx is zipped XML), Camunda (open our BPMN in Camunda Modeler).
3. **Fidelity table (IW-3):** per format and direction, what survives and what is lost, tested on 3 corpus maps.
4. **Ask the users (IW-4):** Greenfield (their original request) and AEF; then a proposed order for the operator.
5. Output: one build task per format and direction, ordered, each with its fidelity promise.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

**IN:** which formats, which direction, what order, what fidelity each promises; small feasibility spikes.
**OUT:** building the formats (one build task each after GO); anything needing a server or a cloud converter
(PD-305 standalone); Camunda execution attributes (the designer does not execute, out_of_scope).

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
  **Why you:** direction — which export formats the designer offers, and in what order, is product direction; and `fw inception decide` is operator-only
  **Steps:**
  1. Run: `fw task review T-1093` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings
  **Reviewer escalation (V-20261021-8b0be955, reviewer-judge-t-1093-r3-851442bc6cae:reviewer, rung rung-3-termlink-single-reviewer):** Product-direction call (which export formats, in what order) and fw inception decide is operator-only: human must decide. Before deciding, note the inception sections (problem statement, assumptions, IW questions, tailored go/no-go criteria) are empty template; settle scope of optional JPEG/GIF and CSV/Markdown, PDF fit vs multi-page, Camunda 7 vs 8 target.

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO (per format) if:**
- it can be produced or read in the browser, offline, inside the single file, at a stated size cost; and
- its fidelity promise is stated (lossless, view, or lossy bridge with the loss listed); and
- a named user needs it (Greenfield, AEF, or the operator).

**NO-GO (per format) if:**
- it needs a server, a cloud converter or a dependency too large for the single file; or
- its loss cannot be stated precisely (a silent lossy import is worse than none).

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

**Rationale:** Owner request with a concrete list (T-172 README item 4). The designer already renders the map as SVG in the browser, so SVG and PNG (rasterised SVG at 1x/2x/4x) are cheap first slices; Camunda-compatible BPMN builds on the existing BPMN export plus standard bpmndi; PDF (fit/multi-page) is the costliest and goes last. GO is to scope and order formats into one build task each, not to build in this inception.

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

<!-- Filled at completion via: fw inception decide T-1093 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-15T09:04:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
