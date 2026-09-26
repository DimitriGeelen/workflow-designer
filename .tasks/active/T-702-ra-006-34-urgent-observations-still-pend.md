---
id: T-702
name: "RA-006: 34 urgent observations still pending in the inbox"
description: >
  Audit WARN cycle 1 2026-09-16: urgent items in .context/inbox.yaml need attention.
  Triage promotes or dismisses, and a dismissal is a judgement about whether a recorded
  finding matters, which is not the agent's to make.

status: started-work
workflow_type: build
owner: human
horizon: now
tags: [arc-003, audit-remediation, RA-006]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:25:08Z
last_update: '2026-09-26T09:06:25Z'
date_finished:
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
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-26T09:06:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 2
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted);
      F2=0 (no-signal); F4=0 (L0: no signal); F3=2 (L2:keyword=termlink); F1=3 (L1:keyword=designer,L1:keyword=bpmn)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:49Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 1
    rationale: blast_radius=1 (paths:.context/inbox.yaml); tier=2 (no-signal); 
      effort=7 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-21T20:24:52Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/inbox.yaml,docs/reports/T-702-urgent-named.md,tools/_t703-inbox-residue.py);
      tier=2 (no-signal); effort=6 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-702: RA-006: 34 urgent observations still pending in the inbox

## Context

**Finding RA-006** - cycle 1, 2026-09-16. Source: fw audit. Severity: WARN.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[WARN] 34 urgent observation(s) still pending
       Evidence: Urgent items in .context/inbox.yaml need attention
       Mitigation: Run: fw note triage
```

**The invariant that is not held:**

An observation register exists so that a finding survives the session that found it. The invariant is that an urgent observation is acted on or dismissed, not merely stored. 34 urgent items are stored and unacted. Capture without application is FP-011; an urgent flag that never triggers anything is a flag that does not mean urgent.

**Root-cause siblings:** T-703 (RA-007)

**Operator action / sovereignty boundary:**
Dismissing a recorded finding is a judgement about whether it matters. The agent may propose a triage verdict but must not enter one. The eleven dismissed observation husks in .context/inbox.yaml are evidence and must not be deleted.

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `fw audit --section observations` reports 0 urgent pending, or every remaining urgent item is individually named with the reason it stays open — **named, all 36** (the finding said 34; it is 36 today, and the handover has been reporting 3 — see T-703 `--counters`). `docs/reports/T-702-urgent-named.md`, generated by `tools/_t703-inbox-residue.py --urgent --write`, lists each pending urgent item with a reason class from the register: 25 carried-by-completed-task (thread lives in that task's episodic), 7 carried-by-active-task, 3 orphan (OBS-249 budget ladder, OBS-251 shared identity, OBS-256 bridge-suite scheduling — each a decision only the operator can make), 1 dangling (OBS-309 → peer task id). `--urgent --check` exits 0 only when every row carries a reason.
- [x] Each triaged item is either promoted to a task or dismissed with a recorded rationale - no item is closed by aggregate sweep — **holds vacuously and deliberately: zero items were closed.** T-703 established (probe, VERDICT CONFIRMED) that the only closing verb, `fw note dismiss --reason`, persists no rationale — so a dismissal by this task could not satisfy this criterion's own wording. Triage-by-dismissal is withheld until the T-703 ruling; nothing was promoted because every item already has a carrying task or is an operator decision. Ticked on the vacuous reading; the operator may reject that reading at /review/T-702.

### Human

- [ ] [REVIEW] Confirm that "named with reason" closes RA-006, or direct a drain
  **Steps:**
  1. Open http://192.168.10.107:3013/review/T-702; read the census at the top of `docs/reports/T-702-urgent-named.md`
  2. The three orphans are yours alone: OBS-249 (CLAUDE.md budget ladder — T-614 has since rewritten the ladder in percentages; if you agree it is resolved, it is the first candidate for dismissal once the verb records a reason), OBS-251 (mint a project termlink key — the same question OBS-248 raised), OBS-256 (bridge suite: schedule it via /etc/cron.d, or make it deterministic first)
  3. Choose: **A** — accept the enumeration as the closure of RA-006 and let T-703's ruling govern the drain; **B** — rule on the three orphans here and now (one letter each: dismiss / promote / hold) and have the agent execute after T-703 A lands
  **Expected:** a letter on this task; under B, three sub-rulings
  **If not:** RA-006 re-files at the next remediation sweep with a larger number

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

# Parked: triage verdicts are the operator's. Verification is the next cycle's audit re-run.

# T-702 legs — same instrument as T-703, urgent mode (any age).
python3 tools/_t703-inbox-residue.py --urgent --check
test -f docs/reports/T-702-urgent-named.md
# every pending urgent item is a row in the report: row count == the exact (yaml-parse) urgent count
test "$(grep -c '^| OBS-' docs/reports/T-702-urgent-named.md)" -eq "$(python3 tools/_t703-inbox-residue.py --counters | awk '/exact/{print $1}')"

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

**Symptom:** 36 urgent observations pending (finding said 34; handover says 3).

**Root cause:** shared with T-703 — the register has no auditable drain, so urgent items age in place; and the urgency signal itself is unreadable because the instrument most sessions read (handover.sh:382) undercounts it 12×.

**Why structurally allowed:** "urgent" is a flag with no consumer: nothing routes on it, nothing expires it, and the one summary that surfaces it miscounts it. A flag nobody acts on decays into noise (OBS-034 made the same point about the misfire rows).

**Prevention:** the named list is regenerable and checked (`--urgent --check`); the counter disagreement is printed by `--counters` so it cannot be re-discovered as new. The handover undercount is a one-bug task candidate (handback), not fixed here.


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

Filed as "34 urgent, triage them". Landed as "36 urgent, every one named, none closed". The pivot came from T-703 one unit earlier: once the dismiss verb was shown to drop its reason, this task's AC2 could not be met by doing what the finding's mitigation line says (`fw note triage — promote or dismiss`). The honest satisfaction of "no item closed by sweep" was to close no item. The 2 items that made 34 into 36 are OBS-354 and OBS-355, both filed 2026-09-20 under T-575/T-696 — the register grows faster than any triage the operator has been asked to do.


## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-20 — reuse T-703's instrument rather than write a second one
- **Chose:** add `--urgent` to `tools/_t703-inbox-residue.py`.
- **Why:** same register, same reason classifier, same parse; a second tool would be a second thing to keep in agreement with the first — the exact disease `--counters` documents.
- **Rejected:** a T-702-specific script.


## Recommendation

**Recommendation:** GO
**Rationale:** Option A — accept the named enumeration as RA-006's closure and let T-703 govern the drain. Every urgent item is now individually accounted for, and 33 of 36 sit with a task (25 completed, 7 active, 1 peer); only 3 are genuinely the operator's and each is a standing decision (budget-ladder wording since overtaken by T-614; project key minting; bridge-suite scheduling). Draining first would clear a number and lose 36 reasons.
**Evidence:** `docs/reports/T-702-urgent-named.md` (36 rows, census 25/7/3/1); `tools/_t703-inbox-residue.py --counters` → 36 / 41 / 3; T-703 probe VERDICT CONFIRMED.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-702 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:25:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-702-ra-006-34-urgent-observations-still-pend.md
- **Context:** Initial task creation

### 2026-09-20T09:11:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
