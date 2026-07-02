# T-033 — revisit-due-scan: v2-schema friction report

```yaml
task: T-033
type: dogfood-friction-report
generated: examples/aef-processes/revisit-due-scan.workflow.yaml
ground_truth: agents/context/revisit-due-scan.sh
validator: tools/validate-workflow.py  # exit 0, no findings, first pass
authored: 2026-07-03
result: TWO new frictions (F16 timer-start, F17 multi-instance) — family sweep closed
prior_slices: [T-021, T-022, T-023, T-025, T-027, T-028, T-029, T-031, T-032]
```

## What this is

Tenth dogfood slice, closing the control-flow **family sweep**: it maps the two
remaining untouched families in one small process. The G-053 daily revisit scan
is (a) triggered by a **timer/cron**, not an agent command, and (b) iterates
**every active task** applying one predicate. It added two new frictions — the
first slice since the campaign began to add two at once, precisely because it is
the first to touch two new families simultaneously.

## The process (ground truth)

`revisit-due-scan.sh` (G-053 / T-1452), run **daily by cron**: resolve
`PROJECT_ROOT`/`TASKS_DIR` (walk up for `.framework.yaml`/`FRAMEWORK.md`), then
`for f in "$TASKS_DIR"/*.md` — for each active task extract frontmatter
`revisit_at`, skip if empty or not a real ISO date, and compare lexicographically
to `TODAY` (UTC); if `revisit_at <= today` the task is **ripe** and appended to a
temp list (`:54-82`). If any ripe → write `.context/working/.revisits-due.txt`
(one line per task); else no file ("no file / empty = same signal", `:12`). The
agent reads that file next session and proposes promoting the deferral. Ownership
→ swimlanes: the whole scan+surface is framework; agent picks up the output; human
decides. Mapped cleanly (exit 0, first pass).

## Friction result — two new gaps + recurrences

- **[F16 — NEW] timer / scheduled start.** The process starts on a **daily cron**,
  not on an agent/human command. BPMN models this with a `timerStartEvent`
  carrying a cron/cycle expression. v2's `NODE_TYPES` has only a bare `startEvent`
  (`validate-workflow.py:46-56`) — no timer, no message, no signal, no conditional
  start-event *definitions*. The schedule had to go in `aef.timer {kind, cycle,
  anchor}`. This is the **scheduled-entry** facet of the "events & boundaries"
  theme (F11 = ambient/interrupt entry; F16 = scheduled entry).

- **[F17 — NEW] multi-instance / for-each over a collection.** `for f in *.md`
  applies one predicate to **each** active task independently (order-independent —
  could be parallel). BPMN models this with a **multiInstance** activity marker
  (`over` a collection, sequential|parallel, with a per-item body). v2 has no such
  marker: a backward edge can *simulate* a while-loop but cannot *express* "one
  instance per item of a dynamically-sized collection." Stashed in
  `aef.multiInstance {over, mode, predicate, collects}`. This is distinct from
  F14 (fan-in aggregation): F17 is the *fan-out over data*; F14 is the *fold back*.
  Together F17→(work)→F14 is the map-reduce shape v2 cannot express end-to-end.

- **[F3↺] determinism** — resolve/scan/surface are deterministic fw-logic.
- **[F10↺] datastore** — reads task frontmatter; writes `.revisits-due.txt`.

## Map

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| **F16 timer / scheduled start** | **NEW** | §3.2 | S4 | 1/10 |
| **F17 multi-instance / for-each** | **NEW** | §2.6 / SD-9 | S8 | 1/10 |
| F3 determinism | ↺ | P4 | S3/S1 | 9/10 |
| F10 datastore | ↺ | §2.5/Fabric | S5 | 6/10 |

## Conclusion — control-flow family sweep complete

Ten processes now span **all six** major control-flow families:

| Family | Slice | Friction added |
|---|---|---|
| linear flow | T-021 inception / T-029 handover | F1–F6 (founding) |
| cyclic state machine | T-022 task / T-028 assumption | F7, F8 |
| advisory loop | T-023 healing | F9, F10 |
| ambient guard | T-025 tier0 | F11, F12 |
| grouped container | T-027 arc | F13 |
| **fan-out / scatter-gather** | **T-031 audit** | **F14** |
| **saga / compensation** | **T-032 upgrade** | **F15** |
| **timer + multi-instance** | **T-033 revisit-scan** | **F16, F17** |

New-friction rate re-read **by family** (not by slice): every genuinely new
family adds 1–2 gaps, every re-visited family adds 0. The register **F1–F17** now
covers all standard BPMN control-flow families the AEF corpus uses. Further
processes are expected to re-confirm recurrences only — this is the true
**friction-dry across families**, the honest version of the T-030 claim.

The **"events & boundaries" cluster** is now the clearest single v3 lever:
F11 (interrupt entry), F16 (scheduled entry), F15 (compensation/error exit),
and F14 (join handler) all want the same missing layer — event definitions on
start events and boundary events on activities. Pair with F17 (multi-instance)
and F5/F13 (composition) as the "structure & concurrency" bundle.

**Recommendation:** update the synthesis to F1–F17, add the family-coverage table,
and elevate "events & boundaries" to a top-tier v3 theme alongside the F3/F1/F5
additive M1 wins. The input-gathering phase is now complete across families.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md.
