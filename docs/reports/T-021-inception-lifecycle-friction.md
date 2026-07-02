# T-021 — inception-lifecycle: v2-schema friction report

```yaml
task: T-021
type: dogfood-friction-report
generated: examples/aef-processes/inception-lifecycle.workflow.yaml
ground_truth: .agentic-framework/lib/inception.sh
validator: tools/validate-workflow.py  # exit 0, no findings
authored: 2026-07-03
```

## What this is

The first dogfood slice (T-020 GO → independent product, AEF-aware seams).
We generated a workflow for a **real** vendored-AEF process — the inception
lifecycle — from its implementation (`lib/inception.sh` + gates), then validated
it with our standalone judge. The file is structurally valid (exit 0).

The *value* is not the clean pass — it is the set of points where generating a
genuine governance process forced the current **v2 canonical schema** to
approximate. Each is a place the schema carries less than the process means.
These are the **v3 design inputs** (r3 Process-layer spec), cross-referenced to
the Sovereign Decision (SD) / section they map to. They are **not defects in the
generated file** — they are the frontier of what v2 can express.

## The process (ground truth)

`fw inception start "<name>" --recommendation GO|NO-GO|DEFER` (agent files an
advisory recommendation + rationale, T-1715/T-554; status `captured`) → `fw
work-on` (`started-work`) → exploration (assumptions, IW Open Questions, C-001
research artifact; readiness gate G-067) → `fw task review` (Watchtower surface +
`.reviewed-T-XXX` marker, T-973) → **human** records `go|no-go|defer` (**Tier-0,
human-only**, T-679/T-1259) → framework completes the matching branch
(auto-tick ACs / park / inject stubs + `revisit_at`) → terminal.

Authority → swimlanes: **human decides, framework enforces/transitions, agent
advises.** That mapping expressed cleanly. The friction is everything below.

## Friction catalogue

### [F1] Human decision → outgoing-edge mapping is not first-class — r3 SD-11
The decide step (`n_dcsn01`, `userTask`) produces a 3-way human outcome
(go/no-go/defer) that selects which branch runs. v2 has no way to bind a node's
**decision outputs** to its outgoing edges, so the outcome had to be modelled as
a separate `exclusiveGateway` (`n_rout01`) with `condition:` guards, and the
outcomes stashed in an out-of-band `aef.decisionOutputs` string. In the real
process the *human step itself* is the branch point; the gateway is an artifact
of the schema, not the process.
- **v3 need:** a first-class `humanTouchpoint` / decision node whose declared
  outcomes map directly to outgoing edges (touchpoint↔edge coverage rule).

### [F2] No workflow-level execution mode — r3 SD-8
The inception lifecycle is **governance-enforced**: the gates (G-067, Tier-0,
review marker) are not advisory hints, they *block*. v2 has no
`execution.mode` (advisory | guided | strict), so the file cannot declare that
this process is strict/enforced versus a merely descriptive diagram. A consumer
cannot tell an enforced process from a sketch.
- **v3 need:** `execution.mode` at workflow scope; strict implies the runner
  honours the gates.

### [F3] No per-node determinism marker — r3 P4
Nodes split into two natures: **agent-improvised** (`n_reco01` file a
recommendation, `n_expl01` conduct exploration — stochastic, judgement) versus
**fw-verb / deterministic** (`n_crea01`, `n_strt01`, `n_revw01`, the decide-
completion scripts — a fixed command with a defined effect). v2 has no field to
mark this, so the stochastic/deterministic frontier — exactly the line the
product's injection thesis cares about — is invisible in the file.
- **v3 need:** per-node `determinism` (or `kind: agent|verb`) marker.

### [F4] Tier-0 human-gate semantics are not a first-class gate property — r3 §3.2
The decision is **Tier-0, human-only** — reserved to the Sovereign, executed via
Watchtower or `--i-am-human`, and blocked for the agent even via `bash !`
(T-679/T-1259). v2 can only *hint* this (`aef.tier: 0` + `lane: human`); there is
no gate object saying "this transition requires human authority and cannot be
agent-driven." The single most important governance property of the process is
carried as a soft annotation.
- **v3 need:** a gate/authority property on the node or transition
  (`requiresAuthority: sovereignty`, `tier: 0`) that a strict runner enforces.

### [F5] DEFER is a sub-process; no callActivity node type — r3 SD-9
A DEFER outcome does more than end: it **injects stubs and sets `revisit_at`**
(the G-053 daily revisit scan then re-surfaces the task, T-1451). That is a
composed sub-process. v2 has no `callActivity` / sub-process node type, so it
flattened to a single `scriptTask` (`n_df01`) with the behaviour described only
in prose. The revisit loop — a real part of the lifecycle — is not represented
structurally.
- **v3 need:** `callActivity` / sub-process node type + composition
  (Workflow Fabric), so DEFER references the revisit sub-process.

### [F6] No workflow governance status / ratification fields — r3 SD-4
The process definition itself has no lifecycle in v2: no `status`
(proposed | ratified | deprecated) and no `ratified_by`. This is the CRUD-
symmetry guardrail the Sovereign flagged — an agent-editable "ratified" workflow
is not a guardrail. v2 cannot say who ratified this definition or whether it is
still authoring-mutable, so the immutability boundary cannot be expressed in the
artifact.
- **v3 need:** `status` + `ratified_by` governance fields (ratified = immutable,
  human-only transition), aligning with seam S4.

## Map to the seam catalogue (T-020)

| Friction | r3 anchor | T-020 seam |
|---|---|---|
| F1 human decision→edge | SD-11 | S6 (human touchpoint routing) |
| F2 execution.mode | SD-8 | S3 (executor / run boundary) |
| F3 determinism marker | P4 | S3 / S1 (judge extends to check it) |
| F4 Tier-0 gate property | §3.2 | S4 (governance status) / S6 |
| F5 callActivity sub-process | SD-9 | S8 (composition) |
| F6 status / ratified_by | SD-4 | S4 (governance status) |

## Conclusion

The generator produced a structurally valid, faithful rendering of a real
governance process on the first pass — the generation logic works and the judge
accepts it. Every gap it hit is a **carrying-capacity** gap in v2 (the schema
cannot hold a property the process has), not a structural-validity gap. All six
map to already-OPEN r3 SDs and to the T-020 seam catalogue, which validates the
independent-product-with-AEF-seams strategy: the injection line ("carry the
metadata, validate the structure, stop at execution") is exactly where the
friction concentrates.

**Feeds:** M1 (validator→v3 structural parity) and the Lock-1 schema-v3 design.
**Next dogfood candidates** (widen the corpus, surface more friction):
task-creation, tier0-escalation, exception-handling, knowledge-leveling,
arc-lifecycle.
