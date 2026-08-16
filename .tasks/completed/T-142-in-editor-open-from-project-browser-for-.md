---
id: T-142
name: "In-editor Open-from-project browser for workflow files"
description: >
  Inception: In-editor Open-from-project browser for workflow files

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-07T18:28:17Z
last_update: '2026-08-16T13:57:17Z'
date_finished: 2026-07-08T06:07:02Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:39Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:17Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-142: In-editor Open-from-project browser for workflow files

## Problem Statement

Opening a different project map from the editor is weak: the operator must leave the editor
for the gallery index page and full-reload; the in-editor "Switch workflow" picker only
holds session scratch (seed-only at Init); and maps saved via "Save to project" are not
discoverable at all. For the operator authoring/curating the corpus, now — because the
editor is otherwise usable but this round-trip is the main daily friction.
Full evidence + code references: `docs/reports/T-142-in-editor-open-from-project-browser.md`.

## Assumptions

Registered via `fw assumption add` (see `## Updates`). Summary:
- Operators want to open another project map without leaving the editor.
- "Open" can swap maps in-place (no full reload) by reusing the `?load` fetch →
  `adoptImportedXml` path.
- A read-only `/api/list` is cheap to build synchronously for 24–50 maps.

## Open Questions

- **IW-1: What is the right shape of a read-only `/api/list` endpoint (fields, and one
  merged list vs corpus/saved split)?**
  confidence: 3
  disposition: answered
  rationale: Spike 1 (scratchpad/spike1_api_list.py) — merged list, per-map {id,title,
  sources[],latest,openTarget}; 24 maps in 6065 bytes / 4.2 ms, stdlib only.
- **IW-2: Can "Open" swap a map in-place (no full-page reload) by reusing the existing
  `?load` → `adoptImportedXml` path (src:7002, src:6927)?**
  confidence: 3
  disposition: answered
  rationale: Spike 2 (live browser) — adoptImportedXml swapped investigate→audit-process,
  URL unchanged, 14 nodes; no reload.
- **IW-3: Does the whole feature hide cleanly on the static gallery (no `/api/*`), like
  Save/Versions already do via detectSaveApi (src:6747)?**
  confidence: 3
  disposition: answered
  rationale: Spike 3 — detectSaveApi already gates Save/Versions (ship display:none, revealed
  on /api/health); a new Open button reuses it verbatim.
- **IW-4: Does the build decompose into ≤2–3 bounded build tasks, keeping this an
  inception (not a creeping subsystem)?**
  confidence: 3
  disposition: answered
  rationale: Split confirmed — (1) /api/list endpoint, (2) in-editor Open modal reusing
  openVersionsModal + adoptImportedXml, (3) optional older-version affordance. 2–3 tasks.
- **IW-5: When a map has saved versions in `.editor-versions/<id>/`, should "Open" default
  to loading the LATEST saved version (not the stale `rendered/` baseline), surface the
  latest version label in the list, and offer older versions via the existing Versions
  modal?**
  confidence: 3
  disposition: answered
  rationale: YES. Spike 1 found 11/24 maps carry saved versions (v1–v4) that today's ?load
  ignores; Spike 2 confirmed /api/version?id=&v= loads the latest in-place (HTTP 200). Default
  to openTarget (latest saved, else rendered), older versions via the existing Versions modal.

## Exploration Plan

Three time-boxed spikes (detail in the research artifact §4):
1. **Endpoint shape + latest-version resolution** (`/api/list`) — read-only prototype; per
   map return `id`, title/description, source (`rendered`/`saved`), and **latest version +
   timestamp** (from `.editor-versions/<id>/index.json`), so the list knows what "open
   latest" means. JSON schema + sample payload. ~45m
2. **Modal UX + open-latest** — "Open…" modal on the Versions-modal pattern; confirm in-place
   open reusing `?load`/`adoptImportedXml`; **default to the latest saved version** (fall back
   to `rendered/` baseline when none), with an older-version affordance handing off to the
   existing Versions modal. Interaction sketch. ~60m
3. **Saved-work visibility + static fallback** — enumerate `.editor-versions/*`; confirm the
   feature hides on `python -m http.server`. ~30m
Each spike updates the research artifact incrementally (C-001); commit after each.

## Technical Constraints

- Single-file editor mirror invariant (`src` ≡ `build/gallery/designer.html`, sync via `cp`).
- Portability: new endpoint must degrade gracefully on the static gallery (Directive 4);
  no non-stdlib deps in `gallery-serve.py`.
- Read-only safety: no writes; resolve ids via the existing `_valid_id` guard; no path
  traversal outside the repo. Must not disturb the T-138 corpus existing/promotion gate.

## Scope Fence

**IN:** exploring a read-only `/api/list` endpoint shape; an in-editor "Open from project"
modal; surfacing `.editor-versions/*` saved maps; **defaulting "Open" to each map's latest
saved version** (with older versions reachable via the existing Versions modal);
static-gallery fallback.
**OUT:** any write/delete/rename of project maps from the browser; auth/multi-user;
renaming or removing the existing "Switch workflow" picker or "Load…" button; changing the
gallery index page's role (that is the Option-B fallback, considered only on NO-GO).

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- `/api/list` has a clean, stdlib-only read-only shape that includes latest-version-per-map (IW-1, IW-5)
- The modal opens a map in-place with no full reload, reusing `?load`/`adoptImportedXml` (IW-2)
- "Open" defaults to the latest saved version (baseline fallback when none), older versions
  reachable via the existing Versions modal (IW-5)
- The feature hides cleanly on the static gallery (IW-3)
- The build decomposes into ≤2–3 bounded build tasks (IW-4)

**NO-GO / narrow to Option B+D if:**
- The endpoint or modal proves disproportionate to the friction it removes
- In-place open cannot reuse existing paths safely (would need a full-page reload anyway)
- Fallback: enhance the gallery index page (thumbnails + client-side search) + surface saved
  work — no new editor modal, self-contained in serve-gallery.sh/index

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO (filed DEFER; revised to GO after all three spikes resolved every open question)

**Rationale:**

All five open questions are answered with evidence and every GO criterion is met. A read-only
`/api/list` has a clean stdlib-only shape (24 maps → 6 KB in 4.2 ms); "Open" swaps maps
in-place with no page reload by reusing `adoptImportedXml`; the version-aware default is
proven against real data (`/api/version?id=&v=` loads a map's latest saved version in-place,
HTTP 200); the feature hides cleanly on the static gallery via the existing `detectSaveApi`
gate; and the build decomposes into 2–3 bounded tasks with no new subsystem and the mirror +
T-138 invariants untouched (read path only). The concrete driver: 11 of 24 corpus maps already
carry saved versions (v1–v4) that today's `?load` silently ignores in favour of the stale
baseline — the browser both removes the gallery round-trip AND stops opening the wrong bytes.
Decision remains the human's (owner: human) via `fw task review T-142`.

**Evidence:**
- Spike 1: `scratchpad/spike1_api_list.py` → 24 maps, 6065-byte payload, 4.2 ms, stdlib only; shape `{id,title,sources[],latest,openTarget}`
- Spike 1: 11/24 maps carry saved versions (arc-lifecycle v4 … tier0-escalation v2) invisible to today's open path
- Spike 2 (live browser): `adoptImportedXml` swapped map in-place, URL unchanged, no reload; `/api/version?id=arc-lifecycle&v=4` → HTTP 200, loaded latest in-place
- Spike 3: `detectSaveApi` (src:6747) already gates Save/Versions on `/api/health` → new Open button reuses it; static gallery keeps the index-page fallback
- Proposed build split: (1) `/api/list` endpoint, (2) in-editor Open modal, (3) optional older-version affordance

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

**Decision**: GO

**Rationale**: All five open questions are answered with evidence and every GO criterion is met. A read-only
`/api/list` has a clean stdlib-only shape (24 maps → 6 KB in 4.2 ms); "Open" swaps maps
in-place with no page reload by reusing `adoptImportedXml`; the version-aware default is
proven against real data (`/api/version?id=&v=` loads a map's latest saved version in-place,
HTTP 200); the feature hides cleanly on the static gallery via the existing `detectSaveApi`
gate; and the build decomposes into 2–3 bounded tasks with no new subsystem and the mirror +
T-138 invariants untouched (read path only). The concrete driver: 11 of 24 corpus maps already
carry saved versions (v1–v4) that today's `?load` silently ignores in favour of the stale
baseline — the browser both removes the gallery round-trip AND stops opening the wrong bytes.
Decision remains the human's (owner: human) via `fw task review T-142`.

**Date**: 2026-07-08T06:07:02Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-07T18:29:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-08T06:07:02Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** All five open questions are answered with evidence and every GO criterion is met. A read-only
`/api/list` has a clean stdlib-only shape (24 maps → 6 KB in 4.2 ms); "Open" swaps maps
in-place with no page reload by reusing `adoptImportedXml`; the version-aware default is
proven against real data (`/api/version?id=&v=` loads a map's latest saved version in-place,
HTTP 200); the feature hides cleanly on the static gallery via the existing `detectSaveApi`
gate; and the build decomposes into 2–3 bounded tasks with no new subsystem and the mirror +
T-138 invariants untouched (read path only). The concrete driver: 11 of 24 corpus maps already
carry saved versions (v1–v4) that today's `?load` silently ignores in favour of the stale
baseline — the browser both removes the gallery round-trip AND stops opening the wrong bytes.
Decision remains the human's (owner: human) via `fw task review T-142`.

### 2026-07-08T06:07:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
