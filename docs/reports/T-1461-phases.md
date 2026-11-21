# T-1461 — Phases across a map (Greenfield's owner's request)

Inception, 2026-11-21. Question: should the designer draw (and later edit) phases across a horizontal map, stored as
`bpmn:group` with `categoryValueRef`?

## The request (Greenfield msg d5819d5e, 2026-11-20, in Dutch; summarised)

Their owner wants to divide a process flow into PHASES:

- (a) vertical divider lines through all lanes at the phase boundaries;
- (b) above the pool, per phase, a bracket with a name and subtitle (e.g. "2 Configuratie · stap 4-6");
- (c) optionally a second row of brackets: another division over the same steps (for them: the Salesforce phase, where
  one Salesforce phase spans several Tacton steps);
- (d) optionally a light background tint per phase.

It must not change the order of steps or the lanes: it is a division along the x axis of a horizontal map. They
suggest BPMN 2.0's `bpmn:group` + `categoryValueRef` (visual grouping, not a process element) so the file stays valid
`.bpmn`. They drew it themselves as SVG/HTML from our DI on their workshop map (ws-2026-11-06-offerte-tot-order;
our fixture `tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn`, 20 tasks, 4 lanes): 5 phases at
x = 560, 1016, 1604, 2080; brackets between the notes and the pool.

Their questions: 1) does this fit our direction, and if so as `bpmn:group` or an own aef extension? 2) if not, can we
at least keep `bpmn:group` unchanged on save (as with notes)? No hurry.

## Findings

### F1 — Groups are already kept byte-for-byte (IW-2; answers their question 2)

`captureProcessLevelKept` (src/aef-workflow-designer.html, ~line 15890; T-1326/T-1327) keeps every `bpmn:group` in the
process or the collaboration, its DI shape, and the root `bpmn:category` elements its `categoryValueRef` names, and
writes them back unchanged. The open notice says "N groups kept unchanged and saved back, not shown yet" (~line
11315). Pinned by the third-party byte-identity golden `tests/fixtures/third-party/kitchen-sink.bpmn` (3 groups).

So Greenfield's fallback already works today. What is missing is only drawing, and later editing.

Limit of the keep: the group's DI bounds are kept verbatim. If a person moves steps in the designer, a kept group does
not follow them. For a phase that is wrong (the bracket would point at the old x), so a drawn phase must be tied to
its steps, not to its stored rectangle (F4).

### F2 — Standard BPMN fits; no aef-only storage needed (IW-1)

BPMN 2.0 (Artifacts, Group): a Group is a visual grouping; it has no effect on the flow, and its meaning is given by
the CategoryValue it references. A category with several values maps exactly onto "one row of phases"; a second
category is a second row (request c). Every BPMN tool keeps or draws groups (bpmn.io draws them as dashed rounded
rectangles), so a map with phases stays a valid `.bpmn` that other tools open.

One thing standard BPMN does not say: that a group is a *phase band* rather than any box. F3 shows why that matters.

### F3 — Not every group is a phase (IW-1, IW-3)

The kitchen-sink groups (bpmn.io-style) are boxes inside one lane (bounds x 190..1400, heights 120–150, in a lane of
height 1160), labelled "Tasks", "Gateways", "Events". Drawing them as full-height phase bands would be wrong.

Proposal: a category is a phase row when it carries a small aef marker in `bpmn:extensionElements` (e.g.
`<aef:phases row="1"/>`), which other tools keep and ignore. Without the marker, a group counts as a phase only when its
bounds span the pool's full height (Greenfield's own drawings and files from other tools); any other group stays a
kept, undrawn group as today (or later is drawn as a plain dashed box, a separate question).

### F4 — A phase is a range of steps, its rectangle is derived (IW-3)

Their subtitle "stap 4-6" already says it: a phase is a contiguous range of steps along the flow. The designer stores
step positions in DI; a phase's boundaries are taken at the midpoint between the last step of one phase and the first
of the next, and its group rectangle (x range × full pool height) is recomputed from its steps on save. On import, a
group's members are the steps whose centres fall inside its bounds.

This keeps the request's own rule: phases never change order or lanes; they follow the steps.

### F5 — Saved bytes and routing (IW-4)

- No corpus map (`examples/aef-processes/`) and no other fixture besides kitchen-sink contains a group
  (`grep -rlE '<(bpmn:)?group[ >]' --include=*.bpmn`): for every map without phases, drawing phases changes nothing,
  on screen or on save.
- Brackets go above the pool, in the band where notes are drawn (T-1447); dividers and tints are behind the lanes.
  Neither touches node positions, so routing is unchanged (dividers are not obstacles: they cross every lane by design).
- T-423 (saved bytes must not depend on the screen) holds: the phase rectangle is computed from step DI, not from the
  canvas.
- Slice 1 (draw only) writes kept groups unchanged, so kitchen-sink's golden stays identical. Slice 2 (edit) rewrites a
  phase's bounds only when its steps moved, or when a person edited phases.

### F6 — AEF's view (IW-5)

Not asked yet. AEF stores the maps the designer writes; groups are already kept for them (F1). Slice 1 changes no
file AEF stores. Slice 2 (a person creates phases) adds `bpmn:group`/`bpmn:category` and the aef marker to maps AEF
stores, so AEF is asked before slice 2 starts, with the exact XML.

## Proposed slices on GO

1. **Draw phases from the file** (S): full-height dividers through all lanes, a named bracket per phase above the pool,
   a second row for a second phase category, the optional tint (a `bpmn:group` colour, or a default light tint per
   phase). Read-only; saved bytes unchanged. Greenfield sees their workshop map with phases as soon as their file
   carries groups.
2. **Edit phases** (M): "Phase from selected steps", rename, subtitle, move a boundary by one step, delete; a second
   row; written as `bpmn:group` + `bpmn:category` + the aef marker, bounds derived from the steps. After AEF's yes.
3. Export: PDF/PNG/SVG carry the bands (follows from 1, since they render the same map).

## Dialogue Log

- 2026-11-20: Greenfield's request arrives (msg d5819d5e); filed as T-1461, EXPLORING.
- 2026-11-21: operator asks for the inception's link; the agent writes the findings and the recommendation.
