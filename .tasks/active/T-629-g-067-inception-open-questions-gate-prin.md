---
id: T-629
name: "G-067 inception open-questions gate prints three remedies that have never been probed for reachability"
description: >
  G-067 inception open-questions gate prints three remedies that have never been probed for reachability

status: started-work
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
created: 2026-08-29T15:06:32Z
last_update: 2026-08-29T15:06:32Z
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

# T-629: G-067 inception open-questions gate prints three remedies that have never been probed for reachability

## Context

The residual T-628 filed rather than assumed away. G-067 is the sibling gate ~25 lines
above G-020 in the same hook, and it prints THREE remedies that have never been run from
inside the state that prints them. Two of the three are task-file edits, which is the
exact shape T-628 proved unreachable from the shell: the `.tasks/*` exemption is a
FILE_PATH test, and a Bash call has no file path.

There is a second question here that T-628 could not ask, because answering it requires
being in a state T-628 was not in. G-020's remedy 2 converts a build task to an
inception. If that conversion lands the agent in a G-067 block whose own remedies are
also unreachable, then G-020's escape does not lead out — it leads one gate deeper. That
is worth measuring before anyone follows the advice we just made reachable.

Remedy 3 (`FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1`) is a Tier-2 bypass flag and is not
the agent's to use (CLAUDE.md §Autonomous Mode Boundaries). Its REACHABILITY is still
measurable without exercising it as a bypass: the probe asserts what the hook does with
the variable set in a throwaway sandbox, which is a statement about the gate, not an
authorisation taken in this tree.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each of G-067's three printed remedies is run verbatim from inside the firing
      state, through the surface the gate restricts, and the result recorded
- [x] The hand-off is measured: taking G-020's remedy 2 (build → inception) either
      leaves the agent unblocked, or lands in G-067 — and which one is stated with
      evidence rather than reasoned from the source
- [x] Any remedy found unreachable is either made reachable or its wording corrected to
      name the surface that works — no remedy is left stated as available when it is not
- [x] `tools/_t629-g067-remedy-reachable.sh` guards its teeth with a reachability leg
      (the T-628 lesson: a mutant that dies at an earlier gate is indistinguishable from
      one that reaches the gate and behaves correctly)
- [x] The prober stages its mutant beside the original, not in the sandbox — G-067 sits
      below the point where a relocated copy loses `find_task_file`
- [x] T-386 and the T-628 prober both still pass — three probers, one hook, no regression

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

# Each line's own exit code is the verdict — no chaining (T-352).
bash tools/_t629-g067-remedy-reachable.sh
bash tools/_t628-g020-remedy-reachable.sh
bash tools/_t386-drift-remedy-reachable.sh
bash -n .agentic-framework/agents/context/check-active-task.sh

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

**Symptom:** G-067 printed three remedies, none of which had ever been run from inside
the state that prints them. Two are task-file edits and every shell form of both is
refused; the block also printed a bare `Attempting to modify: ` with an empty target.

**Root cause:** Identical to T-628 and 25 lines away — the `.tasks/*` exemption is a
FILE_PATH test, and a Bash call has no file path, so the exemption has no expression on
one of the two surfaces the gate restricts.

**Why structurally allowed:** T-628 fixed the instance that a peer happened to report.
Nothing swept the file for siblings, so the identical defect sat in the gate immediately
above it. The class was known and the file was open; what was missing was the step from
"fix the reported instance" to "run the check on every gate in this file that prints a
remedy". Three now have probers; that is the whole population in this hook.

**Prevention:** `tools/_t629-g067-remedy-reachable.sh`, plus the answer to the question
T-628 could not ask — G-020's remedy 2 leads OUT, not deeper. A converted task carries no
`## Open Questions` section and G-067 fires only when that section exists. Asserted as a
leg rather than reasoned from source, because it stops being true the moment someone
makes the conversion template-aware.

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

### 2026-08-29 — a partial mutation under a whole-file assertion has no bite

The teeth leg went green on a mutant that still carried half the fix. The mutation
reverted remedy 1's wording only; remedy 2's line also contains "Edit/Write tool", so the
assertion kept matching and the leg certified nothing. It failed in the safe-looking
direction — the suite reported PASS — which is the shape that survives review.

The rule that falls out, and it is narrower and more useful than "mutation-test your
suite": A MUTATION MUST BE AT LEAST AS WIDE AS THE ASSERTION IT IS MEANT TO MOVE. Revert
the whole fix, or narrow the assertion to the single line the mutation touches. Doing
neither produces a teeth leg that is itself the vacuity it was added to prevent.

Same family as 577's `!`-inverted verification leg (@774 item 5) and 010's vacuous
`## Verification` (@772 item 5): in all three the instrument reports success while
measuring nothing, and in all three it was caught by looking at what the instrument would
print if it had no information at all.

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

### 2026-08-29T15:06:32Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-629-g-067-inception-open-questions-gate-prin.md
- **Context:** Initial task creation
