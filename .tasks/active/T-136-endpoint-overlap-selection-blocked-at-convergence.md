---
id: T-136
name: "Overlapping arrow-ends: selected line unresponsive at convergence points"
description: >
  When 2+ edge endpoints share a connection point (fork/join), the selected line often
  can't be clicked/selected — likely the T-133 r11 endpoint halo shadowing sibling edges.
status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [bug, editor, regression-suspect]
components: []
related_tasks: [T-133]
created: 2026-07-06T16:00:00Z
last_update: 2026-07-06T16:19:53Z
date_finished: 2026-07-06T16:19:11Z
---

# T-136: Overlapping arrow-ends — selected line unresponsive at convergence points

## Context

Operator field report: "when there are two or more arrow ends on the same connection point
the selected line often does not respond." I.e. at a fork/join where multiple edge endpoints
coincide, you can't reliably click-select one of the converging lines.

**Prime suspect — T-133 regression.** In T-133 I enlarged the edge endpoint grab target from a
r6 circle to a **transparent r11 hit halo** (`.edge-handle-endpoint-hit`) that carries the
endpoint-drag mousedown. Those halos render for the SELECTED edge. Where a sibling edge shares
that connection point (e.g. gateway `n_route` → `e_10`/`e_11` in arc-lifecycle both start at the
gateway port), the selected edge's r11 halo sits on top of the sibling edge's line near the
junction. Clicking there hits the halo (→ tries to drag the endpoint) instead of selecting the
sibling edge → "does not respond." The interactive dead-zone grew from r6 to r11, so T-133 at
least aggravated a pre-existing overlap.

## Investigation so far (this session)

- Reproduced the topology: arc-lifecycle gateway `n_route` forks to `e_10`, `e_11` (shared
  source point). No node has 2+ incoming here, but the fork gives 2 coincident source endpoints.
- Confirmed structurally: endpoint halo is r11, appended to the SELECTED edge's `<g>`, with a
  mousedown → `onEndpointMouseDown` (drag). Visible dot is r6 `pointer-events:none`.
- Could NOT finish the click-through repro: the LIVE gallery canvas renders 2900px wide (map
  panned off-viewport) so screen-coordinate clicks were unreliable; and the budget gate hit
  critical before the headless repro (`tools/_endpoint-overlap-diag.mjs`, drafted but NOT yet
  written — blocked) could run. **Next session: write that diagnostic first** (fixed 1200x820
  headless window where the map fits, select `e_10`, `elementsFromPoint` at the shared source and
  ~12% along `e_11` from its source, and simulate a real click on `e_11` near the junction →
  assert selection switches to `e_11`).

## Acceptance Criteria

### Agent
- [x] Repro written & confirms cause: `tools/_endpoint-overlap-verify-cdp.mjs` reproduces the
      operator's condition (two arrow ends on one connection point — a fork pinned to a shared
      source port), confirms the selected edge's r11 endpoint halo is TOPMOST over the sibling's
      line at the shared point (`halo-is-topmost-at-Q: halo`), and asserts the fix falls through.
- [x] Fix so a click that lands on an endpoint halo but does NOT become a drag falls through to
      normal edge hit-testing. **Chose (a)** — on endpoint mouseup with no snap and < 4px of
      movement, `edgeHitTestAt(clientX, clientY, selectedEdgeId)` re-runs edge hit-testing at the
      pointer (via `document.elementsFromPoint`, skipping the halos) and selects the underlying
      edge, preferring a sibling. Keeps the T-133 r11 grab target; T-133 NOT reverted.
- [x] Verified headless (6/6): at the fork, with edge A (e_10) selected and its halo topmost, a
      click on sibling B's line (e_11) near the shared junction selects B; a real endpoint drag
      (>threshold, released in open space) is NOT hijacked into sibling-select. Screenshot READ
      (`/tmp/endpoint-overlap-full.png`) — gateway fork renders cleanly, no visual regression.
- [x] `diff -q src/aef-workflow-designer.html build/gallery/designer.html` clean (mirror).

### Human
- [ ] [REVIEW] At a fork/join, clicking between the converging lines now reliably selects the one
      you click. **Steps:** open a map with a decision gateway (2 outgoing edges), click each
      outgoing line near the gateway. **Expected:** each click selects the line under the cursor.
      **If not:** note which line wouldn't select and where you clicked.

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** At convergence points (coincident edge endpoints), the selected line often can't be
re-selected / a sibling line can't be selected.
**Root cause (suspected):** T-133 enlarged the endpoint grab halo to r11; it shadows sibling
edges near shared connection points and captures clicks as endpoint-drags.
**Why structurally allowed:** T-133 verified endpoint hover/grab in isolation but not the
interaction with overlapping edges at fork/join points (no convergence case in the verifier).
**Prevention:** add a convergence case to endpoint verification; fix click-fallthrough so a
non-drag click on a handle selects the underlying edge.

## Recommendation

**Recommendation:** GO (accept the fix; one Human REVIEW AC remains for live confirmation)

**Rationale:** The fix resolves the reported bug at its root — a non-drag click on an endpoint
halo now falls through to select the underlying/sibling line — while keeping the T-133 r11 grab
target the operator explicitly asked for (T-133 not reverted). The headless verifier reproduces
the operator's exact condition (two arrow ends on one connection point) with the halo forced
topmost, so it is a genuine regression guard, not a trivial pass. Real endpoint drags are proven
unaffected.

**Evidence:**
- `tools/_endpoint-overlap-verify-cdp.mjs` — 6/6 green: `halo-is-topmost-at-Q: halo` (bug
  condition present), `hittest-prefers-sibling: e_11`, `click-selects-sibling: e_10→e_11` (fix
  fires), `drag-not-hijacked-to-sibling: stays e_10` (regression guard).
- Commit d5eb10c (3 edits in `src/aef-workflow-designer.html`); mirror `diff -q` clean (P-011 pass).
- Screenshot `/tmp/endpoint-overlap-full.png` READ — gateway fork renders cleanly, no regression.

**Human review note:** confirm in a live map that clicking between two converging lines at a
gateway selects the line under the cursor. **Requires one hard refresh (Ctrl+Shift+R)** to pick up
the new build. If it still misses, note which line and where you clicked — fallback is approach (b)
(moderate the halo to ~r8), but (a) should fully resolve it.

## Decisions

**Chose approach (a) — click-fallthrough on non-drag endpoint mouseup.** Rationale: it keeps the
T-133 r11 grab target the operator asked for (no radius shrink, no revert) AND fixes selection at
convergence points. The other candidates traded away grab size: (b) shrinking r11→r8 would reduce
but not eliminate the shadowing (any halo over a sibling line still eats the click), and (c)
hover-conditional sizing is fiddly and still leaves a dead-zone while hovering.

Implementation (3 edits in `src/aef-workflow-designer.html`):
1. `onEndpointMouseDown` records `downX/downY` (client px) so mouseup can tell a click from a drag.
2. New `edgeHitTestAt(clientX, clientY, preferNotId)` — walks `document.elementsFromPoint`, ignores
   `.edge-handle-endpoint-hit` halos, returns the topmost `.edge-hit` edge id, preferring one that
   is not `preferNotId` (so a sibling under the pointer wins over the already-selected edge).
3. `mouseup` (endpoint branch): when there was no snap and movement < 4px, run `edgeHitTestAt` at the
   release point and, if a different edge is under the pointer, select it — before `renderAll()`
   tears down the DOM.

Why the native click didn't already do this: the halo's `mousedown` calls `stopPropagation()` +
`preventDefault()` and mouseup's `renderAll()` rebuilds the edge DOM, so the browser click never
reaches the sibling's `.edge-hit`; and even if it did, it would re-select the SAME (halo-owning)
edge, not the sibling.

## Updates

<!-- Section header backfilled 2026-07-28 (T-272): the status-update entry below was stranded
     at the tail of ## Decisions; commit trail added from git history (audit warn: missing
     Updates section). -->

### 2026-07-06T16:19:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-07-28 — commit-trail backfill [T-272]
- 84403d9 capture overlapping-endpoint selection bug + diagnosis (T-133 halo suspect)
- d5eb10c fix overlapping-endpoint selection at convergence points (click-fallthrough, keeps T-133 grab size)
- 3daf623 / b88a7a7 Recommendation block added, then reformatted to T-679 GO format
- fb3f079 finalize — agent ACs complete, verified 6/6, handed to human for live REVIEW

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2a078997
- **Timestamp:** 2026-07-27T21:20:16Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — Repro written & confirms cause: `tools/_endpoint-overlap-verify-cdp.mjs` reproduces the
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_endpoint-overlap-verify-cdp.mjs in: Repro written & confirms cause: `tools/_endpoint-overlap-verify-cdp.mjs` reproduces the`
