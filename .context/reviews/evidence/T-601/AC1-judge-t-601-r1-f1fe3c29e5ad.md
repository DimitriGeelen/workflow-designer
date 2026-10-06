# T-601 AC1: independent review (dispatch judge-t-601-r1-f1fe3c29e5ad)

Revision reviewed: e21a395a30d2eaf8a00a7d7dae8ab568295cd809. The working-tree editor is byte-identical to that commit (cmp).
Criterion: [REVIEW] Labels stay inside the lane they belong to, and the map is no less readable for it.

**Verdict: AMBER.** Every point the previous RED raised is fixed. One shipped-corpus label still sits on the
grey lane header strip, which the Expected rules out without exception. It is session-capture/n_start, and it is
exactly the Step-1 scenario: a node at the pool's left edge with a long name.

## What I checked
1. **Corpus probe, all 24 rendered maps, 141 event/gateway labels.** Wrap on, viewport 1600x1000. The lane
   furniture is read from the DOM (g.lane-header > rect). I used the earlier reviewer's probe script, which I read in
   full before running it. I ran it myself on HEAD and on the pre-T-601 editor (a51e6235^). Raw output:
   probe-head-orig-judge-t-601-r1-f1fe3c29e5ad.txt and probe-pre601-orig-judge-t-601-r1-f1fe3c29e5ad.txt.

| metric | pre-T-601 | e21a395a |
|---|---|---|
| label line under another node's shape | 4 | **0** |
| on lane header strip | 13 | **1** |
| extends past own lane band | 26 | 7 |
| outside pool | 18 | 3 |
| label/edge crossings | 93 | 79 |

   Stress run (every label renamed to a 73-char sentence): header 17 → 2, lane 53 → 9, pool 25 → 2, under-shape 14 → 13.
2. **The 7 remaining lane overhangs.** These are arc-lifecycle n_req, git-commit-flow n_start, inception-review
   n_end_defer, session-handover n_end and n_episodic_gate, task-lifecycle n_partial_check and verification-gate n_partial.
   All are below-placed and legible. Six have exactly the same rect as before T-601, so the criterion's own
   exception covers them ("nowhere clean to go → below as before"). git-commit-flow n_start used to sit left, on the
   header. It now wraps below and hangs past the pool floor, still legible: git-commit-flow-n_start-head-judge-t-601-r1-f1fe3c29e5ad.png.
   arc-lifecycle n_req is back below with the same rect as before (arc-lifecycle-n_req-head-judge-t-601-r1-f1fe3c29e5ad.png).
3. **Previous RED items.** No label is hidden under a task box any more (0). g_found is one line inside its lane:
   it no longer appears in the violation list.
4. **The operator's case and the T-600 screenshots.** .context/working/t601-after.png: the long label sits right of the
   event, inside HUMAN SOVEREIGNTY, clear of the header and the divider. The tools/_t601-lane-boundary.mjs and
   tools/_t1068-corpus-labels.mjs self-tests both pass, and their poison arms fail as they should.

## Offending label
- **session-capture / n_start "session end / context transition"** (AGENT INITIATIVE lane). It is placed left of
  the event, at rect x -68..82, on the header strip (header x 30..90) and outside the pool. It is drawn over the
  "AGENT INITIATIVE" header text: session-capture-n_start-head-judge-t-601-r1-f1fe3c29e5ad.png. This is its pre-T-601 position, so it has not
  got worse. But the Expected says "No label overlaps the lane header strip", and when a label has nowhere clean to
  go it should fall back to **below**, not to the header. The producer states this cost openly. Their new leg C3
  writes it in as an allowance ("limit 1"). That makes the gate accept the violation; it does not remove it.
- **Was a clean spot available?** Geometry measured in the DOM: the node is at 90..126 x 98..134, the lane band is
  62..170, the next task n_scan is at 170..280 x 84..148, and the header ends at x 90. A 2-line wrapped block below
  the node, "session end /" (70px) and "context transition" (97px), starting at about x 92, y 138, clears the task
  (line 2 sits below the task floor at y 148). Only the id badge would cross the divider at 170, by a few px. That is
  the "below as before" fallback the criterion asks for, and it is legible. So the claim that "nothing else in that
  corner is readable" does not hold.

## Why amber, not red or green
Everything the previous RED named is fixed, and nothing has regressed against pre-T-601. One label still breaks an
explicit rule of the Expected. It is a single, well-defined case with a nearby fix.

## Needed
Move session-capture/n_start off the header strip. Use the wrapped-below block, nudged right of the header, and accept
a badge overhang into the next lane as "below as before". Or score the header strip higher than a small lane overhang.
Then tighten C3 to limit 0 and recheck the corpus for nothing under a shape.
