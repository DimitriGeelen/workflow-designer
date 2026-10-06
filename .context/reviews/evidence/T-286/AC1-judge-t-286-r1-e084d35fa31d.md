# T-286 AC1 — reviewer evidence (judge-t-286-r1-e084d35fa31d)

Revision under review: 658ba14661e79094f8fd7bea8ffa5c5647ed7b0e. Date: 2026-10-06.

## What I checked
I drove the live operator-reachable designer at http://192.168.10.107:3000 in an isolated headless
Chromium (chromium-1223, 1600x1000, DPR 1) using real CDP `Input.dispatchMouseEvent` input for the
clicks and drags. The probe is `AC1-probe-judge-t-286-r1-e084d35fa31d.mjs.txt` and its full output is `AC1-probe-judge-t-286-r1-e084d35fa31d.log`.
I wrote the probe myself in /tmp and did not reuse the producer's T-286 probe.

### Step 1 (operator path): FAILED as written
- `:3000/designer` lists 16 cards. **None of them is `t293-retest-harvest`**, and
  `/api/version?id=t293-retest-harvest&v=1` returns `{"error":"not found"}`.
- Root cause: the process on :3000 (pid 973428, `python3 -m web.app --port 3000`) now runs from
  `/opt/999-Agentic-Engineering-Framework`. Its designer store has no t293 copy. The copy exists
  only in this repo's `.context/designer/projects/t293-retest-harvest/`. This is the dead-link class
  from T-253, so a human following the AC steps cannot reach the map.
- Workaround I used: I opened `:3000/designer/app` (the served bundle contains `g-badges`,
  `g-badges-top` and `function layerIdBadges`). Then I adopted the exact t293-retest-harvest v1.bpmn
  bytes through `adoptImportedXml`. That is the same map the card would have loaded.
- Note: the operator's original node `fw_1_scan` is not in any current map. I used every badge and
  arrow overlap that this map actually has.

### Steps 2–4: behaviour, all PASS
| Leg | Result |
|---|---|
| Layer order `g-badges < g-edges < g-nodes < g-badges-top`; both badge layers pointer-events none | PASS |
| With nothing selected, all 24 id badges are in `#g-badges` (0 in g-nodes, 0 in g-badges-top) | PASS |
| Arrow e_23 (n_join→n_summary) runs over badge `frw_17_join`; at that point the paint stack has the edge path, and the badge is not above it | PASS |
| Real click on node n_join moves its badge and halo to `#g-badges-top` | PASS |
| Real click on empty canvas clears the selection and empties `#g-badges-top` | PASS |
| Real click on the e_23 midpoint selects the edge | PASS |
| Sweep of all edges: 4 endpoint handles geometrically overlap an id badge (e_10:src/frw_9_read, e_11:tgt/frw_15_harvest, e_16:tgt/frw_16_harvest, e_23:src/frw_17_join). For each one, a point inside both circle and badge hit-tests to the handle, and a real press+move starts `edgeDrag.kind='endpoint'` with no node drag | 4/4 PASS |

### Screenshots (read by me, 3x zoom crops)
- `AC1-default-judge-t-286-r1-e084d35fa31d.png`: the edge line visibly runs over the `frw_17_join` badge text (badge underneath), and the arrowhead into Tally is unobstructed.
- `AC1-selected-judge-t-286-r1-e084d35fa31d.png`: with n_join selected, the badge and halo sit on top and the line no longer strikes through "join". The badge is fully legible.
- `AC1-deselected-judge-t-286-r1-e084d35fa31d.png`: after the empty-canvas click, the badge is back under the line.
- `AC1-edge-selected-judge-t-286-r1-e084d35fa31d.png`: with e_10 selected, its source handle sits directly on the `frw_9_read` badge, and the press+move there started an endpoint drag.

## Verdict: green
The criterion is the behaviour. All three expected outcomes hold on the bundle the operator actually
reaches: (1) arrowheads are never hidden by a badge by default; (2) the selected node's badge is
foregrounded and legible; (3) endpoint handles are grabbable through the badge area. I tested these with
real mouse input and confirmed them visually. The operator ruled that "feels right" taste checks
without risk belong to the reviewer.

Non-blocking finding for the producer: step 1 of the AC is a dead path, because the t293-retest-harvest
card is missing from :3000, which is now served from the AEF repo. Any future human retest needs
the card re-saved into the store :3000 serves, or the steps repointed.
