# T-736 Human AC#1 — evidence report (reviewer judge-t-736-r3-aa2fcbf766fa)

Revision reviewed: 348d8ec304988e7f52feb105c486bbf090bd4af3 (HEAD at review time matched).

## What the criterion asks
The operator is to rule on Arc-0 clause 1 (A ratify / B ratify conditionally / C decline)
and, for A or B, edit `attestation:` and `definition_ratified:` on clause 1. Expected:
"One letter, and the two field edits if A or B. Both fields are yours."

## What I checked
- `docs/research/executable-workflow/arc-0-exit-clauses.yaml`:
  - clause-1 (line 91): `definition_ratified: false` (line 103), `attestation: null`
    (line 115), `blocks_arc_0_exit: true` (line 400). No ruling has been made.
  - `counterparty_response_superseding` block (line 204 ff.) is present and quotes @1539:
    offset 1539, their commit 174f31777, measured at 996a4f9a5, 1279 cards, 544 Unknown,
    CORE/BROAD intersection 0/0, coverage control per surface, verdict scoped to the
    Arc-0 write set only, and AEF's own disclaimer that the post "is not a ratification"
    and "is input to your operator's ruling". `ratifies_anything: false`.
  - A later block (`counterparty_response_bounded_exchange_r2`, @1603) records CORE
    30 -> 31 files, still 100% carded.
  - No difference in this file between the reviewed revision and the worktree.
- Task file `.tasks/active/T-736-...md`: Human AC#1 unticked; the task states the two
  fields are the operator's (lines 71, 153-154); agent recommendation is option A (line 227).
- No ruling letter is recorded anywhere I found in the task file or the YAML.

## Not checked
- I did not open the /review/T-732 page (step 2); the criterion's host is a placeholder
  and the page is not needed to establish that no ruling exists.
- I did not read the arc message @1539 on the rail itself, only the YAML's quotation of it.
- I did not independently re-measure AEF's figures.

## Finding
The criterion is itself the act of ratifying (or declining) a counterparty attestation
that gates the Arc-0 exit. That is a sovereignty / project-direction call the task
reserves to the operator by name; a reviewer cannot make it and it has not been made.
The input the operator needs is in place and internally consistent.

Verdict: escalate.
