# T-1474 Human AC#1 — independent image review (dispatch judge-t-1474-r3-fb3c7fd7d628)

Revision reviewed: 84ea3eb76b3053b45fbbdcc9fd48fedd90636df8
Digest (`fw reviewer verdict digest T-1474 --ac 1`): eadd9f697578

Note: the brief's entrypoint `bin/fw` does not exist in this checkout; `.agentic-framework/bin/fw` does and was used for the digest and record. Nothing was re-run; images only (per brief).

## Criterion read as written
"Flow labels read as well or better, and the moved 'not found' label still reads as its flow's." Judge: new vs v046 at 1440 and 1920 (review-emission), 1440 (verification-gate, task-lifecycle), and at 1024 that nothing else reads worse. 1024 "not" cut by the open side panel is accepted by operator decision (2026-11-24), so not judged as a failure.

## Images opened (copies in this directory, suffix -fb3c7fd7d628.png)
- v046-review-emission-1440 / new-review-emission-1440
- v046-review-emission-1920 / new-review-emission-1920
- v046-review-emission-1024 / new-review-emission-1024
- v046-verification-gate-1440 / new-verification-gate-1440
- v046-task-lifecycle-1440 / new-task-lifecycle-1440

## Findings
1. **"not found" (review-emission, 1440 and 1920).** v046: the label starts at about x=648 (1440 frame), right beside the gateway's bottom edge, and runs close to "Task file found?" (ends about x=636). New: the label sits about x=673–727, roughly 30 px to the right of the drop arrow (x≈641), on the row of the arrow, clear of the gateway text and of the "found" label above the "found" flow. Reads as the label of the not-found drop into "return 1 — no task file". Same at 1920 (new label at x≈673, clear of the gateway text).
2. **Other labels, review-emission.** "found", "inception", "rejoin", "standard", "links ok", "homework" are in the same positions in v046 and new; none reads worse.
3. **verification-gate 1440.** Visually identical between v046 and new (e.g. "agent ACs unchecked (P-010)", "a verify cmd exit ≠ 0 (P-011)", "agent remediates", "re-run"). No label reads worse.
4. **task-lifecycle 1440.** Visually identical between v046 and new ("build-ready", "placeholder ACs", "re-check", "resume after healing"). No label reads worse.
5. **1024 (review-emission).** New: "not" is cut at the side panel edge; v046 shows "not fou" at the same edge. Operator accepted this (criterion text, Decisions). Other labels in the visible part (Task file found?, frw_gw_task, return 1 — no task file) are unchanged and read the same.

## Limits
- Judged from the screenshots only; no app run. Fine detail (sub-pixel spacing) is judged at the image's resolution.
- The 1024 and 1920 verification-gate and task-lifecycle frames were not in the criterion's step list and were not used.

## Verdict
green — the moved "not found" label clearly belongs to its drop at 1440 and 1920, does not run on into "found?", and no other flow label reads worse in any cited frame. The 1024 cut is out of scope per the operator's decision.
