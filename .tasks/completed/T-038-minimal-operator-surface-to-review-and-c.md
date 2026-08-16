---
id: T-038
name: "Minimal operator surface to review and correct the mapped-process corpus"
description: >
  Inception: Minimal operator surface to review and correct the mapped-process corpus

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-03T07:36:58Z
last_update: '2026-08-16T14:33:08Z'
date_finished: 2026-07-03T07:45:31Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:32Z'
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
  - ts: '2026-08-16T14:33:08Z'
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
  - ts: '2026-08-16T13:57:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-038: Minimal operator surface to review and correct the mapped-process corpus

## Problem Statement

**For the operator (the human Sovereign)**, there is currently no way to *see* which AEF
processes have been mapped to workflow definitions, nor to *review* whether a mapping
faithfully represents the real process, nor to *correct* one.

Ten processes have been mapped (`examples/aef-processes/*.workflow.yaml`) and every one
passes the validator (exit 0). But "exit 0" proves only **structural well-formedness** — it
says nothing about **semantic fidelity** (does the tier0 mapping actually match how Tier-0
escalation really works?). That axis of validity has **never been checked by a human**: I am
both the sole author of the mappings *and* the sole author of the F1–F17 friction register
built from them. That is a blind spot.

Concretely: (a) no operator-facing **register** exists — the mapped set is discoverable only
as a directory listing plus a prose table inside `dogfood-v3-design-inputs.md`; (b) the one
product UI, `src/aef-workflow-designer.html`, reads only `.bpmn`/`.xml`, so **none of the
`.workflow.yaml` corpus is currently viewable** in it. **Why now:** this feedback should
precede further validator hardening (F3/F1) — if human review revises the model, rules built
on the old model are waste.

## Assumptions

Registered via `fw assumption add` (see `fw assumption list`):
- **A-1:** The operator wants a single register showing mapping + validation + review status.
- **A-2:** Seeing a mapping *rendered as a diagram* (not raw YAML) is what lets a human judge
  semantic fidelity.
- **A-3:** A YAML→BPMN bridge is tractable given `schema.md` defines both forms and the
  `XmlValidator` already understands BPMN-XML.
- **A-4:** Human review of the corpus will surface at least one model-validity finding that
  mechanical validation missed (the core value hypothesis).

## Open Questions

- **IW-1: What is the minimal operator surface that lets a human review mapping fidelity?**
  (register-only, register+read-only-viewer, or register+viewer+correct-in-place)
  confidence: 1
  disposition: deferred
  rationale: to be resolved by the exploration + operator dialogue; artifact docs/reports/T-038-*.md
- **IW-2: Does a YAML→BPMN render bridge already exist, or must it be built?**
  confidence: 3
  disposition: answered
  rationale: `tools/` holds only validate-workflow.py; no converter — bridge must be built (verified this session)
- **IW-3: What does "correct" mean — edit YAML in place, or capture a flag/finding for later?**
  confidence: 1
  disposition: deferred
  rationale: affects scope (editor vs annotation surface); needs operator input
- **IW-4: Does human review actually surface fidelity findings the validator misses? (A-4)**
  confidence: 1
  disposition: deferred
  rationale: the load-bearing value test; validated by piloting the surface on ≥1 process with the operator

## Exploration Plan

Time-boxed, non-build (no production artifacts before GO):
1. **(30m) Surface-options analysis** — enumerate 3 surface tiers (register-only /
   +viewer / +correct), cost/value each, in the research artifact.
2. **(30m) YAML→BPMN bridge feasibility spike** — a *throwaway* proof that one corpus file
   can be transformed to the BPMN-XML form the existing editor already renders (paper design
   + minimal snippet; not wired into the product).
3. **(dialogue) Operator fidelity pilot** — walk the operator through one rendered mapping to
   test A-4 (does review surface a finding?) and resolve IW-1/IW-3.
4. Synthesize → GO/NO-GO recommendation with a scoped, phased build proposal.

## Technical Constraints

- **Injection boundary (T-020):** the surface stays on the PRODUCT side — it renders/reviews
  workflow *definitions*; it does NOT execute them against the live framework.
- **Portability (directive 4) / PD-002:** any validation stays framework-agnostic; the
  surface must not couple to AEF internals beyond reading the corpus's own files.
- **Self-contained UI:** `src/aef-workflow-designer.html` is a single 192KB no-build,
  no-external-dependency file (CSP-safe pattern). A viewer should preserve that — no CDN, no
  server required to open a diagram; a static bridge/generated register is preferred over a
  live backend.
- **Format reality:** editor reads `.bpmn`/`.xml`; corpus is `.workflow.yaml`. The bridge is
  the enabling constraint (IW-2, answered: must be built).
- **Sovereignty:** "correct" must never let the agent silently rewrite an operator's mapping;
  corrections are operator-authored or operator-approved.

## Scope Fence

**IN (this inception — explore only):** the register shape; the minimal review surface tier;
YAML→BPMN bridge feasibility; the fidelity-feedback hypothesis (A-4). Output is a research
artifact + GO/NO-GO recommendation.

**OUT:** building the register/UI/bridge (that's post-GO build tasks); a live editing backend;
round-trip BPMN→YAML write-back; multi-user/auth; anything touching the vendored
`.agentic-framework/`; resuming F3/F1 (paused, separate track).

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

**GO if:**
- The minimal surface tier is agreed and is scoped, phased, and reversible (static
  register + bridge + reuse of the existing editor — no new backend)
- The YAML→BPMN bridge is shown tractable (feasibility spike succeeds on ≥1 corpus file)
- A-4 holds: the operator confirms review would surface fidelity feedback worth the build

**NO-GO if:**
- The surface can only be delivered as a full new app / live backend (unbounded scope)
- The bridge proves intractable without reworking the schema
- The operator judges mechanical validation sufficient (A-4 fails — no fidelity gap worth a UI)

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:**

Evidence: the 10 dogfood mappings have only ever been validated MECHANICALLY (validator exit 0 = structurally well-formed), never for SEMANTIC FIDELITY to the real AEF processes; no human has closed that loop. No operator-facing register exists (only a directory + a prose table in dogfood-v3-design-inputs.md), and the existing BPMN editor (src/aef-workflow-designer.html) reads only .bpmn/.xml, so none of the .workflow.yaml corpus is currently viewable. A minimal register + review surface is the first mechanism to get operator feedback on model validity and would correctly precede further validator hardening (F3/F1). Recommend GO to explore the minimal surface; enabling piece (YAML->BPMN bridge) is well-specified by schema.md and the existing XmlValidator.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

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

**Decision**: GO

**Rationale**: Evidence: the 10 dogfood mappings have only ever been validated MECHANICALLY (validator exit 0 = structurally well-formed), never for SEMANTIC FIDELITY to the real AEF processes; no human has closed that loop. No operator-facing register exists (only a directory + a prose table in dogfood-v3-design-inputs.md), and the existing BPMN editor (src/aef-workflow-designer.html) reads only .bpmn/.xml, so none of the .workflow.yaml corpus is currently viewable. A minimal register + review surface is the first mechanism to get operator feedback on model validity and would correctly precede further validator hardening (F3/F1). Recommend GO to explore the minimal surface; enabling piece (YAML->BPMN bridge) is well-specified by schema.md and the existing XmlValidator.

**Date**: 2026-07-03T07:45:31Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-03T07:37:16Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-03T07:45:31Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Evidence: the 10 dogfood mappings have only ever been validated MECHANICALLY (validator exit 0 = structurally well-formed), never for SEMANTIC FIDELITY to the real AEF processes; no human has closed that loop. No operator-facing register exists (only a directory + a prose table in dogfood-v3-design-inputs.md), and the existing BPMN editor (src/aef-workflow-designer.html) reads only .bpmn/.xml, so none of the .workflow.yaml corpus is currently viewable. A minimal register + review surface is the first mechanism to get operator feedback on model validity and would correctly precede further validator hardening (F3/F1). Recommend GO to explore the minimal surface; enabling piece (YAML->BPMN bridge) is well-specified by schema.md and the existing XmlValidator.

### 2026-07-03T07:45:31Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
