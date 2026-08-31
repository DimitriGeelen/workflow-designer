---
id: T-586
name: "kill worktree isolation and pin no-background-install as policy"
description: >
  kill worktree isolation and pin no-background-install as policy

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-25T12:11:15Z
last_update: 2026-08-27T19:30:41Z
date_finished: 2026-08-27T19:30:22Z
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

# T-586: kill worktree isolation and pin no-background-install as policy

## Context

The operator asked, twice in two sessions, whether we were "stuck in a worktree again".
Measured both times: we were not, and this repo never has been — `.git` is a directory,
`git rev-parse --git-dir` equals `--git-common-dir`, `git worktree list` holds one entry,
and `.git/worktrees/` does not exist (git creates that directory on the first
`git worktree add` and never removes it, so its absence is proof none was ever made).

But the question kept being askable because nothing prevented it. `permissions` in
`.claude/settings.json` was empty — 0 deny rules — so `EnterWorktree`,
`Agent(isolation: "worktree")` and `git worktree add` were all reachable. A capability
that has never been wanted, and is repeatedly suspected, is worth removing rather than
re-measuring on request.

Second instruction from the same message: **no background installation unless explicitly
instructed.** Measured at filing — six cron entries, all read-only `fw audit --cron` plus
one `.context/audits/cron/` retention sweep; no systemd timers; no running process and
no cron path calling `fw update`, `fw upgrade`, `do_vendor`, `npm install`, `pip install`
or `apt-get`. The state is already correct. This task pins it so that adding one later is
a deliberate act rather than a drift nobody notices.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The deny rules that make worktree isolation unreachable are SPECIFIED and machine-
      checkable, covering every route it has: the `EnterWorktree` / `ExitWorktree` tools
      AND `git worktree` via Bash. Denying only the tool would leave the shell path open,
      which is gating a surface instead of the capability behind it.
      *Applying* them is the Human AC below, not this one — `.claude/settings.json` is
      gated by B-005 and the agent is structurally blocked from writing it. An Agent AC
      the agent can never check would park this task permanently.
- [x] A guard asserts those rules are still present, so removing them is loud rather than
      silent. A policy that lives only in a config file is one careless edit from gone,
      and its absence looks exactly like its presence until somebody tests it.
- [x] The guard PROVES IT CAN FAIL, demonstrated against a fixture with the rules
      stripped. It asserts the presence of config and would otherwise be satisfied by
      successfully reading any file at all.
- [x] The guard is wired into `tests/run-bridge-tests.sh` in the same commit — a guard
      nothing runs is a guard that finds nothing.
- [x] The no-background-install position is recorded together with the measurement that
      backs it (the cron inventory at time of filing), not as a bare assertion.
- [x] `fw enforcement baseline` refreshed, since `.claude/settings.json` changed (L-398),
      so `fw doctor` does not accumulate a silent FAIL.

### Human
- [ ] [RUBBER-STAMP] Apply the worktree deny rules to `.claude/settings.json`
      **Why this is yours and not the agent's:** B-005 (Enforcement Config Protection)
      blocks agent writes to `.claude/settings.json`, because that file controls the task
      gates, Tier-0 checks and budget enforcement. The gate fired when the agent tried.
      That is the gate working, not an obstacle to route around.
      **Steps:**
      1. Run, from anywhere, exactly this one line:
         `cd /opt/832-Workflow-designer && python3 -c "import json;p='.claude/settings.json';d=json.load(open(p));d.setdefault('permissions',{})['deny']=['EnterWorktree','ExitWorktree','Bash(git worktree:*)'];json.dump(d,open(p,'w'),indent=2)" && .agentic-framework/bin/fw enforcement baseline`
      2. Confirm it took: `cd /opt/832-Workflow-designer && python3 tools/_t586-worktree-denial-guard.py`
      **Expected:** step 2 prints `[denied]` on all three routes and `All worktree routes
      are denied.`, exiting 0. The bridge-suite leg for T-586 goes green at the same time.
      **If not:** the guard names which route is still open and reprints the command. If
      the JSON edit failed, `.claude/settings.json` is unchanged — it is written in one
      shot, so a failure leaves the old file intact rather than a half-written one.

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
         1. Run `bin/fw reviewer T-586`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-586 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# 1. The deny rules are in place, by every route. RED until the operator applies them,
#    which is the point: this task is not done while a worktree route is still open, and
#    the completion gate should say so rather than let it close on the agent's half.
python3 tools/_t586-worktree-denial-guard.py

# 2. We are in the MAIN tree, and no worktree has ever been registered here. The second
#    half is the load-bearing one — git creates .git/worktrees on the first `worktree add`
#    and never removes it, so its absence is evidence about history, not just about now.
sh -c 'test "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" && test ! -e .git/worktrees'

# 3. Nothing in cron installs anything. This is an ABSENCE assertion, so it carries a
#    positive control on the same line: `grep -qF agentic-cron` proves the file exists, is
#    readable, and that grep matches inside it. Without that, a renamed or deleted cron
#    file would satisfy the absence clause by being unreadable (T-560's whole subject).
#    The control earned its place immediately: it was first written `grep -q "fw audit"`,
#    which matches ZERO times because cron writes the path quoted — `bin/fw" audit`. The
#    leg went red on a correct system, and the control is the only reason that read as
#    "my pattern is wrong" rather than "an installer appeared".
sh -c 'f=/etc/cron.d/agentic-audit-832-workflow-designer; test -s "$f" && grep -qF "agentic-cron" "$f" && ! grep -qE "do_vendor|npm install|pip install|apt-get|update|upgrade" "$f"'

# 4. Wired into the suite. A guard nothing runs is a guard that finds nothing.
grep -q "_t586-worktree-denial-guard.py" tests/run-bridge-tests.sh

## Measurements

### Worktree state, 2026-08-25 — five independent checks, all negative

| check | result | why it settles the question |
|---|---|---|
| `git rev-parse --git-dir` vs `--git-common-dir` | both `.git` | in a linked worktree these differ; identical means main tree |
| `.git` | a directory | a linked worktree has `.git` as a *file* holding a `gitdir:` pointer |
| `git worktree list` | one row, `/opt/832-Workflow-designer 3457eea5 [master]` | no linked trees registered |
| `.git/worktrees/` | **does not exist** | git creates it on the first `git worktree add` and never removes it — absence proves none was ever created |
| `pwd` vs `readlink -f .` | identical | no symlink indirection making a worktree look like the main tree |

The fourth row is the load-bearing one: it is evidence about the repo's whole history,
not just its current state. The other four could all be true of a tree that had been a
worktree yesterday.

### Background installation, 2026-08-25 — nothing installs anything

`/etc/cron.d/agentic-audit-832-workflow-designer` holds six entries. Five are
`fw audit --cron` at varying sections and cadences; the sixth is a python one-liner that
deletes `.context/audits/cron/*.yaml` older than 7 days. That retention sweep is also the
explanation for the long list of `D .context/audits/cron/...` deletions in `git status` —
those are cron's, not the agent's, and must not be staged (T-571).

Searched and found nothing: no cron path referencing `fw update`, `fw upgrade`,
`do_vendor`, `npm install`, `pip install` or `apt-get`; no systemd timer naming this
project; no running process matching those patterns.

**Position recorded:** no background installation is to be added. If one is ever wanted it
is an explicit instruction, filed as its own task, not a convenience someone adds inline.
The measurement above is the baseline any future audit compares against.

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

## Recommendation

**Recommendation:** GO — ready for your tick. The `[RUBBER-STAMP]` Human AC's own Expected clause
is already satisfied, and the evidence is mechanical rather than my assessment.

**Evidence the AC asked for, measured after your edit:**

| The AC's Expected clause | Observed |
|---|---|
| guard prints `[denied]` on all three routes | `[denied] EnterWorktree` · `[denied] ExitWorktree` · `[denied] Bash(git worktree:*)` |
| prints "All worktree routes are denied." | printed |
| exits 0 | `EXIT=0` |
| bridge-suite leg goes green | `tests/run-bridge-tests.sh` leg passes |

**A second, independent signal I did not have to ask for:** the `EnterWorktree` and
`ExitWorktree` tools stopped being available to this session at the moment you applied the
rules. That is the deny list acting on the harness, not a file being read back — a different
kind of evidence from the guard, and it agrees with it.

`fw enforcement baseline` also took: `fw doctor` reports "Enforcement baseline intact", so the
settings change did not leave a silent FAIL accumulating (L-398).

**Why I have not ticked it myself:** it is a `### Human` AC, and only you may check those. The
action it certifies — writing `.claude/settings.json` — is gated by B-005 precisely because
that file controls the task gates, Tier-0 checks and budget enforcement. That gate fired when I
tried, which is the gate working. I am reporting evidence, not asserting completion.

**If you disagree:** run `python3 tools/_t586-worktree-denial-guard.py` yourself; it names any
route still open and reprints the one-line command.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-25T12:11:15Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-586-kill-worktree-isolation-and-pin-no-backg.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f18cf755
- **Timestamp:** 2026-08-27T19:30:23Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#6 (Agent)** — `fw enforcement baseline` refreshed, since `.claude/settings.json` changed (L-398),
  - **AC-verify-mismatch** (narrow, heuristic) — `path=claude/settings.json in: `fw enforcement baseline` refreshed, since `.claude/settings.json` changed (L-398),`

### 2026-08-27T19:30:22Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
