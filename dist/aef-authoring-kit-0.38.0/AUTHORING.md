# Authoring governed workflow maps — a guide for the agent that generates them

You are generating BPMN maps for the AEF Workflow Designer from some source: a conversation,
documents, code, an ontology, process descriptions. This kit exists because a real deployment
produced 26 maps that looked fine, saved 130 times without complaint, and carried **no
governance at all**: no map said what it was, and no task had a derivable owner. Nothing told
the generating agent. This guide, the validator beside it, and `CONFORMANCE.md` are what tell
you.

When this guide and the validator disagree, the validator wins and this guide has a bug.
Section 8 lists what the validator does **not** check, so you know where you are on your own.

**Start at `SKILL.md`.** It gives the order of work (draft, update or check a map) and points back
here for each rule. Your project may keep rules of its own on top of these: in its own repository,
never instead of these.

## 1. The loop

1. **Write a candidate** map to a file.
2. **Validate it:** `python3 validate-workflow.py candidate.bpmn` (Python 3, standard library
   only; add `--json` for machine-readable findings). Exit **0** = clean, **1** = warnings only,
   **2** = errors. A wrong command line also exits 2, so if you see 2 with no ERROR line, check
   your invocation before your map. Two options:
   - `--field-catalog <catalog.json>`, when your project has a field catalog: it checks each io field
     against it (section 4b).
   - `--strict`, when your project refuses on the general map rules: it turns the section 4b
     warnings into errors, and makes a map with steps but no io at all an error.
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

**An element backed by several source lines** (a lane that covers several steps, a step the
source describes in two places) cites each quote on its own `source:` line inside the one
`<documentation>`, never joined with a separator a reader could mistake for source text:

```xml
<bpmn:documentation>source: "The warehouse picks the parts."
source: "The warehouse also does quality inspection and labelling for each order."</bpmn:documentation>
```

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
  **Two distinct steps the source gives the same display name** (say, "Part Production" in two
  places) keep that name verbatim on both and get distinct keys. Where the source gives
  distinguishing lane or context, cite it in a qualifier note on each; where it gives none, add
  nothing. Never rename either step to make the names unique.
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
| a system **supports** the step, but the source names nobody who performs it | `none` | none: put the step in the `none` lane and the system in a note (`System: the ERP`) associated to the step |

A system that *supports* a step is a tool, not a performer: "the quote is approved in CPQ"
says where, not who. Only when the source makes the system the actor ("the ERP creates the
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
  add an exclusive gateway: it invents a decision. For unconditional outgoing flows, a parallel
  fork makes the same branching explicit, so it is allowed but not needed. **A parallel join is
  NOT the same as plain converging flows:** a join waits for every incoming branch, while plain
  flows into a step do not synchronise and can run that step once per arrival. Draw a join only
  where the source says the next step waits for all branches; where the source is ambiguous, keep
  the construct you have and say so in a note rather than swapping it silently.
- **The same question for hand-overs.** A step that hands over to two other processes, with the
  source silent on whether both happen, gets two hand-over throws by plain flows (which in BPMN
  means both) and the note above on the step: `Whether both hand-overs happen, or only one, is not
  recorded in the source`. The note records the source's silence; it does not change what the
  flows mean.
- **A hand-over to a step in another map** is a link event, not a note. End the path in this map
  with an `intermediateThrowEvent` carrying
  `<aef:link targetWorkflow="<the other map's workflowMeta id>" name="<the other process's name>"/>`
  in its `extensionElements`, and start the receiving map's path with an
  `intermediateCatchEvent` carrying the same pair pointing back. The validator treats a throw as
  a terminus and a catch as an entry, so neither draws a reachability warning, and the designer
  can jump between the two maps. Cite the source line that states the hand-over. If the source
  names the other process but not the step it goes to, link to the process and say so in the
  citation. **This is an AEF convention, not standard BPMN:** BPMN 2.0.2 link events connect
  sections of ONE process, and each map here is its own process. A standards-only tool sees the
  throw and the catch but cannot infer the cross-process connection from `aef:link`. Where the two
  maps are distinct participants, the BPMN-standard form is a message flow in a collaboration
  (optionally a message end event to a message start event); see CONFORMANCE.md.
- **A step the source says "is detailed in process X"** is a task with a cited note
  `Detailed in: X`. Use a `callActivity` only when the source establishes that the step invokes X
  as reusable behaviour, with `calledElement` resolving to X's BPMN process (a workflowMeta id
  suffices only if your export guarantees that resolution). Never a `subProcess` with content the
  source does not give.
- **Documents a step creates or uses** (a quote, an order confirmation, a delivery note) are data
  objects, linked to that step: section 4b. Since designer 0.37.0 they are drawn under the step.
  A record that is no document (the order row in a system) is the object of an io, also section 4b.
- **Do not invent conditions.** Label each exclusive-gateway branch with the source's own words
  (`name="limit exceeded"`). When the source states the test itself ("credit limit exceeded",
  "status is Approved"), also write it as the branch's `conditionExpression`, in the source's own
  terms: that is the condition, and a branch without one is reported
  (`W-XML-GW-BRANCH-UNCONDITIONED`, `W-XML-GW-AMBIGUOUS`). When the source names the branch but
  not its test, the label alone is honest and the warning stays (section 5). When the
  source clearly implies an "otherwise" case (a yes/no decision whose other branch it does word),
  make that branch the gateway's unlabelled default flow (`default="<flow id>"` on the gateway)
  rather than inventing words for it. Do not infer a default merely because wording is missing.
- **Merging branches:** use a converging exclusive gateway (two or more incoming flows, exactly
  one outgoing), or route the branches straight into the next step. Both are valid. An exclusive
  gateway with one incoming and one outgoing flow decides nothing and is flagged with a warning
  (`W-XML-GW-OUTGOING`; it was an error until T-1212).
- **Prose order is evidence, not proof.** "Picks, packs and books a carrier" is a reasonable
  sequence; "inspection and labelling also happen" is not. When in doubt, it is unknown.

## 4b. The data a step reads and writes

A map that says only *who* does *what* cannot say where the data comes from, what each step changes, or what a
value must look like. These rules say how to write that down (AEF mapping v1.1). Every one of them follows
section 4: write what the source says, and declare the rest open.

**One io per object.** Each `<aef:input>` or `<aef:output>` (inside the step's `<aef:io>`) is about one business object:
an order, a customer, a quote. A step that reads two objects has two inputs. A message that carries several objects
is typed as the message, not as one of them.

| on the io | says | if the source does not say it |
|---|---|---|
| `typeRef="ex:Order"` | which object | do not write the io; note the step instead (`Open: which record it reads`) |
| `sourceSystem` (input) / `targetSystem` (output) | which system | leave it out; the warning stays |
| `operation` | `read`, `create`, `update`, `upsert` or `delete` | leave it out; the warning stays |
| `cardinality` | `one` or `many` | leave it out |

A missing object, system or operation on an object io is `W-XML-IO-INCOMPLETE`. The system may also come from the
step (`<aef:meta sourceSystem="…"/>`) or from the prefix map (`<aef:prefix name="ex" … system="sys:crm"/>`); the
validator looks in that order. An update, upsert or delete needs a field with `role="match"`: the key that picks
the record (`E-XML-IO-MATCH-MISSING`).

**Fields.** Each `<aef:field>` names one attribute, by `fieldRef` (an id from the project's field catalog) or, when
the catalog has none yet, by `path`. Its `role` is `read`, `write`, `match` (the key) or `create` (set only when
the record is made). With `--field-catalog`, the validator checks that the fieldRef exists (`W-XML-IO-FIELD-UNKNOWN`)
and that it belongs to the io's object (`W-XML-IO-FIELD-ENTITY`).

**Every step in a system's lane has io** (a lane with `authority="authority"`), once your map gives io at all:
`W-XML-IO-MISSING`. A system does nothing worth a step without reading or writing something. If the source does not
say what, keep the step, write `Open: what it reads and writes` in its documentation, and keep the warning.

**`aef:expect` is for this step only.** Use it for what must hold here: the status before the step, the value after it.
How a value is built in general (its type, length, pattern, allowed values) belongs to the attribute, in the
project's field catalog or ontology, not in every step that touches it. An expectation the attribute's rule forbids
is an error (`E-XML-IO-EXPECT-CONTRADICTS`); one that only repeats it is a warning (`W-XML-IO-EXPECT-REDUNDANT`).

**A value written to another system gets a Mapping line.** When a step reads from one system and writes to another,
each field it writes says where its value comes from, in the step's documentation:
`Mapping: <mapping id> (source field -> target field): <the rule>`. The validator does not check these yet (section 8).

**Documentation lines start with a known word.** A step's `bpmn:documentation` holds one statement per line, each
starting with one of these words:

| prefix | the line says |
|---|---|
| `Instruction:` | what the person or system does |
| `Screen:` | the screen or state they see |
| `Decision:` | what is decided here |
| `Keys:` | the keys that join records across systems |
| `Open:` | what the source leaves open |
| `Rule:` | a business rule that applies |
| `Master:` | which system is master for the data |
| `Detail:` | the detail map or document for this step |
| `Mapping:` | where a written value comes from (above) |

After a line that starts with `Notes`, the text is free and is not checked. A line with no known word, in
documentation that uses the words, is `W-XML-DOC-PREFIX`.

**Documents are data objects.** A document a step makes or uses is a `dataObjectReference` with a `name`, its state
as `<bpmn:dataState name="draft"/>` when the source gives one, and a `dataOutputAssociation` (the step makes it) or
`dataInputAssociation` (the step uses it) on the step. A document with no name, or linked to no step, is
`W-XML-DATA-UNLINKED`.

**Positions agree.** If you write both `aef:position` and BPMN DI, they hold the same top-left corner. The designer
draws from `aef:position`, other BPMN tools from DI, so a disagreement shows two different maps
(`W-XML-POSITION-DI`). After moving nodes by hand in another tool, update both.

## 5. The honest end state: which warnings stay

Stop iterating when every remaining finding is one of these, and each traces to something the
source does not say. Removing them by changing the map is fabrication.

| what the source leaves unknown | findings you keep |
|---|---|
| the order of N unplaced steps | 1 × `W-XML-DISCONNECTED`, plus per step 1 × `W-XML-UNREACHABLE` and 1 × `W-XML-DEADEND` (when the map has a start and an end event) |
| no stated order at all, so the map has no start or no end event | 1 × `W-XML-NO-START-EVENT` and/or 1 × `W-XML-NO-END-EVENT` for the map, plus 1 × `W-XML-DISCONNECTED` if the steps fall into several parts. Reachability is then not assessed per step. If the source states any chain, mark it with a start and an end (section 4) and the per-step findings above apply instead |
| who performs a step | 1 × `W-LANE-NO-OWNER` per task in the `none` lane |
| an executable branch condition (you labelled branches in the source's words, section 4) | 1 × `W-XML-GW-AMBIGUOUS` per such gateway, or 1 × `W-XML-GW-BRANCH-UNCONDITIONED` per branch when only one lacks a condition. DIALECT-RELATIVE: a branch label is a standard-admitted condition carrier |
| what a system step reads or writes (section 4b) | 1 × `W-XML-IO-MISSING` per such step, with an `Open:` line saying so |
| an io's system or operation | 1 × `W-XML-IO-INCOMPLETE` per such io |
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
- If you emit BPMN DI (`BPMNShape` bounds), the designer uses those coordinates when a node has no
  `aef:position`. When it has both, the designer draws `aef:position`, so keep the two equal
  (`W-XML-POSITION-DI`, section 4b).

## 8. What the validator does NOT check

You are on your own for these. Get them right because the source says so, not because nothing
complained.

- that every node and flow **has** an `aef:uid` (only that no two are equal);
- that a node is in **exactly one** lane (only that it is in at least one);
- the `id`, `version` and `schemaVersion` attributes of `workflowMeta`;
- whether a lane's authority is **true** of the source (only that the value is in the
  vocabulary);
- `isExecutable`, branch label wording, annotation text;
- the `Mapping:` lines (section 4b): neither that one exists for each value written to another
  system, nor that the mapping it names exists. That waits for AEF's mapping vocabulary;
- whether an io's object, fields and expectations are **true** of the source, and, without
  `--field-catalog`, whether its fields exist at all.

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
