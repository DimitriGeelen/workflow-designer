---
id: T-778
name: "Quadrant-ordered selection runs on unconfirmed agent self-estimates, and 46
  tasks are invisible to it for want of a cost proposal"
description: >
  The autonomous mandate selects work by BVP quadrant: Q1 to exhaustion, then Q2,
  low-value parked. That ordering is only as sound as the scores under it. Measured
  at run start: 0 of 149 active tasks carry a confirmed bvp_scores:; 148 carry an
  agent-written bvp_scores_proposed:; 103 carry cost_estimate_proposed:. The quadrant
  filter needs cost, so the 46 without one render as '-' and no quadrant filter matches
  them - they are not low-value, they are unmeasured, and selection cannot see them.
  This task closes the measurable half of that gap with the agent-permissible verb
  (fw bvp estimate-cost, explicitly NOT sovereignty-bearing, writes cost_estimate_proposed:
  only) and re-runs the T-777 census over the completed map, so that 'no high-value
  task is agent-executable' is either confirmed across the whole backlog or refuted.
  The half that CANNOT be closed by an agent is recorded as a Sovereign question rather
  than decided: confirming a score is fw bvp confirm --i-am-human, so an agent that
  selects by quadrant is ranking its own work by its own estimate of that work's value.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bvp, governance, selection]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T20:23:00Z
last_update: '2026-09-21T20:24:53Z'
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
  - ts: '2026-09-21T20:23:44Z'
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
cost_estimate_proposed:
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-778: Quadrant-ordered selection runs on unconfirmed agent self-estimates, and 46 tasks are invisible to it for want of a cost proposal

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **46 -> 0, via the agent-permissible verb only.** `fw bvp estimate-cost all` wrote
      **214** cost proposals. Active tasks lacking `cost_estimate_proposed:`: **46 before,
      0 after**. The verb is documented "advisory, NOT sovereignty-bearing" and writes
      `cost_estimate_proposed:` only. No `cost_estimate:`, no `bvp_scores:`, no
      `--i-am-human` was passed — guarded by a standing leg in `## Verification`.

      **The estimator IS the bvp-estimator worker.** `fw bvp estimate-cost` dispatches to
      `agents/termlink/bvp-estimator/estimator.py`. The mandate's instruction to dispatch
      rather than score inline is therefore satisfied by the verb; only the live TermLink
      *session* is absent (`termlink_discover` returns 15 sessions, none an estimator, none
      belonging to this project). Recorded rather than claimed as "TermLink unavailable".

- [x] **Verdict recorded as a number, and it FLIPPED.** T-777 census, same tool, before and
      after the sweep:

      | | before | after |
      |---|---|---|
      | placed in a high-value quadrant | 31 | 35 |
      | of those, agent-executable | **0** | **1 — T-745** |
      | unquadranted | 105 of 149 | 92 of 150 |

      The census's own control line changed from *"quadrant-ordered autonomous selection has
      no legal move"* to *"the blocking claim is FALSE as of this run."* So the zero carried
      into this run was **an artefact of incomplete measurement**, not a property of the
      backlog — which is exactly what this task existed to find out.

- [x] **Negative control passes, and the moved task is the decisive one.** Four tasks were
      unquadranted before the sweep and carry an `hv-*` quadrant after it: **T-723, T-745,
      T-747, T-748**. T-745 — the task that flips the verdict — is among them, so the re-run
      demonstrably could have returned its previous answer and did not. A sweep that moved
      nothing would have been indistinguishable from one that ran and found nothing to do.

      **Related control, on the sweep's own preview:** `estimate-cost all --dry-run` reported
      `777 tasks: 0 wrote, 777 skipped` while the real run wrote 214. The dry-run summary is
      therefore identical whether or not there is work to do — it cannot preview its own
      effect. Recorded as an observation, not filed as a gap: it misleads a reader, it does
      not corrupt state.

- [x] **Filed as G-076, surfaced and not resolved.** Two mechanisms, one root cause — the
      quadrant map is not an operator-grounded artefact — so one register entry rather than
      two, per the G-075 lesson that per-instance filing manufactures gaps from one defect.

      **(1)** 0 of 149 tasks carry a confirmed `bvp_scores:`; 148 carry an agent-written
      proposal. Selection consults `--include-proposed`, so every hv label governing "work
      this first" is the agent's estimate of the value of the agent's own work. `fw bvp
      confirm` is §ACD-gated, so no amount of agent effort closes this.

      **(2)** 45 of 103 ranked live tasks render `QUAD -` and are invisible to every quadrant
      filter. **This half is correct behaviour and was nearly filed as a defect.**
      `score_blast_radius` (estimator.py:2744) returns None rather than a blind 0, because a
      blind 0 on the dominant F8 term made unmeasured tasks look *cheapest* and an HV/LC
      filter then promoted them — the defect T-2189/T-542 closed. Its docstring: *"Declining
      to rank is honest; ranking it cheapest is not."*

      The consequence is the finding: visibility to autonomous selection turns on whether a
      task's prose happens to name paths that exist in the tree. Measured pair, both with
      `components: []` — T-344 names four real paths -> blast_radius 5 -> hv-hc -> selectable;
      T-241 names none -> absent -> `-` -> invisible. Neither number reflects a judgement
      about the work.

      G-076's closure condition requires movement in a demonstrated direction **and** that a
      task with genuinely no cost signal still declines to rank — so that a "fix" reinstating
      a default blast_radius cannot satisfy it by re-opening T-542.

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
         1. Run `bin/fw reviewer T-778`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-778 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml')); c=d['concerns'] if isinstance(d,dict) else d; assert any(x.get('id')=='G-076' for x in c if isinstance(x,dict)), 'G-076 missing'"
python3 -c "import glob,sys; bad=[f for f in glob.glob('.tasks/active/T-*.md') if 'cost_estimate_proposed:' not in open(f,encoding='utf-8').read()]; sys.exit(1 if bad else 0)"
! grep -rlE '^bvp_scores:' .tasks/active/
! grep -rlE '^cost_estimate:' .tasks/active/
python3 tools/_t777-selection-eligibility-census.py > /dev/null 2>&1; test $? -le 2

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
     fw inception decide T-778 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T20:23:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-778-quadrant-ordered-selection-runs-on-uncon.md
- **Context:** Initial task creation
