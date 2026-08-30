---
id: T-642
name: "Review queue shows 8 agent recommendations as unreadable because the verdict vocabulary is narrower than the positions agents hold"
description: >
  Review queue shows 8 agent recommendations as unreadable because the verdict vocabulary is narrower than the positions agents hold

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
created: 2026-08-30T10:56:07Z
last_update: 2026-08-30T11:00:27Z
date_finished: 2026-08-30T11:00:27Z
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

# T-642: Review queue shows 8 agent recommendations as unreadable because the verdict vocabulary is narrower than the positions agents hold

## Context

`fw review-queue` shows 8 of 53 tasks as `?` — "verdict missing or unparseable". Read from
the operator's side, `?` is indistinguishable from "the agent has not done its part". In
every one of the 8 the agent had in fact written a considered position; the queue simply
could not read it.

Ground-truthed by calling the extractor rather than by reading the display (the accepted
vocabulary is `KEEP-OPEN|NO[-_]GO|CLOSE|GO|DEFER`, `shared.py:791`), which split the 8 into
two unrelated defects:

**(a) Six tasks whose verdict word is outside the vocabulary — this task.**

| task | written as | expressible? |
|---|---|---|
| T-537, T-540 | "Ready for your ruling" | yes → `GO` |
| T-586 | "Ready for your tick" | yes → `GO` |
| T-588 | "A — selective merge, under a scoped …" | yes, once the option letter is named |
| T-341, T-358 | `ABSTAIN` | **no** — see below |

**(b) Two tasks the library parses correctly and the queue still shows as `?`** — T-579
(`CLOSE`) and T-609 (`KEEP-OPEN`). `extract_recommendation_state()` returns the verdict;
the CLI renders `?`. Two readers of one field and the public one is the unverified one —
PL-197 exactly, which `fw work-on` surfaced on the task immediately before this one. **Not
this task.** Filed separately; fixing it here would bundle a framework bug into a content
correction.

**`ABSTAIN` is the finding, not an oversight.** Both uses are deliberate: the agent declines
to choose among options that are the operator's to choose (T-358: "the choice among
A · B · C · AB · no-repair is yours"). That is a real position and arguably the most
honest one available, and the surface has no way to show it — so a considered abstention
displays identically to silence. Mapping it onto `DEFER` would be a lie in the operator's
own decision surface: `DEFER` says "decide later", `ABSTAIN` says "decide now, without me".
This task does not remap them.

## Acceptance Criteria

### Agent
- [x] The four expressible verdicts (T-537, T-540, T-586, T-588) carry a canonical token
      the extractor reads, verified by calling `extract_recommendation_state` — not by
      reading the rendered queue, which is the surface defect (b) proves untrustworthy
- [x] Substance is preserved, not rewritten: the original wording survives as the clause
      after the token, and no rationale or evidence line is altered. A diff shows only the
      verdict token added
- [x] T-341 and T-358 are left as `ABSTAIN` and are NOT remapped, with the reason recorded
      in each task rather than only here
- [x] The `ABSTAIN` vocabulary gap is registered as an observation, so the surface's
      inability to represent a principled abstention is visible after this task archives
- [x] Defect (b) — library parses, CLI shows `?` — is filed as its own task, not fixed here
- [x] `fw review-queue`'s `?` count drops by exactly 4, and the survivors are accounted for
      by name rather than by number: T-341 + T-358 (ABSTAIN, deliberately not remapped) and
      T-579 + T-609 (defect (b), a different bug). Counted before and after.
      **The first draft of this AC said "6 → 2" and was wrong** — it forgot that the two
      defect-(b) tasks also render as `?`, so it would have failed against a correct fix.
      Corrected rather than reconciled by adjusting the count, which is the failure this
      task is about in miniature

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

# Asserted against the LIBRARY, not the rendered queue. Defect (b) in the Context is the
# proof that the display is an unreliable witness for this field, so verifying against it
# would be verifying against the thing that describes rather than the thing that acts.
python3 -c "import sys,glob; sys.path.insert(0,'.agentic-framework/web'); from shared import extract_recommendation_state as s; r={t:s(open(glob.glob('.tasks/active/'+t+'-*.md')[0],errors='replace').read()) for t in 'T-537 T-540 T-586 T-588'.split()}; assert all(v=='GO' for v in r.values()), r; print('4 expressible verdicts parse:', r)"
# The two ABSTAINs must STILL be unreadable — this task deliberately did not remap them, so
# a green here that showed them parsing would mean the substance was changed.
python3 -c "import sys,glob; sys.path.insert(0,'.agentic-framework/web'); from shared import extract_recommendation_state as s; r={t:s(open(glob.glob('.tasks/active/'+t+'-*.md')[0],errors='replace').read()) for t in 'T-341 T-358'.split()}; assert all(v=='?' for v in r.values()), r; print('ABSTAINs left unmapped:', r)"
# Each ABSTAIN carries its reason in its own file, not only in this task, which archives.
python3 -c "import glob; ok=[t for t in 'T-341 T-358'.split() if 'Left as ABSTAIN on purpose' in open(glob.glob('.tasks/active/'+t+'-*.md')[0],errors='replace').read()]; assert len(ok)==2, ok; print('both annotated in place')"
# Defect (b) was filed rather than fixed here.
test -n "$(ls .tasks/active/T-643-*.md 2>/dev/null)"
# The vocabulary gap is registered where it survives this task archiving.
grep -qF "no representation for a principled ABSTAIN" .context/inbox.yaml
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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-30T10:56:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-642-review-queue-shows-8-agent-recommendatio.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-22905b79
- **Timestamp:** 2026-08-30T11:00:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-30T11:00:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
