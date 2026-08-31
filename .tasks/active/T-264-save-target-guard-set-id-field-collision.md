---
id: T-264
name: "Save-target guard set: ID-field collision feedback + commit-on-blur + load-source
  mismatch confirm (T-263 GO)"
description: >
  Build task authorized by T-263 GO (operator decision 2026-07-27). Three guards,
  zero seam surface, all in src/aef-workflow-designer.html: (1) props-panel ID field
  shows visible feedback when a rename collides with an existing library key (today:
  silent revert, 0 alerts/toasts — T-263 probe leg3); (2) ID field commits on blur/Enter
  instead of every input event (today: successful per-keystroke rename re-renders
  the panel and dumps focus mid-typing — probe leg2); (3) saveToProject confirms when
  the current load source names a different map than workflowMeta.id (today: silent
  overwrite of the original — probe leg4, the AEF rail-225 incident). workflowMeta-id-wins
  stays the design; no second identity authority. Evidence base: docs/reports/T-263-save-target-binding.md
  + tools/_t263-save-target-cdp.mjs (extend its legs into regression asserts).

status: captured
workflow_type: build
owner: human
horizon: later
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-27T21:23:22Z
last_update: 2026-08-23T10:24:09Z
date_finished:
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:00Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 3
      F3: 2
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=3 
      (prose:routing-defect-class); F3=2 (prose:seam-namespace); F1=2 
      (prose:process-editor-capability)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-263-save-target-binding.md,src/aef-workflow-designer.html,tests/run-bridge-tests.sh,tests/test_t264_save_target_guards.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-264: Save-target guard set: ID-field collision feedback + commit-on-blur + load-source mismatch confirm (T-263 GO)

## Context

T-263 GO (operator, 2026-07-27). Evidence: docs/reports/T-263-save-target-binding.md;
probe harness tools/_t263-save-target-cdp.mjs (legs become regression asserts).
Origin incident: AEF rail 225 — scratch copy carrying the original's workflowMeta id
silently overwrote the original project. Design ruling: workflowMeta-id-wins stays;
the fix is feedback + guard, not a second identity authority.

**BUILD COMPLETE (2026-07-27, next session):** all steps (a)–(g) below executed;
8-leg harness green, suite 40/40, collision-notice screenshot READ + published
(see ## Visual Verification). Awaiting the Human [REVIEW] AC only.

**BUILD STATE (session ended at budget gate ~287k, 2026-07-27):** Two INERT edits
landed in src/aef-workflow-designer.html — (1) `field()` grew an `opts.deferred`
commit-on-blur/Enter branch (no caller passes it yet, so zero behavior change);
(2) `let _idRenameNotice = null` declared above renderProperties (unused yet).
**Next session continues with:** (a) rewrite the ID-field callback in
renderProperties (:~5045) to pass `deferred: true`, set `_idRenameNotice` on
renameActiveWorkflow refusal, always re-render, and render the notice div after the
ID field append (styled `field-hint id-rename-notice`, `var(--danger)`); (b) add
`_loadSrcStem(src)` helper near currentLoadSrc (:~9414): strip query/hash, basename,
strip `.bpmn/.xml` + `.vN`, lowercase; (c) in saveToProject after the id-regex check
(:~7935): `const _src = (_loadSrcKey != null && activeKey === _loadSrcKey) ?
currentLoadSrc() : null;` → if `_loadSrcStem(_src)` is non-empty and ≠ id.toLowerCase(),
`confirm('Loaded from "<src>" but will save as "<id>" — proceed?')` — abort save on
decline (restore btn label); (d) new harness tools/_t264-save-target-guards-cdp.mjs
(legs: input-event does NOT commit / blur commits / Enter commits / insertText keeps
focus mid-typing / collision renders notice naming the id / mismatch-confirm via
history.replaceState('?load=rendered/other-map.bpmn') + _loadSrcKey=activeKey with
stubbed confirm false→abort true→POST, same-stem→no confirm, no-?load BITE / Title
field still live-commits); (e) wrapper test + run-bridge-tests.sh leg; (f) screenshot
of the collision notice, READ it (visual verification); (g) full bridge suite green.

## Acceptance Criteria

### Agent
- [x] Collision feedback: renaming the workflow (props-panel ID field) to an id that
      already exists in the library shows a visible, non-blocking hint at the field
      (naming the colliding id) instead of today's silent revert; state remains
      unchanged (renameActiveWorkflow still refuses — only the feedback is new).
- [x] ID-field commit-on-blur/Enter: the workflow ID field no longer commits a rename
      on every input event; the rename fires once on blur or Enter. Typing multiple
      characters into the field keeps focus for the whole edit (no mid-typing panel
      re-render). Other meta fields (Title/Version/Description/Source) keep their
      existing live-commit behavior.
- [x] Load-source mismatch confirm: when the document was loaded from a ?load/deep-link
      source whose map name differs from state.workflowMeta.id at save time,
      saveToProject asks one confirm ("Loaded from '<source>' but will save as '<id>'
      — proceed?") before POSTing; same-id saves and non-deep-link documents see no
      new prompt.
- [x] Probe harness extended into a regression guard: _t263 legs re-asserted against
      the new behavior (collision now surfaces feedback; blur/Enter commits; mismatch
      confirm observed via stubbed confirm + /api/save), BITE included (guards driven
      by state, not string echo); suite leg registered in tests/run-bridge-tests.sh;
      full bridge suite green.
- [x] Zero seam surface confirmed: no change to aef:* messages, BPMN emit, MANIFEST,
      or any AEF-facing contract (diff scoped to editor UI paths + tests).

### Human
- [x] [REVIEW] Guard prompts read right (wording + non-naggy feel)
  **Steps:**
  1. Open the editor at http://192.168.10.107:8834/designer.html (gallery serve of
     current src; if 404, ask the agent to refresh the gallery docroot first)
  2. Click empty canvas (no selection) → in the right panel, edit the ID field to an
     existing map's id and press Enter → a hint appears naming the collision
  3. Load any map via "Open from project", change its ID, then "Save to project" —
     the mismatch confirm names both the load source and the save target
  **Expected:** Hint and confirm wording are clear; typing in the ID field keeps focus
  **If not:** Note which prompt reads wrong — wording lives in one place each

<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-264`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-264 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# T-264 guard set: all three guards present in src, harness green, suite leg registered.
grep -q 'id-rename-notice' src/aef-workflow-designer.html
grep -q '_loadSrcStem' src/aef-workflow-designer.html
grep -q 'opts.deferred' src/aef-workflow-designer.html
grep -q 'test_t264_save_target_guards' tests/run-bridge-tests.sh
# Full 8-leg CDP harness via the pytest wrapper (L-387-safe: wrapper captures output).
python3 tests/test_t264_save_target_guards.py

## Visual Verification

- Collision notice, element-level screenshot (properties panel, dark theme), READ 2026-07-27:
  red `.id-rename-notice` renders between the reverted ID field and Title, text
  `id "task-lifecycle" already exists in this library — rename not applied`, hint shows
  "Enter/blur applies", no overlap/regression in adjacent fields.
  Published for operator: http://192.168.10.107:8834/t264-collision-notice.png
  (sha256 557d2b1730df8937dfe9275534968c691bc5e659e5047acfe57faedec618ae6f)

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

### 2026-07-27T21:23:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-264-save-target-guard-set-id-field-collision.md
- **Context:** Initial task creation

### 2026-07-27T21:24:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9af09175
- **Timestamp:** 2026-07-29T13:13:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
### 2026-07-27T21:46:24Z — status-update [task-update-agent]
- **Change:** owner: agent → human

### 2026-08-23T10:24:09Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)
