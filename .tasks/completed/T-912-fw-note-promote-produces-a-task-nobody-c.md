---
id: T-912
name: "fw note promote produces a task nobody can close and a record that points at
  nothing"
description: >
  Two defects in one 8-line function, both of which multiply by the size of any inbox
  drain. do_promote (.agentic-framework/agents/observe/observe.sh:339-346) hardcodes
  --owner human with no override, and its post-promote sed writes the LITERAL string
  'task' into promoted_to rather than the created task id. Blocks draining the 182-item
  inbox: promoting the 71 urgent items would manufacture 71 human-owned tasks that
  an agent cannot close, each carrying zero Human ACs, plus 71 records that cannot
  say which task they became.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: [T-910, T-885]
arc_id: hypothesis-first-inceptions
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-28T11:28:19Z
last_update: 2026-09-28T11:34:11Z
date_finished: 2026-09-28T11:34:11Z
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
bvp_scores_proposed:
  - ts: '2026-09-28T11:28:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-912: fw note promote produces a task nobody can close and a record that points at nothing

## Context

**This is the prerequisite for draining the observation inbox.** 182 pending, 71 urgent (39%), with
33 of the urgent ones aged 31–90 days. Both defects below are in the same 8-line function and both
multiply by the size of any drain.

### Defect 1 — every promotion creates a task an agent cannot close

`observe.sh:343` passes `--owner human`, hardcoded, with no flag to override it. Promoting the 71
urgent observations would manufacture **71 human-owned tasks**, and the evidence says almost none of
them would carry a Human acceptance criterion to justify that ownership:

- **T-910** — promoted from OBS-416. Closed 2026-09-28 with **0/0 Human ACs**, 6/6 Agent ACs and
  verification 10/10. It took the operator three attempts and a `--skip-sovereignty` bypass, because
  `check_human_sovereignty()` (`update-task.sh:104`) fires on the OWNER FIELD, not on any unchecked
  human criterion. Operator ruling, verbatim: *"This is a Zero Human ACs review task. You should not
  even ask me."*
- **T-885** — same shape, still open: Agent ACs ticked, zero open criteria, `owner: human`.

So the default manufactures review work with nothing to review, and does it once per promotion.

### Defect 2 — the record cannot say which task it became

The post-promote edit is:

```
_sed_i "/id: $obs_id/,/promoted_to:/{s/status: pending/status: promoted/;s/promoted_to: null/promoted_to: task/}"
```

It writes the **literal string `task`**. Measured across all six promoted observations in
`.context/inbox.yaml`: `promoted_to` is `'task'` in 6 of 6 — never an id, not once. And
`context_task` is a decoy: it records the task in FOCUS when the observation was CAPTURED, not the
one it became. OBS-416 became **T-910**; its record says **T-890**.

There is therefore no link from an observation to the task it turned into. The field exists and is
filled with a constant.

This is **OBS-257** — *"THE OBSERVATION INBOX HAS NO CROSS-REFERENCING, AND IT PRODUCED A FALSE
RECORD TODAY"* — at 43 days old, in its most concrete form. It reproduced again on 2026-09-28:
OBS-422 corrects a false claim in OBS-421 and nothing links them, so a reader of OBS-421 gets the
wrong answer with no signal that a correction exists.

### Why these are one task and not two

They are not independent deliverables. Neither is useful without the drain, both live in the same
function, and shipping one without the other still leaves the drain blocked. One deliverable:
**`fw note promote` produces a task an agent can close, and a record that points at it.**

**Vendored-tree note:** `.agentic-framework/` is vendored. G-008 permits fixing it in-tree for
upstreaming; the change must be upstreamable, not project-local.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
### Agent
- [x] `fw note promote` accepts `--owner <owner>` and **defaults to `agent`**. The default is the change that matters: a flag nobody passes fixes nothing, and the 182 pending observations will be promoted by whoever drains them, not by someone remembering a flag
- [x] `--owner human` remains available and is still honoured — the point is that human ownership becomes a **choice with a reason**, not the silent default
- [x] `promoted_to` records the **actual created task id** (`T-NNN`), read back from what `create-task.sh` produced rather than assumed. If the id cannot be determined, promote **fails loudly** rather than writing a placeholder — writing `task` again would be the same defect with better intentions
- [x] The **reverse link exists too**: the created task names the observation it came from in a field a query can read, not only in prose. `description:` already says "Promoted from observation OBS-NNN"; that is text, and text is not an index
- [x] **Proved by a real promotion**, not by reading the diff: promote a disposable observation, assert the task is `owner: agent`, assert `promoted_to` equals that task's id, assert the reverse link resolves. Then clean up the fixture
- [x] **Control set first**, and it reports `SETUP BROKEN` rather than scoring: a promotion that did not create a task must be distinguishable from one that created a task with the wrong owner. The two look identical in a naive grep of the inbox
- [x] The six **already-promoted** observations are either backfilled with their real task ids or left alone with a recorded reason. OBS-416→T-910 and OBS-402→T-875 are known; the older four need looking up or honestly marking unknown. **`unknown` is not `ok`** (T-675)

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

# The flag exists and DEFAULTS to agent — the default is the change, not the flag.
.agentic-framework/bin/fw note promote --help > /tmp/.t912h.out 2>&1 && grep -q -- "--owner defaults to 'agent'" /tmp/.t912h.out
grep -q 'local task_owner="agent"' .agentic-framework/agents/observe/observe.sh
# --owner human is still reachable (proved live by the OBS-424 control fixture; this holds the wiring).
grep -qE '^\s+--owner\|-o\) task_owner=' .agentic-framework/agents/observe/observe.sh
# INVARIANT, not a count (T-3326): every non-null promoted_to resolves to a real task file.
python3 -c "import yaml,glob,sys; o=yaml.safe_load(open('.context/inbox.yaml'))['observations']; bad=[(x['id'],x['promoted_to']) for x in o if x.get('promoted_to') and not glob.glob('.tasks/*/%s-*.md'%x['promoted_to'])]; sys.exit(0 if not bad else (sys.stderr.write('dangling: %r\n'%bad) or 1))"
# No record carries the literal string 'task' where a task id belongs.
python3 -c "import yaml,sys; o=yaml.safe_load(open('.context/inbox.yaml'))['observations']; sys.exit(1 if [x for x in o if x.get('promoted_to')=='task'] else 0)"
# CONTROL for the two legs above (PL-328): they assert an absence, so prove the population is non-empty.
python3 -c "import yaml,sys; o=yaml.safe_load(open('.context/inbox.yaml'))['observations']; n=len([x for x in o if x.get('promoted_to')]); sys.exit(0 if n>=7 else (sys.stderr.write('only %d linked records — absence legs would be vacuous\n'%n) or 1))"
# The real promotion done through the fixed path: forward link, reverse link, owner.
python3 -c "import yaml,glob,sys; o=[x for x in yaml.safe_load(open('.context/inbox.yaml'))['observations'] if x['id']=='OBS-423'][0]; f=glob.glob('.tasks/*/T-913-*.md')[0]; t=yaml.safe_load(open(f,encoding='utf-8').read().split('---')[1]); assert o['promoted_to']=='T-913'; assert t['observation']=='OBS-423'; assert t['owner']=='agent'"
# promote refuses an observation that does not exist, and says so.
.agentic-framework/bin/fw note promote OBS-99999 > /tmp/.t912n.out 2>&1; grep -q 'not found' /tmp/.t912n.out
# The script still parses.
bash -n .agentic-framework/agents/observe/observe.sh

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
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

### 2026-09-28 — the main test used a real observation, not a disposable one
- **What changed:** AC5 said "promote a disposable observation … then clean up the fixture". I used
  a REAL one instead — **OBS-423** (the Tier-2 bypass logs no reason), which is a legitimate build
  task and became **T-913**. Creating a task purely to delete it is worse than testing on work that
  needed doing anyway, and it drains an actual inbox item rather than simulating one.
- **Plan impact:** a disposable fixture was still needed for ONE leg — proving `--owner human` is
  still honoured — because the only honest way to check it is to create a human-owned task, and
  that is exactly what this change exists to stop doing by accident.
- **Triggered:** nothing; the AC's intent (prove it with a real promotion) is met more strongly.

### 2026-09-28 — cleaning up the fixture produced a finding, because I did it in the wrong order
- **What changed:** I deleted the fixture task T-914 **before** disposing of its observation. The
  inbox was then holding `promoted_to: T-914` against a task that no longer existed, and
  `fw note dismiss` correctly refused — *"OBS-424 is not pending (status: promoted)"* — so the
  record had **no legal exit** and only a hand edit could resolve it.
- **Plan impact:** none to the deliverable, but it exposed that nothing detects a `promoted_to`
  which does not resolve. That matters precisely because this task **creates** those links: a link
  that can silently dangle is a weaker record than no link, because a reader trusts it.
- **Triggered:** **OBS-425** — wants an audit leg resolving every non-null `promoted_to` against
  `.tasks/`, plus a disposition path for an observation whose task is gone. The invariant leg is
  already in this task's `## Verification`; the audit rail is OBS-425's.

### 2026-09-28 — all six legacy promotions resolved; none had to be marked unknown
- **What changed:** AC7 allowed marking the older four `unknown` if they could not be traced
  (*"`unknown` is not `ok`"*, T-675). None needed it. Each task carries an explicit
  **"Promoted from OBS-NNN (T-436 triage)"** line, so the mapping is an origin statement rather
  than a coincidental mention: OBS-020→T-439, OBS-023→T-440, OBS-029→T-441, OBS-030→T-442,
  OBS-402→T-885, OBS-416→T-910.
- **Plan impact:** `context_task` is confirmed as a decoy rather than a weak substitute — it holds
  the task in focus AT CAPTURE TIME. For all six it disagrees with the truth: OBS-416's says T-890
  where the answer is T-910, OBS-402's says T-875 where the answer is T-885. Anyone who had used it
  as the backlink would have been wrong six times out of six.
- **Triggered:** nothing filed; recorded here because the next person to look for a backlink will
  find `context_task` first and it is the wrong field.

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-28T11:28:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-912-fw-note-promote-produces-a-task-nobody-c.md
- **Context:** Initial task creation

### 2026-09-28T11:28:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-733bd075
- **Timestamp:** 2026-09-28T11:34:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-28T11:34:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
