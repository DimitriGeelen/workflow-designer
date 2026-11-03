# Workflow Designer 0.38.0 — release notes

**Since:** `designer-v0.37.0`. The two builds of 832's T-1375 decision (GO, 2026-11-03), on greenfield's proposal to
stop agreed map rules from getting lost:
- the authoring kit carries the data rules, with a `SKILL.md` entry point;
- the validator reports six general map rules and has a `--strict` mode.

Also in this release: the import notice names what the designer does not draw (T-1372).

## Changes

- **The validator reports six general map rules (T-1377).** Rules agreed with consumers (one io per object, a
  condition on every decision branch, documents linked to their steps, positions that agree) used to be checked only
  in a consumer's own script. They are now warnings every consumer gets:

  | Rule | When |
  |---|---|
  | W-XML-IO-INCOMPLETE | an object io (`typeRef` or `aef:field`) without its object, its system (`sourceSystem` / `targetSystem`, or as mapping v1.1 derives it: the step's `aef:meta`, then the system its typeRef prefix declares), or its `operation` |
  | W-XML-IO-MISSING | a step in a system's lane (`authority="authority"`) with no io, in a map that carries object io elsewhere |
  | W-XML-GW-BRANCH-UNCONDITIONED | one branch of a deciding exclusive gateway with no `conditionExpression` that is not its default (two or more such branches stay `W-XML-GW-AMBIGUOUS`) |
  | W-XML-DOC-PREFIX | a step's documentation line that starts with no known word (`Instruction:` `Screen:` `Decision:` `Keys:` `Open:` `Rule:` `Master:` `Detail:` `Mapping:`), before the free `Notes` part, in documentation that uses the words |
  | W-XML-DATA-UNLINKED | a document (`dataObjectReference`) with no name, or linked to no step |
  | W-XML-POSITION-DI | a node whose `aef:position` and DI bounds differ by more than 0.5 |

  **`--strict`** raises these six, and `W-XML-GW-AMBIGUOUS`, to errors. It also makes two cases errors: a map with
  steps and no io at all, and free-text documentation. It is for a project that refuses a map on these rules. Without
  it, they are warnings and an io-free map stays silent.

  How the rules were measured:
  - **On our 198 tracked maps:** no new error. 14 new warnings in 12 maps, each read and real:
    - documents with no name or no link in two third-party maps;
    - one bare branch;
    - io without operation or system in our own io fixtures and the T-1361 proposal map;
    - one vendored AEF map whose node `hum_1_define` sits 20 px off its DI.
  - **On greenfield's two kept maps:** `--strict` reports the same findings, rule by rule, as greenfield's own
    script (15 and 17).

  Guard: `tests/test_t1377_general_map_checks.py` (core, 15 legs).
- **The authoring kit carries the data rules and a skill (T-1376).**
  - **AUTHORING.md section 4b covers the data a step reads and writes:**
    - one io per object, with its system and operation;
    - fields and their roles;
    - `aef:expect` only for this step;
    - a Mapping line for each value written to another system;
    - io on every system step;
    - the documentation words;
    - documents as data objects with their state;
    - `aef:position` equal to DI.

    Each rule names the validator code that checks it, or says that none does.
  - **Three earlier passages are corrected:**
    - documents are no longer put in notes, because the designer has drawn them since 0.37.0;
    - a test the source states is written as the branch's condition;
    - `aef:position` wins over DI.
  - **`SKILL.md` is new.** It is the kit's entry point, with frontmatter so an agent runtime can load it, and gives the
    order of work: draft, check (validate, round trip, screenshot, review), publish, update, check another's map. It
    says project rules go on top of the kit's rules, never instead of them.
- **The import notice names what it does not draw (T-1372).** It counts the documents actually drawn, with their
  links, and names the rest:
  - `1 data store (CRM), 1 document no task links to (Memo), N link(s): in the file and saved back unchanged, but not
    drawn`.

  It used to call every data element "not shown yet", which was no longer true after 0.37.0 (greenfield's report).

## What changes in stored maps

Nothing. The validator and kit changes write nothing to a map, and the notice is display only. A map saved by 0.37.0
saves identically in 0.38.0.

## Not kept yet

Unchanged from 0.37.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- data stores are kept but not drawn;
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator yet, which waits for AEF's mapping vocabulary (T-4991).

## For AEF

**What changes in what you store:** nothing. Node ids do not change.

**The validator and the kit changed**, so the kit anchors move: the new `validate-workflow.py` and the kit's
`SHA256SUMS` sha256 and size come with this release's message. The new kit file is `SKILL.md`.
- **Check (`POST /api/validate`):** it reports the six new warnings without any change on your side.
- **`--strict`:** optional. A project that wants Check to refuse on these rules would need the wrapper to pass it.
  Until then, the CLI and the authoring kit carry it.
- **`--field-catalog` (since 0.37.0):** still needs the catalog passed for Check to report the catalog findings.

The endpoints as stated at 0.37.0. Please correct anything that has changed:

| Endpoint | Feature (task) | In AEF (as of 0.37.0) |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
