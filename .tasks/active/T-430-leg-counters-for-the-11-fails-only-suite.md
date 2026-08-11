---
id: T-430
name: "Leg counters for the 11 fails-only suites T-429 refused to guard mechanically"
description: >
  T-429 guarded 22 of 35 suites against reporting success with no legs run. Eleven were refused BY NAME because they tally only failures, so fails==0 is both 'clean' and 'empty' and no guard can be written from the file's own state. Adding a leg counter there means reading how each suite is structured — T-429 proved an applier must not attempt it: its first draft injected the counter into fail(), the failure reporter, which would have fired the guard on every green run. One suite at a time, each verified in both directions (legs neutered -> non-zero; unmodified -> still green) with tools/_t429-zero-leg-probe.sh. Suites: _t350-build-only-probe, _t400-schema-teeth, _t408-hygiene-teeth, _t410-secret-artifact-teeth, _t411-census-teeth, _t412-announced-pair-teeth, _t414-mutation-check, _t416-mutation-check, _t416-qualifier-residue-teeth, _t418-attribution-teeth, _t419-carrier-mutation-check. Plus _t353-repair-probe, which has no identifiable verdict block. Close condition: tools/_t429-abstention-census.py exits 0.

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
created: 2026-08-11T14:23:23Z
last_update: 2026-08-11T21:19:05Z
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

# T-430: Leg counters for the 11 fails-only suites T-429 refused to guard mechanically

## Context

T-429 guarded 22 of 35 counter-bearing suites so that a run which executed no legs
cannot exit 0. It refused the rest **by name** rather than guessing: those suites tally
only FAILURES, so `fail=0` means "clean" and "never ran" simultaneously, and no guard is
derivable from the file's own state. Closing them needs a leg counter, and a leg counter
needs the suite read — T-429's own first draft proved an automated applier must not try
it, having injected the counter into `fail()`, the failure reporter, which would have
fired the new guard on every green run.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The population is measured, not recalled: the current census output is captured as a
      BEFORE baseline listing every UNGUARDED suite by name with its tallies, and the
      filed count (11 + `_t353-repair-probe`) is confirmed or corrected against it. The
      task's description is a claim from a prior session; if it disagrees with the
      instrument, the instrument wins and the discrepancy is recorded.
- [x] Every suite named in that baseline carries a counter incremented **at the leg site**
      — the place a leg actually executes — and NOT inside a failure reporter. Asserted
      mechanically, not by eye: for each edited suite, a check shows the increment is not
      within the body of a `fail()`/`err()`-style function.
- [x] Each edited suite is proven in BOTH directions with `tools/_t429-zero-leg-probe.sh`
      (or an equivalent recorded here): legs neutered → the suite exits NON-ZERO and says
      it ran nothing; unmodified → the suite still exits 0. A guard proven in only the
      passing direction is the defect this task exists to remove.
- [x] No suite's pre-existing verdict changes. Each edited suite's pass/fail counts are
      captured before and after and compared; any movement is a regression introduced by
      the guard and is either fixed or reported, never absorbed.
- [x] `python3 tools/_t429-abstention-census.py` exits 0 — every counter-bearing suite in
      `tools/` fails when its legs do not run.
- [x] Suites the census cannot answer for (no identifiable verdict block, e.g.
      `_t353-repair-probe`) are named explicitly with the reason, and either guarded or
      carried forward as a filed follow-up. Silent omission is the failure mode being
      audited here and must not be reproduced by this task.

<!-- No ### Human section: every criterion above is a shell check. Removed rather than
     left as an empty template block — a stray second "### Human" heading is parsed by
     heading and is silently ignored or silently merged depending on which reader looks
     (hit twice in the previous session, on T-432 and T-433).

     Original template guidance retained below for reference only.

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

# The close condition. Exits 0 only when every counter-bearing suite in tools/ takes a
# non-zero exit on the branch where its tally is zero. Its own exit code is the verdict,
# so no capture/grep chain and no errexit exposure (T-352).
python3 tools/_t429-abstention-census.py

# The census reads SOURCE and reasons about branches — it is a belief about behaviour.
# This drives all 13 and reads the result: with every leg neutered each must exit 2 AND
# print its ABSTAINED line. Named in full rather than globbed: a glob that stops matching
# would run zero suites, and this file is about instruments that pass having run nothing.
bash tools/_t430-abstention-teeth.sh tools/_t350-build-only-probe.sh tools/_t353-repair-probe.sh tools/_t400-schema-teeth.sh tools/_t408-hygiene-teeth.sh tools/_t410-secret-artifact-teeth.sh tools/_t411-census-teeth.sh tools/_t412-announced-pair-teeth.sh tools/_t414-mutation-check.sh tools/_t416-mutation-check.sh tools/_t416-qualifier-residue-teeth.sh tools/_t418-attribution-teeth.sh tools/_t418-mutation-check.sh tools/_t419-carrier-mutation-check.sh

## Findings

### 1. The filed population was 12; the instrument says 13

`_t418-mutation-check.sh` is UNGUARDED and was not in the task description's
enumeration. The description was written from a prior session's reading; the census was
run first here precisely so the list would come from the tool. Corrected, not argued.

### 2. The probe this task was told to verify with cannot tell a guard from a corpse

`tools/_t429-zero-leg-probe.sh` blanks the assertion helper and reads the **process exit
code**: non-zero → `GUARDED`. That inference holds only while the suite is otherwise
green, and nothing in the probe says so.

Measured. `_t400-schema-teeth.sh` carries one genuinely red leg. With a leg counter added
and the abstention guard **deleted**, the probe printed:

```
  assertion helper neutered: leg()
  exit code with no legs recorded: 1
GUARDED — the suite refused to report success without running legs.
```

over a file that provably had no guard. It exited 1 because a leg was red. Two distinct
defects compound here:

- **the verdict question is wrong** — it asks *did this process exit non-zero* when the
  question is *did the abstention guard fire*. Mention-vs-instance, inside the fix for
  the finding that named the class.
- **the simulation is incomplete** — blanking only the FIRST increment-bearing helper
  leaves `fails` counting in the shape this task installs, so a suite with any real
  failure never reaches the zero-branch at all.

`tools/_t430-abstention-teeth.sh` neuters **every** increment-bearing helper and requires
`rc == 2` **and** the guard's own sentence. Mutation-proven: it goes red on the
guard-deleted variant the old probe called GUARDED.

The old probe is left in place, unmodified — it is T-429's evidence and has its own teeth.
It is simply not sufficient on its own, which is now written down.

### 3. `_t400-schema-teeth` was already red at HEAD — not absorbed

`RECIPROC` fails: the live `.context/project/concerns.yaml` carries a field `context` in
2 entries that `tools/concerns-schema.py` accounts for nowhere. Pre-existing, unrelated to
this task, and deliberately not silenced by it. Verdict before: `rc=1`, 1 FAIL. After:
`rc=1`, 1 FAIL. Filed as an observation rather than fixed here — one bug, one task.

### 4. Hard-coded denominators were removed where touched

`_t400` printed `TEETH PASS — 10/10 legs` on a run where a leg had failed and been
silenced: a count it never measured, which is the same claim-without-a-denominator the
guard exists to stop, one line further down. It now prints what it recorded — `0/10`
under neutering, so the abstention is visible in the text and not only in the exit code.

### 5. The class landed once more, in this task's own scaffolding

The throwaway check that removed the guard for finding 2 asserted `"ABSTAINED" not in
src` — and failed, because the comment I had written a minute earlier *mentions* the
word. Asked "does the file mention it" when the question was "does the file contain the
executable guard". Re-anchored on `^\s*echo "ABSTAINED`.

### Result

Census `13 UNGUARDED → 0`, exits 0, 39 of 39 counter-bearing suites guarded.
Both directions on all 13: `pass=26 fails=0`. No suite's verdict moved.

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

### 2026-08-11T14:23:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-430-leg-counters-for-the-11-fails-only-suite.md
- **Context:** Initial task creation

### 2026-08-11T21:10:33Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
