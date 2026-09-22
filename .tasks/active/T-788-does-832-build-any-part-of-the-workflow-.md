---
id: T-788
name: "Does 832 build any part of the workflow-to-application executor, or is the whole of it AEF's to deliver?"
description: >
  Inception: Does 832 build any part of the workflow-to-application executor, or is the whole of it AEF's to deliver?

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-09-22T07:40:05Z
last_update: 2026-09-22T07:41:00Z
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

# T-788: Does 832 build any part of the workflow-to-application executor, or is the whole of it AEF's to deliver?

## Problem Statement

Under the operator's confirmed yardstick — *"the workflow designer and its integration with
AEF and our ability to facilitate the agent and human collaboration to iterate from the
workflow to actual working applications"* — the component that turns a workflow into running
work is central. It does not exist in this repository (`fw workflow` verb, dispatch templates
and `policy/prompts` are all verified absent), and the README lists *"usable without
`fw workflow run`"* as an accepted non-goal. That is a direct contradiction between what this
project says it is for and what the operator says it is for.

The frozen standard resolves ownership — *"No translator is built here"* — and AEF confirmed
at `agent-chat-arc` @1616 that their Child-2 translator `tools/bpmn_to_tasks.py` exists in
their tree. So the question is not whether an executor should exist. **It is whether 832
builds any part of it, and that is a scope decision the operator has not been given the
evidence to make.** Now, because the value review surfaced it as SQ-1 and because building
the wrong side of a seam gets more expensive the longer it runs.

Research artifact: `docs/reports/T-788-executor-ownership-inception.md`.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-788 -->

- **A-1** — AEF regards Child-2 as theirs to deliver, not as a shared component.
  *Falsified by:* any reply proposing that 832 build part of it.
- **A-2** — 832's four bridge deliverables (Phase 5 F-10, measured intact) are sufficient on
  the consumer side once an executor exists upstream.
  *Falsified by:* a reply naming a required 832-side component we do not have.

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

- **IW-1: Does AEF's Child-2 translator have a delivery position, or does it exist only as a
  spike?**
  confidence: 1
  disposition: deferred
  rationale: @1616 establishes the FILE exists (`tools/bpmn_to_tasks.py`, grepped by AEF
  themselves) — it establishes nothing about schedule. This is the datum that separates the
  two branches in §3 of the research artifact; asked on the wire under §7.1.

- **IW-2: What does AEF expect 832 to hold on the consumer side of the seam?**
  confidence: 1
  disposition: deferred
  rationale: Phase 5 F-10 measured 832's four bridge deliverables intact, but "intact" was
  judged against OUR reading of the seam — and T-786 proved our derived reading had drifted
  from the frozen parent once already. Only the counterparty can confirm the list is complete.

- **IW-3: Is the README's non-goal ("usable without `fw workflow run`") still the project's
  position, or was it superseded by the confirmed yardstick?**
  confidence: 2
  disposition: deferred
  rationale: Phase 5 §10 records this as an unresolved contradiction. The yardstick came later
  and from the operator, which is the stronger source — but a README non-goal is a published
  commitment and retiring one is the operator's call, not an inference from precedence.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

**No spikes. No prototypes. No code.** The entire exploration is one bounded exchange, because
the unlocking datum is a fact only the counterparty holds.

1. **Ask AEF** for a Child-2 delivery position and for their expectation of 832's consumer-side
   surface (IW-1, IW-2). Time-box: one message, then wait. Contacting 999-AEF is mandated, not
   gated. *Not* a negotiation about who builds what — a request for a position.
2. **Record the reply verbatim with its rail offset** in §7.2 of the research artifact. Rail
   timestamps are not evidence; quoted content is.
3. **Put IW-3 to the operator** alongside the reply, since it is theirs to settle and the
   answer changes what "done" means for this project.
4. **Stop.** The decision is `fw inception decide`, which is the operator's and which agents
   must not invoke at all.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

**IN:** asking for a delivery position; recording the reply; putting IW-3 to the operator;
writing the recommendation and the evidence behind it.

**OUT, explicitly:**
- Writing any part of a translator, executor, or `fw workflow` verb. The frozen standard says
  *"No translator is built here"*, and §4 of the research artifact gives the reason building a
  small one anyway would be the T-786 error at larger radius.
- Editing `docs/standards/aef-bpmn-mapping-v1.md` (frozen Part I, not ours under any outcome).
- Proposing to AEF that they change scope. We are asking what their position IS, not lobbying
  for one — a reply shaped by our preference is not evidence about their plan.
- Deciding. `fw inception decide` is the operator's.

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
  1. Run: `fw task review T-788` (opens Watchtower with recommendation, assumptions, research artifacts)
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

DEFER because the decisive fact is not ours to establish and is cheap to ask for. The frozen standard aef-bpmn-mapping-v1.md Part I is explicit that the forward bridge is AEF-led and that 'No translator is built here'; AEF confirmed at agent-chat-arc @1616 that their Child-2 translator tools/bpmn_to_tasks.py exists in their tree and that our derived forward-compile doc does not. So the executor is real, specified, and owned upstream. What is NOT established is whether Child-2 is scheduled or hypothetical - a delivery position we have never asked for. Building any part of it here before that answer risks duplicating a component another team is actively writing, against the operator's confirmed yardstick which puts AEF integration at 9. F-10 of the Phase 5 review measured 832's four bridge deliverables intact, so the consumer-side slice we would own is already in place and is not blocked by the answer. The unlocking datum is one message to AEF asking for a Child-2 delivery position; until it returns, GO would be building on an assumption and NO-GO would foreclose a scope decision the operator has not been given the evidence to make.

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

<!-- Filled at completion via: fw inception decide T-788 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-22T07:41:00Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
