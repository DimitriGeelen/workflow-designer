# T-1222 Human AC#1: independent review of the proposed shape (2026-10-20)

Reviewer: judge-t-1222-r3-eaf12fa706a0, revision 8016e7cb. Read-only review of the task file, `src/aef-workflow-designer.html`,
`tests/fixtures/third-party/*.bpmn`, `tests/goldens/third-party/*.golden` and `tools/_t1222-event-definitions-kept.py`.

## Verdict: amber

The two-part shape is right in principle, but it was scoped around intermediate events only. Most of the definitions sit on
other hosts, and two of those cases break the proposal as written.

## What I checked

### Where the definitions actually sit (fixtures, parsed with ElementTree)
Kitchen-sink plus collaboration-message-flows hold 49 definitions. By host element:
- startEvent 17 and endEvent 8: a definition is valid inside these, and preservation covers them.
- **boundaryEvent 14** (all in kitchen-sink): cancel 1, compensate 2, conditional 2, error 1, escalation 2, message 2, signal 2, timer 2.
- intermediateCatchEvent 5 (conditional, link, message, signal, timer).
- intermediateThrowEvent 5 (compensate, escalation, link, message, signal).

### Claim: "every third-party intermediate event imports as a link event"
Verified. `REVERSE_TYPE['intermediateThrowEvent'|'intermediateCatchEvent']` maps to linkEventThrow/linkEventCatch
(src:13253-13254). Only a consumed `<aef:eventDef>` overrides it (src:13461-13472). The kitchen-sink golden shows the throw
events saved as `intermediateThrowEvent id="lan_link_event_N"`.

### Gap 1: boundary events import as serviceTask (not addressed by the proposal)
`TYPE_TAG` has no `boundaryEvent` entry, so `REVERSE_TYPE['boundaryEvent']` is undefined and
`let type = REVERSE_TYPE[tag] || 'serviceTask'` (src:13367) applies. The importer reads `attachedToRef` into
`aef._hostDisplayId` (src:13490), but export only emits `boundaryEvent` + attachedToRef for EVENT_KIND types with a hostRef
(src:12550-12557). Evidence from the goldens:
`kitchen-sink.bpmn.golden:393  <bpmn:serviceTask id="lan_10_event" name="Event_11fzkjc">`. The fixture element
(kitchen-sink.bpmn:217) is a boundaryEvent attachedToRef="Activity_0djfr8f" carrying a cancelEventDefinition. The golden has
0 `attachedToRef` for both kitchen-sink (14 boundary events in) and boundary-events.bpmn (3 in).
Consequence: part 1 as written ("written back after incoming/outgoing") puts 14 `*EventDefinition` elements inside
`bpmn:serviceTask`. That is well-formed, which is all the prototype checked, but not schema-valid BPMN. The guard
would go green on it, because it only counts elements and resolves references. The shape has to say what happens to
these hosts: either restore the boundaryEvent tag + attachedToRef (type timer/message/error ones as the designer's
boundary typed events, which src:12546 already supports, and carry the other kinds neutrally), or carry the tag as
`foreignTag` (T-337 path). It must not write definitions into a task.

### Gap 2: typing a THROW host flips it to a catch (T-237 already found this)
Part 2 says "message → eventMessage". Every EVENT_KIND type exports as `intermediateCatchEvent` (TYPE_TAG, src:12017-12019),
and the T-237 comment (src:13455-13459) restricts typing to catch hosts for exactly this reason. Kitchen-sink has an
`intermediateThrowEvent` + messageEventDefinition. Typed per the proposal, it would save as a catch. That contradicts the
proposal's own claim that "its bytes change only by what was dropped coming back". Part 2 must be scoped to catch-side
hosts (intermediateCatchEvent, boundaryEvent). A message throw takes the neutral rendering, like the untyped kinds.

### Preservation and referenced roots
These are sound and already acknowledged. The guard checks dangling messageRef/signalRef/errorRef/escalationRef. The
47-vs-49 discrepancy is explained in the Agent AC (exact regex).

## Ruling on the open question
**A plain catch/throw rendering, not a new generic type.** The node keeps its original BPMN tag (catch or throw,
in-flow or boundary) and its verbatim definition, drawn as a neutral intermediate event. A new palette type would add
authoring vocabulary for kinds the designer cannot bind (no aef field, no validator rule, no fabric meaning). T-190 IW-1
keeps designer-authored maps off native definitions, and a new type would invite authoring them. The "plain" node must
also stop inheriting link semantics (no link jump/target UI) and must keep catch vs throw. The same neutral rendering is
the right home for a message throw (Gap 2). The kind can be shown read-only from the carried definition.

## What is needed for green
1. Add boundary hosts to the shape: no definition written into a serviceTask. Restore boundaryEvent + attachedToRef
   (+ cancelActivity), or use the foreignTag passthrough, and say which. Optionally extend the guard to assert each
   definition's parent tag is unchanged, so this cannot pass silently.
2. Scope part 2 to catch hosts, per T-237. Throw-side message/timer/error stay neutral.
3. Record the open-question ruling (plain catch/throw rendering) in Decisions.
