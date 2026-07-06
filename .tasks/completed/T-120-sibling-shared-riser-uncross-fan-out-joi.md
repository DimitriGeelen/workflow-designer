---
id: T-120
name: "Sibling shared-riser uncross fan-out join edges via guarded render post-pass"
description: >
  Render-time post-pass that reroutes fan-out (shared source) and join (shared
  target) sibling edge groups into a nested shared riser, ordered by far-end y,
  so same-block branch edges nest instead of crossing. Guarded per-group: apply
  only if it strictly reduces proper crossings AND does not increase node-cuts
  for the map. INVESTIGATED — measured NO-GO: faithful guarded prototype yields only
  corpus 20->18 (one map) and is not a visual improvement, so the pass was NOT built.
  See ## Decisions. Render-only investigation, stored geometry untouched (PD-044).

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-097, T-117, T-118, T-119]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-06T05:47:15Z
last_update: 2026-07-06T05:58:42Z
date_finished: 2026-07-06T05:58:42Z
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

# T-120: Sibling shared-riser uncross fan-out join edges via guarded render post-pass

## Context

T-097 eliminated the collinear-overlap "ambiguous bundle" class (overlap pairs
104→7) via anchor spread + channel pitch, but left residual *proper* crossings.
Render-only census (2026-07-06, live editor, 24 maps): 20 proper crossings
(interior segment intersections between different edges; excludes shared-endpoint
touches). Classification: roughly half are topologically forced (bidirectional
pairs e.g. task-lifecycle n_ready↔n_authoring; independent edges crossing due to
node placement — fixable only by moving nodes = mutating stored geometry, out of
scope PD-044); the other half are **fan-out/join anchor-ordering** crossings where
sibling edges leaving one source (or entering one target) cross each other because
their T2 mid-bars are mis-placed/mis-ordered.

The fix: a render-time post-pass that, for each fan-out (shared source) or join
(shared target) group whose far ends all lie on one horizontal side, reroutes the
group into a **nested shared riser** — a common vertical bus at the anchor face,
with each sibling breaking off horizontally at its far-end y, ordered by far y so
they nest without crossing. Applied **per-group** and kept only if it strictly
reduces the map's proper-crossing count AND does not increase node-cuts; otherwise
that group is reverted. Edges with manual waypoints / routing hints / detourY are
excluded. Render-only — operates on the transient `_renderedPolyline`, stored
geometry (`buildBpmnXml`) untouched (PD-044). Same family as T-117/118/119.

First prototype (render-only, guarded on crossings+cuts only, attach points moved
to node-face centres) appeared to give corpus **20 → 14**. **This figure was
retracted** — see ## Acceptance Criteria and ## Decisions. Relocating attach points
discards T-097's anchor spread (not a faithful render-only reroute) and worsens
overlap-pairs once that metric is added to the guard. The faithful, endpoint-
preserving, three-metric-guarded result is **20 → 18** (task-lifecycle only), and
visual verification shows even that is not a visual improvement. Outcome: NO-GO.

## Acceptance Criteria

> **Outcome: measured NO-GO — the shared-riser pass is NOT worth shipping.**
> The task was scoped to build the pass; rigorous render-only measurement +
> visual verification (below) established the safe, faithful win is marginal
> (2 crossings on 1 map) and not a visual improvement, so no source change was
> made. ACs below are the investigation deliverables that were actually
> completed. See ## Decisions for the NO-GO rationale.

### Agent
- [x] Corpus crossing census (headless, live editor, 24 maps): **20 proper
      crossings** classified — ~half topologically forced (bidirectional pairs
      e.g. task-lifecycle n_ready↔n_authoring; independent-edge crossings driven
      by node placement, fixable only by MOVING nodes = PD-044 out of scope);
      ~half fan/join anchor-ordering
- [x] Prototyped the shared-riser transform render-only, guarded per-group on
      three metrics (proper crossings ↓, overlap-pairs not ↑, node-cuts not ↑),
      endpoints preserved exactly. Faithful result: corpus **20 → 18** (−2),
      only `task-lifecycle` qualifies (fans n_ready+n_progress, 3→1 cross, 1→0
      overlap). An earlier 20→14 figure was REJECTED as inflated — it relocated
      attach points to node-face centres, discarding T-097 spread (not a faithful
      render-only reroute) and worsening overlap once measured
- [x] Visual verification: applied the transform live to task-lifecycle and READ
      before/after element screenshots (`.playwright-mcp/t120-tasklife-ready-
      {before,after}.png`). The reroute trades a subtle crossing for a **visible
      backtrack hook** where e_02 re-enters n_authoring (mixed-exit fan
      misclassified as horizontal) — metric win, not a visual win
- [x] Decision recorded (## Decisions): NO-GO. Do not add a permanent renderer
      post-pass for a marginal, geometrically-fragile, single-map, visually-neutral
      change (Reliability). T-097 already captured the high-value crossing/overlap
      reductions; residual crossings need node moves (out of render-only scope) or
      re-entering T-097's diminishing-returns anchor machinery (PL-005)
- [x] No source files changed — only investigation (browser measurement) + this
      task + evidence screenshots. buildBpmnXml/stored geometry untouched (PD-044)

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
(No Human AC — nothing shipped. NO-GO outcome; see ## Decisions. If the operator
wants the marginal task-lifecycle-only win anyway despite the backtrack hook,
that is a taste call for the human to raise — see the before/after screenshots.)

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
# NO-GO outcome — no source change. Verify the investigation left the tree clean:
# the editor and its gallery copy are untouched (still byte-identical), and the
# evidence screenshots exist.
diff -q src/aef-workflow-designer.html build/gallery/designer.html
test -f .playwright-mcp/t120-tasklife-ready-before.png
test -f .playwright-mcp/t120-tasklife-ready-after.png

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

### 2026-07-06 — NO-GO: do not ship a shared-riser render post-pass
- **Chose:** Do not add the pass. Close T-120 as investigated-not-built. Keep the
  editor unchanged.
- **Why:** Measured render-only, faithfully (endpoints preserved, guarded on
  crossings + overlap-pairs + node-cuts), the safe win is **corpus 20 → 18 proper
  crossings**, and only `task-lifecycle` qualifies. Visual verification (READ
  before/after screenshots) shows even that win is not a visual improvement — the
  reroute swaps a subtle crossing for a visible backtrack hook where e_02 re-enters
  n_authoring, because that fan is mixed-exit (one edge down, one right) and the
  horizontal-riser geometry misfits it. A permanent new pass in the hot render path,
  for −2 crossings on 1 map with no visual gain, is a bad Reliability trade.
- **Rejected:**
  (a) The inflated variant (relocate attach points to node-face centres) that showed
      20→14 — it discards T-097's anchor spread, is not a faithful render-only
      reroute, and worsens overlap-pairs once measured.
  (b) Pushing into proper join/fan anchor re-assignment to recover harvest /
      inception-review / eel — that re-enters T-097's spread+channel machinery
      (PL-005: don't reimplement router logic; T-097's own Decisions found
      diminishing returns and regressions there).
  (c) Moving nodes to uncross the topologically-forced independent crossings
      (git-commit-flow, tier0, verification-gate) — that mutates stored geometry
      on a render pass, violating PD-044.
- **Evidence:** `.playwright-mcp/t120-tasklife-ready-{before,after}.png`;
  in-browser guarded prototype over all 24 maps (crossing census + 3-metric guard).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-06 — investigated, NO-GO (agent, still owner:agent)
- Scoped as a build for the shared-riser pass; render-only measurement + visual
  verification turned it into a no-build decision. Corpus census 20 proper
  crossings; faithful guarded prototype yields 20→18 (task-lifecycle only) and the
  render is not visually improved (backtrack hook). No source changed. Decision
  recorded above. Task can be completed as investigated-not-built.
- Follow-on: the high-value crossing work is already shipped (T-097). The residual
  crossings are forced (bidirectional / node-placement) — a future improvement would
  be node-*placement* aware (moving nodes at bake time), not a render pass.

### 2026-07-06T05:47:15Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-120-sibling-shared-riser-uncross-fan-out-joi.md
- **Context:** Initial task creation

### 2026-07-06T05:58:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
