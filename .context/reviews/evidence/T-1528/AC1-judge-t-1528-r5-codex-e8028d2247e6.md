# Reviewer evidence — T-1528 AC#1

- dispatch: `judge-t-1528-r5-codex-e8028d2247e6`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `28b7a802073863258ff69925d781b3f4bf9ae6b3`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `3bb609c4333d721c3cfff269592a5ac0789cdeb6725340966397a78d43c9101d`
- result.md sha256: `d6f0a15888159a373b14ceccea22af07339e59a1309c871255f290a953459d84`

## The worker's verdict block

```
1. [AC] Workflow panel Scope field reads well at every width
VERDICT: amber
WHY: Viewed all six screenshots in docs/reports/T-1528-shots/: workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In every image, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, styling, and select width are consistent with Kind above. The unset selects are blank; the framework selects display “framework.” However, the hint “unset = project · framework ships” does not clearly explain that the map ships to other projects. “Ships” leaves the destination and object implicit for someone unfamiliar with T-1519.
GUIDANCE: Update the Scope hint in all six shots to explicitly explain both outcomes, for example: “Unset: this project only. Framework: map ships to other projects.” Allow wrapping as needed and retake all six screenshots to verify layout.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Workflow panel Scope field reads well at every width
VERDICT: amber
WHY: Viewed all six screenshots in docs/reports/T-1528-shots/: workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In every image, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, styling, and select width are consistent with Kind above. The unset selects are blank; the framework selects display “framework.” However, the hint “unset = project · framework ships” does not clearly explain that the map ships to other projects. “Ships” leaves the destination and object implicit for someone unfamiliar with T-1519.
GUIDANCE: Update the Scope hint in all six shots to explicitly explain both outcomes, for example: “Unset: this project only. Framework: map ships to other projects.” Allow wrapping as needed and retake all six screenshots to verify layout.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```
