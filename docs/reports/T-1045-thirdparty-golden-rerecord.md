# T-1045 — third-party golden re-record: reviewed diff

**Gate:** `tools/_t358-byteid-thirdparty.mjs` (current build vs `tests/goldens/third-party/`, 11 fixtures).
**State before:** 2 identical, 9 drifted. This one cause made two things red:
- the bridge leg the handovers called "T-358 third-party document bytes";
- the `_t509` sweep abstention from `_t581-byteid-baseline-teeth.py`. Its control is red, so it correctly refuses to judge its mutants.

**Goldens recorded:** 3dd1bf86 (T-581, 2026-08-24). Nobody re-recorded them after that.

The gate's rule is "an accepted change is a reviewed diff; re-recording is `--record` and nothing else". This file is that review.

## Method

The output was recorded with `--record` into scratch directories for each build below, using
`T358_SRC=<git show REV:src/aef-workflow-designer.html>` and `T358_GOLDENDIR=<scratch>`. The real
goldens were not touched until the end. Each pair of adjacent builds was then compared with `diff -r`.

| step | builds compared | fixtures changed | cause |
|---|---|---|---|
| 1 | goldens (3dd1bf86) → 7118a92c..adcd5af1~1 | `i18n-documentation` (+1 line) | **T-602** (7118a92c): `bpmn:documentation` on a flow node now survives open→save. The new line is `<bpmn:documentation>A start event.</bpmn:documentation>`, which the golden had recorded as lost. |
| 2 | adcd5af1~1 → adcd5af1 | `bizagi-nested-ns` (73 lines) | **T-603** (adcd5af1): a document with more than one process no longer loses everything but the first. Bizagi's first process is an empty stub, so the golden recorded the **total loss** (0 nodes from a 9 KB file). |
| 3 | adcd5af1 → 3cb17878~1 | none | — |
| 4 | 3cb17878~1 → 3cb17878 | 9 fixtures | **T-891** (3cb17878): a node no `flowNodeRef` claims is no longer put in the first-declared lane. |
| 5 | 3cb17878 → HEAD (a21ef157+) | **none — byte-identical** | — |

Running the bisect over the gate's own counts gave the same answer: 11/0 at 3dd1bf86, 9/2 from adcd5af1 to 3cb17878~1, and 2/9 from 3cb17878 to HEAD.

## T-891's hunks, by kind (all 9 fixtures)

All T-891 hunks are one change seen in several places:
- **`<bpmn:flowNodeRef>` removed** (83 lines; 36 re-emitted under renamed ids). The node no longer belongs to the first lane.
- **Element ids renamed** from the lane-prefixed display id to the unassigned prefix, e.g. `hum_3_start` → `lan_3_start`. The display id carries the lane abbreviation, so leaving the lane renames the node. Its `bpmndi:BPMNShape` (88 lines), and `sourceRef`/`targetRef` on its flows (15), follow.
- **`aef:laneMeta height`** shrinks (e.g. 240 → 130), because the lane is now empty. A few `di:waypoint` lines move with the shapes.

None of these hunks touches anything else: no names, no documentation, no governance keys, no namespaces.

## What this re-record does NOT say

- It does **not** endorse T-891's "no lane" outcome as the right default. That decision is the operator's, open under T-341. T-891 removed a guess and deliberately installed none. If T-341 picks a default, the gate will show it as drift, and a further reviewed re-record follows.
- It does **not** touch T-358's own defect: the importer fabricating lanes the input never had. The fabricated lanes are in these goldens just as they were before; after T-891 they are visibly empty.
- The goldens are a **change detector**, not a correctness oracle. A future silent change will read as DRIFTED, never as a flattering "identical".
