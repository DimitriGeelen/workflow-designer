# T-368 Human AC#2 — "Is a notation/routing revision actually planned?"

Reviewed revision: 49e8fe2777ddee255b26b43e7c708bb222e1b03c. Verdict: **escalate**.

## Why this needs the operator

The criterion asks what the operator intends for the notation and routing: "confirm or deny that a notation/routing revision is planned". That is a project-direction call. The repository can show what was built; it cannot show what the operator plans. The criterion itself exists because the agent searched the task tree, found nothing, and still needed the operator's word.

## What I checked

- **No operator answer is recorded.** `grep -rn T-368 .context/project/*.yaml` finds only the G-024 concern. No PD entry in `decisions.yaml` answers this question. The criterion is unticked in the task file.
- **`docs/reports/T-1065-operator-queue-triage.md:35`** lists this criterion as "kept LIVE (only you know the plan)" with a proposed answer "No further revision planned. AEF keeps drafting in the current notation." That is an agent's recommendation waiting for the operator, not a ruling.
- **`docs/reports/T-1149-observation-triage.md:97`** dismisses an observation on the grounds that T-368 is work-completed "so the queued question is closed". That concerns the 0.9.0 question and does not answer this one.
- **Routing work did ship after the criterion was written.** T-1090 (completed 2026-10-08, PD-360/PD-361) added a routing rule and a Settings toggle `routingPrefs.crossLane`. T-1090's task file has no mention of `aef:routing`, `routingHint`, `loopDetour` or `anchors`, so I see no sign it touched the frozen standard's §1 presentational clause; I did not audit its diff.
- **Active tasks named for notation or routing today:** only T-599 (manual connector routing: add/remove waypoints), status `captured`. Whether T-599 counts as a planned "revision" in the sense AEF's operator meant is again the operator's to say.

## What the operator is asked

Answer once, yes-with-scope or no:
1. Is a notation/routing revision planned beyond what already shipped under T-1090?
2. If yes, does it touch lane semantics, cycle/return-edge authoring, or the §1 presentational clause (`aef:routing` / `routingHint` / `loopDetour` / `anchors`)?
3. Does T-599 (captured, not started) count as such a revision?

The urgency in the criterion ("tell me today") dates from 2026-08-08; AEF's mid-draft 3-lane map of that day has long since been settled one way or the other, so the answer now matters for the record and for future AEF drafting, not for that draft.
