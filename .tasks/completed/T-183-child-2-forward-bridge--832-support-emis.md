---
id: T-183
name: "Child-2: Forward bridge — 832 support (emission spec + reference fixtures for
  AEF translator)"
description: >
  arc: designer-authoring-surface child-2 (forward bridge), GO'd by operator 2026-07-11.
  AEF-LED build (translator + enrichment + sovereignty gate). 832's supporting deliverable:
  (a) confirm the editor emits the full v1 semantic vocabulary + stable aef:uid (already
  shipped), (b) provide AEF a reference BPMN fixture set + the forward-compile spec
  derived from docs/standards/aef-bpmn-mapping-v1.md, (c) modify-vs-create semantics
  doc (uid-resolves test). Not started — teed up; depends on child-1 standard (done,
  T-182).

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
created: 2026-07-11T05:30:52Z
last_update: '2026-08-16T13:57:18Z'
date_finished: 2026-07-11T11:49:17Z
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
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/standards/aef-bpmn-forward-compile-v1.md,docs/standards/aef-bpmn-mapping-v1.md,src/aef-workflow-designer.html,tests/test_editor_bridge_meta_parity.py);
      tier=2 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-183: Child-2: Forward bridge — 832 support (emission spec + reference fixtures for AEF translator)

## Context

arc: designer-authoring-surface, child-2 (forward bridge), GO'd 2026-07-11. The forward
translator + enrichment + sovereignty gate are **AEF-led** (child-2 proper). This task is
832's *supporting* deliverable so AEF has an unambiguous target: reference BPMN(+aef:)
fixtures, a forward-compile spec, and the modify-vs-create rule — all derived strictly from
the frozen `docs/standards/aef-bpmn-mapping-v1.md` (child-1, T-182). No translator is built
here. Grounds: the v1 standard §3 (forward table) and §5 (aef:uid identity).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Reference BPMN(+aef:) fixture set under `tests/fixtures/aef-bpmn/` with at least one
      fixture covering each v1 §3 forward-mapping row present in the editor's vocabulary
      (userTask, serviceTask, scriptTask, exclusiveGateway, parallelGateway, subProcess,
      lane→owner, sequence-flow dependency). Every node AND edge carries a stable `aef:uid`;
      governance scalars are carried as `aef:meta` attributes. All fixtures are well-formed XML.
- [x] Forward-compile spec published at `docs/standards/aef-bpmn-forward-compile-v1.md`: for
      each fixture, the expected **proposed** task/inception-YAML graph (fields, owner, workflow_type,
      dependencies), derived only from v1 §3; states the modify-vs-create rule (aef:uid resolves to
      an existing task ⇒ modify proposal; absent ⇒ create) per v1 §5; explicitly marks the output as
      a *proposal* requiring one sovereignty approval (IW-1/IW-3), never silently authored.
- [x] Fixture-conformance test `tests/test_forward_fixtures.py` (pure stdlib) asserts: every
      fixture parses as XML; every flow node AND sequence flow carries a non-empty `aef:uid`; every
      `aef:meta` attribute key is within the editor/bridge metaKeys vocabulary (reuses
      `bridge_meta_keys` from `test_editor_bridge_meta_parity` — typo/unknown-key guard); and the
      governance contract is demonstrably *exercised* across the set — node scalars `tier` + `agentType`
      appear as `aef:meta`, and `owner` is exercised via lanes (`aef:laneMeta`). (`horizon`/`workflowType`
      are authored-optional and legitimately absent from these process fixtures — noted in the spec.)
      Missing/empty fixtures dir ⇒ FAIL (no vacuous pass).
- [x] Editor-emission confirmation recorded in the spec: `src/aef-workflow-designer.html` already
      emits the full v1 semantic vocabulary + stable `aef:uid`, evidenced by green
      `tests/test_editor_bridge_meta_parity.py` (T-060) and `tests/test_mapping_standard_conformance.py`
      (T-182). No editor change is required for child-2's 832 side.

<!-- No ### Human section: all criteria are structural/agent-verifiable (files exist, parse,
     tests green, keys within the frozen v1 set). Semantic fitness of the spec is validated by
     AEF as the consumer over termlink thread T-175 — cross-repo, not gateable here. -->

## Verification

# Fixtures dir exists and is non-empty
test -d tests/fixtures/aef-bpmn && test -n "$(ls -A tests/fixtures/aef-bpmn)"
# Forward-compile spec published
test -f docs/standards/aef-bpmn-forward-compile-v1.md
# Fixture-conformance test passes (parse + aef:uid + frozen-key membership)
python3 tests/test_forward_fixtures.py
# Standard↔implementation parity still green (child-1 guard, must not regress)
python3 tests/test_mapping_standard_conformance.py

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

### 2026-07-11 — fixture strategy: curate authentic editor output, not hand-authored
- **What changed:** planned to hand-author minimal BPMN fixtures; discovered `.editor-versions/*/v*.bpmn`
  holds real editor emissions. Curating 4 authentic diagrams (arc-lifecycle, harvest-pipeline, investigate,
  resume-status) covers all 8 v1 §3 rows AND guarantees conformance for free (they *are* what the AEF
  translator will receive), which hand-authored fixtures cannot.
- **Plan impact:** the fixture-conformance test asserts `aef:meta` keys ⊆ the **bridge META_KEYS whitelist**
  (not ⊆ the frozen-5) — real fixtures legitimately use the broader ~12-key editor vocabulary (state, gate,
  triggeredBy…). `owner` is exercised via lanes, not node meta; `horizon`/`workflowType` are authored-optional
  and absent here. AC#3 reworded to match.
- **Triggered:** no new sub-tasks. Note: this build ran under a session mis-bound to /opt/023 (PROJECT_ROOT
  inherited across a reused Claude process) — cleared by relaunch; flagged to ring20 as a fw path-isolation gap.

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

### 2026-07-11T05:30:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-183-child-2-forward-bridge--832-support-emis.md
- **Context:** Initial task creation

### 2026-07-11T11:39:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-11T11:49:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
