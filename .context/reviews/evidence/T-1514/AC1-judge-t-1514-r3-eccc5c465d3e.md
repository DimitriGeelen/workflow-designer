# Reviewer evidence — T-1514 AC#1

- dispatch: `judge-t-1514-r3-eccc5c465d3e`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `992463c6848cae88c4110adb0aade1f6292a288a`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `6474a97f9894970bccc655cf2f164eeb0cad2eb06f5bf7771e48ea77e77ccd33`
- result.md sha256: `28986b9f5d487f54db5704897db1038625f5362e894101442fe0666db0b45a80`

## The worker's verdict block

```
1. [AC] Dragging a step into the neighbour phase moves the boundary beside it
VERDICT: amber
WHY: Opened all six images in docs/reports/T-1514-shots/. Each before/after pair preserves its view with both side panels folded. At 1024, 1440, and 1920, “Send Proposal” moves left and down beneath Configuratie, and both the bracket boundary and dashed divider move into the gap to its right. The phase change reads clearly. However, in every after image, the moved card straddles the NOVIS/NAV separator rather than sitting wholly inside NOVIS. The “nothing clipped” requirement also remains unmet: the 1440 pair clips the rightmost Closed Won heading and opportunity card, and the 1024 pair partially hides the leftmost Salesforce card behind the lane-label strip.
GUIDANCE: Position the moved card fully inside NOVIS, leaving clearance for its label above and identifier below. Adjust the framing or zoom to remove the visible edge clipping, then supply updated before/after pairs at all three widths.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Dragging a step into the neighbour phase moves the boundary beside it
VERDICT: amber
WHY: Opened all six images in `docs/reports/T-1514-shots/`. Each before/after pair preserves its view with both side panels folded. At 1024, 1440, and 1920, “Send Proposal” moves left and down beneath Configuratie, and both the bracket boundary and dashed divider move into the gap to its right. The phase change reads clearly. However, in every after image, the moved card straddles the NOVIS/NAV separator rather than sitting wholly inside NOVIS. The “nothing clipped” requirement also remains unmet: the 1440 pair clips the rightmost Closed Won heading and opportunity card, and the 1024 pair partially hides the leftmost Salesforce card behind the lane-label strip.
GUIDANCE: Position the moved card fully inside NOVIS, leaving clearance for its label above and identifier below. Adjust the framing or zoom to remove the visible edge clipping, then supply updated before/after pairs at all three widths.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```
