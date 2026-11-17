# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-codex-14995dee4fb8`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `c7822ac5108b9b55e2bf47bf562e959f2f9f34f0`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `1842045cba41b0df3a2f1e5c58389068e0bee93e160d882d2b4042b7e9e34f33`
- result.md sha256: `4c0f3449d372565825a2242f5d72394bbd0acc704e83f4290dc8380ef64a1235`

## The worker's verdict block

```
1. [AC] The two markers read as different kinds of thing, and the common case is silent.
VERDICT: not-evaluated
WHY: I opened the supplied differs-m.png, missing-m.png, and none-m.png. Visually, the faint grey “◆ ini” reads as an annotation; the orange “⚠ no auth” reads as a defect; none-m has no authority marker. Neither marker appears mis-pitched, and the displayed missing marker does not overlap incoming edges. However, running the screenshot script in a scratch copy failed with listen EPERM: operation not permitted 127.0.0.1. I could not independently regenerate the screenshots or verify hover behavior.
GUIDANCE: Route to a reviewer whose sandbox permits the local HTTP server and headless Chromium. Regenerate the nine screenshots and verify the full hover text; the supplied medium-size screenshots support the requested visual contrast.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] The two markers read as different kinds of thing, and the common case is silent.
VERDICT: not-evaluated
WHY: I opened the supplied differs-m.png, missing-m.png, and none-m.png. Visually, the faint grey “◆ ini” reads as an annotation; the orange “⚠ no auth” reads as a defect; none-m has no authority marker. Neither marker appears mis-pitched, and the displayed missing marker does not overlap incoming edges. However, running the screenshot script in a scratch copy failed with `listen EPERM: operation not permitted 127.0.0.1`. I could not independently regenerate the screenshots or verify hover behavior.
GUIDANCE: Route to a reviewer whose sandbox permits the local HTTP server and headless Chromium. Regenerate the nine screenshots and verify the full hover text; the supplied medium-size screenshots support the requested visual contrast.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```
