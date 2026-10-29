# T-1102 AC1 — independent review (judge-t-1102-r1-43e2fc8d2fc5), revision 21cc68edbf22751647c212a485ab722c212f83cc

## What I looked at
- docs/reports/T-1102-evidence/kitchen-sink-{1024,1440,1920}.png (full pages) and kitchen-sink-1920-ids-crop.png (3x crop),
  copied here as kitchen-sink-1920-ids-crop-judge-t-1102-r1-43e2fc8d2fc5.png.
- My own enlarged crops of kitchen-sink-1920.png: ks1920-lower-lane-la2-judge-t-1102-r1-43e2fc8d2fc5.png (lane "Lane"/Lane_1vakzes band) and
  ks1920-right-ends-judge-t-1102-r1-43e2fc8d2fc5.png (end/link event column).
- The shots were taken at 62d8cff9b; git diff 62d8cff9b..21cc68edb on src/, tools/, tests/run-bridge-tests.sh is comment-only,
  so the shots represent the reviewed revision.

## Findings
1. Distinct ids (1920 crop, read by me): event-subprocess events read la3_start_event, la3_start_event_2 … _12 (all twelve
   visible, none repeated); events in lane Lane_1cofr07 read lan_start_event, lan_start_event_2, lan_start_event_3,
   lan_start_start, lan_message_event … No la3_ label equals a lan_ label.
2. End-event column (my crop): lan_end_event, lan_end_event_2 … _6 and one la3_end_event — the previously duplicated
   lan_end_event now appears once, its subprocess twin reads la3_end_event.
3. Lane "Lane" (Lane_1vakzes) band (my crop): la2_1_activity, la2_3/4/5/6/7/8/9/11/12_activity, la2_gw_gateway,
   la2_link_event — keeps la2_ as the criterion states.
4. Nothing else changed: pixel diff vs T-1264's shots (docs/reports/T-1264-evidence/kitchen-sink-W.png), threshold 24,
   40px cells: 1024 → 0 changed cells; 1440 → 11 cells; 1920 → 13 cells; none in the header/toolbar (y<80) nor in the side
   panels (x<220 or x>1500). Toolbar, notices and panels look identical in the full-page shots.
5. Cross-check: golden tests/goldens/third-party/kitchen-sink.bpmn.golden has no repeated id attribute
   (sort|uniq -d empty); harness tools/_t1102-unique-display-ids-cdp.mjs re-run by me: rc=0, "ok": true.

## Caveat (not a defect of this change)
At 1024 and 1440 the fit-zoom labels are ~5-7 px and not legible by eye; legibility of the ids is shown via the 1920 crop.
The ids are model data independent of viewport width (same golden, same harness), and the 1024/1440 shots show no
non-label change. Verdict: green.
