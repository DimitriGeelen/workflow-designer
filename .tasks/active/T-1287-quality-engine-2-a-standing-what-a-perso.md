---
id: T-1287
name: "Quality engine 2: a standing 'what a person sees' gate on every corpus map
  at 1024/1440/1920 in the opening state, run before any review"
description: >
  ~70% of reviewer findings on T-1241/T-1282 were mechanically decidable (crossings
  incl. arrowheads, clipping, cut text, min text size, contrast, reachability). Consolidate
  _t1256/_t1276/_t1278 into one gate run before any official review (T-1285 GO, ranked
  step 2; evidence docs/reports/T-1285-quality-engine.md)

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: [quality-engine, T-1285]
components: []
related_tasks: []
# write_set:                      # T-3512: optional — globs (relative to PROJECT_ROOT)
#                                 # naming the files this task intends to write. Declared
#                                 # at CAPTURE, unlike components: which the framework
#                                 # resolves from git history at close. Feeds TWO things:
#                                 #   1. `fw write-set check T-A T-B` — without it the
#                                 #      comparison has nothing to compare and every real
#                                 #      pair exits 2 (undecidable). 0 of 3032 tasks
#                                 #      declared it, so that gate has never had an input.
#                                 #   2. BVP blast_radius before close — the 0.6-weighted
#                                 #      cost term, unavailable for 85% of rankable tasks
#                                 #      because components: only exists once the task is
#                                 #      finished (T-3471).
#                                 # Example: write_set: ["lib/bvp.sh", "tests/unit/t*_bvp*"]
#                                 # An EMPTY list is a real declaration ("writes nothing"),
#                                 # which is not the same as omitting the field. Omitted
#                                 # means unknown, and unknown must never score as cheap.
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-1287` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-23T22:13:16Z
last_update: '2026-10-23T22:27:12Z'
date_finished:
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
  - ts: '2026-10-23T22:27:12Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1287: Quality engine 2: a standing 'what a person sees' gate on every corpus map at 1024/1440/1920 in the opening state, run before any review

## Context

This is step 2 of the quality engine (T-1285 GO); see spike 3 in `docs/reports/T-1285-quality-engine.md`. About 9 of 13
reviewer findings on T-1241/T-1282 (~70%) were mechanically decidable on the rendered map, yet each cost a review
round before it became a check (`_t1256`, `_t1276`, `_t1278`). This makes them ONE gate that runs BEFORE any
official review, so a reviewer confirms taste instead of discovering defects.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **One entry point, `tools/person-sees-gate.sh`**, runs, one browser at a time, every check of what a person
      sees, over every corpus map at 1024/1440/1920 in the real opening state (the lens-shot load path):
  - flow/arrowhead crossings and label overlaps (`_t1256`);
  - no ellipsized task names (`_t1276`);
  - minimum text size at opening, Name field not cut, contrast, reachability (`_t1278`);
  - Note box growth (`_t1274`);
  - toolbar reach (`_t1176`).
  A check that exists is called, not copied. A check class from spike 3 with no existing harness is added, or
  listed as a gap with the reason.
  _(done: 6 harnesses called, none copied (the five above + `_t1282`, which gained case 6: last card reachable and
  hover preview inside the window, at 1024/1440/1920, red on a mutant); gaps and reasons under "Spike-3 classes",
  including which legs measure one map rather than the corpus)_
- [x] **A clear verdict:** one summary line per check (PASS/FAIL with counts); exit 0 only when every check
      passes, 1 on any failure, 2 when a check could not run (never a silent pass). It finishes in a bounded time,
      measured and recorded here.
  _(done: 6 lines "PASS|FAIL|NOT RUN <check>: <counts> [Ns]"; current 6 PASS, exit 0, 347 s; 0.25.0 5 FAIL, exit 1,
  344 s; a 3 s timeout gives NOT RUN, exit 2; bound 900 s per check (PERSON_SEES_TIMEOUT))_
- [x] **It runs before every official UI review:**
  - CLAUDE.md's "UI changes are reviewed on screenshots" section says to run `tools/person-sees-gate.sh` and get exit
    0 before `fw reviewer judge`, and before the advisory sweep;
  - the learning from T-1278 (advisory sweep first) is kept;
  - the suite runs the gate as one leg (literal path), replacing the individual legs only where that is equal or
    stronger; the unwired-guard census stays balanced.
  **2026-10-24, met (orchestrator):**
  - the worker's proposed text is applied to CLAUDE.md's UI-review section: the gate is step 1, the advisory sweep
    step 2, and judge only after both;
  - the separate `_t1256` and `_t1282` suite legs are removed: the gate runs the same harnesses under a STRICTER rule
    (exit 0 and ok and no errors), so nothing is lost and they no longer run twice;
  - `_t1176` stays as an entry in the suite's CDP-regression table (~10 s);
  - census ratchet 90=90.
- [x] **Its teeth are proven:** run against `designer-v0.25.0`'s source (via the harnesses' source override), the
      gate FAILS and names the defects the T-1241 reviewers found (arrowheads, cut names, small text). On the current
      source it PASSES.
  _(done: 0.25.0: exit 1, label-clearance 22 (arrowhead `head` hits), name-fit 204 floor hits, sweep 385 (text 7 px,
  lane 6.3 px; 119 Name fields cut), note-box 102, project-browser 2; current: 6 PASS, exit 0. Outputs under "Gate
  evidence". The suite/census half of criterion 3 is done (1 leg, census 90=90); its CLAUDE.md half waits on the
  orchestrator applying "Proposed CLAUDE.md text", so criterion 3 stays unticked)_

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
         1. Run `bin/fw reviewer T-1287`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1287 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

<!--
  Render-touching build tasks (web/templates, web/static, web/blueprints, web/shared.py,
  web/app.py …) add a section headed "Visual Verification" (level-2 heading) after
  Verification, with one checklist table — the check-visual-verification gate reads it
  at commit time (T-4213; T-4202 GO):

    | state | control | 1024 | 1440 | 1920 | note |
    |-------|---------|------|------|------|------|
    | toolbar | Load | ok | ok | ok | |

  Cells: ok / clipped / hidden / overlap / unreachable (non-ok needs a note). Each
  listed state needs screenshots at every UX_SHOT_WIDTHS width:
  fw ux shots <T-ID> <state>=<URL>. This comment is inert: the gate ignores it.
-->

## Verification

bash -n tools/person-sees-gate.sh
node --check tools/_t1282-browse-entry-cdp.mjs
command grep -q 'bash "$ROOT/tools/person-sees-gate.sh"' tests/run-bridge-tests.sh
bash tools/person-sees-gate.sh
python3 tools/_t451-unwired-guard-census.py --ratchet

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
# Build/refactor/decommission tasks with NO command here are refused. If nothing can be
# run, add the line `# verification: none — <why nothing can be run>`; it is serviced
# (queued for review: add a check / other evidence / accept). See docs/reports/T-4024-servicing-loop.md.
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
#
# Vendored-path hint (T-3236, T-4419): if you edited bin/fw, lib/, agents/, policy/,
# web/, tools/ or .tasks/templates/, run `bin/fw vendor self` and add
#     bin/fw vendor self --check --task T-1287X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.

## Gate evidence (2026-10-24, w-t1287)

**What it calls.** `tools/person-sees-gate.sh` (orchestrator only: no measurement of its own) runs, in turn, at
`nice -n 19`, one browser at a time, each under `timeout` (`PERSON_SEES_TIMEOUT`, default 900 s; the timeout signals the
harness's whole process group, so no browser is orphaned): `_t1256` (label-clearance), `_t1276` (name-fit), `_t1278`
(sweep), `_t1274` (note-box), `_t1176` (toolbar-reach), `_t1282` (project-browser). `--src FILE` is passed through
each harness's own override (`T1256_SRC`, `T1276_SRC`, `T1278_SRC`, `T1274_SRC`, `T1176_DESIGNER`, `T1282_SRC`).
Verdict: an exception, missing input, no JSON report or a timeout are `NOT RUN` (exit 2, which wins over 1).

**Current source** (`src/aef-workflow-designer.html`), exit 0, total 347 s:
```
PASS label-clearance: 0 errors  [128s]
PASS name-fit: 0 errors  [59s]
PASS sweep: 0 errors  [104s]
PASS note-box: 0 errors  [29s]
PASS toolbar-reach: 21/21 steps  [10s]
PASS project-browser: 0 errors  [17s]
person-sees-gate: src/aef-workflow-designer.html: total 347s, exit 0
```
(An earlier run of the first five checks: 179/54/95/30/10 s. The bound is 6 × 900 s; observed time is about 6 minutes.)

**designer-v0.25.0** (`git show designer-v0.25.0:src/aef-workflow-designer.html` into a `mktemp -d` dir in the project,
removed after), exit 1, total 344 s. It names the T-1241 defects: **arrowheads** (`head "agt_3_start" x arrowhead of
tl_e3`), **cut names** (204 fit-ladder floor hits, e.g. `tl_verify "… ## Verification comman…"`; 119 Name fields cut),
**small text** (`smallest name text … drawn at 7px (< 9)`, lane text 6.3 px), plus nearness, helper contrast 2.84:1,
Note box cut and not growing, and no `?browse=1` (shipped after 0.25.0):
```
FAIL label-clearance: 22 errors (leg1 2, leg5 14, leg6 6)  [133s]
FAIL name-fit: 204 errors (leg1 204)  [51s]
FAIL sweep: 385 errors (leg1 42, leg3 119, leg4 8, leg5 216)  [91s]
FAIL note-box: 102 errors (leg1 96, leg2 6)  [28s]
PASS toolbar-reach: 21/21 steps  [9s]
FAIL project-browser: 2 errors (opens 1, pick 1)  [32s]
person-sees-gate: …/designer-v0.25.0.html: total 344s, exit 1
```
(Each FAIL line also prints up to 3 errors per leg; the lines above are the summary lines only.)

**Exit 2 proven:** `PERSON_SEES_TIMEOUT=3 … --only note-box` gives `NOT RUN note-box: timed out`, exit 2.

**New leg, and its teeth:** `_t1282` case 6 (spike-3 items "a card below the fold" and "hover preview inside the
viewport"). At 1024/1440/1920 the Open project browser's last card, once scrolled into view, is whole in the window and
in its scroll box and is the element at its centre. A real CDP mouse hover on a card shows the preview whole in the
window and clear of the browser panel. It must show at 1440/1920; at 1024 T-156's no-overlap rule hides it. On the
current source the preview is at [1094,155,1440,414] at 1440 and [1334,155,1694,422] at 1920; hidden at 1024. A mutant
that moves the preview 300 px right gives `FAIL project-browser: 2 errors (cards 2)` (out of the window at 1440 and 1920).
Caveat: with the 8 AEF projects, the last card's bottom (677) already lies inside a 900 px window, so "below the fold"
is measured as "reachable", not proven against a grid that must scroll.

**Suite:** `tests/run-bridge-tests.sh` has ONE leg, `bash "$ROOT/tools/person-sees-gate.sh"`. It replaces the
T-1274/T-1276/T-1278 loop: same harnesses, same exit-0 rule, plus a timeout and NOT RUN ≠ pass, so it is equal or
stronger. The individual `_t1256`, `_t1282` legs and the `_t1176` T1013 guard entry are kept (out of this brief's
scope), so those three run twice per suite run (~155 s extra); a follow-up can drop them. `_t527` capture invariant: OK
(206 if-guards). Census `--ratchet`: baseline 90, current 90 (the gate's literal paths keep _t1274/6/8 live).

### Spike-3 classes: covered and gaps
Covered: label nearness, captions on arrowheads (`_t1256`); ellipsized names (`_t1276`); text size at opening, Name
field clipped, helper and caption contrast, canvas/palette reachability (`_t1278`); hover preview inside the viewport
and the last card reachable (`_t1282` case 6, new). Gaps, with the reason:
- **Watchtower's own `/designer` card page** (hover fly-out, a card below the fold there): it is AEF's page, served by
  AEF; `tools/_t1171-landing-flyout-test.py` checks its structure, not its rendered geometry. Not added: no 832 render
  harness drives that page; it belongs with the AEF host contract (T-1289).
- **Whether a thumbnail is "too small"**, **business-palette wording**: judgement (spike 3), so they stay with the
  reviewer. `_t1278` leg 4 checks only the mechanical part (no BPMN type words).
- **Map-content wording**: not designer scope.
- **Gate is lifecycle-heavy in places:** `_t1274`, `_t1278` legs 1/2 and `_t1176` measure one map, not the whole corpus;
  the corpus-wide legs are `_t1256` 2/6/7, `_t1276` 1 and `_t1278` 3. Widening them is a harness change, not done here.

## Proposed CLAUDE.md text

For the orchestrator to apply (this worker did not edit CLAUDE.md). Replace the numbered list under "### UI changes are
reviewed on screenshots, by you AND an independent review agent (operator, 2026-10-14)" with:

```
For every change that renders (designer `src/`, Watchtower templates/CSS, anything a person sees):
1. **The "what a person sees" gate first** (T-1287): `bash tools/person-sees-gate.sh` must exit 0 before any
   screenshot goes to a reviewer. It runs the render harnesses (crossings incl. arrowheads, cut names, text size,
   Name field, contrast, reachability, Note box, toolbar, project browser) over the corpus at 1024/1440/1920 in the
   opening state, about 6 minutes. Exit 1 = a defect a machine can find: fix it, do not send it to review. Exit 2 =
   a check did not run, so there is no verdict (never read it as a pass). A designer change the gate cannot see
   gets a leg in the harness that owns its class, or a line in the gate.
2. **Then the advisory sweep** (T-1278's learning: sweep before the official review). A cheap independent read of
   the screenshots finds what the gate does not measure, before an official round is spent on it.
3. **Screenshots of every state the change touches** (hover, open/closed, fullscreen, empty/full) **at three
   widths at least**: narrow (~1024), normal (~1440), wide (~1920), plus the operator's screen if known.
4. **Read each one control by control**: every button, menu and field visible, reachable and unclipped; nothing
   overlapping or off-screen; the space used well. Write what was checked per screenshot in the task's
   `## Visual Verification`. A screenshot looked at "for the layout" is not a review.
5. **An independent review agent judges them before close**: a `[REVIEW]` criterion listing the screenshot paths
   and what to check, judged by `fw reviewer judge T-XXX --criterion N` (AEF routing, PD-357), and only after
   steps 1 and 2. The task does not close on the author's own look alone, nor on a red or unrun gate.
```

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
     fw inception decide T-1287 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-23T22:13:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1287-quality-engine-2-a-standing-what-a-perso.md
- **Context:** Initial task creation

### 2026-10-23T22:27:10Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
