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

**2026-09-05 — operator recorded GO via Watchtower (commit `c236d997`), before S1 and S2 ran.**
Two of the three NO-GO arms are conditioned on spike outcomes ("S1 finds no authority at all",
"IW-2 resolves negative"), so the decision was taken on §4's dependency table alone and its own
conditions were still untested at the moment it was recorded. The spikes were run afterwards
rather than skipped — §10 and §11 are their output. Had either resolved negative, the correct
move was to return it to the operator as a failed condition, not to absorb it silently.

---

## 10. S1 output (IW-1) — what "execution / secret / ledger authority" actually means here

Measured 2026-09-05 against `src/aef-workflow-designer.html` (11,240 lines) and
`tools/gallery-serve.py` (788 lines). The editor is a single HTML file; the only thing it can
reach is the seven-route API on the gallery server. That pair IS the whole surface.

| named authority | exists in this tree? | reachable from the editor? |
|---|---|---|
| **Execution** | **No runtime exists.** The server holds exactly one `subprocess` call — `hostname -I`, fixed argv, no shell — inside the startup banner at `tools/gallery-serve.py:773`, structurally outside every request handler. | **No path.** |
| **Secret** | **None.** 0 `document.cookie`, 0 `crypto.subtle`, 0 token/key/password handling. All 26 storage hits are `localStorage` editor *preferences* (routing, snap, label, view) plus autosave. | **Nothing to reach.** |
| **Ledger** | **Yes** — `.editor-versions/<id>/index.json`, an append-per-save version ledger. | **Yes, by design** — `/api/save` appends. |
| **Filesystem write into the git tree** *(unnamed by the arc — and the real one)* | **Yes** — `/api/save` writes `examples/aef-processes/rendered/<id>.bpmn` into the committed corpus. | **Yes**, gated existence-or-promotion (T-138). |

### The NO-GO arm did not fire, and it was closer than expected

The arm reads: *"S1 finds no execution/secret/ledger authority in this tree at all, stubbed or
otherwise."* Ledger authority exists and is reachable, so the arm does not fire. But **two of the
three named authorities do not exist here at all** — and that is the finding, not a footnote.

Fencing "the editor cannot reach execution or secrets" today would be fencing two absences. That
is precisely the trivially-green proof §5 warned about. What the fence must actually guard is the
pair that *does* exist and *is* reachable: **the version ledger, and the write path into the git
tree.**

### What guards them today — the whole list, and it is two items

1. `ID_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')` (`tools/gallery-serve.py:51`) — anchored, no dot,
   no slash, so no traversal. Every id-bearing route validates through `_valid_id` (`:552`), plus a
   containment check on top (`:111`).
2. The existence-or-promotion gate (T-138) — a new id is scratch and is **not** published into the
   committed corpus unless explicitly promoted.

Static reads are separately confined: `DOCROOT = build/gallery` (`:55`), not the repo root, so
`super().do_GET()` cannot serve `.git/` or `.context/`. **Reads are confined to `build/gallery`;
writes reach outside it.** That asymmetry is the fence's subject.

### Why this makes the arc stronger, not weaker

§5's worry was a fence with no possible red state. That worry is now retired on evidence: both
guards are single regex/boolean conditions in one file, and a one-character mutation to either
(a dot in `ID_RE`; forcing `promote` true) produces a real, demonstrable breach in a throwaway
root. The fence is not guarding a hypothetical future runtime — it is **ratcheting two real
guards that exist today and could regress silently in a single edit.**

Corollary worth carrying into the build tasks: the boundary enumeration should be written against
*ledger + tree-write*, and should state plainly that execution and secret authority are absent
rather than asserting they are unreachable. An absence reported as a successful defence is the
T-674/675/677/678 failure class, and reporting it to AEF as an isolation proof would be exactly
the harm §5 named.

### The guard that is documented but not worn

`_within_repo` (`tools/gallery-serve.py:109`) is the traversal guard, and its own docstring calls
it *"belt-and-braces on top of the ID_RE format check — a valid id still shouldn't escape the
tree."* It is referenced in exactly one place: `archive_move` (`:120`), on the **delete** path.

**It is never applied on the `/api/save` write path.** The belt exists; the write path is not
wearing it. Today `ID_RE` alone holds the line — one anchored regex is the entire distance between
the browser and the git tree. §11 demonstrates that behaviourally rather than by reading.

---

## 11. S2 output (IW-2) — the mutation control, and its verdict

**Question:** can the control be built without introducing a real breach path into the shipped
tree? If no, the recommendation flips to NO-GO.

**Answer: yes. IW-2 resolves positive.** Prototype:
`scratchpad/s2-mutation-control.py` (throwaway; the shipped artefact is a build task).

Method — the shipped file is *copied*, never edited. The copy runs with `--repo`/`--docroot`
pointed into a throwaway root, so even a successful breach lands inside the scratchpad. The
control POSTs `/api/save` with `id: "../escaped"`, which resolves
`REPO/.editor-versions/../escaped` → `REPO/escaped`: outside the version store, inside the
throwaway root.

| phase | `ID_RE` | HTTP | escaped? | |
|---|---|---|---|---|
| 1 baseline | pristine | 400 | no | fence holds |
| 2 mutated | widened to admit `.` and `/` | **200** | **yes** | **fence breaks — the red state** |
| 3 reverted | pristine | 400 | no | fence restored |

Plus a fourth leg asserting the shipped `tools/gallery-serve.py` is still byte-pristine at the
end. All four pass; the spike exits 0.

Phase 2 is the load-bearing result. Widening **one regex** — with no other edit — produced a
write outside the version store, which confirms behaviourally what §10 found by reading: nothing
else on the save path checks containment. The fence therefore has a demonstrated red state, and
Arc 2's proof is not the trivially-green artefact §5 feared.

### The control lied on its first run, and the reason matters more than the result

Run 1 reported phase 2 as **no breach** and printed `IW-2 VERDICT: NOT BUILDABLE`. Taken at face
value that is a failed GO condition, and the correct response would have been to hand the arc back
to the operator as NO-GO.

It was wrong. The witness was named `ESCAPED`, and the widened regex admits only `[a-z0-9_./-]` —
so the **mutated** guard refused the id too, for reasons having nothing to do with containment.
Phase 2 could not have gone red no matter how broken the fence was. This is PL-177 exactly: the
control produced a confident verdict for a broken reason, and the verdict it produced was the
*alarming* one, which is the direction least likely to be questioned.

Two things follow for the build tasks. First, the shipped control needs a **meta-assertion**: the
mutated phase must verify the escape id is actually *admitted* by the mutated guard, so "no breach"
can be distinguished from "never tested". Second, this is the same shape as PL-178 — a leg that
asserts nothing while reporting a definite result — and it is now the fifth instance in this
project's register. A control is not evidence until it has been shown to fail for the right reason.
