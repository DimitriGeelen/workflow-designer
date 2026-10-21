# T-733 AC#1 — reviewer evidence (rung-1-same-vendor-independent)

Revision reviewed: 1212b40730dcb3aa57e3ae47df5d1912b932c195

## What I checked
- `docs/research/executable-workflow/arc-0-exit-clauses.yaml` lines 45-78 at the reviewed revision:
  the T-733 header comment and the `rail_citation_integrity` block (measured 2026-09-16,
  hub_topic_store: empty-on-restart, dangling_offsets [602, 643, 650, 734, 737, 741, 742],
  clause_state_changed: false).
- The header records three options explicitly as "NOT DECIDED HERE, AND NOT THE AGENT'S TO DECIDE":
  (1) attempt recovery of the old log from a surviving copy; (2) whether a rail whose runtime
  sits in /tmp is an acceptable substrate for citations treated as evidence; (3) re-pin clauses
  to quoted content only, dropping offsets as identifiers. "Surfaced to the operator, not actioned."
- Task file `.tasks/active/T-733-*.md` (owner: human): confirms the context; no ruling recorded.
- `git grep` across docs/ and .tasks/ at the revision for `rail_citation_integrity`, `/tmp/termlink`:
  no operator ruling found anywhere else.

## Finding
The precondition the criterion asks a reviewer to verify (options recorded, none actioned) is met:
the options are recorded and no clause state was changed. But the criterion itself is a request for
a RULING on what this project accepts as evidence for its Arc-0 exit register (an evidentiary
standard governing counterparty attestations with AEF), which is a project-direction / sovereignty
call. The register itself reserves it to the operator. Option (1) may also touch shared host
infrastructure (/tmp/termlink-0, /var/lib/termlink) outside this repo. A reviewer seat cannot
supply that ruling; doing so would be exactly the "agent invents the property and declares it met"
defect the register warns against.

## Verdict: escalate
