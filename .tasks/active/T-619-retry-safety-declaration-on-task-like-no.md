---
id: T-619
name: "Retry-safety declaration on task-like nodes: is sideEffect already the answer?"
description: >
  T-618 surfaced determinism and sideEffect. The remaining half of the operator request is a retry-safety field. Unlike determinism (215 authored uses, settled 3-value vocabulary) a retry-safety key has ZERO precedent: zero in the corpus, zero in the frozen standard. T-617 IW-4 puts idempotency semantics in AEF Arc 1, so a node may DECLARE it but the designer cannot DEFINE it. Question: does sideEffect (40 authored occurrences, hinted 'what this step already did to the world (retry hazard)') already carry the declaration, making a new key redundant invention?

status: started-work
workflow_type: inception
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-27T17:17:44Z
last_update: 2026-08-27T17:21:56Z
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

# T-619: Retry-safety declaration on task-like nodes: is sideEffect already the answer?

## Problem Statement

The operator wants a workflow the designer authors to be executable: a deterministic node runs
a script/CLI/API call, and a **stochastic** node, on failure, routes back to an agent to
evaluate and remediate. That remediation loop is only safe if the runtime knows whether
**re-running the failed node is safe** — otherwise "route the failure back to an agent" means
"double-charge the customer".

T-618 shipped the first half (`determinism` is now authorable on all 7 node types). The second
half is the retry-safety declaration. Why now: it is the last named piece of the operator's
request, and it is the one piece that sits on the 832↔AEF seam.

## Assumptions

- **A-1:** A retry-safety key has no author and no consumer today (zero corpus, zero standard).
- **A-2:** `sideEffect` (40 occurrences, hint "what this step already did to the world (retry
  hazard)") is already the declaration slot, so a new key would be redundant invention.
- **A-3:** The value vocabulary is AEF Arc 1's to define (roadmap §2.1), not the designer's.

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

- **IW-1: Do the 40 authored `sideEffect` values actually express a retry hazard, or are they
  prose annotations that happen to carry a suggestive field name?**
  confidence: 3
  disposition: answered
  rationale: Prose — but load-bearing prose. 5 of 40 literally say "none" (`none (read-only)`,
  `none  # dry-run: preview only`), so authors already reach for the distinction unprompted;
  verb census `appends 9 / creates 4 / writes 6 / sets 3` recovers the retry class. Raw
  material, not a contract. See docs/reports/T-619-retry-safety-declaration.md §F3.

- **IW-2: Is retry safety DERIVABLE from what the corpus already declares — i.e. does
  (`determinism`, `sideEffect`) jointly determine it — or is there a residue that neither key
  can express?**
  confidence: 3
  disposition: answered
  rationale: NO — there is a real residue, and this is the finding. 37 of 39 side-effecting
  nodes are `deterministic`, and that one value spans accumulates=20 / overwrite=12 / no-op=5.
  A runtime concluding "deterministic ⇒ safe to re-run" double-refunds the billing node
  (`charge reversed…; receipt emailed`). §F2.

- **IW-3: Does AEF Arc 1 define an idempotency vocabulary a node may declare against, and will
  they accept a designer-authored declaration?**
  confidence: 0
  disposition: deferred
  rationale: Posted to 999-AEF at rail offset 636 as a §2.1 joint handoff, in three parts
  (adopt-verbatim / starting-shape / prose-companion). Deferred pending their answer AND the
  operator's ruling — per §2.3 a peer reply is input to the ruling, not the ruling.

- **IW-4: If a new key IS warranted, is it a scalar (carried free by T-570) or does it need
  emitter work — i.e. what is the actual build cost being weighed?**
  confidence: 3
  disposition: answered
  rationale: Scalar, carried free. `carriedKeys = aefKeys.filter(k => !scalarHandled.has(k) &&
  typeof aef[k] !== 'object')` (src:9870) emits any new scalar into `<aef:meta>` with zero
  emitter work; cost is 1 line per node type in AEF_FIELDS + 1 FIELD_META entry. Cost is
  therefore NOT the reason to stop — ownership is. §F4.

## Exploration Plan

| # | Spike | Time-box | Answers |
|---|---|---|---|
| 1 | Census the 40 `sideEffect` values; read them, classify hazard vs prose | 20 min | IW-1 |
| 2 | Cross-tabulate `determinism` × `sideEffect` presence across the corpus | 15 min | IW-2 |
| 3 | Post the §2.1 joint-handoff question to 999-AEF on the rail | 10 min | IW-3 |
| 4 | Confirm scalar carriage path in the T-570 emitter (read-only) | 10 min | IW-4 |

Spikes 1, 2 and 4 are read-only measurement. Spike 3 is peer contact, which roadmap §2.1
mandates rather than gates. **No source file is edited under this task** — a GO produces a
separate build task (CLAUDE.md §Inception Discipline rule 5).

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

**IN:** measuring what the corpus already declares about retry hazard; deciding whether a new
node key is warranted; posing the vocabulary question to AEF.

**OUT:** defining idempotency semantics (AEF Arc 1, roadmap §2.1); implementing a retry/remediation
*runtime* (that is EWCR, not the designer); editing `docs/standards/aef-bpmn-mapping-v1.md`
(frozen); any change to `src/aef-workflow-designer.html` under this task ID.

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
- The `sideEffect` census shows the 40 occurrences do NOT express retry hazard (A-2 falsified), AND
- there is a residue that `determinism` × `sideEffect` jointly cannot express (IW-2), AND
- the key name/values are grounded in something other than my own invention — an AEF Arc 1
  vocabulary, or an author already writing it

**NO-GO if:**
- The declaration slot already exists (`sideEffect`) and merely needed surfacing — which T-618 did
- The only thing missing is a value vocabulary owned by AEF, making this a §2.1 joint handoff
  rather than a designer build
- Building it means minting a key with zero authors and zero consumers (the T-617 `execution`
  failure mode, one task old)

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

**Recommendation:** NO-GO *(on unilateral authorship — see REVISED below; the exploration
sharpened this from "probably redundant" to "real gap, wrong owner")*

**REVISED after measurement (2026-08-27):** NO-GO stands, but for the opposite half of the
reason it was filed. The filing assumed `sideEffect` already answered the question (A-2) and a
new key would be redundant. **A-2 is half wrong.** The measurement found a genuine residue:
`determinism` does not predict retry safety — 37 of 39 side-effecting nodes are `deterministic`
and that one value spans accumulates=20 / overwrite=12 / no-op=5, so a runtime that infers
retry safety from `determinism` issues a **double refund** on the billing node. The operator's
request is therefore **well-founded**, and NO-GO is emphatically *not* "this feature is
unnecessary". It is: *the designer must not author AEF's vocabulary*. Build cost is trivial
(scalar, carried free by T-570, ~2 lines) — which is exactly why cost cannot be the argument.
Question posted to 999-AEF at rail offset 636. **OVERTURNED TO GO** the moment Arc 1 returns a
key name + value set, at which point we surface it verbatim as a constrained dropdown, exactly
as T-618 did for `determinism`.

**Original filing rationale:** NO-GO on minting a new retry-safety key under designer authority. Two independent silences: grep for idempot|retry|rerun|replay|compensat|at-least-once|exactly-once over docs/standards/aef-bpmn-mapping-v1.md returns zero matches, and the same class of grep over examples/ returns zero authored occurrences. Contrast determinism, which T-618 shipped precisely because the corpus had already settled it on 215 nodes with three values. Inventing a key with no author and no consumer is the failure mode T-617 argued against for the execution workflow_type. The authoring slot for retry hazard already exists and already shipped: sideEffect, 40 authored occurrences, added to the panel in T-618. What is genuinely missing is a VALUE vocabulary, and roadmap section 2.1 assigns idempotency semantics to AEF Arc 1 — a joint handoff, not a unilateral build. OVERTURNED IF: AEF returns a defined Arc 1 vocabulary, or the sideEffect census shows the 40 occurrences do not in fact express retry hazard.

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
