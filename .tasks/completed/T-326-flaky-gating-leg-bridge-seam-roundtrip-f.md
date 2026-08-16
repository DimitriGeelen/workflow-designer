---
id: T-326
name: "Flaky gating leg: bridge-seam-roundtrip fails intermittently with no captured
  diagnostic"
description: >
  tests/test_bridge_seam_roundtrip.py failed once inside tests/run-bridge-tests.sh
  (bridge round-trip: 63 passed, 1 failed) and passed standalone and on immediate
  re-run of the identical command (64/0, twice). Observed 2026-08-01 during T-325's
  P-011 gate. The runner printed only [FAIL] with the harness output swallowed, so
  the failing run left no evidence of its cause; the surviving capture is in the session
  scratchpad as T-326-flaky-seam-roundtrip-evidence.txt. The harness drives a real
  Playwright chromium via tools/_bridge-seam-roundtrip-cdp.mjs, and several other
  legs in the same suite drive CDP too, so browser/resource contention is the first
  hypothesis. This matters beyond one leg: an intermittent failure in the GATING runner
  makes a red dismissible as 'just flaky', which is exactly how a real regression
  gets waved through, and it makes a green weaker evidence than it looks. Fix has
  two halves and the second is the important one: (1) find and remove the nondeterminism,
  (2) make the runner CAPTURE the failing harness output so a future intermittent
  failure is diagnosable at all rather than only reproducible.

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T20:21:48Z
last_update: '2026-08-16T12:33:50Z'
date_finished: 2026-08-01T20:40:27Z
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
  - ts: '2026-08-16T12:33:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-326: Flaky gating leg: bridge-seam-roundtrip fails intermittently with no captured diagnostic

## Context

Found while T-325's P-011 gate ran the bridge suite: one leg failed (63 passed, 1 failed) and the
same command passed twice immediately after. The leg is not the interesting part. The runner
discarded the failing leg's output, so the single run that failed left no evidence of its own
cause — it could be re-run, never read.

An intermittent red in a GATING runner is dismissible as "just flaky", which is exactly how a real
regression gets waved through; and it weakens every green, because a suite that fails 1-in-N for
unknown reasons reports a different, weaker claim than its summary line makes. Registered as G-014,
sibling of G-013 (a verdict whose reliability does not travel with it).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tests/run-bridge-tests.sh` CAPTURES each orphan-leg's stdout/stderr and PRINTS it when that
      leg fails. Today a failing leg emits only `[FAIL] <message>` and the harness output is
      discarded, so the one run that failed left no evidence of its own cause — the failure is
      reproducible-only, never diagnosable. This is the half that matters: nondeterminism that
      cannot be reproduced on demand is unfixable without its output — `show_output()` helper; swept ALL THREE swallowing sites in the file, not just the reported one (whole-tree rule).
- [x] Output is printed on FAILURE ONLY — a suite that prints every leg's stdout buries the signal
      it exists to surface, and the passing path stays exactly as quiet as it is today — a green suite prints 0 capture blocks (`grep -c 'captured output'` = 0).
- [x] Proven by forcing a real failure rather than by reading the code: point one leg at a
      deliberately broken invocation, show the harness output now reaches the transcript, restore,
      and confirm the tree is byte-identical (PL-061; and T-321's rule that the mutation must be
      asserted to have LANDED before any verdict is read) — forced-failure run: suite rc=1, 9 capture blocks, the exact `python3: can't open file ...` line reached the transcript; anchor occurrences asserted =1 first; sha 544d46eb78ab restored IDENTICAL. A FIRST attempt (unknown CLI flag) landed but produced NO failure — the legs ignore unknown args — and was discarded as a null result rather than reported as teeth.
- [x] The nondeterminism itself is investigated with a stated hypothesis and a repeat-run
      experiment, and the RESULT IS RECORDED EVEN IF INCONCLUSIVE — "ran it N times, saw it 0/N"
      bounds the rate and is a finding; dropping it silently would leave the next reader believing
      the flake was never chased — hypothesis: browser/resource contention (harness drives a real Playwright chromium; sibling legs drive CDP). NOT REPRODUCED: 0/8 standalone, 0/5 in-suite. Recorded as a BOUND on the rate, not as an absence.
- [x] The known flake is registered where it stays visible (gaps/concerns register), not left to
      live only in this task file — a completed task archives and becomes invisible, which is how
      an intermittent gating failure quietly becomes normal — G-014 in `.context/project/concerns.yaml` (register now 9 watching); its decision_trigger explicitly refuses "we have not seen it lately" as a close condition.
- [x] `tests/run-bridge-tests.sh` still green end-to-end after the change, and the T-316
      runner-orphan guard still passes (the orphan-leg list is exactly what that guard reads, so a
      change to how legs are invoked can silently break it) — bridge 64 passed/0 failed after the change; T-316 orphan guard green.

### Human

*(none — every criterion here is a deterministic shell check, so nothing is routed to the human. The open question this task leaves behind is tracked as G-014, not as an unchecked box.)*

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
# Origin: L-387, captured 4x (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Anchored on structural literals, not on counts later work legitimately moves (T-317).
bash tests/run-bridge-tests.sh > /tmp/.t326-v.out 2>&1 && grep -qE 'bridge round-trip: [0-9]+ passed, 0 failed' /tmp/.t326-v.out
# the passing path stays silent — the capture is failure-only
test "$(grep -c 'captured output of' /tmp/.t326-v.out)" -eq 0
# no invocation in the runner discards its output any more (all three sites swept).
# COMMENT LINES EXCLUDED: the first cut of this line matched the comment that
# explains the removal — a check satisfied by its own explanation, which is the
# same prose-in-the-haystack class this arc keeps finding (T-321, T-311, T-312).
test "$(grep -vE '^[[:space:]]*#' tests/run-bridge-tests.sh | grep -cE '>[ ]?/dev/null 2>&1')" -eq 0
# the helper exists and is used at every site that can report a FAIL for a subprocess
grep -q 'show_output()' tests/run-bridge-tests.sh
test "$(grep -c 'show_output "' tests/run-bridge-tests.sh)" -ge 3
# the flake is registered where it survives this task being archived
grep -q 'id: G-014' .context/project/concerns.yaml
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
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

### 2026-08-01T20:21:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-326-flaky-gating-leg-bridge-seam-roundtrip-f.md
- **Context:** Initial task creation

### 2026-08-01T20:26:25Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b98a6a82
- **Timestamp:** 2026-08-01T20:41:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-01T20:40:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
