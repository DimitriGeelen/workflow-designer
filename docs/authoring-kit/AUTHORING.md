# Authoring governed workflow maps — a guide for the agent that generates them

You are generating BPMN maps for the AEF Workflow Designer from some source: a conversation,
documents, code, an ontology, process descriptions. This kit exists because a real deployment
produced 26 maps that looked fine, saved 130 times without complaint, and carried **no
governance at all**: no map said what it was, and no task had a derivable owner. Nothing told
the generating agent. This guide, the validator beside it, and `CONFORMANCE.md` are what tell
you.

When this guide and the validator disagree, the validator wins and this guide has a bug.
Section 8 lists what the validator does **not** check, so you know where you are on your own.

## 1. The loop

1. **Write a candidate** map to a file.
2. **Validate it:** `python3 validate-workflow.py candidate.bpmn` (Python 3, standard library
   only; add `--json` for machine-readable findings). Exit **0** = clean, **1** = warnings only,
   **2** = errors. A wrong command line also exits 2, so if you see 2 with no ERROR line, check
   your invocation before your map.
3. **Read every finding.** `CONFORMANCE.md` lists every rule with its class.
4. **Fix only what the source lets you derive.** Declare the rest unknown (section 4). Section 5
   tells you exactly which warnings an honest map keeps, so you know when to stop.
5. **Publish** the validated file (save it through the designer or its API, commit it), then
   validate the published bytes again.

**About the save API.** Some designer servers return the validator's verdict in the `/api/save`
response under `validation`. Many do not yet. **No `validation` key means the server did not
validate: run the validator yourself.** `{"ok": false}` inside `validation` means it could not
run. Neither means the map is clean.

## 1b. The loop: generate, review against the source, correct, learn

A validator can only check structure. Whether a map is TRUE to its source (nothing invented,
nothing missed, unknowns declared, authorities right) takes a reviewer that reads the source.
The kit ships that loop:

```
GENERATE.md  you, from the source, citing it        -> map.bpmn
validator    the floor: structure and governance     (never the judge)
REVIEW.md    another agent, against the SOURCE       -> REVIEW.json   (rubric: RUBRIC.md)
CORRECT.md   you: apply or contest each finding      -> CORRECTIONS.json, with a lesson each
             ... re-review until a review round finds nothing
```

`loop.sh` runs it with any two agents you configure (see its header). Use a reviewer from a
different model or vendor than the generator.

**Where to run it.** `loop.sh` starts both agents itself, so run it from a plain shell or CI,
not from inside an agent session: an agent harness may refuse to start nested agents, and then
no review round runs at all. If you are the generating agent and cannot start the loop, write
your maps, then ask your operator to run `loop.sh` (or `loop.sh --review-only`, which reviews
and records maps you already wrote, without starting a generator).

**Reviewer context.** The reviewer reads REVIEW.md, RUBRIC.md, the source and the map in one
prompt. `loop.sh` prints the size of every review prompt; a reviewer whose context window is
smaller than that cannot read it whole, and its review means nothing. In practice allow at
least 16K tokens, more for long sources. A local model loaded at 4096 is too small. `loop.sh --calibrate` proves your reviewer still
catches the kit's planted defects and raises nothing on a clean map; run it when you change
reviewer, model or rubric. The `lesson` in every correction is how the loop improves: read them,
and when one recurs, it belongs in this guide, the rubric, or the validator.

**Cite your source on every element.** Each lane and flow node carries a `<documentation>` child:

```xml
<bpmn:task id="check-credit-limit" name="Check customer credit limit">
  <bpmn:documentation>source: "Credit control checks the customer's credit limit."</bpmn:documentation>
</bpmn:task>
```

or, when the element exists although the source does not state it:
`source: unstated - <why it exists anyway>`. The quote must be verbatim. This is what makes
"invented" checkable: every element either quotes the source or says that it does not.

## 2. What every map carries

`exemplar.bpmn` is a complete map that validates clean. Copy its shape.

- **The AEF namespace:** `xmlns:aef="http://anchorpoint.framework/aef/extensions"` on the root.
  The BPMN namespace may be prefixed (`bpmn:`) or the default; both are accepted.
- **`<aef:workflowMeta id="…" version="1" schemaVersion="2"/>`** in the process's
  `extensionElements`. Without it the map has no id of its own and no `kind`
  (`W-XML-NO-WORKFLOWMETA`). The validator checks only that the element exists and that `kind`,
  if present, is valid; supply `id`, `version` and `schemaVersion` anyway.
- **`<aef:laneMeta authority="…"/>`** in every lane's `extensionElements`
  (`W-XML-LANE-NO-AUTHORITY` if absent). Section 3 says which value.
- **Every flow node in a lane**, including events and gateways (`E-XML-NODE-UNASSIGNED`). The
  source rarely names a performer for an event or a gateway. Put it in the lane of the step it
  follows or decides about. That placement asserts no performer: only tasks are owner-bearing.
- **`<aef:uid value="…"/>`** on every node and every sequence flow, **derived from the source's
  own identity** (a requirement id, an ontology IRI, a step's stable key), never from a counter
  or a random value. A uid that changes when you regenerate makes every regeneration a new map,
  and the round trip loses its history. **When the source has no ids** (interview notes, prose),
  mint a semantic key from the step's own wording, lowercase and hyphenated
  (`check-credit-limit`), and a flow's uid from its endpoints
  (`check-credit-limit--decide-override`). Keep a key once published, even if the step's display
  name changes later: the key is identity, the name is presentation. Two steps that would get the
  same key are a sign that the source names one step twice, so look before you suffix one.
- Plain `<task>` is accepted, as are `userTask`, `serviceTask` and `scriptTask`.

## 3. What a lane is, and which authority it gets

A lane says **who performs** the work in it. Lane by performer, not by system or department
chart, unless the system IS the performer.

| the source says the work is done by… | `authority` | the task's owner |
|---|---|---|
| a named human role or department (sales employee, credit control, warehouse) | `sovereignty` | human |
| an automated system acting on its own rules (the ERP generates the invoice) | `authority` | agent |
| an AI or software agent that proposes or acts on initiative | `initiative` | agent |
| a party outside the organisation (carrier, supplier, customer) | `external` | none: no task is compiled |
| **nobody the source names** | `none` | none: `W-LANE-NO-OWNER` on each task |
| a system **supports** the step, but the source names nobody who performs it | `none` | none: put the step in the `none` lane and the system in a note (`System: Novis`) associated to the step |

A system that *supports* a step is a tool, not a performer: "the quote is approved in CPQ"
says where, not who. Only when the source makes the system the actor ("Novis creates the
production order") is it a lane of its own with `authority`.

**Precedence:** a task may carry its own `<aef:meta authority="…"/>`; when it does, that value
wins over its lane's. Use it only when the source assigns that one step to a different performer
than the rest of the lane. Otherwise let the lane speak.

Task type (`userTask` / `serviceTask` / `scriptTask` / `task`) is presentational. If it disagrees
with the authority you get `W-TYPE-LANE-MISMATCH` and the authority still wins. When the source
does not say how a step is performed, plain `task` is the honest choice.

## 4. Derive, never invent

This is the rule the 26 maps broke. A generator under pressure to produce a "complete" diagram
will make up what the source does not say. Do not.

- **An owner the source does not state stays unknown.** Put the step in a lane with
  `authority="none"`. Passive voice ("the order is closed") names no performer. Do not move the
  step into a plausible lane, and do not omit `laneMeta`.
- **This rule applies only to steps the source presents as part of the flow.** Reference
  material is not a step of unknown order: a command list, an option table, an example or a
  glossary does not belong in the map at all (rubric category `scope`). A loop once read a
  "Commands" section as two steps of unknown order and modelled them as unconnected tasks.
- **An order the source does not state stays unknown.** Do not connect the steps. Leave them
  unconnected, in the lane of their performer, and annotate them:

  ```xml
  <textAnnotation id="note_order">
    <text>Order relative to packing is not recorded in the source</text>
  </textAnnotation>
  <association id="assoc_1" sourceRef="note_order" targetRef="inspect"/>
  ```
- **Do not invent start and end events.** One start before every step with no predecessor and
  one end after every step with no successor turns one process into several parallel ones the
  source never described. Two ends are right when the source states two outcomes (an order is
  rejected or fulfilled), and wrong when they exist only to give orphans an exit.
- **One start and one end around a chain the source states are not invented.** When the source
  states an order (A precedes B precedes C) but no trigger and no outcome, a none start event
  before A and a none end event after C mark where the stated order begins and ends. They assert
  no trigger and no result. Cite them `source: unstated - marks where the stated order begins
  (ends); the source names no trigger (result)`. Do not name them as if they were a trigger
  ("Customer calls") unless the source says so. Leaving them out is not more honest: the
  validator then reports `W-XML-NO-START-EVENT` / `W-XML-NO-END-EVENT` for the map, because
  without them it cannot check reachability at all (section 5).
- **One step precedes two, and the source says nothing about how the two relate.** Draw a plain
  sequence flow from A to each of B and C, with no gateway. In BPMN that means both follow A
  with no order between them, which is what the source says. It also implies both always
  happen. If the source does not say that (it may be either/or), add a note associated to A:
  `Whether B and C both follow A, or only one of them, is not recorded in the source`. Never
  add an exclusive gateway, which invents a decision, or a parallel gateway, which adds nothing
  the plain flows do not already say.
- **A hand-over to a step in another map** is a link event, not a note. End the path in this map
  with an `intermediateThrowEvent` carrying
  `<aef:link targetWorkflow="<the other map's workflowMeta id>" name="<the other process's name>"/>`
  in its `extensionElements`, and start the receiving map's path with an
  `intermediateCatchEvent` carrying the same pair pointing back. The validator treats a throw as
  a terminus and a catch as an entry, so neither draws a reachability warning, and the designer
  can jump between the two maps. Cite the source line that states the hand-over. If the source
  names the other process but not the step it goes to, link to the process and say so in the
  citation.
- **Records a step creates or uses** (an order, a quote, a production order) go in a note
  associated to the step: `Creates: production order`, cited like any element. BPMN's
  `dataObjectReference` is valid and the validator accepts it, but the designer does not draw
  it, so a reader of the map never sees it. Use the note until the designer does.
- **Do not invent conditions.** Label each exclusive-gateway branch with the source's own words
  (`name="limit exceeded"`), not an executable expression the source never stated.
- **Merging branches:** use a converging exclusive gateway (two or more incoming flows, exactly
  one outgoing), or route the branches straight into the next step. Both are valid. An exclusive
  gateway with one incoming and one outgoing flow decides nothing and is refused
  (`E-XML-GW-OUTGOING`).
- **Prose order is evidence, not proof.** "Picks, packs and books a carrier" is a reasonable
  sequence; "inspection and labelling also happen" is not. When in doubt, it is unknown.

## 5. The honest end state: which warnings stay

Stop iterating when every remaining finding is one of these, and each traces to something the
source does not say. Removing them by changing the map is fabrication.

| what the source leaves unknown | findings you keep |
|---|---|
| the order of N unplaced steps | 1 × `W-XML-DISCONNECTED`, plus per step 1 × `W-XML-UNREACHABLE` and 1 × `W-XML-DEADEND` (when the map has a start and an end event) |
| no stated order at all, so the map has no start or no end event | 1 × `W-XML-NO-START-EVENT` and/or 1 × `W-XML-NO-END-EVENT` for the map, plus 1 × `W-XML-DISCONNECTED` if the steps fall into several parts. Reachability is then not assessed per step. If the source states any chain, mark it with a start and an end (section 4) and the per-step findings above apply instead |
| who performs a step | 1 × `W-LANE-NO-OWNER` per task in the `none` lane |
| an executable branch condition (you labelled branches in the source's words, section 4) | 1 × `W-XML-GW-AMBIGUOUS` per such gateway. DIALECT-RELATIVE: a branch label is a standard-admitted condition carrier |
| geometry (you chose the geometry-free layout, section 7) | 1 × `I-XML-LANE-GEOMETRY-SKIP`, an INFO note, not a warning |

The rule against inventing outranks every finding here. "The validator wins" (top of this
guide) is about what the validator **checks**, never permission to make up a fact to satisfy it.

Each of these messages names both readings: `W-XML-DISCONNECTED` says the parts are either
separate processes or steps with no recorded place, and `W-XML-DEADEND` says control is either
trapped or the source does not record what follows. On a map built from a source that leaves
the order unknown, the second reading is the true one, and the map is right as it stands.

## 6. Say what kind of map it is

- **A real process**, including an as-is process captured from interviews: leave `kind` out.
- **An overview, landscape or capability map** (boxes that are not steps of one flow):
  `kind="documentation"`.
- **A plan of work to be carried out as tasks:** `kind="work-plan"`.

Today `kind` is a **declaration that nothing acts on yet**: the validator checks only that the
value is valid, and every rule still applies to an overview map. Declare it anyway. It is the
only carrier for the fact, and tools that honour it can only honour what you wrote.
`isExecutable` is not read by anything here; `false` is the honest value for a captured process.

## 7. Layout

Positions are presentational: they never change what a map means. They do decide whether a
human can read it.

- **Either** emit `aef:position` per node, as the exemplar does: left to right in flow order,
  each node inside its own lane's band. The validator then checks that lanes are in the declared
  order and that each lane's height holds its members. It does not check that the result reads
  well.
- **Or** emit no geometry at all, and **write the flow elements in flow order** in the file. The
  designer lays out an unpositioned map in document order; it does not yet layer by flow. A map
  whose end event comes first in the file is drawn with the end first.
- If you emit BPMN DI (`BPMNShape` bounds), the designer uses those coordinates as given.

## 8. What the validator does NOT check

You are on your own for these. Get them right because the source says so, not because nothing
complained.

- that every node and flow **has** an `aef:uid` (only that no two are equal);
- that a node is in **exactly one** lane (only that it is in at least one);
- the `id`, `version` and `schemaVersion` attributes of `workflowMeta`;
- whether a lane's authority is **true** of the source (only that the value is in the
  vocabulary);
- `isExecutable`, branch label wording, annotation text.

## 9. Classes of finding

`CONFORMANCE.md` classifies every rule, derived from the frozen standard rather than asserted:

- **UNIVERSAL**: rests on the standard or on graph structure. Fix it, or for an unknown owner or
  order, declare the unknown as in section 4.
- **DIALECT-RELATIVE**: our house convention, not the standard. Worth satisfying when you author
  for this designer, never a reason to distort the source.
- **PRESENTATIONAL**: layout only.

`W-XML-DISCONNECTED` is listed UNIVERSAL by that derivation (it reads graph structure), although
the standard has no connectivity clause. That disagreement is known and recorded on our side.
Treat it as section 5 says.
