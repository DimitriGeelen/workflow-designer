# Reviewer evidence — T-1303 AC#1

- dispatch: `judge-t-1303-r5-opencode-1e33eef65c8f`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `a1d493cbcd050ca2d150c75a665487d640f78fee`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `005863aa38f2d57597e96c4486675dc20434b46d2de54ec4c46d5cc0fa6e857d`
- result.md sha256: `a9c191821399ac783c5240e91ab03626b0c35af1188dcc4166ddd78d5e17dd0b`

## The worker's verdict block

```
1. [AC] Check finding on an io reads as belonging to that io, says what is wrong, without crowding the io's own rows, at every width
VERDICT: green
WHY: This seat's model has no image input, so I verified the named screenshots by instrumented reads (tesseract OCR at 4x upscale + pixel-diff) of every findings-* file in docs/reports/T-1303-evidence/ (23 shots: lint, v11, lint-edit × 1024/1440/1920 × full/panel/panel-end), plus a live re-run of the work's own CDP leg (node tools/_t1303-io-findings-cdp.mjs → exit 0, ok:true, errs:[], all temp writes under /tmp; tree untouched). Placement: OCR reading order shows each finding directly under the io row it names — contact→ERROR+message+E-XML-IO-MATCH-MISSING then its v1.1 summary and "edit attributes"; account→WARN+W-XML-IO-MATCH-UNRESOLVED; opp→two ERRORs (sf:, biz:)+E-XML-IO-PREFIX-UNDECLARED — with the inputs section clean (lint state), outputs clean (v11 state), and with an editor open the WARN stays under account, not under the editor; the DOM leg confirms finding-under-its-own-io-only, clean io shows none, renamed io shows nothing. Legibility: severity word, full wrapped message and full rule id OCR cleanly at every width, including 1920 (panel is a fixed 320px at all widths, so horizontal pressure is identical); producer's noted "rule id small and muted" is deliberate (label-grey token) and still machine-legible at all widths. No crowding: header+io-row band of v11-step-1440-panel.png is pixel-identical (diff 0.0) in findings-v11-1440-panel.png; CDP leg c shows a clean step's panel byte-identical before/after Check; geometry leg f shows every finding line inside the panel, no overflow, on top at 1024 and 1440. Caveats, none blocking: (a) the criterion's named comparison pair is not editor-matched (v11-step: editor closed; findings-v11: editor open from an earlier state — the summary collapse that follows is pre-existing T-1249/T-1301 behaviour, not Check-caused); (b) 1920 geometry rests on screenshot OCR completeness, not the CDP leg, which stops at 1440.
GUIDANCE: none needed; optionally add 1920 to the CDP geometry leg f and pair the no-Check counterpart with the same editor state in a future evidence run.
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
The task file names the evidence. Now let me view the primary screenshots named in the Visual Verification section.
The Read tool in this seat cannot render images (no image input support). Before returning not-evaluated, I'll attempt programmatic evaluation of the screenshots (OCR / pixel-diff / DOM harness), since the criterion is a render-surface check.
Node, Chromium, tesseract and PIL are all available, and there's a T-1303-specific CDP leg. Let me inspect it.
This CDP leg drives the real editor against the real server and asserts the placement/geometry claims directly. Let me check it doesn't write into the fingerprinted tree, then run it.
The harness writes only under `os.tmpdir()` (authorized scratch), never into the fingerprinted tree. Running it now.
CDP leg is green against this revision's own source: findings under their own io rows only, clean io clean, clean step byte-identical, drawer/canvas intact, geometry inside-panel/no-overflow/on-top at 1024 and 1440. Now I'll verify the screenshots themselves via OCR and pixel-diff (since this seat can't view images directly).
OCR confirms severity, message and rule id at all widths, findings directly under their io rows, clean sections clean, io's own rows and v1.1 summaries intact. Now the criterion's step 2: pixel-compare `v11-step-1440-panel.png` (no Check) with `findings-v11-1440-panel.png`.
The whole-panel diff is confounded (first diff at row 2). Let me OCR the no-Check counterpart to understand its state, then do band-level matching.
In `findings-v11-1440-panel` the editor is open (pre-existing state), so I'll compare against the same-editor-state `hint-edit-1440-panel` (no Check) for a clean diff, plus verify the io row band sits unchanged.
OCR shows `hint-edit` is a different step — not a counterpart. The criterion's named pair (v11-step vs findings-v11) differs by the pre-existing open-editor state, so I'll verify the structural claim on the pair it names via band matching, and check the severity edge colors.
The io row band is pixel-identical in place (match 0.0 at the 19px crop offset). The edge-color scan found nothing at threshold — let me scan more sensitively for the severity colors.
Edge detection is inconclusive (text antialiasing). Let me verify the full-viewport screenshots at each width by OCR-ing the panel region of the full-page shots.
Nearly complete. Let me OCR the remaining named screenshots for full width coverage (findings-lint-1440 full, findings-lint-edit 1024-panel/1440-panel-end/1920 full).
All evidence gathered. Final verdict:

1. [AC] Check finding on an io reads as belonging to that io, says what is wrong, without crowding the io's own rows, at every width
VERDICT: green
WHY: This seat's model has no image input, so I verified the named screenshots by instrumented reads (tesseract OCR at 4x upscale + pixel-diff) of every `findings-*` file in `docs/reports/T-1303-evidence/` (23 shots: lint, v11, lint-edit × 1024/1440/1920 × full/panel/panel-end), plus a live re-run of the work's own CDP leg (`node tools/_t1303-io-findings-cdp.mjs` → exit 0, ok:true, errs:[], all temp writes under /tmp; tree untouched). Placement: OCR reading order shows each finding directly under the io row it names — `contact`→ERROR+message+`E-XML-IO-MATCH-MISSING` then its v1.1 summary and "edit attributes"; `account`→WARN+`W-XML-IO-MATCH-UNRESOLVED`; `opp`→two ERRORs (sf:, biz:)+`E-XML-IO-PREFIX-UNDECLARED` — with the inputs section clean (lint state), outputs clean (v11 state), and with an editor open the WARN stays under `account`, not under the editor; the DOM leg confirms finding-under-its-own-io-only, clean io shows none, renamed io shows nothing. Legibility: severity word, full wrapped message and full rule id OCR cleanly at every width, including 1920 (panel is a fixed 320px at all widths, so horizontal pressure is identical); producer's noted "rule id small and muted" is deliberate (label-grey token) and still machine-legible at all widths. No crowding: header+io-row band of `v11-step-1440-panel.png` is pixel-identical (diff 0.0) in `findings-v11-1440-panel.png`; CDP leg c shows a clean step's panel byte-identical before/after Check; geometry leg f shows every finding line inside the panel, no overflow, on top at 1024 and 1440. Caveats, none blocking: (a) the criterion's named comparison pair is not editor-matched (v11-step: editor closed; findings-v11: editor open from an earlier state — the summary collapse that follows is pre-existing T-1249/T-1301 behaviour, not Check-caused); (b) 1920 geometry rests on screenshot OCR completeness, not the CDP leg, which stops at 1440.
GUIDANCE: none needed; optionally add 1920 to the CDP geometry leg f and pair the no-Check counterpart with the same editor state in a future evidence run.
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
