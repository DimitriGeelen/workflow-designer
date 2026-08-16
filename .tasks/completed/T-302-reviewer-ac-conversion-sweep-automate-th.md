---
id: T-302
name: "REVIEWER-AC conversion sweep: automate the deterministic half of the approvals
  queue"
description: >
  Operator directive (2026-07-29): mass-automate the verifications queue via the reviewer
  agent. Census: 53 [REVIEWER] Human ACs (deterministic, convertible per T-1811/T-1878)
  vs 128 [REVIEW] (taste - stay human). Sweep: per task run fw reviewer + the AC's
  own Steps commands; convert passing [REVIEWER] ACs to Agent ACs with the command
  in ## Verification; record per-task evidence; suggest completion only where no Human
  ACs remain. NO batch-closing, NO [REVIEW] conversion, NO Human-AC ticking by agent.

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
created: 2026-07-29T11:28:25Z
last_update: '2026-08-16T14:33:25Z'
date_finished: 2026-07-29T13:19:38Z
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
      D3: 4
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=4 
      (body:framework-level-ux); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 4
      D4: 2
      F-RECALL: 3
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=4 
      (body:framework-level-ux); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:docs/reports/T-302-reviewer-sweep.md); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-302: REVIEWER-AC conversion sweep: automate the deterministic half of the approvals queue

## Context

Operator directive (2026-07-29): mass-automate the approvals/verifications queue via the reviewer agent. **Census correction at execution (see Updates):** the filing-time count of "53 [REVIEWER] ACs" was template-comment pollution — every task file embeds a `- [ ] [REVIEWER]` example inside an HTML comment, and the raw grep counted those. Comment-stripped reality: **zero** real `[REVIEWER]` ACs exist; the queue is 76 unchecked `[REVIEW]` ACs, of which 1 is deterministic mis-prefix (PL-027 class, convertible), 10 are inception decision gates (sovereignty — never automatable), and 65 are genuine taste. ACs below amended to the corrected scope; guardrails unchanged.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Sweep inventory built comment-stripped: all 76 active tasks with unchecked Human `[REVIEW]`/`[REVIEWER]` ACs listed with Steps/Expected extracted (scratchpad t302-review-acs.json; classification in docs/reports/T-302-reviewer-sweep.md). Census defect documented: 0 real [REVIEWER] ACs — filing count of 53 was HTML-comment pollution
- [x] Per queue task: `fw reviewer T-XXX` run on all 76 (verdict section written into each task file by the tool: 56 PASS / 20 CONCERN, all CONCERN findings advisory hygiene lints); the one deterministic AC's own Expected check executed (T-090: curl → HTTP 200 + title, evidence in T-090 Updates)
- [x] Deterministic mis-prefixed ACs converted per T-1811/T-1878: T-090's [RUBBER-STAMP] AC moved to `### Agent` ticked with evidence (its curl checks already lived in ## Verification); no other AC qualified (65 taste, 10 decision gates — listed as exceptions with reason in the report)
- [x] Zero taste `[REVIEW]` ACs converted, zero Human ACs ticked by the agent, zero batch-closes: T-090 (Human section emptied, owner human) listed for the operator with a one-line close command, not auto-completed
- [x] Sweep summary posted: converted/exception counts + residual human queue (65 taste + 10 decisions) in docs/reports/T-302-reviewer-sweep.md with a surface-grouped batch checklist and per-task close commands, and in this task's Updates

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

# Census is honest: zero unchecked [REVIEWER] ACs outside HTML comments in active tasks.
# NB: the comment-stripping pattern is assembled at runtime ('<'+'!--...') because the
# P-011 extractor strips HTML comments from this section — a literal comment-shaped
# regex here gets eaten by the gate itself before eval (discovered completing T-302).
out=$(python3 -c "import glob,re; pat='<'+'!--.*?--'+'>'; print(sum(len(re.findall(r'^\s*- \[ \] \[REVIEWER\]', re.sub(pat,'',open(f).read(),flags=re.S), re.M)) for f in glob.glob('.tasks/active/*.md')))"); test "$out" = "0"
# Sweep report exists with the classification and checklist
out=$(grep -c "batch checklist" docs/reports/T-302-reviewer-sweep.md); test "$out" -ge 1
# Reviewer verdict recorded in the full queue (76 files carry a verdict section)
out=$(grep -l "## Reviewer Verdict" .tasks/active/*.md | wc -l); test "$out" -ge 76
# T-090 conversion landed: no unchecked Human AC remains there
out=$(grep -c "^- \[ \] \[REVIEW\]" .tasks/active/T-090-watchtower-review-pages-all-500---dispat.md || true); test "$out" = "0"

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

### 2026-07-29 — Scope after census correction (0 real [REVIEWER] ACs)
- **Chose:** Amend the task ACs to the corrected reality; convert only the PL-027 deterministic mis-prefix (T-090); leave all 65 taste [REVIEW] ACs and all 10 decision gates human; deliver the automation value as (a) reviewer verdicts recorded across the whole queue and (b) a surface-grouped batch checklist so the operator can clear the queue in one gallery pass.
- **Why:** The operator's directive targets the queue's overhead, not its sovereignty. Taste verdicts and go/no-go decisions are exactly what the Human AC mechanism exists for (PL-027 inverse; Autonomous Mode Boundaries). Reclassifying them would be automating away the human, not the toil.
- **Rejected:** (a) Declaring the sweep vacuously complete against the literal "[REVIEWER]" wording — dishonest no-op; (b) converting taste ACs whose Steps merely contain URLs/commands — Steps being copy-pasteable doesn't make the Expected clause deterministic; (c) silently keeping the false "53 convertible" premise.
## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-29T11:28:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-302-reviewer-ac-conversion-sweep-automate-th.md
- **Context:** Initial task creation

### 2026-07-29T13:25:00Z — sweep executed; census corrected [agent]
- **Action:** Ran the sweep. STOP-investigate on AC#1: the filing-time census ("53 [REVIEWER] ACs") was a measurement defect — raw grep counted the `- [ ] [REVIEWER]` example line embedded in every task file's HTML template comment. Comment-stripped: 0 real [REVIEWER] ACs; 76 unchecked [REVIEW] ACs (one per task).
- **Classification:** 1 deterministic mis-prefix (T-090 [RUBBER-STAMP], PL-027 class) — converted + ticked with evidence; 10 inception decision gates (T-184/185/186/244/277/279/280/281/282/301) — sovereignty, excluded by rule; 65 genuine taste — untouched by rule.
- **Reviewer sweep:** `fw reviewer` run on all 76 (0.2 s each): 56 PASS / 20 CONCERN; every CONCERN is advisory hygiene (heuristic AC-verify-mismatch, L-387 SIGPIPE lint on Verification lines) — none blocks the human queue. Verdict sections recorded in each task file by the tool.
- **Deliverable:** docs/reports/T-302-reviewer-sweep.md — classification, verdict table, surface-grouped operator batch checklist with per-task close commands (T-090's included).
- **Learning:** AC census must strip HTML comments before grepping — template embeds prefixed example ACs (captured via fw context add-learning).

### 2026-07-29T13:09:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-83807d2a
- **Timestamp:** 2026-07-29T13:19:39Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T13:19:38Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
