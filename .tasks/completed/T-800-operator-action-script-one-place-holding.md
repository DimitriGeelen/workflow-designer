---
id: T-800
name: "Operator action script: one place holding the decisions only a human can make, with the long commands pre-written"
description: >
  Operator action script: one place holding the decisions only a human can make, with the long commands pre-written

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T09:32:26Z
last_update: 2026-09-22T09:35:54Z
date_finished: 2026-09-22T09:35:54Z
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

# T-800: Operator action script: one place holding the decisions only a human can make, with the long commands pre-written

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — listing is the default; nothing executes without being named.** Running the
      script bare must show what is pending and do nothing else. A script that acts on
      invocation is the wrong shape for a queue of Tier 0 and sovereignty actions, where the
      whole point is that a human chooses each one deliberately.
      Evidence: the `case` dispatches the empty argument to `list`, which prints and returns.
      Verified by running it bare — it listed both actions and the two judgement items and
      ran nothing.
- [x] **AC2 — each action states WHY it needs a human, not just what it runs.** A queue of
      opaque commands trains the operator to paste without reading, which is precisely the
      failure the gates exist to prevent. The reason belongs next to the command.
      Evidence: each action carries a `_WHY` block printed above its command. t788 says why
      it is Tier 0 and what it does to the record (rewrites the Decision block; the original
      GO survives in Updates). t353 says it is read-only and names the expected output, AND
      that the AC's own 16/16 citation decayed and is now 23/23.
- [x] **AC3 — the agent does not execute any listed action, and that is provable.** These are
      Tier 0 / sovereignty actions. Asserted by leaving the world unchanged: T-788 still
      reads `Decision: GO` after this task, which goes red if the agent ran its own script.
      Evidence: `grep -c '^\*\*Decision\*\*: GO'` on T-788 returns **1** after this task —
      the record is untouched. A Verification leg asserts it, so if this agent ever ran its
      own consequential action the leg goes red.
- [x] **AC4 — read-only actions are separated from consequential ones.** Running the T-353
      evidence probe and recording a sovereignty decision are not the same risk, and a list
      that presents them identically is misleading. The consequential ones must confirm
      before acting.
      Evidence: `t353-probe` runs immediately (measured: `probe: 23 passed, 0 failed`).
      `t788-redecide` demands the action id TYPED IN FULL — `y/N` is too easy to fat-finger
      for something that writes a sovereignty record. Measured: answering `yes` aborts with
      "nothing was run", and the T-788 record is unchanged.
- [x] **AC5 — the script is honest about what it cannot do.** Some pending items are not
      commands at all — SQ-2 needs a human to check a `### Human` AC, which is a judgement.
      The script must say so rather than pretending the queue is executable end to end.
      Evidence: a `NOT RUNNABLE FROM HERE` section names SQ-2 and IW-3 as judgement rather
      than commands, and says outright **"NEVER tick a ### Human AC on someone's behalf — not
      the agent's to do, and not this script's either."** It gives the file and line to edit
      and the arithmetic that turns on it (113 - 17 = 96 > 78), then stops.

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
         1. Run `bin/fw reviewer T-800`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-800 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: bare invocation lists and exits clean ───────────────────────────────
bash -n tools/operator-actions.sh
./tools/operator-actions.sh > /dev/null

# ── AC3: THE AGENT DID NOT DECIDE. T-788 still reads GO. ─────────────────────
grep -q '^\*\*Decision\*\*: GO' .tasks/completed/T-788-does-832-build-any-part-of-the-workflow-.md

# ── AC4: read-only action really runs; consequential one refuses a wrong word ─
# NOT the pipe-to-grep form. The abort path exits 1 BY DESIGN — that is the behaviour
# being asserted — and under P-011's pipefail a legitimate non-zero upstream kills the
# pipeline regardless of what grep found. Capture, then case-match: no pipe, and the
# script's own exit code is explicitly not the verdict.
out=$(./tools/operator-actions.sh t353-probe 2>&1 || true); case "$out" in *"probe: 23 passed, 0 failed"*) true;; *) false;; esac
out=$(echo wrong | ./tools/operator-actions.sh t788-redecide 2>&1 || true); case "$out" in *"nothing was run"*) true;; *) false;; esac

# ── AC5: the script refuses to pretend the queue is executable end to end ────
grep -qF "NEVER tick a ### Human AC on someone's behalf" tools/operator-actions.sh
grep -q 'NOT RUNNABLE FROM HERE' tools/operator-actions.sh

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
     fw inception decide T-800 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T09:32:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-800-operator-action-script-one-place-holding.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-010be57b
- **Timestamp:** 2026-09-22T09:35:57Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 50
     - evidence: `./tools/operator-actions.sh > /dev/null`

### 2026-09-22T09:35:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
