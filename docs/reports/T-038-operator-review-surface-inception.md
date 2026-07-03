# T-038 — Operator review surface for the mapped-process corpus (inception)

```yaml
type: inception-research
task: T-038
authored: 2026-07-03
status: exploring
recommendation: GO (tier 2 — register + read-only diagram viewer)
question: "What is the minimal operator surface to review and correct the mapped-process corpus?"
assumptions: [A-1, A-2, A-3, A-4]
```

## 1. Problem recap

Ten AEF processes are mapped to `examples/aef-processes/*.workflow.yaml`, all validator-clean
(exit 0). But exit 0 = **structural** validity only; **semantic fidelity** (does the mapping
match the real process?) has never been human-reviewed. The mappings and the F1–F17 friction
register are both single-author (me) — a blind spot. No operator register exists; the one
product UI (`src/aef-workflow-designer.html`) reads only `.bpmn`/`.xml`, so the YAML corpus is
currently unviewable. This inception explores the **minimal** surface to close that loop, and
whether doing so surfaces feedback mechanical validation misses (A-4).

## 2. Surface-options analysis (IW-1)

Three tiers, increasing cost:

### Tier 1 — Register only
A generated `examples/aef-processes/REGISTER.yaml` (+ a rendered `REGISTER.md` table): per
process → source AEF process, control-flow family, frictions surfaced, validation status,
**review status** (unreviewed / reviewed-ok / needs-correction).
- **Cost:** low (one generator script + doc). No UI, no bridge.
- **Buys:** answers "what's mapped and where does it stand" (IW-1 partial). Does **not** let a
  human judge *fidelity* — you can't see the process, only its metadata.
- **Verdict:** necessary but insufficient — it's the index, not the review.

### Tier 2 — Register + read-only diagram viewer  ← recommended
Tier 1 **plus** a YAML→BPMN bridge so each corpus file renders in the existing editor, plus a
small gallery/landing linking the register rows to their rendered diagrams. Review = the
operator opens a diagram, compares to the real process, and records a verdict/flag in the
register (operator-authored).
- **Cost:** medium. Enabling piece = the bridge (IW-2). Reuses the existing 4,600-line editor
  as-is (renders BPMN it already understands) — no new editor.
- **Buys:** the actual fidelity review (A-2, A-4). Sovereignty-safe: the agent never rewrites
  a mapping; the operator flags, corrections become tracked findings.
- **Verdict:** the minimal surface that actually delivers the value. **Recommended.**

### Tier 3 — Register + editable, round-trip-in-place
Tier 2 **plus** edit-in-the-diagram and BPMN→YAML write-back so corrections are applied
directly.
- **Cost:** high. Round-trip conversion (lossy risk: comments, `aef:` bag, layout), a save
  backend or File System Access API, and sovereignty guards on agent-vs-human edits.
- **Buys:** faster correction, but the corrections in a *dogfood* corpus are rare and better
  captured as reviewed findings than silent rewrites.
- **Verdict:** over-scoped for the goal (get feedback). Defer; revisit only if review shows
  frequent hand-correction is needed.

**Recommendation: Tier 2.** It's the smallest surface that tests fidelity and feeds back,
reuses the existing editor, needs no live backend, and keeps the agent out of the operator's
mappings.

## 3. YAML→BPMN bridge feasibility (IW-2, A-3)

**IW-2 answered:** no converter exists (`tools/` holds only `validate-workflow.py`); the
bridge must be built. **A-3 (tractable):** high confidence, because —
- `docs/designer/schema.md` already defines **both** the YAML canonical form and the BPMN-XML
  export form, node-type by node-type (start/end/service/user/script/exclusive/parallel/link
  events → their `bpmn:` equivalents; lanes → `laneSet`/`flowNodeRef`; edges → `sequenceFlow`
  with `conditionExpression`).
- The `XmlValidator` in `validate-workflow.py` already **parses** that exact BPMN-XML — so the
  target grammar is not only specified, it's machine-checked. A converter is a mechanical
  walk of the YAML AST emitting the documented XML, and its output can be validated by the
  very same tool (self-checking bridge).

**Planned feasibility spike (throwaway, post-review):** convert one corpus file
(`tier0-escalation.workflow.yaml` — it exercises userTask + exclusiveGateway + conditions +
lanes) to BPMN-XML in the scratchpad, run it through `XmlValidator`, and open it in the
editor. Success = validates clean + renders. **Held pending operator review of this template**
(Inception Discipline: present before spiking).

## 4. The fidelity hypothesis (A-4) — the load-bearing test

A-4: *human review will surface ≥1 fidelity finding mechanical validation missed.* This is the
whole justification. Pilot: once Tier 2 exists (or via a one-off rendered spike), walk the
operator through one mapping (e.g. tier0-escalation) and ask "does this match reality?" If it
surfaces a correction or a missed/false friction, A-4 holds and the surface has earned itself.
If the operator finds the mapping perfectly faithful and sees no value in the view, that's a
NO-GO signal worth catching cheaply.

## 5. Recommendation

**GO, scoped to Tier 2**, delivered in phases as post-GO build tasks:
- **P1 — Register generator** → `REGISTER.yaml` + `REGISTER.md` (standalone value; also the
  gallery's data source).
- **P2 — YAML→BPMN bridge** (`tools/`, self-checked by `XmlValidator`).
- **P3 — Gallery/landing** wiring register rows → rendered diagrams in the existing editor +
  an operator flag/verdict affordance writing back to the register.
- **P4 — Fidelity pilot** with the operator on ≥1 process (tests A-4 for real).

Each phase is independently reversible and product-side of the injection line. P1 alone
answers "what's mapped"; P1+P2 answer "let me see it"; P3 closes the review loop.

## Dialogue Log

### 2026-07-03 — origin of this inception
- **Operator asked:** (a) is there a register where the operator can see which processes are
  mapped? (b) an interaction surface to see the mapping and possibly correct it? — and to
  **reflect** whether this is a good intermediate step that "tests the validity of the model
  and gets user feedback."
- **Agent findings:** (a) no register (dir + prose table only); (b) a BPMN editor exists but
  reads only `.bpmn`/`.xml`, disconnected from the YAML corpus; no YAML→BPMN bridge.
- **Agent reflection:** yes — stronger-sequenced than the paused F3/F1 validator work, because
  it tests *semantic fidelity* (never human-checked) rather than structure, puts the operator
  in the loop (previously absent), and de-risks building rules on a possibly-wrong model.
- **Operator decision:** chose to **start an inception** (option 1) for the register + review
  surface. F3/F1 paused (no task was created; nothing to unwind).
- **Outcome:** this inception (T-038) opened with GO recommendation; template filled; awaiting
  operator review before the bridge feasibility spike.
