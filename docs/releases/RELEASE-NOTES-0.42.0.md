# Workflow Designer 0.42.0 — release notes

**Since:** `designer-v0.41.0`. A file that gives none of its nodes a position is laid out along its flows (T-976). The
pool encloses a node placed left of it (T-1386), Settings fits the window (T-1392), and field controls a host does not
serve are hidden (T-1391).

## Changes

- **Files without positions are laid out along their flows (T-976).**
  - **Before.** A BPMN file with no `<aef:position>` and no DI for any node was drawn in the order its elements are
    listed in the file, 90 px apart per lane. A generator that left geometry out got End before the tasks leading to
    it, and overlapping nodes.
  - **Now.** Such a file opens with every node right of the nodes that lead to it. A loop-back flow is the only flow
    that runs back. Nodes that share a lane and a step sit side by side, and every node stays in its lane.
  - **Only when no node has a position.** A file that positions any node keeps today's placement for all of them.
  - Guard: browser leg 229, `tools/_t976-flow-order-cdp.mjs`. On its synthetic fixture: 0 backward flows (0.41.0: 6),
    0 overlapping nodes (0.41.0: 2), no flow through a node, no label clash. A partly positioned file is unchanged.
- **The pool's left edge encloses a far-left node (T-1386).** A node an import placed left of the pool's fixed left
  edge was drawn across the border (known in 0.41.0). The edge now grows to enclose it and its label. The edge moves
  only for such a node. This is a view change; saved bytes are unchanged.
- **Settings fits the window (T-1392).** The dialog ran to 1186 px tall at every width, so its lower settings
  ("Labels", "Reset to defaults") could not be reached on most screens. It now fits the window, and its body scrolls
  under a fixed header with Close.
- **Field controls a host does not serve are hidden (T-1391, operator's option 2).**
  - **Hidden** where the host does not serve `/api/field-profile` or `/api/field-suggestions`: the field-profile
    settings and "Suggest as a field". That is the case for AEF, which will not serve them (your T-4737).
  - **Before**, they were shown disabled or read-only. Where the endpoints are served, nothing changes.

## What changes in stored maps

- **Nothing for a map that carries positions.** That includes every map the designer saved and all of AEF's corpus:
  all 24 save byte-identically to 0.41.0.
- **A file with no positions at all** gets the flow layout's positions on its first save, as it got the file-order
  ones before. No node id, flow or other element changes.

## Not kept yet

Unchanged from 0.41.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator, which waits for AEF's mapping vocabulary (T-4991).

## For AEF

**What changes in what you store:** nothing for maps with positions, which is all of your corpus. A map you
generate without geometry opens laid out along its flows, so a generator no longer has to compute positions to get a
readable map.

**What changes in Check (`POST /api/validate`):** nothing. `validate-workflow.py` is unchanged since 0.41.0. The
kit's `SHA256SUMS` moves with the version only.

The endpoints as you confirmed them on 2026-11-08 (msg adadee0b):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: the button is hidden (T-1391) |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
