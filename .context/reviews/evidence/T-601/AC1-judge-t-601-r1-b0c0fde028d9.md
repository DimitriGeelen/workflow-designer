# T-601 AC1 — independent review (dispatch judge-t-601-r1-b0c0fde028d9)

Revision reviewed: 403d24492ad0e5b8861fc972be4d9ddbd9a8eada (worktree editor byte-identical to that commit).
Criterion: [REVIEW] Labels stay inside the lane they belong to, and the map is no less readable for it.

**Verdict: RED.** The lane header part is fully met. The "own lane" part and the "no less readable / not a
worse position" part are not met on real corpus maps.

## What I checked

1. **Producer harness.** `node tools/_t601-lane-boundary.mjs --self-test` → PASS. L1–L6 live, and L1/L2/L3/L6
   fail under the poison arm. That proves the scripted cases only: one moved node plus the default map's x-edge.
2. **Producer screenshots** (docs/screenshots/T-1068, .context/working/t601-*): read. The operator's case is
   fixed: the label no longer sits on the HUMAN SOVEREIGNTY header or the divider. Its outgoing edge now runs through
   the 3-line block. That is a trade, and it reads acceptably.
3. **My own probe on the real corpus** (`rev-probe-judge-t-601-r1-b0c0fde028d9.mjs`, kept here). It covers all 24
   examples/aef-processes/rendered/*.bpmn, loaded via adoptImportedXml, with wrap on. Furniture is read **from the DOM**
   (`g.lane-header > rect` = header strip + lane band), not from the scorer's own arithmetic. The probe measures every
   event/gateway label block (name lines + id badge). It ran on HEAD and on the pre-T-601 editor (a51e6235^).
   Raw output: probe-head-orig-judge-t-601-r1-b0c0fde028d9.txt, probe-pre601-orig-judge-t-601-r1-b0c0fde028d9.txt.

| 141 event/gateway labels | pre-T-601 | HEAD |
|---|---|---|
| on lane header strip | 13 | **0** |
| outside pool | 18 | **0** |
| extends past own lane band | 26 | **9** |
| label line under another node's shape | 4 | 4 (different labels) |
| label∩edge-segment crossings | 93 | 68 |

Stress run with every event/gateway renamed to the 73-char operator sentence:
header 17→0, lane 53→16, pool 25→1, crossings 199→149.

Overall this is a large improvement. But the criterion is per-label, and these labels fail it:

## Offending labels (HEAD)

- **session-capture / n_start "session end / context transition"** (AGENT INITIATIVE lane) — before T-601 it sat
  left of the event on the header strip, but was fully legible (rev2-session-capture-n_start-before-*.png). Now it sits
  below, and its tail is drawn **under the "scan conversation…" task box**, so only "session end / con" is visible. Its
  id badge runs into the neighbour's badge as "agt_1_sessicagt_2_scan" (rev2-session-capture-n_start-after-*.png).
  The new position is worse.
- **git-commit-flow / n_start 'git.sh commit -m "T-XXX: …"'** (AGENT INITIATIVE) — same pattern. The label tail runs
  under the "parse and check_git…" task box (rev2-git-commit-flow-n_start-after-*.png). Before T-601 it was left, on the header.
- **arc-lifecycle / n_req "Arc proposed (headline mechanic identified)"** (AGENT INITIATIVE) — placed right, as a wrapped
  block. The connector arrow runs through it, and "headline" runs under the "Create arc" task box
  (rev2-arc-lifecycle-n_req-after-*.png). Before T-601 it sat below, hanging past the pool floor but legible.
- **session-capture / g_found "uncaptured items found?"** (AGENT INITIATIVE overlapping FRAMEWORK AUTHORITY) — **new
  divider crossing**. Before T-601 it was one line inside its lane (rect y 143–169, band 62–170). At HEAD it is a
  2-line wrapped block (y 143–181), with the id badge on the divider in the next lane
  (rev2-session-capture-g_found-after-*.png). The cause: the T-1067 wrapped-block candidate is accepted when its score
  is strictly better, even though it now leaves the lane. This is not "below as before".
- **8 other below-placed labels still extend into the next lane**: healing-loop n_trigger (into AGENT INITIATIVE,
  with 3 edge crossings, rev2-healing-loop-n_trigger-after-*.png), cross-host-dispatch n_send, inception-review
  n_request, inception-review n_end_defer, session-handover n_end and n_episodic_gate, task-lifecycle n_partial_check,
  verification-gate n_partial. Most of these the criterion's own exception covers ("nowhere clean to go → below as
  before"). Three of them (n_send, n_request, healing n_trigger) used to go left onto the header and now hang into the
  lane below instead. I judge that an acceptable trade.

## Why red, not amber

The criterion has two parts: labels stay in their own lane, and the map is no less readable for it. The If-not clause
treats any single offending label as a failure. On shipped corpus maps there is one new divider crossing that is not
covered by the exception (g_found). Three labels were legible before and are now partly hidden under a task box or
struck through by an edge. That is the "worse position" the Expected rules out. The cause is in the scorer: a node-box
overlap costs 1 per line, and header plus out-of-pool costs 2 per line, so an occluded below or right placement beats a
legible but misplaced one. The final x-nudge (T-1068) could have made a wrapped below block clean, but the scorer
never considers it.
