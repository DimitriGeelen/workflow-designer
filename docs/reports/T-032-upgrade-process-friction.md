# T-032 — upgrade-process: v2-schema friction report

```yaml
task: T-032
type: dogfood-friction-report
generated: examples/aef-processes/upgrade-process.workflow.yaml
ground_truth: lib/upgrade.sh
validator: tools/validate-workflow.py  # exit 0, no findings, first pass
authored: 2026-07-03
result: ONE new friction (F15 compensation/rollback) + boundary-event gap — coverage extension
prior_slices: [T-021, T-022, T-023, T-025, T-027, T-028, T-029, T-031]
```

## What this is

Ninth dogfood slice, probing the last untouched major control-flow family:
**compensation / rollback (saga)**. The framework upgrade process snapshots
before it mutates, applies steps, verifies, and restores the snapshot on failure.
No prior slice — including the T-031 fan-out — has a backup→apply→verify→rollback
shape or a compensation handler. It surfaced one genuinely new gap (F15) and
sharpened a structural blind spot (v2 has no boundary/event constructs at all).

## The process (ground truth)

`fw upgrade [--dry-run]` (`lib/upgrade.sh`): if `--dry-run`, report planned
changes and exit (no mutation). Otherwise **take a timestamped `.bak` snapshot**
before touching anything (`upgrade.sh:109-115`, `cp <target> <target>.bak-$(date
+%s)`), then apply upgrade steps — settings merge, git-hook install,
command/script sync — each **drift-gated** (per-file compare; apply only on
difference, `:1097`). A `trap "rm -rf '$_tmpd'" EXIT INT TERM HUP` (`:284`)
guarantees cleanup/rollback of temp state even on interrupt. Version checks guard
against silent downgrade (T-1828 rollback family, `:1214`). On failure the `.bak`
files are the restore artifact. Ownership → swimlanes: agent triggers, framework
does snapshot/apply/verify/rollback, human reviews the `.bak` and re-applies lost
customisations (outside the flow). Mapped cleanly (exit 0, first pass).

## Friction result — one new gap + recurrences

- **[F15 — NEW] compensation / rollback.** A step failure (verify fails) must
  **restore a pre-step snapshot**. In BPMN this is a *compensation activity* bound
  to the mutating steps through a **compensation boundary event**; the handler
  "undoes" completed work by restoring saved state. v2 has **neither a boundary
  event nor a compensation association** — the snapshot↔restore relationship
  survives only as `aef:` cross-references (`compensationSnapshot: true` on the
  backup, `compensatedBy` / `compensates` / `restoresFrom` on the steps and the
  rollback node). Modelled here as an ordinary exclusive branch to a rollback
  scriptTask — which loses the semantic that rollback *undoes the specific
  activities* rather than being just another downstream step.

- **[boundary-event gap — structural] v2 has no event-boundary construct at all.**
  The `trap … EXIT INT TERM HUP` means rollback also fires on **interrupt**, not
  only on the verify-false edge — an *event-driven* boundary interrupt (the same
  family as an error/cancel boundary event). v2 has only start/end/link events;
  there is no attached boundary event, no error event, no cancel/terminate. F15's
  compensation is one instance; the general gap is "control can only leave a node
  via an outgoing sequence edge, never via an event raised *during* the node."
  (Tier-0's ambient guard, F11, is the *entry* side of this same missing family.)

- **[F2↺] execution mode (dry-run).** `--dry-run` turns the whole workflow into a
  no-op **preview** — the advisory end of F2's `execution.mode`
  (advisory|guided|strict). First recurrence of F2 since inception; carried as a
  mode gateway + `aef.sideEffects: none`.
- **[F8↺] guard (drift-gated apply).** Each apply step runs only on per-file
  drift — a precondition guard on the activity.
- **[F3↺] determinism** — every step is deterministic fw-logic.
- **[F10↺] datastore** — writes the `.bak` snapshots and the recorded VERSION.

## Map

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| **F15 compensation / rollback** | **NEW** | §3.2 / SD-8 | S4 | 1/9 |
| F2 execution mode (dry-run) | ↺ | SD-8 | S3 | 2/9 |
| F8 guard (drift-gated) | ↺ | §3.2/SD-8 | S4/S3 | 7/9 |
| F3 determinism | ↺ | P4 | S3/S1 | 8/9 |
| F10 datastore | ↺ | §2.5/Fabric | S5 | 5/9 |
| *(structural: no boundary/event construct)* | v3 | §3.2 | S4 | — |

## Conclusion

Second consecutive **new control-flow family** to add exactly one friction
(T-031 fan-out → F14; T-032 saga → F15), confirming the T-031 lesson: friction-dry
must be qualified **per control-flow family**, not declared globally. Two families
remain genuinely untouched — **event/timer-driven** (cron / `revisit-due-scan.sh`
G-053 daily scan, `checkpoint.sh` budget interrupt) and **multi-instance**
(for-each over a collection) — each likely to add at most one gap before the
register is dry across all families.

The deeper structural finding is that **F11 (ambient guard, entry), F14 (fan-in
aggregation) and F15 (compensation, exit) are all facets of the same missing
layer: events and boundaries.** v2 is a pure sequence-flow + exclusive/parallel
gateway language; it has no vocabulary for "something happens *during* or
*around* an activity." v3's biggest single lever may be introducing a boundary/
event construct, which would subsume F11 and F15 and give F14's join a place to
attach an aggregation handler.

**Recommendation:** record F15 and the boundary-event structural gap in the
synthesis; note that F11+F14+F15 cluster into one "events & boundaries" v3 theme.
One event/timer slice (revisit-due-scan) would close the family sweep.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md.
