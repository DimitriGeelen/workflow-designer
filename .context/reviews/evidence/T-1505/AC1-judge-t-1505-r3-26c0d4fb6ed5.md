# T-1505 Human AC#1 — independent image review (run judge-t-1505-r3-26c0d4fb6ed5)

Revision reviewed: bb5be649e77f5967f44da3bc8765f709daea883a
Images opened (all 12 in docs/reports/T-1505-shots/ were viewed; the 8 cited are copied here with the run suffix):
handle-hover-{1024,1440}.png, handle-hover-closeup-{1024,1440,1920}.png (1920 closeup viewed, not copied),
dragging-{1024,1440,1920}.png, moved-{1024,1440,1920}.png (1920 handle-hover full viewed, not copied).
Harness not re-run (per brief). Digest: 783a8cf992ff (`.agentic-framework/bin/fw reviewer verdict digest T-1505 --ac 1`).
Note: the brief names `bin/fw`; that path does not exist in this repo, only `.agentic-framework/bin/fw`, which I used.

## Discoverability (hover)
- handle-hover-1440: a short olive accent bar sits on the header line at x≈930, which is the shared edge between
  "Configuratie" (row 2) and "Offerte & onderhandeling" (row 2). Its position matches the boundary between the two phases.
- handle-hover-closeup-1440 / 1024 / 1920: the bar is visible and is the only hover affordance shown.
- Gap: no mouse pointer or cursor shape is visible in any hover shot, so the "pointer on the edge" condition in the
  criterion cannot be confirmed from the images. No non-hover baseline is supplied, so "appears on hover" is also not shown.
  The bar is small (~12x45 css px at 1440; ~8x25 px at 1920 display scale), which may be hard to notice.

## Landing before release (dragging)
- dragging-1440: a bright dashed yellow-green vertical line at x≈1128, which lies in the empty gap between "Send Proposal"
  (ends ≈1100) and "Opportunity (Proposal)" (starts ≈1157). Row 2 "Offerte" is highlighted from that line.
- dragging-1920: dashed line at x≈1097, in the gap between "Send Proposal" (ends ≈1074) and "Opportunity" (starts ≈1117).
- dragging-1024: dashed line at x≈1180, in the gap between "Send Proposal" (ends ≈1140) and "Opportunity" (starts ≈1222).
- The landing place is clear and sits between steps at all three widths.

## Result (moved)
- moved-1440: row 2 boundary now at x≈1128; "Configuratie" and "Offerte & onderhandeling" labels are both fully visible;
  dashed divider runs through all lanes at the new place. Reads correctly.
- moved-1920: boundary at x≈1097; both row-2 labels visible; divider through lanes. Reads correctly.
- moved-1024: the new boundary and divider are visible, but the canvas is scrolled: the "Configuratie" label is clipped at the
  left edge ("figuratie") and the "Offerte & onderhandeling" label is off-screen to the right, so the result cannot be read
  as a whole at 1024. This is a viewport/scroll capture issue, not a rendering defect in the slice, but the shot does not
  show the result the criterion asks for.

## Clipping / overlap (pre-existing, not introduced by this slice)
- Row 1 "4 Negotiation" / "5 Close" labels run off the right edge at every width.
- At 1024 the top toolbar wraps onto two rows and the warning banner covers the top of the canvas.

## Judgement
Met at 1440 and 1920: the edge is found, it lands in a gap, and the result reads. Not fully met at 1024: the result labels
are out of view in the captured frame, and the hover affordance is not shown with a pointer. Needs: a 1024 moved shot with
both row-2 labels in view, and a hover shot with the pointer on the bar (or the cursor change), before green.
Human judgement is not needed for this; the reviewer can accept or request the re-capture.
