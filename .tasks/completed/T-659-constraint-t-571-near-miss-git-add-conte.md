---
id: T-659
name: "Constraint T-571 near-miss: git add .context/ swept 338 cron retention deletions into the index"
description: >
  Constraint T-571 near-miss: git add .context/ swept 338 cron retention deletions into the index

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t659-retention-sweep-must-not-be-agent-staged.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T18:46:17Z
last_update: 2026-08-31T18:50:43Z
date_finished: 2026-08-31T18:50:43Z
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

# T-659: Constraint T-571 near-miss: git add .context/ swept 338 cron retention deletions into the index

## Context

My own error, caught by my own check, one command after making it. Wrapping up T-658 I ran
`git add .context/` to pick up an episodic file. `.context/audits/cron/` holds 338 pending
deletions from the 7-day retention cron — not mine to commit (T-571) — and a directory-wide
add takes all of them. The very next line I ran counted them and printed `338`.

Three windows of discipline held this line by staging explicit paths every time. It broke
the moment I typed a directory instead of a filename, while *believing* I was following the
rule, because the rule lives in my head and the index does not consult it.

The correction (unstage) is trivial. What is worth the task is that the gate which caught
it was a habit, not a mechanism — and habits are exactly what fail under wrap-up fatigue.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The index contains zero `.context/audits/cron/` paths, and the 338 deletions remain
      in the working tree unstaged — reverted from the index, not resurrected on disk and
      not committed.
- [x] The files that genuinely belong to T-658's completion (fabric card, episodic,
      completed task file) are still staged. Fixing the over-stage must not throw away the
      correct part of it.
- [x] A **mechanism** replaces the habit: something that fails loudly when cron-retention
      deletions are staged, so the next occurrence is not caught by my remembering. Habit
      is what just failed; re-resolving to be careful is not a fix.
- [x] That mechanism is proven to fire on a staged cron deletion and to stay silent on a
      normal `.context/` staging — asserted on a throwaway repo, never on this one's index.
- [x] The check is **not** a new bespoke reimplementation if the framework already has a
      staging guard to extend. Checked first, and which way it went is recorded here.
- [x] Any framework-file change is declared in `.vendor-divergence.yaml` (G-008).

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

# The guard, proven on throwaway repos only. Exit code is the verdict.
bash tools/_t659-retention-sweep-must-not-be-agent-staged.sh

# The mechanism must be LIVE, not merely written into the generator. A guard that exists
# only in hooks.sh and was never installed is the exact defect this session kept fixing.
grep -q 'T-659' .git/hooks/pre-commit

# No cron path may be staged right now.
test 0 -eq "$(git diff --cached --name-only | grep -c 'audits/cron/')"

# The edited generator must still parse, and the change must be declared (G-008).
bash -n .agentic-framework/agents/git/lib/hooks.sh
python3 tools/_t517-vendor-divergence.py

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

**Symptom:** `git add .context/`, run to stage one episodic file, staged 338 pending
retention-cron deletions along with it. Caught one command later by a count I happened to
print in the same breath.

**Root cause:** the constraint "stage explicit paths, never a directory" was enforced by
agent memory. It survived three sessions of deliberate application and then failed on the
first command where the agent's attention was on the *destination* file rather than on the
directory it named.

**Why structurally allowed:** nothing in the commit path knew that
`.context/audits/cron/` deletions have a different owner from everything else in
`.context/`. Git treats a directory add as an unremarkable operation, and it is — the
policy distinction existed only in prose.

**Prevention:** a pre-commit guard that refuses staged deletions under that path when
$CLAUDECODE=1, prints the unstage command, and leaves the operator's own sweep untouched.
Distinct from the fix (unstaging today's 338): that recurs by definition; this reports it.
Proven live — the AC and Verification both assert the guard is present in
`.git/hooks/pre-commit`, not merely in the generator that emits it.

**Known residual:** the guard is path-specific. Another directory acquiring a
different-owner subset would need its own entry; there is no general notion of
"paths this actor may not stage".

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

### 2026-08-31 — extend the existing pre-commit hook, do not add a new surface

- **Chose:** the guard lives in the pre-commit hook `hooks.sh` already generates, ahead of
  the secret scan and beside the master-guard.
- **Why:** a pre-commit hook is where staging policy is already enforced in this project,
  and it is the last point before the mistake becomes history. Checked before writing:
  `hooks.sh` already inspects `git diff --cached` in two places, so this is an extension of
  an existing pattern rather than a second mechanism competing with it.
- **Rejected:** a PreToolUse hook on `git add`. It would fire on the command rather than on
  the resulting index, so `git add -A` and `git commit -a` would both slip past, and it
  would nag on adds that are entirely correct.

### 2026-08-31 — block the agent, never the operator

- **Chose:** gate on `$CLAUDECODE=1`, with `FW_ALLOW_RETENTION_SWEEP=1` as the documented
  deliberate path.
- **Why:** the deletions must reach git eventually or the pruned files return. The problem
  was never that they get committed — it is *who* decides to commit them. A guard that
  blocked everyone would convert an ownership rule into an obstruction and be bypassed
  routinely, which is how gates stop being read.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T18:46:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-659-constraint-t-571-near-miss-git-add-conte.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1b26390a
- **Timestamp:** 2026-08-31T18:50:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-31T18:50:43Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
