# Reviewer evidence — T-1528 AC#1

- dispatch: `judge-t-1528-r5-codex-fc973078f268`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `76e38506c0c2490ddd8c8d3033536a53781310d4`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `ac92b316801c88e140a1305830c813daa1e193e70325a1d369c136056bdd4364`
- result.md sha256: `d5481b7eb1a2035197bb49120c347bbf183a37a40a5ddf8f6daba59d7d40346f`

## The worker's verdict block

```
1. [AC] The workflow panel’s new Scope field reads well at every width
VERDICT: green
WHY: Visually inspected all six supplied images: docs/reports/T-1528-shots/workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In each, the Scope label, “which projects get this map” hint, and select are visible, unclipped, and free of overlap. Alignment, spacing, and styling are consistent with Kind above. The selected text is fully readable: “unset — this project only” or “framework — ships to every project.” The hint and option wording explain project distribution without requiring knowledge of T-1519.
GUIDANCE: No field changes needed. This is the codex seat’s assessment in a degraded single-vendor panel; this run cannot satisfy the multi-vendor requirement, so the criterion stays open.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] The workflow panel’s new Scope field reads well at every width
VERDICT: green
WHY: Visually inspected all six supplied images: docs/reports/T-1528-shots/workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In each, the Scope label, “which projects get this map” hint, and select are visible, unclipped, and free of overlap. Alignment, spacing, and styling are consistent with Kind above. The selected text is fully readable: “unset — this project only” or “framework — ships to every project.” The hint and option wording explain project distribution without requiring knowledge of T-1519.
GUIDANCE: No field changes needed. This is the codex seat’s assessment in a degraded single-vendor panel; this run cannot satisfy the multi-vendor requirement, so the criterion stays open.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
