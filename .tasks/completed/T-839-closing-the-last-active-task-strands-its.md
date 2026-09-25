---
id: T-839
name: "Closing the last active task strands its own commit: T-2054 exemption does not fire"
description: >
  Measured 2026-09-25 while closing T-837 and T-838 back to back. After the SECOND completion, focus.yaml current_task becomes null. check-active-task then BLOCKS both Write and any Bash that modifies - including the git commit that would record the closures. The hook's own message states 'Committing a just-completed task is NOT blocked, even with no focus (T-2054)' and then blocks it anyway, attributing the block to a $(...) substitution that is not present in the command. Tried and refused: multi-line -m, single-line -m, message prefixed 'T-837 + T-838:', message prefixed cleanly 'T-838:'. Also tried 'fw context focus T-838' - silently no-ops because the task is completed, leaving current_task null. NET EFFECT: an agent that correctly closes its last active task cannot commit that closure, cannot write a note about it, and the prescribed remedy is to create a task - which is what this is. The staged closure sits in the index meanwhile, which is the exact state P-009's commit-cadence rule exists to prevent.

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
created: 2026-09-25T06:12:31Z
last_update: 2026-09-25T06:29:21Z
date_finished: 2026-09-25T06:29:21Z
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

# T-839: Closing the last active task strands its own commit: T-2054 exemption does not fire

## Context

Found by walking into it while closing T-837 and T-838 back to back. Probe:
`tools/_t839-commit-exemption-probe.sh` (11/11).

## Root cause — TWO defects, and the second is why the first cost four attempts

### Defect 1 — the exemption is wrapper-blind (this is what blocked the commit)

`.agentic-framework/agents/context/lib/safe-commands.sh` · `_sc_is_commit_only_command()`
splits the command into clauses and matches each one **positionally**: `tok1` (path-stripped),
`tok2`, `tok3`. The `git` branch needs `tok1=git, tok2=commit`; the `fw` branch needs
`tok1=fw, tok2=git, tok3=commit`. **Any exec-wrapper prefix shifts every token**, the `case`
falls through to `_sc_simple_is_safe`, that rejects, and the whole command is judged not
commit-only — so `check-active-task.sh:252` never grants the T-2054 exemption.

Measured, and the discriminators matter as much as the failures:

| command | verdict |
|---|---|
| `fw git commit -m …` | ALLOW |
| `git commit -m …` | ALLOW |
| `cd $REPO && fw git commit -m …` | **ALLOW** — `cd` is NOT the cause |
| `git add a && fw git commit -m …` | ALLOW (the documented shape) |
| `timeout 300 fw git commit -m …` | **BLOCK** |
| `cd $REPO && timeout 300 fw git commit -m …` | **BLOCK** ← the shape used on T-837/T-838 |
| `env GIT_X=1 fw git commit -m …` | **BLOCK** |
| `nice fw git commit -m …` | **BLOCK** |

The class is exec-wrappers generally — `timeout`, `env`, `nice`, and by the same token walk
`nohup`, `command`, `stdbuf`. **A timeout on a commit is ordinary defensive shell**, not an
evasion: it is there so a hung commit cannot wedge the session. The gate refuses the careful
spelling and admits the careless one, which is T-652's defect in a third place — that comment
in the file already records the same shape for `fw git commit` vs `git commit`.

### Defect 2 — the block message names a cause it never tested (PL-304)

`.agentic-framework/agents/context/check-active-task.sh:292`:

```bash
if [ "$TOOL_NAME" = "Bash" ] && [[ "$BASH_CMD" =~ git[[:space:]]+commit ]]; then
    echo "Committing a just-completed task is NOT blocked, even with no focus (T-2054)."
    echo "What blocks here is a \$(...) substitution sharing the line with the commit:"
```

The branch fires on the command merely **containing** `git commit`. It performs **zero** test
for `$(` — verified by grep over the emitting block. So it asserted a substitution was present
in four consecutive commands that contained none.

The irony is load-bearing: the comment directly above it says *"Name that, or the next agent
concludes it is stuck and reaches for a borrowed focus or a Tier-2 bypass — which is what
happened at T-643."* The naming is there. It names the **wrong thing** whenever the cause is
anything but a substitution, and a confidently-wrong diagnosis is worse than silence, because
the reader acts on it. I spent four attempts editing message text — multi-line `-m`, single-line
`-m`, prefix `T-837 + T-838:`, prefix `T-838:` — hunting a substitution that never existed, and
`fw context focus T-838` silently no-ops on a completed task (G-013 requires the focused task in
`active/`), so there was no way back either.

**The four refused invocations, verbatim in shape:**
1. `cd $REPO && timeout 300 .agentic-framework/bin/fw git commit -m "<multi-line>"`
2. `cd $REPO && timeout 300 .agentic-framework/bin/fw git commit -m "<single-line>"`
3. same, message prefixed `T-837 + T-838:`
4. same, message prefixed cleanly `T-838:`

Every one carried `timeout 300`. None carried a `$(`.

## Remediation — scoped, NOT implemented here

Both files are vendored AEF framework code, so this is upstream's to land.
`safe-commands.sh` already carries a declared divergence (`kind: content`, T-404/T-405/T-390,
`upstream: fix`), which is why the fix is proposed rather than applied unilaterally.

**R1 (defect 1, small).** Before the positional walk, strip a leading exec-wrapper from each
clause: `timeout [opts] N`, `env [VAR=val]...`, `nice [-n N]`, `nohup`, `command`, `stdbuf
[opts]`. Strip only from a **closed allowlist** — never "skip tokens until something matches" —
so an unknown binary whose arguments happen to contain `git commit` is still refused, which is
the exact hole T-638 closed and must not be reopened.

**R2 (defect 2, smaller and more valuable).** Make the diagnosis conditional. Test the command
for `$(`/backtick and say so only then; otherwise report which clause actually failed
`_sc_simple_is_safe`. A gate that can name the refusing clause turns a four-attempt hunt into
one read.

**R2 is worth more than R1** even though R1 is the blocker: R1 fixes one spelling, R2 fixes
every future misdiagnosis of this predicate — and the predicate will keep growing clauses.

**Sovereign question (SQ-7), not decided here:** both changes touch a PreToolUse enforcement
path. R1 widens what the exemption admits, which is a governance-surface change however
narrow the allowlist. Whether to take R1, R2, or R2-only is the operator's and upstream's —
an agent widening the gate that governs it is the shape this whole register exists to prevent.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The block is reproduced by a control that FAILS if the defect is absent.** A script that
      sets `current_task: null` in a throwaway fixture, invokes the hook's predicate with a
      commit-shaped command, and asserts it BLOCKS. A control that only demonstrates the current
      behaviour proves nothing about the fix (PL-206) — it must also pass against a fixture where
      focus IS set, so the leg discriminates rather than merely agreeing with today's output.

- [x] **The hook's stated exemption and its actual behaviour are shown to disagree, in the
      hook's own text.** The message says "Committing a just-completed task is NOT blocked, even
      with no focus (T-2054)" and then blocks, attributing the block to a `$(...)` substitution
      that is not in the command. Cite the file and line of both the exemption and the predicate
      that overrides it. A gate that names the wrong reason is PL-304's failure mode and this is
      an instance of it.

- [x] **Four refused invocations are recorded verbatim**, so the next reader does not re-derive
      them: multi-line `-m`; single-line `-m`; message prefixed `T-837 + T-838:`; message
      prefixed cleanly `T-838:`. Plus `fw context focus T-838` silently no-opping on a completed
      task, leaving `current_task: null`.

- [x] **The fix is scoped and the alternative is named, without either being implemented here.**
      Either the exemption learns to detect a just-completed task from the index/`git diff
      --cached` rather than from focus, or `fw context focus` accepts a just-completed task for a
      grace window. Both touch a PreToolUse enforcement path, so which one lands is a Sovereign
      question — recorded as such, not chosen.

- [x] **No bypass was used to escape it.** Verified by `.context/working/.gate-bypass-log.yaml`
      carrying no new entry for this task. The route out was the gate's own remedy #1 (create a
      task), which is why this task exists at all.

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
         1. Run `bin/fw reviewer T-839`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-839 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

bash tools/_t839-commit-exemption-probe.sh
grep -q "_sc_is_commit_only_command" .agentic-framework/agents/context/lib/safe-commands.sh
grep -q "substitution sharing the line" .agentic-framework/agents/context/check-active-task.sh
grep -q "Defect 1 — the exemption is wrapper-blind" .tasks/active/T-839-closing-the-last-active-task-strands-its.md
# No bypass was used to escape this gate — the route out was the gate's own remedy #1.
# NOT "the log is unchanged": it carries two UNCOMMITTED entries predating this session
# (2026-09-08 T-685, 2026-09-22 T-788, both --skip-sovereignty from check_human_sovereignty,
# i.e. the operator's inception-decide path). Asserting no-diff would have been a false
# claim about someone else's rows. Assert the precise thing instead: nothing for this task,
# and nothing dated today.
grep -c "T-839" .context/working/.gate-bypass-log.yaml > /tmp/.t839b1.out 2>&1; test "$(cat /tmp/.t839b1.out)" = "0"
grep -c "2026-09-25" .context/working/.gate-bypass-log.yaml > /tmp/.t839b2.out 2>&1; test "$(cat /tmp/.t839b2.out)" = "0"

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
     fw inception decide T-839 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-25T06:12:31Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-839-closing-the-last-active-task-strands-its.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6f7d5ba9
- **Timestamp:** 2026-09-25T06:29:22Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-25T06:29:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
