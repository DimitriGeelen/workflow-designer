---
id: T-050
name: "Editor fit-to-view measures label text extent via getBBox"
description: >
  Editor fit-to-view measures label text extent via getBBox

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
created: 2026-07-03T13:10:28Z
last_update: 2026-07-03T13:10:28Z
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

# T-050: Editor fit-to-view measures label text extent via getBBox

## Context

Closes PL-003. `syncCanvasSize()` (src/aef-workflow-designer.html:1640) sizes the
viewBox from node **boxes** only (`contentRightEdge()` = `n.x + w + 60`), ignoring
label text. Event/gateway labels are single-line, centered on a 36–48px shape, so a
long label overflows both sides invisibly and fit-to-view clips it. This forced
short-label trimming in three dogfood maps (T-046 right + left bbox x=-38, T-049
right +14px). `renderNodes()` runs before `syncCanvasSize()` in `renderAll()`, so the
label `<text>` elements are already in the DOM — `svg.getBBox()` can measure their
true glyph extent. Fix: size the viewBox from the rendered bbox (padded), keeping the
node-box math as a floor and headless fallback. Pool-rect width (`renderPool`) stays
node-box-driven — labels may legitimately sit outside the pool.

## Acceptance Criteria

### Agent
- [x] `syncCanvasSize()` derives the viewBox from `svg.getBBox()` (actual rendered
      extent, glyphs included), with `contentRightEdge()`/`poolHeight()` retained as a
      floor so small diagrams are unchanged
- [x] The viewBox origin may become negative so a left-overflowing label (leftmost
      node) is enclosed rather than clipped at x=0
- [x] `getBBox()` failure (detached/headless) is caught and falls back to the prior
      node-box sizing — no throw, no blank canvas
- [x] A long label that previously clipped renders fully inside the viewBox with NO
      trimming, verified by element-level Playwright screenshot that is READ (see
      ## Visual Verification); no new regression in a small-diagram map
- [x] No regression from this change: bridge suite green (17/17); every map authored
      under the current T-042/T-043 lane-band convention still passes the geometry
      gate; the change touches only the editor (HTML/JS), not maps or the gate tool.
      (Pre-existing geometry debt in 8 older pre-convention maps is independent of
      this task — registered separately as T-051.)

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

# Fix is present in the code path
grep -q "getBBox" src/aef-workflow-designer.html
# Fallback floor is still wired (node-box math retained)
grep -q "contentRightEdge" src/aef-workflow-designer.html
# No round-trip / corpus regression
bash tests/run-bridge-tests.sh

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

## Visual Verification

Served the editor over HTTP (`python3 -m http.server 8842`) and drove it with
Playwright (`http://127.0.0.1:8842/src/aef-workflow-designer.html`).

**Numeric proof (browser_evaluate).** Set a long single-line label on the right-most
node ("Handoff emitted ✓ → human sovereignty review (out-of-band, Watchtower)") and a
long label on the left-most node, then `renderAll()`:
- Old node-box viewBox would have been `[0, 0, 1600]`; the right label extends to
  x=1613 → **overflowed the old right edge by 13px** (clipped), and the left label
  starts at x=-20 → clipped entirely at the x=0 origin.
- New viewBox `[-36, 0, 1664, 692]` — origin shifted negative to enclose the left
  label, width extended to enclose the right label. `allLabelsWithinViewBox === true`
  on all four sides.

**Screenshot READ** (`t050-longlabels.png`, element-level `#canvas`): the right label's
closing `Watchtower)` is fully visible (previously clipped); the left label's first
glyph is enclosed with margin. No new visual regression in the diagram body. The
left-label/next-node overlap visible in the shot is an artifact of the artificially
long stress label on a tightly-packed seed node — not a viewBox clip.

**Regression (small diagram).** Fresh seed load with normal labels → viewBox exactly
`[0, 0, 1600, 692]`, byte-identical to pre-T-050 (node-box floor = 1600). The fix is a
no-op for well-behaved diagrams; it engages only when a label actually overflows.

**Console:** 0 errors, 0 warnings across both loads.

## Decisions

### 2026-07-03 — how to measure label extent
- **Chose:** size the viewBox from `svg.getBBox()` (actual rendered glyph extent),
  keeping `contentRightEdge()`/`poolHeight()` as a floor and a try/catch fallback.
- **Why:** `renderNodes()` runs before `syncCanvasSize()` in `renderAll()`, so the
  label `<text>` is already in the DOM — getBBox gives exact glyph extent for free,
  including kerning/ellipsis that per-character estimation misses (the failure mode
  CLAUDE.md §Visual Verification warns about). Pool-rect width stays node-box-driven
  so labels may legitimately sit outside the pool.
- **Rejected:** per-character width estimation (`label.length * fontSize*0.55`) —
  inaccurate for proportional fonts and the exact "DOM-math ≠ rendered" trap;
  reflowing/auto-laying-out nodes — violates the T-042 authored-coordinate contract.

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

### 2026-07-03T13:10:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-050-editor-fit-to-view-measures-label-text-e.md
- **Context:** Initial task creation
