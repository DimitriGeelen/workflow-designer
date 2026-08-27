---
id: T-617
name: "designer node execution contract: determinism and failure routing"
description: >
  Inception: designer node execution contract: determinism and failure routing

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-27T09:16:58Z
last_update: 2026-08-27T09:19:53Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-617: designer node execution contract: determinism and failure routing

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

The operator's proposal, stated back: give the designer a notion of **execution** — runtime /
execution tasks as a node kind — and split them **deterministic** (a script, a CLI command, an
API call from code) vs **stochastic** (an agent), so that when a stochastic step fails the
failure can be **routed back to an agent to evaluate, remediate and recover**.

The goal behind it: design → build → execution in one artifact, producing application code.

- **IW-1: Can an execution contract ride the existing `<aef:meta>` scalar carriage, or does
  it need a new element or node type?**
  confidence: 1
  disposition: answered
  rationale: confidence 3. AEF_FIELDS/metaKeys read from src: scalars ride <aef:meta>, metaKeys still 20 (T-589 precedent). No new element, no AEF ratification.
  <br>This is the question the whole cost turns on. T-589 proved that *scalar* fields ride
  `<aef:meta>` with `metaKeys` unchanged and **nothing for AEF to ratify**. A new node type or
  a structured element is a change to `docs/standards/aef-bpmn-mapping-v1.md`, which is frozen
  and **must not be edited under agent control** — making it a joint handoff with 999-AEF
  under roadmap §2.1. Free versus cross-project negotiation. I will not guess between them.

- **IW-2: Does the failure-routing half need any dialect change at all?**
  confidence: 1
  disposition: answered
  rationale: confidence 3. AEF_FIELDS.eventError = ['errorStatus','hostRef','boundaryPos','interrupting','note'] — a BPMN error boundary event, authorable today. No dialect change needed.
  <br>BPMN already has error boundary events, escalation and compensation — the standard's own
  answer to "this step failed, go there instead". If the editor already carries them, the
  operator's routing requirement may be *authoring*, not *dialect*. Inventing an `onFailure`
  attribute alongside a standard mechanism that already expresses it would be the worse
  outcome, and is the failure mode roadmap §2.1 exists to prevent.

- **IW-3: What is the authority boundary of a recovery agent invoked on failure?**
  confidence: 0
  disposition: deferred
  rationale: confidence 0. Governance, not rendering. Arc 2/3, AEF on the other side. BLOCKS execution: fields without this ship a diagram that authorises autonomous remediation.
  <br>The proposal introduces an agent that *acts* when something breaks. The Authority Model
  gives agents INITIATIVE, not AUTHORITY. A remediation node that can retry, roll back or call
  an API is an agent taking consequential action with no human in the loop, at runtime, in a
  workflow authored by someone who may not have thought about it. Arc 2 ("prove browser/editor
  cannot reach execution/secret/ledger authority") and Arc 3 ("render structured refusals")
  are exactly this. **Unanswered, this question makes the feature unsafe rather than merely
  unbuilt.**

- **IW-4: Is retrying a failed step safe, and who declares that?**
  confidence: 0
  disposition: deferred
  rationale: confidence 0. Idempotency is AEF's Arc 1 per roadmap 2.1 — a node may DECLARE it, we cannot DEFINE it. The one genuine joint-handoff item in the proposal.
  <br>"Route the failure back to an agent to recover" presumes the failed step can be re-run.
  A step that partially completed — wrote half its rows, charged the card, sent the mail — is
  not re-runnable, and an agent that retries it double-applies. Roadmap §2.1 puts
  **idempotency** in AEF's Arc 1 column, so the designer cannot answer this alone; but it must
  decide whether a node can *declare* idempotency, because a runtime cannot infer it.

- **IW-5: Is "deterministic vs stochastic" the axis that actually pays, or a proxy for one?**
  confidence: 2
  disposition: dissolved
  rationale: confidence 2. The axis is a proxy. Dialect keys on WHO PERFORMS (agentType); a runtime needs IS THE RESULT CHECKABLE and IS RETRY SAFE. Replaced by three orthogonal scalars: execution / verify / idempotent.
  <br>My own doubt, filed as a question rather than smuggled in as a conclusion. The property a
  runtime needs at a failure boundary may not be *how* the node computed its answer, but
  **whether the answer can be checked without re-running it**. Those correlate but are not the
  same: a flaky network call is deterministic code with a stochastic outcome, and an LLM
  classifier constrained to an enum has a checkable result. If the checkable/uncheckable axis
  is the load-bearing one, the field should encode that instead — and the honest test is
  whether any real node in our corpus separates the two.

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
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Recommendation:** DEFER

**Rationale:**

Filed at DEFER because I have not yet measured the one fact the decision turns on: whether an execution contract can ride the existing <aef:meta> scalar carriage (free, no AEF ratification, as T-589 proved for fabricRef/links) or requires a new node type or element, which is a change to the frozen standard docs/standards/aef-bpmn-mapping-v1.md and therefore a joint handoff with 999-AEF under roadmap 2.1. Those two answers have wildly different costs and I will not guess between them. A second unmeasured question sits underneath: BPMN already carries error boundary events and compensation, so the failure-routing half may need no dialect change at all. Recommendation to be revised to GO or NO-GO once both are measured against the actual editor build rather than recalled.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-08-27T09:17:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
