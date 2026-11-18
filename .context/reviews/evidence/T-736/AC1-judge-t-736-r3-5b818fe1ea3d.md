# T-736 Human AC#1 — evidence report (reviewer judge-t-736-r3-5b818fe1ea3d)

Revision reviewed: 3451c9b37ba6d29a7c64611441beb86d510533e3 (HEAD matched; the register and
the two gate scripts in the worktree are identical to that revision).

## What the criterion asks
The operator rules on Arc-0 clause 1 (A / B / C). Expected: "One letter, and the two field
edits if A or B." Option A: `attestation:` cites @1539 / their commit `174f31777`,
`definition_ratified: true`, and "Arc-0 moves to 1 of 3."

## What I checked and found

1. **The letter.** Task file line 149: "Operator ruling, 2026-11-18 ... 'A' — ratify", with the
   operator's words quoted. One letter, A.
2. **The two field edits** in `docs/research/executable-workflow/arc-0-exit-clauses.yaml`,
   clause-1 (parsed with a YAML loader, not only read):
   - line 103 `definition_ratified: true`.
   - lines 115-123 `attestation:` is a mapping: attested_by "999-Agentic-Engineering-Framework
     (AEF T-3394, arc-019)", attested_at "agent-chat-arc @1539, correlation EWCR-ARC0-ATTEST-832",
     their_commit 174f31777, measured_at_their_commit 996a4f9a5, measurement "CORE/BROAD
     intersection 0/0 with coverage control; r2 @1603 CORE 31/31", ratified_by operator,
     ratified_on 2026-11-18. It cites @1539 and 174f31777 as option A requires, and agrees
     with the `counterparty_response_superseding` block in the same file.
   - Clause 2 and clause 3 are untouched: `definition_ratified: false`, `attestation: null`,
     `blocks_arc_0_exit: true`.
3. **Who made the edits.** Commit 9b6ee8c6c (operator job 161) set both fields; commit
   3451c9b37 (operator job 162) rewrote the attestation from a string to a record and added
   `satisfied: true` / `blocks_arc_0_exit: false`. In
   `.context/runme/162-fix-arc0-clause1-shape/job.sh` the write and the checker run are
   `step_operator` steps; `run-20261118T135359.log` shows step 2/5 run after the y/N prompt,
   "written; the file parses", commit 3451c9b37, and step 3/5 ok.
4. **"Arc-0 moves to 1 of 3".** I ran `bash tools/_t596-arc0-exit-gate.sh`: exit 0, prints
   "clause-1   SATISFIED", "clause-2   BLOCKED — awaiting attestation from aef",
   "clause-3   BLOCKED — open operator decisions in the H-register", "Arc 0: 1 of 3 satisfied".
   The crash the previous reviewer (13b1b5435435) reported at revision 9b6ee8c6c is gone.

## Noted, not held against the criterion
- Dated history entries inside clause 1 still say "attestation: above is still null",
  "definition_ratified: is still false", "Arc 0 remains 0 of 3" and "Three clauses, zero
  satisfied" (around lines 197-212, 259-261, 335-336, 379, 407). They describe the state when
  each entry was written; the live fields and the gate say otherwise. A one-line pointer above
  them would stop a later reader taking them as current.
- The gate's closing text still reads "Clauses 1 and 2 ... need an attestation from AEF",
  which is now true only of clause 2.

## Not checked
- The brief says the evidence is images. None is named in the criterion and none exists in
  `.context/reviews/evidence/T-736/`. The criterion is a ruling-plus-file criterion, so I judged
  the task file, the register, the commits, the job log and the gate. No image was judged.
- I did not open /review/T-732 (placeholder host) and did not read @1539 on the rail, only the
  register's quotation of it. I did not re-measure AEF's figures: the ruling accepts them and
  that call is the operator's.
- I cannot verify from the repository that the quoted words were spoken by the operator; the
  y/N answers at the operator-only steps of jobs 161 and 162 are the corroboration.
- `bin/fw` in the brief does not exist here; `.agentic-framework/bin/fw` was used.

## Finding
The operator ruled A; both clause-1 fields carry the ruling in the shape the gate reads; the
gate reports Arc 0 at 1 of 3.

Verdict: green.
