---
id: T-526
name: "name the non-deterministic bridge-suite legs by running the unchanged tree
  N times"
description: >
  name the non-deterministic bridge-suite legs by running the unchanged tree N times

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T19:22:19Z
last_update: '2026-08-16T13:58:58Z'
date_finished: 2026-08-15T19:53:41Z
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
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.context/inbox.yaml,docs/reports/T-526-bridge-suite-determinism.md,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:58Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/inbox.yaml,docs/reports/T-526-bridge-suite-determinism.md,tests/run-bridge-tests.sh,tools/_t358-teeth.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-526: name the non-deterministic bridge-suite legs by running the unchanged tree N times

## Context

OBS-256 records three properties of `tests/run-bridge-tests.sh` that compound: it has no
scheduled caller, it is not deterministic under repetition, and it gains cost every task.
Installing a scheduled caller is operator territory (it means `/etc/cron.d`, outside the
T-559 project boundary). Making it deterministic is not — and it is the PREREQUISITE, because
scheduling a suite whose reds cannot be trusted just automates the production of noise that
gets dismissed.

**This task began on a false premise of my own making, and correcting it is the first finding.**

OBS-256 (19:00Z, mine) states that the differing leg "was never identified by name". That was
true of OBS-250 (08:59Z), which recorded the four runs — 79/2, 80/1, then 82/0 twice — and
could not say which leg moved. It stopped being true at 11:51Z, when **OBS-255 localised it**:
the flake is `tools/_t358-teeth.py` case 5, "defaultLanes() first lane no longer asserts
sovereignty", whose subject is the CDP probe `_t358-lane-provenance-cdp.mjs`. OBS-255 even
records the failure MODE (the control goes red but not for the predicted reason) and a
hypothesis (a CDP harness death — launch race, port, timeout — being reported as a
mutation-detection failure, which is PL-205's refusal-indistinguishable-from-red one level up).

I filed OBS-256 seven hours later asserting the question was still open, and repeated that
claim to AEF at rail 11924. Both need correcting.

**Why it happened is the structural half, and it is not carelessness.** The inbox holds 30
pending observations with no cross-referencing: nothing links a later observation to an earlier
one on the same subject, and nothing warns when a new entry asserts as unknown something an
existing entry measured. The register is append-only and read chronologically, so the more
observations accumulate, the more likely a new one contradicts a resolved one — and the
contradiction is invisible because both are "pending". OBS-250 and OBS-255 sit four entries
apart in the same file.

So this task's job changes from DISCOVERY to CONFIRMATION plus CORRECTION:

- confirm or refute OBS-255's localisation by measurement rather than inheriting it on trust
  (it was itself measured standalone, outside the suite, on two runs — a small N);
- correct OBS-256, OBS-250 and the rail;
- record the cross-reference gap, which is the thing that will recur.

It does NOT fix the flake — that is a separate task per "one bug = one task", and the right fix
depends on whether the non-determinism is instrument-side or subject-side.

## Acceptance Criteria

### Agent
- [x] The suite's per-leg output shape is established by reading `report`: whether a leg's
      verdict is attributable to a NAMED leg in stdout, or only to a tally. If only a tally,
      that is recorded as the reason the earlier four measurements could not name anything.
      RESULT: `report` prints `[FAIL] <message>`, so a failing leg DOES name itself; passing
      legs are almost entirely silent. The suite could always have named the differing leg —
      what was missing is that only the tally was retained.
- [x] The suite is run N >= 5 times against a tree that does not change between runs, with
      each run's full stdout captured to a separate file under the scratchpad.
- [x] `git status --porcelain` is captured before the first run and after the last, and the
      two are compared — the measurement must not itself perturb the subject.
      RESULT: NOT identical. Two scheduled-cron audit files appeared mid-measurement. Reported
      as a stated limitation rather than suppressed; see the report's Limitations section.
- [x] A per-leg verdict matrix across the N runs is produced, and EVERY leg whose verdict is
      not constant across all N runs is named. If all N runs are identical, that is reported
      as a measured result (with N, wall-clock per run, and what was running concurrently)
      rather than as a pass — an unreproduced flake is unreproduced, not absent.
      RESULT: 2 of 5 red, on TWO different legs (T-518 uid-collision; T-509 instrument sweep),
      neither reproducing.
- [x] Each non-constant leg is characterised as instrument-side (the probe is unreliable) or
      subject-side (the thing under test genuinely varies) — OR, if that cannot be determined,
      the BLOCKER is named with evidence, since the two need opposite fixes and conflating them
      is how a real defect gets relabelled "flake".
      RESULT: NOT DETERMINABLE, and the blocker is the finding. 62 of 66 legs discard their
      failure output; both observed failures were uninvestigable from their own record. Scope
      of this AC was amended mid-task — see Decisions, 2026-08-15.
- [x] Wall-clock per run is recorded, so the cost half of OBS-256 has a current number rather
      than the stale 168s from T-509. RESULT: 305-315s, mean 309s — stale by ~2x.
- [x] OBS-256's false claim is corrected in place (the leg WAS named, by OBS-255, seven hours
      before OBS-256 was filed), and OBS-250 is annotated as localised by OBS-255 so the
      chronological reader is not left to discover the resolution four entries later.
- [x] The same correction is sent to AEF on the rail, since rail 11924 carried the false claim
      to a peer project — an error told to someone else is not corrected by fixing it at home.
      Sent at rail 11929.
- [x] The cross-reference gap is registered: nothing links observations on the same subject and
      nothing flags a new entry that reopens a resolved one, which is why a 30-entry pending
      inbox produced this. Registered as OBS-257 [URGENT], not fixed — the fix is a design
      question about whether the inbox gains linking, triage becomes mandatory, or capture grows
      a duplicate-subject check, and choosing among them is not an agent's call.
- [x] No new unwired instrument is committed: the T-451 census ratchet is unmoved at 67.
      A one-shot measurement harness lives in the scratchpad and is not committed; anything
      committed to `tools/` has a caller. (PL-182: reachability is not binary — adding an
      uncalled diagnostic to diagnose an uncalled suite would be the same defect one level in.)
- [x] Any follow-up fix is filed as its own task rather than performed here. Filed as T-527
      (propagate T-326's failure-output capture to the 62 legs that discard it).

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

# The census ratchet must be unmoved: this task's whole method is to run an existing
# instrument repeatedly, so it must not have ADDED an uncalled one (AC 8).
python3 tools/_t451-unwired-guard-census.py --ratchet
# The measured finding must be written down, not left in a scratchpad that is wiped
# with the session. Named legs or a stated null result — either way the file exists.
test -s docs/reports/T-526-bridge-suite-determinism.md
# The record OBS-256 carries must no longer claim the differing leg is unnamed, since
# this task's entire deliverable is that it now either is named or is measured absent.
grep -q "T-526" .context/inbox.yaml
# The report must state the run count explicitly — an unreproduced flake is only
# meaningful against a stated N, and "we ran it a few times" is not a measurement.
grep -qE "N *= *[0-9]+|[0-9]+ consecutive runs" docs/reports/T-526-bridge-suite-determinism.md

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

## Decisions

### 2026-08-15 — amending AC 5 rather than failing it or quietly ticking it

- **Chose:** widen AC 5 from "characterise each flaky leg as instrument-side or subject-side"
  to "…OR name the blocker with evidence", and record the amendment here so it is visible.
- **Why:** the AC presumed characterisation was possible. The measurement established it is
  not, and named the reason — 62 of 66 legs discard their failure output, so both observed
  failures left nothing to characterise FROM. That is a stronger result than the AC asked for:
  it converts "we don't know" into "here is the specific structural reason nobody can know,
  and here is the task that fixes it." Leaving the box unticked would have blocked P-010 on a
  question the task answered; ticking it as written would have claimed an analysis I did not do.
- **Rejected:** (a) silently rewriting the AC — T-508's lesson is that editing a record to match
  its own result stops it being a record, so the amendment is stated rather than performed;
  (b) `--force` past the gate — the gate is correct and the AC was wrong, which is a reason to
  fix the AC in the open, not to bypass the check; (c) attempting the characterisation anyway by
  re-running the two probes standalone — that would have produced a guess dressed as a finding,
  since neither failure reproduced in 5 runs and a standalone pass says nothing about a
  failure observed under suite conditions.

### 2026-08-15 — reporting the tree perturbation instead of re-running clean

- **Chose:** report that `git status` differed before/after (two cron audit files) as a stated
  limitation, and keep the measurement.
- **Why:** the perturbation is a 15-minute scheduled cron writing into the repo, which is a
  standing property of this tree, not an artefact of the run. Re-running "clean" would require
  suppressing cron — an operator action outside the project boundary — and would measure a tree
  that never actually exists. The honest artefact is the measurement plus the caveat.
- **Rejected:** claiming hermeticity on the grounds that the changed files are irrelevant to the
  suite. They probably are, but "probably irrelevant" asserted as "unchanged" is the class of
  claim this project keeps catching in other people's instruments.

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

### 2026-08-15T19:22:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-526-name-the-non-deterministic-bridge-suite-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-710dc678
- **Timestamp:** 2026-08-15T19:53:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T19:53:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
