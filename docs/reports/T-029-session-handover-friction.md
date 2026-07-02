# T-029 — session-handover: v2-schema friction report

```yaml
task: T-029
type: dogfood-friction-report
generated: examples/aef-processes/session-handover.workflow.yaml
ground_truth: agents/handover/handover.sh
validator: tools/validate-workflow.py  # exit 0 (after the judge caught 2 real YAML errors)
authored: 2026-07-03
result: ZERO new friction — SECOND consecutive friction-dry slice
prior_slices: [T-021, T-022, T-023, T-025, T-027, T-028]
```

## What this is

Seventh dogfood slice and the **second friction-dry confirmation**. The
session-handover process (gather state → episodic-completeness soft gate →
metrics → write doc + LATEST.md → commit → audit → push) is a linear,
framework-dominant pipeline. We generated its workflow and validated it (exit 0;
the judge caught two real YAML errors first — a `${session}` flow-sequence break
and a `${task}:` colon — bringing the campaign's judge-catch rate to 3/7 slices).

**Result: no new friction.** Only recurrences (F3, F5, F8, F10). Two consecutive
dry slices on differently-shaped processes (T-028 evidence-gated state machine;
T-029 linear pipeline) is the convergence criterion the campaign set.

## The process (ground truth)

`fw handover [--commit]` (or PreCompact hook): resolve commit task → gather state
(git, tasks, focus) → **check episodic completeness** (warns + backfills missing
episodics; soft, non-blocking) → extract session metrics → write
`.context/handovers/<session>.md` + `LATEST.md` → auto-commit via git agent →
pre-push audit → push. Ownership → swimlanes: agent triggers; framework does
essentially everything else; human reads the result next session (outside this
flow). Mapped cleanly.

## Friction result — recurrences only

- **[F3↺] determinism** — the pipeline is almost entirely deterministic fw-logic;
  the only mild stochastic element is the "Suggested Action" synthesis in the doc
  (carried as an ordinary node). Carried as `aef.determinism`.
- **[F5↺] sub-process** — episodic backfill invokes `context.sh generate-episodic`
  as a sub-process; no `callActivity`.
- **[F8↺] soft gate** — the episodic-completeness check is an *advisory* gate
  (warn + backfill, never block) — a useful data point that gates come in
  blocking and non-blocking flavours (v3's gate construct needs a `blocking:
  bool` / severity field).
- **[F10↺] datastore** — reads git/tasks/focus; writes the handover docs +
  LATEST.md.

**Notable:** this process is almost entirely single-authority (framework lane).
No friction there — the schema handles a one-lane-dominant process fine — but it
is a reminder that not every process needs the full authority spread; the lanes
are descriptive, not mandatory.

## Map

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| F3 determinism | ↺ | P4 | S3/S1 | 6/7 |
| F5 sub-process | ↺ | SD-9 | S8 | 5/7 |
| F8 gate (soft variant) | ↺ | §3.2/SD-8 | S4/S3 | 5/7 |
| F10 datastore | ↺ | §2.5/Fabric | S5 | 3/7 |
| **(new)** | **none** | — | — | — |

## Conclusion — friction-dry reached

New-friction rate across the seven-slice campaign:
**6 → 2 → 2 → 2 → 1 → 0 → 0.** Two consecutive dry slices on structurally
different processes (evidence-gated state machine, linear pipeline) satisfy the
convergence criterion. The friction register **F1–F13 is complete** for the
v3 input-gathering phase; further slices are expected to only re-confirm
recurrences.

One refinement this slice adds to an existing friction rather than a new ID:
**F8 needs a blocking/advisory (severity) attribute** — gates come in hard
(work-completed battery, tier0) and soft (episodic-completeness) flavours.

**Recommendation:** declare v3 input-gathering complete; consolidate F1–F13 into
the synthesis (add F13, the F1-sharpening from T-028, and the F8 severity
refinement), then begin **M1 (validator → v3 structural parity)** against the
register. Remaining un-mapped processes (decommission, specification, design
task-types) are thin workflow-type labels rather than distinct lifecycles and can
be mapped opportunistically if ever needed.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md.
