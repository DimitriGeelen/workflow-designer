# T-353 Human AC#1 — reviewer evidence

Revision reviewed: d19a5fcf561614dfc4731a6609ca33ce3f742671. Criterion digest: 6b538bd07f39.

## What the criterion asks
A yes/no ruling: may an agent edit `## Verification` blocks inside `.tasks/completed/`
(23 archived lines in other owners' completed tasks). Expected: "a yes or no recorded here".

## What I checked
1. No ruling is recorded: the criterion is unticked and holds no yes/no. The task's own
   Recommendation section says DEFER (do not apply).
2. Nothing has been applied, as claimed: the 4 original `grep -q "VALID"` lines are still
   present in `.tasks/completed/` (T-288 x2, T-298 x1, T-299 x1); no modifications under
   `.tasks/completed/` in `git status`.
3. Step 1 as written (`bash tools/_t353-repair-probe.sh`): **13 passed, 10 failed** — not 16/16.
4. Step 2 as written (`python3 tools/_t353-convert.py`): 19 members FAIL, **DIVERGENT remaining
   after conversion: 19** — not 19/19 and 0.
5. Cause of 3 and 4 (found, not guessed): both tools extract the gate construct from
   `.agentic-framework/agents/task-create/update-task.sh` at run time. That line (2201) now
   reads `... eval "$_close_locks_cmd"; eval "$_verify_tmp_env"; cd "$PROJECT_ROOT" && eval "$cmd" ...`.
   `_verify_tmp_env` arrived with a re-vendor (first seen in 696aaee01, 2026-10-28, T-1319).
   The tools' runner sets `set -euo pipefail` and defines `_close_locks_cmd` and `PROJECT_ROOT`
   but not `_verify_tmp_env`, so every gate run aborts on an unbound variable and reads as
   GATE_FAIL. The harness has drifted from the gate; the patch set itself is not shown wrong.
6. Control: with `_verify_tmp_env=""` exported in the environment (no file changed), the same
   two commands give **probe: 23 passed, 0 failed** and **converted and proven: 19, failed or
   skipped: 0, DIVERGENT remaining after conversion: 0**. So the underlying proof still holds,
   but the "16/16" literal is out of date twice over (the probe now has 23 checks, per its
   T-787 portability/substitution legs) and the steps do not reproduce as written.
7. Step 3: `docs/reports/T-353-corpus-readiness.md` §3 ("4 latent" was wrong) and §4 (T-178
   live consequence, filed as T-354) exist.

## Verdict: escalate
The criterion is itself a request for an operator ruling on a convention about other owners'
archived records. That is a sovereignty / project-direction call; a reviewer cannot supply the
yes or no. Separately, steps 1 and 2 are out of date as written (see 3-6), which the operator
should know before ruling.
