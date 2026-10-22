---
id: T-1278
name: "T-1241 follow-up round 4: fix the codex advisory sweep list (readable minimum
  9px, Name field grows, business-lens palette wording, reachability evidence)"
description: >
  Codex advisory sweep of all 48 T-1241 shots at 2015e17e: 10 blocking, 1 cosmetic,
  no crossings left. Triage by the orchestrator: fix 4 (Name field clips), 6-7 (text
  tiny at the opening zoom), 10 (business palette shows startEvent etc.), measure
  11; prove reachability for 1-3 and 5 with shots (fix if not scrollable); 8-9 are
  AEF map content, recorded, not changed.

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
#                                 # `fw work-on T-1278` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-22T22:21:12Z
last_update: '2026-10-22T22:21:18Z'
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
  - ts: '2026-10-22T22:21:18Z'
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
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L2:keyword=palette)'
    rubric_sha: e4a00f38e801
---

# T-1278: T-1241 follow-up round 4: fix the codex advisory sweep list (readable minimum 9px, Name field grows, business-lens palette wording, reachability evidence)

## Context

**Fourth T-1241 follow-up** (after T-1274, T-1276 and T-1277). This round answers the whole list at once instead of
one amber per round.
- **The sweep:** an ADVISORY codex pass read all 48 shots at 2015e17e. It found no crossings or collisions, and
  listed 10 blocking items and 1 cosmetic. The full list is at
  `.context/reviews/advisory/T-1241-codex-sweep-2015e17e.md`.
- **Orchestrator's triage:**
  - Items 1-3 (map off-screen or under the panel at 1024/1440) and item 5 (left palette below the viewport) are
    scroll by design (T-1256). The shots do not prove reachability, so add evidence; fix if it is not reachable.
  - Item 4: the side-panel Name field clips long names. Fix.
  - Items 6-7: the opening zoom still draws text too small. Raise `OPEN_MIN_TEXT_PX` from 7 to 9.
  - Item 10: the business-lens palette shows technical type names. Fix.
  - Item 11: helper-text contrast. Measure it.
  - Items 8-9 ("T-1068", "fw work-on T-XXX", "P-010", "G-020" in the business view) are AEF's map CONTENT: node
    names, flow names and the Note. The lens filters fields and decoration, not words inside names. They are
    recorded in Decisions and reported to AEF, not changed here.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Readable opening (items 6-7):** `OPEN_MIN_TEXT_PX` is 9. On `aef-task-lifecycle` the smallest node name,
      flow label, id caption and lane caption are drawn at 9 px or more on opening, at 1024, 1440 and 1920. A leg is
      red on 2015e17e and green after. Fit still shows the whole map.
      **Evidence:** `openingZoom()` measures all four classes (`OPEN_TEXT_SEL`). `_t1278-sweep` leg 1, every lens, at
      1024/1440/1920: name 9.0, flow 10.0, id 9.0 (technical/all), lane 9.0 (business/logical) / 10.0 px. The opening
      zoom goes 0.78 -> 1.00. Fit: zoomFactor null and the map fits the canvas. On 2015e17e (`T1278_SRC`): 42 leg-1
      errors, e.g. "smallest name text ... drawn at 7.02px (< 9)". `_t1256` leg 4: minPx 9 at 1024/1440/1920,
      fitStill, 0 unreachable.
- [x] **Reachability (items 1-3, 5):**
  - with the side panel open, scrolling the canvas brings every node, label and the pool's right edge into view at
    1024 and 1440;
  - the left palette scrolls to its last control (LANES) at 1024/1440/1920;
  - a CDP leg asserts both, and new scrolled shots are in `docs/reports/T-1278-evidence/`;
  - if either is not reachable, fix it first.
  **Evidence:** both were already reachable, so nothing was changed (Decisions). `_t1278-sweep` leg 2, panel open, at
  1024 and 1440 in all four lenses: 84 (business/logical) / 101 (technical/all) texts and shapes each scroll fully into
  view with nothing covering them, 0 failures. At the furthest scroll the pool's right edge is at x 674 against the
  visible edge 704 (1024), and 1090 against 1120 (1440). Palette: 23 controls, 0 unreachable; at the end "+ Add Lane"
  (LANES) is inside at 1024/1440/1920 (`overflow-y: auto`). Green on 2015e17e too. Shots in
  `docs/reports/T-1278-evidence/`: `reach-{business,all}-{1024,1440}-{left,mid,right}.png`,
  `palette-end-business-{1024,1440,1920}.png`.
- [x] **Name field (item 4):** grows to its content up to a cap, then scrolls, like the T-1274 Note box. Enter still
      commits and no newline is ever stored; saved bytes are unchanged. Leg: 0 cut Name values on the corpus,
      red on 2015e17e.
      **Evidence:** `field(..., { line: true, grow: true })` uses T-1274's `growToContent` (cap 240 px). `_t1278-sweep`
      leg 3 at 1440: of 321 Name values (24 corpus maps plus the lifecycle map), **0 are cut**; on 2015e17e **99 are
      cut**, 82 of them on corpus maps. At 1024 and 1920, 15/15 lifecycle values, 0 cut. Real CDP keys: "abc" stores "abc"
      and keeps focus (on 2015e17e it stored "a" and focus fell to BODY: the per-keystroke re-render, fixed here, see
      Decisions). A pasted "x\ny" stores "x y". Enter ends the edit with no newline. Bytes are identical after the name
      is restored, and after every leg on every map.
- [x] **Business-lens palette (item 10):** in the business lens the palette subtitles use business wording, not BPMN
      type names or execution terms. The other lenses are unchanged. Leg red on 2015e17e.
      **Evidence:** `PALETTE_WORDING.business` (8 entries) + `renderPaletteWording()`. `_t1278-sweep` leg 4: no business
      subtitle matches the technical-word list (startEvent, Event, status:, cron, horizon, bus topic, composite, fork,
      join, fw, ...); logical/technical/all show exactly the subtitle written in the palette HTML for all 13 items.
      2015e17e: 7 leg-4 errors (e.g. `subtitle of startEvent is "startEvent"`).
- [x] **Helper-text contrast (item 11):** measured. If below 4.5:1, the token is raised; if not, the figure is
      recorded.
      **Evidence:** measured 2.84:1 (#5a6173 on #161922), below 4.5. A new token, `--text-hint` #80869a, gives 4.84:1.
      `_t1278-sweep` leg 5: 76 drawn hints per width (side panel and details view, 4 lenses), minimum 4.84:1, 0 below
      4.5 at 1024/1440/1920. On 2015e17e, 216 were below.
      **Orchestrator's addition (sweep item 7, which the worker found still applies):** lane captions (`.lane-label`)
      and id captions (`.node-id-badge`) used `--text-faint`, 3.1:1 on the canvas `--bg`. Both now use `--text-hint`
      (5.29:1 on `--bg`, 4.84:1 on `--surface`); hover still brightens the lane label to `--text`. No guard pins the
      colour, and `_t1278-sweep` and `_t1241-business-lens` are green after it. The 48 lens shots and the T-1278 evidence
      were re-shot. The reach shots now also cover 1920: at the 9 px opening (zoom 1.00) the map is wider than the
      canvas there too (`reach-*-1920-*.png`).
- [x] **No guard regresses:** the T-1277 guard set stays green (13 guards, `_t1256`, `_t1274-note-box`,
      `_t1276-name-fit`), run one at a time under nice 19. Saved bytes are unchanged on every corpus map.
      **Evidence:** one at a time under `nice -n 19`, all exit 0: `_t600 --self-test`, `_t601 --self-test`,
      `_t1068 --self-test` (5 live legs, 4 poison arms), `_t1067` 6/6, `_t1078` 8 legs, `_t1241-business-lens`, `_t1176`,
      `_t1249-v11-io`, `_editor-behavior-verify`, `_t1091` 31/31, `_endpoint-overlap-verify`, `_t1274-note-box`,
      `_t1276-name-fit`, `_t1256` (all legs: corpus lens-shot 72->0, corpus 134->0, bytes unchanged, opening minPx 9 at
      every width). In the first pass eight guards failed in 0-5 s with ENOSPC: other jobs had filled /tmp (8G tmpfs) to
      100%. Each was rerun once, alone, with TMPDIR in the project's ignored `build/`, and passed. Bytes: legs 1-3 of
      `_t1278-sweep` compare `buildBpmnXml` on all 25 maps; all are unchanged.
- [x] **Shots:**
  - re-shoot all 48 lens shots;
  - make crops for each fixed item;
  - fill `## Visual Verification`;
  - the orchestrator then reruns `fw reviewer judge T-1241 --criterion 1`.
  **2026-10-23, met:** the rerun at fc2c7339 was **green on all three seats** (claude-code, codex, opencode), applied
  by `fw reviewer verdict apply T-1241` as V-20261022-73c28dd4.

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
         1. Run `bin/fw reviewer T-1278`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1278 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#     bin/fw vendor self --check --task T-1278X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
node tools/_t1278-sweep-cdp.mjs > /tmp/.t1278-sweep.out 2>&1 && grep -q '"ok": true' /tmp/.t1278-sweep.out
node tools/_t1274-note-box-cdp.mjs > /tmp/.t1278-1274.out 2>&1
node tools/_t1276-name-fit-cdp.mjs > /tmp/.t1278-1276.out 2>&1
test -s docs/reports/T-1278-evidence/reach-all-1024-right.png && test -s docs/reports/T-1278-evidence/name-field-2x-business-1024.png

## Visual Verification

Shots: all 48 T-1241 lens shots re-shot on this source (`tools/_t1241-lens-shots.py`, 12/12 lens-select ok; the first
run timed out on one screenshot at load average ~42 and was rerun once alone). The T-1278 evidence comes from
`tools/_t1278-shots.py` (48 files) in `docs/reports/T-1278-evidence/`: scrolled reachability shots
`reach-{business,all}-{1024,1440}-{left,mid,right}.png` and `palette-end-business-{1024,1440,1920}.png` (scale 1), and
2x crops `open-text-2x-{lens}-{w}`, `name-field-2x-{business,all}-{w}`, `palette-2x`/`palette-end-2x-{business,logical}-{w}`
and `helper-2x-all-{w}`.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| panel, every lens | Name field "create task — fw work-on (status: captured)" | ok | ok | ok | wraps to 2 lines, whole value shown (name-field-2x crops); details view: one line, whole |
| canvas at opening | node names / flow labels / id captions / lane captions | ok | ok | ok | opening zoom 100%: 9 / 10 / 9 / 9-10 px (open-text-2x crops); "completion gates: … (P-011)" is still dense at 9 px |
| canvas, panel open, scrolled | every node, label, pool right edge | ok | ok | — | reach-*-left/mid/right: "do the work", "Handoff → dispatch loop", "resolved at gate …", gates/unchecked/archive/end all in view at some scroll; at the shot's scroll 0 they run under the canvas edge (scroll, not hidden) |
| canvas, scrolled right | pinned lane header (T-1091) | ok | ok | — | at 1024 right-end it covers the left part of "partial-complete"; whole at the mid scroll |
| canvas at opening, 1920 | human-lane task "partial-complete" | — | — | ok | at 100% the map is wider than the 1920 canvas; the task sits at the right edge, reached by scroll |
| left palette | every item, LANES "Add Lane", help text | ok | ok | ok | palette-end-business-*: scrolls to its end, LANES and the help text in view |
| left palette, business | subtitles | ok | ok | ok | "where the work begins/ends", "framework · Authority", "a step made of steps", "paths run side by side", "when something goes wrong", "after a wait or at a set time", "when a message arrives"; two wrap to 2 lines |
| left palette, logical/technical/all | subtitles | ok | ok | ok | unchanged: startEvent, endEvent, fw · Authority, collapsed composite, fork / join, on status:issues, cron / horizon, on bus topic |
| panel + details | helper text (".field-hint") | ok | ok | ok | 4.84:1, visibly lighter than before (helper-2x crops); the crop is cut at 720 css px wide, not the UI |
| toolbar, dialog Close | buttons | ok | ok | ok | contained, unchanged |

My own reading of the 48 lens shots against the sweep's items 1-11:
- **1-3** (map past the canvas edge at 1024/1440): the shots are at scroll 0, so the same parts still run under the canvas
  edge. They are reachable by scroll (leg 2 and the reach-* shots). Not a defect.
- **4** (Name clipped): no longer applies in any panel or details shot.
- **5** (palette below the viewport): still below the fold in the panel shots; reachable (palette-end-* shots). Not a defect.
- **6** (tiny names): improved, 7.02 -> 9 px. "completion gates: Agent ACs (P-010) + ## Verification commands (P-011)"
  is still the densest box (4 lines at 9 px), legible at native resolution.
- **7** (small, low-contrast captions): size fixed (9-10 px). The lane captions "AGENT · INITIATIVE" / "HUMAN
  SOVEREIGNTY" and the id captions still use `--text-faint` (about 3:1), so the **low-contrast part still applies**. It is
  outside this task's criteria; it needs a follow-up.
- **8-9** (ids/commands in business names and the Note): still apply. This is AEF's map content (Decisions).
- **10** (business palette terms): no longer applies.
- **11** (helper contrast): no longer applies (4.84:1).

The orchestrator then reruns `fw reviewer judge T-1241 --criterion 1` (criterion 7).

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

### 2026-10-23 — which text the opening zoom measures (items 6-7)
- **Chose:** `OPEN_MIN_TEXT_PX` 9, and `openingZoom()` takes its minimum over every drawn node name, flow label,
  id caption and lane caption (`OPEN_TEXT_SEL`), skipping text that is not drawn (lens or ids toggle).
- **Why:** measured at opening on 2015e17e (aef-task-lifecycle, 1024): names 7.02 px (9 px font), id captions 7.02
  (9), lane captions 7.02 (9), flow labels 7.80 (10). No class is drawn smaller than the names on this map today,
  but nothing guarantees it on another map; counting all four classes costs nothing and keeps the floor true for
  every class. After: 9.0 / 9.0 / 9.0 / 10.0 px at 1024, 1440 and 1920 in all four lenses; Fit still shows the whole map.
- **Rejected:** names only (as before): a smaller caption or flow label on another map would open under 9 px unseen.

### 2026-10-23 — items 1-3 and 5 are scroll, not defects
- **Chose:** no layout change; prove reachability with a CDP leg and scrolled shots.
- **Why:** the side panel sits beside the canvas (grid column), not over it: at 1024 the canvas is x 220-704, the
  panel 704-1024. The canvas scrolls (scrollWidth 1410 > clientWidth 484 at 1024; 900 at 1440). Every drawn text and
  node shape (84 business/logical, 101 technical/all) scrolls fully into view and uncovered, and at the furthest
  scroll the pool's right edge is at x 674 against the visible edge 704 (1024) and 1090 against 1120 (1440). The palette
  is `overflow-y: auto` (scrollHeight 1285 > clientHeight 693/825/1032). All 23 controls scroll into view, and at the
  end "+ Add Lane" (LANES) is inside at 1024/1440/1920. The leg is green on 2015e17e too, so nothing needed fixing.
- **Rejected:** shrinking or overlaying the panel to show the whole map at 1024. That would undo T-1256's readable
  opening; scroll is the design.

### 2026-10-23 — items 8-9 (ids and commands in business names) are not changed here
- **Chose:** leave "T-1068", "fw work-on T-XXX", "P-010", "## Verification commands", "P-011" and "G-020" as they are.
- **Why:** they are words inside AEF's node names, flow names and the Note: map CONTENT that AEF authored. A lens
  filters fields and decoration; rewriting words inside a name would change what a person reads per lens and
  would put content edits in the designer. They are reported to AEF as content for their map.
- **Rejected:** a business-lens text filter that strips id-like tokens from names: it guesses, and it would hide
  words AEF chose to show.

### 2026-10-23 — the Name field (item 4)
- **Chose:** the node Name is a one-row textarea (`field(..., { line: true, grow: true })`) sized by T-1274's
  `growToContent` (grows to the cap, then scrolls). Enter ends the edit (blur) and never inserts a newline; a pasted
  line break becomes a space before the value reaches the model. Each keystroke updates the step and the canvas; the
  panel re-renders when the edit ends.
- **Why:** the single-line input cut the value ("captu…"): 99 of 321 named nodes were cut at 1440 across the corpus.
  The T-1278 probe also found that the field re-rendered the panel on every keystroke, which rebuilt the box under
  the cursor: typing "abc" stored "a" and focus fell to the page (the T-264 failure, never covered by a leg). Moving
  the panel re-render to the end of the edit fixes both in the same field.
- **Rejected:** a deferred commit (blur/Enter only, as the workflow ID): it loses the live canvas update while typing.

### 2026-10-23 — business-lens palette wording (item 10)
- **Chose:** a table, `PALETTE_WORDING[lens][data-create]`, applied by `renderPaletteWording()` from
  `renderLensSelect()`. It holds only `business` (8 subtitles: start/end, script task "framework · Authority",
  sub-process, parallel, error/timer/message events). Any item it does not name keeps the subtitle written in the
  palette (kept in `data-meta`), so the other lenses are byte-for-byte the HTML's.
- **Rejected:** putting the wording in the lens file: that file is AEF's shared definition (T-4402) and its shape is
  theirs; a palette-wording key would need their agreement first.

### 2026-10-23 — helper-text contrast (item 11)
- **Chose:** a new token `--text-hint: #80869a` for `.field-label .field-hint` and `.suggest-row .field-hint`.
- **Why:** measured `--text-faint` #5a6173 on the panel and details background `--surface` #161922 at **2.84:1**,
  below 4.5:1, for all 76 drawn hints per width (9 px and 11 px). With `--text-hint` it is **4.84:1**. A hint stays
  a step dimmer than its label (`--text-dim`, 5.58:1).
- **Rejected:** raising `--text-faint` itself: 41 uses, including canvas glyph strokes and read-only fields, which
  would change shapes on the map that no item asked about.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1278 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-22T22:21:12Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1278-t-1241-follow-up-round-4-fix-the-codex-a.md
- **Context:** Initial task creation

### 2026-10-22T22:21:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
