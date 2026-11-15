# Your review, in one pass (2026-11-15)

Three ticks are yours alone; no agent may give them. Each opens on its own Watchtower review page. The
fourth item is optional. Paths are on Watchtower (its address is in `.context/working/watchtower.url`); every item
is also on `/approvals`.

## 1. The project objectives (T-986): what the Workflow Designer is for

**Open:** `/review/T-986`

**Tick:** "The objectives say what 832-Workflow-designer is for, in words you would use".

**What you are signing** (`.context/project/objectives.yaml`): *the designer is AEF's process add-on. It captures a
process completely enough to execute it, so that a human and an agent work the same picture from idea to running
implementation. Processes are modelled once as templates and run many times as instances, for AEF and for other
projects.*

| | in plain words |
|---|---|
| O-1 | A step on the diagram carries everything an implementer needs, and it agrees with its task. Tasks stay canonical; a difference is a reported defect, never a silent one. |
| O-2 | A map says whether it is a picture (documentation) or a plan of work. The designer never promotes it and never refuses on that; AEF decides. |
| O-3 | Every real instance (task, inception, sprint item) knows which template it follows and which step it is on, and the system can answer that. |
| O-4 | A running process is observable. The designer warns and adds friction, never blocks: you can always override, with who and why recorded. It grows stricter as a process matures from draft to ratified. A step past its deadline shows as stalled. Steps can be marked as needing a human, with the reason. |
| O-5 | Many projects (AEF, Greenfield, Sprind, more) each design their own workflows, and nothing is specific to one project. Their real maps come back to us as field feedback and improve the designer. Each project's data stays where its rules say. |
| O-6 | A map round-trips losslessly to AEF's procedure form within the frozen mapping standard. Existing work can be drawn as a picture; that part is not measured yet. |
| O-7 | A step can say how it is meant to run: script or service first, an agent as fallback, and which kind of worker. That is a preference; AEF's runtime selects. |
| O-8 | A process learns from use: a deviation becomes a proposed template change sent to AEF, never applied silently. |

**Out of scope:** a general-purpose BPMN editor; replacing the task system; executing or approving anything (that is
AEF's runtime).

**If a line is not yours:** tell the agent which, and it changes the file before you tick.

## 2. H1, Arcs 4-6 revive the deferred work (T-732): confirm your 2026-10-19 ruling

**Open:** `/review/T-732` (the criterion "Rule H1 …")

**Tick:** it confirms what the register records you said on 2026-10-19: *"So definitely want all this stuff that we
discussed here, absolutely. If you can build it, that would be great."* That was confirmed with "1": revive all four
deferred tasks (T-279, T-280, T-281, T-282) and build them, callActivity (T-282) first, with the lenses raised with
AEF.

**Why it needs your tick:** only an agent's written record of a verbal ruling stands behind it, and the reviewer
escalated it (V-20261019-55e219da). The register already reads `resolved`; your tick is the provenance.

**One thing to know first:** T-282 means the designer will one day support `callActivity`. Today the validator
rejects it by design, and today's kit fix (T-1417) tells vendors not to draw one. Once T-282 ships, the kit text must
change with it. The agent records this on T-282.

**If the record is wrong:** say what you ruled, and the agent corrects the register before you tick.

## 3. The Arc-0 clause-3 definition (T-596): the gate itself, and a criterion that has gone stale

**Open:** `/review/T-596`

**Read this first.** The criterion's text predates your rulings. It asks you to confirm that the register shows H1
and H3 as **open**. Today the register shows both as **resolved**: H1 on 2026-10-19 (item 2), H3 on 2026-09-22. The
gate, run today, says: *clause 3 BLOCKED by 2 open question(s): H5, H6; resolved: H1, H2, H3, H4.*

So you have two choices:
- **a) Tick it** as "the register and the gate read my rulings correctly as they stand today". Then set
  `definition_ratified: true` on clause-3 in `docs/research/executable-workflow/arc-0-exit-clauses.yaml` and delete its
  `ratification_pending:` block. Only you may write those fields.
- **b) Have the agent rewrite the criterion** to today's state first (it is a partial-complete task, so the rewrite is
  a logged Tier-2 edit), then tick.

The agent recommends **a)**. The criterion's purpose, a gate that cannot be satisfied without your rulings on file, is
met and visible in today's gate output. What is left (H5, H6) are not yours to tick here: H5 is with the reviewer, and
H6 waits on AEF (R7 = AEF T-5144, N-1/N-2 with AEF's operator).

## 4. (optional) Clause 1: AEF answered, and did not attest (T-597)

**Open:** `/review/T-597`

On 2026-08-27 AEF replied to clause 1 with its own verdict: not enriched, not validated. A reply is input to your
ruling, not the ruling, so clause 1 stays blocked until you rule on it. Not urgent: Arc 0 also waits on clause 2
(AEF's attestation) and on H5/H6.

---
*Arc 0 stands at 0 of 3 clauses satisfied. After items 1-3 the project's goals are ratified and every ruling of yours
that Arc 0 needs is on file. The rest is AEF's (R7, N-1/N-2, the clause-2 attestation) and the reviewer's (H5).*
