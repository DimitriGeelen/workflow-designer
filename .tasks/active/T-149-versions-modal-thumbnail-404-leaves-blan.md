---
id: T-149
name: "Versions modal thumbnail 404 leaves blank gap — apply placeholder"
description: >
  Versions modal thumbnail 404 leaves blank gap — apply placeholder

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T11:24:33Z
last_update: 2026-07-09T11:26:02Z
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

# T-149: Versions modal thumbnail 404 leaves blank gap — apply placeholder

## Context

T-146 finding F2. The Versions modal's thumbnail 404 handler
(`openVersionsModal`, src `img.onerror = () => { img.style.visibility = 'hidden'; }`
~line 6920) leaves a blank gap when a version PNG is missing, whereas
`openProjectModal` (T-144) shows a neutral ▦ placeholder. Apply the same
placeholder to the Versions modal.

**Fix plan (ready to implement next session):**
1. Extract the `thumbPlaceholder` closure (currently local to `openProjectModal`,
   ~line 7017) to a module-level helper `makeThumbPlaceholder({w, h, radius})` so
   both modals share it. openProjectModal keeps its 104px full-width variant
   (border-bottom); the Versions modal wants ~120×74 with border + border-radius:4px.
2. In `openVersionsModal`, replace `img.onerror = () => visibility hidden` with
   `img.onerror = () => img.replaceWith(makeThumbPlaceholder({w:120,h:74,radius:4}))`.
3. Mirror src → build/gallery/designer.html (`cp` + `diff -q`).
4. Visual-verify: force a 404 (e.g. request a nonexistent version thumb) and
   screenshot the Versions modal showing ▦, not a blank gap.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Shared `makeThumbPlaceholder({w,h,radius})` helper extracted; `openProjectModal` still renders its ▦ placeholder for rendered-only cards (no regression) — module-level helper at src ~6883; openProjectModal's `thumbPlaceholder` closure now delegates to it. Regression check: Open-project modal renders 13 ▦ placeholders + 12 image cards (25 total), no broken images.
- [x] `openVersionsModal` replaces a 404'd version thumbnail with the ▦ placeholder (no blank gap) — `img.onerror` now `img.replaceWith(makeThumbPlaceholder({w:120,h:74,radius:4,flex:'0 0 auto',fontSize:22}))`. Forced-404 on arc-lifecycle v2: DOM shows exactly 1 ▦ tile + 3 real thumbs across 4 rows.
- [x] src mirrored to build/gallery/designer.html (diff -q clean) — MIRROR-OK
- [x] Visual: screenshot Versions modal with a forced-404 thumb showing ▦ (## Visual Verification)

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

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
out=$(grep -n "function makeThumbPlaceholder" src/aef-workflow-designer.html); echo "$out" | grep -q "makeThumbPlaceholder"
out=$(grep -n "img.replaceWith(makeThumbPlaceholder" src/aef-workflow-designer.html); echo "$out" | grep -q "makeThumbPlaceholder"
diff -q src/aef-workflow-designer.html build/gallery/designer.html
test -f .playwright-mcp/t149-versions-404-placeholder.png

## Visual Verification

Forced a 404 by moving `.editor-versions/arc-lifecycle/v2.png` aside (curl confirmed
`/api/thumb?id=arc-lifecycle&v=2` → 404, v1 → 200), then opened the Versions modal via
Playwright on `http://localhost:8834/designer.html`.

- **Screenshot:** `.playwright-mcp/t149-versions-404-placeholder.png` — read and confirmed:
  v4/v3/v1 rows show real BPMN thumbnails; the **v2 row shows a neutral ▦ tile** at the
  same 120×74 size with rounded border, sitting in-row. No blank gap, no broken-image icon.
- **DOM assertion (Versions modal):** 4 rows, exactly 1 ▦ placeholder, 3 remaining `<img>`.
- **Regression (Open-project modal):** 25 cards → 13 ▦ placeholders (rendered-only maps) +
  12 image cards; the shared helper renders correctly in both modals.
- v2.png restored after the test; no version-store changes committed.

## RCA

**Symptom:** In the Versions modal, a version whose thumbnail PNG was missing/404'd
rendered as a blank gap (the `<img>` was set `visibility:hidden`), leaving a ragged
empty tile — inconsistent with the Open-project modal, which already showed a ▦ tile.

**Root cause:** The 404 handler `img.onerror = () => img.style.visibility = 'hidden'`
hid the broken image instead of substituting a placeholder. The ▦ placeholder existed
only as a closure *local to* `openProjectModal`, so the Versions modal had no access to it.

**Why structurally allowed:** The placeholder was written for one modal (T-144) as a
private closure, not a shared helper — so the second consumer silently diverged. DOM-rect
verification wouldn't catch it (geometry is unaffected); only looking at the rendered
output reveals the empty tile.

**Prevention:** Extracted `makeThumbPlaceholder({w,h,radius,...})` as a single module-level
helper both modals call, so any future thumbnail surface reuses the same neutral tile
rather than re-implementing (and diverging on) the 404 path. Visual-verification screenshot
is the check that catches a regression of the rendered output.

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

### 2026-07-09T11:24:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-149-versions-modal-thumbnail-404-leaves-blan.md
- **Context:** Initial task creation
