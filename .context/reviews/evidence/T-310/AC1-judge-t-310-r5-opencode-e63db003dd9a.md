# Reviewer evidence — T-310 AC#1

- dispatch: `judge-t-310-r5-opencode-e63db003dd9a`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.2`)
- seat: `opencode`
- reviewed revision: `2c952a3e6d525bf14d41589069f1c3bb8be95d01`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `f120ad249d089748d48a3685e3bba6a2048b929bead44d0070e69cdcdaf19d9e`
- result.md sha256: `3056de3e0be8f079ced73a805046efc599d2593c0dcf00b878d72114116f7e03`

## The worker's verdict block

```
1. [AC] The reconciliation reads as a repair, not as the editor moving your work around
VERDICT: green
WHY: Drove this revision's real editor (src/aef-workflow-designer.html) headlessly via the repo's own CDP harness (tools/_t310-lane-position-conflict-cdp.mjs, exit 0): reconcile count exactly 2; "framework validates the request" (n_check) ends in lane 'framework' with centre y=302 inside the Framework band [222,382], "agent carries out the work" (n_act) ends in lane 'agent' with centre y=142 inside the Agent band [62,222]; the notice is visible in the live DOM and reads "⚠ 2 nodes were drawn outside their declared lane — moved back into place". It reads as a repair because the DECLARED lanes (the author's semantic content) win, only the two contradicting geometries were corrected (the two agreeing nodes kept their exact fixture y 110/310), the count is reported rather than silent, nothing leaks into the exported document, and re-import reconciles 0 (idempotent). Old-build claim verified by arithmetic from the fixture bytes themselves: n_check centre 132 falls in the agent band, n_act centre 332 in the framework band — each other's lanes, as the criterion describes. Caveat disclosed: this seat's model has no image input, so docs/screenshots/t310-*.png could not be viewed; the same build was instead exercised live in chromium with geometry, membership and notice text read from the rendered DOM, which covers every clause of the Expected text.
GUIDANCE: none


Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
The harness writes only to system temp dirs and copies the designer out of the repo, so it cannot touch the fingerprinted export — it's the sanctioned way to observe the real runtime. Let me check the environment and look at the notice implementation.
The reconciliation logic moves nodes to their declared lane's centre and counts them; the notice reads "N nodes were drawn outside their declared lane — moved back into place". Now let me look at the evidence screenshots committed with the task.
The image reads failed — this seat's model does not support image input, so I cannot view the committed PNGs. I'll disclose that and gather equivalent evidence by driving the real build headlessly instead (the CDP harness serves the exact `src/aef-workflow-designer.html` from this revision in headless chromium and reads back live geometry, lane membership and notice text; it writes only to its own mkdtemp dirs and cleans up, never touching the fingerprinted export).
Live run of the real build passes (exit 0). One disclosure per the tool error above: this seat cannot view images (model without image input), so the committed PNGs were not viewed; I substituted live-runtime evidence from the exact same revision's build.

Evidence summary of what I checked:

- **Harness** `tools/_t310-lane-position-conflict-cdp.mjs` (drives `src/aef-workflow-designer.html` from this revision in headless chromium): exit 0, `reconciled: 2`, `errs: []`.
- **Lane placement (live DOM):** `n_check` ("framework validates the request", declared `framework`) — centre y=302 inside the framework band [222, 382] = **Framework · Authority**; `n_act` ("agent carries out the work", declared `agent`) — centre y=142 inside the agent band [62, 222] = **Agent · Initiative**. Declared membership unchanged for both.
- **Repair, not rearrangement:** the two agreeing nodes kept their exact fixture y (110, 310) — untouched; only the two contradicting nodes moved; re-import of the export reconciles 0 (idempotent); nothing about the reconciliation leaks into the exported bytes; `laneAtY` below all bands returns null.
- **Notice:** visible in the real browser, text "⚠ 2 nodes were drawn outside their declared lane — moved back into place" — states 2 nodes, repair framing ("moved back into place"), dismissible, house advisory style (src/aef-workflow-designer.html:8610, :12443).
- **Before-state (old build) by fixture arithmetic:** fixture bytes put `n_check` centre at y=132 ∈ agent band and `n_act` centre at y=332 ∈ framework band — i.e. in each other's lanes, matching the criterion's description of the old build.

```
1. [AC] The reconciliation reads as a repair, not as the editor moving your work around
VERDICT: green
WHY: Drove this revision's real editor (src/aef-workflow-designer.html) headlessly via the repo's own CDP harness (tools/_t310-lane-position-conflict-cdp.mjs, exit 0): reconcile count exactly 2; "framework validates the request" (n_check) ends in lane 'framework' with centre y=302 inside the Framework band [222,382], "agent carries out the work" (n_act) ends in lane 'agent' with centre y=142 inside the Agent band [62,222]; the notice is visible in the live DOM and reads "⚠ 2 nodes were drawn outside their declared lane — moved back into place". It reads as a repair because the DECLARED lanes (the author's semantic content) win, only the two contradicting geometries were corrected (the two agreeing nodes kept their exact fixture y 110/310), the count is reported rather than silent, nothing leaks into the exported document, and re-import reconciles 0 (idempotent). Old-build claim verified by arithmetic from the fixture bytes themselves: n_check centre 132 falls in the agent band, n_act centre 332 in the framework band — each other's lanes, as the criterion describes. Caveat disclosed: this seat's model has no image input, so docs/screenshots/t310-*.png could not be viewed; the same build was instead exercised live in chromium with geometry, membership and notice text read from the rendered DOM, which covers every clause of the Expected text.
GUIDANCE: none
```

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
