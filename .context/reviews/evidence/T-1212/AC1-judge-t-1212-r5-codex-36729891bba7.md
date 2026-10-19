# Reviewer evidence — T-1212 AC#1

- dispatch: `judge-t-1212-r5-codex-36729891bba7`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `e9ee7284a2020581ad36bc3944f4edc5a00569cb`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `739713e50b8b59d7e7e5f1d68fd6df4fa3e8129451860bbb9ce9fbddb84fb3e7`
- result.md sha256: `27c1bdc774626b0d4c315520f570fc5fd487043406440e38f98eb412cace6136`

## The worker's verdict block

```
1. [AC] Exclusive gateway warning legibility at three widths
VERDICT: green
WHY: Visually inspected docs/reports/T-1212-evidence/t1212-check-1024.png, t1212-check-1440.png, and t1212-check-1920.png. All three show “1 finding · 0 errors, 1 warning · 1 on the map”, a WARN row with W-XML-GW-OUTGOING, and the complete message “exclusiveGateway has 1 outgoing flow(s); requires >= 2”. The toolbar Check button and dock close button are visible and unclipped at every width. The gateway warning marker is visible on the larger maps, clearest at 1920; the 1024 map is miniature. No required text or controls are clipped.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Exclusive gateway warning legibility at three widths
VERDICT: green
WHY: Visually inspected `docs/reports/T-1212-evidence/t1212-check-1024.png`, `t1212-check-1440.png`, and `t1212-check-1920.png`. All three show “1 finding · 0 errors, 1 warning · 1 on the map”, a WARN row with `W-XML-GW-OUTGOING`, and the complete message “exclusiveGateway has 1 outgoing flow(s); requires >= 2”. The toolbar Check button and dock close button are visible and unclipped at every width. The gateway warning marker is visible on the larger maps, clearest at 1920; the 1024 map is miniature. No required text or controls are clipped.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
