# 01 — Feature inventory of the product (`src/aef-workflow-designer.html`)

**Leg:** GATHERER, Phase 2. **Role:** evidence only — nothing here is classified,
recommended, or proposed. Classification belongs to the JUDGE.

**Subject measured 2026-09-20:** `src/aef-workflow-designer.html`, 997,254 bytes,
11,248 lines, **248** `function` declarations (247 unique — `renderEdges` appears
once as a declaration at `function renderEdges()` and once inside a comment at the
`// Edges. Waypoints come from computeEdgeGeometry()` block, so the earlier
254-declaration count in `00-yardstick.md` is a different matcher, not a conflict I
can resolve; **both counts recorded, not averaged**). Two `<style>` blocks
(`  <style>` at file head, `<style>` following it) and ONE `<script>` block opening
at `<script>` immediately after `<div class="xml-panel" id="xml-panel">`'s closing
`</div>` and running to `</script>` at EOF. HTML body markup occupies only
`</style>` → `<script>`; everything after is JavaScript.

## Method and its limits

- Anchors are **function names** or **stable `id="…"` strings**, never bare line
  numbers (they drift). Where I give a line number it is a *locator as of today*,
  always paired with a string anchor.
- Reachability inside the file was computed mechanically: for every declared
  function name, count `name(` call-sites minus the declaration, and count bare
  references (handler assignment). Script re-runnable; it is pure text matching, so
  a call through a computed property or a string would be missed — **UNVERIFIED for
  that class**, and I found no evidence of such a call pattern in this file.
- Reachability *outside* the file was computed by scanning every file under
  `tools/`, `tests/`, `scripts/` for each function name. Four names collide with
  ordinary English/code words and their external hits are **false positives**:
  `done` (75), `text` (242), `field` (91), `section` (70), `el` (31). Excluding
  those five, **88 of 247** functions are named by something outside the product
  file.
- **No product usage telemetry exists** (operator-confirmed; re-checked: no
  `designer-usage.jsonl`, no `.context/telemetry/`, no `logs/`). Therefore **every**
  item below is **UNMEASURED for actual operator use**. Where I write a non-use
  reading it is about *reachability and documentation*, never about use.
- I did not run the test suite, `fw audit`, or any CDP probe. The only live probe
  performed was read-only HTTP GETs against already-running local ports.

## Load-bearing measurement made once, cited throughout

The operator-facing served build is **not** the product in `src/`.

| Artefact | Bytes | sha256 (20) |
|---|---|---|
| `src/aef-workflow-designer.html` | 997,254 | `2b448b61b7fa6c33f347` |
| `dist/aef-workflow-designer-0.12.0.html` | — | `2b448b61b7fa6c33f347` (**identical to src**) |
| `GET http://127.0.0.1:3013/designer/app` | 903,600 | `cab3c75183979b0e15e2` |
| `vendor/designer/aef-workflow-designer-0.8.0.html` | 903,600 | `cab3c75183979b0e15e2` (**identical to what is served**) |

Marker census on the served bytes vs `src/` (`grep -c`): `T-618` 0/2, `T-600` 0/3,
`T-602` 0/2, `T-603` 0/3, `T-589` 0/5, `T-566` 0/6, `T-570` 0/8, `T-423` 0/5,
`T-598` 0/1, `T-690` 0/2. **Ten consecutive shipped changes are absent from the
served app.** Any item below whose origin task is one of those ten is present in
the source of truth and absent from the surface an operator would actually open at
`/designer/app`. This is the same gap `00-yardstick.md` recorded; I re-measured it
independently and it is unchanged. Referred to below as **SERVED-GAP**.

No write-capable gallery server is running: `pgrep -af gallery-serve` → no match;
port 8080 is `open_webui.main:app` (uvicorn), not `tools/gallery-serve.py`. So every
item gated on `/api/health` is, **right now on this host, hidden by its own
progressive-enhancement gate** — separate from whether it works.

---

## A. Inventory

Columns: **Item | Source | Status of source | Data point (with citation) | Window | Kind**

Status legend: EXISTS (present and reachable in the live tree) · PARTIAL (present,
some declared part missing/inert) · DESIGNED-ONLY (described, not built) · ABSENT.

### A1. Shell, chrome, view state

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| App shell / single-file delivery | `src/aef-workflow-designer.html` | EXISTS | One file, no `package.json`, no `Makefile`, no bundler, no external `<script src>`; 997,254 bytes. Serves D4 Portability (open in any browser) and is the premise of the release path | last src change `66e04cff` 2026-09-09 | structure |
| Header toolbar | `id="btn-…"` cluster in `<div class="actions">` | EXISTS | 14 buttons: zoom-out/level/in/fit, toggle-palette, toggle-props, focus-mode, add-lane, reset, clean, xml, settings, load, versions, save-project, save | — | structure |
| Palette (node vocabulary) | `<aside class="palette">`, `data-create=` attributes | EXISTS | 13 creatable types across 6 groups: Events (startEvent, endEvent), Tasks (serviceTask, userTask, scriptTask, subProcess), Gateways (exclusiveGateway, parallelGateway), Handoffs (linkEventThrow, linkEventCatch), Typed events (eventError, eventTimer, eventMessage), Lanes (`id="palette-add-lane"`). Matches `const NODE_DEFAULTS` exactly (13 keys) | subProcess last touched `826b40aa` 2026-08-15; eventTimer `fa201bff` 2026-07-19 | structure |
| Properties panel | `<aside class="properties" id="properties">`, `function renderProperties` | EXISTS | 13 `section('…')` headings: Align, Distribute, Workflow, Recently opened, Tips, Flow, Routing, Lane, Order, BPMN, Event kind, Extensions, I/O contract | — | structure |
| Panel show/hide | `$('btn-toggle-palette').onclick`, `$('btn-toggle-props').onclick`, `function setViewPref` | EXISTS | Persisted in `localStorage['aefViewPrefs']`; applied on load by `applyViewChrome()` called at module scope | T-245 | value |
| Focus mode | `function setFocusMode`, `id="vc-exit"`, `document.addEventListener('fullscreenchange'` | EXISTS | Hides header/palette/properties AND requests browser fullscreen; Esc path is explicit in the keydown handler (`if (focusMode) { setFocusMode(false); return; }`) | `7c53622c` 2026-07-23 | value |
| Zoom (buttons, Ctrl+wheel, click-for-100 %) | `function setZoom`, `function effectiveZoom`, `canvasWrap.addEventListener('wheel'` | EXISTS | Zoom at cursor, step 1.12; `$('zoom-level').onclick = () => setZoom(1)`; fit is `setZoom(null)`. Transient, not persisted | `dc9fedae` 2026-07-25 | value |
| Pan (middle-mouse, Space+drag) | `let panDrag = null, panKeyHeld = false`, `canvasWrap.addEventListener('mousedown'…, true)` | EXISTS | Capture-phase so it preempts the rubber-band without modifying it; `window.addEventListener('blur')` clears a stuck Space | T-249/T-251 | value |
| Status overlay | `id="status"`, `id="status-mode"`, `id="status-selection"`, `function syncOverlayPin` | EXISTS | Shows current mode incl. `create <type>` | — | usage |
| Canvas layer order | `id="g-pool"`, `g-badges`, `g-edges`, `g-nodes`, `g-badges-top`, `g-handles`, `g-preview` | EXISTS | 7 SVG groups; `g-badges`/`g-badges-top` carry `pointer-events="none"`, `g-handles` deliberately does not (comment cites T-293) | T-286/T-293 | structure |

### A2. Authoring — nodes, edges, lanes

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Click-to-place | `function setMode` (`'create:' + el.dataset.create`), `function createNodeAt` | EXISTS | Palette click arms create mode; canvas click places | — | value |
| Drag-to-place | `const AEF_NODE_DND_TYPE = 'application/x-aef-node'`, `svg.addEventListener('drop'` | EXISTS | HTML5 DnD; `dragover` gates on the MIME type because `getData()` is unreadable during dragover; drop routes to the same `createNodeAt` | T-172 | value |
| Node drag / move | `function onNodeMouseDown`, `svg.addEventListener('mousemove'` | EXISTS | — | — | value |
| Node rename in place | `function onNodeDblClick` | EXISTS | — | — | value |
| Multi-select (rubber band) | `function renderRubberBand`, `function finalizeRubberBandSelection`, `let multiSelect` | EXISTS | Delete of a multi-selection is handled separately in the keydown branch (`if (multiSelect.size > 1)`) | — | value |
| Align / Distribute on a multi-selection | `function _applyAlignDistribute`, `function _distributeAxis`, `function renderMultiSelectProps`, `section('Align'` / `section('Distribute'` | EXISTS | Only reachable with >1 node selected | — | value |
| Connect mode (draw sequence flow) | `id="tool-connect"`, `function addEdge`, `connectFrom` | EXISTS | Click source → click target | — | value |
| Edge endpoint re-anchor | `function onEndpointMouseDown`, `function renderPortIndicators`, `function nearestPortName` | EXISTS | Reconnect chrome lives in `g-handles` so it hit-tests above node bodies | T-168/T-293 | value |
| Manual waypoints | `function onWaypointMouseDown`, `function removeWaypoint`, `function clearWaypoints` | PARTIAL | `onWaypointMouseDown` and `removeWaypoint` are called; **`clearWaypoints` has 0 call-sites and 0 bare references in the file** (see §C) | — | structure |
| Add-waypoint affordance | `function onAddWaypointMouseDown` | PARTIAL | **0 call-sites, 0 references in the file** (see §C). `e.waypoints` is read/written elsewhere (`5694`, `6914`, `8580`, `8598`), so the waypoint *model* is live while this specific creation handler is not wired | — | structure |
| Per-segment routing nudge | `function onSegmentMouseDown`, `routingHint` (6 sites) | EXISTS | — | — | value |
| Loop-back detour drag | `function onLoopDetourMouseDown`, `loopDetour`, `function orthoLoopBack` | EXISTS | — | — | value |
| Lane add / delete / reorder / resize | `function addLane`, `deleteLane`, `moveLane`, `onLaneResizeMouseDown` | EXISTS | Lane delete with content prompts via `confirm(…They will be reassigned…)` in the keydown branch | — | value |
| Pool right-edge resize | `function onPoolResizeMouseDown`, `poolResizeDrag` | EXISTS | Handler is **referenced once** — `rightG.addEventListener('mousedown', onPoolResizeMouseDown)` in `renderPool` — never *called*; that is correct wiring, not an orphan. Window-level mousemove, clamp `PAGE_WIDTH_MAX = 16000`, `state.workflowMeta.pageWidth` | T-255 | structure |
| Default lane model | `function defaultLanes` | EXISTS | Exactly 3: `human`/sovereignty, `framework`/authority, `agent`/initiative. This is the AEF authority model made structural — the single strongest yardstick-alignment fact in the file | — | value |
| Built-in seed map | `function getInvestigateWorkflow` | EXISTS | Hardcoded `investigate` demo workflow, 39 `name:` occurrences in its span; it is what `$('btn-reset')` restores | — | structure |

### A3. Layout assistance

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Clean layout (one click) | `$('btn-clean').onclick`, `function cleanLayout`, `function flashCleanFeedback` | EXISTS | Tidy + branch pitch + align rows on every lane; reverts with Ctrl+Z; button flashes `✨ Cleaned N nodes` | `8eb16dd8` 2026-07-28 | value |
| Clean nudge (advisory) | `id="clean-nudge"`, `function maybeShowCleanNudge`, `function mapMessiness` | EXISTS | Heuristic score decides whether to offer Clean | — | friction |
| Lane-fix notice (import repair advisory) | `id="lane-fix-notice"`, `function maybeShowLaneFixNotice` | EXISTS | Shown when an imported map drew nodes outside their DECLARED lane and they were moved back | T-310 | value |
| Tidy lane / undo tidy | `function tidyLane`, `function undoTidy` | EXISTS | Legacy single-step revert; `undo()` falls back to it when the history stack is empty | — | value |
| Row / column alignment + respacing | `alignRowsLane`, `alignColumns`, `alignColumnsMoves`, `distributeEvenly`, `respaceRows`, `respaceColumns` | EXISTS | The standalone `⁙ Align columns` and `↔ Distribute evenly` **toolbar buttons were retired** (comment at the `btn-xml` button cites T-139: "they fought each other"); the functions are retained for Clean/nudge/import/bake/verifiers. `alignColumns`, `alignColumnsMoves`, `alignRowsLane`, `distributeEvenly` are each referenced by `tools/_align-distribute-diag.mjs` | T-139 | friction |
| Lane growth / compaction on import | `function growUnderDeclaredLanes`, `function compactLanesFit` | EXISTS | `compactLanesFit` externally exercised by `tools/_t125-lane-compaction-cdp.mjs` and `tests/test_t125_lane_compaction.py` | — | value |
| Snap (magnet / grid) | `function magneticSnap`, `function setSnapPref`, `id="set-snap-magnet"`, `id="set-snap-grid"` | EXISTS | Persisted in `localStorage['aefSnapPrefs']` | — | value |
| Snap guides | `function renderSnapGuides` | EXISTS | — | — | value |
| Label fitting / wrapping / de-collision | `fitLaneLabel`, `fitNodeLabels`, `wrapText`, `wrapOverlongBelowLabels`, `deCollideBelowLabels`, `adjustLabelPlacements`, `adjustEdgeLabelPlacements` | EXISTS | 7 functions, ~600 lines of the file. `wrapOverlongBelowLabels` last touched `1d383648` 2026-08-26 (T-600); `adjustLabelPlacements` exercised by `tools/_t600-label-wrap.mjs` and `tools/_t601-lane-boundary.mjs` | 2026-08-26 | cost |
| Orthogonal routing engine | `orthoConnect`, `routeAroundObstacles`, `routeAvoidingWithPorts`, `routeOrthogonalSegment`, `simplifyRoutedPolyline`, `consolidateStaircase`, `collapseCollinearPoints`, `endpointStraightSnap`, `corridorSplit`, `loopPathCrossings`, `countNodeCrossings`, `polylineCrossesNodes`, `buildEdgeGroups`, `spreadOffset`, `channelExtra`, `applySpread` | EXISTS | The single largest subsystem: ~16 named functions spanning `function buildEdgeGroups` → `function computeEdgeGeometry`. `routeAvoidingWithPorts` last touched `ec408a88` 2026-07-05 — the **oldest** last-touch of any subsystem I sampled | 2026-07-05 | cost |
| Undo / redo | `function pushHistory`, `undo`, `redo`, `snapshotState`, `_restoreSnapshot`, `const _HISTORY_CAP = 50` | EXISTS | Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl/Cmd+Y. Snapshots are **XML strings** (`_history.push(beforeXml)`), so undo is coupled to the exporter. Externally exercised by `tools/_undo-verify-cdp.mjs` | `dda05878` 2026-07-26 | value |

### A4. Import paths

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| File picker import | `$('btn-load').onclick`, `input.accept = '.bpmn,.xml,application/xml,text/xml'` | EXISTS | Parse failure surfaces as `alert('Failed to parse workflow file:\n' + e.message)` | — | value |
| Deep-link import (`?load=`) | `new URLSearchParams(location.search).get('load')`, `function currentLoadSrc` | EXISTS | Same-origin fetch; comment states it is "only useful when served over HTTP". Interacts with autosave via `_suppressDeepLink` | T-234 | value |
| Autosave restore on load | `function autoLoadStored`, `const AUTOSAVE_KEY = 'aefAutosaveDoc'` | EXISTS | Restores silently, confirms with a toast offering "Start fresh". Three-way rule documented in-code (no `?load` → restore; matching `?load` → restore; differing `?load` → deep-link wins) | `7390131c` 2026-07-22 | value |
| BPMN parser | `function parseBpmnXml` (~620 lines, `10422`→`11045`) | EXISTS | Named by **62** files under tools/tests/scripts — the most externally-referenced symbol in the product after `buildBpmnXml` | T-603 `adcd5af1` 2026-09-09 | structure |
| Multi-`bpmn:process` documents | `adcd5af1` "a document with more than one bpmn:process no longer loses everything but the first, silently" | EXISTS | Probe `tools/_t603-multiprocess-import.mjs` references `maybeShowLaneFixNotice` | 2026-09-09 | value |
| Lane provenance recording | `laneProvenance` (7 sites) | EXISTS | 4 disjoint values assigned on every path, **deliberately not emitted** (commit `3bf37909`, T-358) — recorded so a default can be chosen later by the operator | — | structure |
| Foreign / unknown BPMN tag survival | `foreignTag` (11 sites) | EXISTS | Import no longer deletes flow nodes outside the allowlist (`bd536f05`, T-337); re-emitted on export | — | value |
| `bpmn:documentation` round-trip | `documentation` (11 sites), probe `tools/_t602-documentation-roundtrip.mjs` | EXISTS | `7118a92c` — described in its own commit subject as "a field-reported data loss that never worked" | 2026-09-09 | value |
| BPMN DI import (`dc:Bounds`) | `sourceCarriedDi` (2 sites), commit `fc7f7263` (T-340) | EXISTS | Position precedence documented as `aef:position` → DI → auto-layout | — | structure |
| Clean-on-import option | `id="set-clean-on-import"`, `viewPrefs.cleanOnImport` | EXISTS | Off = files open exactly as saved | T-096 | value |
| Adoption entry point | `function adoptImportedXml` | EXISTS | Named by **16** external files — the shared import funnel every probe drives | — | structure |

### A5. Export paths

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Save → download `.bpmn` | `$('btn-save').onclick`, `a.download = \`${id}.v${v}.bpmn\`` | EXISTS | Blob + object URL; the only export the README documents | — | value |
| BPMN builder | `function buildBpmnXml` (~264 lines, `10158`→`10422`) | EXISTS | Named by **64** external files — the single most externally-depended symbol in the product | `66e04cff` 2026-09-09 | structure |
| `aef:` extension emitter | `function aefExtensionXml` (~267 lines) | EXISTS | Referenced by `tools/yaml-to-bpmn.py`, `tests/test_bridge_aef_passthrough.py`, `tools/_roundtrip-serialization-cdp.mjs` and a fixture — i.e. the emitter is a *cross-repo contract*, not an internal detail | — | structure |
| Attribute escaping | `function escAttr` / `function escText` | EXISTS | `escAttr` emits `&#10;`/`&#13;`/`&#9;` because XML 1.0 §3.3.3 normalises raw whitespace in attribute values; `escText` deliberately untouched, reason recorded in-code. 13 external references to `escAttr` | T-521 | value |
| Generic scalar carriage | `carriedKeys` (3 sites), `metaKeys` (14 sites) | EXISTS | Export emits every scalar `node.aef` value no other emitter claims; `metaKeys` stays at 20 | T-570 `8d3cf2a2` | value |
| BPMN DI emission | `bpmndi:BPMNDiagram` (2 sites), `function computeEdgeGeometry` | EXISTS | Emitted unconditionally since `389133c8` (T-423); `computeEdgeGeometry` extracted so the exporter never reads render state | `389133c8` 2026-08-23 | structure |
| DI trailer comment | `DI_TRAILER` (9 sites) | PARTIAL | `389133c8` records "THE TRAILER'S else IS NOW UNREACHABLE" — a branch kept deliberately, with AEF's ruling behind it | 2026-08-23 | structure |
| `aef:position` carrier | `aef:position` (12 sites) | EXISTS | Coexists with `dc:Bounds`; commit `389133c8` names this as two carriers for one geometry and states the agreement guard is the follow-up | — | structure |
| XML view + copy | `$('btn-xml').onclick`, `function colorizeXml`, `$('btn-copy-xml').onclick` | EXISTS | Syntax-highlighted `buildBpmnXml(state)`; Copy uses `navigator.clipboard.writeText` inside a swallowed try/catch — **a clipboard failure is silent** | — | friction |
| Thumbnail capture | `function captureThumbnail`, `function _inlineComputedStyles`, `function _stripAnnotationLayer` | EXISTS | Inlines computed styles because class-based CSS does not travel with a serialized `<svg>`; annotation overlay stripped. 6 external references incl. `tools/gen-rendered-thumbs.mjs` | `de1f2ff9` 2026-07-27 | value |
| Determinism / sideEffect surfacing | `504e4bc9` (T-618), `AEF_FIELDS` entries `'determinism'`, `'sideEffect'` | EXISTS | Commit records a census of **215 authored values across 7 node types** the panel could not show | 2026-09-09 | value |

### A6. Persistence and the server-backed surface

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Autosave (browser) | `function autosaveNow`, `function scheduleAutosave` | EXISTS | 700 ms debounce; `localStorage['aefAutosaveDoc']` stores `{id,title,src,ts,xml}`; quota/serialization errors swallowed by design | `7390131c` 2026-07-22 | value |
| Editor preferences | `localStorage` keys `aefRoutingPrefs` (5 sites), `aefViewPrefs` (2), `aefSnapPrefs` (2), `aefLabelPrefs` (2) | EXISTS | **4 keys + `aefAutosaveDoc` = 5 total.** No `sessionStorage` use anywhere | T-075 | structure |
| Session library ("Recently opened") | `function saveActiveToLibrary`, `function loadFromLibrary`, `section('Recently opened'` | EXISTS | Row click wires `loadFromLibrary`; rendered only when `library.size > 1` | T-159 | value |
| Library `<select>` renderer | `function refreshLibraryUI` | **PARTIAL — inert body, live callers** | First statement is `const picker = $('workflow-picker'); if (!picker) return;`. **No element with `id="workflow-picker"` exists** in the file (the T-154 comment says the `<select>` was replaced by `id="btn-open-project"`). The function is called **8 times** and returns immediately every time | T-154 | structure |
| Save to project (versioned) | `function saveToProject`, `fetch('/api/save…`, `id="btn-save-project"` | EXISTS, gated | Revealed only when `/api/health` answers (`function detectSaveApi`); hidden by `style="display:none"` otherwise | T-130 | value |
| Save note prompt | `function promptSaveNote` | EXISTS | Esc cancels / Enter commits, note capped at 200 chars | — | value |
| Versions browser | `function openVersionsModal`, `revertToVersion`, `openVersionInPlace`, `deleteVersion`, `pruneOldVersions`, `makeThumbPlaceholder`, `id="btn-versions"` | EXISTS, gated | 7 functions; `fetch('/api/versions…`, `/api/version`, `/api/delete` | `64f564e8` 2026-07-10 | value |
| Loaded-version badge | `id="map-saved-version"`, `function setLoadedSavedVersion`, `function updateSavedVersionBadge` | EXISTS | Hidden for new/unsaved maps | T-157 | usage |
| Open project browser | `function openProjectModal`, `openProjectMap`, `showProjectPreview`, `hideProjectPreview`, `onDeleteWorkflow`, `id="btn-open-project"` | EXISTS, gated | `fetch('/api/list…`; preview falls back to `fetch(\`rendered/${id}.bpmn\`)` | `431dc3f2` 2026-07-22 | value |
| Pending off-page refs ("ghosts") | `function openPendingRefModal`, `function createFromPendingRef`, `id="btn-pending-refs"`, `claim_ghost_after_save` | EXISTS, gated | Wired via `$('btn-pending-refs').onclick = openPendingRefModal`. Backing data `.context/designer/registry.yaml` — **2 ghosts, 4 claims, all `first_seen`/`ts` epoch values in the 1784.6–1784.7 M range, file mtime 2026-08-02, unchanged since** | `431dc3f2` 2026-07-22 | usage |
| Jump to referenced workflow | `async function jumpToWorkflow`, `function resolveWorkflowRef`, `function effectiveJumpTarget`, `refreshUuidIndex`, `_updateUuidIndex` | EXISTS, gated | uuid→project index built from `/api/list`; binds only when **exactly one** live map matches; never written back into `aef.targetWorkflow` (comment cites ratification T-225) | T-240 | value |
| Confirm dialog | `function confirmDialog` | EXISTS | Capture-phase keydown so it intercepts before modal Esc | — | structure |
| Toast | `function showToast`, `function showRestoredToast`, `function _startFresh` | EXISTS | Shared surface; comment records that before T-148 revert mislabelled itself | T-148 | friction |
| Gallery server (the API backend) | `tools/gallery-serve.py` (839 lines), `tools/serve-gallery.sh` | EXISTS, **not running** | Exposes `/api/health`, `/api/list`, `/api/versions`, `/api/version`, `/api/thumb`, `/api/save`, `/api/delete`. `serve-gallery.sh` copies `src/aef-workflow-designer.html` → `$OUT/designer.html` | — | structure |

### A7. The agent-facing seam (dual audience)

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Annotation seam v0 (inbound) | `window.addEventListener('message'`, `function aefApplyAnnotations`, `const AEF_ANNOTATION_TONES`, `const AEF_SEVERITY_TONE` | EXISTS | Accepts `aef:annotate` **only from `window.parent`**; renders read-only badge pills; never serialized (`buildBpmnXml` reads state, not DOM); unknown uids ignored silently | `de1f2ff9` 2026-07-27 | value |
| Ready handshake (outbound) | `function aefEmitReady`, `function _aefEmbedded` | EXISTS | Posts `{type:'aef:ready', version:1, workflow, uids}` with `targetOrigin '*'`; origin policy v0 recorded in-code with the tightening condition stated | 2026-07-27 | value |
| Two-identifier model | `function generateUid`, `computeDisplayId`, `computeEdgeDisplayId`, `refreshDisplayIds`, `displayIdOf` | EXISTS | uid = immutable contract, edges reference by uid; displayId = `<lane.abbr>_<seq>_<slug>`, never stored. `refreshDisplayIds` named by **33** external files; `computeDisplayId`/`displayIdOf` by 4 each | T-364 `652364f1` | value |
| Workflow-id sanitizer + validator | `function sanitizeWorkflowId`, `function isValidWorkflowId`, `function deriveSlug`, `deriveUniqueSlug` | EXISTS | Unified in `2eb10946` (T-562) after four sites disagreed; fallback is a **parameter**, not a constant, because `renameActiveWorkflow` must be able to refuse | `2eb10946` 2026-09-09 | value |
| Owner derivation from lane authority | `function ownerFromAuthority`, `const OWNER_FROM_AUTHORITY`, `const OWNER_BEARING_TYPES` | EXISTS | Read-only in the panel by design (T-197); mirrors `docs/standards/aef-bpmn-mapping-v1.md` §3 | — | value |
| Extension field vocabulary | `const AEF_FIELDS` (13 node types) | EXISTS | Field counts: serviceTask 12, subProcess 12, scriptTask 11, userTask 9, linkEventThrow/Catch 5 each, eventError/Timer/Message 5 each, startEvent 4, exclusiveGateway 4, endEvent 3, parallelGateway 1 | T-618 2026-09-09 | structure |
| Unlisted-key disclosure | `section('Extensions'`, T-566 commit `80f546d2` | EXISTS | Commit records **305 of 714 `aef:meta` values (42.7 %) across 14 keys sat outside `AEF_FIELDS`** before the fix | 2026-09-09 | value |
| Bare-catch-event neutral render | `function isBareCatchEvent`, `const LINK_BIND_FIELDS`, `const sessionAuthoredLinks` | EXISTS | Presentation-only; `sessionAuthoredLinks` intent is **deliberately session-scoped and non-serializable** — the reason (no dialect carrier) is recorded in 12 lines of in-code rationale | T-308 | value |
| Boundary events | `function boundaryHostOf`, `boundaryPerimeterPoint`, `boundaryOutwardPort`, `syncBoundaryPositions`, `AEF_FIELDS` `hostRef`/`boundaryPos`/`interrupting` | EXISTS | 3 of 4 externally exercised by `tools/_typed-events-cdp.mjs` | T-204 Slice 2 | value |
| Producer identity in emitted comment | `function readDocComment`, `function safeCommentData` | EXISTS | `c99f49f8` (T-406): gate the trailer on producer identity rather than inferring authorship from prose | — | value |

### A8. Settings dialog (editor-local preferences)

`id="settings-modal"` — **19 controls**, all `localStorage`-only, none entering the
document (stated at `id="btn-settings-reset"`'s sibling hint: "Stored in this browser
only — never in the workflow file").

| Group | Controls (ids) | Data point | Kind |
|---|---|---|---|
| Routing | `set-attach-middle`, `set-attach-spread`, `set-straighten-tol`, `set-channel-sep`, `set-routing-margin` | 5 controls → `aefRoutingPrefs` | value |
| Snapping | `set-snap-magnet`, `set-snap-grid`, `set-grid-size` | 3 → `aefSnapPrefs` | value |
| View | `set-row-spacing`, `set-col-spacing`, `set-branch-pitch`, `btn-apply-clean` (`id="view-apply-row"`), `set-clean-on-import` | 5 → `aefViewPrefs`. In-code comment records T-104 field report that these "did nothing" and the fix was to apply live | friction |
| Labels | `set-lane-fit`, `set-wrap-labels`, `set-label-size`, `set-show-lane`, `set-show-ids`, `set-show-edge`, `set-show-pool` | 7 → `aefLabelPrefs` | value |
| Reset | `btn-settings-reset` | 1 | value |

### A9. Keyboard surface (complete, mechanically enumerated)

Four `keydown` listeners exist (`function setMode`'s follower at the main handler,
the settings-modal capture handler, `_versionsEsc`, `_projectEsc`) plus two modal
`onKey` closures (`promptSaveNote`, `confirmDialog`) and a Space handler for pan.

| Binding | Anchor | Data point | Kind |
|---|---|---|---|
| `Delete` / `Backspace` | main keydown, `if (e.key === 'Delete' \|\| e.key === 'Backspace')` | Deletes node / multi-selection / edge / lane; lane delete with content prompts | value |
| `Escape` | same handler | Exits focus mode **and nothing else** when focus mode is on (rationale in-code, T-245); otherwise clears selection, cancels connect, resets to select mode | value |
| `Ctrl/Cmd+Z` | same handler | Undo; falls back to `undoTidy` when the stack is empty | value |
| `Ctrl/Cmd+Shift+Z` | same handler | Redo | value |
| `Ctrl/Cmd+Y` | same handler | Redo (Windows convention) | value |
| `Space` (hold) | `if (e.code !== 'Space') return; … panKeyHeld = true` | Arms pan; `preventDefault` so Space cannot page-scroll | value |
| `Ctrl+wheel` | `canvasWrap.addEventListener('wheel'` | Zoom at cursor | value |
| `Enter` / `Esc` in field editors | `inp.addEventListener('keydown'` inside `function field` | Enter commits (non-textarea only) | value |
| `Esc` in settings / versions / project / pending-ref / save-note / confirm | `$('settings-modal')` capture handler, `_versionsEsc`, `_projectEsc`, `onKey` ×2 | 6 independent Esc paths, two of which use capture phase specifically to order themselves | structure |

**There is no keyboard shortcut for: save, load, XML view, clean layout, zoom
in/out/fit, focus mode, new workflow, copy, or duplicate.** Verified by enumerating
every `e.key`/`e.code` comparison in the file — the list above is exhaustive.

### A10. Validation surfaces

| Item | Source | Status | Data point | Kind |
|---|---|---|---|---|
| Workflow-id validation | `function isValidWorkflowId` (`/^[a-z0-9][a-z0-9_-]*$/`) | EXISTS | The **only** hard rejection in the product; save-time | value |
| Import repair advisory | `function maybeShowLaneFixNotice` | EXISTS | Advisory only, never blocks | value |
| Messiness heuristic | `function mapMessiness` | EXISTS | Advisory only | friction |
| Parse failure | `alert('Failed to parse workflow file:…')` | EXISTS | Modal alert, no structured error surface | friction |
| **Schema validation inside the editor** | — | **ABSENT** | `grep -icE "valid(ate\|ation\|ator)"` over the product returns 11 hits, **every one of which is a comment or an id-validator reference**. There is no `btn-validate`, no error list panel, no per-node error decoration. The validator is an external CLI: `tools/validate-workflow.py` | structure |
| **YAML surface** | — | **ABSENT in the product** | `grep -ci yaml` = 14 hits in the product; all 14 are comments or `.yaml` path strings inside the seed map's `contextReads`/`artifactsWrites` demo data. The product reads and writes **BPMN XML only**. `README.md` line 4 states "**YAML is canonical; BPMN XML is a derived import/export format**" — recorded side by side with the measurement, not reconciled | structure |

---

## B. Reverse map — capability / value driver → items that serve it

Yardstick capabilities: authoring surface · import/export fidelity · BPMN-subset
schema · render/round-trip contract · release path.
Value drivers (`policy/value-drivers.yaml` v3): **D1** Antifragility 9 · **D2**
Reliability 7 · **F-RECALL** 6 · **D3** Usability 5 · **D4** Portability 3.

| Capability / driver | Items serving it | Count | Note |
|---|---|---|---|
| **Authoring surface** | A2 (all 15), A3 (all 11), A8 (19 controls), A9 (9 bindings) | ~54 | Densest area of the product by far |
| **Import/export fidelity** | `parseBpmnXml`, `buildBpmnXml`, `aefExtensionXml`, `escAttr`/`escText`, `carriedKeys`/`metaKeys`, `foreignTag`, `documentation`, `laneProvenance`, DI import + emission, `readDocComment`/`safeCommentData` | 12 | Every one of the 10 most recent `src/` commits lands here |
| **BPMN-subset schema** | `NODE_DEFAULTS` (13 types), `AEF_FIELDS` (13 entries), `LINK_BIND_FIELDS`, `OWNER_FROM_AUTHORITY`, `defaultLanes`, `isBareCatchEvent`, typed-event binding fields | 7 | |
| **Render/round-trip contract** | `computeEdgeGeometry`, `refreshDisplayIds`/`computeDisplayId`/`displayIdOf`, `generateUid`, `sanitizeWorkflowId`/`isValidWorkflowId`, `captureThumbnail`, routing engine (16 fns), label engine (7 fns) | ~29 | |
| **Release path** | `scripts/release-designer.sh`, `VERSION` (0.12.0), `dist/` (12 artefacts), `dist/MANIFEST.yaml` | 4 | **Outside** the product file; the product itself carries no version string I could locate |
| **D1 Antifragility (9)** | `laneProvenance` (records without deciding), `sessionAuthoredLinks` (refuses to invent a carrier), `foreignTag`/unknown-key carriage (unknown input survives), `_suppressDeepLink` (autosave vs deep-link precedence), `window.addEventListener('blur')` pan reset, every `catch (_) { /* seam must never break the editor */ }` in the annotation seam | 6 clusters | The **highest-weighted driver**; served largely by *restraint* mechanisms rather than features |
| **D2 Reliability (7)** | Autosave, undo/redo (`_HISTORY_CAP = 50`), versioned Save-to-project, `escAttr` whitespace escaping, `isValidWorkflowId`, DI/position dual carrier, `confirmDialog`, thumbnail annotation-stripping | 8 | |
| **F-RECALL (6)** | "Recently opened" section, `map-saved-version` badge, Versions browser, autosave restore toast, save notes (`promptSaveNote`), Open-project browser + preview, `jumpToWorkflow` | 7 | |
| **D3 Usability (5)** | Clean layout + nudge, snap, zoom/pan, focus mode, panel toggles, drag-to-place, label fitting, settings dialog, tooltips on every toolbar button, lane-fix notice, toast | 11 | |
| **D4 Portability (3)** | Single-file + no-build delivery, no external `<script src>`, `postMessage` seam with stated origin policy, BPMN 2.0 + `bpmndi` standard output, `dist/` byte-pinned artefacts | 5 | Lowest-weighted driver, and the **premise** of the whole file-shape decision |

### Gaps — capability/driver surfaces with **nothing in the product serving them**

Recorded as gaps, **not classified**:

1. **In-editor schema validation → nothing.** The yardstick names "schema-validated
   YAML" as the agent-side promise and `README.md` §Status names "schema validation
   tooling for produced workflow files" as the *next planned slice* (README last
   commit `61242508`, 2026-06-05 — **107 days ago**). The validator exists only as
   `tools/validate-workflow.py`, outside the product. A human drawing in the editor
   gets no schema verdict. **DESIGNED-ONLY** as an in-product surface.
2. **YAML read/write → nothing in the product.** See A10. The README's canonical-form
   claim and the product's actual I/O disagree; both recorded.
3. **Execution / run feedback → nothing.** The annotation seam is the *only* channel
   for execution state and it is **inbound-only from an embedding parent**. There is
   no `fw workflow run` (`00-yardstick.md` records this as established by T-740).
   Consistent with README's "usable today without the planned `fw workflow run`".
4. **Product version display → nothing.** `VERSION` is 0.12.0 but no version string
   renders anywhere in the UI. The T-158 comment records that the "bare `v1`
   contract-version badge" was *deliberately removed*; the `map-saved-version` badge
   that replaced it shows the **map's** snapshot, not the **build's** version. Effect:
   an operator on `/designer/app` has no in-product signal that they are on 0.8.0.
   This is the item that makes SERVED-GAP invisible from inside the product.
5. **Error/telemetry surface → nothing.** Parse failure is an `alert()`; clipboard
   failure, autosave quota failure and annotation-seam failures are all swallowed by
   bare `catch (_)`. No counter, no log, no `console.warn` path an operator would see.
   This is the structural reason every item here is **UNMEASURED**.
6. **F-RECALL beyond the current session/host → nothing in the product.** Everything
   under F-RECALL depends on either `localStorage` (this browser only) or `/api/*`
   (a server that is not running). With the gallery server down, F-RECALL-serving
   items collapse to autosave + "Recently opened".

---

## C. Unreachable / orphaned inside the file

Mechanically derived; **10 functions have zero call-sites AND zero bare references**
anywhere in the 997 KB file:

| Function | Call-sites | Refs | External refs (tools/tests/scripts) | Reading |
|---|---|---|---|---|
| `clearWaypoints` | 0 | 0 | none | Waypoint model is live; this clearer is not reached |
| `onAddWaypointMouseDown` | 0 | 0 | none | Sibling handlers `onWaypointMouseDown`/`onSegmentMouseDown` ARE wired |
| `currentRenderedMiddleCorners` | 0 | 0 | none | Named in `.tasks/completed/T-477-…`, `docs/reports/T-357-di-adoption.md` |
| `findNodeByUid` | 0 | 0 | none | Named in `.tasks/completed/T-364-export-is-nondeterministic…` |
| `findNodeByDisplayId` | 0 | 0 | none | |
| `generateNodeId` | 0 | 0 | none | `generateUid` is the live id path |
| `midOfPath` | 0 | 0 | none | `midOfPolyline` likewise |
| `midOfPolyline` | 0 | 0 | none | |
| `nodeSideForExitDir` | 0 | 0 | none | `nodeSideLength`, `exitDirection` ARE called |
| `portPoint` | 0 | 0 | `tools/_typed-events-cdp.mjs` | **`portPointAt` and `portPointTowards` are live; `portPoint` is not.** Named in `.context/episodic/T-070.yaml` and two completed task files |

Every one of the ten also appears in `vendor/designer/aef-workflow-designer-0.8.0.html`
and in `docs/designer/aef-workflow-designer-complete.md` — i.e. they were already
unreferenced at the 0.8.0 cut, which is the build being served.

**Zero call-sites but correctly wired as handler references** (NOT orphans — listed
so the count above is not misread): `openSettings`, `openPendingRefModal`,
`onPoolResizeMouseDown`, `_versionsEsc`, `_projectEsc`, `_startFresh`, `autosaveNow`,
and the two local `onKey` closures.

**Inert body, live callers** (a distinct shape from the above):
`refreshLibraryUI` — 8 call-sites, all reaching `if (!picker) return;` for an element
`id="workflow-picker"` that does not exist in the file. See A6.

**Deliberately unreachable, recorded as such by its own commit:** the `else` arm of
the `DI_TRAILER` conditional — `389133c8` states "THE TRAILER'S else IS NOW
UNREACHABLE, with AEF's ruling behind it".

**Retired UI whose functions are retained on purpose:** the standalone
`⁙ Align columns` and `↔ Distribute evenly` buttons (T-139 comment). The four
functions are live via Clean and via `tools/_align-distribute-diag.mjs`.

---

## D. Referenced from OUTSIDE the file

- **88 of 247** functions are named by at least one file under `tools/`, `tests/`,
  `scripts/` (93 raw hits minus 5 English-word false positives: `done`, `text`,
  `field`, `section`, `el`). **159 functions are named by nothing outside the file.**
- Heaviest external dependence: `buildBpmnXml` (64 files), `parseBpmnXml` (62),
  `refreshDisplayIds` (33), `renderAll` (21), `adoptImportedXml` (16), `escAttr` (13),
  `undo` (13), `renderProperties` (10).
- **Fabric cross-check:** `grep -rl aef-workflow-designer.html .fabric/components/`
  → **118 cards**, matching the yardstick's count exactly. The anchor card
  `.fabric/components/src-aef-workflow-designer.yaml` lists `depends_on: []` and a
  `depended_by` list of **~190 entries** across three relation types (`reads`,
  `called_by`, `read_by`) that substantially duplicate each other — e.g.
  `tests/test_release_immutability.py` appears under all three. Card fields:
  `last_verified: 2026-09-03`, `created_by: T-671`, `last_enriched: '2026-09-16'`.
  Its `purpose` says "**112 tracked files reference it**" while the live grep says
  **118 cards** — **conflicting counts recorded side by side, not reconciled**; they
  may be counting different denominators (cards vs tracked files).
- **Ghost registry** `.context/designer/registry.yaml`: 2 ghosts (`review-map`
  kind `name-only` T-291; `future-map` kind `uuid-pinned` T-292) and 4 claims, all
  `via: ui`, project names `claim-smoke-target`, `claim-smoke-target2`,
  `aef-task-lifecycle`, `claim-smoke-legacy` — three of four are *smoke-test* names.
  File mtime 2026-08-02; no entry has been added since. This is the **only
  use-shaped record of any kind** I found anywhere for any product feature, and it
  records 4 events, 3 of them tests.
- **Consumed by the release path:** `scripts/release-designer.sh` reads `src/` and
  writes `dist/aef-workflow-designer-$VERSION.html`; `tools/serve-gallery.sh:59`
  copies `src/` → `$OUT/designer.html`.

---

## E. Non-use diagnosis evidence (A–E collected, NOT selected)

Per the leg's instruction, for each low/no-observed-use item I record the evidence
that separates the readings. **I do not pick one.**

### E1. Every item in this inventory: D UNMEASURED
There is no instrumentation on any product path. No counter, no event log, no
`console` breadcrumb, no server-side access log for the editor (the gallery server
that would produce one is not running). `grep` over the product for any telemetry
emission returns nothing beyond the `postMessage` seam, which reports *structure*
(uid list) not *use*. **This applies to all ~90 items above without exception** and
is the dominant reading available from this repo.

### E2. The ten zero-reference functions (§C)
- **A BROKEN:** no evidence. They are never exercised, so nothing can fail.
- **B NEVER WIRED:** *positive evidence.* Zero references in a 997 KB file that
  otherwise wires every handler explicitly. `onAddWaypointMouseDown` is the strongest
  case — its siblings `onWaypointMouseDown`, `onSegmentMouseDown`,
  `onLoopDetourMouseDown`, `onEndpointMouseDown` are all wired. Origin-task intent:
  `portPoint` is named in `.context/episodic/T-070.yaml` and
  `.tasks/completed/T-168-connection-point-anchoring-attach-edges-.md`;
  `currentRenderedMiddleCorners` in `.tasks/completed/T-477-…` and
  `docs/reports/T-357-di-adoption.md`; `findNodeByUid` in
  `.tasks/completed/T-364-export-is-nondeterministic-for-any-node-.md`.
- **C UNDISCOVERABLE:** n/a (not operator-facing).
- **D UNMEASURED:** applies.
- **E NOT WANTED:** no positive recorded reason found for any of the ten.

### E3. `refreshLibraryUI` (inert body, 8 live callers)
- **B NEVER WIRED / re-wired away:** *positive evidence with a recorded reason.* The
  T-154 comment states the `<select>` was replaced by `id="btn-open-project"` as "one
  unified full-corpus entry point, no half-populated dropdown". So the **element**
  removal is recorded as intentional (reading **E** for the dropdown); the **eight
  surviving no-op call-sites** are not addressed by that comment (reading **B** for
  the residue). Both recorded.

### E4. Server-backed items — Save to project, Versions, Open project, Pending refs, Jump
- **A BROKEN:** no evidence from here. Each has a dedicated CDP probe
  (`tools/_saveproject-verify-cdp.mjs`, `_versions-verify-cdp.mjs`,
  `_t233-ghost-cards-cdp.mjs`, `_t263/_t264-save-target*-cdp.mjs`,
  `_editor-behavior-verify-cdp.mjs`); **I did not run them** (pass state is another
  gatherer's leg; `00-yardstick.md` records it as open data gap DG-8).
- **B NEVER WIRED:** contradicted — all five are wired (`$('btn-save-project').onclick
  = saveToProject` etc.).
- **C UNDISCOVERABLE:** *positive evidence.* All four buttons ship
  `style="display:none"` and are revealed only by `detectSaveApi()`. With no gallery
  server running they are invisible. **And** they appear in **neither** `README.md`
  **nor** `docs/designer/user-guide.md` (see E6).
- **D UNMEASURED:** applies. The ghost registry's 4 entries (3 smoke-named) are the
  only trace of any of these paths ever firing, and the file has not changed since
  2026-08-02.
- **E NOT WANTED:** no positive recorded reason found.

### E5. The ten most recent shipped features (T-566, T-570, T-589, T-598, T-600, T-602, T-603, T-618, T-423, T-690)
- **C UNDISCOVERABLE — strongest available evidence:** all ten are **absent from the
  bytes served at `/designer/app`** (marker census, §top). An operator using the
  served surface cannot discover them because they are not there.
- **A BROKEN:** no evidence; each shipped with a probe named in its commit.
- **D UNMEASURED:** applies.

### E6. Documentation reachability (bears on C for most of the product)
`docs/designer/` last commit `fd6f26a5`, **2026-07-04**; all six files have mtime
2026-08-02. `README.md` last commit `61242508`, **2026-06-05**. `src/` has taken
**25 commits since 2026-08-02** and 144 in total.

`grep -ci` over `docs/designer/user-guide.md` and `README.md`:

| Feature | user-guide | README |
|---|---|---|
| Open project | 0 | 0 |
| Versions | 0 | 0 |
| Save to project | 0 | 0 |
| Pending refs | 0 | 0 |
| Settings (dialog) | 0 | 0 |
| focus mode | 0 | 0 |
| zoom | 0 | 0 |
| Clean layout | 0 | 0 |
| annotation (seam) | 0 | 0 |
| autosave | 0 | 0 |
| determinism | 0 | 0 |
| note (field) | 0 | 0 |
| subProcess | 0 | 0 |
| Timer (typed event) | 0 | 0 |
| Undo | 1 | 0 |
| boundary | 1 | 0 |

The user-guide's §8 "Saving and exporting" covers exactly four things: 8.1 Save
(download), 8.2 Load (open from file), 8.3 The library, 8.4 View XML, 8.5 What's
serialized. §8.3 documents "The library" — the surface whose renderer is inert (§C).
`README.md` §Using it says in full: "State is in-memory; **Save** downloads a `.bpmn`
file." **Reading C applies to roughly everything in A6, A7, A8 and half of A3.**

**Counter-evidence against C, recorded alongside:** in-product discoverability is
high. Every toolbar button carries a `title=` tooltip, several of them multi-clause
(e.g. `id="btn-clean"` → "Tidy + branch pitch + align rows on every lane — one
click, Ctrl+Z reverts"); the palette carries a `palette-hint` block explaining
click-to-place, drag-to-place, Connect mode and Add Lane; the properties empty-state
and `section('Tips'` both restate the core interactions; settings rows carry
`settings-hint` spans. A feature absent from the docs is not necessarily absent from
the UI. **Both recorded; not reconciled.**

### E7. INTENT evidence (collected independently, per instruction)

| Intent signal | Evidence |
|---|---|
| **Maps to a value driver** | `defaultLanes()`'s three lanes are the AEF authority model verbatim (sovereignty/authority/initiative); `ownerFromAuthority` mirrors `docs/standards/aef-bpmn-mapping-v1.md` §3 — the product's data model is a direct projection of the governance model |
| **Referenced by a ratified workflow** | `aefExtensionXml` is read by `tools/yaml-to-bpmn.py` and `tests/test_bridge_aef_passthrough.py`; `parseBpmnXml`/`buildBpmnXml` by 62/64 external files; `examples/aef-processes/rendered/` is a seam artefact a consumer pins. In-code comments cite ratifications at T-225, T-250 IW-3, T-258, T-261, T-340 (PD-200), T-521 |
| **Workarounds exist** | *Positive, and recorded by the product's own commit messages.* `80f546d2` (T-566): 001-CashWeb "stopped waiting and built a parallel read surface on the /file/ seam — making the Designer canvas the ONE place their content could not be read." That is a consumer building around the product |
| **Docs promise it** | `README.md` promises YAML-canonical (A10: absent in product) and schema-validation-next (absent in product). `docs/designer/user-guide.md` documents "The library" (§8.3) whose renderer is inert (§C). Three documented promises with no live product surface |
| **Peers filed defects against it** | T-566 records reports from **999-AEF** (their T-2974 defect 1) and **001-CashWeb** (their T-064, 27 nodes); T-355 a callActivity mis-render; T-240 an AEF field observation (their T-2611); T-602 a field-reported data loss. At least **five independent consumer-originated defect reports** are recorded in `src/` commit messages — evidence of the product being *exercised by someone*, which no telemetry in this repo can show |

---

## F. Sources I expected and did not find

| Expected | Result |
|---|---|
| Per-item coverage data | **ABSENT** — no `.coveragerc`, `.nycrc*` or `coverage*` config file at depth ≤2, and no `.cfg`/`.toml`/`.ini`/`.json` in the tree (excluding `.agentic-framework/`) naming coverage except `.context/working/rail-snapshot.json`, which is a framework rail snapshot, not code coverage. The word "coverage" does occur in `tools/_t484-coverage-list-behaviour-audit.py`, `_t525-fabric-coverage-teeth.py`, `_t549-fabric-coverage-mutation-teeth.py` and `tests/test_editor_bridge_field_coverage.py` — those are **fabric-card and field-vocabulary** coverage, not line/branch coverage of the product. Confirms the yardstick's "expected ABSENT" |
| Any usage counter/log on any product path | **ABSENT** — confirmed by reading; all failure paths are bare `catch (_)` |
| A version string rendered in the product UI | **ABSENT** — see gap 4 |
| An in-product schema-validation surface | **ABSENT** — see gap 1 |
| A YAML read/write path in the product | **ABSENT** — see gap 2 |
| A running gallery server (`/api/*`) | **ABSENT on this host** — `pgrep -af gallery-serve` no match; port 8080 is open-webui |
| `docs/designer/` describing post-July features | **ABSENT** — frozen at 2026-07-04 while `src/` took 25 more commits |

## G. Counts, for the JUDGE's arithmetic

- Items inventoried in §A: **93** (A1 11, A2 15, A3 11, A4 11, A5 12, A6 14, A7 10,
  A8 5 groups / 19 controls, A9 9, A10 6 — settings counted as 5 group rows).
- Node types: 13. Properties sections: 13. Settings controls: 19. `localStorage`
  keys: 5. Keyboard bindings: 9. `/api/*` endpoints consumed: 7. SVG layers: 7.
- Functions: 247 unique / 248 declarations. Zero-reference: **10**. Externally
  named: **88**. Named by nothing outside the file: **159**.
- Gaps recorded (capability/driver with nothing serving it): **6**.
