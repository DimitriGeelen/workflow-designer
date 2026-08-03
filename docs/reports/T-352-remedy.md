# T-352 — P-011 errexit suppression: remedy proposal

**Status: PROPOSED, NOT APPLIED.** The gate lives in `.agentic-framework/` (vendored). Changing
how every verification line in every task is evaluated is a framework-wide behaviour change —
G-008 upstream territory and the operator's ruling, not an agent's. This document exists so the
decision can be made from measurements rather than from a description.

## 1. The defect

`update-task.sh:1018` runs each `## Verification` line as:

```bash
if (unset TASKS_DIR CONTEXT_DIR _FW_PATHS_LOADED; eval "$_close_locks_cmd"; cd "$PROJECT_ROOT" && eval "$cmd") > /tmp/verify-$$.out 2>&1; then
```

The subshell is the **condition of an `if`**. Bash suppresses `errexit` inside an `if` condition,
so the `set -euo pipefail` at line 14 does not apply to `$cmd`. A line of the form `a; b` is
therefore **judged on `b` alone** — `a`'s exit code is discarded.

`pipefail` is *not* suppressed. It changes how a pipeline's status is computed rather than
trapping errors, and it survives. This is measured, not reasoned: `false | true` returns non-zero
under the gate's construct, which it would not without `-o pipefail`
(`tools/_t352-p011-errexit-probe.sh`, assertion `A/pipefail`).

So the template's sentence "P-011 runs each command under `set -eo pipefail`" is **half true**,
and the false half is the one that matters.

## 2. Why it is not exotic

The task template *prescribed* the shape, listed first and labelled "Safe pattern":

```bash
out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
```

That form was introduced for a real reason (L-387: `cmd | grep -q PAT` exits 141 on SIGPIPE) and
it does fix SIGPIPE. It also converts a single command into `a; b`, which is the exposure. The
documentation taught the defect, so it regenerated faster than it could be remediated. Fixed at
the point of teaching in `.tasks/templates/default.md` — see §5.

## 3. Proven live

```bash
out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
```

returns **PASS** on a document the validator exits 2 on and labels `INVALID`, because
`grep -q "VALID"` matches `INVALID` as a substring. Two independent defects stacked; either alone
would have been survivable. Reproduced by `tools/_t352-p011-errexit-probe.sh`, which **extracts**
the construct from `update-task.sh` at runtime rather than copying it, so the harness fails when
the gate is fixed. `tools/_t352-teeth.sh` leg (a) proves that: it applies the remedy below and
requires the probe to go red.

## 4. The candidate forms, measured side by side

| form | `a` fails, `b` succeeds | honest line | verdict |
|---|---|---|---|
| **A** `if ( eval "$cmd" )` | PASS | PASS | today's behaviour — wrong |
| **B** `if ( set -e; eval "$cmd" )` | **PASS** | PASS | **still wrong** |
| **C** `if ( … bash -c 'set -eo pipefail; eval "$1"' _ "$cmd" )` | FAIL | PASS | correct |

**Form B is the trap.** It is one word, it reads correct, and it changes nothing: the
errexit-suppressed context is *inherited* by the subshell and re-issuing the option does not clear
it. Anyone reasoning about this defect reaches for B first — I did.

The honest-line column is the positive control and it is what makes the table evidence. Without
it, "C fails more often than A" is equally consistent with C being merely stricter, and a
construct that refused everything would score identically on the first column.

## 5. Recommended change

```diff
-        if (unset TASKS_DIR CONTEXT_DIR _FW_PATHS_LOADED; eval "$_close_locks_cmd"; cd "$PROJECT_ROOT" && eval "$cmd") > /tmp/verify-$$.out 2>&1; then
+        if (unset TASKS_DIR CONTEXT_DIR _FW_PATHS_LOADED; eval "$_close_locks_cmd"; cd "$PROJECT_ROOT" && bash -c 'set -eo pipefail; eval "$1"' _ "$cmd") > /tmp/verify-$$.out 2>&1; then
```

Three deliberate details:

1. **`_ "$cmd"` passes the command as an argument, not by interpolation.** The obvious spelling,
   `bash -c "set -eo pipefail; $cmd"`, re-parses every verification line through a second round of
   quoting and breaks any line containing quotes — a worse defect than the one being fixed.
2. **`-e` and `-o pipefail` only; deliberately no `-u`.** Adding `nounset` would fail every line
   that references a possibly-unset variable, which is a separate (and much larger) change wearing
   the same patch.
3. **`eval "$_close_locks_cmd"` stays in the outer subshell.** The FD closes must happen before the
   child is spawned so the child inherits the closed descriptors (T-1493).

**Already applied under agent authority (point of teaching, in-project, not vendored):**
`.tasks/templates/default.md` now leads with an explicit errexit warning, demotes the capture form,
and promotes `cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out` to PREFERRED. `&&` is immune
because the exit status of `a && b` when `a` fails *is* `a`'s status — nothing needs to trap
anything. That claim is asserted in the probe (`A/and-form`) so the advice is measured rather than
plausible. The vendored copy at `.agentic-framework/.tasks/templates/default.md` carries the same
text and is left alone — G-008 upstream.

## 6. Blast radius — measured, and it inverts the case for the remedy

`tools/_t352-member-scan.py`, run over active/ + completed/:

| population | n |
|---|---:|
| ALL verification lines | 1331 |
| SHAPED (top-level `;`) | 322 |
| RUN (executed under both constructs) | 243 |
| **DIVERGENT** (passes today, fails under the remedy) | **19** |
| LATENT (both constructs agree) | 189 |
| SKIPPED (safety filter) | 79 |
| ANOMALY (timeout / no verdict) | 35 |

Static partition of the 322, decidable without execution:
**SUBSTRING-RISK 4 · ZERO-TOKEN 101 · OTHER 184 · NO-PATTERN 33.**

**The result is not the one this task was filed expecting.**

`DIVERGENT` aggregates two causes pointing in opposite directions — a false green the remedy
*fixes*, and a correct failure-path test the remedy *breaks* — and reading the 19 members shows
they are almost entirely the second kind:

```
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); echo "$out" | grep -q "E-XML-NODE-TYPE"
out=$(grep -c "id=\"brand-version\"" src/aef-workflow-designer.html); test "$out" = "0"
```

Both are **correct**. The validator exits non-zero on an invalid fixture by design and the line
asserts the right error code appears; `grep -c` exits 1 when it counts zero matches, which is
the very condition being asserted. Under the remedy both die.

So, honestly stated:

- **0 currently-manifesting false greens** in the real corpus. The defect is real and
  demonstrated on a constructed fixture; it is not firing anywhere in this tree today.
- **4 latent instances** — the SUBSTRING-RISK class, all `grep -q "VALID"` against
  `validate-workflow.py`. They pass honestly *because their documents are valid*, and become
  false greens the moment a document goes invalid — precisely the case the check exists to
  catch. **Latency is not safety here**; it is the check being untested in the only direction
  that matters.
- **19 correct lines the remedy would break.**
- **All 4 latent instances live in COMPLETED (archived) tasks** — T-288, T-298, T-299. Their
  verification blocks will not run again unless those tasks are re-completed, so the live
  exposure today is effectively **zero**. This is occupancy, not construction: nothing stops the
  next author writing `grep -q "VALID"` tomorrow, which is exactly why the template fix — not the
  gate change — is the part that had to land now.

**Therefore the cost/benefit runs the other way from the filing.** Applying the gate change today
buys removal of 4 latent risks and costs 19 working verification lines across other owners' tasks.
The cheap fix for all 4 is one character each — `grep -q "^VALID"` or `grep -q " VALID "` — with
no gate change at all.

My recommendation, contrary to what I expected when filing: **repair the 4 patterns now; do not
apply the gate change until the 19 are converted** (`;` → `&&` inverted, or the failing command
wrapped so its non-zero exit is expected). The gate change remains correct in principle and
should still land — after the corpus is ready for it, not before.

## 7. Recommended rollout

The remedy is one line, but its effect is global and lands on other owners' tasks. Suggested order:

1. Land the template fix (done — stops new instances).
2. Run `tools/_t352-member-scan.py` and read the PROVEN list. That list *is* the set of tasks that
   will stop completing.
3. Repair those lines (usually: swap `;` for `&&`, or tighten the grep pattern so it cannot match
   the failure output).
4. Apply the gate change, upstream to AEF via G-008.
5. `tools/_t352-teeth.sh` leg (a) and `tools/_t352-p011-errexit-probe.sh` assertion
   `A/false-green` both go red at step 4. **That red is the success signal**, not a regression —
   the probe was built to witness the defect and is expected to die with it.

Step 5 is written down because a harness that goes red on a successful fix is indistinguishable
from a harness that caught a regression, unless someone said so in advance.

## 8. What is deliberately not claimed

- The SKIPPED population in the member scan was **never executed**, so its status is *unknown*, not
  *clean*. Bulk-executing arbitrary verification lines from 341 task files is the exact shape that
  deleted this repository during T-350; refusal is the default and the hole is reported as a hole.
- Whether `errexit` is the right semantics for P-011 *at all* is a governance question, not a
  technical one. A stricter gate refuses more completions; that is the operator's trade to make.
