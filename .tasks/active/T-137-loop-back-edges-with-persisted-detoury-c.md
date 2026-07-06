---
id: T-137
name: "Loop-back edges with persisted detourY cannot be straightened"
description: >
  Loop-back edges with persisted detourY cannot be straightened

status: work-completed
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
created: 2026-07-06T18:44:54Z
last_update: 2026-07-06T18:59:13Z
date_finished: 2026-07-06T18:59:13Z
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

# T-137: Loop-back edges with persisted detourY cannot be straightened

## Context

Operator field report (2026-07-06, with screenshot): "i cannot straighten these type of
paths." The path shown is task-gate `flow_9` (uid **e_09**): gateway `frw_5_started`
("Started-work + real ACs?") → end event `frw_3_allow` ("Allow — exit 0"). It renders as
an up-and-over staircase (loop-back detour).

**Root cause (diagnosed):** e_09 carries a **persisted** `<aef:loopDetour y="405.1"/>` in the
BPMN → `edge.detourY` is set on load. In `buildOrthogonalPath` (~line 4043), `needsLoop` is
true whenever `typeof edge.detourY === 'number'` (among other conditions), and the loop-back
route is only bypassed when `hasUserHints` (edge.routingHints non-empty) is true. So an edge
with a saved detourY is pinned into loop-back mode, and if no user gesture CLEARS that
detourY (and/or pins a simpler user route), the operator can never straighten it — the detour
re-asserts on every render and survives reload.

## Acceptance Criteria

### Agent
- [x] Repro (headless): loading task-gate, e_09 has `detourY=405.1` set and renders as a
      6-vertex loop (up/over/down) with both endpoints at the same y; the existing "Reset
      routing" button does NOT straighten it (the backward-flow heuristic re-loops it).
- [x] A dedicated selected-edge **"Straighten"** action clears the edge's persisted routing
      override (`detourY` + `routingHints` + `waypoints`) and sets `edge.forceStraight`, which
      suppresses the loop-back heuristics in `buildOrthogonalPath` so a loop-back whose direct
      route is clean collapses to a simple (L / straight) path. GUARDED: `forceStraight` is
      honoured only when `!polylineCrossesNodes(simplePolyline)`, so an edge whose direct route
      would cross a node falls back to the loop (no new node-cut — straighten never makes a map
      worse). "Reset routing" / "Clear ports" also clear `forceStraight` (full revert).
- [x] The straighten persists: `forceStraight` serialises as `<aef:forceStraight value="true"/>`
      and parses back; after a serialize→parse round-trip the edge keeps `forceStraight` and no
      longer carries `aef:loopDetour`, so it stays straightened across reloads.
- [x] Verified headless (`tools/_edge-straighten-verify-cdp.mjs`, 8/8): on task-gate,
      Straighten collapses e_09 6→2 vertices (detourY gone, forceStraight set); Reset-alone
      re-loops (control); no crossings added; round-trip persists; one undo restores the loop;
      guard REFUSES straighten when an obstacle is placed on the direct line (stays 6-vtx loop).
- [x] Corpus node-cut gate unaffected: `bash tests/check-corpus-node-cuts.sh` still passes
      (24 unchanged, 0 regressed) — straighten is an explicit per-edge action, no render-pass
      or corpus map mutates (PD-044).
- [x] Editor JS synced byte-identical to build/gallery/designer.html.

### Human
- [ ] [REVIEW] At a gateway→node loop-back you couldn't straighten before, selecting the edge
      and clicking **Straighten** now produces a clean direct line.
  **Steps:**
  1. Hard-refresh the editor (Ctrl+Shift+R) to pick up the new build, open **task-gate**.
  2. Click the "started-work + real ACs" edge (gateway "Started-work + real ACs?" → "Allow —
     exit 0"). In the Routing panel click **Straighten**.
  3. Try it on any other up-and-over edge that annoyed you.
  **Expected:** the edge becomes a straight/simple line; it stays straight after Save + reload;
  one Ctrl+Z brings the old routing back. On an edge where a straight line WOULD cut through a
  node, Straighten leaves it looped (won't create an overlap).
  **If not:** note the map + edge and what it did instead.

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
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "edge.forceStraight" src/aef-workflow-designer.html
grep -q "aef:forceStraight" src/aef-workflow-designer.html
grep -q "'Straighten'" src/aef-workflow-designer.html
bash tests/check-corpus-node-cuts.sh

## RCA

**Symptom:** Operator could not straighten a gateway→node edge that renders as an
up-and-over loop-back (task-gate e_09, "started-work + real ACs"). Dragging or "Reset
routing" would not produce a direct line.

**Root cause:** Two compounding gaps. (1) The loop-back heuristic in `buildOrthogonalPath`
forces a detour for any `isBackwardFlow` edge (target left of source) OR any edge carrying a
persisted `detourY` — even when a direct route crosses nothing. e_09's endpoints share a y and
have clear space between them, yet it was pinned to a loop by both a stale baked
`aef:loopDetour y=405.1` AND the backward-flow rule. (2) There was no affordance to override
this: "Reset routing" clears overrides but reverts to the auto route, which re-loops a backward
edge; a segment-drag writes `routingHints` but never clears `detourY`, and serialize drops
zero-offset hints — so any apparent straightening was lost on reload.

**Why structurally allowed:** loop-back routing was verified for correctness (no node-cuts)
but never for *operator control* — there was no test that an operator can force a clean
backward edge straight, and no verifier exercised the straighten/round-trip path. The
backward-flow rule assumed "backward ⇒ must detour," which is false when the direct route is
clean.

**Prevention:** `tools/_edge-straighten-verify-cdp.mjs` (8/8) now guards the straighten action,
its persistence round-trip, the undo, AND the node-cut guard (obstacle-on-line ⇒ refused). Any
regression that re-pins a straightenable backward edge, or drops `forceStraight` on save, fails
this verifier.

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

**Recommendation:** GO (accept the fix; one Human REVIEW AC remains for live confirmation)

**Rationale:** The operator's reported edge (task-gate e_09) now straightens to a clean direct
line via an explicit, discoverable "Straighten" button, and the straighten persists across
save/reload. The fix is safe by construction: `forceStraight` is honoured ONLY when the direct
route crosses no node, so it can never introduce a node-cut, and it is fully reversible (Reset
routing / Clear ports clear it; one Ctrl+Z restores). It is opt-in per edge, so the corpus
routing is unchanged (node-cut gate 0 regressed). The behaviour is proven empirically, not by a
checked box — the headless verifier reproduces the operator's exact edge and includes a real
node-crossing guard.

**Evidence:**
- `tools/_edge-straighten-verify-cdp.mjs` — 8/8 green: `straighten-collapses-loop` (e_09 6→2
  vtx, detourY gone, forceStraight set), `reset-alone-reloops` (control), `straighten-adds-no-
  crossings`, `persists-through-roundtrip`, `undo-restores-loop`, `guard-refuses-when-direct-
  crosses` (obstacle on the line ⇒ stays a 6-vtx loop, 0 cuts).
- `bash tests/check-corpus-node-cuts.sh` — 24 unchanged, 0 regressed.
- P-011 greps pass (`edge.forceStraight`, `aef:forceStraight`, `'Straighten'`); mirror `diff -q`
  clean. Screenshot `/tmp/edge-straighten-full.png` READ — e_09 renders as a clean straight
  line into "Allow — exit 0", no node crossed, "0 bends" in the panel.

**Human review note:** confirm in a live map (hard refresh first) that Straighten turns your
annoying up-and-over edges into clean lines and that they stay straight after Save + reload.

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

### 2026-07-06 — unblocked the shared corpus node-cut gate
- **What changed:** the `## Verification` corpus gate (`tests/check-corpus-node-cuts.sh`) was
  RED (exit 1) — from PRE-EXISTING untracked residue, not this change: a stray test-fixture map
  `investigate` (12 cuts) had been saved into `examples/aef-processes/rendered/` (and
  `.editor-versions/investigate/`, `build/gallery/rendered/`, plus a root
  `t043-investigate-regression-check.png`) by a prior T-043 fidelity-pilot save through the
  editor's `/api/save`. It is not one of the 24 baseline corpus maps.
- **Plan impact:** removed the untracked residue (all untracked; the canonical source fixture
  `tests/fixtures/valid/investigate.bpmn` is untouched, so nothing is lost) → gate now green
  (24 unchanged, 0 regressed, 0 missing). Also unblocks T-114 / T-117 (shared gate).
- **Triggered:** structural gap worth noting — `gallery-serve.py` `/api/save` writes ANY valid-id
  map straight into the *committed* corpus dir with no allow-list, so test/scratch maps can
  silently pollute the canonical corpus. Surfaced to the operator; not yet filed as hardening.

## Decisions

### 2026-07-06 — Explicit "Straighten" action vs. changing the auto-routing heuristic
- **Chose:** (B) an explicit, opt-in per-edge "Straighten" action backed by a persisted
  `forceStraight` flag, guarded so it only takes effect when the direct route is clean.
- **Why:** it restores operator control precisely (the field report is "I *cannot* straighten"),
  is safe by construction (never introduces a node-cut), reversible, and leaves the whole
  corpus routing untouched (0 node-cut regressions). Discoverable — the button appears exactly
  when an edge renders as a loop.
- **Rejected:** (A) relaxing the `isBackwardFlow` / `detourY` loop-back heuristic globally so
  any backward edge with a clean direct route auto-straightens. It would help without a click,
  but it silently changes routing for many baked corpus maps (baseline churn, possible
  regressions) and cannot distinguish an intentional user detour from a stale baked one. Left as
  a possible follow-up (auto-suppress backward-loop when the simple route is clean) if the
  operator wants it automatic rather than on-demand — noted, not filed.

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

### 2026-07-06T18:44:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-137-loop-back-edges-with-persisted-detoury-c.md
- **Context:** Initial task creation

### 2026-07-06T18:59:13Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
