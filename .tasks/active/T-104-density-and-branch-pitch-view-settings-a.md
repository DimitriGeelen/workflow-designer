---
id: T-104
name: "Density and Branch-pitch VIEW settings appear inert to operator - investigate and fix"
description: >
  Density and Branch-pitch VIEW settings appear inert to operator - investigate and fix

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T17:18:36Z
last_update: 2026-07-05T17:18:36Z
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

# T-104: Density and Branch-pitch VIEW settings appear inert to operator - investigate and fix

## Context

Operator field report (2026-07-05, screenshot of the VIEW settings): Density and
Branch pitch "are still not doing anything". By design (T-096, PL-011) these are
future-action settings — changing them reveals an "✨ Apply now — Clean layout"
button (`btn-apply-clean`) and otherwise takes effect on the next Tidy/Clean/drag-
snap; they never move nodes by themselves. This task: determine whether the report
is (a) a real bug (the pref is not consumed, so Apply changes nothing), or (b) a
discoverability/feedback gap (the affordance exists but the operator doesn't see it
work — e.g. the baked corpus is already a fixpoint at the default, so Apply reports
"already clean"), and fix whichever it is so the settings visibly take effect.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Root cause determined empirically: headless test shows `rowPitch()` = 72/96/124.8 for tight/normal/wide and the resulting node ys DIFFER across density and branchPitch on harvest-pipeline — the pref IS consumed; the mechanism works
- [x] Fix targets discoverability/feedback (pref was consumed, not broken): Density/Branch-pitch now **apply live** — changing the dropdown runs `cleanLayout()` immediately with feedback ("✨ Applied — N nodes moved (Ctrl+Z reverts)"), instead of silently storing the pref behind a separate Apply click
- [x] (N/A — pref was consumed, so no `rowPitch()`/`BRANCH_GAP` wiring bug to fix)
- [x] Change synced byte-identical to `build/gallery/designer.html` (`diff -q` clean)
- [x] Verified: dispatching a real `change` event on `#set-density` moves 11 nodes (`changed:true`, feedback set); before/after screenshots (`.playwright-mcp/t104-density-{normal,wide}.png`) READ — the map visibly re-lays-out at wider row pitch

### Human
- [ ] [REVIEW] Density / Branch pitch now visibly do something
  **Steps:**
  1. `cd /opt/832-Workflow-designer && bin/fw run tools/serve-gallery.sh 8834`
  2. Open any map, open Settings → VIEW, change **Density** (tight/normal/wide) and **Branch pitch** (compact/auto/roomy)
  3. Watch the canvas re-lay-out immediately on each change; note the "✨ Applied — N nodes moved" feedback; press Ctrl+Z to revert
  **Expected:** Each change visibly re-spaces the map right away (no separate Apply click needed); Ctrl+Z restores the previous layout
  **If not:** Note which control did nothing and whether the feedback text appeared

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
diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** Operator changes the VIEW Density / Branch-pitch dropdowns and the
canvas does nothing — "still not doing anything."

**Root cause:** Not a layout-engine bug — `cleanLayout()` correctly consumes both
prefs (`rowPitch()` = 72/96/124.8 for tight/normal/wide; node ys differ per
setting). The bug is interaction design: the change handler only *stored* the pref
and revealed a separate "Apply now" button; nothing happened on the canvas until
that second click. A view-density control that produces no immediate effect reads
as broken (Directive 3, Usability).

**Why structurally allowed:** T-096 deliberately made density a "future-action"
pref (opt-in Apply) to avoid surprise geometry mutation (PD-044). That choice
optimised for PD-044 strictness over the user's mental model of a live view
control, and no feedback loop caught that it felt inert — until the operator said
so, twice ("still").

**Prevention:** Make the setting self-evidently effective — apply live on change
with explicit "N moved / Ctrl+Z reverts" feedback, so effect and reversibility are
both visible. The live re-Clean is still user-initiated (they changed the control)
and revertible, so PD-044's intent (no *unattributed* mutation) holds.

## Recommendation

**Recommendation:** GO (agent work complete; ready for operator review)

**Rationale:** Cheapest correct fix for the reported symptom: the prefs already
worked, so this wires the change handlers to apply `cleanLayout()` live with clear,
revertible feedback — turning a silent no-op into an immediate, visible re-layout.
Reverses T-096's opt-in stance on the strength of repeated field feedback; PD-044
intent preserved (user-initiated + Ctrl+Z).

**Evidence:** Headless — `#set-density` change event moves 11 nodes, feedback set,
pref updated; screenshots `.playwright-mcp/t104-density-{normal,wide}.png` show the
map re-laying-out; gallery `diff -q` clean.


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

### 2026-07-05T17:18:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-104-density-and-branch-pitch-view-settings-a.md
- **Context:** Initial task creation
