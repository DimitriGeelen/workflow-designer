# T-022 — task-lifecycle: v2-schema friction report

```yaml
task: T-022
type: dogfood-friction-report
generated: examples/aef-processes/task-lifecycle.workflow.yaml
ground_truth: agents/task-create/update-task.sh, lib/enums.sh, agents/healing/healing.sh
validator: tools/validate-workflow.py  # exit 0, no findings
authored: 2026-07-03
prior_slice: docs/reports/T-021-inception-lifecycle-friction.md
```

## What this is

Second dogfood slice (after T-021 inception-lifecycle). We generated a workflow
for the **task lifecycle** — the core "nothing gets done without a task" process
— from its vendored implementation, then validated it (exit 0, no findings). The
generation logic again produced a structurally valid, faithful rendering.

The task lifecycle differs from the inception lifecycle in one structural way
that makes it a sharper test: **it is a cyclic state machine**, not a mostly
one-way flow. `captured → started-work ⇄ issues → work-completed`, with three
backward loops (issues→started-work, gate-fail→rework, partial→human→finalize).
That paradigm mismatch is the headline new friction (F7).

Two frictions are **new** (F7, F8). Three **recur** from T-021 (F1, F3, F5) —
and recurrence is itself the finding: a gap that shows up in two independent
real processes is a *systemic* v2 limitation, not a one-off of the first
process. That is the signal M1/Lock-1 should weight most heavily.

## The process (ground truth)

States (`lib/enums.sh:62-77`): **captured** (start) → **started-work** ⇄
**issues** → **work-completed** (terminal → moves to `.tasks/completed/`).
Transitions are `fw task update --status X` (alias `fw work-on` for start),
validated by `is_valid_transition`. Auto-triggers: **healing diagnose** on
arrival at `issues` (`update-task.sh:1688-1698`); **episodic generation** +
move-to-completed on `work-completed` (`:1704-1994`). Completion is gated by a
battery (R-033 sovereignty, P-010 ACs, P-011 verification, G-019 RCA, T-1718
Evolution), each independently `--skip-*` bypassable. `owner=human` with
unchecked `### Human` ACs → **partial-complete** (status set but file stays
active, owner sticky-human, review emitted, episodic deferred).

Authority → swimlanes expressed cleanly (agent works, framework enforces/
transitions, human finalizes human-owned completion). Everything below is where
v2 could not carry what the process means.

## NEW friction

### [F7] The lifecycle is a state machine; the schema models flow — r3 SD-2 (canonical representation)
The BPMN-subset is a **flow** language: a directed graph of *activities* joined
by sequence flow. The task lifecycle is a **state machine**: a small set of
*states* with guarded transitions and self-returning cycles. To render it we had
to (a) demote states to pass-through activities carrying an out-of-band
`aef.state` tag, and (b) express every cycle (issues→started-work, gate-fail→
rework, partial→finalize) as a **backward sequence edge**. The validator accepts
backward edges (no acyclicity rule in v2), but the artifact no longer *says* "this
is a state machine" — a reader sees an activity graph. There is no first-class
`state` node, no state/transition duality, no guard-on-transition.
- **v3 need:** either a first-class state/transition representation, or an
  explicit `kind: state` node + `aef.state` promoted to a schema field, so the
  state machine is legible rather than reconstructed from tags.
- **Why it matters most:** governance processes in AEF are predominantly state
  machines (task, inception, healing, arc). If the canonical form can't model a
  state machine natively, every governance process pays the F7 tax.

### [F8] Transition guards / gate-SET with per-gate bypass are not first-class — r3 §3.2 / SD-8
The `work-completed` transition is guarded by a **battery** of five independent
gates (R-033, P-010, P-011, G-019, T-1718), AND-composed, **each with its own
Tier-2 bypass** (`--skip-*`), plus a deprecated umbrella `--force`. v2 has no way
to attach a precondition — let alone a *set* of independently-bypassable
preconditions — to a transition. We modelled the whole battery as one opaque
`scriptTask` (`n_gates`) with the real structure buried in an `aef.gates` list.
The single most governance-critical property of the process (what blocks
completion, and how each block can be lawfully overridden) is invisible to a
consumer of the definition.
- **v3 need:** a transition-guard / gate-set construct: a transition carries an
  ordered list of gates, each with `{id, rule, bypass, tier}`; a strict runner
  enforces them; the bypass path is declared, not folkloric.
- **Relation:** generalises T-021 F2 (execution.mode) and F4 (single Tier-0
  gate) — F8 is the multi-gate, per-gate-bypass form. If v3 does F8 well, F2/F4
  fall out as special cases.

## RECURRING friction (systemic — seen in both slices)

### [F1↺] Human decision → outgoing-edge mapping not first-class — r3 SD-11 · seam S6
T-021: the go/no-go/defer human decision. T-022: the **partial-complete** branch
— routed by an ownership+AC-state condition (`owner=human && Human ACs unchecked`)
whose outcome selects the edge. Both are "a human-governed condition picks the
branch" and both had to be modelled as a plain `exclusiveGateway`. **2/2 slices.**

### [F3↺] No per-node determinism marker — r3 P4 · seam S3/S1
Both processes mix agent-improvised nodes (here: `perform the work`, `write ACs`
— stochastic) with fw-verb nodes (start, gates, finalize — deterministic). We
carried it as `aef.determinism`, an out-of-band tag. The stochastic/deterministic
frontier — the exact line the product's injection thesis is about — has no
first-class home. **2/2 slices.**

### [F5↺] Auto-triggers are sub-processes; no callActivity / onTransition — r3 SD-9 · seam S8
T-021: DEFER injects stubs + revisit_at (a sub-process). T-022: **two** —
healing-diagnose fires on arrival at `issues`, and episodic-generation fires on
`work-completed`. Both are sub-processes invoked as **transition side-effects**,
not explicit flow nodes. v2 has neither a `callActivity` node type nor an
`onTransition` hook, so they live as `aef.autoTrigger` prose. **2/2 slices, and
this process alone contributes two instances.**

## Map to r3 SDs and the T-020 seam catalogue

| Friction | New? | r3 anchor | T-020 seam | Slices seen |
|---|---|---|---|---|
| F7 state-machine vs flow | new | SD-2 | S2 (canonical) | T-022 |
| F8 transition guard / gate-set | new | §3.2 / SD-8 | S4 / S3 | T-022 |
| F1 human decision→edge | ↺ | SD-11 | S6 | T-021, T-022 |
| F3 determinism marker | ↺ | P4 | S3 / S1 | T-021, T-022 |
| F5 callActivity / onTransition | ↺ | SD-9 | S8 | T-021, T-022 |

(T-021-only so far: F2 execution.mode, F4 Tier-0 gate property, F6 status/
ratified_by — F2/F4 are now subsumed by F8's general form.)

## Conclusion

The generator handled a cyclic state machine on the first pass and the judge
accepted it — the generation logic is robust across two structurally different
process shapes. The friction is again pure **carrying-capacity**: v2 validates
the structure but cannot hold the semantics (state, guard, determinism,
sub-process, human-branch). The recurrence of F1/F3/F5 across two independent
processes elevates them from "nice to have" to **systemic v3 requirements**, and
F7/F8 add the state-machine and gate-set constructs the governance domain needs.

**Feeds:** M1 (validator → v3 structural parity) and the Lock-1 schema-v3 design.
Prioritisation signal for v3: F7 (paradigm), F8 (guards), then the 2/2-recurring
F1/F3/F5.
**Next dogfood candidates:** healing loop (classify→lookup→suggest→log — another
state machine), tier0-escalation, arc-lifecycle.
