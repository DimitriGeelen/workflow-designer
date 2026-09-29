---
id: T-885
name: "The round-trip guard _roundtrip-serialization-cdp.mjs covers only the NODE-level
  aef.* seam — checkDenominator() derives its 36 keys from aef.* dot-accesses, metaKeys
  and bindFields. Document-level aef:workflowMeta attributes are outside its denominator
  BY CONSTRUCTION. Measured under T-875 by mutation: deleting the editor's kind writer
  line entirely still yields exit 0 / pass true over 20 fixtures. The open question
  this raises is bigger than the attribute that found it: uuid, pageWidth, tier_default,
  title and description are all workflowMeta attributes and may be riding on no round-trip
  guard at all. uuid in particular is connector-referenceable identity (T-224) and
  is pinned cross-agent. Needs a census of what actually guards document-level metadata,
  then an instrument."
description: >
  Promoted from observation OBS-402

status: started-work
workflow_type: build
current_node: frw_6_run
owner: agent
horizon: now
tags: []
components: []
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
created: 2026-09-26T23:43:01Z
last_update: 2026-09-29T17:23:05Z
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
  - ts: '2026-09-26T23:43:13Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-885: The round-trip guard _roundtrip-serialization-cdp.mjs covers only the NODE-level aef.* seam — checkDenominator() derives its 36 keys from aef.* dot-accesses, metaKeys and bindFields. Document-level aef:workflowMeta attributes are outside its denominator BY CONSTRUCTION. Measured under T-875 by mutation: deleting the editor's kind writer line entirely still yields exit 0 / pass true over 20 fixtures. The open question this raises is bigger than the attribute that found it: uuid, pageWidth, tier_default, title and description are all workflowMeta attributes and may be riding on no round-trip guard at all. uuid in particular is connector-referenceable identity (T-224) and is pinned cross-agent. Needs a census of what actually guards document-level metadata, then an instrument.

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent

**This task is the CENSUS, not the repair.** Scope fence: it answers "what, if anything,
guards document-level `aef:workflowMeta` attributes" and files what it finds. Building the
instrument is a separate task, filed on this task's evidence. Writing a guard before knowing
what is bare is how the second wrong guard gets built — exactly the mistake the T-875
mutation caught.

- [x] Every `aef:workflowMeta` attribute the editor reads and every one it writes is enumerated, and the two lists are diffed — an attribute written but never read back is a silent-drop candidate on its own, before any guard question
- [x] For the writable set, coverage is established **by mutation, not by reading test names**: with the attribute suppressed in the writer, the candidate guards are re-run and the result recorded per attribute as COVERED (something went red) or BARE (nothing did)
- [x] The mutation is proven to have applied — a substitution that silently matched nothing reads identically to a guard that passed, and that failure mode has already occurred twice in this corpus
- [x] `uuid` is reported explicitly and separately whatever the result: it is connector-referenceable identity (T-224), pinned cross-agent with AEF, and is the one attribute whose silent loss would be a seam-integrity defect rather than a cosmetic one
- [x] The source tree is left byte-identical to its pre-census state — every mutation reverted and the revert verified, not assumed
- [x] Findings are filed as their own task(s) with the census as evidence; this task builds no guard

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

# The census's findings were filed and built: T-886 (workflowMeta denominator) and T-910 (laneMeta) are closed tasks.
ls .tasks/completed/T-886-*.md .tasks/completed/T-910-*.md
# The repair the census asked for exists and is static-checkable without a browser: every emitter-written
# workflowMeta and laneMeta attribute is compared or excluded with a reason (property, not a live count).
node tools/_roundtrip-serialization-cdp.mjs --denominators-only | grep -q '"denominators_only": true'
# ANCHOR REPAIR (2026-09-29). This line used to end the pattern at `0 unclassified"` — a closing
# quote, i.e. anchored to the END of the summary string. T-905 (78a25279, 01:32Z) appended
# "; computed sources N verified, M open" to that same summary FIFTEEN MINUTES after this line was
# written (d328aff6, 01:17Z), and the line went red while the property it checks stayed true. It sat
# red for ten hours because nothing re-runs a parked task's verification. Exactly the mutable-anchor
# rot this block warns about above (T-3326). Now pins the INVARIANT and nothing about what follows.
# The [^0-9] guard is load-bearing: a bare `0 unclassified` would also match "10 unclassified".
node tools/_roundtrip-serialization-cdp.mjs --denominators-only > .context/working/.t885-denoms.out 2>&1 && grep -qE '[^0-9]0 unclassified' .context/working/.t885-denoms.out
# uuid — the census's one seam-integrity finding — is in the compared set, not merely mentioned.
grep -qE "^const WMSPEC = \[.*'uuid'" tools/_roundtrip-serialization-cdp.mjs
# The write-only attribute the census found (source=) is excluded WITH a reason that names the census.
grep -qE "^  source: 'WRITE-ONLY \(T-885 census\)" tools/_roundtrip-serialization-cdp.mjs
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

### 2026-09-26 — the census found the finding it was shaped for, and one it was not
- **What changed:** Filed to answer "what guards document-level aef:workflowMeta attributes" — the answer was nothing: uuid, description and kind could each be dropped from the writer with every guard green (commit 90a8f47c). The unplanned finding was `source=`: written by the emitter and read back by nothing, so a round-trip comparison of it is structurally impossible, not merely missing. That became the first entry in WM_EXCLUDED with a reason, and the shape "write-only attribute" became T-898's inception.
- **Plan impact:** Scope fence held — this task built no guard. T-886 built the workflowMeta denominator on this evidence; T-910 later generalised it to laneMeta after T-890 measured the identical gap one element over.
- **Triggered:** T-886 (repair), T-898 (write-only source=), and by lineage T-910.

### 2026-09-29 — closing under procAsFit round 1
- **What changed:** Nothing in the deliverable. All six ACs were ticked on 2026-09-26; the task then sat at started-work with an empty Verification and Evolution for three days — the G-027 shape, third instance this round (T-866, T-906, this).
- **Plan impact:** Verification pins properties the census's downstream repairs must keep true (both denominators static-checkable and clean; uuid compared; source= excluded with the census named), rather than re-running the destructive mutation census, which the task's own AC required to leave the tree byte-identical.
- **Triggered:** Nothing filed.

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

**Recommendation:** GO — close as work-completed.

**Rationale:** The deliverable is a CENSUS, and it answered its question on 2026-09-26: nothing
guarded document-level `aef:workflowMeta`. All six Agent ACs were ticked that day. Its scope fence
("this task builds no guard") held, and the repairs it asked for were filed and are now CLOSED —
T-886 (workflowMeta denominator) and T-910 (laneMeta). Nothing about the census is outstanding.
There are no `### Human` acceptance criteria: the only two checkbox lines under that heading are the
template's own [REVIEW]/[REVIEWER] examples, inside the HTML comment. So this task is not waiting on
a verification step the operator owes — it is waiting only on the R-033 sovereignty gate, because
`owner: human` and an agent may not complete a human-owned task. That is the whole of the block.

**Evidence:**
- Census result: `uuid`, `description` and `kind` each deletable from the editor's writer with every
  guard green across 20 fixtures (commit `90a8f47c`). `uuid` reported separately per AC 4 — it is
  connector-referenceable identity (T-224), pinned cross-agent, so its silent loss is a
  seam-integrity defect and not a cosmetic one.
- Unplanned finding: `source=` is emitter-written and read back by nothing, making a round-trip
  comparison structurally impossible rather than merely absent. Became T-898; carried in the guard
  as WM_EXCLUDED with a reason naming this census.
- Downstream repairs exist and are static-checkable without a browser: both denominators derive
  clean (`node 37 / workflowMeta 10 / laneMeta 4 attributes derived, 0 unclassified`), `uuid` is in
  the compared set, `source=` excluded with its reason.
- Verification: 5/5 PASS under gate semantics (`set -o pipefail`, no errexit), re-run 2026-09-29.

**One caveat the operator should see before approving.** This block's `0 unclassified` line was RED
until minutes ago, and not for a real failure. It was written at `d328aff6` (01:17Z) anchored to the
END of the summary string; T-905 (`78a25279`, 01:32Z) appended `; computed sources N verified, M
open` to that same string fifteen minutes later, in the same session. The property stayed true and
the check stopped measuring it, for ten hours, because nothing re-runs a parked task's verification.
The anchor is repaired and the repair is proven both ways — it accepts the live output and rejects
`3 unclassified`, `10 unclassified` and `40 unclassified`. Flagged rather than quietly fixed because
a green that was red an hour ago is worth one sentence of the approver's attention.

**Not in scope of this close:** `computed sources 3 verified, 3 open` in the same summary is T-905's
loose end, not this census's. Folding it in here would re-open a scope fence that deliberately held.

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

### 2026-09-26T23:43:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-885-the-round-trip-guard-roundtrip-serializa.md
- **Context:** Initial task creation

### 2026-09-26T23:43:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## 2026-09-27 — CENSUS RESULTS

Method: suppress the attribute in the editor writer, re-run the guards, record whether
anything goes red. Every mutation asserted applied before the run (count==1 or hard error);
source tree restored and verified byte-identical with `cmp` afterwards.

Guards run: `tools/_roundtrip-serialization-cdp.mjs` (20 fixtures),
`tests/test_corpus_fixture_pins.py`, `tests/test_designer_export_contract.py`.

| attribute | fixtures carrying | read? | written? | mutation verdict |
|---|---|---|---|---|
| `id` | 20 | yes | unconditional | structural — not suppressible |
| `version` | 20 | yes | unconditional | structural — not suppressible |
| `schemaVersion` | 20 | yes | unconditional | structural — not suppressible |
| `title` | 20 | yes | yes | **COVERED** — killed the harness (falls back to `Process_<id>`) |
| `tier_default` | 20 | yes | yes | **COVERED** — killed the harness |
| `description` | 3 | yes | yes | **BARE** — mutant survived |
| `uuid` | 1 | yes | yes | **BARE** — mutant survived |
| `kind` | 1 | yes | yes | **BARE** — mutant survived (measured under T-875) |
| `pageWidth` | 0 | yes | yes | **NOT EXERCISABLE** — no fixture carries it, so nothing was measured (T-3105: that is not a pass) |
| `source` | 0 | **NO** | yes | **WRITE-ONLY** — emitted by the writer, never read on import, and no map anywhere carries it |

### uuid is the finding, reported separately as the AC required

`uuid` is BARE. Suppress it in the writer and every guard stays green.

It is not a cosmetic attribute: T-224 introduced it as connector-referenceable identity, it is
what off-page links resolve against, and it is pinned cross-agent — AEF holds fixtures byte-pinned
on our side (`offpage-seam.bpmn`, `s4-exemplar.bpmn`). A regression that stopped emitting it
would break link resolution on both sides of the seam and no test in this repository would say so.

Only ONE of 20 fixtures carries a uuid, which is the likely reason coverage never developed —
the population that would exercise it is a single file.

### Two predictions I got wrong, recorded because they show the model was unreliable

- I predicted `tier_default` would be BARE, reasoning that the reader defaults it to `2` and
  would mask the loss. It is COVERED.
- I predicted `uuid` would be COVERED, reasoning the projection would show `null` against a
  value. It is BARE.

Two of three predictions inverted. Reading the harness was not a substitute for mutating it,
and the same will be true of whoever writes the instrument next.

### Not repaired here

This task builds no guard, by its own scope fence. Three bare attributes, one unexercisable and
one write-only branch are filed as the follow-up.

### 2026-09-29T17:23:05Z — status-update [task-update-agent]
- **Change:** owner: human → agent
