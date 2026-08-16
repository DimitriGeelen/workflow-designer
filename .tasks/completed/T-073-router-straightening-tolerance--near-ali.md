---
id: T-073
name: "Router straightening tolerance — near-aligned ends render as one straight line"
description: >
  Survey R-jog fix, operator-approved: if two connected ends are within ~8px of a
  shared axis, slide anchor along the node side and draw straight. Render-only — no
  position mutation, corpus YAML untouched.

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
created: 2026-07-04T09:43:50Z
last_update: '2026-08-16T12:33:34Z'
date_finished: 2026-07-04T10:06:02Z
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
  - ts: '2026-08-16T12:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-073: Router straightening tolerance — near-aligned ends render as one straight line

## Context

Operator-approved fix for the R-jog class from the routing readability survey
(docs/reports/T-041-routing-readability-survey.md): when two connected element
centres are ALMOST aligned (within a small tolerance of a shared axis), the
orthogonal router draws a 3-segment jog with two corners instead of one straight
line. Two operator screenshots showed this on healing-loop (gateway→advisory
vertical near-miss) and resume→resolved (horizontal near-miss). Fix is
RENDER-ONLY: slide the two anchor points along their node sides onto the shared
axis and draw a single straight segment. No node position mutation, corpus YAML
untouched, works with both attach modes (middle/spread).

## Acceptance Criteria

### Agent
- [x] A straightening pass exists in the edge render path: when source and target anchors for an auto-anchored edge are within STRAIGHTEN_TOL (default 16px — see Decisions) of a shared axis, both anchors are slid along their node sides to the common axis and the edge renders as one straight segment (verified: healing-loop e_05 dy=12 and e_10 dy=14 both render with uniqueY=1).
- [x] The slide is clamped to the node side extents (sideBoundaryPointAt returns null → bail, never distort) and applies only when both anchor sides are parallel and facing (E↔W or N↔S) — perpendicular-side edges are untouched.
- [x] Render-only: no `state.nodes[*].x/y` mutation from the straightening pass; buildBpmnXml output byte-identical before/after a render pass (exportIdentical=true on task-lifecycle) and positions array unchanged on healing-loop.
- [x] Explicitly pinned ports (non-auto) are never overridden by straightening (e_02 with targetPort=N kept its corner; restored to auto → straight again).
- [x] Trusted-input regression (PL-006): real page.mouse drag of n_resume by ~14 model px — connected e_09 still renders straight through the straightener; e_10 (now 27.8px off-axis, beyond tol) correctly jogs. Both sides of the tolerance behave.
- [x] Visual verification: element/clipped screenshots of healing-loop (resume→resolved, gateway→choose regions) and task-lifecycle full canvas READ with the Read tool — jogs collapsed to straight lines, no new overlap regression.
- [x] Editor JS passes `node --check` after the change; gallery copy refreshed (build/gallery/designer.html).

### Human
- [x] [REVIEW] Straightened routing reads calmer on the live gallery
  **Steps:**
  1. Open http://192.168.10.107:8834/ and click healing-loop, then task-lifecycle
  2. Look at edges between near-aligned elements (previously 2-corner jogs)
  **Expected:** Near-aligned connections render as single straight lines; diagrams read calmer, no edges overlapping node bodies that didn't before
  **If not:** Note which map + which edge, screenshot it, and report back

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

## Recommendation

**Recommendation:** GO
**Rationale:** All seven Agent ACs verified with evidence spanning static checks, live-browser probes, trusted input, and read screenshots. The change is render-only and heavily guarded (pinned ports, spread siblings, waypoints, hints, detours all excluded), so downstream risk to documents and the bridge seam is nil — bridge suite still 31/31. The one open item is the Human [REVIEW] AC (subjective calmness on the live gallery), which is exactly what partial-complete exists for.
**Evidence:**
- Operator cases fixed: healing-loop e_05 (dy=12) and e_10 (dy=14) now render uniqueY=1 (straight); clipped screenshots read and confirmed
- Render-only proven: buildBpmnXml byte-identical before/after render on task-lifecycle; node positions array unchanged on healing-loop
- Trusted input (PL-006): real page.mouse drag — within-tol edge stays straight, beyond-tol edge correctly jogs
- Pinned-port guard: e_02 targetPort=N kept its corner, restored to auto → straight again
- Gates: node --check clean, gallery copy diff-identical, bridge round-trip 31 passed 0 failed

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

awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t073-check.js && node --check /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t073-check.js
grep -q "STRAIGHTEN_TOL" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)

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

### 2026-07-04 — Straightening tolerance value
- **Chose:** STRAIGHTEN_TOL = 16px (task description said ~8px).
- **Why:** Measured the actual corpus misalignment class on healing-loop: nodes in the same lane row with different type heights have centre deltas of half the height difference — task↔gateway 12px (e_05), task↔event 14px (e_10). 8px would have missed BOTH operator-screenshot cases the task exists to fix. 16 covers the class; max slide per node side is 8px, well within all shape clamps.
- **Rejected:** 8px (misses the real cases); 24px+ (risks straightening intentionally offset connections).

### 2026-07-04 — Common-axis choice
- **Chose:** Midpoint of the two anchor coordinates — each anchor slides half the delta.
- **Why:** Symmetric, minimal per-node displacement, no bias toward either shape; a clamp failure on either side bails to the normal jog rather than distorting.
- **Rejected:** Snapping to the source's axis (asymmetric, source-biased); snapping to lane centre (that is T-074's authoring-time job, not a render decision).

### 2026-07-04 — Eligibility guards
- **Chose:** Straighten only when both ports are auto, spread offsets are 0, no manual waypoints, no routingHints, no detourY.
- **Why:** Each of those signals an explicit user/router intent that a silent visual override would fight — pinned ports are user choices, spread separates siblings, hints/detours are user-dragged geometry.
- **Rejected:** Straightening spread siblings toward a shared axis (would re-collide the edges that spread exists to separate).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T09:43:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-073-router-straightening-tolerance--near-ali.md
- **Context:** Initial task creation

### 2026-07-04T09:54:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T10:06:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cd31bd6b
- **Timestamp:** 2026-07-29T13:13:30Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
