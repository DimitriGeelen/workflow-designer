---
id: T-801
name: "Make the SQ-2 ruling decision-ready: re-verify T-353's cited evidence and surface that its yes/no does not contain the narrow option"
description: >
  Make the SQ-2 ruling decision-ready: re-verify T-353's cited evidence and surface that its yes/no does not contain the narrow option

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
created: 2026-09-22T09:41:49Z
last_update: 2026-09-22T09:41:49Z
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

# T-801: Make the SQ-2 ruling decision-ready: re-verify T-353's cited evidence and surface that its yes/no does not contain the narrow option

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — every tool T-353's Human AC tells the operator to run is re-run first.** One of
      the two cited numbers was already stale: step 1 says "16/16" and the probe reported
      12+1 until T-787 repaired it (now 23/23). Sending the operator to run step 2 without
      checking it would repeat the defect I fixed this morning, one AC line below where I
      found it.
      Evidence: step 2 re-run — `_t353-convert.py` reports **19/19, DIVERGENT remaining 0**,
      so that citation is sound. Step 1's "16/16" is **stale** and is 23/23 after T-787.
      Step 3's artifact exists with the cited sections. The stale one is corrected in the
      options doc rather than left for the operator to trip over.
- [x] **AC2 — the mismatch between the AC's binary and the available rulings is surfaced.**
      The AC offers Yes (apply T-353's 23-line patch set) or No (nothing). **Neither is the
      narrow ruling** that would unblock `_t560` — permit appending sibling control legs when
      a teeth instrument requires it. A decision presented as a binary that excludes the
      recommended option is not decision-ready.
      Evidence: the options doc states the AC's binary contains neither the narrow ruling nor
      the population split, and quotes the AC's own escape hatch — *"if the question is not
      the right one to be asking, say so"* — as the sanctioned route to Option C.
- [x] **AC3 — the two populations are separated with counts.** T-353's 23 lines are inert
      (archived, never re-run). `_t560`'s 96 have a live consequence (a red teeth
      instrument). They can be ruled differently, and conflating them forces one answer onto
      two questions.
      Evidence: 23 archived lines with **no** consequence (archived blocks never re-run)
      against **110 of 127** `_t560` legs in `completed/` with a live one (a red instrument).
      127 - 17 = 110 > 78, so no agent-permitted action closes it.
      **AND THE DISCLOSURE:** 14 of the 127 are the agent's own, added this session, all now
      in `completed/`. Its "positive control on the same pattern" claim was **wrong** — the
      control used a related pattern, not the same string. Recorded as a learning and stated
      in the doc where the operator will read it, not buried.
- [x] **AC4 — paste-ready text is drafted for EVERY option, including the ones I do not
      recommend.** Drafting only the recommended wording is steering a sovereignty decision
      by making one answer easier to give than the others.
      Evidence: all three options carry a ruling-text block AND a "the cost, stated fairly"
      paragraph. B's cost names the thing that argues FOR acting (a permanently red check
      decays into ignored noise); C's cost names that narrow rules widen quietly and that it
      was proposed by the agent who caused 14 of the problem. The recommendation sits in §4,
      AFTER the drafts, so it does not colour them.
- [x] **AC5 — the `### Human` AC is not ticked, and that is asserted mechanically.** Drafting
      the text a human may choose to paste is not deciding. The unticked box stays unticked
      by this task, proven by a Verification leg rather than promised.
      Evidence: the AC at line 191 is still `- [ ]`. A Verification leg asserts it, so if this
      agent ever ticked it the leg goes red. The doc says outright that `### Human` ACs are
      the operator's alone and the agent will not tick it.

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
         1. Run `bin/fw reviewer T-801`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-801 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: the cited evidence reproduces (step 2 of the Human AC) ──────────────
out=$(timeout 300 python3 tools/_t353-convert.py 2>&1 || true); case "$out" in *"DIVERGENT remaining after conversion: 0"*) true;; *) false;; esac
test -f docs/reports/T-353-corpus-readiness.md

# ── AC5: THE HUMAN AC IS STILL UNTICKED. Goes red if the agent ever ticks it. ─
out=$(sed -n '191p' .tasks/active/T-353-prepare-the-corpus-for-the-p-011-errexit.md); case "$out" in "- [ ] "*) true;; *) false;; esac

# ── AC2/AC3/AC4: the doc carries all three options and the disclosure ────────
grep -q 'Option A — YES' docs/reports/T-801-sq2-ruling-options.md
grep -q 'Option B — NO' docs/reports/T-801-sq2-ruling-options.md
grep -q 'Option C — the narrow' docs/reports/T-801-sq2-ruling-options.md
grep -q 'Disclosure:' docs/reports/T-801-sq2-ruling-options.md
test "$(grep -c 'The cost, stated fairly' docs/reports/T-801-sq2-ruling-options.md)" -eq 3

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
     fw inception decide T-801 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T09:41:49Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-801-make-the-sq-2-ruling-decision-ready-re-v.md
- **Context:** Initial task creation
