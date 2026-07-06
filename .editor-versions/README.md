# .editor-versions/ — Workflow Designer version store (T-129 / B2)

Per-map version history written by the editor's **Save to project** action, served by
`tools/gallery-serve.py`. One directory per map id:

```
.editor-versions/<id>/
  v1.bpmn, v2.bpmn, …     immutable BPMN snapshots (the editor's native format)
  v1.png,  v2.png,  …     optional canvas thumbnails (shown in the revert UI, B4)
  index.json             [{v, ts, note, thumb, bytes}] — the version list
```

**Why BPMN, not workflow.yaml:** the editor emits BPMN and there is no lossy
bpmn→yaml step; storing BPMN preserves the operator's geometry exactly and stays
diffable for the future layout-learning arc. The human-authored semantic
`examples/aef-processes/<id>.workflow.yaml` is never rewritten by a Save; only the
rendered map (`examples/aef-processes/rendered/<id>.bpmn`) is updated to the latest
saved layout.

This directory is committed (durable, shareable) — do not add it to `.gitignore`.
