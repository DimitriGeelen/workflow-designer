---
id: T-585
name: "the approvals queue cannot tell an empty queue from a mis-sectioned Human AC"
description: >
  the approvals queue cannot tell an empty queue from a mis-sectioned Human AC

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
created: 2026-08-25T09:17:44Z
last_update: 2026-08-25T09:17:44Z
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

# T-585: the approvals queue cannot tell an empty queue from a mis-sectioned Human AC

## Context

T-344 carried a real unchecked `[REVIEW]` acceptance criterion and never appeared on
`/approvals` or in `fw review-queue`, because its `### Human` block sat under
`## Measurements` instead of under `## Acceptance Criteria`. The queue predicate
(`count_unchecked_human_acs`, web/shared.py:831) anchors on `^## Acceptance Criteria\s*$`
and scopes `### Human` to that section, so the block was out of scope and the only
`### Human` it found was the template's commented example — which strips to nothing.
Predicate: 0. Direct comment-stripped read of the same file: 1.

**The failure renders as health.** A mis-sectioned Human AC produces an EMPTY queue
entry, and an empty queue reads as "nothing pending", not as an error. No gate fires,
no warning prints. T-344 was found by hand, and only because the operator complained
that `/approvals` showed nothing but review items.

This is the same shape as T-2075's own fix one level up: centralising the predicate
made `/approvals` and `fw review-queue` AGREE. It did not make them RIGHT. Agreement
removed the disagreement that was the only visible symptom (PL-259).

Nothing in the tree compares "tasks with a real unchecked human AC anywhere in the body"
against "tasks the queue surfaces". This task builds that comparison.

## Acceptance Criteria

### Agent
- [x] A census tool enumerates BOTH sides of the comparison and PRINTS the population
      of each: tasks the queue predicate surfaces, and tasks carrying an unchecked
      Human AC anywhere in the body. A count alone is not the deliverable — a census
      that reports "0 findings" without naming its denominator is the failure mode
      this task exists to detect, one level up.
- [x] The census calls the REAL predicate by import, not a reimplementation of it.
      A local copy would drift from the surface under test and the tool would then
      be measuring itself.
- [x] The census carries a CONTROL on fixtures that runs FIRST and ABORTS the run on
      failure: a positive fixture (Human AC mis-sectioned outside `## Acceptance
      Criteria`) that MUST be flagged, and a negative fixture (correctly sectioned)
      that MUST NOT be. The real-tree assertion is an absence assertion — "no
      mis-sectioned ACs" — and is satisfied by a detector that is merely broken.
- [x] Every discrepancy class the census can distinguish is reported separately
      rather than collapsed into one "invisible" bucket, and each class names the
      specific predicate step that drops the AC.
- [x] The census is wired into `tests/run-bridge-tests.sh` with a failure message that
      tells the reader what a non-zero exit means, including the case where the CONTROL
      aborted and therefore nothing was measured.
- [x] Any task the census finds mis-sectioned has its `### Human` block RELOCATED into
      `## Acceptance Criteria` verbatim, and is reported to the operator. The AC text is
      never edited and the box is never ticked. Relocation restores visibility; it does
      not answer the question. See `## Decisions` — this AC was written the other way
      round and corrected once the first finding showed the reasoning was wrong.

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

# 1. The census itself: six fixtures, then the sweep. Exit 0 means no active task carries
#    an unchecked Human AC the queue cannot see. Exit 2 would mean the fixtures failed and
#    the sweep never ran — the tool says so in those words rather than printing a clean 0.
python3 tools/_t585-human-ac-visibility-census.py

# 2. The teeth. Three mutations of a COPY, each rewriting a line the interpreter reaches.
#    Without this, leg 1's green is a claim about a detector nobody has tried to break.
bash tools/_t585-census-teeth.sh

# 3. The two surfaces name the same tasks. This is what makes "the census imports the live
#    predicate" checked rather than stated: a local copy would agree today and diverge the
#    first time web/shared.py moved, and set inequality is where that would surface.
python3 tools/_t585-human-ac-visibility-census.py --cross-check

# 4. Wired into the suite. A census nothing runs is a census that finds nothing.
grep -q "_t585-human-ac-visibility-census.py" tests/run-bridge-tests.sh

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

**Symptom:** T-344 carried an unchecked `[REVIEW]` acceptance criterion and appeared
on neither `/approvals` nor `fw review-queue`. The operator saw an empty decision
queue and read it as "nothing is waiting on me".

**Root cause:** `count_unchecked_human_acs` scopes `### Human` to the block anchored
by `^## Acceptance Criteria\s*$`. T-344's `### Human` block was under `## Measurements`.
Out of scope → not counted → not surfaced. The predicate behaved exactly as written.

**Why structurally allowed:** the predicate's zero is ambiguous and nothing
disambiguates it. "This task has no Human ACs" and "this task's Human ACs are
somewhere I do not look" produce the identical return value, and the queue renders
both as absence. Absence of a row is the normal, healthy state of a queue, so there
is no observable that distinguishes the two. No gate validates that a `### Human`
block is reachable from the anchor, and no instrument compares the queue's population
against the population of tasks that actually carry a human AC.

**Prevention:** the census in this task is the missing comparison. It runs in the
bridge suite, so a newly mis-sectioned AC is caught at suite time rather than by an
operator noticing an empty page. Its fixture control means a broken census reports
red, not clean.

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

### 2026-08-25 — report-only vs relocate, for a mis-sectioned Human AC

- **Chose:** relocate the block into `## Acceptance Criteria` verbatim, never edit its
  text, never tick it, and report the relocation to the operator.
- **Why:** the AC was originally written "report, do not repair", on the reasoning that
  relocating changes what the operator is asked to rule on. The first real finding
  (T-402) showed that reasoning is wrong. Relocation does not change WHAT is asked — the
  words are untouched — it changes WHETHER it is asked. Leaving the block where it is
  means filing a report about a decision the operator still cannot see on `/approvals`,
  which reproduces the defect while documenting it. This is also what was already done
  for T-344, so report-only would have made the two findings inconsistent.
- **Rejected:** *Report only.* Preserves the file byte-for-byte, but the operator's
  queue stays wrong until someone hand-edits it — and the whole finding is that nobody
  notices an empty queue.
- **Rejected:** *Relocate and rewrite the AC to fit its new section.* Any edit to the
  wording is the agent restating the operator's question. Verbatim move or nothing.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-25T09:17:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-585-the-approvals-queue-cannot-tell-an-empty.md
- **Context:** Initial task creation
