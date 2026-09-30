---
id: T-951
name: "Assert the stem == workflowMeta.id invariant across all three corpora (T-301 GO)"
description: >
  Assert the stem == workflowMeta.id invariant across all three corpora (T-301 GO)

status: started-work
workflow_type: build
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
created: 2026-09-30T18:15:41Z
last_update: 2026-09-30T18:15:41Z
date_finished: null
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

# T-951: Assert the stem == workflowMeta.id invariant across all three corpora (T-301 GO)

## Context

Build task authorised by **T-301 GO** (2026-08-20), the only genuinely un-acted GO decision
of the 27 the T-949 triage examined. Its GO overturned an earlier DEFER and nothing followed
for 41 days.

**Two identities name the same map and only a convention keeps them equal.** The *store card
id* is the file stem — the browser fetches `rendered/<m.id>.bpmn` and the server keys versions
by it. The *document id* is `state.workflowMeta.id`, derived inside `parseBpmnXml` from the
document's own bytes. `openProjectMap` (`src/aef-workflow-designer.html:8756`) fetches by card
id, hands the bytes to `adoptImportedXml`, which re-derives the id from the document and sets
`activeKey` to *that*. From then on the card id is gone, and both reported symptoms follow
from the one divergence:

- `openVersionsModal` fetches `/api/versions?id=state.workflowMeta.id` → **empty panel**
- `saveToProject` POSTs `{id: state.workflowMeta.id}` → **a forked project record**

**The GO's scope is deliberately NOT a code fix.** Its reasoning: the editor *cannot* produce
the divergence (every editor write path keys the card by `workflowMeta.id`); the *store* can,
and did — `t101-review-audit-process` was a store-level copy of `audit-process` whose bytes
still said `audit-process`. So an editor-side guard would protect the path that was never the
source. The honest guard is a corpus check, which *"would have caught the reported instance
the day it appeared, costs one file walk, and is the only thing here that is cheap and catches
the real producer."*

**Why now rather than later.** T-501's drafted remediation derives identity via
`deriveSlug(procId)`, and `deriveSlug('customer-refund') === 'customer'`. If that ships, this
defect fires for the first time on a real served document. The GO argues for landing the
invariant check *before* any T-501 build task, not after.

**The derivation moved after the GO was written.** T-301's evidence says `customer-refund.bpmn`
derives its id from `<bpmn:process name>`. T-563 has since changed the chain to
`aef:workflowMeta[@id] || sanitizeWorkflowId(procId) || sanitizeWorkflowId(procName) ||
'imported'` (`:11210`), with the authored id deliberately **not** sanitized. The check must
replicate *that* chain, or it measures a derivation the editor no longer performs.

Explicitly out of scope per the GO: changing `openProjectMap`, changing T-263's
workflowMeta-id-wins ruling, or carrying the card id through `adoptImportedXml`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_t301-id-stem-invariant.py` asserts `card id == derived workflowMeta.id` across
      **all three** populations: `examples/aef-processes/rendered/*.bpmn`,
      `build/gallery/rendered/*.bpmn`, and `.editor-versions/*/v*.bpmn` — where for the third
      the card id is the **directory name**, which is the population the reported instance
      actually lived in.
      **Extended to a FOURTH root, with reasoning.** `build/gallery/rendered` is *untracked
      build output*, and the one document that diverges is sourced from
      `examples/app-processes/customer-refund.workflow.yaml` →
      `examples/app-processes/rendered/`, which **is** tracked. Watching only the build copy
      would guard an artifact while the tracked source drifted underneath it.
- [x] The id derivation replicates `src/aef-workflow-designer.html:11210` exactly, including
      that an authored `aef:workflowMeta[@id]` is used **unsanitized** while the two fallback
      legs are sanitized through `sanitizeWorkflowId`'s five transforms. Proven by asserting
      the check's own derivation against named corpus documents, not by reading the code.
      Four teeth legs pin it: MixedCase authored id matches an identical stem, the same id
      lowercased in the stem **diverges** (no case folding), `Pool_customer_refund`
      sanitizes to `pool_customer_refund`, and **procId beats procName**.
- [x] **A divergent fixture is caught.** A synthesised card whose bytes declare a different id
      than its stem must make the check exit non-zero and name both ids. This is the leg the
      GO explicitly asked for.
      Two legs: a rendered card (`review-copy` stem / `original` bytes) and a store card
      (`.editor-versions/t101-review-audit-process/v1.bpmn` carrying `audit-process`), the
      second reproducing the originally reported instance from scratch.
- [x] **An empty population is not a pass** (T-3105). If any of the three roots contributes
      zero documents the check says so and refuses to report success for that root — a walk
      that found nothing must not read as "invariant holds".
      Two legs: no corpus at all → **rc=3 COULD-NOT-MEASURE**; one populated root beside
      empty ones → **NOT EVALUATED** per root and a non-zero exit, so scope cannot shrink
      silently.
- [x] Wired into `tests/run-bridge-tests.sh`.
- [x] The current corpus state is **measured and recorded**, not assumed. T-301 measured 0
      divergences over 49 rendered documents and 24 store cards on 2026-08-20; this task
      re-measures and states the number, whatever it is.
      **Measured 2026-09-30: 128 documents across 4 roots — 126 derive from an authored
      `aef:workflowMeta[@id]`, 2 from the `procId` fallback, and BOTH of those diverge.**
      The divergence is `customer-refund` (card) vs `pool_customer_refund` (document), in
      the tracked source and its untracked build copy.
      **So the invariant does NOT hold today, and T-301's prediction was right about the
      file and wrong about the cause.** T-301 expected T-501 to activate this defect via
      `deriveSlug`. It was already live: **T-563** reordered the chain to put `procId`
      before `procName`, and this is the only served document with no `aef:workflowMeta`
      to pin its id — so the "equal to its stem by luck" that T-301 measured stopped being
      true, without anyone touching T-501.
- [x] The live divergence is **recorded with a reason, not silenced**, in
      `tools/_t301-known-divergences.txt`, and the check prints it on every run. A baseline
      entry whose divergence disappears is reported as **stale** (the `_t517` inference), so
      the ratchet cannot become a permanent hole. Not fixed in this task on purpose: adding
      `<aef:workflowMeta>` to that document may destroy its value as the one
      metadata-less third-party-import fixture, and T-563's notes are explicit that moving
      corpus bytes is a seam event watched by `_t308`/`_t358`. That is an operator call.

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

# --- T-951 (T-301 GO) --------------------------------------------------------
# The invariant check runs clean against the live corpus, with the one live divergence
# recorded rather than silenced.
python3 tools/_t301-id-stem-invariant.py
# It BITES: 11 legs including the divergent fixture the GO asked for by name, the
# derivation chain from src:11210, and both empty-population refusals.
bash tools/_t301-invariant-teeth.sh
# The recorded divergence carries a reason (the format requires one) and names the file.
grep -q 'customer-refund | pool_customer_refund |' tools/_t301-known-divergences.txt
# The derivation is pinned to the editor's real namespace and its real chain order,
# not to a guess. Both of these were wrong in the first cut.
grep -q 'anchorpoint.framework/aef/extensions' tools/_t301-id-stem-invariant.py
grep -q 'anchorpoint.framework/aef/extensions' src/aef-workflow-designer.html
# All four corpus roots are in scope, including the tracked app-processes source.
grep -q 'examples/app-processes/rendered' tools/_t301-id-stem-invariant.py
grep -q 'examples/aef-processes/rendered' tools/_t301-id-stem-invariant.py
grep -q 'build/gallery/rendered' tools/_t301-id-stem-invariant.py
# Reachable from something other than this one-shot gate (PL-161, PL-363).
grep -q '_t301-invariant-teeth.sh' tests/run-bridge-tests.sh
grep -q '_t301-id-stem-invariant.py' tests/run-bridge-tests.sh
bash -n tests/run-bridge-tests.sh
# The measurement this task reports is reproducible: 128 documents, 4 populated roots.
# Positive assertion against the check's own output, with the count read from the run
# rather than hard-coded into a grep of prose (T-3326 — pin the invariant, and a
# shrinking corpus should fail the empty-root leg above, not this one).
python3 tools/_t301-id-stem-invariant.py > /tmp/.t301-measure.out 2>&1 && grep -qE 'examined [0-9]+ document\(s\) across 4 populated root\(s\)' /tmp/.t301-measure.out

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

### 2026-09-30T18:15:41Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-951-assert-the-stem--workflowmetaid-invarian.md
- **Context:** Initial task creation
