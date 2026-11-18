# T-732 Human AC#2 (clause-3 ratification) — reviewer evidence

Revision reviewed: f7b11e8ba9f6857753d4931eda9872929067b567 (HEAD at review time; the three files read below have no
uncommitted difference from it).

## Checked
1. The criterion's own check, run as written, on the working tree and on the file as committed at the revision:
   prints `True False`. `clause-3` in `docs/research/executable-workflow/arc-0-exit-clauses.yaml` carries
   `definition_ratified: true`, no `ratification_pending` key, and
   `ratification: {by: operator, date: 2026-11-18, in: 832 T-732 (operator ruling 'a', in session; written by operator job 163)}`.
   Fields written in commit 974003222 (job 163); f7b11e8ba only renamed the record's `on` key to `date`, which now
   parses as a real key (the earlier run's note about `on` -> boolean True is fixed).
2. T-596's Human AC reads `- [x]` at this revision (`.tasks/completed/T-596-arc-0-exit-gate-is-uncheckable-the-opera.md`
   line 101). It is the box the operator restated (restatements.jsonl: decision accepted, by operator, accepting
   V-20261118-7571175e); the tick was applied from a green ledger verdict on the restated text
   (applied.jsonl, 2026-11-18T19:33:37Z, V-20261118-5a0608da, open_human_remaining 0).
3. The operator's ruling exists in the raw session log (`572fe488-...jsonl`): row 232960 (assistant, 17:23:18Z) offers
   "a. Approve the definition as written" / "b. Change it"; row 232967 (type=user, userType=external, 17:24:54Z)
   answers "[A". The criterion's "Operator ruling, 2026-11-18: 'a'" line matches.
4. `tools/_t596-arc0-exit-gate.sh`: exit 1; clause 3 BLOCKED on H5, H6 only (H1-H4 resolved); "Arc 0: 1 of 3
   satisfied". Matches the criterion's "measured on a copy" line, and shows the clause is now satisfiable (blocked by
   open questions, not by an unratified definition).

## Finding
Both halves of Expected are met as written: `True False`, and T-596's Human AC reads `- [x]`.

## Notes (do not change the verdict)
- Step 2 names `.tasks/active/T-596-*.md`; T-596 is closed and its file is now under `.tasks/completed/`. Expected
  names no path, so its literal is unaffected.
- The brief's `bin/fw` does not exist in this project; `.agentic-framework/bin/fw` was used.
- The repository alone cannot show that job 163 was run by the operator rather than an agent (one commit author for
  all commits). The ruling that authorises the write is verified in item 3.
