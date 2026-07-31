---
id: T-316
name: "Nine test files are referenced by no runner: green today, structurally silent tomorrow"
description: >
  AEF's rail 347 found seven structural guards in tests/lint/ that no runner globbed - never had - with one red since 2026-06-10, and the reason it survived was a name collision that returned green output about an unrelated tool. Swept our side: our tests/ has no orphaned SUBDIRECTORY, but the same class exists one level down. 9 of 33 tests/test_*.py are named in no runner (run-bridge-tests.sh, run-validator-tests.sh, check-corpus-geometry.sh, check-corpus-node-cuts.sh): test_bridge_seam_roundtrip, test_designer_export_contract, test_designer_owner_derived, test_designer_render, test_forward_fixtures, test_mapping_standard_conformance, test_release_immutability, test_roundtrip_serialization, test_validate_iw9. No pytest config, no conftest, no CI workflow, no fw wiring - they run only when invoked by hand. All 9 pass TODAY, which is why this is not urgent and is exactly why it is dangerous: a suite nobody runs cannot report a failure, so its silence is indistinguishable from health. Several guard the producer seam this arc depends on (forward fixtures, export contract, round-trip serialization, release immutability G-007). Fix is a directory/glob-level orphan guard that fails loudly when a tests/ file no runner references appears, verified RED against a synthetic orphan - not a one-time wiring of these nine, which would leave the next added file in the same hole.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tests/test_t316_runner_orphans.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T10:37:50Z
last_update: 2026-07-31T11:23:24Z
date_finished: 2026-07-31T11:23:24Z
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

# T-316: Nine test files are referenced by no runner: green today, structurally silent tomorrow

## Context

AEF's rail 347 found seven structural guards in `tests/lint/` that no runner ever globbed —
one red since 2026-06-10 — surviving because `fw test lint` runs shellcheck, so the obvious
command actively reassured. Swept our tree: no orphaned subdirectory, but the same class one
level down. 9 of 34 `tests/test_*.py` are named by no runner.

AEF then ran OUR check against THEIR tree and found their own fresh orphan guard was blind to
exactly this case — it globbed `*.bats` only, so `tests/web/` (32 pytest files, including the
designer-seam API contract tests both sides depend on) was invisible to the guard written to
find invisibility. Their predicate, sent at rail 349 and adopted here:

  MATCH WHAT A RUNNER WOULD COLLECT, NOT WHAT LOOKS LIKE A TEST.

A guard that flags helpers is not a stricter guard; per their L-527 it is one that gets ignored,
and the honest response to a guard with false positives is to stop running it.

Their second warning, which applies harder here than there: wiring a directory into one runner
turned their guard green while the suite that actually gates still named a single file. One
mention anywhere satisfies a directory-level guard — it proves REACHABILITY, not COMPLETENESS
across runner paths. Our tree is worse on this axis: four runners sit in `tests/`, and a file
named only by `check-corpus-node-cuts.sh` (9 task-Verification references) would read as wired
while the suite 78 tasks actually call, `run-bridge-tests.sh`, never touches it.

## Acceptance Criteria

### Agent
- [x] Pre-wiring baseline recorded in this task: each of the 9 unreferenced files run individually
      BEFORE any wiring, with its exit code. Green-after proves nothing; establishing green-before
      is what makes this a wiring change rather than a quiet absorption of unknown state.
- [x] `tests/test_t316_runner_orphans.py` exists and implements the collectable predicate:
      `test_*.py`, `*_test.py`, `*.bats` under `tests/` are in scope; every other file is a helper
      and is NOT flagged. Directory walk skips `fixtures/` and `__pycache__/`.
- [x] The guard matches against the GATING runner (`tests/run-bridge-tests.sh`) with comment lines
      stripped before the match — a comment naming a path is prose about the wiring, not the wiring.
- [x] The guard fails loudly if the gating runner is absent, renamed, or empty, instead of passing
      vacuously (the T-312 span-vacuity class: a check that cannot find its subject must go red).
- [x] Fixed point: the guard asserts its OWN basename is named by the gating runner, so removing
      its leg is caught by the guard itself rather than silently retiring it.
- [x] Three negative controls, executed by the guard against synthetic trees and asserted:
      (a) RED on a synthetic collectable orphan; (b) RED on call-site drift (gating runner exists
      but no longer names a collectable file); (c) GREEN on a directory holding only a
      non-collectable helper — the false-positive control.
- [x] Teeth on the REAL tree, not only synthetic: the guard is proven RED by mutating the actual
      runner (removing a leg) and green again after restore. Mutate-then-check, not read-and-believe.
- [x] All 9 orphans wired into `tests/run-bridge-tests.sh`; census of collectable-but-not-gated
      files is 0 with an empty deliberate-exclusion list.
- [x] Full bridge suite green after wiring, with the new leg count recorded.

## Verification

python3 tests/test_t316_runner_orphans.py
bash tests/run-bridge-tests.sh > /tmp/.t316-suite 2>&1
# Anchored on the whole summary line. `grep -q "0 failed"` is satisfied by
# "10 failed" — the prose-in-the-haystack class, fourth instance this arc, and
# this one was in the verification of the guard against that very class.
grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$" /tmp/.t316-suite
# The guard must be wired into the runner it checks (fixed point, asserted from
# outside as well as inside — an inside-only fixed point is self-consistency,
# which PL-034 says cannot detect a broken promise).
grep -vE "^\s*#" tests/run-bridge-tests.sh | grep -q "tests/test_t316_runner_orphans.py"
# Every previously-orphaned file is now named by the gating runner, matched on
# the invocation path form rather than the bare basename.
for f in test_bridge_seam_roundtrip test_designer_export_contract test_designer_owner_derived test_designer_render test_forward_fixtures test_mapping_standard_conformance test_release_immutability test_roundtrip_serialization test_validate_iw9; do grep -vE "^\s*#" tests/run-bridge-tests.sh | grep -q "tests/$f.py" || exit 1; done


## Evidence

**Pre-wiring baseline (green BEFORE, so this reads as wiring and not as absorption).**
Each of the nine run individually on 2026-07-31 before any runner change, all `rc=0`:

| file | rc | tail |
|---|---|---|
| test_bridge_seam_roundtrip.py | 0 | bridge emissions survive editor import with no silent drop |
| test_designer_export_contract.py | 0 | 8 owner-bearing node(s) each carry a non-empty authority carrier |
| test_designer_owner_derived.py | 0 | owner retired from AEF_FIELDS, no editable owner drop-down |
| test_designer_render.py | 0 | render, T-177 markers, inspector dropdowns, corpus (0.8.0) |
| test_forward_fixtures.py | 0 | 18 fixture(s) forward-compile clean |
| test_mapping_standard_conformance.py | 0 | all 4 frozen governance meta-keys present |
| test_release_immutability.py | 0 | G-007 guard — 5 paths pass |
| test_roundtrip_serialization.py | 0 | semantic fixed point across all aef-bpmn fixtures |
| test_validate_iw9.py | 0 | IW-9 rules O-1 / O-3 — 14 cases |

**Guard RED before, GREEN after, on the REAL tree.** Pre-wiring the guard reported
10 orphans (the nine plus itself) and a fixed-point failure. Post-wiring: 35
collectable files, all invoked, deliberate-exclusion list empty.

**Mutation teeth (three, against the actual runner, restored byte-identical after):**
1. Removed the `test_validate_iw9.py` leg → RED, naming that file.
2. Repointed the guard's own leg at another path → RED on the fixed-point assertion.
3. Renamed `run-bridge-tests.sh` → RED as unevaluable, rather than passing over an
   empty span. This is the T-312 vacuity class and the reason the check refuses to
   treat "cannot find my subject" as "nothing wrong".

**Negative controls (five, inside the guard, run every time):** synthetic orphan RED;
call-site drift RED; a directory holding only non-collectable helpers GREEN (the
false-positive control — a guard that flags helpers gets switched off, and per AEF's
L-527 the honest response to it is to stop running it); unreadable/empty runner RED;
commented-out call site RED.

The first cut of the commented-out-call control was itself wrong — it built a runner
whose only line was a comment, so the empty-runner rule fired first and the control
proved nothing. Caught by running it, not by reading it.

**Suite:** `bridge round-trip: 60 passed, 0 failed` (was 50), geometry sweep 24 clean,
62s wall.


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

### 2026-07-31T10:37:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-316-nine-test-files-are-referenced-by-no-run.md
- **Context:** Initial task creation

### 2026-07-31T11:18:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e8989f35
- **Timestamp:** 2026-07-31T11:24:25Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 10
     - evidence: `grep -vE "^\s*#" tests/run-bridge-tests.sh | grep -q "tests/test_t316_runner_orphans.py"`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 13
     - evidence: `for f in test_bridge_seam_roundtrip test_designer_export_contract test_designer_owner_derived test_designer_render test_forward_fixtures test_mapping_standard_conformance test_release_immutability tes`

### 2026-07-31T11:23:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
