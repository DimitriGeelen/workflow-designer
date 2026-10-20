# T-1222 Human AC#1: independent review of the amended shape (revision 39a44de8)

Reviewer: judge-t-1222-r3-cceb9cd5d157 (rung-3-termlink-single-reviewer). I only read files. I looked at the task file at 39a44de8
(`## Context`, `## Decisions` both entries), `src/aef-workflow-designer.html` at 39a44de8,
`tests/fixtures/third-party/*.bpmn` (parsed with ElementTree) and `tools/_t1222-event-definitions-kept.py`. I did not
run the guard, because the fix is not built, so the guard is red by design.

## Verdict: amber

The amendment answers the prior amber's three items: boundary hosts are restored, typing is limited to catch hosts,
and the open question is ruled. The ruling is sound. But the amended part 2 now lists **start** as a catch host for
typing, and that reproduces the tag-flip defect T-237 guards against. Two smaller points are left open as well.

## Evidence

### Definitions by host (fixtures, 49 total)
startEvent 15 (message 4, timer 3, error 1, signal 3, conditional 3, escalation 2, compensate 1), endEvent 8,
boundaryEvent 14, intermediateCatchEvent 5, intermediateThrowEvent 5.
The 14 boundary events are all in kitchen-sink. 9 of them have no `cancelActivity` attribute and 5 have `cancelActivity="false"`.

### Part 1, preservation plus referenced root elements: holds
The guard counts definitions per kind, fails on a dangling messageRef/signalRef/errorRef/escalationRef, and now also
fails on a definition whose parent is not `*Event`. The 47-vs-49 count is explained in the Agent AC.

### Claim "every third-party intermediate event imports as a link event": verified
src:13253-13254 map `REVERSE_TYPE['intermediate{Throw,Catch}Event']` to linkEventThrow/linkEventCatch. Only a consumed
`aef:eventDef` overrides this (src:13461-13472).

### DEFECT: typing a startEvent flips its tag
The amendment says: "Part 2 applies to catch hosts (intermediate catch, start, boundary)". But
TYPE_TAG maps eventError/eventTimer/eventMessage to `'intermediateCatchEvent'` (src:12017-12019), and export emits
`TYPE_TAG[n.type]` (src:12545), turning it into boundaryEvent only when a hostRef is present (src:12550-12557). A third-party
`startEvent` + timer/message/error definition (8 of them in the fixtures: message 4, timer 3, error 1) typed as
eventTimer/eventMessage/eventError would therefore save as `intermediateCatchEvent`. The process loses its start event,
and the validators key on `type === 'startEvent'` (e.g. src:10562 startIds). This is the same flip as the throw case. The
existing import deliberately excludes startEvent from typing: `_catchHost` = intermediateCatchEvent | linkEventCatch |
boundaryEvent (src:13467), and the T-259 comment (src:13476) names "startEvent / intermediateThrowEvent hosts" as
not consumed. The guard would not catch this, because the definition's parent still ends in "Event".
**Needed:** drop "start" from part 2. Start events stay `startEvent` and keep their verbatim definition untyped (the
designer has no typed start vocabulary), the same as end events.

### Open point: untyped boundary events need an export path that does not exist yet
Export emits `boundaryEvent attachedToRef` only `if (EVENT_KIND[n.type] && n.aef.hostRef)` (src:12550). 9 of the 14
boundary definitions (cancel 1, compensate 2, conditional 2, escalation 2, signal 2) have no designer type. Under the
ruling they become a "plain catch". As the export stands, they would save as in-flow `intermediateCatchEvent` with no
attachedToRef, and the guard passes that. The amended text ("keeping its original tag") implies the fix, but the
shape should say outright that the plain-catch rendering carries hostRef and exports
`boundaryEvent attachedToRef cancelActivity`, like the typed boundary events.

### Open point: the guard and Agent AC#4 do not pin the boundary restoration
- The guard checks only that the parent ends in "Event". It does not check that the parent tag is unchanged, or that a boundary
  event keeps its attachedToRef. A boundary flattened to intermediateCatchEvent passes, as does a start flipped to a catch (see
  above). Export also degrades a dangling hostRef to the in-flow tag (comment at src:12546-12549). The prior reviewer
  suggested this check. The amendment chose a weaker one.
- Agent AC#4 still says third-party goldens change "only by the definitions (and their referenced root elements)
  coming back". Restoring boundaryEvent/attachedToRef also changes serviceTask to boundaryEvent, and export always writes
  `cancelActivity="${interrupting}"` (src:12556), which adds `cancelActivity="true"` to the 9 boundary events that had none.
  That matches the BPMN default, so the meaning is unchanged, but the bytes are new. AC#4's wording needs to admit both.

## Ruling on the open question (confirmed)
**Plain catch/throw rendering, not a new generic type.** The node keeps its original tag (intermediate catch/throw,
boundary, start, end) and its verbatim definition, has no link jump/target UI, and shows its kind read-only. No palette
type is added, because the designer cannot bind signal/escalation/conditional/compensate/cancel/terminate (no aef field,
no validator rule), and T-190 IW-1 keeps designer-authored maps off native definitions.

## What is needed for green
1. Part 2: limit typing to intermediateCatchEvent and boundaryEvent hosts, matching `_catchHost` at src:13467. Remove "start".
2. State that the untyped plain catch on a boundary host exports as boundaryEvent + attachedToRef + cancelActivity
   (the export condition at src:12550 has to widen beyond EVENT_KIND).
3. Tighten the guard so each definition's parent local tag is unchanged from the fixture, and a boundary event keeps
   attachedToRef. Then the start-flip and the boundary flattening both go red.
4. Amend Agent AC#4 so it allows the boundaryEvent/attachedToRef restoration and the added `cancelActivity="true"`.
