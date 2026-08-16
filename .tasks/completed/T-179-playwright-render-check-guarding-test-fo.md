---
id: T-179
name: "Playwright render-check guarding test for designer build"
description: >
  Add a committable Playwright render-check that guards the designer BUILD (complement
  to curl+sha byte-check). Serves the built artifact locally, loads it headless, asserts:
  (1) render — palette, canvas nodes, inspector present; (2) version/feature marker
  — FIELD_META.horizon present (catches stale/wrong build); (3) console clean EXCEPT
  the documented /api/health 404 (whitelist+comment the expected backend-absent probe;
  do NOT suppress in src) and favicon. Needs new node/playwright dev tooling (832
  is shell+python only today; chromium already cached). Origin: T-178. See learning
  under T-178 (P-011).

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
created: 2026-07-10T21:17:29Z
last_update: '2026-08-16T14:33:18Z'
date_finished: 2026-07-10T21:45:05Z
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
  - ts: '2026-08-16T12:33:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:18Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); 
      F4=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/test_designer_render.py,tests/test_editor_bridge_meta_parity.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-179: Playwright render-check guarding test for designer build

## Context

Deployment-drift and render-regression both hid behind a green byte-check this session (T-177/T-178):
curl+sha256 proves the *bytes* match but not that the build *renders* or that the governance dropdowns
actually appear. This adds a committable render-check that guards the designer BUILD: serve the current
`dist/` artifact via a local static server (no backend — mirrors the AEF-served static condition), load it
headless with python-playwright (chromium already cached), and assert render + feature-marker + clean
console. Origin: T-178; learning P-029 (deployment verification needs a browser render-check of the served
artifact, not just a byte-check). Complements `tests/test_editor_bridge_meta_parity.py` (static parity) —
this is the dynamic render half. Python-native (matches 832's shell+python stack); no node toolchain.

## Acceptance Criteria

### Agent
- [x] `tests/test_designer_render.py` exists and is runnable standalone (`python3 tests/test_designer_render.py`); it resolves the current build from `VERSION` → `dist/aef-workflow-designer-<version>.html`, serves `dist/` on an ephemeral localhost port via a stdlib static server, and drives it headless via python-playwright/chromium.
- [x] **Render assertion:** the page loads with no uncaught JS exception; palette task items (Service Task, User Task, Script Task, Sub-process) and the canvas are present in the DOM; page `<title>` contains "Workflow Designer".
- [x] **Feature-marker assertion (stale-build guard):** in-page `FIELD_META.horizon` is truthy AND `AEF_FIELDS.serviceTask` contains `horizon`, `workflowType`, and `owner` — this assertion FAILS on any pre-T-177 build (proven: pointed at 0.1.0 sha `d0e0177c…` → `FIELD_META.horizon: False`, `serviceTask=['tier','agentType','endpoint','contextReads','artifactsWrites']`, guard fires on all three missing).
- [x] **Rendered-DOM assertion:** placing a task node and selecting it renders the three governance `<select>` controls (Horizon / Workflow type / Owner) in the inspector's EXTENSIONS block, each with the expected option sets.
- [x] **Console assertion:** no console errors EXCEPT whitelisted `/api/health` and `/favicon.ico` 404s (documented backend-absent probes; the test whitelists them by URL and comments why — src is NOT modified to suppress them).
- [x] Test passes against the current `0.2.0` build (exit 0); one-time dev setup (`pip install playwright && playwright install chromium`) is documented in the test's module docstring.
- [x] `## Verification` runs the test so P-011 gates future builds on it.

## Verification

# Dynamic render-check of the current dist/ build (serves it headless, asserts
# render + T-177 markers + inspector dropdowns + clean console). Exit 0 = pass.
python3 tests/test_designer_render.py
# Static parity guard (unchanged) — editor metaKeys ⊆ bridge META_KEYS.
python3 tests/test_editor_bridge_meta_parity.py

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

### 2026-07-10 — tooling assumption was already satisfied
- **What changed:** The task filing assumed "needs new node/playwright dev tooling (832 is shell+python only)". In fact python-playwright is already installed (`/usr/local/lib/python3.12/dist-packages/playwright`) and chromium is cached (`~/.cache/ms-playwright/`). Zero install needed; the test is python-native (matches the existing `tests/*.py` stack), no node toolchain added.
- **Plan impact:** Dropped the "add node/playwright tooling + get operator go" step. Portability preserved (Directive 4) — no new language toolchain.
- **Triggered:** Nothing new. Test serves `dist/` via stdlib `http.server` (mirrors the backend-absent `:3001` static condition), so `/api/health` + `/favicon.ico` 404s reproduce locally and are whitelisted — same signature as the live deployment.

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

### 2026-07-10T21:17:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-179-playwright-render-check-guarding-test-fo.md
- **Context:** Initial task creation

### 2026-07-10T21:37:53Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-10T21:45:05Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
