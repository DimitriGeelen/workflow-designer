# AEF Workflow Designer

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
