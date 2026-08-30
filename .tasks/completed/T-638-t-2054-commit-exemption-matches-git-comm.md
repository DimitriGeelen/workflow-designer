---
id: T-638
name: "T-2054 commit exemption matches git commit anywhere, so a compound command carries its other clauses past the active-task gate"
description: >
  T-2054 commit exemption matches git commit anywhere, so a compound command carries its other clauses past the active-task gate

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
created: 2026-08-30T08:32:22Z
last_update: 2026-08-30T08:41:16Z
date_finished: 2026-08-30T08:41:16Z
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

# T-638: T-2054 commit exemption matches git commit anywhere, so a compound command carries its other clauses past the active-task gate

## Context

The T-2054 branch in `check-active-task.sh` exists for one narrow, well-argued reason:
`--status work-completed` nulls focus and moves the task out of `active/`, so the
completion's own file-move and episodic could never be committed. Its justification is
written into the comment — *"Committing persists work already produced under the Write/Edit
task gate — it is not new work."*

That justification is true of a command that **is** a git commit. The branch tests whether
the command **contains** one:

```
[[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]
```

So `git commit -m "T-x: y"; rm -rf /some/path` matches, and the whole compound command —
every clause of it — runs with no active task. Worse, the branch sits *after* the
write-pattern check at line 91, which does not `exit`, it falls through. So a command whose
second clause `has_bash_write_pattern` correctly identifies as destructive is then handed an
`exit 0` by this branch. The gate detects the write and admits it anyway.

This is the framework's central gate — "nothing gets done without a task" — and the
exemption is one `;` wide. Found while probing T-636 (OBS-325).

Same family as the four before it: a character-level scan standing in for structure, so a
command that MENTIONS a commit is treated as one.

## Acceptance Criteria

### Agent
- [x] The T-2054 exemption fires only when **every** clause of the command is a `cd` or a
      `git commit` — the property its own comment claims. `cd /path && git commit -m "..."`
      still works (it is the project's documented copy-pasteable form).
- [x] Clause splitting reads the **quote-stripped** command, so a `;` or `&&` inside a commit
      message is message text and not a clause boundary. Reuses `_sc_strip_quoted`; does not
      hand-roll a second quote parser.
- [x] A command containing `$(` or a backtick never takes the exemption — substitution runs
      arbitrary code that no clause check can see. (Same precedent as T-636.)
- [x] `git commit ... ; rm -rf <path>` is BLOCKED with no active task, and the rest of the
      compound never runs.
- [x] `--no-verify` / `-n` exclusion is preserved unchanged.
- [x] A mutation prober drives the REAL hook (not a pinned copy) and dies if the fix is
      reverted — the mutant must disagree with the live hook on the compound case and agree
      with it on the legitimate ones.
- [x] The fix does not widen the gate: no command blocked before this change is allowed after
      it.

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

# Mutation prober: drives the REAL hook, and a mutant carrying the pre-fix regex
# derived from live source. Both directions — holes closed, legitimate forms kept,
# gate not widened, and the mutant must still SHOW the hole or the greens are unearned.
bash tools/_t638-commit-exemption-is-clause-scoped.sh
# The standing corpus for this library, extended with the predicate's own contract.
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q

## RCA

**Symptom:** With no active task, `git commit -m "..." ; <anything>` ran in full —
every clause past the framework's central gate. So did `git commit ... | tee f`,
and so did `somebinary --flag "please git commit this"`, an arbitrary unknown
binary admitted because a quoted argument contained the words.

**Root cause:** The T-2054 exemption asked whether the command CONTAINED a commit
(`=~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]])`, on the raw unstripped
string) when its own written justification — "persists work already produced under
the Write/Edit task gate — it is not new work" — is only true of a command that IS
one. A second, compounding defect: the write-pattern check earlier in the hook
falls through rather than exiting, so a command already flagged as a write reached
this branch and was handed `exit 0`. The gate saw the write and admitted it.

**Why structurally allowed:** The library had the right tools — `_sc_strip_quoted`
and the per-segment splitter that `is_bash_safe_command` uses — and this branch
used neither, because it lives in the hook rather than the library and was written
as a one-line regex. Nothing tested the branch: the corpus covered the predicates
in `safe-commands.sh`, and the exemption was in `check-active-task.sh` where no
test reached it. Six instances in three days of one class (character-level scan
standing in for structure) and this was the one with a governance consequence.

**Prevention:** distinct from the fix in both directions. (1) The predicate now
lives in the library beside the splitter it reuses, and has 21 corpus tests that
run on every change to that file. (2) `tools/_t638-…sh` derives a pre-fix mutant
from live source and asserts real-vs-mutant DISAGREEMENT on the holes — reverting
the fix turns the prober red rather than silently restoring the bypass. (3) A
no-widening leg tests the direction nobody checks: real allows nothing the mutant
blocked.

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

### 2026-08-30T08:32:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-638-t-2054-commit-exemption-matches-git-comm.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-34c4fe51
- **Timestamp:** 2026-08-30T08:41:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-30T08:41:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
