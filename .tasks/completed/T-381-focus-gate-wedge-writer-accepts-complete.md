---
id: T-381
name: "focus gate wedge: fw context focus accepts a completed task id its own reader
  rejects"
description: >
  `fw context focus <id>` validated existence (active/ OR completed/) while the task
  gate requires activeness (active/ only), so focusing a completed task succeeded
  and
  then blocked every gated Write/Edit/Bash. Writer now requires what its reader requires.
  Filed originally with a second claim — that the write-pattern precheck disarmed
  the
  bootstrap exemption and left no in-band recovery. MEASURED AND DISPROVED (see RCA):
  every remedy the block message prints is allowed while wedged. Title corrected.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T15:17:56Z
last_update: '2026-08-16T12:33:54Z'
date_finished: 2026-08-08T15:25:37Z
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
  - ts: '2026-08-16T12:33:54Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-381: focus gate wedge: `fw context focus` accepts a completed task id its own reader rejects

## Context

`fw context focus <id>` validates with `find_task_file "$id"` — **unscoped**, so it resolves
against `active/` AND `completed/` (agents/context/lib/focus.sh). The gate that reads the
value validates with `find_task_file "$CURRENT_TASK" active` — **scoped**
(agents/context/check-active-task.sh:387). The writer accepts a wider set than the reader
requires, so focusing a completed task succeeds and then blocks every gated Write/Edit/Bash.

Hit live in T-380 (`fw context focus T-005`, archived). Recovered only by editing
focus.yaml directly, because `.context/` is an exempt path.

**PL-020 (surfaced by recall at task creation):** *a write endpoint that validates input
FORMAT is not the same as validating that the value is USABLE by its reader.* Same class:
here the writer validates EXISTENCE where the reader requires ACTIVENESS.

Second, unmeasured mechanism: check-active-task.sh:92-107 tests `has_bash_write_pattern`
FIRST and the bootstrap exemption (`fw work-on|context focus|task create|inception`, T-2052)
is an `elif`. Any bootstrap command carrying a write pattern would therefore skip the
exemption and be judged on focus state — i.e. the printed remedy would be blocked by the
block. **This is a reading-derived hypothesis carried across a compaction boundary, not an
observation.** AC-2 measures it; AC-4 fixes it only if measurement confirms it.

## Acceptance Criteria

### Agent
- [x] **AC-1 — the wedge reproduces in isolation.** A sandbox project under the scratchpad
      (its own `.tasks/` + `.context/working/focus.yaml`, reached via the hook's stdin `cwd`
      re-anchor, T-2463) reproduced it pre-fix: `focus <completed-id>` exited 0 and the next
      gated Bash call was blocked citing "is not active". Post-fix the same legs assert the
      refusal instead; the pre-fix behaviour is re-derivable via the mutation run below. The
      live repo's own focus is never set to a completed id by the probe.
- [x] **AC-2 — the exit path is MEASURED, not assumed.** In the wedged sandbox, the hook is
      invoked with each printed remedy in BOTH forms: bare (`bin/fw context focus T-X`) and
      the CLAUDE.md-mandated single-line form (`cd <proj> && bin/fw context focus T-X`).
      Allowed/blocked is recorded for all four, and the result is reported whichever way it
      goes — a finding of "exemption works, my carried claim was wrong" is a valid outcome
      and must be stated as such.
- [x] **AC-3 — writer refuses a non-active id.** `do_focus` rejects an id that resolves only
      in `completed/`, with a message naming the id, its actual location, and the command to
      resume or create. Exit non-zero. A still-active id is unaffected.
- [x] **AC-4 — mechanism 2 resolved on the evidence.** If AC-2 shows the exemption is
      reachable, no code change is made and the non-result is recorded in Decisions. If it
      shows the exemption is disarmed, the ordering is fixed so a bootstrap command is exempt
      regardless of write-pattern content, and AC-2's probe legs flip to allowed.
- [x] **AC-5 — probe has teeth, proven by mutation.** `tools/_t381-focus-gate-wedge.sh`
      exercises AC-1/AC-2/AC-3. Every assertion is shown RED against the pre-fix tree (or a
      neutralised fix, `:` not deletion) before being believed, and each mutant is `bash -n`
      clean first so a syntax error cannot masquerade as a caught defect.
- [x] **AC-6 — no bypass used.** No `--force`, `--skip-*`, `--no-verify`, `FW_SAFE_MODE=1`
      or direct focus.yaml edit is used to complete this task.

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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.


# The probe's own exit code is the verdict ([ $FAIL -eq 0 ]) — single command, no
# capture/grep chain, so neither the T-352 errexit hole nor the L-387 SIGPIPE case
# applies. Output stays visible for the gate's failure excerpt.
bash /opt/832-Workflow-designer/tools/_t381-focus-gate-wedge.sh
# The fix itself: the writer must ask for the scope its reader requires.
# -F is load-bearing: without it the '$' in "$task_id" is read as a BRE metacharacter and
# the match fails against a file that is CORRECT — a red that sends the next reader to
# debug working code (probes-that-fail-when-right). Caught by dry-running this block.
grep -qF 'find_task_file "$task_id" active' /opt/832-Workflow-designer/.agentic-framework/agents/context/lib/focus.sh

## RCA

**Symptom:** `fw context focus T-005` (an archived task) exited 0 and set focus. Every
subsequent gated Write/Edit/Bash was then blocked with "Task T-005 is not active".

**Root cause:** writer/reader scope asymmetry on one shared value. `do_focus`
(agents/context/lib/focus.sh) validated with `find_task_file "$task_id"` — no scope
argument, which resolves `active/` then falls back to `completed/`. The gate that consumes
the value (check-active-task.sh:387, G-013) validates with
`find_task_file "$CURRENT_TASK" active`. **The writer's accepted set was a strict superset
of the reader's usable set**, and every id in the difference produces a state that is
writable but unusable. PL-020 class, generalised: validating that a value EXISTS is not
validating that its CONSUMER can use it. The framework already treated this state as
impossible — T-2054 records that `--status work-completed` nulls `current_task` *and* moves
the file to `completed/` precisely so it cannot be re-focused — but nothing enforced it on
the one path that could still write it.

**Why structurally allowed:** the two call sites are in different files, written for
different purposes, and the shared function's scope parameter is OPTIONAL with a permissive
default. Omitting an argument is invisible at the call site — `find_task_file "$id"` reads
as complete and correct in isolation. Nothing pairs the writer with its reader, so the
constraint lived only in the reader and there was no test that a focusable id is a usable
one.

**Prevention:** `tools/_t381-focus-gate-wedge.sh` asserts the round trip rather than either
end — an id the writer accepts must be an id the gate allows. It carries a control leg
(an ACTIVE id must still be accepted) so a blanket refusal cannot pass, and the entry leg
is proven RED against a `bash -n`-clean mutant that restores the unscoped lookup.

**A CLAIM I FILED WAS WRONG, AND THE MEASUREMENT IS THE POINT.** T-380 recorded that the
gate "blocked every Bash and Write call including `fw work-on` and `fw context focus` — the
exact remedy the block message prints", i.e. no in-band recovery. **Measured here: false.**
All four printed remedies are ALLOWED while wedged — `context focus` and `work-on`, in both
the bare form and the `cd … && …` form CLAUDE.md mandates. The T-2052 bootstrap exemption
(check-active-task.sh:98) works as documented. I recovered by editing focus.yaml directly
and inferred from that, plus the Write/Edit blocks I *had* seen, that the fw commands were
blocked too — I never ran one. **The diagnosis then crossed a compaction boundary, where it
kept its confidence and lost its evidence** ([[notes-carried-across-a-boundary]]), and I
came back this session ready to build an ordering fix for a deadlock that does not exist.
Only mechanism A is real. The severity I reported to the operator was overstated: a wedge
with an in-band exit is an annoyance, one without is a session-ender, and I reported the
second.

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

## Decisions

### 2026-08-08 — fix the writer, not the reader
- **Chose:** narrow `do_focus` to `find_task_file "$task_id" active`.
- **Why:** the reader's requirement is the real constraint (G-013: a focused task must be
  active, and the gate is the thing that enforces "nothing gets done without a task"). The
  asymmetry is the writer being too permissive, not the gate being too strict.
- **Rejected:** widening the gate to accept completed tasks — that would let work proceed
  under a closed task, which is the exact thing P-002 exists to prevent. Also rejected:
  auto-reopening the task on focus, which silently reverses a completion the human owns.

### 2026-08-08 — mechanism B: no code change, recorded as a disproved hypothesis
- **Chose:** leave check-active-task.sh:92-107 untouched.
- **Why:** AC-2 measured all four printed remedies as ALLOWED while wedged. The T-2052
  exemption is reachable; there is no deadlock to fix. Changing the ordering would have been
  a fix to a defect that does not exist, justified by a memory rather than a measurement.
- **Rejected:** reordering the exemption above the write-pattern precheck on the strength of
  the filed claim. This is the branch that nearly happened and is worth naming: I arrived
  this session with the fix already designed.

### 2026-08-08 — the probe measured the wrong tree under the gate's environment
- **Chose:** strip `PROJECT_ROOT`/`TASKS_DIR`/`CONTEXT_DIR`/`FRAMEWORK_ROOT` from the env for
  the probe's direct CLI calls (`fw_sb`), rather than relaxing the legs that went red.
- **Why:** P-011 runs the probe from inside update-task.sh, which has already exported those
  for the live repo; they win over `cd`, so the sandbox fixtures were invisible and
  `fw context focus T-901` answered "Task not found". Green in my shell, red in the gate —
  [[rehearsed-in-the-wrong-shell]]. **The entry leg still PASSED there, for the wrong
  reason:** it asserts a non-zero exit, and "does not exist anywhere" exits non-zero exactly
  like "exists but is completed". Only the message-content legs caught it. A bare rc compare
  would have certified this fix from a tree where the fixture did not exist.
- **Rejected:** loosening the two message legs to make the gate green — that would have
  deleted the only thing that detected the problem.

### 2026-08-08 — B2 probe leg reported, not scored
- **Chose:** print the bootstrap-verb-plus-redirect result without a PASS/FAIL, and file it
  as OBS-001.
- **Why:** it is a real measured behaviour but not this task's defect. Scoring it PASS would
  mean rewriting the expectation to match what was observed — fitting the test to the tree.
  Scoring it FAIL would assert a defect the evidence does not establish, since "a redirect is
  a write and writes need a task" is a coherent reading of the rule.
- **Rejected:** deleting the leg (loses a measurement someone will otherwise re-derive) and
  asserting either verdict (both overclaim).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T15:17:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-381-focus-gate-wedge-writer-accepts-complete.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1e146386
- **Timestamp:** 2026-08-08T15:25:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T15:25:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
