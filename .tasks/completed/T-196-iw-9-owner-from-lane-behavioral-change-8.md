---
id: T-196
name: "IW-9 owner-from-lane behavioral change (832 editor/bridge)"
description: >
  Authorized by the IW-9 v1.1 graduation (T-189). Standards now mandate owner is derived from the lane authority with NO node-level override. This is the 832-side CODE change: the forward path must source owner from aef:laneMeta authority (collapse map sovereignty->human, initiative/authority->agent, external->no task) and IGNORE any node-level aef:meta owner rather than honor it; emit an O-1 validation WARNING on task-type/lane mismatch (lane wins). O-2: KEEP owner in editor metaKeys/bridge META_KEYS for reverse-render laning (conformance-safe). O-3: assert an inception's go/no-go boundary is human-laned, fail fast if not. AEF's Child-2 compiler (T-2531) already implements this; T-187/T-188 round-trip guards cover the serialization change. Doc-delta was T-189; this is the implementation it teed up.

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
created: 2026-07-12T20:45:40Z
last_update: 2026-07-12T21:09:38Z
date_finished: 2026-07-12T21:09:38Z
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

# T-196: IW-9 owner-from-lane behavioral change (832 editor/bridge)

## Context

**Scoped down from the umbrella filed at creation.** The IW-9 v1.1 graduation (T-189) authorized 832-side
follow-through. Scope investigation (Explore, this session) found it decomposes into two deliverables with
different verification methods, so per task-sizing this task covers **only the validator enforcement** (pure
logic, unit-testable, no UI). The **editor UI** portion (retire the node-`owner` override field, derive owner
from lane) needs Playwright visual verification and is a **sibling task**.

This task makes the just-frozen v1.1 rules **machine-enforceable** in `tools/validate-workflow.py` on the
**BPMN form** (where the byte-validated corpus fixtures live and the arc exchanges artifacts with AEF):
- **O-3 (MUST):** an inception's go/no-go boundary MUST be sovereignty(human)-laned — fail fast on a malformed
  inception (mapping-v1 §7, forward-compile §8).
- **O-1 (SHOULD):** BPMN task-type SHOULD agree with the lane authority; WARN on mismatch (lane wins,
  presentational — mapping-v1 §3).

Collapse map (mapping-v1 §3): `sovereignty→human`, `initiative→agent`, `authority→agent`, `external→no task`.
Task-type→performer: `userTask→human`; `serviceTask`/`scriptTask→agent`.

## Acceptance Criteria

### Agent
- [x] `tools/validate-workflow.py` `XmlValidator` adds an **O-3 inception-laning** rule: a `subProcess`
  carrying `aef:meta workflowType="inception"` MUST be a member of a lane whose `aef:laneMeta
  authority="sovereignty"`. Violation (unlaned, or non-sovereignty lane) → **ERROR** `E-INCEPTION-NOT-SOVEREIGN`
  (exit 2).
- [x] `tools/validate-workflow.py` `XmlValidator` adds an **O-1 type/lane mismatch** rule: for
  `userTask`/`serviceTask`/`scriptTask`, the task-type-implied performer is compared to the member lane's
  authority via the collapse map; mismatch → **WARN** `W-TYPE-LANE-MISMATCH` (lane wins). `external` lanes
  author no task and are skipped.
- [x] Both rules resolve a node→lane→authority map by parsing `bpmn:laneSet`/`flowNodeRef` +
  `aef:laneMeta authority`; implemented to match the graduated v1.1 standard (mapping-v1 §3/§7).
- [x] Unit tests (`tests/test_validate_iw9.py`, runnable as `python3 tests/test_validate_iw9.py`, exits
  non-zero on failure): (a) `inception-gonogo.bpmn` produces **no** `E-INCEPTION-NOT-SOVEREIGN`; (b) a crafted
  inception in a non-sovereignty lane **does**; (c) a `serviceTask` in a sovereignty lane yields
  `W-TYPE-LANE-MISMATCH`; (d) `resume-status.bpmn` (no inception) yields no O-3 finding.
- [x] **No regression:** every existing `tests/fixtures/aef-bpmn/*.bpmn` validates with **no new ERROR**
  introduced by these rules; `python3 tests/test_forward_fixtures.py` and the new test both pass.
- [x] Sibling task filed for the editor-UI portion (retire node-`owner` override field + derive-from-lane),
  with a note that it requires visual verification.

### Human
_None — every criterion is machine-verifiable (validator logic + unit tests). No UI in this task; the
editor-UI portion (which does need human/visual verification) is the sibling task._

## Verification

# Inception-gonogo (sovereignty-laned) must NOT trip the new O-3 ERROR (exit 0 or 1, never 2).
test "$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/inception-gonogo.bpmn --quiet >/dev/null 2>&1; echo $?)" != "2"
# The new IW-9 rules exist in the validator.
grep -q "E-INCEPTION-NOT-SOVEREIGN" tools/validate-workflow.py
grep -q "W-TYPE-LANE-MISMATCH" tools/validate-workflow.py
# New unit tests pass.
python3 tests/test_validate_iw9.py
# No regression on the fixture conformance guard.
python3 tests/test_forward_fixtures.py
# No corpus fixture newly hard-errors (exit 2) from these rules.
for f in tests/fixtures/aef-bpmn/*.bpmn; do python3 tools/validate-workflow.py "$f" --quiet >/dev/null 2>&1; test $? -ne 2 || { echo "REGRESSION: $f exits 2"; exit 1; }; done

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

### 2026-07-12T20:45:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-196-iw-9-owner-from-lane-behavioral-change-8.md
- **Context:** Initial task creation

### 2026-07-12T20:59:23Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-12T21:09:38Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
