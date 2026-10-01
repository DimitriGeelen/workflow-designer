# Workflow Designer 0.15.1 — release notes

**Since:** `designer-v0.15.0` (2026-10-01) · **One fix, in the authoring kit only.**

## Fixed

- **The review loop works with sandboxed agents** (T-991). In 0.15.0, `loop.sh` told each agent
  to read the kit by absolute path, outside the agent's working directory. A sandboxed agent
  refuses that: running the released calibration with GLM through opencode logged
  `external_directory ... auto-rejecting`, the reviewer could not read `REVIEW.md`, and
  `loop.sh --calibrate` correctly reported COULD NOT MEASURE. `loop.sh` now stages a copy of the
  kit at `<workdir>/kit/` for every agent and names only `./kit/` paths in every prompt.

## Why 0.15.0 shipped with it

All 14 of the kit's loop tests used stub agents, and a stub has no sandbox. A new test leg now
fails if any prompt points outside the agent's working directory (it fails on the 0.15.0
`loop.sh`), and the learning ledger records the lesson (L5): test the kit's tooling with a real
sandboxed agent before shipping.

## Unchanged

The designer, the validator, the guide, the rubric, the briefs and the calibration set are as in
0.15.0. The designer file differs only in its version string.
