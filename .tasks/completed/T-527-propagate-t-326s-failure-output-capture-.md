---
id: T-527
name: "propagate T-326's failure-output capture to the 62 bridge-suite legs that discard
  it"
description: >
  T-526 measured 66 report FAIL calls against 4 show_output calls in tests/run-bridge-tests.sh:
  62 legs discard the evidence of their own failure, and 6 of the 10 CDP legs (every
  one of them an AEF-seam conformance probe: _t511 _t513 _t515 _t518 _t520 _t523)
  redirect to /dev/null. T-326 diagnosed this exact defect and wrote the reason into
  the source, then wired the remedy into 4 legs; every probe added since was written
  by copying a leg that discards. Consequence measured at N=5: both intermittent failures
  observed (T-518 uid-collision, T-509 instrument sweep) were uninvestigable from
  their own output, so whether the suite's non-determinism is instrument-side or subject-side
  CANNOT be answered. This is the prerequisite for fixing the flake, not a cleanup.
  See docs/reports/T-526-bridge-suite-determinism.md.

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
created: 2026-08-15T19:51:49Z
last_update: '2026-08-16T13:58:58Z'
date_finished: 2026-08-15T21:17:21Z
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
  - ts: '2026-08-16T12:34:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F-AUTONOMY=0
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/audits/cron/2026-08-15-2315.yaml,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t527-capture-invariant.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:58Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/audits/cron/2026-08-15-2315.yaml,tests/run-bridge-tests.sh,tools/_t527-capture-invariant.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-527: propagate T-326's failure-output capture to the 62 bridge-suite legs that discard it

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The population is counted properly before anything is changed.** The task was filed
      saying "62 legs", from 66 `report FAIL` calls minus 4 `show_output` calls. Those count
      different things — most `report FAIL` sites are inside per-corpus loops, not standalone
      legs — so 62 is a difference between two populations, the PL-222 shape this project keeps
      finding, committed here by me. The real figure is measured and the false one corrected
      wherever it was transmitted, including to AEF at rail 11934.
      MEASURED: **23**, not 62. Corrected to AEF at rail **11939** and in the suite's own comment
      block. `show_output` call sites went 4 → **27** = 4 + 23, which is the arithmetic that
      should have been the filing check.
- [x] Every if-guarded leg that discards its probe's output now captures it to a file under the
      suite's own `$TMP` (which its EXIT trap already removes), and prints it via `show_output`
      on the failing branch ONLY — failure-only is T-326's design and a suite that prints every
      leg's stdout buries the signal it exists to surface.
- [x] The whole population is converted, not the interesting subset. Doing the 6 AEF-seam probes
      and stopping would be this task's own subject matter — a fix landing on the instances that
      prompted it while the population grows around it (T-508, T-509, T-326 itself).
- [x] Any leg deliberately left discarding is named with its reason in a comment, so the next
      count is of a declared exemption rather than of an oversight.
- [x] The mechanism is demonstrated, not assumed: a leg is forced to fail and its captured
      output is shown to appear in the suite's stdout. A capture nobody proved prints is the
      same defect one level over.
- [x] `bash -n tests/run-bridge-tests.sh` parses, ratchet unmoved at 67, and the suite's
      result is reported HONESTLY rather than asserted at 94 — see ## Decisions for why
      this criterion was amended mid-task and what the number legitimately became.
      RESULT: **95 passed, 0 failed, rc=0** (94 + the new standing invariant leg).
      `bash -n` clean. Census population 189 → 190 with the new tool, FINDINGS unmoved at
      **67** and `_t527-capture-invariant.sh` absent from the unwired list — it is wired,
      not merely added.
      THE RUN CARRIED ITS OWN PERTURBATION WITNESS (`git status --porcelain` before and
      after), and the witness is worth more than the green: the tree DID change during the
      run — `?? .context/audits/cron/2026-08-15-2315.yaml` appeared and PERSISTED, which is
      exactly the class that drove leg 7 red in probe B — and the suite was green anyway.
      That is the discriminating case for the corrected model: a persistent write during a
      run is NECESSARY BUT NOT SUFFICIENT; it has to land inside the specific leg's ~61s
      window. A bare green run would have been consistent with three different stories.

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

# The suite itself is deliberately NOT run here. It takes ~305s and T-526 measured it
# red on 2 of 5 identical runs; T-527 then localised one red to a leg asserting a
# whole-tree property (see ## RCA). Wiring a known-flaky 5-minute suite into P-011 would
# make the completion gate itself non-deterministic — the exact defect class this task
# exists to make legible. The suite result is reported in the task body as evidence
# instead. These three lines check what THIS change actually did, deterministically.
bash -n tests/run-bridge-tests.sh
bash tools/_t527-capture-invariant.sh

## RCA

**Symptom:** 23 of the bridge suite's if-guarded legs redirected their probe's stdout/stderr
to `/dev/null`. When one failed, the suite printed a single `[FAIL]` line and the evidence of
*why* was already destroyed. Measured consequence (T-526, N=5): both intermittent reds observed
were uninvestigable from the suite's own output.

**Root cause:** T-326 diagnosed this exact defect, wrote the reason into the source, and wired
the remedy (`show_output`) into 4 legs. Every probe added afterwards was written by copying a
leg that discards. The remedy existed and was reachable; nothing made copying it the default,
and nothing counted uses of the remedy against uses of the thing it remedies.

**Why structurally allowed:** the suite's dominant leg shape emits NOTHING on pass, so a
discarding leg and a capturing leg are byte-identical in every green run. The defect is only
observable in the failure path, which by construction is rare — so the population could grow
by copy for months with no signal. This is T-526's own learning ("a fix applied to the instance
that raised it does not reach the population, and the population keeps growing by copy"),
recorded there and instantiated here for the third time after T-508 and T-509.

**Prevention:** distinct from the fix, and the first version of this paragraph was wrong.
It claimed the greps pinned in `## Verification` prevent recurrence — they do not: P-011 runs
a task's Verification only at THAT task's completion, so a leg added by a future task would
never trip them. That is a plausible-shaped false claim of exactly the kind logged to AEF at
rail 11939 an hour earlier, and it is corrected here rather than quietly replaced.

The actual prevention is `tools/_t527-capture-invariant.sh`, wired as a standing leg of the
bridge suite, so it runs whenever the suite does. It asserts the INVARIANT (zero if-guards
discard) rather than the count 27 — pinning a count of an always-moving population inside the
suite would be G-015, going red for whoever next adds a leg for a reason unrelated to their
change. It abstains with rc 2 rather than passing when `show_output()` is missing or the leg
idiom changed (PL-205), because "zero discards" is vacuously true of a suite with no remedy.
Demonstrated red for each named reason before wiring: mutant reintroducing one discarding
guard → rc 1 naming line 1213; mutant renaming the helper → rc 2 abstaining; tree restored
byte-identical after both.


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

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-08-15 — AC6's "green at 94" was amended, twice, for two different reasons

- **Chose:** report the suite's actual result as evidence in the task body, and drop "94" as a
  literal pass condition. The expected figure is now **95**: this task adds one standing leg
  (`_t527-capture-invariant.sh`).
- **Why:** two things falsified the original wording after it was written.
  (1) The first clean regression run came back **93 passed / 1 failed**, and the red was
  `_t525-fabric-coverage-teeth.py` — which passes 7/7 standalone. Its leg 7 asserts "the working
  tree is byte-identical after the run" by comparing whole-tree `git status` before vs after its
  own 61-second window, so ANY writer anywhere in the repo turns it red. The PreCompact handover
  committed at 22:56:58, inside that run (22:53:28→22:58:31). Demonstrated, not inferred: a
  persistent new file created mid-run drove it red naming `?? _t527-probe-marker.tmp`.
  A hard-coded "94" would have made this task's completion gate depend on whether anything else
  touched the repo during a five-minute window.
  (2) Adding the prevention leg changes the count by construction. Leaving AC6 reading "94" and
  ticking it anyway would have been the gate certifying a number that no longer described the
  thing.
- **Rejected:** re-running until a green 94 appeared. T-526 measured 3-of-5 green, so retrying
  until the wanted number shows up is sampling until the answer agrees — it would have produced
  a true statement ("the suite ran green at 94") that certified nothing, and it would have
  buried the one red that turned out to be the most valuable output of this task.
- **Rejected:** fixing the `_t525` hermeticity leg here. Different bug, different root cause,
  own task (CLAUDE.md: one bug = one task). Filed as an observation instead.

### 2026-08-15 — the pinned `show_output == 27` was removed from ## Verification after it blocked me

- **Chose:** verify with `bash -n` plus `tools/_t527-capture-invariant.sh`, and pin no count.
- **Why:** the gate caught me. I wrote `-eq 27` into ## Verification, then added the standing
  invariant leg — which contains a `show_output` call — and the count became 28. P-011 refused
  completion, correctly. This is the exact defect the Decisions entry above describes (a count
  of an always-moving population goes stale for reasons unrelated to what it is checking),
  committed by me against myself, inside the single task whose subject is that class. Bumping
  27 → 28 would have restored the green and preserved the defect for the next person to add a
  leg. The invariant does not move.
- **Rejected:** keeping the count as a record that 23 legs were converted. That is a historical
  fact and belongs in the AC and the commit message, which is where it now lives. A completion
  gate should assert a property that must remain true, not a number that was true once.

### 2026-08-15 — the suite is deliberately NOT in this task's ## Verification

- **Chose:** verify with three deterministic greps (`bash -n`, `show_output` == 27, discarding
  guards == 0) and report the suite run in the body.
- **Why:** the suite takes ~305s and T-526 measured it red on 2 of 5 identical runs. Wiring a
  known-flaky five-minute suite into P-011 would make the completion gate itself
  non-deterministic — the exact defect class this task exists to make legible.
- **Rejected:** wiring the full suite in for thoroughness. It would convert a real gate into a
  coin flip, and the first time it blocked a good task the response would be `--force`, which
  trains exactly the wrong reflex.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-15T19:51:49Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-527-propagate-t-326s-failure-output-capture-.md
- **Context:** Initial task creation

### 2026-08-15T20:46:52Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1de52214
- **Timestamp:** 2026-08-15T21:17:21Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T21:17:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
