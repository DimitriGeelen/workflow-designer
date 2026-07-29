---
id: T-167
name: "Version-level delete and keep-only-latest in the Versions modal"
description: >
  Version-level delete and keep-only-latest in the Versions modal

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
created: 2026-07-09T23:29:05Z
last_update: 2026-07-09T23:37:04Z
date_finished: 2026-07-09T23:36:45Z
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

# T-167: Version-level delete and keep-only-latest in the Versions modal

## Context

Second half of the operator's delete ask (2026-07-10): "the option to remove individual saved
version or to only keep the last saved version." Adds two version-level operations to the
Versions modal, reusing the T-166 archive infra (`archive_move`/`trash_dir`) and `confirmDialog()`:

1. **Delete one version** — 🗑 on each version row → archive that snapshot's `vN.bpmn`/`vN.png`
   to `.editor-versions/_trash/<id>-<ts>/vN.*` and drop its entry from `index.json`.
2. **Keep only latest** — a header action → archive every snapshot except the newest, prune
   `index.json` to just the latest entry.

Server: extend `POST /api/delete` with `scope:'version'` (needs `v`) and `scope:'prune-old'`.
Both are archive-based/recoverable and touch only the working tree. Guarded by id validation +
REPO containment (PL-020). Note: deleting the *only/last* saved version is equivalent to removing
the saved history — allowed; the map falls back to its rendered baseline (if any) in `/api/list`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `POST /api/delete {id, scope:'version', v}` archives that version's `vN.bpmn`/`vN.png` to `_trash/<id>-<ts>/` and removes its `index.json` entry, leaving other versions intact; returns `{ok:true, archived:[...]}`. Rejects a missing/invalid v (400) and a non-existent v (404). *(curl: [1,2,3]→delete v2→[1,3], archived v2.bpmn; v9→404; missing v→400)*
- [x] `POST /api/delete {id, scope:'prune-old'}` archives all snapshots except the highest `v` and rewrites `index.json` to just that latest entry; returns `{ok:true, kept:<v>, archived:[...]}`. A single-version map is a no-op success (nothing archived, `kept` = that v). *(curl: [1,3]→prune→kept:3,[3]; prune again→kept:3,archived:[])*
- [x] Each Versions-modal row has a 🗑 delete button (themed `confirmDialog` first) that removes just that version; after it the modal refreshes and the row is gone. *(UI: 3 rows→3 🗑; click v2 🗑→themed confirm→Delete→versions [1,3])*
- [x] The Versions modal header has a "Keep only latest" action (shown only when ≥2 versions), confirmed via `confirmDialog`; after it only the latest version remains. *(UI: header "Keep only latest" present with ≥2 versions; confirm→versions [3])*
- [x] src↔build mirror invariant holds (`diff -q src build/gallery/designer.html`) and `python3 -c "import ast; ast.parse(open('tools/gallery-serve.py').read())"` parses. *(MIRROR-OK; PARSE-OK)*
- [x] Playwright (throwaway scratch map with ≥3 versions): delete a middle version → it's gone, others remain; then Keep-only-latest → only the newest remains; files archived under `_trash`; 0 console errors (beyond benign thumbnail 404s); element screenshot READ. *(ui-v167: delete v2→[1,3]→keep-only-latest→[3]; .playwright-mcp/t167-version-actions.png read; all 11 console msgs are scratch-fixture thumbnail 404s, no code errors)*

### Human
- [ ] [REVIEW] Version-level delete + keep-only-latest read clearly
  **Steps:**
  1. Open `http://localhost:8834/designer.html`, open a map with several saved versions, click **🕘 Versions**.
  2. Try 🗑 on one version, and the **Keep only latest** header action.
  **Expected:** Each confirms first, then prunes exactly as described; remaining versions/thumbnails are correct.
  **If not:** Note which action and what was off.

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
**Rationale:** Both version-level operations work end-to-end and are archive-based (recoverable),
reusing the T-166 infra. Server scopes (version, prune-old) and their guards verified via curl;
the UI row 🗑 and header "Keep only latest" verified live. Remaining Human AC is a taste-check.
**Evidence:**
- `.playwright-mcp/t167-version-actions.png` (read): per-row ⤢/↩/🗑 + header "Keep only latest".
- curl: [1,2,3]→del v2→[1,3]; v9→404; missing v→400; prune→kept 3,[3]; prune-again→no-op.
- UI: del v2→[1,3]; keep-only-latest→[3]. All console msgs are scratch thumbnail 404s (no PNG saved).
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

### 2026-07-09T23:29:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-167-version-level-delete-and-keep-only-lates.md
- **Context:** Initial task creation

### 2026-07-09T23:36:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2bc05baf
- **Timestamp:** 2026-07-29T13:13:40Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#6 (Agent)** — Playwright (throwaway scratch map with ≥3 versions): delete a middle version → it's gone, others remain; then Keep-only-latest → only the newest remains; files archived under `_trash`; 0 console error
  - **AC-verify-mismatch** (narrow, heuristic) — `path=playwright-mcp/t167-version-actions.png in: Playwright (throwaway scratch map with ≥3 versions): delete a middle version → it's gone, others remain; then Keep-only-latest → only the newest remai`
