# Workflow Designer 0.15.1 — release notes

**Since:** `designer-v0.15.0` (2026-10-01) · **Two fixes, both in the authoring kit.**

## Fixed

- **The review loop works with sandboxed agents** (T-991). In 0.15.0, `loop.sh` told each agent
  to read the kit by absolute path, outside the agent's working directory. A sandboxed agent
  refuses that: running the released calibration with GLM through opencode logged
  `external_directory ... auto-rejecting`, the reviewer could not read `REVIEW.md`, and
  `loop.sh --calibrate` correctly reported COULD NOT MEASURE. `loop.sh` now stages a copy of the
  kit at `<workdir>/kit/` for every agent and names only `./kit/` paths in every prompt.

- **Calibration no longer fails a correct reviewer** (T-991). Once the loop could run, the real
  calibration said FAIL for a reviewer that had caught all three planted defects:
  `calibration/planted.bpmn` carried artefacts of how the defects were planted (a flow id that lied
  about its target, five stale incoming/outgoing references), and scoring demanded the exact node
  and category, so a correct catch reported on the implementing flow scored as a miss. The planted
  map now holds its three defects and nothing else, and a defect counts as caught when any element
  that implements it is reported with any category that truthfully describes it.
  **Real result on 0.15.1: GLM-5.2 through opencode (sandboxed) caught 3/3, 0 false findings.**

## Why 0.15.0 shipped with it

All 14 of the kit's loop tests used stub agents, and a stub has no sandbox. A new test leg now
fails if any prompt points outside the agent's working directory (it fails on the 0.15.0
`loop.sh`), and the learning ledger records the lesson (L5): test the kit's tooling with a real
sandboxed agent before shipping.

## Unchanged

The designer, the validator, the guide, the rubric and the briefs are as in
0.15.0. The designer file differs only in its version string.
