# T-039 — inception-review flow: friction note

```yaml
type: dogfood-friction
task: T-039
authored: 2026-07-03
process: inception-review (fw task review → link/QR/marker → fw inception decide)
ground_truth: lib/review.sh (emit_review) + lib/inception.sh (decide) + T-973 marker gate
validation: examples/aef-processes/inception-review.workflow.yaml — exit 0, no findings
verdict: friction-dry (no new ID) — recurrences only, per PL-001
```

## Ground truth

The flow the operator lives when an inception is presented: the **agent** requests review
(`fw task review`); the **framework** audits the recommendation for placeholders, validates
the review link resolves, emits the Watchtower URL + QR + artifacts list, and writes the
`.reviewed-T-XXX` marker (T-973); the **human** reviews and records `fw inception decide
go|no-go|defer`. A readiness failure (placeholder recommendation) loops back to the agent.

## Result

Mapped and validated clean on the first pass (exit 0). This is a **cyclic state machine with
a three-way human decision** — the same family as task-lifecycle (T-022) and healing (T-023).
Per **PL-001** (friction-dry is per control-flow family), the expectation for a revisited
family is 0 new gaps, and that holds: no new friction ID.

**Recurrences exercised:**
- **F3 (determinism, 4/4→5/5):** all three kinds appear cleanly — fw-verb steps
  `deterministic`, the agent's recommendation authoring `stochastic`, the review `human`.
- **F1 (human-decision → edge):** the go/no-go/defer decision, three declared outcomes routed
  by three conditioned edges. First corpus instance of a **three-way** human decision (prior
  idioms were 2-way approve/abandon or go/no-go/defer on inception-lifecycle) — hardens F1's
  recurrence count without changing its shape.
- **F7 (state machine):** the placeholder→fix→re-request readiness loop is a backward edge.

## One sharpening (not a new ID)

The `.reviewed-T-XXX` **marker is a cross-invocation precondition**: it is written by one CLI
command (`fw task review`) and gates a *separate, later* command (`fw inception decide`),
across an unbounded human pause. v2 could only model this as in-workflow sequence order
(`n_emit → n_review → n_decide`), which hides that these are **two independent entry points
linked by a persisted token**. This is the intersection of **F12** (single-use/expiring
capability token — the marker unlocks exactly one decide) and **F10** (durable state
outliving a step). No new construct is needed beyond F12+F10; noting it here because the
review flow is the clearest example of the two composing.

Also observed: a **DEFER** outcome arms a *future* timer-triggered re-entry (`revisit_at` →
G-053 daily scan) — a decision edge that schedules a scheduled-start of a later process. This
is F1 (decision→edge) composing with F16 (timer start) + F5 (onTransition), all already in
the register.

## Conclusion

**Friction-dry** for this process: the inception-review flow is fully expressible modulo the
already-catalogued gaps (F1, F3, F7, F12, F10, F16, F5). It earns its place in the corpus not
by surfacing new friction but as the **operator-familiar fidelity-pilot subject** for the
T-038 review surface — the one process the operator can judge for semantic faithfulness from
lived experience.
