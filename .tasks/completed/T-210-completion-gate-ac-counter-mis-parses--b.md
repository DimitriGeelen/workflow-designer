---
id: T-210
name: "Completion-gate AC counter mis-parses >-bearing inline comments (G-009)"
description: >
  Completion-gate AC counter mis-parses >-bearing inline comments (G-009)

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
created: 2026-07-19T19:20:48Z
last_update: '2026-08-16T12:33:43Z'
date_finished: 2026-07-19T19:24:55Z
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
  - ts: '2026-08-16T12:33:43Z'
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

# T-210: Completion-gate AC counter mis-parses >-bearing inline comments (G-009)

## Context

G-009: the completion-gate AC counter in `agents/task-create/update-task.sh`
(`check_acceptance_criteria`) strips one-line HTML comments with
`sed -E 's/<!--[^>]*-->//g'`. The `[^>]*` stops at the first literal `>`, so a
one-line AC comment that cites an XML/HTML tag (e.g. a `bpmn` element) survives
that pass; the subsequent range strip `/<!--/,/-->/d` then enters delete-mode
(the T-1967 same-line non-close behaviour) and swallows content down to a later
comment close — including the `### Human` header. The parser loses the
Agent/Human split and mis-attributes an unchecked `### Human` AC as an unchecked
agent AC, HARD-BLOCKING the partial-complete review handoff (T-193) instead of
downgrading. Surfaced completing T-204 (all 9 agent ACs checked, blocked on the
Human `[REVIEW]` AC). Incomplete T-1967 fix (that fix covered comment-free-of-`>`).
Governance tool 832 runs (not the T-559 designer↔AEF product seam); fix here +
upstream-propagate per the G-008 pattern.

## Acceptance Criteria

### Agent
- [x] `check_acceptance_criteria` one-line comment strip tolerates a literal `>` inside the comment: the `[^>]*` pattern is replaced with a minimal-match that stops at the first comment close and does not truncate on `>` (no lazy quantifier, POSIX/GNU sed safe).
- [x] A task whose agent ACs all carry one-line comments containing a `>` (and are all checked) with one unchecked `### Human` AC is classified as agent-complete + partial-complete (Human AC not counted as an agent AC) — the gate does NOT block.
- [x] Teeth preserved: a task with a genuinely unchecked `### Agent` AC (comments also containing `>`) still BLOCKS completion.
- [x] New regression test `agents/task-create/tests/test_ac_comment_strip.sh` extracts the real `check_acceptance_criteria` verbatim and asserts both the pass fixture (no false block) and the teeth fixture (still blocks); exits 0.
- [x] The genuine multi-line comment case still strips (the range-strip fall-through is unaffected) — covered by the existing behaviour and not regressed by the pass/teeth fixtures.

## Verification

bash .agentic-framework/agents/task-create/tests/test_ac_comment_strip.sh
bash .agentic-framework/agents/task-create/tests/test_disposition_gate.sh

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

**Symptom:** `fw task update T-204 --status work-completed` reported "1/3 agent AC
unchecked" and pointed at the `[REVIEW]` Human AC, despite all 9 agent ACs being
checked and `[REVIEW]` being correctly under `### Human`. The intended behaviour
(T-193 partial-complete downgrade) never fired — the review handoff hard-blocked.

**Root cause:** the one-line comment strip in `check_acceptance_criteria`
(`update-task.sh:91`) used `sed -E 's/<!--[^>]*-->//g'`. `[^>]*` matches only chars
that are not `>`, so a one-line comment containing a literal `>` (T-204's AC comments
cite BPMN element tags) does not match the one-line pattern and is left in place. The
following `sed '/<!--/,/-->/d'` then range-deletes from that surviving `<!--` to the
next `-->` — which, given the T-1967 same-line-non-close behaviour, spans lines and
swallows the `### Human` header. With the header gone, the awk Agent/Human partition
(lines 98/107, keyed on `^### Human`) collapses and the leftover `[REVIEW]` checkbox is
counted in the agent set.

**Why structurally allowed:** the T-1967 fix added the one-line pre-strip but wrote it
as `[^>]*`, tacitly assuming comment bodies never contain `>`. AC comments routinely
cite XML/HTML/generic-type syntax, so the assumption was wrong; and there was no
regression test exercising a `>`-bearing comment, so the incompleteness was invisible.

**Prevention:** (a) the pattern is now `<!--([^-]|-[^-]|--[^>])*-->` — a minimal match to
the first `-->` that tolerates any `>` inside; (b) new
`agents/task-create/tests/test_ac_comment_strip.sh` extracts the real function and
asserts a `>`-comment pass fixture does not block AND a genuinely-unchecked-agent-AC
fixture still blocks — so any regression to `>`-intolerance is caught. Upstream
propagation tracked in G-009 (same re-vendor loss mode as G-001/G-004/G-008).

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

### 2026-07-19T19:20:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-210-completion-gate-ac-counter-mis-parses--b.md
- **Context:** Initial task creation

### 2026-07-19T19:24:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
