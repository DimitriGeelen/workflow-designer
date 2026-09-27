---
id: T-910
name: "The round-trip guard covers aef:workflowMeta but NOT aef:laneMeta — the same
  coverage gap T-885 measured for document-level metadata, one element over. Measured
  under T-890 by mutation: suppressed the editor's authoringDefault writer entirely
  and _roundtrip-serialization-cdp.mjs still reported pass:true, exit 0, with 'wm-denominator:
  0 unclassified / 10 written'. The 10 are workflowMeta attributes; laneMeta's are
  outside the denominator by construction, exactly as node-level aef.* was outside
  it before T-886. So every aef:laneMeta attribute — abbr, authority, height, and
  now authoringDefault — can be dropped from the emitter in silence. authority is
  the serious one: it is the frozen standard's authority-of-record under §3, and nothing
  asserts the editor keeps emitting it. T-886 generalised the workflowMeta denominator
  so 'the next attribute cannot enter unclassified'; that guarantee stops at the element
  boundary. Needs the same derived-denominator treatment for laneMeta, and the fix
  should ask whether the guard wants one denominator per aef: element or one that
  walks them all."
description: >
  Promoted from observation OBS-416

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components:
  - tools/_roundtrip-serialization-cdp.mjs
  - src/aef-workflow-designer.html
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
created: 2026-09-27T21:24:40Z
last_update: 2026-09-27T22:08:43Z
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
  - ts: '2026-09-27T21:25:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 4
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=4 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-27T21:25:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=278,acs=8)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-27T21:26:11Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (2-components); tier=2 (workflow:build); effort=8 
      (lines=278,acs=8)
    rubric_sha: e4a00f38e801
---

# T-910: The round-trip guard covers aef:workflowMeta but NOT aef:laneMeta — the same coverage gap T-885 measured for document-level metadata, one element over. Measured under T-890 by mutation: suppressed the editor's authoringDefault writer entirely and _roundtrip-serialization-cdp.mjs still reported pass:true, exit 0, with 'wm-denominator: 0 unclassified / 10 written'. The 10 are workflowMeta attributes; laneMeta's are outside the denominator by construction, exactly as node-level aef.* was outside it before T-886. So every aef:laneMeta attribute — abbr, authority, height, and now authoringDefault — can be dropped from the emitter in silence. authority is the serious one: it is the frozen standard's authority-of-record under §3, and nothing asserts the editor keeps emitting it. T-886 generalised the workflowMeta denominator so 'the next attribute cannot enter unclassified'; that guarantee stops at the element boundary. Needs the same derived-denominator treatment for laneMeta, and the fix should ask whether the guard wants one denominator per aef: element or one that walks them all.

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**Scoped and scored by the previous run so this one can start immediately** — it was parked only
because that session hit the framework's `urgent` budget threshold, not because anything is
undecided. `authority` is the frozen standard's authority-of-record under §3 and nothing asserts
the editor keeps emitting it.

- [x] A derived denominator covers `aef:laneMeta` the way T-886's covers `aef:workflowMeta` — derived **from the emitter**, so the next laneMeta attribute cannot enter unclassified. Copying a hand-written list would rebuild the defect one element over
- [x] **Proved by mutation, per attribute.** Suppress each of `authority`, `abbr`, `height`, `authoringDefault` in the writer and the guard goes red **naming the attribute**. Measured under T-890: suppressing `authoringDefault` today leaves it `pass: true`, so the current state is a confirmed false green, not a suspicion
- [x] Every mutation is **asserted applied** before its result is scored — an unapplied mutation reads identically to a survival, which this corpus has hit twice
- [x] `authority` is called out separately in the result whatever it shows: it is the §3 authority-of-record, and its silent loss is a seam-integrity defect rather than a cosmetic one
- [x] The control set runs first and reports **MUTATION SETUP BROKEN** rather than scoring kills through a broken harness
- [x] Decide and record whether the guard wants **one denominator per `aef:` element or one that walks them all** — T-886 solved `workflowMeta`, this solves `laneMeta`, and a third element would otherwise arrive with the same gap. If the answer is "walk them all", say so and file it rather than building the third special case

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

# The laneMeta denominator, derived from the emitter. Static, no browser, ~1s.
timeout 120 node tools/_roundtrip-serialization-cdp.mjs --denominators-only > /tmp/.t910a.out 2>&1 && grep -q '"pass": true' /tmp/.t910a.out
# All four laneMeta attributes are derived FROM THE EMITTER, and none is unclassified.
grep -q 'laneMeta 4 attributes derived, 0 unclassified' /tmp/.t910a.out
# The full harness is green, and the lane leg proves all four LIVE with nothing unmeasured.
timeout 300 node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t910b.out 2>&1 && grep -q '4 LIVE / 0 BLIND' /tmp/.t910b.out
# NEVER-PRESENT is zero: authoringDefault now has a fixture, so nothing is scored as passed-but-unmeasured (T-3105).
grep -q '0 NEVER-PRESENT' /tmp/.t910b.out
# authority is reported separately and is LIVE — the v1 §3 authority-of-record (AC4).
grep -q 'authority=LIVE' /tmp/.t910b.out
# The fixture authors authoringDefault on exactly one of its two laneMeta elements, so BOTH the
# present and the absent branch of an optional attribute are exercised. Counted on the laneMeta
# lines only: the file's header comment also contains the string, and grepping the whole file
# counted 2 and failed a check that was describing the right property with the wrong denominator.
test "$(grep -c '<aef:laneMeta' tests/fixtures/aef-bpmn/t910-lane-authoring-default.bpmn)" -eq 2
test "$(grep '<aef:laneMeta' tests/fixtures/aef-bpmn/t910-lane-authoring-default.bpmn | grep -c 'authoringDefault=')" -eq 1
# Teeth: 10 cases, every mutation asserted applied, control set first. Mutates tracked source and
# restores it — the script verifies the restore against a sha256 and exits 91 if it cannot.
timeout 580 bash tools/_t910-lanemeta-teeth.sh > /tmp/.t910c.out 2>&1 && grep -q '^FAIL: 0' /tmp/.t910c.out
# Control sibling (PL-328): the teeth run must actually report passes, or 'FAIL: 0' is vacuous.
grep -qE '^PASS: [1-9][0-9]+' /tmp/.t910c.out
# And the teeth must leave the mutated source byte-identical.
git diff --quiet src/aef-workflow-designer.html

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

### 2026-09-28 — the gap was narrower than filed, and the first repair accused an innocent guard
- **What changed:** the task was filed on the belief that all four `aef:laneMeta` attributes were
  silently droppable. Measured: **two** were (`height`, `authoringDefault`) and **two**
  (`authority`, `abbr`) were incidentally compared by a hand-typed `{id, authority, abbr}` lanes
  projection. `authority` — the §3 authority-of-record — was on the safe side of that split **by
  accident, not by guarantee**: nothing derived it, nothing asserted it, and one edit to a literal
  would have moved it. That is the finding, and it is worse than the one filed, not better.
- **Plan impact:** the repair is not only "add a denominator" but "make the projection
  LMSPEC-driven", because the denominator alone would have left the projection hand-typed.
- **Triggered:** OBS-419 (the AC6 ruling).

### 2026-09-28 — the first version of the new leg reported a false BLIND
- **What changed:** the lane self-test, copied in shape from the workflowMeta one, reported
  `height` BLIND on one fixture. It was not blind — `growUnderDeclaredLanes()` rewrites an
  under-declared lane height on import, so the authored 260 never reaches the model to be
  perturbed. The leg written to catch false greens produced a **false red** on its first run.
- **Plan impact:** added NOT-EXERCISABLE as a fourth verdict; the lane leg now keeps four unproven
  states apart (NEVER-PRESENT / NOT-EXERCISABLE / MUTATION-NOT-APPLIED / BLIND) where the first
  draft kept two.
- **Triggered:** OBS-418 — while chasing this I found the inherited reporting names the wrong
  fixtures: `witnesses` is pooled across verdicts at the node and workflowMeta levels, so the
  BLIND finding printed two fixtures where the key was LIVE. Fixed at the lane level only; the
  other two are OBS-418 rather than a silent rewrite of guards this task is not about.

### 2026-09-28 — case 8 proved the derivation could point at the wrong element
- **What changed:** the teeth instrument's unresolvable-carrier case went red for the **wrong
  reason**. `${lane.extra ? … }` resolved its leading identifier to the `for (const lane of
  lanesToEmit)` LOOP VARIABLE, then scanned from the loop head and pulled `id` and `name` off the
  sibling `<bpmn:lane>` into `aef:laneMeta`'s denominator (derivedTotal 6, orphans `id`, `name`).
  It happened to fail only because those two were not in `LMSPEC`; against a list that contained
  them it would have gone **green over a denominator describing a different element**.
- **Plan impact:** resolution is now restricted BY POLICY to two carrier shapes — a bare local and
  `ident.join(…)` — and must resolve to a real assignment, never a `for…of` binding.
- **Triggered:** nothing new; the teeth case that caught it is case 8 and it now passes for the
  right reason.

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

**Recommendation:** GO — close it. All six Agent acceptance criteria are ticked and every one is
backed by a command in `## Verification` that was rehearsed under the gate's own shell semantics
(`set -o pipefail`, no errexit) and passes. The task carries **no Human acceptance criteria**; the
only thing standing between it and `work-completed` is `owner: human`, which `fw note promote` set
by default (G-027) and which an agent may not change.

**Rationale:** the confirmed false green is gone and its absence is proven by breaking it, not by
observing a pass. Suppressing each of the four `aef:laneMeta` attributes in the writer now turns
the harness red and names the attribute — the same mutation that under T-890 left it `pass: true,
exit 0`. `authority`, the v1 §3 authority-of-record, is LIVE on all 21 fixtures and is reported by
name rather than averaged into a fraction.

**Evidence:**
- `lm-denominator: 0 unclassified / 4 written / 4 LIVE / 0 BLIND / 0 NOT-APPLIED /
  0 NOT-EXERCISABLE / 0 NEVER-PRESENT / 0 EXCLUDED over 21 fixtures; authority=LIVE`
- `tools/_t910-lanemeta-teeth.sh` — **40 assertions, 0 failures**, 10 cases: a control set that
  requires the clean run to be green *and* the failure strings to be absent from it (PL-328), the
  four writer suppressions, two denominator-evasion cases, an unresolvable-carrier case, anchor
  rot, and a deliberately broken mutator that must report `MUTATION SETUP BROKEN` rather than
  score kills. Every mutation asserts its replacement count and re-hashes the file.
- The instrument mutates tracked source and restores it; the restore is verified against a
  sha256 and the script exits 91 rather than leaving a mutant behind. `git diff --quiet
  src/aef-workflow-designer.html` is a verification line for exactly that.
- Three defects found on the way, none of them silently absorbed: **OBS-418** (the node and
  workflowMeta legs name the wrong fixtures in a BLIND finding), **OBS-419** (the AC6 ruling and
  its 23-element census), **OBS-420** (`fw fabric register` refuses and writes the card anyway).

**What is NOT claimed:** `@height` is proven on 20 of 21 fixtures and is NOT-EXERCISABLE on
`lane-capacity-large-spill.bpmn`, because `growUnderDeclaredLanes()` rewrites 260 to 591 on import.
That is reported as its own state rather than counted as coverage, and rather than being written
off as a blind guard.

**The one operator action:** `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-910 --owner agent`
— then the close runs itself. This is the third task this session that `fw note promote` has left
in a state an agent cannot finish; that pattern is G-027 and is worth a decision of its own.

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

### 2026-09-28 — one shared derivation, not a registry that walks every aef: element (AC6)
- **Chose:** generalise into ONE shared `deriveEmittedAttrs()` / `checkElementDenominator()` pair,
  used by both `aef:workflowMeta` and `aef:laneMeta`. Not a third special case, and not a registry
  that walks every `aef:` element.
- **Why:** the emitter writes **23 distinct `aef:` element names**, and **21 of them are
  NODE-level**, already inside `checkDenominator()`'s scope via `aefExtensionXml()`. A
  "register every `aef:` element" check would begin life with 21 entries needing blanket
  exclusions — the permanently-red rail OBS-293 names, which trains readers to ignore it. Only
  **two** container-level elements exist, and they now share one derivation, so a third arrives by
  adding data rather than by writing a third checker.
- **Rejected:** (a) a second hand-written derivation — that is the T-322 defect, a list checked
  only by its author re-reading the same source, which is the exact omission being repaired;
  (b) a full `aef:`-element registry — see above; the revisit trigger is a third *container-level*
  element, not a third element of any kind.
- **Recorded as OBS-419** so the next container element does not re-derive this.

### 2026-09-28 — @height stays compared, and NOT-EXERCISABLE is a fourth state
- **Chose:** keep `height` in the compared set; add **NOT-EXERCISABLE** as a distinct verdict,
  derived by comparing the *authored* wire value against the *parsed* value.
- **Why:** `height` came back BLIND on exactly one fixture. The cause is `growUnderDeclaredLanes()`,
  a deliberate import repair with its own guard (`tools/_t315-lane-grow-on-import-cdp.mjs`):
  `lane-capacity-large-spill.bpmn` authors `height="260"` and parses as **591**. Scoring that as
  BLIND blames the projection for a repair working as designed. It is `height` being *unreachable
  by the probe on that document*, which is a different fact with a different remedy.
- **Rejected:** (a) excluding `height` — it is genuinely live on the other 20 fixtures, and
  excluding it would have made the emitter free to drop it in silence again; (b) teaching the
  guard the repair's own arithmetic — that duplicates a rule in two places (T-322). Comparing
  authored against parsed is general: the next transform-on-import classifies itself.

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

### 2026-09-27T21:24:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-910-the-round-trip-guard-covers-aefworkflowm.md
- **Context:** Initial task creation

### 2026-09-27T22:08:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
