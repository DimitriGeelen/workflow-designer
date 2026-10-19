# Workflow Designer 0.24.0 — release notes

**Since:** `designer-v0.23.0` (2026-10-18) · **Minor: third-party maps lose less on save; two gateway rules become
warnings.** Includes everything in 0.23.0.

## Saving keeps what a map brought

Three things a save used to destroy in maps the designer did not write. All three were reported by
aef-greenfield-test on its corpus (their T-240, T-276).

- **Extra attributes on step inputs and outputs are kept (T-1220).** `<aef:input>` / `<aef:output>` attributes beyond
  `name`, `type` and `required` (for example `ref`, `role`, `cardinality`, `dataType`) are written back unchanged, in
  their order. Nothing reads them yet: AEF is defining them for mapping-v1.1 (AEF T-4415). A map without such
  attributes saves exactly as before.
- **Standard link events keep their pairing (T-1217).** A link throw or catch marked with
  `<bpmn:linkEventDefinition id name>` keeps that element on save, and its name fills the designer's Link ID when no
  `aef:link` gives one. Before, the save dropped the element and the pairing between throw and catch was lost.
  Maps the designer authored are unchanged: they keep `aef:link` only.
- **An unnamed start or end event stays unnamed (T-1218).** The designer used the element id as its name, so the
  canvas showed "StartEvent_1" and the save wrote `name="StartEvent_1"` back. Now the label is empty and the save
  writes no name. Element ids do not change: the event's slug is carried as `<aef:meta slug>` while it has no name.
  Unnamed tasks and gateways still show their id, so an empty box cannot get lost on the canvas.

## Validator

- **The exclusive-gateway arity rules are warnings now, and renamed (T-1212; operator decision 2026-10-19).** An
  exclusive gateway with fewer than two outgoing flows that does not converge (1-in/1-out, or 0 out) is still reported,
  but no longer fails the check: nothing requires it (mapping-v1 §3 has no MUST/SHALL there, BPMN admits the shape, and
  the dialect axis classes it CONVENTIONAL). **Id map, for anything that stores finding ids:** `E-GW-OUTGOING` →
  `W-GW-OUTGOING`, `E-XML-GW-OUTGOING` → `W-XML-GW-OUTGOING`. **For AEF:** a check that FAILED on such a gateway now
  passes with a warning (exit 1 instead of 2). The finding text and the converging-gateway exemption are unchanged.
  The kit's `CONFORMANCE.md` lists both as WARN; `AUTHORING.md` names the new id.

## Designer

- **The element details view opens at the top every time (T-1209).** Reopening it kept the previous scroll position;
  edits inside it still keep your place.

## What changes in stored maps

- Third-party maps with unnamed start/end events: on the next save the id-as-name disappears and
  `<aef:meta slug="…">` appears on those events. No element id changes.
- Third-party maps with native link definitions: the definition is now written back (it was dropped before).
- Nothing else: maps the designer authored save byte-identically.

## Re-test

1. Open `tests/fixtures/third-party/zeebe-service-task.bpmn`: the start and end circles have no label; their grey
   display ids read `lan_start_startevent` and `lan_end_event`, as in 0.23.0.
2. Open a map whose link throw carries `<bpmn:linkEventDefinition name="X">`, save, and View XML: the definition is
   there, and the node's Link ID reads `X`.
3. Add `ref="sfdc:Opportunity.OwnerId"` to an `<aef:input>`, open, save: the attribute is still there.
4. Validate a map with a one-way exclusive gateway: a `W-XML-GW-OUTGOING` warning, no error.
