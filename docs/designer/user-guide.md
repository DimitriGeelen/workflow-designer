# AEF Workflow Designer — User Guide

How to use the editor. For the file format produced by the editor, see
[schema.md](schema.md). For implementation details, see
[architecture.md](architecture.md).

---

## 1. Modes

The editor has three modes, switched via the toolbar:

- **Select** (default) — click to select, drag to move, multi-select with
  shift-click or rubber-band drag
- **Connect** — click a source node, then click a target node to create an
  edge between them
- **Create** — set by clicking a palette item; the next canvas click places
  a node of that type

The status overlay shows the active mode. Press **Esc** to return to Select
mode from anywhere.

---

## 2. Working with nodes

### 2.1 Placing a node

Click any palette item on the left. The mode switches to Create for that
type. Click anywhere on the canvas to place. The node is assigned to the
lane its y-coordinate falls into.

After placement, the mode reverts to Select and the new node is selected.

### 2.2 Moving a node

In Select mode, click and drag any node. The node follows the cursor. While
dragging, the displayId remains stable (no flickering renumber); on release
it recomputes to reflect the new spatial position.

**Multi-node drag**: shift-click multiple nodes (or rubber-band them), then
drag any one. All selected nodes move together.

**Lane reassignment during drag**: drop a node in a different lane → its
`lane` field updates. The displayId's prefix changes to reflect the new
lane. Spatial seq recomputes within the new lane.

### 2.3 Deleting a node

Select it, press **Delete** or **Backspace**. Or click the trash icon in
the node's property panel header.

Edges connected to the deleted node are also deleted.

For multi-select: Delete removes all selected nodes (with confirmation if
more than one) and their connected edges.

### 2.4 Node properties panel

Click a node → properties appear on the right.

**BPMN section**:

- **Name** — display name, free text. Slug auto-updates when name changes
  (unless slug has been manually edited).
- **Slug** — short identifier, lowercase, alphanumeric and hyphens. Used in
  displayId. Editing this sets a "manual" flag so subsequent name changes
  don't clobber it.
- **Display ID** — read-only, shown in accent color. Updates live as name
  / slug / lane / position change.
- **UID** — read-only, dim mono. The internal stable reference. Useful for
  debugging; safe to ignore.
- **Lane** — dropdown of available lanes. Changing it reassigns the node
  and updates its displayId.

**AEF section** (fields vary by node type):

- **Tier** — action authority (0/1/2/3). 0 is read-only/observe; 3 is full
  autonomy.
- **Agent type** (serviceTask only) — `primary` | `termlink-worker` | `human`
- **Endpoint** — what executes this step. Free text; format depends on type.
- **Context reads** / **Artifacts writes** — comma-separated paths.
- **Triggered by** (startEvent) / **Emits** (endEvent) — event identifiers.
- **Decision input** / **Decision owner** (exclusiveGateway) — expression
  and authority for the routing decision.
- **Decision outputs** (userTask) — comma-separated enum of possible
  outcomes.

**I/O section**:

A typed data contract distinct from filesystem reads/writes. Each row is
one input or output with:

- **Name** — identifier
- **Type** — one of `string`, `number`, `boolean`, `ref`, `path`,
  `task_id`, `arc_id`, `list`, `object`
- **Required** (inputs only) — boolean

The header shows `n→m` where n = required inputs, m = outputs.

---

## 3. Working with lanes

### 3.1 Adding a lane

Three entry points:

1. Toolbar "+ Add Lane" button
2. The lane-palette icon in the left palette (drag onto canvas)
3. The "+ Add another lane" strip at the bottom of the pool

Newly created lanes get a default name and auto-derived `abbr`.

### 3.2 Lane properties

Click a lane header → properties appear.

- **Name** — display label
- **Abbreviation** — 3-char prefix used in node displayIds. Defaults to
  first three letters of name; editable. Enforced unique across the
  workflow. Editing this stops auto-update from name.
- **Authority** — dropdown: sovereignty / authority / initiative / external /
  none. Tints the lane background subtly.
- **Height** — pixel height of the lane band.

### 3.3 Reordering lanes

In the lane properties panel: up/down arrows to move the lane higher or
lower in the pool. Nodes inside move with the lane.

### 3.4 Resizing lanes

Hover the divider between two lanes; cursor changes to ns-resize. Drag to
adjust both lanes' heights (the upper grows / shrinks, the lower
counter-adjusts). Minimum 60 px, maximum 800 px.

Alternatively, use the height stepper in the lane properties panel.

### 3.5 Deleting a lane

Click the trash icon in the lane property panel header. A confirm dialog
appears since deletion would orphan any nodes in the lane. Confirm →
nodes are reassigned to the first remaining lane, or you can pick a
different target.

---

## 4. Working with edges

### 4.1 Creating an edge

Switch to **Connect** mode (toolbar). Click a source node, then click a
target node. The edge is created with `auto` ports on both ends.

Mode reverts to Select after the edge is created.

### 4.2 Re-anchoring an edge

Select an edge → endpoint handles (circles) appear at both ends. Drag
either handle:

- Over another node → snaps to the nearest port. The edge re-anchors to
  that node when you release.
- Over a different port of the same node → re-pins the port.
- Into open space → the edge stays as it was; drop here cancels the drag.

Visual signals during drag:

- Solid line + "release to connect to X (port)" status → drop will commit
- Dashed faded line + "release in open space to cancel" status → drop
  will cancel
- Cursor changes: `alias` when snapping, `no-drop` when floating

### 4.3 The port system

Each node has 8 potential anchor ports: `N`, `NE`, `E`, `SE`, `S`, `SW`,
`W`, `NW`. Plus `auto` (the default), which lets the router pick whichever
side faces the other endpoint.

To pin a port explicitly: select the edge → port indicators appear on
source and target nodes → click any port to pin the edge to it.

Gateways (diamonds) collapse diagonal ports to their nearest cardinal tip,
since the diagonal corners don't visually exist on a diamond.

To clear pinned ports and return to auto-routing: properties panel →
**Clear ports** button.

### 4.4 Aim-assist

While dragging an endpoint, ghost port dots appear on all nodes within
140 px of the cursor. Their opacity fades with distance. This previews
all possible snap targets so you can aim before committing.

### 4.5 Edge properties

Select an edge → properties appear on the right.

- **Display ID** — `flow_N` (read-only)
- **UID** — internal reference (read-only)
- **Source** / **Target** — dropdown of nodes
- **Name** — optional label rendered on canvas
- **Condition** (for exclusiveGateway outflows) — expression evaluated at
  decision time

**Routing section**:

- **Source port** / **Target port** — dropdowns
- **Reset routing** — clears any waypoints, detourY, and routingHints.
  Falls back to pure auto-routing.
- **Clear ports** — sets both ports to `auto` and clears routing state.
- **Reverse** — swaps source and target, including ports and reversed
  waypoint list.

---

## 5. Routing

The auto-router draws orthogonal (right-angle) paths between nodes. You
have three levels of override available.

### 5.1 Auto-routing (default)

For most edges, you don't need to do anything. The router picks the
shortest sensible orthogonal path between source and target ports.

**Multi-edge spread**: when several edges share the same node side
(e.g. three edges leaving the `E` port of a parallel gateway), they
automatically distribute along the side to avoid stacking.

**Loop-back detection**: if the natural path would crash through other
nodes, or if it would U-turn awkwardly backward, the router routes around
via a detour band above or below the involved nodes.

### 5.2 Per-segment nudges (routing hints)

Click any edge → small green pills appear at the midpoint of each interior
segment. Pills are oriented to match the segment:

- Horizontal pills sit on horizontal segments and drag vertically
  (cursor: ns-resize)
- Vertical pills sit on vertical segments and drag horizontally
  (cursor: ew-resize)

Drag a pill perpendicular to the segment → the segment moves. The edge
stays auto-routed: if you then move a connected node, the path re-routes
but your nudge is preserved.

To remove a nudge: click **Reset routing** in the properties panel.

### 5.3 Loop-back cross-bar

Auto-detected loop-back edges (like the `insufficient · loop` edge in the
seed workflow) get a dedicated cross-bar handle: a green pill on the
horizontal middle of the detour. Drag up/down to position the detour
within the lane band.

The detour is clamped to stay inside the lane (specifically, between
"just below the lower of source/target" and "the lane's bottom margin",
or the symmetric above-routing band). You can't drag it outside this
range.

### 5.4 Manual waypoints (escape hatch)

When the auto-router and the hints don't capture what you need, you can
manually edit the YAML to insert explicit waypoints. The router walks
them in order, drawing orthogonal segments between consecutive points.

There's currently no in-canvas UI to add waypoints; this is the only way
to override the auto-routing entirely. Manual waypoints take precedence
over all other routing fields.

### 5.5 Resetting routing

The **Reset routing** button clears all overrides on the selected edge:
waypoints, detourY, and routingHints. The edge returns to pure
auto-routing.

---

## 6. Handoffs to other workflows

Workflows compose. When `triage` finishes and needs to dispatch
`investigate`, that's a *handoff* — a typed boundary crossing between
two distinct workflow definitions. The designer models these as
**off-page connectors**, BPMN's standard mechanism for cross-page
references.

### 6.1 The two halves of a handoff

Each handoff is a pair:

- **Throw** (`Handoff →`) — a node *in the originating workflow* that
  represents "from here, dispatch the other workflow." Hollow circle
  with a right-pointing chevron.
- **Catch** (`← Handoff`) — a node *in the receiving workflow* that
  represents "I am invoked when the other workflow hands off." Hollow
  circle with a left-pointing chevron.

They're linked by a shared `linkId` (a short string like `X1` or
`RESULT`) and a `targetWorkflow` reference (the id of the workflow on
the other side).

### 6.2 Creating a handoff

1. In the originating workflow, drag a **Handoff →** from the palette
   onto the canvas. The node appears as a hollow circle.
2. In its properties panel, **Target workflow** dropdown lists all
   loaded workflows. Pick one. (If the target isn't loaded, use the
   free-text field below to type its id.)
3. **Link ID** is a short identifier you choose. Convention: uppercase
   short codes like `X1`, `RESULT`, `ESCALATE`.
4. Connect upstream nodes to this handoff with a sequence flow, just
   like any other node.
5. In the receiving workflow, drag a **← Handoff** onto its canvas.
   Set its **Target workflow** to point back at the originator (this
   is optional but useful documentation) and set its **Link ID** to
   match.

### 6.3 The contract a handoff implies

Handoffs are typed — they carry data, not just control flow. The
inputs declared on the **Handoff →** node specify what data leaves
the originating workflow. The outputs declared on the **← Handoff**
node specify what data arrives in the receiving workflow.

Conceptually these are two halves of one contract: the throw's
inputs should match the catch's outputs (modulo names — types must
agree). The designer doesn't yet enforce this; future validation
will check it.

### 6.4 What handoffs don't do

The designer is an *editor*, not a runtime. Drawing a handoff doesn't
make anything execute — it documents the intended composition. When
`fw workflow run` ships, the handoff metadata gives it everything it
needs to actually dispatch the target workflow with the correct
inputs.

---

## 7. Selection and keyboard shortcuts

### 6.1 Selection

- **Click a node or edge** → select it (and only it)
- **Shift-click** a node → toggle its membership in the current selection
- **Click empty canvas** → clear selection
- **Drag empty canvas** → rubber-band; nodes inside the rectangle are
  selected on release

The status overlay shows current selection: `N nodes selected` or
`edge selected` or empty.

Multi-selected nodes show subtle outlines and the primary selection (the
last clicked) drives the properties panel.

### 6.2 Keyboard

- **Delete** / **Backspace** — delete the current selection
  (single node, multi-select, or edge)
- **Esc** — clear selection / exit Connect or Create mode
- **Shift+click** — toggle multi-select membership (see above)

No undo/redo yet. Be careful.

---

## 8. Saving and exporting

### 8.1 Save (download)

Click **Save** in the toolbar → downloads a `.bpmn` file named
`<workflow-id>.v<version>.bpmn` containing the workflow in BPMN 2.0 XML
with AEF extensions.

### 8.2 Load (open from file)

Click **Load…** → file picker → choose a `.bpmn` file → the workflow is
parsed and added to the in-session library. If a workflow with the same
id is already loaded, the new one is auto-renamed (`<id>_v2`) to avoid
collision.

Round-trips preserve identity: every node's `uid` survives, so edges keep
their references intact. Positions, routing hints, loop detours, lane
abbreviations, and link event targets are all restored.

### 8.3 The library

Multiple workflows can be open at the same time. The toolbar dropdown
shows all loaded workflows; clicking a different one switches the active
canvas. Unsaved edits are kept in memory across switches — until you
close the page, all loaded workflows persist.

Click **+** in the toolbar to create a fresh empty workflow.

The library section in the properties panel (visible when nothing is
selected) shows all loaded workflows as clickable cards.

### 8.4 View XML

Click **View XML** → an overlay shows the current workflow's XML
representation. Read-only. Useful for:

- Verifying schema compliance during authoring
- Copy-pasting fragments into AEF documentation
- Debugging unexpected behaviors

Close the overlay with **Esc** or the close button.

### 8.5 What's serialized

Everything visible in the editor:

- All nodes with name, slug, lane, position, type-specific aef fields, I/O
- All edges with source/target, name, condition, ports, routing
- Lanes with name, abbr, authority, height
- The pool itself

Plus internal stable identifiers (uids) preserved in `aef:uid` extension
elements for future round-trip.

---

## 9. Tips

- **Use the seed workflow as a reference**. The `investigate` workflow that
  ships with the editor demonstrates every node type, gateway, lane,
  loop-back, and labeled edge. Inspect its XML for examples of every
  schema feature.

- **Name your nodes meaningfully.** The auto-derived slug takes the first
  word, so "Decompose problem" becomes `decompose`. If you have multiple
  nodes starting with the same word ("Search code", "Search history",
  "Search related"), they'll collide and get `-2`, `-3` suffixes
  automatically — but more distinctive names lead to more meaningful
  displayIds.

- **Set lane abbreviations early.** Lane `abbr` defaults to first 3 letters
  of the lane name. If your lanes are similarly-named ("approval-1",
  "approval-2"), the auto-derived abbrs will collide. Set them once at the
  start.

- **Reset routing if things look wrong.** When the routing seems stuck in
  an unhelpful shape after node moves or port changes, clicking **Reset
  routing** is almost always the right answer. It returns to pure
  auto-routing, and you can re-nudge from there.

- **Check the XML before committing.** Until inline validation is built,
  View XML is your sanity check that the workflow's structure matches your
  intent.
