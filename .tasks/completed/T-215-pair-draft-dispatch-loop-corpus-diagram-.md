---
id: T-215
name: "Pair-draft dispatch-loop corpus diagram (AEF arc-015)"
description: >
  Pair-draft dispatch-loop corpus diagram (AEF arc-015)

status: work-completed
workflow_type: build
owner: human
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-19T21:21:33Z
last_update: '2026-08-16T14:33:20Z'
date_finished: 2026-07-19T21:39:39Z
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
  - ts: '2026-08-16T12:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:20Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/fixtures/aef-bpmn/dispatch-loop.bpmn,tests/fixtures/aef-bpmn/investigate.bpmn,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-215: Pair-draft dispatch-loop corpus diagram (AEF arc-015)

## Context

Arc: designer-authoring-surface (↔ AEF corpus arc-015). Pair-draft **#2**, taking up AEF's
standing invitation (rail offset 94, after their clean compile of pair-draft #1). 832 authors
a REAL framework process — the **Sub-Agent Dispatch Protocol** (CLAUDE.md §Sub-Agent Dispatch
Protocol) — as a BPMN diagram in the canonical dialect. Where pair-draft #1 (session-handover,
T-214) carried an exclusiveGateway + back-edge, this one deliberately exercises a
**parallelGateway fork/join** (fan-out to N≤5 sub-agents → join) that session-handover did not
— a fresh probe of AEF's `fw bpmn` parallel-branch handling. It also keeps a back-edge (the
completeness re-dispatch loop) and adds a human·sovereignty check-in (commit-cadence "report &
continue?"), so all three authority lanes carry a real role.

Semantics kept distinct from the existing `investigate.bpmn` fan-out fixture: this models the
DISPATCH mechanics specifically — scope (1 task = 1 deliverable), a framework headroom-reserve
gate (≥40K free), a parallel-vs-sequential MODE decision, the fan-out cap (≤5), collect via the
result-ledger (`fw bus manifest` — path+summary, size-gated ≥2KB→blob), synthesize, and a
completeness gateway that re-dispatches remaining work.

Dialect modelled on `tests/fixtures/aef-bpmn/investigate.bpmn` (the canonical parallelGateway
exemplar): three lanes (human·sovereignty / framework·authority / agent·initiative) with
`aef:laneMeta`; every flow node carries `aef:uid` + `aef:position`; typed nodes; `aef:uid` on
every sequenceFlow; balanced parallel fork/join with NO conditionExpression on parallel branches
(W-PGW-CONDITION/UNBALANCED/NOOP clean).

## Acceptance Criteria

### Agent
- [x] New fixture `tests/fixtures/aef-bpmn/dispatch-loop.bpmn` authored in the canonical dialect (3 authority-typed lanes; every flow node has `aef:uid` + `aef:position`; every sequenceFlow has `aef:uid`)
- [x] It validates CLEAN under `tools/validate-workflow.py` (exit 0, no findings) — including balanced parallel fork/join (no W-PGW-* WARN) and the O-3 sovereignty rule (the human check-in node sits in the sovereignty lane)
- [x] It faithfully models the dispatch protocol: scope → framework headroom gate → **mode exclusiveGateway** (parallel vs sequential) → **parallelGateway fan-out (≤5)** → sub-agent workers → **parallelGateway join** → collect-from-ledger → synthesize → **completeness exclusiveGateway** (re-dispatch back-edge vs done) → framework commit checkpoint → human check-in → end
- [x] Fixture is well-formed XML and byte-stable (sha `95bc24cd…43594b`, 18793 B); delivered to AEF rail-inline with its sha for their `fw bpmn` compile (rail offsets 99+101, concat-verified)

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
- [x] [REVIEW] The dispatch-loop diagram reads faithfully in the designer UI (the pair-draft review step)
  **Steps:**
  1. Open the designer at the served URL (see `.context/working/watchtower.url`), use in-editor Open-from-project (or load `tests/fixtures/aef-bpmn/dispatch-loop.bpmn`).
  2. Trace the flow: dispatch needed → scope deliverables → headroom gate (framework) → mode gateway → (parallel) fan-out → 3 sub-agent workers → join / (sequential) single worker → collect from ledger → synthesize → completeness gateway → (more) loops back to scope / (done) commit checkpoint → human check-in → end.
  3. Check the three lanes read correctly (human·sovereignty top, framework·authority middle, agent·initiative bottom) and the parallel fork/join renders as a clean fan-out/fan-in.
  **Expected:** The diagram is a recognisable, correct depiction of the Sub-Agent Dispatch Protocol; lanes/owners are right; the parallel fan-out/join + completeness back-edge render legibly.
  **If not:** Note the step that is wrong/missing or mis-laned; correct it in the UI (or tell me) and re-save.

## Recommendation

**Recommendation:** GO

**GO — accept the pair-draft, pending your UI read.** All agent-verifiable criteria pass: the
diagram validates CLEAN under the canonical validator (exit 0, no findings, incl. balanced
parallel fork/join and O-3 sovereignty), is well-formed and byte-stable (sha recorded in the
delivery), and was delivered to AEF rail-inline for their `fw bpmn` compile. It faithfully
models the Sub-Agent Dispatch Protocol across the three authority lanes with a parallel
fan-out/join and the completeness re-dispatch back-edge.

The one remaining step is the pair-draft's whole point: **your eyes on the rendered diagram**
in the designer (the `[REVIEW]` Human AC) — confirm it reads as a correct, legible depiction of
the dispatch protocol, and that the parallel fork/join renders cleanly. Evidence it's ready:
`tools/validate-workflow.py` clean; the designer is served (see `.context/working/watchtower.url`).
If it reads right, check the AC and run `fw task update T-215 --status work-completed`. Not
recommending closure without your UI read — validator correctness ≠ a faithful, legible diagram.

## Verification

# The authored diagram validates CLEAN under the canonical validator (exit 0, no findings):
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/dispatch-loop.bpmn
# It is well-formed XML:
python3 -c "import xml.etree.ElementTree as ET; ET.parse('tests/fixtures/aef-bpmn/dispatch-loop.bpmn')"
# It carries the required dialect markers (workflowMeta, a parallel fork/join, a mode gateway):
grep -q "aef:workflowMeta" tests/fixtures/aef-bpmn/dispatch-loop.bpmn
grep -q "parallelGateway" tests/fixtures/aef-bpmn/dispatch-loop.bpmn
grep -q "exclusiveGateway" tests/fixtures/aef-bpmn/dispatch-loop.bpmn

# --- template hints below (kept for reference) ---
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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-19T21:21:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-215-pair-draft-dispatch-loop-corpus-diagram-.md
- **Context:** Initial task creation

### 2026-07-19T21:39:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d0370151
- **Timestamp:** 2026-07-29T13:13:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
