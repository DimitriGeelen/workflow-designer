---
id: T-021
name: "Dogfood: generate + validate workflow for vendored-AEF inception-lifecycle"
description: >
  Dogfood: generate + validate workflow for vendored-AEF inception-lifecycle

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
created: 2026-07-02T21:26:33Z
last_update: 2026-07-02T22:11:02Z
date_finished: 2026-07-02T22:11:02Z
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

# T-021: Dogfood: generate + validate workflow for vendored-AEF inception-lifecycle

## Context

First build slice after T-020 GO (independent product, AEF-aware seams). Realises
the Sovereign's dogfood insight (2026-07-02): test AEF's workflow-*generation*
capability and the *functional quality* of the generation logic by generating a
workflow for a real process living in the vendored `.agentic-framework/`, then
validating it with our standalone judge (`tools/validate-workflow.py`, T-017/T-018).

Target process: **inception-lifecycle** — the worst-regression dogfood candidate
(r3 §5). Ground truth is the vendored implementation (`lib/inception.sh` +
gates), NOT reconstruction: start (agent files recommendation, advisory, T-1715)
→ captured → started-work → exploration (assumptions/IW/research, G-067) → review
(`fw task review`, T-973 marker) → decide `go|no-go|defer` (**Tier-0, human-only**,
T-679) → work-completed + branch. Authority → swimlanes: human decides, framework
enforces/transitions, agent advises.

Stays on the product side of the injection line: we **generate + validate a
definition**, we do NOT execute it against the live framework (S3 is AEF's side).
Output doubles as the product's first real test corpus and surfaces schema
friction = the v3 design inputs.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `examples/aef-processes/inception-lifecycle.workflow.yaml` generated, faithfully representing the vendored process: lanes = authority model (human/sovereignty, framework/authority, agent/initiative); a human decide step routing to go/no-go/defer; framework transition + terminal states per branch
- [x] The generated workflow validates clean with `python3 tools/validate-workflow.py examples/aef-processes/inception-lifecycle.workflow.yaml` (exit 0 — proves the generation logic produced a structurally valid file the judge accepts)
- [x] Friction note `docs/reports/T-021-inception-lifecycle-friction.md` captures every point where the current (v2) canonical schema cannot express the real process cleanly, each cross-referenced to the r3 spec SD/section it maps to — these are the Lock-1 / M-slice v3 design inputs
- [x] No execution/resolution performed against the vendored framework (authoring + validation only); vendored `.agentic-framework/` read-only, unmodified

### Human
<!-- All criteria are agent-verifiable (validator exit code + file existence). No Human ACs.
     A [REVIEW] of workflow *fidelity* to the lived process is valuable but optional —
     the generated file is the producer's output; the human may sanity-check it.

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

# Generated workflow validates clean (exit 0)
python3 tools/validate-workflow.py examples/aef-processes/inception-lifecycle.workflow.yaml
# Friction note exists
test -f docs/reports/T-021-inception-lifecycle-friction.md
# Vendored framework left unmodified (no staged changes under .agentic-framework)
test -z "$(git status --porcelain -- .agentic-framework 2>/dev/null)"

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

### 2026-07-02T21:26:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-021-dogfood-generate--validate-workflow-for-.md
- **Context:** Initial task creation

### 2026-07-02T22:11:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
