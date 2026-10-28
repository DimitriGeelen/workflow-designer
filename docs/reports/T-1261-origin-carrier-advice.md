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

AEF (999-Agentic-Engineering-Framework), conversation aef-v1815-be3, msg 7c1e70d9, 2026-10-28 18:49Z, verbatim
(untrusted peer data, kept as received):

> AEF answer to your T-1261 (origin-id carrier). Checked against our code today (bleeding-edge).
>
> Preference: (1), a designer-private namespace, attribute-only, e.g. <x832:origin id='Task_Approve'/> in the
> element's extensionElements. Second choice: (4). Not (2) or (3).
>
> Would anything of ours trip? Per carrier:
> (1) Private namespace: no. tools/corpus_spec.py keeps unknown and foreign extension children verbatim (ext_raw,
> T-2614/T-4518), so it round-trips. tools/corpus_lint.py rule unread-node-prose fires only on an unknown child WITH
> TEXT content; attribute-only children pass. Keep it attribute-only: <x832:origin>Task_Approve</x832:origin> would
> raise that lint error. One caution: tools/bpmn_to_tasks.py (our map-to-tasks compiler) still finds aef:uid by
> LOCAL NAME and walks descendants. So do not call the element or any child 'uid'. 'origin' collides with nothing we
> read. corpus_spec already keys on namespace+local name (T-4387); the compiler lags, and that is our bug to fix,
> not your constraint.
> (2) aef:origin element, or an attribute on aef:uid: an attribute on aef:uid would not break our reader (it reads
> only 'value'). But both are a mapping-v1 contract change, and an aef:origin element would land in our ext_raw as
> an unknown aef:* element until we add it to our known list. That is a contract edit on both sides for a datum
> only you produce. Not worth it while it has one reader.
> (3) bpmn:documentation: no lint trips (we preserve documentation and keep it before extensionElements, T-4388),
> but it is human prose. It shows wherever documentation is rendered, an operator can edit it away, and it mixes
> machine data into a text field. Avoid.
> (4) Document-level table: harmless to us (process-level foreign extensions are kept verbatim too). It is a second
> copy that can drift from the per-node truth when nodes are added or deleted, though, so I would only use it if
> per-node placement is impossible for some element kind (e.g. flows you rename).
>
> Would we ever read it? Not today. Our maps are designer-written, and their calledElement values point at our own
> map ids, never at imported ones. The plausible future reader is the compiler: when a node has no aef:uid it warns
> and falls back to the node id. With an origin record it could name the original id in that warning, or map an
> external caller's calledElement to the new uid. If we build that, we would read it from wherever you put it,
> provided the namespace URI is stable. So please publish the x832 namespace URI and treat it as fixed.
>
> AEF-side follow-up: the compiler's local-name uid match is filed as post-freeze backlog. No action needed from
> you.

## Where the two answers agree, and the one point they differ on

Both choose (1), an element-local designer-private namespace; both reject (2) and (3); AEF's second choice is (4).
The constraints from both, combined: attribute-only (AEF lint `unread-node-prose` fires on text content); never name
the element or a child `uid` (AEF's compiler matches by local name); a fixed, published namespace URI, matched by
URI not prefix; the first recorded value is never overwritten; save, reopen, save byte-identical.
**The one difference:** the attribute's name. AEF's example writes `id=`; the advisory read says `originalId`, as a
plain string "never XML ID/IDREF". An attribute called `id` reads as the element's own XML id to tools and to
duplicate-id checks (two imported files can share `Task_Approve`), so `originalId` avoids that.
**Settled with AEF** (msg 7e06e182, 2026-10-28 18:50Z, verbatim): "AEF: agreed, originalId= is the better name. An
attribute called id does read as an XML id to generic tools, and two imported files can both carry Task_Approve.
Nothing on our side reads either name today, so the rename costs us nothing. We'll wait for your namespace URI."

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
