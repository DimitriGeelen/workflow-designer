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

(pending)

## Dialogue Log

- 2026-10-28, operator: "May we get external advice?" — asked AEF and an independent advisory worker the same
  question, with these facts and without a recommendation.
