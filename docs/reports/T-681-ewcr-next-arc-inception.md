# T-681 — What is the next arc of Designer-owned EWCR work?

**Type:** inception · **Arc:** arc-002 `ewcr-governed-delivery` · **Opened:** 2026-09-05
**Decision owner:** operator. Agents may not run `fw inception decide` (two gates enforce it).
**Recommendation:** **GO**, scoped to Arc 2's Designer column only — and only with the mutation
control described in §5, without which the recommendation is NO-GO.

---

## 1. The question

One question, per inception sizing: *what is the next arc of Designer-owned EWCR work that can
start without an Arc-0 exit, and is opening it now the right call?*

## 2. Why the question exists now

Measured 2026-09-05:

- `arc-002` held **16 tasks and all 16 were `work-completed`**. The arc had zero live work while
  sitting at `status: draft`, and the focus star was on `arc-001`. An arc with no open tasks is
  indistinguishable from a finished one at a glance, which is how this went unnoticed.
- `roadmap-5be23719.md` §2.1 defines **seven arcs (0–6)**, each with a named
  Workflow-Designer-owned column. **Only Arc 0 has ever been decomposed into tasks.**
- The headline mechanic — author a workflow, export it as an executable contract, have a runtime
  execute it with every step traceable to its justifying evidence and authorising decision — has
  **no task anywhere that builds toward it**.

So the EWCR arc was not stalled. It had quietly run out.

## 3. Why Arc 0 will not exit on our initiative

Established by T-680, and not a transport problem:

| clause | owner | state |
|---|---|---|
| 1 — topology non-empty and validated | AEF | AEF measured it and **declined to attest**: 1134 cards, 52 edgeless of 1047 assessed, 749 outside any watch pattern. Recorded as *their refusal*, not as unsatisfied. |
| 2 — refusal matrix complete | AEF | AEF calls it a scope ruling for **their operator**: produce the DeepSeek/Mistral disposition tables, or rule those findings out of Arc-0. |
| 3 — source-of-truth reconciliation | shared | unratified |

All three carry `definition_ratified: false`, which is **our operator's** ruling. No amount of
Designer-side work moves any of them. Planning that waits on Arc-0 is planning that waits.

## 4. Arc-by-arc: what the Designer owns, and what it depends on

From §2.1's Designer column, against what exists today:

| arc | Designer owns | blocked on | verdict |
|---|---|---|---|
| 1 Semantics kernel | read fixture/projection prototypes; **no execution code** | AEF registry, ledger/fold, task binding | **blocked** — nothing to read prototypes *of* |
| 2 Isolation proof | prove browser/editor cannot reach execution/secret/ledger authority | *nothing* | **startable** |
| 3 Secure actions | author declarative profile references, render structured refusals | AEF action catalogue, capability profiles | **blocked** |
| 4 Operator/Fabric | runtime visualisation, operator UX, diagram↔Fabric navigation | AEF projection API | **mostly blocked** — its one independent slice, diagram↔Fabric navigation, **already shipped as T-611** |
| 5 Guided agentic | author/visualise agent nodes, scopes, outcomes | AEF prompt action, context envelope | **blocked** |
| 6 Routing/composition | visual routing explanation, sub-procedure composition | AEF router, binding authority | **blocked** |

**One of six is startable.** That is the finding, and it is also the argument against opening the
others: decomposing work whose inputs are counterparty-blocked manufactures a backlog that
*measures as progress* and cannot move. We have just spent a session establishing that a queue
which cannot distinguish "not started" from "blocked" misrepresents who is holding the work.

## 5. The objection that nearly killed the recommendation, and the control that answers it

**Objection (IW-3).** Arc 2 asks us to prove the browser/editor *cannot reach* execution, secret,
or ledger authority. No runtime, no secret store and no ledger exist yet. A proof that the editor
cannot reach something that does not exist is **trivially green and worth nothing** — the exact
absence-versus-not-looked failure this project has now hit four times (T-674/675/677/678), and a
fence that has never been red is a fence nobody knows works (PL-178: a green leg can assert
nothing, and the gate cannot tell).

**Why it is still the right arc.** The value is not the proof, it is the **ratchet**. The fence
is cheapest to install *before* the code that could breach it exists, and it is the one artefact
whose worth does not depend on Arc-0 ever exiting. Installing it later means installing it
against a codebase that already has the paths, at which point it is a migration rather than a
boundary.

**The control that makes it real, and the condition on this recommendation (IW-2).** The fence
ships **only** with a mutation control: deliberately introduce a path from the editor to a
stand-in execution/secret/ledger authority, demonstrate the fence goes **red**, revert,
demonstrate it goes green. A fence with no demonstrated red state is not evidence and must not be
counted as Arc-2 progress.

**Without that control this recommendation is NO-GO**, because the deliverable would be a green
check that certifies nothing — which is worse than no check, since it would be reported to AEF
as an isolation proof.

## 6. Recommendation

**GO**, scoped to Arc 2's Designer column only, conditional on §5.

Recommend **against** opening Arcs 1, 3, 5 and 6 now. Recommend **against** re-opening Arc 4:
its independent slice shipped, and the rest needs the projection API.

On a GO, the decomposition is expected to be three build tasks — the boundary enumeration (what
authorities exist or are stubbed, and every path the editor has to them), the fence itself, and
the mutation control — created as separate tasks under `arc-002`, not continued under T-681.

## 7. Alternatives considered

- **DEFER until Arc-0 exits.** Rejected: Arc-0's exit is not ours to cause, and two of three
  clauses sit with a counterparty's operator. Deferring to it is deferring indefinitely, which is
  the state we have just spent a session diagnosing.
- **Open all six arcs and let priority sort it out.** Rejected: five would be born blocked, and a
  backlog of blocked tasks reads as scope while measuring as progress.
- **Close arc-002 as complete.** Rejected: Arc 0 has not exited and the headline mechanic is
  unbuilt. Closing would require a demo of the mechanic firing (§ACD/G-062), which does not exist.

## 8. Open questions carried on the task

Filed as IW-1..IW-4 on T-681; none is disposed, because disposing them is exploration this
inception has not yet run. Summarised here for the reader:

1. **IW-1** — does "execution/secret/ledger authority" have a stateable definition on our side
   today, sufficient to enumerate paths against? *This is the first spike.*
2. **IW-2** — can the mutation control be built without introducing a real breach path into the
   shipped tree? *If no, the recommendation flips to NO-GO.*
3. **IW-3** — is a fence installed before the authority it guards exists a ratchet, or a green
   check that certifies nothing? *§5 is the argument; the mutation control is the test.*
4. **IW-4** — is AEF's Arc-2 column genuinely theirs, or would we need to stub it beyond a test
   double?

## 9. What this document does not do

It does not decide. `definition_ratified:`, `attestation:`, inception decisions and BVP
confirmation are the operator's. Nothing here has been sent to AEF as a commitment, and no reply
from them would ratify it.

## Dialogue Log

**2026-09-05 — operator:** *"Where are we now on the EWCR work? We should have an arc with tasks
like that. You should also evaluate the arc and the tasks and if there is a new scope, add that
as tasks. Are we doing that? Are we still on focus on the EWCR work?"*

**Answer given:** No on both counts. The arc existed but every task in it was closed, and the
focus star was on `arc-001`. New scope was not being added — six of seven roadmap arcs had never
been decomposed. This inception is the response to the third clause of that question.

**Course correction inside this task:** the first version of the recommendation was "GO, Arc 2"
without §5. Writing out the dependency table surfaced that Arc 2's proof is trivially satisfiable
while the authorities it fences are unbuilt, which would have delivered a green check certifying
nothing. The recommendation now carries a condition that can flip it to NO-GO, and the objection
is filed as IW-3 rather than settled by assertion.
