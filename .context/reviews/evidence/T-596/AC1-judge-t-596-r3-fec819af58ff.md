# T-596 Human AC#1 — reviewer evidence

Revision reviewed: 7b0c0d78684ef2f6ff19f4e7c4ac13c2ab57344c (HEAD at review time; the register, gate scripts and task file had no uncommitted changes).
Verdict: **amber** — the criterion's literal is out of date.

## What I ran

1. `cat docs/research/executable-workflow/operator-decisions.yaml`, and parsed it with PyYAML.
2. `tools/_t596-arc0-exit-gate.sh` (exit 1) and `tools/_t596-arc0-exit-gate.sh --self-test` (exit 0, 13/13 legs pass).
3. `git show 33b7d204d:docs/research/executable-workflow/operator-decisions.yaml` (the commit that landed T-596).
4. `python3 tools/_t830-correlation-gate.py` (exit 0).

## What I found

| Part of the criterion as written | Found now | Meets literal? |
|---|---|---|
| H1 entry reads **open** | `status: resolved`, `decided_by: operator`, `decided_at: 2026-10-19` (recorded under T-732, commit b71bab127; an earlier opposite ruling of 2026-09-21 in 22014fea6 is kept as history) | No |
| H3 entry reads **open** | `status: resolved`, `decided_by: operator`, `decided_at: 2026-09-22` (option D, recorded under T-830, commit 403502ea1) | No |
| Gate exits non-zero | exit 1 | Yes |
| Prints `BLOCKED` for the third clause, listing open ids | `clause 3  BLOCKED by 2 open question(s)  open: H5, H6  resolved: H1, H2, H3, H4` | Yes |
| Four ids named (H1/H3/H5/H6) | Two ids named (H5, H6) | No |

At the landing commit 33b7d204d the register read H1 open, H2 resolved, H3 open, H4 resolved, H5 open, H6 open. So the reading the criterion asks about was the recorded state when T-596 landed.

On the criterion's substantive question (was H1 already answered by the T-587 GO; were the in-use correlations already ratified): the later history is consistent with "open" having been right. H1 was ruled separately, twice (2026-09-21, then reversed 2026-10-19), and neither ruling cites the T-587 GO as its source; the register still says "T-587 is NOT this question's source_of_truth". H3 was ruled as option D, which replaced the in-use values `ewcr-v1` / `ewcr-v1-designer-fixture` with arc-derived ones rather than ratifying them. This is my reading of recorded artifacts; I did not see the operator's sessions.

## Two things the operator should see before accepting a restatement

1. **H1's source_of_truth points at the register itself.** `source_of_truth.file` is `docs/research/executable-workflow/operator-decisions.yaml` and its `path` is `decisions[id=H1].chosen`, although the file's top-level key is `questions`, not `decisions`. The register header says every resolved entry must name "an external artifact that independently carries the decision", and this criterion's own If-not clause warns against a resolution with no source. The gate does not catch this: `tools/_t596_arc0_check.py` lines 70-82 only check that the named file exists, and the field-by-field agreement check exists for H2 only. The H1 entry discloses this openly in its `note`, and its `ruling_channel` says T-732's H1 Human AC is still unticked and "the tick wins". That box is unticked at this revision (T-732 line 167) and carries a prior reviewer escalation (V-20261019-55e219da). H3's source (`source-manifest.yaml`, `correlation`) is external and does carry both values; T-830's gate passes.
2. **Ticking this criterion is wired to a ratification.** `arc-0-exit-clauses.yaml` clause-3 has `definition_ratified: false` with `ratification_pending`: "It becomes ratified when the operator ticks T-596's Human AC, not before." T-732 line 185 says "Only you may tick it" and that the agent is forbidden from writing `definition_ratified`. A reviewer verdict on this criterion should not be read as that ratification.

## Proposed restatement

PROPOSED RESTATEMENT: [REVIEW] Confirm the register read H1 and H3 correctly as **open** when T-596 landed (commit 33b7d204d, 2026-08-26), that each was later moved to `resolved` only by an operator ruling (H1 under T-732, H3 under T-830), and that `tools/_t596-arc0-exit-gate.sh` exits non-zero and prints `BLOCKED` for the third Arc-0 clause naming exactly the questions still open in the register (H5 and H6 at this revision).

Against that restatement the evidence above is met on the gate and on the landing-commit reading. The "operator ruling" part rests for H1 on an agent-written register entry with a self-referential source and an unticked T-732 box (finding 1), so it is met as recorded, not independently confirmed.
