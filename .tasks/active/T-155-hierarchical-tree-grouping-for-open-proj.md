---
id: T-155
name: "Hierarchical tree grouping for Open-project map browser"
description: >
  Operator floated (tentative) reorganizing the flat Open-project grid into a hierarchical
  tree-style grouping. Larger redesign of openProjectModal. Backlog until prioritized.

status: started-work
workflow_type: inception
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T15:01:59Z
last_update: 2026-09-20T10:30:57Z
date_finished:
revisit_at: 2026-08-21
revisit_evidence_needed: "NONE OUTSTANDING -- the evidence arrived 2026-09-20. IW-1/IW-2/IW-3
  are all disposition: answered, measured against the corpus rather than recalled, and the
  recommendation is no longer A1+B1+C1 (DEFER) but NO-GO. Nothing is being waited on except
  the operator running `fw inception decide T-155 no-go --rationale ...`."
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
  - ts: '2026-08-16T14:32:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 
      (paths:docs/reports/T-155-tree-grouping-inception.md); tier=4 (no-signal);
      effort=8 (no-signal)
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
  confidence: 3
  disposition: answered
  rationale: measured 2026-09-20 (artifact §Measured against the corpus). (c) handoff-graph is
    DEAD — `targetWorkflow` in 0 of 24 rendered files, `linkEvent` in 0 of 24; there is no
    cross-workflow graph to cluster. (b) id-prefix is DEAD — splitting 48 ids yields one prefix
    with 5 members (the `claim-smoke-*` probes) and the rest at 1-2, i.e. ~20 groups over 48
    items. Only (a) source class survives, and it has exactly two values.
- **IW-2: Tree vs. grouped-sections vs. collapsible folders?** Full tree (arbitrary depth) is a
  big build; grouped sections (one level of headers over the existing grid) may deliver 80% of the
  value at a fraction of the cost. Which does the operator actually want?
  confidence: 3
  disposition: answered
  rationale: dissolved by IW-1. With (b) and (c) gone the only data-backed key is two-valued, and
    a tree control over a two-valued key is a section header with extra machinery. Grouped
    sections win by default — but see the Recommendation: the measurement says the browser's
    problem is duplication (48 cards, 33 distinct workflows, 15 shown twice), not depth.
- **IW-3: Does grouping require persisted metadata** (folder/tag per workflow, round-tripped
  through save/serialization + the server), or can it be derived purely from existing data (source,
  id, handoff graph) with zero storage changes?
  confidence: 3
  disposition: answered
  rationale: NO. Both the surviving grouping key (source class) and the recommended successor
    (dedupe by id with a source badge) are derivable from what the browser already holds —
    presence in `examples/aef-processes/rendered/` vs `.editor-versions/`. No schema change, no
    new save path, no round-trip risk.

## Recommendation

**Recommendation:** NO-GO
**Rationale:** The corpus cannot support the feature as scoped. Of the three data-derived grouping
keys, two have no data — the handoff graph is empty (`targetWorkflow` in 0 of 24 rendered files,
`linkEvent` in 0 of 24) and id prefixes carry no hierarchy (one prefix with 5 members, all test
probes; the rest at 1-2, i.e. ~20 groups over 48 items). The only surviving key, source class, has
exactly two values, and a tree control over a two-valued key is a section header with extra
machinery. Building a tree here means building a control for a hierarchy the corpus does not
contain. What the measurement surfaced instead is that the browser shows **48 cards over 33
distinct workflows** — 15 workflows appear twice, once as corpus baseline and once as the user's
saved edit of the same workflow. Nearly a third of the grid is duplication, which a tree nests
rather than fixes.
**Evidence:** `docs/reports/T-155-tree-grouping-inception.md` §"Measured against the corpus —
2026-09-20"; counts reproduced by this task's `## Verification` legs (24 corpus / 24 saved / 15
overlap / 0 handoff files). Prior recommendation (DEFER pending operator input on IW-1/IW-2) is
superseded: the survey it deferred on has now been run, and it was run against the files rather
than against recollection.

**Named successor for the operator to rule on** — one bounded build task, *not* filed under this
inception id: **"deduplicate `openProjectModal`: one card per distinct workflow id, with a source
badge (corpus / saved / both) and the saved-version history under it."** Removes 15 cards outright,
needs no new metadata (IW-3 = no), no storage decision, no tree control — a rendering change in
`src/aef-workflow-designer.html` over data the browser already holds. Cost estimate **S**: single
file, one render path, no schema change. The majority of its cost is the mandatory visual
verification (element screenshots of `openProjectModal` across theme and density modes), not the
logic.

**Explicitly still NOT recommended:** user-assigned nested folders with persisted metadata
(IW-1(d) / A4+B2+C2) — subsystem-scale change for a tentatively-floated feature. Unchanged from
the original survey, and the measurement gives no new reason to revisit it.

## Acceptance Criteria

### Agent
<!-- Inception ACs: exploration deliverables, not build criteria. Real build ACs come after GO. -->
- [x] Research artifact `docs/reports/T-155-tree-grouping-inception.md` created (C-001) surveying the grouping design space and answering IW-1..IW-3.
- [ ] A recommended approach + GO/NO-GO/DEFER presented to the operator with rationale and a cost/scope estimate; decision recorded via `fw inception decide T-155 …`.
      **HALF DONE — the agent half is complete, the other half is not the agent's to do.**
      Presented: `## Recommendation` carries a structured **NO-GO** with rationale, evidence and
      an **S** cost/scope estimate for the named successor, and the full survey is in
      `docs/reports/T-155-tree-grouping-inception.md`. NOT done: "decision recorded via
      `fw inception decide`" — agents are structurally forbidden to invoke that verb (two
      independent gates: Tier 0 hook and the `$CLAUDECODE=1` refusal). Left unchecked
      deliberately so P-010 keeps blocking; this task is waiting on the operator, not on work.
- [ ] On GO: follow-up build tasks filed (decomposed); no production UI built under this inception id.
      Conditional on a GO that has not been given, and the recommendation is NO-GO. If the
      operator instead rules GO on the *named successor* (dedupe `openProjectModal`), that is one
      new build task — filed under its own id, never under this inception id.

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
         1. Run `bin/fw reviewer T-155`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-155 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# T-155 legs — the four figures the NO-GO rests on, re-measured from the tree.
# Each is a direct count, not a self-report. Command substitution keeps pipefail off `test`.
test "$(ls examples/aef-processes/rendered/*.bpmn 2>/dev/null | wc -l)" -eq 24
test "$(ls -d .editor-versions/*/ 2>/dev/null | xargs -n1 basename | grep -vc '^_')" -eq 24
test "$(comm -12 <(ls examples/aef-processes/rendered/*.bpmn | xargs -n1 basename | sed 's/\.bpmn$//' | sort) <(ls -d .editor-versions/*/ | xargs -n1 basename | grep -v '^_' | sort) | wc -l)" -eq 15
# the handoff graph IW-1(c) assumed: absent. Both attributes, zero files.
test "$(grep -l 'targetWorkflow' examples/aef-processes/rendered/*.bpmn 2>/dev/null | wc -l)" -eq 0
test "$(grep -l 'linkEvent' examples/aef-processes/rendered/*.bpmn 2>/dev/null | wc -l)" -eq 0
grep -q 'Measured against the corpus' docs/reports/T-155-tree-grouping-inception.md


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


### 2026-09-20 — the measurement inverted the task, and the survey it replaced was written from memory

Filed as "design a tree". Landed as "there is no hierarchy here, and the thing you are actually
hitting is duplication". The July artifact was explicit that it was "seeded from prior-session
knowledge of the browser's data model" — and one of the three grouping keys it proposed rested on
a claim about the corpus (`aef.targetWorkflow` handoffs forming a cross-workflow graph) that is
false of every file in it: 0 of 24. Two of three keys died on first contact with `ls` and `grep`.
The general shape, worth carrying: **an inception that surveys a design space without counting the
population can propose keys the data cannot supply.** The counting cost six commands.

### ROUTING FINDING — not fixed here, one lock at a time

`fw review-queue` lists 9 tasks under "DECISIONS — pending inception GO/NO-GO". **T-155 is not one
of them**, before or after this session's work — it carried a `DEFER` recommendation since
2026-07-10 and a `NO-GO` now, and the surface that tells the operator what needs deciding has
never shown it. So an inception can hold a written recommendation and still be invisible to the
queue that exists to surface exactly that. Not investigated further: the budget was in the warn
band and opening a second structural change while this task is ungated is the failure mode the
run is meant to avoid. Deliberately NOT filed to `.context/inbox.yaml` either — T-703 measured
that register at 118 pending with no auditable drain, so a capture there is a write into an
archive. Recorded here, where it is attached to the artifact it concerns, and in the run handback.

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

### 2026-09-20T10:26:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)
