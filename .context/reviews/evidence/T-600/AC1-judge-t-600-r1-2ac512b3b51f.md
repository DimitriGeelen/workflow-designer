# T-600 AC1 — reviewer evidence (judge-t-600-r1-2ac512b3b51f)

Revision reviewed: ebb4f44f535f1cc749739797edcd641753490160 (includes T-1067 fix 86f740da)
Criterion: [REVIEW] Long event/gateway sentences wrap instead of sprawling, and the map still reads well.
Verdict: **green**

## Method
- The operator's map with `hum_3_run` is not in the repo (the previous reviewer found the same). Stand-in: the real
  editor `src/aef-workflow-designer.html` @ HEAD in headless Chromium (CDP, device scale 3). I renamed the human-lane end
  event (badge `hum_2_ready`, beside "Human review & route", the same position as in the operator's screenshot) to the exact
  text **"run halted - operator kill switch"**, then:
  - set the label size S/M/L through the real `#set-label-size` select, with `wrapNames` on and off;
  - toggled the real Settings checkbox `#set-wrap-labels` by click: on → off → on at size M.
- I measured each line with getComputedTextLength() and the block's bounding box, and compared it against the lane-divider y positions.
- Probe: `AC1-judge-t-600-r1-2ac512b3b51f-probe.mjs.txt` (adapted from the previous reviewer's probe). Raw output: `AC1-judge-t-600-r1-2ac512b3b51f-probe-log.txt`.

## Results
| size | wrap | lines (measured px) | crosses lane divider (y=187/281) |
|---|---|---|---|
| S | on  | "run halted -" 52 / "operator kill" 54 / "switch" 28, right of circle | no |
| S | off | one line, 138 px, below circle | no |
| M | on  | 57 / 59 / 31, right of circle | no |
| M | off | one line, 151 px, below circle and running left into the "dispatch" edge label and the task | no |
| L | on  | 65 / 67 / 35, right of circle | no |
| L | off | one line, 172 px | no |
| M, checkbox click → off | | one line, 151 px (checkbox reads false) | no |
| M, checkbox click → on  | | 3 lines again (checkbox reads true) | no |

- localStorage `aefLabelPrefs` persists `wrapNames`, and the checkbox now reflects the stored pref on load (T-1067 syncSettingsUI).

## Screenshots (I read each one)
- `AC1-judge-t-600-r1-2ac512b3b51f-on-m.png`: ON, size M. Three stacked lines right of the circle, with the `hum_2_ready` badge directly beneath. It stays inside the lane
  and clears the edge, its label and the task. Reads cleanly.
- `AC1-judge-t-600-r1-2ac512b3b51f-off-m.png`: OFF, size M. The old single line sprawls left under the circle and overlaps the "dispatch" edge label and the "Human review" box edge.
- `AC1-judge-t-600-r1-2ac512b3b51f-on-s.png`, `AC1-judge-t-600-r1-2ac512b3b51f-on-l.png`: ON at S and L. Same 3-line block, no regressions. `AC1-judge-t-600-r1-2ac512b3b51f-off-s.png`, `AC1-judge-t-600-r1-2ac512b3b51f-off-l.png`: the single line returns.
- `AC1-judge-t-600-r1-2ac512b3b51f-settings-off-m.png`, `AC1-judge-t-600-r1-2ac512b3b51f-settings-on-again-m.png`: the real checkbox toggle, off then on again.

## Against Expected
- "With the option on the sentence occupies two or three stacked lines under/beside the circle": MET (3 lines, beside, S/M/L).
- "no longer runs across the lane divider": MET (the block lies between the dividers in every case).
- "with it off the old single-line behaviour returns": MET.
- "the map still reads well": MET in the screenshots.

## Caveats (not verdict-changing)
- This is the seed map, not the operator's own map. The T-1067 trigger is "the label collides on every side" (bboxScore: edges, nodes,
  pool), so on a different geometry an under-cap label that collides with nothing stays one line. That is by design (T-105).
- Separate from this criterion: `node tools/_t600-label-wrap.mjs --self-test` exits 2 at this revision
  ("SELF-TEST FAIL — L3 passed under poison"; poison arm B no longer bites). That breaks one of the task's own Verification
  commands and its Agent AC#6, so it should be fixed before the task is closed. The plain run (7/7) and `_t1067` (6/6) pass.
