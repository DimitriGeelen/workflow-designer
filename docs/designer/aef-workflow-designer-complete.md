# AEF Workflow Designer — Complete Reference

This document combines all four reference documents and the full artifact source
code into a single self-contained file. Use it for offline reference, archival,
or as a single deliverable.

**Contents:**

1. [Overview (README)](#1-overview)
2. [User Guide](#2-user-guide)
3. [Schema Reference](#3-schema-reference)
4. [Architecture](#4-architecture)
5. [Artifact Source (HTML)](#5-artifact-source)

---

# 1. Overview

A visual, BPMN-subset editor for authoring AEF (Anchorpoint Framework)
workflows. Humans drag and drop; agents read the structured representation.
Produces YAML-canonical workflow files with BPMN XML as a derived export
format.

---

## What this is

A self-contained HTML artifact that lets you compose a workflow visually —
laying out tasks, decisions, and parallel branches across swimlanes that
correspond to the AEF authority model (Human · Sovereignty, Framework ·
Authority, Agent · Initiative). The result is a workflow file structured
enough for an executor to run, while remaining editable by humans and
generatable by agents.

The editor is intentionally **dual-audience**:

- **Humans** see a Visio-like canvas, drag shapes around, fill in
  properties.
- **Agents** see a typed, schema-validated YAML/XML representation with
  stable identifiers and explicit data contracts.

Both audiences operate on the same file. Neither sees a degraded version
intended for the other.

---

## Where it fits in AEF

AEF's workflow representations evolve along a **manifest-maturity ladder**:

1. **Exploration** — markdown dispatch templates (`agents/dispatch/*.md`).
   Humans write a prompt; an agent improvises the workflow from it. Useful
   for one-off tasks where the structure isn't yet clear.
2. **Stabilization** — structured workflow files (this designer's output).
   The workflow is captured as a graph with typed I/O and routing. Suitable
   for repeated work where the structure has stabilized but the runtime
   still uses the framework's normal dispatch.
3. **Automation** — `fw workflow run <name>` executor (planned). The
   framework runs the workflow file directly, dispatching agents at each
   step, evaluating gateway conditions, persisting audit trails.

**This designer occupies the Stabilization tier.** It produces files that
are richer than dispatch templates but don't require the runtime executor
to be useful — they can be hand-executed today, with the runtime taking
over once it ships.

---

## Quick orientation

- The editor is a **single HTML file**:
  `aef-workflow-designer.html`. Open it in any modern browser; no server
  required.

- State is **in-memory only**. Reloading the page starts from the seed
  workflow. The Save button downloads a `.bpmn` file. Import is on the
  roadmap.

- The seed workflow is **`investigate`** — a representative AEF dispatch
  with all node types (start/end events, service/user/script tasks, both
  gateway types, sequenceFlows), all three default lanes, labeled edges,
  conditional branches, and a loop-back. Inspect it as a worked example of
  every schema feature.

- The artifact is **CDN-only sandboxed**: no `bpmn-js`, no local storage,
  no external libraries beyond the ones explicitly loaded inline. This is
  a constraint, not an aesthetic — see
  [architecture.md §1](architecture.md#1-the-single-file-constraint).

---

## Where to find what

| You want to… | Read |
|---|---|
| Use the editor — draw, edit, save | [user-guide.md](user-guide.md) |
| Understand the workflow file format | [schema.md](schema.md) |
| Generate a workflow file from an agent | [schema.md](schema.md), especially §3 and §7 |
| Validate a workflow file | [schema.md §7.3](schema.md#73-validation) |
| Modify the designer's code | [architecture.md](architecture.md) |
| Understand why a design decision was made | [architecture.md](architecture.md) — captures the *why* behind the data model, routing system, and interaction model |
| Add a new node type | [architecture.md §2](architecture.md#2-state-shape) + [schema.md §4](schema.md#4-node-types) |
| Add a new aef: extension field | [schema.md §7.2](schema.md#72-the-aef-extension-namespace) + the `AEF_FIELDS` / `FIELD_META` tables in the artifact |
| Diagnose a routing surprise | [architecture.md §4](architecture.md#4-the-routing-system) |

---

## Status

**Implemented:**

- Eight-element BPMN subset (start/end events, three task types, two
  gateway types, sequence flow)
- Off-page connectors: link event throw + catch, for handoffs to other workflows
- Three default lanes mapping to AEF authority model; full lane CRUD
- Two-identifier model (immutable `uid` + computed `displayId`)
- Auto-routing with multi-edge spread, loop-back detection with lane-clamped
  detour, per-segment routing hints
- BPMN XML export *and* import with `aef:` extension namespace
- Multi-workflow library: edit several workflows in one session, switch via picker
- Workflow identity (id, title, version, description) editable via properties panel
- Save downloads `<id>.v<version>.bpmn`; Load opens a file picker
- Properties panel for nodes, edges, lanes, and the workflow itself
- Multi-select, group drag, keyboard delete
- Magnetic snap with aim-assist; explicit port pinning

**Not implemented (in roughly the order they'd matter):**

- Undo / redo
- Pan / zoom on the canvas
- Inline validation (red outlines, problem list)
- Copy / paste of nodes and selections
- Manual waypoint insertion in canvas (currently YAML-only)
- Cross-workflow navigation (click a handoff → jump to the other workflow's catch)
- Auto-discovery of workflow library from disk (currently you load files manually)

See [architecture.md §8](architecture.md#8-open-architectural-questions) for
why each is open and the rough shape an implementation would take.

---

## Conventions

- **uids** are internal. Avoid referencing them in conversation or
  documentation. Say `agt_2_decompose`, not `n_a3f7c0b2`.
- **displayIds** are the conversational handle. They will mutate as the
  workflow evolves; this is intentional. The edge graph survives via uids
  underneath.
- **Names** are free text and can drift; the slug-derivation handles most
  cases but `slugManual` lets you pin a slug when needed.
- **The seed workflow** is the worked example of how to use every feature.
  When in doubt about field shape or naming convention, look there first.

---

# 2. User Guide

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

---

# 3. Schema Reference

Authoritative reference for the workflow file format produced by the AEF workflow
designer. Read this when authoring workflow files by hand, generating them from
an agent, or writing a validator.

This document describes the *contract*. For implementation details of the
designer itself, see [architecture.md](architecture.md). For the on-canvas
editing experience, see [user-guide.md](user-guide.md).

---

## 1. The two-identifier model

Every node and every edge carries **two identifiers**:

- **`uid`** — immutable, internal, never user-facing in conversation.
- **`displayId`** — computed, human-readable, mutable, shown on canvas.

The two layers exist because the values different audiences need are
incompatible. Edges in storage need to point at something that never changes
or every rename breaks the graph. Humans authoring the file need readable
references like `agt_2_decompose`, not opaque hex strings. The solution is to
have both, with each layer doing the job it's good at.

### 1.1 `uid` — the storage contract

`uid` is the actual key that other parts of the workflow reference. Edges
store `source` and `target` as uids. Future runtime systems (audit logs,
execution traces) persist uids. Anything that needs identity-over-time
keys off uid.

**Format**: `<prefix>_<8 hex chars>` — `n_a3f7c0b2` for nodes, `e_b91dcf04`
for edges. Random; collision probability is negligible for any plausible
workflow size. Never edited by users.

**When generated**: on node creation. Once assigned, never changes.

**When emitted in XML**: as `<aef:uid value="…"/>` inside the
`<bpmn:extensionElements>` block on every node and edge.

### 1.2 `displayId` — the human contract

`displayId` is what people see and reference in conversation. It's computed
from three inputs and recomputed whenever any of them changes.

**Format for nodes**: `<lane.abbr>_<seq>_<slug>`

```
agt_2_decompose
└─┬─┘ │ └───┬───┘
 lane │     slug from name
      └─ spatial position within lane (left-to-right by x)
```

**Format for edges**: `flow_<seq>` — sequential by edge creation order
(stable; deleted edges leave gaps). Edges don't get richer displayIds
because the meaningful identifier on an edge is its `name` label
(`sufficient`, `abandon`, `insufficient · loop`), not a manufactured
descriptor.

**Recomputation triggers**:

- Node moved to a new lane → lane abbr in the displayId changes
- Node moved horizontally past another node in same lane → seq changes for
  both nodes
- Node renamed (and `slugManual` is false) → slug changes
- Node's `slug` field edited directly → slug changes
- Lane's `abbr` field edited → all nodes in that lane recompute

**When recomputation happens**: only at commit moments — after a drag
release, after a property edit, after an add/delete. *Not* during
in-progress drags. This keeps the canvas labels stable while you're
manipulating, with the update landing when you let go.

**When emitted in XML**: as `bpmn:id` attribute on every BPMN element.

---

## 2. Lane abbreviations

Every lane carries a 3-character `abbr` field used as the prefix in node
displayIds. Default derivation: first three alphanumeric characters of the
lane's name, lowercased.

```
human     → hum
framework → frw
agent     → agt
```

**Uniqueness**: enforced across lanes in the same workflow. If a derived
candidate collides with an existing lane's abbr, the system tries
two-character bases with digit suffixes (`hu2`, `hu3`) until unique.

**User-editable**: yes. The properties panel exposes the field. Editing
sets a `abbrManual` flag on the lane; subsequent name changes don't
auto-update the abbr.

**Constraints**: any string is accepted but the conventional shape is
3 characters, lowercase, alphanumeric. Longer abbreviations work but
clutter the canvas.

---

## 3. Workflow file structure (YAML canonical form)

The designer produces BPMN XML as its export format, but the canonical
representation in AEF is YAML. Both forms carry the same information; the
YAML is recommended for source control and for hand-authoring.

```yaml
workflowMeta:
  id: investigate          # workflow identifier (slug)
  version: 1               # schema version (see §8)
  source: agents/dispatch/investigate.md   # optional pointer to origin
  tier_default: 2          # default action tier for unspecified nodes

pool:
  id: Pool_investigate
  name: investigate

lanes:
  - id: human
    name: Human · Sovereignty
    abbr: hum
    authority: sovereignty
    height: 130
  - id: framework
    name: Framework · Authority
    abbr: frw
    authority: authority
    height: 130
  - id: agent
    name: Agent · Initiative
    abbr: agt
    authority: initiative
    height: 320

nodes:
  - uid: n_a3f7c0b2
    type: startEvent
    name: Investigation requested
    slug: investigation
    lane: framework
    x: 280
    y: 96
    aef:
      triggeredBy: fw dispatch investigate ${task_id}
      contextReads: .tasks/active/${task_id}.md
    io:
      outputs:
        - { name: task_id, type: task_id }
        - { name: run_id,  type: string }

edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2     # uid, not displayId
    target: n_c40e8a5d
    sourcePort: E          # optional; default 'auto'
    targetPort: W
    # name, condition, waypoints, detourY, routingHints — all optional
```

The minimal valid workflow has `workflowMeta`, `pool`, `lanes` (at least one),
and `nodes` and `edges` (both can be empty).

---

## 4. Node types

The designer supports an eight-element BPMN subset, each mapping to a specific
AEF concept.

| Type | Shape | Default lane | AEF meaning |
|---|---|---|---|
| `startEvent` | Circle | framework | Workflow entry point — typically a dispatch trigger or external event |
| `endEvent` | Circle (heavy) | framework | Terminal state — emits a completion event |
| `serviceTask` | Rectangle | agent | Work performed by an agent (Initiative authority) |
| `userTask` | Rectangle | human | Work performed by a human (Sovereignty authority) |
| `scriptTask` | Rectangle | framework | Work performed by the framework runtime (Authority authority) |
| `exclusiveGateway` | Diamond | agent | Decision point — exactly one outgoing path taken |
| `parallelGateway` | Diamond (`+`) | agent | Fan-out or join — all paths taken |
| `linkEventThrow` | Hollow circle (chevron →) | framework | Off-page connector: hands off to another workflow |
| `linkEventCatch` | Hollow circle (chevron ←) | framework | Off-page connector: receives a handoff from another workflow |
| `sequenceFlow` | Arrow | — | Edge connecting two nodes |

The mapping between task type and lane is a *convention*, not a constraint. A
`serviceTask` can sit in the framework lane if the workflow author has reason
to. The lane prefix in the displayId reflects actual lane membership; the type
prefix in the slug (when auto-derived) reflects type.

### 4.1 Required fields per node

All nodes require:

- `uid` (auto-generated)
- `type` (one of the seven node types above)
- `name` (display label)
- `lane` (a valid lane id)
- `x`, `y` (canvas coordinates in pixels)

Optional but conventional:

- `slug` (auto-derived from name; user can override)
- `slugManual` (boolean; `true` if user has edited slug directly)
- `aef` (object with type-specific fields; see §4.3)
- `io` (object with `inputs` and `outputs` arrays; see §4.4)

### 4.2 Node-type-specific fields

The `aef:` extension namespace carries the AEF-specific metadata. Which fields
apply depends on node type.

| Field | startEvent | endEvent | serviceTask | userTask | scriptTask | exclusiveGateway | parallelGateway | linkEventThrow | linkEventCatch |
|---|---|---|---|---|---|---|---|---|---|
| `tier` | — | — | ✓ | ✓ | ✓ | — | — | — | — |
| `agentType` | — | — | ✓ | — | — | — | — | — | — |
| `endpoint` | — | — | ✓ | ✓ | ✓ | — | — | — | — |
| `contextReads` | ✓ | — | ✓ | — | ✓ | — | — | — | — |
| `artifactsWrites` | — | — | ✓ | — | ✓ | — | — | — | — |
| `triggeredBy` | ✓ | — | — | — | — | — | — | — | — |
| `emits` | — | ✓ | — | — | — | — | — | — | — |
| `decisionInput` | — | — | — | — | — | ✓ | — | — | — |
| `decisionOwner` | — | — | — | — | — | ✓ | — | — | — |
| `decisionOutputs` | — | — | — | ✓ | — | — | — | — | — |
| `targetWorkflow` | — | — | — | — | — | — | — | ✓ | ✓ |
| `linkId` | — | — | — | — | — | — | — | ✓ | ✓ |

Fields used by multiple node types:

- **`tier`** — action authority tier (0, 1, 2, 3). Workflow-level `tier_default`
  applies when unspecified.
- **`endpoint`** — what executes this step. Format depends on the task type:
  - `serviceTask`: agent prompt path (`agents/dispatch/skills/decompose.md`) or
    framework command (`fw recall ${query} --scope code`)
  - `userTask`: watchtower view URL (`watchtower:/investigate/runs/${run_id}`)
  - `scriptTask`: framework command (`fw report write investigate --run ${run_id}`)
- **`contextReads`** / **`artifactsWrites`** — comma-separated path globs the
  step reads from / writes to. These are *filesystem* contracts, distinct from
  the typed I/O in §4.4.
- **`agentType`** — for serviceTask only: `primary` | `termlink-worker` | `human`.
  Identifies the executor.
- **`decisionInput`** — for exclusiveGateway only: an expression that
  evaluates to the routing key (`${findings.confidence}`).
- **`decisionOwner`** — for exclusiveGateway only: who makes the decision —
  `agent` | `human` | `framework`. Almost always implied by lane membership,
  but explicit for cases where lane and decision authority diverge.
- **`decisionOutputs`** — for userTask only: comma-separated enum of possible
  human decisions (`dispatch, abandon, reinvestigate`). Each value typically
  corresponds to an outgoing edge `name`.
- **`triggeredBy`** — for startEvent only: free-form description of what
  triggers entry (`fw dispatch investigate ${task_id}`).
- **`emits`** — for endEvent only: event name(s) emitted on completion
  (`event:investigate.ready`).
- **`targetWorkflow`** — for link events only: id of the workflow on the
  other side of the handoff. A `linkEventThrow` in workflow A with
  `targetWorkflow = "investigate"` and `linkId = "X1"` is matched by a
  `linkEventCatch` in workflow B (where B's `workflowMeta.id` is `investigate`)
  with the same `linkId`.
- **`linkId`** — for link events only: identifier that pairs a throw with its
  matching catch across workflows. Convention: short uppercase code (`X1`,
  `RESULT`, etc.).

### 4.3 The I/O contract (typed data flow)

Distinct from `contextReads` / `artifactsWrites` (filesystem operations), the
`io` block declares the typed data contract between steps:

```yaml
io:
  inputs:
    - { name: findings, type: ref, required: true }
    - { name: run_id,   type: string, required: true }
  outputs:
    - { name: report_path, type: path }
    - { name: audit_entry, type: ref }
```

**Type vocabulary**: `string`, `number`, `boolean`, `ref`, `path`, `task_id`,
`arc_id`, `list`, `object`. The vocabulary is extensible; new types can be
added without schema-breaking changes.

**Required vs. optional**: `required: true` declares the input must be present.
The framework will refuse to dispatch a step missing required inputs.

**Which node types carry I/O**:

| Type | inputs | outputs |
|---|---|---|
| `startEvent` | — | ✓ |
| `endEvent` | ✓ | — |
| `serviceTask` | ✓ | ✓ |
| `userTask` | ✓ | ✓ |
| `scriptTask` | ✓ | ✓ |
| `exclusiveGateway` | ✓ | — (decision is routing, not data) |
| `parallelGateway` | — | — |
| `linkEventThrow` | ✓ | — (data leaves into the target workflow) |
| `linkEventCatch` | — | ✓ (data arrives from the throwing workflow) |

---

## 5. Lanes

```yaml
lanes:
  - id: human
    name: Human · Sovereignty
    abbr: hum
    authority: sovereignty
    height: 130
```

**Required fields**: `id`, `name`, `authority`, `height`. The `abbr` is
auto-derived but persisted for stability.

**`authority`** — one of: `sovereignty`, `authority`, `initiative`,
`external`, `none`.

- `sovereignty` — humans only. Decisions that require human judgment or
  rule-of-three authority (per AEF's authority model).
- `authority` — framework operations. Deterministic actions the framework
  executes on behalf of the user.
- `initiative` — agent operations. Probabilistic actions an agent proposes
  or executes.
- `external` — third-party systems. Operations performed by something
  outside the AEF runtime (an API, a webhook target).
- `none` — pool-level lanes that don't carry authority semantics
  (purely visual grouping).

The authority value tints the lane background subtly on canvas and is
serialized in `aef:laneMeta`. Future validation rules will likely cross-check
node types against lane authority (e.g. warn if a `userTask` is in an
`initiative` lane).

**`height`** — pixel height of the lane band on canvas. Persisted because
visual layout is part of the workflow's affordances; an editor reopening the
file should see the same canvas the author left.

---

## 6. Edges

```yaml
edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2     # uid of source node
    target: n_c40e8a5d     # uid of target node
    name: sufficient       # optional label, rendered on canvas
    condition: ${findings.confidence >= 0.7}   # optional, exclusiveGateway only
    sourcePort: E          # optional; default 'auto'
    targetPort: W
    # Routing overrides — all optional
    waypoints: []          # explicit polyline points; if non-empty, router honors them
    detourY: 165.0         # for loop-back edges; absolute Y of the cross-bar
    routingHints:          # per-segment perpendicular offsets
      seg_mid: 20.0
```

### 6.1 Required vs. optional

Required: `uid`, `source`, `target`.

Everything else is optional. A minimal edge:

```yaml
edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2
    target: n_c40e8a5d
```

### 6.2 Ports

`sourcePort` and `targetPort` specify which side of each node the edge
anchors to. Eight cardinal/diagonal values are supported:

```
N, NE, E, SE, S, SW, W, NW
```

Plus `auto` (the default when omitted) which lets the router pick whichever
side faces the other endpoint.

### 6.3 Routing fields and their precedence

When multiple routing override fields are present, precedence is:

1. **`waypoints`** (if non-empty) — explicit manual polyline. The router
   draws orthogonal segments between consecutive waypoints, with stubs
   from each anchor to the first/last waypoint.
2. **`detourY`** — for loop-back-detected edges. Specifies the absolute
   Y of the horizontal cross-bar; the router computes everything else
   around it, clamped to lane bounds.
3. **`routingHints`** — per-segment perpendicular offsets keyed by role
   name (`seg_first`, `seg_mid`, `seg_last`). Applied to the
   auto-computed corners; the edge stays auto-routed.
4. **None of the above** — pure auto-routing.

If `waypoints` is non-empty, `detourY` and `routingHints` are ignored —
manual routing is a complete override.

### 6.4 Routing hint roles

The auto-router classifies each computed path into one of five topologies:

- `T0` — straight line, no corners
- `T1_HV` — one corner, source horizontal then target vertical
- `T1_VH` — one corner, source vertical then target horizontal
- `T2_H` — two corners on a shared Y (parallel horizontal stubs)
- `T2_V` — two corners on a shared X (parallel vertical stubs)

Each topology has a fixed set of interior segments named by stable role:

- `seg_first` — the segment immediately after the source stub
- `seg_mid` — the middle segment (T2 only)
- `seg_last` — the segment immediately before the target stub

A `routingHints[role]` value is a number representing perpendicular pixel
displacement. Positive = down or right depending on segment orientation;
negative = up or left.

**Topology stability**: when the geometry changes such that the topology
shifts (e.g. a port re-pin changes T2 to T1), role-keyed hints that no
longer apply are silently ignored. The edge routes from scratch in the new
topology. No errors, no migration; if the user wants the visual back, they
re-drag in the new topology.

### 6.5 Conditions

`condition` is meaningful only on edges leaving an `exclusiveGateway`.
Format: an expression string referencing the gateway's `decisionInput` or
upstream outputs.

```yaml
- uid: e_xxx
  source: <GW_sufficient>
  target: <Script_writeReport>
  name: sufficient
  condition: ${findings.confidence >= 0.7}
```

The framework runtime evaluates conditions at decision time and follows
exactly one outgoing edge (whichever condition is true; or an unconditioned
edge marked as default).

---

## 7. BPMN XML representation

The designer's **Save** action emits a `.bpmn` file with the workflow encoded
in BPMN 2.0 XML, augmented with an `aef:` extension namespace for the
AEF-specific fields.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:aef="http://anchorpoint.framework/aef/extensions">

  <bpmn:process id="Pool_investigate" name="investigate">

    <bpmn:laneSet id="LaneSet_investigate">
      <bpmn:lane id="human" name="Human · Sovereignty">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="hum" authority="sovereignty"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>frw_1_investigation</bpmn:flowNodeRef>
        ...
      </bpmn:lane>
      ...
    </bpmn:laneSet>

    <bpmn:serviceTask id="agt_1_decompose" name="Decompose problem">
      <bpmn:extensionElements>
        <aef:uid value="n_a3f7c0b2"/>
        <aef:meta tier="2" agentType="primary"/>
        <aef:endpoint>agents/dispatch/skills/decompose.md</aef:endpoint>
        <aef:contextReads paths=".context/working/.../bundle.yaml"/>
        <aef:artifactsWrites paths=".context/working/.../sub-questions.yaml"/>
        <aef:io>
          <aef:input name="bundle" type="ref" required="true"/>
          <aef:output name="sub_questions" type="list"/>
        </aef:io>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_2</bpmn:incoming>
      <bpmn:outgoing>flow_3</bpmn:outgoing>
    </bpmn:serviceTask>

    <bpmn:sequenceFlow id="flow_13" name="insufficient · loop"
                       sourceRef="agt_8_sufficient" targetRef="agt_1_decompose">
      <bpmn:conditionExpression
          xsi:type="bpmn:tFormalExpression"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        ${findings.confidence &lt; 0.7}
      </bpmn:conditionExpression>
      <bpmn:extensionElements>
        <aef:uid value="e_b91dcf04"/>
        <aef:loopDetour y="165.0"/>
      </bpmn:extensionElements>
    </bpmn:sequenceFlow>

  </bpmn:process>
</bpmn:definitions>
```

### 7.1 Identifier mapping

- `bpmn:id` attributes → displayId (`agt_1_decompose`, `flow_13`)
- `<aef:uid value="…"/>` → uid (`n_a3f7c0b2`)
- `sourceRef` / `targetRef` on `<bpmn:sequenceFlow>` → displayId of the
  linked node
- `<bpmn:flowNodeRef>` inside `<bpmn:lane>` → displayId

Re-import (when implemented) will key off `aef:uid` to preserve identity
across edits made in external BPMN tools.

### 7.2 The aef: extension namespace

| Element | Where | Purpose |
|---|---|---|
| `aef:uid` | inside any extensionElements | Internal stable identifier |
| `aef:meta` | inside node extensionElements | Carries tier, agentType, decisionOwner, triggeredBy, emits as attributes |
| `aef:endpoint` | inside node extensionElements | Endpoint text (multi-line capable) |
| `aef:contextReads` | inside node extensionElements | `paths="…"` attribute |
| `aef:artifactsWrites` | inside node extensionElements | `paths="…"` attribute |
| `aef:decisionInput` | inside exclusiveGateway extensionElements | Expression text |
| `aef:decisionOutputs` | inside userTask extensionElements | `values="…"` attribute |
| `aef:io` | inside node extensionElements | Wraps `aef:input` and `aef:output` |
| `aef:input` / `aef:output` | inside `aef:io` | `name=`, `type=`, optional `required=` |
| `aef:laneMeta` | inside lane extensionElements | `abbr=`, `authority=`, `height=` |
| `aef:anchors` | inside sequenceFlow extensionElements | `sourcePort=`, `targetPort=` |
| `aef:routing` | inside sequenceFlow extensionElements | Wraps `aef:waypoint` elements |
| `aef:waypoint` | inside `aef:routing` | `x=`, `y=` coordinates |
| `aef:loopDetour` | inside sequenceFlow extensionElements | `y=` absolute coordinate |
| `aef:routingHint` | inside sequenceFlow extensionElements | `role=`, `offset=` |
| `aef:workflowMeta` | inside process extensionElements | `id=`, `version=`, `schemaVersion=`, `title=`, `description=`, `source=`, `tier_default=` |
| `aef:position` | inside node extensionElements | `x=`, `y=` — node canvas coordinates (preserved for round-trip) |
| `aef:link` | inside intermediateThrowEvent / intermediateCatchEvent | `targetWorkflow=`, `linkId=` — off-page connector to another workflow |

### 7.3 Validation

For a workflow to be valid:

- Every `bpmn:id` must be unique within the document
- Every `aef:uid` must be unique within the document
- Every `sourceRef` and `targetRef` must resolve to a node's `bpmn:id`
- Every node's `lane` must match a lane in the `bpmn:laneSet`
- Every required input must have a corresponding upstream output of compatible type
- Every `exclusiveGateway` must have at least two outgoing edges; conditions must be mutually exclusive (or default-marked)

Validation is not currently enforced by the designer — it will produce
invalid files if you create one. A future `fw workflow validate` command
is the planned enforcement point.

---

## 8. Schema versioning

The workflow file carries two version markers:

- **`workflowMeta.version`** — the *content* version of this specific workflow.
  Free integer or string; the author bumps it manually when the workflow's
  semantics change. Defaults to `"1"`.
- **`workflowMeta.schemaVersion`** — the *schema* version this file conforms
  to. Currently `2`. Maintained by the editor; users don't edit this.

### 8.1 Schema version history

**v2** (current)
- Added `aef:workflowMeta` element on `<bpmn:process>` carrying `id`,
  `version`, `schemaVersion`, `title`, `description`, `source`, `tier_default`
- Added `aef:position` element on every node for canvas layout round-trip
- Added `aef:link` element on `<bpmn:intermediateThrowEvent>` and
  `<bpmn:intermediateCatchEvent>` for off-page connectors
- Added `linkEventThrow` and `linkEventCatch` node types

**v1**
- Initial release. Eight-element BPMN subset, two-identifier model, routing
  extensions.

### 8.2 Compatibility policy

- **Additive changes** (new optional fields, new aef: elements) → no version bump
- **Breaking changes** (renamed fields, removed elements, changed semantics)
  → version bump, with migration notes in CHANGELOG when one exists

Until `fw workflow run` ships and external consumers exist, the schema is
considered pre-v1 and may change without ceremony. Once external runtime
exists, version bumps become contractual.

The designer's import path (when implemented) will read the version and apply
forward migrations as needed.

---

## 9. The relationship between AEF concepts and this schema

A few mappings worth being explicit about, since they often confuse newcomers:

- **The three-role authority model** (Sovereignty / Authority / Initiative)
  maps to the `authority` field on lanes. It's *not* the same as `tier`
  (action authority 0–3 on individual nodes).
- **Tier** is per-node and describes how much autonomy the executor has for
  that specific step — not who's executing it. A `serviceTask` in the agent
  lane (Initiative authority) can be tier 0 (read-only), tier 1 (proposes),
  tier 2 (acts with confirmation), or tier 3 (acts autonomously).
- **The manifest-maturity ladder** (Exploration → Stabilization → Automation)
  is the dimension along which a workflow representation evolves. This
  designer occupies the Stabilization tier. Dispatch markdown templates are
  Exploration; `fw workflow run` execution will be Automation.
- **The Four Constitutional Directives** (Antifragility, Reliability, Usability,
  Portability) are values, not levels. They don't map to schema fields; they
  inform design decisions about what fields exist at all.

---

# 4. Architecture

Implementation reference for anyone modifying the designer's code. Captures
the *why* behind design decisions, the data flow through the artifact, and
the open architectural questions worth being aware of.

For the workflow file format itself, see [schema.md](schema.md). For the
canvas editing experience, see [user-guide.md](user-guide.md).

---

## 1. The single-file constraint

The designer ships as a single self-contained HTML artifact. This is not
elegance for its own sake — it's a constraint imposed by the rendering
sandbox (CDN-only imports; no localStorage; no `bpmn-js` because it can't
be loaded). The artifact must work entirely with what it can declare inline.

**Consequences:**

- No persistence between page loads. Save downloads a `.bpmn` file; reload
  starts from the seed. (Future: implement import to round-trip.)
- No `bpmn-js` or comparable BPMN renderer. The designer rolls its own
  SVG-based canvas. This is more work but also more controllable — every
  pixel of behaviour is explicit.
- All state lives in a single top-level `state` object. No external store,
  no framework, just mutation and re-render.
- No build step. The file is editable in any text editor and runs in any
  browser.

**When to migrate away**: if AEF takes on a server-backed editor or a
multi-user collaboration model, the single-file constraint goes away.
The data model (§2) is designed to survive that migration — the YAML
canonical form is the source of truth, the rendering layer is replaceable.

---

## 2. State shape

The entire mutable state of the editor lives in one object:

```javascript
state = {
  pool: { id, name },
  workflowMeta: { id, version, source, tier_default },

  lanes: [
    {
      id,            // stable lane identifier
      name,          // display name
      abbr,          // 3-char prefix used in node displayIds
      abbrManual,    // boolean; set if user has overridden abbr
      authority,     // 'sovereignty' | 'authority' | 'initiative' | 'external' | 'none'
      height,        // pixel height of the lane band
    },
    ...
  ],

  nodes: [
    {
      uid,           // immutable, e.g. 'n_a3f7c0b2'
      id,            // alias for uid (legacy compat — see §3)
      slug,          // user-editable short descriptor
      slugManual,    // boolean; set if user has edited slug directly
      type,          // 'serviceTask' | ... | 'exclusiveGateway' | etc.
      name,          // display name (free text)
      lane,          // lane id this node belongs to
      x, y,          // top-left pixel coordinates on canvas
      aef,           // { tier?, agentType?, endpoint?, contextReads?, ... }
      io,            // { inputs?: [...], outputs?: [...] }
    },
    ...
  ],

  edges: [
    {
      uid,           // immutable, e.g. 'e_b91dcf04'
      id,            // alias for uid
      source,        // uid of source node
      target,        // uid of target node
      name,          // optional label
      condition,     // optional, for exclusiveGateway outflows
      sourcePort,    // optional, one of 'N' 'NE' 'E' 'SE' 'S' 'SW' 'W' 'NW' or 'auto'
      targetPort,
      waypoints,     // optional manual polyline [{x, y}, ...]
      detourY,       // optional, for loop-back edges
      routingHints,  // optional, { seg_first?: number, seg_mid?: number, seg_last?: number }

      // Transient (underscore-prefixed; not serialized):
      _renderedPolyline,   // last computed polyline from the router
      _segmentMeta,        // segment role metadata for handle placement
      _loopDetourY,        // last computed detour Y (for handle rendering)
      _loopXRange,
    },
    ...
  ],
};
```

**Mutability**: this object is mutated freely in place. There is no Redux,
no immutability discipline. The pattern is: modify state → call `renderAll()`
(or a more specific render function) → DOM updates.

**Transient vs persisted**: fields prefixed with `_` are set by the renderer
for later use within the same render or for handle event handlers. They are
deliberately not serialized in XML/YAML. They're recomputed every render.

---

## 3. The two-identifier model (deeper)

[schema.md §1](schema.md#1-the-two-identifier-model) covers the contract.
Here are the implementation choices that aren't visible from outside.

### 3.1 Why `id` is an alias for `uid`

Originally the code referenced nodes by `n.id`. When the two-identifier
model was introduced, every callsite would have needed renaming to `n.uid`.
Instead, the migration assigns `node.id = node.uid` — keeping `n.id` as a
working synonym. New code uses `uid` directly; old code reading `n.id`
continues to function.

This is **technical debt by design**. The cleanup is a mechanical
search/replace whenever someone has the appetite to do it. Until then, both
field names refer to the same string.

### 3.2 displayId is computed, not stored

`computeDisplayId(node)` walks `state.nodes`, filters to same-lane, sorts by
`x`, finds the node's spatial rank. Combined with the lane's abbr and the
node's slug, this yields the displayId.

A naive implementation would call `computeDisplayId` from every render-time
location that needs it. That's O(n) per call, O(n²) overall per render.

The actual implementation: a `_displayIdCache: Map<uid, string>` is rebuilt
by `refreshDisplayIds()` at commit moments only. Calls to `displayIdOf(node)`
hit the cache. Cost: one O(n log n) rebuild per commit, then O(1) lookups
during render.

**Commit moments that rebuild the cache** (deliberately not during drag):
- Node mouseup after a drag
- Add/delete node or edge
- Name/slug/abbr edit
- Lane add/delete/reorder/reassignment

The drag itself only updates `node.x` / `node.y`. The displayId stays stable
until the user lets go. This is what gives the "renumber on drop" behavior
you'd want from a process diagram editor.

### 3.3 Slug derivation: option (c)

`deriveSlug(displayName)` returns the *first significant word* (length > 1)
of the name, lowercased, alphanumeric. "Decompose problem" → `decompose`.

`deriveUniqueSlug(node, displayName)` wraps that and appends `-2`, `-3`,
etc. for collisions within the same lane.

The choice was *option c* from a slate of options:
- (a) Full sanitized name truncated: `decompose-problem`
- (b) User-set slug independent of name
- (c) First significant word: `decompose`

Reasoning: short. Most workflow names are 2–4 words, and the first word is
usually the strongest signifier. The collision suffix handles the edge case
(three "Search …" tasks → `search`, `search-2`, `search-3`). Trade-off: a
slug like `search-2` is less informative than `search-history` would be, but
it's stable and consistent.

### 3.4 Edge displayId is just `flow_N`

Edges' displayIds are anonymous sequential numbers. The semantic identifier
on an edge is its `name` label (where present). Most edges don't have
labels — they're plumbing between gateway and downstream tasks — so a
descriptive displayId would be manufactured noise.

The number is the edge's index in `state.edges`. Deletion leaves gaps; new
edges get the next free integer (not necessarily `length + 1`). Stable.

---

## 4. The routing system

This is the most complex subsystem in the artifact and where the conversation
history matters most. The system was iteratively designed; the final
architecture is the result of several rounds.

### 4.1 Orthogonal router

Inputs: source anchor, target anchor, source direction, target direction,
optionally source/target node objects (for collision detection).

Output: `{ polyline, segmentMeta, loopDetourY?, loopXRange? }`.

The polyline is always five-plus points:

```
[anchorA, stubA, corner1?, corner2?, stubB, anchorB]
```

The two stubs are perpendicular 22-pixel extensions from each anchor,
heading in the port direction. They guarantee the path leaves the node
perpendicular to its side — visually expected and topologically clean.

The middle corners are produced by `orthoConnect(stubA, stubB, dirA, dirB)`,
which classifies the stub-relationship into one of five topologies:

- `T0` — same axis, aligned (0 corners): straight line
- `T1_HV` — dirA horizontal, dirB vertical (1 corner)
- `T1_VH` — dirA vertical, dirB horizontal (1 corner)
- `T2_H` — both stubs horizontal, not aligned (2 corners on shared Y)
- `T2_V` — both stubs vertical, not aligned (2 corners on shared X)

Each topology comes with `segments` metadata — an array of
`{ role, dir, perpAxis }` objects describing each interior segment for the
benefit of the segment-handle UI.

### 4.2 Loop-back detection

The simple ortho router cheerfully draws straight lines through other nodes
when the natural path crosses them. To detect this, `routeOrthogonalSegment`
computes the simple path first, then calls `polylineCrossesNodes(polyline,
src, tgt)`.

If any non-source/target node's bounding box (with 4-pixel margin) is
intersected by any segment of the polyline, the path is rerouted via
`orthoLoopBack`.

The original implementation used a `isBackwardFlow(...)` heuristic that
checked specific direction combinations. It missed cases where the natural
path technically wasn't "backward" but still crashed through nodes (e.g.
two side-by-side nodes with an edge between them at the same Y as another
node). The intersection test replaces this with a robust general check.

`isBackwardFlow` is still consulted as a *secondary* trigger for cases where
the path doesn't cross nodes but flows in an awkward backward direction —
this is kept for back-compat, not strictly necessary.

### 4.3 Loop-back routing (`orthoLoopBack`)

When triggered, the loop-back router computes a detour Y for the horizontal
cross-bar that routes above or below the involved nodes.

**Lane clamping**: when source and target share a lane, the detour Y is
clamped to stay inside that lane's vertical band — between
`lowestNodeBottom + STUB_CLEARANCE` and `laneBottom - LANE_MARGIN` for
below-routing, mirror for above. This prevents the loop from escaping into
the pool's bottom margin and visually leaving its lane.

**Cross-lane**: when source and target are in different lanes, the clamp
falls back to wider bounds (200 px above and below). Cross-lane loops can
visually leave the lane during the detour; this is acceptable but
inconsistent with same-lane behavior.

**Auto-pick scoring**: when `edge.detourY` is not user-set, the router
tries 10 candidate Ys (5 above, 5 below at varying offsets) and picks the
one with the lowest score. Score = `crossings × 100 + closenessPenalty +
above-tiebreaker`. The closeness penalty prefers detours nearer to the
artefacts ("a bit under the lower artefact" matches this).

**User override (`edge.detourY`)**: when set, the user's value is honored
but still clamped to the lane band. The dedicated loop-detour handle (a
horizontal pill on the cross-bar) drags this value live.

**Why `detourY` is a separate field, not a routing hint**: the loop-back
case has its own clamping logic that doesn't fit the perpendicular-offset
model of `routingHints`. The detour Y is an *absolute* coordinate constrained
to a lane band; routing hints are *relative offsets* applied to topology-
specific corners. Two different operations, two different fields. The
loop-back handle uses `detourY`; the generic segment handles use
`routingHints`.

### 4.4 Multi-edge spread

When multiple edges leave the same side of the same node, they need to
visually separate. Otherwise three edges all using `E` port would draw on
top of each other.

`buildEdgeGroups(state.edges)` groups edges by `(nodeId, side)`. For each
group of size > 1, `spreadOffset(idx, count, sideLength)` distributes them
evenly along the side, capped at 70% of the side's length (so the spread
doesn't push edges off the side entirely).

`applySpread(edge, anchor)` shifts the anchor along the side perpendicular
to the exit direction. This is computed at render time, cached on a layout
key (`edges.length`, `nodes.length`, hash of port assignments).

**Stable ordering**: within a group, edges are sorted by the Y (or X) of
their *other* endpoint. This minimizes visual crossings. The dragged edge
during a drag is excluded from spread to avoid jitter.

### 4.5 Routing hints

The most recent addition (and the most architecturally subtle).

**Motivation**: the previous design converted edges to manually-routed on
the first segment drag, replacing auto-routing with explicit waypoints.
This broke the "follows nodes as they move" property — once converted,
manual waypoints stuck in place even when source/target moved.

The hint model fixes this: each interior segment can carry a *perpendicular
offset* keyed by stable role (`seg_first`, `seg_mid`, `seg_last`). The
router computes the natural path on every render, then applies offsets
to the appropriate corner coordinates. The edge stays auto-routed.

**`applyRoutingHints(orthoResult, hints, stubA, stubB)`**: takes the
topology-tagged router output and the user's hints, and returns adjusted
corners. The implementation has one case per topology:

- `T0` with a non-zero hint promotes to `T2` (introduces an elbow)
- `T1_*` applies the hint to the single corner along its perp axis
- `T2_*` applies `seg_first` to corner1's perp axis, `seg_last` to corner2's,
  `seg_mid` to both corners' shared axis

**Topology change behavior**: when the user re-pins a port, the topology
may change (T2 → T1, etc.). Hints with roles that don't exist in the new
topology are silently ignored. The edge routes from scratch with whatever
hints still apply. This is deliberate — auto-migrating hints across
topology changes would be complex and unpredictable; silent loss is
predictable.

**Suppression of loop-back when hints are set**: if `edge.routingHints`
has any entries, the loop-back detection is bypassed. The reasoning: the
user has explicitly nudged a segment, so they want the path to go where
they put it, even if it crosses a node. Resolution: they can Reset
routing to restore auto-loop-back, or move the involved nodes.

### 4.6 Precedence summary

When the router decides which routing to use, the order is:

1. **Manual waypoints** (`edge.waypoints.length > 0`) — manual routing
   takes over entirely; ortho router walks segments between waypoints.
2. **`edge.detourY`** — loop-back routing with user-clamped detour.
3. **`edge.routingHints`** — auto-routing with per-segment offsets.
4. **Auto loop-back trigger** — path crosses nodes or `isBackwardFlow`.
5. **Plain auto-routing** — no overrides, no obstacles.

---

## 5. Interaction model

### 5.1 Drag state machines

The editor has five concurrent drag state variables, all top-level:

- `drag` — node drag (single node)
- `groupDrag` — multi-select drag (multiple nodes)
- `edgeDrag` — edge interaction (`kind` varies):
  - `endpoint` — dragging the source or target end of an edge
  - `waypoint` — dragging an existing waypoint
  - `add-waypoint` — pending insert from a midpoint dot (legacy, currently
    not exposed in UI)
  - `loop-detour` — dragging the cross-bar handle of a loop-back edge
  - `segment` — dragging a per-segment handle (updates routingHints)
- `laneResizeDrag` — dragging a lane divider
- `rubberBand` — selection box drag

Only one is active at a time (mutually exclusive at mousedown). Mouseup
clears all of them.

### 5.2 Click-offset capture

A common bug pattern: user clicks a handle, the handle jumps to the
cursor position because the drag code assumes the cursor *is* the new
position. The fix is universal: on mousedown, capture `offX` and `offY` =
`clickPoint - handlePosition`. On mousemove, the new position is
`cursorPoint - (offX, offY)`. Handle stays "glued" to the cursor at the
same relative spot through the whole drag.

This pattern is used on every handle: endpoints, waypoints, add-waypoint
adders, loop-detour, segment handles. Whenever a new drag kind is added,
remember the offset capture.

### 5.3 Snap algorithm (endpoint drag)

When dragging an edge endpoint, the system scans for snap targets:

1. For each node within `NEARBY_RADIUS` (160 px) of the cursor, compute
   the position of each of its 8 ports.
2. Pick the globally closest port to the cursor across all candidates.
3. If that closest port is within `SNAP_RADIUS` (22 px), snap to it.
4. Otherwise, the drag is "floating" — drop in open space cancels.

**Aim-assist** shows ghost dots on all nodes within `AIM_RADIUS` (140 px)
of the cursor, with opacity fading by distance. Helps the user see where
the snap targets are before committing.

**Visual signals during drag**:
- Snap target identified → solid line, status says "release to connect",
  cursor is `alias`
- Open space → dashed faded line, status says "release to cancel", cursor
  is `no-drop`

### 5.4 Why segment handles render only on selected edges

Three reasons:

1. **Visual noise.** With ~15 edges and 3 segments each, all-edges-handles
   would be ~45 pills on the canvas at all times.
2. **Discoverability.** Handles appearing on click connects them to the
   selection model — the user understands "the thing I clicked has
   manipulators."
3. **Hit-test simplicity.** Segment handles need to intercept mousedown
   before the segment line itself. With handles only on selected edges,
   the click-target overlap is contained.

The selected-edge model is consistent with how event/gateway property
panels work too.

---

## 6. Render pipeline

`renderAll()` is the top-level entry. Order:

1. Pool background + lane headers
2. Edges (via `renderEdges`)
3. Nodes (via `renderNodes`)
4. Properties panel (via `renderProperties`)
5. Status overlay (via `updateStatus`)

**Why edges before nodes**: nodes need to draw on top of edge endings.
Otherwise the arrowheads would render under the nodes and look like the
edge passes behind. Z-order via insertion order is the SVG default; we
exploit it.

**Why properties last**: the properties panel is built from the current
selection, which is set during edge/node rendering when a click event
runs. Building properties after the canvas means selection state is
always current.

**Transient fields and timing**: `_renderedPolyline`, `_segmentMeta`,
`_loopDetourY`, `_loopXRange` are set by the router during `renderEdges`.
The handle rendering (also in `renderEdges` after the path) reads them.
They're stale outside that render cycle, which is fine — they're consumed
within the same tick.

---

## 7. XML serialization

`workflowToBpmnXml(state)` produces the BPMN 2.0 XML. Three sections:

1. **Process header** with the laneSet — declares lanes, includes
   `<bpmn:flowNodeRef>` entries pointing at each lane's nodes by displayId.
2. **Nodes** — one `<bpmn:*>` element per node, with the bpmn-spec type tag
   (`bpmn:serviceTask`, `bpmn:exclusiveGateway`, etc.) and the extension
   block carrying aef: fields.
3. **Edges** — one `<bpmn:sequenceFlow>` per edge, with optional
   `<bpmn:conditionExpression>` and the routing extension block.

**Identifier mapping in XML**:

- `bpmn:id` attribute → displayId (readable, mutable)
- `aef:uid` extension → uid (stable, internal)
- `sourceRef` / `targetRef` → displayId of linked node
- `bpmn:flowNodeRef` → displayId

**Round-trip story**: export works. Import does not. When import is built,
it should:

1. Parse the XML
2. Build a uid → node map keyed by `aef:uid`
3. Build a displayId → uid fallback map for nodes lacking `aef:uid`
   (importing from a non-AEF BPMN editor)
4. Rewrite `sourceRef` / `targetRef` from displayIds to uids
5. Recompute displayIds on the resulting state (positions may have changed
   in an external editor, which would alter spatial-seq numbering)

---

## 8. Open architectural questions

### 8.1 Library auto-discovery is not implemented

The editor loads workflows on demand via the Load button (file picker). It
doesn't scan a directory or watch for new files. The library is per-session.

**Why it matters**: when the AEF repo grows to dozens of workflows, manually
loading each one to author cross-workflow link events becomes friction. A
"library index" file or directory-scan would help.

**Why it's not built yet**: the artifact runs in a CDN-only sandbox with no
filesystem access. Real library auto-discovery requires either an export
manifest committed to the repo, or a desktop wrapper around the editor that
can read the filesystem. Both are out of scope for the artifact today.

**Short-term workaround**: keep a small "core workflows" set loaded at the
start of each session (load them once, switch between them via the picker).
Cross-workflow link events you author in that session can validate against
the loaded set.

### 8.2 Undo/redo is not implemented

Every mutation is direct. There is no command history.

**Why it matters**: practically, this is the most-asked-for missing feature
in any editor. Without it, mistakes are unrecoverable.

**The shape it would take**: a command pattern with `do/undo` pairs pushed
to a stack on every mutation. The mutation surface is wide (drag, port
change, name edit, lane add, etc.) so the cleanest approach is probably a
state snapshot before each "transaction" — a transaction being everything
between a user action's start and end (drag start to drag end, or property
edit blur).

### 8.3 No pan/zoom

The canvas grows in size as workflows expand, but there's no way to scroll
or zoom. Workflows wider than the viewport are truncated.

**Why it matters**: most real workflows will exceed initial viewport. The
investigate seed already nearly does.

**The shape it would take**: SVG transform on the root `<g>` element,
driven by drag-on-background (pan) and wheel events (zoom). Coordinate
transforms in `clientToSvg(...)` already exist; pan/zoom would extend
them.

### 8.4 Cross-lane loop-backs don't use lane clamping

The lane-clamping logic in `orthoLoopBack` only applies when
`src.lane === tgt.lane`. Cross-lane loop-backs fall back to wider bounds.
This is acceptable in practice — loops are usually within a single lane —
but inconsistent with the same-lane behavior.

A more thoughtful design would pick "the lane containing the larger node"
or "the lane between source and target lanes" as the clamping band.

### 8.5 Routing hints don't auto-migrate across topology changes

When a port re-pin changes the routing topology, hints keyed by roles that
no longer apply are silently dropped. This is documented behavior, but it
means the user sees their routing visually reset when they didn't ask for it.

An alternative: when transitioning T2 → T1, attempt to map `seg_mid` →
the equivalent role in the new topology. Possible but adds complexity and
introduces edge cases. Current decision: simplicity wins; user re-drags.

### 8.6 No "Insert waypoint" UI

A previous version had a dashed-dot midpoint adder for inserting waypoints
at arbitrary positions. When segment handles were introduced, the dot was
removed to avoid two affordances at the same location. This means there's
currently no in-canvas way to add a manual waypoint at a non-default
position — the routing-hints model covers most cases, but for the edge
case where someone wants a specific bend, the only path is editing the
YAML directly.

If this becomes a real pain point, add a small "Insert waypoint here"
button to the Routing properties section, or restore the dashed dot in a
distinct location (e.g. 1/4 along each segment, not at the midpoint where
the segment handle sits).

### 8.7 Validation is not enforced

The designer will produce invalid files (missing required inputs,
unconditioned exclusive gateways, dangling edges). The `fw workflow
validate` command is the planned enforcement point but doesn't exist yet.

Adding inline validation (red outlines on invalid nodes, problem-list
panel) is straightforward but currently out of scope. The trade-off: the
designer is permissive, which is good for exploration; validation comes
later when the file is committed.

---

## 9. AEF concepts in the codebase

A quick map between AEF concepts and where they appear in the artifact:

| Concept | Where it appears |
|---|---|
| Authority model (Sovereignty/Authority/Initiative) | Lane `authority` field, `AUTHORITIES` constant, default lane definitions, authority-tinted lane backgrounds |
| Action tier (0/1/2/3) | `aef.tier` field on tasks, `tier_default` on workflowMeta |
| Action endpoints | `aef.endpoint` field (free-form: paths, commands, URLs depending on task type) |
| Filesystem contracts | `aef.contextReads` and `aef.artifactsWrites` |
| Typed I/O contracts | `node.io.inputs` and `node.io.outputs` with type from `IO_TYPES` |
| Decision authority | `aef.decisionOwner` on exclusiveGateway, separate from lane authority |
| Manifest maturity ladder | Implicit — this designer is the Stabilization-tier authoring tool |
| Constitutional Directives | Implicit — informs design but not encoded as fields |

---

# 5. Artifact Source

The complete source of `aef-workflow-designer.html`. To run the editor: copy
this section into a `.html` file and open it in any modern browser. No server,
no build step, no external dependencies beyond the inline CDN imports.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>AEF Workflow Designer — investigate.bpmn</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0d0f13;
    --surface: #161922;
    --surface-2: #1d2230;
    --surface-3: #262d3e;
    --border: #2a3142;
    --border-strong: #3a4257;
    --text: #e8eaef;
    --text-dim: #8b91a3;
    --text-faint: #5a6173;
    --accent: #c4ee54;
    --accent-soft: rgba(196,238,84,0.12);
    --blue: #6aa8ff;
    --blue-soft: rgba(106,168,255,0.12);
    --green: #57c785;
    --green-soft: rgba(87,199,133,0.14);
    --orange: #f5a847;
    --orange-soft: rgba(245,168,71,0.14);
    --red: #f06f6f;
    --red-soft: rgba(240,111,111,0.14);
    --purple: #b483f0;
    --purple-soft: rgba(180,131,240,0.14);
    --shadow: 0 1px 0 rgba(255,255,255,0.04) inset, 0 1px 2px rgba(0,0,0,0.4);
    --mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace;
    --sans: 'Outfit', system-ui, -apple-system, sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { height: 100%; overflow: hidden; }
  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    font-size: 13px;
    line-height: 1.45;
    -webkit-font-smoothing: antialiased;
  }

  .app {
    display: grid;
    grid-template-rows: 48px 1fr;
    height: 100vh;
  }

  /* ============ Header ============ */
  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 16px;
    background: linear-gradient(180deg, #15192266 0%, transparent 100%), var(--surface);
    border-bottom: 1px solid var(--border);
  }
  .brand {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .brand-mark {
    font-family: var(--mono);
    font-weight: 600;
    font-size: 11px;
    color: var(--accent);
    padding: 4px 8px;
    background: var(--accent-soft);
    border: 1px solid rgba(196,238,84,0.25);
    border-radius: 3px;
    letter-spacing: 0.04em;
  }
  .brand-title {
    font-weight: 600;
    font-size: 14px;
    letter-spacing: -0.01em;
  }
  .brand-file {
    font-family: var(--mono);
    font-size: 12px;
    color: var(--text-dim);
    margin-left: 4px;
  }
  .brand-separator {
    color: var(--text-faint);
    margin: 0 2px;
  }
  .brand-picker {
    font-family: var(--mono);
    font-size: 12px;
    color: var(--text);
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 3px 6px;
    cursor: pointer;
    max-width: 180px;
  }
  .brand-picker:hover { border-color: var(--accent); }
  .brand-picker:focus { outline: 1px solid var(--accent); outline-offset: 1px; }
  .brand-version {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text-dim);
    background: var(--surface-3);
    padding: 2px 6px;
    border-radius: 3px;
    cursor: pointer;
  }
  .brand-version:hover { color: var(--accent); }
  .btn-icon {
    font-family: var(--sans);
    font-size: 14px;
    font-weight: 600;
    color: var(--text-dim);
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 4px;
    width: 22px;
    height: 22px;
    padding: 0;
    cursor: pointer;
    line-height: 1;
  }
  .btn-icon:hover { color: var(--accent); border-color: var(--accent); }
  .actions {
    display: flex;
    gap: 6px;
  }
  .btn {
    font-family: var(--sans);
    font-size: 12px;
    font-weight: 500;
    color: var(--text-dim);
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 6px 12px;
    cursor: pointer;
    transition: all 0.12s ease;
  }
  .btn:hover { color: var(--text); background: var(--surface-3); border-color: var(--border-strong); }
  .btn-primary { color: var(--accent); border-color: rgba(196,238,84,0.3); background: var(--accent-soft); }
  .btn-primary:hover { background: rgba(196,238,84,0.2); }
  .btn.active { background: var(--accent); color: #0d0f13; border-color: var(--accent); }

  /* ============ Main layout ============ */
  main {
    display: grid;
    grid-template-columns: 220px 1fr 320px;
    min-height: 0;
  }

  /* ============ Palette ============ */
  .palette {
    background: var(--surface);
    border-right: 1px solid var(--border);
    overflow-y: auto;
    padding: 16px 12px;
  }
  .palette-section {
    margin-bottom: 20px;
  }
  .palette-label {
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--text-faint);
    font-weight: 600;
    margin-bottom: 8px;
    padding: 0 4px;
  }
  .palette-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 10px;
    border-radius: 4px;
    cursor: pointer;
    border: 1px solid transparent;
    margin-bottom: 2px;
    transition: all 0.1s ease;
    user-select: none;
  }
  .palette-item:hover {
    background: var(--surface-2);
    border-color: var(--border);
  }
  .palette-item.active {
    background: var(--accent-soft);
    border-color: rgba(196,238,84,0.3);
  }
  .palette-glyph {
    width: 28px;
    height: 28px;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .palette-glyph svg { width: 100%; height: 100%; }
  .palette-text {
    flex: 1;
    min-width: 0;
  }
  .palette-name {
    font-size: 12px;
    color: var(--text);
    font-weight: 500;
  }
  .palette-meta {
    font-size: 10px;
    color: var(--text-faint);
    font-family: var(--mono);
    margin-top: 1px;
  }
  .palette-tool {
    padding: 8px 10px;
    font-size: 11px;
    color: var(--text-dim);
    cursor: pointer;
    border-radius: 4px;
    border: 1px solid var(--border);
    margin-bottom: 4px;
    background: var(--surface-2);
    text-align: center;
    user-select: none;
    transition: all 0.1s ease;
  }
  .palette-tool:hover { color: var(--text); border-color: var(--border-strong); }
  .palette-tool.active { background: var(--accent); color: #0d0f13; border-color: var(--accent); font-weight: 600; }
  .palette-hint {
    font-size: 10px;
    color: var(--text-faint);
    padding: 0 4px;
    line-height: 1.5;
  }

  /* ============ Canvas ============ */
  .canvas-wrap {
    position: relative;
    background:
      radial-gradient(circle at 1px 1px, rgba(255,255,255,0.04) 1px, transparent 0) 0 0/24px 24px,
      var(--bg);
    overflow: hidden;
  }
  #canvas {
    display: block;
    width: 100%;
    height: 100%;
    cursor: default;
  }
  #canvas.mode-create { cursor: crosshair; }
  #canvas.mode-connect { cursor: crosshair; }
  #canvas.drag-endpoint-snap { cursor: alias; }
  #canvas.drag-endpoint-float { cursor: no-drop; }

  .canvas-overlay {
    position: absolute;
    bottom: 12px;
    left: 12px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 8px 12px;
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text-dim);
    pointer-events: none;
  }
  .canvas-overlay .status-mode { color: var(--accent); }

  /* SVG element styles */
  .lane-bg { transition: fill 0.15s ease, stroke 0.15s ease; }
  .lane-bg.selected { stroke: var(--accent); stroke-width: 1.5; }
  .lane-divider { stroke: var(--border); stroke-width: 1; }
  .lane-resize-handle { cursor: ns-resize; }
  .lane-resize-hit { fill: transparent; pointer-events: stroke; pointer-events: all; }
  .lane-resize-grip {
    fill: var(--border-strong);
    opacity: 0;
    transition: opacity 0.12s ease, fill 0.12s ease;
    pointer-events: none;
  }
  .lane-resize-handle:hover .lane-resize-grip { opacity: 1; fill: var(--accent); }
  .lane-resize-handle.dragging .lane-resize-grip { opacity: 1; fill: var(--accent); }
  .lane-label {
    fill: var(--text-faint);
    font-family: var(--mono);
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    font-weight: 500;
  }
  .lane-header { cursor: pointer; }
  .lane-header:hover .lane-label { fill: var(--text); }
  .lane-header.selected .lane-label { font-weight: 600; }
  .pool-label {
    fill: var(--text-dim);
    font-family: var(--sans);
    font-size: 12px;
    font-weight: 600;
  }
  .pool-border {
    fill: none;
    stroke: var(--border-strong);
    stroke-width: 1.5;
  }
  .pool-add-lane { cursor: pointer; }
  .pool-add-lane rect { transition: fill 0.1s ease, stroke 0.1s ease; }
  .pool-add-lane:hover rect { fill: var(--accent-soft); stroke: var(--accent); }
  .pool-add-lane-text {
    fill: var(--text-dim);
    font-family: var(--mono);
    font-size: 10px;
    font-weight: 500;
    letter-spacing: 0.04em;
    pointer-events: none;
  }
  .pool-add-lane:hover .pool-add-lane-text { fill: var(--accent); }

  .pool-add-lane-strip { cursor: pointer; }
  .pool-add-lane-strip-bg {
    fill: var(--surface);
    stroke: var(--border);
    stroke-width: 1;
    stroke-dasharray: 4 3;
    transition: all 0.12s ease;
  }
  .pool-add-lane-strip:hover .pool-add-lane-strip-bg {
    fill: var(--accent-soft);
    stroke: var(--accent);
    stroke-dasharray: none;
  }
  .pool-add-lane-strip-text {
    fill: var(--text-faint);
    font-family: var(--mono);
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.04em;
    pointer-events: none;
    transition: fill 0.12s ease;
  }
  .pool-add-lane-strip:hover .pool-add-lane-strip-text { fill: var(--accent); }

  .node { cursor: pointer; }
  .node-shape { transition: stroke-width 0.1s ease; }
  .node-label { fill: var(--text); font-family: var(--sans); font-size: 11px; font-weight: 500; pointer-events: none; }
  .node-label-sub { fill: var(--text-faint); font-family: var(--mono); font-size: 9px; pointer-events: none; }
  .node-io-badge { fill: var(--text-dim); font-family: var(--mono); font-size: 8px; pointer-events: none; }
  .node-id-badge { fill: var(--text-faint); font-family: var(--mono); font-size: 9px; pointer-events: none; letter-spacing: 0.02em; }
  .node.selected .node-shape { stroke-width: 3px; filter: drop-shadow(0 0 6px var(--accent)); }
  .node.multi-selected .node-shape { stroke-width: 2.5px; filter: drop-shadow(0 0 3px var(--accent)); stroke: var(--accent); }
  .node:hover .node-shape { stroke-width: 2.5px; }

  .edge-path { fill: none; stroke: var(--text-dim); stroke-width: 1.5; transition: stroke 0.1s ease; }
  .edge:hover .edge-path { stroke: var(--text); }
  .edge.selected .edge-path { stroke: var(--accent); stroke-width: 2.5px; }
  .edge.dragging .edge-path { stroke: var(--accent); stroke-width: 2.5px; }
  .edge.dragging .edge-hit { pointer-events: none; }
  /* Floating = dragging but no snap target — release here will cancel */
  .edge.floating .edge-path {
    stroke: var(--text-faint);
    stroke-width: 1.5px;
    stroke-dasharray: 4 3;
    opacity: 0.7;
  }
  .edge-label { fill: var(--text-dim); font-family: var(--mono); font-size: 10px; pointer-events: none; }
  .edge-hit { fill: none; stroke: transparent; stroke-width: 16; cursor: pointer; }

  /* Edge handles — only rendered for the currently selected edge */
  .edge-handle { cursor: grab; }
  .edge-handle:active { cursor: grabbing; }
  .edge-handle-endpoint {
    fill: var(--accent);
    stroke: var(--bg);
    stroke-width: 2;
  }
  .edge-handle-endpoint:hover { fill: #d8ff7d; r: 7; }
  .edge-handle-waypoint {
    fill: var(--accent);
    stroke: var(--bg);
    stroke-width: 2;
    rx: 2;
  }
  .edge-handle-waypoint:hover { fill: #d8ff7d; }
  .edge-handle-add {
    fill: var(--bg);
    stroke: var(--accent);
    stroke-width: 1.5;
    stroke-dasharray: 2 2;
    cursor: copy;
    opacity: 0.6;
  }
  .edge-handle-add:hover { opacity: 1; fill: var(--accent-soft); }
  .edge-handle-detour {
    fill: var(--accent);
    stroke: var(--bg);
    stroke-width: 2;
    cursor: ns-resize;
  }
  .edge-handle-detour:hover { fill: #d8ff7d; }
  .edge-handle-segment {
    fill: var(--accent-soft);
    stroke: var(--accent);
    stroke-width: 1.5;
    opacity: 0.55;
    transition: opacity 0.1s ease, fill 0.1s ease;
  }
  .edge-handle-segment:hover { opacity: 1; fill: var(--accent); }
  .edge-handle-segment.horiz { cursor: ns-resize; }
  .edge-handle-segment.vert  { cursor: ew-resize; }

  /* Highlight a node while an edge endpoint is being dragged onto it */
  .node.hover-target .node-shape { stroke: var(--accent); stroke-width: 3px; filter: drop-shadow(0 0 6px var(--accent)); }

  .connect-preview { stroke: var(--accent); stroke-width: 2; stroke-dasharray: 4 3; fill: none; pointer-events: none; }
  .rubber-band {
    fill: rgba(196, 238, 84, 0.08);
    stroke: var(--accent);
    stroke-width: 1;
    stroke-dasharray: 3 3;
    pointer-events: none;
  }

  /* Port indicators on a node when an edge is selected — click to pin endpoint */
  .port-indicator {
    fill: var(--surface-3);
    stroke: var(--accent);
    stroke-width: 1;
    cursor: pointer;
    transition: r 0.08s ease, fill 0.08s ease;
  }
  .port-indicator:hover {
    fill: var(--accent);
    /* r is set via attribute; size up via stroke */
    stroke-width: 2;
  }
  .port-indicator.active {
    fill: var(--accent);
    stroke: var(--bg);
    stroke-width: 2;
  }
  .port-indicator-auto {
    fill: var(--surface);
    stroke-dasharray: 1.5 1.5;
    opacity: 0.65;
  }
  .port-indicator-auto:hover { opacity: 1; }
  .port-indicator-auto.active {
    fill: var(--accent);
    stroke-dasharray: none;
    opacity: 1;
  }
  /* Ghost port shown during endpoint drag to indicate snap target */
  .port-indicator-snap {
    fill: none;
    stroke: var(--accent);
    stroke-width: 2;
    stroke-dasharray: 2 2;
    pointer-events: none;
  }
  /* Aim-assist: ghost ports on nearby nodes during endpoint drag */
  .port-aim-assist {
    fill: var(--accent);
    stroke: var(--bg);
    stroke-width: 1;
    pointer-events: none;
  }

  /* ============ Properties panel ============ */
  .properties {
    background: var(--surface);
    border-left: 1px solid var(--border);
    overflow-y: auto;
    display: flex;
    flex-direction: column;
  }
  .props-empty {
    padding: 40px 20px;
    color: var(--text-faint);
    text-align: center;
    font-size: 12px;
    line-height: 1.6;
  }
  .props-empty .kbd {
    display: inline-block;
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 1px 6px;
    font-family: var(--mono);
    font-size: 10px;
    color: var(--text-dim);
    margin: 0 2px;
  }
  .props-tips { font-size: 11px; color: var(--text-faint); line-height: 1.7; padding: 4px 0; }
  .props-tips .kbd {
    display: inline-block;
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 0 5px;
    font-family: var(--mono);
    font-size: 10px;
    color: var(--text-dim);
    margin: 0 1px;
  }
  .props-lib-list { display: flex; flex-direction: column; gap: 2px; }
  .props-lib-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 6px 8px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
    color: var(--text-dim);
    border: 1px solid transparent;
  }
  .props-lib-row:hover { background: var(--surface-2); color: var(--text); }
  .props-lib-row.active {
    background: var(--surface-2);
    border-color: var(--accent);
    color: var(--text);
    cursor: default;
  }
  .props-lib-name { font-weight: 500; }
  .props-lib-id { font-family: var(--mono); font-size: 10px; color: var(--text-faint); }
  .props-header {
    padding: 14px 16px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .props-type-badge {
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .props-type-badge svg { width: 100%; height: 100%; }
  .props-type-info { flex: 1; min-width: 0; }
  .props-type-name { font-size: 13px; font-weight: 600; color: var(--text); }
  .props-type-id { font-family: var(--mono); font-size: 10px; color: var(--text-faint); margin-top: 1px; }
  .props-delete {
    color: var(--red);
    background: transparent;
    border: 1px solid transparent;
    border-radius: 3px;
    padding: 4px 8px;
    cursor: pointer;
    font-size: 11px;
    font-family: var(--mono);
  }
  .props-delete:hover { border-color: var(--red); background: var(--red-soft); }

  .props-section {
    border-bottom: 1px solid var(--border);
    padding: 12px 16px;
  }
  .props-section-title {
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--text-faint);
    font-weight: 600;
    margin-bottom: 10px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .props-section-title .ns-tag {
    background: var(--accent-soft);
    color: var(--accent);
    padding: 1px 5px;
    border-radius: 2px;
    font-family: var(--mono);
    font-size: 9px;
    letter-spacing: 0.05em;
  }
  .field {
    margin-bottom: 10px;
  }
  .field:last-child { margin-bottom: 0; }
  .field-label {
    font-size: 11px;
    color: var(--text-dim);
    font-weight: 500;
    margin-bottom: 4px;
    display: flex;
    align-items: baseline;
    gap: 6px;
  }
  .field-label .field-hint {
    font-family: var(--mono);
    font-size: 9px;
    color: var(--text-faint);
    font-weight: 400;
  }
  .field-input, .field-select, .field-textarea {
    width: 100%;
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 3px;
    color: var(--text);
    font-family: var(--mono);
    font-size: 11px;
    padding: 6px 8px;
    outline: none;
    transition: border-color 0.1s ease;
  }
  .field-input:focus, .field-select:focus, .field-textarea:focus {
    border-color: var(--accent);
  }
  .field-textarea {
    resize: vertical;
    min-height: 50px;
    line-height: 1.4;
  }
  .field-select {
    appearance: none;
    -webkit-appearance: none;
    background-image: linear-gradient(45deg, transparent 50%, var(--text-dim) 50%), linear-gradient(135deg, var(--text-dim) 50%, transparent 50%);
    background-position: calc(100% - 14px) 50%, calc(100% - 9px) 50%;
    background-size: 5px 5px, 5px 5px;
    background-repeat: no-repeat;
    padding-right: 24px;
  }
  .tier-row { display: flex; gap: 4px; }
  .tier-btn {
    flex: 1;
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 5px;
    text-align: center;
    cursor: pointer;
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text-dim);
    transition: all 0.1s ease;
  }
  .tier-btn:hover { color: var(--text); border-color: var(--border-strong); }
  .tier-btn.active.tier-0 { background: var(--red-soft); color: var(--red); border-color: var(--red); }
  .tier-btn.active.tier-1 { background: var(--orange-soft); color: var(--orange); border-color: var(--orange); }
  .tier-btn.active.tier-2 { background: var(--green-soft); color: var(--green); border-color: var(--green); }
  .tier-btn.active.tier-3 { background: var(--blue-soft); color: var(--blue); border-color: var(--blue); }

  /* I/O list editor */
  .io-list { display: flex; flex-direction: column; gap: 4px; margin-bottom: 6px; }
  .io-empty {
    font-size: 11px;
    color: var(--text-faint);
    font-family: var(--mono);
    padding: 4px 0;
    font-style: italic;
  }
  .io-row {
    display: grid;
    grid-template-columns: 1fr 78px auto auto;
    gap: 4px;
    align-items: center;
  }
  .io-row.no-req { grid-template-columns: 1fr 78px auto; }
  .io-name, .io-type {
    background: var(--surface-2);
    border: 1px solid var(--border);
    border-radius: 3px;
    color: var(--text);
    font-family: var(--mono);
    font-size: 11px;
    padding: 4px 6px;
    outline: none;
    min-width: 0;
  }
  .io-name:focus, .io-type:focus { border-color: var(--accent); }
  .io-type {
    appearance: none;
    -webkit-appearance: none;
    padding-right: 16px;
    background-image: linear-gradient(45deg, transparent 50%, var(--text-dim) 50%), linear-gradient(135deg, var(--text-dim) 50%, transparent 50%);
    background-position: calc(100% - 9px) 50%, calc(100% - 5px) 50%;
    background-size: 4px 4px, 4px 4px;
    background-repeat: no-repeat;
  }
  .io-req {
    display: flex;
    align-items: center;
    gap: 3px;
    font-family: var(--mono);
    font-size: 10px;
    color: var(--text-faint);
    user-select: none;
    cursor: pointer;
    padding: 0 2px;
  }
  .io-req input { accent-color: var(--accent); width: 12px; height: 12px; margin: 0; cursor: pointer; }
  .io-del {
    color: var(--text-faint);
    cursor: pointer;
    font-size: 14px;
    padding: 0 4px;
    line-height: 1;
    user-select: none;
  }
  .io-del:hover { color: var(--red); }
  .io-add {
    font-family: var(--mono);
    font-size: 10px;
    color: var(--text-dim);
    cursor: pointer;
    padding: 4px 6px;
    border: 1px dashed var(--border);
    border-radius: 3px;
    text-align: center;
    user-select: none;
    transition: all 0.1s ease;
  }
  .io-add:hover { color: var(--accent); border-color: var(--accent); background: var(--accent-soft); }

  /* Routing section */
  .routing-info {
    font-family: var(--mono);
    font-size: 10px;
    color: var(--text-dim);
    line-height: 1.7;
    margin-bottom: 8px;
  }
  .routing-info strong { color: var(--text-faint); font-weight: 500; }
  .routing-info .mono { color: var(--accent); }
  .routing-tip {
    font-size: 11px;
    color: var(--text-faint);
    line-height: 1.5;
    margin-bottom: 10px;
    padding: 8px 10px;
    background: var(--surface-2);
    border-radius: 3px;
    border-left: 2px solid var(--accent);
  }
  .routing-actions { display: flex; gap: 4px; flex-wrap: wrap; }
  .btn-routing {
    flex: 1;
    min-width: 0;
    padding: 5px 8px;
    font-size: 11px;
  }
  .btn-routing:disabled {
    opacity: 0.35;
    cursor: not-allowed;
  }

  /* Lane height stepper */
  .lane-height-row {
    display: grid;
    grid-template-columns: 32px 1fr 32px;
    gap: 4px;
  }
  .lane-height-row .btn-routing { flex: none; padding: 5px; font-size: 13px; line-height: 1; }
  .lane-height-row .field-input { font-size: 11px; padding: 5px; }

  /* ============ XML panel ============ */
  .xml-panel {
    position: fixed;
    inset: 48px 0 0 0;
    background: var(--bg);
    z-index: 50;
    display: none;
    flex-direction: column;
  }
  .xml-panel.visible { display: flex; }
  .xml-panel-header {
    padding: 12px 20px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    background: var(--surface);
  }
  .xml-panel-title {
    font-family: var(--mono);
    font-size: 12px;
    color: var(--text-dim);
  }
  .xml-panel-title strong { color: var(--accent); }
  .xml-content {
    flex: 1;
    overflow: auto;
    padding: 20px;
  }
  .xml-content pre {
    font-family: var(--mono);
    font-size: 12px;
    line-height: 1.55;
    color: var(--text);
    white-space: pre;
  }
  .xml-content .x-tag { color: var(--blue); }
  .xml-content .x-aef { color: var(--accent); }
  .xml-content .x-attr { color: var(--orange); }
  .xml-content .x-val { color: var(--green); }
  .xml-content .x-com { color: var(--text-faint); font-style: italic; }

  /* ============ Misc ============ */
  ::-webkit-scrollbar { width: 8px; height: 8px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 4px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--border-strong); }
</style>
</head>
<body>
<div class="app">
  <header>
    <div class="brand">
      <span class="brand-mark">AEF · BPMN</span>
      <span class="brand-title">Workflow Designer</span>
      <span class="brand-separator">·</span>
      <select class="brand-picker" id="workflow-picker" title="Switch workflow"></select>
      <button class="btn-icon" id="btn-new-workflow" title="New workflow">+</button>
      <span class="brand-version" id="brand-version">v1</span>
    </div>
    <div class="actions">
      <button class="btn" id="btn-add-lane">+ Add Lane</button>
      <button class="btn" id="btn-reset">Reset</button>
      <button class="btn" id="btn-xml">View XML</button>
      <button class="btn" id="btn-load">Load…</button>
      <button class="btn btn-primary" id="btn-save">Save</button>
    </div>
  </header>

  <main>
    <!-- ============ Palette ============ -->
    <aside class="palette">
      <div class="palette-section">
        <div class="palette-label">Tool</div>
        <div class="palette-tool active" data-mode="select" id="tool-select">Select / Move</div>
        <div class="palette-tool" data-mode="connect" id="tool-connect">Connect →</div>
      </div>

      <div class="palette-section">
        <div class="palette-label">Events</div>
        <div class="palette-item" data-create="startEvent">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--green-soft)" stroke="var(--green)" stroke-width="1.5"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Start</div>
            <div class="palette-meta">startEvent</div>
          </div>
        </div>
        <div class="palette-item" data-create="endEvent">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--red-soft)" stroke="var(--red)" stroke-width="3"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">End</div>
            <div class="palette-meta">endEvent</div>
          </div>
        </div>
      </div>

      <div class="palette-section">
        <div class="palette-label">Tasks</div>
        <div class="palette-item" data-create="serviceTask">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--blue-soft)" stroke="var(--blue)" stroke-width="1.5"/><circle cx="8" cy="11" r="1.4" fill="var(--blue)"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Service Task</div>
            <div class="palette-meta">agent · Initiative</div>
          </div>
        </div>
        <div class="palette-item" data-create="userTask">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/><circle cx="8" cy="11" r="1.4" fill="var(--accent)"/><path d="M6 14 q2 -2 4 0" stroke="var(--accent)" stroke-width="1.2" fill="none"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">User Task</div>
            <div class="palette-meta">human · Sovereignty</div>
          </div>
        </div>
        <div class="palette-item" data-create="scriptTask">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--orange-soft)" stroke="var(--orange)" stroke-width="1.5"/><path d="M6 10 h6 M6 13 h8 M6 16 h5" stroke="var(--orange)" stroke-width="1"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Script Task</div>
            <div class="palette-meta">fw · Authority</div>
          </div>
        </div>
      </div>

      <div class="palette-section">
        <div class="palette-label">Gateways</div>
        <div class="palette-item" data-create="exclusiveGateway">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><path d="M14 4 L24 14 L14 24 L4 14 Z" fill="var(--orange-soft)" stroke="var(--orange)" stroke-width="1.5"/><path d="M10 10 L18 18 M18 10 L10 18" stroke="var(--orange)" stroke-width="1.5" stroke-linecap="round"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Exclusive (XOR)</div>
            <div class="palette-meta">decision</div>
          </div>
        </div>
        <div class="palette-item" data-create="parallelGateway">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28"><path d="M14 4 L24 14 L14 24 L4 14 Z" fill="var(--blue-soft)" stroke="var(--blue)" stroke-width="1.5"/><path d="M14 9 V19 M9 14 H19" stroke="var(--blue)" stroke-width="1.5" stroke-linecap="round"/></svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Parallel (AND)</div>
            <div class="palette-meta">fork / join</div>
          </div>
        </div>
      </div>

      <div class="palette-section">
        <div class="palette-label">Handoffs</div>
        <div class="palette-item" data-create="linkEventThrow">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28">
              <circle cx="14" cy="14" r="11" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/>
              <path d="M9 8 L17 14 L9 20" stroke="var(--accent)" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Handoff →</div>
            <div class="palette-meta">to another workflow</div>
          </div>
        </div>
        <div class="palette-item" data-create="linkEventCatch">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28">
              <circle cx="14" cy="14" r="11" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/>
              <path d="M19 8 L11 14 L19 20" stroke="var(--accent)" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">← Handoff</div>
            <div class="palette-meta">from another workflow</div>
          </div>
        </div>
      </div>

      <div class="palette-section">
        <div class="palette-label">Lanes</div>
        <div class="palette-item" id="palette-add-lane">
          <div class="palette-glyph">
            <svg viewBox="0 0 28 28">
              <rect x="3" y="5" width="22" height="18" rx="2" fill="none" stroke="var(--accent)" stroke-width="1.5"/>
              <line x1="9" y1="5" x2="9" y2="23" stroke="var(--accent)" stroke-width="1.2"/>
              <line x1="3" y1="14" x2="25" y2="14" stroke="var(--accent)" stroke-width="0.8" stroke-dasharray="2 2"/>
              <text x="19" y="11" fill="var(--accent)" font-family="monospace" font-size="9" font-weight="700" text-anchor="middle">+</text>
            </svg>
          </div>
          <div class="palette-text">
            <div class="palette-name">Add Lane</div>
            <div class="palette-meta">swimlane · authority</div>
          </div>
        </div>
      </div>

      <div class="palette-section">
        <div class="palette-hint">Click a palette item, then click on the canvas to place. <br><br>To connect, switch to <b>Connect</b>, click source, then click target. <br><br><b>+ Add Lane</b> appends a new swimlane to the pool.</div>
      </div>
    </aside>

    <!-- ============ Canvas ============ -->
    <div class="canvas-wrap">
      <svg id="canvas" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
            <path d="M0,0 L10,5 L0,10 z" fill="var(--text-dim)" />
          </marker>
          <marker id="arrow-selected" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
            <path d="M0,0 L10,5 L0,10 z" fill="var(--accent)" />
          </marker>
        </defs>
        <g id="g-pool"></g>
        <g id="g-edges"></g>
        <g id="g-nodes"></g>
        <g id="g-preview"></g>
      </svg>
      <div class="canvas-overlay" id="status">
        Mode: <span class="status-mode" id="status-mode">select</span><span id="status-selection"></span>
      </div>
    </div>

    <!-- ============ Properties panel ============ -->
    <aside class="properties" id="properties">
      <div class="props-empty">
        Click a node to inspect.<br><br>
        <span class="kbd">Connect</span> mode → click source then target to draw a sequence flow.<br><br>
        Drag any selected node to reposition.
      </div>
    </aside>
  </main>

  <!-- ============ XML view (overlay) ============ -->
  <div class="xml-panel" id="xml-panel">
    <div class="xml-panel-header">
      <div class="xml-panel-title">Canonical BPMN 2.0 XML — <strong>investigate.bpmn</strong> (with <strong>aef:</strong> extensions)</div>
      <div class="actions">
        <button class="btn" id="btn-copy-xml">Copy</button>
        <button class="btn" id="btn-close-xml">Close</button>
      </div>
    </div>
    <div class="xml-content"><pre id="xml-output"></pre></div>
  </div>
</div>

<script>
//
// ============================================================================
//  AEF Workflow Designer — minimal BPMN 2.0 subset editor
// ============================================================================
//
//  Eight-element subset:
//    startEvent, endEvent,
//    serviceTask (Agent / Initiative),
//    userTask    (Human / Sovereignty),
//    scriptTask  (Framework / Authority),
//    exclusiveGateway, parallelGateway,
//    sequenceFlow
//
//  Three swimlanes mirror the AEF authority model:
//    Human  → Sovereignty
//    Framework → Authority
//    Agent  → Initiative
//
//  Every node carries an aef:extensionElements payload that AEF can
//  enrich at design-time (id, endpoint, tier, contextReads,
//  artifactsWrites, decisionOwner, etc.) and read at run-time.
//

const LANE_HEADER = 60;       // left header width (vertical lane labels)
const POOL_HEADER = 32;       // top pool header height
const POOL_X = 30, POOL_Y = 30;
const POOL_WIDTH = 1480;

// Authority enum — applied to lanes; influences validation (D1 lane-authority check)
const AUTHORITIES = ['sovereignty', 'authority', 'initiative', 'external', 'none'];
const AUTHORITY_COLOR = {
  sovereignty: 'rgba(196,238,84,0.025)',  // accent (human)
  authority:   'rgba(106,168,255,0.025)', // blue (framework)
  initiative:  'rgba(180,131,240,0.025)', // purple (agent)
  external:    'rgba(245,168,71,0.025)',  // orange
  none:        'transparent',
};
const AUTHORITY_LABEL_COLOR = {
  sovereignty: 'var(--accent)',
  authority:   'var(--blue)',
  initiative:  'var(--purple)',
  external:    'var(--orange)',
  none:        'var(--text-faint)',
};

// Default lanes for a new workflow — mirror AEF's three-role authority model.
function defaultLanes() {
  return [
    { id: 'human',     name: 'Human · Sovereignty',     abbr: 'hum', authority: 'sovereignty', height: 130 },
    { id: 'framework', name: 'Framework · Authority',   abbr: 'frw', authority: 'authority',   height: 130 },
    { id: 'agent',     name: 'Agent · Initiative',      abbr: 'agt', authority: 'initiative',  height: 320 },
  ];
}

// ============================================================================
//  uid + slug + displayId
// ============================================================================
//
// Two-identifier model:
//   - uid:       immutable, autogenerated, never user-edited. The contract.
//                Edges reference nodes by uid. Audit logs persist uid.
//   - displayId: computed as `<lane.abbr>_<spatial-seq>_<slug>`.
//                Never stored. Always re-derived from current state.
//                Used for canvas labels, conversation, BPMN export.
//
// slug: user-editable short identifier on the node; first word of the display
// name by default, but the user can override it independently.
//
// abbr: 3-char identifier on each lane; user-editable; defaulted from name.

function generateUid(prefix) {
  // short uid: prefix + 8 hex chars. Collision-resistant enough for a workflow file,
  // readable in audit logs.
  const hex = Array.from({ length: 8 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
  return `${prefix}_${hex}`;
}

// Derive a short slug from a display name. First "significant" word (>1 char),
// lowercased, stripped of non-alphanum. Falls back to 'node' if nothing usable.
function deriveSlug(displayName) {
  if (!displayName) return 'node';
  const words = displayName
    .toLowerCase()
    .replace(/[^a-z0-9\s\-]/g, ' ')
    .split(/[\s\-]+/)
    .filter(w => w.length > 1);
  return (words[0] || 'node').slice(0, 16);
}

// Derive a slug that's unique within its lane (among other nodes in that lane).
// If the base slug collides with siblings, append `-2`, `-3`, ... until unique.
function deriveUniqueSlug(node, displayName) {
  const base = deriveSlug(displayName);
  const siblings = state.nodes.filter(other => other !== node && other.lane === node.lane);
  if (!siblings.some(s => s.slug === base)) return base;
  let n = 2;
  while (siblings.some(s => s.slug === `${base}-${n}`)) n++;
  return `${base}-${n}`;
}

// Derive a 3-char lane abbreviation from its name. Conservative: take the
// first three alphanumeric characters of the first significant word.
function deriveLaneAbbr(laneName) {
  if (!laneName) return 'lan';
  const firstWord = laneName.toLowerCase().replace(/[^a-z0-9\s]/g, '').split(/\s+/).filter(Boolean)[0] || 'lan';
  return firstWord.slice(0, 3);
}

// Ensure a candidate abbreviation is unique among existing lanes (excluding the
// lane being renamed). If it collides, append/swap characters until unique.
function ensureUniqueAbbr(lane, candidate) {
  const others = state.lanes.filter(l => l !== lane);
  if (!others.some(l => l.abbr === candidate)) return candidate;
  // try variations: first 2 chars + digit
  const base = candidate.slice(0, 2);
  for (let i = 2; i <= 9; i++) {
    const c = base + i;
    if (!others.some(l => l.abbr === c)) return c;
  }
  // fall back: 'la' + digit
  for (let i = 1; i <= 99; i++) {
    const c = ('la' + i).slice(0, 3);
    if (!others.some(l => l.abbr === c)) return c;
  }
  return candidate; // give up
}

// Compute a node's displayId from its slug, lane, and spatial position.
// Spatial position = 1-based rank by x-coordinate among nodes in the same lane.
// If two nodes share an x exactly, uid order breaks the tie deterministically.
function computeDisplayId(node) {
  const lane = findLane(node.lane);
  const abbr = lane?.abbr || 'lan';
  const sameLane = state.nodes
    .filter(n => n.lane === node.lane)
    .slice()
    .sort((a, b) => a.x - b.x || a.uid.localeCompare(b.uid));
  const seq = sameLane.findIndex(n => n.uid === node.uid) + 1;
  const slug = node.slug || deriveSlug(node.name);
  return `${abbr}_${seq}_${slug}`;
}

// Edge displayId: `flow_<seq>` where seq is the edge's index in state.edges.
// This is the simple anonymous numbering — labels carry the semantics for
// edges that have them.
function computeEdgeDisplayId(edge) {
  const seq = state.edges.findIndex(e => e.uid === edge.uid) + 1;
  return `flow_${seq}`;
}

// DisplayId cache: maps uid → current displayId. Recomputed only on commit
// events (drop, add, delete, lane move, slug/abbr/name edits) — NOT during
// in-progress drags. This gives the user a stable label while they're
// manipulating the diagram, with renumbering happening at quiet moments.
let _displayIdCache = new Map();

function refreshDisplayIds() {
  _displayIdCache = new Map();
  for (const node of state.nodes) {
    _displayIdCache.set(node.uid, computeDisplayId(node));
  }
  for (const edge of state.edges) {
    _displayIdCache.set(edge.uid, computeEdgeDisplayId(edge));
  }
}

function displayIdOf(thing) {
  // Returns the cached displayId, falling back to live compute if missing.
  if (!thing) return '';
  const cached = _displayIdCache.get(thing.uid);
  if (cached !== undefined) return cached;
  if (state.nodes.includes(thing)) return computeDisplayId(thing);
  if (state.edges.includes(thing)) return computeEdgeDisplayId(thing);
  return '';
}

// Lookup a node by uid (replacing findNode's old id lookup).
function findNodeByUid(uid) { return state.nodes.find(n => n.uid === uid); }

// Lookup a node by display id (for convenience / for the future agent contract
// where authors might write displayIds in conditions).
function findNodeByDisplayId(displayId) {
  return state.nodes.find(n => computeDisplayId(n) === displayId);
}

const NODE_DEFAULTS = {
  startEvent:        { w: 36, h: 36, lane: 'framework' },
  endEvent:          { w: 36, h: 36, lane: 'framework' },
  serviceTask:       { w: 110, h: 64, lane: 'agent' },
  userTask:          { w: 110, h: 64, lane: 'human' },
  scriptTask:        { w: 110, h: 64, lane: 'framework' },
  exclusiveGateway:  { w: 48, h: 48, lane: 'agent' },
  parallelGateway:   { w: 48, h: 48, lane: 'agent' },
  // Link events — off-page connectors that hand off to (throw) or receive
  // from (catch) another workflow. Visually a hollow circle with a chevron.
  linkEventThrow:    { w: 36, h: 36, lane: 'framework' },
  linkEventCatch:    { w: 36, h: 36, lane: 'framework' },
};

// Which aef:* fields are meaningful for each node type.
const AEF_FIELDS = {
  startEvent:   ['triggeredBy', 'contextReads'],
  endEvent:     ['emits'],
  serviceTask:  ['tier', 'agentType', 'endpoint', 'contextReads', 'artifactsWrites'],
  userTask:     ['tier', 'endpoint', 'decisionOutputs'],
  scriptTask:   ['tier', 'endpoint', 'contextReads', 'artifactsWrites'],
  exclusiveGateway: ['decisionInput', 'decisionOwner'],
  parallelGateway: [],
  linkEventThrow: ['targetWorkflow', 'linkId'],
  linkEventCatch: ['targetWorkflow', 'linkId'],
};

const FIELD_META = {
  triggeredBy:    { label: 'Triggered by',    hint: 'event or fw command', textarea: false },
  contextReads:   { label: 'Context reads',   hint: 'paths · comma-separated', textarea: true },
  artifactsWrites:{ label: 'Artifacts writes',hint: 'paths · comma-separated', textarea: true },
  emits:          { label: 'Emits',           hint: 'event name(s)', textarea: false },
  tier:           { label: 'Tier',            hint: '0=tier0 / 1 / 2 / 3', special: 'tier' },
  agentType:      { label: 'Agent type',      hint: 'primary | termlink-worker | human', special: 'select', options: ['primary', 'termlink-worker', 'human'] },
  endpoint:       { label: 'Endpoint',        hint: 'fw … | agent prompt | watchtower view', textarea: true },
  decisionInput:  { label: 'Decision input',  hint: 'expression, e.g. ${findings.confidence}', textarea: false },
  decisionOwner:  { label: 'Decision owner',  hint: 'agent | human | framework', special: 'select', options: ['agent', 'human', 'framework'] },
  decisionOutputs:{ label: 'Decision outputs',hint: 'enum, comma-separated', textarea: false },
  targetWorkflow: { label: 'Target workflow', hint: 'id of the other workflow', special: 'workflowPicker' },
  linkId:         { label: 'Link ID',         hint: 'identifier shared with matching catch/throw', textarea: false },
};

// I/O contract — which node types declare typed inputs/outputs, and the type vocabulary.
// This is the *data contract* that flows between steps, distinct from `contextReads`
// (ambient filesystem reads) and `artifactsWrites` (filesystem writes).
const NODE_IO = {
  startEvent:       { in: false, out: true  },
  endEvent:         { in: true,  out: false },
  serviceTask:      { in: true,  out: true  },
  userTask:         { in: true,  out: true  },
  scriptTask:       { in: true,  out: true  },
  exclusiveGateway: { in: true,  out: false }, // gateway reads to decide; outflows are routing, not data
  parallelGateway:  { in: false, out: false }, // pure routing
  // Throw: receives inputs from the workflow and emits them to the target.
  // Catch: emits outputs into the workflow from the receiving workflow.
  linkEventThrow:   { in: true,  out: false },
  linkEventCatch:   { in: false, out: true  },
};
const IO_TYPES = ['string', 'number', 'boolean', 'ref', 'path', 'task_id', 'arc_id', 'list', 'object'];

// ----------------------------------------------------------------------------
//  Initial workflow — investigate.bpmn
// ----------------------------------------------------------------------------
function getInvestigateWorkflow() {
  const lanes = defaultLanes();
  // Stage lanes into a temporary state so laneCenterY() resolves correctly during seed construction.
  // We restore the previous state on the way out.
  const prevState = state;
  state = { lanes };
  const result = {
    lanes,
    pool: { id: 'Pool_investigate', name: 'investigate' },
    workflowMeta: {
      id: 'investigate',
      version: '1',
      schemaVersion: 2,
      title: 'Investigate',
      description: 'Decompose a question, gather context across code/history/related tasks, synthesize findings, and route to human review.',
      source: 'agents/dispatch/investigate.md',
      tier_default: '2',
    },
    nodes: [
      { id: 'Start_request',         type: 'startEvent',       name: 'Investigation requested', lane: 'framework', x: POOL_X + LANE_HEADER + 30,  y: laneCenterY('framework') - 18,
        aef: { triggeredBy: 'fw dispatch investigate ${task_id}', contextReads: '.tasks/active/${task_id}.md' },
        io: { outputs: [{ name: 'task_id', type: 'task_id' }, { name: 'run_id', type: 'string' }] } },

      { id: 'Script_loadContext',    type: 'scriptTask',       name: 'Load context bundle', lane: 'framework', x: POOL_X + LANE_HEADER + 110, y: laneCenterY('framework') - 32,
        aef: { tier: '2', endpoint: 'fw context build --task ${task_id} --depth 2',
               contextReads: '.context/project/, .context/episodic/, policy/anti-patterns.yaml',
               artifactsWrites: '.context/working/investigate-${run_id}/bundle.yaml' },
        io: { inputs: [{ name: 'task_id', type: 'task_id', required: true }, { name: 'run_id', type: 'string', required: true }],
              outputs: [{ name: 'bundle', type: 'ref' }] } },

      { id: 'Service_decompose',     type: 'serviceTask',      name: 'Decompose problem', lane: 'agent', x: POOL_X + LANE_HEADER + 260, y: laneCenterY('agent') - 32,
        aef: { tier: '2', agentType: 'primary', endpoint: 'agents/dispatch/skills/decompose.md',
               contextReads: '.context/working/investigate-${run_id}/bundle.yaml',
               artifactsWrites: '.context/working/investigate-${run_id}/sub-questions.yaml' },
        io: { inputs: [{ name: 'bundle', type: 'ref', required: true }],
              outputs: [{ name: 'sub_questions', type: 'list' }] } },

      { id: 'GW_fork',               type: 'parallelGateway',  name: 'Fan out', lane: 'agent', x: POOL_X + LANE_HEADER + 410, y: laneCenterY('agent') - 24,
        aef: {} },

      { id: 'Service_searchCode',    type: 'serviceTask',      name: 'Search codebase', lane: 'agent', x: POOL_X + LANE_HEADER + 510, y: laneCenterY('agent') - 110,
        aef: { tier: '2', agentType: 'termlink-worker', endpoint: 'fw recall ${sub_questions} --scope code',
               contextReads: '.fabric/, src/',
               artifactsWrites: '.context/working/investigate-${run_id}/evidence-code.yaml' },
        io: { inputs: [{ name: 'sub_questions', type: 'list', required: true }],
              outputs: [{ name: 'evidence_code', type: 'ref' }] } },

      { id: 'Service_searchHistory', type: 'serviceTask',      name: 'Search episodes', lane: 'agent', x: POOL_X + LANE_HEADER + 510, y: laneCenterY('agent') - 32,
        aef: { tier: '2', agentType: 'termlink-worker', endpoint: 'fw recall ${sub_questions} --scope episodic',
               contextReads: '.context/episodic/, .context/handovers/',
               artifactsWrites: '.context/working/investigate-${run_id}/evidence-history.yaml' },
        io: { inputs: [{ name: 'sub_questions', type: 'list', required: true }],
              outputs: [{ name: 'evidence_history', type: 'ref' }] } },

      { id: 'Service_searchRelated', type: 'serviceTask',      name: 'Search tasks & arcs', lane: 'agent', x: POOL_X + LANE_HEADER + 510, y: laneCenterY('agent') + 46,
        aef: { tier: '2', agentType: 'termlink-worker', endpoint: 'fw recall ${sub_questions} --scope tasks,arcs',
               contextReads: '.tasks/, .context/arcs/',
               artifactsWrites: '.context/working/investigate-${run_id}/evidence-related.yaml' },
        io: { inputs: [{ name: 'sub_questions', type: 'list', required: true }],
              outputs: [{ name: 'evidence_related', type: 'ref' }] } },

      { id: 'GW_join',               type: 'parallelGateway',  name: 'Join', lane: 'agent', x: POOL_X + LANE_HEADER + 660, y: laneCenterY('agent') - 24,
        aef: {} },

      { id: 'Service_synthesize',    type: 'serviceTask',      name: 'Synthesize findings', lane: 'agent', x: POOL_X + LANE_HEADER + 760, y: laneCenterY('agent') - 32,
        aef: { tier: '2', agentType: 'primary', endpoint: 'agents/dispatch/skills/synthesize.md',
               contextReads: '.context/working/investigate-${run_id}/evidence-*.yaml',
               artifactsWrites: '.context/working/investigate-${run_id}/findings.yaml' },
        io: { inputs: [{ name: 'evidence_code', type: 'ref', required: true },
                       { name: 'evidence_history', type: 'ref', required: true },
                       { name: 'evidence_related', type: 'ref', required: true }],
              outputs: [{ name: 'findings', type: 'ref' }] } },

      { id: 'GW_sufficient',         type: 'exclusiveGateway', name: 'Sufficient?', lane: 'agent', x: POOL_X + LANE_HEADER + 920, y: laneCenterY('agent') - 24,
        aef: { decisionInput: '${findings.confidence}', decisionOwner: 'agent' },
        io: { inputs: [{ name: 'findings', type: 'ref', required: true }] } },

      { id: 'Script_writeReport',    type: 'scriptTask',       name: 'Write report', lane: 'framework', x: POOL_X + LANE_HEADER + 1020, y: laneCenterY('framework') - 32,
        aef: { tier: '2', endpoint: 'fw report write investigate --run ${run_id}',
               contextReads: '.context/working/investigate-${run_id}/findings.yaml',
               artifactsWrites: 'docs/reports/investigate-${run_id}.md, .context/audits/investigate-runs.jsonl' },
        io: { inputs: [{ name: 'findings', type: 'ref', required: true }, { name: 'run_id', type: 'string', required: true }],
              outputs: [{ name: 'report_path', type: 'path' }, { name: 'audit_entry', type: 'ref' }] } },

      { id: 'User_review',           type: 'userTask',         name: 'Human review & route', lane: 'human', x: POOL_X + LANE_HEADER + 1170, y: laneCenterY('human') - 32,
        aef: { tier: '1', endpoint: 'watchtower:/investigate/runs/${run_id}',
               decisionOutputs: 'dispatch, abandon, reinvestigate' },
        io: { inputs: [{ name: 'report_path', type: 'path', required: true }],
              outputs: [{ name: 'route', type: 'string' }] } },

      { id: 'End_ready',             type: 'endEvent',         name: 'Ready', lane: 'human', x: POOL_X + LANE_HEADER + 1320, y: laneCenterY('human') - 18,
        aef: { emits: 'event:investigate.ready' } },

      { id: 'End_abandon',           type: 'endEvent',         name: 'Abandoned', lane: 'framework', x: POOL_X + LANE_HEADER + 1320, y: laneCenterY('framework') - 18,
        aef: { emits: 'event:investigate.abandoned' } },
    ],
    edges: [
      { id: 'f1', source: 'Start_request',         target: 'Script_loadContext' },
      { id: 'f2', source: 'Script_loadContext',    target: 'Service_decompose' },
      { id: 'f3', source: 'Service_decompose',     target: 'GW_fork' },
      { id: 'f4a', source: 'GW_fork',              target: 'Service_searchCode' },
      { id: 'f4b', source: 'GW_fork',              target: 'Service_searchHistory' },
      { id: 'f4c', source: 'GW_fork',              target: 'Service_searchRelated' },
      { id: 'f5a', source: 'Service_searchCode',   target: 'GW_join' },
      { id: 'f5b', source: 'Service_searchHistory',target: 'GW_join' },
      { id: 'f5c', source: 'Service_searchRelated',target: 'GW_join' },
      { id: 'f6', source: 'GW_join',               target: 'Service_synthesize' },
      { id: 'f7', source: 'Service_synthesize',    target: 'GW_sufficient' },
      { id: 'f8y',source: 'GW_sufficient',         target: 'Script_writeReport', name: 'sufficient', condition: '${findings.confidence >= 0.7}' },
      { id: 'f8n',source: 'GW_sufficient',         target: 'Service_decompose',  name: 'insufficient · loop', condition: '${findings.confidence < 0.7}' },
      { id: 'f9', source: 'Script_writeReport',    target: 'User_review' },
      { id: 'f10y',source: 'User_review',          target: 'End_ready',          name: 'dispatch' },
      { id: 'f10n',source: 'User_review',          target: 'End_abandon',        name: 'abandon' },
    ],
  };

  // ---- Migration to two-identifier model -------------------------------
  // Each node gets a uid + slug. The legacy `id` field is repurposed to *equal*
  // the uid (so existing code that does `n.id` / `e.id` continues to work as
  // a stable reference key). The `slug` and computed displayId are new.
  const oldIdToUid = new Map();
  for (const node of result.nodes) {
    const oldId = node.id;
    node.uid = generateUid('n');
    // Slug derives from the display name — first significant word, lowercased.
    // Consistent with the runtime deriveSlug() used for renames.
    node.slug = deriveSlug(node.name);
    oldIdToUid.set(oldId, node.uid);
    // Repurpose `id` to equal `uid` so existing code reading `n.id` continues
    // to use a stable reference key.
    node.id = node.uid;
  }
  // Slug uniqueness within a lane: if two nodes in the same lane share a slug,
  // append `_2`, `_3` etc. in lane-insertion order. (Spatial reordering will
  // recompute this later via refreshDisplayIds.)
  const slugCounts = new Map(); // key: `${lane}|${slug}` → count seen so far
  for (const node of result.nodes) {
    const key = `${node.lane}|${node.slug}`;
    const seen = slugCounts.get(key) || 0;
    if (seen > 0) node.slug = `${node.slug}-${seen + 1}`;
    slugCounts.set(key, seen + 1);
  }
  for (const edge of result.edges) {
    edge.uid = generateUid('e');
    edge.source = oldIdToUid.get(edge.source) || edge.source;
    edge.target = oldIdToUid.get(edge.target) || edge.target;
    edge.id = edge.uid;
  }

  state = prevState;
  return result;
}

function getLanes() { return (state && state.lanes) ? state.lanes : defaultLanes(); }
function findLane(id) { return getLanes().find(l => l.id === id); }
function laneTop(laneId) {
  let y = POOL_Y + POOL_HEADER;
  for (const l of getLanes()) {
    if (l.id === laneId) return y;
    y += l.height;
  }
  return y;
}
function laneCenterY(laneId) {
  const l = findLane(laneId);
  if (!l) return POOL_Y + POOL_HEADER;
  return laneTop(laneId) + l.height / 2;
}
function poolHeight() {
  return POOL_HEADER + getLanes().reduce((s, l) => s + l.height, 0);
}
// Locate which lane a given y-coordinate falls into; returns lane id or first lane id as fallback.
function laneAtY(y) {
  let top = POOL_Y + POOL_HEADER;
  for (const l of getLanes()) {
    if (y >= top && y < top + l.height) return l.id;
    top += l.height;
  }
  return getLanes()[0]?.id;
}

// ============================================================================
//  State
// ============================================================================
let state = null;
let selection = null; // { kind: 'node'|'edge'|'lane', id } — primary; drives properties panel
let multiSelect = new Set(); // node ids in the active multi-selection (always includes primary if it's a node)
let rubberBand = null; // { startX, startY, x, y } while drawing
let groupDrag = null;  // { startX, startY, originalPositions: Map<nodeId, {x, y}> }
let mode = 'select'; // 'select' | 'connect' | 'create:<type>'
let connectFrom = null;
let drag = null;
let edgeDrag = null; // { kind: 'endpoint'|'waypoint'|'add-waypoint', edgeId, ... }
let laneResizeDrag = null; // { laneId, startY, startHeight }
let nextId = 100;

// ============================================================================
//  Library — in-session collection of loaded workflows.
// ============================================================================
// The user can load multiple workflows; one is the *active* workflow whose state
// is bound to `state` (and thus everything else). Switching via the toolbar
// picker writes the current state back into the library Map and pulls the
// chosen one out into `state`. The library is browser-memory only — there's no
// persistence; reload starts from the seed.
const library = new Map(); // key (workflow id) → workflow state object
let activeKey = null;

function saveActiveToLibrary() {
  if (state && activeKey != null) {
    library.set(activeKey, state);
  }
}

function loadFromLibrary(key) {
  if (!library.has(key)) return false;
  saveActiveToLibrary();
  state = library.get(key);
  activeKey = key;
  selection = null;
  multiSelect.clear();
  mode = 'select';
  refreshDisplayIds();
  renderAll();
  refreshLibraryUI();
  return true;
}

// Seed the library with the investigate workflow, set it as active.
const seed = getInvestigateWorkflow();
library.set(seed.workflowMeta.id, seed);
state = seed;
activeKey = seed.workflowMeta.id;

const SVG_NS = 'http://www.w3.org/2000/svg';
const $ = id => document.getElementById(id);
const svg = $('canvas');
const gPool = $('g-pool');
const gEdges = $('g-edges');
const gNodes = $('g-nodes');
const gPreview = $('g-preview');

function el(tag, attrs = {}, children = []) {
  const e = document.createElementNS(SVG_NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  for (const c of children) if (c) e.appendChild(c);
  return e;
}
function findNode(id) { return state.nodes.find(n => n.uid === id); }
function findEdge(id) { return state.edges.find(e => e.uid === id); }

// ============================================================================
//  Rendering
// ============================================================================
function renderAll() {
  renderPool();
  renderEdges();
  renderNodes();
  renderProperties();
  syncCanvasSize();
  updateStatus();
}
function refreshLibraryUI() {
  const picker = $('workflow-picker');
  if (!picker) return;
  picker.innerHTML = '';
  // Sort by id for stable display
  const keys = Array.from(library.keys()).sort();
  for (const k of keys) {
    const wf = library.get(k);
    const opt = document.createElement('option');
    opt.value = k;
    const title = wf.workflowMeta?.title || wf.workflowMeta?.id || k;
    opt.textContent = title;
    if (k === activeKey) opt.selected = true;
    picker.appendChild(opt);
  }
  const versionEl = $('brand-version');
  if (versionEl) {
    const v = state?.workflowMeta?.version || '1';
    versionEl.textContent = 'v' + v;
  }
}

// Create a new empty workflow and add it to the library, making it active.
function createNewWorkflow() {
  // Saves the current edits before swapping
  saveActiveToLibrary();
  // Find a unique id
  let base = 'workflow';
  let n = 1;
  while (library.has(`${base}_${n}`)) n++;
  const id = `${base}_${n}`;
  const lanes = defaultLanes();
  const newState = {
    pool: { id: `Pool_${id}`, name: id },
    workflowMeta: {
      id,
      version: '1',
      schemaVersion: 2,
      title: 'Untitled workflow',
      description: '',
      tier_default: '2',
    },
    lanes,
    nodes: [],
    edges: [],
  };
  library.set(id, newState);
  state = newState;
  activeKey = id;
  selection = null;
  multiSelect.clear();
  refreshDisplayIds();
  renderAll();
  refreshLibraryUI();
}

// Rename the active workflow's id. Updates the library key, the workflowMeta.id,
// and the pool id/name (since those default to following the workflow id).
// Enforces uniqueness against existing workflows in the library.
function renameActiveWorkflow(newId) {
  newId = (newId || '').trim().toLowerCase().replace(/[^a-z0-9_\-]/g, '-');
  if (!newId || newId === activeKey) return false;
  if (library.has(newId)) return false; // collision
  library.delete(activeKey);
  state.workflowMeta.id = newId;
  if (state.pool && state.pool.name === activeKey) state.pool.name = newId;
  if (state.pool && state.pool.id === `Pool_${activeKey}`) state.pool.id = `Pool_${newId}`;
  library.set(newId, state);
  activeKey = newId;
  refreshLibraryUI();
  return true;
}

function updateStatus() {
  const sel = $('status-selection');
  if (!sel) return;
  // During an endpoint drag, the hint takes priority over selection info
  if (edgeDrag && edgeDrag.kind === 'endpoint' && edgeDrag.cursorPt) {
    if (edgeDrag.snapNodeId) {
      sel.textContent = `   ·   release to connect to ${edgeDrag.snapNodeId} (${edgeDrag.snapPort})`;
      sel.style.color = 'var(--accent)';
    } else {
      sel.textContent = '   ·   release in open space to cancel';
      sel.style.color = 'var(--text-faint)';
    }
    return;
  }
  if (multiSelect.size > 1) {
    sel.textContent = `   ·   ${multiSelect.size} nodes selected`;
    sel.style.color = 'var(--accent)';
  } else if (selection) {
    sel.textContent = `   ·   ${selection.kind} selected`;
    sel.style.color = 'var(--text-faint)';
  } else {
    sel.textContent = '';
  }
}
function syncCanvasSize() {
  const w = POOL_X + LANE_HEADER + POOL_WIDTH + 30;
  const h = POOL_Y + poolHeight() + 50 /* room for the + add another lane strip */;
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  svg.setAttribute('preserveAspectRatio', 'xMinYMin meet');
}
function renderPool() {
  gPool.innerHTML = '';
  // pool outline
  const px = POOL_X, py = POOL_Y;
  const pw = LANE_HEADER + POOL_WIDTH;
  const ph = poolHeight();

  // pool header strip
  gPool.appendChild(el('rect', { x: px, y: py, width: pw, height: POOL_HEADER, fill: 'var(--surface-2)' }));
  gPool.appendChild(el('text', { x: px + 14, y: py + 21, class: 'pool-label' }, [text(state.pool.name + '  ·  workflow:' + state.workflowMeta.id)]));

  // lanes
  let yCursor = py + POOL_HEADER;
  const lanesArr = getLanes();
  for (let li = 0; li < lanesArr.length; li++) {
    const lane = lanesArr[li];
    const lh = lane.height;
    const isSelected = selection?.kind === 'lane' && selection.id === lane.id;

    // Lane body background — tinted by authority
    gPool.appendChild(el('rect', {
      x: px, y: yCursor, width: pw, height: lh,
      class: 'lane-bg' + (isSelected ? ' selected' : ''),
      fill: AUTHORITY_COLOR[lane.authority] || 'transparent',
      stroke: 'var(--border)',
      'stroke-width': '1',
    }));

    // Lane header (left strip) — clickable hit zone for the lane
    const headerG = el('g', { class: 'lane-header' + (isSelected ? ' selected' : ''), 'data-lane-id': lane.id });
    headerG.appendChild(el('rect', { x: px, y: yCursor, width: LANE_HEADER, height: lh, fill: 'var(--surface)' }));
    const cx = px + LANE_HEADER / 2 + 2;
    const cy = yCursor + lh / 2;
    headerG.appendChild(el('text', {
      x: cx, y: cy, class: 'lane-label', 'text-anchor': 'middle',
      transform: `rotate(-90 ${cx} ${cy})`,
      fill: isSelected ? AUTHORITY_LABEL_COLOR[lane.authority] || 'var(--text)' : 'var(--text-faint)',
    }, [text(lane.name)]));
    headerG.addEventListener('click', ev => { ev.stopPropagation(); onLaneClick(lane); });
    gPool.appendChild(headerG);

    // Divider at top edge (skip for first lane — that's the pool header line)
    if (li > 0) {
      gPool.appendChild(el('line', { x1: px, y1: yCursor, x2: px + pw, y2: yCursor, class: 'lane-divider' }));
    }
    yCursor += lh;

    // Resize handle at the *bottom* edge of every lane — invisible thick zone + visible thin grip.
    // Dragging this handle resizes THIS lane.
    const handleG = el('g', { class: 'lane-resize-handle', 'data-lane-id': lane.id });
    handleG.appendChild(el('rect', { x: px + LANE_HEADER, y: yCursor - 4, width: pw - LANE_HEADER, height: 8, class: 'lane-resize-hit' }));
    // small grip indicator in the middle of the lane width
    const gripCx = px + LANE_HEADER + (pw - LANE_HEADER) / 2;
    handleG.appendChild(el('rect', { x: gripCx - 12, y: yCursor - 1, width: 24, height: 2, rx: 1, class: 'lane-resize-grip' }));
    handleG.addEventListener('mousedown', ev => onLaneResizeMouseDown(ev, lane.id));
    gPool.appendChild(handleG);
  }
  // bottom border
  gPool.appendChild(el('rect', { x: px, y: py, width: pw, height: ph, class: 'pool-border' }));

  // "+ Add another lane" strip below the pool — clearly discoverable
  const stripY = py + ph + 8;
  const stripH = 24;
  const addStrip = el('g', { class: 'pool-add-lane-strip' });
  addStrip.appendChild(el('rect', { x: px, y: stripY, width: pw, height: stripH, rx: 3, class: 'pool-add-lane-strip-bg' }));
  addStrip.appendChild(el('text', { x: px + pw / 2, y: stripY + 16, class: 'pool-add-lane-strip-text', 'text-anchor': 'middle' }, [text('+ Add another lane')]));
  addStrip.addEventListener('click', ev => { ev.stopPropagation(); addLane(); });
  gPool.appendChild(addStrip);
}

function onLaneClick(lane) {
  if (mode.startsWith('create:') || mode === 'connect') return;
  selection = { kind: 'lane', id: lane.id };
  renderAll();
}

function text(s) { const t = document.createTextNode(s); return t; }

function renderNodes() {
  gNodes.innerHTML = '';
  for (const n of state.nodes) {
    const def = NODE_DEFAULTS[n.type];
    const isPrimary = selection?.kind === 'node' && selection.id === n.id;
    const isInMulti = multiSelect.has(n.id);
    const cls = 'node' + (isPrimary ? ' selected' : '') + (isInMulti && !isPrimary ? ' multi-selected' : '');
    const g = el('g', { class: cls, 'data-id': n.id });
    g.addEventListener('mousedown', e => onNodeMouseDown(e, n));
    g.addEventListener('click', e => { e.stopPropagation(); onNodeClick(n, e); });

    if (n.type === 'startEvent') {
      g.appendChild(el('circle', { cx: n.x + def.w / 2, cy: n.y + def.h / 2, r: def.w / 2, class: 'node-shape', fill: 'var(--green-soft)', stroke: 'var(--green)', 'stroke-width': '1.5' }));
    } else if (n.type === 'endEvent') {
      g.appendChild(el('circle', { cx: n.x + def.w / 2, cy: n.y + def.h / 2, r: def.w / 2, class: 'node-shape', fill: 'var(--red-soft)', stroke: 'var(--red)', 'stroke-width': '3' }));
    } else if (n.type === 'serviceTask') {
      g.appendChild(el('rect', { x: n.x, y: n.y, width: def.w, height: def.h, rx: 8, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--blue)', 'stroke-width': '1.5' }));
      g.appendChild(el('circle', { cx: n.x + 10, cy: n.y + 10, r: 3, fill: 'var(--blue)' }));
    } else if (n.type === 'userTask') {
      g.appendChild(el('rect', { x: n.x, y: n.y, width: def.w, height: def.h, rx: 8, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--accent)', 'stroke-width': '1.5' }));
      g.appendChild(el('circle', { cx: n.x + 10, cy: n.y + 10, r: 2, fill: 'var(--accent)' }));
      g.appendChild(el('path', { d: `M${n.x + 6} ${n.y + 14} q4 -3 8 0`, stroke: 'var(--accent)', 'stroke-width': '1.2', fill: 'none' }));
    } else if (n.type === 'scriptTask') {
      g.appendChild(el('rect', { x: n.x, y: n.y, width: def.w, height: def.h, rx: 8, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--orange)', 'stroke-width': '1.5' }));
      g.appendChild(el('path', { d: `M${n.x + 6} ${n.y + 8} h6 M${n.x + 6} ${n.y + 11} h8 M${n.x + 6} ${n.y + 14} h5`, stroke: 'var(--orange)', 'stroke-width': '1' }));
    } else if (n.type === 'exclusiveGateway') {
      const cx = n.x + def.w / 2, cy = n.y + def.h / 2, r = def.w / 2;
      g.appendChild(el('path', { d: `M${cx} ${n.y} L${n.x + def.w} ${cy} L${cx} ${n.y + def.h} L${n.x} ${cy} Z`, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--orange)', 'stroke-width': '1.5' }));
      g.appendChild(el('path', { d: `M${cx - 8} ${cy - 8} L${cx + 8} ${cy + 8} M${cx + 8} ${cy - 8} L${cx - 8} ${cy + 8}`, stroke: 'var(--orange)', 'stroke-width': '2', 'stroke-linecap': 'round' }));
    } else if (n.type === 'parallelGateway') {
      const cx = n.x + def.w / 2, cy = n.y + def.h / 2;
      g.appendChild(el('path', { d: `M${cx} ${n.y} L${n.x + def.w} ${cy} L${cx} ${n.y + def.h} L${n.x} ${cy} Z`, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--blue)', 'stroke-width': '1.5' }));
      g.appendChild(el('path', { d: `M${cx} ${cy - 10} V${cy + 10} M${cx - 10} ${cy} H${cx + 10}`, stroke: 'var(--blue)', 'stroke-width': '2', 'stroke-linecap': 'round' }));
    } else if (n.type === 'linkEventThrow' || n.type === 'linkEventCatch') {
      // Off-page connector: hollow circle with a chevron arrow inside.
      // Throw = chevron pointing right (data leaves); catch = chevron pointing left (data enters).
      const cx = n.x + def.w / 2, cy = n.y + def.h / 2, r = def.w / 2;
      const isThrow = n.type === 'linkEventThrow';
      g.appendChild(el('circle', { cx, cy, r, class: 'node-shape', fill: 'var(--surface-2)', stroke: 'var(--accent)', 'stroke-width': '1.5' }));
      // chevron
      const chevDir = isThrow ? 1 : -1;
      g.appendChild(el('path', {
        d: `M${cx - 5 * chevDir} ${cy - 6} L${cx + 5 * chevDir} ${cy} L${cx - 5 * chevDir} ${cy + 6}`,
        stroke: 'var(--accent)', 'stroke-width': '2', fill: 'none',
        'stroke-linecap': 'round', 'stroke-linejoin': 'round',
      }));
    }

    // label
    let lx = n.x + def.w / 2;
    let ly = (n.type === 'startEvent' || n.type === 'endEvent' ||
              n.type === 'linkEventThrow' || n.type === 'linkEventCatch' ||
              n.type.endsWith('Gateway'))
      ? n.y + def.h + 14
      : n.y + def.h / 2 + 4;
    if (n.type === 'serviceTask' || n.type === 'userTask' || n.type === 'scriptTask') {
      // multi-line label
      const lines = wrapText(n.name, 14);
      lines.forEach((line, i) => {
        g.appendChild(el('text', { x: lx, y: n.y + def.h / 2 + (i - (lines.length - 1) / 2) * 13 + 4, class: 'node-label', 'text-anchor': 'middle' }, [text(line)]));
      });
      // I/O badge in top-right of task rect
      const io = n.io || {};
      const inN = (io.inputs || []).filter(i => i.name).length;
      const outN = (io.outputs || []).filter(i => i.name).length;
      if (inN || outN) {
        const badge = `${inN}→${outN}`;
        const bw = badge.length * 5.4 + 8;
        g.appendChild(el('rect', { x: n.x + def.w - bw - 4, y: n.y + 4, width: bw, height: 12, rx: 2, fill: 'var(--surface-3)', stroke: 'var(--border)', 'stroke-width': '0.5' }));
        g.appendChild(el('text', { x: n.x + def.w - bw / 2 - 4, y: n.y + 12, class: 'node-io-badge', 'text-anchor': 'middle' }, [text(badge)]));
      }
      // ID below the rectangle, centered
      g.appendChild(el('text', { x: lx, y: n.y + def.h + 12, class: 'node-id-badge', 'text-anchor': 'middle' }, [text(displayIdOf(n))]));
    } else {
      g.appendChild(el('text', { x: lx, y: ly, class: 'node-label', 'text-anchor': 'middle' }, [text(n.name)]));
      // ID below the name, in mono and lower contrast
      g.appendChild(el('text', { x: lx, y: ly + 12, class: 'node-id-badge', 'text-anchor': 'middle' }, [text(displayIdOf(n))]));
    }
    gNodes.appendChild(g);
  }
}

function wrapText(s, max) {
  const words = s.split(' ');
  const out = [];
  let cur = '';
  for (const w of words) {
    if ((cur + ' ' + w).trim().length > max) {
      if (cur) out.push(cur);
      cur = w;
    } else {
      cur = (cur + ' ' + w).trim();
    }
  }
  if (cur) out.push(cur);
  return out;
}

function renderEdges() {
  gEdges.innerHTML = '';
  for (const e of state.edges) {
    const src = findNode(e.source);
    const tgt = findNode(e.target);
    if (!src || !tgt) continue;
    const isSelected = selection?.kind === 'edge' && selection.id === e.id;
    // Is *this* edge currently having an endpoint dragged?
    const isBeingDragged = edgeDrag && edgeDrag.kind === 'endpoint' && edgeDrag.edgeId === e.id && edgeDrag.cursorPt;
    const isFloating = isBeingDragged && !edgeDrag.snapNodeId;

    // Compute the full polyline including waypoints.
    const wps = isBeingDragged ? [] : (e.waypoints || []);
    const firstWp = wps[0];
    const lastWp = wps[wps.length - 1];

    // Port-aware anchors. If an endpoint of *this* edge is being dragged, the
    // dragged endpoint follows the cursor (with optional snap to a port).
    let sp, tp;
    let effectiveSrc = src, effectiveTgt = tgt;
    let effectiveSrcPort = e.sourcePort, effectiveTgtPort = e.targetPort;
    if (isBeingDragged && edgeDrag.role === 'source') {
      sp = edgeDrag.previewPt || edgeDrag.cursorPt;
      // If snapping, the effective source for routing is the snap node + port.
      if (edgeDrag.snapNodeId) {
        const snap = findNode(edgeDrag.snapNodeId);
        if (snap) { effectiveSrc = snap; effectiveSrcPort = edgeDrag.snapPort; }
      }
      tp = anchorPoint(tgt, e.targetPort, sp);
    } else if (isBeingDragged && edgeDrag.role === 'target') {
      tp = edgeDrag.previewPt || edgeDrag.cursorPt;
      if (edgeDrag.snapNodeId) {
        const snap = findNode(edgeDrag.snapNodeId);
        if (snap) { effectiveTgt = snap; effectiveTgtPort = edgeDrag.snapPort; }
      }
      sp = anchorPoint(src, e.sourcePort, tp);
    } else {
      sp = anchorPoint(src, e.sourcePort, firstWp ? firstWp : centerOf(tgt));
      tp = anchorPoint(tgt, e.targetPort, lastWp ? lastWp : centerOf(src));
    }

    // Multi-edge spread (A1 + B3): if this edge shares a side with sibling edges,
    // distribute it perpendicular to the exit direction so they don't overlap.
    // We don't apply spread to the *dragged* endpoint — that's following the cursor.
    if (!isBeingDragged) {
      const sDir = exitDirection(src, sp, e.sourcePort || 'auto');
      const tDir = exitDirection(tgt, tp, e.targetPort || 'auto');
      const sOff = spreadOffset(e, 'source', sDir, src);
      const tOff = spreadOffset(e, 'target', tDir, tgt);
      sp = applySpread(sp, sDir, sOff);
      tp = applySpread(tp, tDir, tOff);
    } else if (edgeDrag.role === 'source') {
      // Only the non-dragged end gets spread
      const tDir = exitDirection(tgt, tp, e.targetPort || 'auto');
      const tOff = spreadOffset(e, 'target', tDir, tgt);
      tp = applySpread(tp, tDir, tOff);
    } else if (edgeDrag.role === 'target') {
      const sDir = exitDirection(src, sp, e.sourcePort || 'auto');
      const sOff = spreadOffset(e, 'source', sDir, src);
      sp = applySpread(sp, sDir, sOff);
    }
    const points = [sp, ...wps, tp];

    // Build a temporary edge shape with effective ports for the router.
    const effectiveEdge = isBeingDragged
      ? { ...e, sourcePort: effectiveSrcPort, targetPort: effectiveTgtPort }
      : e;
    const path = routePathFromPoints(points, effectiveSrc, effectiveTgt, wps.length > 0, effectiveEdge);

    const g = el('g', { class: 'edge' + (isSelected ? ' selected' : '') + (isBeingDragged ? ' dragging' : '') + (isFloating ? ' floating' : ''), 'data-id': e.id });
    g.appendChild(el('path', { d: path, class: 'edge-hit' }));
    g.appendChild(el('path', { d: path, class: 'edge-path', 'marker-end': isSelected ? 'url(#arrow-selected)' : 'url(#arrow)' }));

    if (e.name && !isBeingDragged) {
      const mid = midOfPolyline(points);
      g.appendChild(el('rect', { x: mid.x - estLabelWidth(e.name) / 2 - 4, y: mid.y - 8, width: estLabelWidth(e.name) + 8, height: 14, fill: 'var(--bg)', rx: 2 }));
      g.appendChild(el('text', { x: mid.x, y: mid.y + 3, class: 'edge-label', 'text-anchor': 'middle' }, [text(e.name)]));
    }

    // Handles only when this edge is selected
    if (isSelected) {
      // Source endpoint handle — drag to re-anchor source onto a port or a different node
      const srcHandle = el('circle', { cx: sp.x, cy: sp.y, r: 6, class: 'edge-handle edge-handle-endpoint', 'data-role': 'src' });
      srcHandle.addEventListener('mousedown', ev => onEndpointMouseDown(ev, e, 'source'));
      g.appendChild(srcHandle);

      // Target endpoint handle
      const tgtHandle = el('circle', { cx: tp.x, cy: tp.y, r: 6, class: 'edge-handle edge-handle-endpoint', 'data-role': 'tgt' });
      tgtHandle.addEventListener('mousedown', ev => onEndpointMouseDown(ev, e, 'target'));
      g.appendChild(tgtHandle);

      // Waypoint handles
      wps.forEach((wp, idx) => {
        const wpHandle = el('rect', { x: wp.x - 5, y: wp.y - 5, width: 10, height: 10, class: 'edge-handle edge-handle-waypoint' });
        wpHandle.addEventListener('mousedown', ev => onWaypointMouseDown(ev, e, idx));
        wpHandle.addEventListener('dblclick', ev => { ev.stopPropagation(); removeWaypoint(e, idx); });
        g.appendChild(wpHandle);
      });

      // Per-segment drag handles — one pill on each *interior* segment of the
      // rendered orthogonal polyline. Each handle stores the *role* of its segment
      // (seg_first / seg_mid / seg_last) so the perpendicular nudge updates the
      // corresponding entry in edge.routingHints. The edge stays auto-routed; the
      // router applies the offsets every time it computes the path.
      //
      // The dedicated loop-detour handle (with its lane-clamp) gets priority on
      // its segment; we skip the generic segment handle there.
      const hasLoopDetour = typeof e._loopDetourY === 'number' && e._loopXRange && wps.length === 0;
      const rendered = e._renderedPolyline || [];
      const segmentMeta = e._segmentMeta || [];
      if (rendered.length >= 4 && wps.length === 0) {
        // Interior segments: from index 1 (stubA → first corner or stubB) to index
        // rendered.length - 2 (last corner or stubA → stubB).
        // Map each interior segment index → role in segmentMeta.
        // The rendered polyline is: [anchor, spA, ...corners, spB, anchor]
        // Interior segments (between stubs) are: spA→c1, c1→c2, ..., cN→spB
        // These correspond to indices 1..rendered.length-3 in the polyline.
        // segmentMeta indexes match: segmentMeta[0] is spA→c1, etc.
        const numInteriorSegs = rendered.length - 3;
        for (let i = 0; i < numInteriorSegs; i++) {
          const meta = segmentMeta[i];
          if (!meta) continue;
          const a = rendered[i + 1], b = rendered[i + 2];
          const isHoriz = meta.dir === 'H';
          const segLen = isHoriz ? Math.abs(b.x - a.x) : Math.abs(b.y - a.y);
          if (segLen < 8) continue;
          const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;

          // Skip the segment hosting the loop-detour handle
          if (hasLoopDetour && isHoriz && Math.abs(my - e._loopDetourY) < 1) continue;

          const handleW = isHoriz ? 22 : 8;
          const handleH = isHoriz ? 8 : 22;
          const segHandle = el('rect', {
            x: mx - handleW / 2, y: my - handleH / 2,
            width: handleW, height: handleH, rx: 3,
            class: 'edge-handle edge-handle-segment ' + (isHoriz ? 'horiz' : 'vert'),
            'data-role': meta.role,
          });
          segHandle.addEventListener('mousedown', ev => onSegmentMouseDown(ev, e, meta.role, meta.perpAxis, mx, my));
          segHandle.appendChild(el('title', {}, [text(`drag to nudge segment ${isHoriz ? 'up/down' : 'left/right'}`)]));
          g.appendChild(segHandle);
        }
      }

      // Loop-detour handle — appears on the horizontal cross-bar of a loop-back
      // edge. Drag up/down to reposition the detour within its available band.
      if (hasLoopDetour) {
        const hx = (e._loopXRange[0] + e._loopXRange[1]) / 2;
        const hy = e._loopDetourY;
        const handleW = 22, handleH = 8;
        const detourHandle = el('rect', {
          x: hx - handleW / 2, y: hy - handleH / 2,
          width: handleW, height: handleH, rx: 3,
          class: 'edge-handle edge-handle-detour',
        });
        detourHandle.addEventListener('mousedown', ev => onLoopDetourMouseDown(ev, e, hy));
        detourHandle.appendChild(el('title', {}, [text('drag to move loop detour up/down')]));
        g.appendChild(detourHandle);
      }
    }

    g.addEventListener('click', ev => { ev.stopPropagation(); onEdgeClick(e); });
    gEdges.appendChild(g);
  }

  // When an edge is selected, also render port indicators on its source and target nodes.
  // The indicators are clickable: click one to pin the endpoint to that port. They are
  // also the snap targets while dragging the endpoint handle.
  if (selection?.kind === 'edge') {
    const e = findEdge(selection.id);
    if (e) {
      renderPortIndicators(findNode(e.source), 'source', e);
      renderPortIndicators(findNode(e.target), 'target', e);
    }
  }
}

function renderPortIndicators(node, role, edge) {
  if (!node) return;
  const activePort = role === 'source' ? edge.sourcePort : edge.targetPort;
  for (const p of PORT_NAMES) {
    const pt = portPointAt(node, p);
    const isActive = activePort === p;
    const dot = el('circle', {
      cx: pt.x, cy: pt.y, r: isActive ? 5 : 4,
      class: 'port-indicator' + (isActive ? ' active' : ''),
      'data-port': p,
      'data-role': role,
    });
    // SVG-native tooltip on hover
    dot.appendChild(el('title', {}, [text(`${role} · port ${p}${isActive ? ' (active)' : ''}`)]));
    dot.addEventListener('click', ev => {
      ev.stopPropagation();
      if (role === 'source') edge.sourcePort = p;
      else edge.targetPort = p;
      // pinning to a port invalidates manual waypoints — the geometry changed
      edge.waypoints = [];
      renderAll();
    });
    gEdges.appendChild(dot);
  }
  // Also render an "auto" indicator at the node center — click to clear the port pin.
  const c = centerOf(node);
  const autoActive = !activePort || activePort === 'auto';
  const autoDot = el('circle', {
    cx: c.x, cy: c.y, r: 3,
    class: 'port-indicator port-indicator-auto' + (autoActive ? ' active' : ''),
    'data-port': 'auto',
    'data-role': role,
  });
  autoDot.appendChild(el('title', {}, [text(`${role} · auto${autoActive ? ' (active)' : ''}`)]));
  autoDot.addEventListener('click', ev => {
    ev.stopPropagation();
    if (role === 'source') edge.sourcePort = 'auto';
    else edge.targetPort = 'auto';
    edge.waypoints = [];
    renderAll();
  });
  gEdges.appendChild(autoDot);
}
function estLabelWidth(s) { return s.length * 5.2; }

function centerOf(n) {
  const d = NODE_DEFAULTS[n.type];
  return { x: n.x + d.w / 2, y: n.y + d.h / 2 };
}

// Port names → unit-vector positions on the node's bounding box.
// auto = computed at render time toward whatever is on the other side.
const PORT_NAMES = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
const PORT_OFFSETS = {
  N:  { dx:  0.0, dy: -0.5 },
  NE: { dx:  0.5, dy: -0.5 },
  E:  { dx:  0.5, dy:  0.0 },
  SE: { dx:  0.5, dy:  0.5 },
  S:  { dx:  0.0, dy:  0.5 },
  SW: { dx: -0.5, dy:  0.5 },
  W:  { dx: -0.5, dy:  0.0 },
  NW: { dx: -0.5, dy: -0.5 },
};

// Resolve a port name to absolute coordinates on a node. For circular shapes
// (events) and diamonds (gateways), the offset is projected to the perimeter.
function portPointAt(node, portName) {
  const d = NODE_DEFAULTS[node.type];
  const cx = node.x + d.w / 2, cy = node.y + d.h / 2;
  const off = PORT_OFFSETS[portName];
  if (!off) return { x: cx, y: cy };

  if (node.type === 'startEvent' || node.type === 'endEvent') {
    // circle perimeter
    const r = d.w / 2;
    const len = Math.sqrt(off.dx * off.dx + off.dy * off.dy) || 1;
    return { x: cx + (off.dx / len) * r, y: cy + (off.dy / len) * r };
  }
  if (node.type === 'exclusiveGateway' || node.type === 'parallelGateway') {
    // diamond — only N/E/S/W make sense; corners project to the same tips
    const r = d.w / 2;
    // for cardinal ports the diamond tip lies at (±r, 0) or (0, ±r)
    // for diagonal ports we still anchor at the *nearest* tip
    if (portName === 'N')  return { x: cx, y: cy - r };
    if (portName === 'S')  return { x: cx, y: cy + r };
    if (portName === 'E')  return { x: cx + r, y: cy };
    if (portName === 'W')  return { x: cx - r, y: cy };
    if (portName === 'NE' || portName === 'NW') return { x: cx, y: cy - r };
    if (portName === 'SE' || portName === 'SW') return { x: cx, y: cy + r };
    return { x: cx, y: cy };
  }
  // rectangle — port lies on the perimeter at the offset
  return { x: cx + off.dx * d.w, y: cy + off.dy * d.h };
}

// Pick the port whose absolute position is nearest to a given world point.
function nearestPortName(node, worldPt) {
  let best = null, bestD = Infinity;
  for (const p of PORT_NAMES) {
    const pt = portPointAt(node, p);
    const dd = (pt.x - worldPt.x) ** 2 + (pt.y - worldPt.y) ** 2;
    if (dd < bestD) { bestD = dd; best = p; }
  }
  return best;
}

// Compute the anchor point used by the renderer. If port is 'auto' or missing,
// fall back to the old "nearest border point toward the other end" behavior so
// existing diagrams keep their look. Otherwise pin to the named port.
function anchorPoint(node, port, towardPt) {
  if (!port || port === 'auto') return portPointTowards(node, towardPt);
  return portPointAt(node, port);
}

function portPointTowards(from, towardPt) {
  // returns nearest border point on `from` toward an arbitrary world point
  const fd = NODE_DEFAULTS[from.type];
  const fcx = from.x + fd.w / 2, fcy = from.y + fd.h / 2;
  const dx = towardPt.x - fcx, dy = towardPt.y - fcy;
  if (from.type === 'startEvent' || from.type === 'endEvent' ||
      from.type === 'exclusiveGateway' || from.type === 'parallelGateway') {
    const r = fd.w / 2;
    const len = Math.sqrt(dx * dx + dy * dy) || 1;
    return { x: fcx + dx / len * r, y: fcy + dy / len * r };
  }
  const halfW = fd.w / 2, halfH = fd.h / 2;
  const scale = Math.max(Math.abs(dx) / halfW, Math.abs(dy) / halfH) || 1;
  return { x: fcx + dx / scale, y: fcy + dy / scale };
}

// kept for backward callers in case anything still calls it
function portPoint(from, to) { return portPointTowards(from, centerOf(to)); }

// ============================================================================
//  Multi-edge spread (A1 + B3)
// ============================================================================
//
// When several edges share the same node-side (e.g. three edges leave the East
// side of a fan-out gateway), they would overlap if anchored at the same port
// position. The spread distributes them perpendicular to their exit direction,
// in stable order, so each gets its own visible anchor.
//
// The grouping is keyed by (nodeId, side) where side ∈ {N,E,S,W}. Each edge
// appears once per endpoint, since source-side and target-side are independent
// groups.

function nodeSideForExitDir(dir) {
  // dir is one of N/E/S/W; the node side it's leaving from is the same letter
  return dir;
}

// Returns the side-length on a node for a given side direction.
function nodeSideLength(node, side) {
  const d = NODE_DEFAULTS[node.type];
  if (node.type === 'startEvent' || node.type === 'endEvent') return d.w; // circle diameter — approximate
  if (node.type === 'exclusiveGateway' || node.type === 'parallelGateway') return d.w * 0.7; // diamonds: usable spread is narrower
  return (side === 'N' || side === 'S') ? d.w : d.h;
}

// Build a map: "nodeId:side" → ordered list of { edgeId, role: 'source'|'target', otherKey }
// where otherKey is a sort key (Y for E/W sides, X for N/S sides) derived from the
// OTHER endpoint's position. Stable ordering keeps the spread consistent across renders
// and avoids unnecessary edge crossings.
let _edgeGroupCache = null;
let _edgeGroupCacheKey = '';

function buildEdgeGroups() {
  // simple cache key based on edges + node positions (good enough for the demo)
  const key = state.edges.map(e => `${e.id}|${e.source}|${e.target}|${e.sourcePort || ''}|${e.targetPort || ''}`).join(';') +
              '||' + state.nodes.map(n => `${n.id}|${n.x}|${n.y}|${n.lane}`).join(';');
  if (_edgeGroupCache && _edgeGroupCacheKey === key) return _edgeGroupCache;

  const groups = new Map();
  for (const e of state.edges) {
    const src = findNode(e.source);
    const tgt = findNode(e.target);
    if (!src || !tgt) continue;

    // Determine each end's side by computing where the anchor would naturally be.
    const sAnchor = anchorPoint(src, e.sourcePort, centerOf(tgt));
    const tAnchor = anchorPoint(tgt, e.targetPort, centerOf(src));
    const sDir = exitDirection(src, sAnchor, e.sourcePort || 'auto');
    const tDir = exitDirection(tgt, tAnchor, e.targetPort || 'auto');

    // For sort key: when spreading along an E/W side we order by Y (target's Y for source-side, source's Y for target-side).
    // When spreading along N/S side, we order by X.
    const sKey = (sDir === 'E' || sDir === 'W') ? tAnchor.y : tAnchor.x;
    const tKey = (tDir === 'E' || tDir === 'W') ? sAnchor.y : sAnchor.x;

    const sGroupKey = `${e.source}:${sDir}`;
    const tGroupKey = `${e.target}:${tDir}`;
    if (!groups.has(sGroupKey)) groups.set(sGroupKey, []);
    if (!groups.has(tGroupKey)) groups.set(tGroupKey, []);
    groups.get(sGroupKey).push({ edgeId: e.id, role: 'source', sortKey: sKey });
    groups.get(tGroupKey).push({ edgeId: e.id, role: 'target', sortKey: tKey });
  }
  // Stable sort each group by sortKey
  for (const list of groups.values()) {
    list.sort((a, b) => a.sortKey - b.sortKey || a.edgeId.localeCompare(b.edgeId));
  }
  _edgeGroupCache = groups;
  _edgeGroupCacheKey = key;
  return groups;
}

// Given an edge endpoint, return the perpendicular offset (in pixels) that
// distinguishes it from siblings on the same node-side. Single-edge groups
// return 0 (no spread).
function spreadOffset(edge, role, dir, node) {
  const nodeId = role === 'source' ? edge.source : edge.target;
  const groupKey = `${nodeId}:${dir}`;
  const groups = buildEdgeGroups();
  const list = groups.get(groupKey);
  if (!list || list.length <= 1) return 0;
  const idx = list.findIndex(x => x.edgeId === edge.id && x.role === role);
  if (idx < 0) return 0;
  const n = list.length;
  const spacing = 16; // pixels between adjacent edges
  // Total spread width, capped to 70% of the node's side length
  const sideLen = nodeSideLength(node, dir);
  const cap = sideLen * 0.7;
  const totalSpread = Math.min((n - 1) * spacing, cap);
  const actualSpacing = (n > 1) ? totalSpread / (n - 1) : 0;
  // Distribute symmetrically around the port center.
  return (idx - (n - 1) / 2) * actualSpacing;
}

// Apply the spread offset to an anchor point. The offset is perpendicular to
// the exit direction: for E/W (horizontal exit) we offset in Y; for N/S we
// offset in X.
function applySpread(anchor, dir, offset) {
  if (offset === 0) return anchor;
  if (dir === 'E' || dir === 'W') return { x: anchor.x, y: anchor.y + offset };
  return { x: anchor.x + offset, y: anchor.y };
}


// ============================================================================
//  Orthogonal router
// ============================================================================
//
// Every segment is purely horizontal or vertical. Each segment leaves its
// anchor perpendicular to the node's edge (so lines emerge straight out of
// the side they're attached to), then bends 0–2 times to reach the other end.
//
// The router needs to know each anchor's *exit direction* — which way the
// line should leave the node. For a port on the East side this is +x; for N
// it's -y; etc. For `auto` anchors we infer the direction by comparing the
// anchor's position to the node's center.

const STUB = 22; // length of the perpendicular "stub" out of each anchor

function exitDirection(node, anchor, port) {
  // Returns one of: 'N','S','E','W' — the direction the line should leave `anchor`.
  if (port && port !== 'auto') {
    if (port === 'N' || port === 'NE' || port === 'NW') return 'N';
    if (port === 'S' || port === 'SE' || port === 'SW') return 'S';
    if (port === 'E') return 'E';
    if (port === 'W') return 'W';
    // diagonal ports on rectangles split between two cardinal directions —
    // pick the one closer to horizontal since left-to-right is the dominant
    // workflow flow direction
    return port === 'E' ? 'E' : 'W';
  }
  // auto — infer from anchor position vs node center
  const c = centerOf(node);
  const dx = anchor.x - c.x;
  const dy = anchor.y - c.y;
  if (Math.abs(dx) >= Math.abs(dy)) {
    return dx >= 0 ? 'E' : 'W';
  }
  return dy >= 0 ? 'S' : 'N';
}

function stubPoint(anchor, dir, len = STUB) {
  switch (dir) {
    case 'N': return { x: anchor.x,         y: anchor.y - len };
    case 'S': return { x: anchor.x,         y: anchor.y + len };
    case 'E': return { x: anchor.x + len,   y: anchor.y };
    case 'W': return { x: anchor.x - len,   y: anchor.y };
  }
  return anchor;
}

function isHorizontalDir(d) { return d === 'E' || d === 'W'; }

// Connect two stub endpoints (a, b) with an orthogonal polyline.
// dirA is the exit direction at a; dirB is the exit direction at b.
// Returns an array of intermediate points (a and b not included).
function orthoConnect(a, b, dirA, dirB) {
  // Returns { corners: [...], topology, segments } where:
  //   corners: 0, 1, or 2 intermediate points between stubA and stubB
  //   topology: 'T0' | 'T1' | 'T2' — describes the routing shape
  //   segments: array of { role, dir, perpAxis } describing each interior segment
  //     where role is a stable name ('seg_first', 'seg_mid', 'seg_last'),
  //     dir is the segment's direction ('H' or 'V'),
  //     perpAxis is the axis along which a perpendicular nudge moves it ('x' or 'y').
  //
  // Roles let user offsets survive topology recomputation when only the magnitude
  // of source/target movement changes. If the topology itself changes (e.g. user
  // re-pins a port), some hints become inapplicable and are silently ignored.
  const aHoriz = isHorizontalDir(dirA);
  const bHoriz = isHorizontalDir(dirB);

  // Case 1: T0 — already aligned, straight line, no corners.
  if (aHoriz && bHoriz && Math.abs(a.y - b.y) < 1) {
    return { corners: [], topology: 'T0', segments: [{ role: 'seg_first', dir: 'H', perpAxis: 'y' }] };
  }
  if (!aHoriz && !bHoriz && Math.abs(a.x - b.x) < 1) {
    return { corners: [], topology: 'T0', segments: [{ role: 'seg_first', dir: 'V', perpAxis: 'x' }] };
  }

  // Case 2: T1 — perpendicular stubs → 1 corner.
  if (aHoriz && !bHoriz) {
    return {
      corners: [{ x: b.x, y: a.y }],
      topology: 'T1_HV',
      segments: [
        { role: 'seg_first', dir: 'H', perpAxis: 'y' },  // a → corner: horizontal
        { role: 'seg_last',  dir: 'V', perpAxis: 'x' },  // corner → b: vertical
      ],
    };
  }
  if (!aHoriz && bHoriz) {
    return {
      corners: [{ x: a.x, y: b.y }],
      topology: 'T1_VH',
      segments: [
        { role: 'seg_first', dir: 'V', perpAxis: 'x' },
        { role: 'seg_last',  dir: 'H', perpAxis: 'y' },
      ],
    };
  }

  // Case 3: T2 — parallel stubs, two corners.
  if (aHoriz && bHoriz) {
    const my = (a.y + b.y) / 2;
    return {
      corners: [{ x: a.x, y: my }, { x: b.x, y: my }],
      topology: 'T2_H',
      segments: [
        { role: 'seg_first', dir: 'V', perpAxis: 'x' },  // a → corner1: vertical leg
        { role: 'seg_mid',   dir: 'H', perpAxis: 'y' },  // corner1 → corner2: middle bar
        { role: 'seg_last',  dir: 'V', perpAxis: 'x' },  // corner2 → b: vertical leg
      ],
    };
  }
  // both vertical
  const mx = (a.x + b.x) / 2;
  return {
    corners: [{ x: mx, y: a.y }, { x: mx, y: b.y }],
    topology: 'T2_V',
    segments: [
      { role: 'seg_first', dir: 'H', perpAxis: 'y' },
      { role: 'seg_mid',   dir: 'V', perpAxis: 'x' },
      { role: 'seg_last',  dir: 'H', perpAxis: 'y' },
    ],
  };
}

// Apply user-supplied routing hints (perpendicular offsets per segment role) to the
// corners produced by orthoConnect. Returns adjusted corners + the segment metadata
// updated to reflect any displacement so the caller knows where each segment now sits.
function applyRoutingHints(orthoResult, hints, stubA, stubB) {
  if (!hints || Object.keys(hints).length === 0) return orthoResult;
  const { corners, topology, segments } = orthoResult;

  // Topology decides which hint roles map to which corner adjustments.
  if (topology === 'T0') {
    // Straight line — no interior corners to displace. If the user has dragged this,
    // we need to bend it: insert two corners.
    const hint = hints.seg_first;
    if (typeof hint !== 'number' || Math.abs(hint) < 1) return orthoResult;
    const seg = segments[0];
    // create a single corner offset perpendicular: this *changes* topology, but
    // for the rendering pass we can just emit a 2-corner shape.
    if (seg.dir === 'H') {
      const newY = stubA.y + hint;
      return {
        corners: [{ x: stubA.x, y: newY }, { x: stubB.x, y: newY }],
        topology: 'T2_H',
        segments: [
          { role: 'seg_first', dir: 'V', perpAxis: 'x' },
          { role: 'seg_mid',   dir: 'H', perpAxis: 'y' },
          { role: 'seg_last',  dir: 'V', perpAxis: 'x' },
        ],
      };
    }
    const newX = stubA.x + hint;
    return {
      corners: [{ x: newX, y: stubA.y }, { x: newX, y: stubB.y }],
      topology: 'T2_V',
      segments: [
        { role: 'seg_first', dir: 'H', perpAxis: 'y' },
        { role: 'seg_mid',   dir: 'V', perpAxis: 'x' },
        { role: 'seg_last',  dir: 'H', perpAxis: 'y' },
      ],
    };
  }

  if (topology === 'T1_HV') {
    // One corner at (b.x, a.y). Two interior segments — seg_first (H) and seg_last (V).
    // Nudging seg_first (perpAxis y) → shift corner.y by hint
    // Nudging seg_last  (perpAxis x) → shift corner.x by hint
    const c = { ...corners[0] };
    if (typeof hints.seg_first === 'number') c.y += hints.seg_first;
    if (typeof hints.seg_last  === 'number') c.x += hints.seg_last;
    return { ...orthoResult, corners: [c] };
  }
  if (topology === 'T1_VH') {
    const c = { ...corners[0] };
    if (typeof hints.seg_first === 'number') c.x += hints.seg_first;
    if (typeof hints.seg_last  === 'number') c.y += hints.seg_last;
    return { ...orthoResult, corners: [c] };
  }

  if (topology === 'T2_H') {
    // Two corners on shared Y. Three interior segments:
    //   seg_first (V, perpAxis x): shifts corner1.x → also affects where seg_mid starts
    //   seg_mid   (H, perpAxis y): shifts shared Y → both corners move
    //   seg_last  (V, perpAxis x): shifts corner2.x
    const c1 = { ...corners[0] };
    const c2 = { ...corners[1] };
    if (typeof hints.seg_first === 'number') c1.x += hints.seg_first;
    if (typeof hints.seg_last  === 'number') c2.x += hints.seg_last;
    if (typeof hints.seg_mid   === 'number') { c1.y += hints.seg_mid; c2.y += hints.seg_mid; }
    return { ...orthoResult, corners: [c1, c2] };
  }
  if (topology === 'T2_V') {
    const c1 = { ...corners[0] };
    const c2 = { ...corners[1] };
    if (typeof hints.seg_first === 'number') c1.y += hints.seg_first;
    if (typeof hints.seg_last  === 'number') c2.y += hints.seg_last;
    if (typeof hints.seg_mid   === 'number') { c1.x += hints.seg_mid; c2.x += hints.seg_mid; }
    return { ...orthoResult, corners: [c1, c2] };
  }

  return orthoResult;
}

// Loop-back specialization: when the natural orthogonal route would U-turn
// awkwardly (e.g. flowing backward across the same lane), route around using
// a tall vertical detour below (or above) all involved nodes.
function isBackwardFlow(sp, tp, dirA, dirB) {
  // "Backward" = source is to the right of target AND both anchors face the
  // same horizontal direction (so the natural elbow would loop awkwardly).
  if (dirA === 'E' && dirB === 'W' && sp.x > tp.x) return false; // normal R-to-L flow
  if (dirA === 'W' && dirB === 'E' && sp.x < tp.x) return false; // normal L-to-R flow
  // A clear loop-back: source emits E but target receives from S/N from below source
  if (dirA === 'E' && tp.x < sp.x) return true;
  if (dirA === 'W' && tp.x > sp.x) return true;
  return false;
}

// Scan a horizontal corridor for nodes that would intersect it.
// Returns the count of nodes (excluding source/target) whose vertical extent
// crosses the band [y - margin, y + margin] within the X range [x1, x2].
function nodesIntersectingCorridor(y, x1, x2, src, tgt, margin = 20) {
  const xMin = Math.min(x1, x2) - margin;
  const xMax = Math.max(x1, x2) + margin;
  let count = 0;
  for (const n of state.nodes) {
    if (n.id === src.id || n.id === tgt.id) continue;
    const d = NODE_DEFAULTS[n.type];
    const nx1 = n.x, nx2 = n.x + d.w;
    const ny1 = n.y - margin, ny2 = n.y + d.h + margin;
    if (nx2 < xMin || nx1 > xMax) continue;
    if (y >= ny1 && y <= ny2) count++;
  }
  return count;
}

// Check whether a polyline (array of {x,y}) crosses through any node other than
// source/target. Returns true if any segment of the polyline intersects a node's
// bounding box. Used to validate a proposed routing.
function polylineCrossesNodes(points, src, tgt, margin = 4) {
  for (let i = 0; i < points.length - 1; i++) {
    const a = points[i], b = points[i + 1];
    // segment is axis-aligned (orthogonal routing)
    const x1 = Math.min(a.x, b.x), x2 = Math.max(a.x, b.x);
    const y1 = Math.min(a.y, b.y), y2 = Math.max(a.y, b.y);
    for (const n of state.nodes) {
      if (n.id === src.id || n.id === tgt.id) continue;
      const d = NODE_DEFAULTS[n.type];
      const nx1 = n.x - margin, nx2 = n.x + d.w + margin;
      const ny1 = n.y - margin, ny2 = n.y + d.h + margin;
      // segment vs rect intersection — for axis-aligned segments this reduces to:
      // segment x-range overlaps rect x-range AND segment y-range overlaps rect y-range
      if (x2 < nx1 || x1 > nx2) continue;
      if (y2 < ny1 || y1 > ny2) continue;
      return true;
    }
  }
  return false;
}

// Route via a detour band above or below the bounding box of source+target.
// Generalised over direction: from each stub, go vertically toward the chosen
// detour Y, then horizontally across, then vertically to the other stub.
// Picks the band (above vs below) with the fewest node crossings.
function orthoLoopBack(spA, spB, dirA, dirB, src, tgt, edge) {
  const srcH = NODE_DEFAULTS[src.type].h;
  const tgtH = NODE_DEFAULTS[tgt.type].h;
  const srcBottom = src.y + srcH, srcTop = src.y;
  const tgtBottom = tgt.y + tgtH, tgtTop = tgt.y;
  const lowestBottom = Math.max(srcBottom, tgtBottom);
  const highestTop = Math.min(srcTop, tgtTop);

  // Available bands: when source and target share a lane, constrain detours
  // to remain *inside* that lane (just below the lower artefact, or just above
  // the upper artefact). When they differ, use the broader bounds.
  const STUB_CLEARANCE = 18; // distance from node edge to the detour line
  const LANE_MARGIN = 12;    // distance from the lane border to the detour line
  let belowMin, belowMax, aboveMin, aboveMax;
  if (src.lane === tgt.lane) {
    const lane = findLane(src.lane);
    if (lane) {
      const laneTopY = laneTop(src.lane);
      const laneBotY = laneTopY + lane.height;
      belowMin = lowestBottom + STUB_CLEARANCE;
      belowMax = laneBotY - LANE_MARGIN;
      aboveMin = laneTopY + LANE_MARGIN;
      aboveMax = highestTop - STUB_CLEARANCE;
    }
  }
  // Fallback (cross-lane or no lane info): wider bounds, no clamp
  if (belowMax === undefined) {
    belowMin = lowestBottom + STUB_CLEARANCE;
    belowMax = lowestBottom + 200;
    aboveMin = highestTop - 200;
    aboveMax = highestTop - STUB_CLEARANCE;
  }

  // If the edge has a user-set detourY, honor it — but clamp to a sensible band.
  if (edge && typeof edge.detourY === 'number') {
    // Decide which band the user's value falls in
    const userY = edge.detourY;
    let clampedY;
    if (userY >= lowestBottom) {
      clampedY = Math.max(belowMin, Math.min(belowMax, userY));
    } else {
      clampedY = Math.max(aboveMin, Math.min(aboveMax, userY));
    }
    return {
      points: [{ x: spA.x, y: clampedY }, { x: spB.x, y: clampedY }],
      detourY: clampedY,
    };
  }

  // Auto-pick: try a few candidate Ys in the available bands and score each.
  // Score = node crossings * 100 + tiny distance penalty (prefer closer detours).
  const candidates = [];
  for (const t of [0.25, 0.5, 0.4, 0.6, 0.75]) {
    if (belowMax > belowMin) candidates.push({ y: belowMin + (belowMax - belowMin) * t, kind: 'below' });
    if (aboveMax > aboveMin) candidates.push({ y: aboveMax - (aboveMax - aboveMin) * t, kind: 'above' });
  }
  // Also include a tight "just below the lower artefact" option, since that
  // matches the visual you asked for: "a bit under the lower artefact".
  candidates.unshift({ y: belowMin, kind: 'below' });
  candidates.unshift({ y: aboveMax, kind: 'above' });

  let best = candidates[0];
  let bestScore = Infinity;
  for (const c of candidates) {
    const crossings = nodesIntersectingCorridor(c.y, spA.x, spB.x, src, tgt);
    // Prefer closer-to-artefact (the value of c.y close to lowestBottom or highestTop)
    const closenessPenalty = c.kind === 'below'
      ? (c.y - lowestBottom) / 50
      : (highestTop - c.y) / 50;
    const score = crossings * 100 + closenessPenalty + (c.kind === 'above' ? 0.05 : 0);
    if (score < bestScore) { bestScore = score; best = c; }
  }

  const detourY = best.y;
  return {
    points: [{ x: spA.x, y: detourY }, { x: spB.x, y: detourY }],
    detourY,
  };
}

// Main routing entry: route a single segment from anchor A → anchor B.
// Returns { polyline, segmentMeta } where segmentMeta describes each interior
// segment (between stubA and stubB) — its role name, direction, perpendicular axis.
// The caller (renderer) uses this metadata to place segment-drag handles.
function routeOrthogonalSegment(anchorA, anchorB, dirA, dirB, src, tgt, edge) {
  const spA = stubPoint(anchorA, dirA);
  const spB = stubPoint(anchorB, dirB);

  // Compute the simple orthogonal route as a structured object, then apply
  // user-supplied per-segment hints if present.
  const arrivalDirAtB = oppositeDir(dirB);
  let orthoResult = orthoConnect(spA, spB, dirA, arrivalDirAtB);
  if (edge && edge.routingHints) {
    orthoResult = applyRoutingHints(orthoResult, edge.routingHints, spA, spB);
  }
  const simplePolyline = [anchorA, spA, ...orthoResult.corners, spB, anchorB];

  // Loop-back is needed if (a) the natural path would cross a node, or (b) the
  // edge has an explicit user-set detourY, or (c) the legacy backward-flow
  // heuristic matched.
  // Don't trigger loop-back if the user has set per-segment hints — those are
  // an explicit override that should always win.
  const hasUserHints = edge && edge.routingHints && Object.keys(edge.routingHints).length > 0;
  const needsLoop = src && tgt && !hasUserHints && (
    polylineCrossesNodes(simplePolyline, src, tgt) ||
    (edge && typeof edge.detourY === 'number') ||
    isBackwardFlow(anchorA, anchorB, dirA, dirB)
  );

  if (needsLoop) {
    const loop = orthoLoopBack(spA, spB, dirA, dirB, src, tgt, edge);
    return {
      polyline: [anchorA, spA, ...loop.points, spB, anchorB],
      loopDetourY: loop.detourY,
      loopXRange: [spA.x, spB.x],
      // For loop-back, the segments are: leg_a (V), cross (H), leg_b (V).
      // We expose them as standard segment roles for the segment-handle UI.
      segmentMeta: [
        { role: 'seg_first', dir: 'V', perpAxis: 'x' },
        { role: 'seg_mid',   dir: 'H', perpAxis: 'y' },
        { role: 'seg_last',  dir: 'V', perpAxis: 'x' },
      ],
    };
  }

  return {
    polyline: simplePolyline,
    segmentMeta: orthoResult.segments,
  };
}

function oppositeDir(d) { return { N: 'S', S: 'N', E: 'W', W: 'E' }[d]; }

function routePathFromPoints(points, src, tgt, hasManualWaypoints, edge) {
  if (points.length < 2) return '';

  // During an endpoint drag in *open space* (no snap target), draw a simple
  // straight line from the non-dragged anchor to the cursor. This avoids
  // visually jarring orthogonal contortions while the user is mid-aim.
  if (edgeDrag && edgeDrag.kind === 'endpoint' && edgeDrag.edgeId === edge?.id && !edgeDrag.snapNodeId) {
    return 'M' + points.map(p => `${p.x} ${p.y}`).join(' L');
  }

  // Resolve exit directions for the two endpoints. We need `edge` here to know
  // the ports — if not provided (legacy callers), fall back to auto inference.
  const srcPort = edge?.sourcePort || 'auto';
  const tgtPort = edge?.targetPort || 'auto';
  const dirA = exitDirection(src, points[0], srcPort);
  const dirB = exitDirection(tgt, points[points.length - 1], tgtPort);

  if (hasManualWaypoints) {
    // With manual waypoints: route each segment between consecutive points
    // orthogonally. Only the very first and last segments get perpendicular
    // stubs from the actual node anchors; intermediate joins are direct.
    const out = [];
    const firstResult = routeOrthogonalSegment(points[0], points[1], dirA, inferIntermediateArrival(points[1], points[0]), src, null, edge);
    out.push(...firstResult.polyline);
    for (let i = 1; i < points.length - 2; i++) {
      // intermediate-to-intermediate — connect with an orthogonal L
      const a = points[i], b = points[i + 1];
      const corner = { x: b.x, y: a.y }; // simple L; alternative: { x: a.x, y: b.y }
      out.push(corner, b);
    }
    const lastResult = routeOrthogonalSegment(points[points.length - 2], points[points.length - 1], inferIntermediateExit(points[points.length - 2], points[points.length - 1]), dirB, null, tgt, edge);
    // skip first point of last to avoid duplicating the join
    out.push(...lastResult.polyline.slice(1));
    return 'M' + out.map(p => `${p.x} ${p.y}`).join(' L');
  }

  // No manual waypoints — single orthogonal segment from anchor to anchor.
  const result = routeOrthogonalSegment(points[0], points[points.length - 1], dirA, dirB, src, tgt, edge);
  // Stash routing info on the edge (transient — used by the renderer to place handles).
  if (edge) {
    edge._loopDetourY = result.loopDetourY;
    edge._loopXRange = result.loopXRange;
    edge._segmentMeta = result.segmentMeta;
    edge._renderedPolyline = result.polyline;
  }
  return 'M' + result.polyline.map(p => `${p.x} ${p.y}`).join(' L');
}

// For intermediate joins in manually-routed paths, infer a reasonable exit/arrival
// direction from the relative geometry of neighboring points.
function inferIntermediateExit(from, to) {
  const dx = to.x - from.x, dy = to.y - from.y;
  if (Math.abs(dx) >= Math.abs(dy)) return dx >= 0 ? 'E' : 'W';
  return dy >= 0 ? 'S' : 'N';
}
function inferIntermediateArrival(at, from) {
  // arrival direction is the direction we were going at `at`, i.e. inverse of where we came from
  return inferIntermediateExit(from, at);
}

function midOfPolyline(points) {
  if (points.length < 2) return { x: 0, y: 0 };
  if (points.length === 2) return { x: (points[0].x + points[1].x) / 2, y: (points[0].y + points[1].y) / 2 };
  // pick the midpoint of the middle segment
  const i = Math.floor((points.length - 1) / 2);
  return { x: (points[i].x + points[i + 1].x) / 2, y: (points[i].y + points[i + 1].y) / 2 };
}
function midOfPath(sp, tp) {
  return { x: (sp.x + tp.x) / 2, y: (sp.y + tp.y) / 2 };
}

// ============================================================================
//  Properties panel
// ============================================================================
function renderProperties() {
  const props = $('properties');
  props.innerHTML = '';
  if (!selection) {
    // No selection → show the workflow metadata editor.
    // This is the panel for editing things that belong to the workflow itself
    // (not to any specific node): title, version, description, source path.
    const wm = state.workflowMeta = state.workflowMeta || { id: 'workflow', version: '1' };
    props.appendChild(propsHeader('workflow', wm.id, null));

    const sMeta = section('Workflow');
    sMeta.appendChild(field('ID', wm.id, v => {
      const trimmed = (v || '').trim().toLowerCase().replace(/[^a-z0-9_\-]/g, '-');
      if (!trimmed || trimmed === activeKey) return;
      const ok = renameActiveWorkflow(trimmed);
      if (!ok) {
        // collision — re-render to revert the field
        renderProperties();
      } else {
        renderProperties();
      }
    }, { mono: true, hint: 'identifier · lowercase, no spaces · unique in library' }));
    sMeta.appendChild(field('Title', wm.title || '', v => {
      wm.title = v;
      refreshLibraryUI();
    }, { hint: 'human-readable name shown in picker' }));
    sMeta.appendChild(field('Version', wm.version || '1', v => {
      const trimmed = (v || '').trim();
      if (!trimmed) return;
      wm.version = trimmed;
      refreshLibraryUI();
    }, { mono: true, hint: 'bump manually when contract changes' }));
    sMeta.appendChild(field('Description', wm.description || '', v => {
      wm.description = v;
    }, { textarea: true, hint: 'free text · what this workflow does' }));
    sMeta.appendChild(field('Source', wm.source || '', v => {
      wm.source = v;
    }, { mono: true, hint: 'optional · path to originating doc' }));
    sMeta.appendChild(field('Default tier', wm.tier_default || '2', v => {
      wm.tier_default = v;
    }, { mono: true, hint: '0–3 · applies to nodes without explicit tier' }));
    props.appendChild(sMeta);

    // Library section — quick view of all loaded workflows
    if (library.size > 1) {
      const sLib = section('Library');
      const libList = document.createElement('div');
      libList.className = 'props-lib-list';
      for (const [k, wf] of Array.from(library.entries()).sort()) {
        const row = document.createElement('div');
        row.className = 'props-lib-row' + (k === activeKey ? ' active' : '');
        const title = wf.workflowMeta?.title || k;
        const v = wf.workflowMeta?.version || '1';
        row.innerHTML = `<span class="props-lib-name">${title}</span><span class="props-lib-id">${k} v${v}</span>`;
        row.onclick = () => { if (k !== activeKey) loadFromLibrary(k); };
        libList.appendChild(row);
      }
      sLib.appendChild(libList);
      props.appendChild(sLib);
    }

    // Hints section — keep the original instructional text but compact
    const sHint = section('Tips', true);
    const tips = document.createElement('div');
    tips.className = 'props-tips';
    tips.innerHTML = 'Click a node or edge to inspect.<br>' +
      '<span class="kbd">Connect</span> mode → click source, then target.<br>' +
      'Drag selected nodes to reposition.<br>' +
      '<span class="kbd">Delete</span> removes selection · <span class="kbd">Esc</span> clears it.';
    sHint.appendChild(tips);
    props.appendChild(sHint);

    return;
  }
  if (selection.kind === 'edge') {
    const e = findEdge(selection.id);
    if (!e) { selection = null; renderProperties(); return; }
    props.appendChild(propsHeader('sequence flow', displayIdOf(e), () => deleteEdge(e.id)));
    const sec = section('Flow');
    sec.appendChild(field('Label', e.name || '', v => { e.name = v; renderEdges(); }));
    sec.appendChild(field('Condition', e.condition || '', v => { e.condition = v; }, { mono: true, textarea: true, hint: 'expression · evaluated by exclusive gateway' }));
    props.appendChild(sec);

    // Routing section — endpoints, ports, and waypoints
    const wpCount = (e.waypoints || []).length;
    const secR = section('Routing');
    const info = document.createElement('div');
    info.className = 'routing-info';
    const srcPort = e.sourcePort || 'auto';
    const tgtPort = e.targetPort || 'auto';
    const srcNode = findNode(e.source);
    const tgtNode = findNode(e.target);
    const srcDisplay = srcNode ? displayIdOf(srcNode) : e.source;
    const tgtDisplay = tgtNode ? displayIdOf(tgtNode) : e.target;
    info.innerHTML = `<div><strong>source</strong> → <span class="mono">${srcDisplay}</span> · port <span class="mono">${srcPort}</span></div>` +
                     `<div><strong>target</strong> → <span class="mono">${tgtDisplay}</span> · port <span class="mono">${tgtPort}</span></div>` +
                     `<div><strong>waypoints</strong> · ${wpCount} ${wpCount === 1 ? 'bend' : 'bends'}</div>`;
    secR.appendChild(info);

    // Port pickers — dropdown for source and target
    const portOptions = ['auto', ...PORT_NAMES];
    secR.appendChild(selectField('Source port', srcPort, portOptions, v => {
      e.sourcePort = v;
      e.waypoints = [];
      renderAll();
    }, 'pin connection to a side of the source node'));
    secR.appendChild(selectField('Target port', tgtPort, portOptions, v => {
      e.targetPort = v;
      e.waypoints = [];
      renderAll();
    }, 'pin connection to a side of the target node'));

    const tipText = 'Click a port dot on either node to pin that endpoint. Drag an endpoint handle onto a node to re-anchor; drop on the same node to snap to its nearest port. Drag the dashed midpoint dot to add a bend.';
    const tip = document.createElement('div');
    tip.className = 'routing-tip';
    tip.textContent = tipText;
    secR.appendChild(tip);

    const btnRow = document.createElement('div');
    btnRow.className = 'routing-actions';
    const hintCount = e.routingHints ? Object.keys(e.routingHints).length : 0;
    const hasOverrides = wpCount > 0 || typeof e.detourY === 'number' || hintCount > 0;
    if (hasOverrides) {
      const resetBtn = document.createElement('button');
      resetBtn.className = 'btn btn-routing';
      resetBtn.textContent = 'Reset routing';
      resetBtn.onclick = () => {
        e.waypoints = [];
        delete e.detourY;
        delete e.routingHints;
        renderEdges();
        renderProperties();
      };
      btnRow.appendChild(resetBtn);
    }
    if (e.sourcePort || e.targetPort) {
      const clearPortsBtn = document.createElement('button');
      clearPortsBtn.className = 'btn btn-routing';
      clearPortsBtn.textContent = 'Clear ports';
      clearPortsBtn.onclick = () => {
        e.sourcePort = null; e.targetPort = null;
        e.waypoints = [];
        delete e.detourY;
        delete e.routingHints; // hints become stale on port change
        renderAll();
      };
      btnRow.appendChild(clearPortsBtn);
    }
    const reverseBtn = document.createElement('button');
    reverseBtn.className = 'btn btn-routing';
    reverseBtn.textContent = 'Reverse';
    reverseBtn.onclick = () => {
      const tmp = e.source; e.source = e.target; e.target = tmp;
      const tmpP = e.sourcePort; e.sourcePort = e.targetPort; e.targetPort = tmpP;
      if (e.waypoints) e.waypoints.reverse();
      renderAll();
    };
    btnRow.appendChild(reverseBtn);
    secR.appendChild(btnRow);

    props.appendChild(secR);
    return;
  }
  if (selection.kind === 'lane') {
    const lane = findLane(selection.id);
    if (!lane) { selection = null; renderProperties(); return; }
    const lanes = getLanes();
    const idx = lanes.indexOf(lane);
    const isLast = lanes.length <= 1;
    const nodeCount = state.nodes.filter(n => n.lane === lane.id).length;

    props.appendChild(propsHeader('lane', lane.id, () => {
      if (isLast) { alert('Cannot delete the last lane.'); return; }
      if (nodeCount > 0) {
        if (!confirm(`This lane has ${nodeCount} node${nodeCount === 1 ? '' : 's'}. They will be reassigned to the first remaining lane. Continue?`)) return;
      }
      deleteLane(lane.id);
    }));

    const sBpmn = section('Lane');
    sBpmn.appendChild(field('Name', lane.name, v => {
      lane.name = v;
      // Auto-update abbr unless user has overridden it manually
      if (!lane.abbrManual) lane.abbr = ensureUniqueAbbr(lane, deriveLaneAbbr(v));
      refreshDisplayIds();
      renderAll();
    }));
    sBpmn.appendChild(field('Abbreviation', lane.abbr || '', v => {
      const newAbbr = (v || '').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 3);
      if (!newAbbr) return;
      // refuse collision with other lanes
      if (state.lanes.some(l => l !== lane && l.abbr === newAbbr)) return;
      lane.abbr = newAbbr;
      lane.abbrManual = true;
      refreshDisplayIds();
      renderAll();
    }, { mono: true, hint: '3-char prefix · used in display ids' }));
    sBpmn.appendChild(field('ID', lane.id, v => {
      if (!v || v === lane.id) return;
      const old = lane.id;
      lane.id = v;
      state.nodes.forEach(n => { if (n.lane === old) n.lane = v; });
      selection = { kind: 'lane', id: v };
      refreshDisplayIds();
      renderAll();
    }, { mono: true }));
    sBpmn.appendChild(selectField('Authority', lane.authority, AUTHORITIES, v => {
      lane.authority = v;
      renderAll();
    }, 'tints background · drives D1 validation'));

    // Height — small numeric stepper
    const heightWrap = document.createElement('div');
    heightWrap.className = 'field';
    const hLbl = document.createElement('div');
    hLbl.className = 'field-label';
    hLbl.textContent = 'Height';
    const hHint = document.createElement('span');
    hHint.className = 'field-hint';
    hHint.textContent = '· vertical space (px)';
    hLbl.appendChild(hHint);
    heightWrap.appendChild(hLbl);
    const hRow = document.createElement('div');
    hRow.className = 'lane-height-row';
    const hMinus = document.createElement('button');
    hMinus.className = 'btn btn-routing';
    hMinus.textContent = '−';
    hMinus.onclick = () => { lane.height = Math.max(60, lane.height - 30); renderAll(); };
    const hVal = document.createElement('input');
    hVal.className = 'field-input';
    hVal.style.textAlign = 'center';
    hVal.value = lane.height;
    hVal.addEventListener('change', e => {
      const v = parseInt(e.target.value, 10);
      if (!isNaN(v) && v >= 60 && v <= 800) { lane.height = v; renderAll(); }
      else { e.target.value = lane.height; }
    });
    const hPlus = document.createElement('button');
    hPlus.className = 'btn btn-routing';
    hPlus.textContent = '+';
    hPlus.onclick = () => { lane.height = Math.min(800, lane.height + 30); renderAll(); };
    hRow.appendChild(hMinus); hRow.appendChild(hVal); hRow.appendChild(hPlus);
    heightWrap.appendChild(hRow);
    sBpmn.appendChild(heightWrap);

    props.appendChild(sBpmn);

    // Ordering
    const secO = section('Order');
    const orderInfo = document.createElement('div');
    orderInfo.className = 'routing-info';
    orderInfo.innerHTML = `<div><strong>position</strong> · ${idx + 1} of ${lanes.length}</div>` +
                          `<div><strong>nodes in lane</strong> · ${nodeCount}</div>`;
    secO.appendChild(orderInfo);
    const orderRow = document.createElement('div');
    orderRow.className = 'routing-actions';
    const upBtn = document.createElement('button');
    upBtn.className = 'btn btn-routing';
    upBtn.textContent = '↑ Move up';
    upBtn.disabled = idx === 0;
    upBtn.onclick = () => { if (idx === 0) return; moveLane(lane.id, idx - 1); };
    const downBtn = document.createElement('button');
    downBtn.className = 'btn btn-routing';
    downBtn.textContent = '↓ Move down';
    downBtn.disabled = idx === lanes.length - 1;
    downBtn.onclick = () => { if (idx === lanes.length - 1) return; moveLane(lane.id, idx + 1); };
    orderRow.appendChild(upBtn); orderRow.appendChild(downBtn);
    secO.appendChild(orderRow);
    props.appendChild(secO);
    return;
  }
  const n = findNode(selection.id);
  if (!n) { selection = null; renderProperties(); return; }

  props.appendChild(propsHeader(n.type, displayIdOf(n), () => deleteNode(n.id)));

  // BPMN basics
  const sBpmn = section('BPMN');
  sBpmn.appendChild(field('Name', n.name, v => {
    n.name = v;
    // Slug auto-tracks the name unless the user has overridden it.
    if (!n.slugManual) n.slug = deriveUniqueSlug(n, v);
    refreshDisplayIds();
    renderNodes();
    renderProperties();
  }));
  sBpmn.appendChild(field('Slug', n.slug || '', v => {
    n.slug = (v || '').toLowerCase().replace(/[^a-z0-9\-]/g, '').slice(0, 16);
    n.slugManual = true; // mark as user-overridden so name changes don't clobber it
    refreshDisplayIds();
    renderNodes();
    renderProperties();
  }, { mono: true, hint: 'short id descriptor · derived from name unless overridden' }));
  // Read-only displayId preview
  const displayPreview = document.createElement('div');
  displayPreview.className = 'field';
  const displayLabel = document.createElement('div');
  displayLabel.className = 'field-label';
  displayLabel.textContent = 'Display ID';
  const displayHint = document.createElement('span');
  displayHint.className = 'field-hint';
  displayHint.textContent = '· computed · <lane>_<seq>_<slug>';
  displayLabel.appendChild(displayHint);
  displayPreview.appendChild(displayLabel);
  const displayValue = document.createElement('div');
  displayValue.className = 'field-input';
  displayValue.style.cssText = 'background: var(--surface); color: var(--accent); user-select: text;';
  displayValue.textContent = displayIdOf(n);
  displayPreview.appendChild(displayValue);
  sBpmn.appendChild(displayPreview);
  // Read-only uid
  const uidField = document.createElement('div');
  uidField.className = 'field';
  const uidLabel = document.createElement('div');
  uidLabel.className = 'field-label';
  uidLabel.textContent = 'UID';
  const uidHint = document.createElement('span');
  uidHint.className = 'field-hint';
  uidHint.textContent = '· immutable internal id';
  uidLabel.appendChild(uidHint);
  uidField.appendChild(uidLabel);
  const uidValue = document.createElement('div');
  uidValue.className = 'field-input';
  uidValue.style.cssText = 'background: var(--surface); color: var(--text-faint); user-select: text;';
  uidValue.textContent = n.uid;
  uidField.appendChild(uidValue);
  sBpmn.appendChild(uidField);

  sBpmn.appendChild(selectField('Lane', n.lane, getLanes().map(l => l.id), v => {
    n.lane = v;
    // snap to that lane's center vertically
    n.y = laneCenterY(v) - NODE_DEFAULTS[n.type].h / 2;
    refreshDisplayIds();
    renderNodes(); renderEdges();
    renderProperties();
  }));
  props.appendChild(sBpmn);

  // AEF extensions
  const aefFields = AEF_FIELDS[n.type];
  if (aefFields && aefFields.length) {
    const sAef = section('Extensions', true);
    n.aef = n.aef || {};
    for (const f of aefFields) {
      const meta = FIELD_META[f];
      if (meta.special === 'tier') {
        sAef.appendChild(tierField(n.aef[f] || '', v => { n.aef[f] = v; renderProperties(); }));
      } else if (meta.special === 'select') {
        sAef.appendChild(selectField(meta.label, n.aef[f] || '', meta.options, v => { n.aef[f] = v; }, meta.hint));
      } else if (meta.special === 'workflowPicker') {
        // Dropdown listing all loaded workflows; plus a "(other — type below)" option
        // for the case where the target workflow isn't loaded in this session.
        const options = Array.from(library.keys()).filter(k => k !== activeKey);
        options.push('__other__');
        const cur = n.aef[f] || '';
        // If the current value matches a known workflow, show as selected; else show "(other)" and a text field below
        const knownMatch = options.includes(cur);
        sAef.appendChild(selectField(
          meta.label,
          knownMatch ? cur : (cur ? '__other__' : ''),
          options.map(o => o === '__other__' ? '(other — type below)' : o),
          v => {
            // Reverse the display mapping
            if (v === '(other — type below)') {
              n.aef[f] = n.aef[f] && n.aef[f] !== '__other__' ? n.aef[f] : '';
              renderProperties();
            } else {
              n.aef[f] = v;
              renderProperties();
            }
          },
          meta.hint,
        ));
        // Free-text override field, always visible — lets the user type a workflow id
        // not currently loaded into the session.
        sAef.appendChild(field(meta.label + ' (free text)', n.aef[f] || '', v => { n.aef[f] = v; renderProperties(); }, { mono: true, hint: 'override or workflow not loaded' }));
      } else {
        sAef.appendChild(field(meta.label, n.aef[f] || '', v => { n.aef[f] = v; }, { mono: true, textarea: meta.textarea, hint: meta.hint }));
      }
    }
    props.appendChild(sAef);
  }

  // I/O contract (data flowing through the workflow, not filesystem side-effects)
  const ioSpec = NODE_IO[n.type];
  if (ioSpec && (ioSpec.in || ioSpec.out)) {
    n.io = n.io || {};
    const sIo = section('I/O contract', true);
    if (ioSpec.in)  sIo.appendChild(ioListField('inputs',  n.io.inputs  || (n.io.inputs  = []), true));
    if (ioSpec.out) sIo.appendChild(ioListField('outputs', n.io.outputs || (n.io.outputs = []), false));
    props.appendChild(sIo);
  }
}
function propsHeader(typeName, id, onDelete) {
  const h = document.createElement('div');
  h.className = 'props-header';
  const badge = document.createElement('div');
  badge.className = 'props-type-badge';
  badge.innerHTML = typeBadgeSvg(typeName);
  const info = document.createElement('div');
  info.className = 'props-type-info';
  const name = document.createElement('div');
  name.className = 'props-type-name';
  name.textContent = typeName;
  const idEl = document.createElement('div');
  idEl.className = 'props-type-id';
  idEl.textContent = id;
  info.appendChild(name); info.appendChild(idEl);
  h.appendChild(badge); h.appendChild(info);
  if (onDelete) {
    const del = document.createElement('button');
    del.className = 'props-delete';
    del.textContent = '× delete';
    del.onclick = onDelete;
    h.appendChild(del);
  }
  return h;
}
function typeBadgeSvg(t) {
  if (t === 'startEvent') return '<svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--green-soft)" stroke="var(--green)" stroke-width="1.5"/></svg>';
  if (t === 'endEvent') return '<svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--red-soft)" stroke="var(--red)" stroke-width="3"/></svg>';
  if (t === 'serviceTask') return '<svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--blue-soft)" stroke="var(--blue)" stroke-width="1.5"/></svg>';
  if (t === 'userTask') return '<svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/></svg>';
  if (t === 'scriptTask') return '<svg viewBox="0 0 28 28"><rect x="2" y="6" width="24" height="16" rx="3" fill="var(--orange-soft)" stroke="var(--orange)" stroke-width="1.5"/></svg>';
  if (t === 'linkEventThrow') return '<svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/><path d="M9 8 L17 14 L9 20" stroke="var(--accent)" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  if (t === 'linkEventCatch') return '<svg viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="var(--accent-soft)" stroke="var(--accent)" stroke-width="1.5"/><path d="M19 8 L11 14 L19 20" stroke="var(--accent)" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  if (t === 'workflow') return '<svg viewBox="0 0 28 28"><rect x="3" y="5" width="22" height="18" rx="2" fill="none" stroke="var(--accent)" stroke-width="1.5"/><line x1="9" y1="5" x2="9" y2="23" stroke="var(--accent)" stroke-width="1.2"/><circle cx="6" cy="9" r="1.2" fill="var(--accent)"/></svg>';
  if (t === 'exclusiveGateway') return '<svg viewBox="0 0 28 28"><path d="M14 4 L24 14 L14 24 L4 14 Z" fill="var(--orange-soft)" stroke="var(--orange)" stroke-width="1.5"/></svg>';
  if (t === 'parallelGateway') return '<svg viewBox="0 0 28 28"><path d="M14 4 L24 14 L14 24 L4 14 Z" fill="var(--blue-soft)" stroke="var(--blue)" stroke-width="1.5"/></svg>';
  if (t === 'sequence flow') return '<svg viewBox="0 0 28 28"><path d="M4 14 H22" stroke="var(--text-dim)" stroke-width="2"/><path d="M18 10 L22 14 L18 18" stroke="var(--text-dim)" stroke-width="2" fill="none"/></svg>';
  if (t === 'lane') return '<svg viewBox="0 0 28 28"><rect x="3" y="6" width="22" height="16" rx="2" fill="none" stroke="var(--text-dim)" stroke-width="1.5"/><line x1="9" y1="6" x2="9" y2="22" stroke="var(--text-dim)" stroke-width="1.5"/></svg>';
  return '';
}
function section(title, isAef) {
  const s = document.createElement('div');
  s.className = 'props-section';
  const t = document.createElement('div');
  t.className = 'props-section-title';
  t.textContent = title;
  if (isAef) {
    const ns = document.createElement('span');
    ns.className = 'ns-tag';
    ns.textContent = 'aef:';
    t.appendChild(ns);
  }
  s.appendChild(t);
  return s;
}
function field(label, value, onInput, opts = {}) {
  const wrap = document.createElement('div');
  wrap.className = 'field';
  const lbl = document.createElement('div');
  lbl.className = 'field-label';
  lbl.textContent = label;
  if (opts.hint) {
    const h = document.createElement('span');
    h.className = 'field-hint';
    h.textContent = '· ' + opts.hint;
    lbl.appendChild(h);
  }
  wrap.appendChild(lbl);
  const inp = document.createElement(opts.textarea ? 'textarea' : 'input');
  inp.className = opts.textarea ? 'field-textarea' : 'field-input';
  inp.value = value;
  inp.spellcheck = false;
  inp.addEventListener('input', e => onInput(e.target.value));
  inp.addEventListener('blur', () => { renderProperties(); });
  wrap.appendChild(inp);
  return wrap;
}
function selectField(label, value, options, onInput, hint) {
  const wrap = document.createElement('div');
  wrap.className = 'field';
  const lbl = document.createElement('div');
  lbl.className = 'field-label';
  lbl.textContent = label;
  if (hint) {
    const h = document.createElement('span');
    h.className = 'field-hint';
    h.textContent = '· ' + hint;
    lbl.appendChild(h);
  }
  wrap.appendChild(lbl);
  const sel = document.createElement('select');
  sel.className = 'field-select';
  for (const o of options) {
    const opt = document.createElement('option');
    opt.value = o;
    opt.textContent = o;
    if (o === value) opt.selected = true;
    sel.appendChild(opt);
  }
  sel.addEventListener('change', e => { onInput(e.target.value); renderProperties(); });
  wrap.appendChild(sel);
  return wrap;
}
function tierField(value, onInput) {
  const wrap = document.createElement('div');
  wrap.className = 'field';
  const lbl = document.createElement('div');
  lbl.className = 'field-label';
  lbl.textContent = 'Tier';
  const h = document.createElement('span');
  h.className = 'field-hint';
  h.textContent = '· risk classification';
  lbl.appendChild(h);
  wrap.appendChild(lbl);
  const row = document.createElement('div');
  row.className = 'tier-row';
  ['0', '1', '2', '3'].forEach(t => {
    const b = document.createElement('div');
    b.className = 'tier-btn tier-' + t + (value === t ? ' active' : '');
    b.textContent = 'T' + t;
    b.onclick = () => { onInput(t); renderProperties(); };
    row.appendChild(b);
  });
  wrap.appendChild(row);
  return wrap;
}

// I/O list editor — renders a small label, then a list of {name, type, required?} rows,
// then an "add" button. Mutates `items` in place and re-renders.
function ioListField(kind /* 'inputs' | 'outputs' */, items, isInput) {
  const wrap = document.createElement('div');
  wrap.className = 'field io-block';
  const lbl = document.createElement('div');
  lbl.className = 'field-label';
  lbl.textContent = kind;
  const hint = document.createElement('span');
  hint.className = 'field-hint';
  hint.textContent = isInput ? '· name · type · required' : '· name · type';
  lbl.appendChild(hint);
  wrap.appendChild(lbl);

  const list = document.createElement('div');
  list.className = 'io-list';
  if (items.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'io-empty';
    empty.textContent = isInput ? '(no inputs)' : '(no outputs)';
    list.appendChild(empty);
  }
  items.forEach((item, idx) => list.appendChild(ioRow(item, idx, items, isInput)));
  wrap.appendChild(list);

  const addBtn = document.createElement('div');
  addBtn.className = 'io-add';
  addBtn.textContent = '+ add ' + (isInput ? 'input' : 'output');
  addBtn.onclick = () => {
    items.push(isInput ? { name: '', type: 'string', required: false } : { name: '', type: 'string' });
    renderProperties();
  };
  wrap.appendChild(addBtn);
  return wrap;
}

function ioRow(item, idx, items, isInput) {
  const row = document.createElement('div');
  row.className = 'io-row';

  const nameIn = document.createElement('input');
  nameIn.className = 'io-name';
  nameIn.value = item.name;
  nameIn.placeholder = 'name';
  nameIn.spellcheck = false;
  nameIn.addEventListener('input', e => { item.name = e.target.value; });
  row.appendChild(nameIn);

  const typeSel = document.createElement('select');
  typeSel.className = 'io-type';
  for (const t of IO_TYPES) {
    const o = document.createElement('option');
    o.value = t; o.textContent = t;
    if (t === item.type) o.selected = true;
    typeSel.appendChild(o);
  }
  typeSel.addEventListener('change', e => { item.type = e.target.value; });
  row.appendChild(typeSel);

  if (isInput) {
    const reqWrap = document.createElement('label');
    reqWrap.className = 'io-req';
    const reqIn = document.createElement('input');
    reqIn.type = 'checkbox';
    reqIn.checked = !!item.required;
    reqIn.addEventListener('change', e => { item.required = e.target.checked; });
    reqWrap.appendChild(reqIn);
    const reqLbl = document.createElement('span');
    reqLbl.textContent = 'req';
    reqWrap.appendChild(reqLbl);
    row.appendChild(reqWrap);
  }

  const del = document.createElement('div');
  del.className = 'io-del';
  del.textContent = '×';
  del.title = 'remove';
  del.onclick = () => { items.splice(idx, 1); renderProperties(); };
  row.appendChild(del);

  return row;
}

// ============================================================================
//  Interactions
// ============================================================================
function setMode(m) {
  mode = m;
  $('status-mode').textContent = m.startsWith('create:') ? 'create ' + m.split(':')[1] : m;
  document.querySelectorAll('.palette-tool').forEach(el => el.classList.toggle('active', el.dataset.mode === m));
  document.querySelectorAll('.palette-item').forEach(el => el.classList.toggle('active', 'create:' + el.dataset.create === m));
  svg.classList.toggle('mode-create', m.startsWith('create:'));
  svg.classList.toggle('mode-connect', m === 'connect');
  connectFrom = null;
  gPreview.innerHTML = '';
}

// Keyboard: Delete/Backspace removes the selected node or edge; Esc clears selection / cancels connect.
document.addEventListener('keydown', e => {
  // ignore when typing into a form input
  const t = e.target;
  if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT' || t.isContentEditable)) return;
  if (e.key === 'Delete' || e.key === 'Backspace') {
    if (selection?.kind === 'node') {
      // Delete the whole multi-selection if it has more than one node
      if (multiSelect.size > 1) {
        const ids = new Set(multiSelect);
        state.nodes = state.nodes.filter(n => !ids.has(n.id));
        state.edges = state.edges.filter(ed => !ids.has(ed.source) && !ids.has(ed.target));
        selection = null;
        multiSelect = new Set();
        renderAll();
      } else {
        deleteNode(selection.id);
      }
      e.preventDefault();
    }
    else if (selection?.kind === 'edge') { deleteEdge(selection.id); e.preventDefault(); }
    else if (selection?.kind === 'lane') {
      const lane = findLane(selection.id);
      if (!lane) return;
      if (getLanes().length <= 1) { return; }
      const nodeCount = state.nodes.filter(n => n.lane === lane.id).length;
      if (nodeCount > 0 && !confirm(`This lane has ${nodeCount} node${nodeCount === 1 ? '' : 's'}. They will be reassigned. Continue?`)) return;
      deleteLane(lane.id);
      e.preventDefault();
    }
  } else if (e.key === 'Escape') {
    selection = null;
    multiSelect = new Set();
    connectFrom = null;
    gPreview.innerHTML = '';
    setMode('select');
    renderAll();
  }
});

document.querySelectorAll('.palette-tool').forEach(el => {
  el.addEventListener('click', () => setMode(el.dataset.mode));
});
document.querySelectorAll('.palette-item').forEach(el => {
  el.addEventListener('click', () => setMode('create:' + el.dataset.create));
});

svg.addEventListener('mousedown', e => {
  // Only start a rubber-band when the user mousedowns on actual background.
  // Skip if a node, edge, edge handle, port indicator, lane header, lane resize handle,
  // or add-lane affordance is the actual target.
  if (mode !== 'select') return;
  const isBg = e.target === svg || (e.target.tagName === 'rect' && e.target.classList.contains('lane-bg'));
  if (!isBg) return;
  const pt = clientToSvg(e.clientX, e.clientY);
  rubberBand = { startX: pt.x, startY: pt.y, x: pt.x, y: pt.y, additive: e.shiftKey };
});

svg.addEventListener('click', e => {
  if (drag || groupDrag || rubberBand) return;
  // canvas click
  const pt = clientToSvg(e.clientX, e.clientY);
  if (mode.startsWith('create:')) {
    const type = mode.split(':')[1];
    createNodeAt(type, pt.x, pt.y);
    setMode('select');
    return;
  }
  // background click clears selection (clicking lane body, not lane header, also clears)
  if (e.target === svg || (e.target.tagName === 'rect' && e.target.classList.contains('lane-bg'))) {
    selection = null;
    multiSelect = new Set();
    renderAll();
  }
});
svg.addEventListener('mousemove', e => {
  if (mode === 'connect' && connectFrom) {
    const pt = clientToSvg(e.clientX, e.clientY);
    const from = findNode(connectFrom);
    if (!from) return;
    const fc = { x: from.x + NODE_DEFAULTS[from.type].w / 2, y: from.y + NODE_DEFAULTS[from.type].h / 2 };
    gPreview.innerHTML = '';
    gPreview.appendChild(el('path', { d: `M${fc.x} ${fc.y} L${pt.x} ${pt.y}`, class: 'connect-preview' }));
  }
  if (drag) {
    const pt = clientToSvg(e.clientX, e.clientY);
    const n = findNode(drag.id);
    n.x = pt.x - drag.offX;
    n.y = pt.y - drag.offY;
    // lane reassignment based on y (centre of node)
    const centerY = n.y + NODE_DEFAULTS[n.type].h / 2;
    const newLane = laneAtY(centerY);
    if (newLane) n.lane = newLane;
    renderNodes(); renderEdges();
  }
  if (groupDrag) {
    const pt = clientToSvg(e.clientX, e.clientY);
    const dx = pt.x - groupDrag.startX;
    const dy = pt.y - groupDrag.startY;
    for (const [id, orig] of groupDrag.originalPositions) {
      const node = findNode(id);
      if (node) {
        node.x = orig.x + dx;
        node.y = orig.y + dy;
        // lane reassign per node
        const centerY = node.y + NODE_DEFAULTS[node.type].h / 2;
        const newLane = laneAtY(centerY);
        if (newLane) node.lane = newLane;
      }
    }
    renderNodes(); renderEdges();
  }
  if (rubberBand) {
    const pt = clientToSvg(e.clientX, e.clientY);
    rubberBand.x = pt.x;
    rubberBand.y = pt.y;
    renderRubberBand();
  }
  if (edgeDrag) {
    const rawPt = clientToSvg(e.clientX, e.clientY);
    // For endpoint drags, the cursor was offset from the handle center on mousedown.
    // Subtract that offset so the handle stays glued to the cursor at the same
    // pixel position throughout the drag (rather than drifting based on where the
    // initial click landed on the 6-px dot).
    const pt = (typeof edgeDrag.offX === 'number' && typeof edgeDrag.offY === 'number')
      ? { x: rawPt.x - edgeDrag.offX, y: rawPt.y - edgeDrag.offY }
      : rawPt;
    const edge = findEdge(edgeDrag.edgeId);
    if (!edge) return;
    if (edgeDrag.kind === 'endpoint') {
      // Three cases while dragging an endpoint:
      //   (a) cursor over a node other than the current anchor → re-anchor candidate
      //   (b) cursor near a port of the current node (within snap radius) → port re-pin
      //   (c) cursor in open space → endpoint follows the cursor (preview drag)
      //
      // The actual edge re-renders each frame using `edgeDrag.previewPt` as the
      // effective endpoint, so the line, the handle, and the arrowhead all
      // visually track the finger together — no ghost trail.
      const ownEndId = edgeDrag.role === 'source' ? edge.source : edge.target;
      const SNAP_RADIUS = 22;

      // Step 1: figure out the snap target.
      //   First check if cursor is *inside* a node (clear intent → snap to that node's nearest port).
      //   Otherwise scan all ports across all nodes within aim range and pick the closest port within SNAP_RADIUS.
      const hoverId = nodeAt(pt.x, pt.y);
      let snapNode = null;
      let snapPortName = null;
      let snapDistance = Infinity;

      if (hoverId) {
        // direct hit — snap to this node's nearest port regardless of distance
        snapNode = findNode(hoverId);
        snapPortName = nearestPortName(snapNode, pt);
      } else {
        // scan ports of nearby nodes — pick the globally closest port within SNAP_RADIUS
        const NEARBY_RADIUS = 160; // only consider nodes whose center is within this range
        for (const n of state.nodes) {
          const nc = centerOf(n);
          if (Math.hypot(pt.x - nc.x, pt.y - nc.y) > NEARBY_RADIUS) continue;
          for (const p of PORT_NAMES) {
            const portPt = portPointAt(n, p);
            const d = Math.hypot(portPt.x - pt.x, portPt.y - pt.y);
            if (d < snapDistance && d <= SNAP_RADIUS) {
              snapDistance = d;
              snapNode = n;
              snapPortName = p;
            }
          }
        }
      }

      // Step 2: commit the snap state
      edgeDrag.cursorPt = pt;
      edgeDrag.hoverNodeId = hoverId;
      if (snapNode && snapPortName) {
        const portPt = portPointAt(snapNode, snapPortName);
        edgeDrag.previewPt = portPt;
        edgeDrag.snapNodeId = snapNode.id;
        edgeDrag.snapPort = snapPortName;
      } else {
        edgeDrag.previewPt = pt;
        edgeDrag.snapNodeId = null;
        edgeDrag.snapPort = null;
      }

      // Step 3: visual feedback
      gPreview.innerHTML = '';

      // Aim-assist: render ghost port dots on every node within AIM_RADIUS of the cursor,
      // so the user can see snap options before committing. The dots are subtler than the
      // selected-edge's port indicators (no pinning click; just visibility).
      const AIM_RADIUS = 140; // how far from cursor a node has to be to show its ports
      const otherId = edgeDrag.role === 'source' ? edge.target : edge.source;
      for (const n of state.nodes) {
        const nc = centerOf(n);
        const distToNode = Math.hypot(pt.x - nc.x, pt.y - nc.y);
        if (distToNode > AIM_RADIUS) continue;
        // intensity falls off with distance — fully visible at distToNode <= 60, fades to 30% at AIM_RADIUS
        const t = Math.max(0, Math.min(1, (AIM_RADIUS - distToNode) / (AIM_RADIUS - 60)));
        const opacity = 0.25 + 0.6 * t;
        for (const p of PORT_NAMES) {
          const portPt = portPointAt(n, p);
          // skip drawing aim-assist on the currently-snapped port — the strong snap indicator handles that
          if (edgeDrag.snapNodeId === n.id && edgeDrag.snapPort === p) continue;
          gPreview.appendChild(el('circle', {
            cx: portPt.x, cy: portPt.y, r: 3.5,
            class: 'port-aim-assist',
            style: `opacity: ${opacity.toFixed(2)}`,
          }));
        }
      }

      // Strong snap indicator on the chosen port
      if (edgeDrag.snapPort && edgeDrag.snapNodeId) {
        gPreview.appendChild(el('circle', { cx: edgeDrag.previewPt.x, cy: edgeDrag.previewPt.y, r: 7, class: 'port-indicator-snap' }));
      }
      gNodes.querySelectorAll('.node').forEach(g => {
        const isSnap = edgeDrag.snapNodeId === g.dataset.id;
        g.classList.toggle('hover-target', isSnap && g.dataset.id !== otherId);
      });

      // Step 4: re-render edges so the dragged edge follows the cursor live.
      renderEdges();
      updateStatus();
      // Update canvas cursor to signal commit vs cancel
      svg.classList.toggle('drag-endpoint-snap', !!edgeDrag.snapNodeId);
      svg.classList.toggle('drag-endpoint-float', !edgeDrag.snapNodeId);
    } else if (edgeDrag.kind === 'waypoint') {
      edge.waypoints[edgeDrag.idx] = { x: pt.x, y: pt.y };
      renderEdges();
    } else if (edgeDrag.kind === 'add-waypoint') {
      // Pending insert — only commits on first real move; turns into a waypoint drag.
      const dist = Math.hypot(pt.x - edgeDrag.startX, pt.y - edgeDrag.startY);
      if (dist > 3) {
        edge.waypoints = edge.waypoints || [];
        edge.waypoints.splice(edgeDrag.segmentIdx, 0, { x: pt.x, y: pt.y });
        // Transition to waypoint drag, preserving the click offset so the cursor
        // doesn't jump when the kind switches.
        edgeDrag = {
          kind: 'waypoint',
          edgeId: edge.id,
          idx: edgeDrag.segmentIdx,
          offX: edgeDrag.offX,
          offY: edgeDrag.offY,
        };
        renderEdges();
      }
    } else if (edgeDrag.kind === 'loop-detour') {
      // Move the cross-bar of a loop-back edge up or down. The clamp to lane
      // bounds is enforced inside orthoLoopBack() via edge.detourY.
      edge.detourY = pt.y - edgeDrag.offY;
      renderEdges();
    } else if (edgeDrag.kind === 'segment') {
      // Segment drag — perpendicular nudge updates edge.routingHints[role].
      // Edge stays auto-routed: the router applies hints on each render. No
      // waypoint conversion; the relationship between segments and roles is
      // stable across renders unless the topology itself changes.
      const dx = pt.x - edgeDrag.startX;
      const dy = pt.y - edgeDrag.startY;
      const perpDelta = edgeDrag.perpAxis === 'y' ? dy : dx;
      edge.routingHints = edge.routingHints || {};
      edge.routingHints[edgeDrag.role] = edgeDrag.baselineHint + perpDelta;
      renderEdges();
    }
  }
  if (laneResizeDrag) {
    const pt = clientToSvg(e.clientX, e.clientY);
    const lane = findLane(laneResizeDrag.laneId);
    if (!lane) return;
    const delta = pt.y - laneResizeDrag.startY;
    const newH = Math.max(60, Math.min(800, laneResizeDrag.startHeight + delta));
    if (newH !== lane.height) {
      // Resize affects the position of all lanes *below* this one. Nodes in below-lanes
      // would visually shift; re-snap them to their lane centers afterwards.
      lane.height = newH;
      // Re-snap nodes in lanes below the one being resized so they stay in their lane
      const lanesArr = getLanes();
      const idx = lanesArr.findIndex(l => l.id === lane.id);
      for (let i = idx + 1; i < lanesArr.length; i++) {
        const belowLane = lanesArr[i];
        for (const n of state.nodes) {
          if (n.lane === belowLane.id) {
            n.y = laneCenterY(belowLane.id) - NODE_DEFAULTS[n.type].h / 2;
          }
        }
      }
      // The lane being resized: its nodes should stay where they are *relative to the lane top*,
      // but since we only changed height, anything above the new bottom is fine; anything that
      // now falls outside the new bounds we clamp toward the center.
      const top = laneTop(lane.id);
      for (const n of state.nodes) {
        if (n.lane === lane.id) {
          const def = NODE_DEFAULTS[n.type];
          const cy = n.y + def.h / 2;
          if (cy < top || cy > top + newH) {
            n.y = top + newH / 2 - def.h / 2;
          }
        }
      }
      renderAll();
    }
  }
});
window.addEventListener('mouseup', e => {
  if (edgeDrag && edgeDrag.kind === 'endpoint') {
    const edge = findEdge(edgeDrag.edgeId);
    if (edge && edgeDrag.snapNodeId) {
      const ownEndId = edgeDrag.role === 'source' ? edge.source : edge.target;
      const snapId = edgeDrag.snapNodeId;
      const snapPort = edgeDrag.snapPort;
      if (snapId === ownEndId) {
        // re-pinning the same node to a (possibly different) port
        if (snapPort) {
          if (edgeDrag.role === 'source') edge.sourcePort = snapPort;
          else edge.targetPort = snapPort;
          edge.waypoints = [];
        }
      } else {
        // re-anchor to a different node, with the snapped port
        if (edgeDrag.role === 'source') {
          edge.source = snapId;
          edge.sourcePort = snapPort;
        } else {
          edge.target = snapId;
          edge.targetPort = snapPort;
        }
        edge.waypoints = [];
      }
    }
    // If no snap target — drop in open space — the edge stays as it was; no commit.
    gPreview.innerHTML = '';
    gNodes.querySelectorAll('.node.hover-target').forEach(g => g.classList.remove('hover-target'));
    svg.classList.remove('drag-endpoint-snap', 'drag-endpoint-float');
    edgeDrag = null; // clear before renderAll so updateStatus sees no drag in flight
    renderAll();
  }
  if (laneResizeDrag) {
    document.querySelectorAll('.lane-resize-handle.dragging').forEach(el => el.classList.remove('dragging'));
  }
  if (rubberBand) {
    // Finalize selection from rubber-band bounds
    finalizeRubberBandSelection();
    rubberBand = null;
    gPreview.innerHTML = '';
  }
  // On drop after a single-node drag or group drag, the spatial ordering may
  // have changed — recompute displayIds. (We deliberately don't do this during
  // the drag itself to avoid live-renumber visual noise.)
  if (drag || groupDrag) {
    refreshDisplayIds();
    renderNodes();
  }
  drag = null;
  edgeDrag = null;
  laneResizeDrag = null;
  groupDrag = null;
});

function onLaneResizeMouseDown(ev, laneId) {
  ev.stopPropagation();
  ev.preventDefault();
  const lane = findLane(laneId);
  if (!lane) return;
  const pt = clientToSvg(ev.clientX, ev.clientY);
  laneResizeDrag = { laneId, startY: pt.y, startHeight: lane.height };
  // visual feedback while dragging
  ev.currentTarget.classList.add('dragging');
}

function onNodeMouseDown(e, n) {
  if (mode === 'connect') return;
  // If an edge endpoint handle was clicked, the node mousedown shouldn't also fire-drag the node
  if (edgeDrag) return;
  const pt = clientToSvg(e.clientX, e.clientY);
  // If this node is in the multi-selection, treat the drag as a *group* move.
  if (multiSelect.has(n.id) && multiSelect.size > 1) {
    const originalPositions = new Map();
    for (const id of multiSelect) {
      const node = findNode(id);
      if (node) originalPositions.set(id, { x: node.x, y: node.y });
    }
    groupDrag = { startX: pt.x, startY: pt.y, originalPositions };
  } else {
    drag = { id: n.id, offX: pt.x - n.x, offY: pt.y - n.y };
  }
}
function onNodeClick(n, e) {
  if (mode === 'connect') {
    if (!connectFrom) {
      connectFrom = n.id;
    } else if (connectFrom !== n.id) {
      addEdge(connectFrom, n.id);
      connectFrom = null;
      gPreview.innerHTML = '';
    }
    return;
  }
  // Shift-click — toggle membership in the multi-selection without changing primary
  if (e && e.shiftKey) {
    if (multiSelect.has(n.id)) {
      multiSelect.delete(n.id);
      // if we just deselected the primary, promote any other multi-member to primary
      if (selection?.kind === 'node' && selection.id === n.id) {
        const first = [...multiSelect][0];
        selection = first ? { kind: 'node', id: first } : null;
      }
    } else {
      multiSelect.add(n.id);
      // if there was no primary yet, this node becomes it
      if (!selection || selection.kind !== 'node') selection = { kind: 'node', id: n.id };
    }
    renderNodes(); renderEdges(); renderProperties();
    return;
  }
  // Plain click — primary selection, single-node selection set
  selection = { kind: 'node', id: n.id };
  multiSelect = new Set([n.id]);
  renderNodes(); renderEdges(); renderProperties();
}
function onEdgeClick(e) {
  if (mode === 'connect') return;
  selection = { kind: 'edge', id: e.id };
  multiSelect = new Set();
  renderEdges(); renderProperties();
}

// ----- Edge editing handlers -----
function onEndpointMouseDown(ev, edge, role) {
  ev.stopPropagation();
  ev.preventDefault();
  // Capture the click offset from the handle's center so the cursor stays glued
  // to the dot for the whole drag (instead of slowly drifting away if you clicked
  // a few px off-center).
  const clickPt = clientToSvg(ev.clientX, ev.clientY);
  const src = findNode(edge.source);
  const tgt = findNode(edge.target);
  // Recompute the current handle position the same way renderEdges does.
  const wps = edge.waypoints || [];
  const firstWp = wps[0];
  const lastWp = wps[wps.length - 1];
  let handlePt;
  if (role === 'source') {
    handlePt = anchorPoint(src, edge.sourcePort, firstWp ? firstWp : centerOf(tgt));
  } else {
    handlePt = anchorPoint(tgt, edge.targetPort, lastWp ? lastWp : centerOf(src));
  }
  const offX = clickPt.x - handlePt.x;
  const offY = clickPt.y - handlePt.y;
  edgeDrag = { kind: 'endpoint', edgeId: edge.id, role, offX, offY };
}
function onWaypointMouseDown(ev, edge, idx) {
  ev.stopPropagation();
  ev.preventDefault();
  // Capture offset between click and waypoint center so the square stays glued
  // to the cursor at the same relative spot for the whole drag.
  const clickPt = clientToSvg(ev.clientX, ev.clientY);
  const wp = edge.waypoints[idx];
  const offX = wp ? clickPt.x - wp.x : 0;
  const offY = wp ? clickPt.y - wp.y : 0;
  edgeDrag = { kind: 'waypoint', edgeId: edge.id, idx, offX, offY };
}
function onAddWaypointMouseDown(ev, edge, segmentIdx, mx, my) {
  ev.stopPropagation();
  ev.preventDefault();
  // Don't insert immediately — only on movement (>3px). A pure click on the adder
  // is treated as a no-op so users can click around freely without polluting waypoints.
  // Capture click offset from the adder dot center so the inserted waypoint stays
  // glued to the cursor at the same relative spot.
  const clickPt = clientToSvg(ev.clientX, ev.clientY);
  const offX = clickPt.x - mx;
  const offY = clickPt.y - my;
  edgeDrag = { kind: 'add-waypoint', edgeId: edge.id, segmentIdx, startX: mx, startY: my, offX, offY };
}

function onLoopDetourMouseDown(ev, edge, currentY) {
  ev.stopPropagation();
  ev.preventDefault();
  // Capture offset between click point and the cross-bar's current Y so the bar
  // stays glued to the cursor at the same relative position throughout the drag.
  const clickPt = clientToSvg(ev.clientX, ev.clientY);
  const offY = clickPt.y - currentY;
  edgeDrag = { kind: 'loop-detour', edgeId: edge.id, offY };
}

// Drag a generic orthogonal segment perpendicular to its direction.
// On commit (mousemove > 3px threshold), the edge converts to manually-routed:
// two waypoints are inserted at the segment's endpoints, both shifted by the
// drag delta in the perpendicular axis. Subsequent drags update the existing
// waypoints rather than creating new ones.
function onSegmentMouseDown(ev, edge, role, perpAxis, mx, my) {
  ev.stopPropagation();
  ev.preventDefault();
  const clickPt = clientToSvg(ev.clientX, ev.clientY);
  const offX = clickPt.x - mx;
  const offY = clickPt.y - my;
  // Read current hint value for this role (default 0) — drag deltas accumulate from here.
  edge.routingHints = edge.routingHints || {};
  const baselineHint = edge.routingHints[role] || 0;
  edgeDrag = {
    kind: 'segment',
    edgeId: edge.id,
    role,
    perpAxis,
    startX: mx,
    startY: my,
    offX,
    offY,
    baselineHint,
  };
}

function removeWaypoint(edge, idx) {
  if (!edge.waypoints) return;
  edge.waypoints.splice(idx, 1);
  renderEdges();
}

function clearWaypoints(edge) {
  edge.waypoints = [];
  renderEdges();
}

// Re-run the orthogonal router for `edge` and extract the middle corner points
// (everything between the two stub-points). Returns an object with:
//   points: the corners, to be assigned to edge.waypoints
//   segmentToFlanksMap: { [renderedSegmentIdx]: { a: waypointIdx, b: waypointIdx } }
// where rendered segment index refers to a segment in the polyline returned by the router
// (polyline = [anchor, spA, ...middle, spB, anchor]) and waypoint indices refer to entries
// in the resulting edge.waypoints array (which is the middle list).
function currentRenderedMiddleCorners(edge) {
  const src = findNode(edge.source);
  const tgt = findNode(edge.target);
  if (!src || !tgt) return { points: [], segmentToFlanksMap: {} };
  const sp = anchorPoint(src, edge.sourcePort, centerOf(tgt));
  const tp = anchorPoint(tgt, edge.targetPort, centerOf(src));
  const dirA = exitDirection(src, sp, edge.sourcePort || 'auto');
  const dirB = exitDirection(tgt, tp, edge.targetPort || 'auto');
  // Temporarily clear edge.detourY/waypoints so the router computes the natural polyline
  // rather than honoring stale overrides.
  const savedDetour = edge.detourY;
  const savedWps = edge.waypoints;
  delete edge.detourY;
  edge.waypoints = [];
  const result = routeOrthogonalSegment(sp, tp, dirA, dirB, src, tgt, edge);
  edge.detourY = savedDetour;
  edge.waypoints = savedWps;
  // polyline = [anchor=sp, spA, ...middle, spB, anchor=tp]; we want middle.
  const polyline = result.polyline;
  const middle = polyline.slice(2, -2);
  // Build segment→flank map. Segment i (between polyline[i] and polyline[i+1]) flanks:
  //   - waypoints[i-2] on its left (if i >= 2)
  //   - waypoints[i-1] on its right (if i-1 < middle.length)
  // Because middle = polyline[2..len-3], waypoint index j corresponds to polyline index j+2.
  const segmentToFlanksMap = {};
  for (let i = 1; i < polyline.length - 2; i++) {
    const aIdx = i - 2; // index into middle/waypoints; -1 means "this side is spA"
    const bIdx = i - 1;
    segmentToFlanksMap[i] = {
      a: aIdx >= 0 && aIdx < middle.length ? aIdx : null,
      b: bIdx >= 0 && bIdx < middle.length ? bIdx : null,
    };
  }
  return { points: middle, segmentToFlanksMap };
}

// Hit-test: return the topmost node id at world coordinates (x, y), else null.
function nodeAt(x, y) {
  // iterate in reverse render order so later (visually-on-top) nodes win
  for (let i = state.nodes.length - 1; i >= 0; i--) {
    const n = state.nodes[i];
    const d = NODE_DEFAULTS[n.type];
    if (n.type === 'startEvent' || n.type === 'endEvent') {
      const cx = n.x + d.w / 2, cy = n.y + d.h / 2;
      if (Math.hypot(x - cx, y - cy) <= d.w / 2) return n.id;
    } else if (n.type === 'exclusiveGateway' || n.type === 'parallelGateway') {
      // diamond: |dx|/r + |dy|/r <= 1
      const cx = n.x + d.w / 2, cy = n.y + d.h / 2, r = d.w / 2;
      if ((Math.abs(x - cx) + Math.abs(y - cy)) <= r) return n.id;
    } else {
      // rect
      if (x >= n.x && x <= n.x + d.w && y >= n.y && y <= n.y + d.h) return n.id;
    }
  }
  return null;
}

// Render the rubber-band rectangle in the preview layer.
function renderRubberBand() {
  if (!rubberBand) { gPreview.innerHTML = ''; return; }
  const x = Math.min(rubberBand.startX, rubberBand.x);
  const y = Math.min(rubberBand.startY, rubberBand.y);
  const w = Math.abs(rubberBand.x - rubberBand.startX);
  const h = Math.abs(rubberBand.y - rubberBand.startY);
  gPreview.innerHTML = '';
  gPreview.appendChild(el('rect', { x, y, width: w, height: h, class: 'rubber-band' }));
}

// Translate the rubber-band rectangle into a multi-selection of every node
// whose center falls inside the rectangle. Additive (shift held) preserves
// the previous multi; non-additive replaces it.
function finalizeRubberBandSelection() {
  if (!rubberBand) return;
  const x1 = Math.min(rubberBand.startX, rubberBand.x);
  const y1 = Math.min(rubberBand.startY, rubberBand.y);
  const x2 = Math.max(rubberBand.startX, rubberBand.x);
  const y2 = Math.max(rubberBand.startY, rubberBand.y);
  // tiny boxes (= a click that registered as drag-of-1px) clear selection rather than select nothing
  if ((x2 - x1) < 4 && (y2 - y1) < 4) {
    if (!rubberBand.additive) { selection = null; multiSelect = new Set(); renderAll(); }
    return;
  }
  const hits = [];
  for (const n of state.nodes) {
    const d = NODE_DEFAULTS[n.type];
    const cx = n.x + d.w / 2, cy = n.y + d.h / 2;
    if (cx >= x1 && cx <= x2 && cy >= y1 && cy <= y2) hits.push(n.id);
  }
  if (!rubberBand.additive) multiSelect = new Set();
  for (const id of hits) multiSelect.add(id);
  // pick a primary — keep current if still in set, otherwise the first hit
  if (!selection || selection.kind !== 'node' || !multiSelect.has(selection.id)) {
    const first = [...multiSelect][0];
    selection = first ? { kind: 'node', id: first } : null;
  }
  renderAll();
}

function clientToSvg(cx, cy) {
  const rect = svg.getBoundingClientRect();
  const vb = svg.viewBox.baseVal;
  return {
    x: ((cx - rect.left) / rect.width) * vb.width,
    y: ((cy - rect.top) / rect.height) * vb.height,
  };
}

// BPMN-style ID prefixes by node type. Gateways collapse to GW_ regardless of kind.
const ID_PREFIX = {
  startEvent:        'Start',
  endEvent:          'End',
  serviceTask:       'Service',
  userTask:          'User',
  scriptTask:        'Script',
  exclusiveGateway:  'GW',
  parallelGateway:   'GW',
};

// Default descriptors that fill the second half of the ID — kept lower-case and
// short. These match what the user sees as the default name on a freshly created node.
const ID_DESCRIPTOR = {
  startEvent:        'start',
  endEvent:          'end',
  serviceTask:       'task',
  userTask:          'review',
  scriptTask:        'script',
  exclusiveGateway:  'decision',
  parallelGateway:   'parallel',
};

// Returns a unique id of shape `<Prefix>_<descriptor>` (or with `_N` suffix on clash).
// Scans the current workflow to ensure uniqueness across ALL nodes — not just same-type.
function generateNodeId(type) {
  const prefix = ID_PREFIX[type] || type;
  const descriptor = ID_DESCRIPTOR[type] || 'node';
  const base = `${prefix}_${descriptor}`;
  const taken = new Set(state.nodes.map(n => n.id));
  if (!taken.has(base)) return base;
  let n = 2;
  while (taken.has(`${base}_${n}`)) n++;
  return `${base}_${n}`;
}

function createNodeAt(type, x, y) {
  const def = NODE_DEFAULTS[type];
  // figure out lane based on y; fall back to default lane for the type if it exists,
  // else to the first lane in the workflow (handles workflows with non-standard lane sets)
  let lane = laneAtY(y);
  if (!lane) {
    lane = findLane(def.lane) ? def.lane : getLanes()[0]?.id;
  }
  const uid = generateUid('n');
  const name = defaultName(type);
  const node = {
    uid,
    id: uid,             // alias for compat — same as uid
    slug: 'tmp',         // overwritten below after pushing into state.nodes
    type,
    name,
    lane,
    x: x - def.w / 2,
    y: y - def.h / 2,
    aef: {},
  };
  state.nodes.push(node);
  // Now that the node is in state, derive a unique-within-lane slug.
  node.slug = deriveUniqueSlug(node, name);
  selection = { kind: 'node', id: uid };
  refreshDisplayIds();
  renderAll();
}
function defaultName(type) {
  return ({
    startEvent: 'Start',
    endEvent: 'End',
    serviceTask: 'Task',
    userTask: 'User task',
    scriptTask: 'Script',
    exclusiveGateway: 'Decision',
    parallelGateway: 'Parallel',
    linkEventThrow: 'Handoff →',
    linkEventCatch: '← Handoff',
  })[type] || type;
}
function addEdge(source, target) {
  const uid = generateUid('e');
  state.edges.push({ uid, id: uid, source, target });
  refreshDisplayIds();
  renderEdges();
}
function deleteNode(id) {
  state.nodes = state.nodes.filter(n => n.id !== id);
  state.edges = state.edges.filter(e => e.source !== id && e.target !== id);
  selection = null;
  multiSelect = new Set();
  refreshDisplayIds();
  renderAll();
}
function deleteEdge(id) {
  state.edges = state.edges.filter(e => e.id !== id);
  selection = null;
  refreshDisplayIds();
  renderAll();
}

// ----- Lane CRUD -----
function addLane() {
  if (!state.lanes) state.lanes = defaultLanes();
  // generate a fresh id that doesn't collide with existing ones
  let suffix = state.lanes.length + 1;
  let id;
  do { id = 'lane_' + suffix++; } while (findLane(id));
  // Auto-derive a 3-char abbreviation, ensuring uniqueness across lanes.
  let abbr = deriveLaneAbbr('New lane');
  let abbrSuffix = 2;
  while (state.lanes.some(l => l.abbr === abbr)) {
    abbr = deriveLaneAbbr('New lane').slice(0, 2) + abbrSuffix++;
  }
  const newLane = {
    id,
    name: 'New lane',
    abbr,
    authority: 'none',
    height: 130,
  };
  state.lanes.push(newLane);
  selection = { kind: 'lane', id };
  refreshDisplayIds();
  renderAll();
}

function deleteLane(id) {
  if (!state.lanes || state.lanes.length <= 1) return;
  const remaining = state.lanes.filter(l => l.id !== id);
  // reassign nodes from deleted lane to the first remaining lane
  const fallbackId = remaining[0].id;
  state.nodes.forEach(n => { if (n.lane === id) n.lane = fallbackId; });
  state.lanes = remaining;
  // re-snap every node's y to its lane's centre — the lane layout has shifted
  state.nodes.forEach(n => {
    n.y = laneCenterY(n.lane) - NODE_DEFAULTS[n.type].h / 2;
  });
  // strip waypoints on any edge — old waypoints made sense for the old geometry
  state.edges.forEach(e => { if (e.waypoints) e.waypoints = []; });
  selection = null;
  refreshDisplayIds();
  renderAll();
}

function moveLane(id, newIdx) {
  if (!state.lanes) return;
  const oldIdx = state.lanes.findIndex(l => l.id === id);
  if (oldIdx === -1) return;
  const [lane] = state.lanes.splice(oldIdx, 1);
  state.lanes.splice(newIdx, 0, lane);
  // re-snap every node to its lane's vertical centre — the absolute y values
  // for every node have shifted relative to lane positions.
  state.nodes.forEach(n => {
    n.y = laneCenterY(n.lane) - NODE_DEFAULTS[n.type].h / 2;
  });
  // strip waypoints — old routings made sense for the old geometry
  state.edges.forEach(e => { if (e.waypoints) e.waypoints = []; });
  refreshDisplayIds();
  renderAll();
}

// ============================================================================
//  Buttons
// ============================================================================
$('btn-add-lane').onclick = () => { addLane(); };
$('palette-add-lane').onclick = () => { addLane(); };
$('btn-reset').onclick = () => {
  // Reset: blow away library and start over with seed
  library.clear();
  const fresh = getInvestigateWorkflow();
  library.set(fresh.workflowMeta.id, fresh);
  state = fresh;
  activeKey = fresh.workflowMeta.id;
  selection = null;
  nextId = 100;
  refreshDisplayIds();
  setMode('select');
  renderAll();
  refreshLibraryUI();
};
$('btn-xml').onclick = () => {
  $('xml-output').innerHTML = colorizeXml(buildBpmnXml(state));
  $('xml-panel').classList.add('visible');
};
$('btn-close-xml').onclick = () => { $('xml-panel').classList.remove('visible'); };
$('btn-copy-xml').onclick = async () => {
  const raw = buildBpmnXml(state);
  try { await navigator.clipboard.writeText(raw); } catch (_) {}
};
$('btn-save').onclick = () => {
  saveActiveToLibrary();
  const raw = buildBpmnXml(state);
  const blob = new Blob([raw], { type: 'application/xml' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  // Filename: <workflow-id>.v<version>.bpmn
  const id = state.workflowMeta.id;
  const v = state.workflowMeta.version || '1';
  a.href = url;
  a.download = `${id}.v${v}.bpmn`;
  a.click();
  URL.revokeObjectURL(url);
};
$('btn-load').onclick = () => {
  // File picker — accepts .bpmn / .xml
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.bpmn,.xml,application/xml,text/xml';
  input.onchange = async ev => {
    const file = ev.target.files[0];
    if (!file) return;
    const text = await file.text();
    try {
      const loaded = parseBpmnXml(text);
      if (!loaded) {
        alert('Could not parse this file. Expected BPMN XML with AEF extensions.');
        return;
      }
      saveActiveToLibrary();
      // Collision: append _v<n> until unique
      let key = loaded.workflowMeta.id;
      let n = 2;
      while (library.has(key)) { key = `${loaded.workflowMeta.id}_v${n++}`; }
      if (key !== loaded.workflowMeta.id) loaded.workflowMeta.id = key;
      library.set(key, loaded);
      state = loaded;
      activeKey = key;
      selection = null;
      multiSelect.clear();
      refreshDisplayIds();
      renderAll();
      refreshLibraryUI();
    } catch (e) {
      console.error('Load failed:', e);
      alert('Failed to parse workflow file:\n' + e.message);
    }
  };
  input.click();
};
$('btn-new-workflow').onclick = () => { createNewWorkflow(); };
$('workflow-picker').onchange = ev => {
  const key = ev.target.value;
  if (key !== activeKey) loadFromLibrary(key);
};
$('brand-version').onclick = () => {
  const cur = state.workflowMeta.version || '1';
  const next = prompt('Workflow version', cur);
  if (next == null) return;
  const trimmed = String(next).trim();
  if (!trimmed) return;
  state.workflowMeta.version = trimmed;
  refreshLibraryUI();
  renderProperties();
};

// ============================================================================
//  BPMN XML build
// ============================================================================
function escAttr(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
function escText(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

const TYPE_TAG = {
  startEvent: 'startEvent',
  endEvent: 'endEvent',
  serviceTask: 'serviceTask',
  userTask: 'userTask',
  scriptTask: 'scriptTask',
  exclusiveGateway: 'exclusiveGateway',
  parallelGateway: 'parallelGateway',
  // Link events use BPMN's intermediate-throw/catch tags. Inside the element,
  // a <bpmn:linkEventDefinition/> would mark it as a link variant; we instead
  // encode this via aef:link extension since the rest of our XML pipeline
  // already routes through extensionElements.
  linkEventThrow: 'intermediateThrowEvent',
  linkEventCatch: 'intermediateCatchEvent',
};

function aefExtensionXml(node) {
  const aef = node.aef || {};
  const io = node.io || {};
  const aefKeys = Object.keys(aef).filter(k => aef[k] !== '' && aef[k] != null);
  const inputs = (io.inputs  || []).filter(i => i.name);
  const outputs = (io.outputs || []).filter(i => i.name);
  // Always emit the extension block to preserve the uid (so XML re-import keeps identity).

  let out = '      <bpmn:extensionElements>\n';
  // uid first — the immutable internal reference; re-import keys off this.
  if (node.uid) out += `        <aef:uid value="${escAttr(node.uid)}"/>\n`;
  // position — round-trip canvas layout
  if (typeof node.x === 'number' && typeof node.y === 'number') {
    out += `        <aef:position x="${node.x.toFixed(1)}" y="${node.y.toFixed(1)}"/>\n`;
  }
  // meta (tier, agentType, decisionOwner, triggeredBy, emits)
  const metaKeys = ['tier', 'agentType', 'decisionOwner', 'triggeredBy', 'emits'];
  const metaAttrs = metaKeys.filter(k => aefKeys.includes(k)).map(k => `${k}="${escAttr(aef[k])}"`).join(' ');
  if (metaAttrs) out += `        <aef:meta ${metaAttrs}/>\n`;
  if (aef.endpoint) out += `        <aef:endpoint>${escText(aef.endpoint)}</aef:endpoint>\n`;
  if (aef.contextReads) out += `        <aef:contextReads paths="${escAttr(aef.contextReads)}"/>\n`;
  if (aef.artifactsWrites) out += `        <aef:artifactsWrites paths="${escAttr(aef.artifactsWrites)}"/>\n`;
  if (aef.decisionInput) out += `        <aef:decisionInput>${escText(aef.decisionInput)}</aef:decisionInput>\n`;
  if (aef.decisionOutputs) out += `        <aef:decisionOutputs values="${escAttr(aef.decisionOutputs)}"/>\n`;
  // Link event: targetWorkflow + linkId (for linkEventThrow / linkEventCatch)
  if (aef.targetWorkflow || aef.linkId) {
    out += `        <aef:link targetWorkflow="${escAttr(aef.targetWorkflow || '')}" linkId="${escAttr(aef.linkId || '')}"/>\n`;
  }

  // I/O data contract
  if (inputs.length || outputs.length) {
    out += `        <aef:io>\n`;
    for (const i of inputs) {
      const reqAttr = i.required ? ' required="true"' : '';
      out += `          <aef:input name="${escAttr(i.name)}" type="${escAttr(i.type)}"${reqAttr}/>\n`;
    }
    for (const o of outputs) {
      out += `          <aef:output name="${escAttr(o.name)}" type="${escAttr(o.type)}"/>\n`;
    }
    out += `        </aef:io>\n`;
  }

  out += '      </bpmn:extensionElements>\n';
  return out;
}

function buildBpmnXml(s) {
  const lines = [];
  lines.push(`<?xml version="1.0" encoding="UTF-8"?>`);
  lines.push(`<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"`);
  lines.push(`                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"`);
  lines.push(`                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"`);
  lines.push(`                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"`);
  lines.push(`                  xmlns:aef="http://anchorpoint.framework/aef/extensions"`);
  lines.push(`                  id="Definitions_${escAttr(s.workflowMeta.id)}"`);
  lines.push(`                  targetNamespace="https://aef.anchorpoint.dev/workflows">`);
  lines.push(``);
  lines.push(`  <bpmn:collaboration id="Collaboration_${escAttr(s.workflowMeta.id)}">`);
  lines.push(`    <bpmn:participant id="${escAttr(s.pool.id)}" name="${escAttr(s.pool.name)}" processRef="Process_${escAttr(s.workflowMeta.id)}"/>`);
  lines.push(`  </bpmn:collaboration>`);
  lines.push(``);
  lines.push(`  <bpmn:process id="Process_${escAttr(s.workflowMeta.id)}" isExecutable="true">`);
  // workflow-level aef:workflowMeta
  const wm = s.workflowMeta;
  lines.push(`    <bpmn:extensionElements>`);
  const wmAttrs = [
    `id="${escAttr(wm.id)}"`,
    `version="${escAttr(wm.version || '1')}"`,
    `schemaVersion="${escAttr(wm.schemaVersion || 2)}"`,
  ];
  if (wm.title) wmAttrs.push(`title="${escAttr(wm.title)}"`);
  if (wm.description) wmAttrs.push(`description="${escAttr(wm.description)}"`);
  if (wm.source) wmAttrs.push(`source="${escAttr(wm.source)}"`);
  if (wm.tier_default) wmAttrs.push(`tier_default="${escAttr(wm.tier_default)}"`);
  lines.push(`      <aef:workflowMeta ${wmAttrs.join(' ')}/>`);
  lines.push(`    </bpmn:extensionElements>`);

  // lane set
  lines.push(`    <bpmn:laneSet id="LaneSet_1">`);
  const lanesToEmit = s.lanes || defaultLanes();
  for (const lane of lanesToEmit) {
    lines.push(`      <bpmn:lane id="${escAttr(lane.id)}" name="${escAttr(lane.name)}">`);
    lines.push(`        <bpmn:extensionElements>`);
    lines.push(`          <aef:laneMeta abbr="${escAttr(lane.abbr || '')}" authority="${escAttr(lane.authority)}" height="${lane.height || 130}"/>`);
    lines.push(`        </bpmn:extensionElements>`);
    for (const n of s.nodes.filter(x => x.lane === lane.id)) {
      lines.push(`        <bpmn:flowNodeRef>${escText(displayIdOf(n))}</bpmn:flowNodeRef>`);
    }
    lines.push(`      </bpmn:lane>`);
  }
  lines.push(`    </bpmn:laneSet>`);

  // nodes
  for (const n of s.nodes) {
    const tag = TYPE_TAG[n.type];
    const nodeDisplayId = displayIdOf(n);
    // For incoming/outgoing references, use the *edge* displayIds (which look like flow_N).
    const incoming = s.edges.filter(e => e.target === n.id).map(e => `      <bpmn:incoming>${displayIdOf(e)}</bpmn:incoming>`).join('\n');
    const outgoing = s.edges.filter(e => e.source === n.id).map(e => `      <bpmn:outgoing>${displayIdOf(e)}</bpmn:outgoing>`).join('\n');
    lines.push(``);
    lines.push(`    <bpmn:${tag} id="${escAttr(nodeDisplayId)}" name="${escAttr(n.name)}">`);
    const aefBlock = aefExtensionXml(n);
    if (aefBlock) lines.push(aefBlock.trimEnd());
    if (incoming) lines.push(incoming);
    if (outgoing) lines.push(outgoing);
    lines.push(`    </bpmn:${tag}>`);
  }

  // edges
  for (const e of s.edges) {
    lines.push(``);
    const edgeDisplayId = displayIdOf(e);
    const nameAttr = e.name ? ` name="${escAttr(e.name)}"` : '';
    // sourceRef/targetRef point at the displayIds of the linked nodes — readable in XML.
    const srcNode = findNode(e.source);
    const tgtNode = findNode(e.target);
    const srcRef = srcNode ? displayIdOf(srcNode) : e.source;
    const tgtRef = tgtNode ? displayIdOf(tgtNode) : e.target;
    lines.push(`    <bpmn:sequenceFlow id="${escAttr(edgeDisplayId)}"${nameAttr} sourceRef="${escAttr(srcRef)}" targetRef="${escAttr(tgtRef)}">`);
    if (e.condition) {
      lines.push(`      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">${escText(e.condition)}</bpmn:conditionExpression>`);
    }
    const wps = e.waypoints || [];
    const hasPort = (e.sourcePort && e.sourcePort !== 'auto') || (e.targetPort && e.targetPort !== 'auto');
    // Always emit extensionElements to preserve the edge uid
    lines.push(`      <bpmn:extensionElements>`);
    if (e.uid) lines.push(`        <aef:uid value="${escAttr(e.uid)}"/>`);
    if (hasPort) {
      const sp = e.sourcePort && e.sourcePort !== 'auto' ? ` sourcePort="${escAttr(e.sourcePort)}"` : '';
      const tp = e.targetPort && e.targetPort !== 'auto' ? ` targetPort="${escAttr(e.targetPort)}"` : '';
      lines.push(`        <aef:anchors${sp}${tp}/>`);
    }
    if (typeof e.detourY === 'number') {
      lines.push(`        <aef:loopDetour y="${e.detourY.toFixed(1)}"/>`);
    }
    if (e.routingHints && Object.keys(e.routingHints).length > 0) {
      for (const [role, offset] of Object.entries(e.routingHints)) {
        if (typeof offset === 'number' && offset !== 0) {
          lines.push(`        <aef:routingHint role="${escAttr(role)}" offset="${offset.toFixed(1)}"/>`);
        }
      }
    }
    if (wps.length) {
      lines.push(`        <aef:routing>`);
      for (const wp of wps) {
        lines.push(`          <aef:waypoint x="${wp.x.toFixed(1)}" y="${wp.y.toFixed(1)}"/>`);
      }
      lines.push(`        </aef:routing>`);
    }
    lines.push(`      </bpmn:extensionElements>`);
    lines.push(`    </bpmn:sequenceFlow>`);
  }

  lines.push(`  </bpmn:process>`);
  lines.push(``);
  lines.push(`  <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->`);
  lines.push(`</bpmn:definitions>`);
  return lines.join('\n');
}

// ============================================================================
//  BPMN XML parse — the import path.
// ============================================================================
// Reads a BPMN file with AEF extensions and reconstructs an in-memory workflow
// state. Identifier handling: bpmn:id is the displayId; aef:uid (when present)
// is the immutable internal reference. When aef:uid is absent (e.g. importing
// from a non-AEF BPMN editor), a fresh uid is generated; displayId is used as
// a fallback key for matching edges to nodes.
//
// Returns the workflow state object, or null on parse failure. Throws on
// malformed XML (caller handles).
function parseBpmnXml(text) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(text, 'application/xml');
  // Detect parse errors
  const errs = doc.getElementsByTagName('parsererror');
  if (errs.length) throw new Error('XML parse error: ' + (errs[0].textContent || '').trim().slice(0, 200));

  // Helper: getElementsByTagNameNS with the bpmn namespace
  const BPMN_NS = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  const AEF_NS  = 'http://anchorpoint.framework/aef/extensions';
  const byBpmn = (parent, local) => Array.from(parent.getElementsByTagNameNS(BPMN_NS, local));
  const byAef  = (parent, local) => Array.from(parent.getElementsByTagNameNS(AEF_NS, local));

  const processes = byBpmn(doc, 'process');
  if (!processes.length) return null;
  const proc = processes[0];

  // ---- workflowMeta ----
  // workflowMeta isn't yet round-tripped through XML — pull what we can from the
  // process attributes and fall back to defaults.
  const procId = proc.getAttribute('id') || 'imported';
  const procName = proc.getAttribute('name') || procId.replace(/^Pool_/, '');
  const aefMetaEl = byAef(proc, 'workflowMeta')[0];
  const workflowMeta = {
    id: aefMetaEl?.getAttribute('id') || procName || 'imported',
    version: aefMetaEl?.getAttribute('version') || '1',
    schemaVersion: parseInt(aefMetaEl?.getAttribute('schemaVersion') || '2', 10),
    title: aefMetaEl?.getAttribute('title') || procName || 'Imported workflow',
    description: aefMetaEl?.getAttribute('description') || '',
    tier_default: aefMetaEl?.getAttribute('tier_default') || '2',
  };

  // ---- lanes ----
  const lanes = [];
  const laneSets = byBpmn(proc, 'laneSet');
  if (laneSets.length) {
    for (const laneEl of byBpmn(laneSets[0], 'lane')) {
      const laneMeta = byAef(laneEl, 'laneMeta')[0];
      lanes.push({
        id: laneEl.getAttribute('id') || generateUid('l').slice(2),
        name: laneEl.getAttribute('name') || laneEl.getAttribute('id') || 'lane',
        abbr: laneMeta?.getAttribute('abbr') || deriveLaneAbbr(laneEl.getAttribute('name') || laneEl.getAttribute('id') || 'lane'),
        authority: laneMeta?.getAttribute('authority') || 'none',
        height: parseInt(laneMeta?.getAttribute('height') || '130', 10),
      });
    }
  }
  if (!lanes.length) lanes.push(...defaultLanes());

  // ---- nodes ----
  const REVERSE_TYPE = {}; // bpmn-tag → our node type
  for (const [k, v] of Object.entries(TYPE_TAG)) REVERSE_TYPE[v] = k;
  // Link events use a different mapping (added in v2)
  REVERSE_TYPE['intermediateThrowEvent'] = 'linkEventThrow';
  REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch';

  const nodes = [];
  const displayIdToUid = new Map(); // for resolving sourceRef/targetRef on edges

  const nodeTags = ['startEvent', 'endEvent', 'serviceTask', 'userTask', 'scriptTask',
                    'exclusiveGateway', 'parallelGateway', 'intermediateThrowEvent', 'intermediateCatchEvent'];
  for (const tag of nodeTags) {
    for (const el of byBpmn(proc, tag)) {
      const displayId = el.getAttribute('id') || '';
      const name = el.getAttribute('name') || displayId;
      const type = REVERSE_TYPE[tag] || 'serviceTask';
      // uid from aef:uid extension, else generate
      const uidEl = byAef(el, 'uid')[0];
      const uid = uidEl?.getAttribute('value') || generateUid('n');
      // Position from aef:position extension if present, else lay out automatically
      const posEl = byAef(el, 'position')[0];
      let x, y;
      if (posEl) {
        x = parseFloat(posEl.getAttribute('x'));
        y = parseFloat(posEl.getAttribute('y'));
      }

      // Lane membership: look up which laneSet entry references this displayId
      let laneId = lanes[0]?.id;
      for (const laneEl of byBpmn(proc, 'lane')) {
        const refs = byBpmn(laneEl, 'flowNodeRef').map(r => r.textContent?.trim());
        if (refs.includes(displayId)) { laneId = laneEl.getAttribute('id'); break; }
      }

      // aef extension fields
      const aef = {};
      const metaEl = byAef(el, 'meta')[0];
      if (metaEl) {
        for (const a of metaEl.attributes) aef[a.name] = a.value;
      }
      const endpointEl = byAef(el, 'endpoint')[0];
      if (endpointEl) aef.endpoint = (endpointEl.textContent || '').trim();
      const ctxEl = byAef(el, 'contextReads')[0];
      if (ctxEl) aef.contextReads = ctxEl.getAttribute('paths') || '';
      const artEl = byAef(el, 'artifactsWrites')[0];
      if (artEl) aef.artifactsWrites = artEl.getAttribute('paths') || '';
      const decInEl = byAef(el, 'decisionInput')[0];
      if (decInEl) aef.decisionInput = (decInEl.textContent || '').trim();
      const decOutEl = byAef(el, 'decisionOutputs')[0];
      if (decOutEl) aef.decisionOutputs = decOutEl.getAttribute('values') || '';
      // Link event extension: targetWorkflow + linkId
      const linkEl = byAef(el, 'link')[0];
      if (linkEl) {
        aef.targetWorkflow = linkEl.getAttribute('targetWorkflow') || '';
        aef.linkId = linkEl.getAttribute('linkId') || '';
      }

      // I/O
      const io = { inputs: [], outputs: [] };
      const ioEl = byAef(el, 'io')[0];
      if (ioEl) {
        for (const inp of byAef(ioEl, 'input')) {
          io.inputs.push({
            name: inp.getAttribute('name') || '',
            type: inp.getAttribute('type') || 'string',
            required: inp.getAttribute('required') === 'true',
          });
        }
        for (const out of byAef(ioEl, 'output')) {
          io.outputs.push({
            name: out.getAttribute('name') || '',
            type: out.getAttribute('type') || 'string',
          });
        }
      }

      // Derive slug from name if not encoded
      const slug = deriveSlug(name);

      // Default position if none was encoded — simple flow layout per lane
      if (x == null || isNaN(x) || y == null || isNaN(y)) {
        const sameLane = nodes.filter(n => n.lane === laneId);
        x = POOL_X + LANE_HEADER + 30 + sameLane.length * 90;
        y = 0; // patched below once lanes are inserted into state
      }

      nodes.push({
        uid, id: uid, slug, type, name, lane: laneId,
        x, y,
        aef, io,
      });
      displayIdToUid.set(displayId, uid);
    }
  }

  // ---- edges ----
  const edges = [];
  for (const el of byBpmn(proc, 'sequenceFlow')) {
    const uidEl = byAef(el, 'uid')[0];
    const uid = uidEl?.getAttribute('value') || generateUid('e');
    const srcDisplayId = el.getAttribute('sourceRef');
    const tgtDisplayId = el.getAttribute('targetRef');
    const source = displayIdToUid.get(srcDisplayId) || srcDisplayId;
    const target = displayIdToUid.get(tgtDisplayId) || tgtDisplayId;
    const edge = { uid, id: uid, source, target };
    const name = el.getAttribute('name');
    if (name) edge.name = name;
    const condEl = byBpmn(el, 'conditionExpression')[0];
    if (condEl) edge.condition = (condEl.textContent || '').trim();
    const anchorsEl = byAef(el, 'anchors')[0];
    if (anchorsEl) {
      const sp = anchorsEl.getAttribute('sourcePort');
      const tp = anchorsEl.getAttribute('targetPort');
      if (sp) edge.sourcePort = sp;
      if (tp) edge.targetPort = tp;
    }
    const loopEl = byAef(el, 'loopDetour')[0];
    if (loopEl) edge.detourY = parseFloat(loopEl.getAttribute('y'));
    const hints = {};
    for (const h of byAef(el, 'routingHint')) {
      const role = h.getAttribute('role');
      const off = parseFloat(h.getAttribute('offset'));
      if (role && !isNaN(off)) hints[role] = off;
    }
    if (Object.keys(hints).length) edge.routingHints = hints;
    const routing = byAef(el, 'routing')[0];
    if (routing) {
      const wps = [];
      for (const wp of byAef(routing, 'waypoint')) {
        wps.push({ x: parseFloat(wp.getAttribute('x')), y: parseFloat(wp.getAttribute('y')) });
      }
      if (wps.length) edge.waypoints = wps;
    }
    edges.push(edge);
  }

  // Snap y-coords to lane centers for nodes that lacked explicit positions
  const result = {
    pool: { id: proc.getAttribute('id') || 'Pool_imported', name: procName },
    workflowMeta,
    lanes,
    nodes,
    edges,
  };
  // Use a temporary state so laneCenterY() resolves correctly during patching
  const prev = state;
  state = { lanes };
  for (const n of nodes) {
    if (n.y === 0) {
      const def = NODE_DEFAULTS[n.type] || NODE_DEFAULTS.serviceTask;
      n.y = laneCenterY(n.lane) - def.h / 2;
    }
  }
  state = prev;
  return result;
}

function colorizeXml(xml) {
  return escText(xml)
    .replace(/&lt;(\/?)(bpmn|bpmndi|dc|di):([\w]+)/g, '<span class="x-tag">&lt;$1$2:$3</span>')
    .replace(/&lt;(\/?)(aef):([\w]+)/g, '<span class="x-aef">&lt;$1$2:$3</span>')
    .replace(/(\s)([\w:_-]+)=(&quot;)/g, '$1<span class="x-attr">$2</span>=$3')
    .replace(/(&quot;)([^&]*?)(&quot;)/g, '<span class="x-val">$1$2$3</span>')
    .replace(/(&lt;!--[\s\S]*?--&gt;)/g, '<span class="x-com">$1</span>');
}

// ============================================================================
//  Init
// ============================================================================
refreshDisplayIds();
renderAll();
refreshLibraryUI();
setMode('select');
</script>
</body>
</html>

```
