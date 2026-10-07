# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-codex-b42fd5db2e94`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `b0e8abe2782a4d5034ae40a2da6b25940b44f22b`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `093ac53c7fb1594e9af8479abe21c2af802f8222cfe657a31fe53ee190a367f2`
- result.md sha256: `076b65e5627e3b5318707bfc7a658a11214f19647a9cfce11786245e889b51e8`

## The worker's verdict block

```
1. [AC] Distinct marker kinds; common case silent
VERDICT: amber
WHY: Inspected all nine committed screenshots. The medium images show a faint “◆ ini” annotation, a visibly stronger orange “⚠ no auth” defect marker, and no authority marker in the common case. Neither marker appears mis-pitched; missing-m.png shows no collision with the incoming edge label. Source confirms adaptive shortening and full-text SVG titles. The state test passed 13/13. Fresh screenshot generation and live hover verification remain unverified: the required script writes files, conflicting with this review’s read-only restriction.
GUIDANCE: Run the screenshot script in a writable isolated checkout of the reviewed revision, confirm successful completion, and verify the full-text hover. No visual adjustment is indicated by the saved images.

Summary: 0 green, 1 amber, 0 red, 0 escalate
```

## The worker's full output (result.md)

```
1. [AC] Distinct marker kinds; common case silent
VERDICT: amber
WHY: Inspected all nine committed screenshots. The medium images show a faint “◆ ini” annotation, a visibly stronger orange “⚠ no auth” defect marker, and no authority marker in the common case. Neither marker appears mis-pitched; `missing-m.png` shows no collision with the incoming edge label. Source confirms adaptive shortening and full-text SVG titles. The state test passed 13/13. Fresh screenshot generation and live hover verification remain unverified: the required script writes files, conflicting with this review’s read-only restriction.
GUIDANCE: Run the screenshot script in a writable isolated checkout of the reviewed revision, confirm successful completion, and verify the full-text hover. No visual adjustment is indicated by the saved images.

Summary: 0 green, 1 amber, 0 red, 0 escalate
```
