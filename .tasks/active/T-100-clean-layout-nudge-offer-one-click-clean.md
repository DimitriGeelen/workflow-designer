---
id: T-100
name: "Clean layout nudge: offer one-click Clean on load when a map is measurably messy"
description: >
  Operator option 3 (auto-tidy discussion): after a user import/deep-link, if clean-on-import is OFF and the map is measurably wavy/cramped, show a dismissable one-click 'This map could use Clean layout' nudge near the toolbar. Zero mutation until clicked; uses cleanLayout(); auto-hides when clean or when clean-on-import is on.

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
created: 2026-07-05T10:30:52Z
last_update: 2026-07-05T10:38:30Z
date_finished: 2026-07-05T10:37:54Z
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

# T-100: Clean layout nudge: offer one-click Clean on load when a map is measurably messy

## Context

Operator decision (2026-07-05 dialogue on auto-tidy): option 3 of three. Complements T-099: when clean-on-import is OFF and a user opens a measurably messy map, show a dismissable on-canvas nudge offering one-click Clean — zero geometry mutation until the operator clicks (PD-044). Messiness measured by a NON-mutating dry-run of the Clean passes (would-move count). Nudge auto-suppressed when clean-on-import is on (map already cleaned) or the dry-run moves nothing.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `mapMessiness()` read-only signal: counts nodes involved in a same-lane node overlap OR a wavy row (side-by-side row-mates, centres 1–14px off); no mutation, no render — `buildBpmnXml` byte-identical before/after the probe (messiness_netzero: true). NOTE: pivoted from the filed "cleanWouldMove dry-run" — see Evolution
- [x] On a user import (`opts.userImport`) with clean-on-import OFF, `mapMessiness() >= 3` shows the canvas nudge ("✨ This map could use Clean layout" + Clean button + dismiss ✕); clicking Clean runs `cleanLayout()` (feedback "Cleaned 15 nodes — Ctrl+Z reverts") and hides the nudge; ✕ hides without mutating. Verified live (messy_userimport_prefoff: true; clean click → nudgeVisible false)
- [x] Nudge suppressed when clean-on-import ON (messy_prefon: false), messiness < 3 (clean_userimport: false), or load is programmatic (messy_programmatic: false); re-evaluated on each user import
- [x] Live check: `?load=rendered/task-lifecycle.bpmn` (pref off) shows the nudge (messiness 9); the 6 clean corpus maps (release-pipeline, cross-host-dispatch, fabric-blast-radius, inception-review, resume-status, review-emission) score 0 → no nudge; clicking Clean tidies and hides it
- [x] Suites pass (bridge 31/31, validator 34/34, corpus 24 clean, parity OK); gallery copy identical
- [x] Screenshots READ: nudge shown (`.playwright-mcp/t100-nudge-shown.png`), after-clean (`t100-after-clean.png` — nudge gone, map tidied)

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
- [ ] [REVIEW] Nudge is helpful, not naggy
  **Steps:**
  1. Ensure Settings → View → "Clean layout when opening a file" is OFF
  2. Open http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  3. Try the nudge's Clean button, and (reload) try its ✕ dismiss
  **Expected:** A small "This map could use Clean layout" prompt appears on a messy map; Clean tidies it and the prompt vanishes; ✕ dismisses without changing the map; already-tidy maps show no prompt
  **If not:** Note whether it nagged on a clean map or failed to appear on a messy one; screenshot

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

out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "function mapMessiness" src/aef-workflow-designer.html
grep -q "clean-nudge" src/aef-workflow-designer.html

## Visual Verification

Screenshots taken via Playwright and READ:
- `.playwright-mcp/t100-nudge-shown.png` — task-lifecycle via `?load=` (pref off): nudge centered top ("✨ This map could use Clean layout" + Clean button + ✕), accent border
- `.playwright-mcp/t100-after-clean.png` — after clicking the nudge's Clean: nudge gone, rows tidied

## Recommendation

**Recommendation:** GO
**Rationale:** Zero-mutation until the operator clicks; only appears on maps with genuine visual mess (overlaps/wavy rows), so it complements T-099 without nagging. The 6 clean corpus maps stay quiet; messy ones offer one click.
**Evidence:**
- Branch logic verified live: shows on messy+userImport+prefOff; hidden on clean map, pref-on, and programmatic load
- mapMessiness net-zero (buildBpmnXml byte-identical across probes); clean/messy separation at threshold 3 (6 maps score 0, messy 3–14)
- Suites green: bridge 31/31, validator 34/34, corpus 24 clean, parity OK; gallery copy identical
- Screenshots READ (nudge shown; after-clean)

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

### 2026-07-05 — messiness signal: not "would Tidy move", but overlaps+waves
- **Chose:** `mapMessiness()` = count of nodes in a same-lane overlap or wavy row-pair, threshold 3.
- **Why:** The filed plan's `cleanWouldMove()` dry-run was built and measured first — it reported ≥3 on ALL 24 maps (release-pipeline, the survey's clean control, scored 17) because Tidy grid-snaps at least one node on every machine-generated raw file. A nudge on every single load is exactly the nagging the operator's "helpful not naggy" bar forbids. The overlap+wave metric cleanly separates the 6 genuinely-clean maps (score 0) from messy ones (3–14).
- **Rejected:** Higher would-move threshold (no value separates clean from messy — release-pipeline 17 > many messy maps); measuring move *magnitude* (fragile, sub-pixel-sensitive).

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-05T10:30:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-100-clean-layout-nudge-offer-one-click-clean.md
- **Context:** Initial task creation

### 2026-07-05T10:37:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
