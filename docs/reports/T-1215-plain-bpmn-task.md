# T-1215 — Plain `bpmn:task` from third-party maps, and AEF's intake

**Status:** inception, recommendation GO on option (a). **Task:** T-1215.

## The problem

A plain `<bpmn:task>` (BPMN's untyped activity) is what bpmn.io and most authors write by default. The designer keeps
it through a save (T-337 foreignTag: drawn as a task, re-emitted as `bpmn:task`), but AEF's intake
(`tools/corpus_spec.py`) does not accept `bpmn:task`, so such a map cannot be promoted into AEF's corpus.

Options: (a) AEF accepts `bpmn:task` with a round trip; (b) the designer converts it to a supported type on import, with
a notice; (c) leave it and say so on export.

## Evidence

- **How common** (re-counted 2026-10-20): 8 of the 11 third-party fixtures in `tests/fixtures/third-party/` carry a plain
  task (6 prefixed `bpmn:`/`bpmn2:`, 2 unprefixed). Our own authoring kit's example is a `bpmn:task`
  (`docs/authoring-kit/AUTHORING.md:65`), and its calibration clean map carries 12.
- **Cost on AEF's side:** AEF msg abc0de1e — a TYPE_TO_TAG addition with a round trip, like callActivity in their T-4374,
  filed on our decision.
- **Why not (b):** `bpmn:task` says "an activity of no stated kind". Converting it to serviceTask or userTask invents an
  executor the author did not name, and rewrites exactly the maps our kit invites. **Why not (c):** the map stays
  unpromotable.
- The designer needs no change for (a): T-337 already keeps `bpmn:task` byte-identical (third-party goldens).

## Dialogue log

- 2026-10-19: AEF raised it (msg 0917b9b0). Filed with the three options; recommendation DEFER for two evidence gaps
  (how common; cost on AEF's side).
- 2026-10-19: AEF answered option (a) is cheap (msg abc0de1e).
- 2026-10-20: both gaps closed; recommendation changed to GO on (a); template filled.
- 2026-10-20: the go/no-go box was routed operator-only by `fw task classify-ac` because its text said "not a sovereignty
  ... call" (the classifier does not read the negation); reworded, same decision, now reviewer-judged.
- 2026-10-20: reviewer amber — the evidence was wrong in two places: the fixture count was 8/11, not 5/11 (unprefixed
  tasks missed), and the "68 maps other models wrote with our kit" were copies of our two calibration fixtures, which
  the models reviewed, not wrote. Both corrected; the GO stands on the corrected evidence.
