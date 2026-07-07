---
id: T-142
name: "In-editor Open-from-project browser for workflow files"
description: >
  Inception: In-editor Open-from-project browser for workflow files

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-07T18:28:17Z
last_update: 2026-07-07T18:31:19Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
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
  confidence: 1
  disposition: deferred
  rationale: Spike 1 will prototype it in gallery-serve.py and produce a sample payload.
- **IW-2: Can "Open" swap a map in-place (no full-page reload) by reusing the existing
  `?load` → `adoptImportedXml` path (src:7002, src:6927)?**
  confidence: 2
  disposition: deferred
  rationale: Path exists and is in-memory; Spike 2 confirms it works from a modal click.
- **IW-3: Does the whole feature hide cleanly on the static gallery (no `/api/*`), like
  Save/Versions already do via detectSaveApi (src:6747)?**
  confidence: 2
  disposition: deferred
  rationale: Precedent exists; Spike 3 confirms the list button hides without /api/health.
- **IW-4: Does the build decompose into ≤2–3 bounded build tasks, keeping this an
  inception (not a creeping subsystem)?**
  confidence: 1
  disposition: deferred
  rationale: Provisional split — endpoint / modal / saved-work surfacing; confirmed at decide.
- **IW-5: When a map has saved versions in `.editor-versions/<id>/`, should "Open" default
  to loading the LATEST saved version (not the stale `rendered/` baseline), surface the
  latest version label in the list, and offer older versions via the existing Versions
  modal?**
  confidence: 2
  disposition: deferred
  rationale: Today `?load` always fetches `rendered/<id>.bpmn` (baseline), so saved edits are
  silently ignored on open — the friction this inception exists to fix. `/api/versions` +
  `/api/version?v=` already exist (gallery-serve.py:28-29); Spike 1 resolves latest-per-map,
  Spike 2 wires "open latest" as the default with an older-version affordance.

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
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
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

**Recommendation:** DEFER

**Rationale:**

Evidence shows browsing is genuinely weak: opening a project map requires leaving the editor for the gallery page and a full reload; the in-editor 'Switch workflow' picker only holds session scratch (populated from the in-memory library, seed-only at Init, refreshLibraryUI:1909); saved maps in .editor-versions/ never appear in the gallery (index lists only rendered/*.bpmn snapshotted at server start); and there is no /api/list endpoint, so the editor cannot even enumerate the corpus. Option A (new /api/list + in-editor picker modal) is the real fix but introduces a new API route and a new modal — inception-sized per G-020. DEFER to a spike that validates the endpoint shape and modal UX against the running gallery before any build commitment; the go/no-go follows that evidence.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-07T18:29:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
