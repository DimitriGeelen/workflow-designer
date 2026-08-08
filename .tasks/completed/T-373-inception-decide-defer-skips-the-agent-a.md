---
id: T-373
name: "DEFER produces exactly the task state the G-053 revisit scanner cannot see"
description: >
  DEFER produces exactly the task state the G-053 revisit scanner cannot see

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T07:51:56Z
last_update: 2026-08-08T07:57:35Z
date_finished: 2026-08-08T07:57:35Z
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

# T-373: DEFER produces exactly the task state the G-053 revisit scanner cannot see

## Context

**The premise I filed this under was wrong, and finding that out is what produced the
real one.** I carried a note from a prior session reading: *"`inception.sh:521` gates the
agent-AC preflight on `go|no-go` only — DEFER (682) skips it entirely, a mechanical
gradient toward the exact hedge the prose forbids."* The title of this task still said
that when I opened the file.

Reading the code, **requiring ACs on DEFER would be a defect, not a fix.** You defer
*because* the work is not done. The skip is deliberate and the comment at `inception.sh:663`
says so outright. Had I built the "fix" implied by the title, I would have made the tool
worse and called it governance.

The defensible finding is one layer down. DEFER is the only decision that:

1. skips the agent-AC preflight (`inception.sh:521`, correctly), and
2. skips P-010/P-011 — it calls `update-task.sh --horizon later`, not `--status
   work-completed`, and those gates fire on completion, and
3. **leaves no revisit obligation.**

Point 3 is the finding. The task template declares the field and its purpose:

```
# revisit_at: YYYY-MM-DD   # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
```

`revisit_at` appears **zero times in the whole of `lib/inception.sh`**. The canonical way
to create a deferral never sets the field, never prompts for it, and never requires it.

And the scanner keyed on it skips silently — `agents/context/revisit-due-scan.sh:70`:

```sh
[ -z "$revisit_at" ] && continue
```

So `fw inception decide T-XXX defer` parks a task at `horizon: later` in exactly the state
the daily revisit scan cannot see. A missing `revisit_at` means both *"deliberately no
revisit date"* and *"nobody set one"*, and the scan treats both as nothing-to-do — the
`absence-cannot-carry-a-decision` shape, in the one path whose entire purpose is to defer
something to a later date.

Compounding: DEFER is simultaneously the cheapest exit from the decision gate (no AC
preflight, no P-010, no P-011) **and** the least visible outcome. That is a gradient, but
not the one I originally named — the pressure is toward deferrals that quietly never ripen,
not toward hedged decisions.

Shared vendored framework → **G-008 upstream candidate**; the same construct is in AEF's tree.

### Incidence in this project

With the fix in place the scan surfaces **one** task: T-155 (*Hierarchical tree grouping for
Open-project map browser*), parked with a DEFER decision and no revisit date. That is **1 of
1** — the only DEFER decision in the active corpus is undated.

Stated as `1 of 1` rather than `100%`: n is one, and a rate off a single member is a sample
wearing a proportion. The number worth watching is the direction, not the ratio — nothing
ever blocked a dateless deferral, so instances could only accumulate, never be prevented.

## Acceptance Criteria

### Agent
- [x] Both halves of the claim established by evidence, not reading: (a) `revisit_at` occurs
      zero times in `lib/inception.sh`, so the DEFER path cannot set it; (b) the G-053
      scanner skips a `horizon: later` task that has no `revisit_at`, demonstrated by
      running the real scanner against a task file, not by quoting line 70.
      → `tools/_t373-defer-revisit-blindspot.sh`. (a) whole-file occurrence count = 0.
        (b) the real script driven against a synthetic project root; pre-fix it reports
        nothing for the dateless task while correctly reporting the ripe one.
- [x] **The scanner demonstration has teeth:** the same task WITH a ripe `revisit_at` must
      be reported. A scan that reports nothing in both cases proves nothing — it could be
      broken, or pointed at the wrong directory.
      → ripe T-902 reported, future-dated T-903 correctly ignored, on every run. Run
        against the **pre-fix** scanner (`T373_SCAN=`, extracted via `git show HEAD:`)
        the harness goes RED on exactly the finding leg (1 fail / 7 pass) with both
        controls still green — so the red is the defect, not a broken harness.
- [x] Remedy makes the partition **total**: a deferred task is either (i) carrying a real
      `revisit_at`, or (ii) explicitly recorded as deferred-without-a-date. No task may sit
      in the state where absence stands in for both. Absence must not be the silent case.
      → `revisit-due-scan.sh` now emits a **second, separate** signal
        `.context/working/.revisits-undated.txt`, surfaced by `handover.sh` under its own
        heading. Deliberately NOT extra lines in `.revisits-due.txt`: that file means
        "ripe today" and its consumer prints it under that heading — a dateless deferral
        is not ripe, and widening an existing signal to carry a second meaning is exactly
        how this ambiguity arose.
- [x] Remedy is proven to discriminate — it fires on a deferral with no date and stays quiet
      on one with a date. Both directions, or it is not a gate.
      → fires on dateless T-901; silent on dated T-903; silent on ordinary non-deferred
        T-904 (a rule that reported every dateless task would bury the signal it raises);
        and T-901 is kept OUT of `.revisits-due.txt` so the two signals stay distinct.
        8/8 on the fixed build.
- [x] **No governance gate is exercised to test this.** `fw inception decide` requires
      operator authority; the probe drives the scanner and synthetic task files directly and
      never records a real inception decision. Stated here because the obvious test is the
      one I must not run.
      → no `fw inception decide` invocation anywhere in the harness; half (a) is a static
        whole-file count precisely because the end-to-end test is off-limits.
- [x] Finding + fix communicated to AEF as a G-008 upstream, including the correction that
      my originally-reported "DEFER skips the AC preflight" framing was wrong and why.
      → RAIL-450, retraction first and explicitly flagged as do-not-act-on: I had sent them
        the wrong framing at 448, and the fix it implied would have made the tool worse.
        Includes both edits, the teeth result against the pre-fix scanner, the 1-of-1
        incidence with its n stated, and what I deliberately did NOT change (the
        operator-authority decide path) and why that is their call and my operator's.

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

```
bash tools/_t373-defer-revisit-blindspot.sh
```

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

### 2026-08-08T07:51:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-373-inception-decide-defer-skips-the-agent-a.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-32906ed6
- **Timestamp:** 2026-08-08T07:57:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T07:57:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
