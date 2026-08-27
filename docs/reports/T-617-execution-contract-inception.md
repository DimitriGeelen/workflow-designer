# T-617 — should the designer node dialect carry an execution contract?

**Status:** inception, exploration. No build artifacts. Recommendation filed at DEFER and
revised below now that the two cost-determining facts are measured.

**The operator's proposal, stated back.** Give the designer a notion of *execution* — runtime
or execution tasks as a node kind — and split them **deterministic** (a script, a CLI command,
an API call from code) versus **stochastic** (an agent), so that when a step fails the failure
can be routed back to an agent to evaluate, remediate and recover. Goal: design → build →
execution in one artifact, producing application code.

---

## The headline: most of this already exists, and one part of it is finished

I expected to be scoping a dialect extension. Measured against `src/aef-workflow-designer.html`
rather than recalled, three of the four moving parts are already in the editor.

### `eventError` is a real, authorable boundary error event

`AEF_FIELDS` carries:

```
eventError:   ['errorStatus', 'hostRef', 'boundaryPos', 'interrupting', 'note'],
```

`hostRef` attaches it to a host node. `boundaryPos` places it on that node's boundary.
`interrupting` is the BPMN interrupting/non-interrupting distinction. That is a BPMN error
boundary event, in the editor, authorable today — alongside `eventTimer` (`timerSpec`) and
`eventMessage` (`busTopic`).

**So the failure-routing half of the proposal needs no dialect change at all.** "This task
fails → go to that agent node" is drawable now: an `eventError` on the task's boundary, a
sequence flow to a `serviceTask` carrying `agentType`.

This is the answer that matters most, because it is the half that looked like new work.

### The determinism axis is already half-encoded — it just has no name

`metaKeys` (20, unchanged since T-589) contains, among others:

| key | what it already expresses |
|---|---|
| `agentType` | an agent runs this node — the stochastic marker |
| `exitCode` | a checkable numeric result — the deterministic marker |
| `external` | the work happens outside the runtime |
| `softFail` | a failure that does not abort the flow |
| `guard` / `gate` | a precondition that can refuse |
| `terminalKind` | how a terminal node ends |

`agentType` is authorable on `serviceTask` only. `endpoint` is authorable on `serviceTask`,
`userTask`, `scriptTask` and `subProcess`.

So the dialect already distinguishes *who or what performs a node*. What it does not do is
**say so as a contract** — there is no single field a runtime can read to decide how to treat a
failure, and no rule that `agentType` and `exitCode` are mutually exclusive.

### A new node type would duplicate an existing distinction

`serviceTask` (call something) and `scriptTask` (run a script) already split the deterministic
world, and both are in the frozen standard. Adding an "execution task" type alongside them
would encode the same distinction twice and would be a change to
`docs/standards/aef-bpmn-mapping-v1.md` — frozen, not editable under agent control, and
therefore a joint handoff with 999-AEF under roadmap §2.1.

---

## Open Questions — dispositions

### IW-1 — scalar carriage or new element? **ANSWERED: scalar carriage suffices.**

T-589 established that scalar fields ride `<aef:meta>` with `metaKeys` unchanged and nothing
for AEF to ratify. An execution contract expressed as scalars — say `execution` and
`idempotent` — rides the same carriage. **No new element, no new node type, no ratification.**

Cost goes from cross-project negotiation to an ordinary build task. That is the whole
difference this inception was filed to establish.

### IW-2 — does failure routing need a dialect change? **ANSWERED: no.**

`eventError` exists with `hostRef` / `boundaryPos` / `interrupting`. The mechanism is built.
Note `errorEventDefinition` appears **0** times in `src/` — the editor carries its own `aef:`
representation rather than the raw BPMN element name, which is worth confirming against the
export path before anyone claims round-trip fidelity, but does not change the answer.

Worth stating plainly: had I not measured, I would have proposed an `onFailure` attribute
beside a standard mechanism that already expresses it. That is the exact failure roadmap §2.1
exists to prevent.

### IW-3 — authority boundary of a recovery agent? **OPEN. This is the real work.**

The proposal introduces an agent that *acts* when something breaks: retries, rolls back, calls
an API — at runtime, with no human present, in a workflow authored by someone who may not have
considered it. The Authority Model gives agents INITIATIVE, not AUTHORITY, and nothing in the
current dialect bounds what a recovery node may do.

Roadmap Arc 2 ("prove browser/editor cannot reach execution/secret/ledger authority") and Arc 3
("render structured refusals") are precisely this, and both have AEF on the other side.

**Unanswered, this makes the feature unsafe rather than merely unbuilt.** A `recovery` node
that can do anything is a governance hole with a diagram around it.

### IW-4 — is retry safe, and who declares it? **OPEN, and partly AEF's.**

"Route the failure back to an agent to recover" presumes the failed step can be re-run. A step
that partially completed — wrote half its rows, charged the card, sent the mail — is not
re-runnable, and an agent that retries it double-applies.

Roadmap §2.1 puts **idempotency** in AEF's Arc 1 column, so the designer cannot define it. But a
runtime cannot *infer* it either, which means the node must be able to **declare** it. That is
a Designer-side authoring question with an AEF-side semantic — a §2.1 joint handoff, and the
one genuine coordination item in this proposal.

### IW-5 — is deterministic/stochastic the axis that pays? **PARTLY. It is a proxy.**

Filed as my own doubt and it survives measurement, so it goes in the record rather than being
quietly dropped.

The property a runtime needs at a failure boundary is not *how* a node computed its answer but
**whether the answer can be checked without re-running it**. These correlate and are not the
same:

- a flaky network call is deterministic code with a stochastic outcome
- an LLM classifier constrained to an enum has a checkable result
- a script that writes a file has a checkable result; a script that emails has not

The existing dialect keys on **who performs the node** (`agentType`) rather than on
**whether the result is checkable** (`exitCode` gestures at it). Those are different axes and
the corpus already contains nodes that separate them.

**Suggested shape:** two orthogonal scalars, not one enum.

```
execution:  agent | code | human | external     # who performs it
verify:     exit-code | schema | assertion | none | human   # how the result is checked
idempotent: yes | no | unknown                  # whether retry is safe (declared, never inferred)
```

`verify: none` combined with `idempotent: no` is the cell a runtime must refuse to auto-retry —
and that combination is *invisible* under a single deterministic/stochastic flag, which is the
argument for splitting the axis.

---

## Recommendation

**Recommendation:** GO — but on a scope roughly a third of what was proposed, and with the
authority question resolved before any recovery node is executable.

**Rationale:** the expensive parts turn out to be built. Failure routing exists (`eventError`,
boundary-attached, interrupting). The execution distinction is already half-encoded in
`metaKeys` and needs naming, not inventing. Scalars ride the existing carriage with no AEF
ratification (T-589's precedent), so this is an ordinary build task rather than a cross-project
negotiation. What should **not** be built is a new node type — `serviceTask`/`scriptTask`
already carry that split and duplicating it costs a change to the frozen standard for nothing.

The two things that genuinely block execution are IW-3 (what may a recovery agent do) and IW-4
(may this step be retried at all). Both are governance, not rendering, and IW-4 needs AEF
because idempotency is Arc 1's. Authoring the fields without answering IW-3 would ship a
diagram that authorises autonomous remediation — the feature would look finished and be unsafe.

**Evidence:**
- `AEF_FIELDS.eventError = ['errorStatus','hostRef','boundaryPos','interrupting','note']` — boundary error events authorable today
- `metaKeys` = 20, containing `agentType`, `exitCode`, `external`, `softFail`, `guard`, `gate`
- `errorEventDefinition` count 0 in `src/` — editor uses its own `aef:` representation
- node types present: `serviceTask` 31, `subProcess` 23, `scriptTask` 17, `userTask` 16, `callActivity` 1
- T-589 precedent: scalars ride `<aef:meta>`, `metaKeys` unchanged, no ratification
- roadmap §2.1: idempotency is AEF's Arc 1; Arc 2/3 own isolation and refusal rendering

**Not decided by me.** `fw inception decide` is operator-only and agents are structurally
blocked from invoking it. This is advisory.

---

## Dialogue Log

### 2026-08-27 — the operator's proposal

**Asked:** whether to add runtime/execution tasks as a task type, and to distinguish
stochastic from deterministic tasks, with failure on a stochastic task routing back to an agent
to evaluate and remediate.

**Answered:** yes to the distinction, no to the new node type, and the failure-routing half is
already built. Raised two questions the proposal did not contain — what a recovery agent is
permitted to do, and whether the failed step may be retried at all — as the parts that actually
gate execution.

**Course correction on my own framing:** I filed IW-5 doubting that deterministic/stochastic is
the load-bearing axis, and measurement supported the doubt. The dialect keys on *who performs*
the node; a runtime needs to know *whether the result is checkable* and *whether retry is safe*.
Recommending three orthogonal scalars rather than one binary flag.

**Ambiguity worth naming:** the phrase "as tasks" is genuinely ambiguous between the framework's
governance tasks (`.tasks/`, `workflow_type: build|design|inception|…`) and the designer's BPMN
node types. This artifact answers for **node types**. If the intent was also to add an
`execution` workflow_type to the governance task system, that is a separate and much smaller
question, and it should not be bundled — one inception, one question.
