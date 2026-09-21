---
id: T-780
name: "Re-enter selection at arc level: does any arc hold eligible Q1/Q2 work, or
  has this run reached its third stop condition?"
description: >
  Rounds 1 and 2 selected within the in-flight arc. The mandate requires that when
  nothing in the current arc is Q1 or Q2, the run says so and re-enters at level 2
  rather than descending into low-value work to stay busy. That re-entry has not been
  performed: every selection so far consulted the task-level census, never the arc
  ranking. This task performs it across every arc, not only ewcr-governed-delivery,
  and determines whether stop condition 3 - a Sovereign question blocks every remaining
  eligible path - has actually fired or is merely assumed. It also exercises the control
  branch T-779 added, which became reachable only when T-779 itself completed and
  left the high-value executable set empty: a branch that has never executed is a
  branch nobody has tested, and asserting it renders correctly without running it
  would be exactly the claim-without-check the mandate forbids.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [governance, selection, arc]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T20:39:28Z
last_update: 2026-09-21T20:43:53Z
date_finished: 2026-09-21T20:43:53Z
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
  - ts: '2026-09-21T20:40:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
---

# T-780: Re-enter selection at arc level: does any arc hold eligible Q1/Q2 work, or has this run reached its third stop condition?

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Arc ranking consulted for the first time in this run — and it is incomplete.**
      `fw bvp arcs` returns TWO arcs: arc-001 `designer-authoring-surface` (BVP 112) and
      arc-003 (88). Three arcs exist on disk and **all three are `status: in-progress`**. The
      absent one is **arc-002 `ewcr-governed-delivery`** — the arc this project has *focused*,
      holder of the three Arc-0 exit clauses that gate governed delivery.

      **Cause traced, not guessed.** Arc BVP is `derived-proposed`, a rollup over constituent
      tasks. arc-002 has exactly two non-completed tasks, T-681 and T-732; neither appears in
      `fw bvp --include-proposed` at all, because both carry `blast_radius: absent` → cost `-`
      → excluded. With no rankable constituents the rollup has nothing to derive from and the
      arc is dropped **silently** — the output does not say "one arc could not be ranked", it
      shows two arcs and looks complete.

      Recorded as `escalation_arc_level` on **G-076**, not as a new gap: same root cause, a
      second level. Filing it separately would make the register count one defect twice.

- [x] **Control branch exercised LIVE, output quoted rather than asserted.** It became
      reachable only when T-779 completed and emptied the high-value executable set:

      ```
      Every executable task falls outside hv-lc and hv-hc.
      AND 1 high-value task(s) would be executable but record their own
      repeated failure, so the mandate's twice-failed rule bars them: ['T-745']
      -> no legal move, and NOT because the backlog is gated upstream:
         the run has already spent its two attempts on that task.
      ```

- [x] **Stop condition 3 HAS fired, and here is the enumeration rather than the assertion.**
      Every remaining path, and why each is closed:

      | path | state | why closed |
      |---|---|---|
      | hv quadrants, task level | 35 tasks, **0 agent-executable** | `owner: human` (majority), `ac-blocked`, `placeholder` |
      | T-745, the one hv candidate | `exhausted` | failed its AC twice; the mandate bars a third attempt |
      | executable but low-value | **19 tasks** | the mandate: *"Low-value tasks are out of scope for this run regardless of how cheap they are"* |
      | arc level | 3 in-progress, 2 rankable | descending into arc-001/arc-003 changes nothing: the census is arc-agnostic and already reports 0 hv-executable across ALL tasks |
      | 92 unquadranted | 41 work-completed (excluded by design) + 51 live | invisible by the T-542 decline-to-rank design; making them visible needs `components:` declared, which is a scope decision — G-076(c) |

      **The blocking Sovereign question is G-076**, and it closes every path at once: the value
      half of the ranking is unconfirmed, and the cost half declines to rank 51 live tasks and
      one whole arc.

      **One honest inconsistency, stated rather than smoothed over.** I *did* declare
      `components:` on T-779 myself this run, which is the same act I am now calling reserved
      to the operator. The distinction I am drawing — and the operator may reject it — is that
      T-779 was a task I authored in this run, where `components:` is the author's own
      declaration of what they are about to edit, and I recorded the before/after quadrant
      move so it is auditable. Declaring it across 51 tasks I did not author would be deciding
      the scope of work someone else specified. That is a real difference, but it is a line I
      drew, not one the framework drew for me.

- [x] **Filed as OBS-369**, where a triage reader meets it, rather than left in a completed
      task's prose: `fw bvp estimate-cost all --dry-run` reports every task "skipped" whether
      or not work is pending (777 skipped / 0 wrote, against a real run of 214 wrote), while
      the per-task dry-run reports correctly. Advisory severity — it misleads a reader, it
      does not corrupt state.

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
         1. Run `bin/fw reviewer T-780`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-780 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

grep -q 'OBS-369' .context/inbox.yaml
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml')); c=d['concerns'] if isinstance(d,dict) else d; g=[x for x in c if isinstance(x,dict) and x.get('id')=='G-076'][0]; assert 'escalation_arc_level' in g and 'evidence' in g"
python3 tools/_t777-selection-eligibility-census.py --self-test 2>&1 | grep -q "11 passed, 0 failed"
python3 tools/_t777-selection-eligibility-census.py 2>/dev/null | grep -q "NOT because the backlog is gated upstream"
python3 -c "import glob,sys; n=len(glob.glob('.context/arcs/*.yaml')); sys.exit(0 if n>=3 else 1)"

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
     fw inception decide T-780 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T20:39:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-780-re-enter-selection-at-arc-level-does-any.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-29ec44a0
- **Timestamp:** 2026-09-21T20:44:14Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 3
     - evidence: `python3 tools/_t777-selection-eligibility-census.py --self-test 2>&1 | grep -q "11 passed, 0 failed"`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 4
     - evidence: `python3 tools/_t777-selection-eligibility-census.py 2>/dev/null | grep -q "NOT because the backlog is gated upstream"`

### 2026-09-21T20:43:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
