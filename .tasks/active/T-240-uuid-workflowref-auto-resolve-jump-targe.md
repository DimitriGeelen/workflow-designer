---
id: T-240
name: "uuid workflowRef: auto-resolve jump target on load"
description: >
  AEF field observation (rail offset 166, their T-2611, non-blocking): a linkEventThrow with uuid workflowRef + name shows 'Target workflow — none —' and a disabled jump after a ?load deep-link load, until the operator re-binds via Choose-from-project; legacy slug refs bind directly. AEF's whole corpus is uuid-form post-recreate, so this costs one picker step per jump per session. Candidate fix (AEF-suggested): resolve uuid->project via /api/list at load/import time and bind the jump target when exactly one live map matches the workflowRef.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-22T21:20:28Z
last_update: 2026-07-23T07:07:17Z
date_finished: 2026-07-23T07:07:17Z
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

# T-240: uuid workflowRef: auto-resolve jump target on load

## Context

AEF field observation (rail 166, their T-2611): after a `?load` deep-link, a link node carrying
only `workflowRef` (uuid) + `name` shows "Target workflow — none —" with a disabled jump button;
the operator must re-bind via Choose-from-project once per session. Root cause (investigated):
the jump affordance (properties readout at ~5094, jump button at ~5124, dbl-click at ~6791) is
wired ONLY to `aef.targetWorkflow` (legacy slug), and `jumpToWorkflow()` resolves by library key
or `/api/list` map `id` — never by uuid. `/api/list` already exposes `uuid` per map (gallery-serve
`list_project_maps`), so a runtime uuid→project index is sufficient; no server change needed.

Design: module-level uuid→project-id index built from `/api/list` (refreshed at `detectSaveApi()`
success, after a successful save-to-project, and opportunistically inside `jumpToWorkflow`'s
existing fetch). `effectiveJumpTarget(n)` = explicit `targetWorkflow` else index lookup of
`workflowRef`. Binding is RUNTIME-ONLY — `aef.targetWorkflow` is never written (ratified: diagram
XML is never silently migrated; serialization stays byte-identical). Ambiguity guard: a uuid
matching more than one live map is dropped from the index (bind only on exactly-one match, per
the AEF-suggested contract); a uuid matching zero live maps (ghost) stays unresolved — readout
"— none —", jump disabled, no false binding.

## Acceptance Criteria

### Agent
- [x] With the gallery API available, a link node with only `workflowRef` (uuid) + `name` whose
      uuid matches exactly one live project map shows that map's id in the Target workflow
      readout (visibly marked as auto-resolved from the uuid) instead of "— none —", and the
      "Open target workflow" jump button is enabled — including after a `?load` deep-link load
      (the exact AEF field case).
      *(t240-uuid-resolve leg: panel DOM read after `?load` shows resolved id + marker, button enabled)*
- [x] Jump works from both affordances on such a node (jump button and node double-click) and
      opens the resolved map.
      *(leg clicks the REAL jump button → lands on t240-target with nodes>0; dbl-click delegates to
      `effectiveJumpTarget(n)`, asserted to return the resolved id)*
- [x] No silent migration: resolving/jumping never writes `aef.targetWorkflow`; the serialized
      XML for a workflowRef-only node contains no `targetWorkflow` attribute after resolve+jump.
      *(leg asserts `aef.targetWorkflow` unset in state AND `buildBpmnXml` emit carries no
      `targetWorkflow=` substring)*
- [x] Negative guard: a uuid matching zero live maps (ghost) keeps "— none —" and a disabled
      jump button; an explicit `targetWorkflow` always wins over the uuid resolution.
      *(ghost probe n_gh asserted "— none —" + disabled + no marker; explicit-wins is structural:
      `effectiveJumpTarget` short-circuits on `targetWorkflow`, and the panel computes `resolved`
      only when `cur` is empty; duplicate-uuid ambiguity drops the uuid from the index entirely)*
- [x] `jumpToWorkflow()` also resolves a raw uuid argument via the `/api/list` uuid match
      (free-text uuid target jumps instead of dead-ending at "not found").
      *(step-2 finder now matches `x.id === id || x.uuid === id`)*
- [x] A T-240 leg is added to the standing editor-behavior CDP suite
      (`tools/_editor-behavior-verify-cdp.mjs`) covering the resolve, jump, ghost-guard, and
      no-migration assertions hermetically; the full suite passes.
      *(4/4 legs green: jump-no-poison, same-map-edit-restore, t237-classification, t240-uuid-resolve;
      pytest wrapper tests/test_editor_behavior.py passes)*

### Human
- [ ] [REVIEW] The auto-resolved readout reads clearly in the properties panel
      **Steps:**
      1. `cd /opt/832-Workflow-designer && python3 tools/gallery-serve.py --port 8834` (if not already running)
      2. Open http://192.168.10.107:8834/aef-workflow-designer.html?load=arc-lifecycle.bpmn (or any map with a uuid link node), click a link event whose ref is a uuid
      **Expected:** Target workflow shows the resolved map id with an "auto-resolved" note, jump button enabled; one click lands on the target map
      **If not:** Screenshot the properties panel and note what reads wrong
<!--

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Visual Verification

Element-level screenshots of the properties panel, captured hermetically (isolated
chromium + sidecar, G-006) and READ:
- `.playwright-mcp/t240-panel-resolved.png` — resolved node: "Target workflow / t240-target"
  in normal text + "↳ auto-resolved from workflow ref (uuid)" marker, styled like existing hints.
- `.playwright-mcp/t240-panel-ghost.png` — ghost node: muted "— none —", no marker.
No layout regression in either state.

## Recommendation

**Recommendation:** GO
**Rationale:** All six Agent ACs verified via the standing hermetic suite (real panel DOM,
real button click), no serialization change by construction (runtime-only index, never
written into aef), and the exact AEF field case (?load deep-link) is the tested path.
Open item: the Human [REVIEW] AC on how the auto-resolved readout reads.
**Evidence:**
- t240-uuid-resolve leg green: resolved readout + marker + enabled jump after ?load; real
  button click lands on t240-target (1 node); ghost stays "— none —"/disabled
- No-migration: state `aef.targetWorkflow` unset + emitted XML has no `targetWorkflow=`
- Full suite 4/4 legs, pytest wrapper green, corpus pins green
- Panel screenshots (both states) captured and read — see Visual Verification

## Verification

out=$(node tools/_editor-behavior-verify-cdp.mjs 2>&1); python3 -c "import json,sys; v=json.loads(sys.argv[1]); assert v['pass'], 'suite failed'; legs={l['leg']: l['pass'] for l in v['legs']}; assert legs.get('t240-uuid-resolve'), 't240 leg failed'" "$out"
python3 -m pytest tests/test_editor_behavior.py -q
grep -q "auto-resolved from workflow ref (uuid)" src/aef-workflow-designer.html
grep -q "function effectiveJumpTarget" src/aef-workflow-designer.html
grep -q "t240-uuid-resolve" tools/_editor-behavior-verify-cdp.mjs
test -s .playwright-mcp/t240-panel-resolved.png
test -s .playwright-mcp/t240-panel-ghost.png

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-22T21:20:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-240-uuid-workflowref-auto-resolve-jump-targe.md
- **Context:** Initial task creation

### 2026-07-23T06:57:52Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-23T07:07:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
