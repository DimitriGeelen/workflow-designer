---
id: T-121
name: "inception-review layout: align emit-human column and record-end centres for
  clean midpoint attach"
description: >
  Operator field report (2026-07-06, screenshot of inception-review): edges do
  not attach at clean N/S/E/W face midpoints and elements do not align — frw_4_emit
  (n_emit) and hum_1_human (n_review) are 220px apart in x, so the sequential
  cross-lane edge staircases instead of dropping straight; and n_go/n_end_go +
  n_defer/n_end_defer centres are ~5px off, so straightenAnchors compensates with
  off-centre (±3px) attach. Fix the stored geometry (explicit, user-directed layout
  edit): move n_review under n_emit (shared centre-x) and align the end events to
  their record nodes' centre-y. Corpus data only — no editor JS change.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [ui, editor, corpus, bug, layout, routing]
components: []
related_tasks: [T-073, T-097, T-107, T-101]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-06T06:18:22Z
last_update: '2026-08-16T12:33:38Z'
date_finished: 2026-07-06T06:22:23Z
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
  - ts: '2026-08-16T12:33:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-121: inception-review layout: align emit-human column and record-end centres for clean midpoint attach

## Context

Field report (2026-07-06): in `inception-review`, the sequential flow
`n_emit → n_review → n_decide` reads as a staircase because `n_review` (cx=1255)
is 220px right of `n_emit` (cx=1035) — sequential cross-lane nodes should share a
column. Separately, `n_go`(cy=300)/`n_end_go`(cy=305) and
`n_defer`(cy=484)/`n_end_defer`(cy=479) are ~5px off-centre (the ends were spaced
by "distribute evenly" with a different pitch than the records), so the
straightenAnchors pass (T-073) keeps `e_12`/`e_14` straight by attaching ±3px off
the E/W face midpoint — the "lines don't attach to midpoints cleanly" symptom.

Root cause is stored-node-position, not the router. Fix = align node centres in
`examples/aef-processes/inception-review.workflow.yaml` (explicit user-directed
layout edit; not a render-pass mutation, so PD-044-clean) and re-render the bpmn.

## Acceptance Criteria

### Agent
- [x] `n_review.x` set to 980 (cx 1035 = `n_emit` cx) in inception-review.workflow.yaml
      — `n_emit → n_review` (e_07) renders as a single clean vertical drop
      (S-mid → N-mid, **0 bends**, `[1035,424]→[1035,540]`), no staircase
- [x] `n_end_go.y` set to 282 (cy 300 = `n_go` cy) and `n_end_defer.y` set to 466
      (cy 484 = `n_defer` cy) — `e_12`/`e_14` now attach **E-mid → W-mid, 0 bends,
      straight**, no ±3px straighten offset (e_13 was already clean)
- [x] bpmn re-rendered via `tools/yaml-to-bpmn.py` and mirrored to gallery; served
      map reflects the change (validator: VALID, no findings)
- [x] Post-change measurement (headless, live editor): e_07 S-mid→N-mid straight;
      e_12/e_14 E-mid→W-mid (no `-off(n)`); node-cuts 0; crossings 1 — the
      **pre-existing** decide→go/nogo fan (e_09×e_10), NOT introduced here
- [x] Before/after screenshots READ: `.playwright-mcp/t121-emit-human-after.png`
      (clean vertical emit→human, clean horizontal human→decide) and
      `.playwright-mcp/t121-record-end-after.png` (all 3 record→end edges dead-centre
      E-mid→W-mid, no hooks). "Before" = operator's field screenshot. No regression
- [x] No editor JS change (`src/aef-workflow-designer.html` untouched); other 23
      corpus maps unchanged (only inception-review.{workflow.yaml,bpmn}; gallery
      mirror is gitignored)

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
python3 -c "import yaml; yaml.safe_load(open('examples/aef-processes/inception-review.workflow.yaml'))"
python3 tools/validate-workflow.py examples/aef-processes/rendered/inception-review.bpmn
git diff --quiet src/aef-workflow-designer.html && echo "editor untouched"
grep -q "x: 980" examples/aef-processes/inception-review.workflow.yaml

## RCA

**Symptom:** `inception-review` opens with a staircased `emit→human` edge and
several edges attaching ~3px off the node face midpoint (little hooks) instead of
cleanly at N/S/E/W centres.

**Root cause:** Stored node positions are mis-aligned. `n_review` sits 220px right
of `n_emit` (sequential cross-lane nodes not column-aligned), and the three end
events were placed by even-distribution at a different vertical pitch (86.7px) than
their record nodes (92px), leaving the outer two ~5px off-centre. The router then
compensates: staircase for the big offset, straightenAnchors ±3px off-centre attach
for the small ones.

**Why structurally allowed:** Clean/align-columns only snaps *near*-aligned nodes
(220px is beyond tolerance and reads as intentional spacing), and align-rows/
distribute-evenly acted on records and ends independently so their centres drifted.
No corpus check asserts "sequential cross-lane nodes share a column" or "an edge
between two ~aligned nodes attaches at the face midpoint (no straighten offset)".

**Prevention:** (candidate) a corpus lint that flags edges whose endpoints attach
> N px off a face midpoint while the two nodes are within align tolerance — i.e.
straightenAnchors firing is a signal the nodes should have been aligned at bake.
Logged as a follow-up; this task fixes the one reported map.

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

### 2026-07-06 — Move n_review (not n_emit) to close the column
- **Chose:** Align by moving `n_review` left to cx=1035 (under `n_emit`).
- **Why:** `n_emit` is part of the framework-lane horizontal spine
  (readiness→ready_gate→linkcheck→emit, all cy=392) — it cannot move down without
  breaking that row. `n_review` is a lone human-lane node, free to slide under emit.
- **Rejected:** Moving `n_emit` (breaks the framework row); shrinking the 220px gap
  partially (still staircases).

### 2026-07-06 — Align end events to their record nodes, not vice-versa
- **Chose:** Set `n_end_go`/`n_end_defer` centre-y to match `n_go`/`n_defer`.
- **Why:** The records are evenly pitched (92px, cy 300/392/484); the ends had
  drifted to an 86.7px pitch from a separate distribute-evenly pass. Snapping the
  ends to the records restores a clean E-mid→W-mid attach with no straighten offset.
- **Rejected:** Re-pitching the records (would ripple to the decide→record fan).

## Visual Verification

Element-level screenshots (`#canvas`) taken after the fix and READ:
- `.playwright-mcp/t121-emit-human-after.png` — `frw_4_emit` sits directly above
  `hum_1_human`; the edge is a single clean vertical drop; `human→decide` is a clean
  horizontal into the Decision? gateway. Staircase eliminated.
- `.playwright-mcp/t121-record-end-after.png` — all three record→end edges
  (GO/NO-GO/DEFER) attach dead-centre E-mid→W-mid into the end circles, perfectly
  horizontal, no ±3px hooks.
"Before" reference = operator's field screenshot (2026-07-06). No new regression.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-06T06:18:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-121-inception-review-layout-align-emit-human.md
- **Context:** Initial task creation

### 2026-07-06T06:22:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
