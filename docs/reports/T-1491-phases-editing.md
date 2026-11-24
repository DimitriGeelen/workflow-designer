# T-1491 — Editing phases in the designer (inception)

**Status:** exploring. **Question:** can a person make and change a map's phases in the designer, in bounded slices,
writing standard BPMN that the drawing slice (T-1473, 0.47.0) reads back unchanged?

**The request (operator, 2026-11-24, in session):** "I want to be able to delete them or switch them on and off and I
want to be able to add them myself … in the left panel these brackets I want to be able to add them and add the
documentation … configure them … drag them to the left, to the right, and the configuration where the phase ends and
starts." And: "create a persona and a user story and try to run the tool from a persona and a user story doing this."

Builds on the phases design `docs/reports/T-1461-phases.md` (F1–F6; slice 2 sketched there as "Edit phases").

## Persona

**Mira, process facilitator** at a manufacturer that sells configured products. She runs the workshops where sales,
configuration, ERP and production agree how an order flows. She knows the process and the business words; she is
not a BPMN specialist and does not edit XML. She works on a laptop (1440 px), sometimes on the meeting room screen
(1920 px), and projects the map while people talk. What she wants from phases: everyone in the room sees at a glance
which steps belong to "Offerte & onderhandeling" and which to "Order", and the phase carries the agreements made
about it.

## User story

> As a facilitator preparing a workshop, I want to divide the order-to-delivery map into the phases we agreed on,
> write down what each phase means, and adjust where a phase starts and ends when the room disagrees, so that
> participants see at a glance which steps belong to which phase and what was agreed about it.

**Scenario (the hypothesis' measurable signal):** on a map without phases (Greenfield's sample with its groups and
categories stripped, so the steps are real):

1. Find phases in the left panel and add a phase row ("Fase").
2. Split it into 5 phases at the agreed step gaps and name them (Opportunity, Configuratie, Offerte & onderhandeling,
   Order, Productie & service).
3. Add a second row ("Fase in Salesforce") with its 6 stages.
4. Write the agreements on "Offerte & onderhandeling" (its documentation).
5. The room decides "Firm Ready" belongs to Offerte, not Configuratie: move that boundary one step.
6. Hide the second row while projecting; show it again.
7. Delete one phase of the second row.
8. Save; reopen the file. The phases, names, boundaries and documentation are as she left them, and 0.47.0's reader
   draws them the same.

## Walkthrough on 0.47.0 (run as Mira, 2026-11-24)

A one-off CDP script drove `dist/aef-workflow-designer-0.47.0.html` at 1440 px through the scenario's first moves.

| Step | What Mira does | What 0.47.0 does |
|---|---|---|
| 1 | Looks for phases in the left panel | Sections: Tool, Events, Tasks, Gateways, Handoffs, Typed events, Lanes. **No Phases section**; the panel ends at "Add Lane" (`T-1491-shots/1-left-panel-bottom.png`) |
| 2–4 | (on the map that has phases) clicks a phase name to rename it or add its documentation | **Nothing is selected**: the phase layer has `pointer-events: none`; the panel stays on "workflow" (`T-1491-shots/2-click-phase.png`) |
| 2–4 | right-clicks a phase | **No menu** |
| 6 | looks for a way to hide a row | **No control** anywhere on the page mentions phases |
| 5, 7 | drag a boundary; delete a phase | not reachable: nothing about a phase can be selected |

Result: the scenario stops at step 1, as expected for a read-only slice. Every step is outside the designer today
(Greenfield draws its phases in another tool and imports them).

**What the designer already offers for the nearest thing, lanes:** a "Lanes" section in the left panel ("Add Lane"),
a lane selected on the canvas gets its own panel (Name, ID, Abbreviation, Authority, Authoring default) with delete.
Phases are the vertical counterpart of lanes, so Mira will look for them in the same places.

## Proposed design, step by step (IW-1)

```
 left panel                canvas                                          right panel (a phase selected)
 ───────────               ───────────────────────────────────────────    ─────────────────────────────
 LANES                     Fase in Salesforce │ 1 Qualif. │ 2 Needs …  │   phase
  ⊞ Add Lane               Fase               │Opportunity│Configuratie│   Fase · Offerte & onderhandeling
 PHASES                    ┌──────────────────┼───────────┼────────────┤   Name   [Offerte & onderhandeling]
  ⊞ Add phase row          │ SALESFORCE       │  ○→[ ]→[ ]│  [ ]       │   Row    [Fase           ▾]
  ⊞ Add phase   (click a   │ TACTON           │           ┆ [ ]→[ ]    │   Documentation
     gap between steps)    │ …                │           ┆            │   [ Agreed: discount above … ]
                           └──────────────────┴───────────┴────────────┘   × delete phase
```

1. **Left panel → Phases** (under Lanes, same look): **Add phase row** makes a row (a `bpmn:category`) with one phase
   spanning the whole pool, named "Fase" / "Phase 1", and selects it. **Add phase**, then a click on the canvas, splits
   the phase under the click at the step gap nearest the click (the same click-to-place pattern as every palette item).
   Mira can also drag "Add phase" onto a gap.
2. **Select a phase** by clicking its bracket or name (the layer takes clicks where it is drawn; everything else as
   today). The right panel shows **phase**: Name, Row, **Documentation**, delete. Renaming updates the bracket at once.
3. **Select a row** by clicking its row label (T-1498): Row name, **Visible** (on/off), Dividers through the lanes
   (row 1 only), delete row.
4. **Documentation** is a text field on the phase, shown the same way as a step's documentation (T-1492): one block per
   line prefix (Rule:, Open:, Decision: …) when read, plain text when edited.
5. **Move a boundary:** drag a divider (row 1) or the shared edge of two brackets left or right; it **snaps to the
   gaps between step columns** (IW-2), with the two phase names updating live. Steps never move.
6. **Hide a row:** the row's Visible switch, and one toolbar switch for all phases (beside the lens control).
7. **Delete** a phase (its neighbour takes its range) or a row (all its phases), from the panel or with Delete.
8. **Save** writes each phase as standard BPMN (IW-4/IW-5); opening it again, in this designer or in 0.47.0, draws
   the same phases.

## Open questions, proposed answers

- **IW-2 (boundary: free or by steps):** by step gaps. T-1461 F4 makes a phase a range of steps: its rectangle is
  derived from its steps, and a boundary sits at the midpoint between the last step of one phase and the first of the
  next. Dragging snaps to those gaps; a free x would let a boundary cut through a step and break that rule. When steps
  move (Clean layout, dragging a step), the boundaries follow the steps.
- **IW-3 (on/off: view or file):** a view setting, remembered per map in the browser, not written to the file. Hiding
  phases is about what is projected now, not about the process; writing it would change saved bytes for a viewing
  choice and make other tools disagree on whether the phases "exist". To settle with the operator at the decision.
- **IW-4 (documentation in the file):** `<bpmn:documentation>` inside the `bpmn:group`, standard BPMN (tBaseElement),
  kept by every tool that keeps groups; Greenfield's own reader can show it.
- **IW-5 (the XML a made phase writes):**
  ```xml
  <bpmn:category id="Category_fase" name="Fase">
    <bpmn:categoryValue id="CategoryValue_f3" value="Offerte &amp; onderhandeling"/>
  </bpmn:category>
  <!-- in the process -->
  <bpmn:group id="Group_f3" categoryValueRef="CategoryValue_f3">
    <bpmn:documentation>Rule: discount above 10 % needs sales lead approval</bpmn:documentation>
  </bpmn:group>
  <!-- DI: full pool height, x range from the steps (T-1461 F3/F4) -->
  <bpmndi:BPMNShape id="Group_f3_di" bpmnElement="Group_f3"><dc:Bounds x="1168" y="60" width="588" height="680"/></bpmndi:BPMNShape>
  ```
  The same shape Greenfield already writes (msg 6ae1899a), so 0.47.0 reads it back by its full-height rule; no aef
  marker is needed (F3 proposed one only for groups that do not span the pool).
  **AEF's answer (2026-11-24, msg 581bf5d2, their T-5381):** yes in principle, this is the right form; but their side
  is not ready: `tools/corpus_spec.py parse_map` hard-refuses any map containing `<bpmn:group>` ("unsupported BPMN
  element", deliberately since their T-2614, data-loss class), and a root `<bpmn:category>` is not read, so it is lost
  on `fw corpus spec regenerate`. 0 maps they store carry either. They will confirm on the thread when T-5381 (group
  with documentation and category carried verbatim, byte round-trip test) is in a be-tag. Until then, no slice lets a
  person make phases in a map AEF stores.
  **Update (2026-11-24, msg 75ada896):** T-5381 done on AEF's bleeding-edge (groups with documentation, categories pass
  their corpus tooling and regenerate byte-identically as elements; groups placed after the last flow on regenerate).
  Open: their regenerate writes no DI, so group shapes are lost, and the designer draws a phase only from its shape.
  Asked when maps are regenerated and whether shapes can be carried (our preference) or the designer should also
  record a phase's first and last step (msg on the same thread).
  **Answer (msg 82a0b44b):** regenerating a stored map is not routine; only the manual `fw corpus spec prove` does it.
  AEF agreed on plain BPMN with the group shapes carried through regenerate (their T-5387, no aef extension); until it
  lands, `prove` refuses a map with `bpmn:group` instead of undrawing it. T-5387 does not block phase creation; the
  be-tag carrying T-5381 still does.
- **IW-6 (the band above the pool):** phase rows sit directly above the pool, each row labelled at its left in the
  lane-header column (T-1498); notes above the pool are placed above the phase rows, and their associations route
  around the row labels (T-1499). T-1498 and T-1499 come before or with the first editing slice.

## Proposed slices on GO

| Slice | What Mira can do after it | Scenario steps | Writes the file? |
|---|---|---|---|
| A | select a phase or a row; rename; edit documentation; delete; row labels (T-1498) | 2 (names), 4, 7 | yes: names, documentation, removals on existing groups |
| B | Phases section in the left panel: add a row, add a phase at a step gap | 1, 2, 3 | yes: new category, values, groups, shapes |
| C | drag a boundary, snapping to step gaps; boundaries follow moved steps | 5 | yes: group bounds |
| D | show/hide per row and for all phases (view only) | 6 | no |
| — | notes and phase rows share the band above the pool (T-1499) | (all) | no |

**Order (after AEF's answer):** A and D first: they work on files that already carry phases (Greenfield's) and make
none. B and C (new phases, new bounds) after AEF confirms T-5381 in a be-tag.

Each slice ends with a browser leg (the scenario's steps it covers, plus a save read back by 0.47.0's reader),
screenshots at 1024/1440/1920 and a reviewer judgement, as T-1473 did. A map without phases saves byte-identically
throughout.

## Dialogue Log

- 2026-11-24 — operator: accept T-1474 as it is ("1 yes"); T-1492 in scope ("2 yes"); then the phases-editing request
  quoted at the top, and to try it from a persona and a user story first. The agent framed T-1491 (problem,
  hypothesis, IW-1..IW-6, go/no-go criteria), wrote the persona and story, and ran the walkthrough on 0.47.0.
