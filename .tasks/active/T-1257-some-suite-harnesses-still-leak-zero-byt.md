---
id: T-1257
name: "Some suite harnesses still leak zero-byte /tmp/.org.chromium.Chromium.* shm
  files (89 during one suite run; dimitri-mint-dev T-115)"
description: >
  dimitri-mint-dev counts 16,359 zero-byte .org.chromium.Chromium.* files in /tmp,
  ~4,600-6,200/day since 2026-10-19. Measured 2026-10-21: _t1243 alone leaves 0, and
  0 when SIGTERMed mid-run (T-1247 helper); but 89 appeared 21:31-21:38 during a full
  bridge suite run, and ~1 per 6-12 min while a worker runs harnesses. Find which
  harnesses leak them (count per harness), make them stop (graceful Chrome shutdown
  before SIGKILL, or the helper's cleanup, or Playwright scripts), add a suite check
  that counts new shm files across the run. dimitri-mint-dev's T-115 stays open until
  the rate is zero.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-1247]
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
#                                 # `fw work-on T-1257` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-21T21:13:51Z
last_update: 2026-11-13T19:54:38Z
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
  - ts: '2026-11-11T16:55:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 3
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref); D2=0 (no-signal); D3=3 (body:component-discoverability);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1257: Some suite harnesses still leak zero-byte /tmp/.org.chromium.Chromium.* shm files (89 during one suite run; dimitri-mint-dev T-115)

## Context

**Background / trigger:** dimitri-mint-dev T-115 counted thousands of `.org.chromium.Chromium.*` files in /tmp
(2026-10-21: 89 appeared during one suite run). On 2026-11-11 /tmp (a 32 GB tmpfs) filled up and stopped release job 128;
3,509 such files (326 MB, mostly 256 KB each, not zero-byte) were in /tmp, dated 2026-11-08..11.

**Problem / hypothesis:** headless Chromium with `--disable-dev-shm-usage` puts its shared-memory files in TMPDIR. A
launcher that runs Chromium with TMPDIR=/tmp and kills it hard leaves them. Which launcher?

**Goal:** find the launcher that leaves them, fix it, and remove what is ours.

**Expected outcome:** a run of every 832 path that launches Chromium leaves no file in /tmp.

### Measured 2026-11-11 (agent)
- `_t1392-settings-reach`, `_t1134`, `_t1126` run directly (TMPDIR=/tmp): +0 each.
- `bash tools/person-sees-gate.sh` (all its render harnesses, outside the suite): +0.
- `_editor-behavior-verify-cdp.mjs` run directly 7 times (incl. 12 busy loops alongside): +0.
- The suite and the task close keep Chromium's files in their own TMPDIR (T-1183, T-4846) and remove it.
- From 16:37Z to 16:55Z no new file appeared at all (so other projects did not create any in that window either).
- The files cluster by hour where our pipelines ran: 00h, 09-12h, 15h local on 2026-11-11. Not yet measured: the
  review/sweep WORKER seats (`fw termlink dispatch`, `fw reviewer judge`: codex, claude-code, opencode), which open
  the screenshots and may start a browser outside any of our TMPDIRs. That is the next hypothesis.
- Not removed: the files are root's and cannot yet be shown to be ours.

### Measured 2026-11-12 (agent)
- `/tmp` holds TWO kinds of Chromium leftover, not one:
  1. `.org.chromium.Chromium.*` (dotted): 4,935 FILES (4,087 of 256 KB, 845 empty; about 1 GB), up from 3,509 the day
     before, 947 of them in the last 8 hours, clustered 15-19h local when our closes and release 0.42.0 ran browser
     tiers (and other projects were busy too: load 40-90).
  2. `org.chromium.Chromium.*` (no dot): 2,087 empty DIRECTORIES.
- `TMPDIR=$(mktemp -d /tmp/t1257.XXXX) node tools/_t1395-cdp-client-selftest.mjs` (3 Chrome launches): PASS, and after
  exit the TMPDIR holds 3 `org.chromium.Chromium.*` directories (one per launch) and NO dotted file. So kind 2 is ours
  (every launch from a harness leaves one; at least partly the 2,087); kind 1 is still not shown to be ours.
- A long TMPDIR (the agent's scratchpad path) makes Chrome fail to start ("no devtools port"): the SingletonSocket
  path passes the ~107-byte limit (the T-1390 class). Any fix that gives Chrome its own temp dir must keep it short.
- Fix direction for kind 2: give Chrome a private short TMPDIR inside the profile dir `_cdp-profile.mjs` already
  removes on exit. Each harness spawns Chrome itself, so it reaches them the way T-1395's sweep did.
- Kind 1: the next step is finding the writing process (the dispatch seats remain the hypothesis). Nothing removed;
  removal only with the operator's approval and only of files shown to be ours.

### 2026-11-13 (agent)
- Kind 2 is done: T-1404 (closed) makes the profile helper remove each launch's dir; the operator's job 135 removed
  1,942 stale ones (rules: name, > 24 h, singleton-only or empty, socket not listened on; 0 skipped), leaving 145
  (newer, or holding other content such as Chrome component downloads).
- Kind 1 (dotted files): 3,245 now, down from 4,935 the day before, so something removes them too. A harness run with the
  default TMPDIR added 0 (third measurement), while T-1404's browser tier ran Chrome at the same time. Newest file
  2026-11-12 23:42:43 UTC; no process holds any of the 20 newest. By 10-minute bucket (local time, +0100): 22 files at
  21:4x and 23 at 00:3x-00:4x, both overlapping core-tier runs (T-1402's close; the two pre-push gate runs), but a core
  run at 22:12 local left only 1, so this is a correlation to test, not a finding. Hypothesis: core's namespace hides
  the Playwright Chromium but not /opt/google/chrome, so a leg that falls back to it would write outside the private
  TMPDIR. Test: count around one isolated core run.

### 2026-11-13 evening (agent): the core-run hypothesis tested against this session's own runs
New dotted files per window (file mtimes, CET), against what this project ran (commit and runs-log times):
| window (CET) | ours running | new dotted files |
|---|---|---|
| 18:02-18:27 | browser tier, local (T-1409 real run) | 14 |
| 18:28-18:47 | core tier, local (first T-1409 push) | 48 |
| 18:50-19:09 | core tier, local (T-1410 push) | **0** |
| 19:11-20:15 | nothing that starts Chrome (idle, then task-file edits) | **159** |
An isolated core run left 0, and 159 appeared in an hour with no Chrome of ours. The core-fallback hypothesis is
weakened; most kind-1 files are written by something else on the machine (load 44 at 19:25Z). Next: a read-only
watcher (every 2 s, new dotted file -> holder pid, cwd, cgroup, ancestry) for 20 min, to name the writer.
- Watcher result, 19:33:53-19:53:53Z (4,232 existing): **0 new files**, so nothing to attribute. (A first attempt
  used `ls -1`, which hides dotfiles, and measured nothing; re-run with `ls -1A`, which sees all 4,232.) The writer
  works in bursts (03-04h, 09-11h, 13h, 17-20h CET today). Next: run the watcher across a whole burst window (hours,
  not 20 min), e.g. during the next busy period of other projects, and attribute the first new files it catches.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The launcher that leaves `.org.chromium.Chromium.*` in /tmp is identified by measurement (a run with a count
  before and after), or every 832 launcher is shown to leave none and the source is named outside 832.
- [ ] If it is ours, it is fixed (Chromium's TMPDIR contained and removed) and a run leaves +0; the existing files that
  are ours are removed with the operator's approval.

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
         1. Run `bin/fw reviewer T-1257`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1257 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#     bin/fw vendor self --check --task T-1257X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.

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
     fw inception decide T-1257 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-21T21:13:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1257-some-suite-harnesses-still-leak-zero-byt.md
- **Context:** Initial task creation

### 2026-11-11T16:55:49Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
