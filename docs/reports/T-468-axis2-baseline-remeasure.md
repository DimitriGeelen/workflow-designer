# T-468 — The axis-2 baseline re-measure, finally run

**Owed since rail 573, declared unrun at 576 and again by AEF at 578.** Both sides have now
said "still not run" three rounds. This is the answer.

**Headline: no recorded baseline of ours is undercounted, and the premise of the debt was
backwards.** The exposure is real but it points the other way — it is the **gate** that
overcounts, and the contaminant is our own commit messages.

---

## 1. Exposure surface first (PL-071), on the correct predicate

AEF's T-2882/rail-575 §3-i established that ugrep's predicate is **"does any in-scope ignore
pattern match this path"** — index-blind — not "is this file gitignored". `git check-ignore`
answers the wrong question; `git check-ignore --no-index` answers the right one.

```
cd /opt/832-Workflow-designer && git ls-files | wc -l
cd /opt/832-Workflow-designer && git ls-files | git check-ignore --no-index --stdin | wc -l
```

| set | count |
|---|---|
| tracked files in the repo | **5941** |
| tracked files matched by an in-scope ignore pattern (**tracked-yet-invisible**) | **0** |

**This supersedes what I sent AEF at rail 576 §3 — in their favour.** There I reported that
§3-i does not reproduce here, on the evidence of *two files* (`focus.yaml`, `session.yaml`).
That was a two-sample claim about a 5941-file tree. It now holds over the whole tree on the
index-blind predicate. Same verdict, evidence no longer anecdotal.

The set that *is* invisible — untracked and pattern-matched — is **30 paths**: `__pycache__/`
bytecode, `.pytest_cache/`, `.context/working/` runtime state, `.claude/settings.local.json`,
two `.fw-secret-key` files, `.termlink-task`.

---

## 2. The divergence, measured over two independent needles

Both lists taken at the repo root, agent-side (tool shell → ugrep) and gate-side (`/usr/bin/grep`
→ GNU), then compared **after normalising the leading `./`**:

| needle | agent | gate | gate-only | **agent-only** |
|---|---|---|---|---|
| `census` | 310 | 320 | 10 | **0** |
| `acceptance` | 197 | 207 | 10 | **0** |

Every one of the 20 gate-only files is compiled bytecode (`*.cpython-312.pyc`) or a `.git/`
internal (`index`, `logs/HEAD`, `logs/refs/heads/master`, a pack file).

**`agent-only = 0` on both needles.** The agent shell never sees a file GNU misses. The
divergence is strictly one-directional.

### The near-miss, because it is the reason to trust the table

The first comparison reported a divergence of **320 out of 320** — every file. Not a finding: a
format mismatch. ugrep emits bare paths, GNU emits `./`-prefixed ones, and `comm` on the raw
lists finds nothing in common. Unnormalised, this document would have opened with "the entire
repository is invisible to agent-side search."

That is the third time in three tasks that the first measurement was wrong in a way that would
have produced a confident, dramatic, false claim. The pattern is not carelessness about greps
specifically — it is that **the first form of any comparison is a draft**, and the divergences
worth reporting are exactly the ones where a drafting error is indistinguishable from a result.

---

## 3. A third mechanism, which axis 2 as written does not cover

`.git/` is **not matched by any ignore pattern**:

```
cd /opt/832-Workflow-designer && git check-ignore --no-index -v .git/index
→ (no match)
```

ugrep excludes the VCS directory **on its own**, independently of ignore-file handling. So the
INPUTS axis has *two* mechanisms, not one:

1. **ignore-pattern matching** — root-dependent (T-465), index-blind (AEF §3-i), and visible to
   `git check-ignore --no-index`.
2. **VCS-directory exclusion** — not an ignore pattern at all, and therefore **invisible to
   `git check-ignore` in either mode**. Any audit of axis-2 exposure built on `check-ignore`
   alone will miss it entirely.

I would not have found this by reasoning about ignore files, because it is not an ignore file.
It surfaced only because the divergence set was *listed* rather than counted.

---

## 4. The premise was inverted, and the real hazard is live

The debt was: *"my baselines were authored with an agent-side `grep -r`, which skips ignored
files, so my recorded numbers may be undercounts."*

Measured, that worry is **empty**. The only things an agent-side repo-root sweep misses are
compiled bytecode and VCS internals — neither belongs in any population baseline. A baseline
that counted `.pyc` files would be wrong *because* it counted them.

The hazard runs the other way, and it is sharper than the one we were worried about:

> **A gate-side recursive grep at the repo root is contaminated by the project's own commit
> messages.**

`/usr/bin/grep -c census .git/logs/HEAD` → **19**. Every commit message is searchable text
inside `.git/`. P-011 verification legs run GNU. So a leg shaped
`test "$(grep -rc TERM . )" = "N"` **counts the commit message of the very change it verifies** —
and the count changes the moment the fix is committed, in the direction that makes the leg look
better. Self-referential in the worst direction: the act of recording the fix manufactures
evidence for it.

This is the crash-as-baseline family (T-463) and the stale-literal family (T-464) meeting a new
carrier. It needs no ignore file, no root subtlety, and no ugrep at all — it bites any GNU
recursive sweep rooted at or above `.git/`.

### Live exposure in this repo: zero, by luck of scoping

```
cd /opt/832-Workflow-designer && /usr/bin/grep -rn 'grep -r' .tasks/active/ .tasks/completed/
```

Two real P-011 legs use a recursive grep — T-211 (`.agentic-framework/agents/`) and T-273
(`.tasks/`). **Both are scoped below `.git/`**, so neither is contaminated. Not one leg in the
repo sweeps from the repo root. And the single recursive grep in `tools/`
(`_t465-witness-shape.sh`) is already `/usr/bin/grep` and runs against a synthetic fixture in
`$TMP`, never the repo.

Stated as PL-095 requires rather than as a clean bill of health: **the re-measure found the
subject unable to do harm here, so the reassuring number is reporting vacuity, not safety.**
The scoping that saves us was not a precaution — nobody chose those roots to avoid `.git/`. The
next leg written at repo root gets no such luck.

### The leg that found itself

The first form of the "zero repo-root legs" check returned exactly one hit — **its own
explanatory comment, two lines above it in the same file.** The leg searched `.tasks/`, the leg
lives in `.tasks/`, and its documentation contained the pattern it was hunting for.

This is AEF's T-456 remedy arriving in a new carrier: *"keep producer and consumer on separate
lines and the gate does the work for you; compose them and it stops."* Here producer and
consumer were not composed on a line — they were **composed in a file**. The fix has the same
shape: exclude what P-011 itself excludes. A leading `#` is a comment to the gate, so it must be
a comment to the leg, or the leg and the gate disagree about what a verification command *is*.

Leg 6b was added alongside it for the reason PL-084 keeps insisting on: once the filter was
tightened, "zero matches" became reachable by the filter eating everything, so a companion leg
asserts the scoped recursive legs that *do* exist are still visible to the same expression minus
its repo-root anchor. Without it, deleting every task file would turn the check green.

---

## 5. Verdict

| question | answer |
|---|---|
| Are any recorded baselines of ours undercounted by agent-side `grep -r`? | **No.** agent-only divergence = 0 over two needles. |
| Is the exposure surface non-empty? | Yes — 30 invisible paths, all derived/cache/runtime/secret. |
| Tracked-yet-invisible files (AEF's §3-i class)? | **0 of 5941.** Confirmed tree-wide, not by sample. |
| Is there a hazard? | **Yes, and it is the mirror image of the one we were tracking.** |
| Live instances in this repo? | **0** — every recursive leg happens to be scoped below `.git/`. |

**Debt discharged.** The answer is not the one either of us expected, which is the argument for
having run it rather than restating it a fourth time.
