# T-1472 Human AC#1 — independent review (revision 59bb6ba8)

Judged the six supplied images in docs/reports/T-1472-shots/ (copies alongside this report). Did not re-run the app (image evidence, per brief).

## Before (fit, all widths)
- 1024: whole map squeezed into ~460 px of canvas; node text and lane names are unreadable (a few px tall). Large empty canvas below.
- 1440 / 1920: whole map at fit; node names are tiny (1440 barely legible, id captions illegible; 1920 node names marginally readable, id captions not).

## After (100%, top-left)
- 1024: zoom readout 100%. Pool title, lane names (HUMAN SOVEREIGNTY / FRAMEWORK AUTHORITY / AGENT INITIATIVE), start event "Investigation requested", "Load context bundle", "Decompose problem" and their id captions all clearly readable. Start event and first two steps in view, flow arrows lead the eye right/down. Sensible start.
- 1440: readable; start through Fan out, the three parallel searches, Join, and part of "Synthesize findings" in view; loop edge "insufficient · loop" legible. Horizontal scrollbar signals more to the right.
- 1920: readable; nearly the whole flow through "Sufficient?", "Write report", "Human review & route" in view; only the two end events lie off the right edge.

## Anything worse?
- No readability regression: every element legible in after is either illegible or smaller in before. Toolbar, palette and inspector unchanged.
- Expected trade-off: at 100% the far-right part of the map (end events) is off-screen at all widths, and at 1440 the right panel-collapse handle sits over the edge of "Synthesize findings". Acceptable for an opening view that starts at the start event.
- Observation (not judged a regression of this criterion): the display-id captions under the three stacked search tasks are numbered differently across shots (1440-after: codebase=agt_2_search, episodes=agt_4_search-2; 1920-after: codebase=agt_4_search, episodes=agt_2_search-2; both befores: codebase=agt_3_search). Captions read fine at every width; the numbering inconsistency is worth a look by the agent (may relate to T-1474's zoom-dependent label pass or to refreshDisplayIds tie-breaking on equal x).
- Minor: the id caption under the top search node sits close to the next node's top border at 100% (e.g. 1440 "agt_2_search" touches "Search episodes"); also present in before.

Verdict: green.
