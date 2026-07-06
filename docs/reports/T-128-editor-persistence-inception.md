# T-128 — Editor Persistence, Versioning & Recovery Subsystem (Inception)

**Status:** exploration → recommendation GO
**Date:** 2026-07-06
**Focus task:** T-128 (inception)
**Predecessor:** T-126 (autosave RCA + safety-net, verified)

## 1. Problem

The workflow designer had no durable document persistence — only preferences persisted; the
document lived in memory and "Save" downloaded a file. A reload lost unsaved work (T-126). The
autosave safety-net now exists and is verified, but the operator wants a real subsystem:

1. Reload **auto-loads** the stored version (no banner).
2. Manual **Save into the repo** (durable).
3. **Versioning** + **revert-to-previous**.
4. **Undo/redo**.
5. **Version thumbnails** in the restore/revert UI.

**Strategic why:** versioned corrections become before/after geometry diffs — the training data
to learn the operator's routing/layout rules. Durable *diffable* versioning is the enabler for
that downstream learning arc.

## 2. Layering model

Three distinct persistence layers, deliberately separated:

| Layer | Trigger | Scope | Store | Purpose |
|-------|---------|-------|-------|---------|
| Autosave | automatic (debounced, every edit) | in-progress doc | `localStorage[aefAutosaveDoc]` | never-lose safety net |
| Undo/redo | per mutating gesture | live session | in-memory stack | step back/forward |
| Save-to-repo | manual ("Save to project") | durable checkpoint | `.editor-versions/<id>/` + canonical yaml | versioned, revertable, diffable |

Autosave ≥ last Save (fires on every edit) → on reload we auto-adopt autosave. Save is the
durable checkpoint that also produces the learning diff.

## 3. Design decisions

### D1 — Version store: explicit snapshot files (IW-1)
`.editor-versions/<id>/` holding `vN.workflow.yaml`, `vN.png` (thumbnail), `index.json`
(`[{v, ts, note, thumb}]`). Committed to the repo. Chosen over git-log-only because it holds
thumbnails and needs no browser-side git. Canonical `<id>.workflow.yaml` git history still gives
learning diffs.

### D2 — Reload precedence (IW-3)
Auto-adopt `localStorage[aefAutosaveDoc]` keyed by `workflowMeta.id` → repo-latest → seed. No
banner. Non-modal "New" and "Discard local → last saved" affordances remain.

### D3 — Undo/redo (IW-4)
`pushHistory(label)` snapshots state BEFORE each mutating gesture (per-gesture granularity),
generalizing the existing `lastTidy`/`undoTidy`. Redo cleared on new mutation. Stack capped ~50.
NOT hooked into `renderAll()` (fires on non-mutating re-renders → spurious entries). Autosave
stays in renderAll (idempotent).

### D4 — Sovereignty (IW-6)
Autosave is automatic and NEVER writes the repo. Repo writes happen ONLY on manual Save (explicit
user action → PD-044 satisfied). Post-save guards: node-cut census 0/24, mirror `diff -q` clean.

## 4. Server API (B2)

A localhost write endpoint alongside the gallery (transport TBD — spike S-2):

- `POST /api/save` `{id, yaml, png(base64), note}` → write canonical `examples/aef-processes/<id>.workflow.yaml`,
  re-render `rendered/<id>.bpmn` via `tools/yaml-to-bpmn.py`, mirror to build/gallery, append
  version to `.editor-versions/<id>/` (+ thumbnail). Returns `{v, ts}`. Rejects path traversal in `id`.
- `GET /api/versions?id=<id>` → `index.json`.
- `GET /api/version?id=<id>&v=<n>` → that version's yaml.
- `GET /api/thumb?id=<id>&v=<n>` → that version's png.

## 5. Decomposition (build tasks, authorised on GO)

1. **B1 Reload auto-load** — editor-only; replace banner with keyed auto-adopt. *First (operator #1, lowest risk).*
2. **B2 Save sidecar** — server endpoints + snapshot store + re-render/mirror.
3. **B3 Save-to-project button** — editor POSTs doc + thumbnail.
4. **B4 Versioning + revert UI** — version list modal with thumbnails; revert loads a version.
5. **B5 General undo/redo** — `pushHistory` stack.

## 6. Constraints

- Mirror `src/aef-workflow-designer.html` ≡ `build/gallery/designer.html` byte-identical.
- No CDN / external network; thumbnail path dependency-free.
- Agent verification: ISOLATED headless chromium only (G-006).
- Localhost-only writes; reject path traversal.

## 7. Spike results

**S-2 (transport, IW-2):** `:8834` is `python3 -m http.server --directory build/gallery`
(`tools/serve-gallery.sh`) — static, read-only, serves an off-repo copy (keeps `.git`/`.context`
off the wire). Cannot POST. → **Dedicated Python sidecar**, run from repo root, localhost-bound,
serving the designer + `/api/*` from one origin (no CORS). Editor progressively enhances: version
UI only when `/api/*` is reachable; degrades to autosave+download on the static gallery.

**S-3 (thumbnail, IW-5):** DOM probe found the diagram is `<svg id="canvas">` (439×389, 38 `<g>`,
**0 `foreignObject`**, no `<canvas>` element; labels are `<text>`). A control render of an inline
SVG through `Image(data-URL) → canvas.drawImage → toDataURL('image/png')` returned a valid
`data:image/png;base64,iVBOR…` (742 bytes) with **no SecurityError** — no taint source present
(no foreignObject, no external/CDN refs). → **Client-side SVG→PNG thumbnails are viable**; server
CDP fallback unnecessary. (Harness heredocs mangled a regex mid-spike — cosmetic; the taint
verdict stands on the foreignObject-absence + successful control render.)

## 8. Dialogue Log

- Operator (across T-126→T-128): "i want reload to load the stored version!!!!" (not a banner);
  "we need to work on a save in rpeo + versioning and revert to previous version"; "can we also
  have manual save?"; "maybe we should also add a undo / redo function"; "should we incept this?
  btw a nice thing would be to see screenshot from the versions in restore".
- Agent recommendation: GO — the asks form a bounded subsystem with a clear 5-task decomposition;
  sovereignty and durability questions resolved; enables the learning goal. Operator authorised
  ("proceed as seen fit … deliver what we discussed").
