# T-1118 — Unknown content becomes a designer field only on operator approval; field visibility

**Status:** inception, explored 2026-10-11, recommendation GO (see end). **Origin:** the operator's ruling on T-347,
2026-10-10.

## The ruling this builds on (T-347)

- **R1 (build, T-347):** content the designer does not understand is kept and written back unchanged. Nothing is lost
  silently any more. (R1a, a second pool kept with a notice on import, was built as T-1119/T-1120.)
- **R2 (this inception):** when the designer meets an unknown kind of content, it **suggests** turning it into a real,
  editable field; the **operator approves** each one. Valuable twice: the field becomes editable, and the suggestions
  show which fields real files use that the designer is missing.

## Scope, in the operator's words

1. "An option to show or not in certain projects — we can extend, but not everything is desirable." → visibility **per project**.
2. "Maybe even per workflow you want to show or hide certain fields for elements." → visibility **per workflow, per element type**.
3. "You look what you need and then you hide the not used fields, because we've got a lot of pollution, a lot of empty
   fields there where nothing is shown." → **show only what is used**.

## What the designer does today (evidence)

- **Which fields an element offers is one fixed list in the code:** `AEF_FIELDS` (`src/aef-workflow-designer.html:2174`),
  per element type, with labels and hints in `FIELD_META` (`:2330`). Every project and every map gets the same list.
  Changing it means a designer release.
- **Every listed field is drawn, filled or not** (`renderProperties`, `:6814-6928`). A service task offers 13.
- **Measured pollution:** over the 42 service tasks in `examples/`, the **median filled is 2 of 13**. `endpoint` 30,
  `tier` 19, `agentType` 16, `contextReads` 7, `artifactsWrites` 6, `note` 4, `determinism` 2; `horizon`,
  `workflowType`, `sideEffect`, `fabricRef`, `links` 0 (`authority` 0 is expected: it lives on the lane). So about 11
  of 13 boxes on a typical service task are empty — the operator's "a lot of empty fields".
- **Detection of unknown keys already exists:** T-566 added "Other extensions · N" (`:6988-7024`), which lists every
  `aef:` key on the element that has no field, **read-only**, and T-570 makes sure it is written back. At T-566 this
  was 305 of 714 values (42.7%) across 14 keys. This is the natural place for "suggest as a field".
- **Not yet detected:** content outside the `aef:` namespace inside an element (e.g. `zeebe:`/`camunda:` extensions,
  `bpmn:documentation`). R1 for element-interior content (T-347 build) must land first; then the same section can
  list it.
- **Where settings live today:** only the browser (`localStorage`: routing, snap, label, view prefs, `:2843-2943`).
  That is per person, per browser — wrong for "per project" (other people and Greenfield's portal would not see it).
  The gallery server (`tools/gallery-serve.py`) serves maps per project id (`/api/list`, `/api/version?id=`), so a
  project can carry a file next to its maps.

## Answers to the questions

- **IW-1 — detect and suggest.** Extend "Other extensions": each unknown key gets a "Suggest as a field" action, with
  the evidence counted for the open map ("`approvalLimit` · on 7 of 12 user tasks"). A suggestion is a record (key,
  element types seen on, example values, which map), never a field by itself. Confidence 2 (the section and its
  rule are read; the wording is a proposal).
- **IW-2 — approval and record.** The designer cannot approve; the operator does. Suggestions are queued in a file
  per project (`fields-suggested.yaml`, written by the gallery server, or downloaded when the designer runs
  standalone). Approval = the key moves into the project's field profile (below) with `approved_by` and date, done
  by a runme job the operator runs (832's rule for operator actions) — so the record is the committed profile file
  and its git history. Confidence 2.
- **IW-3 — where visibility lives, who wins.** Three layers, most specific wins, with one hard rule above them:
  1. **Designer default** — today's `AEF_FIELDS`.
  2. **Project profile** — `field-profile.yaml` beside the project's maps: per element type, `show` / `hide`, and the
     approved extra fields (label, hint, type).
  3. **Workflow** — the same shape, stored *in the map* (an `aef:` setting on the process), so it travels with the
     file to Greenfield or anyone else.
  4. **Hard rule: a field that carries a value is never hidden.** Hiding is only for empty fields; a hidden-but-filled
     field shows, marked "hidden in this project". Data must not become invisible (that is the T-566 lesson).
  Confidence 2.
- **IW-4 — show only what is used.** Default: show filled fields plus the fields the project/workflow pins as
  "always show"; collapse the rest behind one row, "+ 11 empty fields", that expands in place to fill one. A
  checkbox in Settings ("show all fields") gives the old behaviour. On today's data a service task goes from 13
  boxes to about 2-3 plus one row. Needs no approval machinery, so it can ship first. Confidence 3 (measured).
- **IW-5 — first kinds.** Greenfield's pools and message flows are **elements, not fields**: they are kept and drawn
  since 0.17.0 (T-1119/T-1120); making them editable is a separate build, not this mechanism. The first *field*
  candidates are the unknown `aef:` keys already counted by T-566, then Greenfield's element-interior content once
  T-347 R1 keeps it. Confidence 2 (Greenfield's own interior content not yet measured).

## Recommendation: GO, as three build tasks in this order

1. **B1 — hide empty fields** (IW-4): collapse row, "show all" setting, value-never-hidden rule. Smallest, removes the
   pollution now, no new files.
2. **B2 — field profile** (IW-3): project file + per-workflow setting in the map, the precedence above, read by the
   designer (gallery server serves the project file; standalone falls back to defaults).
3. **B3 — suggest and approve** (IW-1/2): "Suggest as a field" on unknown keys, the suggestion queue, the runme
   approval job writing the profile.

Each is testable on its own (CDP legs like T-1120's) and reversible (defaults reproduce today's panel).

## Dialogue Log

- 2026-10-10, operator on T-347: "certainly one" (R1); R2 "on suggestion… tier 0, with operator… it can be really
  valuable… we're also missing"; "an option to show or not in certain projects… not everything is desirable".
- 2026-10-10: "maybe even per workflow you want to show or hide certain fields for elements."
- 2026-10-10: "you look what you need and then you hide the not used fields because we've got a lot of pollution, a lot
  of empty fields there where nothing is shown. So put that also in the inception please."
- 2026-10-11: operator "proceed as suggested and you see fit" → exploration done, findings above, awaiting go/no-go.
