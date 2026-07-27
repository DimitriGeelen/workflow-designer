# T-257 research: where the save path drops start/throw aef:eventDef

**Task:** T-257 (inception) · **Date:** 2026-07-27 · **Author:** agent
**Question:** Localize the exact drop site(s) that make a layout-only open→save in the
designer strip `<aef:eventDef>` from startEvent and intermediateThrowEvent carriers
(AEF field defect, rail 201 / their T-2620), and determine the bounded fix shape.

## Evidence base

- Pinned byte-pair fixture `tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/`
  (v1 5845caae pre-editor, v2 7c0bd69a post-0.4.0-save; AEF byte-check EXACT MATCH,
  rail 215).
- Code read of the only source file touching eventDef: `src/aef-workflow-designer.html`
  (grep across src confirms single file).
- AEF-side intake stance, source-verified by AEF at rail 215.

## Findings

### F1 — Drop site (a): parse-time discard in adoptImportedXml

`src/aef-workflow-designer.html:9088-9099`. The importer reads `<aef:eventDef>` into
`eventDefEl` for every node, but consumes it only under the `_catchHost` guard:

```
const _catchHost = tag === 'intermediateCatchEvent' || tag === 'linkEventCatch' || tag === 'boundaryEvent';
if (eventDefEl && _catchHost && !_linkHasTarget) { …type override + binding capture… }
```

On a `startEvent` host (node type stays `startEvent`) or an `intermediateThrowEvent`
host (node type becomes `linkEventThrow` via REVERSE_TYPE), the guard fails and
kind/binding never enter the node model. The information is gone at parse time.

### F2 — Drop site (b): export-time gate in aefExtensionXml

`src/aef-workflow-designer.html:8735-8739`. The exporter emits `<aef:eventDef>` only
when `EVENT_KIND[node.type]` matches — i.e. only for the three typed-catch node types
(eventError/eventTimer/eventMessage). Even if the model carried the data for other
hosts, nothing would be re-emitted. A preservation fix must touch **both** sites.

### F3 — Fixture trace matches the field repro exactly

- v1 `th_obs_fire` (startEvent, `kind="timer"`, no aef:link): fails F1 guard → dropped.
- v1 `th_signal` (intermediateThrowEvent, `kind="message"`, no aef:link): fails F1
  guard → dropped.
- v1 `th_pickup` (intermediateCatchEvent, `kind="message"`): passes guard, is
  type-overridden to `eventMessage`, re-exports via F2 — survives in v2:238 as
  `<aef:eventDef kind="message" binding=""/>`.

The v2 survivor also proves the exporter's **canonical normalization** (`binding=""`
added vs v1's attribute-less form) is already in the wild and accepted by AEF's
intake — so the fix may re-emit canonically; byte-verbatim attribute preservation is
unnecessary machinery.

### F4 — Peer intake risk: none (closed externally)

AEF rail 215, verified in their source: `corpus_spec.py:212` captures aef:eventDef
host-agnostically with no rejection path; lint (`corpus_lint.py:179`) classifies
direction by host tag — start=neutral (no finding), throw=emitter. Restoring throw
eventDefs additionally **cures** the emitterless-typed-catch lint class (T-2551) that
this defect manufactures.

### F5 — T-237 "invalid hybrid" concern does not apply to preservation

The src comment at :9082-9087 records why the guard exists: EVENT_KIND types all
export as `intermediateCatchEvent`, so **type-overriding** a THROW host would silently
mutate its tag to a catch on round-trip; and link-with-target nodes must stay link
events. A passthrough that leaves node type and host tag untouched triggers neither
failure mode. The T-237 decision stays intact for the catch path; the concern
dissolves for preservation.

## Fix shape (build task on GO)

1. **Import:** when `eventDefEl` exists but the catch-override doesn't apply, store
   kind/binding as inert aef passthrough fields (no node-type change, no UI).
2. **Export:** after the EVENT_KIND block, re-emit `<aef:eventDef>` canonically for
   nodes carrying the passthrough.
3. **Test:** regression leg — open fixture v1, save, assert all 3 eventDefs survive
   with kinds intact.

Blast radius: single source file + one test leg (≈1-2 vs anticipated 3).

## Dialogue Log

No human dialogue segments this phase — exploration was code-read + fixture-diff
against evidence already ratified on the rail (201/208/209/215). Operator decision
pending at /inception/T-257.
