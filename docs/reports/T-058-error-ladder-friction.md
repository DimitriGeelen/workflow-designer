# T-058 — Friction-dry analysis: error-escalation-ladder (A/B/C/D + proactive Level-D)

**Subject:** `examples/aef-processes/error-escalation-ladder.workflow.yaml`
**Ground truth:** `agents/healing/lib/diagnose.sh` (classify L113, lookup L147, A/B/C/D menu
L156-204), `lib/resolve.sh`, `lib/promote.sh`/`harvest.sh` (CODE); `CLAUDE.md` §Error
Escalation Ladder + §Proactive Level D (DOCTRINE).
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and record
where the schema strained. Dogfood mapping #21 — **last** of the four "constitutional gate"
maps from the T-054 audit (task-gate T-055, verification-gate T-056, context-memory T-057,
error-ladder T-058). **The T-054 constitutional-gate series is now complete.**

## Verdict

**Schema expressivity: constructs available, 0 blocking gaps — but this process is half code,
half doctrine, and the schema has no way to say which.** Mapped the reactive ladder (A don't-
repeat → B technique → C tooling → D ways-of-working) as a recurrence-driven climb, the healing
loop that suggests it, and the proactive-Level-D branch (reflect → mine → assess → codify).
14 nodes, 16 edges, 2 lanes; geometry clean on first author; round-trip VALID; suite 24→25. One
headline finding — **empirically verified** — plus one recurrence and one node-type gap.

## New candidate frictions

### FC-13 — the `aef:` "free-form passthrough namespace" is NOT passthrough (VERIFIED)  ⭐ headline
I wanted a first-class `aef.enforcement: code | doctrine` marker to tag each node — this process
demands it, because a workflow diagram makes every box look like an executable step when half of
these are agent *judgement* the framework only advises. I tested whether the bridge would carry a
new `aef.enforcement` key:

    aef.enforcement = "DOCTRINE-TESTMARKER"  →  yaml-to-bpmn.py  →  key ABSENT from BPMN output

**Confirmed dropped.** The bridge emits only its known set (position / `<aef:meta>` META_KEYS /
decisionInput / decisionOutputs / contextReads / artifactsWrites / io / link); any *other* `aef.`
key is silently discarded. So the namespace the editor advertises as "free-form passthrough" is,
on the canonical YAML→BPMN path, a **closed whitelist**. This is the *generalized root* of the
T-059 (dedicated-element) and T-060 (meta-attribute) coverage bugs — both were instances of "the
bridge only carries what its whitelist names." **Why it matters:** any user (or map author) who
adds a custom `aef.` field to express a domain concept loses it with no error and no test failure.
**Workaround used here:** encode code-vs-doctrine in node NAMES (`[CODE]`/`[DOCTRINE]`) + reuse
`determinism` (deterministic=code, stochastic=judgement) — both survive because they are whitelisted.
**Recommendation:** this is a real product defect, not just a modelling nuisance — the passthrough
claim and the bridge behaviour disagree. Filed as a follow-up bug (see Outcome). Two fixes are
possible and mutually exclusive-ish: (a) make the bridge genuinely pass through unknown scalar
`aef.` keys as `<aef:meta>` attributes (honour the claim), or (b) drop the "free-form" language and
document `aef:` as a fixed vocabulary (honour the code). Either closes the gap; the guard is a test
asserting round-trip of an arbitrary `aef.` key. Registered under concern **G-002** (the seam).

## Recurrences

### No node type for an agent-cognitive step (sharpens FC-12 / the actor question)
The ladder rungs and the proactive-D steps are *agent judgement* — "decide which rung", "assess
codification value". The schema's task types are `serviceTask` (automated service), `scriptTask`
(framework script), `userTask` (human). None means "the agent reasons/decides". I used
`serviceTask` + `determinism: stochastic` as the least-wrong encoding, but a reader sees a
service call where the truth is a cognition step. Related to T-057 FC-12 (the lane axis can't
carry actor when partitioned by another axis): here it is the *node* axis that lacks an
agent-reasoning primitive. Recorded, not built (PD-002). Consistent low-grade signal across the
enforcement maps that "agent judgement" is a first-class actor the BPMN-subset vocabulary omits.

### Collapsed/parallel rungs & the shared resolve sink (echoes T-056 FC-10)
`diagnose.sh` prints **all four** rungs as a menu; the agent picks. The map draws a single
`exclusiveGateway` fanning to A/B/C/D that all reconverge on `n_resolve` — the same "guard/menu
drawn as routing" tension as T-056 FC-10, and the four-into-one convergence is the tell that the
rungs are *alternatives from one suggestion*, not independent branches. No new primitive needed;
noted for consistency of the pattern across maps.

## Outcome

Map committed (25/25 suite, geometry sweep 20 clean, round-trip VALID). **The T-054 constitutional-
gate series is complete** — all four gates (task, verification, context-memory, error-ladder) are
now dogfood maps. FC-13 is the standout: the first *empirically verified* product defect surfaced
by the dogfooding (the `aef:` passthrough claim is false on the bridge path), generalizing the
T-059/T-060 class to its root — filed as a follow-up bug task. Cross-map friction tally now points
at three recurring gaps the BPMN-subset schema has (all PD-002 "register, don't build" until a
threshold): a second/data lane axis (FC-12), a read/recall edge distinct from sequence flow (FC-8,
2×), and an agent-judgement node primitive. The corpus (21 maps) remains the evidence base if any
crosses the codification threshold.
