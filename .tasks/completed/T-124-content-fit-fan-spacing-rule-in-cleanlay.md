---
id: T-124
name: "Content-fit fan-spacing rule in cleanLayout: spread cramped gateway fans so
  branch labels get distinct channels"
description: >
  Content-fit fan-spacing rule in cleanLayout: spread cramped gateway fans so branch
  labels get distinct channels

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-06T08:11:02Z
last_update: '2026-08-16T13:57:16Z'
date_finished: 2026-07-06T08:17:28Z
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
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:16Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:build/gallery/designer.html,src/aef-workflow-designer.html); tier=2
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-124: Content-fit fan-spacing rule in cleanLayout: spread cramped gateway fans so branch labels get distinct channels

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Baseline captured (headless + in-browser): corpus label-on-gateway = 8 across 5
      maps, label∩label = 1 (verification-gate), node-cuts = 0/24, all edges routed clean
- [x] cleanLayout pass structure documented: passes = per-lane `tidyLane` (grid row-snap
      + T-093 branch-stack pitch respace) → `alignRowsLane` → `alignColumnsMoves`. The
      branch-stack pass ALREADY spreads cramped vertical fans, guarded (revert on new
      collision, grow lane on overflow), pitch = tallestMember + `BRANCH_GAP` where
      GAP = {compact:6, auto:12, roomy:28}. So the "fan-spacing lever" already exists as
      the branch-pitch setting — the only new-code option would be auto-escalating it.
- [x] Faithful corpus experiment (in-browser, exact attach points, PL-015): ran
      cleanLayout at auto vs roomy pitch across the 5 label-affected maps + 5 clean
      controls, measuring onGateway / label∩label / node-cuts each. **RESULT (NO-GO):**
      roomy clears only **1 of 9** residual overlaps (error-escalation-ladder 2→1); the
      other 8 are unaffected because they are horizontally-adjacent gateways
      (verification-gate ×3+1 = the T-105 gateway-NAME issue, already has a render-only
      fix pending human review) or single-branch labels — neither touchable by vertical
      pitch. roomy added **zero** cuts and **zero** crossings anywhere (harmless).
- [x] DECISION: **do NOT ship** an adaptive-pitch fan-spacing pass (see ## Decisions).
      Payoff = 1 minor overlap on 1 map; cost = new code in the core layout pass + a
      layout-vs-label phase-ordering loop + regression surface across 24 maps. Fails the
      ship-gate: not a strict, meaningful win. Editor left unchanged.
- [x] TOOL-ONLY honoured: no editor JS changed, no corpus re-bake —
      `diff -q src/aef-workflow-designer.html build/gallery/designer.html` clean;
      `examples/aef-processes/*.workflow.yaml` untouched.

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

### 2026-07-06 — Measured NO-GO: no fan-spacing pass shipped
- **Chose:** Ship NO editor change. The "fan-spacing lever" already exists (T-093
  branch-pitch, gap 6/12/28). Faithful corpus experiment shows escalating it (auto→roomy)
  clears just 1 of 9 residual label-on-gateway overlaps and cannot touch the other 8
  (horizontally-adjacent gateways / single-branch labels). Not a meaningful win.
- **Why:** Ship-gate (PL-015 / T-120): only ship a layout-engine change that strictly and
  meaningfully wins on faithful measurement. Adding an auto-escalating adaptive-pitch pass
  (plus a layout↔label-measurement phase loop) to the core `tidyLane` for one minor
  overlap is regression surface without payoff. The residual overlaps are minor, and the
  densest (verification-gate) is the T-105 gateway-NAME case already fixed render-only
  (deCollideBelowLabels, pending human review).
- **Rejected:** (a) horizontal fan-reflow (shift branch column + downstream right) — most
  invasive option, high ripple/regression risk, for the same marginal gain; (b) global
  roomy default — would over-spread the already-compact/clean maps the operator wants
  tight (violates the pair-7 "fit spacing to content" meta-rule in the other direction);
  (c) re-bake corpus at roomy — mutates sovereign geometry (the T-122 concern) for 1 map.
- **Broader finding for the operator:** the corpus is objectively clean (0 node-cuts/24,
  ~9 minor label touches mostly horizontal-gateway-name or bbox-corner artifacts). There
  is no high-value *automated* routing optimisation left to ship right now without risking
  the delicately-tuned engine. The compaction the operator demonstrated in the before/after
  images was uncommitted (never in git) and the objective sprawl is modest & structural
  (lane order, not inflated heights). Further layout-taste work is best done live WITH the
  operator, not baked autonomously.

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-06T08:11:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-124-content-fit-fan-spacing-rule-in-cleanlay.md
- **Context:** Initial task creation

### 2026-07-06T08:17:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
