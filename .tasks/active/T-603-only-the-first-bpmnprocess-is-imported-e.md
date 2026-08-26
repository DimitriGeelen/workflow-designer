---
id: T-603
name: "Only the first bpmn:process is imported: every later process is silently discarded"
description: >
  MEASURED 2026-08-26 while landing T-602. parseBpmnXml takes processes[0] (src/aef-workflow-designer.html:10370) and ignores every other bpmn:process in the document. tests/fixtures/third-party/bizagi-nested-ns.bpmn declares two: the first holds only an empty laneSet, the second holds all the flow content. Round-tripping it through the real editor yields nodesInState 0, outDocs 0, outProcesses 1 - the entire diagram is discarded and the save writes an empty process back. Counts do not go down from any baseline the corpus holds, so no existing instrument reports it; T-347's census attributes the loss to 'documentation' because that is the only shape it counts. Severity is total data loss on any collaboration or multi-pool document, which is the normal shape for third-party exports (Bizagi here). Decide whether the fix is import-all-processes, import-the-largest, or refuse-with-a-named-reason - silently keeping the empty one is the only option that is certainly wrong.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T17:47:20Z
last_update: 2026-08-26T17:55:56Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-603: Only the first bpmn:process is imported: every later process is silently discarded

## Context

Found while landing T-602. `parseBpmnXml` took `processes[0]` unconditionally
(src/aef-workflow-designer.html:10370), so every later `<bpmn:process>` was discarded
without a word. `tests/fixtures/third-party/bizagi-nested-ns.bpmn` declares two: the first
holds an empty `laneSet`, the second holds the entire diagram. Measured through the real
editor before any change: `nodesInState 0, outDocs 0, outProcesses 1` — the editor imported
nothing, drew nothing, and would have written the empty process back over the file on save.

Nothing counts DOWN from a baseline the corpus holds, so no instrument reported it. The one
census that touched the file (T-347) attributed the total loss to a "documentation" row,
because documentation is the only shape it counts there. The fixture has been in-tree for
months reading as a documentation defect.

## Acceptance Criteria

### Agent
- [x] The process carrying flow content is the one imported, not blindly the first
- [x] Ties keep the earliest process, so single-process documents and documents whose first process is richest behave exactly as before
- [x] Every process NOT imported is reported to the operator by element id and content count — the residual loss is visible, not silent
- [x] A single-process document raises no process notice at all
- [x] `node tools/_t603-multiprocess-import.mjs --self-test` passes, with a poison arm faithful to pre-T-603 code failing L1-L4
- [x] The T-347 census is re-run as evidence: bizagi moves from `LOST 8->0` to `LOST 8->2`

## Verification

# Shell commands that MUST pass before work-completed. One per line.
node tools/_t603-multiprocess-import.mjs
node tools/_t603-multiprocess-import.mjs --self-test
node tools/_t602-documentation-roundtrip.mjs

## Decisions

- **Pick the richest process AND report the rest, not one or the other.** Choosing better is
  a heuristic: a document with real content in two processes still loses one. Selection alone
  would make the defect rarer without making it visible, which is how it survived this long.
  The report is the half that keeps the residual loss survivable.
- **Do not merge processes or model them as pools.** That is a semantic change to what a
  document means — participants, message flows, pool identity — and it belongs to the
  collaboration question, not to a data-loss fix.
- **Ties keep the earliest.** This is what makes the change byte-neutral for the entire
  existing corpus rather than merely low-risk.
- **The notice is stated last and names ids.** The other two import notices (T-310 lane
  moves, T-315 band growth) report cosmetic or positional repairs. This one means CONTENT IS
  NOT ON THIS CANVAS, so it is worded as not-imported-and-not-saved and carries the element
  ids so the operator can go and look at what was left behind.

## Updates

- The self-test caught a defect in its own poison arm. Neutering only the SELECTION left the
  skip report in place naming the wrong process, so L3 ("a skip was reported") passed on
  broken code — it asserted nothing until the poison removed both halves. A poison arm that
  is not faithful to the pre-fix code produces exactly the vacuous leg it exists to prevent.

### 2026-08-26T17:55:56Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
