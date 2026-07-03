# M1 implementation spec — F3 (determinism) + F1 (human-decision → edge)

```yaml
type: implementation-spec
milestone: M1 (validator → v3 structural parity)
task: T-037
authored: 2026-07-03
status: draft-awaiting-posture-call
covers:
  - F3   # per-node determinism marker
  - F1   # human-decision → outgoing-edge coverage
source_contract: docs/reports/dogfood-v3-design-inputs.md
constrains_against:
  - PD-002   # "extend the standalone validator only with pure-structural, additive, WARN-level rules" (T-034)
posture_fork:
  - "path-A: first-class v3 schema fields (validator reads legitimate product fields)"
  - "path-B: opt-in --aef-lint mode (validator reads the existing aef: bag)"
recommendation: path-A (staged), with path-B explicitly rejected — see §7
commits_code: false   # this task ships only this document
```

## 1. Purpose & scope

The dogfood campaign catalogued 17 frictions (F1–F17). Two are **universal** — they
appear in **4/4** of the mapped process families and top the additive-M1 roadmap:

- **F3 — per-node determinism marker.** Is a node's work agent-stochastic, a
  deterministic `fw`-verb, or a human act? This frontier *is* the product's injection
  thesis ("stop at the execution/resolution boundary"), yet v2 has no field for it.
- **F1 — human-decision → outgoing-edge coverage.** A human decision with declared
  outcomes (go/no-go/defer; approve/abandon; A/B/C/D) must map those outcomes onto the
  outgoing edges that route on them. v2 has no first-class binding, so the mapping is
  unchecked — a declared outcome with no edge (or an edge routing on an undeclared
  outcome) validates clean today.

This spec turns both into **exact validator rules + fixtures**, under **two mutually
exclusive postures**, and recommends one. It commits **no** validator/schema/corpus
change — that is a deliberate governance choice (§7): the posture is a
product-vs-framework decision earmarked for a human, and PD-002 constrains it.

Out of scope: F5/F7/F8/F9 and the events-&-boundaries cluster (F11/F14/F15/F16) — those
are schema-shape / execution changes for a coordinated v3 bump, not additive M1 rules.

## 2. How F3 & F1 live in the corpus **today** (the `aef:` bag)

The generator already emits a consistent, informal vocabulary — stashed in the free-form
`aef:` passthrough bag that the validator **ignores by design**. That "it had to go there,
with no first-class home" is precisely what F3/F1 record. Observed shape:

```yaml
# F3 — determinism (every activity node carries it today)
- uid: n_classify
  type: scriptTask
  lane: agent
  aef:
    determinism: stochastic        # ∈ {deterministic, stochastic, human}

# F1 — human decision spans TWO nodes: a declaring userTask + a routing gateway
- uid: n_human_decide
  type: userTask
  lane: human
  aef:
    determinism: human
    decisionOutputs: approve, abandon      # NOTE: informal comma-string, not a list
- uid: n_route
  type: exclusiveGateway
  lane: human
  aef:
    decisionInput: ${decision}
    decisionOwner: human                   # ∈ {framework, agent, human}
# …routed by exclusiveGateway outgoing edges:
edges:
  - { from: n_route, to: n_consume,  condition: "${decision == 'approve'}" }
  - { from: n_route, to: n_abandon,  condition: "${decision == 'abandon'}" }
```

Key facts the rules must honour:
- `determinism` values seen in corpus: **`deterministic`**, **`stochastic`**, **`human`**.
- The F1 decision is a **two-node idiom**: a `userTask` **declares** outcomes
  (`decisionOutputs`), a following `exclusiveGateway` **routes** them (`decisionInput` +
  `decisionOwner: human`), and the **edges** carry the `condition` predicates. F1 fires
  only for **human-authority** decisions — agent/framework *data-condition* branches
  (`decisionOwner: framework`, e.g. `${verify_ok}`) are already first-class in v2 and are
  explicitly out of F1 (dry-slice sharpening, T-028).
- `decisionOutputs` is currently a comma-separated **string** ("approve, abandon"). Any
  rule that parses it must split on commas + trim; Path A should regularise it to a list.

## 3. The posture fork (the decision this spec exists to frame)

| | **Path A — first-class fields** | **Path B — opt-in `--aef-lint`** |
|---|---|---|
| Where the data lives | promote `determinism` / decision-outcomes to **top-level node fields** (v2.1 schema bump) | stays in the `aef:` bag |
| What the validator reads | legitimate **product** schema fields | the **aef:** namespace (framework-coupled) |
| Default behaviour | new rules run by default (they read product fields) | **unchanged**; rules run only under `--aef-lint` |
| Corpus impact | **migration required** (10 files: `aef.determinism` → `determinism`, etc.) | none |
| PD-002 (pure-structural) | **compatible** — fields are product structure; rules stay additive/WARN | **in tension** — reading `aef:` is exactly what PD-002 fenced off |
| Portability directive | strong — product owns its own vocabulary | weaker — validator couples to AEF's namespace |
| Build size | larger (schema + migration + rules) | smaller (rules behind a flag) |
| Reversibility | schema bump is a commitment; migration is mechanical | one flag + one code path to remove |

Both **commit the codebase to a direction** the design-inputs doc earmarks as
framework-agent v3 work. That is why T-037 ships this spec and stops — the build waits
on a human posture call.

## 4. F3 — determinism marker

### 4.1 Field (both paths)

- **Name:** `determinism` (keep the corpus name — zero cognitive migration).
- **Values:** enum `deterministic | stochastic | human`.
- **Applies to:** activity nodes (`serviceTask`, `userTask`, `scriptTask`). Not events/gateways.
- **Placement:** Path A → top-level node field `node.determinism`. Path B → `node.aef.determinism` (as today).

### 4.2 Validator rule

| | |
|---|---|
| **Rule id** | `W-DET-MISSING` (advisory) and `E-DET-VALUE` (error) |
| **W-DET-MISSING** | activity node has no `determinism` → **WARN** (the injection-line frontier is unstated). |
| **E-DET-VALUE** | `determinism` present but not in the enum → **ERROR** (typo'd marker is worse than none). |
| **Severity** | WARN for absence (additive, non-breaking); ERROR only for an *invalid* value. |
| **Cross-check (WARN, `W-DET-LANE`)** | `determinism: human` on a node **not** in a `sovereignty`/`human` lane, or `determinism: stochastic` on a `framework`-authority lane, is likely mislabeled. Derive expected-determinism from lane authority; mismatch → WARN. This is the "likely free from lane authority" leverage noted in the roadmap (item 4). |

Pseudocode (form-agnostic; runs in both YAML `Validator` and XML `XmlValidator`):

```python
ACTIVITY = {"serviceTask", "userTask", "scriptTask"}
DET_VALUES = {"deterministic", "stochastic", "human"}
def _check_determinism(self, nodes):
    for n in nodes:
        if node_type(n) not in ACTIVITY:
            continue
        d = determinism_of(n)          # path-A: n["determinism"]; path-B: n["aef"]["determinism"]
        if d is None:
            self.warn("W-DET-MISSING", loc(n), "activity node has no determinism marker")
        elif d not in DET_VALUES:
            self.error("E-DET-VALUE", loc(n), "determinism '%s' not in %s" % (d, DET_VALUES))
        elif d == "human" and lane_authority(n) not in ("sovereignty",):
            self.warn("W-DET-LANE", loc(n), "determinism:human outside a sovereignty lane")
```

Only `determinism_of()` differs between paths — one accessor, swappable.

### 4.3 Fixtures (per `tests/run-validator-tests.sh` naming: `<RULE-ID>.<ext>`)

| Fixture | Bucket | Asserts |
|---|---|---|
| `W-DET-MISSING.yaml` / `.xml` | warn/ | activity node with no marker → exit 1 + rule fires |
| `E-DET-VALUE.yaml` / `.xml` | invalid/ | `determinism: maybe` → exit 2 + rule fires |
| `W-DET-LANE.yaml` / `.xml` | warn/ | `determinism: human` on an agent lane → exit 1 + rule fires |
| `det-clean.yaml` | valid/ | every activity marked, all in-enum, lanes consistent → exit 0 |

Under **Path A** the 10 corpus files migrate to top-level `determinism` and stay 10/10 clean
(they already carry the values). Under **Path B** the corpus is untouched and stays clean by
default; `--aef-lint` would run the rules over the existing bag.

## 5. F1 — human-decision → edge coverage

### 5.1 Fields (both paths)

- A **decision node** is one with human authority over a declared outcome set. Detected by:
  `determinism == human` **or** `decisionOwner == human` (the routing gateway).
- **`decisionOutputs`** — the declared outcome labels. Path A: regularise to a YAML **list**
  (`[approve, abandon]`) on the node; Path B: parse the comma-string in place.
- Outcomes are consumed by **outgoing-edge `condition`** predicates on the routing
  `exclusiveGateway` (`${decision == 'approve'}`).

### 5.2 The two-node idiom (the rule's main subtlety)

Declaration (`decisionOutputs`) and routing (`condition` edges) sit on **different nodes**
joined by the decision variable. The rule must:
1. find the declaring node (has `decisionOutputs`, human authority);
2. find its routing gateway (the `exclusiveGateway` whose `decisionInput` names the same
   variable, typically the declaring node's flow successor);
3. compare declared outcomes against the literals in that gateway's outgoing-edge conditions.

### 5.3 Validator rule (`W-DEC-*`, advisory — coverage, not validity)

| Rule id | Trigger | Severity |
|---|---|---|
| `W-DEC-UNROUTED` | a declared outcome has **no** outgoing edge routing on it (dangling outcome) | WARN |
| `W-DEC-UNDECLARED` | a routing edge condition references an outcome **not** in `decisionOutputs` | WARN |
| `W-DEC-NOGATEWAY` | a human decision node declares outputs but no routing `exclusiveGateway` consumes its variable | WARN |

All WARN: these are **coverage** gaps (the graph is structurally valid — edges exist and
resolve — but the human-decision semantics aren't fully wired). Escalating to ERROR would
break additivity (PD-002) and risk false positives on outcome-literal extraction.

Pseudocode:

```python
def _check_human_decision_coverage(self, nodes, edges):
    for d in nodes:
        if not is_human_decision(d):            # determinism==human or decisionOwner==human
            continue
        declared = outcomes_of(d)               # split/trim decisionOutputs → {"approve","abandon"}
        if not declared:
            continue
        gw = routing_gateway_for(d, nodes, edges)   # exclusiveGateway consuming d's decisionInput
        if gw is None:
            self.warn("W-DEC-NOGATEWAY", loc(d), "human decision has no routing gateway")
            continue
        routed = {outcome_literal(e) for e in out_edges(gw, edges) if e.get("condition")}
        for missing in declared - routed:
            self.warn("W-DEC-UNROUTED", loc(gw), "declared outcome '%s' has no edge" % missing)
        for extra in routed - declared:
            self.warn("W-DEC-UNDECLARED", loc(gw), "edge routes on undeclared outcome '%s'" % extra)
```

`outcome_literal(e)` parses `${decision == 'approve'}` → `approve` (regex on the equality
RHS). Robustness note: if a condition is not a simple equality, skip it (don't guess) — the
rule under-reports rather than false-positives.

### 5.4 Fixtures

| Fixture | Bucket | Asserts |
|---|---|---|
| `W-DEC-UNROUTED.yaml` / `.xml` | warn/ | declares `approve, abandon`; edges route only `approve` → WARN |
| `W-DEC-UNDECLARED.yaml` / `.xml` | warn/ | declares `approve`; an edge routes `${decision == 'defer'}` → WARN |
| `W-DEC-NOGATEWAY.yaml` / `.xml` | warn/ | human decision with `decisionOutputs`, no consuming gateway → WARN |
| `dec-clean.yaml` | valid/ | declared set == routed set (the tier0 idiom) → exit 0 |

`tier0-escalation.workflow.yaml` is the natural `dec-clean` model (approve/abandon fully
wired) — under Path A it stays clean after migration.

## 6. Build plan sketch (the fast-follow once a path is chosen)

Sized as **one deliverable per rule-family** (task-sizing rules — no compounding):

- **Path A:** T-a1 schema v2.1 (add `determinism` + `decisionOutputs` list fields to
  `docs/designer/schema.md` §node); T-a2 mechanical corpus migration (`aef.determinism` →
  `determinism`) + re-validate 10/10; T-a3 F3 rules + fixtures (YAML+XML); T-a4 F1 rules +
  fixtures (YAML+XML). Each: real ACs, `## Verification` runs the fixture harness, commit,
  check-in.
- **Path B:** T-b1 `--aef-lint` flag plumbing + PD-002 amendment (record the overturn);
  T-b2 F3 rules behind the flag + fixtures; T-b3 F1 rules behind the flag + fixtures.

Either path is ~4 small tasks; neither needs an execution runtime (stays product-side of
the injection line).

## 7. Recommendation

**Path A (first-class fields), staged — with Path B rejected.**

Rationale, weighed against PD-002 and the four constitutional directives:

1. **Portability (directive 4) — decisive.** `determinism` and `decisionOutputs` describe
   the *product's own* control-flow semantics, not AEF's. Making them product schema fields
   keeps the validator framework-agnostic; Path B hard-couples the validator to the `aef:`
   namespace, which is the one thing the injection-boundary thesis (T-020) tells us to
   avoid. A future non-AEF consumer of the Workflow Designer still needs determinism and
   decision-coverage; it does not have an `aef:` bag.
2. **PD-002 (pure-structural, additive, WARN).** Path A is *compatible*: once the fields are
   product schema, the rules are pure-structural over product structure and stay additive
   /WARN (only `E-DET-VALUE` is an error, and only for a malformed enum). Path B **overturns**
   PD-002 (reading `aef:` is exactly what it fenced off) — permissible only by an explicit,
   logged human decision, not agent initiative.
3. **Antifragility & Reliability.** First-class fields are self-documenting and
   schema-checkable; a bag key is silent until someone writes a linter. Surfacing the
   injection-line frontier as a required-ish field (WARN if absent) makes the most
   product-differentiating property *legible* rather than optional trivia.
4. **Usability.** One migration cost, paid once, mechanical, fully reversible via git; after
   that the vocabulary is discoverable in the schema doc, not folklore in example files.

**Cost acknowledged:** Path A is a v2→v2.1 schema bump plus a 10-file corpus migration.
That is real and is why this is a human call, not an agent one. If the human prefers to
defer the schema bump, **Path B is the correct *interim*** — but it should be built as an
explicitly-flagged, explicitly-logged PD-002 exception, and treated as a stepping-stone to
Path A, not a terminus.

## 8. Open questions for the human (the posture call)

1. **Path A or Path B?** (schema-first vs opt-in aef-lint) — the load-bearing decision.
2. If Path A: is a **v2.1** bump acceptable now, or should F3/F1 wait for the coordinated
   v3 events-&-boundaries bump? (They are additive and independent — I recommend v2.1 now.)
3. `determinism` absence: **WARN** (recommended, additive) or **ERROR** (strict, breaks
   any unmarked node)? Spec assumes WARN.
4. `W-DET-LANE` cross-check: include in the first slice, or defer as a separate refinement?
   (It is the highest-value/lowest-cost "authority model at node granularity" win — F9
   adjacent — but adds lane-authority derivation logic.)

---

_Ends. This document is the T-037 deliverable; no validator, schema, or corpus file is
modified by this task._
