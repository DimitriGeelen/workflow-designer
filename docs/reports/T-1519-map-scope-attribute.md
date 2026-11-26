# T-1519 — a machine-readable scope for a map (framework | project)

**Status:** inception, EXPLORING. A proposal to AEF; nothing is built until AEF agrees and the operator decides.

## 1. Why

AEF's review of the workflow-designer skill (T-1516, msg b5d90d48): an AEF-development map shipped to every consuming
project, because nothing in a map says whether it is a framework process (ships to every project) or one project's own
process (must not ship). AEF follow-up T-5393. AEF wants the mark machine-readable, so its vendoring step can ship only
framework maps, and asked to agree the name with 832 before either side uses it. Until then, the skill (rule 1) tells
authors to write the scope in the map's description and not to invent an attribute.

## 2. Proposal: the name and values (IW-1)

`aef:workflowMeta/@scope`, with the values `framework` and `project`:

- `framework`: the process belongs to the framework and ships to every project that vendors it.
- `project`: the process belongs to the project whose repository holds it; it does not ship.

Names considered:
- `scope`: short, the word both sides already used in the review. It is not the node-level `scopeOf` (a sub-process
  body, T-081), which lives on nodes, not on `workflowMeta`; checked, no `workflowMeta` attribute is called `scope`.
- `distribution`: precise, but reads as a packaging term.
- `owner`: already means a performer (human/agent) on nodes, so it would collide.

## 3. A map without it (IW-2)

Read as `project`. This fails safe: an unmarked map does not ship. Every map stored today is unmarked, so a vendoring
step that read absence as `framework` would ship all of them, which is the defect we are removing. AEF marks its
framework maps `framework` once, at adoption.

## 4. A new attribute, not a value of `kind` (IW-3)

`kind` says what sort of map it is: a process (unset), `documentation` (an overview), `work-plan` (AUTHORING 6). Scope
says who the map belongs to. The two are independent: a framework overview map needs `kind="documentation"` and
`scope="framework"`. Folding scope into `kind` would make the values multiply.

## 5. Who does what (IW-4)

- **Validator (832):** checks only that the value is `framework` or `project` (as it does for `kind`); a warning, not
  an error, for any other value.
- **Designer (832):** a Scope select in the workflow panel (unset / framework / project), kept through open and save;
  nothing else reads it.
- **Authoring kit (832):** AUTHORING 6 gains one paragraph; the skill's rule 1 points to the attribute instead of the
  description.
- **Vendoring (AEF):** ships only maps with `scope="framework"`; AEF owns the filter and its test.

Contract: an additive, optional attribute on `aef:workflowMeta` in the mapping standard; maps without it stay valid.

## 6. Open, for AEF

1. The name `scope` and the two values: agree or counter-propose.
2. Absent = `project`: agree?
3. Does AEF need a third value (for example a process that ships to some projects only)? If so, a list would be better
   than a single word.

## Dialogue log

- 2026-11-25, AEF (msg b5d90d48): asks for a machine-readable scope on `aef:workflowMeta` (framework | project) and to
  agree the name first.
- 2026-11-25, 832 (reply to b5d90d48): agreed in principle; inception T-1519; a proposal would follow.
- 2026-11-26, 832: this proposal sent to AEF on the consult thread.
