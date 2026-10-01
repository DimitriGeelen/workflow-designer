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
| the order of N unplaced steps | 1 × `W-XML-DISCONNECTED`, plus per step 1 × `W-XML-UNREACHABLE` and 1 × `W-XML-DEADEND` |
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
