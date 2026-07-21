# T-213 — Disposition: `aef:workflowMeta kind=` diagram-kind marker (AEF T-2556)

**Status:** recommendation written, awaiting operator disposition (owner: human)
**Arc:** designer-authoring-surface (AEF integration)
**Rail:** `[[aef-integration-rail]]` — AEF T-2556, offsets 87 (original) → 125 (full proposal)

## The gap (origin)

Corpus diagrams D1–D5 are **documentation** — framework processes drawn for humans to read.
Nothing in the serialized BPMN distinguishes them from an actionable **work-plan**. So AEF's
`fw bpmn promote` treats illustrative nodes as promotable and mints real `owner:human` tasks
from them.

This is a **live defect**, not hypothetical: AEF's L-504 / T-2548–T-2549 records a joint fixture
whose inception-marked documentation nodes were promoted straight into the task gate. The
serialized artifact carries zero author-intent signal, so the consumer cannot tell "this is a
picture" from "this is a plan."

## AEF's proposal (their T-2556 build, gated on our ratification)

One **optional** attribute on `aef:workflowMeta`:

```
kind="documentation" | kind="work-plan"
```

- Absent/unknown `kind` → **byte-identical today-behavior on both sides.** No other serialization change.
- AEF-side consumption once 832 ratifies:
  1. `fw bpmn compile`: `kind=documentation` adds one advisory notice ("documentation diagram —
     skeletons are illustrative, not for promote"); all skeleton output unchanged.
  2. `fw bpmn promote`: refuses `kind=documentation` staged proposals (explicit override flag for
     the deliberate case).
  3. Regression tests pin both paths: absent-marker byte-identical + marked-documentation refusal.
- 832-side (our call, all optional): surface `kind` in the meta-edit UI; new diagrams default
  **UNSET** (not `work-plan`) so the marker stays an explicit author decision. AEF would re-mark the
  5 corpus diagrams `kind=documentation` via normal editor saves after ratification — no bulk rewrite.

## Analysis

**Why this is low-risk:**
- *Additive + frozen-v1 safe.* Absent/unknown `kind` is byte-identical, so it cannot disturb the
  existing byte-pinned corpus (session-handover / dispatch-loop / offpage-seam). Those stay clean
  until deliberately re-marked. No pin moves without an explicit author save.
- *Right layer.* Intent originates where authoring happens (the 832-owned schema), and the consumer
  (AEF) enforces on it. The producer/consumer split mirrors the seam contract exactly.
- *No silent reclassification.* Default-UNSET on new diagrams means the marker is always an explicit
  choice; nothing is auto-tagged `work-plan`.

**Meets the GO criteria:** root cause identified (no intent signal in the file), bounded fix path,
scoped/testable/reversible.

## Open questions → dispositions

- **IW-1 — ratify the marker?** Answered: GO/ratify (agent read; operator's sovereign call).
- **IW-2 — closed enum vs open string?** Answered: closed enum `{documentation, work-plan}`.
- **IW-3 — default for new diagrams?** Answered: UNSET (explicit author decision).

## Amendment options (for the operator)

| Axis | Options | Recommendation |
|------|---------|----------------|
| Attribute name | `kind=` (namespaced under `aef:workflowMeta`) | Keep — concise, no collision with existing attrs |
| Values | closed enum `{documentation, work-plan}` vs open string | **Closed enum** — frozen-v1 discipline; open vocab invites drift; a third value can be added later additively without moving a pin |
| Third value now? | add `template`/`example` | Defer — not needed for the defect |

## Recommendation

**GO — ratify as-is**, with the closed-enum amendment. (Agent read; ratification is the operator's
sovereign call — the dialect vocabulary is 832-owned.)

## On ratification — the build loop (same as the seam)

1. 832 spins a build task: (a) `kind=` surfaced in the meta-edit UI, default UNSET; (b) the byte-exact
   `kind=documentation` fixture (validate-clean → byte-pin → rail-inline delivery).
2. 832 re-marks the 5 corpus diagrams `kind=documentation` via normal editor saves.
3. AEF wires their T-2556 legs (compile-notice + promote-refusal + regression pins) *after* our
   delivery — producer-contract discipline, identical to T-219.

## Dialogue Log

- **2026-07-19 (offset 87):** AEF first floats the diagram-kind marker; 832 files T-213 to hold the
  disposition (owner: human), non-blocking for AEF.
- **2026-07-21 (offset 125):** AEF sends the full proposal with the concrete build legs + the live
  defect citation (L-504 / T-2548-9), requesting disposition (ratify / amend / reject). No urgency.
- **2026-07-21 (offset 127):** 832 acks receipt, routes to T-213, posts the non-binding engineering
  read (ratify-as-is, closed enum), commits to posting the disposition on the rail once the operator
  rules. Same loop as the seam — AEF builds only after 832's word.
