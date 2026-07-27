---
id: T-176
name: "Offline-harden the designer: inline or self-host fonts (remove Google Fonts CDN dependency)"
description: >
  Surfaced by T-174: the designer links Google Fonts (fonts.googleapis.com/gstatic). Authoring functions offline (system-font fallback) but is not zero-network, which matters for air-gapped AEF deployments vendoring the released artifact. Inline the woff2 fonts as base64 (or self-host) so the single file is truly self-contained. Visual change to src/ — needs visual verification across modes.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: ["arc:designer-authoring-surface"]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-10T10:57:14Z
last_update: 2026-07-18T07:55:42Z
date_finished: 2026-07-18T07:55:04Z
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

# T-176: Offline-harden the designer: inline or self-host fonts (remove Google Fonts CDN dependency)

## Context

The designer links Google Fonts (`fonts.googleapis.com` preconnect ×2 +
a css2 stylesheet for JetBrains Mono 400/500/600 and Outfit 400/500/600/700).
The "single-file self-contained" artifact AEF vendors therefore makes a live
network call at load — it degrades to system fonts offline, but is not
zero-network, which breaks fidelity in air-gapped AEF deployments (Directive 4,
Portability). Fix: embed the woff2 faces as base64 `@font-face` inside the file
so it is truly self-contained, keeping `--mono`/`--sans` stacks (embedded family
first, system fallback retained) unchanged.

## Acceptance Criteria

### Agent
- [x] All three Google Fonts `<link>` tags (2× preconnect + css2 stylesheet) removed from `src/aef-workflow-designer.html`; no `fonts.googleapis.com` / `fonts.gstatic.com` / external font URL remains (grep-clean).
- [x] JetBrains Mono (400/500/600) + Outfit (400/500/600/700) embedded as base64 woff2 `@font-face` rules in one inline `<style>` block; `--mono`/`--sans` variables unchanged (embedded family first, system fallback retained).
- [x] Generator `scripts/embed-fonts.py` committed — reproducibly re-fetches + re-embeds (documents source URL, families, weights, subsets) so a future weight change is one command, not hand-edited base64.
- [x] Rendered with the network blocked, the real JetBrains Mono + Outfit faces render (not system fallback) — proven by screenshot read with the Read tool.
- [x] No console/render regression: `python3 tests/test_designer_owner_derived.py` + the 5 JS↔Py seam guards still exit 0 (src unaffected structurally).

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
- [ ] [REVIEW] Embedded fonts render identically to the CDN version, no visible regression
  **Steps:**
  1. Serve the source: `cd /opt/832-Workflow-designer && python3 -m http.server 8199 --directory src`
  2. Open `http://127.0.0.1:8199/aef-workflow-designer.html` (optionally with the network throttled to offline in devtools)
  3. Compare the canvas node labels, IDs, headings, and property-panel text against `docs/screenshots/t176-fonts-*.png`
  **Expected:** JetBrains Mono (mono labels/IDs/badges) and Outfit (headings/node names) render exactly as before; no fallback-font flash, no metric shift, no console font error.
  **If not:** Screenshot the affected element and note whether it fell back to a system font.

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
# no external font references remain
! grep -Eq "fonts\.(googleapis|gstatic)\.com" src/aef-workflow-designer.html
# fonts embedded as base64 woff2 @font-face
grep -q "@font-face" src/aef-workflow-designer.html
grep -q "data:font/woff2;base64," src/aef-workflow-designer.html
# both families still wired into the CSS variables
grep -q "JetBrains Mono" src/aef-workflow-designer.html
grep -q "Outfit" src/aef-workflow-designer.html
# generator is committed and runnable
test -f scripts/embed-fonts.py
# structural guards unaffected by the font embed
out=$(python3 tests/test_designer_owner_derived.py 2>&1); echo "$out" | grep -q "PASS"
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_namespace_consistency.py

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

### 2026-07-18 — subset scope decided at build time
- **What changed:** css2 returns 26 unicode-range faces (latin, latin-ext, cyrillic, greek, vietnamese). Full embed = +525 KB; latin+latin-ext = +429 KB (14 faces). The designer UI + realistic AEF process content is latin/latin-ext; exotic scripts were never part of the design and fall back to system fonts exactly as they do today.
- **Plan impact:** Chose latin-only embed (the generator keeps `--latin-only` as the used mode and full as the fallback default) — ~100 KB smaller on every vendored copy with no fidelity loss for the actual content.
- **Triggered:** none — bounded within the task.

## Visual Verification

`docs/screenshots/t176-fonts-baseline-cdn.png` (CDN fonts, online) and
`docs/screenshots/t176-fonts-embedded.png` (embedded data-URI fonts, no font
network) are **byte-identical (70588 B each)** — pixel-identical rendering.
Headings render in Outfit, mono labels/IDs/paths in JetBrains Mono; no
system-font fallback, no metric shift. `document.fonts` shows all 7 weights
`loaded` from the inline faces, and the network trace shows **zero** requests to
any font host (only the HTML + the whitelisted `/api/health` probe) — proving
the artifact is zero-network for fonts.

## Recommendation

**Recommendation:** GO

**Rationale:** The single-file artifact is now truly self-contained — the live
Google Fonts dependency is gone, closing the Directive-4 (Portability) gap for
air-gapped AEF deployments that vendor the released build. Rendering is proven
pixel-identical (byte-identical screenshots), so there is no design regression;
the one Human AC is a fidelity confirmation.

**Evidence:**
- 0 external font hosts in src; 14 base64 woff2 `@font-face` embedded; families still wired to `--mono`/`--sans`.
- Byte-identical before/after screenshots; zero font network requests.
- All 6 JS↔Py seam/render structural guards still exit 0 (embed is presentational only).
- Reproducible via `scripts/embed-fonts.py --latin-only`.

**To finalize:** review `docs/screenshots/t176-fonts-embedded.png` (or run the
Human AC steps), check the `[REVIEW]` box, then
`cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-176 --status work-completed`.

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

### 2026-07-10T10:57:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-176-offline-harden-the-designer-inline-or-se.md
- **Context:** Initial task creation

### 2026-07-18T07:50:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-18T07:55:04Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2e406094
- **Timestamp:** 2026-07-27T21:20:19Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
