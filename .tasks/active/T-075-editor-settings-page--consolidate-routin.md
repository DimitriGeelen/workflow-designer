---
id: T-075
name: "Editor settings page — consolidate routing/snapping/grid preferences"
description: >
  Operator-approved: a settings surface (panel or page) consolidating editor-local prefs: attach mode (middle/spread, absorbs T-070 sidebar toggle), straightening tolerance px (T-073), snap toggles + grid size (T-074). All localStorage, never document data — bridge seam untouched.

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
created: 2026-07-04T09:44:04Z
last_update: 2026-07-04T10:19:27Z
date_finished: 2026-07-04T10:18:57Z
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

# T-075: Editor settings page — consolidate routing/snapping/grid preferences

## Context

Third piece of the operator-approved v3 scope ("maybe we should add a config page
where we can configure all these settings?"): one settings dialog consolidating
every editor-local preference — routing attach mode (absorbing the T-070 sidebar
toggle), T-073's straightening tolerance, and T-074's magnet/grid snapping. All
values stay in localStorage (aefRoutingPrefs / aefSnapPrefs, PD-017 pattern);
nothing enters the document format or the bridge seam.

## Acceptance Criteria

### Agent
- [x] ⚙ Settings button in the header opens the modal (real click → .visible confirmed); closes via Close button, Escape (verified), and backdrop click; full-viewport overlay blocks canvas interaction while open.
- [x] Dialog exposes and live-applies all prefs: attach middle/spread radios (real radio click → routingPrefs.attach='spread', persisted `{"attach":"spread","straightenTol":16}`); straightening tolerance number input (0=off) in aefRoutingPrefs, read by straightenAnchors; magnet/grid checkboxes + grid size in aefSnapPrefs.
- [x] Tolerance is live under trusted input: page.fill '0' + Tab → e_05 jogged (straight=false); page.fill '16' + Tab → e_05 straight again. Screenshot of the dialog (t075-settings-dialog.png) READ and confirmed clean.
- [x] Sidebar "Routing" palette section removed; zero remaining references to routing-middle/routing-spread in the file (grep count 0) — setRoutingAttach no longer touches DOM classes.
- [x] Reset-to-defaults (real click) restored both localStorage keys to `{"attach":"middle","straightenTol":16}` / `{"magnet":true,"grid":false,"gridSize":20}` and synced the visible controls (uiMiddle=true, uiTol=16).
- [x] Document untouched: buildBpmnXml byte-identical after the full settings exercise (open, tol 0→16, spread, reset, close) — exportIdentical=true.
- [x] Editor JS passes `node --check`; bridge suite 31 passed 0 failed; gallery copy refreshed.

### Human
- [ ] [REVIEW] Settings dialog is clear and the knobs do what they say
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/healing-loop.bpmn
  2. Click the Settings button in the header
  3. Flip attach mode to spread and back — watch the arrows fan out / converge
  4. Set straightening tolerance to 0 — near-aligned lines get their corners back; set it back to 16
  5. Toggle grid snap on, drag a node — it lands on 20px steps; toggle off
  **Expected:** Every control applies immediately (no save button needed), labels are self-explanatory, Reset restores the defaults
  **If not:** Note which control was unclear or didn't visibly apply, and report back

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

## Recommendation

**Recommendation:** GO
**Rationale:** All seven Agent ACs verified; every dialog interaction exercised with trusted input (real clicks, real typing) per PL-006, and the settings exercise was proven side-effect-free on the document (byte-identical export). This closes the operator's v3 trio: T-073 straightening, T-074 snapping, T-075 the config surface governing both. Open item: the Human [REVIEW] AC on control clarity.
**Evidence:**
- Open/close: real click → visible; Escape and backdrop close verified
- Live tolerance: fill 0 → e_05 jogs; fill 16 → straight (trusted input on the actual number field)
- Attach spread via real radio click, persisted; Reset restored both localStorage keys and the UI
- Consolidation: routing-middle/routing-spread references now 0 in the file
- Export byte-identical across the full settings exercise; bridge 31/31; node --check clean; dialog screenshot read and confirmed

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

awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t075-check.js && node --check /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t075-check.js
grep -q "btn-settings" src/aef-workflow-designer.html
grep -q "settings-modal" src/aef-workflow-designer.html
out=$(grep -c "routing-middle\|routing-spread" src/aef-workflow-designer.html || true); test "$out" -le 3
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)

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

### 2026-07-04 — Modal dialog, not a separate page or sidebar section
- **Chose:** In-editor modal overlay (settings-modal/settings-dialog) opened from a header ⚙ button; controls apply live with no save step.
- **Why:** The editor is a single-file app — a separate page would need routing/state handoff for three preference groups; live-apply lets the user see the routing/snapping effect behind the dialog immediately.
- **Rejected:** Separate settings page (overkill, breaks single-file simplicity); growing the sidebar palette (T-070's two-entry section already read as clutter — the palette is for canvas objects, not preferences).

### 2026-07-04 — Sidebar Routing section removed, not duplicated
- **Chose:** The attach toggle now lives ONLY in the settings dialog; the palette section from T-070 is deleted.
- **Why:** The operator asked for consolidation ("a config page where we can configure all these settings"); two control surfaces for one pref invite state-sync bugs.
- **Rejected:** Keeping both with syncing (more wiring for marginal quick-access value on a rarely-flipped pref).

### 2026-07-04 — straightenTol joins aefRoutingPrefs (not a third key)
- **Chose:** Tolerance persists inside the existing aefRoutingPrefs blob; STRAIGHTEN_TOL const remains as the fallback default.
- **Why:** It is a routing-render pref; one key per concern (routing vs snapping) keeps localStorage legible and the reset logic two-line.
- **Rejected:** Separate aefStraightenPrefs key (fragmentation); folding everything into one mega-pref blob (couples unrelated resets).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T09:44:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-075-editor-settings-page--consolidate-routin.md
- **Context:** Initial task creation

### 2026-07-04T10:13:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T10:18:57Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5556cc76
- **Timestamp:** 2026-07-29T13:13:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
