# T-1474 — Human AC#1 — independent review evidence

Reviewer dispatch: judge-t-1474-r3-2e85af468b4f
Revision reviewed: 293cff55cfaa20b191f055e54582312684e68535
Criterion: flow labels read as well or better; the moved "not found" label still reads as its flow's drop.

## What I checked

Images in docs/reports/T-1474-shots/ (new = this change, v046 = 0.46.0 baseline). Copies cited here are in this directory with my dispatch suffix.

1. review-emission flow, full width, 1024 / 1440 / 1920 (`new-review-emission-*`, `v046-review-emission-*`).
2. Gateway region enlarged 3x (crops `gw-{new,v046}-review-emission-{1024,1440,1920}-judge-t-1474-r3-2e85af468b4f.png`, cut from the full images at x 560–780, y 360–430; no other processing).
3. verification-gate and task-lifecycle at 1440 (`new-/v046-verification-gate-1440`, `new-/v046-task-lifecycle-1440`).

I did not re-run the app or the capture script (`shots.mjs`); judged the images as given.

## Findings

- "not found" moved right ~24 px at every width: v046 starts at x≈649 (1440, 1920) and x≈645 (1024); new starts at x≈673 at all three widths. Consistent with the stated zoom-independent placement.
- 1440 and 1920: new "not found" is fully visible, sits to the right of the not-found arrow, and is clear of "Task file found?" and of the gateway name `frw_gw_task`. It reads as the label of the drop to "return 1 — no task file". Both pass the "belongs to its drop" check.
- The v046 1440/1920 positions already did not run on with "found?" in these captures, so the captures do not show the "no longer runs on" improvement the criterion names. The visible change is only the 24 px shift.
- 1024: this is worse than the baseline. v046 shows "not fou" before the open side panel edge (~x 704); new shows only "not" (the label now starts at x≈673 and is cut at the panel edge). The criterion's item 4 asks whether this is acceptable given neighbours are also cut.
- Neighbours at 1024: the gateway's right-hand "found" flow is hidden under the panel, as the criterion states. So "not found" is cut "like its neighbours", but it is cut earlier than in 0.46.0.
- Other flow labels: in review-emission 1440/1920, verification-gate 1440 and task-lifecycle 1440 the visible labels are identical between new and v046 (inception?, standard, found, rejoin, links ok, homework, Check, Validate, Print review card, Block, re-run, Partial-complete, etc.). Nothing else reads worse in the captured region. Labels past the right panel edge (e.g. "QR + artifact", "every verify cmd exit") are cut identically in both.

## Why escalate

The open question is whether a label cut at 1024 is acceptable, or whether the opening view at narrow widths should become its own task. The criterion itself names this as a project-direction call: it would change how maps open, not where labels sit. I cannot settle that from the images. Neither reading is a verifiable fact in the screenshots.

## Verdict

escalate. Labelling at 1440 and 1920 is met and nothing else reads worse. At 1024 the label shows only "not", which reads worse than 0.46.0's "not fou". Whether that is acceptable, or should go to a separate opening-view task, is for the human.
