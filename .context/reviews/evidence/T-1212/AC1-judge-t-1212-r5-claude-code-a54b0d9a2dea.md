# T-1212 Human AC#1 — independent screenshot review (seat claude-code, rung-5-panel)

Dispatch: judge-t-1212-r5-claude-code-a54b0d9a2dea · Revision reviewed: e9ee7284a2020581ad36bc3944f4edc5a00569cb

## Provenance
The three screenshots in docs/reports/T-1212-evidence/ are byte-identical to the blobs at e9ee7284
(git hash-object == git rev-parse e9ee7284:<path>):
- t1212-check-1024.png 0e78115733b7c4dd1335f3637f544c47bdd2c103
- t1212-check-1440.png dd761d3d3874cfcfcf590d87c0219da67c9f14d2
- t1212-check-1920.png a96642d0bf17651d830db63967e0f60e9b131cf3
Copies cited here: t1212-check-{1024,1440,1920}-judge-t-1212-r5-claude-code-a54b0d9a2dea.png; zoomed crops of the gateway:
gateway-marker-{1440,1920}-zoom-judge-t-1212-r5-claude-code-a54b0d9a2dea.png.

## Per screenshot
| check | 1024 | 1440 | 1920 |
|---|---|---|---|
| Dock line "1 finding · 0 errors, 1 warning · 1 on the map" | ok (verbatim) | ok (verbatim) | ok (verbatim) |
| Row severity WARN (amber), not ERROR | ok | ok | ok |
| Rule id W-XML-GW-OUTGOING | ok | ok | ok |
| Message "exclusiveGateway has 1 outgoing flow(s); requires >= 2" | ok | ok | ok |
| Dock close button (×) visible, unclipped | ok (x≈683) | ok (x≈1099) | ok (x≈1579) |
| Toolbar "✓ Check" button visible, unclipped | ok (row 2) | ok (row 2) | ok (row 1) |
| Gateway finding marker on map | map drawn too small to resolve (fit-zoom thumbnail) — allowed by the criterion's "where the map is drawn large enough" | ok — amber warning-triangle badge at gateway's lower right | ok — amber warning-triangle badge clearly visible at gateway's lower right |

No ERROR row, no red marker, nothing clipped in any shot. Toolbar wraps to two rows at 1024/1440 without clipping.
The "no authority" banner over the map is an unrelated advisory and does not cover the dock, the Check button or the gateway.

## Verdict: green
