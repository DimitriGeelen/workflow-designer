---
id: T-740
name: "Value review: the AEF seam and the workflow -> program -> execution chain, and what the handoffs need"
description: >
  Operator-scoped value review (DELETE/REFACTOR/ADD) of the AEF integration seam: operator<->AEF and agent collaboration along the chain workflow -> program -> execution, the handoffs between those stages, and what is missing to make the chain work. Producer-not-judge: GATHERER collects evidence read-only, a separate JUDGE classifies from the evidence file alone, the operator decides item by item. Research is not authorization - nothing is deleted, restructured or built under this task.

status: started-work
workflow_type: specification
owner: agent
horizon: now
tags: [value-review, aef-seam, workflow-execution, arc-0]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-20T20:03:20Z
last_update: 2026-09-20T20:18:51Z
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

# T-740: Value review: the AEF seam and the workflow -> program -> execution chain, and what the handoffs need

## Context

Operator-scoped value review (DELETE / REFACTOR / ADD), scope set by the operator on 2026-09-20:
*"the integration with AEF and operator AEF, agent collaboration where we go from a workflow to a
program to incomplete execution and that handoff in between that and what we need for that."*

The scope maps exactly onto two of this project's three arcs, so the chain is not something this
review has to discover — it is already declared:

| Arc | Chain stage | Headline mechanic |
|---|---|---|
| arc-001 `designer-authoring-surface` (T-175) | **workflow → program** | human draws a process → AEF agent turns it into an approved governed task/inception graph; and the reverse |
| arc-002 `ewcr-governed-delivery` (T-590) | **program → execution** | operator exports a Designer workflow as an executable contract → a runtime executes it, every step traceable to evidence and to the authorising decision, any step lacking either refused |

arc-003 (audit remediation) is out of scope.

Yardstick, data availability map and role setup: `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/00-yardstick.md`.

**Producer-not-judge.** GATHERERs collect evidence read-only (Phases 0–3); a separate JUDGE
classifies from the evidence files and the confirmed yardstick alone (Phase 4–5); the operator
decides item by item (Phase 5) and authorises execution (Phase 6). **Research is not
authorization** — nothing is deleted, restructured or built under this task id.

**Gate refusal recorded, not routed around.** `fw hook check-agent-dispatch` (T-533, TermLink-first
dispatch enforcement) capped Agent-tool dispatch at 2 and blocked gatherers 3–5. Its offered exits
`fw dispatch approve` and `fw dispatch reset` are self-authorisation and were **not** taken; the
sanctioned path named by the gate itself — `fw termlink dispatch` — was used instead.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Yardstick written and traceable to sources: purpose, users/consumers, core capabilities, non-goals, value drivers and weights, plus the contradictions found between stated purpose and the live tree.
- [x] Data availability map records every source as EXISTS / PARTIAL / DESIGNED-ONLY / ABSENT, verified against the live tree — with ABSENT rows named explicitly rather than omitted.
- [x] Evidence files exist for all six gatherer domains (seam contract, workflow→program, program→execution, handoff/collaboration, ledger/cost, operator surface), each fact carrying a path:line, command output, commit hash or record ID.
- [x] Every chain step in the Phase 2 reverse map is either mapped to an item that serves it, or recorded as served by nothing.
- [x] NON-USE DIAGNOSIS evidence (readings A–E) collected for every low/no-use item, with the reading left unresolved by the GATHERER.
- [x] JUDGE ran with the evidence files and yardstick as its only inputs, and its classification is separable from the gathering — if that separation did not hold, every confidence is dropped one level and the report says so.
- [x] Final report written to `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md` with all 12 required sections, including data gaps that capped confidence, contradictions, what was not reviewed, and Sovereign questions each carrying a recommendation.
- [x] Counter-evidence against this session's own prior findings is recorded rather than suppressed — specifically the T-739 narrowing established at `06-operator-surface.md` §3.
- [x] No item is deleted, restructured or built under this task id, and no gate is bypassed: `.context/working/.gate-bypass-log.yaml` gains no entry attributable to T-740.

<!-- No ### Human section on the agent side of this task: the operator's act is the Phase 5
     decision itself, which is recorded below as the review's own gate. -->

### Human
- [ ] [REVIEW] The review's findings are approved, rejected or modified item by item, and the decisions are recorded.
  **Steps:**
  1. Read `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md` — start at §5 Summary and §6 Findings table.
  2. For each finding row, record approve / reject / modify. Rejections should carry a reason so the item is not re-proposed without new evidence.
  3. Rule on the Sovereign questions in §12 separately — those touch driver weights, ratified workflows, gates or authority and are not the agent's to settle.
  **Expected:** every non-KEEP row has a recorded disposition, and no Phase 6 execution has happened before that.
  **If not:** say which rows are undecidable as written and what evidence would make them decidable.

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
         1. Run `bin/fw reviewer T-740`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-740 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# T-740 legs. Each re-checks a file-state fact, not a self-report.
test "$(ls docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/*.md | wc -l)" -eq 7
test -f docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md
test "$(grep -cE '^## (1|2|3|4|5|6|7|8|9|10|11|12)\. ' docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md)" -eq 12
grep -q "COUNTER-EVIDENCE against this session's own T-739 filing" docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/06-operator-surface.md
grep -q "Sovereign questions" docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md
test "$(grep -c 'T-740' .context/working/.gate-bypass-log.yaml)" -eq 0

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
     fw inception decide T-740 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-20T20:03:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-740-value-review-the-aef-seam-and-the-workfl.md
- **Context:** Initial task creation

### 2026-09-20T20:03:26Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
