# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-antigravity-998291e5dad8`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `281a7807ba173f63d1a872a460a451bb9871b293`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `5176ee2ea8a931382e9b8bf8ed6d9a9c0c82a94fdcef02da2b57c6770f313ccf`

## The worker's verdict block

```
1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Verified via headless Chromium execution (tools/_t893-authority-marker-shots.mjs exited 0 with L1 PASS and L2 PASS) and direct visual inspection of rendered screenshots across densities (docs/reports/t893-shots/{none,differs,missing}-{s,m,l}.png). In none-m.png, no authority marker is shown (silent default). In differs-m.png, the marker appears as faint mono ◆ ini (subtle authorial annotation). In missing-m.png, the marker appears as orange ⚠ no auth (prominent defect indicator). The subtle/loud contrast is visually balanced and semantically distinct. The shortened text cleanly avoids collision with incoming edge arrows landing at top-centre, and edge labels maintain clear clearance. Full text is preserved in <title> for hover. Note: single-vendor panel degraded run (seat antigravity), criterion stays open pending multi-vendor quorum.
GUIDANCE: None needed (criterion met).

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
## Evidence Report: Review Worker T-3580 (Task T-893)

**Panel Seat:** `antigravity` (Rung 5 — IW-7 impact-risk model, D1/D2 > 3)  
**Status:** **degraded: single-vendor panel.** Fewer vendors can be dispatched than the panel requires, so this run cannot satisfy a multi-vendor requirement: this verdict is recorded and reported, and the criterion stays open.

---

### Step Execution & Visual Inspection Evidence

1. **Step 1:** Executed `node tools/_t893-authority-marker-shots.mjs` using Node v22.22.1 (`WebSocket` native support).
   - Execution succeeded with exit code 0.
   - Output: `L1 PASS` (marker counts per size: differs=1, missing=3, nodes=15) and `L2 PASS` (`buildBpmnXml` before == after rendering markers; default never writes).
   - 9 screenshots written to `docs/reports/t893-shots/`.

2. **Step 2:** Inspected `docs/reports/t893-shots/none-m.png`, `differs-m.png`, and `missing-m.png` side by side (along with `s` and `l` variants):
   - **`none-m.png` (`frw_3_start`):** No marker rendered above the element. Standard I/O badge (`1→0`) and node ID badge rendered normally. The common case is completely silent.
   - **`differs-m.png` (`frw_4_enter`):** Rendered faint mono `◆ ini` at top-left above the node. Uses `--text-faint` monospace 8px. It reads clearly as an informative annotation and metadata tag rather than an alarm or defect.
   - **`missing-m.png` (`agt_2_perform`):** Rendered orange `⚠ no auth` at top-left above the node. Uses `--orange` monospace 8px font-weight 600 with the warning triangle icon. It reads immediately as a defect/error.
   - **Visual Pitch & Collision Check:** The subtle (`◆ ini`) vs loud (`⚠ no auth`) contrast is appropriately pitched. The shortened form `⚠ no auth` fits cleanly to the left of the top-centre entry point, avoiding collision with the incoming flow arrowhead entering at top-centre. Incoming edge label `(issues -> started-work)` is positioned with clear vertical clearance above the node. Full tooltip text (`no authority — this element has none and its lane offers no default`) is preserved in the SVG `<title>` element with pointer events enabled.

---

1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Verified via headless Chromium execution (`tools/_t893-authority-marker-shots.mjs` exited 0 with L1 PASS and L2 PASS) and direct visual inspection of rendered screenshots across densities (`docs/reports/t893-shots/{none,differs,missing}-{s,m,l}.png`). In `none-m.png`, no authority marker is shown (silent default). In `differs-m.png`, the marker appears as faint mono `◆ ini` (subtle authorial annotation). In `missing-m.png`, the marker appears as orange `⚠ no auth` (prominent defect indicator). The subtle/loud contrast is visually balanced and semantically distinct. The shortened text cleanly avoids collision with incoming edge arrows landing at top-centre, and edge labels maintain clear clearance. Full text is preserved in `<title>` for hover. Note: single-vendor panel degraded run (seat antigravity), criterion stays open pending multi-vendor quorum.
GUIDANCE: None needed (criterion met).

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
