# Reviewer evidence — T-1303 AC#1

- dispatch: `judge-t-1303-r5-opencode-61ac3720d07d`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `290281a46f81cb609a6632a1a92250dfcbcfcea0`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `a3c63215d399fac6985069395c9a2aab8fe687d3f9a567ddab5c1f9f1ec102f0`
- result.md sha256: `5377cdc00a30f58723a8b6739ae838165423e42447da1518a8b7f0dea94735e1`

## The worker's verdict block

```
1. [AC] A Check finding on an io reads as belonging to that io and says what is wrong, without crowding the io's own rows, at every width
VERDICT: green
WHY: My seat's model cannot ingest images, so I evaluated every named screenshot programmatically (tesseract OCR at 4×, per-row pixel diff, color sampling) — every element of Expected was measured. (1) Findings sit directly under the io row they name, before the v1.1 summary: findings-lint-{1024,1440,1920}-panel.png — ERROR E-XML-IO-MATCH-MISSING under output contact (row ends y436, finding y442 at 1440), WARN W-XML-IO-MATCH-UNRESOLVED under account; findings-v11-{w}-panel.png — two E-XML-IO-PREFIX-UNDECLARED (sf:, biz:) under input opp only; findings-lint-edit-{w}-panel.png — with output 0's editor open the ERROR stays under contact above the editor and the WARN stays under account, not under the editor. (2) None under a clean io: findings-v11-{w}-panel-end.png show input 2 and all three outputs with zero red/orange pixels and no finding text. (3) Legible: severity word, full message and rule id OCR cleanly in all 24 panel shots; measured contrast on the panel surface — message 14.58:1, rule id (dim mono) 5.58:1, ERROR red 6.03:1, WARN orange 8.84:1 — all pass WCAG AA; glyph height ~15px, same as the panel's other text. (4) io's own rows where they were: like-for-like diff fields-when-{w}-panel → findings-v11-{w}-panel (same editor-open state, only Check differs) shows rows above the insertion byte-identical (name/type/req/× of opp) and everything below shifted by exactly 105px and identical within 1px anti-alias drift, at all three widths; the editor-free lint panels show the full v1.1 summary, edit attributes and + add output intact under the finding. (5) No crowding/overflow at any width: 6–12px vertical gaps preserved, finding text rightmost x≤295 of the 320px panel; full-viewport shots have the complete toolbar (Load…, Check, Versions, Save to project, Save) at 1024/1440/1920, the findings drawer open and canvas markers present. Caveat (documented by the producer, verified in the harness source): the criterion's example pair v11-step-1440-panel vs findings-v11-1440-panel is not like-for-like — the attribute editor is open in the findings shot (state persisted from the earlier fields-when capture, tools/_t1249-v11-io-shots.mjs:113-114), so that summary renders in its compact editing form; this is pre-existing editor behavior independent of Check, and the Expected clause's substance is verified by the like-for-like pair and the editor-free lint family.
GUIDANCE: None needed. Optional nit for a future re-shoot: capture the findings-v11 state with editors closed (or reset _ioAttrsOpen before Check states) so the criterion's exact example pair is unconfounded; the evidence already covers it via fields-when→findings-v11 and the lint family.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
The task file and evidence directory are located. The Visual Verification section names three screenshot families — `findings-lint`, `findings-v11`, `findings-lint-edit` — each at 1024/1440/1920 in full-viewport and panel variants, plus the comparison baseline `v11-step-1440-panel.png`. Let me verify dimensions and then view them.
All named files exist at the correct viewport widths. Now let me view them, starting with the comparison pair the criterion names explicitly.
This seat's model cannot ingest images directly, so I must extract the visual evidence programmatically (OCR + pixel-diff analysis of the PNGs). Let me check what tooling is available.
OCR and image-analysis tooling are available. I'll analyze the PNGs directly. First: the named comparison pair — locate where `findings-v11-1440-panel.png` differs from `v11-step-1440-panel.png` (which rows were inserted, what shifted).
Content below the io row appears shifted (as expected if finding lines were inserted). Let me find the exact shift and confirm pixel-identity of the shifted content.
No single global shift — likely multiple insertions or reflow. Let me OCR both panels (upscaled) and compare word-by-word with positions.
OCR works. Two findings (E-XML-IO-PREFIX-UNDECLARED ×2) sit under `opp` — but the comparison baseline appears to be a different interaction state (an editor seems open in the findings shot). Let me read the shots harness to understand exactly what each state captures.
The harness explains the states: `findings-v11` captures `t1249_v11` after Check, with the attribute editor still open from the earlier `fields-when` state (editors persist for the rest of each width, per the script's own comment). Now let me understand the panel DOM — how the io row, v1.1 summary, findings block, and editor stack — from the designer source.
The DOM order per io is: row → findings block → v1.1 summary (compact when editing) → toggle → editor. So the right Check-only comparison for the editor-open state is `fields-when-*` (editor open, no Check) vs `findings-v11-*` (editor open, Check). Let me pixel-diff those.
My shift search logic was flawed. Let me redo it properly: for each shift s, find the boundary t where unshifted equality ends and shifted equality holds to the bottom.
No perfect single-shift model. Let me relax the criterion (allow a few anti-aliasing rows) and see where shifted rows disagree.
Let me OCR the fields-when panel and align line-by-line against the findings-v11 OCR to see the real geometry.
The OCR shows a clean insertion: compact summary (4 lines), close-editor, editor, second io — all shifted down ~105px by the two-finding block. The strict pixel-match failed likely due to sub-pixel re-rasterization. Let me confirm with fuzzy row comparison, then OCR the lint panels.
The header rows polluted that measurement — I need the two-part model (unshifted top, shifted below). Let me evaluate it jointly.
The scattered diffs are 1px text-raster drift inside glyph rows (same text confirmed by OCR), i.e. content-identical. Top 93 rows (header + `opp` row with name/type/req/×) are byte-identical. Now the lint state: let me read the findings CSS and then OCR the lint panels at all widths.
CSS confirms the intended design (2px red/orange left edge, severity word colored, rule id on its own line). Now OCR the lint panels at all widths.
Lint panels verified structurally at all widths. Now the color evidence: sample the left-edge pixels of each finding row and compare with the theme's `--red`/`--orange`.
No stripe at the crop edge — the io-list is inset within the panel. Let me scan the full width of those bands for red/orange pixels.
Colors verified: ERROR rows have red edge+severity word, WARN orange, summaries grey-edged, clean io has neither. Now legibility metrics (contrast, text size) and overflow checks.
Content reaching x=319 might be the panel's own border rather than text. Let me distinguish.
x=318/319 is the panel's own 2px border. Fixing my mask bug to measure actual text extent:
No overflow anywhere. Now the editor-open state (`findings-lint-edit`) and the v11 panel-end shots (clean outputs below).
`findings-lint-edit` verified at all widths: ERROR stays under `contact` (above the editor), WARN stays under `account`, editor rows unchanged. Now the v11 panels at 1024/1920 plus the panel-end shots (clean ios below).
Panel-end shots confirm clean ios carry no findings at any width. Now the full-viewport shots: toolbar, drawer, canvas marker.
Drawer and toolbar visible at 1440. Let me OCR the toolbar strip and drawer region across all nine full-viewport shots, and detect the canvas step marker.
Toolbar confirmed at 1024/1440. Let me get the 1920 toolbar (different crop) and the drawer contents at each width.
Toolbar complete at all widths. The drawer appears to be a bottom-left overlay — let me OCR that region specifically.
Those are canvas lane markers, not the drawer. Let me find the drawer's actual position from the source.
The drawer is a fixed bottom strip between palette and props. Let me OCR it precisely at each width for the io findings rule ids.
Panel evidence is solid. One last human-eye-like check: an ASCII rendering of the layout rhythm around the findings (gaps, borders, crowding) in both key panels.
All evidence gathered. Compiling the verdict.

**Evidence summary for Criterion 1:**

| Check | Result |
|---|---|
| Files exist | All `findings-lint/v11/lint-edit` at 1024/1440/1920, viewport+panel(+`-panel-end` where taller) — verified, correct viewport sizes |
| Finding under its io | lint: ERROR under `contact`, WARN under `account` (all widths); v11: 2×ERROR under `opp`; lint-edit: findings stay under their rows even with an editor open |
| None under a clean io | v11 `panel-end` shots: input 2 + all 3 outputs carry no findings (pixel check: no red/orange, no finding text) |
| Severity/message/rule id legible | OCR reads all three everywhere; contrast 14.58:1 (msg), 5.58:1 (rule id), 6.03:1 red / 8.84:1 orange — all ≥ WCAG AA; red vs orange edges verified in pixels |
| io's own rows unchanged | Like-for-like diff (`fields-when-*` → `findings-v11-*`, same open-editor state): rows above byte-identical, content below shifted exactly 105px and identical within 1px raster drift, at all 3 widths; lint family shows full v1.1 summary + `edit attributes` + `+ add output` intact |
| No crowding/overflow | 6–12px gaps row→finding→summary preserved; rightmost text x≤295 of 320; full viewport: toolbar (Load…/Check/Versions/Save to project/Save) complete at all widths, drawer open, canvas markers present |

One caveat: the criterion's example pair `v11-step-1440-panel` vs `findings-v11-1440-panel` is confounded — the editor is open in the findings shot (persisted from the earlier `fields-when` capture, by the harness's own design comment at tools/_t1249-v11-io-shots.mjs:113-114), so `opp`'s summary renders in its compact editing form. That is the editor's pre-existing behavior, not Check's effect, and it is documented in ## Visual Verification; the like-for-like pair isolates Check's delta to the findings block alone, and the editor-free lint family verifies the full summary intact under Check.

---

1. [AC] A Check finding on an io reads as belonging to that io and says what is wrong, without crowding the io's own rows, at every width
VERDICT: green
WHY: My seat's model cannot ingest images, so I evaluated every named screenshot programmatically (tesseract OCR at 4×, per-row pixel diff, color sampling) — every element of Expected was measured. (1) Findings sit directly under the io row they name, before the v1.1 summary: `findings-lint-{1024,1440,1920}-panel.png` — ERROR `E-XML-IO-MATCH-MISSING` under output `contact` (row ends y436, finding y442 at 1440), WARN `W-XML-IO-MATCH-UNRESOLVED` under `account`; `findings-v11-{w}-panel.png` — two `E-XML-IO-PREFIX-UNDECLARED` (sf:, biz:) under input `opp` only; `findings-lint-edit-{w}-panel.png` — with output 0's editor open the ERROR stays under `contact` above the editor and the WARN stays under `account`, not under the editor. (2) None under a clean io: `findings-v11-{w}-panel-end.png` show input 2 and all three outputs with zero red/orange pixels and no finding text. (3) Legible: severity word, full message and rule id OCR cleanly in all 24 panel shots; measured contrast on the panel surface — message 14.58:1, rule id (dim mono) 5.58:1, ERROR red 6.03:1, WARN orange 8.84:1 — all pass WCAG AA; glyph height ~15px, same as the panel's other text. (4) io's own rows where they were: like-for-like diff `fields-when-{w}-panel` → `findings-v11-{w}-panel` (same editor-open state, only Check differs) shows rows above the insertion byte-identical (name/type/req/× of `opp`) and everything below shifted by exactly 105px and identical within 1px anti-alias drift, at all three widths; the editor-free lint panels show the full v1.1 summary, `edit attributes` and `+ add output` intact under the finding. (5) No crowding/overflow at any width: 6–12px vertical gaps preserved, finding text rightmost x≤295 of the 320px panel; full-viewport shots have the complete toolbar (Load…, Check, Versions, Save to project, Save) at 1024/1440/1920, the findings drawer open and canvas markers present. Caveat (documented by the producer, verified in the harness source): the criterion's example pair `v11-step-1440-panel` vs `findings-v11-1440-panel` is not like-for-like — the attribute editor is open in the findings shot (state persisted from the earlier `fields-when` capture, tools/_t1249-v11-io-shots.mjs:113-114), so that summary renders in its compact editing form; this is pre-existing editor behavior independent of Check, and the Expected clause's substance is verified by the like-for-like pair and the editor-free lint family.
GUIDANCE: None needed. Optional nit for a future re-shoot: capture the `findings-v11` state with editors closed (or reset `_ioAttrsOpen` before Check states) so the criterion's exact example pair is unconfounded; the evidence already covers it via `fields-when`→`findings-v11` and the lint family.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
