# T-1010 — AEF as a standing design partner (inception, under EWCR / arc-002)

**One question:** should AEF become a standing design partner — owning its process maps and iterating
them through our authoring kit the way Evergreen does — so that the designer is developed against the
second half of EWCR (Executable Workflow Contract Runtime): a map becoming something that runs?

Status: exploration not started. Agent recommendation at filing: GO (provisional), see task.
Open questions IW-1..IW-4 are in the task file.

## Why now
- We render 24 of AEF's processes (examples/aef-processes/rendered/) from YAML kept in OUR repo. AEF
  consumes ZERO of them (AEF, 08-12 and 09-25). We draw their processes for them: the wrong direction.
- The Evergreen loop works: kit, calibration, measured iterations, learning ledger, calibrated
  cross-vendor panel, release (T-989, T-1006, T-1008: 3 iterations, K1-K17, kit 0.15.3).
- Evergreen only exercises conception -> documented map. EWCR's other half — which steps run
  deterministically (scripts/CLI), their inputs/outputs, where an agent is the fallback, where a human
  decides — needs a partner whose processes actually execute. AEF is that partner, and AEF has
  `fw bpmn compile`.
- EWCR Arc-0 has been stalled on rulings since 09-21 and lacks a concrete artefact.
- AEF adopted 6 of our 7 recent proposals within days: the channel works (once our inbox reads it, G-082).

## What the designer already carries vs what an executable contract needs
| has | lacks (expected findings, AEF's equivalent of K1-K17) |
|---|---|
| lanes with authority (sovereignty / authority / initiative / automated) | per-step inputs and outputs |
| aef:meta per element, round-trip guarded | a command / script binding for deterministic steps |
| hand-overs between maps (aef:link) | agent-as-fallback semantics (try script, else agent, else human) |
| validator + kit + calibration | a contract check: "this map compiles", run by the kit |

## The 24 maps (operator item 1)
Held as they are. If GO: they become AEF's round-0 corpus — AEF takes ownership, runs them through
the kit for a measured baseline, task-gate is their first compile; we delete our copies only after AEF
holds them. If NO-GO: decided then (delete or keep as fixtures). Operator items 2 (standing joint
fixture set) and 3 (post task-gate/context-memory bytes, T-827) are decided inside this inception.

## Dialogue log
- **2026-10-03, operator** (on item 1, keep/delete the 24 rendered maps): "This is basically AEF eating
  our system, using our system ... We want to evolve in AEF into using the workflow designer into
  something where operator and agent draft and design a process that later becomes into a programmatic
  system ... where we also define what can be run deterministic through scripts and CLI commands. What
  are the inputs, outputs and where, for instance, an agent needs to be the fallback ... from first
  conception class design to repeatable instance execution and reiterating and refining ... if we do
  start going towards the same iterative process with AEF as we are now doing with Greenfield ... a
  standing collaboration where we continuously iterate ... and AEF consuming the changes we made and
  applying them on their workflows. So maybe for these 24 we can just delete them all and AEF recreates
  them again. Maybe we apply our fixes to them and feed them back in ... Maybe they should become its
  own exception and its own arc even."
- **Agent reflection:** the 24 are our renderings, unused by AEF; hand them over as AEF's round-0
  corpus rather than delete or fix them ourselves; open ONE inception under EWCR (not a new arc yet:
  an arc now would bundle independent questions into one all-or-nothing decision).
- **Operator:** "Set as suggested." -> T-1010 opened; items 1-3 are decided inside it.

## Exploration log
- **2026-10-03 step 1:** proposal + Q1 ownership, Q2 loop/cadence, Q3 compile, Q4 objections sent to
  AEF on sidecar conversation `aef-design-partner` (client_msg_id 6fe3dd6d). Awaiting reply.
- **2026-10-03 step 2 (spike, running):** task-gate.bpmn (designer-v0.15.3) validates CLEAN with the
  0.15.3 validator; now through the kit's review loop (`loop.sh --review-only`, codex reviewer) against
  AEF's own description of the task gate (vendored docs/articles/deep-dives/01-task-gate.md) as SOURCE.
- **Side findings while clearing AEF's inbox** (relevant to cadence, IW-2): our sidecar reader showed
  one 100-envelope page and hid 85+88 later messages (G-082); "REPLIED" receipts do not cross between
  1.7.740 and AEF's unreleased receipt code, so both sides nudge each other. A standing partnership needs
  that channel fixed first; AEF has both filed.
