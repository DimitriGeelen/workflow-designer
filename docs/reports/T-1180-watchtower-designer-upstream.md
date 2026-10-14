# T-1180: Watchtower designer pages, three upstream fixes from 832 (T-1171, T-1172, T-1175)

For: AEF (999-Agentic-Engineering-Framework). From: 832-Workflow-designer, 2026-10-14.
Patch: `docs/reports/T-1180-watchtower-designer.patch` (3 files, paths relative to your tree: `web/...`).

All three were asked for by 832's operator on 2026-10-14 and are live in 832's Watchtower. They touch only the
designer pages: the /designer landing grid and a new /designer/open route. /designer/app and the T-2596/T-2599
deep-link nonce flow are unchanged.

## 1. Open a map inline, inside Watchtower (T-1172, 832 commit f9a1fc70)

**Problem.** The landing cards opened `/designer/app?load=…`, the bare designer bundle, as the whole tab. Watchtower's
navigation disappeared, and the only way back was the browser's Back button.

**Change.**
- `web/blueprints/designer.py`: new route `/designer/open?load=<same value>`. It renders Watchtower's base layout
  around the designer, framed from `/designer/app` with the **same** `load` value, so deep-links and the nonce flow
  are untouched. Without `?load` it redirects to `/designer`.
- The cards' `open_url` points at `/designer/open` instead of `/designer/app`.
- `web/templates/designer_open.html` (new): a bar (back to the maps, title, version, "Open alone" =
  /designer/app, fullscreen toggle) and the frame filling the viewport. The fullscreen toggle follows
  `fabric_explorer.html`: `requestFullscreen` on the stage, and the button follows `fullscreenchange`. Inside
  fullscreen the exit button sits at the bottom right, because top right covered the designer's own toolbar.

**Guard in 832:** `tools/_t1172-designer-open-test.py`.

## 2. The inline page uses the full window width (T-1175, 832 commit 680d8de5)

**Problem.** Watchtower's centred content column (`main#content` max-width) left wide empty margins around the
designer frame.

**Change.** `designer_open.html` lifts the cap for this page only, with
`main#content:has(#dsg-stage) { max-width: none; … }`. It is a single-level `:has()`, the same form `base.html`
already uses. Other pages keep the column.

**Guard in 832:** leg 6 of `_t1172-designer-open-test.py` asserts the rule appears on the inline page and on no other page.

## 3. Thumbnail fly-out on the landing cards (T-1171, 832 commit a55cbcb3)

**Problem.** The card thumbnails are too small to recognise a map by.

**Change.** In `web/templates/designer_landing.html`, hovering a thumbnail shows it about twice the size as a
fly-out, after a short delay. The fly-out is kept inside the viewport and has an Open button; it shrinks away when
the pointer leaves. Open, the fly-out image and the tile all click the card's own editor link. That link stays the
card's **only** `?load` link (T-2596).

**Guard in 832:** `tools/_t1171-landing-flyout-test.py`. `_t1048` now counts tiles, not images.

## Applying it

- `git apply --check` passes on 832's vendored copies of the three files as they were before these commits.
- It was **not** checked against your current tree: 832's project boundary does not let it read yours. If a hunk
  does not apply, the three changes are independent: route + `open_url`, the `:has` rule, and the fly-out block.
- 832 records this report as `delivered: reported` on the three entries in `.vendor-divergence.yaml`.
