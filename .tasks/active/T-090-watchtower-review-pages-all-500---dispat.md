---
id: T-090
name: "Watchtower review pages all 500 - dispatch_pause import broken in shared-tooling mode"
description: >
  Every /review/T-XXX returns 500: vendored web/blueprints/review.py inserts PROJECT_ROOT/lib on sys.path before 'from dispatch_pause import ...', but in shared-tooling mode lib/ lives under FRAMEWORK_ROOT (.agentic-framework/lib). PROJECT_ROOT/lib does not exist here. Vendored tree is read-only: ship a product-side shim lib/dispatch_pause.py re-exporting the framework module; upstream fix is FRAMEWORK_ROOT like every other blueprint.

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
created: 2026-07-04T22:35:13Z
last_update: 2026-07-04T22:38:53Z
date_finished: 2026-07-04T22:38:53Z
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

# T-090: Watchtower review pages all 500 - dispatch_pause import broken in shared-tooling mode

## Context

Discovered while probing for a review index: EVERY /review/T-XXX on Watchtower (port 3005) returns 500 — the operator's entire 13-task review queue is unreachable, and all partial-complete tasks' Human AC instructions point at these URLs. watchtower.log traceback: `web/blueprints/review.py:25 → from dispatch_pause import ... → ModuleNotFoundError`. review.py:18 does `sys.path.insert(0, str(PROJECT_ROOT / "lib"))` (comment cites T-1810 CLI parity), but in shared-tooling mode the module lives at FRAMEWORK_ROOT/lib/dispatch_pause.py (.agentic-framework/lib/) and PROJECT_ROOT/lib does not exist. Every other blueprint (docs, cockpit, enforcement, quality) uses FRAMEWORK_ROOT for framework assets. The vendored tree is READ-ONLY here, so the product ships a shim `lib/dispatch_pause.py` that re-exports the framework module via the exact sys.path entry the buggy line inserts; the upstream one-line fix (PROJECT_ROOT → FRAMEWORK_ROOT) goes to the framework repo via the T-016 cascade.

## Acceptance Criteria

### Agent
- [x] Root cause recorded in RCA with the traceback line and the exact buggy path expression
- [x] Product-side shim `lib/dispatch_pause.py` exists, loads the framework's real module by file path (no copy of framework logic), re-exports its public names, and documents WHY it exists + when to remove it
- [x] Watchtower restarted; all 13 partial-complete review pages return HTTP 200 (T-073,T-074,T-075,T-076,T-077,T-079,T-081,T-082,T-083,T-084,T-085,T-087,T-089)
- [x] Gap registered in `.context/project/concerns.yaml` (framework blind >7 days? — review pages were last known-good when T-073 reviews were filed; register regardless: structural upstream flaw, shim is mitigation not prevention) with pointer to the upstream one-line fix
- [x] No vendored file modified: `git status .agentic-framework` clean / untouched

### Human
- [ ] [REVIEW] [RUBBER-STAMP] The review queue loads again in your browser
  **Steps:**
  1. Open http://192.168.10.107:3005/review/T-089
  **Expected:** The T-089 review page renders (task name, ACs, recommendation) — no "500 Internal Server Error"
  **If not:** Run `cd /opt/832-Workflow-designer && tail -30 .context/working/watchtower.log` and share the traceback

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

# Shim parses and points at the real framework module
python3 -c "import ast; ast.parse(open('lib/dispatch_pause.py').read())"
out=$(grep -c "agentic-framework" lib/dispatch_pause.py); test "$out" -ge 1
# Review pages live again (spot: first and last of the queue + newest)
out=$(curl -s -o /dev/null -w "%{http_code}" "$(cat .context/working/watchtower.url)/review/T-073"); test "$out" = "200"
out=$(curl -s -o /dev/null -w "%{http_code}" "$(cat .context/working/watchtower.url)/review/T-089"); test "$out" = "200"
# Gap registered
out=$(grep -c "dispatch_pause" .context/project/concerns.yaml); test "$out" -ge 1
# Vendored tree untouched
out=$(git status --porcelain .agentic-framework | wc -l); test "$out" = "0"

## Recommendation

**Recommendation:** GO
**Rationale:** The entire 13-task review queue went from 500 to 200 with a one-file, self-documenting product-side shim; the vendored tree is untouched and the structural flaw is registered as G-004 with the upstream one-liner named. Nothing subjective changed in the pages themselves — the blueprint code is byte-identical; only the import now resolves.
**Evidence:**
- All 13 review pages + dashboard verified 200 (curl loop); T-089 page renders task name, ACs, recommendation
- lib/dispatch_pause.py re-exports format_age / list_paused_dispatches_for_task / truncate from the framework module (tested via the same sys.path mechanism review.py uses)
- git status .agentic-framework: 0 changes
- G-004 in .context/project/concerns.yaml with removal condition for the shim

## RCA

**Symptom:** Every Watchtower /review/T-XXX returns HTTP 500 (ModuleNotFoundError: dispatch_pause); the operator's 13-task review queue is fully unreachable while all partial-complete Human ACs point at those URLs.

**Root cause:** `.agentic-framework/web/blueprints/review.py:18` inserts `PROJECT_ROOT / "lib"` into sys.path for the T-1810 paused-dispatch helpers, then line 25 imports `dispatch_pause`. In shared-tooling mode PROJECT_ROOT is the product repo (/opt/832-Workflow-designer) which has no lib/; the module lives at FRAMEWORK_ROOT/lib/dispatch_pause.py. Wrong root constant — every other blueprint (docs/cockpit/enforcement/quality) uses FRAMEWORK_ROOT for framework assets.

**Why structurally allowed:** The framework's own host repo has PROJECT_ROOT == FRAMEWORK_ROOT, so the bug is invisible upstream — it only manifests in shared-tooling deployments, and no health check exercises /review routes (fw doctor and the audit ping / but not /review/*). Same blindspot class as T-015 (TASKS_DIR/CONTEXT_DIR contamination): shared-mode divergence has no test coverage upstream.

**Prevention:** Gap registered in concerns.yaml with the upstream one-liner (PROJECT_ROOT → FRAMEWORK_ROOT); recommend upstream add a shared-mode smoke test (PROJECT_ROOT != FRAMEWORK_ROOT, GET each blueprint route asserts non-500) — mirror of the T-015 recommendation. Product-side shim documents its own removal condition so it cannot silently outlive the upstream fix.

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

### 2026-07-04T22:35:13Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-090-watchtower-review-pages-all-500---dispat.md
- **Context:** Initial task creation

### 2026-07-04T22:38:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
