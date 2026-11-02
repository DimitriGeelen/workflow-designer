# Workflow Designer 0.36.0 — release notes

**Since:** `designer-v0.35.0`. Two changes that come from greenfield's to-be sales map WT-01, a process across a CRM, a
CPQ tool, middleware and a legacy order system. They make what such a map already carries visible in the designer:
- a state change in another system that starts a step (a conditional event);
- how each attribute's value is built (the value rule from the project's field catalog).

## Changes

- **Conditional and signal events read as what they are (T-1366).** Before, a conditional or signal intermediate event
  written by another tool opened as a link catch: an empty double ring, a display id containing `link`, and a side
  panel saying it "carries no kind" with an offer to make it a handoff. The definition was always kept on save (T-1222);
  only the display was wrong. Now:
  - the canvas draws BPMN's kind marker inside the ring: a lined sheet for conditional, an outlined triangle for a
    signal catch, a filled triangle for a signal throw;
  - the display id names the kind (`sal_conditional_lead` instead of `sal_link_lead`);
  - the side panel heads the event `conditionalEvent` / `signalEvent`, says what the flow waits for, shows the
    condition as the source wrote it, and offers no handoff.
  Message, timer and error events, and a catch with no definition, are unchanged. Guard: leg 222,
  `tools/_t1366-plain-event-kinds-cdp.mjs`, on a synthetic fixture.
- **The io panel shows how each attribute's value is built (T-1365).** Under each `aef:field` whose `fieldRef` the
  project's field catalog knows (`GET /api/field-catalog`), the input/output editor shows a read-only rule line:
  - folded, one summary such as `crm:Order.Id · string · max 18 · pattern · e.g. ORD…` or `… · one of 3`;
  - opened, the full rule: meaning, format, type and maximum length, pattern, allowed values, a made-up example (marked
    as such), where the value comes from or what it is derived from, the system, and the rule's id.
  A `fieldRef` the catalog does not know says "not in the project's field catalog: no value rule". A field addressed by
  `path` gets no line. Without a catalog the panel is as before. The rule is read from optional keys on each catalog
  row, named after SHACL: `datatype`, `maxLength`, `pattern`, `in` (array or `|`-text), `description`, plus `example`,
  `valueSource`, `derivedFrom`, `unit`, `shape`. Catalog contract T-1312 already carries such keys through untouched.
  Guard: leg 223, `tools/_t1365-value-rules-cdp.mjs`, on a synthetic map and catalog.

## What changes in stored maps

- **One thing: the id word of conditional and signal events.** The designer writes display ids as element ids on save.
  A conditional or signal event in a map from another tool, saved by 0.36.0, gets `…_conditional_…` / `…_signal_…`
  where 0.35.0 wrote `…_link_…` (for example `sal_link_lead` → `sal_conditional_lead`). This happens once, on the next
  save. Nothing else changes: the event definitions, conditions, DI and every other id save as in 0.35.0.
- **T-1365 writes nothing.** The value rules are display only; the save is byte-identical with and without a catalog.

## Not kept yet

Unchanged from 0.35.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it on the canvas (they are drawn flat; the save keeps them nested).

Escalation, compensate and other event kinds still draw as a plain event without a marker. Their definitions are kept.

## For AEF

**One change to what you store:** the node id of a conditional or signal event changes on the first save by 0.36.0, as
above. If you key anything on those node ids, map `…_link_…` to `…_conditional_…` / `…_signal_…` for those nodes, or
re-read them after the save.

**The field catalog:** to show value rules, your `GET /api/field-catalog` must pass the catalog rows' extra keys through
unchanged, as contract T-1312 says. Greenfield's `nid-attributes.json` now carries them for the WT-01 attributes. A
catalog without them still works: the panel shows only the attribute's name.

The validator is unchanged, so the kit anchors stay the same unless the build differs; the release message gives them.
The endpoints as stated at 0.35.0. Please correct anything that has changed since:

| Endpoint | Feature (task) | In AEF (as of 0.35.0) |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312); now also **value rules** (T-1365) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
