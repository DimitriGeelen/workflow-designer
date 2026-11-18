# T-368 Human AC#2: "Is a notation/routing revision actually planned?"

Reviewed revision: d2328fde63d9f8241c49d6443bf5d6bf55a26207. Verdict: **green**.

## What the criterion asks

Expected: "yes-with-scope, or no". It is a project-direction question that only the operator can answer; the earlier review (V-20261116-4b135262) escalated it for that reason. My job at this revision is to check that the operator's answer is recorded and that it answers the question asked.

## What I checked

- **An answer is recorded, and it is "no".** The criterion now carries "Operator ruling, 2026-11-18 (in session, answering the escalation above): 'a' — NO. No notation or routing revision was planned in August 2026 and none is planned now." It was added by commit `d2328fde6` (6 lines added to the T-368 task file, nothing else), authored under the operator's git identity.
- **It answers each part of the earlier escalation.** The escalation asked (1) is a revision planned beyond T-1090, (2) does it touch lane semantics, cycle/return-edge authoring or the §1 presentational clause, (3) does T-599 count. The ruling says no; says T-1090 (PD-360/361) and T-599 are incremental refinements that do not count; and says none of the three areas change.
- **The ruling is consistent with the task tree.** T-599 is `captured` (not started) and is the only open task whose name is about routing or notation (`grep` over `.tasks/active` names for notation/routing/lane semantic with status captured or started-work). T-1090 is `work-completed`. Neither file, nor T-286, T-102 or T-289, mentions `aef:routing`, `routingHint`, `loopDetour` or `anchors` (0 hits each).
- **The "If not" branch does not apply.** It fires only if a revision IS planned. With "no", the RAIL-444 advice to AEF ("draft into the current notation") stands and no correction is owed, as the ruling states.

## Limit of what I verified

The ruling is described as given in session. No `resolve-escalation` row exists in `.context/reviews/` for V-20261116-4b135262, so the only record of it is the task-file line and commit `d2328fde6` (operator's git identity, agent co-author trailer). I cannot verify the spoken ruling beyond that record. I did not audit T-1090's diff; I checked its task file only.
