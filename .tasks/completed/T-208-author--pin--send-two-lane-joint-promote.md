---
id: T-208
name: "Author + pin + send two-lane joint promote fixture to AEF"
description: >
  Author + pin + send two-lane joint promote fixture to AEF

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
created: 2026-07-19T08:55:16Z
last_update: '2026-08-16T13:58:50Z'
date_finished: 2026-07-19T15:42:48Z
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
  - ts: '2026-08-16T12:33:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=1 (body/components:prompt-incidental); F1=0 (no-signal); 
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/fixtures/aef-bpmn/two-lane-joint.bpmn,tests/test_roundtrip_serialization.py,tests/test_two_lane_joint_contract.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:50Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/fixtures/aef-bpmn/two-lane-joint.bpmn,tests/test_roundtrip_serialization.py,tests/test_two_lane_joint_contract.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-208: Author + pin + send two-lane joint promote fixture to AEF

## Context

AEF asked (rail offset 69, option (a), joint-fixture convergence) for a canonical
two-lane joint fixture authored + pinned by 832 (serialization source-of-truth). The
proven shared fixture `inception-gonogo.bpmn` exercises only sovereignty→owner:human
derivation (its single owner-bearing node is the human-lane subProcess; agent-lane nodes
are events). AEF's `bpmn_promote_e2e.bats` seam-slice needs a fixture that ALSO exercises
initiative→owner:agent — i.e. an owner-bearing TASK in BOTH a Human/sovereignty lane and
an Agent/initiative lane. This task authors that fixture in the exact editor-export shape,
verifies it three ways (validator-clean, round-trip fixed point, manifest tuples), pins
its sha256, and sends it to AEF under its OWN distinct transfer_id (never back-to-back
with another send — PL-039). Arc: designer-authoring-surface. Feeds AEF T-2546/T-2545.

## Acceptance Criteria

### Agent
- [x] New fixture `tests/fixtures/aef-bpmn/two-lane-joint.bpmn` authored in the canonical editor-export shape: namespaced `<aef:uid>` on every flow node AND every edge; `<aef:laneMeta authority=…>` per lane; no node-level owner override (IW-9)
- [x] Fixture has an owner-bearing task in BOTH lanes: `hum_1_inception` (subProcess) in the `authority="sovereignty"` lane → owner:human, and `agt_2_plan` (serviceTask) in the `authority="initiative"` lane → owner:agent
- [x] Fixture validates CLEAN under `tools/validate-workflow.py` (exit 0 — O-3 sovereignty + shape)
- [x] Fixture is a round-trip fixed point in the REAL editor (`test_roundtrip_serialization.py`: two-lane-joint.bpmn ok:true, projEqual, deterministic, 0 missing uids)
- [x] Manifest extraction (reuses `test_promote_contract.py` helpers) yields BOTH owner-bearing tuples — n_inception{owner:human←sovereignty, wf:inception} and n_plan{owner:agent←initiative, wf:build}; uid-totality holds; teeth verified (`tests/test_two_lane_joint_contract.py`, wired into run-bridge-tests.sh, 34/0)
- [x] sha256 pinned: `efb53839bfddeb44c12bf0d8e11198c4394b017f55f0e0e238eb2524271a8c92` (5491 bytes), recompute-stable
- [x] Fixture delivered to `aef` under a DISTINCT id AND durably inline: CLI `termlink file send` (per-process id `xfer-2296252-1784465566631`) + a durable `channel post` artifact envelope at rail offset 75 (base64 payload, `sha256=efb53839…` in metadata) — the byte-exact-handoff path preferred over MCP file_send (PL-033/PL-039). Rail notices posted (offsets 74, 76) with pin + verify request (ok:true ≠ delivered)

<!-- NOT an agent AC — externally gated on AEF: AEF sha-verifies the reassembled fixture
     and adopts it as the canonical joint fixture, then drives its bpmn_promote_e2e.bats
     seam-slice off it. Tracked on the rail; this task's agent ACs complete when the
     fixture is authored+verified+pinned+sent, mirroring T-207's hub-accepted honesty. -->

<!-- No human AC — the fixture is fully agent-verifiable (validator + round-trip + manifest).
     AEF adoption is external, tracked on the rail, not a Human AC here. -->

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

# 1. Fixture validates clean under the canonical validator (O-3 + shape).
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/two-lane-joint.bpmn
# 2. Manifest tuples + uid-totality: BOTH owner:human←sovereignty AND owner:agent←initiative.
python3 tests/test_two_lane_joint_contract.py
# 3. Round-trip fixed point in the real editor (env-skips loudly if no browser).
python3 tests/test_roundtrip_serialization.py
# 4. sha256 matches the pin (recompute-stable, == the byte AEF cross-validates).
test "$(sha256sum tests/fixtures/aef-bpmn/two-lane-joint.bpmn | cut -d' ' -f1)" = "efb53839bfddeb44c12bf0d8e11198c4394b017f55f0e0e238eb2524271a8c92"

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

### 2026-07-19 — delivery mechanism: session-constant id → CLI → durable inline
- **What changed:** The MCP `file_send` mints ONE transfer_id per session (not per-send), so
  the fixture send drew the same `xfer-mcp-3313260` as T-207's 0.3.0 send. I initially feared
  a re-blend and over-corrected on the rail (offset 73) before reading AEF's already-posted
  71/72 — which showed the 0.3.0 had already landed clean from that id (AEF had drained it
  before my second send). Corrected the record (offset 74). Delivered the fixture robustly:
  CLI `termlink file send` (per-process id `xfer-2296252`) + a durable `channel post` artifact
  envelope (offset 75, base64 + sha256 metadata) — the PL-033/line-222 byte-exact path.
- **Plan impact:** Send AC reworded from "MCP file_send under distinct id" to the durable-inline
  + CLI delivery actually used. Task stays open pending AEF's fixture sha-confirm/adoption.
- **Triggered:** PL-039 corrected (session-constant id nuance + delivery preference order);
  PL-040 added (read latest inbound before posting an async-rail correction).

### 2026-07-19 — authoring by minimal extension of the proven fixture
- **What changed:** Rather than author a fresh two-lane workflow from scratch (higher risk
  of a shape the editor round-trips differently), I extended the proven `inception-gonogo`
  shape — kept the human/sovereignty inception subProcess verbatim, added one
  agent/initiative `serviceTask` (`agt_2_plan`, workflowType=build) and rewired the three
  edges. This reuses vocabulary already verified as a round-trip fixed point.
- **Plan impact:** None to the ACs; confirmed the geometry sweep (`check-corpus-geometry.sh`)
  scopes only `examples/aef-processes/`, so fixture node positions are not gated there — the
  round-trip harness (auto-globs `tests/fixtures/aef-bpmn/*.bpmn`) is the geometry-relevant gate.
- **Triggered:** New contract test `tests/test_two_lane_joint_contract.py` (both-lane owner
  derivation + teeth), wired into run-bridge-tests.sh (34/0). No new sub-tasks.

### 2026-07-19 — AEF confirmed + adopted; fixture caught a real defect (external gate SATISFIED)
- **What changed:** AEF (fp 0e7ee6ca) confirmed on the rail (offsets 77–78): `file_receive`'d
  the fixture under the distinct CLI id `xfer-2296252-1784465566631`, **independently sha256'd
  the landed bytes** (explicitly did not trust the tool self-report) = `efb53839…`, **5491
  bytes == the pin**, and adopted it as `tests/fixtures/bpmn/two-lane-joint.bpmn` (their
  canonical joint fixture). Compiler owner-derivation confirmed on the staged manifest:
  `n_inception` (sovereignty)→owner:human/inception, `n_plan` (initiative)→**owner:agent**/build
  — the initiative→agent leg this fixture uniquely enables, present pre-gate.
- **The fixture earned its keep:** driving it through the REAL promote gate surfaced a genuine
  defect on AEF's side — `fw bpmn promote` could not materialize the inception node
  (`create_via_gate` delegated to `fw task create --type inception` with no
  `--recommendation`/`--rationale`, so the T-2204 recommendation-completeness gate refused it).
  It was the FIRST inception node driven through the real gate end-to-end; AEF's prior e2e
  (no inception node; mocked gate) never caught it. AEF captured it as L-504, fixed in T-2549,
  and proved the seam GREEN end-to-end: `bpmn_promote_e2e.bats` 5/5, `test_bpmn_promote.py`
  16/16, landed on AEF master (`cf05c2074`). The initiative→agent leg is now proven through
  the full chain (compiler derives owner:agent from the initiative lane; G2 gate overrides to
  owner:human at materialization) — a path the single-node `inception-gonogo` fixture cannot reach.
- **Plan impact:** The external gate this task was held open for is SATISFIED (recipient
  sha-confirmed + adopted + drove the seam-slice green). T-208 completes.
- **Triggered:** New AEF proposal (offset 78) — "your compile→promote→create integration test
  from the 832 side" against the contract pinned in AEF `tests/unit/bpmn_promote_e2e.bats`.
  Per G-020 this is a PROPOSAL, not a build instruction; captured as a separate task for
  scope assessment (T-559 symmetric boundary means it is a 832-side producer-contract test,
  not a live e2e). PL added: a joint fixture with an owner-bearing node per authority lane
  surfaces real cross-repo gate defects the single-node fixture cannot reach.

## Decisions

### 2026-07-19 — which bytes to pin as the canonical joint fixture
- **Chose:** Pin the hand-authored `.bpmn` file (5491 bytes, sha `efb53839…`), authored in
  the same style as the proven `inception-gonogo.bpmn` (comments + pretty-print), not the
  editor's `buildBpmnXml` raw output (4601 bytes).
- **Why:** The established convention IS hand-authored fixtures — `inception-gonogo.bpmn`
  is hand-authored-with-comments and AEF adopted exactly those bytes as byte-exact
  (T-2535/T-2536, sha `0938584…`). AEF's `bpmn_promote_e2e.bats` reads the raw `.bpmn` XML
  directly (never through 832's editor), so the manifest tuple it consumes comes from the
  authored bytes — which the contract test verifies. The round-trip harness independently
  proves 832's editor consumes the file as a clean semantic fixed point (projEqual,
  deterministic), so "editor-canonical shape" is satisfied without pinning the editor's
  whitespace-minimal output.
- **Rejected:** Pinning the editor's `buildBpmnXml` output — it strips the explanatory
  comment block and `workflowMeta`, diverges from the sibling-fixture convention, and buys
  no contract value since AEF reads raw XML.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-19T08:55:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-208-author--pin--send-two-lane-joint-promote.md
- **Context:** Initial task creation

### 2026-07-19T15:42:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
