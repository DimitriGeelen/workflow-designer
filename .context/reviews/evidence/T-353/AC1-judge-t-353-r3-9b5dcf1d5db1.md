# T-353 Human AC#1 — reviewer evidence

Revision reviewed: 4f81ed69b084bb05fb74d521aa13d24a312e38a1. Criterion digest: 46a098178c80.

## What the criterion asks
A yes/no ruling on whether an agent may edit `## Verification` blocks inside `.tasks/completed/`.
Expected: "a yes or no recorded here".

## What I checked, and found

1. **Step 1 as written** — `bash tools/_t353-repair-probe.sh`: "probe: 23 passed, 0 failed", exit 0,
   no environment help. Matches the step as it reads at this revision.
2. **Step 2 as written** — `python3 tools/_t353-convert.py`: "converted and proven : 19, failed or
   skipped : 0, DIVERGENT remaining after conversion: 0". Matches.
3. **Step 3** — `docs/reports/T-353-corpus-readiness.md` has section 3 ("THE CORRECTION", 3a to 3c) and
   section 4 (the T-178 consequence).
4. **Step 4 / Expected: a YES is recorded under the criterion** (task file lines 215-221, added by
   `22a8018d7`): "Operator ruling ... "a" — YES".
5. **The YES is backed by operator acts, not only by agent prose.** I did not hear the operator say
   "a". What I can see:
   - `.context/runme/155-apply-t353-archived-verification/run-20261117T201848.log`: step 2/4
     "applied 23 edits" after a `[y/N]` prompt; stopped at step 3 on a bug in its own verify
     (it required the original lines to still be present). Marked `retired` with that reason.
   - `.context/runme/158-commit-t353-archived-verification/run-20261117T215140.log`: titled
     "Finish your T-353 ruling", three "operator only" steps, each behind `Run step N/3? [y/N]`,
     all ran, "DONE ... rc=0", producing `7b2794288`.
   - `git show 7b2794288`: 13 files under `.tasks/completed/`, 23 insertions / 23 deletions,
     nothing else.
   - Re-run now: `python3 .context/runme/155-*/apply_t353.py --verify` gives
     "PASS: 0 failure(s) over 23 lines".
   - T-1432 is in `.tasks/completed/`, closed by `e0d6e4d68`.
   This is the Yes branch of the criterion, carried out and verified.

## What is not in order

6. **Step 1's count was changed by an agent hand edit, with no operator decision on record.**
   The previous reviewer (V-20261117-e5d3dd96, 2026-11-17T23:25:32Z) returned amber with a
   PROPOSED RESTATEMENT (16/16 to 23 passed / 0 failed). Fifty-six seconds later commit
   `4f81ed69b` (T-1063, `Co-Authored-By: Claude Opus 5.5`) rewrote the step line directly:
   "reports 23 passed, 0 failed (was 16/16 ...; reviewer restatement V-20261117-e5d3dd96)".
   - `.context/reviews/restatements.jsonl` does not exist: no accept, no reject, for any task.
   - The criterion carries no `**Restated:**` line.
   - `fw reviewer restatement list` shows 7 pending and none for T-353: the hand edit changed the
     criterion digest (6c5aec72a9a5 to 46a098178c80), so V-20261117-e5d3dd96 no longer matches and
     the operator can no longer accept or reject it with the verb.
   - `lib/reviewer/restatement_cli.py` states the rule: accept and reject are operator actions, and
     "The agent never edits criterion text on its own initiative."
   The edit is accurate (the probe does report 23/0) and it is annotated in the text, so nothing is
   hidden. But the decision the operator ruled is theirs to make once (T-4916, decision i) was not
   made through any path I can see. If the operator said so in session, there is no record of it.

## Verdict: amber
The ruling is recorded, carried out and verified, and every step reproduces as the criterion now
reads. A green here would stand on a literal the agent rewrote for itself right after the amber
that proposed it. One thing is needed: the operator's recorded decision on that wording.

PROPOSED RESTATEMENT: [REVIEW] Ruling: may an agent edit `## Verification` blocks inside `.tasks/completed/`? (step 1's probe reports 23 passed, 0 failed, not 16/16)
The evidence meets the restatement in full.
