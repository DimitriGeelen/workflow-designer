# Reviewer evidence — T-1212 AC#1

- dispatch: `judge-t-1212-r5-codex-b2a5534c1249`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `736159b355715bcd54494531e9abb9cc1d8cfd36`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `f65ac41402581a90cdca567df1e149143eff6fad2c23bf3fb58740610dc6b7be`
- result.md sha256: `3503a8dd02d339f148d65c7ccc495d8d423404986f3ecce164866fd2365f89ca`

## The worker's verdict block

```
1. [AC] Warning display at 1024, 1440, and 1920 widths
VERDICT: green
WHY: Visually inspected all three specified screenshots in docs/reports/T-1212-evidence/. Each shows “1 finding · 0 errors, 1 warning · 1 on the map”, a WARN row with W-XML-GW-OUTGOING, and the complete message “exclusiveGateway has 1 outgoing flow(s); requires >= 2”. The toolbar Check button and Validator close button are visible and unclipped at every width. The gateway’s warning marker is visible at 1920, where the map is large enough to inspect clearly. No required text or control is clipped.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Warning display at 1024, 1440, and 1920 widths
VERDICT: green
WHY: Visually inspected all three specified screenshots in docs/reports/T-1212-evidence/. Each shows “1 finding · 0 errors, 1 warning · 1 on the map”, a WARN row with W-XML-GW-OUTGOING, and the complete message “exclusiveGateway has 1 outgoing flow(s); requires >= 2”. The toolbar Check button and Validator close button are visible and unclipped at every width. The gateway’s warning marker is visible at 1920, where the map is large enough to inspect clearly. No required text or control is clipped.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
