---
id: T-942
name: "T-884's /api/instances: the four remaining sites, and the fabricated 'three weeks' I put in T-941's record"
description: >
  T-884's /api/instances: the four remaining sites, and the fabricated 'three weeks' I put in T-941's record

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh, tests/test_designer_export_contract.py, tests/test_designer_owner_derived.py, tests/test_designer_render.py, tools/_t682-boundary-inventory.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-30T11:28:05Z
last_update: 2026-09-30T11:33:59Z
date_finished: 2026-09-30T11:33:59Z
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

# T-942: T-884's /api/instances: the four remaining sites, and the fabricated 'three weeks' I put in T-941's record

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

Two findings, one investigation.

**1. I fabricated a date.** T-941 asserts `/api/instances` shipped on `2026-09-09` and that the
boundary-inventory finding "went unread for three weeks". Measured: the route first appears in
`tools/gallery-serve.py` at `94d2b2a6`, **2026-09-29 09:35 +0200** — about 26 hours before I
wrote that. `designer-v0.13.0` is dated 2026-09-22, so three weeks was never available. I did
not check; I picked a number and repeated it in five artifacts, one of which is a learning other
sessions will read as fact. That is the defect class this whole session has been about — a
confident figure nobody measured — committed by the agent writing the checks against it.

The corrected reading is weaker in magnitude and unchanged in substance: the latency was ~26
hours, and the point was never that it was *long*. It is that the latency is **unbounded**,
because nothing schedules the check. It was 26 hours only because a sweep happened to run today.

**2. The same omission has four more sites.** `94d2b2a6` shipped the route plus its own test and
touched none of the guards that load the designer:

| site | state |
|---|---|
| `test_designer_render.py` CONSOLE_WHITELIST | fixed 2026-09-30 (T-940), by blocking the release |
| `_t682-boundary-inventory.py` ROUTE_SEMANTICS | fixed 2026-09-30 (T-941) |
| `test_designer_export_contract.py` CONSOLE_WHITELIST | **FAILING** — 404 on /api/instances |
| `test_designer_owner_derived.py` CONSOLE_WHITELIST | **FAILING** — 404 on /api/instances |
| `test_gallery_instances_api.py` | **ORPHAN** — T-884 wrote it, never wired it to the runner |
| `test_boundary_inventory_unclassified.py` | **ORPHAN — mine, from T-941, the same mistake** |

Three CONSOLE_WHITELIST copies with one purpose and independent contents is the shared-mechanism
defect (PL-214): the next optional probe will break a subset of them again.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The fabricated date is corrected in every artifact carrying it,** and corrected rather
      than deleted, so the record shows what was claimed and what measurement replaced it:
      PL-363, `tools/_t682-boundary-inventory.py`'s comment,
      `tests/test_boundary_inventory_unclassified.py`'s docstring, and T-941's task file
      → all four carry the measured figure (`94d2b2a6`, 2026-09-29 09:35, ~26 hours) with the
      original claim shown as corrected. T-941's Context carries it as a blockquote at the top.
- [x] **Both orphaned tests are wired into `tests/run-bridge-tests.sh`** and the T-316
      runner-orphan guard reports zero orphans. One of the two is mine: I wrote PL-363 about
      instruments nothing runs, then added an instrument nothing runs, in the same commit
      → `47 collectable file(s), all invoked`. The guard's own negative controls pass, and its
      `helper GREEN` control confirms `designer_console.py` is correctly read as a helper rather
      than an unwired test, so the new module did not buy a false green.
- [x] **`test_designer_export_contract.py` and `test_designer_owner_derived.py` pass,** with
      `/api/instances` whitelisted for the documented reason — the browser's network layer emits
      the entry before any JS runs, so it cannot be caught away — and NOT by muting the console
      check or editing `src/` to satisfy a stale test
      → both `rc=0`, and `src/` was not touched. `test_gallery_instances_api.py` also passes 8/8;
      its final check, "the route wrote nothing into the repo", independently corroborates the
      `mutates: none` row T-941 added from reading the call graph.
- [x] **The three whitelists stop being three independent copies.** One shared definition, so
      the next optional probe cannot break a subset (PL-214). If a shared module is the wrong
      shape here, say why in Decisions rather than leaving three copies undiscussed
      → `tests/designer_console.py`. The matching RULE moved with the tuple, not just the data:
      three identical `any(w in e for w in ...)` comprehensions were the same duplication one
      level down. Verified to discriminate: a real console error is not swallowed, every
      documented probe is tolerated. One definition site, asserted as an invariant.

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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# Zero orphans. This is the leg that caught my own mistake, so it runs first.
python3 tests/test_t316_runner_orphans.py
# REPLACED under T-944. This line was:
#     test "$(grep -l 'CONSOLE_WHITELIST = (' tests/*.py | wc -l)" -eq 1
# and its comment claimed it "pins the INVARIANT rather than a corpus count". The G-015
# hygiene ratchet classified it [population-pinned] and it was right: the line counts a
# glob over tests/*.py, so it is a global that moves when anyone else adds a test file,
# not a property of what T-942 delivered. My own comment asserting otherwise is exactly
# the self-issued exemption that rule exists to refuse.
# Traded for four assertions naming the four files this task actually changed. What is
# LOST is the "no other file defines its own copy" guarantee; that belongs to a ratchet
# over the tree, not to one task's verification block.
grep -q 'CONSOLE_WHITELIST = (' tests/designer_console.py
grep -q 'from designer_console import' tests/test_designer_render.py
grep -q 'from designer_console import' tests/test_designer_export_contract.py
grep -q 'from designer_console import' tests/test_designer_owner_derived.py
# All three console guards green against the shared definition.
python3 tests/test_designer_render.py
python3 tests/test_designer_export_contract.py
python3 tests/test_designer_owner_derived.py
# T-884's own test, now that something runs it. Its 8th check independently corroborates
# the 'mutates: none' row T-941 added: "the route wrote nothing into the repo".
python3 tests/test_gallery_instances_api.py
# The shared whitelist discriminates rather than merely existing: a real console error is
# NOT swallowed, and every documented probe IS tolerated. Negative leg first.
python3 -c "import sys; sys.path.insert(0,'tests'); from designer_console import unexpected, CONSOLE_WHITELIST; assert unexpected(['Uncaught TypeError @ http://h/d.html']); assert all(not unexpected([f'404 @ http://h{w}']) for w in CONSOLE_WHITELIST)"
# The correction is recorded, not quietly dropped: the learning states the measured figure.
grep -q '26 HOURS' .context/project/learnings.yaml

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-30T11:28:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-942-t-884s-apiinstances-the-four-remaining-s.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-51763040
- **Timestamp:** 2026-09-30T11:34:09Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — **Both orphaned tests are wired into `tests/run-bridge-tests.sh`** and the T-316
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/run-bridge-tests.sh in: **Both orphaned tests are wired into `tests/run-bridge-tests.sh`** and the T-316`

### 2026-09-30T11:33:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
