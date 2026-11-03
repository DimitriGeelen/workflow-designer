---
name: workflow-map-authoring
description: Draft, update or check a governed BPMN workflow map for the AEF Workflow Designer, from a source (documents, code, an ontology, conversations). Use when building a map from a source, changing an existing map, or checking a map before it is published. It gives the order of work; the rules are in AUTHORING.md beside it.
---

# Draft, update or check a workflow map

This is the order of work. Each step points to the rule it applies, in `AUTHORING.md` beside this file. Read that
guide once before your first map; come back to the section a step names when you are unsure.

The one rule above all others: **write what the source says, and declare the rest open** (AUTHORING.md section 4).
A finding the source cannot answer stays; making something up to clear it is the worst defect a map can have.

## Draft a map

1. **Collect the sources** and keep them beside the map. Every element you write traces to one of them: a document,
   a code path, a decision, a conversation. If you cannot say which, do not write the element.
2. **Steps and lanes.** One lane per performer, with its authority (section 3). Steps in the order the source states,
   and unknown order left unknown (section 4). Every node in a lane. Ids derived from the source (section 2).
3. **Data, per step.** For each step, decide which objects it reads and writes, and write one io per object, with
   its system and operation, its fields with their roles, a key field for an update (section 4b).
   Use the project's field catalog for field ids when there is one.
   - Write an `aef:expect` only for what must hold in this step.
   - Write a `Mapping:` line for each value written to another system.
   - Write documents as data objects, linked to the step that makes or uses them.
4. **Decisions.** A label on every branch in the source's words. Where the source states the test, write it as the
   branch's condition too (section 4). Use a default for the stated "otherwise".
5. **Documentation lines.** One statement per line, each starting with a known word (`Instruction:`, `Screen:`,
   `Decision:`, `Keys:`, `Open:`, `Rule:`, `Master:`, `Detail:`, `Mapping:`), then `Notes` for free text
   (section 4b).
6. **Say what kind of map it is** (section 6), and lay it out (section 7). If you write both `aef:position` and DI,
   keep them equal.
7. **Build the file.**

## Check it

8. **Validate:**

   ```
   python3 validate-workflow.py map.bpmn --field-catalog catalog.json
   ```

   Leave out `--field-catalog` if the project has no catalog. Add `--strict` if your project refuses on the general
   map rules. Read every finding (section 1). Exit 0 is clean, 1 is warnings only, 2 is errors: **refuse on 2**, never
   on 1. A declared open key stays a warning, even under `--strict` (section 5).
9. **Fix only what the source lets you derive.** Stop when every remaining finding is in the honest end state
   (section 5) and traces to something the source does not say.
10. **Round trip:** open the map in the designer and save it again. The save must keep every node, flow, lane,
    io and document. A count that changes is a defect, either in the map or in the designer: report it, do not
    work around it.
11. **Look at it.** Take a screenshot of the map in the designer and read it: every step in its lane, no label
    cut off, documents under their steps, nothing overlapping. The validator does not see layout.
12. **Review it**, when the loop is set up: `loop.sh` runs a reviewing agent against the source (section 1b,
    `REVIEW.md`, `RUBRIC.md`) and `CORRECT.md` tells you how to apply its findings.

## Publish it

13. Save it through the designer or its API, or commit it, then validate the **published** bytes again (section 1).

## Update a map

Start from the published map, not from a regenerated one: its ids are its identity (section 2). Change only what the
new source says; keep every id. Then run steps 8 to 13 again.

## Check a map someone else made

Run steps 8, 10 and 11, and review it against its source (step 12). Report what you find; changing it is an update.

## Project rules

A project may have rules of its own: the language its maps are written in, the wording of messages its users see,
lanes that must name a role, conventions of the systems it maps. They live in the project's own repository, are
added on top of these, and never replace them. When a project rule and this kit disagree, ask the project's owner;
do not choose silently.
