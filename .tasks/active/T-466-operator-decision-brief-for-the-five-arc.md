---
id: T-466
name: "The arc view cannot see what blocks the arc"
description: >
  Opened to write a decision brief for the five rulings gating arc-001; found that four of
  the five are already briefed, well, in docs/reports/T-397-import-repair-semantics-brief.md
  (dependency map, consistency constraints, per-ruling options, copy-pasteable recording
  commands, provenance table) — last updated 2026-08-10. A second brief would be duplicated
  work, so this task is re-scoped to the two things that are actually missing.
  FIRST: the blockage is invisible from the arc. `fw arc show designer-authoring-surface`
  lists T-423 as `[captured/now]` — indistinguishable from ready — when T-423's own first
  Agent AC reads "this task does not start until T-340 is ruled and step 1 has landed".
  T-340 is step 1 of the same three-step T-357 decomposition whose steps 2 and 3 (T-423,
  T-424) ARE arc-tagged; step 1 is not, so the one task the arc is waiting on is the one
  task the arc view does not show. Same shape as PL-145 one level up: a blocking relation
  recorded only in AC prose is invisible to every instrument that looks at the arc.
  SECOND, and this overtook the first: re-deriving the blocking set instead of restating it
  showed the set is WRONG. The arc is blocked on T-340 ALONE. T-341, T-347, T-358 and T-209
  appear nowhere in either arc task — not as blockers, not in related_tasks, not in prose. The
  "five" came from handover `tasks_touched`, a co-occurrence list of what one window opened,
  restated in the next window's summary as a causal claim and inherited unchecked for three.
  Deliverable is the correction with its evidence plus the arc_id fix; NOT a re-brief.

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
created: 2026-08-12T19:37:23Z
last_update: 2026-08-12T19:37:23Z
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

# T-466: The arc view cannot see what blocks the arc

## Context

Deliverable: `docs/reports/T-466-arc-blockage.md`. Opened to write a decision brief for the
five rulings I had been reporting as arc blockers; found T-397's brief already covers four of
them well, and then found that the blocking set itself was wrong — the arc waits on **T-340
alone**. See the report for the derivation, the near-miss that nearly produced a wrong partial
retraction, and the RCA for how a co-occurrence list became a causal claim.

**Two Human-AC example lines inside this file's `### Human` template comment were ticked by a
blanket tick and could not be reverted:** `check-human-ac-tick` (T-1731) is symmetric and
refuses `[x]` → `[ ]` as well, so restoring the invariant the guard exists to protect requires
the same `FW_ALLOW_HUMAN_AC_TICK=1` override as violating it. Not bypassed — left as-is and
reported. They are example text inside an HTML comment, not acceptance criteria: P-010 gates on
`### Agent`, and `fw task verify` reads none of them. Recorded as an observation.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] No duplicate brief is produced. `docs/reports/T-397-import-repair-semantics-brief.md`
      remains the single consolidated view for Q1a/Q1b/Q2a/Q2b, unedited by this task.
      Checked as a real criterion because the first version of this task was scoped to write
      exactly that duplicate, and the only thing that stopped it was opening the file.
- [x] T-340 carries `arc_id: designer-authoring-surface` and appears in
      `fw arc show designer-authoring-surface`. Steps 2 and 3 of the T-357 decomposition are
      already arc-tagged; step 1 was not, so the task the arc is waiting on was the one task
      the arc view omitted.
- [x] The denominator is stated and derived, not asserted (PL-084): how many active tasks
      carry the arc_id, how many of those are blocked, and by which AC text. Recorded in the
      task's Decisions or the T-209 note, with the deriving command shown.
- [x] `docs/reports/T-466-arc-blockage.md` records the correction with its evidence: the arc
      is blocked on ONE ruling (T-340), not the five I reported to the operator across three
      windows. Anchored-match evidence shown, including the false positive that the first
      unanchored attempt produced (`T-209` matching inside `T-2090`) — because that near-miss
      is the reason to distrust the original claim, and burying it would leave the reader no
      way to judge how the wrong number survived three windows.
- [x] Every operator command in that document is single-line, `cd`-prefixed, uses
      `.agentic-framework/bin/fw`, and contains no placeholder token (T-609/T-325).
- [x] Per PL-145 — which comes from T-209, one of the four now shown NOT to block the arc —
      the document names WHERE the T-340 ruling must be recorded so instruments can see it.
- [x] OUT OF SCOPE, stated rather than silently dropped: T-209 is the one ruling of the five
      with no brief, and this task does not write one. It was in scope while the "five
      blockers" framing held; once T-209 is shown not to block the arc, folding its brief in
      here would be the umbrella-task antipattern (one task = one deliverable). Recorded as a
      follow-up candidate in the document instead.
- [x] No `### Human` AC on any of the five tasks is ticked, no ruling is recorded, and no
      task ownership is changed by this task. Verified mechanically, not asserted.

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
       - [x] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [x] [REVIEWER] Block message names both bypass mechanisms
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
#
# Every grep below is spelled /usr/bin/grep on purpose (G-037): the gate runs GNU grep,
# the agent's tool shell routes to ugrep, and a leg that silently swaps pattern engines
# between where it was written and where it runs is the confusion this project has a
# register entry for. -F wherever the needle carries regex metacharacters.

# 1. The deliverable exists and states the correction, not a hedge.
test -f docs/reports/T-466-arc-blockage.md && /usr/bin/grep -qF 'blocked on one ruling, not five' docs/reports/T-466-arc-blockage.md

# 2. The load-bearing claim reproduces RIGHT NOW, anchored. If T-341/T-347/T-358/T-209 ever
#    do become arc blockers, this leg goes red and the document stops being true quietly.
test "$(/usr/bin/grep -ohE 'T-(341|347|358|209)([^0-9]|$)' .tasks/active/T-423-*.md .tasks/active/T-424-*.md | wc -l)" = "0"

# 3. ...and T-340 IS referenced by T-423, so leg 2 passing means "absent", not "grep broken".
#    Without this, a typo'd path would give leg 2 a free green (PL-084: prove the probe can see).
test "$(/usr/bin/grep -ohE 'T-340([^0-9]|$)' .tasks/active/T-423-*.md | wc -l)" -ge 1

# 4. T-340 carries the arc_id and the arc view actually renders it.
/usr/bin/grep -q '^arc_id: designer-authoring-surface' .tasks/active/T-340-*.md && .agentic-framework/bin/fw arc show designer-authoring-surface > /tmp/.t466-arc.txt 2>&1 && /usr/bin/grep -q 'T-340' /tmp/.t466-arc.txt

# 5. The denominator claimed in the document is the denominator on disk.
test "$(/usr/bin/grep -l '^arc_id: designer-authoring-surface' .tasks/active/*.md | wc -l)" = "3"

# 6. The T-397 brief was NOT edited by this task — the whole point was to not duplicate it.
git diff --quiet HEAD -- docs/reports/T-397-import-repair-semantics-brief.md

# 7. No placeholder token survived into an operator-facing document (T-609/T-325).
! /usr/bin/grep -qE 'T-XXX|<why>|\[First criterion\]|\[Second criterion\]' docs/reports/T-466-arc-blockage.md

# 8. Every fw command in the document is single-line and cd-prefixed (T-609).
test "$(/usr/bin/grep -c 'agentic-framework/bin/fw' docs/reports/T-466-arc-blockage.md)" = "$(/usr/bin/grep -c 'cd /opt/832-Workflow-designer && .agentic-framework/bin/fw' docs/reports/T-466-arc-blockage.md)"

# 9. SOVEREIGNTY: not one Human AC on any of the five rulings was ticked by this task.
test "$(/usr/bin/grep -h '^\s*- \[x\].*\[REVIEW\]' .tasks/active/T-340-*.md .tasks/active/T-341-*.md .tasks/active/T-347-*.md .tasks/active/T-358-*.md .tasks/active/T-209-*.md | wc -l)" = "0"

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

**Symptom:** For three consecutive windows I reported to the operator that arc-001 was gated on
five operator rulings (T-340, T-341, T-347, T-358, T-209), and twice offered to prepare a brief
for all five. The arc waits on **T-340 alone**; the other four appear nowhere in either arc task.

**Root cause:** A set assembled by *adjacency in a work log* was restated as a set defined by
*causation in the task graph*. All five are open `[REVIEW]` rulings, so a window spent triaging
open rulings touches all five and they land adjacent in handover `tasks_touched:` — a field whose
only semantics are "seen this window". The next window's summary rendered that adjacency as
"blocks the arc", and every window after that inherited the summary rather than the task files.

**Why structurally allowed:** three compounding gaps, none of which can see the claim.
(1) **Nothing derives arc blockage.** `fw arc show` prints constituent tasks with status and
horizon; the blocking relation lives in AC prose (`"does not start until T-340 is ruled"`), which
no instrument parses. There is no `blocked_by` field, so there is nothing for a gate to check the
claim against. (2) **The blocker was not even in the arc.** T-340 is step 1 of the same T-357
decomposition whose steps 2 and 3 are arc-tagged; step 1 was not, so the one task the arc waited
on was the one task the arc view omitted — the register could not have contradicted me. (3) **A
summary is a claim with its derivation stripped off.** Re-deriving costs two greps; restating
costs nothing. Across a compaction boundary the summary is what survives, so the cheap operation
wins by default and there is no point at which the expensive one is prompted.

**Prevention — honest split between what is done and what is not.**
*Done:* T-340 now carries `arc_id`, so the arc view shows the ordering; and this task's
verification leg 2 asserts the corrected claim mechanically — if T-341/T-347/T-358/T-209 ever do
become arc blockers, the leg goes red instead of the document going quietly stale. Leg 3 exists
so leg 2 cannot pass by a broken probe (PL-084).
*Not done, and it is the real prevention:* nothing derives "what blocks this arc" from the task
graph, so the next prose-only dependency will be just as invisible. Tagging is **mitigation**
(this instance is visible), not **prevention** (the class cannot recur) — the G-019 distinction,
stated rather than blurred. A `blocked_by:` field that `fw arc show` renders would be prevention;
that is a framework change in vendored code and is not this task.

**Second-order finding:** the near-miss is the load-bearing evidence. The first correction attempt
used an unanchored pattern and reported T-209 present in both arc tasks — matching `T-209` inside
`T-2090`. It would have produced a *partial retraction that was itself wrong*, which is worse than
the original error because it would have carried the authority of having been re-checked.

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

### 2026-08-12T19:37:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-466-operator-decision-brief-for-the-five-arc.md
- **Context:** Initial task creation
