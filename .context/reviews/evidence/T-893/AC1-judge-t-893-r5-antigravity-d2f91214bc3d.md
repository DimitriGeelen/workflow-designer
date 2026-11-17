# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-antigravity-d2f91214bc3d`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `1de2010087da57dc32310ea416b5783dff372eca`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `3fa8de7f2dbf739afe882a8d623a2f4fa68a60d8bc42a53f9eea70fa22056377`

## The worker's verdict block

```
1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Ran tools/_t893-authority-marker-shots.mjs (L1/L2/L3 PASS, 9/9 PNGs written) and tools/_t1069-authority-marker-clearance-cdp.mjs (M1–M4 PASS across all 24 corpus maps, 0 edge crossings, 600/600 hoverable titles) in an isolated $TMPDIR/run copy, and visually inspected none-m.png, differs-m.png, and missing-m.png (plus s and l variants) side by side. none-m.png renders no marker (silent common case); differs-m.png renders a muted faint-grey monospace ◆ ini above top-left that reads as a quiet metadata annotation; missing-m.png renders a semibold orange ⚠ no auth above top-left that stops cleanly left of the top-centre incoming arrowhead with no edge or label collision and reads unmistakably as a defect. Note: degraded single-vendor panel run (rung-5-panel:antigravity), so this verdict is recorded and reported while the criterion stays open for multi-vendor completion.
GUIDANCE: None on the artefact itself; criterion remains open only because this dispatch is a degraded single-vendor panel run.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
### Evidence Report — T-893 Independent Review (`rung-5-panel:antigravity`)

- **Task:** T-893 (`1de2010087da57dc32310ea416b5783dff372eca`)
- **Seat:** `antigravity`
- **Panel status:** **degraded: single-vendor panel.** Fewer vendors can be dispatched than the Rung 5 panel requires, so this run cannot satisfy a multi-vendor requirement: this verdict is recorded and reported, and the criterion stays open.

#### Verification Performed
1. **Isolated reproduction in `$TMPDIR/run`:**
   - Copied the exported tree to `$TMPDIR/run` without touching the working tree.
   - Executed [t893-authority-marker-state.test.mjs](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/tests/t893-authority-marker-state.test.mjs): `PASS 13 / FAIL 0`.
   - Executed [_t893-authority-marker-shots.mjs](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/tools/_t893-authority-marker-shots.mjs) in headless Chromium (via Node v22.18.0 for native `WebSocket` support):
     - `L1 PASS`: marker counts per size `{"s":{"differs":1,"missing":3,"nodes":15},"m":{"differs":1,"missing":3,"nodes":15},"l":{"differs":1,"missing":3,"nodes":15}}`.
     - `L2 PASS`: `buildBpmnXml` before == after rendering markers (`22736` bytes).
     - `L3 PASS`: `9/9` shots clear and unobstructed at clip centre.
   - Executed [_t1069-authority-marker-clearance-cdp.mjs](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/tools/_t1069-authority-marker-clearance-cdp.mjs): `PASS — 4 legs` (`M1`: 0 missing crossings, `M2`: 0 differs crossings, `M3`: 306 missing / 294 differs markers rendered across 24 corpus maps, `M4`: 0 markers without hoverable `<title>`).
2. **Side-by-side visual inspection of all 9 PNGs in `docs/reports/t893-shots/` (and fresh renders in `$TMPDIR/run/docs/reports/t893-shots/`):**
   - [none-m.png](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/docs/reports/t893-shots/none-m.png) (`frw_1_start`, *"Start work (captured -> started-work)"*): No authority marker is rendered above the node across `s`/`m`/`l`. The common case is completely silent.
   - [differs-m.png](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/docs/reports/t893-shots/differs-m.png) (`frw_2_enter`, *"Enter issues (auto → healing diagnose)"*): Renders a quiet, faint monospace `◆ ini` (`fill: var(--text-faint)`, 8px mono) above the top-left corner of the node border. Its low contrast matches the visual weight of the bottom `frw_...` ID badge, reading naturally as a structural annotation of an authorial choice rather than a warning.
   - [missing-m.png](file:///tmp/tl-dispatch/judge-t-893-r5-antigravity-d2f91214bc3d/tree/docs/reports/t893-shots/missing-m.png) (`agt_2_perform`, *"Perform the work"*): Renders a bright orange semibold `⚠ no auth` (`fill: var(--orange)`, `font-weight: 600`, 8px mono) above the top-left corner of the blue-bordered node. The marker terminates cleanly to the left of the top-entering sequence flow arrowhead with zero overlap against incoming edges or labels, and carries the full text in a hoverable `<title>` (`cursor: help`). The orange color, warning glyph, and heavier weight immediately read as a defect/hole, contrasting clearly against the muted `◆ ini` annotation.

1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Ran `tools/_t893-authority-marker-shots.mjs` (L1/L2/L3 PASS, 9/9 PNGs written) and `tools/_t1069-authority-marker-clearance-cdp.mjs` (M1–M4 PASS across all 24 corpus maps, 0 edge crossings, 600/600 hoverable titles) in an isolated `$TMPDIR/run` copy, and visually inspected `none-m.png`, `differs-m.png`, and `missing-m.png` (plus `s` and `l` variants) side by side. `none-m.png` renders no marker (silent common case); `differs-m.png` renders a muted faint-grey monospace `◆ ini` above top-left that reads as a quiet metadata annotation; `missing-m.png` renders a semibold orange `⚠ no auth` above top-left that stops cleanly left of the top-centre incoming arrowhead with no edge or label collision and reads unmistakably as a defect. Note: degraded single-vendor panel run (`rung-5-panel:antigravity`), so this verdict is recorded and reported while the criterion stays open for multi-vendor completion.
GUIDANCE: None on the artefact itself; criterion remains open only because this dispatch is a degraded single-vendor panel run.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
