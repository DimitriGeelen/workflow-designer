---
id: T-723
name: "RA-027: FAIL D2 human review queue has 12 tasks waiting over 30 days"
description: >
  Audit FAIL cycle 1 2026-09-16: the only failure on the board. 10 await judgement
  and 2 are signed off awaiting only the status flip. 22 more wait over 14 days. Human
  ACs are the operator's alone to tick.

status: started-work
workflow_type: build
owner: human
horizon: now
tags: [arc-003, audit-remediation, RA-027]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:26:05Z
last_update: 2026-09-20T18:20:20Z
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
  - ts: '2026-09-16T13:30:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 4
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=4
      (body:framework-level-ux); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-723: RA-027: FAIL D2 human review queue has 12 tasks waiting over 30 days

## Context

**Finding RA-027** - cycle 1, 2026-09-16. Source: fw audit. Severity: FAIL.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[FAIL] D2: Human review queue - 12 task(s) waiting >30d: 10 awaiting judgement: T-233(32d) T-308(48d) T-310(48d) T-325(45d) T-340(32d) T-351(44d) T-353(44d) T-368(39d) T-410(38d) T-449(35d); 2 signed off, awaiting only the status flip: T-093(73d) T-178(67d); 22 waiting >14d: T-392(20d) T-432(25d) T-433(25d) T-537(19d) T-540(19d) T-565(20d) T-579(22d) T-586(19d) T-588(20d) T-589(21d) T-590(21d) T-592(21d) T-593(20d) T-596(20d) T-597(20d) T-600(20d) T-601(20d) T-606(20d) T-608(20d) T-609(19d) T-643(16d) T-647(16d)
       Evidence: Tasks may be forgotten
       Mitigation: Review with: fw task verify (lists unchecked Human ACs). The signed-off ones need no review at all - close them: fw task update T-XXX --status work-completed
```

**The invariant that is not held:**

The only FAIL on the board. A Human AC is a verification step that catches real problems; the invariant is that it gets performed, not merely recorded. 34 tasks are waiting, the oldest for 73 days. At that latency the Human AC has stopped being a gate and become a parking space - the deliverable ships or does not ship without it either way. Two of the twelve are already signed off and need no review at all, which means part of this FAIL is not a review backlog but an unflipped status.

**Root-cause siblings:** T-708 (RA-012), T-724 (RA-028), T-727 (RA-031)

**Operator action / sovereignty boundary:**
Copy-pasteable triage view: cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task verify --compact --by-age

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] D2 reports no task waiting over 30 days, or every remaining one is individually justified
      — **justified, not drained.** `docs/reports/T-723-review-queue-residue.md`, generated by
      `tools/_t723-review-queue-residue.py --write`, carries all 38 queue rows with a per-row
      reason; the 10 over 30 days are each a named operator decision quoted from the task's own
      unticked Human AC (T-308 neutral-glyph reading, T-310 reconciliation framing, T-325 the two
      carriers §1 does not classify, T-351 the six pre-existing orphans, T-353 may an agent edit
      `## Verification` in `completed/`, T-368 cut 0.9.0, T-410 the history rewrite, T-449 which
      "pair-draft" definition, T-233 ghost-entry legibility, T-340 DI repair semantics). `--check`
      exits 0 only when every >30d row carries a reason, and is negative-controlled: a judgement
      row with no Human AC text yields an empty reason and fails the check.
      The probe reproduces the control's own numbers independently — 10 over 30d and 23 over 14d,
      the same IDs audit.sh D2 names.
- [x] The 2 signed-off tasks (T-093, T-178) are closed - this is separable from the review backlog and does not require judgement
      — closed via `fw task archive-eligible` (the remedy D2's own message names). Both had every
      criterion ticked, Agent and Human (7/7 and 6/6). Verified on both halves: absent from
      `.tasks/active/`, present in `.tasks/completed/` — so a deletion cannot pass as an archive.
      No skip or force flag was used; `archive-eligible` re-runs the partial-complete recheck and
      takes neither.
      **Confirmed by the control, not by this task's probe:** `fw audit --section discovery` now
      reads `D2: Human review queue — 10 task(s) waiting >30d: 10 awaiting judgement: ...` — down
      from 12, and the `; N signed off, awaiting only the status flip:` clause is gone from the
      message entirely, because `d2_fail_flip` is now 0. The FAIL that remains is the ten real
      decisions, which are the operator's.
- [x] The count of tasks awaiting genuine judgement is stated separately from the count awaiting only a status flip, so the two are never again reported as one number
      — **already held when this task was opened; the credit is T-656's, not this task's.**
      `audit.sh` builds `d2_fail`/`d2_fail_flip` as separate counters with separate detail lists
      and composes the remedy per group (audit.sh:4118-4195); `active-task-scan.py` Loop 10 carries
      the `unticked` field that makes the split possible. Ticked on the evidence that the state
      holds, with a grep leg so a regression re-opens it.
      One sharpening added here: the control counts unticked boxes across the WHOLE AC section, so
      a task still owing AGENT work would be indistinguishable from one owing a human decision.
      The probe splits Agent from Human and reports `awaiting-agent-work` as a third kind. Measured
      today it is **0** — P-010 held, and the conflation is latent rather than live. It is kept as a
      guard because a `--force` completion would land there.

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
         1. Run `bin/fw reviewer T-723`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-723 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# AC1 — every >30d row in the queue carries a named reason. Exits 0 only when none is missing.
python3 tools/_t723-review-queue-residue.py --check

# AC2 — T-093/T-178 are out of active/ AND in completed/. Both halves, so a delete cannot pass as an archive.
test "$(ls .tasks/active/ | grep -cE '^T-(093|178)-')" = "0"
test "$(ls .tasks/completed/ | grep -cE '^T-(093|178)-')" = "2"

# AC2 durability — the probe independently sees zero signed-off-flip rows left in the queue.
python3 tools/_t723-review-queue-residue.py > /tmp/.t723-queue 2>&1 && grep -qE "signed-off-flip +0" /tmp/.t723-queue

# AC3 — the control itself still reports the two kinds under separate labels (T-656).
grep -q "signed off, awaiting only the status flip" .agentic-framework/agents/audit/audit.sh

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
     fw inception decide T-723 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:26:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-723-ra-027-fail-d2-human-review-queue-has-12.md
- **Context:** Initial task creation

### 2026-09-20T18:07:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
