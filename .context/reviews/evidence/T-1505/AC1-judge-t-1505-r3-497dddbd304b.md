# T-1505 Human AC#1 — independent image review (dispatch judge-t-1505-r3-497dddbd304b)

Revision reviewed: d5511667060cb88ee88e4f6b6cbf38f2f07505d7 (= HEAD)
Digest: 5303e5fe7222
Scope: judged on the supplied images only. The harness was not re-run. Shots are in docs/reports/T-1505-shots/.

## What I looked at

Sample map: process_nooteboom (Greenfield sample). Shown in the viewer header and the right panel as process_nooteboom.

| Criterion step | Image (copied as evidence) | What it shows |
|---|---|---|
| Baseline, pointer away | handle-idle-closeup-1920 | Gap between brackets "Configuratie" | "Offerte & onderhandeling" at the boundary; no accent. Idle state shows the edge only as a small notch. |
| Discoverable on hover | handle-hover-closeup-1920 | Solid green-olive accent bar sits on the gap between the two brackets, plus a dashed guide down the lanes. |
| Discoverable on hover | handle-hover-closeup-1024 | Same accent bar at 1024. |
| Discoverable on hover | handle-hover-closeup-1440 | Same accent bar at 1440. |
| Landing place before release | dragging-1920 | Mid-drag: yellow dashed line sits in the gap between Send Proposal and Opportunity (Proposal + doc. sturen), i.e. between two steps. |
| Before (undone) | before-1920 | Divider between Firm Ready and Send Proposal (dashed line at x≈800); Configuratie and Offerte brackets meet there. |
| After (redone) | moved-1920 | Same view, divider now between Send Proposal and Opportunity (Proposal + doc. sturen); "Configuratie", "Offerte & onderhandeling", "3 Proposal" headers in view; brackets moved to match. |
| 1024 pair | before-1024, moved-1024 | Zoomed out to 51%; divider moves from between Firm Ready / Send Proposal to between Send Proposal / Opportunity. Both neighbouring phase names visible ("Configuratie", "Offerte & onderhandeling"). |
| 1440 pair | (dragging-1440 and before-1440 seen, not copied) moved-1440 | Divider moves from between Firm Ready / Send Proposal to between Send Proposal / Opportunity; phase brackets updated. |

Not viewed: handle-idle-closeup-1024 and handle-idle-closeup-1440 (the 1920 baseline was viewed); handle-hover full-frame 1024/1440/1920 (only the close-ups were opened). I did not copy dragging-1024, dragging-1440 or the 1440 before file as cited evidence; I did view them.

## Judgement against the four questions

1. Is the handle discoverable on hover? Yes. The accent bar appears on hover at all three widths I opened. It is small, and it appears only on hover (idle shows just a notch). That meets "a person sees that the edge can be dragged" as the criterion describes.
2. Is the landing place clear before release? Yes. The dashed guide and the mid-drag line show the boundary landing in the gap between two steps (1920 and 1024 both confirmed).
3. Does the result read? Yes. The before/moved pair in the same view shows the bracket and divider moved between the same steps the criterion names (1920: Firm Ready|Send Proposal to Send Proposal|Opportunity).
4. Is anything clipped or overlapping? At 1024 the zoomed-out view clips the leftmost phase label ("...osal)" / "...lysis (blijft tot Proposal)") at the canvas edge. The neighbouring phases the criterion requires are fully readable, and the clipped label is not the handle. The toast panel at 1024 does not overlap the phase header row. No overlap seen with the handle.

## Not evaluated / not relied on

- The pointer cursor (col-resize) is not in any screenshot. The criterion says the harness asserts it. I did not see the harness output and did not rely on it. This does not change the image judgement above.
- The "Judged by" command in the criterion text is `fw reviewer judge`. I used `.agentic-framework/bin/fw` because `bin/fw` is absent in this checkout (see the brief). No restatement proposed; the criterion's literal meaning is unchanged.

## Verdict

green on Human AC#1, judged on the images. Guidance: none required.
