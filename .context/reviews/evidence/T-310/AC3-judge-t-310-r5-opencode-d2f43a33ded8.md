# Reviewer evidence — T-310 AC#3

- dispatch: `judge-t-310-r5-opencode-d2f43a33ded8`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.2`)
- seat: `opencode`
- reviewed revision: `2ecd350d8fc1a36691b3216c138a3c98d8b20c03`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `385347d76f44a5794d67df54a24673797573b0f6d50ffc43985bb544d9ed0047`
- result.md sha256: `c0f242f4535fef046575a88819bec586bbd6838f42bfe1a96c0e657b4291efc4`

## The worker's verdict block

```
1. [AC] Cosmetic: the stacked Clean nudge overlaps top-lane content
VERDICT: green
WHY: Verified the disclosed state is exactly what ships. Measured the screenshot (2x DPI): notice at CSS y 12–42.5, nudge stacked below at exactly y=52px (src/aef-workflow-designer.html:533 .clean-nudge.stacked{top:52px}), no banner-vs-banner collision. Confirmed the overlap is real via pixel analysis — a top-lane node (the fixture's agt_2_act, misnamed agt_2_agent in the AC text) sits ~85% behind the opaque nudge, with only a left sliver (device x 504–518) and bottom fragments (device y 192–204) visible. Judged acceptable because: (a) same overlay class as the pre-existing single nudge at top:12px/z-index:5 (T-264 chrome) — one row down, not a new defect; (b) occurs only when BOTH advisories fire, i.e. malformed maps with messiness ≥ 3 (CLEAN_NUDGE_MIN, src:8413); (c) both banners dismissible in one click and dismissing the notice un-stacks the nudge (src:9331, 9334–9335); (d) nothing is corrupted — nodes are in their declared lanes and the banner hides, not alters, content; (e) honestly disclosed in the task's Visual Verification section; and decisively (f) the remedy the AC names is filed as tracked work with enforcement-bearing ACs (T-1078: rect-intersection, nowrap overflow at 1280/1720, poison-arm bridge leg), so the wrinkle cannot silently evaporate when T-310 archives.
GUIDANCE: None required for T-310. The tracked follow-up T-1078 (canvas top-padding or docking advisories outside the canvas) should be scheduled; when it lands, re-shoot the both-advisories state and correct the node id there (agt_2_act, not agt_2_agent).

Summary: 1 green, 0 amber, 0 red, 0 escalate
```

## The worker's full output (result.md)

```
I can't visually render the image in this session, so I'll analyze the screenshot programmatically to gather evidence about the overlap.
The screenshot is 2x DPI. Banner 1 (lane-fix notice) spans y=12–43 CSS px; banner 2 (Clean nudge) spans y=52–94 CSS px — matching the criterion's stated y=52px. Now let me verify the overlap with a top-lane node.
The task context confirms this AC documents a known regression. Now let me verify the covered-node claim against the fixture's actual node positions.
The harness confirms the notice/nudge DOM (`#lane-fix-notice`, `#clean-nudge.stacked`). Now let me check the source for the stacking geometry (y=52px claim) and confirm both banners are dismissible.
All factual claims verified against source (`top:12px` base, `.stacked{top:52px}`, both dismissible). Last check: is the known overlap tracked anywhere as a follow-up, since completed tasks archive away?
T-1078 is the filed follow-up for exactly this overlap, with concrete ACs. One last source check on the dismiss/pinning behavior:
All evidence gathered. Final verification summary before the verdict:

**Facts verified:**
1. **Geometry matches the disclosure exactly** — `t310-both-after.png` (1720×1418 @2x): lane-fix notice at CSS y 12–42.5, Clean nudge stacked below at CSS y 52–94.5 (lime top border at device px 104 = 52 CSS px, matching `.clean-nudge.stacked { top: 52px }` at src/aef-workflow-designer.html:533). The two banners do not collide with each other.
2. **The overlap is real** — pixel analysis shows a top-lane node mostly hidden behind the nudge: a ~10px card sliver at device x 504–518 spanning the banner's full height, plus bottom-edge fragments at device x 545–590, y 192–204 — geometrically consistent with the reconciled node at BPMN x=470 that T-310 moved into the top lane. Not a new interaction class: base `.clean-nudge` has floated over canvas content at `top:12px`, `z-index:5` since T-264; T-310 only added the second row.
3. **Both banners dismissible, correctly wired** — `#clean-nudge-dismiss` (src:9331), `#lane-fix-dismiss` (src:9334) which also removes `.stacked` so the nudge returns to the 12px slot; both pin to viewport on scroll (src:3014).
4. **Rare state only** — requires BOTH advisories: a lane-conflicted map (malformed) that also scores messiness ≥ 3 (`CLEAN_NUDGE_MIN`, src:8413).
5. **The remedy is tracked, not prose** — T-1078 ("Advisory banners overlay the canvas…", status captured, horizon next) files exactly the two fixes the criterion names, with measurable ACs (advisory-rect/node-rect intersection zero, nowrap overflow at 1280/1720, poison-arm bridge leg).

One noted discrepancy: the AC (and T-1078) call the covered node `agt_2_agent`; the fixture's node is `agt_2_act` (uid `n_act`). The geometric overlap is verified regardless — a naming slip, not a misrepresentation.

1. [AC] Cosmetic: the stacked Clean nudge overlaps top-lane content
VERDICT: green
WHY: Verified the disclosed state is exactly what ships. Measured the screenshot (2x DPI): notice at CSS y 12–42.5, nudge stacked below at exactly y=52px (`src/aef-workflow-designer.html:533` `.clean-nudge.stacked{top:52px}`), no banner-vs-banner collision. Confirmed the overlap is real via pixel analysis — a top-lane node (the fixture's `agt_2_act`, misnamed `agt_2_agent` in the AC text) sits ~85% behind the opaque nudge, with only a left sliver (device x 504–518) and bottom fragments (device y 192–204) visible. Judged acceptable because: (a) same overlay class as the pre-existing single nudge at `top:12px`/`z-index:5` (T-264 chrome) — one row down, not a new defect; (b) occurs only when BOTH advisories fire, i.e. malformed maps with messiness ≥ 3 (`CLEAN_NUDGE_MIN`, src:8413); (c) both banners dismissible in one click and dismissing the notice un-stacks the nudge (src:9331, 9334–9335); (d) nothing is corrupted — nodes are in their declared lanes and the banner hides, not alters, content; (e) honestly disclosed in the task's Visual Verification section; and decisively (f) the remedy the AC names is filed as tracked work with enforcement-bearing ACs (T-1078: rect-intersection, nowrap overflow at 1280/1720, poison-arm bridge leg), so the wrinkle cannot silently evaporate when T-310 archives.
GUIDANCE: None required for T-310. The tracked follow-up T-1078 (canvas top-padding or docking advisories outside the canvas) should be scheduled; when it lands, re-shoot the both-advisories state and correct the node id there (`agt_2_act`, not `agt_2_agent`).

Summary: 1 green, 0 amber, 0 red, 0 escalate
```
