---
id: T-696
name: "T-624 chose a template warning as its prevention and twelve days later the number has not moved: a comment is not a gate"
description: >
  RETARGETED 2026-09-10. Filed as a voi_score repair, which was a DUPLICATE of
  T-624/T-625 — they found the tie, the abstention framing, the estimator site and
  the missing _proposed: lane, and shipped tools/_t624-voi-provenance.py. What is
  new is the RECURRENCE: T-624 measured 38 of 41 inceptions at the template default
  on 2026-08-29 and chose an in-template warning as prevention; on 2026-09-10 the
  figure is 12 of 13 active (92%), and T-624's own tool reports 40 of 43 on the cost
  axis. The warning is emphatic, correct, and sits directly above the field. It has
  changed nothing measurable. This task is about that: prevention that cannot fail
  is not prevention. Original (duplicate) description follows.

  Measured under T-694. The task template ships voi_score 0.5 pre-filled; 12 of 13 active inceptions still carry it with the comment attached. int(round(0.5*5))=2, and an absent voi_score also returns 2 via the grandfathered path, so 'nobody assessed this' and 'judged exactly mid' are indistinguishable. All 12 land in hv-lc, the quadrant a work-Q1-first rule drains before any measured high-value build task. Neither voi_score nor target_blast_radius has a _proposed lane, so the estimator cannot assess the one task type whose purpose is deciding what to build.

status: captured
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
created: 2026-09-10T05:45:00Z
last_update: 2026-09-10T05:45:00Z
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

# T-696: T-624 chose a template warning as its prevention and twelve days later the number has not moved: a comment is not a gate

## Context

**Filed as a duplicate and retargeted in the same session.** As originally written this
task repeated T-624 and T-625, which had already found the inception tie, named
`_score_inception_voi`, framed 0.5 as an *abstention printed as a confident 126*, stated
the missing `_proposed:` lane, and shipped `tools/_t624-voi-provenance.py`. All of that
is documented in `.tasks/templates/inception.md:26-35`, four lines above the field. I did
not check before filing. The duplicate ACs are struck through below rather than deleted.

What survives is one measurement T-624 could not have made, because it needed time to
pass:

| | T-624, 2026-08-29 | here, 2026-09-10 |
|---|---|---|
| inceptions at template-default `voi_score` | 38 of 41 (93%) | 12 of 13 active (92%) |
| at template-default `target_blast_radius` | 38 of 41 | 40 of 43 (93%), T-624's own tool |

T-624 diagnosed correctly and chose **an in-template warning** as its prevention. Twelve
days on, the proportion is unchanged. The warning is emphatic (`⚠ CHANGE THIS`), correct,
specific, and physically adjacent to the field it governs — and it has moved nothing.

**This task is about that, and only that: a comment is not a gate.** It is FP-011
(capture-without-application) arriving on a *mitigation* rather than on a learning, and
it is a Level C/D question about how this project selects preventions — not a question
about `voi_score`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] ~~**The collision is measured, and the two colliding states are named.** Done under
      T-694: `estimator.py:2441-2450` returns 2 for an absent `voi_score` (grandfathered)
      and `int(round(0.5*5)) = 2` for the template's pre-filled 0.5, so the output cannot
      separate *unassessed* from *judged mid*. Measured population: 12 of 13 active
      inceptions still carry the value **and** its explanatory comment; T-155 carries no
      `voi_score` at all and scores identically. `docs/reports/T-694-bvp-distinguishability.md` §2.~~ **DUPLICATE of T-624.**

- [x] ~~**The absence of an agent lane is checked, not assumed.** `bvp_scores_proposed` and
      `cost_estimate_proposed` exist; there is no `voi_score_proposed` or
      `target_blast_radius_proposed` anywhere in the task template or `lib/bvp.sh`. So the
      estimator has no permitted way to assess an inception, and the field is operator-only
      by CLAUDE.md's own sovereignty split.~~ **DUPLICATE of T-625**, which states it verbatim.

- [ ] **The recurrence is measured by a re-runnable command, not by comparing two prose
      reports.** `tools/_t624-voi-provenance.py` already reports the population; a thin
      wrapper or flag records the figure with its date so the NEXT check is a diff against
      a recorded number rather than someone re-reading T-624. Without this the twelve-day
      observation decays into another prose claim.

- [ ] **BLOCKED on the Human AC** — whatever prevention is chosen, it is watched FAILING
      before it is relied on. A prevention that has never been observed to refuse anything
      is the same class of artefact as the warning it replaces.

### Human

- [ ] [REVIEW] **Rule on the prevention, not the field: A · B · C · D · no repair**

      T-624 already picked one prevention (a template warning) and it did not work. The
      menu below is inherited from that unfinished repair; what is being asked now is
      which of them is a **gate** rather than another notice.


      **Why this is not the agent's call:** `voi_score` is your field, with no `_proposed:`
      lane by design. Any repair I chose would be me deciding, structurally, how much the
      questions I have not asked are worth — and this run's selection rule works Q1 to
      exhaustion, so it would be me deciding what I work on next.

      **A — stop shipping `voi_score` pre-filled.** Template emits it empty or commented.
      Absence then means absence. Existing 12 keep the stale 0.5 until you set them.

      **B — rank unassessed inceptions LAST rather than mid.** Make the grandfathered path
      return 0, not 2. Unassessed work stops outranking measured work. Sharp, and it will
      bury genuinely urgent inceptions until you score them.

      **C — give the two inception inputs a `_proposed:` lane** so the estimator may put a
      number in front of you to accept or overrule, the way it already does for the D-drivers
      and cost. Most consistent with the rest of the model; widens what the estimator may
      touch, which is a sovereignty question in its own right.

      **D — make unassessed a distinct state, not a score.** `fw bvp` reports these tasks in
      an `unscored` bucket outside the quadrant grid. Nothing is ranked on an unset field
      and nothing is buried. Costs a change to how the quadrant view is read.

      **No repair:** 0.5-as-mid is a defensible prior, and the tie only bites under a strict
      Q1-first rule. If you take this option, the tie is documented rather than fixed, and a
      future autonomous run should be told to treat hv-lc inceptions as unranked.

      **Steps:** 1. Read `docs/reports/T-694-bvp-distinguishability.md` §2 and §3.
      2. Reply with A, B, C, D, or no-repair.
      **Expected:** one letter, recorded in this task's `## Decision`.
      **If not:** the two Agent ACs above stay BLOCKED and this task stays parked.

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
         1. Run `bin/fw reviewer T-696`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-696 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
     fw inception decide T-696 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-10T05:45:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-696-a-pre-filled-voiscore-makes-an-unassesse.md
- **Context:** Initial task creation
