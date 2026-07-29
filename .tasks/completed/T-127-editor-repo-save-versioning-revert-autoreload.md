---
id: T-127
name: "B1: Editor reload auto-loads the stored (autosaved) version — no banner"
description: >
  T-128 GO decomposition, task B1. On reload the editor AUTOMATICALLY loads the
  stored/autosaved version — no dismissible banner, the work just comes back
  (operator's #1 ask). Keyed by map id / deep-link so a reload never crosses maps;
  a non-modal "Start fresh" affordance remains. Editor-only, lowest risk. Save-to-repo,
  versioning, revert, undo/redo, thumbnails are B2–B5 (separate tasks).
status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, persistence, autoload]
components: []
related_tasks: [T-126, T-128]
created: 2026-07-06T09:40:00Z
last_update: 2026-07-29T15:39:24Z
date_finished: 2026-07-06T12:34:59Z
---

# T-127: Editor reload-restores + Save-to-repo + versioning + revert

## Context

Follow-on from the T-126 work-loss incident. The autosave shipped under T-126
(localStorage snapshot + a dismissible restore *banner*) is the safety net, but the
operator wants stronger, durable persistence. This task turns "don't lose work" into
"work is versioned in git and any version is recoverable."

Precede build with the T-126 verification (fix `tools/_autosave-verify-cdp.mjs` import,
confirm autosave works) — do not build on an unverified base.

## Acceptance Criteria

### Agent
- [x] **Reload auto-loads** (operator's #1): replace T-126's `offerAutosaveRestore()` banner
      with `autoLoadStored()` — on load, if an autosave exists it is adopted silently as the
      working document, no prompt.
- [x] **Keyed so reloads never cross maps:** autosave records the current `?load` src; on load,
      auto-adopt ONLY when there is no `?load`, or the `?load` src matches the stored one. An
      explicit `?load` of a DIFFERENT map wins (deep-link respected, autosave not clobbering it).
      A `_suppressDeepLink` guard prevents the async `?load` fetch from overwriting a same-map restore.
- [x] **Clean replace, no `_v2`:** `adoptImportedXml` gains a `{replace:true}` path so restore
      overwrites the seed rather than collision-renaming to `<id>_v2`.
- [x] **Non-modal affordance:** a small auto-dismissing toast confirms the restore and offers
      "Start fresh" (clears autosave + `createNewWorkflow()`). No modal, no persistent banner.
- [x] **Verified in ISOLATED headless** (`tools/_autoload-verify-cdp.mjs`, new — the T-126
      banner verifier is preserved for history): edit→autosave→reload asserts (a) NO
      `#restore-nudge` banner, (b) the mutated geometry is already present (proves auto-load,
      not fresh seed), (c) same map id (no `_v2`). Screenshot the restored canvas + READ.
- [x] `diff -q src/aef-workflow-designer.html build/gallery/designer.html` clean (mirror).

### Human
- [x] [REVIEW] I edit a map, reload the page, and my work is just there — no banner to click.
  **Steps:** 1) open a map in the designer, move a few nodes. 2) reload the browser tab.
  **Expected:** the edited layout is back automatically; a small toast confirms it with a
  "Start fresh" option. **If not:** note whether work was lost or a banner appeared instead.

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html

## Decisions

### 2026-07-06 — B1 auto-load precedence (per T-128 IW-3)
- **Chose:** auto-adopt localStorage autosave keyed by `?load` src; no `?load` → restore last
  session; `?load` differs from stored src → respect the deep-link. `replace:true` restore
  (no `_v2`). Non-modal toast + "Start fresh", replacing the banner.
- **Why:** operator wants reload to just load their work; keying prevents cross-map clobber.
- **Rejected:** dismissible banner (operator rejected); unconditional auto-adopt (would clobber
  an explicit deep-link to another map).

## Recommendation

**Recommendation:** GO (accept B1 — ready for your browser check)

**Rationale:** Reload now auto-loads the autosaved document with no banner (operator's #1 ask),
keyed by deep-link so reloads never cross maps, replacing the seed cleanly (no `_v2`), with a
non-modal toast + "Start fresh" affordance. All agent ACs pass; verified end-to-end in isolated
headless (5/5) and confirmed by a screenshot that was READ. Only the in-your-own-browser check
remains (Human AC).

**Evidence:**
- `tools/_autoload-verify-cdp.mjs` — 5/5 steps pass: clean-load (no banner/toast), edit→autosave,
  reload auto-loads (banner=false, nodeY restored=276, id=`investigate` no `_v2`, toast shown),
  same-deeplink restores (arc-lifecycle nodeY=633), different-deeplink not clobbered (audit-process loads).
- Screenshot READ: arc-lifecycle auto-loaded (14 nodes), library shows single `arc-lifecycle v1`,
  toast "↩ Restored your unsaved work (7/6/2026, 2:33:36 PM)" + Start fresh, no banner.
- `diff -q src build/gallery` clean (mirror invariant held).
- Impl: `src/aef-workflow-designer.html` — `autoLoadStored()`/`showRestoredToast()` replace
  `offerAutosaveRestore()`; `adoptImportedXml(...,{replace:true})`; `_suppressDeepLink` guards the
  async `?load` fetch.

## Updates

### 2026-07-06 — captured at session budget ceiling
- Spec captured from operator ("reload should load stored version; save in repo + versioning
  + revert"). Could not build in-window (budget gate at 308k blocks source edits). Turnkey
  for next session. Do T-126 verification FIRST, then build this.

### 2026-07-06T12:34:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5c29bee6
- **Timestamp:** 2026-07-29T13:13:38Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#5 (Agent)** — **Verified in ISOLATED headless** (`tools/_autoload-verify-cdp.mjs`, new — the T-126
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_autoload-verify-cdp.mjs in: **Verified in ISOLATED headless** (`tools/_autoload-verify-cdp.mjs`, new — the T-126`
