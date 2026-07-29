---
id: T-286
name: "Edge arrowheads render above node-id badges; selected element's badge comes to foreground"
description: >
  Edge arrowheads render above node-id badges; selected element's badge comes to foreground

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-28T17:29:48Z
last_update: 2026-07-28T17:55:05Z
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

# T-286: Edge arrowheads render above node-id badges; selected element's badge comes to foreground

## Context

Operator request (2026-07-28, with screenshot of fw_1_scan): node-id badges + their T-083
halos paint above edge arrowheads (badges live inside node groups in #g-nodes, above
#g-edges), which (a) occludes arrowheads entering a node near its badge and (b) makes the
edge-endpoint drag handle unreachable where a badge/halo overlaps it (SVG hit-testing
follows paint order). Requested behaviour: arrows always above id badges by DEFAULT;
when an element is selected, THAT element's badge raises to the foreground. Mechanism:
re-home badge+halo pairs into a dedicated #g-badges layer painted below #g-edges
(selected element's badge into #g-badges-top above #g-nodes), pointer-events:none on
both layers. Constraint verified pre-build: all node-id-badge DOM queries (placement
passes, halo pass) run inside renderNodes BEFORE the re-home step; the edge router uses
state-derived nodeVisualBottom, not badge DOM — no cross-render consumers break.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Default paint order: after render, all node-id badges (and their halo rects) live in #g-badges, which precedes #g-edges in document order — arrowheads paint above badges (CDP: 15 badges + 15 halos in #g-badges, 0 left in #g-nodes; compareDocumentPosition order g-badges < g-edges < g-nodes < g-badges-top)
- [x] Selecting a node moves its id badge+halo to #g-badges-top (after #g-nodes); deselecting returns it to #g-badges (CDP: n_request click → agt_1_fw + halo in top, 14 below; canvas click → 0 top / 15 below)
- [x] Drag-handle reachability: elementFromPoint at edge-endpoint handles returns port-indicator/handle or the (pre-existing) node shape — never a badge/halo; hit at badge center passes through to lane-bg (CDP hit-tests on verification-gate, edge e_06)
- [x] Badge layers are pointer-events:none — clicks through badge area reach whatever is beneath (attribute asserted + lane-bg hit-test)
- [x] No routing/geometry regression: geometry sweep 24 clean, node-cut sweep 0 (baseline 0), bridge round-trip 41/41
- [x] Visual verification: screenshots read at 94% zoom (single dark theme — no theme system) — default: edge lines run continuous over frw_5_011/frw_3_agent badges; selected: n_verify's badge + halo raised above the edge (t286-zoomed-{default,selected}.png on :8834)

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
- [ ] [REVIEW] Arrow-over-badge default + selected-badge-forward feels right; endpoint drag handles now grabbable near badges
  **Steps:**
  1. Open http://192.168.10.107:3000/designer and click the **t293-retest-harvest** card
     (:3000 serves the 0.8.0 bundle with this change; :8834 is LAN-blocked — no ufw rule, T-253 class)
  2. Find a node whose id badge sits near an incoming arrow (e.g. the fw_1_scan node from your screenshot)
  3. Confirm the arrowhead reads on top of the badge; click the node — its badge should pop to the foreground; click empty canvas — badge drops back under
  4. Select the incoming edge and drag its endpoint handle where the badge overlaps it
  **Expected:** arrowhead never hidden by a badge when nothing is selected; selected node's badge fully legible; endpoint handle grabbable through the badge area
  **If not:** screenshot the spot and note which map/node — reopen T-286

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
grep -q 'id="g-badges"' src/aef-workflow-designer.html
grep -q 'id="g-badges-top"' src/aef-workflow-designer.html
bash tests/check-corpus-geometry.sh > /tmp/.t286-geom 2>&1 && grep -qi "clean\|pass\|ok" /tmp/.t286-geom
bash tests/run-bridge-tests.sh > /tmp/.t286-bridge 2>&1

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

### 2026-07-28 — badge text was never the pointer blocker; the halo was
- **What changed:** pre-build reading showed .node-id-badge already had pointer-events:none (line 571) — the interception came from the T-083 halo rect (no pointer-events attr, painted inside the node group above edges). The operator's "cannot drag handle" symptom and the arrowhead occlusion share one root: badges+halos living in #g-nodes, above #g-edges.
- **Plan impact:** none structural — the layer-split design covers both; but the halo needed a class (badge-halo) so the re-home step can move the pair without guessing at previousSibling identity (the sibling can be the node's body rect when a badge has no halo).
- **Triggered:** nothing filed. Note for T-083 lineage: its "pad masks any edge segment" comment is now intentionally inverted by default — masking only applies to the selected element's raised badge.

## Visual Verification

- t286-zoomed-default.png (on :8834) — 94% zoom, verification-gate: edge lines continuous over frw_5_011/frw_3_agent badges, arrowheads unmasked
- t286-zoomed-selected.png (on :8834) — same view, n_verify selected: its badge+halo raised above the edge, node glow visible

## Recommendation

**[GO]** — the requested behaviour is implemented exactly as described (arrows above badges by default, selected element's badge foregrounded), all six agent ACs verified with CDP assertions + read screenshots, zero regression across geometry/node-cuts/bridge suites. The mechanism (paint-order layer split, pointer-events:none) is the minimal structural fix for both reported symptoms — occluded arrowheads and unreachable endpoint handles.

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

### 2026-07-28T17:29:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-286-edge-arrowheads-render-above-node-id-bad.md
- **Context:** Initial task creation

### 2026-07-28T17:48:43Z — status-update [task-update-agent]
- **Change:** owner: agent → human

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8d418ec8
- **Timestamp:** 2026-07-29T13:13:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
