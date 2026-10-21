---
id: T-1241
name: "Business lens in the designer (T-281 GO, slice 1): lens switch in the toolbar,
  business lens first"
description: >
  Build slice 1 of inception T-281 (GO 2026-10-20, operator job 063). A toolbar switch
  business / logical / technical / all; the business lens hides technical badges,
  ids and fields outside the business set in the panel, the details view and on the
  canvas. Driven by the lens definition AEF owns (AEF T-4402; until it lands, a local
  file of the same shape, swapped for AEF's when it ships). Success clause from T-281:
  on aef-task-lifecycle in the business lens 0 technical badges and 0 fields outside
  the business set visible (test), 0 bytes changed in the saved BPMN when switching
  lenses, 0 fields shown that the field profile hides, and the operator can follow
  the map. Screenshots at 1024/1440/1920 + independent reviewer.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
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
#                                 # `fw work-on T-1241` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-20T20:41:29Z
last_update: 2026-10-21T11:58:48Z
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
  - ts: '2026-10-20T23:42:19Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 2
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L2:keyword=canvas)'
    rubric_sha: e4a00f38e801
---

# T-1241: Business lens in the designer (T-281 GO, slice 1): lens switch in the toolbar, business lens first

## Context

Slice 1 of inception T-281 (GO 2026-10-20, operator job 063). Design and evidence:
`docs/reports/T-281-audience-lenses.md`. The lens definition is AEF's (their T-4402); until it ships, a local file of
the same shape, swapped for AEF's when it lands.

## Acceptance Criteria

### Agent
- [ ] A lens definition (data, not code) names per lens the fields and the canvas decorations it shows; the designer
      reads it like the field profile, and works without it (all fields, as today)
- [ ] A toolbar switch business / logical / technical / all; the business lens drives the side panel, the details view
      and the canvas decoration at once
- [ ] Test on `aef-task-lifecycle` in the business lens: 0 technical badges and 0 fields outside the business set
      visible; 0 fields shown that the field profile hides
- [ ] Switching lenses changes 0 bytes of the saved BPMN (export before == export after, every lens)
- [ ] Screenshots of each lens at 1024, 1440 and 1920, read control by control in `## Visual Verification`
- [ ] The full bridge run stays green

### Human
- [ ] Independent screenshot review (reviewer-judged, `fw reviewer judge T-1241 --criterion 1`): each lens is
      legible, nothing clipped or overlapping, the business lens reads as a business view
  **Steps:** 1. Open the screenshot paths listed under `## Visual Verification`. 2. Check each lens at 1024/1440/1920.
  **Expected:** every control reachable and unclipped; the business lens shows the flow without ids or technical badges.
  **If not:** name the screenshot and the control; the agent fixes and re-shoots.
- [ ] [REVIEW] The operator opens `aef-task-lifecycle` in the designer in the business lens and can follow it
  **Why you:** act-in-the-world — T-281's success clause names the operator as the reader who must follow the map.
  **Steps:** 1. Open the map in Watchtower's designer. 2. Switch the toolbar lens to Business. 3. Read the flow.
  **Expected:** you can follow what happens and who decides, without technical noise.
  **If not:** say what got in the way; it becomes a fix in this task.

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
         1. Run `bin/fw reviewer T-1241`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1241 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#     bin/fw vendor self --check --task T-1241X
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

## Visual Verification

Screenshots: `docs/reports/T-1241-evidence/t1241-<lens>-<width>-<panel|details>.png`, 4 lenses (business, logical,
technical, all) x 3 widths (1024, 1440, 1920) x 2 states (panel = canvas + side panel with the service task
"create task — fw work-on" selected; details = the element details view open on it) = 24 files, taken by
`python3 tools/_t1241-lens-shots.py` on `aef-task-lifecycle` (v3). Read by the author control by control; the
independent read is the `[REVIEW]` criterion.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| toolbar | Lens select ("Lens: Business" …) | ok | ok | ok | 1024: first control of row 2, beside Add Lane; 1440/1920 in row 1 after the view group |
| toolbar | Check / Versions / Save to project / Save | ok | ok | ok | all reachable; at 1920 "Save to project" and "Save" now wrap to row 2 (the row was already full: the old toolbar ended at 1906 of 1920 px, no room for any new control) |
| business panel | Name, Lane, Note, Owner | ok | ok | ok | no Slug, Display ID, UID, no id under the type name, no aef: tag, no I/O, no Other extensions |
| business canvas | node labels, gateways, edge labels | ok | ok | ok | no id captions, no I/O or authority marker, pool label "AEF task lifecycle" without "workflow:aef-task-lifecycle" |
| business details | BPMN (Name, Lane), Extensions (Note, Owner), Close | ok | ok | ok | two-column sheet, Close reachable |
| logical panel | + Authority, Horizon, Workflow type, Determinism, I/O contract | ok | ok | ok | no ids, no Slug/UID |
| logical details | the same, two-column | ok | ok | ok | |
| technical panel | + Slug, Display ID, UID, id under the type name, aef: tags, Other extensions | ok | ok | ok | id captions back on the canvas |
| all panel | as before the lens (every field, "+ N empty fields") | ok | ok | ok | identical to the pre-lens designer |

Notes: at 1024 the map fits small (fit zoom), the id captions' absence is visible only at 1440/1920. The panel's Lane
select still lists lane ids (`agent`) in every lens: a lane id is the lane's name here, left as is for slice 1.

### Toolbar fit (2026-10-21)

The lens select wrapped the 1920 header to two rows (`_t1176` leg "1920px: one 48px row" got 77). Fix in
`src/aef-workflow-designer.html`: options show the lens name only ("All", "Business" …, no "Lens: " prefix) behind
a 12px half-filled lens icon (`<label for="lens-select">`, aria-hidden; the select keeps aria-label and title
"Audience lens"); a drawn 8px chevron instead of the native arrow; `#instancePicker` loses its extra 8px left margin;
header gap 6px → 4px. No control removed or hidden, no font smaller. Width won at 1920 with the real lens list
(widest option "Technical"): lens group 113 → 89 px, 8 px margin, ~46 px of gaps = ~78 px; the row now ends at 1906
with 15 px to spare (35+ px when the server has no lens definition, as in the `_t1176` harness).

Screenshots `docs/reports/T-1241-evidence/toolbar-fit-<width>-lens<all|business>.png` (real lens definition served),
read control by control:

| shot | checked |
|------|---------|
| 1920-lensall | ONE row: brand, version, fault dot, Open project, Pending refs, +, instances: unavailable, zoom − fit + ⤢, ◧ ◨ ⛶, lens icon + "All" ▾, Add Lane, Reset, Clean layout, View XML, Settings, Load, Check, Versions, Save to project, Save — all fully visible, none clipped or overlapping, Save ends at x=1906, inside the 14 px padding |
| 1920-lensbusiness | same one row with "Business" ▾ (select is sized to "Technical", so no shift between lenses); lens icon legible (checked at 5× zoom) |
| 1440-lensall / -lensbusiness | row 1 to View XML with the lens group after the view group; row 2 Settings … Save; nothing clipped; label and select never split |
| 1024-lensall / -lensbusiness | row 1 to the view group, row 2 starts with the lens icon + select, then Add Lane … Save; all inside 1024; icon stays with its select |

Not shot: the lens select open — a native `<select>` popup is not drawn in a headless CDP screenshot. Not
re-measured: the Watchtower inline frame (1894 px at a 1920 screen) with the lens definition served is 26 px narrower,
so with 15 px to spare at 1920 it is ~11 px short there and Save may still wrap to row 2 (estimate, not shot); `_t1176` (21/21) and `_t1241` (ok) pass.

**Inline frame, measured (orchestrator, 2026-10-21).** With the lens definition served, the header at 1894 px was 75 px
(two rows), confirming the estimate. Fix: the instance picker's unavailable label `instances: unavailable` →
`instances: n/a` (~45 px; the picker's title still explains the overlay; `_t884` L6 updated, 6/6). Measured after, real
lens list: 1894 px → 48 (one row), 1920 → 48, 1440 → 75 and 1024 → 75 (two rows, as before the lens; `_t1176` checks
only reach there and passes). Shots `docs/reports/T-1241-evidence/toolbar-fit-n-a-<1024|1440|1894|1920>-lensall.png`:

| shot | checked |
|------|---------|
| n-a-1894-lensall | ONE row at the inline width: brand, version, Open project, Pending refs, +, instances: n/a, − fit +, ⤢ ◧ ◨ ⛶, lens icon + "All", Add Lane, Reset, Clean layout, View XML, Settings, Load, Check, Versions, Save to project, Save; nothing clipped or overlapping |
| n-a-1920-lensall | one row, same controls, more spare space before Save |
| n-a-1440-lensall | two rows, every control present, none clipped |
| n-a-1024-lensall | two rows: row 1 brand … view group + lens icon + "All"; row 2 Add Lane … Save; all inside 1024 |

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
     fw inception decide T-1241 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-20T20:41:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1241-business-lens-in-the-designer-t-281-go-s.md
- **Context:** Initial task creation

### 2026-10-20T23:42:18Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
