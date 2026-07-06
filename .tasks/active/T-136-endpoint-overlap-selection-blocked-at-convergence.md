---
id: T-136
name: "Overlapping arrow-ends: selected line unresponsive at convergence points"
description: >
  When 2+ edge endpoints share a connection point (fork/join), the selected line often
  can't be clicked/selected — likely the T-133 r11 endpoint halo shadowing sibling edges.
status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug, editor, regression-suspect]
components: []
related_tasks: [T-133]
created: 2026-07-06T16:00:00Z
last_update: 2026-07-06T16:02:32Z
date_finished: null
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
- [ ] Repro written & confirms cause: `tools/_endpoint-overlap-diag.mjs` shows the selected
      edge's endpoint halo is topmost over a sibling edge near a shared connection point, and a
      click on the sibling near the junction fails to select it (stays on the first edge).
- [ ] Fix so a click that lands on an endpoint halo but does NOT become a drag falls through to
      normal edge hit-testing (selects the edge under the pointer, incl. a sibling). Candidate
      approaches to weigh: (a) on endpoint mouseup with no drag, re-run edge hit-test at the point
      and select whatever edge is there; (b) moderate the halo radius (r11 → ~r8, still bigger
      than the pre-T-133 r6 the operator called "too tight"); (c) shrink the halo to visible-dot
      size except when hovering the endpoint. Prefer (a) — keeps the T-133 grab size AND fixes
      selection; (b) is the cheap fallback. DO NOT simply revert T-133 (operator wanted the
      bigger grab target).
- [ ] Verified headless: at the fork, with edge A selected, a click on edge B near the shared
      junction selects B; endpoint drag-to-reanchor still works when you actually drag. Screenshot
      READ.
- [ ] `diff -q src/aef-workflow-designer.html build/gallery/designer.html` clean (mirror).

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

## Decisions

<!-- record if an approach among (a)/(b)/(c) is chosen and why -->
