# Authoring governed workflow maps — a guide for the agent that generates them

You are generating BPMN maps for the AEF Workflow Designer from some source: a conversation,
documents, code, an ontology, process descriptions. This kit exists because a real deployment
produced 26 maps that looked fine, saved 130 times without complaint, and carried **no
governance at all**: no map said what it was, and no task had a derivable owner. Nothing told
the generating agent. This guide, the validator beside it, and `CONFORMANCE.md` are what tell
you.

Everything here is checkable. If the validator and this guide ever disagree, the validator wins
and this guide has a bug.

## The loop

1. **Generate** the map from the source.
2. **Validate before you save**: `python3 validate-workflow.py <map.bpmn>` (Python 3, standard
   library only). Exit 0 = clean, 1 = warnings, 2 = errors. Add `--json` for machine-readable
   findings. If you save through the designer's `/api/save`, the response carries the same
   verdict under `validation`, and `{ok:false}` there means the validator could not run. That is
   NOT a clean map.
3. **Read every finding.** Each one names a rule id; `CONFORMANCE.md` lists them all with their
   class.
4. **Fix only what the source lets you derive.** Leave the rest unknown, declared as unknown
   (see below).
5. Save, then re-validate the saved bytes.

## What every map carries

Compare `exemplar.bpmn`: a complete map that validates clean.

- **`<aef:workflowMeta id=… version=… schemaVersion=…/>`** inside the process's
  `extensionElements`. Without it the map has no id of its own and no `kind`
  (`W-XML-NO-WORKFLOWMETA`).
- **`<aef:laneMeta authority=…/>` on every lane.** The lane is the sole authority-of-record for
  who performs the work in it (mapping-v1 §3). A lane that states nothing gets
  `W-XML-LANE-NO-AUTHORITY`. The vocabulary is in `CONFORMANCE.md`.
- **Every flow node in exactly one lane** (`E-XML-NODE-UNASSIGNED` otherwise).
- **A stable `<aef:uid value=…/>`** on every node and sequence flow, so a round trip keeps
  identity.

Plain `<task>` is fine; so is the default (unprefixed) BPMN namespace. The task type
(user/service/script) is presentational. If it disagrees with the lane, the lane wins and you get
a warning (`W-TYPE-LANE-MISMATCH`), not a refusal.

## Derive, never invent

This is the rule the 26 maps broke. A generator under pressure to produce a "complete" diagram
will make up what the source does not say. Do not.

- **An owner the source does not state stays unknown.** Declare it: `authority="none"` on the
  lane. That earns `W-LANE-NO-OWNER` on each task in it, which is the honest finding. Do **not**
  omit `laneMeta`, and do **not** pick a plausible authority to make the warning go away.
- **An order the source does not state stays unknown.** Do not connect the steps. Put them in
  the map unconnected, add a `textAnnotation` saying the order is not recorded in the source, and
  accept `W-XML-DISCONNECTED`. That warning is the true statement about the map. Connecting the
  steps to silence it fabricates process knowledge.
- **Do not invent start and end events.** One start before every step with no predecessor and
  one end after every step with no successor turns a single process into several parallel ones
  the source never described. If the source states one process, draw one.

## Say what kind of map it is

`<aef:workflowMeta kind="documentation"/>` marks a map as illustrative: an overview, a landscape,
a capability map. Nothing will mint executable tasks from it. Leave `kind` out only for a real
process. A landscape overview judged as an executable process produces findings that are
category errors.

## Classes of finding

`CONFORMANCE.md` classifies every rule, derived from the frozen standard rather than asserted:

- **UNIVERSAL**: any conformant document satisfies it. Fix it, or, for an unknown owner or order,
  declare the unknown as above.
- **DIALECT-RELATIVE**: our house convention, not the standard. A conformant document can trip
  it. Still worth satisfying when you author for this designer, and never a reason to distort
  the source.
- **PRESENTATIONAL**: layout. Never affects what the map means.
