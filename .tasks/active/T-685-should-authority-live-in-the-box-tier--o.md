---
id: T-685
name: "Should authority live in the box (tier + owner) with the lane meaning domain, instead of the lane being the sole authority-of-record?"
description: >
  Inception: Should authority live in the box (tier + owner) with the lane meaning domain, instead of the lane being the sole authority-of-record?

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
created: 2026-09-06T16:39:41Z
last_update: 2026-09-06T16:43:11Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
                                  # ⚠ CHANGE THIS TOO (T-625). Measured 2026-08-29: 38 of 41 inceptions still carried this
                                  # exact 3, the same 38 that carried voi_score: 0.5. Between them the two fields fix the
                                  # task's ENTIRE BVP position — value and cost — so leaving both planted means the
                                  # ranking is the template's opinion, not anyone's. The 3 is a placeholder, not a guide.
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
                                  # ⚠ CHANGE THIS (T-624). For an inception voi_score IS the entire BVP composite: the
                                  # estimator skips per-driver scoring and derives all nine drivers from this one number
                                  # (estimator.py _score_inception_voi). Leaving 0.5 does not score the task, it abstains —
                                  # and an abstention is printed as a confident BVP 126 that no reader can tell from a real
                                  # score. Measured 2026-08-29: 38 of 41 inceptions still carried this exact default, so the
                                  # entire hv-lc quadrant ranked as one flat tie. `python3 tools/_t624-voi-provenance.py`
                                  # reports which tasks were ever deliberately scored. The 0.5 below is a placeholder that
                                  # exists only to satisfy the schema gate (PL-167) — it is not a recommendation.
---

# T-685: Should authority live in the box (tier + owner) with the lane meaning domain, instead of the lane being the sole authority-of-record?

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-685 -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

- **IW-1: What is a "domain", precisely — is `customer` the same KIND of thing as `system`?**
  confidence: 2
  disposition: answered
  rationale: NO — researched 2026-09-06 (artifact §5b). TOGAF's BDAT set makes Business
    (customer) and Application/Technology (system) different LAYERS of one stack, not peers on
    one list, so one lane axis cannot hold both without reproducing this inception's own defect.
    All three bodies of knowledge (BABOK scope/IGOE, TOGAF BDAT, DDD bounded context) treat
    domain as a BOUNDARY and none uses it to mean who-performs. Residual: "the lane means
    domain" stays under-specified until we name WHICH layer — that part rolls into IW-7.

- **IW-2: Who sets the `tier`, and can an agent change it?**
  confidence: 2
  disposition: answered
  rationale: Operator ruled 2026-09-06 (artifact §5c) — lifecycle-gated mutability: agent
    proposes/detects, anyone may set while draft, once locked a tier change is itself a tier-0
    action. Carrier already exists (.editor-versions scratch vs the T-138 existence-or-promotion
    corpus gate). Answered as a POSITION, not yet as a design: three objections remain open and
    are split out as IW-8/IW-9/IW-10 rather than left inside this question.

- **IW-7: WHICH BDAT layer does the lane's domain denote — business, or application/technology?**
  confidence: 0
  disposition: deferred
  rationale: Falls directly out of IW-1's answer. If both layers must be visible, one lane axis
    is insufficient and shape C (nested lanes) or D (Group) is forced. Untested.

- **IW-8: What VALIDATES a tier at lock time?**
  confidence: 0
  disposition: deferred
  rationale: A lock protects a value; it does not validate it. A tier mis-set in draft and then
    locked is defended exactly as strongly as a correct one, and now costs a tier-0 approval to
    correct. Same class as T-674/675/677/678 and PL-178: stable rather than correct.

- **IW-9: Who may LOCK?**
  confidence: 0
  disposition: deferred
  rationale: If an agent can both propose a tier and lock the document, it can make its own
    guess expensive to reverse with no human having ruled. Lock authority may need to be
    sovereignty-only; unresolved.

- **IW-10: Is tier derivation deterministic outside framework-operation maps?**
  confidence: 1
  disposition: deferred
  rationale: CLAUDE.md §Enforcement Tiers names concrete tier-0 operations (force push, hard
    reset, rm -rf), so derivation is plausible for framework maps. For a general business step
    ("send invoice to customer") the tier is a judgement, not a derivation — and business
    process maps are most of what a workflow designer exists for. Determinism is therefore
    proven for a subset and unproven for the majority case.

- **IW-3: Do `tier` (0–3) and `authority` (sovereignty/initiative/authority/external) both
  need to survive, or does one subsume the other?**
  confidence: 2
  disposition: answered
  rationale: Both. They answer different questions — tier is per-ACTION risk (CLAUDE.md
    §Enforcement Tiers: tier 0 = force push/rm -rf needs human approval), authority is
    per-ACTOR role. A tier-0 action performed under agent initiative is the interesting case
    and neither field alone expresses it.

- **IW-4: What does `authority="none"` mean, and what owner should its 12 nodes derive?**
  confidence: 3
  disposition: answered
  rationale: MEASURED — it means nothing. `authority="none"` is on 3 lanes in
    examples/aef-processes/rendered/context-memory.bpmn carrying 12 flowNodeRefs, and it is
    absent from the collapse map at docs/standards/aef-bpmn-mapping-v1.md:97 and handled
    nowhere in tools/bpmn-cli.py. Those nodes have no derivable owner and nothing detects it.
    This is answered as a DEFECT, not as a design: the fix is in scope of the decision below.

- **IW-5: Can O-3 (inception go/no-go MUST sit in a sovereignty lane, compile-time enforced)
  be re-expressed against the element without losing the guarantee?**
  confidence: 1
  disposition: deferred
  rationale: If no, box-authority costs a machine-checked sovereignty property and the
    recommendation weakens sharply. Untested — needs a spike, not an argument.

- **IW-6: Is this ours to decide at all?**
  confidence: 3
  disposition: answered
  rationale: NO, not unilaterally. Part I of docs/standards/aef-bpmn-mapping-v1.md is frozen
    and shared with 999-AEF, and v1.1 (IW-9, T-189) DELIBERATELY removed the node-level owner
    override this proposal would restore. Any GO here opens a standard-change conversation
    with AEF; it does not authorise editing the frozen standard.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-685` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

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

GO on opening the question; the mechanism is genuinely unresolved and is the operator variable. The status quo is not a neutral baseline: examples/aef-processes/rendered/context-memory.bpmn carries three domain lanes at authority="none", a value absent from the standard collapse map (sovereignty/initiative/authority/external) and handled nowhere in the standard or tools/bpmn-cli.py, so 12 flowNodeRefs currently have no derivable owner and nothing detects it. Meanwhile aef:meta tier="0|1" already sits ON elements in 10+ corpus maps (27 tier-1, 10 tier-0) while the standard mentions tier only 4 times and never as an authority carrier, so half the operator proposed design is built and undocumented. T-341 half B is blocked on this: lanes[0] is positional, so authority today is decided by third-party laneSet serialisation order, which is exactly the defect that disappears if authority moves into the box. Costs are real and bound the exploration: frozen standard v1.1 deliberately REMOVED the node-level owner override making the lane the sole authority-of-record, and O-3 compile-time enforcement of the sovereignty go/no-go lane would need rewriting against the element.

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

<!-- Filled at completion via: fw inception decide T-685 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-06T16:41:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
