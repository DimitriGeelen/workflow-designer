# T-1261: where a third-party file's original ids are carried — the question and the advice

The operator has ruled (2026-10-28, on `docs/reports/T-1329-open-job-c-findings-brief.md`) that the designer should
**record** a third-party element's original id (job C F3) and keep its own display-id rule. Open: where in the saved
file the original id is carried. The operator asked for external advice before choosing (2026-10-28).

## The facts

- On first open of a file without `aef:uid`, a node gets `uid = deriveUid('n', id)` (FNV-1a, one-way) and is saved
  under the designer's lane-prefixed display id (`Task_Approve` -> `app_1_approve`, a rule since 0.20). A flow gets
  `deriveUid('e', id)`. The original id appears nowhere in the output and cannot be recovered. Re-opening the output
  is stable (it now carries `aef:uid`), so the loss is on the first save only.
- The designer already keeps, verbatim and in place, every attribute, child and other-tool extension it does not read
  (T-1325), including unknown `aef:*` children (T-1268).
- `docs/standards/aef-bpmn-mapping-v1.md` §1 (frozen v1, normative): "Every `aef:` datum is exactly one of two
  classes": **semantic** (compiles to task-YAML; includes the identity key `aef:uid`) or **presentational** (layout;
  must be a no-op for the task graph). Editing the frozen standard is the operator's to sign off, batched with the
  pending v1.1 deltas (T-189/T-195).
- AEF is the designer's main consumer and reads these files; AEF's own maps are designer-written and never lack
  `aef:uid`, so they would carry no original id.

## The candidate carriers

1. A designer-private namespace inside the element's `extensionElements`, e.g. `<x832:origin id="Task_Approve"/>`.
   No standard change; AEF keeps it like any other tool's extension; not part of the AEF contract.
2. A new `aef:origin` element (or an attribute on `aef:uid`), added to the frozen standard as a v1.1 edit.
3. A BPMN-native place: for example a `<bpmn:documentation textFormat="…">`, or keeping the original as the element's
   `id` (rejected by the ruling: it breaks the display-id rule).
4. Outside the element: one mapping table at document level (original id -> uid), in either namespace.

## Advice

### AEF

(pending)

### Independent advisory read

Codex worker `t1261-advice-f667c406bf03` (dispatch, task-type review, advisory: no verdict asked), 2026-10-28,
verbatim:

> 1. **Designer-private extension:** Main risk is loss through other tools or AEF regeneration. BPMN permits
> extensions but explicitly allows their loss during interchange (OMG §8.3.3). The designer's foreign-extension
> passthrough supports this carrier; it does not establish AEF preservation. A documented namespace makes it usable
> by any tool: read the origin value and the containing element's current `id`.
>
> 2. **`aef:origin`, including an attribute on `aef:uid`:** Main risk is violating the frozen partition. Historical
> provenance is neither a task-YAML field nor derived diagram cosmetics. Being task-graph-neutral is necessary for
> presentation, but does not make provenance presentational. Nesting it on semantic `uid` does not resolve that.
> Adoption requires an explicit contract revision defining classification and forward/reverse behavior. Today, the
> UID writer emits only `value`, so an extra attribute would disappear (src:13352).
>
> 3. **BPMN documentation / original native `id`:** Documentation is structurally suitable for text, but its main
> risk is semantic confusion: AEF's mapping identifies documentation as an acceptance-criteria seed (standard:95).
> A custom `textFormat` needs explicit reader rules; generic editors may expose or edit the payload as prose.
> Retaining the native ID preserves references naturally, but conflicts with the ruling.
>
> 4. **Document-level mapping:** Main risk is synchronization and scope. Entries can become orphaned or ambiguous
> after copying, merging, or deleting elements. Old-ID→UID additionally requires joining UID→current-ID; tools
> unfamiliar with AEF need that relationship documented. An `aef:` table has candidate 2's classification problem;
> a private table has candidate 1's preservation uncertainty. Neither placement guarantees stable serialization.
>
> **Recommendation:** Use a documented designer namespace and an element-local `<x832:origin
> originalId="Task_Approve"/>`. The deciding reason is that it records provenance without changing the frozen
> meaning of `aef:` data.
>
> Use a stable namespace URI, matching by URI/local name rather than prefix. Define `originalId` as a string, never
> XML ID/IDREF. Preserve the first recorded value; do not replace it with each newly imported display ID. Define
> source-document scope and clone/merge behavior so duplicate historical IDs remain distinguishable. Capture
> provenance independently of whether `aef:uid` exists. Specify deterministic emission and verify
> save→reopen→save byte equality; carrier choice alone cannot guarantee it. Separately address stale references in
> opaque vendor payloads: an origin record does not repair them.
>
> The facts need these corrections: "Verbatim and in place" is too strong: XML is reserialized and namespace
> declarations removed (src:13232); retained node extensions are appended (src:13541). Unknown AEF extensions are
> excluded by generic passthrough, while flow output only re-emits foreign extensions (src:14219, src:13991).
> "AEF keeps it" is unverified, not a consequence of BPMN conformance. "Pending v1.1 deltas (T-189/T-195)" is
> stale: the standard already records those changes in version 1.1 (standard:3). "Original id appears nowhere" is
> overbroad: unnamed tasks use it as their name (src:14925). That incidental retention is not a reliable provenance
> channel.

**Checked by the author against the source (2026-10-28):** all four corrections hold. The standard header reads
"Version: 1.1 (2026-07-12)", so an `aef:` addition would be a v1.2 edit. `keptElementXml`'s caller at src:14219
skips `aef:` children (nodes keep unknown ones through T-1268's `nodeAefKeptXml`; flows do not). An unnamed task's
name falls back to its display id (src:14925), not reliably the original. "AEF keeps it" is the question put to AEF.

## Dialogue Log

- 2026-10-28, operator: "May we get external advice?" — asked AEF and an independent advisory worker the same
  question, with these facts and without a recommendation.
