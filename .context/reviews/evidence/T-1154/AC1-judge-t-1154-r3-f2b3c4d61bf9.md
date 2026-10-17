# T-1154 Human AC#1 — reviewer judge-t-1154-r3-f2b3c4d61bf9 (rung-3), revision b4c6ff22

## What I checked
I opened all six screenshots in `.playwright-mcp/` (t1154-{1024,1440,1920}-{fit,zoomed}.png, dated 2026-10-17 18:31, just before
commit b4c6ff22 at 18:34). Then I cropped the pool's right end and bottom edge with PIL and enlarged them 3–6× to read them closely.

## Right edge (the core of the criterion): met in all six
| shot | label + badge vs right border | header band / lanes |
|------|-------------------------------|---------------------|
| 1024 fit | label and frw_end_resolved end inside; the gap is about 2–3 screen px at this tiny scale but visible when enlarged | reach the border |
| 1024 zoomed | label ends at x≈644, border at x≈664: about 20 px gap | header band and all 3 lanes reach x≈664 |
| 1440 fit | inside, with a visible gap | reach the border |
| 1440 zoomed | label ends at x≈1059, border at x≈1080: about 20 px gap (crop-1440-zoomed-right-edge) | reach the border |
| 1920 fit | inside, with a clear gap | reach the border |
| 1920 zoomed | label ends at x≈1539, border at x≈1560: about 20 px gap | reach the border |
The wider pool looks intentional: the header band, lane fills and dividers all end on the same right edge, and there is no short band.

## Exception: "nothing else in the canvas ... overlapped"
- t1154-1920-zoomed.png and t1154-1920-fit.png: the id badge `agt_4_apply` (under "Apply the chosen recovery", bottom lane)
  sits on the pool's BOTTOM border. Its background hides the border line where it crosses
  (crop-1920-zoomed-bottom-badge-*, crop-1920-fit-bottom-badge-*).
- The task records this as a deliberate choice ("Decisions: 2026-10-17 — Bottom edge left as is"; badges up to +6 px below).
  But the author's Visual Verification table does not mention it, and the criterion as worded ("nothing else ... overlapped",
  "in all six") does not exempt it.
- I accepted these as by design or not related to this change: the sticky lane-name strip covering part of the end event at 1024 zoomed (T-1091,
  documented); the "Mode: select" badge and the "Restored your unsaved work" autosave toast floating over the canvas bottom
  (existing overlay chrome). No toolbar or panel control is clipped.

## Verdict: amber
The right-edge fix the criterion asks for is fully met. The only gap is the bottom-border badge overlap at 1920, which the
criterion's literal wording counts as an overlap.
