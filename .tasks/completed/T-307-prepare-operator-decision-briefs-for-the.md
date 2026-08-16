---
id: T-307
name: "Prepare operator decision briefs for the 10 open inception tasks"
description: >
  Prepare operator decision briefs for the 10 open inception tasks

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
created: 2026-07-29T16:12:05Z
last_update: '2026-08-16T13:57:20Z'
date_finished: 2026-07-29T16:20:52Z
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
  - ts: '2026-08-16T12:33:49Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 1
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=1 
      (body/components:context-fabric-incidental); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/learnings.yaml,docs/reports/T-302-reviewer-sweep.md,docs/reports/T-307-inception-decision-briefs.md);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-307: Prepare operator decision briefs for the 10 open inception tasks

## Context

**Operator correction (2026-07-29):** the T-302 report's 10 inception-decision templates all shipped as `fw inception decide T-XXX go --rationale "<why>"` — a placeholder rationale in a **sovereignty record**, plus `go` pre-filled as the default verb. The operator caught it: pasting that verbatim writes garbage into the permanent `## Decision` section the framework mines for episodic memory, invites rubber-stamping, and biases toward approval. It also inverted the flow — decisions were requested without the evidence in front of the human (CLAUDE.md §Inception Discipline step 2: present the filled template BEFORE requesting a decision; T-609/T-325: no placeholders the human must figure out).

**This task:** produce one decision brief per open inception (T-155 T-184 T-185 T-186 T-244 T-277 T-279 T-280 T-281 T-282) — the question explored, findings from the task file / research artifact, assumption status, an agent recommendation WITH reasoning, and a paste-ready command whose rationale is **drafted from the findings** (the operator's to adopt, edit, or discard) with all three verbs (go/no-go/defer) presented neutrally. The decision itself remains operator-only; this task produces evidence, never a decision.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Decision brief written for all 10 open inceptions (T-155 T-184 T-185 T-186 T-244 T-277 T-279 T-280 T-281 T-282) in docs/reports/T-307-inception-decision-briefs.md — each with: the one question, evidence from the task file / research artifact, assumption status, recommendation + reasoning, and consequences of each verb (9 briefs + T-155 documented as already-decided/needs-closing, not a decision)
- [x] Zero placeholder rationales: every `fw inception decide` command in the brief carries a substantive rationale drafted from that inception's findings — no `"<why>"`, no `"your reasoning"`; a grep for placeholder markers in the decide lines returns nothing (0 executable lines with placeholders; the single `<why>` occurrence is prose quoting the defect being corrected)
- [x] All three verbs presented neutrally per task (go/no-go/defer each shown as a full paste-ready command, not `go` with alternatives in parentheses) (27 commands = 9 tasks × 3 verbs, each with a verb-appropriate rationale)
- [x] The defective templates in docs/reports/T-302-reviewer-sweep.md are corrected or superseded with a pointer to the briefs, so the placeholder version cannot be pasted by mistake (SUPERSEDED notice replaces the 10 defective command lines)
- [x] Learning captured: placeholder rationales in operator-facing sovereignty commands are a defect class (cites this T-302 instance) (PL-063)


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

# No executable decide line in the briefs carries a placeholder rationale (prose quoting the defect is allowed)
out=$(grep -c "^cd .*fw inception decide.*\(<why>\|your reasoning\|<reason>\)" docs/reports/T-307-inception-decision-briefs.md || true); test "$out" = "0"
# All three verbs drafted for all 9 open inceptions (9 x 3 = 27 complete commands)
out=$(grep -c "^cd .*fw inception decide" docs/reports/T-307-inception-decision-briefs.md || true); test "$out" = "27"
# Every one of the 9 open inceptions has a brief
for t in T-184 T-185 T-186 T-244 T-277 T-279 T-280 T-281 T-282; do grep -q "$t" docs/reports/T-307-inception-decision-briefs.md || exit 1; done
# The defective T-302 templates are superseded, not still pastable
grep -q "SUPERSEDED (T-307" docs/reports/T-302-reviewer-sweep.md
out=$(grep -c "^cd .*fw inception decide.*<why>" docs/reports/T-302-reviewer-sweep.md || true); test "$out" = "0"
# PL-063 captured
grep -q "PL-063" .context/project/learnings.yaml


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

### 2026-07-29T16:12:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-307-prepare-operator-decision-briefs-for-the.md
- **Context:** Initial task creation

### 2026-07-29T16:30:00Z — briefs delivered [agent]
- **Action:** Gathered evidence for all 10 open inceptions (2 Explore agents + direct comment-stripped extraction after the dispatch gate capped agents at 2 per TermLink-first policy T-533), then wrote one decision brief each. Four findings reframed the ask: (1) it is NINE decisions, not ten — T-155 already has a DEFER recorded and needs closing; (2) all nine carry an agent recommendation of DEFER, none is a GO candidate, so the operator faces ratification-or-disagreement, not ten build calls; (3) the sanctioned route is `fw task review` -> Watchtower /inception/T-XXX, NOT a pasted CLI command (fw inception decide is agent-blocked by T-679/T-1259 and needs --i-am-human for a human inside an agent session) — my original CLI suggestion was off-protocol as well as placeholder-ridden; (4) ZERO of the nine carry revisit_at/revisit_evidence_needed, so a DEFER ratified as-is would rot invisibly (G-053 scans frontmatter dates, not prose triggers) — each brief proposes both fields.
- **Output:** docs/reports/T-307-inception-decision-briefs.md — 9 briefs (question, evidence state, findings, recommendation + reasoning, all 3 verbs as complete commands with verb-appropriate drafted rationales = 27 commands, proposed revisit fields) + T-155 documented as needs-closing + summary table with confidence per recommendation. T-184 and T-279 flagged as the two deserving most scrutiny (T-184: dependency half of its revisit trigger already fired; T-279: trigger is operator-will only, so DEFER risks becoming permanent silence). T-302's defective section superseded in place. PL-063 captured.
- **Context:** Operator correction — "hello rationlae :: my reasoning !!! reflect why this is wroimng !!! wehat are thej inception instructions" — on placeholder rationales in sovereignty records.


## Reviewer Verdict (v1.5)

- **Scan ID:** R-ea440500
- **Timestamp:** 2026-07-29T16:20:53Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T16:20:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
