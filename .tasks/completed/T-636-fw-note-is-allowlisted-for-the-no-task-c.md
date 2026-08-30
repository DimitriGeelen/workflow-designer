---
id: T-636
name: "fw note is allowlisted for the no-task case and was refused anyway"
description: >
  fw note is allowlisted for the no-task case and was refused anyway

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
created: 2026-08-29T22:39:02Z
last_update: 2026-08-29T22:48:50Z
date_finished: 2026-08-29T22:48:50Z
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

# T-636: fw note is allowlisted for the no-task case and was refused anyway

## Context

Completing T-635 cleared focus. The next action was to file the observation T-635 turned
up, and `fw note "<text>" --tag census --task T-635` was refused by check-active-task with
"No active task."

`fw note` is explicitly allowlisted for exactly this state. safe-commands.sh:240 (T-390):

    `fw note` is the lightweight observation inbox — the verb for recording something
    you noticed but are not acting on now. Blocking it with no active task is
    self-defeating in a specific way: the framework could not record the observation
    that it cannot record observations.

So the intent is on record and the behaviour contradicts it. A probe of the classifier — a
`bash -c` sourcing safe-commands.sh to print the predicates for four `fw note` forms — was
refused by the same gate, which is why investigating this needs a task at all.

Known, and NOT yet the mechanism: the same kind of text filed cleanly last session while
T-633 was active, so the gate passed on "a task exists" and never consulted the allowlist.
That tells us the allowlist branch is rarely exercised; it does not tell us why it fails
when it is. The mechanism is to be measured, not inferred — the first hypothesis in T-632
(a `>` inside the quoted argument) was wrong there and is only a candidate here.

## Acceptance Criteria

### Agent
- [x] The mechanism is identified by MEASUREMENT: which predicate refuses the command, and
      at which of check-active-task's checks — not inferred from the block message
      — `has_bash_write_pattern`'s raw-string destructive-VERB scan matches `rm` inside
      the quoted prose; check-active-task.sh:91 checks it BEFORE the allowlist, so the
      `note` branch at safe-commands.sh:240 is never reached. Both hypotheses that read
      as obvious were wrong first: the `>` in the prose (the redirect walk runs on the
      stripped string) and apostrophe desync (`_sc_strip_quoted` is a state machine that
      tracks which quote opened the span).
- [x] `fw note "<text>"` with focus genuinely null is accepted by the hook, measured
      through `check-active-task.sh` rather than through the library in isolation
- [x] The fix does not widen the gate: with focus still null, a command that must be
      refused is still refused (anti-vacuity control in the same run)
      — `make install` still rc=2; 5 must-block forms still refused, including
      `fw note "$(...)"`, because a command substitution disqualifies the exemption
- [x] A prober pins the no-task case for EVERY verb the framework declares safe with no
      active task (`note`, `handover`, `task create`, `context add-*`), so the next one to
      regress reddens instead of being discovered by a blocked session — 7 verbs pinned
- [x] Teeth: reverting the fix turns the prober red, and any mutation anchor is asserted
      to occur exactly once — two-file mutation (lib + hook, both staged beside their
      originals); without the exemption the observation is refused again
- [x] The observation that could not be filed is filed — OBS-324

Added during the work, because the corpus and the prober each caught something:
- [x] The corpus perf contract caught the first draft of `_sc_is_framework_prose_verb`
      forking three awks per Bash call; rewritten with pure parameter expansion and a
      matching contract test added for the new helper
- [x] The must-not-widen list caught a case that turned out to be pre-existing (a
      compound command led by `git commit` passes on the T-2054 branch). Filed as
      OBS-325 rather than fixed here — one bug, one task — and the prober asserts only
      that the real and exemption-free hooks agree on it, a claim that survives a fix
- [x] Corpus extended 71 → 89 with both sides of the new boundary

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

bash tools/_t636-prose-verbs-vetoed-by-their-own-text.sh
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q
bash tools/_t632-read-only-misclassification.sh

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

**Symptom:** `fw note "<text mentioning rm>"` refused with "No active task", in the one
state the `note` exemption exists for.

**Root cause:** `has_bash_write_pattern` scans the RAW command string for destructive
verbs, so a quoted mention matches. check-active-task checks the write predicate BEFORE
the safe-command allowlist, so the veto is final and the exemption is never consulted.

**Why structurally allowed:** the raw scan is a deliberate T-404 decision resting on an
asymmetry — a false positive costs "you need an active task", a false negative lets
`sh -c "rm -rf x"` past. The reasoning is about EXECUTION and is correct for arguments
that are code. Nothing noticed that four framework verbs take arguments that are PROSE,
stored and never run, where the cheap side of the asymmetry is the expensive one. It went
undetected because the allowlist branch is only reached with focus null — a state that
occurs at the exact moment a task completes, which is also the moment you most want to
file the observation you just turned up.

**The block message made it worse than the block.** "No active task" names a cause that
is not the cause and hands over the remedy "create a task" — precisely what the note
exemption exists to avoid. A gate that misreports why it fired sends the reader somewhere
useful-looking and wrong.

**Prevention:** the exemption scans the stripped string rather than skipping the scan, so
clauses outside the quotes are judged as before, and a command substitution disqualifies
it outright. `tools/_t636-*.sh` drives the real hook with focus null for all seven
no-task verbs and proves by two-file mutation that the exemption is what carries them;
the corpus pins both sides of the boundary and holds a fork contract on the new helper.

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

### 2026-08-29T22:39:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-636-fw-note-is-allowlisted-for-the-no-task-c.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-498c586d
- **Timestamp:** 2026-08-29T22:49:06Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T22:48:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
