# T-1504 Human AC#1 — independent image review (run run-t-1504-71db63c7ff)

Revision reviewed: c1800044a2f3ef6ed86254f975eab8fd951de3ef (HEAD matched at review time).
Images: the 12 files in docs/reports/T-1504-shots/, copied here as `<name>-<width>-$FW_SIDECAR_AGENT_ID.png`. Opened and inspected every one. No harness or app run (per brief).
The existing AC1-judge-t-1504-r3-4a63e7d3c4f5.md (amber, rev 51f261e85) is another run's record; I read it as input and did not touch it. Its one gap (no dashed split line in split-preview shots) is closed in these shots at all three widths; the fix commit c1800044a ("split-preview shots scroll the hovered gap into view") is the change that did it.

## Per element, per width (1024 / 1440 / 1920)

1. **palette** — Phases section under LANES with two items: "Add phase row — one phase across the map" and "Add phase — click where it starts". Footer: "Click a palette item then click the canvas to place". Names and hints readable at all three widths; nothing clipped. Clear.
2. **row-added** — One bracket labelled "Phases" runs across the top of the pool (lime bracket). Right panel: `phase` / Name "Phase 1" / Row "Phases". Status bar: "Mode: select · phase selected". The new phase is visibly selected. Clear.
3. **split-preview** — "Add phase" palette item highlighted; status bar "Mode: add phase: click where it starts · phase selected" at all widths. A dashed lime vertical line (the landing line) is drawn across the pool at all three widths: x≈858 at 1440, x≈896 at 1024, x≈643 at 1920 (scaled display), sitting in the gap between the step nodes. The landing line is visible, so a person sees where the split will land before clicking.
4. **five-phases** — 1440 and 1920 show "Phase 4" and "Phase 5" labels, Phase 5 bracket in lime and selected, panel reads "Phase 5", dashed dividers at the step gaps. 1024 shows the selected Phase 5 bracket at the right edge and "ase 4" clipped at the left edge because the canvas is scrolled. Scroll position limits how many of the five brackets are in frame; no bracket overlaps or is cut mid-label apart from that scroll edge. Dividers at gaps visible.

## Clipping / overlap
- No overlap between palette, status bar, notification stack and pool at any width.
- Notification banners sit over the top of the canvas in every shot; they do not hide the Phases bracket.
- Pool extends past the viewport in the shots (scrolled canvas). Normal, not a defect of the feature.

## Limits of this evidence
- Five-phase shots do not show all five brackets at once (canvas scrolled). The dividers and the selected fifth phase are visible; the other brackets are off-frame. Not a readability problem for the criterion.
- Judgement is on the images only; I did not re-run the harness (brief).

## Verdict
green. The palette, the row, the landing line, the selection and the five-phase result are visible and match the Expected clause at all three widths.
