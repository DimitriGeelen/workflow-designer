---
id: T-088
name: "Bug: lane-label shrink tier was a silent no-op — CSS class rule overrides font-size presentation attribute"
description: >
  Probe evidence (2026-07-04): a lane-label text with font-size=8px ATTRIBUTE computes to 10px (.lane-label CSS wins over SVG presentation attributes); with inline style font-size:8px it computes to 8px. T-084's fit ladder set shrink steps as attributes, so tiers fs 9/8 never rendered smaller text — measurements stayed at 10px, making the shrink tier unreachable dead code (wrap and ellipsize tiers were honest and carried the 0/67 overflow result). Fix: mk() now sets inline style (shipped inside T-085's commit, required there so ladder steps beat the new svg[data-lsize] size CSS). This task records the RCA and the re-verified corpus invariant.

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
created: 2026-07-04T21:50:54Z
last_update: 2026-07-04T21:53:32Z
date_finished: 2026-07-04T21:53:32Z
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

# T-088: Bug: lane-label shrink tier was a silent no-op — CSS class rule overrides font-size presentation attribute

## Context

Discovered during T-085's size-pref work via a twin-element probe: `.lane-label { font-size: 10px }` (CSS class rule) silently overrides the `font-size` presentation attribute T-084's fit ladder used for its shrink tiers, so "shrink to 9/8px" never rendered smaller text. The invariant (0/67 overflow) still held because the later tiers — which measure honestly — compensated. Fix (attribute → inline style) shipped inside T-085's commit, where it was required anyway so ladder steps beat the new `svg[data-lsize]` size CSS. This task records the RCA and re-verified evidence.

## Acceptance Criteria

### Agent
- [x] Root cause demonstrated by measurement, not inference: probe elements with identical class show font-size ATTRIBUTE ignored (computes 10px under .lane-label) while inline STYLE applies (computes 8px)
      Evidence: browser probe on gallery designer 2026-07-04 — attrApplied="10px", styleApplied="8px".
- [x] Fix in place: fitLaneLabel's mk() sets shrink steps via inline style; no font-size-attribute path remains in the ladder
      Evidence: `attrs.style = 'font-size:' + fs + 'px'` in src + gallery copy (shipped with T-085).
- [x] Corpus invariant re-verified under honest shrink rendering: 0/67 lane-label overflow (25 wrapped / 1 ellipsized / 0 shrunk)
      Evidence: 24-map sweep 2026-07-04 post-fix; T-084's headline result stands — only the intermediate shrink tier was dead, wrap/ellipsize always measured honestly.
- [x] Learning captured for the class (verify styling via getComputedStyle, never via the attribute you set)
      Evidence: fw context add-learning entry referencing this task.

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

grep -q "attrs.style = 'font-size:'" src/aef-workflow-designer.html
sh -c "! grep -q \"attrs\['font-size'\] = fs\" src/aef-workflow-designer.html"
diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** T-084's lane-label fit ladder never produced genuinely smaller text: shrink tiers set `font-size` attributes (9/8px) but rendered size stayed 10px, so the shrink tier could never satisfy its own fit measurement and every shrink-candidate lane fell through to wrap or ellipsize.

**Root cause:** SVG presentation attributes sit at the bottom of the CSS cascade — any stylesheet rule (`.lane-label { font-size: 10px }`) overrides them; only inline `style` wins. The ladder used `el('text', { 'font-size': ... })`, silently defeated by the class rule.

**Why structurally allowed:** T-084's verification measured the end INVARIANT (0/67 overflow — which held, because later tiers compensated) and classified tiers by attribute presence, not computed style. Nothing compared `getComputedStyle(el).fontSize` against the intended value, so a dead tier looked alive in tier statistics.

**Prevention:** Learning captured: when code must control styling on a class-styled SVG element, set inline style AND verify with getComputedStyle — measure the rendered result, never trust the input you set (same spirit as PL-008). The 3-line twin-probe (attr vs style) from T-085 is the reusable check.

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

## Recommendation

**Recommendation:** GO
**Rationale:** Root cause proven by twin-element probe, fix shipped (inline style) and re-verified corpus-wide; the RCA and learning close the "measured the invariant but not the mechanism" blind spot for future ladder work.
**Evidence:**
- Probe: attribute font-size computes 10px, inline style computes 8px (same class)
- Post-fix sweep: 0/67 overflow, tiers 25 wrapped / 1 ellipsized / 0 shrunk (honest rendering)
- Learning recorded via fw context add-learning (T-088)

## Updates

### 2026-07-04T21:50:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-088-bug-lane-label-shrink-tier-was-a-silent-.md
- **Context:** Initial task creation

### 2026-07-04T21:53:31Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T21:53:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
