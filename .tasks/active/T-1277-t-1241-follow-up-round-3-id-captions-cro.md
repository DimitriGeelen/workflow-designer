---
id: T-1277
name: "T-1241 follow-up round 3: id captions crossed by bottom-centre flows in the
  lens-shot state (agt_3_start, agt_6_completion)"
description: >
  Codex amber on T-1241 AC1 at 6d03c1b9 (judge-t-1241-r5-codex-3833c9b619ce): in t1241-{technical,all}-1920-panel.png
  the upward flows cross the id captions agt_3_start and agt_6_completion. The same
  crossing is in the 1440 shots BEFORE T-1276; 1920 now shows it because it opens
  at the T-1256 readable zoom (78%). clearLabelsOfFlows (T-1256) measures with getBBox,
  so the cause is a state difference the T-1256 harness does not exercise. Root-cause,
  fix, and make the harness count crossings in the lens-shot state.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: [designer, ui, T-1241]
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
#                                 # `fw work-on T-1277` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-22T20:30:31Z
last_update: '2026-10-22T20:30:41Z'
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
  - ts: '2026-10-22T20:30:41Z'
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

# T-1277: T-1241 follow-up round 3: id captions crossed by bottom-centre flows in the lens-shot state (agt_3_start, agt_6_completion)

## Context

This is the third follow-up from T-1241's AC1 review, after T-1274 and T-1276.
- **The amber:** the claude-code seat judged green and codex amber at 6d03c1b9
  (`.context/reviews/evidence/T-1241/AC1-judge-t-1241-r5-codex-3833c9b619ce.md`). In
  `docs/reports/T-1241-evidence/t1241-{technical,all}-1920-panel.png`, the upward flows into "start work" and
  "completion gates" run through the id captions `agt_3_start` and `agt_6_completion`.
- **Found in the orchestrator's review:**
  - The 1440 shots from **before** T-1276 (`git show 6d03c1b9~1:…/t1241-technical-1440-panel.png`) have the same
    crossing.
  - The previous 1920 shot did not: it opened at fit, and there the T-1256 pass had moved both captions clear.
  - 1920 now opens at the T-1256 readable zoom (78%, because T-1276's 9px names lowered the smallest name size).
  - Node positions differ between the 1440 and 1920 shots.
  - `clearLabelsOfFlows()` measures with `getBBox` (SVG units), so zoom alone cannot change its choice. The cause is a
    difference in rendered state between the lens-shot path (adopt, openingZoom, lens switch) and what the T-1256
    harness measures, which reported crossings 134→1.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Root cause** is stated in `## RCA` with the evidence: which state differs, and why the pass leaves these
      captions crossed, or never runs, there.
      **Evidence:** no state differs. The pass runs and its choice is the same at every width. The pass and the
      harness both ignore the arrowheads: the captions stood against the 12-unit head of the flow into their own task,
      with a gap of 0.00 units. Three hypotheses, one test each, are in `## RCA`.
- [x] **Fix:** in the lens-shot state, no id caption or gateway/event name is crossed by a drawn flow on
      `aef-task-lifecycle`, in all four lenses, at 1024, 1440 and 1920 (ids on). Corpus totals are not higher than
      today in that state. Saved bytes are unchanged on every corpus map.
      **Evidence (2026-10-22):** `clearLabelsOfFlows()` now counts each drawn arrowhead (`#arrow` end, `#arrow-source`
      start, bounding box + 1 unit, unselected stroke) as an obstacle at the same cost as a segment (10, hard). It is
      render-only and deterministic, and a move is still kept only when strictly better. `_t1256` leg 5 'shot' (the
      lens-shot load) at 1024/1440/1920, the 'link' run at 1440/1920 and the Playwright 'shell' run at 1440/1920, all
      lenses × ids on/off: gwFlow = idFlow = head = elFlow = ll = clip = near = 0. The three captions now stand above
      their rects. Corpus in the lens-shot state (leg 7, 24 maps × 3 widths, lens all, ids on): **72 → 0** against
      6d03c1b9. Leg 2 corpus (gwFlow+idFlow, 1920, vs 0.24.0): 134→**0** (was 134→1). Bytes: leg 3 25/25 unchanged;
      leg 7 reports no changed map at any width.
- [x] **Harness:** the T-1256 harness (or a new leg) measures crossings in the **lens-shot state**, the same load path
      as `tools/_t1241-lens-shots.py`. It is red on 6d03c1b9 for the two named captions and green after.
      **Evidence:** `_t1256` measures `head` (a name or caption on an arrowhead) in legs 1 and 5, and leg 5's lens-shot
      run now covers 1024 too. The new leg 7 opens every corpus map the way the shot tool does. On 6d03c1b9
      (`git show` into a mktemp dir, removed after; `T1256_SRC=… T1256_ONLY=leg5`): exit 1 with 14 leg-5 errors, each
      `head "agt_3_start" x arrowhead of tl_e16; head "agt_4_do" x arrowhead of tl_e3; head "agt_6_completion" x
      arrowhead of tl_e20` (technical/all, link 1440/1920, shot 1024/1440/1920, shell 1440/1920). On this source the
      full run exits 0, all legs green.
- [x] **No guard regresses:** the T-1274 guards plus `_t1274-note-box` and `_t1276-name-fit` stay green, run one at a
      time under nice 19.
      **Evidence:** one at a time under `nice -n 19`, every one exit 0, no reruns: `_t600 --self-test`,
      `_t601 --self-test`, `_t1068 --self-test`, `_t1067` 6/6, `_t1078` 8 legs, `_t1241-business-lens`, `_t1176`,
      `_t1249-v11-io`, `_editor-behavior-verify`, `_t1091` 31/31, `_endpoint-overlap-verify`, `_t1274-note-box`,
      `_t1276-name-fit`, and `_t1256` (all legs; 1024 min text 7.02px). After them only a comment line in the source
      changed.
- [x] **Shots:**
  - re-shoot all 48 T-1241 lens shots;
  - make 2x crops of both captions in the technical and all lenses at 1440 and 1920 into
    `docs/reports/T-1277-evidence/`;
  - fill the `## Visual Verification` table;
  - the orchestrator then reruns `fw reviewer judge T-1241 --criterion 1`.
  **2026-10-23, met:** instead of an official rerun right after this round, a codex ADVISORY sweep read all 48 shots
  (no crossings left; the other items went to T-1278). The official rerun at fc2c7339 was green on all three seats,
  applied as V-20261022-73c28dd4.

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
         1. Run `bin/fw reviewer T-1277`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1277 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#     bin/fw vendor self --check --task T-1277X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
node tools/_t1256-label-clearance-cdp.mjs > /tmp/.t1277-1256.out 2>&1 && grep -q '"ok": true' /tmp/.t1277-1256.out
node tools/_t1276-name-fit-cdp.mjs > /tmp/.t1277-1276.out 2>&1
node tools/_t1274-note-box-cdp.mjs > /tmp/.t1277-1274.out 2>&1
test -s docs/reports/T-1277-evidence/caption-agt3-start-2x-technical-1920.png && test -s docs/reports/T-1277-evidence/caption-agt6-completion-2x-all-1440.png

## Visual Verification

Shots: all 48 T-1241 lens shots re-shot on this source (`tools/_t1241-lens-shots.py`, 12/12 lens-select ok). True 2x
crops (device_scale_factor 2, the lens-shot load: adopt, renderAll, openingZoom, lens, `tl_create` selected; temp
script outside the repo) in `docs/reports/T-1277-evidence/`:
`caption-{agt3-start,agt6-completion,agt4-do}-2x-{technical,all}-{1440,1920}.png` (12). At 1440 the canvas was
scrolled to bring `agt_6_completion` into view, so the 1440 `agt4-do` crop shows the same scrolled view.

What was checked across the 48 shots, looking for ANY flow on a name or caption, not only the two named ones:
- **panel ×12:** the map area was cropped at native resolution and read node by node. Captions: `agt_start_work`,
  `agt_1_create`, `agt_gw_ready`, `agt_3_start`, `agt_4_do`, `agt_gw_issues`, `agt_6_completion`, `agt_gw_gates`,
  `agt_gw_unchecked`, `agt_7_archive`, `agt_end_task`, `agt_2_parked`, `agt_link_handoff`, `agt_5_healing`,
  `hum_1_partial`. Gateway/event names: "work identified", "ready to start now?", "issues encountered?",
  "gates pass?", "unchecked Human ACs?", "task archived", "Handoff → dispatch loop". **None is crossed by a line or
  touched by an arrowhead** in any lens or width.
- **panel-bottom ×12:** the canvas region is pixel-identical to its panel shot (ImageChops difference = none in all 12),
  so the reading above holds for it.
- **details / details-bottom ×24:** the details dialog covers and dims the canvas. No map text can be read, so there
  is nothing to cross. Read as contact sheets.
- **Not a crossing, noted:** at 1024 the "Handoff → dispatch loop" name runs under the side-panel edge (the canvas
  scrolls), as in T-1276's shots.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| canvas, technical/all | `agt_3_start` caption ("start work") | ok | ok | ok | 2x crops: above the rect, centred; the upward flow `tl_e16` and its head end at the rect bottom with nothing beside them. 1024: panel shot (above the rect) and harness leg 5 shot@1024 head 0 |
| canvas, technical/all | `agt_6_completion` caption ("completion gates") | ok | ok | ok | 2x crops: above the rect, clear of the "blocked —" flow above and of the `tl_e20` head below. 1024: off the opening view; leg 5 shot@1024 head/idFlow 0 |
| canvas, technical/all | `agt_4_do` caption ("do the work") | ok | ok | ok | was on the head of `tl_e3` (found by the new leg); now above the rect, clear of the head and the incoming "now" flow |
| canvas, technical/all | other id captions (12, listed above) | ok | ok | ok | panel shots: each under or above its shape, none on a line or head |
| canvas, every lens | gateway/event names (7, listed above) | ok | ok | ok | panel shots: none crossed. 1024: "Handoff → dispatch loop" runs under the side-panel edge (scroll, not a crossing) |
| details, every lens | details dialog over the canvas | ok | ok | ok | canvas covered and dimmed, nothing readable to cross |

Review of these screenshots by an independent agent: the orchestrator reruns `fw reviewer judge T-1241 --criterion 1`
(criterion 5).

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
**Symptom:** in the T-1241 lens shots (technical/all), `agt_3_start` and `agt_6_completion` sit on the upward flows
into "start work" and "completion gates". The T-1256 harness reported 0 crossings for the lifecycle map in every lens.

**Hypotheses, one test each:**
1. *The lens-shot load path (adopt → renderAll → openingZoom → setLens → select) leaves a state the pass did not
   finish, or a later re-render undoes it.* Test: replay that exact path in Playwright at 1024/1440/1920 (technical,
   all) and run the harness's own `__t1256measure` right after the load and again 400 ms later (when the shot is taken).
   **Disproved:** idFlow = gwFlow = 0 in all 12 runs, both times; the pass had run (the caption stood at its
   `[cx + 6, below, 'start']` candidate, not at its default).
2. *Node positions or the pass's choice differ by viewport.* Test: dump `state.nodes` x/y and the caption attributes at
   the three widths. **Disproved:** identical (`tl_start@420,114.5`, `tl_verify@965,114.5`; `agt_3_start` x=481 at
   every width). What changes with width is only scroll and zoom, so the same crossing is in every width's shot. Why
   the old 1920 shot was clean: on 6d03c1b9~1 the same probe gives `agt_3_start` x=481 'start' (the crossed place) at
   1440 (78%), but x=534 y=139.5 (beside the shape) at 1920, where that source opened at fit; `agt_6_completion` is
   above its rect there. So the clear 1920 shot was a different candidate winning at fit, clear of the head by luck.
   I did not trace which obstacle tipped it (likely sub-unit text-box differences at another scale); it does not
   matter for the fix, because the arrowhead was invisible to the cost at every width.
3. *The pass and the harness model a flow as a zero-width polyline, and the arrowhead is not part of it.* Test: a 2x
   crop of the 1920 technical shot, plus the arrowhead boxes computed from the markers (`#arrow`: markerWidth 8 ×
   stroke 1.5 = 12 units, refX 9, so the head runs 10.8 units back from the end and 6 units to each side;
   `#arrow-source`: 7.5 units) against the caption boxes. **Confirmed:** the flow `tl_e16` ends on the bottom of
   "start work" at x=475; the pass put `agt_3_start` at x=481 (cx + 6, 'start'), 6 units right of the line, which its
   segment test (Liang-Barsky on the `d` points, label padded by 1) scores as clear. The head's base spans 469..481 and
   y 177.3..189.3; the caption spans x 481.. and y 181.5..193. Gap 0.00, so the base of the head touches the "a"
   (visible in the 2x crop). Same for `agt_6_completion` on `tl_e20` (gap 0.00). The same blind spot hides a third
   one: `agt_4_do` sat on the head of `tl_e3` (beside-the-shape place, `end` anchor 4 units left of the rect, where
   the 10.8-unit head arrives).

**Root cause:** `clearLabelsOfFlows()` (T-1256) and `__t1256measure` both build their obstacles from the `d` of each
`path.edge-path`, so the drawn arrowheads (markers) were never an obstacle. A caption 6 units from a flow's axis is
"clear" to both while the head of the flow arriving at its own node covers it. It is not a lens-shot state difference.
The harness's leg 5 already replays the lens-shot path ('shot' and 'shell' runs) and was right about the segments.

**Why structurally allowed:** both the product and its check used the same geometry model (the line only), so the
check could not see what the model leaves out. Every T-1256/T-1274 leg counts segments.

**Prevention:** the harness now counts `head` (a gateway/event name or id caption on an arrowhead, raw text box against
the head box + 1 unit) in legs 1 and 5. Leg 5 also measures the lens-shot load at 1024. A new leg 7 opens every corpus
map in the lens-shot state at 1024/1440/1920 (lens all, ids on) and fails if any map or the total rises over 6d03c1b9,
or if the saved bytes change. On 6d03c1b9, leg 5 is red with `head "agt_3_start" x arrowhead of tl_e16`,
`head "agt_6_completion" x arrowhead of tl_e20` (and `agt_4_do` × `tl_e3`) in technical/all at 1024, 1440 and 1920.

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
     fw inception decide T-1277 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-22T20:30:31Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1277-t-1241-follow-up-round-3-id-captions-cro.md
- **Context:** Initial task creation

### 2026-10-22T20:30:40Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
