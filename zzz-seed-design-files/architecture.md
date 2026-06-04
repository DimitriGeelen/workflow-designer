# AEF Workflow Designer — Architecture

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
