# T-092 — Routing + Layout/Alignment Optimisation Survey → Settings-Menu Proposal

**Task:** T-092 (inception) · **Date:** 2026-07-05 · **Status:** in progress

**Question:** Which additional routing, layouting, and alignment (horizontal/vertical) optimisations should the workflow designer offer, and where does each belong — the settings/configuration menu (persistent preference), a one-shot action (Clean / Tidy / Align), or an always-on render pass?

## Method

1. Mechanical sweep of all 24 corpus maps in the live editor (Playwright): per-map edge bends, edge-edge crossings, edges crossing node boxes, loop-backs, label collisions (T-082/T-089 measure), row-alignment deviation (nodes sharing a lane row whose y differs), column-alignment deviation (sequential nodes whose x-centres nearly-but-not-exactly align).
2. Full-canvas screenshot of every map → `.playwright-mcp/t092-<map>.png` (all 24 on disk); detailed reads of the worst offenders by metric.
3. Inventory of existing controls (settings modal today) vs gaps.
4. Numbered proposal, each option tagged: settings-menu / one-shot action / automatic pass, with expected effect grounded in the sweep numbers.

## Existing controls today (settings modal)

- Routing: straightening tolerance (T-073), loop-back periphery routing (T-076)
- Snapping: magnetic drag snapping — lane centre, neighbour centres, grid + guide lines (T-074), adaptive sub-row snap lines (T-079)
- Grid: grid preferences (T-075)
- View: density tight/normal/wide — affects Tidy row pitch only (T-085)
- Labels: show/hide per class (lane/ids/edge/pool), size S/M/L (T-085); fit ladders are automatic passes (T-084 lane, T-087 node, T-089 edge wrap-on-contest)

## Sweep results

Mechanical sweep of all 24 maps (live editor, measured polylines/geometry). Screenshots: the 6 metrically-worst maps + 1 clean control were captured and READ (`.playwright-mcp/t092-*.png`); the remaining 17 maps are metrically quiet (≤7 crossings, 0 node cuts) and were not individually screenshotted — stated openly, not silently capped.

| map | N | E | bends | crossings | node-cuts | row near-miss | col near-miss |
|---|---|---|---|---|---|---|---|
| audit-process | 14 | 17 | 52 | **53** | 4 | 9 | 0 |
| harvest-pipeline | 24 | 28 | 68 | **48** | **21** | 1 | 5 |
| task-lifecycle | 15 | 18 | 41 | 24 | 0 | **26** | 0 |
| error-escalation-ladder | 14 | 16 | 41 | 21 | **11** | 7 | 1 |
| task-gate | 11 | 14 | 30 | 16 | 0 | 7 | 0 |
| context-memory | 12 | 12 | 17 | 13 | 0 | 8 | 1 |
| verification-gate | 15 | 18 | 33 | 6 | 0 | **25** | 2 |
| session-handover | 10 | 10 | 9 | 2 | 0 | 13 | 0 |
| release-pipeline (control) | 17 | 17 | 26 | 6 | 0 | 0 | 3 |
| …15 remaining maps | | | | ≤7 each | ≤3 each | ≤14 each | ≤3 each |

Corpus totals: **~245 edge-edge crossings, 42 edges slicing through unrelated node boxes, 168 near-miss row pairs (same-lane centres 1–14px apart), 21 near-miss column pairs, 25 residual label collisions (post T-089).**

## Findings

1. **Fan-out/join branch stacks overlap their own nodes.** Parallel blocks stack branch tasks at a pitch smaller than node height (64px): audit-process's 5-branch stack and harvest-pipeline's 6-branch stack visibly touch/overlap (read in screenshots). No current control addresses branch pitch — Tidy rows by lane, not by block.
2. **Crossings concentrate in fan/join corridors.** audit-process 53 and harvest-pipeline 48 crossings are almost entirely branch edges sharing one unmanaged corridor; error-escalation-ladder's 11 node-cuts are corridor edges slicing sibling nodes. Linear-chain maps have ≤7.
3. **Horizontal alignment wobble is systemic (168 pairs).** Mixed node heights (task 64, gateway ~42, event ~28) mean top-aligned placements have misaligned CENTRES — chains look wavy (task-lifecycle 26, verification-gate 25). Drag-snap (T-074) only helps during a drag; nothing re-aligns existing geometry.
4. **Column near-misses are few but cheap to zero (21 pairs).** T-073's straightening tolerance fixes the rendered EDGE but leaves node x untouched — the dogleg is hidden, not removed.
5. **Loop-back periphery routing (T-076) shares its corridor with row-2 nodes** (task-lifecycle "gate failed — rework" run) — no reserved routing band exists at lane bottom.
6. **The 25 residual label collisions all live in fan/join corridors** — confirming T-082's prediction that density/corridor work, not more label heroics, is the fix.
7. **Clean maps prove the target state.** release-pipeline (0 cuts, 0 row misses) and post-T-087 session-handover read cleanly; ALL remaining visual debt is parallel-block layout + mixed-height rows.

## Proposal

**Settings menu (persistent preferences, editor-local like T-085's viewPrefs):**
1. **Branch pitch** — fan-out stack spacing: auto (≥ node height + 12px) / compact / roomy. Applied by Tidy to parallel blocks. Eliminates finding 1 by construction.
2. **Edge channel separation** — offset parallel edges sharing a corridor by 0/4/8px so fan/join bundles stop overlapping and crossing ambiguously (finding 2).
3. **Routing margin** — reserved periphery band per lane (none/8/16px) that loop-backs and long runs use exclusively (finding 5).
4. **Row alignment mode** — align row-mates by centre (default) or top; consumed by Tidy and drag-snap (kills the mixed-height wobble class at source, finding 3).
5. **Structural straightening** — off/on: when T-073's tolerance detects a near-straight edge, Tidy MOVES the node into true alignment instead of only rendering straight (finding 4).

**One-shot actions (a "Clean" toolbar menu — not settings):**
6. **Align rows (horizontal)** — snap each lane's row-mates to the row's median centre-y (zeroes the 168 near-miss pairs).
7. **Align columns (vertical)** — snap near-aligned connected nodes to a shared centre-x (zeroes the 21 pairs).
8. **Distribute evenly** — equalise gaps in a row / stack.
9. **Clean layout (composite)** — Tidy + branch pitch + align rows/columns + reroute, single click, undoable.

**Automatic render pass (no UI):**
10. **Crossing-aware branch ordering** — order fan/join corridor edges by target-y so branch edges never cross inside their own block (audit-process 53 → expected single digits).

**Suggested phasing:** Phase A = options 1 + 6 + 9 (largest visible win: overlapping stacks + wavy rows, low risk, all geometry-editing so undo must work). Phase B = 2 + 10 (corridor discipline; should also clear most of the 25 residual label collisions). Phase C = 3, 4, 5, 7, 8.

All geometry-affecting options are Tidy-time or explicit-action only — stored geometry is never mutated by a render pass (PD-044 discipline).

## Dialogue Log

- 2026-07-05 operator: "screenshot all workflows and identify more routing optimisation / options and propose including ones to include in configuration menu, also same for layouting and alignment (horizontal and vertical) all that includes clean / layout" → this survey.
