---
id: T-163
name: "Target-workflow field uses the Open-project card browser to pick a map"
description: >
  The handoff-node "Target workflow" field currently uses a dropdown + free-text control.
  Operator wants it to provide the SAME interface as Open-project — i.e. pick the
  target
  from the visual card browser (thumbnails, filter) instead of a plain dropdown.
status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: [T-160, T-153, T-144]
created: 2026-07-10T00:00:00Z
last_update: '2026-08-16T12:33:40Z'
date_finished: 2026-07-09T22:54:06Z
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:40Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 1
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=1 (body:fix-without-learning); D2=0 (no-signal); D3=0 
      (no-signal); D4=3 (body:portability-abstraction); F-RECALL=0 (no-signal); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-163: Target-workflow field uses the Open-project card browser to pick a map

## Context

Operator (2026-07-09): "target workflow should provide same interface as open project,
makes sense?" — yes. Today the handoff-node **Target workflow** field (FIELD_META
`targetWorkflow`, `special: 'workflowPicker'`, rendered in `renderProperties` ~line 4692)
is a `<select>` of loaded library ids **plus** a free-text override. Two problems:
1. It only lists in-session library maps, not the full project corpus.
2. The dropdown and free-text can show out of sync (noted in T-160) — confusing.

**Goal:** replace the dual control with a **"Choose from project…" button** that opens the
**same card browser as Open-project** (`openProjectModal` — thumbnails from T-153, filter,
hover-zoom, and the T-162 label fix), but in a **pick mode** that RETURNS the chosen map id
into `aef.targetWorkflow` instead of navigating to it. Show the current target next to the
button (with the T-160 "↗ Open target workflow" jump button kept). This unifies "browse the
corpus" everywhere and fixes the desync.

## Design notes (for the next session)

- **Refactor `openProjectModal` to accept an optional options arg**, e.g.
  `openProjectModal({ pick: (mapId) => {…} })`. Default (no arg) = today's behaviour
  (card click → `openProjectMap`). In pick mode, a card click calls `pick(m.id)` and
  closes the modal instead of opening the map. Keep the shared card-building code (tiles,
  filter, hover-zoom) so both modes look identical.
  - Header title could read "Choose target workflow" in pick mode vs "Open project map".
- **In the `workflowPicker` field branch** (`renderProperties`, ~4692): replace the
  `<select>` + free-text pair with:
  - a read-only display of the current `aef.targetWorkflow` (or "— none —"),
  - a **"Choose from project…"** button → `openProjectModal({ pick: id => { n.aef.targetWorkflow = id; renderProperties(); } })`,
  - keep the **"↗ Open target workflow"** jump button (T-160),
  - optionally keep a small free-text override for ids not in the corpus (a map may be
    referenced before it is saved) — decide during build; the operator's ask is "same
    interface as open project", so lead with the browser.
- **Corpus vs loaded:** the browser lists the full corpus + saved maps via `/api/list`
  (superset of the old dropdown), so this also fixes problem (1).
- Watch the pick-mode modal's `closeProjectModal`/Esc/backdrop paths — they must resolve
  the pick cleanly (treat close-without-pick as "no change", like Cancel).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `openProjectModal` accepts a pick mode (options arg) that, on card click, returns the map id to a callback and closes — without navigating; default no-arg behaviour is unchanged (still opens the map). *(verified: pick-mode title "Choose target workflow"; default title "Open project map")*
- [x] The handoff-node Target-workflow field offers a "Choose from project…" button that opens the card browser in pick mode; choosing a card sets `aef.targetWorkflow` to that id and the field reflects it. The T-160 "↗ Open target workflow" jump button is retained. *(verified: picked `arc-lifecycle`, aef.targetWorkflow set, readout + jump-enabled reflect it)*
- [x] The picker lists the full corpus + saved maps (via `/api/list`), not only in-session library entries; the old dropdown/free-text desync (T-160 note) is gone. *(verified: 25 cards — the full corpus)*
- [x] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`. *(MIRROR-OK)*
- [x] Playwright: select a handoff node → Choose from project… → the card browser opens; clicking a card sets the target (verified via `aef.targetWorkflow`) and closes the modal; the jump button then navigates there; 0 console errors; element screenshot READ. *(.playwright-mcp/t163-pick-modal.png — read; 0 console errors)*

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

<!-- Not a bug-class task. -->

## Updates

### 2026-07-10 — captured
- Captured from operator request during the T-153/T-160/T-161/T-162 browsing-polish session.
  Deferred to next session (this one hit budget-critical). Full design notes above so the
  next session can build immediately.

### 2026-07-09T22:50:42Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-09T22:54:06Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
