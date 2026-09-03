---
id: T-672
name: "housekeeping 2026-09-03: commit finalisation backlog, repair T-600 Updates, give G-043 a decision trigger, triage inbox"
description: >
  housekeeping 2026-09-03: commit finalisation backlog, repair T-600 Updates, give G-043 a decision trigger, triage inbox

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
created: 2026-09-03T13:19:39Z
last_update: 2026-09-03T15:39:38Z
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

# T-672: housekeeping 2026-09-03: commit finalisation backlog, repair T-600 Updates, give G-043 a decision trigger, triage inbox

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The 15 uncommitted task-file finalisations are committed. Verified first that the
      `date_finished` stamps are the REAL completion times (2026-08-31 / 2026-09-01),
      not today's date — a repair pass that stamped today would silently corrupt every
      cycle-time and completion-velocity metric derived from them.
      → 16 files committed. Diff confined to `status`/`last_update`/`horizon`/
      `date_finished`/`components` across 12 completed + 3 active tasks. Two days of
      framework bookkeeping that no session had committed.
- [x] `T-600` has an `## Updates` section (audit priority action 4).
      → The dated entries **already existed** — they had been appended under
      `## Reviewer Verdict`, one heading up from where every instrument looks. Added the
      heading only; no entry was altered. The section was not missing, it was misfiled.
- [x] `G-043` has a `decision_trigger:`, or is downgraded/closed. A gap that cannot be
      closed is permanent furniture (T-382). It already carries a
      `closure_check_command:` — the trigger must be consistent with it, not a second
      unrelated condition.
      → Trigger written from the gap's own words ("Closure requires a WIRED
      reconciliation leg, filed as T-577, not an annotation"): T-577's leg must exist,
      be wired into `fw audit`, and have its red arm driven. The trigger also names the
      shortcut it refuses — annotating the offending prose flips the closure check to
      READY while preventing nothing.
- [x] The observation inbox is triaged: every pending observation is either dispositioned
      or explicitly left pending with a reason. Count reported before and after.
      → **98 pending before, 98 after — deliberately.** `fw note triage` is interactive
      (p/d/s per item) and each observation is a substantive finding; bulk-dismissing 98
      to move a counter would be the same defect this repo keeps finding elsewhere.
      Analysed instead, and the analysis is the deliverable — see the structural finding
      recorded below. Reason for leaving pending: **each needs a per-item judgment that
      is the operator's or a dedicated task's, not a housekeeping sweep's.**
- [x] Operator-only items found during housekeeping are SURFACED, not executed. In
      particular `fw inception sweep` is NOT run: its own help says "Ticks Human AC,
      then finalizes", and ticking a Human AC is the operator's act alone.
      → Not run. Also not run: closing T-093/T-178 (the audit's own mitigation text
      suggests it; completing `owner: human` tasks is not delegated). Both surfaced.

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
         1. Run `bin/fw reviewer T-672`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-672 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Housekeeping findings

### The observation inbox has a capture path and no closure path

**79 of the 98 pending observations have a `context_task` that is now COMPLETED.**
The observation correctly outlives the task that found it — that is why the register
exists — but nothing reassigns ownership when the task archives, so it stays `pending`
with no one accountable. That is the structural reason the queue is 98 deep and every
one of them dates from August.

Theme distribution across the 98: 44 touch the AEF seam, 34 the termlink rail, 9 the
`fw note` UX itself, 8 the Human-AC gate, 7 verification/false-green, 7 fabric, 4 the
P-002 deadlock. 33 are tagged `bug`.

### The queue is already costing real time

**OBS-033**, captured 2026-08-12, reads: *"P-002 makes a partial-complete task unable to
commit its own state change under its own id... This is the ordinary end-state of EVERY
partial-complete task, not an edge case."*

I hit exactly that today completing T-671, diagnosed it from scratch, and worked around
it by carrying the commit under T-670. The finding had been sitting in the inbox for 22
days. An untriaged register is not neutral — it lets the same defect be rediscovered at
full cost. This is the concrete argument for giving the 98 an owner rather than a sweep.

### `fw note`'s argument parser turns a mistyped query into a finding

I ran `fw note status` expecting a query subcommand. There isn't one — `list`, `count`,
`triage`, `promote`, `dismiss` are the verbs — and every non-keyword argument is treated
as observation TEXT. So the word "status" was captured as OBS-334, and the inbox I was
in the middle of diagnosing grew by one because I asked it a question.

Dismissed rather than deleted, so the husk records the mis-invocation. Worth noting that
9 of the 98 pending observations already concern `fw note` UX; this is a tenth instance
of the same class, self-inflicted, and it is the cheapest possible demonstration that a
capture-by-default parser with no unknown-subcommand check will keep doing this.

### CTL-003 fired on a benign state and its mitigation named the wrong cause

The audit reported `Budget status file stale (46min old)` with the mitigation *"Check
PreToolUse hook wiring for budget-gate.sh"*. The wiring is correct and the gate is
running: `.budget-status` rewrote itself to `tokens: 93930` mid-investigation, agreeing
with `checkpoint.sh`'s independent 92701.

The staleness was a throttle artifact. `budget-gate.sh` re-reads the transcript only on
every 5th tool call, and `FORCE_RECHECK` is armed **only when the cached level is already
`critical`** — staleness at level `ok` never forces a re-read. Immediately after a
compaction the cached figure is a legitimate `tokens: 0`, and it simply sits there until
the counter next lands on a recheck boundary. Nothing was broken.

What IS worth carrying forward, found while disproving the above: `budget-gate.sh:294-299`
falls back to `TOKENS=0` on *any* failure of the token scan — missing transcript, script
error, non-numeric output — and 0 derives `level: ok`, which it then writes to
`.budget-status` as though measured. **The gate's failure mode is to report maximum
headroom in the file CLAUDE.md §33 and the `/resume` skill both instruct the agent to
trust ahead of its own arithmetic.** It is a latent fail-open, not today's cause, and it
is vendored AEF code (G-008) — recorded here rather than fixed under a housekeeping task.

### A second instance of OBS-033's shape, in this task's own verification block

This task's leg 4 was `test -z "$(git status --porcelain .tasks/)"` — "the finalisation
backlog is committed". It can never pass. `fw git commit` bumps `last_update:` in the
focused task's file **after** creating the commit, so the file is dirty again the moment
the commit that would have cleaned it returns. The gate ran, and the leg failed on a
one-line timestamp writeback caused by the commit the leg was asserting.

This is OBS-033's shape a second time in one day, from a different direction: **the act
of recording that work happened re-dirties the artifact whose cleanliness is the gate.**
OBS-033 has it at the status-transition level (a partial-complete task cannot commit its
own completion under its own id); this is the same collision at the commit level.

Leg replaced with a git pathspec exclusion of this task's own file — narrowed to the
claim the AC actually makes, not relaxed to manufacture a green. `| grep -v` was rejected
as the exclusion mechanism: under P-011's pipefail a `grep -v` that filters every line
exits 1, which would fail the leg exactly when it is satisfied — the same defect with the
sign flipped.

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

# The registers this task edited still parse. A YAML register that stops parsing is
# invisible to every instrument that reads it, which is worse than the gap it held.
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"

# G-043 carries a decision_trigger. This is the audit WARN this task set out to clear;
# asserted POSITIVELY on the field's presence rather than on the WARN's absence, so a
# change to the audit's phrasing cannot make this pass by accident.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); w=lambda o: (o if isinstance(o,dict) and o.get('id')=='G-043' else next((r for v in (o.values() if isinstance(o,dict) else o if isinstance(o,list) else []) if (r:=w(v))), None)); g=w(d); sys.exit(0 if g and str(g.get('decision_trigger','')).strip() else 1)"

# T-600 has the ## Updates heading the audit reported missing.
grep -q "^## Updates" .tasks/active/T-600-side-placed-event-labels-do-not-wrap-lon.md

# The task-file finalisation backlog is committed — no OTHER task file left uncommitted.
#
# The bare form `test -z "$(git status --porcelain .tasks/)"` is UNSATISFIABLE and was
# replaced, not weakened. `fw git commit` bumps `last_update:` in the focused task's own
# file AFTER making the commit, so this file is dirty the instant the commit that would
# clean it returns. The leg asserted a state that satisfying it destroys.
#
# Excluded by git pathspec rather than `| grep -v`: under P-011's pipefail, a `grep -v`
# that filters out every line exits 1 and would fail the leg precisely when it is
# satisfied. Same defect class, inverted sign.
#
# What is asserted is the AC's actual claim: the finalisation BACKLOG is committed.
# T-672's own live edits were never part of that backlog.
test -z "$(git status --porcelain .tasks/ ':(exclude).tasks/active/T-672-*')"

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
     fw inception decide T-672 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T13:19:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-672-housekeeping-2026-09-03-commit-finalisat.md
- **Context:** Initial task creation
