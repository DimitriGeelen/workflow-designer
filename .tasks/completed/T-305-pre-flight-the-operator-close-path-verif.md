---
id: T-305
name: "Pre-flight the operator close path: verify-gate sweep of the 66 close-ready tasks, fix rotted Verification lines"
description: >
  Pre-flight the operator close path: verify-gate sweep of the 66 close-ready tasks, fix rotted Verification lines

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
created: 2026-07-29T14:48:14Z
last_update: 2026-07-29T15:04:48Z
date_finished: 2026-07-29T15:04:48Z
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

# T-305: Pre-flight the operator close path: verify-gate sweep of the 66 close-ready tasks, fix rotted Verification lines

## Context

T-302 handed the operator 66 one-line close commands; each close runs P-011 verification, and probe shows rot: T-073 pins "31 passed, 0 failed" while the bridge suite now reports 43 — the close would block in the operator's face. Count-pinned suite assertions rot every time a suite leg lands (suite grew 31→43 across six+ additions). Pre-flight every close-ready task's Verification block now, fix rotted lines, so the batch checklist actually closes.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] All Verification commands across the 66 close-ready tasks extracted (same comment-stripped parser as the gate), deduped; unique heavy commands (suite runs) executed once each with expectations evaluated against the captured output — no 66x suite re-runs (330 lines → 213 unique, sweep runner t305-run.py; 10 failing)
- [x] Every failing line diagnosed: count-pinned rot rewritten count-agnostic (e.g. `grep -q "passed, 0 failed"`), genuinely-broken lines fixed or corrected with the reason in that task's file; zero expectations weakened beyond count-agnosticism (failure detection must survive: pattern still requires 0 failed) (10 failures → 6 root classes → 26 task files fixed, each rewrite carries an inline reason comment citing T-305)
- [x] Post-fix re-verify green with deduped coverage (equivalent to per-task re-runs without ~24 redundant executions of the identical suite line): one fresh bridge-suite run evaluates the shared count-agnostic pattern, every other fixed line re-executes standalone, and the 7 structurally-edited tasks (T-075 T-090 T-095 T-096 T-101 T-195 T-293) get full `fw task verify`; sweep tally recorded in Updates and appended to docs/reports/T-302-reviewer-sweep.md so the operator checklist carries the pre-flight stamp (suite 43 passed 0 failed; 7/7 GATE-PASS; one transient curl blip on the T-293 standalone re-ran clean in isolation and its full gate passed)
- [x] Learning captured: Verification lines must assert failure-shape ("passed, 0 failed"), never pin suite totals (PL-class; cites T-073 31-vs-43 rot) (PL-061)


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

# Shared suite pattern (count-agnostic, failure-shape preserved)
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
# No active task's ## Verification SECTION still pins the rotted suite total (prose/AC mentions are historical record and stay; self-excluded: this file quotes the literal as a negative probe)
out=$(python3 -c "import glob,re; print(sum(1 for f in glob.glob('.tasks/active/*.md') if 'T-305' not in f and '31 passed, 0 failed' in ((re.search(r'## Verification\n(.*?)(\n## |\Z)', open(f).read(), re.S) or type('m',(),{'group':lambda s,i:''})()).group(1))))"); test "$out" = "0"
# Operator checklist carries the pre-flight stamp
grep -q "Pre-flight stamp (T-305" docs/reports/T-302-reviewer-sweep.md
# PL-061 captured
grep -q "PL-061" .context/project/learnings.yaml

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

**Symptom:** Operator's one-line close commands (T-302 checklist) would block at the P-011 gate — probe showed T-073 pinning "31 passed, 0 failed" while the suite reports 43; full sweep found 10 failing lines across ~30 task references.

**Root cause:** Verification lines written against a moving baseline. Six classes, one shape: assertions pinned to the world as it was at write time (suite totals, exact source-grep counts, a shim path, a port, a regen path) instead of to the failure-shape they exist to detect. The world moved (suite grew 31→43, call sites grew 2→9, shim deleted at T-276, :8834 retired at T-253, dialect rule landed at T-288/T-300); the assertions did not.

**Why structurally allowed:** P-011 runs a task's Verification only at that task's completion — nothing re-runs the blocks of tasks parked in partial-complete awaiting Human ACs. Rot accumulated invisibly for weeks; the framework had no eye on the gap between "gate written" and "gate finally run".

**Prevention:** PL-061 (assert failure-shape, never pinned totals; `|| true` on `grep -c`; `-ge` floors; read the watchtower triple file, never hard-code ports) — plus this sweep's inline reason comments in all 26 fixed files so the pattern is visible at the next edit. Structural re-run-on-age gate deliberately not built now (66-task backlog is a one-time artifact of the T-302 batch; register a concern if a second batch accumulates).

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

### 2026-07-29T14:48:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-305-pre-flight-the-operator-close-path-verif.md
- **Context:** Initial task creation

### 2026-07-29T15:20:00Z — pre-flight sweep complete [agent]
- **Action:** Extracted 330 Verification lines from the 66 close-ready tasks (comment-stripped, gate-identical parser), deduped to 213 unique commands, ran each once. 10 failing lines traced to 6 root classes: (A) count-pinned suite totals `31 passed` vs today's 43 (~24 tasks shared the line); (B) `grep -c` exits 1 on zero matches under `set -e` (T-075, T-195 — passing intent, failing implementation); (C) exact-count source greps outgrown by legitimate call sites (T-095/T-096 cleanLayout =2/=3 vs 9 today → `-ge` floors); (D) T-090 checks on shim `lib/dispatch_pause.py` deleted at the T-276 re-vendor; (E) T-101 forbidden yaml-to-bpmn regen-diff (G-012 destructive path vs editor-saved dialect, T-288/T-300) → `tools/_corpus-adopt-verify.py`, plus geometry tail-pipe → capture-first count-agnostic; (F) T-293 curl at retired :8834 (T-253 ufw RCA) → watchtower triple-file URL.
- **Output:** 26 task files fixed (Verification sections only, inline reason comments citing T-305). Re-verify: fresh suite 43 passed 0 failed on the count-agnostic pattern; all standalone fixed lines pass (one transient curl blip on T-293 re-ran clean and its full gate passed); 7/7 full `fw task verify` GATE-PASS (T-075 T-090 T-095 T-096 T-101 T-195 T-293). Pre-flight stamp appended to docs/reports/T-302-reviewer-sweep.md. PL-061 captured.
- **Context:** T-302's 66 one-line closes now pass their P-011 gates instead of blocking in the operator's face.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6a6427ad
- **Timestamp:** 2026-07-29T15:05:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T15:04:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
