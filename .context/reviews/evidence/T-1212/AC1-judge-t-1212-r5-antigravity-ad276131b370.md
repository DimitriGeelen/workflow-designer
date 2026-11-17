# Reviewer evidence — T-1212 AC#1

- dispatch: `judge-t-1212-r5-antigravity-ad276131b370`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `736159b355715bcd54494531e9abb9cc1d8cfd36`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `baf785567ae96e19e0cd93f6a0634754d9d6f428465e871d271c66a767127e97`

## The worker's verdict block

```
1. [AC] Independent screenshot review (reviewer-judged, fw reviewer judge T-1212 --criterion 1): the designer shows a 1-in/1-out exclusive gateway as a WARNING, legibly, at three widths
VERDICT: green
WHY: Inspected [t1212-check-1024.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1024.png), [t1212-check-1440.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1440.png), and [t1212-check-1920.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1920.png) alongside [W-XML-GW-OUTGOING.xml](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/tests/fixtures/warn/W-XML-GW-OUTGOING.xml). Across all three widths (1024px, 1440px, and 1920px) in Workflow Designer v0.23.0: (1) the Validator dock header legibly reads "Validator  1 finding · 0 errors, 1 warning · 1 on the map"; (2) the finding row displays "WARN" (not ERROR), the rule ID W-XML-GW-OUTGOING, and the message exclusiveGateway has 1 outgoing flow(s); requires >= 2; (3) both the Validator dock's close (×) button and the toolbar's ✓ Check button are completely visible and unclipped; and (4) the agt_1_gate exclusive gateway on the map carries its amber warning marker badge in the top-right corner of the gateway node.
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Independent screenshot review (reviewer-judged, `fw reviewer judge T-1212 --criterion 1`): the designer shows a 1-in/1-out exclusive gateway as a WARNING, legibly, at three widths
VERDICT: green
WHY: Inspected [t1212-check-1024.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1024.png), [t1212-check-1440.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1440.png), and [t1212-check-1920.png](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/docs/reports/T-1212-evidence/t1212-check-1920.png) alongside [W-XML-GW-OUTGOING.xml](file:///tmp/tl-dispatch/judge-t-1212-r5-antigravity-ad276131b370/tree/tests/fixtures/warn/W-XML-GW-OUTGOING.xml). Across all three widths (1024px, 1440px, and 1920px) in Workflow Designer v0.23.0: (1) the Validator dock header legibly reads "Validator  1 finding · 0 errors, 1 warning · 1 on the map"; (2) the finding row displays "WARN" (not ERROR), the rule ID `W-XML-GW-OUTGOING`, and the message `exclusiveGateway has 1 outgoing flow(s); requires >= 2`; (3) both the Validator dock's close (`×`) button and the toolbar's `✓ Check` button are completely visible and unclipped; and (4) the `agt_1_gate` exclusive gateway on the map carries its amber warning marker badge in the top-right corner of the gateway node.
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
