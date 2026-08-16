---
id: T-144
name: "In-editor Open-from-project modal (uses /api/list, opens latest version in-place)"
description: >
  T-142 GO build task 2 of 2. Add an 'Open…' toolbar button (gated by detectSaveApi
  like Save/Versions) that opens a modal listing maps from /api/list (T-143) — thumbnail
  + title + source badge + latest-version label + client-side filter. Clicking a map
  opens it IN-PLACE (no reload) via adoptImportedXml with replace semantics, defaulting
  to openTarget (latest saved version, else rendered baseline). Validated in T-142
  Spike 2. Mirror invariant + T-138 untouched (read path).

status: work-completed
workflow_type: build
owner: human
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-08T12:19:53Z
last_update: '2026-08-16T14:33:16Z'
date_finished: 2026-07-09T06:43:32Z
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
  - ts: '2026-08-16T12:33:39Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:16Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=2 (body:lightly-promoted); 
      F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:17Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:build/gallery/designer.html,docs/reports/T-142-in-editor-open-from-project-browser.md,src/aef-workflow-designer.html,tools/_gallery-save-allowlist-verify.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-144: In-editor Open-from-project modal (uses /api/list, opens latest version in-place)

## Context

Build task 2 of the T-142 GO — the visible payoff. Adds an "Open project…" toolbar button +
modal that lists maps from `/api/list` (T-143) and opens one in-place at its latest saved
version. Reuses the `openVersionsModal` UI pattern and the `adoptImportedXml` open path
(both proven in T-142 Spike 2). See `docs/reports/T-142-in-editor-open-from-project-browser.md`.

> **WIP CHECKPOINT (2026-07-08, session hit budget gate at ~95%).** Code is COMPLETE and
> mirror-synced; static checks passed (`grep` for btn/function/open-opts + `diff -q` mirror).
> **NOT yet verified — do this next session before completing:**
> 1. Restart gallery (`tools/serve-gallery.sh 8834`) so :8834 serves the new editor.
> 2. Headless proof (Playwright): `btn-open-project` visible; click → modal lists 24 maps;
>    click arc-lifecycle → opens in-place (URL unchanged, `state.workflowMeta.id`=='arc-lifecycle').
> 3. Re-run `python3 tools/_gallery-save-allowlist-verify.py` (expect 6/6 — server unchanged).
> 4. Element screenshot of the modal, Read it back (Visual Verification AC).
> 5. Then check the agent ACs, fill `## Recommendation`, `fw task update T-144 --status work-completed`.
> Code locations: button `src:~955`; `detectSaveApi` reveal `src:~6760`; `openProjectModal`/
> `openProjectMap`/`closeProjectModal` inserted just before `adoptImportedXml`; onclick wired
> next to `btn-versions`. Nothing verified via browser yet — the gate blocked it.

## Acceptance Criteria

### Agent
- [x] New `📂 Open project…` toolbar button (`btn-open-project`), shipped `display:none` and
      revealed only by `detectSaveApi()` alongside Save/Versions (hidden on static gallery)
- [x] Clicking it opens a modal built on the `openVersionsModal` pattern: fetches `/api/list`,
      renders one card per map with title, source badge (rendered/saved), latest-version label
      (thumbnail via `/api/thumb` when a saved version exists), and a client-side filter box
- [x] Clicking a map opens it IN-PLACE (no page reload) via `adoptImportedXml(text,
      {replace:true, userImport:true})`, resolving `openTarget`: latest saved version
      (`/api/version?id=&v=`) when present, else the rendered baseline (`rendered/<id>.bpmn`)
- [x] Modal closes on Escape / backdrop click; no leaked keydown listener (mirrors
      `closeVersionsModal`/`_versionsEsc`)
- [x] Read-only: no writes; the T-138 save-gate verifier still passes 6/6; no change to
      `/api/save`
- [x] Editor JS synced byte-identical to `build/gallery/designer.html` (mirror invariant)
- [x] Headless proof: with the gallery running, `btn-open-project` is visible; clicking it
      lists 24 maps; clicking a saved map (e.g. arc-lifecycle) opens it in-place with URL
      unchanged and `state.workflowMeta.id` == the chosen map

### Human
- [x] [REVIEW] The Open-project browser feels right
  **Steps:**
  1. Reuse the running gallery on :8834 (or `tools/serve-gallery.sh 8834`)
  2. Open the editor; click "📂 Open project…"
  3. Type in the filter box; pick a map that shows a version label (e.g. arc-lifecycle)
  **Expected:** The list is readable (thumbnails/titles/badges), filter narrows it, and the
  chosen map opens in-place at its latest saved version without a full page reload
  **If not:** Note which map, what you expected, and what you saw (screenshot helps)

## Visual Verification

<!-- Element screenshots of the modal (light + dark if the change affects both). -->
- [x] Modal screenshotted (element-level) and read back — cards render with title/badge/label

**Evidence (2026-07-09, live :8834, dark theme):**
- `.playwright-mcp/t144-open-project-modal.png` — first pass; **caught a regression:** rendered-only maps
  (no saved thumb) rendered a browser broken-image icon + spilled alt text ("<id> preview").
  Root cause: an `<img>` was created for every card but `src` was only set when `saved`;
  an img with no `src` never fires `onerror`, so the `visibility:hidden` fallback never ran.
- **Fix:** only build an `<img>` when a saved-version thumb exists; rendered-only cards (and
  saved thumbs that 404) get a neutral `▦` placeholder of the same height. Verified via
  network trace: only the 11 saved maps fire `/api/thumb` (200); the 13 rendered-only maps
  fire none.
- `.playwright-mcp/t144-open-project-modal-fixed.png` — re-shot and read back: 11 real thumbnails + 13 clean
  `▦` placeholders, no broken icons, badges/titles/version labels correct.

**Functional headless proof (live :8834):** button visible (detectSaveApi); modal lists 24
maps; filter `arc` → 1 card, cleared → 24; clicking arc-lifecycle opens in-place — window
sentinel survives (no reload), URL unchanged, modal auto-closes, canvas header +
workflow-picker both read `arc-lifecycle`, and the open fetched
`/api/version?id=arc-lifecycle&v=4` (latest saved version, IW-5). Escape closes; a second
Escape is a no-op (listener removed). Console: 0 errors.

> Minor, out of scope (pre-existing): the browser tab `document.title` stays `investigate.bpmn`
> after an in-place open — `adoptImportedXml` doesn't update it (same for the existing Load…
> path). On-canvas identity updates correctly. Not introduced by T-144; not fixed here.

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
grep -q "id=\"btn-open-project\"" src/aef-workflow-designer.html
grep -q "function openProjectModal" src/aef-workflow-designer.html
grep -q "replace: true, userImport: true" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
python3 tools/_gallery-save-allowlist-verify.py

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

### 2026-07-09 — Thumbnail placeholder for maps without a saved-version PNG
- **Chose:** Build an `<img>` only when a saved-version thumb exists; rendered-only cards
  (and saved thumbs that 404) get a neutral `▦` placeholder `<div>` of the same height.
- **Why:** Visual verification caught that an img with no `src` never fires `onerror`, so the
  `visibility:hidden` fallback never ran → the browser painted a broken-image icon and spilled
  the alt text across ~half the cards.
- **Rejected:** (a) leaving the `visibility:hidden` onerror only — doesn't fire without a src,
  so it never triggers; (b) pointing all cards at `/api/thumb` regardless — 13 needless 404s
  and still a fallback problem.

## Recommendation

**Recommendation:** GO — accept the Open-project modal; sign off the one Human [REVIEW] AC.

**Rationale:** All 7 Agent ACs are verified live on :8834, not just statically. The feature is
gated exactly like Save/Versions (`detectSaveApi`), opens maps in-place at their latest saved
version (the IW-5 requirement), and is read-only (no `/api/save` change, save-allowlist still
6/6). The only reason this isn't fully auto-completing is the deliberate `### Human` [REVIEW]
AC on subjective "feels right" quality, which only the human may check.

**Evidence:**
- Button gated by `detectSaveApi` — visible on :8834 (API present), ships `display:none`.
- Modal lists 24 maps; filter `arc` → 1 card, cleared → 24 (headless).
- arc-lifecycle opens in-place: no reload (window sentinel survives), URL unchanged, canvas
  header + workflow-picker both read `arc-lifecycle`; fetch was
  `/api/version?id=arc-lifecycle&v=4` (latest saved, not rendered baseline).
- Escape closes the modal; a second Escape is a no-op (listener removed, no leak).
- Read-only: `python3 tools/_gallery-save-allowlist-verify.py` → 6/6; no `/api/save` change.
- Mirror byte-identical: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`.
- Visual Verification caught + fixed a broken-thumb regression; re-shot clean
  (`.playwright-mcp/t144-open-project-modal-fixed.png`). 0 console errors.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-08T12:19:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-144-in-editor-open-from-project-modal-uses-a.md
- **Context:** Initial task creation

### 2026-07-09T06:43:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fba61ac1
- **Timestamp:** 2026-07-29T13:13:39Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
