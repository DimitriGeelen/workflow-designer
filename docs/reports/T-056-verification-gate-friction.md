# T-056 — Friction-dry analysis: verification-gate (P-011 completion gate chain)

**Subject:** `examples/aef-processes/verification-gate.workflow.yaml`
**Ground truth:** `.agentic-framework/agents/task-create/update-task.sh` — the
`--status work-completed` dispatch block (L1405-1492) + finalize Trigger 2 (L1704-2043).
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and
record where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #18 — second of the four "constitutional gate" maps identified by the T-054
coverage audit (after task-gate / T-055).

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps.** The completion gate
mapped faithfully across the three authority lanes: agent invokes → framework runs the gate
chain (sovereignty → P-010 → **P-011 verify** → collapsed RCA/evolution/inception → write →
finalize) → human authorises bypass (logged Tier-2). Geometry gate clean on first author (15
nodes, 18 edges, 3 lanes, no straddle/overlap); bridge round-trip validated clean; suite
22→23. The map's own `emits` / `agentType` / `triggeredBy` survived the bridge — a live
end-to-end dogfood of the **T-060** fix landed earlier this session (pre-T-060 this map would
have lost all four `<aef:meta>` scalar instances). Two recurrences sharpened; two new
candidate frictions surfaced; one notable *contrast* with the prior enforcement maps.

## Notable contrast (not a friction) — the startEvent is honest here

task-gate (T-055) and tier0-escalation (T-049) are **ambient interceptors** — PreToolUse
hooks that fire on every tool call, so their single `startEvent` overstates a bounded flow
(recorded as recurrence F11). The completion gate is the opposite: the agent **explicitly
invokes** `fw task update --status work-completed`. The `startEvent` "fw task update …" is
therefore genuinely faithful — the first enforcement map where the entry event is not a
modelling compromise. Worth recording because it isolates F11 as a property of *ambient*
guards specifically, not of enforcement maps in general.

## New candidate frictions

### FC-10 — a guard chain is a conjunction, drawn as a routing tree  ⭐ headline
The real gate chain is **~11 sequential gates, all of which must pass** — a fail-fast logical
AND: each gate `exit 1`s on block, and the status write runs only if every gate falls through.
The schema renders each as an `exclusiveGateway` with pass/block branches, which visually reads
as *routing* (a decision that sends flow one of several ways) when the semantics are *assertion*
(a guard that either lets flow continue or aborts). A reader sees a branching decision tree; the
truth is a straight-line pipeline of asserts sharing one failure sink (`n_block`). Every block
edge converging on the single `n_block` is the tell, but the gateway glyph fights it.
**Why it matters:** guard-gateways and routing-gateways are semantically different but visually
identical; the "all must pass" invariant lives only in the reader's inference from the shared sink.
**Recommendation:** first map dominated by a guard chain — register, don't build (PD-002). A
future `aef.gateKind: assertion|routing` marker (or a distinct guard-gateway glyph) could carry it.

### FC-11 — a collapsed node cannot declare what it collapsed
For legibility this map folds six real gates (recommendation, RCA G-019, disposition,
render-review P-013, inception-decision, inception-scope-trace, evolution T-1718, task-pair
P-012) into a single `g_gates`. That collapse is faithful *as a decision* but **invisible in the
artifact**: nothing on `g_gates` tells a reader it is a composite spanning three policy families,
nor which ones. Same class as T-055's "decision cascade collapsed for readability", but more
severe — 6 gates across 3 families vs 3 adjacent guards in one hook. The header comment carries
the collapse; the node does not.
**Recommendation:** candidate `aef.collapsedFrom: [gate-ids]` annotation so a collapsed node
declares its constituents inline (round-trippable, greppable). Register; do not build. Now the
2nd collapse instance — if a 3rd appears, promote from candidate to a schema proposal.

## Recurrences

### Tier-graded bypass on a plain gateway (recurs: T-049, T-055 → now 3×)
Every gate in the chain is escapable via a `--skip-*` flag (or the deprecated `--force`, which
sets all of them), each routing through `log_gate_bypass()` → `.context/working/.gate-bypass-log.yaml`
(the Tier-2 audit sink). This map renders one representative path (sovereignty → human authorise
→ `n_logbypass` → continue); the schema draws plain gateways and a plain scriptTask, with the
"who may override, at what tier, logged where" axis carried only in labels + the Human-lane node
and the `tier: 2` / `sideEffect` meta. Reinforces the standing `aef.bypass` override-authority
candidate — now seen **3×** across the enforcement maps, the strongest recurring signal in the
corpus. (Threshold watch: a 3rd independent recurrence is the Level-D codification trigger.)

### Partial-complete is a third terminal that is neither pass nor fail (sharpens T-193 modelling)
`g_ac` has **three** outcomes: agent-ACs-ok (continue), agent-ACs-unchecked (block), and
only-human-ACs-remain (**partial-complete** — task stays in `active/`, owner→human, no episodic).
`exclusiveGateway` handles the 3-way split structurally, but "partial" is a *suspended* state —
neither the success end (`n_done`) nor the failure end (`n_block`) — with no schema marker to say
"this terminal is a hand-off, not a completion". Rendered as a distinct `endEvent`, which is the
closest faithful shape; the suspended-handoff semantics live in the label. Not a gap (the shape
exists) — noted so the modelling choice is recorded, and as weak support for FC-10's assertion
vs routing distinction.

## Outcome

Map committed to the corpus (23/23 suite, geometry sweep 18 clean). FC-10 (guard chain as
routing tree) is the strongest new candidate and the first guard-chain-dominated map; FC-11
(collapsed-node opacity) is the 2nd collapse instance. The `aef.bypass` axis now recurs 3× —
flagged for the Level-D codification threshold, but per PD-002 no schema change is built here:
register candidates, keep the schema minimal. The session's own T-060 fix was dogfooded end to
end by this map's `<aef:meta>` scalars surviving the bridge.
