---
id: T-188
name: "Bridge-editor cross-seam round-trip: prove yaml-to-bpmn emission survives editor import without silent drop (G-002 half 2)"
description: >
  Bridge-editor cross-seam round-trip: prove yaml-to-bpmn emission survives editor import without silent drop (G-002 half 2)

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface, testing, round-trip]
components: []
related_tasks: [T-187, T-042, T-053]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-11T14:33:17Z
last_update: 2026-07-11T14:38:29Z
date_finished: 2026-07-11T14:38:29Z
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

# T-188: Bridge-editor cross-seam round-trip: prove yaml-to-bpmn emission survives editor import without silent drop (G-002 half 2)

## Context

The **second half** of G-002 (T-187 shipped the first). T-187 guards the editor-INTERNAL round
trip; this task guards the **JS↔Python cross-seam** — the concern's original motivation. Both
confirmed G-002 incidents were bridge→editor drifts: T-042 (editor import used a different aef:
namespace URI → every aef:uid/position silently dropped) and T-053 (editor read aef:decisionOutputs
as an attribute while the bridge emits element text → decision enum lost on import). The durable
fix the concern names is exactly `bridge YAML → yaml-to-bpmn.py → editor parseBpmnXml → editor
buildBpmnXml → re-validate`. Human ratified the node+chromium-in-suite portability decision and
GO'd this extension (2026-07-11, recorded on G-002). Reuses the T-187 CDP pattern (isolated
headless chromium, G-006). No new production code — a test harness only.

## Acceptance Criteria

### Agent
- [x] **Harness feeds real bridge emissions through the editor.** `tools/_bridge-seam-roundtrip-cdp.mjs` runs `python3 tools/yaml-to-bpmn.py` on every `examples/aef-processes/*.workflow.yaml`, then imports each resulting BPMN into the real editor (`parseBpmnXml`) in isolated headless chromium (own `--user-data-dir`, G-006). Empty/missing workflow set ⇒ FAIL (PL-022). Exits 0 all-pass, 1 on any drift, 2 on self-test failure.
- [x] **No silent drop on import (the cross-seam property).** For each bridge BPMN `B0`: every `aef:uid` present in the `B0` XML text appears on a node/edge in the editor's parsed model, and every governance `aef:meta` attribute (tier/agentType/owner/horizon/workflowType/decisionOwner/…) present in `B0` is present in the editor's projection. A bridge-emitted governance signal that the editor drops on import fails the workflow — this is precisely the T-042/T-053 class.
- [x] **Editor round trip on bridge output is a semantic fixed point.** After import, `buildBpmnXml → parseBpmnXml` again yields an equal uid-keyed semantic projection (as in T-187), so bridge output is stable under editor re-emit, not just importable once.
- [x] **Guard bites + suite integration.** A self-test perturbs one governance attr in a bridge emission and asserts the drop-detector flags it (non-vacuous). `tests/test_bridge_seam_roundtrip.py` runs the harness as a subprocess, asserting exit 0, and SKIPs loudly when chromium/node absent. `## Verification` runs the harness directly so P-011 exercises the real cross-seam.

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
# --- T-188 verification commands ---
test -n "$(ls examples/aef-processes/*.workflow.yaml 2>/dev/null)"
test -f tools/_bridge-seam-roundtrip-cdp.mjs
node tools/_bridge-seam-roundtrip-cdp.mjs
python3 tests/test_bridge_seam_roundtrip.py
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

### 2026-07-11 — cross-seam drop-detection design
- **What changed:** The cross-seam property can't be checked purely in Python (no Python BPMN
  parser) nor purely by comparing to YAML. The robust check is: count aef governance signals in
  the bridge's BPMN *text* (regex over aef:uid / aef:meta attrs) and assert the editor's parsed
  projection accounts for each — a bridge signal absent from the editor model = a silent drop
  (the T-042/T-053 class).
- **Plan impact:** Reuses T-187's CDP harness scaffold; adds a Python-side bridge-emit step and a
  text-vs-model drop comparison. No change to the editor or bridge.
- **Triggered:** none — closes the second half of G-002; on green both halves exist and the human
  can flip G-002 to resolved.

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

### 2026-07-11T14:33:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-188-bridge-editor-cross-seam-round-trip-prov.md
- **Context:** Initial task creation

### 2026-07-11T14:38:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
