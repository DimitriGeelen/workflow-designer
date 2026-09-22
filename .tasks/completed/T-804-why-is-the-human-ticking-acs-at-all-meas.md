---
id: T-804
name: "Why is the human ticking ACs at all: measure how many of the unchecked Human ACs are genuine judgement vs misfiled machine-checkable ones"
description: >
  Why is the human ticking ACs at all: measure how many of the unchecked Human ACs are genuine judgement vs misfiled machine-checkable ones

status: work-completed
workflow_type: design
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T10:18:08Z
last_update: 2026-09-22T10:21:21Z
date_finished: 2026-09-22T10:21:21Z
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

# T-804: Why is the human ticking ACs at all: measure how many of the unchecked Human ACs are genuine judgement vs misfiled machine-checkable ones

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the queue is counted and split by KIND, not just counted.** "77 unchecked Human
      ACs" is a number that invites a shrug. The useful split is between criteria that
      genuinely need a human's judgement and criteria a machine could check but that were
      filed as human work anyway — the framework's own `[REVIEW]` vs `[REVIEWER]` distinction
      (T-1811/T-1878).
      Evidence: **71 `[REVIEW]` · 6 `[RUBBER-STAMP]` · 0 `[REVIEWER]`.** Zero. The
      framework's own marker for "this should have been an Agent AC" is unused across the
      entire live queue, and reading the `[REVIEW]`s confirms they are what they claim —
      governance rulings a machine cannot make. **My hypothesis that most were misfiled is
      disproved**, and disposing of the comfortable answer is the useful result.
- [x] **AC2 — the operator's question is answered on its merits, including where the answer
      is "you shouldn't."** They asked why they should tick ACs at all. If most of the queue
      is misfiled, the honest answer is that they should not be ticking most of it, and
      defending the queue as it stands would be defending my own backlog.
      Evidence: the answer is "mostly you should not", but NOT because they are misfiled.
      Agents generate rulings faster than any human issues them — three went to the operator
      today, of which one was blocked on (SQ-2) and one did not exist (IW-3, my misquote).
      A 42-day median does not mean the human is slow; it means the agents are asking too
      much. That is ours to fix.
- [x] **AC3 — the age of the queue is measured.** A verification queue and a graveyard look
      identical in a count. What separates them is whether anything ever leaves.
      Evidence: **median 42 days**, 32 tasks aged 31–90 days, oldest 73 (T-189), none past
      90. So not abandonment — but not drainage either. The queue is held at a level rather
      than cleared, which is what distinguishes a backlog from a graveyard AND from a working
      queue.
- [x] **AC4 — a concrete remedy is proposed with its cost, not a principle.** "Write better
      ACs" is not a remedy. Whatever is proposed must say what changes mechanically and what
      it would cost to do.
      Evidence: three remedies with costs. **A — stop adding**: escalate only what is
      BLOCKED, cost is that the agent makes calls it would have escalated. **B — batch by
      question**: 77 ACs are fewer than 77 decisions (T-732 alone holds five), cost is
      building it and it does not slow inflow. **C — let a recorded decision close its task**:
      PD-308 exists yet T-353 stays open, cost is that it is AEF's framework behaviour to
      change and it weakens the guarantee a human read the specific words. Recommended A,
      because it starts now and costs nothing to begin.

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
         1. Run `bin/fw reviewer T-804`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-804 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: the queue count and the marker split, re-measured ───────────────────
out=$(timeout 300 python3 tools/_t783-human-ac-queue-extract.py 2>&1 || true); case "$out" in *"T-732"*) true;; *) false;; esac

# ── AC1: zero [REVIEWER] markers — with the POSITIVE CONTROL on the same string.
# Leg (a) proves the pattern REVIEWER matches where it IS present (the task template
# documents it), so leg (b)'s silence is about the queue and not a broken pattern.
# Control target corrected: the template is default.md, not zzz-default.md. The first
# version failed with grep exit 2 — FILE NOT FOUND, not 'pattern absent'. Worth noting
# that the two are indistinguishable in a bare `grep -q` and only the exit CODE tells
# them apart, which is the same confusion an uncontrolled absence leg lives on.
grep -q 'REVIEWER' .tasks/templates/default.md
out=$(timeout 300 python3 tools/_t783-human-ac-queue-extract.py 2>&1 || true); case "$out" in *"REVIEWER  "*) false;; *) true;; esac

# ── AC2/AC3/AC4: the report says the uncomfortable parts ─────────────────────
grep -q 'My hypothesis was wrong' docs/reports/T-804-human-ac-queue.md
grep -q 'That is our failure, not the operator' docs/reports/T-804-human-ac-queue.md
grep -q 'queue recursion' docs/reports/T-804-human-ac-queue.md
grep -q 'Not ticking anything' docs/reports/T-804-human-ac-queue.md

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
     fw inception decide T-804 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T10:18:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-804-why-is-the-human-ticking-acs-at-all-meas.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7cb15f60
- **Timestamp:** 2026-09-22T10:21:22Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T10:21:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
