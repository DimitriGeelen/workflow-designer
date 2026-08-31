---
id: T-661
name: "Probers pin an exact substitution count where the invariant is a floor"
description: >
  Probers pin an exact substitution count where the invariant is a floor

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T19:36:43Z
last_update: 2026-08-31T19:44:58Z
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

# T-661: Probers pin an exact substitution count where the invariant is a floor

## Context

999-AEF at rail @897 sent back a defect of a class we have already named twice and
committed anyway. Their `tests/unit/ac_counter_sed_range_one_line_comment.bats` asserts
`grep -c` of the tolerant comment-strip regex `== 2` in update-task.sh. They now have 3
call sites, all correct — so their suite is RED for having done the right thing, and has
been for a while because their daily audit runs tests/lint and not tests/unit. Their
words: "an EQUALITY where the invariant is a FLOOR."

That exact assertion is NOT in our tree (measured: we carry no `tests/unit/` at all, and
2 call sites at update-task.sh:94 and :1614). But the shape is ours too. Our mutation
probers all assert `MUTATED -ne 1` on a `grep -c` of the substituted marker. That count
is a FLOOR — "the mutation landed at least once" is what the leg needs — pinned as an
EQUALITY. Add a second correct call site to any mutated subject and the prober reports
"MUTATION FAILED" for a change that made the teeth stronger.

We already hold PL-061 ("verification lines must assert failure-SHAPE, never pin suite
totals") from T-305 and PL-075 ("witnesses over counts") from T-330. Both were surfaced
by `fw work-on` when this task was created. The learnings existed and did not reach the
code, which is the part worth fixing.

## Acceptance Criteria

### Agent
- [x] Every `tools/_t*.sh` prober is measured for the exact-count-on-substitution shape,
      and the count of affected files is recorded here (not estimated)
      → **89 prober files scanned. 7 carried the shape**, all converted:
      `_t650` (`-ne 2`), `_t654` (`-ne 1`), `_t656` (`-ne 2`), `_t657`, `_t658`, `_t659`,
      `_t660` (all `-ne 1`). One further candidate, `_t634:157` (`NSITE -ne 1`),
      was inspected and **deliberately left as an equality** — see Decisions.
- [x] Each affected assertion is changed from an equality to a floor (`-lt 1` / `-eq 0`),
      preserving the "the mutation demonstrably landed" guarantee the leg depends on —
      the floor must still fail when the mutation lands ZERO times
      → Landed as something stronger than a floor: `assert_mutation_complete` asks
      whether the ORIGINAL form is gone (`before >= 1` and `after == 0`), which has no
      upper bound and additionally catches a marker the subject already contained.
- [x] A prober proves the repair discriminates: a subject with TWO correct occurrences of
      the mutated marker passes under the fixed form and fails under the old equality.
      → `tools/_t661-mutation-count-is-a-floor.sh`, 7 legs. Leg 2 is the two-site case;
      leg 3 is its witness, asserting the retired `-ne 1` form would have read 2 there.
- [x] All previously-green probers still pass after the change (no leg silently loosened
      into one that cannot fail — each mutation leg still reports its teeth result)
      → 7/7 green at identical leg counts (16/7/8/7/11/6/9). Loosening was tested for
      directly: breaking each anchor in place turns three of them red (8/1, 6/1, 7/1)
      with a STALE ANCHOR diagnosis, so the legs can still fail.
- [x] AEF's specific question is answered by measurement on our tree and the answer is
      sent back on the rail with the numbers, not a "checked, we're fine"
      → Their bats file is absent here (we carry no `tests/unit/`) and we have 2 tolerant
      comment-strip sites, not 3 — so that assertion cannot bite us. The class does:
      7 instances of our own. Rail reply posted.
- [x] PL-061's scope is widened to name mutation-substitution counts, since the existing
      wording says "suite totals" and that is why it did not reach these files
      → **The premise was wrong and the AC is closed by correcting it, not by doing it.**
      PL-061 already reads "exact-count source greps (use -ge floor)" — it named this
      defect precisely, in 2026-07, and `fw work-on` printed it to me when this very task
      was created. Widening it would have been busywork against a learning that was
      already right. What was missing is a place where the wrong form is unreachable.
      Captured as **PL-303** and built as `tools/lib/mutation-assert.sh`.

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
         1. Run `bin/fw reviewer T-661`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-661 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
bash tools/_t661-mutation-count-is-a-floor.sh
bash tools/_t657-vendor-divergence-must-reach-an-audit-line.sh
bash tools/_t658-p011-must-distinguish-killed-from-failed.sh
bash tools/_t659-retention-sweep-must-not-be-agent-staged.sh
bash tools/_t660-actionability-checker-must-have-teeth.sh
bash tools/_t656-review-queue-splits-judgement-from-the-status-flip.sh
bash tools/_t654-archiving-a-partial-complete-task-must-null-its-horizon.sh
# No prober may reintroduce the shape: an equality on a count of substituted markers.
# Asserts the failure SHAPE (zero occurrences of the broken form), not a total — which
# is the very lesson this task is about, so it must not be written the other way.
# The `[ "$` anchor is load-bearing: the first draft matched the bare words and flagged
# _t661's own witness leg, which NAMES the retired form inside a message string. Same
# false-positive class as T-660's house-style matcher — match the assertion, not the prose.
test 0 -eq "$(grep -lE '\[ "\$(MUTATED|REVERTED|SUBST)[A-Z_]*" -(ne|eq) [0-9]' tools/_t*.sh 2>/dev/null | wc -l)"

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

### 2026-08-31 — not every equality on a count is the defect

- **Chose:** Convert 7 probers; leave `_t634:157` (`NSITE -ne 1`) exactly as it is.
- **Why:** `_t634` counts CALL SITES of `run_verification_commands` in the subject and
  says "expected exactly 1 call site — the analysis covers only one". There, exactness
  IS the property: if a second site appeared, the leg's conclusion would cover half its
  subject and the equality going red is the correct outcome. That is the same
  single-writer invariant 999-AEF deliberately created in their own bug-1 fix at @897.
  The defect is not "an equality on a count"; it is an equality standing in for a
  property that has no upper bound. Blanket-converting would have destroyed a real
  guard while claiming to fix a class.
- **Rejected:** A sweep over every `-ne <n>` in tools/. It would have been faster,
  larger-looking, and would have removed the one assertion in the group that was right.

### 2026-08-31 — assert the original form is gone, not that the marker appeared

- **Chose:** `assert_mutation_complete <subject> <mutant> <original-pattern>`, checking
  `before >= 1 && after == 0`, rather than the minimal fix of `-ne 1` → `-lt 1`.
- **Why:** The floor alone still asks the wrong question. `grep -c 'if false; then'`
  cannot tell a landed mutation from an `if false; then` the subject already contained,
  so a subject that was never mutated can report a healthy count and certify teeth the
  prober does not have. "Zero occurrences of the pre-mutation form survive" answers the
  question the leg actually depends on, has no upper bound, and additionally names a
  STALE ANCHOR distinctly from a PARTIAL mutation.
- **Rejected:** Six bespoke in-place fixes. Six copies of a subtle assertion is the
  shape that produced both this bug and AEF's; one writer is the point.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-661 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T19:36:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-661-probers-pin-an-exact-substitution-count-.md
- **Context:** Initial task creation
