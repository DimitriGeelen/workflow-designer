# T-1301 Human AC#1: independent review (judge-t-1301-r3-56d0a0df8e01)

Revision: d4693b5d3aa6f62de9686a82d631959351341bc0. Source: docs/reports/T-1301-evidence/ (46 shots) and docs/reports/T-1304-evidence/ (0.27.0).

## Checked
- I viewed stylea-edit-1024-panel, stylea-edit-1024-panel-end, stylea-edit-1440 (full window), stylea-edit-1920-panel, v1-edit-1440-panel, v1-step-1920-panel, v11-step-1024-panel-end, and T-1304 v11-step-1024-panel and stylea-step-1440-panel.
- Untouched states: I ran a PIL pixel diff of every T-1301 shot against the matching T-1304 shot.
  - empty-step and workflow \*-panel at 1024/1440/1920: pixel-identical (diff bbox None).
  - The full-window shots differ only in the toolbar band (bbox y<=68).
  - The v1-, stylea- and v11-step panels differ. Visually, the only change is the closed "▸ edit attributes" line under each io row. The summaries are unchanged.

## Findings
- Toggle: "▸ edit attributes" / "▾ close editor" is visible and unclipped at all three widths.
- Field labels and controls: all ten (ref, fieldRef, typeRef, schemaRef, conceptRef, role, operation, cardinality, sourceSystem or targetSystem, dataType) are visible and aligned, and the select arrows are intact.
- Row membership: an accent bar ties each open editor to its row. The open row's summary is hidden, and a closed row keeps its summary. Two editors can be open at once. At 1024 the second editor is reached by scrolling (panel-end shot). Editing reads as editing: the inputs are boxed and there is no placeholder in empty fields (v1-edit).
- **Clipped (fails "unclipped"):** in stylea-edit, at 1024, 1440 and 1920, the ref field of input row 1 shows "nid:attr-opportunity-i…" and of output row 1 shows "nid:attr-account-compa…". The full value appears only in the tooltip. The task's own VV table marks this "clipped" at every width and defers the fix to T-1305.
  - The io name field cut ("sfdc:Opportunity.Ic…") already exists in 0.27.0 (T-1304 stylea-step-1440-panel), so T-1301 did not introduce it.
- **Not seen:** the undeclared-prefix hint. ioUndeclaredPrefix (src/aef-workflow-designer.html:8900) fires only for fieldRef, typeRef and conceptRef. No screenshot puts an undeclared CURIE in those fields: stylea's nid: is on ref, which is exempt. So the hint's rendering is not shown at any width. The CDP harness leg f checks only that the hint is present, not how it lays out.

## Verdict: amber
Everything else in the expected result holds. Two gaps remain: (1) the ref values are clipped at every width, and (2) no screenshot shows the prefix hint.
