# T-1094 — What should the step number in a node id count? (inception)

Origin: Greenfield T-172 item 2b (split from T-1088). Evidence: their map
`build/evergreen-intake/resend-20261008/unpacked/T-172-designer-requests/T-172-designer-requests/after-owner-straightened.bpmn`.

## The problem, measured

`computeDisplayId` (`src/aef-workflow-designer.html:2155`) builds `<lane abbr>_<seq>_<slug>`, where
`seq` is the node's 1-based rank by x among **all** nodes in its lane: tasks, gateways, start and end events.
In Greenfield's map:

| Lane | What the owner sees | Why |
|---|---|---|
| Salesforce | tasks numbered 1, 2, 4, 5 | the parallel gateway `sal_3_tegelijk` takes 3 |
| Verkoper | first task is `ver_2_lead`; "start + first task look unnumbered" | the start event takes `ver_1` |
| Verkoper, Novis | end events numbered (`ver_11_einde`, `nov_2_klant`) | same rule |

The owner reads the number as "step N of the work". The code means "position N in the lane".

## The constraint

This same string is the **BPMN id** on export (`displayIdOf` at :12207, flowNodeRef :12181, DI shapes
:12350). Changing the scheme changes the ids written into every re-saved map.

But those ids are **already unstable today**: `seq` is a rank by x, so moving, adding or deleting any
node in a lane renumbers its neighbours on the next save (`refreshDisplayIds`, :2181). Ids are not a
stable key now. Determinism (same map → same bytes) is guarded by `_t358` and the tie rule by `_t364`;
both keep holding under any option below, since every option is still a pure function of the map.

## Options

1. **Leave it; document it.** The number means position in the lane. No change, no id churn.
   Greenfield's owner keeps reading 1, 2, 4, 5 as a gap.
2. **Activities only (recommended).** Tasks, send/receive/user/service/script tasks, call activities and
   sub-processes take the step number, counted in x order. Events and gateways get a type word instead:
   `ver_start_lead`, `sal_gw_tegelijk`, `ver_end_einde` (de-duplicated with a suffix when a lane has two).
   Salesforce would read `sal_1 … sal_4` with no gap; Verkoper's first task becomes `ver_1_lead`.
   Cost: re-saved maps get new ids for every node after the first event or gateway in a lane, a one-time
   change of the same kind a node move already causes. Tests that pin exact ids need their expectations
   updated, not their logic.
3. **Keep the ids, change only the visible badge.** The id stays position-based; the badge on the canvas
   shows an activity-only step number. No id churn, but the canvas then shows a number that is not the
   node's id, and the details panel and exported file disagree with the canvas. Two numbering systems.

## Recommendation

**DEFER until AEF answers IW-3 (can it follow a one-time rename of task-lifecycle's node ids?); then decide
between option 2 with a coordinated migration, option 2 with task-lifecycle exempt, or option 3.**
IW-1 is answered (2026-10-13, see "Who keys on node ids" below): Greenfield keys on nothing, but the
task-lifecycle map's node ids are used as task positions by AEF and by 832 itself.

The original case for option 2 still holds:
The ids are not stable today, so option 2's churn is no worse than what every layout edit
already does, and it removes the misreading at its source. Option 3 trades one confusion for another.

What we bet: owners read the number as a step count, and nothing outside the designer keys on node ids
across saves. Not yet confirmed: Greenfield's DM 61 says their generators stamp the *map* id (their T-189);
whether anything of theirs keys on *node* ids is unasked. Ask them before the build. Measurable: Greenfield's
re-test of the same map reads 1..n per lane with no gaps, and `_t358`/`_t364` stay green.

## Who keys on node ids (IW-1, measured 2026-10-13)

| consumer | keys on node ids? | evidence |
|---|---|---|
| Greenfield | no | sidecar cf5afe0b: doc-merge matches by name; their generators overwrite the ids of maps they publish; links use map ids; lane checks use lane ids; "a one-time id change on re-save is fine" |
| AEF (framework) | yes, task-lifecycle only | `lib/instance-position.sh` (pristine AEF 1146a7450) names 6 frw ids as the positions a task is at (frw_3_start, frw_4_enter, frw_6_run, ...) |
| 832 (local framework fix) | yes, task-lifecycle only | `update-task.sh` 9 refs (frw_7_all, frw_9_human, frw_11_task, ...) |
| 832 task records | yes | 186 task files carry `current_node: frw_*` (170 `frw_11_task`) |
| 832 teeth | yes | `_t880`, `_t881`, `_t882`, `_t883`, `_t923` |

Option 2 renames every id in the task-lifecycle `frw` lane: activities renumber (frw_3_start -> frw_1_start,
frw_6_run -> frw_3_run, ...), events and gateways get a type word (frw_7_all, frw_11_task, ...). 7 of the 11 are
referenced above. The renumbering also reuses old numbers for other nodes (frw_3_ was "start", becomes "run"),
so a migration must map names, not numbers. These ids already change if anyone moves a node in task-lifecycle
and re-saves; they stay put today because nobody does.

The remaining choice: (a) option 2 plus a coordinated one-time migration (AEF's lib, our update-task.sh, the
records, the teeth); (b) option 2 with maps whose ids are used as positions exempt (task-lifecycle keeps its
ids); (c) option 3. Asked AEF (IW-3) which it can carry.

## Open sub-question for the build task

Should boundary events (attached to a task) share the task's number (`ver_3a_…`) or take the type word? The
evidence map has none, so this can wait for the build.

## Dialogue Log

- 2026-10-12 (session S-2026-1012): converted from build to inception because the choice changes saved ids
  and is the operator's; options and recommendation written for the operator's decision.
- 2026-10-13: the operator pointed out the task was handed over while Watchtower itself said "Not ready for
  your decision" (no Hypothesis; an open evidence question). The agent had not opened the readiness check before
  sending the link. Fixed: Problem Statement, Hypothesis, Open Questions (IW-1 open, IW-2 deferred), Go/No-Go
  criteria added; recommendation changed GO -> DEFER until IW-1 is answered.
- 2026-10-13: Greenfield answered (sidecar cf5afe0b): nothing of theirs keys on node ids. Before handing over a
  GO, the agent checked the consumers it had not asked and found AEF's lib/instance-position.sh and 832's own
  update-task.sh, task records and teeth keyed on task-lifecycle's node ids. Recommendation stays DEFER; IW-3
  asked of AEF.
