---
id: T-091
name: "Upstream fix bundle: env-export contamination (T-015 GO) + review.py lib path
  (G-004)"
description: >
  T-015 decided GO: the TASKS_DIR/CONTEXT_DIR env export contamination is an upstream
  framework flaw. Deliverable: patch files + a maintainer-facing report covering BOTH
  known shared-mode bugs (T-015 env export; G-004 review.py PROJECT_ROOT/lib one-liner)
  plus the recommended shared-mode smoke test, staged for delivery via the ring20
  cascade (T-016 channel). No vendored files modified here.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-04T22:50:45Z
last_update: '2026-08-16T13:57:15Z'
date_finished: 2026-07-04T23:16:42Z
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
  - ts: '2026-08-16T12:33:36Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 4
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=4 (body:cross-machine); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:15Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 
      (paths:docs/reports/T-091-upstream-shared-mode-fixes.md); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-091: Upstream fix bundle: env-export contamination (T-015 GO) + review.py lib path (G-004)

## Context

T-015's GO (2026-07-04, operator-recorded) authorizes pursuing the upstream fix for the TASKS_DIR/CONTEXT_DIR env-export contamination. G-004 (T-090) is the second confirmed shared-mode bug in the same class. Bundle both into one maintainer-facing delivery: patch files (framework repo paths), a report explaining reproduction in shared-tooling mode, and the recommended prevention (shared-mode smoke test: PROJECT_ROOT != FRAMEWORK_ROOT, exercise CLI env + each blueprint route). Delivery channel is the ring20 cascade (T-016) — drafting is unblocked, transmission may wait on ring20.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `docs/reports/T-091-upstream-shared-mode-fixes.md` exists: symptom/root-cause/repro for BOTH bugs, patch inline or referenced, prevention recommendation (shared-mode smoke test), delivery instructions for the cascade
- [x] Patch for G-004: diff of web/blueprints/review.py (PROJECT_ROOT -> FRAMEWORK_ROOT, 2 lines: import + sys.path.insert) at `docs/patches/T-091-0001-review-py-lib-path-framework-root.patch`, verified with `git apply --check --directory=.agentic-framework` (vendored tree untouched)
- [x] Patch/diagnosis for T-015 env export: code path is `lib/paths.sh:49-50` (`${TASKS_DIR:-...}` trusts inherited env) + `lib/paths.sh:74` (`export ... TASKS_DIR CONTEXT_DIR` propagates to all children); scoped fix = FW_PATHS_FOR stamp patch at `docs/patches/T-091-0002-paths-sh-cross-project-env-guard.patch`, also `git apply --check` verified; guard logic simulation-tested (cross-project re-derives, same-project custom location preserved, cold start unchanged)
- [x] No vendored file modified: git status .agentic-framework stays empty

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

test -f docs/reports/T-091-upstream-shared-mode-fixes.md
grep -q "shared-mode smoke test" docs/reports/T-091-upstream-shared-mode-fixes.md
grep -q "FRAMEWORK_ROOT" docs/patches/T-091-0001-review-py-lib-path-framework-root.patch
grep -q "FW_PATHS_FOR" docs/patches/T-091-0002-paths-sh-cross-project-env-guard.patch
git apply --check --directory=.agentic-framework docs/patches/T-091-0001-review-py-lib-path-framework-root.patch
git apply --check --directory=.agentic-framework docs/patches/T-091-0002-paths-sh-cross-project-env-guard.patch
test -z "$(git status --porcelain .agentic-framework)"

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

**Symptom:** Two shared-tooling-mode failures: (1) every Watchtower /review/T-XXX page 500s (ModuleNotFoundError: dispatch_pause) — found T-090; (2) nested fw invocations with PROJECT_ROOT set for another project write tasks/focus into the CALLING project (fw test-onboarding repro) — found T-015.

**Root cause:** One class, two instances: framework code resolving framework-owned assets / trusting project-scoped env across project boundaries. (1) review.py:18 inserts `PROJECT_ROOT / "lib"` on sys.path but dispatch_pause.py lives under FRAMEWORK_ROOT/lib. (2) paths.sh:49-50 honour any inherited TASKS_DIR/CONTEXT_DIR (`${VAR:-default}`) while paths.sh:74 exports them to every child — cross-project inheritance is always contamination.

**Why structurally allowed:** All upstream development and CI runs with PROJECT_ROOT == FRAMEWORK_ROOT, where both bugs are invisible. No test exercises the split-root configuration; no lint flags PROJECT_ROOT-based resolution of framework assets. PL-010 records the class.

**Prevention:** Report §Prevention proposes an upstream shared-mode smoke test (temp consumer with split roots: CLI surface writes land consumer-side, every blueprint route curls 200, nested-invocation probe) + a grep lint for `PROJECT_ROOT / "lib"`-style asset resolution. Consumer-side, gap G-004 stays open until upstream prevention exists (mitigation ≠ prevention per G-019); the test-onboarding `env -u` workarounds double as the regression test for Bug 2.

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

### 2026-07-04T22:50:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-091-upstream-fix-bundle-env-export-contamina.md
- **Context:** Initial task creation

### 2026-07-04T23:12:35Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T23:16:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
