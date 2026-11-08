# Workflow Designer 0.40.0 — release notes

**Since:** `designer-v0.39.0`. The warnings shown when a map opens no longer take a large share of the canvas
(T-1384).

## Changes

- **The advisory banners are one card (T-1384).** Opening an imported map can show three advisories above the canvas:
  - the import notice;
  - "This map could use Clean layout";
  - the authority summary.

  In 0.39.0 they were three separate boxes stacked one under another. At 1024×768 with both side panels open they took
  270px of a 685px canvas (39%). Now:
  - **One card.** The three rows share one width and are joined into one card. Each row's controls (✕, "Clean
    layout") sit at its right edge.
  - **Narrow canvas.** When the canvas is under 700px wide, a notice with more than one part shows its first part
    and "▸ N more". One click shows every part and the control reads "▾ less"; another click folds it again. The
    import notice opens on its first line ("1 data store no task links to (Archive) … but not drawn"). The authority
    summary opens on "⚠ This map declares no authority".
  - **Wider canvas.** Every part is shown and there is no control.
  - **No text changed.** Every "NOT kept" and "not drawn" line reads exactly as before. Nothing is removed, only
    folded on a narrow canvas.
  - **Diagram never covered.** As before (T-1078), no advisory covers the diagram: the canvas is padded below the
    card.

  Canvas height taken by the card, on the T-1381 data-stores map:

  | Width | 0.39.0 | 0.40.0 |
  |---|---|---|
  | 1024 | 270px (39%) | 135px (20%) |
  | 1440 | 200px | 176px |
  | 1920 | 182px | 158px |

  Guard: leg 226, `tools/_t1384-advisory-dock-cdp.mjs`. It is red on 0.39.0, and its self-test catches both
  deliberately broken copies (no narrow mode, no toggle).

## What changes in stored maps

Nothing. The change is in what is shown, not in what is saved: every byte-identity golden is unchanged. The validator
is unchanged since 0.38.0. The kit's sources (`docs/authoring-kit/`, `tools/build-authoring-kit.py`) are unchanged
since 0.39.0.

## Also in this repository

- The repository is licensed Apache-2.0: `LICENSE` and `NOTICE` were added at the root (T-1383). The designer
  artifact's bytes are not changed by it.

## Not kept yet

Unchanged from 0.39.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator, which waits for AEF's mapping vocabulary (T-4991).

## For AEF

**Nothing changes in what you store.** Node ids, fields and saved bytes are the same as 0.39.0 for every map.

**The validator is unchanged:** `validate-workflow.py` is byte-identical to 0.38.0's (sha256 88d6a649…, 137965
bytes). The kit carries the new version, so its `SHA256SUMS` moves. The new anchors come with this release's message.

The endpoints as stated at 0.38.0 (your T-5015 check of the table is still open). Please correct anything that has
changed:

| Endpoint | Feature (task) | In AEF (as of 0.38.0) |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
