---
id: T-649
name: "warn when a task is completed with its own work still uncommitted (G-047 prevention)"
description: >
  warn when a task is completed with its own work still uncommitted (G-047 prevention)

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
created: 2026-08-31T11:59:20Z
last_update: 2026-08-31T12:04:41Z
date_finished: 2026-08-31T12:04:41Z
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

# T-649: warn when a task is completed with its own work still uncommitted (G-047 prevention)

## Context

G-047 records a four-way deadlock: after `--status work-completed`, a task's own diff cannot
be committed. Focus on the completed task refuses every write; focus elsewhere trips
focus-drift on a `T-NNN:` subject; `work-completed` is terminal so the task cannot be
reopened; and with focus null, `git commit` is admitted but `git add` is not.

Observed again today, and worse than registered: **with focus null the gate refuses even a
read.** A plain `cat .context/working/.budget-status` was blocked by P-002. So the null-focus
escape hatch is narrower than G-047 describes.

Every exit is a Tier-2 bypass, which is the operator's to grant and not mine. The cadence
that avoids the trap entirely is **commit before you complete** — and it is written down
nowhere. It held on all four tasks today (T-647, T-646, T-645, T-648); nothing was stranded.

CLAUDE.md is explicit that mitigation is not prevention: *"Do not close the gap until
prevention exists… Did I fix the symptom, or did I fix the reason the framework couldn't
detect it?"* A cadence I happen to remember is not prevention. A check that notices is.

**Why a warning and not a block.** A block would be wrong here. Uncommitted working-memory
churn under `.context/` is normal and constant, and completion is often the right moment to
proceed anyway. The failure is not "uncommitted files exist" — it is "you are about to lose
the ability to commit THESE files under THIS task, and nothing tells you". That is an
awareness defect, so the fix is to say so, at the last moment when acting on it is still free.

**Predicate:** tracked, modified, non-`.context/` files at the moment of the transition,
excluding the task file itself (which the transition is about to move anyway). That is a
heuristic — it cannot know which edits "belong to" the task — and the warning is worded to
suit a heuristic: it names the files and the cadence, and asserts nothing about ownership.

## Acceptance Criteria

### Agent
- [x] `update-task.sh` prints a warning on the `work-completed` transition when tracked, modified, non-`.context/` files are present, naming up to 5 of them
- [x] The warning names the CADENCE (commit before complete) and the gap (G-047), so the reader can act rather than just feel warned
- [x] It is a WARNING, not a gate: exit status of the transition is unchanged and the task still completes — proven by completing a task with a dirty tree
- [x] It does not fire on a clean tree, and does not fire when the only modifications are under `.context/` (working-memory churn) or the task file itself
- [x] It does not fire on non-`work-completed` transitions
- [x] A prober `tools/_t649-*.sh` pins all of the above against the REAL script in a throwaway git repo — no append-only ledger or live task is touched, and no live `.tasks/` state is mutated
- [x] The prober has teeth: removing the check makes it fail
- [x] G-047 is updated with today's evidence (cadence held 4/4) and with the null-focus read-block, which the original entry did not know about

**Evidence.**

`bash tools/_t649-completing-with-uncommitted-work-warns.sh` → **8 passed, 0 failed**, every
leg run against the REAL `warn_uncommitted_work()` lifted out of `update-task.sh` and executed
in a throwaway git repo. No live task was completed to test a warning about completing tasks.

Legs: silent on a clean tree · silent on `.context/` churn alone · silent when only the task
file changed · warns and names file + cadence + G-047 + task id · returns 0 (warning, not gate)
· silent on `started-work` · truncates a 9-file list with "and 3 more" · teeth (neutralise the
warning line and the dirty-tree leg goes quiet).

**A correction I made to my own work mid-task.** I first wrote the call site with the comment
"Runs FIRST among the completion checks so the reader sees it even when a later gate refuses."
It did not run first — three gates preceded it. I moved it, found three MORE gates in front
(sovereignty, P-010, P-011), and then stopped moving it, because on reflection the placement
was right and the comment was wrong: if a hard gate refuses, the transition did not happen and
nothing has been lost yet, so warning there would be noise on an attempt that was never going
to complete. The comment now says that. **A comment asserting an ordering is a claim like any
other, and I had shipped two versions of it without checking either.**

G-047 updated: the null-focus read-block (measured today — even `cat` is refused with no active
task, which clause (d) did not know), the 4/4 cadence result, what this ships against
`decision_trigger` clause (c), and explicitly what is still missing so the update cannot be
mistaken for closure.

## Recommendation

**Recommendation:** GO — ships prevention against half of one clause; the gap stays open.

**Rationale:** CLAUDE.md is explicit that mitigation is not prevention and that a gap does not
close until prevention exists. This is prevention, and it is deliberately partial: a warning
tells you the trap is ahead, it does not build a way out once you are in it. Clauses (a) and
(b) of the decision trigger — reopening a completed task, and the completed-task gate admitting
that task's own paths — are untouched and are framework-design questions, not agent fixes.

**The half of clause (c) I did not do, and why it is yours.** It also asks that CLAUDE.md's
completion checklist state the cadence; its "When completing" list still puts the status change
before any mention of committing, which is what makes the trap reachable at all. That is an
edit to this project's operating instructions, so it is your call rather than mine. The exact
change is one line: in **§Working with Tasks → When completing**, add *"commit the task's work
BEFORE setting status"* ahead of the current step 4.

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

bash tools/_t649-completing-with-uncommitted-work-warns.sh
bash -n .agentic-framework/agents/task-create/update-task.sh
bash -n tools/_t649-completing-with-uncommitted-work-warns.sh
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[x for x in d['concerns'] if x['id']=='G-047'][0]; sys.exit(0 if 'T-649' in g['tasks'] else 1)"

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

### 2026-08-31T11:59:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-649-warn-when-a-task-is-completed-with-its-o.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0bb28c88
- **Timestamp:** 2026-08-31T12:04:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-31T12:04:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
