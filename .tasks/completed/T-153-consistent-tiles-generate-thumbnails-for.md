---
id: T-153
name: "Consistent tiles: generate thumbnails for rendered-corpus maps (Open-project)"
description: >
  Open-project modal shows the ▦ placeholder for all rendered-only corpus maps (no saved PNG). Corpus BPMNs carry no DI coords, so tiles need a headless-render thumbnail pipeline: render each corpus map in the designer, capture a PNG, cache it server-side, and have /api/thumb serve it for rendered maps (▦ fallback). Flagship of the F-series browsing polish.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T15:01:58Z
last_update: 2026-07-09T15:52:35Z
date_finished: 2026-07-09T15:52:35Z
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

# T-153: Consistent tiles: generate thumbnails for rendered-corpus maps (Open-project)

## Context

Open-project modal shows the ▦ placeholder for all rendered-only corpus maps (no saved
PNG). Corpus BPMNs carry no DI coords, so tiles need a headless-render thumbnail pipeline.

**Operator decision (2026-07-09): GO — build the full pipeline** (preferred over the
lazy cache-on-open alternative). Approach: render each corpus map in the designer
headlessly (Playwright), capture a PNG via `captureThumbnail()`, cache it server-side
(e.g. `build/gallery/thumbs/<id>.png` or a `.editor-versions/_rendered/<id>.png` cache),
and extend `gallery-serve.py` `/api/thumb` to serve the cached rendered thumb (▦ fallback).
Then `openProjectModal` uses a real `<img>` for rendered cards too. Highest-impact of the
remaining browsing-polish items; makes T-156 hover-zoom useful everywhere.
This is the suggested first task for the next session.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/gen-rendered-thumbs.mjs` exists — a headless CDP batch generator (same harness family as `tools/_*-verify-cdp.mjs`) that loads each rendered-corpus map, calls `captureThumbnail()`, and writes `.editor-versions/_rendered/<id>.png`. Exits 0 and reports 24/24 generated. **Verified:** ran clean, `24/24 thumbnails generated`, each with real bbox + node count.
- [x] After running the generator, `.editor-versions/_rendered/` contains one non-empty PNG per corpus map (24 files), and the cache dir is skipped by the map scanner (starts with `_`, fails `ID_RE`) so it never appears as a fake map in `/api/list`. **Verified:** 24 PNGs on disk; `/api/list` returns 25 real maps, `_rendered` absent, no underscore-leading ids.
- [x] `gallery-serve.py` `/api/thumb?id=<id>` (no `v`) serves the cached rendered PNG (`image/png`, 200) when it exists, and returns 404 JSON when it does not. The existing saved-version path (`&v=<n>`) is unchanged. **Verified:** `audit-process` no-v → 200 image/png 14821B; `arc-lifecycle&v=1` → 200 (unchanged); `nonexistent` → 404.
- [x] `openProjectModal` renders a real `<img src="/api/thumb?id=<id>">` for rendered-only cards (▦ `makeThumbPlaceholder` fallback on `onerror`), and sets `card._previewSrc` so T-156 hover-zoom shows the tile for rendered maps too. **Verified:** 25/25 tiles loaded, 0 broken, 0 ▦ placeholders; hover-zoom on rendered `cross-host-dispatch` loads 320×141, no overlap.
- [x] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`. **Verified:** MIRROR-OK.
- [x] Playwright visual verification: Open-project modal shows real tiles (not ▦) for rendered maps; 0 console errors; element screenshot READ. **Verified:** see `## Visual Verification` — every card shows a genuine diagram; console errors = 0.

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

test -f tools/gen-rendered-thumbs.mjs
test "$(ls .editor-versions/_rendered/*.png 2>/dev/null | wc -l)" -eq 24
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "_rendered" tools/gallery-serve.py
grep -q "api/thumb?id=" src/aef-workflow-designer.html

## Visual Verification

Viewport 1440×900, Open-project modal, gallery on :8834 (restarted to pick up the
`/api/thumb` change):

- `.playwright-mcp/t153-tiles-modal.png` — the full modal: all 25 cards show a real
  rendered diagram tile (nodes, gateways, edges, lanes). Zero ▦ placeholders. READ and
  confirmed — this is the "consistent tiles" the operator asked for.
- `.playwright-mcp/t153-hover-rendered.png` — hover-zoom preview of the rendered-only map
  `cross-host-dispatch`: enlarged legible diagram, caption "cross-host-dispatch · rendered",
  no overlap with the modal. Confirms T-156 hover-zoom now works for rendered maps too.

Console errors during modal open + hover: **0**.

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
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-153-consistent-tiles-generate-thumbnails-for.md
- **Context:** Initial task creation

### 2026-07-09T15:45:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-09T15:52:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
