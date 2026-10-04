---
id: T-893
name: "Render authority on the element, and indicate mismatch and missing DIFFERENTLY"
description: >
  T-888 ruling clause 4 — the clause that answers the strongest objection from four
  rounds of review ('replaces an architectural guarantee with a lint rule'). Authority
  is drawn on the node so the picture is honest where the fact lives. THREE states,
  and conflating the last two is the defect to avoid: matches the lane default ->
  NO indicator (the common case must not shout); DIFFERS -> subtle marker, a legitimate
  authorial choice made visible; NO authority at all -> louder marker, because that
  is not a choice but a hole and a compile error. Follows this project's own grammar:
  not-evaluated is not passed, missing is not different. Visual verification required
  per CLAUDE.md — element-level screenshots in every theme and density, read back,
  not DOM math.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [arc:designer-authoring-surface]
components: [tests/test_rule_dialect_axis.py, tests/test_rule_form_parity.py, tools/validate-workflow.py]
related_tasks: []
arc_id: designer-authoring-surface
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T10:41:46Z
last_update: 2026-09-28T23:45:31Z
date_finished: 2026-09-28T23:45:31Z
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
cost_estimate_proposed:
  - ts: '2026-09-27T15:47:10Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 1
      tier: 2
      effort: 8
    rationale: blast_radius=1 (single-component); tier=2 (workflow:build); 
      effort=8 (lines=275,acs=4)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-28T23:45:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (4-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=246,acs=6)
    rubric_sha: e4a00f38e801
bvp_scores_proposed: []
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 1
  F3: 0
  F1: 3
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T23:40:53Z'
---

# T-893: Render authority on the element, and indicate mismatch and missing DIFFERENTLY

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **One pure function decides the state:** `authorityMarkerState(own, laneDefault)` in `src/aef-workflow-designer.html` returns exactly one of `'none' | 'differs' | 'missing'`, with the three states from T-888 clause 4 and nothing else: own present and equal to the lane default → `none`; own present and different from a present default → `differs`; neither own nor default → `missing`. Own present with no default → `none` (there is nothing to differ from — the same three-state grammar the validator's `W-XML-AUTHORITY-DEFAULT-MISMATCH` uses, T-894). Pinned by a node-run unit test that slices the function out of the HTML, so it runs without a browser
- [x] `renderNodes()` draws a marker per state: nothing for `none`; a subtle marker (class `node-authority-badge`, faint text, the element's own authority abbreviated) for `differs`; a louder marker (class `node-authority-missing`, the `--orange` token, never a literal colour) for `missing`. Colours come from theme tokens
- [x] **The default never writes (T-888 clause 3):** rendering a marker mutates no node — a leg serialises the document before and after a render with lane defaults set and requires byte-identical output
- [x] **Visual verification per CLAUDE.md, not DOM math:** element-level Playwright screenshots of a node in each of the three states, in every label-size mode the app has (`s` / `m` / `l`, its only visual modes — there is a single theme), READ back, and referenced in a `## Visual Verification` section of this task. Nine screenshots minimum, each one named
- [x] The existing designer suites that touch node rendering stay green (`tools/_t889-authority-on-the-element-teeth.sh` static legs and the round-trip guard's `--denominators-only`), because the marker adds no emitted key and no new `aef.*` access

### Human
- [ ] [REVIEW] **The two markers read as different KINDS of thing, and the common case is silent.**
      **Steps:**
      1. `cd /opt/832-Workflow-designer && node tools/_t893-authority-marker-shots.mjs` (isolated headless Chromium; writes 9 PNGs to `docs/reports/t893-shots/`)
      2. Open `docs/reports/t893-shots/differs-m.png`, `missing-m.png`, `none-m.png` side by side.
      **Expected:** `none-m` shows no marker; `differs-m` shows a faint mono "◆ ini" above the node that reads as an annotation, not an alarm; `missing-m` shows an orange "⚠ no authority" that reads as a defect. The agent's reading of the nine shots is in `## Visual Verification` below; the judgment this AC asks for is whether the subtle/loud contrast is RIGHT, which is taste, not geometry.
      **If not:** name which of the two markers is mis-pitched (too loud / too quiet) and whether the marker's position (top-left, above the shape) collides with incoming edge labels on your maps — `missing-m.png` shows an edge label sitting just above it on task-lifecycle.

## Visual Verification

Element-level screenshots taken by `tools/_t893-authority-marker-shots.mjs` in an isolated headless
Chromium (the shared Playwright MCP browser was in use by another session — G-006 — so the project's
own CDP plumbing was used instead), on a task-lifecycle fixture with the agent lane set to the retired
`none` sentinel and `frw_4_enter` given its own `authority="initiative"`. All nine READ back on 2026-09-29:

| state | s | m | l | what I saw |
|---|---|---|---|---|
| none | `docs/reports/t893-shots/none-s.png` | `none-m.png` | `none-l.png` | no marker at any size; the node reads exactly as before (I/O badge, id badge only) |
| differs | `differs-s.png` | `differs-m.png` | `differs-l.png` | faint mono "◆ ini" above the top-left corner, same weight as the id badge; legible at `s`, unchanged by label size (the marker is 8px at every size, as designed) |
| missing | `missing-s.png` | `missing-m.png` | `missing-l.png` | orange "⚠ no authority" above the top-left corner, clearly louder than the differs marker; on this fixture an incoming edge label ("resume after healing…") sits just above it — close but not overlapping, flagged for the Human AC |

No regression seen on the nodes themselves in any mode: labels, I/O badge (`1→0`) and id badges render as before.

## Verification

# The pure state function, sliced from the editor and run without a browser (13 cases incl. the exact three-state partition).
node tests/t893-authority-marker-state.test.mjs | grep -qE '^PASS [0-9]+ / FAIL 0$'
# The render is wired to it and to the effective-default helper (property, not prose).
grep -q 'const mstate = authorityMarkerState(n.aef?.authority, effectiveLaneDefault(lane));' src/aef-workflow-designer.html
# Both marker classes exist and take their colour from tokens — control first (PL-328): the token pattern hits where tokens are defined.
grep -q '^\s*--orange: ' src/aef-workflow-designer.html
grep -qE '\.node-authority-missing \{ fill: var\(--orange\)' src/aef-workflow-designer.html
grep -qE '\.node-authority-badge +\{ fill: var\(--text-faint\)' src/aef-workflow-designer.html
# Isolated-Chromium driver: marker counts per state x size match the fixture, buildBpmnXml unchanged by rendering (clause 3), 9 PNGs written.
timeout 120 node tools/_t893-authority-marker-shots.mjs | grep -q '^L2 PASS'
test "$(ls docs/reports/t893-shots/*.png | wc -l)" -ge 9  # T-1015: was =9; G-015, the population grows
# The marker adds no emitted key and no new aef.* access inside the emitter: the static guard is unchanged.
node tools/_roundtrip-serialization-cdp.mjs --denominators-only | grep -q 'computed sources 3 verified'
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

### 2026-09-29 — the cheap-by-radius, expensive-by-verification task, done
- **What changed:** The three states are decided by one pure function and pinned by a browserless test; the render draws two classes. What the build ADDED to the ruling's text is the migration-period reading of "the lane's default" (Decisions) — without it the marker would have shouted on the whole corpus on day one, which is the exact failure T-624 taught (a warning that fires everywhere is dismissed everywhere).
- **Plan impact:** The visual verification standard was met without the shared Playwright browser, which was in use (G-006); the project's own isolated-Chromium CDP plumbing produced the nine element-level shots and two byte-level legs. The abandonment note from T-897 stands as a calibration finding: `blast_radius=1` scored this cheap, and the verification was most of the cost.
- **Triggered:** Nothing filed. T-892 (lane config UI for authoringDefault) will make the `differs` state reachable by authoring rather than only by import.

## Recommendation

**Recommendation:** GO
**Rationale:** All five Agent ACs are verified by legs that run without human judgment; the one Human AC is genuine taste (is the subtle/loud contrast right, is the position clear of edge labels on real maps) and is stated with the nine shots to look at.
**Evidence:**
- `tests/t893-authority-marker-state.test.mjs`: 13/13, including the exact-partition case.
- `tools/_t893-authority-marker-shots.mjs`: L1 counts (differs=1, missing=3 agent-lane nodes) identical across s/m/l; L2 buildBpmnXml byte-identical before/after render (23,321 bytes).
- Nine screenshots read back; table in `## Visual Verification`.
- Static guard unchanged: `computed sources 3 verified`.

## Decisions

### 2026-09-29 — what counts as the lane's default while T-895 is pending
- **Chose:** the effective default is `lane.authoringDefault` when declared, else the lane's legacy `authority` unless it is the retired `none` sentinel (`effectiveLaneDefault`).
- **Why:** today no corpus map declares an authoring default and no element carries its own authority, so the literal clause-4 rule ("no authority → louder marker") would flag every node on all 24 maps. The lane's `authority` IS where the fact lives until T-895 migrates it; reading it as the default keeps the marker truthful on the current corpus and makes the retired `none` lanes — whose elements genuinely carry no authority anywhere — the only place the louder marker fires.
- **Rejected:** authoringDefault-only (the pure clause-4 reading): correct after migration, a corpus-wide false alarm before it. Treating `none` as a default: it is the value T-888 retired precisely because it hid this hole.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-27T10:41:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-893-render-authority-on-the-element-and-indi.md
- **Context:** Initial task creation

## 2026-09-27 — `components:` populated (T-906)

Basis: **inferred from the stated deliverable: rendering authority on the element is an editor change; the editor is one file in this repo**

Populated so `fw bvp` can compute a `blast_radius` and therefore a quadrant. Empty `components:` made `estimate-cost` refuse the radius — correctly, since unmeasured is not zero — while printing `[wrote]` and exiting 0, so the refusal read as a success and two procAsFit rounds concluded the cost axis did not exist.

### 2026-09-27T19:41:04Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-842cbfcf
- **Timestamp:** 2026-09-28T23:45:34Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 4

**Per-AC findings:**

- **AC#5 (Agent)** — The existing designer suites that touch node rendering stay green (`tools/_t889-authority-on-the-element-teeth.sh` static legs and the round-trip guard's `--denominators-only`), because the marker add
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t889-authority-on-the-element-teeth.sh in: The existing designer suites that touch node rendering stay green (`tools/_t889-authority-on-the-element-teeth.sh` static legs and the round-trip guar`

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 2
     - evidence: `node tests/t893-authority-marker-state.test.mjs | grep -qE '^PASS [0-9]+ / FAIL 0$'`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 10
     - evidence: `timeout 120 node tools/_t893-authority-marker-shots.mjs | grep -q '^L2 PASS'`
  3. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 13
     - evidence: `node tools/_roundtrip-serialization-cdp.mjs --denominators-only | grep -q 'computed sources 3 verified'`

### 2026-09-28T23:45:31Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
