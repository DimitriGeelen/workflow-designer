# Workflow Designer 0.25.0 — release notes

**Since:** `designer-v0.24.0` (2026-10-19) · **Minor: structured step inputs and outputs (mapping v1.1) are shown and
kept; a business lens; event definitions survive a save.** Includes everything in 0.24.0.

## Structured inputs and outputs (mapping v1.1)

AEF's operator ruled the v1.1 io standard on 2026-10-21 (AEF T-4415; text `policy/standards/aef-bpmn-mapping-v1.1-io.md`,
AEF T-4548). This release is the designer's first slice of it (832 T-1249, under T-1242).

- **Shown, read-only (T-1249).** Under each `aef:input` / `aef:output` that carries v1.1 data, the io panel shows its
  `fieldRef`, `typeRef` or `schemaRef`, `conceptRef`, `role`, `operation`, `cardinality` and source/target system, and a
  compact list of its `aef:field` (with `aef:when`), `aef:expect` and `aef:example` children. A system taken from the
  step default or from a declared prefix is labelled "derived". The workflow panel gets a read-only **Mapping** section
  with `mappingVersion` and the `aef:prefixes`. Nothing new is editable yet (editing is the next slices); a v1 io looks
  exactly as before.
- **Kept byte-exactly on save (T-1249).** Three losses found while building it are fixed: an io with no `name` (for
  example only `typeRef` and `operation`) was deleted on save; the process-level `aef:meta` (where v1.1 puts
  `mappingVersion` and the prefix map) was dropped; an io block written on one line was re-laid out one item per line.
  An io block is now written back as read while its items are unedited. Checked on the standard's section-11 examples,
  AEF's corpus_spec round-trip cases, every tracked map with io (84) and aef-greenfield-test's VZN-T1: 0 bytes changed.
- **Child elements inside an io survive a save (T-1243).** 0.24.0 kept unknown io attributes (T-1220); a child element
  (an `aef:field`, an `aef:expect`, a foreign-namespace extension) was dropped. Now every child is kept verbatim, in
  order, adding no namespace declarations.

Guards: `tools/_t1249-v11-io-cdp.mjs`, `tools/_t1243-io-children-cdp.mjs`.

## Business lens (T-1241, T-281 slice 1)

- **A lens switch in the toolbar: All / Business / Logical / Technical.** A lens narrows the side panel, the details
  view and the canvas decorations (ids, io badge, constituents, authority markers, findings) at once. It never shows a
  field the project's field profile hides, and it is a view only: switching changes 0 bytes of the saved map.
- **The lenses are data.** The designer reads them from `GET /api/lens-definition`, the interim stand-in for AEF's
  shared lens file (AEF T-4402). Without a definition the switch offers only "All" and every field is shown, as before.
- **Toolbar fit.** The lens select shows the lens name behind a small lens icon, and the instance picker's
  unavailable label is now `instances: n/a` (was `instances: unavailable`), so the header stays one row at 1920 px and
  in Watchtower's 1894 px inline frame.

Guard: `tools/_t1241-business-lens-cdp.mjs`.

## Native BPMN event definitions survive a save (T-1222)

A save used to drop 46 of the 49 `*EventDefinition` elements in the third-party fixtures and flattened every
third-party `boundaryEvent` into a `serviceTask`. Now each definition is kept verbatim on its own host, with any root
`message`/`signal`/`error`/`escalation` it names; boundary events keep `attachedToRef`. A catch whose one definition is
timer, message or error takes that designer type. Guard: `tools/_t1222-event-definitions-kept.py`.

## What changes in stored maps

- **v1.1 maps** (with `mappingVersion="1.1"`, `aef:prefixes`, nameless io, or one-line io blocks): kept as written; under
  0.24.0 a save lost or reshaped them.
- **io with child elements:** kept (dropped before).
- **Third-party maps with event definitions or boundary events:** first save keeps them; their display ids differ
  from what 0.24.0 gave them (boundary events no longer count as numbered steps). Maps already saved by 0.24.0 keep
  their ids.
- **Nothing else:** maps the designer authored save byte-identically. No node id, field or finding id changes.
- **For anything that matches UI text:** the instance picker's unavailable state reads `instances: n/a`.

## Re-test

1. Open a map with a v1.1 io (the standard's section-11 example with `operation="upsert"`): the io panel shows the
   typeRef, operation and the field list with roles; save, then View XML: the io is unchanged.
2. Open `aef-task-lifecycle` with a lens definition served and choose **Business**: no technical badges, only business
   fields; switch back to **All** and export: identical to the export before switching.
3. Open `tests/fixtures/third-party/` maps with timer/message boundary events: they are boundary events after save.
