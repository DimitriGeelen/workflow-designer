# T-797 — Design or instance? Measured across all three layers

**The operator's question:** *"We have workflow designs, the process designs, and we have the
instantiation of the process, where we want to track the execution. So for which one is this?"*

**Answer: neither, as those terms are normally used. The entire stack is the DESIGN side. No
layer anywhere models a run.**

---

## 1. The measurement

| layer | instance / run concept |
|---|---|
| The designer — `src/aef-workflow-designer.html`, 997 KB | `processInstance` 0 · `instanceId` 0 · `runId` 0 · `execution` 0 · `instantiate` 0 · `startInstance` 0 |
| The frozen standard — `aef-bpmn-mapping-v1.md` | `instance` 0 · `runtime` 0 · `execution` 0 · `invocation` 0 |
| AEF's compiler — per @1631 | reconciles **one** task set; does not create runs |
| Realization log — `.context/audits/bvp-realization.jsonl` | **absent** |

Controls, so those zeros mean something: the designer has 1035 `node`, 980 `lane`, 162
`version`; the standard has 35 `task`, 22 `lane`, 17 `owner`. The files are readable and the
vocabulary is rich — it is simply a vocabulary about **definitions**.

## 2. The decisive evidence is AEF's own reconcile semantics

`fw bpmn compile` is not an instantiation step, and their description of it says so without
meaning to. Reconciliation is idempotent on `(uid, source_bpmn_sha)`:

> new → create · unchanged → **no-op** · changed → refuse-clobber if human-touched ·
> deleted → orphan + flag

**Run it twice and you do not get two runs — you get the same tasks.** That is synchronisation,
not instantiation. `aef:uid` is described as *"the modify/create discriminator"*, which only
makes sense if a diagram node maps to **exactly one** task, permanently.

So the real shape of the chain is:

    one diagram  ──compile──▶  one task set, kept in sync with it

Not:

    one diagram  ──instantiate──▶  run #1, run #2, run #3 …

## 3. What that means in the operator's own terms

- **Process design** — fully served. The designer authors it, the validator checks it, the
  standard governs it, and three MCP tools now expose it to agents.
- **Instantiation / tracking the execution** — **does not exist, anywhere, on either side of
  the seam.** Not built here, not built upstream, not defined in the frozen standard, not
  claimed by AEF in @1631's list of what they own.

The stack models **process-as-template-for-the-backlog**: "how we do audits" becomes a set of
tasks that mirrors the diagram. It does not model **process-as-repeatable-run**: "the October
audit, started Tuesday, currently at step 3, blocked on step 2's approval."

## 4. Is that a defect, or the design?

Fairly: for a governance framework it may be deliberate. A process that describes *how a team
works* has one living backlog, not one per occurrence, and forcing runs on it would multiply
tasks without adding governance.

**But it is a deliberate answer to a question nobody appears to have asked out loud.** The
frozen standard does not discuss instances even to exclude them — 0 occurrences of the entire
vocabulary. An absent concept and a rejected concept look identical in a document, and only one
of them is a decision.

And it collides with the operator's yardstick, which says **"iterate"** — a word that implies
repetition. If "iterate" means *refine the design and recompile*, the current stack delivers it
today. If it means *run this process repeatedly and watch each run*, nothing does.

## 5. Why this is the more interesting question than T-788's

T-788 asked who builds the **compiler**. Answered: AEF, shipped and pinned, and the write must
stay inside their task-gate perimeter.

This question asks who builds the **instance layer** — and the honest answer is that nobody has,
nobody has claimed it, and the frozen standard is silent rather than exclusionary. That is an
open architectural question, not a settled ownership one.

**It is also much more plausibly "core functionality" than the compiler was.** Tracking
execution against a design is what makes a workflow tool a workflow tool rather than a drawing
tool. That is worth deciding deliberately rather than discovering later.

## 6. What this task does NOT do

It does not propose building an instance layer. That is a scope decision with an obvious
predecessor question — *does AEF consider instances theirs, as they considered the compiler
theirs?* — and asking is cheap, whereas guessing wrong is the T-786 error again.

**Recommendation: ask AEF where instances sit before anyone designs one**, and put the
"what does iterate mean" question to the operator in the same breath, because the two answers
together determine whether this is 832's work at all.
