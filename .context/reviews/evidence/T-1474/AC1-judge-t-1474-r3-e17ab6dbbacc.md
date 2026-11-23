# T-1474 — Human AC#1 evidence (independent reviewer, rung 3)

Reviewed revision: 63699b62b079bea49169b22940913207cba9e9d1
Dispatch: judge-t-1474-r3-e17ab6dbbacc
Digest (`fw reviewer verdict digest T-1474 --ac 1`): 860f2cf45d5b

## Criterion (as written)
"[REVIEW] Flow labels read as well or better, and the moved 'not found' label still reads as its flow's
drop." Expected: "not found" clearly belongs to its drop and no longer runs on with "found?"; nothing else
reads worse. If not: name the label and what reads worse.

## What I checked
Images only (no harness re-run). Pixel diff via PIL of each v046/new pair (same width):
- review-emission 1024/1440/1920, verification-gate 1024/1440/1920, task-lifecycle 1024/1440/1920 all differ.
  Diff regions: review-emission confined to the gateway/drop area; verification-gate and task-lifecycle
  diffs are small offsets around flow labels.

### review-emission (the moved label)
- 1440 (`new-review-emission-1440`, `v046-review-emission-1440`): v046 "not found" sits tight against the drop
  line and close to "found?". New: "not found" is ~30 px right of the drop line and clear of "Task file found?"
  / frw_gw_task. It still sits level with its drop and no other line is next to it. Meets the Expected.
- 1920 (`new-review-emission-1920`, `v046-review-emission-1920`): label fully visible, clear of the gateway
  name, next to its drop. Meets the Expected.
- 1024 (`new-review-emission-1024`, `v046-review-emission-1024`): the canvas side-panel handle (the ▸ toggle at the
  canvas right edge) overlaps the label in BOTH versions. v046 shows "not fou" before the handle; the new
  render shows only "not". The label moved further right into the handle, so at 1024 it no longer reads as
  "not found". This is a regression at a required width (UX_SHOT_WIDTHS includes 1024), not a pre-existing
  equal state.

### verification-gate and task-lifecycle (other flow labels), checked at 1440
(`new-verification-gate-1440`, `v046-verification-gate-1440`, `new-task-lifecycle-1440`, `v046-task-lifecycle-1440`)
- "agent ACs unchecked (P-010)", "a verify cmd exit ≠ 0 (P-011)", "sovereignty bypassed (Tier-2)",
  "only human ACs remain (T-193)", "agent ACs checked", "build-ready", "re-check", "placeholder ACs",
  "resume after healing": all read the same as v046. Line routing changed only slightly. No label reads
  worse at 1440. I did not compare these at 1024 or 1920.

## Crops written (my own, in this directory)
- crop-review-emission-1440-v046-top-new-bottom-judge-t-1474-r3-e17ab6dbbacc.png
- crop-review-emission-1024-1920-v046-left-new-right-judge-t-1474-r3-e17ab6dbbacc.png (1024 = top row; 1920 = bottom row)
- crop-verification-gate-1440-judge-t-1474-r3-e17ab6dbbacc.png
- crop-task-lifecycle-1440-judge-t-1474-r3-e17ab6dbbacc.png

## Finding
At 1024 the moved "not found" label runs under the canvas panel handle and loses "found". Before the change
it showed "not fou". The criterion's "reads as its flow's label" is not met at that width.
Verdict: AMBER. Needed: pull the vertical-drop label back left (smaller side offset for a vertical drop, or a
clamp that keeps it clear of the right canvas handle at 1024), then re-render v046-vs-new review-emission at
1024 and confirm "not found" is fully visible and clear of "Task file found?". The 1440/1920 renders already
satisfy the Expected. Other labels: no regression at 1440.
