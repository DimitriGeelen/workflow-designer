---
id: T-164
name: "Consistent-tile hover-zoom in the Versions modal"
description: >
  Consistent-tile hover-zoom in the Versions modal

status: work-completed
workflow_type: build
owner: human
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T22:57:45Z
last_update: '2026-08-16T12:33:41Z'
date_finished: 2026-07-09T23:01:11Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-164: Consistent-tile hover-zoom in the Versions modal

## Context

The Versions modal (`openVersionsModal`, ~line 7044) lists a map's saved versions as list
rows with a plain 120×74 thumbnail. The Open-project card browser (T-153/T-156) shows a real
tile with an enlarged **hover-zoom** preview; version-browsing should match it. Reuse the
existing hover-zoom infrastructure (`showProjectPreview`/`hideProjectPreview`/`_projectPreviewEl`,
keyed off `card._previewSrc`/`_previewMeta`) so hovering a version thumbnail shows the same
enlarged floating preview it does in Open-project. Small, self-contained polish — no server
or data-model change.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `showProjectPreview` resolves its anchor modal generically (works inside `#versions-modal` as well as `#project-modal`), so the hover-zoom preview positions correctly in the Versions modal. *(via `card.closest('#project-modal, #versions-modal')`; Open-project hover regression-checked OK)*
- [x] Each Versions-modal row's thumbnail carries `_previewSrc`/`_previewMeta` and shows the enlarged floating preview on `mouseenter`/focus and hides it on `mouseleave`/blur — same behaviour as an Open-project card. *(verified: hover on v4 → preview visible with image + caption "v4 / arc-lifecycle · ts"; leave → hidden)*
- [x] `closeVersionsModal` tears down the hover-preview element (`#project-hover-preview`) and clears the listener, exactly as `closeProjectModal` does — no orphaned preview after the modal closes. *(verified: modalGone + previewElementRemoved both true on close)*
- [x] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`. *(MIRROR-OK)*
- [x] Playwright: open the Versions modal for a map with ≥1 saved version → hover a version thumbnail → the enlarged preview appears (verified present + visible) → close the modal → the preview element is gone; 0 console errors; element screenshot READ. *(.playwright-mcp/t164-versions-hover-zoom.png — read: 4 versions + floating v4 preview; 0 console errors)*

### Human
- [x] [REVIEW] Version-browsing hover-zoom feels consistent with Open-project
  **Steps:**
  1. Open `http://localhost:8834/designer.html`, open a map that has saved versions (or Save-to-project twice to create some).
  2. Click **🕘 Versions** in the toolbar.
  3. Hover over a version's thumbnail.
  **Expected:** An enlarged preview of that version floats beside the modal (same look as hovering a card in Open-project), and disappears when you move away or close the modal.
  **If not:** Note which version/row and whether the preview failed to appear, mispositioned, or lingered after close.

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

## Recommendation

**Recommendation:** GO
**Rationale:** All five agent ACs verified in a live headless browser. Hovering a version
thumbnail now shows the same enlarged floating preview as the Open-project card browser,
positioned beside the modal, and it tears down cleanly on close. The change reuses the
existing hover-zoom infrastructure and did not regress Open-project (regression-checked).
The remaining Human AC is a quick visual taste-check.
**Evidence:**
- `.playwright-mcp/t164-versions-hover-zoom.png` (read): Versions modal for `arc-lifecycle`
  showing v4–v1 rows plus the floating v4 preview with caption.
- Hover on v4 → preview present + visible with image and caption; leave → hidden.
- Close → `#versions-modal` gone AND `#project-hover-preview` removed (no orphan).
- Open-project hover regression: still works + cleans up. 0 console errors.
- Verification gate: `diff -q src build/gallery/designer.html` → PASS (MIRROR-OK).

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

### 2026-07-09T22:57:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-164-consistent-tile-hover-zoom-in-the-versio.md
- **Context:** Initial task creation

### 2026-07-09T23:01:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1c896a33
- **Timestamp:** 2026-07-29T13:13:40Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#5 (Agent)** — Playwright: open the Versions modal for a map with ≥1 saved version → hover a version thumbnail → the enlarged preview appears (verified present + visible) → close the modal → the preview element is g
  - **AC-verify-mismatch** (narrow, heuristic) — `path=playwright-mcp/t164-versions-hover-zoom.png in: Playwright: open the Versions modal for a map with ≥1 saved version → hover a version thumbnail → the enlarged preview appears (verified present + vis`
