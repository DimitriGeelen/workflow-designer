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

## 6. Blast radius

Every verification line in every task is re-evaluated under real errexit. **Currently-green lines
will go red, and that is the point** — but it means tasks that complete today may stop completing,
including tasks owned by other people.

Measured rather than estimated: see `docs/reports/T-352-member-scan.md` for the population
breakdown and the enumerated members. The distinction that matters:

- **SHAPED** — lines with a top-level `;`, structurally judged on their last command alone. This is
  an **upper bound and not a finding**. Most pin a zero-failure token (`passed, 0 failed`) and are
  perfectly safe.
- **PROVEN** — lines that PASS today and FAIL under the remedy, established by running both. These
  are the lines that would flip on the day the remedy lands.

Two independent numbers I got wrong before measuring properly, both recorded because the shape of
the error is the lesson:

- **332** was a naive `grep ';'` over verification blocks. It counts semicolons inside quotes,
  inside `sed 's/a;b/c/'`, and in `find … \;` — none of which are command separators.
- **26** was the first parser, which incremented nesting depth on `$` *and* again on the following
  `(`, so `$(…)` never returned to depth 0 and every top-level `;` after a command substitution was
  invisible. A confident undercount reads exactly like a careful one.

The parser now has a **self-test that must pass before any number is produced**, with cases in both
directions — a test with only positives passes for a parser that answers True to everything, which
is the mirror of the bug that actually occurred.

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
