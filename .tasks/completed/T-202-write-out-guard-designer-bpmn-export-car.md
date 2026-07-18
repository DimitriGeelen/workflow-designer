---
id: T-202
name: "Write-out: guard designer .bpmn export carries the promote content contract (aef:uid + lane authority)"
description: >
  Post-GO on T-201 write-out inception. Seam resolved: content-authority=832, gated-write=AEF via fw bpmn promote -> fw task create (T-2541). This is 832's side of the content contract: guarantee the designer .bpmn export carries a stable aef:uid and a defined lane authority for every owner-bearing node, so promote can derive owner (IW-9) and stamp provenance with no gaps. Machine-verifiable guard; end-to-end integration waits on AEF T-2541 promote+Spike-1.

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
created: 2026-07-18T08:44:10Z
last_update: 2026-07-18T08:48:06Z
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

# T-202: Write-out: guard designer .bpmn export carries the promote content contract (aef:uid + lane authority)

## Context

Post-GO on the T-201 write-out inception (Dimitri recorded GO 2026-07-18). The
seam resolved to **manifest-as-seam**: content-authority = 832, gated-write = AEF
via `fw bpmn promote` → `fw task create` (AEF joint inception T-2541). AEF's
promote derives each emitted task's `owner` (via the IW-9 collapse map) and stamps
`aef_provenance` (`uid` + source `.bpmn`) from the compiled manifest — which is
compiled from **832's designer export**. This task guards 832's side of that
contract: the export must never hand promote a node it cannot lane or identify.
Concretely, every owner-bearing node (`serviceTask`/`userTask`/`scriptTask`/
`subProcess`) in the designer's `.bpmn` export must carry a stable non-empty
`aef:uid` AND sit in a lane with a defined authority (`sovereignty`/`authority`/
`initiative`/`external`/`none`) — otherwise IW-9 owner derivation or provenance
stamping has a gap. Full contract: `docs/reports/T-201-writeout-mode-inception.md`
§3a/§3b. End-to-end integration (compile→promote→`fw task create`) waits on AEF
T-2541; this guard is independent and buildable now.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A guard test asserts every owner-bearing node (`serviceTask`/`userTask`/`scriptTask`/`subProcess`) in the designer's serialized `.bpmn` export carries a non-empty `aef:uid`. — `audit()` §(1), `tests/test_designer_export_contract.py`
- [x] The same guard asserts every owner-bearing node belongs to a lane whose authority is one of the five defined values (`sovereignty`/`authority`/`initiative`/`external`/`none`) — so IW-9 owner derivation never resolves against an undefined/absent lane. — `audit()` §(2)
- [x] The guard runs against the designer's seed workflow (`getInvestigateWorkflow`) and passes; it fails (red) if a uid is stripped or a node is placed in a lane with no authority — proving it is a real gate, not a tautology. — teeth check via `_strip_first_uid` / `_blank_first_lane_authority`; PASS reports "8 owner-bearing node(s) … teeth proven".
- [x] The test is wired into the designer test suite (src-served, same harness as `test_designer_owner_derived.py`) and is green. — added to `## Verification`; `python3 tests/test_designer_export_contract.py` exits 0.

## Verification

python3 tests/test_designer_export_contract.py

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

### 2026-07-18T08:44:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-202-write-out-guard-designer-bpmn-export-car.md
- **Context:** Initial task creation

### 2026-07-18T08:48:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
