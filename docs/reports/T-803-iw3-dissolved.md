# T-803 — IW-3 dissolves: the README never stated the non-goal

**IW-3 as carried:** *"Is the README's non-goal ('usable without `fw workflow run`') still the
project's position, or was it superseded by the confirmed yardstick?"*

**Answer: the question rests on a misquotation, and it is mine.** There is no non-goal, so
there is nothing to supersede and nothing for the operator to rule on.

---

## 1. What the README actually says

`README.md:13-15`, verbatim:

> It occupies the **Stabilization** tier of AEF's manifest-maturity ladder: richer than
> markdown dispatch templates, but **usable today without the planned `fw workflow run`
> executor**.

## 2. What I turned it into

| hop | text |
|---|---|
| README | "usable **today** without **the planned** `fw workflow run` executor" |
| Phase 5 §10 (mine) | "'usable without `fw workflow run`' is an **accepted non-goal** in the README" |
| T-788 IW-3 (mine) | "Is the README's **non-goal** … still the project's position?" |

**Two words were dropped in the first hop, and they carried the whole meaning:**

- **"today"** — a statement about the present state, not a permanent commitment.
- **"the planned … executor"** — the README explicitly *anticipates* the executor. It is not
  disavowing it; it is saying the designer is useful in the meantime.

A maturity statement became a non-goal. Then a non-goal became a contradiction with the
yardstick. Then that contradiction became an open question put to the operator.

**The README and the yardstick never disagreed.** The README says the executor is planned; the
yardstick says the workflow→application path is central; AEF confirmed at @1631 that the
executor is shipped and pinned. All three agree.

## 3. Why this kept happening today

Third citation defect in one session, all the same shape — a claim travelling more than one hop
from its source and arriving changed:

| | source | as carried | reality |
|---|---|---|---|
| T-787 | repair probe | "16/16" | 12+1; the target had been reaped |
| T-801 | T-353's AC step 1 | "16/16" | 23/23 after repair |
| **T-803** | **README:13** | "an accepted non-goal" | **"usable today without the planned executor"** |

The first two decayed because the world moved. **This one was wrong when I wrote it** — the
README had not changed since 2026-08-02. Paraphrase, not decay, and worse for it: a decayed
citation can be re-measured, while a paraphrase reads as evidence and is not obviously checkable.

## 4. What is left for the operator — small, and optional

One factual staleness, not a contradiction: the README calls the executor **"planned."** As of
@1631 it is **shipped and pinned in release v1.6.768**. The sentence is no longer accurate about
AEF's state.

Suggested wording, if wanted — **the README is the operator's and this task does not touch it**:

> It occupies the **Stabilization** tier of AEF's manifest-maturity ladder: richer than markdown
> dispatch templates, and usable both standalone and as the authoring front end for AEF's
> `fw bpmn compile` executor (shipped in v1.6.768).

**The case for changing it:** it is stale, and "planned" understates a dependency that now
exists and is maintained.

**The case for leaving it:** it is accurate about *this* project — the designer really is usable
without the executor, which remains true and is worth saying. And a README that chases every
upstream release becomes a changelog.

## 5. What this task did NOT do

- **Did not edit the README.** Retiring or rewording a published statement about what the
  project is for is the operator's call.
- **Did not correct T-788's IW-3 text.** T-788 is in `.tasks/completed/`, and **PD-308 does not
  cover this** — the ruling permits appending a sibling control leg where a teeth instrument
  requires it, and nothing else. Correcting prose in a completed task is outside it. The
  narrow ruling constraining its own author within the hour is the ruling working.
- The Phase 5 report **is** corrected in place, because it is the document that introduced the
  error and it is not archived.
