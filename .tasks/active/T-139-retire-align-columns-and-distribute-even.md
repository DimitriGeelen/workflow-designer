---
id: T-139
name: "Retire Align-columns and Distribute-evenly toolbar buttons (keep Clean + all functions)"
description: >
  Retire Align-columns and Distribute-evenly toolbar buttons (keep Clean + all functions)

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-07T14:39:26Z
last_update: 2026-07-07T14:39:26Z
date_finished: null
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

# T-139: Retire Align-columns and Distribute-evenly toolbar buttons (keep Clean + all functions)

## Context

Operator UI simplification. The `⁙ Align columns` (T-107) and `↔ Distribute evenly`
(T-109) toolbar buttons explicitly fight each other (their own tooltips admit each
"partly undoing" the other), and `✨ Clean layout` (T-095) already performs column
alignment internally via `alignColumnsMoves()` (T-116). Retire the two standalone
buttons and their `.onclick` bindings, keeping **all three underlying functions**
(`cleanLayout`, `alignColumns`/`alignColumnsMoves`, `distributeEvenly`) intact — they
are depended on by Clean, the load-nudge, apply-on-import, the bake tool, and the
T-101/T-102 verifiers. Also repoint `_undo-verify-cdp.mjs` (T-132's gate), which clicks
`btn-clean` by id, so it stays green (btn-clean is retained; this is defensive as the
diag tool `_align-distribute-diag.mjs` references the removed ids).

## Acceptance Criteria

### Agent
- [x] `btn-align-cols` button element AND its `$('btn-align-cols').onclick` binding removed from `src/aef-workflow-designer.html`
- [x] `btn-distribute` button element AND its `$('btn-distribute').onclick` binding removed from `src/aef-workflow-designer.html`
- [x] `✨ Clean layout` button (`btn-clean`) and its binding retained and unchanged
- [x] All three functions retained: `grep -q "function cleanLayout"`, `"function alignColumns"`, `"function alignColumnsMoves"`, `"function distributeEvenly"` all present (nudge/import/bake/verifiers still work)
- [x] Mirror invariant restored: `diff -q src/aef-workflow-designer.html build/gallery/designer.html` identical
- [x] Corpus node-cut gate stays green (0 cuts/24) — proves no routing/layout regression
- [x] `_undo-verify-cdp.mjs` still passes (btn-clean retained; T-132 gate unaffected)

### Human
- [ ] [REVIEW] Toolbar reads clean with only Clean layout remaining; Clean still tidies + aligns columns
  **Steps:**
  1. Hard-refresh the gallery on :8834 (Ctrl+Shift+R), open any gateway-dense map (e.g. promotion-pipeline)
  2. Confirm the toolbar shows `✨ Clean layout` but no longer shows `⁙ Align columns` or `↔ Distribute evenly`
  3. Click `✨ Clean layout`
  **Expected:** toolbar is less cluttered; Clean still straightens vertical drops (column alignment still happens inside Clean); Ctrl+Z reverts
  **If not:** note which button is still present, or whether Clean stopped aligning columns

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

diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "id=\"btn-clean\"" src/aef-workflow-designer.html
bash -c '! grep -q "id=\"btn-align-cols\"" src/aef-workflow-designer.html'
bash -c '! grep -q "id=\"btn-distribute\"" src/aef-workflow-designer.html'
grep -q "function cleanLayout" src/aef-workflow-designer.html
grep -q "function alignColumnsMoves" src/aef-workflow-designer.html
grep -q "function distributeEvenly" src/aef-workflow-designer.html
tests/check-corpus-node-cuts.sh
node tools/_undo-verify-cdp.mjs

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

Element/viewport screenshot of the live toolbar (gallery :8834, promotion-pipeline)
taken and READ after the change:
- `t139-toolbar-viewport.png` (archived `.playwright-mcp/t139-toolbar-after.png`):
  toolbar now shows `✨ Clean layout` among the layout actions; `⁙ Align columns`
  and `↔ Distribute evenly` are absent. Clean layout button retained and unchanged.
  No layout/overflow regression in the toolbar row.

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

## Recommendation

**Recommendation:** GO (finalize — agent ACs complete + visually verified, ship to human REVIEW)

**Rationale:** The two standalone buttons that fought each other are removed; `✨ Clean
layout` (which already aligns columns via `alignColumnsMoves()`) is the single remaining
layout action. All three underlying functions are retained, so the load-nudge,
apply-on-import, the bake tool, and the T-101/T-102 verifiers are unaffected. No gate
regressed: corpus node-cut 0/24, the T-132 undo verifier passes (btn-clean retained),
mirror byte-identical. Only a Human REVIEW of the decluttered toolbar feel remains.

**Evidence:**
- `! grep btn-align-cols` and `! grep btn-distribute` in source → both removed; `grep btn-clean` → retained
- `function cleanLayout/alignColumnsMoves/distributeEvenly` all still present
- `diff -q src build/gallery/designer.html` → identical (mirror restored)
- `tests/check-corpus-node-cuts.sh` → 24 unchanged, 0 regressed, total cuts 0
- `node tools/_undo-verify-cdp.mjs` → `pass: true`
- Toolbar screenshot READ (see ## Visual Verification): both buttons gone, Clean intact

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-07T14:39:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-139-retire-align-columns-and-distribute-even.md
- **Context:** Initial task creation
