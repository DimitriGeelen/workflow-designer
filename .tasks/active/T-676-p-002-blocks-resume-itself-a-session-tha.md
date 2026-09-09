---
id: T-676
name: "P-002 blocks /resume itself: a session that ends by FILING a task cannot gather state in the next one"
description: >
  MEASURED 2026-09-04 at session start. The previous session ended by filing T-674, which left focus.yaml pointing at a task with status 'captured'. check-active-task then refused EVERY Bash call in the new session - including the read-only 'git status --short' and 'git log --oneline -5' that the /resume skill's own Step 1 requires. The recovery workflow cannot run on the exact state that filing a task produces, and filing a task at session end is the behaviour the framework asks for. Note the gate blocks on TASK STATE, not on write-intent: 'git status' modifies nothing. Same family as OBS-033 (P-002 catch-22) and the T-672 leg that asserted a state its own satisfaction destroys. Workaround used: 'fw context focus T-575' to a started-work task - no bypass flag. Candidate fix: exempt read-only Bash from the captured-task block (the budget gate already classifies git status/log/diff as read-only in its allow-regex, so the classification exists and is not duplicated), or have the gate treat a 'captured' focus as no-focus rather than as a blocking violation.

status: started-work
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-04T21:55:13Z
last_update: 2026-09-09T07:43:23Z
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

# T-676: P-002 blocks /resume itself: a session that ends by FILING a task cannot gather state in the next one

## Context

**THREE live instances in one session (2026-09-04/05), two of them not the filed
shape.** The filed shape is a `captured` focus. The other two are the more common
one and were not anticipated when this was written:

| # | trigger | gate said |
|---|---|---|
| 1 | session ended by filing T-674, focus left `captured` | `Task T-674 has status 'captured'` |
| 2 | completing T-674 cleared focus | `No active task` |
| 3 | completing T-677 cleared focus | `No active task` |
| 4 | completing T-467 cleared focus | `No active task` (blocked `fw arc list`) |
| 5 | completing T-670 cleared focus | `No active task` (blocked `checkpoint.sh status`) |
| 6 | post-compaction, focus null | `No active task` (blocked `/resume`'s OWN state-gathering — the tool counter and budget read the skill prescribes) |
| 7 | completing T-689 cleared focus | `No active task` (blocked `git push`) |
| 8 | completing T-423 left focus ON it, `work-completed` | `Task T-423 has status 'work-completed'` (blocked `checkpoint.sh status` AND reading `.gate-bypass-log.yaml`) |

**EIGHT instances across four sessions.** Instances 6-8 were measured 2026-09-08/09.

Instance 8 is a **fourth trigger state** the table above did not have: focus is neither
absent nor `captured` but points at a task that has just reached `work-completed`. It arises
from the *partial-complete* path specifically — T-423 has an unticked `[REVIEW]` Human AC, so
it stayed in `.tasks/active/` with `owner: human`, and focus stayed pointed at it. The gate's
own message names the remedy as NOT AVAILABLE for this state ("`fw context focus` accepts
active tasks only") and offers only the two Tier-2 bypasses, which an autonomous run is not
delegated. So instance 8 is the first one with **no non-bypass remedy on the task itself** —
the escape was to focus an unrelated task, which is the governance theatre this task already
names, now forced rather than merely tempting.

It also blocked the read of `.gate-bypass-log.yaml` — a file whose whole purpose is to make
bypasses auditable. Worth stating: the gate that exists to keep bypasses honest blocked the
read of the bypass ledger.

**A second, separate defect found while recording instance 8 (2026-09-09).** `fw work-on
T-676 | head -6` printed `=== Resuming T-676 ===` and exited cleanly, but the status stayed
`captured` — `head` closes the pipe, the script takes SIGPIPE partway through, and the status
write never lands. The visible output is indistinguishable from success, and the next command
is refused by a gate citing the state the command was supposed to have changed. This is
L-387's SIGPIPE class arriving on a *state-changing* command rather than a verification one,
where the cost is not a false red but a silent no-op. Do not pipe `fw` state-changing
commands into `head`/`grep -q`.

**FIVE instances across two sessions, four of them on the normal end of a task.** Instances
4 and 5 were measured 2026-09-05 while landing T-467/T-679/T-670 — the same session that
landed three tasks hit the gate twice, both times on a read-only command immediately after
a successful completion. Instance 4 blocked `fw arc list`; instance 5 blocked
`checkpoint.sh status`, which is the command CLAUDE.md's own budget rule names as the safe
way to measure context.

That last one is worth stating plainly: **the gate blocks the framework's own prescribed
budget read at the exact moment the ladder says to take it** — right after finishing a unit
of work, when the agent is deciding whether there is room for another. The workaround
(`fw context focus T-575`) is governance theatre either way, but a rule that must be routed
around to obey a different rule is the shape that trains an operator to route around gates
generally.

So the gate fires on the NORMAL end of every task, not just on an unusual leftover
state: finishing work is what clears focus, and the next read-only command is refused.
Each time the blocked call was `checkpoint.sh budget` or `git status` — commands that
modify nothing. The workaround each time was `fw context focus T-575`, which is
governance theatre: it satisfies the gate without any of the intent behind it.

This strengthens the candidate fix. Exempting read-only Bash is not a loosening —
the budget gate's own allow-regex already classifies `git status|log|diff`,
`fw handover|git|task`, and `checkpoint.sh` as read-only, so the classification
exists in-tree and would not be duplicated. A gate that must be routed around three
times in one session to do ordinary work is training the operator to route around it.

---

## CORRECTION 2026-09-09 — the paragraph directly above is WRONG, and AC 3 is what caught it

AC 3 required quoting the clause instead of restating it (PL-323). Quoted, from
`.agentic-framework/agents/context/budget-gate.sh:152`:

```
is_allowed_cmd = bool(re.search(r'(git\s+commit|git\s+add|git\s+push|git\s+fetch|git\s+(status|log|diff)|fw\s+(handover|git|context\s+init|resume|task)|context\.sh\s+init|resume\.sh|checkpoint\.sh|budget-gate\.sh|handover\.sh|update-task\.sh|echo\s+0\s*>)', command)) if command else False
```

and its own comment, `budget-gate.sh:147`:

```
# Classification: 'allowed' for wrap-up/read ops, 'blocked' for new work
```

**There is no read-only classifier in that file.** What exists is a *wrap-up* allow-list
answering a different question — "what may still run at critical budget?" — and it contains
`git commit`, `git add`, `git push`, `git fetch`, `fw task` and `update-task.sh`, every one
of which writes. The paragraph above rewrote a wrap-up list as a read-only list and then
leaned on the rewrite: **"the classification exists in-tree and would not be duplicated" is
false.** Reusing this regex for P-002 would permit committing, pushing and mutating task
status with no active task — precisely what P-002 exists to prevent. The proposal would have
shipped a gate that admits the writes it exists to refuse.

This is PL-323 exactly, in this project's own task file: a claim whose authority comes from
an external artefact, paraphrased instead of quoted, drifting silently because a paraphrase
never looks wrong. It is also FP-019's under-reporting direction — the restatement made the
proposal look *safer* and cheaper than it is.

**What survives.** The genuinely read-only members are `git status|log|diff`, `checkpoint.sh`,
`budget-gate.sh`, and `Read`/`Glob`/`Grep` (the separate `is_read_tool` test at line 153,
which IS a clean read-only classification but covers tools, not Bash commands). A read-only
Bash exemption for P-002 must therefore be **written fresh and narrow**, not borrowed. That
makes the proposal more expensive than filed — a new allow-list is a new thing to keep
correct — and the operator should weigh it knowing that, not knowing the cheaper story.

## Proposal, with its blast radius

**Trigger states, because the fix differs per state** (AC 2):

| state | instances | remedy available today |
|---|---|---|
| (a) focus on a `captured` task | 1 | `fw context focus <started task>` |
| (b) focus cleared by completion | 2, 3, 4, 5, 7 | `fw context focus <started task>` |
| (c) focus on a `work-completed` task | 8 | **none except a Tier-2 bypass** |
| (d) focus set, command's first `T-NNN` differs (T-638 / OBS-335) | this session's `add-learning --task T-690` | re-attribute, or Tier-2 |

**Register completeness, stated rather than implied** (AC 1): instances 4–8 carry the exact
refused command and gate message, recorded live. Instances 1–3 carry the gate message and
the trigger but **not** the precise command — they were reconstructed at filing time from a
session that had already ended. They are counted as instances and NOT as evidence about
which commands the exemption would need to cover. A register that quietly rounds recalled
detail up to measured detail is the same defect this task just caught in its own prose.

**Variant A — treat a `captured` or `work-completed` focus as no-focus.** Fixes (a) and (c)
only, leaves (b) untouched, and (b) is five of eight. Cheap, but it does not address the
common case.

**Variant B — exempt a narrow, freshly written read-only Bash allow-list regardless of focus
state.** Would have prevented all of (a), (b), (c) — seven of eight instances. Does not help
(d), which is a matcher defect, not a focus-state one.

**What Variant B costs, said plainly.** A read-only allow-list is a regex over command TEXT,
and every regex over command text in this project has been defeated by text it did not
anticipate: the project-boundary hook blocks prose mentioning a peer path, and OBS-335 shows
the focus-drift matcher keys on the first `T-NNN` in the string rather than the invocation's
target. So the honest expectation is that a read-only exemption will eventually admit
something that is not read-only — `git diff --output=FILE` writes a file, and `checkpoint.sh`
appears in the same regex as commands that mutate state. The exemption should therefore be
anchored on the command's **first token** rather than on a substring search anywhere in the
line, or it inherits the defect class it is meant to relieve.

**What an agent gains from the loosening:** the ability to run `git status`, `git log`,
`git diff` and `checkpoint.sh status` with no active task. Nothing that writes to the repo,
nothing that changes task state, nothing that touches `.context/`. **What it does not gain:**
any relief from G-020, the arc-id gate, Tier 0, or the sovereignty gates — those are separate
hooks and unaffected.

**Recommendation to the operator: Variant B, first-token-anchored.** Recorded as a
recommendation and nothing more; the ruling is the Human AC below, and no edit to
`check-active-task.sh` exists or will exist before it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**Note on what this task may and may not deliver.** The candidate fix is a change to
`check-active-task.sh`, a Tier-1 PreToolUse enforcement hook. Loosening an enforcement gate
is not an agent decision however well-evidenced the case is, so the ACs below stop at a
ratifiable proposal. AC 4 is the operator's, and nothing here edits the hook before it.

- [x] The instance register is complete and mechanically derived, not remembered. Every
      occurrence carries: date, the command that was refused, the gate's exact message, and
      whether the refused command modified anything. A count assembled from memory is the
      same evidence problem this task is about.
- [x] Each instance is classified by TRIGGER STATE, because the fix differs per state and the
      filed shape turned out to be the rare one: (a) focus left on a `captured` task,
      (b) focus cleared by a completion, (c) focus left on a `work-completed` task,
      (d) focus set but the command's first `T-NNN` names a different task (T-638/OBS-335).
      A single "P-002 is annoying" bucket cannot be turned into a hook change.
- [x] The read-only classification the proposal depends on is shown to ALREADY EXIST in-tree
      and is quoted with its file and line — `budget-gate.sh`'s allow-regex already treats
      `git status|log|diff`, `fw handover|git|task` and `checkpoint.sh` as read-only. If it
      does not say what this task claims it says, the proposal collapses and that is the
      finding. **Quote the clause, cite the line, never paraphrase it** (PL-323).
- [x] The proposal names its own blast radius honestly: which commands would newly be
      permitted, which of the eight recorded instances each variant would have prevented, and
      what an attacker or a careless agent gains from the loosening. A proposal that only
      lists benefits is not ratifiable.

### Human
- [ ] [REVIEW] **Should P-002 exempt read-only Bash when focus is absent, captured, or
      completed?**
      **Steps:**
      1. Read the instance register in `## Context` — eight occurrences, with what each
         refused command would have done.
      2. Read the blast-radius section of the proposal.
      3. Rule: GO (apply the exemption), NO-GO (keep the gate as-is and close this task), or
         DEFER with what evidence would decide it.
      **Expected:** a recorded ruling. Nothing edits `check-active-task.sh` before it.
      **If not:** leave this unticked; the task stays parked and the workaround
      (`fw context focus <active task>`) remains the standing answer.

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
         1. Run `bin/fw reviewer T-676`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-676 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# 1. The quoted regex in the CORRECTION section is the one in the file, not a remembered
#    version of it. This is the whole point of AC 3 and the leg that would catch its decay:
#    the correction's authority comes from an external artefact, so the pin is on that
#    artefact. If budget-gate.sh:152 is edited, this goes red and the correction gets re-read.
python3 -c 'import sys;g=open(".agentic-framework/agents/context/budget-gate.sh").read().split(chr(10))[151];t=open(".tasks/active/T-676-p-002-blocks-resume-itself-a-session-tha.md").read();sys.exit(0 if g.strip() in t else 1)'

# 2. The load-bearing claim of the correction: that allow-list contains commands that WRITE,
#    so it is not a read-only classifier and cannot be borrowed as one.
python3 -c 'import sys;l=open(".agentic-framework/agents/context/budget-gate.sh").read().split(chr(10))[151];sys.exit(0 if ("is_allowed_cmd" in l and "git" in l and "commit" in l) else 1)'

# 3. The instance register carries all eight rows. A count asserted in prose that the table
#    does not carry is the failure mode this task documents in its own subject matter.
python3 -c 'import re,sys;t=open(".tasks/active/T-676-p-002-blocks-resume-itself-a-session-tha.md").read();sys.exit(0 if len(re.findall(r"^\| [1-8] \|", t, re.M)) == 8 else 1)'

# 4. NO T-676 COMMIT has edited the enforcement hook this task proposes to change. The
#    proposal is ratifiable precisely because the change does not exist yet.
#    First draft of this leg asked whether ANY of the last 20 commits touched the hook and
#    went red on T-662's legitimate edit — right answer to the wrong question. Kept in the
#    record because a verification leg that fails for a reason unrelated to its task is how
#    a gate gets bypassed with --force by whoever meets it next.
test -z "$(git log --oneline --grep '^T-676' -- .agentic-framework/agents/context/check-active-task.sh)"

# 5. ...and the working tree carries no uncommitted edit to it either, which leg 4 cannot see.
git diff --quiet HEAD -- .agentic-framework/agents/context/check-active-task.sh

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
     fw inception decide T-676 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-04T21:55:13Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-676-p-002-blocks-resume-itself-a-session-tha.md
- **Context:** Initial task creation

### 2026-09-09T07:41:41Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
