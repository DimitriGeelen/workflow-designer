# Reviewer evidence — T-1528 AC#1

- dispatch: `judge-t-1528-r5-codex-cc3cd74dcbc4`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `2e77c7e2e2d786c03a88adf966a5b6571a70e73a`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `0ed1e2d5a8847e9e905525ca13e3fcb017363555114ba66d7e85beb07c834c5a`
- result.md sha256: `081abdb4b9fa8109fbf9da7dce7ee2c184dfa4416d22b45d28847ba82619cfbe`

## The worker's verdict block

```
1. [AC] Workflow panel Scope field reads well at every width
VERDICT: amber
WHY: Viewed all six supplied images in docs/reports/T-1528-shots/: workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In every image, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, spacing, and styling match Kind above. The selects correctly show blank or framework. However, the hint “unset = project · framework ships” does not clearly explain that the map ships to other projects; “framework ships” leaves the object and destination implicit for an unfamiliar reader.
GUIDANCE: Revise the Scope hint in all six shots to explicitly explain the outcome, for example: “unset = this project only · framework = map ships to other projects”. Retake both states at all three widths and verify wrapping and spacing.

Panel limitation: degraded single-vendor panel, seat codex. This review cannot satisfy the multi-vendor requirement; the criterion remains open.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Workflow panel Scope field reads well at every width
VERDICT: amber
WHY: Viewed all six supplied images in `docs/reports/T-1528-shots/`: `workflow-panel-unset-{1024,1440,1920}.png` and `workflow-panel-framework-{1024,1440,1920}.png`. In every image, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, spacing, and styling match Kind above. The selects correctly show blank or `framework`. However, the hint “unset = project · framework ships” does not clearly explain that the map ships to other projects; “framework ships” leaves the object and destination implicit for an unfamiliar reader.
GUIDANCE: Revise the Scope hint in all six shots to explicitly explain the outcome, for example: “unset = this project only · framework = map ships to other projects”. Retake both states at all three widths and verify wrapping and spacing.

Panel limitation: degraded single-vendor panel, seat `codex`. This review cannot satisfy the multi-vendor requirement; the criterion remains open.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```
