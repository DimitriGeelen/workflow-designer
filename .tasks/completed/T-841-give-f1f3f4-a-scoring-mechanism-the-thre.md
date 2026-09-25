---
id: T-841
name: "Give F1/F3/F4 a scoring mechanism: the three weight-9 drivers cannot be scored at all"
description: >
  Root cause of SQ-6, named by 1.7.68's new audit (lib/bvp-scorability.sh, AEF T-3427/T-3428). F1 V_SDLC_ENABLEMENT, F3 V_AEF_INTEGRATION and F4 V_WORKFLOW_ROUTING each carry weight 9 - the three highest in the model, 27 of total weight - and each has NEITHER a handler NOR a declarative scoring: spec. Per the audit: 'cannot be scored, so it contributes nothing to any ranking while its weight and rubric read as a live axis'. T-3427 omits them from the normalisation denominator. So every task in this project scores structurally 0 on all three, always, and cannot do otherwise - which is the mechanism behind what we raised as SQ-6 (no-signal rendered as evidence of no value) and why T-826, an AEF-integration task, reads lv while serving F3 at weight 9. Deliverable this task: drafted and VALIDATED scoring specs for all three, dry-run with fw bvp driver --explain --scoring-file against real tasks, and the ranking delta measured. ATTACHING them is NOT in scope: --scoring-file only attaches via --add (new drivers), there is no verb to give an EXISTING driver a mechanism, hand-editing is forbidden by the schema header, and --add/--remove are ACD-gated. That gap is a finding for AEF and the attach is the operator's.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t841-scoring-spec-controls.sh]
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
created: 2026-09-25T07:49:50Z
last_update: 2026-09-25T08:46:41Z
date_finished: 2026-09-25T08:46:41Z
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

# T-841: Give F1/F3/F4 a scoring mechanism: the three weight-9 drivers cannot be scored at all

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The defect is stated as the audit states it, with the weights.** F1 V_SDLC_ENABLEMENT,
      F3 V_AEF_INTEGRATION, F4 V_WORKFLOW_ROUTING — each `weight: 9`, together 27 of total
      weight — have neither a handler nor a `scoring:` spec, so `lib/bvp-scorability.sh` WARNs
      per driver and T-3427 omits them from the normalisation denominator. Every task scores a
      structural 0 on all three and cannot do otherwise.

- [x] ~~Each spec is derived from the driver's OWN declared rubric~~ **WITHDRAWN — THERE IS NO
      RUBRIC TO DERIVE FROM.** Measured: F1, F3 and F4 carry only `id`, `name`, `weight: 9`,
      `protected: false` and a one-line `rationale`. No `rubric`, no `polarity`, no `guardrails`,
      no `retire_when`. Contrast F-RECALL and F2, which carry all five. All three rationales are
      sourced "operator directive 2026-08-16" and read, in full:
      F4 "anything improving workflow routing / clean workflows" · F3 "anything improving
      integration into AEF" · F1 "anything enhancing workflow capability to support a software
      development process built on the workflows".
      So the axes were named at the top weight in the model and never given levels. This AC
      assumed a rubric existed; it does not, and the assumption is recorded rather than
      quietly restated.

- [x] **The level ladders are PROPOSED, and marked as proposals throughout.** With no rubric,
      any 0–5 ladder is a judgement about what the operator's own value model means — what
      counts as L1 vs L5 AEF-integration. That is theirs. The ladders follow the house pattern
      set by F-RECALL and F2 (0–5 plus guardrails plus polarity) and each level cites the clause
      of the one-line rationale it claims to encode, so the operator can see exactly where a
      reading was supplied rather than derived. **Nothing is installed.**

- [x] **The rubric absence is raised as a Sovereign question in its own right.** Three weight-9
      drivers with no levels is not a mechanism gap that a spec fixes — it is an unfinished
      policy decision from 2026-08-16 that has silently zeroed 27 of the model's weight for 40
      days. A spec written over it encodes the agent's reading of the operator's intent, which
      is exactly what "surfaced, not resolved" exists to prevent.

- [x] **Every spec passes `fw bvp driver --validate-scoring`.** Recorded verbatim, all three.

- [x] **THE TEMPLATE TRAP IS TESTED, NOT ASSUMED.** The schema warns that a keyword drawn from
      `.tasks/templates/default.md` matches every task uniformly, so the driver ranks nothing
      while appearing to work — measured on consumer 1409-sprind. For each spec: run
      `--explain` against a task the driver SHOULD score high and one it should score 0, and
      show the scores DIFFER. A spec that returns the same level for both has not been shown to
      discriminate, whatever `--validate-scoring` says about its shape.

- [x] **T-826 is one of the explain targets, and its F3 result is recorded.** It is an
      AEF-integration task (AEF's own `kind=documentation|work-plan` ruling) currently reading
      `lv` at BVP 79. If F3 scores it 0 under a spec derived from F3's rubric, the spec is wrong
      or the rubric is — either way that is the finding, reported rather than tuned away.

- [x] **The ranking delta is measured, not asserted.** With the specs supplied via
      `--scoring-file`, how many of the currently-`lv` tasks would move, and does any reach Q1.
      Reported as a table. This is the number that tells the operator what their ruling buys.

- [x] **Nothing is attached, and the reason is recorded.** `--scoring-file` attaches only via
      `fw bvp driver --add` (new drivers); there is no verb to give an EXISTING driver a
      mechanism. Hand-editing is forbidden by the schema header ("never hand-edit a spec into
      this file — the verbs validate"), and `--add`/`--remove` are §ACD-gated. Verified by
      `.context/working/.gate-bypass-log.yaml` carrying no new entry for this task, and by
      `policy/value-drivers.yaml` being unmodified.

- [x] **The verb-surface gap is filed for AEF.** The audit WARNs on three existing drivers while
      the only remedy it names (`--add --scoring-file`) cannot address an existing driver. That
      is a gap between the check and the fix path, and it is upstream's.

#### Recorded shortfalls on the ticks above

Three of the nine ticks carry a qualification. Ticking them without saying so would be the
false-green this task is otherwise about.

**AC "raised as a Sovereign question" — satisfied only as PROSE, and that is the known
defect.** There is no Sovereign-question register in this project: no file, no id
allocator, no status field, and no instrument that can answer "which Sovereign questions
are open". So SQ-8 is recorded in `docs/reports/T-841-scoring-mechanism-measurement.md`
and in concern **G-080**, following the G-055 / G-061 precedent of naming an SQ from a
concern. That is the most durable home available and it is still prose — exactly the
failure PL-145 names (a ruling filed as prose is invisible to instruments), applied here
to the QUESTION rather than the ruling. Not fixed here: one bug, one task, and the remedy
(new register vs. a concern type) is an architectural decision that is the operator's.

**AC "THE TEMPLATE TRAP IS TESTED" — the test RAN and TWO OF THREE SPECS FAILED IT.** The
AC asks that scores DIFFER between a task the driver should score high and one it should
score 0. F3 passes (T-826=3, T-839=0, and 6 distinct levels across 44 tasks). F1 and F4 do
not: 93.2% and 86.4% of 44 tasks land on a single level. The AC is ticked because the test
was performed and reported, not because all three passed. **F1 and F4 are tabled as
measured failures, deliberately not tuned** — fitting their keywords until a 44-task
spread looked better would fit them to this corpus rather than to a meaning, and the next
44 tasks would resaturate. Cause was mine and is recorded in the report: I drew their
L4/L5 keywords from my own authoring vocabulary, so the specs measured who wrote the task.

**AC "the ranking delta is measured, not asserted" — measured, with an arithmetic limit
recorded.** The migration (median BVP 80 -> 98; 4 promoted lv->hv, 4 demoted; T-826
79 -> 106) is my arithmetic over `--explain` output, applying `+9 x F3` and re-deriving the
median. It is not the ranker's own number. T-3427's normalisation denominator also changes
when a driver becomes scorable, so NORM and the cost axis may shift in ways this does not
capture. **The true post-attach ranking cannot be measured without attaching, and
attaching is gated** — which is the verb-surface gap itself, not a shortcut I declined to
take. Read the migration as sound in direction, approximate in magnitude. An earlier
fixed-threshold pass claimed 10 promotions; that was wrong and is superseded.


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

# ── T-841 legs ────────────────────────────────────────────────────────────────
# Each leg below is paired with a control inside tools/_t841-scoring-spec-controls.sh
# that was SHOWN to fail on a mutant. Leg 2 is the one that matters: it asserts the
# controls actually RAN, because a control instrument nobody re-runs starts misinforming
# (PL-332) and an all-green run with zero controls is indistinguishable from a dead one.

out=$(bash tools/_t841-scoring-spec-controls.sh 2>&1); echo "$out" | grep -q '^# passed ' && ! echo "$out" | grep -q '^not ok'
out=$(bash tools/_t841-scoring-spec-controls.sh 2>&1); test "$(echo "$out" | grep -c 'CONTROL leg-')" -ge 6

# All three PROPOSED specs still validate. Sub-shell so every iteration counts, not just
# the last (the `cmd1; cmd2` trap documented above).
bash -c 'set -eo pipefail; for f in F1-sdlc-enablement F3-aef-integration F4-workflow-routing; do .agentic-framework/bin/fw bvp driver --validate-scoring "docs/proposals/T-841-$f-PROPOSED.yaml" >/dev/null; done'

# The measurement record carries the two findings it claims to carry. Pinned on phrases
# that are conclusions, not on live counts (T-3326).
#
# THIS LEG WAS WRONG ON ITS FIRST WRITING AND THE DEFECT IS THE ONE T-803 NAMED: it
# greped 'modal level 0', a phrase from my own shell output that I remembered writing,
# rather than one that is in the report — where the modal level is a bare table cell.
# Caught by rehearsing under `bash -c 'set -o pipefail; ...'` before closing, which is
# the only reason it did not ship green-looking and dead.
R=docs/reports/T-841-scoring-mechanism-measurement.md; grep -q '93.2' "$R" && grep -q '86.4' "$R" && grep -q '79 -> 106' "$R" && grep -q 'Saturation at the floor is a measurement' "$R"

# NOTHING WAS INSTALLED. The task's central negative claim.
git diff --quiet HEAD -- .agentic-framework/policy/value-drivers.yaml

# No gate was bypassed under this task id. Scoped to T-841 only — asserting the log has
# "no diff at all" would be a false claim about other sessions' rows (T-839's lesson).
! grep -q 'T-841' .context/working/.gate-bypass-log.yaml
#
# ── CONTROL LEGS APPENDED AFTER CLOSE, under PD-308, by T-669 ─────────────────
# The absence assertion directly above shipped UNCONTROLLED and _t560's census counted it
# as one of the 122. It is the defect this very task argued against: if the bypass log were
# deleted or renamed, `! grep -q` passes vacuously and reports a clean result. I wrote a
# 13-leg control instrument for this task and then shipped an uncontrolled absence
# assertion beside it.
#
# TWO controls, not one, because _t560's header is explicit that they catch different
# mistakes and are NOT interchangeable: PATTERN catches a wrong pattern, EXISTENCE catches
# a wrong path, and reading `test -f X && ! grep -q P X` as fully controlled is "the exact
# overstatement this tool exists to avoid". The first leg's own grep pattern is the SAME
# STRING as the absence assertion's — required, because an earlier attempt was credited for
# a control whose pattern merely APPEARED nearby, and mention is not invocation.
# Nothing above was altered; these lines are additions only.
grep -q 'T-841' docs/reports/T-841-scoring-mechanism-measurement.md
test -f .context/working/.gate-bypass-log.yaml

# G-080 is registered AND the register still parses. Both halves matter: an unparseable
# concerns.yaml with G-080 in it is not a registration, it is a broken file.
python3 -c "import yaml,sys; c=yaml.safe_load(open('.context/project/concerns.yaml'))['concerns']; sys.exit(0 if any(isinstance(e,dict) and e.get('id')=='G-080' for e in c) else 1)"

# DELIBERATELY NOT A LEG: that the AEF post landed. It went to framework:pickup via the
# MCP surface (posting via Bash is forbidden here), so no shell leg can read it back
# without violating that boundary — and a rail offset is not evidence in any case. The
# post's CONTENT is quoted in this task's Recommendation section instead, which is the
# house rule: quote inline, do not cite a timestamp.

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

**Recommendation:** GO on F3 as a PROPOSAL for the operator to rule on; NO-GO on F1 and F4.

**Rationale:** The task's deliverable was drafted, validated and dry-run specs plus a
measured ranking delta — all delivered. F3 earns its proposal: it discriminates across six
levels on 44 tasks and it reproduces SQ-6 by name, lifting T-826 from 79 to 106 and across
the hv threshold. F1 and F4 do not and should not be tabled as candidates: 93.2% and 86.4%
of tasks land on one level, so attaching either would add weight to the model without
adding information — the same defect as leaving them unscored, wearing a mechanism's
clothes. Nothing is installed either way; attaching is the operator's and the verb to do it
does not exist upstream yet.

**Evidence:**
- Three specs pass `--validate-scoring`; two of the three rank nothing. Shape validation
  cannot see saturation.
- F3 level spread over 44 lv tasks: `0:26 1:1 2:3 3:12 4:1 5:1`. F1: `4:41` of 44. F4:
  `5:38` of 44.
- Ranking delta, F3 alone: median BVP 80 -> 98, 8 of 82 tasks change quadrant, T-826
  79 -> 106. Arithmetic limit recorded — the true post-attach ranking needs the attach.
- `policy/value-drivers.yaml` unmodified against HEAD; no bypass-log entry for T-841.
- 13/13 on `tools/_t841-scoring-spec-controls.sh`, every leg paired with a control that
  was shown to fire on a mutant.

### Sent to AEF — content quoted inline (rail offsets are not evidence)

Posted to `framework:pickup` via the MCP surface, `metadata.from_project=832-Workflow-designer`,
`origin_task=T-841`. Two findings, both discovered while trying to ACT on 1.7.68's own WARN:

**Finding 1 — the audit's named remedy cannot reach the drivers the audit flags.** The WARN
tells the reader to draft a spec, validate it, and try it with `--explain --scoring-file`;
`--validate-scoring`'s success output then says *"Attach it to a driver with: fw bvp driver
--add ... --scoring-file <file>"*. But `--add` creates a NEW driver. `--scoring-file` is
accepted by `--add` and `--explain` and nothing else. There is no verb that gives an
existing driver a mechanism, hand-editing is forbidden by the schema header, and
`--add`/`--remove` are ACD-gated. A consumer following the advice literally would have to
remove a live policy axis and re-add it under a new id. Suggested: a `--set-scoring Fn
--scoring-file FILE` verb; ACD-gating it is fine, the gate is not the problem, the absence
is. Consequence named for them: a check whose remedy cannot be applied trains readers to
skip the check — ours sat 40 days, and when we finally read it the fix path did not exist.

**Finding 2 — `--validate-scoring` passes specs that rank nothing**, with our three specs
and their level distributions as the worked example, plus the asymmetry we think belongs in
their schema docs: saturation at 0 is a measurement (most tasks genuinely do not touch the
seam, and `L0: no signal` stays in the denominator), saturation at 5 is flattery. And the
trap distinct from the one they already document: we drew F1/F4's L4/L5 keywords from our
own authoring vocabulary, so the specs measured *who wrote the task*. `strip_template: true`
cannot help — the saturating vocabulary is not in `default.md`, it is in the author.
Suggested: `--explain --corpus` reporting level distribution and modal share, warning above
~70% modal share.

Explicitly NOT asked for: no bump, no branch action, no ruling on our ladders. The rubric
absence is our operator's call and is parked as G-080 / SQ-8.

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

### 2026-09-25T07:49:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-841-give-f1f3f4-a-scoring-mechanism-the-thre.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-dbdc9153
- **Timestamp:** 2026-09-25T08:46:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-25T08:46:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
