---
id: T-043
name: "inception-review diagram exceeds canvas viewport clipping decision fan"
description: >
  inception-review diagram exceeds canvas viewport clipping decision fan

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-03T08:58:02Z
last_update: 2026-07-03T09:09:17Z
date_finished: 2026-07-03T09:09:17Z
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

# T-043: inception-review diagram exceeds canvas viewport clipping decision fan

## Context

After T-042 fixed the editor's `aef:` namespace so authored positions are honoured, the
`inception-review` diagram renders at its authored width (~1900px; nodes out to x=1860).
The editor canvas neither scrolls nor zoom-to-fits, so the go/no-go/defer decision fan and
the three end-events are **clipped off the right edge** — the operator cannot see the
payoff of the flow, which blocks the T-041 A-4 fidelity pilot. Evidence:
`t042-inception-review-fullwidth.png` (fan edges labelled go/no-go/defer trail off-canvas).

Two candidate approaches (pick during build):
- **Editor** — add canvas zoom-to-fit (or horizontal pan/scroll) so any diagram wider than
  the viewport is fully reachable. Product-level fix; benefits the whole corpus.
- **Data** — compress the corpus x-coordinates to fit a standard viewport (~1280px). Cheap,
  per-file, but doesn't help larger workflows.

Prefer the editor fix (portable, benefits all workflows); confirm approach before building.

## Acceptance Criteria

### Agent
- [x] The full `inception-review` diagram — all 14 nodes incl. the go/no-go/defer fan and
      the three end-events (uids `n_go`/`n_nogo`/`n_defer`/`n_end_go`/`n_end_nogo`/`n_end_defer`)
      — is reachable in the editor without editing the file (fit-to-view: canvas viewBox now
      sizes to `contentRightEdge()`, not the fixed `POOL_WIDTH`)
- [x] Verified by Playwright: screenshot shows the decision fan + end-events fully rendered
      (not clipped), READ to confirm — no regression to the now-correct lane layout
      (`t043-inception-review-fittoview.png`)
- [x] The default `investigate` workflow still renders correctly both via library
      (`t043-investigate-regression-check.png`) and via file Load… (golden preserves authored
      uids/positions `n_start01 x=280 y=96` — verified in-browser) — no layout regression

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
# Structural proxies for the fit-to-view fix (visual proof is in ## Visual Verification):
grep -q "function contentRightEdge" src/aef-workflow-designer.html
! grep -q "POOL_X + LANE_HEADER + POOL_WIDTH + 30" src/aef-workflow-designer.html

## RCA

**Symptom:** After T-042 made the editor honour authored positions, the `inception-review`
diagram rendered at its true width (nodes to x=1860) but the go/no-go/defer fan and the three
end-events were clipped off the right edge, unreachable (canvas neither scrolls nor fits).

**Root cause:** `syncCanvasSize` set the SVG `viewBox` width from the fixed constant
`POOL_WIDTH` (1480) rather than the actual content extent, and `renderPool` sized the pool
the same way. With `preserveAspectRatio` on the SVG, anything past that fixed width fell
outside the viewBox and was cropped. The canvas width was never content-aware.

**Why structurally allowed:** Until T-042 no imported file's positions were honoured (the
namespace bug auto-laid-out everything into the POOL_WIDTH box), so a diagram wider than
1480px never occurred — the fixed width was never exercised. Fixing the namespace exposed
the latent width assumption. No test rendered a wide corpus file and checked full visibility.

**Prevention:** `contentRightEdge()` now sizes both the viewBox and the pool to enclose the
right-most node (falling back to the POOL_WIDTH floor), so the viewBox scales to fit
(fit-to-view) instead of cropping — for any workflow width, not just this one. Verification
pins the helper in place and asserts the old fixed-width viewBox line is gone.

## Visual Verification

Playwright, editor at `http://127.0.0.1:8010/src/aef-workflow-designer.html`:
- `t043-inception-review-fittoview.png` — READ: the full `inception-review`, incl. the
  Record GO/NO-GO/DEFER fan and all three end-events, now renders unclipped; lanes still
  correctly contain their nodes; no overlap.
- `t043-investigate-regression-check.png` — READ: default `investigate` (library load)
  unchanged. File-load of the golden `investigate.bpmn` verified in-browser to preserve
  authored uids/positions (`n_start01 x=280 y=96`).

<!--
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

### 2026-07-03T08:58:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-043-inception-review-diagram-exceeds-canvas-.md
- **Context:** Initial task creation

### 2026-07-03T09:09:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
