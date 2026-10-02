# Workflow Designer 0.15.2 — release notes

**Since:** `designer-v0.15.1` (2026-10-02) · **The authoring kit, revised from the first real
trial.** An agent at a vendor deployment (Evergreen, T-989) regenerated 26 production maps with
only the 0.15.1 kit. It reported eight places where the kit left it guessing (K1-K8). All eight
are answered here. Each went through the learning ledger (L7-L14) and was confirmed by the
operator before it became a rule.

## Validator

- **A map without start or end events is no longer silently unchecked** (K1, L7). Reachability
  needs a start event and termination needs an end event. Without them both checks used to be
  skipped *silently*, so leaving events out earned fewer warnings than declaring them: omission
  was rewarded. Now each missing kind draws one finding for the map, carrying the number of nodes
  not assessed:
  - `W-XML-NO-START-EVENT` / `W-XML-NO-END-EVENT` (BPMN)
  - `W-NO-START-EVENT` / `W-NO-END-EVENT` (YAML)

  On a source that states no order at all, these are the honest end state (AUTHORING §5). On
  the real corpus they fire on 0 of the designer's own maps.

## Guide (AUTHORING.md) and rubric (v4)

- **K2:** one step precedes two, and the source says nothing about how the two relate. Draw
  plain flows, with no gateway, and add a note if "both always happen" is not stated.
- **K3:** one none start and one none end around a chain the source states are not invented.
  Cite them `unstated` and do not name them as a trigger.
- **K4:** a hand-over to a step in another map is a link throw/catch event (`aef:link`), not a
  note.
- **K5:** records a step creates or uses go in a cited note. The designer does not draw
  `dataObjectReference`.
- **K6:** a system that only *supports* a step is not its performer. The step goes in the `none`
  lane, with a system note.
- §5's table now covers event-less maps.
- The rubric's new "Not invented" list keeps a reviewer from flagging these honest choices.

## Review loop (loop.sh)

- **`loop.sh --review-only <workdir> <source.md> <map.bpmn>`** (K7, L13) reviews a map you
  already wrote, without a generator agent, and numbers the rounds. One reason: an agent harness
  may refuse to let an agent start other agents. The guide now says to run `loop.sh` from a
  plain shell or CI.
- **Reviewer context is measured** (K8, L14). Every review prints its prompt size. Set
  `KIT_REVIEWER_CONTEXT=<tokens>` and a review the reviewer cannot read whole is refused, with
  calibration reporting COULD NOT MEASURE, instead of being run blind. The guide advises at
  least 16K.

## Verified before release

- **Kit tests:** T-974 16/16, T-983 18/18 (new legs 10-12 fail on the 0.15.1 `loop.sh`), T-984
  8/8. Validator guards green: dialect axis, form parity, anchorability, check-pass
  reachability, cross-form agreement (25 pairs, 0 disagreements).
- **Real calibration** of this kit's `loop.sh` with a real sandboxed reviewer (ledger L5):
  RESULT_PLACEHOLDER

## Unchanged

The designer itself. The designer file differs from 0.15.1 only in its version string.
