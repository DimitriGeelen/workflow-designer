---
id: T-681
name: "EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all"
description: >
  Inception: EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
created: 2026-09-05T14:17:12Z
last_update: 2026-09-08T20:40:54Z
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

# T-681: EWCR arc holds only Arc-0 and every task in it is closed; roadmap Arcs 1-6 have no tasks at all

## Problem Statement

`arc-002 ewcr-governed-delivery` held 16 tasks on 2026-09-05 and **all 16 were
`work-completed`** — zero live work, `status: draft`, and the focus star on `arc-001`. Meanwhile
`roadmap-5be23719.md` §2.1 defines **seven arcs (0–6)**, each with a named Workflow-Designer-owned
column, and **only Arc 0 has ever been decomposed into tasks**. The headline mechanic (author →
export as executable contract → runtime executes with traceable evidence) has no task anywhere
building toward it.

For the operator, who asked directly whether we are still focused on EWCR and whether new scope
is being added as tasks. The answer to both was no. Now, because Arc-0's exit is not ours to
cause — two of its three clauses sit with AEF's operator (T-680) — so waiting for it is waiting
indefinitely.

Full analysis: `docs/reports/T-681-ewcr-next-arc-inception.md`.

## Assumptions

Registered as IW-1..IW-4 under Open Questions rather than duplicated here; IW-2 is the one that
can flip the recommendation to NO-GO.

## Open Questions

- **IW-1: Does "execution / secret / ledger authority" have a stateable definition on the
  Designer side today, sufficient to enumerate every path the editor has to it?**
  confidence: 3
  disposition: answered
  rationale: Yes — and enumerated, not asserted, but only after T-689 corrected an omission in the first answer. Arc 2's clause (roadmap-5be23719.md:66) names THREE authorities — execution, secret, ledger. T-682 measured two: it substituted "mutation" for "ledger" in its own docstring and the third was never searched for. This disposition was first written at confidence 3 on that two-of-three basis (commit 8a5950cf), which was the same overclaim T-682 exists to prevent, one level up. T-689 added `LEDGER_PATTERNS` to the same instrument. Now measured, all three: execution present in-file but unreachable from any route (`gallery-serve.py:824`, fixed-arg `subprocess.check_output(['hostname','-I'])`); secret 0 matches over 8 patterns; ledger PRESENT — 5 WRITE sites, `.editor-versions/<id>/index.json` plus `.context/designer/registry.yaml` via `write_registry` (gallery-serve.py:416,426,448,450), reached from `/api/save` and `/api/delete`. That correction also fixed the mutation row, which said `/api/save` writes 5 targets when it writes 6. S1's stated failure branch — "if the list is empty" — did not fire.

- **IW-2: Can the Arc-2 mutation control be built without introducing a real breach path into
  the shipped tree?** If it cannot, the recommendation flips to NO-GO: a fence with no
  demonstrated red state is not evidence, and shipping a breach to prove one is worse.
  confidence: 3
  disposition: answered
  rationale: Yes — the control never touches the shipped tree. `tools/_t684-mutation-control.py` `variant()` (:72-94) writes each mutated server to a fresh tempdir and runs it against a throwaway repo (`fresh_repo()`, :97); the shipped `gallery-serve.py` is read, never written. Its ID_RE is additionally pinned by T-683's `id-re-unchanged` leg, so a fix resting on widening the regex would fail. Measured 2026-09-08: VERDICT GREEN, exit 0 — phase A manufactured breach escaped=True, phase B fence escaped=False. The NO-GO branch did not fire.

- **IW-3: Is a fence installed before the authority it guards exists actually a ratchet, or is
  it a green check that certifies nothing?** The value claim rests on installing the boundary
  while it is cheap; the objection is PL-178 — a leg that has never been red asserts nothing.
  confidence: 3
  disposition: dissolved
  rationale: The question's premise did not survive contact. It assumes a fence installed BEFORE the authority exists; T-683 measured the opposite — the authority already existed and was already unguarded. `_within_repo` was referenced only on the delete path while `/api/save` wrote 5 request-derived targets behind ID_RE alone, and T-681 S2 had already put a write outside the version store (HTTP 200, escaped=True). So this was never a fence ahead of its authority; it was a fence arriving late. PL-178's underlying demand — never ship a leg that has not been seen red — was met on its own terms rather than argued: T-683's suite proven red against reconstructed pre-fix code, T-684's phase A manufacturing a visible breach, T-682's drift check proven red by an injected `/api/exfiltrate` route.

- **IW-4: Is AEF's Arc-2 column (service identity, authenticated API, runner-owned state)
  genuinely theirs, or would we need to stub it beyond a test double to prove anything?**
  confidence: 2
  disposition: answered
  rationale: Genuinely theirs, and nothing was stubbed. Roadmap §2.1's Arc-2 AEF column is service identity, authenticated API, and runner-owned state; none of the three shipped deliverables touches any of it. All three are falsifiable claims about our own tree — `tools/gallery-serve.py` and its two harnesses — and each runs against a throwaway repo with no counterparty artefact, real or doubled. Confidence 2 rather than 3: this rests on reading the roadmap column and observing what the deliverables import, not on a measurement of AEF's side, which is not ours to measure.

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

Two spikes, both cheap, both run only **after** a GO. Neither writes production code.

- **S1 (IW-1, ~1h)** — enumerate what "execution / secret / ledger authority" means in this tree
  today: what exists, what is stubbed, what is purely AEF's. Output: a list of named authorities
  and every path the editor has to each. If the list is empty, IW-3 is answered *against* the
  recommendation and the fence has nothing to guard.
- **S2 (IW-2, ~1h)** — prototype the mutation control in a throwaway root: introduce a path,
  show the fence red, revert, show it green. Time-boxed; if it cannot be done without a real
  breach path in the shipped tree, the disposition is NO-GO and S1's output is kept as evidence.

IW-3 is argued in §5 of the research artifact and *tested* by S2 — it is not settled by
assertion. IW-4 is answered by reading roadmap §2.1's AEF column, not by a spike.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

**IN:** deciding which single EWCR arc to open next, and on what condition. Producing the
decomposition *only* after a GO, as separate build tasks under `arc-002`.

**OUT:**
- Opening Arcs 1, 3, 5 or 6 — all four are counterparty-blocked and would be born unstartable.
- Re-opening Arc 4 — its one independent slice shipped as T-611.
- Any Arc-0 clause work. `definition_ratified:` and `attestation:` are the operator's, and AEF
  declined clause 1 deliberately.
- Building the fence itself under this task ID. On GO it becomes separate build tasks.
- Touching `voi_score:` / `target_blast_radius:` in this file. Both are planted template defaults
  (0.5 / 3) that flatten this task's BVP position, and both are operator-owned with no
  `_proposed:` lane — flagged for the operator rather than filled in.

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
  1. Run: `fw task review T-681` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Exactly one roadmap arc has a Designer-owned column with no counterparty dependency — measured
  in §4 of the research artifact: Arc 2 is the only one of six.
- The mutation control in §5 is buildable without introducing a real breach path into the shipped
  tree (IW-2), so the fence has a demonstrated red state and is evidence rather than decoration.
- The work survives an Arc-0 that never exits — an isolation proof is actionable regardless of
  whether AEF ever attests.

**NO-GO if:**
- IW-2 resolves negative: the control cannot be built without a real breach path. Then the
  deliverable is a green check certifying nothing, which is worse than no check because it would
  be reported to AEF as an isolation proof.
- S1 finds no execution/secret/ledger authority in this tree at all, stubbed or otherwise — a
  fence guarding nothing is not a ratchet, it is a placeholder that will be read as coverage.
- The scope cannot be held to Arc 2's Designer column alone without stubbing AEF's half (IW-4).

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.
#
# This inception is an exception to "verification is often not needed": the GO produced three
# shipped controls, so closing it without re-running them would close on the recommendation
# being believed rather than on it having held. Each command below is one Arc-2 deliverable.
python3 tools/_t682-boundary-inventory.py
python3 tools/_t683-save-containment-verify.py
python3 tools/_t684-mutation-control.py
# Negative leg: these controls must be CAPABLE of red, not merely green today. Each --self-test
# sabotages its own control on purpose and exits 0 only if the sabotage was detected — so a 0
# here means "the red state was reached", which is the opposite of what a green usually means.
python3 tools/_t682-boundary-inventory.py --self-test
python3 tools/_t684-mutation-control.py --self-test

## Recommendation

**Recommendation:** GO

**Rationale:**

GO, scoped to Arc 2's Designer-owned half ONLY: prove the browser/editor cannot reach execution, secret, or ledger authority. Of the six undecomposed arcs, five have a Designer column depending on an AEF artefact that does not exist yet (Arc 1 registry/ledger, Arc 3 action catalogue, Arc 5 prompt/context envelope, Arc 6 router; Arc 4 needs the projection API, and its one independent slice - diagram-to-Fabric navigation - already shipped as T-611). Arc 2's Designer column is the exception: it is a falsifiable claim about OUR OWN code, provable today with nothing from the counterparty. It is also the only one whose value survives an Arc-0 that never exits, because an isolation proof is evidence the operator can act on regardless of whether AEF attests. Recommending AGAINST opening Arcs 1/3/5/6 now: decomposing work whose inputs are counterparty-blocked manufactures a backlog that measures as progress and cannot move.

**Evidence:**

Recorded 2026-09-08, **after** the operator's GO of 2026-09-05. This does not revise the
recommendation — the GO text above is unchanged. It records what the GO produced, so the
closure rests on measurements rather than on the recommendation being believed.

The GO authorised Arc-2's Designer-owned half only. It decomposed into three build tasks,
all now `work-completed`, and each shipped a control that has been **seen red**:

- **T-682** — `tools/_t682-boundary-inventory.py` + `docs/reports/T-682-arc-2-boundary-inventory.md`.
  Route set AST-derived from the server's own dispatch, so it cannot go stale silently.
  Measured 2026-09-08: `OK — 7 routes, server and inventory agree, all classified` (exit 0).
  Red state demonstrated: `--self-test` injects `/api/exfiltrate` and the drift check fails.
- **T-683** — per-target containment on `/api/save` (`_escaping_save_target`, `gallery-serve.py`).
  Measured 2026-09-08: **8/8 passed** (exit 0), including the load-bearing leg
  `within-repo-would-have-allowed-it` — which proves the fix the task originally *specified*
  (`_within_repo` on the save path) would have admitted the exact write it exists to refuse.
- **T-684** — `tools/_t684-mutation-control.py`. Measured 2026-09-08: **VERDICT GREEN** (exit 0),
  phase A manufactured breach `escaped=True`, phase B fence `escaped=False`. Its third verdict
  INCONCLUSIVE is reachable and proven so by `--self-test`.

Two of the four IW questions were answered against their filed premise rather than in
agreement with it, which is recorded in the dispositions above: IW-3 dissolved (the authority
already existed and was unguarded — this was not a fence installed early), and the T-682 filing's
claim that execution authority "does not exist in this tree at all" was an overclaim, corrected
to the narrower checkable claim that no route reaches it.

**One correction found while disposing these questions (T-689).** The Arc-2 clause names three
authorities; the shipped inventory measured two. `tools/_t682-boundary-inventory.py`'s own
docstring read "mutation, execution, secret" — swapping the roadmap's third authority for a
fourth of its own — and ledger went unsearched behind that substitution. Filed as T-689 rather
than patched under this inception ID, and now closed: the ledger section reports 5 WRITE sites,
and the `/api/save` row is corrected from 5 targets to 6 (the sixth being
`.context/designer/registry.yaml`). The GO's conclusion is unchanged; its evidence is now
complete rather than two-thirds complete.

**What this evidence does not cover:** Arcs 1, 3, 5 and 6 remain undecomposed by design, per the
Scope Fence. Arc-0's exit stays blocked on two counterparty-owned clauses (T-680). Closing this
task closes the *decision*, not the arc.

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

**Rationale**: Recommendation: GO

Rationale:

GO, scoped to Arc 2's Designer-owned half ONLY: prove the browser/editor cannot reach execution, secret, or ledger authority. Of the six undecomposed arcs, five have a Designer column depending on an AEF artefact that does not exist yet (Arc 1 registry/ledger, Arc 3 action catalogue, Arc 5 prompt/context envelope, Arc 6 router; Arc 4 needs the projection API, and its one independent slice - diagram-to-Fabric navigation - already shipped as T-611). Arc 2's Designer column is the exception: it is a falsifiable claim about OUR OWN code, provable today with nothing from the counterparty. It is also the only one whose value survives an Arc-0 that never exits, because an isolation proof is evidence the operator can act on regardless of whether AEF attests. Recommending AGAINST opening Arcs 1/3/5/6 now: decomposing work whose inputs are counterparty-blocked manufactures a backlog that measures as progress and cannot move.

Evidence:

**Date**: 2026-09-05T16:30:45Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-05T16:22:02Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-05T16:30:45Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale:

GO, scoped to Arc 2's Designer-owned half ONLY: prove the browser/editor cannot reach execution, secret, or ledger authority. Of the six undecomposed arcs, five have a Designer column depending on an AEF artefact that does not exist yet (Arc 1 registry/ledger, Arc 3 action catalogue, Arc 5 prompt/context envelope, Arc 6 router; Arc 4 needs the projection API, and its one independent slice - diagram-to-Fabric navigation - already shipped as T-611). Arc 2's Designer column is the exception: it is a falsifiable claim about OUR OWN code, provable today with nothing from the counterparty. It is also the only one whose value survives an Arc-0 that never exits, because an isolation proof is evidence the operator can act on regardless of whether AEF attests. Recommending AGAINST opening Arcs 1/3/5/6 now: decomposing work whose inputs are counterparty-blocked manufactures a backlog that measures as progress and cannot move.

Evidence:
