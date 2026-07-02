# T-028 — assumption-validation: v2-schema friction report

```yaml
task: T-028
type: dogfood-friction-report
generated: examples/aef-processes/assumption-validation.workflow.yaml
ground_truth: lib/assumption.sh
validator: tools/validate-workflow.py  # exit 0, no findings, first pass
authored: 2026-07-03
result: ZERO new friction — first friction-dry slice
prior_slices: [T-021, T-022, T-023, T-025, T-027]
```

## What this is

Sixth dogfood slice, run as a deliberate **friction-dry probe**. The assumption
lifecycle (`untested → validated | invalidated`, evidence-gated; invalidated
becomes a gap/risk) is a simple, near-acyclic evidence-gated state machine. We
generated its workflow and validated it (exit 0, first pass, no YAML catch).

**Result: no new friction.** Every gap this process touches is already in the
register (F3, F5, F7, F8, F10). This is the first slice to add nothing new — the
convergence signal the campaign was watching for.

## The process (ground truth)

`fw assumption add '<statement>' --task T-XXX` → status `untested`, `A-NNN`
(`assumption.sh:68`). Evidence is gathered, then `fw assumption validate A-NNN
--evidence '...'` or `invalidate A-NNN --evidence '...'` (evidence mandatory,
`:178`). Lifecycle `untested → validated | invalidated` (`:59-61`); invalidated
assumptions "become gaps or risks" (`:61`). Ownership → swimlanes: agent
registers + gathers evidence, framework records status + spawns the gap/risk,
human may adjudicate. Mapped cleanly.

## Friction result — recurrences only

- **[F3↺] determinism** — `gather evidence` is stochastic; register/validate/
  invalidate are deterministic fw-verbs. Carried as `aef.determinism`.
- **[F5↺] sub-process handoff** — invalidated → gap/risk is a cross-process
  handoff with no `callActivity`.
- **[F7↺] state machine** — untested → validated|invalidated; carried as
  `aef.state`. (Milder than prior slices: acyclic, so the flow/state gap barely
  bites — further evidence F7 is real but low-severity for simple lifecycles.)
- **[F8↺] evidence-required guard** — validate/invalidate both require
  `--evidence`; a guard precondition on the transition.
- **[F10↺] datastore** — writes `assumptions.yaml` and the gaps register.

**Notable non-friction:** the validated/invalidated branch is a **data-condition
gateway** (`evidence_supports?`), *not* a human decision — so it is expressible
cleanly in v2 and did **not** trigger F1. This is worth recording: F1 fires only
when a *human* owns the decision; agent/framework data-branches are already
first-class. That sharpens the F1 requirement (it is specifically about
human-authority decision outputs, not branching in general).

## Map

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| F3 determinism | ↺ | P4 | S3/S1 | 5/6 |
| F5 sub-process handoff | ↺ | SD-9 | S8 | 4/6 |
| F7 state machine | ↺ | SD-2 | S2 | 4/6 |
| F8 evidence/guard | ↺ | §3.2/SD-8 | S4/S3 | 4/6 |
| F10 datastore | ↺ | §2.5/Fabric | S5 | 2/6 |
| **(new)** | **none** | — | — | — |

## Conclusion

First **friction-dry** slice: a real process that surfaces no schema-expressivity
gap beyond the established register. Combined with the arc slice (one new friction)
and the decreasing new-friction rate across the campaign (6→2→2→2→1→**0**), this is
strong evidence the register (F1–F13) is **converging**. It also sharpened F1
(human-authority decisions only — data-condition branches are already fine).

**Recommendation:** one or two more diverse candidates (session-handover,
decommission) to confirm the dry signal holds on differently-shaped processes; if
they also add nothing new, declare the v3 input-gathering phase complete and move
to M1 (validator → v3 structural parity) against the F1–F13 register.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md — record the friction-dry
result and the F1 sharpening.
