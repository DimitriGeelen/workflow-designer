---
id: T-117
name: "De-jog routed edges: collapse tiny interior staircase steps to clean 90 corners"
description: >
  Operator improvement B (connect on 90, fuller slice). After align-in-middle (T-116), branch edges still render as a staircase with a small (6-8px) perpendicular kink where the connector between two stub-ends steps between parallel runs (e.g. promotion e_11: down, right, down7, right, down instead of a clean Z). Add a render-time de-jog post-pass on the transient _renderedPolyline: drop collinear points, then collapse an interior H-V-H / V-H-V pattern (short perpendicular step flanked by perpendicular outer segments so the outer stubs just flex) to a single straight run at the midpoint coordinate. Accept a collapse ONLY if it does not increase node crossings (polylineCrossesNodes) — a jog that clears an obstacle is left alone. Pure render cleanup, stored geometry untouched (PD-044). Endpoint-adjacent micro-steps (77% of jogs, stub meets face off-centre) are a deeper attachment-point change, deferred as a separate follow-up.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-116, T-114, T-105]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T22:14:10Z
last_update: 2026-07-06T19:03:15Z
date_finished: 2026-07-06T19:02:56Z
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

# T-117: De-jog routed edges: collapse tiny interior staircase steps to clean 90 corners

## Context

Operator improvement B (connect on 90°), fuller slice. Corpus census after T-116:
81 real jog-steps across 43 edges (collinear points excluded). Classification: 62
(77%) are endpoint-adjacent stub-attachment micro-steps (deeper fix, deferred); ~19
are interior staircase kinks — a short (6–8px) perpendicular step flanked by
perpendicular outer segments (e.g. promotion e_11: the connector between two
stub-ends steps between parallel runs). Prototype de-jog removed 26 with 0 node-cuts
added. This task ships the safe interior de-jog only.

## Acceptance Criteria

### Agent
- [x] `simplifyRoutedPolyline(pl, src, tgt)` + `collapseCollinearPoints` added:
      (a) drops collinear midpoints, (b) collapses an interior H-V-H / V-H-V step
      (≤10px) flanked by perpendicular outer segments to a single straight run at
      the midpoint coordinate
- [x] Collapse accepted ONLY if `polylineCrossesNodes` does not increase (a jog that
      clears an obstacle is preserved) — self-validating, no phantom regression (T-110)
- [x] Wired into buildOrthogonalPath's finalize (applied to the transient polyline
      used for BOTH the drawn path string and `edge._renderedPolyline`); stored
      geometry untouched (PD-044)
- [x] Corpus-wide: node-cut gate 0/24 PASS; interior jog count 81→55 (−26 removed);
      0 node overlaps introduced; visually confirmed on promotion e_11 (gateway→warn
      drop now a single straight vertical, screenshot read)
- [x] Endpoint-adjacent micro-steps (62 of 81, stub meets face off-centre) explicitly
      OUT of scope — deeper attachment-point change, deferred follow-up
- [x] Editor JS synced byte-identical to build/gallery/designer.html

### Human
- [ ] [REVIEW] Branch edges read as clean 90° corners, not staircases
  **Steps:**
  1. Reuse the gallery on :8834; open promotion-pipeline (click Clean if needed)
  2. Look at the gateway→"Warn early promotion" drop and other branch drops
  **Expected:** each drop is one straight vertical into the node, no 6–8px kink
  **If not:** note the map + edge that still steps (may be an endpoint-adjacent case,
  which is the deferred follow-up)

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
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "function simplifyRoutedPolyline" src/aef-workflow-designer.html
grep -q "simplifyRoutedPolyline(result.polyline" src/aef-workflow-designer.html
tests/check-corpus-node-cuts.sh

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

## Recommendation

**Recommendation:** GO (accept the change; one Human REVIEW AC remains for live confirmation)

**Rationale:** The interior de-jog (`simplifyRoutedPolyline` + `collapseCollinearPoints`,
wired into `buildOrthogonalPath`'s finalize) collapses tiny interior staircase kinks to clean
90° corners, and does so safely: a collapse is accepted ONLY when `polylineCrossesNodes` does
not increase, so it can never turn a clean edge into a node-cut. The scope is deliberately the
safe interior kinks only — endpoint-adjacent stub micro-steps (62 of 81) are explicitly
deferred. The corpus node-cut gate is the live regression guard.

**Evidence:**
- `bash tests/check-corpus-node-cuts.sh` — 24 unchanged, 0 regressed, total cuts 0 (the
  de-jog never introduces a crossing; the whole corpus stays clean).
- P-011 greps pass: `simplifyRoutedPolyline` present and wired at
  `simplifyRoutedPolyline(result.polyline …)`; mirror `diff -q` clean.
- Prior build measurement recorded in the ACs: interior jog count 81→55 (−26 removed) with 0
  node-cuts added.

**Human review note:** confirm in a live map (hard refresh first) that branch edges read as
clean 90° corners rather than short staircases, with no edge visibly cutting a node.

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

### 2026-07-05T22:14:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-117-de-jog-routed-edges-collapse-tiny-interi.md
- **Context:** Initial task creation

### 2026-07-06T19:02:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cd772241
- **Timestamp:** 2026-07-27T21:20:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
