# T-1428 Human AC#1: the recorded path and its legend. Reviewer judge-t-1428-r3-29a86afc96a4

Revision reviewed: cf836e5cdd1722bf1b7b038ddac5ed55c5796fb1 (HEAD at review time; the six t1428-recorded files are
committed and unmodified in the working tree).

## What I opened

- `docs/reports/t884-shots/t1428-recorded-{1024,1440,1920}.png` (1024x900, 1440x900, 1920x900, map fitted). Copies:
  `t1428-recorded-{1024,1440,1920}-judge-t-1428-r3-29a86afc96a4.png`.
- `t1428-recorded-e_07.png` (480x316) and `t1428-recorded-e_09.png` (704x496), 100% close-ups. Copies:
  `t1428-recorded-e_07-judge-t-1428-r3-29a86afc96a4.png`, `t1428-recorded-e_09-judge-t-1428-r3-29a86afc96a4.png`.
- `t1428-recorded-title.txt`.
- My own enlargements of the loop region of each fitted shot (nearest-neighbour, no smoothing):
  `zoom-loop-fit-{1024,1440,1920}-judge-t-1428-r3-29a86afc96a4.png`.
- `tools/_t884-instance-overlay-cdp.mjs` lines 67-74 and 229-261, only to learn which route the fixture records
  (e_01, e_03, e_05, then e_06, e_07, e_09 twice) so I could check the picture against it. I did not re-run the script:
  it writes into docs/reports, outside what a reviewer may touch.

## Findings

1. Route reads as one route, distinct from untaken edges: MET at 1024, 1440 and 1920. The taken edges are a
   continuous green line Start -> Build-ready gateway -> Start work -> Perform the work -> Outcome? -> Enter issues ->
   back to Perform the work; every other edge is thin grey. Visible even at 1024, where the map is about 475 px wide.
2. Not louder than the current node: MET. The current node (Perform the work) carries a bright lime ring and the
   lime "T-9991" tag; the route is a darker, mid green. The current node is the brightest thing on the map at all
   three widths.
3. "x2" legible beside its edge, not colliding with the edge label: MET in the 100% close-ups. Three x2 pills, one
   each on e_06 (vertical leg above Perform the work), e_07 (left of the leg above Outcome?) and e_09 (on its top
   horizontal leg), matching the three edges the fixture takes twice. In e_07 and e_09 the pill beside e_07 sits
   left of the "blocked / failing" label with a clear gap of about 20 px; no pill touches "resume after healing
   (issues -> started-work)", a node, the check badge or another pill.
4. Title says "recorded": MET. All three widths give "... ✓ recorded path (the edges this task took, ×N where it
   took one more than once) · 1 hop not on this map · 1 recorded edge not in this map version ...".
5. Nothing clipped: MET. The whole map is inside the canvas at all three widths; the toolbar wraps to two rows at
   1024 with every control whole; the picker text "T-9991 · agt_2_perform · started-work" is whole.
6. "The route AND ITS COUNT read at all three widths" (the Expected clause): NOT MET AS WRITTEN for the count.
   In the fitted shots the pill is about 15 px wide at 1920 (x2 just guessable), about 9 px at 1440 (a pill shape,
   digits not readable) and about 5 px at 1024 (a green dot). See `zoom-loop-fit-*-judge-t-1428-r3-29a86afc96a4.png`. This is the fit scale,
   not a defect of the pill: no node name is readable at 1024 fitted either. The criterion's own step 1 says the
   close-ups are "where the ×2 pills are readable", so the Expected clause asks more than its steps supply. The two
   close-ups are one zoom level and say nothing per width.

## Observation outside the criterion

The label "resume after healing (issues -> started-work)" belongs to e_09 but sits directly above the horizontal leg
of e_06, so it reads as e_06's label. That is flow-label placement, not the instance overlay, and the criterion does
not ask about it.

## Verdict: amber

Everything the steps ask is met. The Expected clause, read literally, is not: the count does not read at 1024 or
1440 in the fitted shots. Either the operator accepts the restatement in the guidance (then the evidence meets it as
it stands, no rework), or the producer adds a 100% close-up of the loop at each of 1024, 1440 and 1920.
