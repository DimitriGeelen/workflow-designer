---
id: T-187
name: "Round-trip serialization harness: editor parse/emit idempotence (close G-002)"
description: >
  Round-trip serialization harness: editor parse/emit idempotence (close G-002)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [arc:designer-authoring-surface, testing, round-trip]
components: []
related_tasks: [T-175, T-183]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-11T14:14:16Z
last_update: '2026-08-16T12:33:42Z'
date_finished: 2026-07-11T14:22:20Z
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
  - ts: '2026-08-16T12:33:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-187: Round-trip serialization harness: editor parse/emit idempotence (close G-002)

## Context

Closes registered gap **G-002**: the editor↔bridge aef: serialization seam is guarded
aspect-by-aspect (7 static tests: meta-parity, field-coverage, structured-parity,
extension-shape, namespace, mapping-conformance, forward-fixtures) but **never by a true
round trip**. Only the editor JS (`parseBpmnXml` `src/aef-workflow-designer.html:7959`,
`buildBpmnXml` `:7830`) can parse BPMN back into a re-emittable model — the Python bridge is
emit-only — so a genuine round trip is reachable only by driving the real editor runtime in a
browser. This harness does that (isolated headless chromium via `gallery-serve.py`, mirroring
the `tools/_*-cdp.mjs` pattern; respects G-006) and asserts the seam is a **semantic fixed
point**: `parse → emit → parse` preserves aef:uid identity, aef:meta governance, node/edge
topology, and lane authority. Supports the **designer-authoring-surface** arc — child-2
(forward bridge) and future child-3 (reverse bridge) both rest on round-trip safety. Related
learning **PL-005** (editor/bridge can drift on ANY aef aspect) is the standing motivation.

No new production code — a test harness only.

## Acceptance Criteria

### Agent
- [x] **Harness exists and boots the real editor in isolation.** `tools/_roundtrip-serialization-cdp.mjs` serves `src/aef-workflow-designer.html` via `gallery-serve.py` on a free port and drives it in an **isolated** headless chromium (own `--user-data-dir`, never the shared browser — G-006). Exits 0 on success, 1 on any round-trip defect, and prints a JSON verdict with per-fixture steps.
- [x] **Every fixture round-trips as a semantic fixed point.** For each `tests/fixtures/aef-bpmn/*.bpmn`: load it via the editor's real import path, re-emit via `buildBpmnXml`, re-import the emission, and assert the semantic projection of `parse(fixture)` equals the projection of `parse(emit(parse(fixture)))`. The harness gates (exit 1) if any fixture's projection drifts across the round trip. Empty/missing fixtures dir ⇒ FAIL, not a vacuous pass (PL-022).
- [x] **The projection covers the governance-bearing content.** Equality is asserted structurally over: the aef:uid multiset (every flow node + every sequenceFlow), each node's aef:meta key→value map, node-type counts, the edge source→target set, and per-lane `authority`. A drift in any one fails the fixture. `buildBpmnXml` determinism is separately asserted (`emit(s)===emit(s)`); a byte-level emit1≠emit2 is surfaced in the verdict even when the semantic projection holds.
- [x] **Suite integration + Verification gate green.** `tests/test_roundtrip_serialization.py` invokes the harness as a subprocess and asserts exit 0; when chromium is unavailable it SKIPs with an explicit reason (loud, not a silent green). The `## Verification` block runs the harness directly (chromium is present in this env) so P-011 exercises the real round trip.

### Human
<!-- All criteria are agent-verifiable (harness exit code + structural assertions). No human AC. -->
_None — all acceptance is agent-verifiable via the harness and its Verification commands._

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
# --- T-187 verification commands ---
test -d tests/fixtures/aef-bpmn && test -n "$(ls tests/fixtures/aef-bpmn/*.bpmn 2>/dev/null)"
test -f tools/_roundtrip-serialization-cdp.mjs
node tools/_roundtrip-serialization-cdp.mjs
python3 tests/test_roundtrip_serialization.py
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

### 2026-07-11 — scoping (Explore-agent) settled build vs inception
- **What changed:** Confirmed the bridge (`tools/yaml-to-bpmn.py`) is emit-only (YAML→BPMN);
  there is NO Python BPMN parser. The only re-emittable BPMN parser is the editor JS
  `parseBpmnXml`. So a *true* round trip is reachable only by driving the real editor runtime
  (browser), not by a pure-stdlib Python test.
- **Plan impact:** Ruled out a pure-Python round-trip harness (would require a second parser
  implementation → drift/false-green hazard, and is inception-scale). Chose the browser-driven
  CDP path reusing the established `tools/_*-cdp.mjs` pattern — no new production code.
- **Triggered:** none — contained to this build task. G-002 closes on green; if AEF's pending
  enrichment/tier rulings later reshape the *proposal graph*, that is downstream of this seam
  and does not invalidate the round-trip guard.

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

### 2026-07-11T14:14:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-187-round-trip-serialization-harness-editor-.md
- **Context:** Initial task creation

### 2026-07-11T14:22:20Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
