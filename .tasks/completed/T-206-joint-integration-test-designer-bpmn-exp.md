---
id: T-206
name: "Joint integration test: designer .bpmn export -> AEF compile/promote -> gated
  fw task create"
description: >
  Joint integration test: designer .bpmn export -> AEF compile/promote -> gated fw
  task create

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
created: 2026-07-18T21:08:00Z
last_update: '2026-08-16T14:33:20Z'
date_finished: 2026-07-18T21:19:45Z
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
  - ts: '2026-08-16T14:33:20Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 0
      F2: 0
      F4: 4
      F3: 5
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=4 (prose:routing-structural); F3=5 
      (prose:seam-contract); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/fixtures/aef-bpmn/inception-gonogo.bpmn,tests/run-bridge-tests.sh,tests/test_promote_contract.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-206: Joint integration test: designer .bpmn export -> AEF compile/promote -> gated fw task create

## Context

The 832-side half of the joint compile→promote→`fw task create` seam, green-lit by AEF
(DM `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` offset 65; AEF reference test
`tests/unit/bpmn_promote_e2e.bats`, T-2545).

**Boundary reality (decisive):** T-559 is SYMMETRIC — 832 cannot run AEF's
`fw bpmn compile`/`promote`, and AEF cannot read 832's exports. So there is NO live
end-to-end run from either side. The seam is a **producer-contract test + shared fixture**:
832 proves its `.bpmn` export carries exactly the INPUTS AEF's compiler consumes; AEF proves
its promote/gate OUTPUTS on its side; the two halves meet at a byte-identical fixture + pinned sha.

**Boundary-honest scope split (do NOT invert):**
- 832 (this task) asserts producer INPUTS: stable namespaced `aef:uid` per owner-bearing node;
  exactly-one lane with defined `aef:laneMeta authority`; owner DERIVED from lane authority
  (IW-9, no node override); the manifest-read fields `name` / `workflow_type` / `horizon`
  extractable per node; and **byte-determinism** so AEF's reconcile key `(uid, source_bpmn_sha)`
  is stable (sha over the exact exported bytes recompute-equal to a pinned constant).
- AEF (its side, NOT asserted here) stamps the OUTPUTS: manifest write, `aef_provenance`
  block, materialized `owner:human`+`status:captured`, reconcile states (new/no-op/PROPOSE/ORPHAN),
  gate refusal. Writing 832-side assertions over these would build against the wrong contract.

**Canonical fixture:** `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` (authored FOR AEF's
forward-compiler slice-3, T-192). Two lanes (Human·sovereignty, Agent·initiative), 3 nodes;
one owner-bearing node `hum_1_inception` (subProcess, uid `n_inception`, workflowType `inception`,
sovereignty→owner `human`); start/end events `n_request`/`n_outcome` in the agent lane carry uids
but are not owner-bearing. NOTE the divergence from AEF's `two-lane-sample.bpmn` (which has an
Agent-lane owner-bearing *task*): surfaced to AEF on the rail as a fixture-convergence question —
does NOT block this test. See existing coverage: `test_designer_export_contract.py` (uid+lane
structural, editor), `test_designer_owner_derived.py` (owner-from-lane, editor),
`test_bridge_seam_roundtrip.py` (no-silent-drop). The GAP this task closes is the
manifest-tuple + byte-sha-stability contract over the shared `.bpmn` fixture.

## Acceptance Criteria

### Agent
- [x] New Python test `tests/test_promote_contract.py` exists, runs standalone as a `__main__` script (exit 0 pass / non-zero fail, matching the repo's other python tests), and is wired into `tests/run-bridge-tests.sh` (new "designer→AEF promote contract (T-206)" block)
- [x] Over the shared fixture, the test asserts for the owner-bearing node(s): non-empty stable `aef:uid`; referenced by exactly one lane with `aef:laneMeta authority` in the defined set; and the AEF manifest-read tuple is extractable — `name`, `workflow_type` (from `aef:meta workflowType`), and `owner` DERIVED from lane authority (sovereignty→human) via the canonical `validate-workflow.py §3` mapping (mirrored + drift-guarded, not forked), with NO node-level owner override (IW-9). Manifest for `inception-gonogo`: `{n_inception: {name, owner:human, workflow_type:inception}}`. `horizon` intentionally NOT asserted — absent from the export, AEF-defaulted manifest-side (documented in test header, not silently dropped)
- [x] The test asserts every uid-bearing node/edge carries a non-empty `aef:uid` — the reconcile key half `uid` is total over the fixture (n_request, n_inception, n_outcome, e_1, e_2)
- [x] Byte-determinism: the test computes sha256 over the exact fixture bytes, asserts it equals pinned `093858400716…`, AND asserts recompute-equality (stable `source_bpmn_sha`, the other reconcile key half)
- [x] Gate teeth: mutation (5a) blanking the sovereignty lane authority trips the canonical validator's O-3; mutation (5b) stripping a `uid` is caught by the totality + manifest checks — proving the test detects a broken producer, not just a happy path
- [x] Pure-Python bridge suite green — `bash tests/run-bridge-tests.sh` → 32 passed / 0 failed (includes the new test AND `test_bridge_aef_passthrough.py`, `test_editor_bridge_*` parity, corpus geometry). Browser/CDP-only tests (`test_designer_export_contract.py`, `test_designer_owner_derived.py`, `test_bridge_seam_roundtrip.py`) NOT run — unaffected: this task added a new test + a runner block + a task file only; it touched no `src/` and no shared/pre-existing test
- [x] Shared fixture + pinned sha256 delivered to AEF via `file_send` (xfer-mcp-3273116, sha256 093858400716…, 4314 bytes) and posted on the rail (DM offset 67) with the fixture-convergence question, for byte-exact cross-validation on AEF's side

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

# The producer-contract test must pass (deterministic, no browser needed).
python3 tests/test_promote_contract.py

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-18T21:08:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-206-joint-integration-test-designer-bpmn-exp.md
- **Context:** Initial task creation

### 2026-07-18T21:19:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
