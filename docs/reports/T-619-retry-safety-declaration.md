# T-619 — Retry-safety declaration on task-like nodes

**Type:** inception · **Status:** exploring · **Filed recommendation:** NO-GO (on minting a new key)

## The question

The operator asked for a retry-safety field: a way for a node to say whether re-running it is
safe, so a failure can be routed back to an agent for remediation without the retry itself
causing harm.

T-618 shipped `determinism` because the corpus had *already settled it* — 215 authored nodes,
three values. The question here is whether retry safety has the same standing, or whether
building it means inventing vocabulary on the wrong side of a seam.

## Findings

### F1 — Two silences (A-1 confirmed)

| Probe | Result |
|---|---|
| `grep -Ei 'idempot\|retry\|rerun\|replay\|compensat\|at-least-once\|exactly-once'` over `docs/standards/aef-bpmn-mapping-v1.md` | **0 matches** |
| same class over `examples/**` | **0 authored occurrences** |

A retry-safety key today has no author and no consumer. Minting one is the exact failure mode
T-617 argued against for the `execution` workflow_type — one task ago.

### F2 — `determinism` does NOT predict retry safety (IW-2 answered, and this is the finding)

Cross-tabulating the 39 corpus nodes carrying `sideEffect` against their `determinism`:

| determinism | retry class | n |
|---|---|---|
| deterministic | accumulates | **20** |
| deterministic | overwrite | 12 |
| deterministic | no-op | 5 |
| stochastic | overwrite | 2 |

**37 of 39 side-effecting nodes are `deterministic`, and that single value spans all three
retry classes.** A runtime reading `determinism: deterministic` and concluding "safe to re-run"
is wrong on 20 of them. Exemplars, all authored `deterministic`:

| sideEffect prose | behaviour on re-run |
|---|---|
| `creates a GitHub Release (--generate-notes --latest)` | a second release |
| `creates a local annotated git tag` | fails — tag exists |
| `appends {timestamp, task, flag, caller, reason}` | duplicate audit record |
| `charge reversed on payment provider; ledger entry written; receipt emailed` | **double refund + second email** |

Three distinct behaviours under repetition — harmless, fails, harms — none of them
distinguishable from `determinism`. **The gap is real.** This is the measurement that stops
NO-GO from being a shrug.

### F3 — The raw material is already authored, but as prose (A-2 half-falsified)

`sideEffect` carries 40 values. The authors are already reaching for the distinction unprompted:
**5 of them literally say "none"** — `none (read-only)`, `none (read-only gate)`,
`none (in-memory string)`, `none  # dry-run: preview only`.

Leading-verb census: `appends` 9 · `none` 5 · `creates` 4 · `writes`/`write` 6 · `sets` 3 ·
then `moves`, `pushes`, `consume`, `touch`, `git mv`, `charge`, `runs`, `proposes`, `graduates`.

The verb recovers the retry class. But **a verb heuristic over free prose is my invention, not
a contract**, and no runtime should depend on it. So `sideEffect` is the raw material, not the
declaration — A-2 is right that the slot exists, wrong that it already answers the question.

### F4 — Build cost is not the blocker (IW-4 answered)

`src/aef-workflow-designer.html:9870`:

```js
const carriedKeys = aefKeys.filter(k => !scalarHandled.has(k) && typeof aef[k] !== 'object').sort();
```

T-570 carriage means **any new scalar key round-trips for free** — no emitter work. Surfacing it
costs one line in `AEF_FIELDS` per node type plus one `FIELD_META` entry. This could ship in a
session. **Cheapness is not authority**, and that is the point: the reason to stop here is
ownership, not cost.

## The seam

Roadmap §2.1 assigns idempotency semantics to **AEF Arc 1**. A node may *declare*; the designer
may not *define*. Question posted to 999-AEF at rail offset **636** in three parts: (1) does Arc 1
have a vocabulary we can adopt verbatim; (2) if not, is `no-op | idempotent | accumulates` a
defensible starting shape or does Arc 1 need compensation handlers / retry budgets /
at-least-once vs exactly-once; (3) should `sideEffect` prose stay as the human-readable companion.

Per §2.3 a reply is **input to the operator's ruling, not the ruling itself**.

## Dialogue Log

**Operator (x4, verbatim):** asked whether run-time/execution tasks should be a task type, and
whether tasks should distinguish stochastic from deterministic — a deterministic task being a
script, CLI command or API call; a stochastic one being able to route its failure back to an
agent to evaluate, act on, and remediate.

**Operator, option 4:** "keep building rather than discuss" — the named pieces were the
round-trip harness covering `determinism` (**done, T-618**) and the retry-safety field (**this task**).

**Agent course-correction:** filed NO-GO on *minting a key*, not on the operator's request. The
operator's underlying need — a safe remediation loop — is confirmed real by F2. What is refused
is unilateral authorship of AEF's vocabulary, not the feature.
