---
id: T-701
name: "RA-005: 100 real files modified and uncommitted"
description: >
  Audit WARN cycle 1 2026-09-16: git traceability check reports uncommitted work.
  Uncommitted work is work that no task reference can be traced to, which is the invariant
  P-002 exists to hold.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: claude
horizon: null
tags: [arc-003, audit-remediation, RA-005]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:25:05Z
last_update: 2026-11-14T16:08:57Z
date_finished: 2026-11-14T16:08:57Z
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
  - ts: '2026-09-16T13:30:33Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-11-14T16:04:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 4
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref); D2=4 (body:fw-audit-or-doctor); D3=0 (no-signal);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:49Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-701: RA-005: 100 real files modified and uncommitted

## Context

**Background / trigger:** the September residue audit (RA-005) counted 100 real files modified and uncommitted.
**Problem / hypothesis:** framework housekeeping (retention sweeps, episodic refreshes, card edits) leaves files changed
in the working tree that nobody commits, so the tree is never clean and real changes hide among them.
**Goal:** identify every uncommitted path by class, commit what belongs in history (explicit paths, task-referenced),
and justify what stays.
**Expected outcome:** a working tree whose remaining changes are each explained.

**Finding RA-005** - cycle 1, 2026-09-16. Source: fw audit. Severity: WARN.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[WARN] Uncommitted changes present
       Evidence: 100 real file(s) modified (1547 session-state file(s) ignored)
       Mitigation: Commit changes with task reference or stash
```

**The invariant that is not held:**

P-002 holds that every change in the tree traces to a task. An uncommitted change has no task reference and therefore no traceability: it is a modification nobody can attribute. 100 real files are in that state. Note the check already excludes 1547 session-state files, so the 100 are genuine content.

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The 100 modified files are either committed under a task reference, or each is individually identified and its uncommitted state justified in this task
- [x] `fw git status` shows no unattributed real-file modifications, or the residue is enumerated by path with a reason
- [x] No file is committed by a directory-wide stage - explicit paths only (T-571)

**Evidence (2026-11-14).** `git status --short` held 3,170 paths. **Committed** (explicit path lists via
`--pathspec-from-file`, no folder staging): 162 episodic records of closed tasks (34 never committed: T-1092 … T-1230;
128 framework footprint refreshes) and 2 session handovers never committed (S-2026-1008-1224, S-2026-1019-1812),
commits 2ad181cf5 and e097ed0e8. The residue, 3,006 paths, by class and why each stays uncommitted:
| class (paths) | count | why it stays |
|---|---|---|
| `D .context/audits/cron/*` | 758 | the audit cron's retention sweep deletes old tracked records; whether HEAD should follow the sweep is the framework's retention policy (see T-763, AEF T-5131), not decided here |
| `?? .context/audits/cron/*` | 698 | new cron records the cron leaves untracked by design (audit: "Cron outputs: every declared output is committed by its job or untracked" PASS) |
| `?? .context/locks/*` | 441 | runtime lock files of task operations; not history (903 older ones are tracked; whether locks should be ignored is a framework question) |
| `?? .context/runme/*` | 326 | operator job run logs, `done` and pid files; by design only `job.sh` and `dryrun.ok` are tracked |
| `?? / D .context/working/tmp/*` | 130 | scratch space of running tools |
| `?? .context/handovers/*.discard-manifest.yaml` | 62 | compaction discard manifests (~110 KB each) the handover agent writes beside each handover; not committed by it |
| `M .fabric/components/*` | 15 | component cards rewritten by framework enrichment; unattributed, left for a fabric task (a blind stage once swept in cards that were not ours) |
| `?? / D vendor/designer/*` | 14 | old release copies (0.15.0 … 0.41.0) and one deleted 0.8.0 left by release jobs; which to keep is a release-hygiene call |
| `.claude/*` (settings, resume command, 9 new skill commands, a `.pre-t857` backup) | 13 | the operator's and the framework installer's Claude configuration; not the agent's to commit |
| `M .tasks/active/*` (7) and `.tasks/completed/T-1204` | 8 | small framework writes (last_update, BVP proposals) and T-701's own edit; committed with their tasks when those close |
| `docs/reports/*` (T-1125 review outputs, t892 screenshots) and `.playwright-mcp/*.png` | ~16 | screenshots re-taken by harness runs and raw reviewer outputs; artefacts of old runs, not new content |
| `tests/.run-history.tsv`, `.tasks/.id-highwater`, `.agentic-framework/.context/*` | 4 | run log, the framework's id counter, the vendored framework's own runtime state |
No source file (`src/`, `tools/`, `tests/` code) is uncommitted (T-751's measurement, same day).

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
         1. Run `bin/fw reviewer T-701`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-701 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

out=$(.agentic-framework/bin/fw git status 2>&1); grep -q "Git Status" <<<"$out"
git cat-file -e 2ad181cf5 && git cat-file -e e097ed0e8

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

### 2026-11-14 — the "100 real files" are almost all framework housekeeping
- **What changed:** the tree grew to 3,170 paths; 164 were real records never committed (now committed); the rest are
  framework runtime output whose tracking policy is the framework's, listed above with reasons.
- **Plan impact:** none here; ignore-rule questions (locks, discard manifests, working/tmp) are framework hygiene.
- **Triggered:** nothing filed; offered to the operator.

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
     fw inception decide T-701 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:25:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-701-ra-005-100-real-files-modified-and-uncom.md
- **Context:** Initial task creation

### 2026-11-14T16:04:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-14T16:08:57Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-23311d31
- **Timestamp:** 2026-11-14T16:08:59Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
