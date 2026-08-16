---
id: T-154
name: "Open-project vs workflow-picker dropdown overlap (dedupe/clarify)"
description: >
  The toolbar workflow-picker <select> (local library switch) overlaps in function
  with the 'Open project…' modal. Operator noted the 3rd control should be open-project,
  not a duplicate of the picker. Needs a design call on how the two relate before
  implementing.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T15:01:58Z
last_update: '2026-08-16T12:33:40Z'
date_finished: 2026-07-09T19:42:12Z
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
  - ts: '2026-08-16T12:33:40Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-154: Open-project vs workflow-picker dropdown overlap (dedupe/clarify)

## Context

The toolbar workflow-picker `<select>` (`#workflow-picker`, switches the local in-memory
library; onchange → `loadFromLibrary`) overlaps in function with the "📂 Open project…"
modal.

**Operator decision (2026-07-09): the picker/dropdown should OPEN THE PROJECT BROWSER** —
i.e. make the dropdown control launch `openProjectModal` (one unified "open a map" entry
point) rather than only switching the local library. Design note for next session: decide
whether to (a) replace the `<select>` with a button that opens the modal, or (b) keep the
`<select>` for quick-switch of already-loaded maps but route "browse all" through the
modal. Confirm the exact interaction before building (the `<select>` currently lists only
in-memory library workflows, not the full project corpus).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these.
     Operator decision (2026-07-09, AskUserQuestion): "Replace with a button" — drop the
     <select> entirely; the toolbar control becomes a "📂 Open project" button that
     launches the full-corpus modal. The <select> quick-switch is gone. Since a
     #btn-open-project button already exists (T-144, in .actions, API-gated), the
     duplicate-free implementation is to MOVE it into the brand slot (next to +) and
     delete the <select> + its onchange handler. -->
- [x] The toolbar `<select id="workflow-picker">` is removed; the `📂 Open project…` button (`#btn-open-project`, `openProjectModal`) sits in the brand area next to the `+` button. **Verified:** `pickerRemoved:true`, `buttonInBrandArea:true`, label `📂 Open project…`.
- [x] No duplicate control: exactly ONE `id="btn-open-project"` exists in the source (the old `.actions` copy is moved, not duplicated). **Verified:** `grep -c` = 1; DOM `querySelectorAll('#btn-open-project').length` = 1.
- [x] No dead `workflow-picker` wiring remains: the `$('workflow-picker').onchange` handler is removed (the element is gone; leaving it would throw at init). `loadFromLibrary` is retained — still used by the palette map-list (`row.onclick`). **Verified:** only live ref is the null-guarded `$('workflow-picker')` in `refreshLibraryUI` (early-returns); init has 0 console errors.
- [x] The button stays API-gated: `display:none` until `/api/health` succeeds, revealed by the unchanged `detectSaveApi` path (finds it by id). **Verified:** button visible after API detect; markup keeps `style="display:none"`.
- [x] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`. **Verified:** MIRROR-OK.
- [x] Playwright visual verification: the brand-area `📂 Open project…` button is visible under the gallery API, clicking it opens the modal (25 maps with tiles); init has 0 console errors; element screenshot READ. **Verified:** click → modal with 26 buttons (25 maps + ✕); 0 console errors; toolbar screenshot READ.

### Human
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
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

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

# Pipe-free greps read the file directly (no `echo |` → no L-387 SIGPIPE, per T-153).
diff -q src/aef-workflow-designer.html build/gallery/designer.html
test "$(grep -c 'id="btn-open-project"' src/aef-workflow-designer.html)" -eq 1
! grep -q 'id="workflow-picker"' src/aef-workflow-designer.html
! grep -q "workflow-picker').onchange" src/aef-workflow-designer.html

## Visual Verification

Viewport 1440×900, gallery on :8834, fresh load:

- `.playwright-mcp/t154-toolbar.png` — the toolbar. Brand area now reads
  `AEF · BPMN  Workflow Designer  ·  [📂 Open project…]  [+]` (the `<select>` picker is
  gone). The `.actions` group has NO second Open-project button — just Add Lane, Reset,
  Clean layout, View XML, Settings, Load…, Versions, Save to project, Save. Single,
  duplicate-free entry point — exactly the operator's chosen mockup. READ and confirmed.

Behaviour: clicking the brand button opens the full-corpus modal (25 maps, all with the
T-153 tiles). Console errors at init + open: **0**.

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

### 2026-07-09T15:01:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-154-open-project-vs-workflow-picker-dropdown.md
- **Context:** Initial task creation

### 2026-07-09T19:38:12Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-09T19:42:12Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
