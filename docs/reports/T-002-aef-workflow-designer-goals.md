# T-002 — Goals & Architecture: AEF Workflow Designer

**Task:** T-002 (inception, owner: human)
**Date:** 2026-06-05
**Author:** Claude Code (agent research; decision reserved for human operator)
**Source material:** `zzz-seed-design-files/` (README, architecture.md, schema.md,
user-guide.md, and the implemented `aef-workflow-designer.html` artifact)

---

## Problem Statement

**What:** A visual, BPMN-subset editor for authoring AEF workflows. Humans
compose workflows by dragging tasks, decisions, and parallel branches across
swimlanes; agents consume the same file as a typed, schema-validated
representation with stable identifiers and explicit data contracts.

**Why:** AEF workflow representations climb a *manifest-maturity ladder*:

1. **Exploration** — markdown dispatch templates; an agent improvises structure.
2. **Stabilization** — structured workflow files (this designer's output): a
   graph with typed I/O and routing, usable today by hand-execution.
3. **Automation** — a future `fw workflow run <name>` executor runs the file
   directly.

There is currently no authoring tool for tier 2. Hand-writing structured
workflow YAML is error-prone, and markdown templates don't capture routing,
typed I/O, or the authority-model lane structure. This designer fills that gap.

**For whom (dual-audience, same file):**
- **Humans** — a Visio-like canvas: drag shapes, fill properties, save.
- **Agents** — typed YAML/XML with stable `uid`s and `aef:` extension fields.

Neither audience sees a degraded version meant for the other.

---

## Goals

1. Let a human author a complete AEF workflow visually with no server and no build step.
2. Produce a YAML-canonical file rich enough for an executor, editable by humans, generatable by agents.
3. Map swimlanes to the AEF authority model (Human · Sovereignty, Framework · Authority, Agent · Initiative, plus External/None).
4. Round-trip BPMN XML (export *and* import) with an `aef:` extension namespace.
5. Remain useful **before** the runtime executor exists (hand-executable output).

---

## Target Architecture (from seed design)

- **Single self-contained HTML file** — CDN-only sandbox: no `bpmn-js`, no
  localStorage, no build step. The designer rolls its own SVG canvas. This is a
  *constraint* of the rendering sandbox, not an aesthetic choice
  (architecture.md §1).
- **One mutable `state` object** — `pool`, `workflowMeta`, `lanes[]`, `nodes[]`,
  `edges[]`. Mutate → `renderAll()`. No Redux/framework (architecture.md §2).
- **Two-identifier model** — immutable `uid` (edge graph anchor) + computed
  `displayId` (conversational handle, derived from lane abbr + spatial rank).
  `id` is a legacy alias for `uid` (architecture.md §3).
- **Eight-element BPMN subset** — start/end events, three task types
  (service/user/script), two gateway types (exclusive/parallel), sequence flow;
  plus off-page link connectors for cross-workflow handoffs.
- **Auto-routing** — multi-edge spread, loop-back detection with lane-clamped
  detour, per-segment routing hints (architecture.md §4).
- **YAML canonical, BPMN XML derived** — YAML is the source of truth; the
  rendering layer is replaceable, so the data model survives a future migration
  to a server-backed/multi-user editor.

---

## Constraints

- **Rendering sandbox:** CDN-only imports; no localStorage; no `bpmn-js`.
- **No persistence between page loads:** Save downloads `<id>.v<version>.bpmn`;
  Load opens a file picker. (Auto-discovery of a library from disk is roadmap.)
- **Browser-only:** runs in any modern browser, no server required.

---

## Current State (what already exists in seed)

A working artifact (`aef-workflow-designer.html`, ~192 KB) already implements:
the eight-element subset, off-page connectors, three authority lanes with full
CRUD, the two-identifier model, auto-routing with loop-back, BPMN XML
import/export with `aef:`, a multi-workflow library, properties panels, multi-
select/group-drag, and magnetic snap. The `investigate` seed workflow exercises
every schema feature as a worked example.

**Not yet implemented (roughly by priority):** undo/redo, pan/zoom, inline
validation, copy/paste, in-canvas waypoint editing, cross-workflow navigation,
auto-discovery of the workflow library.

---

## Scope Fence

**IN scope for the project (post-GO build):**
- Promote the seed design + artifact into the canonical repository structure.
- Decide where the product source lives (e.g. `src/` or a top-level artifact).
- Establish verification (schema validation of produced workflow files).

**OUT of scope (explicit non-goals for now):**
- The `fw workflow run` runtime executor (tier 3 — separate, planned effort).
- Server-backed or multi-user collaboration (the data model is designed to
  survive that migration, but it is not this project).
- Abandoning the single-file constraint.

---

## Go/No-Go Criteria

**GO if:**
- The problem statement and target users are clear and the human confirms the
  AEF Workflow Designer (as scoped above) is the intended product.
- The seed design is accepted as the architectural baseline.

**NO-GO / redirect if:**
- The intended project differs materially from the seed design.
- The single-file constraint or YAML-canonical model is not desired.

---

## Recommendation

**Recommendation: GO** — adopt the seed design as the architectural baseline and
proceed to build tasks that promote the artifact into the canonical repository.

**Rationale:** The design is complete, internally consistent, and already backed
by a working artifact. The problem (a tier-2 authoring tool for AEF workflows)
is real and unfilled. Scope and constraints are well understood. Risk is low
because the deliverable is hand-usable before any runtime executor exists.

**This decision is reserved for the human operator** (T-002 is `owner: human`;
it is the foundational project decision). On GO, create separate build tasks —
do not continue building under T-002.

---

## Dialogue Log

- 2026-06-05 — Agent synthesized this artifact from `zzz-seed-design-files/`
  during framework initialisation (operator directive: "focus on framework
  initialisation and stabilisation; proceed as seen appropriate"). Decision
  pending human review.
