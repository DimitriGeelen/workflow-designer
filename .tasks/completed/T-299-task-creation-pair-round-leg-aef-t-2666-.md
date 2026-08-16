---
id: T-299
name: "Task-creation pair round leg (AEF T-2666 dogfood 3)"
description: >
  Pair round #3: validate AEF draft-task-creation v2 bytes with our validator, answer
  mapping-v1 taste questions (multiple start events, activation gateway, owner-validation
  conformance hole), pair against our task-lifecycle/task-gate articles, report on
  rail

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-29T07:38:22Z
last_update: '2026-08-16T12:33:48Z'
date_finished: 2026-07-29T07:42:33Z
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
  - ts: '2026-08-16T12:33:48Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-299: Task-creation pair round leg (AEF T-2666 dogfood 3)

## Context

AEF opened pair round #3 (rail 314, their T-2666, dogfood #3 of 4): draft-task-creation v2
at http://192.168.10.107:3001/api/version?id=draft-task-creation (14 nodes / 20 flows / 3 lanes),
modelling the task-creation ceremony (fw work-on → create-task.sh path, T-555 validation,
ID keylock, 7-way workflow-type gateway, G-020 readiness gate). They applied the T-2665-round
dialect teaching at seed. Asks: (1) validator over the draft bytes; (2) pair against our
catalog's task-creation article (closest: task-lifecycle / task-gate); (3) three taste
questions — multiple start events in mapping-v1, activation gateway vs aef:meta note for
the bare `fw task create` path, and a live conformance hole (is_valid_owner never called
at creation; no status predicate) → wire-the-predicates vs pin-the-hole.

## Acceptance Criteria

### Agent
- [x] AEF draft v2 bytes fetched (sanctioned HTTP) and run through tools/validate-workflow.py; full findings list reported verbatim on the rail — VALID, zero findings (sha 15565384…, 16765 B); structure independently re-counted 14n/20f/2 starts/1 end/7-way fw_gw_type, matches their manifest
- [x] Taste question 1 answered from spec+code evidence: YES — mapping-v1 §5 table has no start-cardinality rule; validator unions reachability from all startEvents (validate-workflow.py:554-566); 2 of our 24 shipped maps are dual-start (context-memory, error-escalation-ladder)
- [x] Taste question 2 answered: FORK the activation gateway — real divergent code path (bare `fw task create`, no --start) is control flow not annotation; the captured/no-focus end is the exact startEvent of our task-lifecycle article ("Task captured (filed)"), making it a documented F5-class cross-article seam
- [x] Taste question 3 answered: BOTH in sequence — pin-the-hole in the article (their fw_4_write note = our healing-loop v2 honesty class), wire-the-predicates as its own Level-C bug task (one bug = one task; owner + status predicates are two independent holes), rev article when fix lands; G-019: concerns:1151 open until predicate is CALLED
- [x] Pairing check done: no task-creation article in our catalog — their draft fills the hole upstream; seams: both their ends feed task-lifecycle's start, their G-020 node overlaps task-gate (creation-time readiness vs tool-call-time enforcement); cross-reference, no competing article
- [x] Rail reply posted to offset 314 (landed at 316); memory file rail frontier updated

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

out=$(python3 tools/validate-workflow.py /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/draft-task-creation-v2.bpmn 2>&1); echo "$out" | grep -q "VALID"
[ $(grep -c "<bpmn:startEvent" examples/aef-processes/rendered/context-memory.bpmn) -eq 2 ]
[ $(grep -c "<bpmn:startEvent" examples/aef-processes/rendered/error-escalation-ladder.bpmn) -eq 2 ]

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

### 2026-07-29T07:38:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-299-task-creation-pair-round-leg-aef-t-2666-.md
- **Context:** Initial task creation

### 2026-07-29 — round #3 verdict delivered (same session)
- **Action:** Fetched draft v2 (raw BPMN, 16765 B, sha 15565384…), validator VALID zero findings — first AEF draft of the four to seed clean (round-#2 teaching applied at seed). Answered all three taste questions with cited evidence (Q1 multi-start YES: spec silence + validator union-reachability + 2 in-corpus precedents; Q2 fork the activation gateway: control flow + task-lifecycle seam; Q3 pin-in-article AND wire-as-own-task: healing-loop v2 + T-295 + G-019 precedents). Pairing: no catalog duplication, two seams documented (task-lifecycle start, task-gate overlap).
- **Output:** Rail reply at offset 316 (reply to 314); acked through 314 at 315.
- **Context:** Also received at 313: AEF 0.8.0 re-pin PASS (their T-2673) — :3001 now serves the T-293 fix; healing-loop pair leg confirmed closed both sides.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a9c69b35
- **Timestamp:** 2026-07-29T07:42:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T07:42:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
