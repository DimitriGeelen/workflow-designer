# T-356 — What happens when real third-party BPMN meets today's importer

**Run:** `node tools/_t356-third-party-fidelity-cdp.mjs`, 2026-08-03.
**Positive control** (`arc-lifecycle`, a designer-produced corpus map, input-derived):
**clean** — so the round-trip path itself is sound and every subject loss below is real.

**Result: 5 of 5 third-party fixtures lose content. T-356 AC2 is satisfied — the
population is capable of failing.** Every number here is the first time this project
has measured import fidelity against documents it did not write.

| fixture | nodes | processes | participants | lanes | msgFlows | DI diagrams | DI shapes | DI edges | `dc:Bounds` | `exporter=` |
|---|---|---|---|---|---|---|---|---|---|---|
| `simple` | 5→**4** | 1→1 | 0→**1** | 0→**3** | – | 1→**0** | 5→**0** | 3→**0** | 9→**0** | 1→**0** |
| `boundary-events` | 9→**8** | 1→1 | 0→**1** | 0→**3** | – | 1→**0** | 9→**0** | 1→**0** | 15→**0** | 1→**0** |
| `multiple-diagrams` | 2→**1** | 2→**1** | 0→**1** | 0→**3** | – | 2→**0** | 2→**0** | – | – | 1→**0** |
| `collaboration-message-flows` | 4→**3** | 2→**1** | 2→**1** | 0→**3** | 4→**0** | 1→**0** | 6→**0** | 4→**0** | 12→**0** | 1→**0** |
| `nested-subprocesses` | 12→12 | 1→1 | 0→**1** | 0→**3** | – | 1→**0** | 8→**0** | 5→**0** | 17→**0** | 1→**0** |

## Confirmations — three previously-synthetic findings now have real witnesses

1. **T-340 (DI dropped).** Wiped in **5 of 5**: every `BPMNDiagram`, `BPMNShape`,
   `BPMNEdge` and `dc:Bounds` goes to zero. Until now this was measured by
   *injecting* DI into a map we wrote. It is now measured on documents Camunda
   Modeler and bpmn-js actually emitted.

2. **T-348 (two-pool collaboration saves as ONE pool).** `collaboration-message-flows`:
   **participants 2→1, processes 2→1**. This row was filed at RAIL-400 as the one
   that survived the T-347/T-348 fold, and it had no third-party witness. It has one
   now — from a document with `exporter="camunda modeler"` on it.

3. **T-348 (first-only root reads).** `multiple-diagrams`: **2 processes → 1, 2
   BPMNDiagram → 0**. A real emitter's multi-diagram document, not an injection.

Also newly visible: **`messageFlow` 4→0** on the collaboration fixture, and **node
loss in 4 of 5** — 9→8, 5→4, 4→3, 2→1. That last column is not cosmetics. Actual
task-graph elements are destroyed on open→save.

## Two findings that are NOT in any existing task

### (A) The importer does not only DROP — it FABRICATES

**Every one of the five gains `lanes 0→3` and `participants 0→1`.** None of these
documents contains a single lane or pool. They come out carrying a three-lane
structure and a participant the author never wrote, and on save that fabricated
structure *becomes* the document.

The whole import-loss class catalogued on this arc — T-337 tags, T-340 DI, T-347
accepted-element content, T-348 root shapes — shares one sentence: *what the
importer does not enumerate is invisible, and export writes only what `state`
holds*. That sentence describes **subtraction**. This is the other direction:
export also writes what `state` holds **that the input never did**, because `state`
is initialised into our own lane skeleton and an absent lane set is indistinguishable
from an empty one.

Subtraction and fabrication are not the same defect and do not have the same repair.
Preserving what you dropped does nothing about inventing what was never there — and
fabrication is the more dangerous of the two, because a dropped element leaves a gap
somebody may notice, while an invented lane assignment is **positively asserted
governance metadata** that reads exactly like the author's intent. Filed separately.

### (B) The fingerprint that proves foreignness does not survive the operation that needs proving

**`exporter=` is dropped in 5 of 5.** The attribute T-356 relies on to establish that
a fixture was tool-authored is destroyed by the very round trip under test.

Consequence, and it is a trap rather than a curiosity: **round-trip a foreign
document once and it becomes indistinguishable from one we authored.** A corpus
"refreshed" by opening and saving these fixtures would silently revert to the
incapable population T-356 exists to escape — and the census that detected the
problem (`grep -c 'exporter='`) would report the fixtures are fine, because it would
be counting the originals. My own criterion has a half-life under the operation it
measures, and nothing warns when it expires.

Practical guard, now stated in `PROVENANCE.md`: the fixtures are **inputs only** and
must never be replaced by their own round-trip output; the pinned digests are what
detects it if they are.

## What this run does NOT establish

- **AC3 is not met.** Each existing import-loss instrument still needs re-running
  with its denominator restated **per-population** (designer-produced vs
  third-party). Pooling 126 incapable files with 5 capable ones would rebuild the
  original error inside the fix.
- **No expectation pin was flipped** (AC4). `_t338`'s `EXPECTED_*` sets are
  untouched; this instrument pins nothing. Every row above is a finding to file, not
  a verdict to update.
- **Nothing was repaired.** T-356 adds a population. The losses it exposes belong to
  T-340, T-348 and the two new tasks, and remain subject to the operator's T-340
  ruling.

## Suite state (AC5)

- `tests/run-bridge-tests.sh` — **69 passed, 0 failed**; geometry sweep 24 clean,
  0 new-fail.
- `tools/_t308-export-byte-identity-cdp.mjs` — **identical: 24** of 24. Adding input
  fixtures changed nothing about what we emit for existing maps, as required.

---

## AC3 — denominators restated PER-POPULATION

The requirement was to re-state each import-loss instrument's denominator with the
split reported per-population rather than pooled, because 126 incapable files
diluting a handful of capable ones would rebuild the original error inside the fix.

The restatement turns out to be simpler and starker than expected: **the split is
already total and disjoint. No instrument pools — because until today no instrument
had a single third-party document in it.**

| instrument | leg | denominator | designer-produced | third-party |
|---|---|---|---|---|
| `_t308` byte-identity | (whole) | 24 corpus maps | 24 | **0** |
| `_t338` fidelity | 1 corpus losslessness | 24 | 24 | **0** |
| `_t338` | 2 out-of-vocabulary tags | **1** (`maps[0]` is the sole carrier) | 1 | **0** |
| `_t338` | 3 malformed input | 24 × cases | 24 | **0** |
| `_t338` | 4 unresolvable refs | 24 × cases | 24 | **0** |
| `_t338` | 5 unknown sub-tree (DI) | 24 | 24 | **0** |
| `_t338` | 6 accepted-element content | 24 × cases | 24 | **0** |
| `_t338` | 7 root shapes | 24 | 24 | **0** |
| `_t356` (new) | third-party fidelity | 5 + 1 control | 1 (control) | **5** |

Three things this table says that the corpus-wide census could not:

1. **Every leg of the pre-existing fidelity instrument carries its probes on
   documents we wrote.** Injection asks "does the importer drop X when X is spliced
   into a file we authored?" — a real question, and not the question the severity
   ratings were quoting it for.

2. **Leg 2's denominator is 1, not 24.** Every out-of-vocabulary tag verdict this
   project holds was measured on a single carrier map, `maps[0]`. That is a
   population definition chosen for one hunt and inherited by every later sentence —
   the RAIL-409 shape again, and it was not visible until the denominators were
   written down side by side.

3. **The third-party column is zero everywhere except the instrument added today.**
   T-356's premise stated corpus-wide is "no third-party BPMN exists in the tree".
   Stated per-instrument it is sharper: *no fidelity verdict this project has ever
   published had third-party evidence behind it.*

**Not pooled, and deliberately not merged.** The new fixtures were NOT added to
`_t338`'s legs. Folding them in would produce mixed denominators (24 designer + 5
third-party) in instruments whose `EXPECTED_*` sets were measured over the
designer-only population, silently changing what every existing verdict means — and
AC4 forbids flipping a pin in this task. The correct sequencing is: measure the new
population separately (done), file what it exposes (T-358, plus confirmations on
T-340/T-348), and let the merge happen in whichever task repairs the defect, where
the pin change is the deliberate subject rather than a side effect.
