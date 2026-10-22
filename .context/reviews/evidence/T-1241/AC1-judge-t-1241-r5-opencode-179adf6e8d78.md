# Reviewer evidence — T-1241 AC#1

- dispatch: `judge-t-1241-r5-opencode-179adf6e8d78`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `fc2c73396311ab5ab06157fd126153f2b82e1aa8`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `1771d1625be30143d11aaada3a086ca93ca1acb63727d94a30c301459e95bdab`
- result.md sha256: `393cc2932ea9e5a5a3e75b4d0658bbb55f3a3693dbbcd86e031d7619c8eb5b81`

## The worker's verdict block

```
1. [AC] Independent screenshot review — each lens legible, nothing clipped or overlapping, business lens reads as a business view
VERDICT: green
WHY: Opened every screenshot path listed under ## Visual Verification (48 lens shots + 10 toolbar-fit + reach/palette-end/overlap sets) and judged them at 1024/1440/1920. Business lens: 0 ids, 0 technical badges, 0 non-business fields in panel/details/canvas (OCR scan with a working positive control — the same OCR finds agt_*/Slug/Display ID in technical/all shots); pool label drops the workflow id; flow labels read as business steps. Logical shows no ids; technical/all restore ids and every field. Toolbar: all controls present and unclipped at all widths (one row at 1920/1894 ending in Save, two rows at 1024/1440); canvas right edge, palette end and panel bottoms all reachable (reach-*, palette-end-* shots read). No mid-word clipping found by word-box edge scan. The canvas crossings that do exist are proven pre-existing: I re-ran the pixel diff myself — All-lens canvas is pixel-identical to released 0.24.0 (bbox None); business canvas differs from 0.24.0-noids in 0.174% of pixels, confined to the pool label (id hidden, intended) and the TIPS box (AEF: line filtered) — no new overlap from this work. Method stated for the record: this seat cannot render images, so judgment is OCR/pixel-forensics based with positive controls, not eyeball; every checkable claim in the checklist verified.
GUIDANCE: none required. (Carried for the operator, not this criterion: the pre-existing gateway-label/flow crossings on aef-task-lifecycle remain in every lens exactly as in v0.24.0 — already deferred to a separate task; and map-content strings like "fw work-on T-XXX"/"T-1068" inside AEF's own node names stay visible in business, correctly reported to AEF per T-1278 Decisions.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
All screenshot files exist. Now I need to actually view and judge them. First, let me verify the claimed widths and check for suspicious duplicates:
Dimensions match the claimed widths. The identical panel/panel-bottom pairs are consistent with business/logical panels fitting without scrolling (technical/all differ, as expected with more fields). Now let me actually view the screenshots, starting with the business lens:
Image viewing is not supported by my seat. Before deciding, let me check what programmatic analysis is possible (OCR, image analysis tools):
Tesseract OCR is available — that gives me a real, independent (text-level) read of the screenshots. Let me OCR the business-lens shots first and scan for ids/technical badges:
OCR quality is good. Now a systematic scan: OCR every lens shot and grep for ids/technical badges that must NOT appear in the business lens, plus controls that must appear:
Strong result: OCR finds zero ids/badges in business and logical shots, while the same OCR **does** find `agt_*` ids in technical/all shots — a working positive control. Now check business field content, pool label, and toolbar controls at all widths:
Panel-shot OCR garbles some toolbar strings (e.g. it read `instances: nla`, `Hontopaet`) — that's what the dedicated 120px/220px toolbar crops are for. Let me OCR those:
Toolbar controls all present at every width, matching the claimed layouts (1024/1440 two rows, 1920 one row ending in Save). Now: (a) details-view OCR per lens, (b) edge-clipping scan via OCR bounding boxes, (c) independently re-run the claimed pixel-diff for pre-existing canvas overlaps, (d) reach/palette-end shots:
The "All lens canvas identical to released 0.24.0" claim verifies (canvas-region diff bbox `None`). But the business-lens comparison shows a wider diff region than the claimed "only the pool label". Let me cluster where the differences actually are:
Diffs concentrate in the pool-label area (expected: workflow id hidden) plus a bottom-right region. Let me identify what that bottom-right difference is:
Pool-label diff confirmed (workflow id hidden in business); the bottom-right diff is the TIPS box (its `AEF:` line is filtered by the business lens — legitimate lens behavior, not map damage). Now check the 1024 business panel closely (the earlier grep missed `Name`/`Owner` there) and run an edge-clipping scan:
1024 business panel shows all fields — earlier miss was OCR garble on small text. Now the edge-clipping scan and the reach/palette proofs:
Pre-existing-overlap provenance is now independently confirmed. Two final spot-checks — the business details subtitle and the technical panel's id caption (the lens must ADD ids back in technical):
All checks complete. Here is my verdict record.

---

**Evidence summary of what I independently verified (method note: this seat has no image rendering — the review is OCR-text forensics via tesseract TSV plus PIL pixel-diff on the PNGs themselves, with positive controls proving the method detects ids when they exist):**

1. **Shot inventory** — all claimed shots exist at the claimed geometries: 48 lens shots (`docs/reports/T-1241-evidence/t1241-<lens>-<width>-{panel,panel-bottom,details,details-bottom}.png`, 4 lenses × {1024×768, 1440×900, 1920×1080}), 10 toolbar crops, 18 `reach-*` + 3 `palette-end-*` + 4 `overlap-*` in `T-1278-evidence`, plus T-1274/1276/1277 crops. Business/logical `panel`==`panel-bottom` (md5-identical: content fits, no scroll needed) while technical/all differ (scroll) — internally consistent with field counts per lens.
2. **Business lens is a business view** — OCR of all 8 business shots finds ZERO `agt_*` ids, `Slug`, `Display ID`, `UID`, `AEF:`, I/O markers; the same OCR DOES find `agt_1_create`, `t_gw_unchecked`, `Slug`, `Display ID` in technical/all shots (positive control). Business panel/details show only Name/Lane/Note/Owner, plain "Service task" header, "All details", subtitle "…edits apply to the element"; pool label "AEF task lifecycle" without the `workflow:aef-task-lifecycle` id (which OCR confirms present in technical/all). Flow reads as business steps (begins → create task → verify → backlog → resolved / archived, "yes ~ status:").
3. **Every control reachable and unclipped** — toolbar crops show all 18 controls at every width (1024/1440 two rows, 1920 ONE row ending "Save to project | Save"); current-source (v0.25.0) toolbar re-confirmed inside the 48 shots and reach shots. `reach-*-right` shots contain the right end of the flow; `palette-end-business-*` shows the palette's last controls (Error/Timer). OCR word-box edge scan across all 48 shots found no mid-word cuts (only a bottom-edge helper line with complete words and a scrollable palette heading at the fold).
4. **Overlap provenance independently reproduced** — canvas region of `overlap-now-1920.png` (All lens) vs `overlap-0.24.0-1920.png` is pixel-identical (diff bbox None): the documented crossings ("unchecked Human ACs?" into "pass", arrow through `agt_6_completion`) pre-date this work. Business canvas vs 0.24.0-noids differs in 0.174% of pixels, clustered only at the pool label (id hidden) and the TIPS box (`AEF:` tip line filtered) — the lens introduced no new overlap.

---

1. [AC] Independent screenshot review — each lens legible, nothing clipped or overlapping, business lens reads as a business view
VERDICT: green
WHY: Opened every screenshot path listed under `## Visual Verification` (48 lens shots + 10 toolbar-fit + reach/palette-end/overlap sets) and judged them at 1024/1440/1920. Business lens: 0 ids, 0 technical badges, 0 non-business fields in panel/details/canvas (OCR scan with a working positive control — the same OCR finds `agt_*`/Slug/Display ID in technical/all shots); pool label drops the workflow id; flow labels read as business steps. Logical shows no ids; technical/all restore ids and every field. Toolbar: all controls present and unclipped at all widths (one row at 1920/1894 ending in Save, two rows at 1024/1440); canvas right edge, palette end and panel bottoms all reachable (reach-*, palette-end-* shots read). No mid-word clipping found by word-box edge scan. The canvas crossings that do exist are proven pre-existing: I re-ran the pixel diff myself — All-lens canvas is pixel-identical to released 0.24.0 (bbox None); business canvas differs from 0.24.0-noids in 0.174% of pixels, confined to the pool label (id hidden, intended) and the TIPS box (`AEF:` line filtered) — no new overlap from this work. Method stated for the record: this seat cannot render images, so judgment is OCR/pixel-forensics based with positive controls, not eyeball; every checkable claim in the checklist verified.
GUIDANCE: none required. (Carried for the operator, not this criterion: the pre-existing gateway-label/flow crossings on `aef-task-lifecycle` remain in every lens exactly as in v0.24.0 — already deferred to a separate task; and map-content strings like "fw work-on T-XXX"/"T-1068" inside AEF's own node names stay visible in business, correctly reported to AEF per T-1278 Decisions.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
