# T-281 — Audience lenses: one map, read by business, logical and technical readers

Inception research artefact (C-001). Started 2026-10-19 after the operator revived T-281 (H1 reversed). Exploration
only; no build before `fw inception decide T-281`. Any build that renders gets screenshots at three widths and an
independent reviewer (UI rule, 2026-10-14).

## The question

Should the designer show one map through audience lenses (business, logical, technical), so that each reader
sees what matters to them without a second document, and if so, what is a lens: a view preset in the designer, a
rendered document, or both?

## Where it comes from

AEF process-layer package, INSTRUCTIONS §2.2 "The three lenses (P1) — views, not separate files": "A single
workflow file carries all three design layers; renderers filter."

| Lens | Fields shown | Audience |
|---|---|---|
| business | lanes, node names, gateways and decision labels, human-touchpoint decisions, descriptions | business stakeholder, the Sovereign's review |
| logical | + I/O contracts, conditions, link events, callActivity references | designer, reviewing agent |
| technical | + endpoints, contextReads/artifactsWrites, tiers, routing, components | implementing agent, operator |
| pseudocode (SD-14) | a linearised logical lens (if/else, parallel blocks, calls), one-way derived | executing agent, PR reviewers |

The package also names `fw workflow render <id> --lens …` as a renderer, and Lock 5 asks for proof of all four lenses.

## AEF's position (their T-2669, msg 705e7d58)

T-2669 is **not** an objection. Its finding: the business/logical/technical lenses belong to roadmap Arc 4
(arc-019 §10), rendered from the ratified procedure, in the designer, not in AEF's corpus-map package. A
designer-only render view with no compiler impact is fully consistent with it. Three conditions:
1. **One reader, not a second:** wrap or replace the `fw corpus explain` / ask-recall seam (AEF T-2622), never
   duplicate it.
2. **The pseudocode lens (SD-14) was retired** on its own evidence; it stays out unless this inception adds it
   with a named consumer.
3. **The first real reader is the operator,** through the onboarding curriculum's routes: a ready acceptance
   fixture for the business lens.

## What already exists in the designer

| Piece | What it does | Relevance |
|---|---|---|
| Field profile (T-1125/T-1128, `/api/field-profile`) | Per-project policy: which Extensions fields the side panel shows; hidden ones are marked in the details view | A lens is a NARROWER, per-reader selection on top of it. Layering: the profile decides what may be shown; the lens decides what this reader sees. |
| Hide empty fields (T-1124) | Folds unset fields in the panel | Same mechanism, different axis |
| Element details view (T-1127) | Every field of one element, full screen | The "technical" end, for one element |
| Canvas badges (id, authority, findings) | Technical decoration on the map | A business lens hides most of it |
| `fw corpus explain <map_id>` (framework) | A map explained in text | The one reader AEF means; a lens must use it, not re-implement it |

So most of a lens already exists as parts. What is missing is a **named, switchable selection** (business /
logical / technical) that applies to the panel, the details view and the canvas decoration at once, and that is
recognisably the same view the text reader produces.

## Design options

| Option | What | Pro | Con |
|---|---|---|---|
| A. View preset in the designer | A lens switch in the toolbar; each lens is a field-and-decoration selection over the field profile | Small; reuses T-1124/T-1125/T-1127; immediate for the operator | A second reader unless tied to corpus explain (condition 1) |
| B. Rendered document | `fw corpus explain --lens business` produces the business view as text/HTML | One reader by construction; diffable | Not in the designer, where the operator reads maps |
| C. Both, from one definition | One lens definition (which fields and elements per lens) used by the designer's switch AND by the explain reader | Satisfies condition 1 and is visible where people read | Needs the definition shared across two code bases (designer JS, framework Python) |

**Leaning: C, built in two slices:** first the lens definition as a data file both sides can read, with the
designer switch (A) driven by it; then the explain reader reads the same file (AEF's side, via T-2622's seam).

## Slices (if GO)

1. **Lens definition + business lens in the designer.** A small data file naming the fields and decorations per
   lens; a toolbar switch (business / logical / technical / all); business hides technical badges and fields.
   Accepted when the operator reads an onboarding-route map in the business lens and can follow it.
2. **Logical and technical lenses,** from the same file.
3. **The explain reader reads the same definition** (with AEF, T-2622 seam): `fw corpus explain --lens`.
4. Pseudocode: out, unless a consumer is named (condition 2).

## Open questions

- **IW-1:** Is a lens a per-reader view (A), a document (B) or both (C)? (Leaning C; confidence 1.)
- **IW-2:** How does a lens relate to the field profile? Proposed: the profile is project policy (what may be
  shown), the lens a per-reader selection within it, never showing a field the profile hides. (Confidence 2.)
- **IW-3:** Which onboarding-route maps are the acceptance fixture, and does the operator read them in the
  designer or as text? Needs the operator. (Confidence 0.)
- **IW-4:** Does AEF want to own the lens definition file (it is about reading THEIR process maps) or should 832?
  **Answered (AEF msg 77dcf341):** AEF owns it. It lives next to `tools/corpus_spec.py`; `tools/` is vendored to
  consumers again since AEF T-4392, so the designer reads the same file from the vendored framework, not a copy.
  AEF validates that every field a lens names exists in the corpus spec; 832 proposes changes by message. Filed
  as **AEF T-4402** (horizon next; it waits for this inception and builds after we confirm the shape). The lens
  applies to `fw corpus explain --lens`; the ask/recall index stays lens-free (retrieval is not filtered by
  audience) unless this inception finds a reason. (Confidence 3.)
- **IW-3 input from AEF:** first business-lens fixtures `aef-task-lifecycle` (referenced 6 times from the
  onboarding curriculum, the most-read map) and `aef-session-lifecycle` (4); second tier
  `aef-greenfield-onboarding` and `aef-existing-project-onboarding` (2 each), the first maps a newcomer meets. Still
  open for the operator: read them in the designer, as text, or both.

## Hypothesis (draft)

We believe that a business lens in the designer, defined once and shared with the explain reader, lets the operator
follow a process map without technical noise, and we will achieve one reader per map instead of a map plus a
separately written summary. We will know we succeeded when the operator reads an onboarding-route map in the
business lens and says they could follow it, and `fw corpus explain --lens business` shows the same selection.

## Dialogue log

- 2026-10-19, operator: revived T-279/280/281/282, confirmed "1" (build all four; lenses raised with AEF).
- 2026-10-19, AEF: T-2669 points the lenses at Arc 4 in the designer; three conditions (above).
- 2026-10-20, operator: T-281 ruled **GO** (asked with the agent's then-standing DEFER as the recommended option).
- 2026-10-20, operator, IW-3: reads the fixture maps **in the designer**. The hypothesis and recommendation in the
  task were updated to slice 1 accordingly; the decision itself is recorded by the operator's job.

## Recommendation (draft)

**GO for slice 1** (lens definition + business lens), with IW-3 answered by the operator and IW-4 asked of AEF
first. Logical and technical lenses and the explain-reader integration follow as their own build tasks.
Pseudocode stays out.
