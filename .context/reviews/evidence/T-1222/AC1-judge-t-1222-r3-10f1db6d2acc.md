# T-1222 Human AC#1: independent review of the shape at revision c37c56e6 (third round)

Reviewer: judge-t-1222-r3-10f1db6d2acc (rung-3-termlink-single-reviewer). I read the task file at c37c56e6
(`## Context`, all `## Decisions` entries, the Agent ACs) and `src/aef-workflow-designer.html`. I parsed
`tests/fixtures/third-party/*.bpmn`, looked at `tests/goldens/third-party/kitchen-sink.bpmn.golden` and read and
ran `tools/_t1222-event-definitions-kept.py`.

## Verdict: amber

The second amber's four items are closed, and the ruling on the open question holds. One new gap remains. Part 2's
promise that "no `aef:eventDef` is added to a third-party file" does not match how the export works today, and the shape
does not say how the build will make it true.

## The previous amber's items: all closed
1. Typing is limited to intermediateCatchEvent/boundaryEvent hosts. This matches `_catchHost` (src:13462). Start and throw
   events keep their tag. Done.
2. An untyped boundary event exports as boundaryEvent + attachedToRef + cancelActivity, which needs the export condition at
   src:12550 to widen. Now stated. I also checked the 5 kitchen-sink boundary events with `cancelActivity="false"`.
   The importer reads cancelActivity for any node with attachedToRef, typed or not (src:13491-13494), and the export
   honours `interrupting === 'false'` (src:12555). So non-interrupting events survive, and only the 9 that had no
   attribute gain `cancelActivity="true"`, as AC#4 now allows.
3. The guard now matches each definition to its host by definition id. It flags a host-tag change and a boundary event
   that lost its attachedToRef. All 49 fixture definitions carry an id (grep finds no `*EventDefinition` without `id=`),
   so the id match skips nothing.
   I ran the guard on the current code: rc=1, "total 49 -> 3", 10 losses. That is red, as expected before the fix.
4. AC#4 now admits the boundaryEvent/attachedToRef restoration and the added `cancelActivity="true"`. Done.

## Part 1 (preservation plus referenced root elements): holds
The guard fails on a loss per kind, on a dangling messageRef/signalRef/errorRef/escalationRef, on a definition outside an
event, and on a host-tag change. None of the fixtures uses compensate `activityRef`, so the REF set is enough for this corpus.

## Part 2, the new gap: a typed event always emits `<aef:eventDef>`
- `aefExtensionXml` (src:12157-12164) says: "Always emitted for a typed event so re-import can recover the type".
  `if (EVENT_KIND[node.type])` writes `<aef:eventDef kind=… binding=…/>` unconditionally.
- So if a third-party timer, message or error catch or boundary event is typed eventTimer, eventMessage or eventError
  (part 2), the save gains an `<aef:eventDef kind="timer" binding=""/>` line. The current kitchen-sink golden has
  0 `aef:eventDef`. The shape says this will not happen ("no `aef:eventDef` is added to a third-party file, so its bytes
  change only by what was dropped coming back"), and AC#4 does not list it as an allowed change. The shape does not say
  how the build will suppress it.
- Suppressing it has a cost the shape does not cover. The binding fields (timerSpec, busTopic, errorStatus) ride only
  on `aef:eventDef`. If the export leaves it out for a natively typed node, a user's edit to that binding on a
  third-party event is silently lost on save. That is the same class of silent loss this task fixes.
- The guard counts only native definitions, so it cannot see either outcome. Only the diff-by-diff review under AC#4
  would catch it.

## Ruling on the open question (confirmed, unchanged from the earlier rounds)
Plain catch/throw rendering, not a new generic type. The decision as recorded is sound. The node keeps its tag and its
verbatim definition, has no link semantics, and no palette type is added. The designer cannot bind signal, escalation,
conditional, compensate, cancel or terminate, and T-190 IW-1 keeps designer-authored maps off native definitions.

## What is needed for green
Record one rule in `## Decisions` for a node typed from a native definition. Recommended (a): omit `aef:eventDef` while
the binding is empty, so the native definition carries the type and re-import types from it again; emit it once the user
sets a binding, and admit that line in AC#4. Alternative (b): always emit it and amend part 2's byte claim and AC#4 to
allow it. Either way, say which, and make the AC#4 diff review (or the guard) check that an open-and-save without edits
adds no `aef:eventDef` to a third-party file (under (a)).
