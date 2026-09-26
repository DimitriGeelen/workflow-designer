# 832-Workflow-designer — project purpose and goals

**Status:** DRAFT for operator ratification · authored under T-874 · 2026-09-27
**Sources:** operator statement 2026-09-27; `docs/aef-designer-integration-protocol.md`;
`docs/proposals/aef-workflow-process-layer-2026-07-02/` (INSTRUCTIONS + DISPOSITION);
the 24-map corpus and its `aef:` vocabulary; `policy/value-drivers.yaml`; arcs 001–004.

> **Why this document exists.** The project had no written purpose. Four arcs, 715 completed
> tasks and two standards were produced against a purpose that lived only in the operator's
> head and in scattered task prose. When an agent was asked to derive it from the corpus on
> 2026-09-27 it produced something the operator did not recognise — technically accurate
> about the *method*, wrong about the *product*. That failure is the evidence that this
> document was missing, and it is recorded here rather than tidied away.

---

## 1. Project questions

The five questions this project answers about itself. Derived pending SPRIND's own wording
(see §5); the arc questions in §4 hang off these.

### P1 — What is this project for, in one sentence?

**Workflow Designer is AEF's process add-on: it captures a process completely enough to
execute it, so that a human and an agent can work the same picture from idea to running
implementation.**

### P2 — Who is the user, and what can they do that they could not before?

| user | what they get |
|---|---|
| **process author** (human) | draws a process — steps, decisions, dependencies — and attaches everything an implementer needs: inputs, outputs, pseudocode, decision trees, the artifacts each step reads and writes |
| **AEF agent** | reads that picture as a proposal for governed work, and compiles it into a task/inception graph |
| **operator** | sees a live process instance and knows which step it is standing on, which it failed at, and why |
| **second tenant** (the Sprind application) | models its own processes with the same machinery — proving this is a modelling substrate, not one bespoke diagram set |

### P3 — What is the organising idea?

**Class and instance.** A workflow is modelled once as a *template* and instantiated many
times, exactly as a class is to an object.

- `task-lifecycle` is a **class**. `T-873` is an **instance** of it.
- `inception-lifecycle` is a class. Each real inception is an instance.
- The same holds for the Sprind application's processes.

Everything else in this project is downstream of that distinction. Capture gives the class
its content; forward-compile turns a class into proposed work; instantiation binds a real
entity to its class; execution monitoring says which node of the class a given instance is
standing on.

### P4 — What must be true for this to be delivering?

Not "finished" — delivering. All six goals in §3 have a measurable signal, and none of them
is "a document exists".

### P5 — What would make this project worth stopping?

Stated honestly so it is answerable rather than rhetorical:

- If AEF stops consuming the seam — the designer is an add-on to AEF, and an authoring
  surface nothing authors *for* is a drawing tool.
- If the class/instance model cannot be made to hold — if instances cannot be bound to their
  templates without hand-maintenance, the monitoring goal collapses and what remains is
  documentation tooling, which is a smaller and honest thing to admit.
- If a second tenant cannot use it. Tenant-neutrality is a stated design property (IW-6); a
  substrate that only ever serves AEF's own 24 maps has not been shown to be one.

---

## 2. Purpose

> **Capture a process completely enough to execute it, and let humans and agents work the
> same picture from idea to running implementation.**
>
> Processes are modelled as classes and run as instances. A class carries its steps,
> decisions, dependencies, inputs and outputs, pseudocode, decision trees and artifacts. An
> instance binds that class to real work — a task number, an inception, a sprint item — and
> can be watched as it advances, step by step, with a step that is not permitted refused
> rather than taken.
>
> It is an add-on to AEF with tight integration, and the same machinery serves more than one
> tenant.

### What this is *not*

- Not a BPMN editor. BPMN is the portable serialisation, not the point.
- Not a replacement for the task system. **Tasks are canonical**; a diagram *proposes*
  governed work and never authors it (T-175 IW-1, and the July package was superseded
  precisely on this point). Instantiation binds to the task graph; it does not become it.
- Not a runtime. Execution *monitoring* is in scope; `strict` mode where the framework drives
  execution node-by-node is explicitly out (SD-8, and EWCR/arc-002 is the separate programme
  for anything that actually runs).

---

## 3. Goals

Each carries a falsifiable claim in the project's own hypothesis form (arc-004), because a
goal with no measurable signal is a slogan.

### G1 — Capture is complete enough to implement from

*We believe that if a step carries its inputs, outputs, decisions, artifacts and pseudocode,
an implementer needs nothing outside the picture. We will know when a reader can implement a
step from the diagram alone with no recourse to the task text.*

**State:** largely built. `aef:decisionInput` ×102, `aef:io` ×56, `aef:decisionOutputs` ×46,
`aef:output` ×31, `aef:artifactsWrites` ×21, `aef:contextReads` ×19, `aef:input` ×12.
**Gap: pseudocode has no carrier** — zero occurrences corpus-wide (SD-14 → T-281).

### G2 — A class is distinguishable from an instance

*We believe that if the serialised form says whether a map is a template or a work-plan,
nothing will promote a picture of a process into real governed work. We will know when the
marker exists, is round-tripped, and the promote path refuses an unmarked documentation map.*

**State: decided and unbuilt.** T-213 GO'd 2026-07-21; `aef:workflowMeta` carries
`version, uuid, title, schemaVersion, id, default` and **no `kind`**, 68 days later. The
defect it closes is live: AEF's `fw bpmn promote` has minted real `owner:human` tasks from
illustrative nodes (their L-504 / T-2548–9).

### G3 — An instance knows its class

*We believe that if a real entity records which template it instantiates, an operator can ask
"what process is T-873 following" and get an answer from the system rather than from a human
who remembers. We will know when a task resolves to its template and its current node.*

**State: does not exist.** SD-10 — "no binding, no instance files, no gated setter". One
hairline: `update-task.sh:249` names the enforcing node `tl_archive` when a gate trips.

### G4 — Execution is observable and guarded

*We believe that if instance state is held by the framework and advanced only through a
validated transition, an out-of-order step is refused and audited instead of silently taken.
We will know when an out-of-order advance, a skipped human gateway, and an unmet input
contract are each refused and land in the audit log.*

**State: not started.** This is V7 verbatim, and SD-8's `guided` rung. Note the ladder:
`advisory` (today, by convention) → `guided` (the target) → `strict` (out of scope).

### G5 — More than one tenant

*We believe that if a second, unrelated application models its processes with this machinery,
tenant-neutrality is demonstrated rather than asserted. We will know when the Sprind
application carries its own templates and instances.*

**State:** one app-flavoured example map exists (T-283, completed). All 24 corpus maps remain
AEF-internal. Sprind is the named second tenant.

### G6 — Idea to implementation round-trips with AEF

*We believe that if forward-compile and reverse-render both hold, work can start as a picture
and existing work can be seen as one. We will know when a re-pin round-trips the corpus
byte-identically with no hand repair.*

**State:** forward-compile spec'd (`aef-bpmn-forward-compile-v1`, AEF-led, their translator);
round-trip identity delivered (V3, G-002); reverse render partial (arc-001).

### G0 — The method, named so it is not mistaken for a goal

*Nothing is asserted that cannot be wrong.* Controls on absence assertions, mutation control
sets, `NOT EVALUATED` instead of vacuous PASS, hypothesis-first scoring, sticky provenance.

This is **how** G1–G6 get built without self-deception. It is not what the project is for. An
earlier draft of this document made it the headline, and that was the error §0 records.

---

## 4. Arc questions

Every arc in this project answers these six. Derived from the principle stated at
`sprind:pickup` offset 7; **pending SPRIND's actual wording** (§5).

- **A1 — Goal.** What is the arc's goal, stated as something a user observes? (This is
  `fw arc create --headline-mechanic`, which already refuses substrate-only phrasing.)
- **A2 — Trace.** Which project goal (G1–G6) does this arc advance, and how? An arc that
  cannot name one is either a new goal to be ratified or should not be opened.
- **A3 — Type.** Is this arc **BOUNDED** (a deliverable; closes on demo evidence) or
  **CONTINUOUS** (an ongoing obligation, fed by an external stream; closing it is not a
  coherent event)?
- **A4 — Exit or cadence.** If bounded: what demo closes it? If continuous: what is its
  review cadence, and what would make it worth *abandoning*?
- **A5 — Per-task check.** For each constituent task: *does this deliver arc purpose and
  project purpose?* Asked **at task creation and again at arc review** — not at every close,
  where it degrades into a reflexive yes.
- **A6 — Has it bitten?** Recorded per arc: how many times A5 returned **no**, and what
  happened (cut, rescoped, re-parented). *An A5 that has never produced a no is decoration,
  and the arc review must say so.*

**On A3, a live case in this project.** `arc-003` (audit remediation) is **CONTINUOUS**: it is
fed by whatever `fw audit` emits next, so it has no coherent closing event. It has sat
`in-progress` at 23/64 because the tooling has no other state for it, and it absorbs agent
capacity by default because it is the only place work is shaped for an agent. Marking it
continuous is a modelling fix, not an excuse, and `fw arc close` currently cannot express it.

---

## 5. Provenance of the question sets, and what is still owed

The arc-goal practice originates in the **Sprind** project. The operator asked for it to be
used here. The actual wording was requested by 055-agentic-fleet-cockpit at `sprind:pickup`
offset 7 and has not been answered; we searched `sprind:pickup`, `sprind-streichliste` and the
1409 inbox and it is on none of them.

**So §1 and §4 are DERIVED from the principle as offset 7 states it, not copied.** We seconded
the request at offset 8. When SPRIND's wording arrives, this document is reconciled against it
and the differences recorded — including ours that were wrong.

Two clauses from offset 7 are carried deliberately because they are the parts most likely to
be lost in a re-derivation: the anti-decoration rule (A6), and the bounded/continuous
distinction (A3).

---

## 6. Open to the operator

1. **Ratify or correct the purpose (§2) and the six goals (§3).** They are derived from your
   2026-09-27 statement plus the corpus; G5's second tenant being *Sprind specifically* is an
   inference from one sentence.
2. **A3 for the existing arcs.** We propose: arc-001 bounded, arc-002 bounded,
   **arc-003 continuous**, arc-004 bounded. arc-003 is the one that changes behaviour.
3. **G0's standing.** It is listed as method, not goal. If you want falsifiability as a
   first-class project goal it should be G7, not G0 — say which.
4. **The first arc written against this document:** `arc-005 process-instances`, covering
   G2/G3/G4. Scope and task manifest in `docs/reports/arc-005-process-instances-scope.md`.
   It is **draft**, not started, pending ratification of §2–§3 here and §1–§4 there.

## 7. Goal → arc coverage

| goal | arc | state |
|---|---|---|
| G1 capture completeness | — | **uncovered.** Its one gap is pseudocode (SD-14 → T-281, captured in arc-001). No arc owns it. |
| G2 class ≠ instance | arc-005 S1 | draft |
| G3 instance knows its class | arc-005 S2 | draft |
| G4 execution observable + guarded | arc-005 S3/S4 | draft |
| G5 second tenant (Sprind) | — | **uncovered.** Enabled by arc-005, delivered after it. |
| G6 idea→implementation round-trip | arc-001 | in progress, 21/31 |

Two goals have no arc. That is stated rather than papered over: G1 is one task away from
covered, and G5 cannot start until arc-005 lands. arc-002 (EWCR) and arc-003 (audit
remediation) trace to no goal in this list — arc-002 is a separate programme with its own
purpose, and arc-003 is infrastructure hygiene. **If a goal-less arc is not acceptable under
A2, arc-003 is the one to examine first**, since it holds 41 of the project's open tasks and
absorbs agent capacity by default.
