# T-596 Human AC#1 — reviewer evidence

Revision reviewed: b442604fcd9595cb838825198b93f008a72bb81c (HEAD at review time; register, gate scripts and task file unchanged against it).
Verdict: **amber** — the criterion's literal is out of date.

The brief says the evidence is images. No image is named in the criterion and none exists in `.context/reviews/evidence/T-596/`; the criterion's own steps are a `cat` and a script, so I ran those.

## What I ran

1. `cat docs/research/executable-workflow/operator-decisions.yaml` and a PyYAML parse of it.
2. `tools/_t596-arc0-exit-gate.sh` → exit 1. `--self-test` → exit 0, 14/14 legs pass.
3. `git show 33b7d204d:docs/research/executable-workflow/operator-decisions.yaml` (the commit that landed T-596, 2026-08-26).
4. Read `tools/_t596_arc0_check.py` lines 60-90, `arc-0-exit-clauses.yaml` clause-3, T-732's H1 box, `.context/reviews/restatements.jsonl`.

## Found

| Part of the criterion as written | Found at this revision | Meets literal? |
|---|---|---|
| H1 reads **open** | `status: resolved`, `decided_by: operator`, `decided_at: 2026-10-19` (T-732, commit b71bab127; opposite ruling of 2026-09-21 kept as history) | No |
| H3 reads **open** | `status: resolved`, `decided_by: operator`, `decided_at: 2026-09-22` (option D, T-830, commit 403502ea1) | No |
| Gate exits non-zero | exit 1 | Yes |
| Prints `BLOCKED` for the third clause, listing open ids | `clause 3  BLOCKED by 2 open question(s) / open: H5, H6 / resolved: H1, H2, H3, H4` | Yes |
| Four ids named (H1/H3/H5/H6) | Two ids (H5, H6) | No |

At landing commit 33b7d204d the register read H1 open, H2 resolved, H3 open, H4 resolved, H5 open, H6 open, so the reading the criterion asks about was the recorded state when it was written.

On the substance (was "open" right): the later history is consistent with it. H1 was ruled separately from the T-587 GO, twice, and the entry still says T-587 is not its source. H3 was ruled as option D, which replaced the in-use values instead of ratifying them. This is read from recorded artifacts; I did not see the operator's sessions.

A prior reviewer (V-20261116-c4c70fc6, revision 7b0c0d786) returned amber with a proposed restatement. `restatements.jsonl` has no T-596 row and the task file has no `**Restated:**` line, so that restatement has been neither accepted nor rejected. I checked its findings myself and they hold at this revision.

## Two things the operator should see

1. **H1's source_of_truth is the register itself.** `file` is `operator-decisions.yaml`, `path` is `decisions[id=H1].chosen` although the top-level key is `questions`. The register header requires an external artifact for every resolved entry, and this criterion's If-not clause warns against exactly that shape. The gate does not catch it: `_t596_arc0_check.py` only checks the named file exists (field agreement is checked for H2 only). The entry discloses this in its `note`, and says T-732's H1 box "wins" over the transcription; that box is still `- [ ]` (T-732 line 167).
2. **Ticking this criterion is wired to a ratification.** `arc-0-exit-clauses.yaml` clause-3 has `definition_ratified: false`, to become true "when the operator ticks T-596's Human AC, not before". That step is reserved to the operator; a reviewer verdict here is not that ratification.

## Proposed restatement

PROPOSED RESTATEMENT: [REVIEW] Confirm the register read H1 and H3 correctly as **open** when T-596 landed (commit 33b7d204d, 2026-08-26), that each was later moved to `resolved` only by an operator ruling (H1 under T-732, H3 under T-830), and that `tools/_t596-arc0-exit-gate.sh` exits non-zero and prints `BLOCKED` for the third Arc-0 clause naming exactly the questions still open in the register (H5 and H6 at this revision).

Against that restatement: met on the gate and on the landing-commit reading. The "operator ruling" part for H1 rests on an agent-written entry with a self-referential source and an unticked T-732 box, so it is met as recorded, not independently confirmed.
