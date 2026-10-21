---
id: T-1256
name: "Gateway labels collide with flows and id captions on aef-task-lifecycle (pre-existing
  in 0.24.0; found by the T-1241 reviewer)"
description: >
  With id captions on, gateway labels beside the diamonds collide: 'issues encountered?'
  crossed by its incoming flow, 'unchecked Human ACs?' runs into the 'pass' flow label,
  the arrow into 'completion gates' runs through its id caption agt_6_completion;
  and with ids off, the vertical flow to the human lane crosses 'unchecked Human ACs?'.
  Pixel-identical in designer-v0.24.0 (evidence: docs/reports/T-1241-evidence/overlap-0.24.0-1920.png,
  overlap-now-1920.png, overlap-0.24.0-noids-1920.png, overlap-now-business-1920.png).
  Found by the independent reviewer of T-1241 (amber, 2026-10-21).

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-1241]
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
#                                 # `fw work-on T-1256` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-21T20:23:36Z
last_update: 2026-10-21T20:30:47Z
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
  - ts: '2026-10-21T20:29:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 0
      F1: 0
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=0 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1256: Gateway labels collide with flows and id captions on aef-task-lifecycle (pre-existing in 0.24.0; found by the T-1241 reviewer)

## Context

The T-1241 reviewer (codex seat, red, `.context/reviews/evidence/T-1241/AC1-judge-t-1241-r5-codex-75cb0e15cc62.md`) saw
flows cross gateway labels and the `agt_6_completion` caption on aef-task-lifecycle, and fitted text at 1024 too small
to read. Pixel-identical in designer-v0.24.0. The operator chose to fix it before releasing 0.25.0.

**Cause** (all in `src/aef-workflow-designer.html`):
- `adjustLabelPlacements()` (:4559), the only pass that moves a gateway/event name off a flow, skips every block of one
  line: `if (els.length < 2) continue;` (:4671). It was written for the name+id pair, so with id captions off (and
  in the Business lens, which hides ids) a single-line name like "issues encountered?" or "unchecked Human ACs?"
  never moves, whatever crosses it.
- Its side places stack the block centred on the shape's cy (:4686, `RIGHT()` :4697). A gateway's own E/W flows
  leave at cy, so the right/left candidates are crossed by construction, and the score (:4664) weighs a crossed flow
  at 1 against 3 for leaving the own lane, so a crossed place is often kept as "best".
- A task's id caption is placed centred under the box (:4267) and dodges only a flow on its OWN bottom centre
  (T-1090 `bottomFlow`); a flow arriving elsewhere (the arrow into "completion gates" through `agt_6_completion`,
  three flows through `agt_4_do`) is never looked at.
- The scorers read `e._renderedPolyline`, which `routePathFromPoints` stashes only for flows without manual
  waypoints, so a manually routed flow is invisible to them (not the case on this map, but the same blindness).
- Text size at 1024: fit scales the whole map into a 484px canvas (both side panels open), 0.243x; 11px names render
  at 2.7px (5.0px at 1440, 7.6px at 1920).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Cause named: where a gateway's label and a node's id caption are placed, and why that placement ignores the flows
  drawn next to them (with file:line).
- [x] On `aef-task-lifecycle` at 1920, in every lens and with id captions on and off: 0 gateway labels crossed by a
  flow segment, 0 id captions crossed by a flow, 0 label/label overlaps (the four cases in the reviewer's notes are
  among them). Measured by a CDP harness from the rendered SVG geometry (text bbox vs flow polylines), not by eye.
- [x] Across every map in `examples/aef-processes/rendered/`: the count of label/flow and caption/flow crossings does
  not rise for any map, and falls in total (reported per map before/after).
- [x] Saved bytes: if label placement is not written to the map, 0 bytes change on any tracked map; if it is (BPMN DI
  label bounds), the change is stated and shown, and the goldens are updated only for that reason.
- [x] Readable at 1024: fit zoom on `aef-task-lifecycle` at 1024 leaves node and gateway text at a stated minimum
  rendered size (or the map opens at a readable zoom with the rest reachable by scroll), without hiding any element.
- [ ] Screenshots of every lens at 1024/1440/1920, plus scrolled side-panel and details shots that show the lowest
  controls reachable, read control by control; the independent reviewer judges T-1241's criterion 1 again after this.
- [ ] Harness as a bridge leg, red on the 0.24.0 placement; `_t1241`, `_t1176`, `_t1249` still pass; full suite green.

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
         1. Run `bin/fw reviewer T-1256`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1256 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#     bin/fw vendor self --check --task T-1256X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.

node tools/_t1256-label-clearance-cdp.mjs > /tmp/.t1256.out 2>&1 && head -2 /tmp/.t1256.out | grep -q '"ok": true'
node tools/_t1241-business-lens-cdp.mjs > /tmp/.t1241.out 2>&1 && head -2 /tmp/.t1241.out | grep -q '"ok": true'
node tools/_t1176-toolbar-reach-cdp.mjs > /tmp/.t1176.out 2>&1
node tools/_t1249-v11-io-cdp.mjs > /tmp/.t1249.out 2>&1
node tools/_t600-label-wrap.mjs --self-test > /tmp/.t600.out 2>&1
node tools/_t601-lane-boundary.mjs --self-test > /tmp/.t601.out 2>&1
node tools/_t1068-corpus-labels.mjs --self-test > /tmp/.t1068.out 2>&1
grep -q '_t1256-label-clearance-cdp.mjs' tests/run-bridge-tests.sh

## Visual Verification

Shots: `docs/reports/T-1256-evidence/` (`tools/_t1256-shots.py`: aef-task-lifecycle opened by `?load=`, canvas element,
Clean-layout nudge dismissed with its ✕; `before-*` = designer-v0.24.0, `after-*` = this source; ids / noids = lens All
with id captions on/off; business = Business lens) and
`docs/reports/T-1241-evidence/t1241-{business,logical,technical,all}-{1024,1440,1920}-{panel,panel-bottom,details,details-bottom}.png`
(`tools/_t1241-lens-shots.py`, 48 shots, the map opened with `openingZoom()` as a person gets it). Read control by control.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| canvas before (0.24.0) | gateway names, id captions | overlap | overlap | overlap | before-1920-noids: "ready to start now?", "issues encountered?", "unchecked Human ACs?" each crossed by a flow; before-1920-ids: `agt_6_completion`, `agt_4_do` on arrows; before-1024: names 2.7px, unreadable |
| canvas after, ids on | gateway names, id captions | ok | ok | ok | after-1920-ids: "issues encountered?" right-below its diamond, "unchecked Human ACs?" left-above, `agt_6_completion` above its box clear of the arrow; no caption on a flow |
| canvas after, ids off | gateway names | ok | ok | ok | after-1920-noids: "ready to start now?" above, "issues encountered?" left-below, "unchecked Human ACs?" above its diamond; no line through any name |
| canvas after, Business | gateway names | ok | ok | ok | after-1920-business, t1241-business-*-panel: same places as ids off; no id captions |
| canvas at open | zoom readout, text size, reach | ok | ok | ok | 1024 and 1440 open at 70% (names ≥ 7px), 1920 at fit (7.6px); after-1024-*-scrolled-mid/end: every node reached by scroll, lane names pinned (T-1091); Fit still fits |
| canvas | flow labels | ok | ok | ok | "yes — status: issues" / "shelved — …" touch a flow in some lenses exactly as in 0.24.0 (placed by the unchanged `adjustEdgeLabelPlacements`); harness: no flow label moved onto a line, corpus 0→0 |
| toolbar | every control (lens select, zoom −/readout/+, Fit, panels, fullscreen, Add Lane … Save) | ok | ok | ok | two rows at 1024 and 1440, one at 1920; none clipped |
| side panel | top (type header, All details, BPMN fields) | ok | ok | ok | t1241-*-panel |
| side panel | bottom (Owner, Other extensions, + add input, + add output) | ok | ok | ok | t1241-*-panel-bottom: scrolled to the end, "+ add output" fully visible (Business has no I/O section and does not scroll) |
| details view | header, Close | ok | ok | ok | t1241-*-details |
| details view | bottom (Note, Owner, Other extensions, I/O contract, + add input / output) | ok | ok | ok | t1241-*-details-bottom: scrolled to the end inside the sheet, Close still in its header |

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

**Symptom:** on aef-task-lifecycle, flows run through "issues encountered?", "unchecked Human ACs?", "ready to start
now?" and the `agt_6_completion` caption, in every lens; at 1024 the fitted map's text is 2.7px.
**Root cause:** see Context: the one placement pass skips single-line names, centres side places on the gateway's own
flow axis and prefers a crossed place to leaving the lane; task captions dodge only their own bottom-centre flow.
**Why structurally allowed:** the label guards (T-600/T-601/T-1068) measure labels against shapes, lanes and the header
strip; none counted a flow segment through a label, and none ran with id captions off.
**Prevention:** `tools/_t1256-label-clearance-cdp.mjs` as a bridge leg, measured from the rendered SVG: lifecycle 0 in
all 8 lens/id configurations, no corpus map worse than 0.24.0, no flow label pushed onto a line, bytes unchanged, 1024
opens at ≥ 7px.

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

### 2026-10-21 — where the fix lives
- **Chose:** a new last pass, `clearLabelsOfFlows()`, after the flow labels are placed. It moves ONLY a name block or
  id caption that a drawn flow segment (read off each `.edge-path`'s `d`, so manual routes count) or another label
  crosses, to the cheapest of 12 fixed places (below / beside a vertical flow / beside the shape above or below its own
  flow axis / above), the name also as one line or two, never on the lane header; kept only when strictly better. Then
  one more `adjustEdgeLabelPlacements()` for a flow label still on a line (strictly better only).
- **Why:** deterministic and local; an uncontested map is untouched; flow labels keep their 0.24.0 places. Corpus (lens
  All, ids on+off): crossings 134 → 1, label/label 20 → 0, no map worse; lifecycle 0 in every lens.
- **Rejected:** retuning `adjustLabelPlacements()`'s weights (three guards pin it, the weights encode lane semantics);
  moving nodes or rerouting flows (out of scope, changes bytes).
- **Guards adapted:** the T-600 and T-1068 self-test poison arms also switch the new pass off; otherwise it repairs the
  poisoned placement and the self-test reports "asserts nothing". Live legs unchanged.

### 2026-10-21 — readable at 1024: minimum opening zoom, 7px
- **Chose:** `openingZoom()`: a map that is opened (deep link, Load, project/version open, autosave restore) and whose fit
  would draw its smallest node/gateway name below `OPEN_MIN_TEXT_PX` = 7px opens at the zoom that draws it at 7px,
  scrolled to the top-left; Fit still fits the whole map; a zoom the person chose is never overridden.
- **Why:** measured fit sizes on this map: 2.7px at 1024, 5.0px at 1440, 7.6px at 1920. Both T-1241 reviewers read the
  1920 shots; the codex reviewer called 1024 unreadable. So the floor sits just under what was read. Result: 1024 and
  1440 open at 70%, 1920 unchanged (fit).
- **Rejected:** leaving fit as is (fails the criterion); a floor on Fit itself (the overview the button promises would be
  gone); hiding panels or elements (the criterion forbids hiding).
- **Consequence:** harnesses whose premise was "a large map opens at fit" now press Fit first (`_editor-behavior-verify`
  legs 9/10, `_t1091`, `_t249` spike); assertions unchanged. AEF's embed opens a large map zoomed in the same way; the
  0.25.0 release note to AEF must say so.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1256 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-21T20:23:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1256-gateway-labels-collide-with-flows-and-id.md
- **Context:** Initial task creation

### 2026-10-21T20:29:49Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
