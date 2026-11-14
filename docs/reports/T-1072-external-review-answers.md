# T-1072 — External review of the revised objectives: findings and answers

Consult `t1072-objectives` (`.context/consults/t1072-objectives.json`), 2026-11-14 21:57Z, paid proposal RP-2a8817eb
approved by the operator (job 139). Brief: `docs/reports/T-1072-external-review-brief.md`. Panel: openai/gpt-4o,
google/gemini-2.5-pro, x-ai/grok-4.7, deepseek/deepseek-chat, qwen/qwen-2.5-72b-instruct; 5 of 5 answered.

## Findings, grouped, with the answer to each

| # | Finding | Raised by | Answer | Where |
|---|---|---|---|---|
| F1 | O-2 still says a map "is refused" on promote, contradicting "advisory, never a hard block; the hatch never closes" (and O-4) | gpt-4o, grok, deepseek, qwen | **Accepted, fixed.** O-2 now: the marker is authored and exported; the designer never promotes and never refuses; what a promote does with it is AEF's decision. | objectives.yaml O-2 |
| F2 | Absence is unobserved: a step that never starts or "fades into darkness" has no failure to show | gemini, grok, deepseek | **Accepted, fixed.** O-4: a step may declare when it is expected to finish; one with no outcome by then is shown as stalled. Who arms the timer stays the runtime's (the designer does not execute). | O-4 |
| F3 | "Humans where it really matters" is not expressible; warning on every skipped gateway pressures gates everywhere | gemini, grok, deepseek | **Accepted, fixed.** O-4: a step can be marked as needing a human with a reason (destructive, risky, uncertain), and other steps are not. | O-4 |
| F4 | The override record should say who and why ("not lightly") | deepseek | **Accepted, fixed.** O-4: override logged with who and why. | O-4 |
| F5 | Strictness "earned by repetition" can make a much-run draft stricter than a new ratified procedure | grok, gemini (draft lifecycle) | **Accepted, fixed.** O-4: stricter "as a process matures from draft to ratified". | O-4 |
| F6 | O-5 names a second tenant no operator quote names; "standalone plugins" is not "a second application runs processes" | grok, deepseek (partly), qwen | **Open, for the operator.** Options: drop O-5; or reduce it to "no hard-coded tenant and no service dependency in what the designer exports". | Q1 below |
| F7 | O-1 ("implement from the picture alone, no recourse to the task text") contradicts "tasks are canonical" | grok | **Open, for the operator.** Proposed fix: strike "no recourse to the task text"; measure diagram/task agreement on a fixed field list instead. | Q2 below |
| F8 | O-6 (byte-identical re-pin) and O-9 (lossless within the frozen standard) are two incompatible oracles | grok | **Proposed:** merge into one interchange objective with O-9's oracle (lossless within the frozen boundary); keep reverse-render of existing work as its own, still unmeasured part. | Q3 below |
| F9 | The learning loop the operator described adjusts *risk and routing confidence*, not only template versions | grok | **Accepted in part:** O-8 already makes every change a proposal; the routing-confidence signal (deterministic path failed / unclear / edge case) belongs to O-7's preference and would be proposed the same way. Left as a note for the operator's ratification, no new objective. | — |
| F10 | The objectives treat the map as the territory: an agent's off-diagram recovery may not reverse-render into a readable picture | gemini | **Recorded as the open risk of O-6's reverse half**, which the draft already marks "not measured yet". Gemini's proposed test (force a fallback at step 3 of 5, render the trace) is the right first measurement. | — |
| F11 | No explicit "draft" state between documentation and template | gemini | Covered by O-4's draft-to-ratified wording and EWCR's ratification; no separate objective. | — |

## Questions for the operator (before ratifying T-986)

- **Q1 (O-5, second tenant):** a) drop it; b) reduce it to "no hard-coded tenant, no service dependency in exports";
  c) keep it and name the second tenant yourself.
- **Q2 (O-1 vs tasks canonical):** a) strike "no recourse to the task text" and measure diagram/task agreement;
  b) keep O-1 as written.
- **Q3 (O-6 and O-9):** a) merge into one interchange objective (lossless within the frozen standard) plus
  reverse-render as its own part; b) keep both.

## Did the consult change a decision?

Yes: O-2's refusal sentence was removed, and O-4 gained absence, human-only-where-it-matters, who/why on overrides and
maturity tied to ratification (F1-F5). Recorded as `changed_decision` on the consult.
