---
id: T-223
name: "Editor entry-point shadowing: B1 autosave-restore hides server-latest map,
  no 'open latest saved' action (AEF UX-defect input, operator recurrence)"
description: >
  Editor entry-point shadowing: B1 autosave-restore hides server-latest map, no 'open
  latest saved' action (AEF UX-defect input, operator recurrence)

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
created: 2026-07-21T12:49:17Z
last_update: '2026-08-16T14:33:21Z'
date_finished: 2026-07-21T18:29:32Z
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
  - ts: '2026-08-16T12:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:21Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 3
      F2: 0
      F4: 1
      F3: 1
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=1 (prose:AEF seam-incidental); 
      F1=2 (prose:process-editor-capability)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:src/aef-workflow-designer.html); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-223: Editor entry-point shadowing: B1 autosave-restore hides server-latest map, no 'open latest saved' action (AEF UX-defect input, operator recurrence)

## Context

AEF UX-defect input (rail offset 115, thread T-2586): the operator's recurring "off-page connectors
not working" report is NOT a seam/connector defect (AEF live-verified the 0.3.0 seam works) — it's
**entry-point shadowing** in the editor. B1 autosave-restore silently replaces the seed with the
operator's last localStorage draft on every `/designer` open (winning over a same-map `?load`
deep-link); an operator who opened a corpus map before new content shipped sees their STALE draft
(same title, no handoff nodes) and concludes "still broken." The "Restored your unsaved work" toast
is easy to miss and its only action is "Start fresh" (blank) — there is **no "open latest saved"**
path. Fix addresses the operator's ACTUAL complaint. Separate from the gated T-218 seam build.
See `[[aef-integration-rail]]`.

## WIP state (2026-07-21, hit 300K budget ceiling mid-fix)

**Done + committed (src/aef-workflow-designer.html):**
- `showToast` extended to support `opts.actions:[{label,onAction}]` (back-compat with legacy `actionLabel`/`onAction`) — for multi-button toasts.
- `showRestoredToast` rewritten: base toast (unchanged "Start fresh") + async `/api/list` check → when the same map id has a saved `latest.{v,ts}`, upgrade toast to offer **"Open latest saved (vN)"** + "Keep draft" + "Start fresh", flagging when server copy is NEWER (via `_tsToMs` normalize). `openProjectMap(m)` loads it. Helpers `_tsToMs`, `_startFresh` added.
- **Verified in Playwright:** page loads clean (only benign favicon 404); confirmed `/api/list` exposes `latest.{v,ts}` (15/25 corpus maps have saved versions); planted an arc-lifecycle draft with older ts.

**DONE (2026-07-21, fresh window):**
- **Ordering bug FIXED:** dropped `!_apiAvailable` from the guard at line 8787 → `if (!s || !s.id) return;` (with an explanatory comment: the `fetch('/api/list')` in the async IIFE IS the availability probe — rejects on `file://` → caught → base toast stays; returns non-ok when no write-capable server). `autoLoadStored()` (8827) runs before `detectSaveApi()` (8828), which is why the old guard bailed.
- **Verified via Playwright** (:8834, build refreshed from src via `cp`): (1) NEWER variant fires — "↩ Restored your unsaved draft — but the project has a NEWER saved version (v4)." + 3 buttons; (2) non-newer variant — "A saved version (v4) is in the project." + 3 buttons; (3) **no regression** — id with no server version keeps the original base toast ("Restored your unsaved work" + single "Start fresh"). Screenshots read back (see `## Visual Verification`).

## Acceptance Criteria

### Agent
- [x] Verified the current B1 autosave-restore behavior in `src/aef-workflow-designer.html` (autoLoadStored + restore toast) against AEF's diagnosis, with file:line evidence — `autoLoadStored()` (8716) adopts the localStorage draft silently; `showRestoredToast` (8783) is the surface. Root ordering bug: `autoLoadStored()` (8827) runs BEFORE `detectSaveApi()` (8828), so `_apiAvailable` was false at restore time.
- [x] On restore, when a write-capable server is present, the map's server latest version is checked and — if newer than / different from the restored draft — the operator is told a newer saved version exists — `showRestoredToast` async-fetches `/api/list`, compares `_tsToMs(latest.ts)` vs draft ts, shows "NEWER saved version (vN)" when server is newer (Playwright-verified both branches).
- [x] The restore toast offers an "Open latest saved" action alongside "Start fresh" (not just discard-to-blank) — 3-button enriched toast: "Open latest saved (vN)" → `openProjectMap(m)`, "Keep draft", "Start fresh".
- [x] `?load=<id>` / same-map deep-link is honored rather than silently shadowed by a stale autosave draft of a different map (or the shadowing is made visible + reversible) — deep-link precedence preserved unchanged (8720: explicit `?load` to another map wins); the shadowing is now made **visible + reversible** via the "Open latest saved" action.
- [x] Visual-verified with element-level Playwright screenshots of the restore toast (both actions visible); screenshots read back — `.playwright-mcp/t223-toast-dark.png` (NEWER variant, 3 buttons) + `.playwright-mcp/t223-toast-nonewer.png` (non-newer variant, 3 buttons). Editor is dark-theme only (no light/`data-theme`/`prefers-color-scheme`) → dark is the sole mode; the second screenshot covers the other message branch instead. See `## Visual Verification`.

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

# The _apiAvailable ordering-bug guard is gone (the fix); the availability-probe comment is present.
grep -q 'do NOT gate on _apiAvailable' src/aef-workflow-designer.html
# The enriched restore path (server-latest check + Open latest saved) is wired into the restore toast.
grep -q 'Open latest saved' src/aef-workflow-designer.html
# Editor still parses as a single well-formed HTML document (no truncation from the edit).
python3 -c "import html.parser,sys; p=html.parser.HTMLParser(); p.feed(open('src/aef-workflow-designer.html').read()); print('html-parse-ok')"

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

## Visual Verification

Editor is **dark-theme only** (fixed `:root` dark vars; no `data-theme` / `prefers-color-scheme` / theme toggle) → dark is the sole rendering mode. Screenshots cover both message branches of the enriched restore toast instead of nonexistent light/dark modes. Captured on :8834 (build refreshed from src), element-visible, read back with the Read tool.

- `.playwright-mcp/t223-toast-dark.png` — **NEWER** variant: "↩ Restored your unsaved draft — but the project has a NEWER saved version (v4)." with 3 buttons (Open latest saved (v4) / Keep draft / Start fresh). Message wraps to 3 lines, buttons legible, no layout breakage.
- `.playwright-mcp/t223-toast-nonewer.png` — **non-newer** variant: "↩ Restored your unsaved draft. A saved version (v4) is in the project." with the same 3 buttons. Clean render.
- No-regression path (base toast, id absent from store → single "Start fresh") verified programmatically via Playwright evaluate (not screenshotted — identical to pre-T-223 rendering).

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

### 2026-07-21T12:49:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-223-editor-entry-point-shadowing-b1-autosave.md
- **Context:** Initial task creation

### 2026-07-21T18:29:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
