# Reviewer evidence — T-1514 AC#1

- dispatch: `judge-t-1514-r3-bcb49b292b5d`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `bea2a50944692585f362789eb7d3e8f8da8d6e5b`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `6524d68e55c04c98a289be304e69d8900c108c21a618c4bcd54189d388ded016`
- result.md sha256: `57734839837119f362b5f51920d6c736d6684d8a246b90cbb65566eb8b5963aa`

## The worker's verdict block

```
1. [AC] Dragging a step into the neighbour phase moves the boundary beside it
VERDICT: amber
WHY: Visually inspected all six images in docs/reports/T-1514-shots/: before/after pairs for 1024, 1440, and 1920. Each pair clearly shows “Send Proposal” moving left into the empty bottom lane under “Configuratie”; the bracket ends and dashed divider move right into the gap after it. The moved step, its text, and the relevant boundary are fully visible without overlapping other nodes. However, “nothing clipped” is not fully met: all six shots cut off the pool heading at the left edge and identifiers beneath the Closed Won column at the right edge.
GUIDANCE: Adjust the paired crops consistently at all three widths so visible headings and identifiers are fully included, or end the crops in clear gaps before peripheral content. Preserve the current clear view of the moved step and boundary.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Dragging a step into the neighbour phase moves the boundary beside it
VERDICT: amber
WHY: Visually inspected all six images in `docs/reports/T-1514-shots/`: before/after pairs for 1024, 1440, and 1920. Each pair clearly shows “Send Proposal” moving left into the empty bottom lane under “Configuratie”; the bracket ends and dashed divider move right into the gap after it. The moved step, its text, and the relevant boundary are fully visible without overlapping other nodes. However, “nothing clipped” is not fully met: all six shots cut off the pool heading at the left edge and identifiers beneath the Closed Won column at the right edge.
GUIDANCE: Adjust the paired crops consistently at all three widths so visible headings and identifiers are fully included, or end the crops in clear gaps before peripheral content. Preserve the current clear view of the moved step and boundary.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```
