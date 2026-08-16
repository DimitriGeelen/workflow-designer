---
id: T-204
name: "Typed BPMN event palette: error/timer/message + boundary events (two-slice
  build)"
description: >
  Build authorized by T-190 GO (inception, firm post Spike-1+2). Add typed BPMN events
  to the designer palette using the aef:-extension encoding (IW-1): a BPMN event tag
  + aef:eventDef marker (kind=error|timer|message + binding: status:issues / cron
  / bus-topic), riding the tested aef:/x- round-trip channel — NO native bpmn:*EventDefinition
  machinery required. Two slices under one task (IW-3): Slice 1 = non-boundary error/timer/message
  (palette entry + subtype + aef: serialization in buildBpmnXml + bridge parity in
  yaml-to-bpmn.py + mapping-standard row + DI render); Slice 2 = boundary variants
  (host binding as additive aef field hostRef+boundaryPos+interrupting per scopeOf/constituents
  precedent T-081; host-follow via groupDrag ~5493; boundary-origin edges via T-168
  ports; host-relative render branch in renderNodes ~2354). Target carrier: T-081
  collapsed-subProcess (G-3). Guards T-187/T-188 round-trip + T-202 export-contract
  must stay green.

status: work-completed
workflow_type: build
owner: human
horizon:
tags: [typed-events, editor, bridge, aef, arc, feature]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-18T19:42:25Z
last_update: '2026-08-16T14:33:20Z'
date_finished: 2026-07-19T19:27:19Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:20Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 3
      F3: 4
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=3 
      (prose:routing-defect-class); F3=4 (prose:seam-fixture-or-pin); F1=0 
      (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 9
    rationale: blast_radius=9 
      (paths:docs/reports/T-190-typed-event-palette-inception.md,docs/standards/aef-bpmn-forward-compile-v1.md,docs/standards/aef-bpmn-mapping-v1.md,src/aef-workflow-designer.html);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-204: Typed BPMN event palette: error/timer/message + boundary events (two-slice build)

## Context

Authorized by T-190 GO (see `docs/reports/T-190-typed-event-palette-inception.md`).
Design: `aef:`-extension encoding (IW-1) — BPMN event tag + `<aef:eventDef>` marker; NO
native `bpmn:*EventDefinition`. Mirror the existing `linkEvent*` pattern end-to-end.

### Slice 1 anchor map (src/aef-workflow-designer.html — verified 2026-07-18, pre-edit)
New node types `eventError` / `eventTimer` / `eventMessage`, added at every site where
`linkEventThrow`/`linkEventCatch` appear:

| Site | line(s) | change |
|---|---|---|
| Palette HTML | 1109–1205 (`linkEventThrow`/`Catch` at 1193/1205) | 3 `.palette-item data-create="eventError\|eventTimer\|eventMessage"` |
| Node dims | 1608–1618 (`linkEvent*` 1617/1618) | `{ w:36, h:36, lane:'framework' }` each |
| Field defs (per-type aef fields) | 1626–1638 (`linkEvent*` 1637/1638 = `['targetWorkflow','linkId']`) | error→binding `status:issues`; timer→cron/`horizon`; message→bus topic |
| Field META (label/hint) | ~1665–1666 | new field labels/hints for the eventDef fields |
| Ports in/out | 1686–1696 (`linkEvent*` 1695/1696) | in/out flags |
| Render branch | 2380–2397 (`linkEvent*` branch) | draw glyph; add types to event `ly`/`isBelow` at 2397/2459/2564/3645 |
| Icon SVG | 5004–5011 (`linkEvent*` 5010/5011) | error ▲/⚡, timer ⏱, message ✉ |
| **TYPE_TAG** | 7894–7910 (`linkEvent*` 7906/7907) | map new types → BPMN tag |
| **aefExtensionXml** | 7912–8001; `aef:link` emit at 7944–7948 | add `<aef:eventDef kind="…" binding="…"/>` branch (mirror aef:link) |
| **buildBpmnXml** | 8005; tag via `TYPE_TAG[n.type]` at 8053; aef via `aefExtensionXml(n)` at 8060 | no change beyond TYPE_TAG/aefExtensionXml |
| **REVERSE_TYPE** (import) | built 8185 from TYPE_TAG | ⚠ COLLISION: if error/timer/message share a BPMN tag (e.g. all `intermediateCatchEvent`, which also = `linkEventCatch`), `REVERSE_TYPE[tag]` can't disambiguate — import MUST read `aef:eventDef.kind` to pick the type (same override linkEvent needs vs a plain intermediate event). |
| **Import parser** | `adoptImportedXml` at 7779 | parse `<aef:eventDef>` back → set node.type from kind + restore fields (round-trip) |

### Key design decisions to lock at build time
1. **BPMN tag per type:** non-boundary error/timer/message → likely all `bpmn:intermediateCatchEvent` (neutral "event in flow"), type carried by `aef:eventDef.kind`. Because that tag already maps to `linkEventCatch`, the import path must branch on extension content (`aef:link` → linkEventCatch; `aef:eventDef` → typed event). Confirm against REVERSE_TYPE(8185)+adoptImportedXml(7779) before editing.
2. **Bridge (`tools/yaml-to-bpmn.py`):** confirm whether `aef.eventDef` is added as known vocabulary (dedicated element) or rides `aef.x-*` passthrough (T-061 guarantees x- round-trips; bare unknown drops LOUDLY). Read the bridge first — AC says "rides the aef:/x- channel."
3. **Round-trip test:** export→import→export byte-stable for eventDef fields; assert `<aef:eventDef>` present. New `tests/test_designer_typed_events.py` (or extend `test_designer_export_contract.py`).

### Build order (each a commit + check-in)
1. Data path: TYPE_TAG + aefExtensionXml eventDef + import parse + round-trip test (green) — load-bearing core.
2. Registry + palette + render glyphs + icons (visual).
3. Bridge parity + mapping-standard rows.
4. Visual verification (Playwright element screenshots, all modes) → tick Human AC.

## Acceptance Criteria

### Agent

**Slice 1 — non-boundary error / timer / message**
- [x] Palette gains three typed-event entries (error / timer / message). Placing one creates a BPMN event node carrying an `aef:eventDef` extension marker (`kind` ∈ `error|timer|message`) plus its AEF binding (error→`status:issues`, timer→cron/`horizon`, message→bus topic). No native `bpmn:*EventDefinition` is emitted as the primary encoding (IW-1: aef:-extension shape). <!-- step 2: palette section + dims/fields/ports/render/icons/defaultName; placement verified via Playwright (docs/reports/T-204-slice1-visual/) -->
- [x] `buildBpmnXml(state)` serializes each typed event as `<bpmn:*Event>` + `<extensionElements><aef:eventDef …/></>`; the editor re-imports losslessly (export→import→export is stable for the eventDef fields). <!-- step 1 data path; proven by tests/test_typed_events.py (correctness+BITE) + round-trip fixed point -->

- [x] `tools/yaml-to-bpmn.py` bridge parity: `aef:eventDef` fields ride the `aef:`/`x-` passthrough channel per the T-061 contract (bare unknown still drops loudly). Existing `tests/test_bridge_aef_passthrough.py` stays green + a new assertion covers `eventDef`. <!-- step 3: TYPE_MAP + EVENT_KIND/EVENT_BINDING_FIELD + <aef:eventDef> emit branch (keyed on node type) + binding scalars in KNOWN_AEF_KEYS; new check_eventdef() asserts all 3 kinds; full bridge suite 34/0 -->
- [x] One mapping-standard row per typed event added on the T-081 collapsed-subProcess carrier (editor and forward-compiler agree). <!-- step 3: row added to BOTH docs/standards/aef-bpmn-mapping-v1.md §3 (editor-side) AND docs/standards/aef-bpmn-forward-compile-v1.md §3.1 (compiler-side), each enumerating error/timer/message + bindings; conformance test green. See Evolution for the "one family row" interpretation. -->


**Slice 2 — boundary variants**
- [x] A typed event attaches to a host node's boundary via an additive `aef` field set (`hostRef` uid + `boundaryPos` + `interrupting`), serialized as `<bpmn:boundaryEvent attachedToRef=…>` + `aef:eventDef`, round-tripping losslessly (reuses the `aef:scopeOf`/`aef:constituents` node→node ref precedent, T-081). <!-- step 1 data path: export tag/attrs (boundaryEvent + attachedToRef + cancelActivity) + boundaryPos presentational element + inspector fields (hostRef/boundaryPos/interrupting) + import (nodeTags + attachedToRef→hostRef post-pass resolution). Proven by boundary-events.bpmn round-trip (7 nodes, byte-idempotent, hostRef/interrupting teeth in proj) + boundary correctness+BITE in _typed-events-cdp.mjs (real boundaryEvent tag + both cancelActivity values). -->
<!-- step 1 also gives an authoring surface (inspector text/select fields) so a boundary event is human-authorable before the drag UX in step 3. -->

<!-- Remaining Slice-2 sub-parts (host-follow drag, boundary-origin ports, host-relative render) below are steps 2-3. -->

- [x] Host-follow: moving a host moves its boundary events (reuses `groupDrag` ~5493); a boundary-origin edge anchors via the T-168 port machinery. <!-- DONE (both halves). Host-follow ✓ — delivered for FREE by the step-2 render-sync: both the single-node drag (renderNodes at ~5639) and groupDrag (~5662) call renderNodes() every frame, and renderNodes()→syncBoundaryPositions() re-derives each boundary event's x/y from host.x. Confirmed via Playwright: shifting the host by (+180,+40) moved BOTH boundary events by exactly (+180,+40). PORT HALF ✓ (step 3) — boundaryOutwardPort(node,host) returns the host-edge outward NORMAL (N/E/S/W) derived from the SAME boundaryPos perimeter walk as boundaryPerimeterPoint (deterministic; a centre-to-centre heuristic ties and picks the wrong axis at corners). renderEdges pins a boundary-origin edge's source anchor to that port (auto source only — an explicit pin still wins) via a local srcPortEff, threaded through anchor + exitDirection + straighten-skip. So the edge EXITS the perimeter away from the host body instead of the default centre-toward-target anchor that can cross the host — proven on the hard case (n_btmr, a TOP-edge boundary whose handler is BELOW: exits N and routes AROUND, not down through the host). Also fixed a latent one-frame bug: renderAll runs renderEdges BEFORE renderNodes, so syncBoundaryPositions was hoisted to renderAll ahead of renderEdges (kept in renderNodes too for the drag path). Teeth: new PORT_ASSERT_EXPR in _typed-events-cdp.mjs asserts source-anchor==outward-port AND polyline-never-crosses-host for both boundary edges. Visual: docs/reports/T-204-slice2-visual/boundary-ports.png. Optional refinement NOT done: drag-a-boundary-event-along-the-perimeter to set boundaryPos (still a text field) + boundary-label placement polish — de-scoped to follow-ups (see Evolution). -->

- [x] Boundary event renders at a host-relative perimeter point (contained new branch in `renderNodes` ~2354), not at free `x/y`. <!-- step 2: syncBoundaryPositions() derives each attached event's x/y from boundaryPerimeterPoint(host, boundaryPos) at the top of renderNodes (default bottom-centre); the typed-event render branch adds the BPMN double ring (dashed outer ring = non-interrupting). Visually verified — docs/reports/T-204-slice2-visual/boundary-on-host.png: error event straddles the host bottom edge (solid double ring), timer straddles the top edge (dashed outer ring); both host-relative. Known cosmetic follow-up: boundary-event LABELS can overlap the host label (intrinsic to boundary/host overlap) — placement polish, not a functional defect. -->
      <!-- Note: because position is host-derived, a boundary event is pinned to its host (can't be dragged free) — correct BPMN behaviour; sliding it along the perimeter (edit boundaryPos by drag) is a step-3 refinement. -->


**Guards (both slices)**
- [x] Round-trip guards T-187/T-188, export-contract T-202, and render gate `tests/test_designer_render.py` all stay green; a new test asserts the typed-event export→import→export round-trip and the `aef:eventDef` serialization. <!-- verified post step-2: render gate PASS, export-contract PASS, round-trip fixed point PASS, full bridge suite 34/0, test_typed_events.py PASS -->


### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->
- [x] [REVIEW] Typed-event nodes render correctly in the served designer across visual modes.
  **Steps:**
  1. Open the designer at the served URL (see `.context/working/watchtower.url`), place an error, timer, and message event from the palette, and (Slice 2) attach an error event to a serviceTask host.
  2. Inspect element-level screenshots in each affected mode (mono/sans/serif fonts; light/dark themes; compact/normal densities).
  **Expected:** each typed event has a distinct, legible glyph; the boundary event sits on the host perimeter and follows the host on drag; no overlap/regression versus plain events.
  **If not:** screenshot the failing mode and note which glyph/placement is wrong.

## Recommendation

**Recommendation:** GO

**Rationale:** Both slices are agent-complete — all 8 agent ACs + the guards AC are
checked and independently verified. Typed error/timer/message events serialize via the
`aef:eventDef` extension (no native `bpmn:*EventDefinition`), round-trip losslessly, and
bridge-parity holds; boundary variants attach as native `<bpmn:boundaryEvent>`, render on
the host perimeter with the BPMN double ring, follow the host on drag, and their outgoing
edges now exit the perimeter outward via the T-168 port machinery (never crossing the host
body). The only open item is the `[REVIEW]` Human AC, which is genuine human taste on the
served release (glyph legibility + boundary placement) — not something the agent can self-
certify. Nothing blocks GO; the agent-verifiable surface is fully green.

**Evidence:**
- Guards 5/5 green (P-011): `test_designer_render`, `test_designer_export_contract`,
  `test_bridge_aef_passthrough`, `test_roundtrip_serialization`, `test_typed_events`
  (typed + boundary correctness + BITE + port-anchoring assertions).
- Round-trip fixed point across all `tests/fixtures/aef-bpmn/*.bpmn` incl.
  `boundary-events.bpmn` (byte-idempotent; `hostRef`/`interrupting` teeth in the projection).
- Port anchoring proven in-editor: source anchor == outward port AND routed polyline never
  crosses the host body for both boundary edges, incl. the hard top-edge case
  (`PORT_ASSERT_EXPR` in `tools/_typed-events-cdp.mjs`).
- Visual evidence read + saved: `docs/reports/T-204-slice1-visual/` (glyphs, palette,
  inspector) and `docs/reports/T-204-slice2-visual/` (`boundary-on-host.png`,
  `boundary-ports.png`).
- Commits: `e8d611e` (data path), `ef25739` (host-relative render), `49ed247` (host-follow),
  `4f2029b` (T-168 ports). All pushed to the ssh remote.

## Visual Verification

### 2026-07-19 — Slice 1 step 2 (visual surface)

Served `src/aef-workflow-designer.html` over local HTTP (single-file app), drove headless
Chrome via Playwright, placed all three typed events on a clean canvas, and READ each
rendered screenshot. Designer is **dark-theme-only** (`:root` defines a single palette; no
light/serif/density variants exist in this app), so the applicable visual-mode axis is
**label size (s/m/l)** — all captured. Element-level screenshots (not full-viewport zoom-out):

- `docs/reports/T-204-slice1-visual/canvas-default.png` — canvas, default label size:
  Error = red circle + filled lightning bolt; Timer = blue circle + clock face/hands;
  Message = green circle + envelope. All three glyphs distinct, legible, correctly coloured
  from the theme vars (`--red`/`--blue`/`--green`). Labels + derived display IDs correct.
- `docs/reports/T-204-slice1-visual/canvas-labelsize-s.png` — label size `s`: no glyph/label
  collision, no regression.
- `docs/reports/T-204-slice1-visual/canvas-labelsize-l.png` — label size `l`: labels larger,
  still clear of glyphs and id-badges; no regression.
- `docs/reports/T-204-slice1-visual/palette-typed-events.png` — the new **TYPED EVENTS**
  palette section: three items (Error/on status:issues, Timer/cron·horizon, Message/on bus
  topic), each with its distinct glyph at palette size.
- `docs/reports/T-204-slice1-visual/full-palette-inspector.png` — full app: palette (left,
  Typed events section disambiguated from the Start/End "Events" section), canvas (three
  events), and inspector (right) for the selected `eventMessage` showing the envelope badge
  icon (typeBadgeSvg) + the **EXTENSIONS · AEF: "Bus topic"** binding field — confirms
  `AEF_FIELDS`/`FIELD_META` wired end-to-end.

Symptom-free: each typed event has a distinct legible glyph; no overlap/regression vs plain
events. (The `[REVIEW]` Human AC below still requires the human's own confirmation on the
served release — these are the agent's own pre-commit verification per §Visual Verification.)

### 2026-07-19 — Slice 2 step 2 (host-relative render)

Served `src/aef-workflow-designer.html` over local HTTP, drove headless Chrome via
Playwright, imported `tests/fixtures/aef-bpmn/boundary-events.bpmn` (host serviceTask +
interrupting error boundary @ boundaryPos 0.75 + non-interrupting timer boundary @ 0.25),
framed the host, and READ the rendered canvas.

- `docs/reports/T-204-slice2-visual/boundary-on-host.png` — the host "do the work"
  (blue serviceTask rect); **"on error"** = red lightning event with a **solid double
  ring** (interrupting) straddling the host **bottom edge** (boundaryPos 0.75 → bottom
  R→L walk, center y = host bottom); **"timeout"** = blue clock event with a **dashed
  outer ring** (non-interrupting) straddling the host **top edge** (boundaryPos 0.25 →
  top L→R walk, center y = host top). Both anchored to the host perimeter (verified in
  JS: berr center on bottom edge, btmr center on top edge — NOT the free fixture x/y),
  each with an outgoing edge to its handler end event. The BPMN solid-vs-dashed
  interrupting convention reads clearly.
- **Known cosmetic artifact (not a functional defect):** boundary-event name labels
  render below the shape and can overlap the host's own label when the event sits near
  the host body ("timeout" over "do the work"). Intrinsic to boundary/host overlap;
  boundary-label placement is a polish follow-up. Perimeter placement (the AC) is met.

### 2026-07-19 — Slice 2 step 3 (boundary-origin ports)

Served `src/aef-workflow-designer.html` over local HTTP, drove headless Chrome via
Playwright, imported `boundary-events.bpmn`, framed the host cluster, and READ the canvas.

- `docs/reports/T-204-slice2-visual/boundary-ports.png` — host "do the work"
  (blue serviceTask); **"on error"** (red lightning, solid ring) on the host BOTTOM edge —
  its edge drops straight DOWN to "handle issue"; **"timeout"** (blue clock, dashed ring)
  on the host TOP edge — its edge exits UP (outward) and routes AROUND the host's right
  side down to "handle timeout", NOT straight down through the host body. Corroborated by
  an in-page geometry assertion (source anchor == outward port; routed polyline does not
  enter the host interior; `headingIntoHost:false`, `crossesHostBody:false` for both) — now
  a permanent guard (`PORT_ASSERT_EXPR` in `tools/_typed-events-cdp.mjs`).

## Verification

python3 tests/test_designer_render.py
python3 tests/test_designer_export_contract.py
python3 tests/test_bridge_aef_passthrough.py
python3 tests/test_roundtrip_serialization.py
python3 tests/test_typed_events.py

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

### 2026-07-19 — Slice 2 step 3 (T-168 boundary-origin ports) landed; all Slice-2 agent ACs done

- **What changed / built:** boundary-origin edges now exit the host perimeter OUTWARD.
  `boundaryOutwardPort(node, host)` returns the host-edge outward normal (N/E/S/W) from
  the SAME `boundaryPos` perimeter walk that places the event — deterministic, where a
  centre-to-centre heuristic ties at the corners and picks the wrong axis (observed: a
  bottom-edge event tie-breaking to W instead of S). `renderEdges` pins the source anchor
  to that port for auto-source boundary edges via a local `srcPortEff`, threaded through
  the anchor computation, `exitDirection`, and the straighten-skip guard. Explicit port
  pins still win. Guarded by a new `PORT_ASSERT_EXPR` in `_typed-events-cdp.mjs`
  (source-anchor == outward-port AND routed polyline never crosses the host body, both
  boundary edges). Visually verified — `docs/reports/T-204-slice2-visual/boundary-ports.png`.
- **Bug found + fixed while building (the port guard caught it):** `renderAll` runs
  `renderEdges()` BEFORE `renderNodes()`, but `syncBoundaryPositions()` lived only inside
  `renderNodes` — so on the FIRST render after a parse, boundary-origin edges routed from
  the stale pre-sync x/y (self-corrected one frame later). Hoisted `syncBoundaryPositions()`
  into `renderAll` ahead of `renderEdges`; kept the call in `renderNodes` too because the
  drag handlers call `renderNodes()+renderEdges()` directly (renderNodes first) and
  host-follow re-derives positions there. Idempotent, so the double call is a no-op.
- **Design note (why frac-derived, not centre-derived):** the outward direction MUST agree
  with where the event was placed. Both come from the one perimeter walk keyed on
  `boundaryPos`, so they can never disagree — the earlier centre-vector version was
  tie-sensitive at exactly the diagonal corner positions the fixture uses.
- **De-scoped to follow-ups (logged, not lost):** (a) drag-a-boundary-event-along-the-
  perimeter to author `boundaryPos` by mouse (today a text field + pinned position);
  (b) boundary-event label-placement polish (a name label can overlap the host label when
  the event sits near the host body). Neither is required by any Slice-2 AC. Slice 2 is now
  AGENT-complete; the only open item is the Human `[REVIEW]` AC (glyphs + boundary placement
  + follow on the served release) — task goes partial-complete, owner:human.



<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

### 2026-07-19 — Slice 2 host-follow confirmed free; only ports remain for step 3

- **What we learned:** host-follow (AC2 first half) needs NO code — it falls out of the
  step-2 render-sync. Every drag frame (single `drag` at ~5639, `groupDrag` at ~5662) calls
  `renderNodes()`, which calls `syncBoundaryPositions()` first, re-deriving each boundary
  event's x/y from the (now-moved) host. Confirmed via Playwright: host +（180,40) → both
  boundary events +（180,40) exactly. This is cleaner than threading boundary events through
  `groupDrag` (the original plan) — the single source of truth (host perimeter) does it.
- **Plan impact:** step 3 shrinks to the **port half of AC2**: boundary-origin edges should
  anchor via the T-168 port machinery so an outgoing edge exits the perimeter *away from the
  host body* (today it connects center-to-center, which can cross the host). Optional
  refinement: drag a boundary event along the perimeter to set `boundaryPos` (today it's a
  text field + pinned position). Plus the noted boundary-label placement polish.
- **Remaining for a fresh session (step 3):** (a) T-168 port anchoring for boundary-origin
  edges; (b) optional perimeter-slide authoring of `boundaryPos`; (c) label-placement polish.
  Then the human `[REVIEW]` AC (glyphs + boundary placement on the served release). Everything
  else in Slice 2 (attach/serialize/round-trip, host-relative render, host-follow) is done +
  verified. Do NOT set work-completed until the port half lands or is explicitly de-scoped.

### 2026-07-19 — Slice 2 step 2 (host-relative render) landed; interaction remains

- **What changed / built:** `renderNodes` now calls `syncBoundaryPositions()` first —
  for every typed event with a resolvable `hostRef`, its x/y is DERIVED from
  `boundaryPerimeterPoint(host, boundaryPos)` (clockwise perimeter walk from top-left;
  default bottom-centre). The typed-event render branch gained the BPMN boundary double
  ring (outer ring **dashed** when `interrupting==='false'`). Keeping the derived point
  in the model (not just at draw time) means edges/hit-testing/serialization all see the
  perimeter position — one source of truth. Visually verified (see §Visual Verification).
- **Design note:** a boundary event is now **pinned** to its host (render re-derives its
  position each frame), which is correct BPMN behaviour — you don't drag a boundary event
  freely. Two refinements belong to step 3: (a) dragging a host carries its boundary
  events (`groupDrag`), (b) dragging a boundary event *along the perimeter* edits its
  `boundaryPos`, and boundary-origin edges anchor via the T-168 port machinery.
- **Known cosmetic follow-up:** boundary-event name labels can overlap the host label
  (boundary/host overlap is intrinsic). Perimeter placement (the AC) is met; label
  placement is polish, logged not lost.

### 2026-07-19 — Slice 2 step 1 (boundary data path) landed; render + interaction remain

- **What changed / built:** the boundary-event *data path* — additive and byte-stable.
  A typed event (`eventError`/`eventTimer`/`eventMessage`) carrying `aef.hostRef` becomes a
  native `<bpmn:boundaryEvent attachedToRef=<host displayId> cancelActivity=<interrupting>>`;
  the kind still rides `<aef:eventDef>`. Import adds `boundaryEvent` to `nodeTags`, reads the
  native `attachedToRef`/`cancelActivity`, and resolves `attachedToRef` (a displayId) back to
  the host **uid** in a post-loop pass (`_hostDisplayId` → `hostRef`), so file order is
  irrelevant. Inspector gains `hostRef`/`boundaryPos`/`interrupting` fields (authoring surface
  before the drag UX). New `tests/fixtures/aef-bpmn/boundary-events.bpmn` (host + interrupting
  error + non-interrupting timer) round-trips byte-identical (4836==4836); round-trip proj
  gained `hostRef`+`interrupting` teeth; `_typed-events-cdp.mjs` gained a boundary correctness
  assertion (real `boundaryEvent` tag, both `cancelActivity` values, host stays serviceTask) +
  a BITE (strip `attachedToRef` ⇒ `hostRef` gone — attachment is attribute-driven, not tag-driven).
- **Field taxonomy decision (v1 §1):** `hostRef` + `interrupting` are **semantic** (attachment +
  cancelActivity change execution) → carried on native BPMN attributes, projected in the fixed
  point. `boundaryPos` is **presentational** (where the badge sits on the perimeter) → its own
  `<aef:boundaryPos>` element like `aef:position`, excluded from the projection. This deliberately
  keeps `boundaryPos` OFF the `aef:meta` channel, so the editor↔bridge meta-parity invariant
  (`metaKeys ⊆ META_KEYS`) is untouched — no bridge change is forced by Slice-2 step 1.
- **Bridge/mapping deferred (flagged):** `tools/yaml-to-bpmn.py` still emits the in-flow
  `intermediateCatchEvent` for typed events; it does not yet emit `boundaryEvent`/`attachedToRef`.
  The Slice-2 ACs are editor-scoped (attach/serialize/round-trip via the editor's own
  parse/build, host-follow, host-relative render) and do not require the forward-compile bridge.
  Bridge boundary parity + a mapping-standard row are a **separate follow-up** (candidate task)
  if/when the forward-compiler needs to author boundary events — captured here so the divergence
  is logged, not lost.
- **Remaining (steps 2-3):** host-relative perimeter render branch in `renderNodes` (~2354);
  host-follow drag via `groupDrag` (~5493, ~6624) so moving a host moves its boundary events;
  boundary-origin edges via the T-168 port machinery; then Playwright visual verification of the
  boundary glyph on the host perimeter (Human `[REVIEW]` AC). Do NOT set work-completed.

### 2026-07-19 — Slice 1 step 3 (bridge parity + mapping rows) landed; Slice 1 agent-complete

- **What changed / built:** bridge parity in `tools/yaml-to-bpmn.py` — added the three
  typed events to `TYPE_MAP` (all → neutral `intermediateCatchEvent`), module constants
  `EVENT_KIND`/`EVENT_BINDING_FIELD` (byte-mirror of the editor), a new `<aef:eventDef
  kind=.. binding=..>` emit branch keyed on **node type** (not an aef key — the one way
  eventDef differs from the `aef:link` analogue), and registered `errorStatus/timerSpec/
  busTopic` in `KNOWN_AEF_KEYS` so they don't trip the T-061 loud-drop. New `check_eventdef()`
  in `test_bridge_aef_passthrough.py` asserts all three kinds + no-warn on the binding scalars.
  Mapping rows added to **both** standards docs (mapping-v1 §3 editor-side; forward-compile-v1
  §3.1 compiler-side).
- **Decision #2 (RESOLVED):** eventDef rides the **known-vocabulary** channel, NOT `x-`
  passthrough. Rationale: the editor already emits a first-class `<aef:eventDef>` element
  (not an `aef.x-eventDef` scalar), and the binding fields are a closed vocabulary (three
  fixed keys) — so they belong in `KNOWN_AEF_KEYS` like `targetWorkflow`/`linkId`, mirroring
  the `aef:link` precedent. `x-` is for genuinely open-ended author extensions; this isn't one.
- **AC4 interpretation (flagged):** "one row per typed event" read as **one family row**
  enumerating all three kinds (error/timer/message) + bindings — mirroring the single
  `linkEventThrow / Catch` precedent row rather than three near-identical rows. Both standards
  docs got the row ("editor and forward-compiler agree"). The AC's "on the T-081
  collapsed-subProcess carrier" phrase refers to the design's target carrier for typed events
  (relevant to **Slice 2** boundary events attaching to a host), not a requirement to nest the
  Slice-1 row under the subProcess table row — Slice-1 typed events are standalone in-flow.
- **Slice 1 is now AGENT-complete:** all four Slice-1 agent ACs + the guards AC are checked.
  Remaining: the `[REVIEW]` **Human AC** (human confirms glyphs on the served release — task
  goes partial-complete, owner:human, once Slice 2 is also done OR if Slice 1 ships alone) and
  **Slice 2** (boundary variants). Do NOT set work-completed: Slice 2 agent ACs are still open.

### 2026-07-19 — Slice 1 step 2 (visual surface) landed; step 3–4 remain

- **What changed / built:** the visual surface mirroring `linkEvent*` at 8 sites —
  palette section (now labelled **"Typed events"**), `NODE_DEFAULTS` dims (36×36),
  `AEF_FIELDS` binding fields, `FIELD_META` (errorStatus/timerSpec/busTopic labels+hints),
  `NODE_IO`, on-canvas render branch (circle + kind glyph: lightning/clock/envelope,
  coloured `--red`/`--blue`/`--green`), below-label placement (`startsWith('event')` added
  to `ly` + the three isBelow predicates), `typeBadgeSvg` inspector icons, and `defaultName`.
  All guards stayed green; Playwright visual verification passed in every applicable mode
  (see `## Visual Verification`).
- **Plan impact:** none new — the anchor map held. Two small choices locked (see Decisions):
  NODE_IO for typed events is `{in:false,out:false}` (trigger nodes, no typed-data panel;
  the eventDef binding IS the content); palette label disambiguated to "Typed events" so it
  doesn't collide with the existing Start/End "Events" section header.
- **Remaining:** step 3 = bridge parity in `tools/yaml-to-bpmn.py` (decision #2 still open:
  `aef.eventDef` as known vocabulary vs `x-` passthrough — resolve by reading the bridge
  first) + mapping-standard rows (AC3, AC4); step 4 = human ticks the `[REVIEW]` AC on the
  served release. Slice 2 (boundary variants) after Slice 1 closes.

### 2026-07-19 — Slice 1 step 1 (data path) landed; steps 2–4 remain

- **What changed / locked at build time:**
  - **BPMN tag (decision #1):** all three typed events → `intermediateCatchEvent`
    (neutral "event in flow"); the kind rides `<aef:eventDef kind=… binding=…/>`,
    mirroring `aef:link`. The anchor-map REVERSE_TYPE(8185) collision (tag also =
    `linkEventCatch`) is resolved in `adoptImportedXml` by branching on extension
    content — `aef:eventDef` present → typed node type; else the default
    `linkEventCatch` stands. Proven by the BITE test (strip eventDef → linkEventCatch).
  - **Binding storage:** one kind-specific aef field each — `errorStatus`
    (`status:issues`), `timerSpec` (cron/horizon), `busTopic` — via
    `EVENT_BINDING_FIELD`. `EVENT_KIND`/`EVENT_KIND_TYPE`/`EVENT_BINDING_FIELD` are
    the single source of truth shared by export + import (no drift).
  - **Testing:** fixed-point round-trip proves *self-consistency* only, so a
    dedicated CDP harness (`tools/_typed-events-cdp.mjs` + `tests/test_typed_events.py`)
    was added for *correctness* (actual types+bindings+eventDef emit) + BITE. The
    shared round-trip harness projection was extended (METAKEYS +errorStatus/timerSpec/
    busTopic) so its fixed point also has teeth on the binding.
- **Plan impact:** none — the anchor map held. Decision #2 (bridge `aef.eventDef`
  vocabulary vs `x-` passthrough) is UNRESOLVED, deferred to **step 3** (bridge parity).
- **Remaining (next session):** step 2 = registry + palette + render glyphs + icons
  (the visual surface — needs Playwright element screenshots per §Visual Verification,
  all modes); step 3 = bridge parity in `tools/yaml-to-bpmn.py` + mapping-standard rows;
  step 4 = tick Human AC after visual verification. Field defs/META/dims/ports/render
  anchors are in the map above (1608–2397, 5004–5011). Stopped here on budget (~256K/300k).

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-07-19 — NODE_IO for typed events
- **Chose:** `eventError/eventTimer/eventMessage` → `{ in: false, out: false }` (no typed-data I/O panel in the inspector).
- **Why:** typed intermediate events are trigger/signal nodes — their semantic content is the `aef:eventDef` binding (status:issues / cron / bus topic), not a typed data contract flowing between steps. Sequence-flow in/out is handled by the edge machinery independent of `NODE_IO` (which only gates the I/O panel, per its single consumer at renderProperties). Adding an I/O list would create untested round-trip surface for no modelling gain.
- **Rejected:** mirroring `linkEventCatch {in:false,out:true}` — would offer an Outputs list implying the event carries a typed payload into the flow; not true for these framework-trigger events, and would need its own round-trip coverage.

### 2026-07-19 — Palette section label "Typed events"
- **Chose:** label the new palette section **"Typed events"** (not "Events").
- **Why:** the palette already has an "Events" section (Start/End). Two sections both rendering as uppercased "EVENTS" is confusing (caught in visual verification). "Typed events" matches the task/feature vocabulary and disambiguates.
- **Rejected:** "Events" (collision); "Intermediate events" (accurate but longer and leaks BPMN jargon the rest of the palette avoids).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-18T19:42:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-204-typed-bpmn-event-palette-errortimermessa.md
- **Context:** Initial task creation

### 2026-07-19T19:27:19Z — status-update [task-update-agent]
- **Change:** tags: +feature

### 2026-07-19T19:27:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b6d230db
- **Timestamp:** 2026-07-29T13:13:42Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Per-AC findings:**

- **AC#3 (Agent)** — `tools/yaml-to-bpmn.py` bridge parity: `aef:eventDef` fields ride the `aef:`/`x-` passthrough channel per the T-061 contract (bare unknown still drops loudly). Existing `tests/test_bridge_aef_passthro
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/yaml-to-bpmn.py in: `tools/yaml-to-bpmn.py` bridge parity: `aef:eventDef` fields ride the `aef:`/`x-` passthrough channel per the T-061 contract (bare unknown still drops`
- **AC#6 (Agent)** — Host-follow: moving a host moves its boundary events (reuses `groupDrag` ~5493); a boundary-origin edge anchors via the T-168 port machinery. <!-- DONE (both halves). Host-follow ✓ — delivered for FRE
  - **AC-verify-mismatch** (narrow, heuristic) — `path=docs/reports/T-204-slice2-visual/boundary-ports.png in: Host-follow: moving a host moves its boundary events (reuses `groupDrag` ~5493); a boundary-origin edge anchors via the T-168 port machinery. <!-- DON`
- **AC#7 (Agent)** — Boundary event renders at a host-relative perimeter point (contained new branch in `renderNodes` ~2354), not at free `x/y`. <!-- step 2: syncBoundaryPositions() derives each attached event's x/y from 
  - **AC-verify-mismatch** (narrow, heuristic) — `path=docs/reports/T-204-slice2-visual/boundary-on-host.png in: Boundary event renders at a host-relative perimeter point (contained new branch in `renderNodes` ~2354), not at free `x/y`. <!-- step 2: syncBoundaryP`
