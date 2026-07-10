---
id: T-166
name: "Delete a workflow from the project (archive-based, Open-project browser)"
description: >
  Delete a workflow from the project (archive-based, Open-project browser)

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
created: 2026-07-09T23:11:35Z
last_update: 2026-07-09T23:29:59Z
date_finished: 2026-07-09T23:28:46Z
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

# T-166: Delete a workflow from the project (archive-based, Open-project browser)

## Context

Operator: "we also need a means to delete workflows" → full removal, archive-based (decision
2026-07-10). A workflow exists as 3 git-tracked things: `.editor-versions/<id>/` (saved
version history), `examples/aef-processes/rendered/<id>.bpmn` (committed corpus baseline),
`.editor-versions/_rendered/<id>.png` (browser thumbnail). Delete = **archive all of them**
to `.editor-versions/_trash/<id>-<ts>/` (recoverable) + drop the gitignored served copy.
Touches only the working tree — git stays a recovery net.

**Surface:** a 🗑 button on each Open-project card → themed confirm dialog → `POST /api/delete`.
This task also builds the two shared pieces reused by T-167 (version-level delete): the
server archive helper and the themed `confirmDialog()`. Corpus caveat: deleting a corpus map
drops the shipped set 24→23 (operator's deliberate choice; archived + git-recoverable).

Guards (PL-020): the endpoint validates id format AND confirms each source path resolves
inside REPO before moving (no traversal). `_trash` starts with `_` so `build_map_list`/ID_RE
never re-enumerate archived maps.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `POST /api/delete {id, scope:'workflow'}` archives `.editor-versions/<id>/`, the corpus baseline `examples/aef-processes/rendered/<id>.bpmn`, and the thumbnail `.editor-versions/_rendered/<id>.png` into `.editor-versions/_trash/<id>-<ts>/`, drops the served copy, and returns `{ok:true, archived:[...], trash:...}`. After it, `/api/list` no longer lists the id and `/api/versions?id=` is empty. *(verified via curl: save test-del-tmp → {archived:['.editor-versions/test-del-tmp'], trash:...}; list=False, versions=0, files under _trash/…/versions/)*
- [x] The endpoint rejects an invalid id (400) and returns 404 when there is nothing to delete; every source path is containment-checked against REPO before moving (no path traversal). *(verified: id `../../etc`→400, `no-such-map-xyz`→404, bad scope→400; `_within_repo` realpath guard in archive_move)*
- [x] Open-project cards show a 🗑 delete button (default mode only, not pick mode); clicking it opens a themed `confirmDialog()` (no native confirm), and only on confirm does it call `/api/delete` and refresh the browser list. *(verified: 27 cards→27 🗑 in default mode; 0 🗑 in pick mode; click → themed dialog; confirm → gone)*
- [x] `confirmDialog()` is a reusable themed promise-returning dialog (Cancel/confirm, Esc=cancel via capture so it does not also close the underlying modal, danger styling), sitting above the project modal (z-index > 10001). *(z-index 10002, capture-phase Esc with stopImmediatePropagation, red Delete button — see screenshot)*
- [x] src↔build mirror invariant holds (`diff -q src build/gallery/designer.html`) and `python3 -c "import ast,sys; ast.parse(open('tools/gallery-serve.py').read())"` parses. *(MIRROR-OK; PARSE-OK)*
- [x] Playwright (against a throwaway temp store so no real map is harmed): save a scratch map → it appears in the browser → 🗑 → confirm → it disappears from the list and its files are archived under `_trash`; 0 console errors; element screenshot READ. *(ui-del-scratch: saved→visible→confirm→gone from modal+/api/list, versions=0; .playwright-mcp/t166-delete-confirm.png read. Only console msg is a benign 404 for the scratch fixture's absent thumbnail — real editor-saved maps carry a PNG; not from the delete path)*

### Human
- [ ] [REVIEW] Deleting a workflow feels safe and clear
  **Steps:**
  1. Open `http://localhost:8834/designer.html`, click **📂 Open project…**.
  2. Click 🗑 on a workflow you don't mind archiving (it's recoverable from `.editor-versions/_trash/`).
  3. Confirm in the dialog.
  **Expected:** A clear confirm dialog naming the workflow; after confirming, it disappears from the browser and its files are under `.editor-versions/_trash/<id>-<ts>/`.
  **If not:** Note whether the dialog was unclear, the map lingered, or files weren't archived.

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html
python3 -c "import ast; ast.parse(open('tools/gallery-serve.py').read())"

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

## Recommendation

**Recommendation:** GO
**Rationale:** Whole-workflow delete works end-to-end and is archive-based (recoverable). Server
lifecycle, guards (invalid/404/traversal/bad-scope), and the UI flow (🗑 → themed confirm →
removal) all verified live. Built the two shared pieces T-167 will reuse: `archive_move`/`trash_dir`
on the server and `confirmDialog()` on the client. Remaining Human AC is a taste-check that
deletion feels safe.
**Evidence:**
- `.playwright-mcp/t166-delete-confirm.png` (read): 🗑 on every card + themed confirm w/ red Delete.
- curl lifecycle: save→list=True→delete→{archived,trash}→list=False, versions=0, files under `_trash/…/versions/`.
- Guards: `../../etc`→400, `no-such-map-xyz`→404, bad scope→400.
- UI: ui-del-scratch saved→visible (27 cards, 27 🗑)→confirm→gone; pick mode shows 0 🗑.
- Gates: `diff -q src build` PASS; `ast.parse(gallery-serve.py)` PASS.

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

### 2026-07-09T23:11:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-166-delete-a-workflow-from-the-project-archi.md
- **Context:** Initial task creation

### 2026-07-09T23:28:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
