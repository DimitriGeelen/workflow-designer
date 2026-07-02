# T-031 — audit-process: v2-schema friction report

```yaml
task: T-031
type: dogfood-friction-report
generated: examples/aef-processes/audit-process.workflow.yaml
ground_truth: agents/audit/audit.sh
validator: tools/validate-workflow.py  # exit 0, no findings, first pass
authored: 2026-07-03
result: ONE new friction (F14 aggregation) + one validator gap — coverage extension
prior_slices: [T-021, T-022, T-023, T-025, T-027, T-028, T-029]
```

## What this is

Eighth dogfood slice, run **after** the friction-dry declaration to close a
**coverage gap**: none of the seven prior workflows exercised `parallelGateway` —
every one was sequential or exclusive-branching. The audit process is a
**scatter-gather / fan-out**, so it is the first workflow to use a parallel fork
and an AND-join. Mapping it tests the generator + validator on genuinely new
structural ground (concurrency, join, aggregation) rather than re-confirming
recurrences — and it did surface one new gap.

## The process (ground truth)

`fw audit [--sections ...]` (or cron): `should_run_section` gates ~20 logically
**independent** check sections (compliance, quality, traceability, enforcement,
learning, episodic, observations, gaps, handover, graduation, research,
structure, discovery, orchestrator, arc-completion, deployment, oe-*). Each
section calls `pass`/`warn`/`fail`/`info` (`audit.sh:384-410`), incrementing
shared `PASS_COUNT`/`WARN_COUNT`/`FAIL_COUNT` and appending to a `FINDINGS[]`
array. After all sections: SUMMARY prints tallies → a YAML audit record is written
→ **exit code by severity-max** (`FAIL_COUNT>0` → 2; `WARN_COUNT>0` → 1; else 0,
`audit.sh:4551-4557`) → push notification if any FAIL (T-709). The sections are
order-independent and share no data — the sequential bash loop is an
implementation detail; the *process semantics* are fan-out/fan-in. Modeled with a
representative **5 of the ~20** sections. Mapped cleanly (exit 0, first pass).

## Friction result — one new gap + recurrences

- **[F14 — NEW] fan-in aggregation / reduction.** The verdict is a **fold** over
  the `FINDINGS[]` collected across all branches: severity-max (any FAIL → fail,
  else any WARN → warn, else pass), plus the three running counters. v2's
  `parallelGateway` **join only reconverges control flow — it has no construct to
  COMBINE branch data.** Every prior join in the corpus was either a trivial
  re-convergence of *exclusive* branches (exactly one path taken, nothing to
  combine) or absent (linear). This is the first process where N branches all run
  and their outputs must be *reduced* to one value. Stashed in
  `aef.aggregation: {over, reduce, outputs}` — the fact that it had to go in the
  free-form bag IS the finding. **F14 is the fan-in dual of F1** (F1 = decision
  fans control OUT to edges; F14 = a join fans data IN to one verdict).

- **[validator gap — M1 input] `parallelGateway` is unvalidated.** The validator
  applies its gateway rules (`>= 2` outgoing, at-most-one-default) **only to
  `exclusiveGateway`** (`validate-workflow.py:277`). `parallelGateway` passes with
  zero structural checks: no fork/join pairing, no branch-count symmetry
  (fork out-degree vs join in-degree), no "a fork should have a matching join."
  This is a *validator* gap, distinct from the *schema-expressivity* frictions —
  and it is directly actionable in M1 as an additive rule set.

- **[F3↺] determinism** — every check section is deterministic fw-logic
  (grep/scan/count); no stochastic node. Carried as `aef.determinism`.
- **[F8↺] guard (section-filter variant)** — `should_run_section` conditionally
  activates each branch by the `--sections` filter: a per-branch activation guard.
- **[F5↺] sub-process** — the fail-branch `fw_notify` (T-709) is a side-effect
  sub-process handoff; no `callActivity`.
- **[F10↺] datastore** — writes the durable audit record
  (`.context/audits/${date}.yaml`, `LATEST-CRON.yaml`) and the discovery history.

## Map

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| **F14 fan-in aggregation/reduction** | **NEW** | §2.6 / SD-9 | S8 | 1/8 |
| F3 determinism | ↺ | P4 | S3/S1 | 7/8 |
| F5 sub-process | ↺ | SD-9 | S8 | 6/8 |
| F8 guard (section-filter variant) | ↺ | §3.2/SD-8 | S4/S3 | 6/8 |
| F10 datastore | ↺ | §2.5/Fabric | S5 | 4/8 |
| *(validator gap: parallelGateway unvalidated)* | M1 | 7.3 | — | — |

## Conclusion

The friction-dry signal held for **schema-expressivity of the seven governance
lifecycles**, but a **structurally new shape** (fan-out/fan-in) surfaced one
genuine new gap — exactly the outcome the synthesis predicted diverse shapes
might produce ("each new process either hardens a recurrence or surfaces a
genuinely new gap"). The new-friction count for a *new control-flow family* is 1,
not 0 — which sharpens the friction-dry claim: it was dry **within** the
sequential/exclusive family, not across all of BPMN's control-flow constructs.

Two distinct outputs feed forward:
1. **F14 (schema):** the parallel join needs an **aggregation / reduction**
   spec (`over` a collection, `reduce` op, emitted outputs) — the fan-in dual of
   F1. Add to the register.
2. **Validator gap (M1):** `parallelGateway` gets **zero** structural checks
   today. M1 should add fork/join rules (matching join for every fork; branch
   symmetry) — cheap, additive, product-side.

**Recommendation:** record F14 in the synthesis and note the parallelGateway
validator gap as an M1 work item. One more distinct shape worth probing before
re-declaring dry: an **event/timer-driven** or **compensation/rollback** process
(e.g. decommission with rollback) — the last major control-flow family the corpus
has not touched.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md.
