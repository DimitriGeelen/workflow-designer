---
id: T-155
name: "Hierarchical tree grouping for Open-project map browser"
description: >
  Operator floated (tentative) reorganizing the flat Open-project grid into a hierarchical
  tree-style grouping. Larger redesign of openProjectModal. Backlog until prioritized.

status: captured
workflow_type: inception
owner: agent
horizon: later
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T15:01:59Z
last_update: '2026-08-16T12:33:25Z'
date_finished:
revisit_at: 2026-08-21
revisit_evidence_needed: "operator answers IW-1/IW-2; the recommendation (A1+B1+C1)
  is already written, so the only missing input is ratification"
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
  - ts: '2026-08-16T12:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-155: Hierarchical tree grouping for Open-project map browser

## Context

**This is an inception/exploration task** (converted from build 2026-07-10). The operator floated
— tentatively — reorganizing the flat Open-project card grid (`openProjectModal`) into a
hierarchical **tree-style grouping**. This is a larger redesign of the browser, so per pickup/
inception discipline it needs a design pass + a go/no-go decision before any build, not an
autonomous build.

**Deliverable of this inception:** a research artifact (`docs/reports/T-155-tree-grouping-inception.md`,
to be created at the start of the research session per C-001) that surveys the grouping design
space, recommends one approach, and presents a GO/NO-GO for the operator. After a GO, decompose
into separate build tasks.

**Known context (from this session's work on the browser):** a "map" in the browser carries: an
`id`, whether it is a **corpus baseline** (`examples/aef-processes/rendered/<id>.bpmn`) vs a
**user-saved** workflow (`.editor-versions/<id>/`), a thumbnail, and a saved-version history.
Handoff nodes (`linkEventThrow`/`linkEventCatch`) carry `aef.targetWorkflow`, giving an implicit
**cross-workflow graph**. These are the candidate grouping keys.

## Open Questions
<!-- Inception readiness (G-067): at least one IW-N entry required before source edits. -->
- **IW-1: What is the grouping key?** Options: (a) source — corpus vs saved; (b) id naming
  convention / prefix (e.g. `arc-*`, `frw_*`); (c) handoff-graph clusters (workflows that link to
  each other); (d) explicit user-assigned folders/tags (needs a new metadata field + save path).
  confidence: 1
  disposition: deferred   # resolve during research + operator dialogue
  rationale: TBD
- **IW-2: Tree vs. grouped-sections vs. collapsible folders?** Full tree (arbitrary depth) is a
  big build; grouped sections (one level of headers over the existing grid) may deliver 80% of the
  value at a fraction of the cost. Which does the operator actually want?
  confidence: 1
  disposition: deferred
  rationale: TBD
- **IW-3: Does grouping require persisted metadata** (folder/tag per workflow, round-tripped
  through save/serialization + the server), or can it be derived purely from existing data (source,
  id, handoff graph) with zero storage changes?
  confidence: 2
  disposition: deferred
  rationale: TBD — deriving from existing data is strongly preferred (no schema change).

## Recommendation

**Recommendation:** DEFER — pending operator input on IW-1/IW-2 (full survey in `docs/reports/T-155-tree-grouping-inception.md`).

Recommended shape once confirmed: **A1 (source class: corpus vs saved) + optionally A2 (id prefix)
as a second level, rendered as B1 (grouped collapsible sections over the existing card grid), C1
(derive-only — zero storage/schema change).**

- Delivers the scannability win at a fraction of the cost of a full tree; purely additive to
  `openProjectModal`, reuses the existing card renderer/hover-zoom/delete.
- No serialization/server changes → no round-trip risk, no new failure surface (Reliability).
- **Explicitly NOT recommended now:** A4+B2+C2 (user-defined nested folders with persisted
  metadata) — subsystem-scale change for a tentatively-floated feature; let real use of B1 tell us
  whether explicit folders are worth the storage complexity.
- On operator confirmation (expected A1+B1+C1): file ONE bounded build task ("grouped sections in
  openProjectModal, derived from source class") — not a subsystem redesign.

## Acceptance Criteria

### Agent
<!-- Inception ACs: exploration deliverables, not build criteria. Real build ACs come after GO. -->
- [ ] Research artifact `docs/reports/T-155-tree-grouping-inception.md` created (C-001) surveying the grouping design space and answering IW-1..IW-3.
- [ ] A recommended approach + GO/NO-GO/DEFER presented to the operator with rationale and a cost/scope estimate; decision recorded via `fw inception decide T-155 …`.
- [ ] On GO: follow-up build tasks filed (decomposed); no production UI built under this inception id.

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

**Decision**: DEFER

**Rationale**: Recommendation: DEFER — pending operator input on IW-1/IW-2 (full survey in `docs/reports/T-155-tree-grouping-inception.md`).

Recommended shape once confirmed: A1 (source class: corpus vs saved) + optionally A2 (id prefix)
as a second level, rendered as B1 (grouped collapsible sections over the existing card grid), C1
(derive-only — zero storage/schema change).

- Delivers the scannability win at a fraction of the cost of a full tree; purely additive to
  `openProjectModal`, reuses the existing card renderer/hover-zoom/delete.
- No serialization/server changes → no round-trip risk, no new failure surface (Reliability).
- Explicitly NOT recommended now: A4+B2+C2 (user-defined nested folders with persisted
  metadata) — subsystem-scale change for a tentatively-floated feature; let real use of B1 tell us
  whether explicit folders are worth the storage complexity.
- On operator confirmation (expected A1+B1+C1): file ONE bounded build task ("grouped sections in
  openProjectModal, derived from source class") — not a subsystem redesign.

**Date**: 2026-07-29T05:31:27Z

## Updates

### 2026-07-09T15:01:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-155-hierarchical-tree-grouping-for-open-proj.md
- **Context:** Initial task creation

### 2026-07-10T04:32:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-10T04:41:16Z — status-update [task-update-agent]
- **Change:** workflow_type: build → inception

### 2026-07-29T05:31:27Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** DEFER
- **Rationale:** Recommendation: DEFER — pending operator input on IW-1/IW-2 (full survey in `docs/reports/T-155-tree-grouping-inception.md`).

Recommended shape once confirmed: A1 (source class: corpus vs saved) + optionally A2 (id prefix)
as a second level, rendered as B1 (grouped collapsible sections over the existing card grid), C1
(derive-only — zero storage/schema change).

- Delivers the scannability win at a fraction of the cost of a full tree; purely additive to
  `openProjectModal`, reuses the existing card renderer/hover-zoom/delete.
- No serialization/server changes → no round-trip risk, no new failure surface (Reliability).
- Explicitly NOT recommended now: A4+B2+C2 (user-defined nested folders with persisted
  metadata) — subsystem-scale change for a tentatively-floated feature; let real use of B1 tell us
  whether explicit folders are worth the storage complexity.
- On operator confirmation (expected A1+B1+C1): file ONE bounded build task ("grouped sections in
  openProjectModal, derived from source class") — not a subsystem redesign.

### 2026-07-29T05:31:28Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)
- **Reason:** Inception decision: DEFER — parking task
