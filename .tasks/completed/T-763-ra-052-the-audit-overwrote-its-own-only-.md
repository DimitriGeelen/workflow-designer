---
id: T-763
name: "RA-052: the audit overwrote its own only full-coverage baseline before it was
  ever committed"
description: >
  The full-coverage audit record was overwritten by a same-scope run before it was
  ever committed, so T-677's git-history retention invariant did not hold.

status: work-completed
workflow_type: test
current_node: frw_end_task
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T09:38:02Z
last_update: 2026-11-14T15:16:47Z
date_finished: 2026-11-14T15:16:47Z
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
  - ts: '2026-09-21T09:39:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-26T09:06:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 2
    rationale: 'D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 (body:default-change);
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=0 (no-signal);
      F4=0 (L0: no signal); F3=0 (L0: no signal); F1=2 (L1:keyword=designer,L1:keyword=bpmn)'
    rubric_sha: e4a00f38e801
  - ts: '2026-11-14T15:14:14Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref,body:concern-ref); D2=0 (no-signal); D3=0
      (no-signal); D4=0 (no-signal); F-RECALL=2 (body:lightly-promoted); F2=0 (no-signal);
      F4=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F3=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal); F1=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/audits/2026-09-21.yaml,docs/reports/T-761-cycle2-findings.md);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-763: RA-052: the audit overwrote its own only full-coverage baseline before it was ever committed

## Context

**Background / trigger:** the residue audit (RA-052) found the 2026-09-21 full-coverage audit record overwritten by a
same-day re-run before it had ever been committed.
**Problem / hypothesis:** T-677's retention rule assumes earlier runs live in git history, but that only holds if each
record is committed before the next same-scope run that day; nothing enforces it.
**Goal:** write the precondition down where the rule lives and get the enforcement question ruled.
**Expected outcome:** the operator's ruling recorded and passed to the framework; nothing back-filled.

### Verbatim tool output

```
$ git log --oneline --all -- .context/audits/2026-09-21.yaml
(no output)

$ git ls-files --error-unmatch .context/audits/2026-09-21.yaml
UNTRACKED — never committed

$ git status --porcelain -- .context/audits/2026-09-21.yaml
?? .context/audits/2026-09-21.yaml
```

### The invariant that is not held

T-677 establishes that `.context/audits/` holds the last run of each date, per
scope, and that earlier runs live in git history. The second half of that is a
promise about a different system: git holds only what was committed.

Cycle 2's full run — 687s, Pass 175 / Warn 31 / Fail 1, the **only 19-of-19
coverage record this project has ever produced** — was written to
`.context/audits/2026-09-21.yaml`, never committed, and overwritten roughly two
hours later by cycle 3's same-scope run. Nothing warned and nothing blocked.

So the retention design carries an unstated precondition — *commit before the
next run of the same scope on the same date* — and nothing enforces it. The
invariant that is not held is the one T-677 states in prose: for this record, the
earlier run does not live in git history, because it never got there.

The cost was immediate and concrete. Cycle 3 could not diff its finding set
against cycle 2's. Warn fell 31 → 29; one of those two is accounted for
(RA-053), and the second cannot be attributed to anything, because the record it
would be attributed against no longer exists.

### Root-cause links

Bears on RA-046/T-755 (the self-kill is why full runs are rare, which is why losing one matters) and on every cycle of arc-003, whose method is cycle-over-cycle comparison of audit records.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] T-677's unstated precondition is written down where the retention rule is stated: a dated audit record survives only if it is committed before the next run of the same scope on the same date.
- [x] Whether the framework should enforce that — a pre-run commit, a write-if-absent, a content-addressed filename, or an explicit accept-the-loss ruling — is filed as a Sovereign question. It changes retention semantics, which the operator owns, so it is NOT decided here.
- [x] The lost record is not reconstructed and nothing is back-filled into `.context/audits/`. Cycle 2's counts are reported as observed-in-output with their provenance stated. Manufacturing a record that was never written would be fabricating the exact evidence this finding is about.
- [x] This cycle's record is committed, preserving the instance. That is mitigation, not prevention (G-019): the class stays open until the ruling above exists.

**Evidence (2026-11-14):**
1. T-677's rule is recorded as a learning in `.context/project/learnings.yaml` (task T-677); the precondition is now a
   learning beside it (task T-763, 2026-11-14), citing RA-052 and the ruling.
2. Filed and **ruled by the operator 2026-11-14 ("1a"): a dated audit record is never overwritten; a same-day re-run
   writes its own record** (recorded as a decision under T-763). Audit retention is framework code, so the ruling went
   to AEF as a request (999-Agentic-Engineering-Framework, conversation `832-audit-rulings`, msg 2e36719a); the
   prevention lands when AEF builds it.
3. Nothing reconstructed or back-filled; cycle 2's counts (687 s, Pass 175 / Warn 31 / Fail 1) stay as observed in
   output, as stated in the Context above.
4. The cycle's record `.context/audits/2026-09-21.yaml` is committed (d8f41034b, T-765).

<!-- No Human ACs: this finding record carries no step a human can execute until
     the Sovereign question it raises is answered. An empty Human section would
     lengthen a review queue already 67 deep (SQ-3) with nothing to review.

     Original template guidance retained below for the next editor.

     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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
         1. Run `bin/fw reviewer T-763`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-763 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

test -f .context/audits/2026-09-21.yaml
grep -q 'sections: "all"' .context/audits/2026-09-21.yaml
grep -q 'Record integrity note' docs/reports/T-761-cycle2-findings.md

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
     fw inception decide T-763 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T09:38:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-763-ra-052-the-audit-overwrote-its-own-only-.md
- **Context:** Initial task creation

### 2026-11-14T15:14:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-14T15:16:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-11-14T15:22Z — AEF took the ruling [agent]
- AEF (msg f418252f, conversation `832-audit-rulings`): "audit record retention, no same-day overwrite = AEF T-5131",
  on their next-up list; they report when it lands on bleeding-edge. Follow it until it does.

### 2026-11-14T17:50Z — AEF T-5131 landed on bleeding-edge [agent]
- AEF (msg dd2f9ebc): a manual audit no longer overwrites a dated record; an earlier same-day `<date>.yaml` is moved
  aside to `<date>-<HHMM of its mtime>.yaml` (counter on a clash), `<date>.yaml` stays the newest; closed with tests.
  Ships with their next be-tag. Verify after 832's next framework upgrade.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cb970319
- **Timestamp:** 2026-11-14T15:16:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
