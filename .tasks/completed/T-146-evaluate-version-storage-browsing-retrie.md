---
id: T-146
name: "Evaluate version storage-browsing-retrieval via Playwright"
description: >
  Evaluate version storage-browsing-retrieval via Playwright

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T10:58:14Z
last_update: 2026-07-09T11:14:32Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-146: Evaluate version storage-browsing-retrieval via Playwright

## Context

Playwright evaluation of the version subsystem (storage → browsing → retrieval)
on the live write-capable server (:8834, store=.editor-versions). Read-only: no
Save clicks, so the real `.editor-versions/` store and corpus were not mutated
(respects gap G-006). Screenshots in `.playwright-mcp/t146-*.png`.

### What works (verified live + in source)
- **Storage** — `.editor-versions/<id>/` holds vN.bpmn + vN.png + index.json
  (arc-lifecycle carries v1–v4 with timestamps + thumbnails). `POST /api/save`.
- **Browsing — Open project** (`openProjectModal`, T-144): 24-map grid (saved +
  rendered), thumbnails for saved / ▦ placeholder for rendered-only, live filter,
  `saved · vN` / `rendered` badges. Clean on fresh load. Screenshot: t146-open-project-modal.png.
- **Browsing — Versions** (`openVersionsModal`): per-map history newest-first
  (v4→v1), thumbnails, timestamps, per-version Revert. Screenshot: t146-versions-modal.png.
- **Retrieval — open latest in-place** (`openProjectMap` → `/api/version` at openTarget). ✓
- **Retrieval — revert to a specific version** (`revertToVersion` → `/api/version`):
  reverting arc-lifecycle to v1 re-rendered the v1 geometry. 0 console errors.
  Screenshot: t146-reverted-v1.png.

### Findings (each = candidate its-own-task; NOT fixed here — one bug = one task)
- **F1 [UX bug, low]** Revert shows the wrong toast. `revertToVersion` (src:6877)
  calls `showRestoredToast`, which ignores the passed title and reuses the
  page-load autosave banner: after reverting to v1 the UI said *"↩ Restored your
  unsaved work (<now>)"* with a **Start fresh** button — misleading; should read
  "Reverted to arc-lifecycle v1" with no Start-fresh action.
- **F2 [inconsistency, low]** Versions-modal thumb 404 handling (src:6920,
  `visibility:hidden` → blank gap) never got the T-144 ▦-placeholder fix that
  `openProjectModal` uses. A missing version PNG leaves a blank gap.
- **F3 [possible bug, medium — needs repro]** On the FIRST (dirty) load, with an
  autosave-restore pending, clicking "Open project…" adopted `review-emission`
  and showed NO modal. Not reproducible after `localStorage.clear()`. Smells like
  a race between `autoLoadStored`/`?load=` deep-link and modal open — real users
  will have autosave state, so worth a targeted repro.
- **F4 [dead feature, low]** Version notes are inert end-to-end-ish: `/api/save`
  accepts `note` and the Versions modal renders it (src:6926), but `saveToProject`
  hardcodes `note: ''` (src ~/api/save body) — a user can never attach a note.
- **F5 [clarity, low]** Two "version" concepts collide under one word: right-panel
  "Version: 1" (workflow contract version, manual bump) vs "saved · v4" (snapshot
  number). Same label, different meaning.
- **F6 [minor visual, low]** Open-project cards: on saved-thumbnail cards the title
  sits tight/slightly clipped against the thumbnail bottom edge.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Storage, browsing (Open-project + Versions) and retrieval (open-in-place + revert-to-version) each exercised live via Playwright, with element screenshots read
- [x] Findings recorded (F1–F6) with src line refs; no source mutated during evaluation (read-only, store/corpus untouched)
- [x] Findings triaged with severity + recommended fix sequence (F3 race first, then F1/F2/F4 quick wins)

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

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

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-09T10:58:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-146-evaluate-version-storage-browsing-retrie.md
- **Context:** Initial task creation
