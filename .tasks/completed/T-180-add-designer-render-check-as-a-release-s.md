---
id: T-180
name: "Add designer render-check as a release-script gate"
description: >
  Wire tests/test_designer_render.py into scripts/release-designer.sh so a release cut fails if the freshly-built artifact does not render or lost the T-177 governance fields. Closes the T-179 loop: the guarding test currently only runs manually/P-011, not at release time. Arc: designer-authoring-surface (release-then-repin hardening, Directive 1).

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
created: 2026-07-10T21:47:11Z
last_update: 2026-07-10T21:50:58Z
date_finished: 2026-07-10T21:50:58Z
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

# T-180: Add designer render-check as a release-script gate

## Context

T-179 built `tests/test_designer_render.py` (render + T-177-marker + console guard), but it only runs
manually / under T-179's P-011 — NOT when a release is cut. That leaves the release itself ungated: a
future `scripts/release-designer.sh` run could ship a build that doesn't render or dropped a governance
field, exactly the drift class the test exists to catch (PL-004: a gate never run against its subject is
latent). This wires the render-check into the release script as a fail-closed gate. Arc:
designer-authoring-surface (release→re-pin hardening, Directive 1 Antifragility).

## Acceptance Criteria

### Agent
- [x] `scripts/release-designer.sh` runs `python3 tests/test_designer_render.py` after producing the artifact (before writing the manifest, so a failed gate never leaves a manifest pointing at a bad build); a non-zero exit fails the release with a clear, actionable message. Proven: forced a failing stub → release exit 1, "render gate FAILED", manifest unchanged.
- [x] Gate is **fail-closed by default** but bypassable via `RELEASE_SKIP_RENDER_CHECK=1`, which prints a loud `WARNING` to stderr (no silent skip — PL-004 / "no silent caps") and continues. Proven: bypass with a failing stub → WARNING + exit 0.
- [x] Determinism preserved: re-running `scripts/release-designer.sh` at the current unchanged `0.2.0` re-produces the identical artifact sha256 (`e301986b…`) AND passes the render gate (exit 0); `dist/` stays clean.
- [x] `docs/aef-designer-integration-protocol.md` notes that a release cut now runs the render-check gate (in the release/verification section).

## Verification

# Release cut runs green end-to-end (produces artifact AND passes the render gate).
bash scripts/release-designer.sh
# Determinism: artifact sha256 unchanged after the re-cut above.
a=$(sha256sum dist/aef-workflow-designer-0.2.0.html | awk '{print $1}'); [ "$a" = "e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a" ]
# The script actually invokes the render-check (gate is wired, not just documented).
grep -q 'test_designer_render.py' scripts/release-designer.sh
# Documented bypass exists (fail-closed with an escape hatch).
grep -q 'RELEASE_SKIP_RENDER_CHECK' scripts/release-designer.sh
# Protocol doc mentions the render gate.
grep -q 'render-check' docs/aef-designer-integration-protocol.md

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

### 2026-07-10T21:47:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-180-add-designer-render-check-as-a-release-s.md
- **Context:** Initial task creation

### 2026-07-10T21:50:58Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
