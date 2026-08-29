---
id: T-631
name: "Is the Tier-0 approval command reachable while Tier 0 is blocking, or does the gate refuse its own approval route"
description: >
  Is the Tier-0 approval command reachable while Tier 0 is blocking, or does the gate refuse its own approval route

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
created: 2026-08-29T15:16:52Z
last_update: 2026-08-29T15:21:09Z
date_finished: 2026-08-29T15:21:09Z
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

# T-631: Is the Tier-0 approval command reachable while Tier 0 is blocking, or does the gate refuse its own approval route

## Context

Applying the sweep rule this session's own rail post (@779) told two peers to adopt:
when you fix a remedy, sweep the population rather than stopping at the reported
instance. T-628/T-629 swept `check-active-task.sh` — all three of its gates are now
probed. The remaining population is the other eight registered PreToolUse hooks, and
one of them matters more than the rest.

`check-tier0.sh` is matched on `Bash` and blocks consequential commands. Its block
message prints `fw tier0 approve` as the route forward. That command is itself a Bash
call, and therefore passes through the same hook that just blocked. If Tier 0 refuses
its own approval command, the OPERATOR — not the agent — is the one wedged, and they are
wedged at the exact moment the framework is asking them to exercise sovereignty. That is
a strictly worse instance of the class than G-020, where the blocked party was an agent
holding a second write surface.

This task asks one question and answers it with a measurement. It does not approve
anything: `fw tier0 approve` is the operator's act (CLAUDE.md §Autonomous Mode
Boundaries), and reachability is measured against fixture state in a throwaway sandbox,
never by approving a real pending command in this tree.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Measured from inside a firing Tier-0 block: is `fw tier0 approve` refused by the
      same hook, or does it pass? Stated with the hook's own output as evidence
- [x] Every command the Tier-0 block message names as a route forward is probed, not
      just the first one
- [x] If any is unreachable it is made reachable or the wording is corrected — and if
      all are reachable, that negative result is recorded with the evidence that makes
      it a measurement rather than an assumption
- [x] The probe never approves a real pending Tier-0 command: fixture state only, in a
      sandbox, asserted on the hook's output
- [x] `tools/_t631-tier0-approval-reachable.sh` guards its teeth with a reachability leg
      and stages any mutant beside the original (PL-267)
- [x] The other seven registered PreToolUse hooks are enumerated with a one-line verdict
      each on whether they print a command-shaped remedy — so the population is closed,
      not sampled

**Result: clean negative, measured.** `fw tier0 approve` is NOT refused — control fires
(TIER 0 BLOCK banner on `git push --force`), remedy passes rc=0. The population is closed
rather than sampled: of nine registered PreToolUse hooks, four are Bash-matched, and of
those only check-tier0 and check-active-task print Bash-shaped remedies. Both are now
probed (this file; T-386/T-628/T-629). 6/6 legs, mutation-proven.
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

bash tools/_t631-tier0-approval-reachable.sh
bash tools/_t630-p011-stdin-swallow.sh
bash tools/_t629-g067-remedy-reachable.sh
bash tools/_t628-g020-remedy-reachable.sh
bash tools/_t386-drift-remedy-reachable.sh

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

Not a bug-class task — the measurement returned a negative. Recorded here because a
negative that is not written down gets re-measured, or worse, assumed the other way.

**What was asked:** does Tier 0 refuse `fw tier0 approve`, the route its own block message
prints? **Answer:** no. **Evidence:** control `git push --force origin master` → TIER 0
BLOCK banner, rc 2. Remedy `fw tier0 approve` → rc 0, no banner. Both against a throwaway
sandbox root; nothing in this tree was approved.

**The reason is not the one assumed, and that matters.** The remedy passes because a bash
keyword pre-filter `exit 0`s before the Python PATTERNS list is consulted — not because no
pattern matches it. The pre-filter already screens some `fw` verbs (`fw .*--force`,
`fw .*inception .*decide`), so `fw` is in its scope, and one more clause there would start
refusing the operator's approval route. The prober now guards exactly that.

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

### 2026-08-29 — two clauses the remedy-reachability rule was missing

999-AEF's rule (@775) is "run the remedy verbatim while the gate is firing". 577 added
(@776) "and through the same surface the gate is restricting". Working this one produced
two more, and both are about NOT doing the work rather than doing it:

**AND BY THE PARTY THE REMEDY ADDRESSES.** `fw tier0 approve` is the operator's act, and
an operator types it in their own terminal where PreToolUse hooks do not run at all. For
the party it addresses, this remedy is reachable by construction. Measuring it against
the agent's surface would have answered a question nobody asked — and would have produced
a "finding" that no operator could ever have experienced.

**A REMEDY IS ONLY AT RISK WHEN THE HOOK THAT PRINTS IT MATCHES THE TOOL THE REMEDY
NEEDS.** A Write-matched hook prescribing a Bash command cannot refuse it; the hook never
sees the call. This is what makes the population closeable instead of a nine-hook slog:
nine registered → four Bash-matched → two printing Bash-shaped remedies, both already
probed. The check re-derives this from `.claude/settings.json` on every run, so a tenth
hook widens it rather than escaping it.

### 2026-08-29 — a mutation aimed at the wrong layer produces a green leg

check-tier0 has two independent classifiers: a bash keyword pre-filter, then a Python
PATTERNS list. My first teeth added a PATTERNS entry for the remedy and the leg stayed
green — correctly, because the pre-filter had already released the command and PATTERNS
was never reached. The mutation was applied, the file changed, nothing moved.

A MUTATION MUST TARGET THE LAYER THAT ACTUALLY DECIDES FOR THE INPUT IN QUESTION. This
one survived only because the leg asserts the blocked banner rather than asserting that
the mutation was applied — an "assert the mutation took effect" formulation would have
gone green and certified nothing. Third instance this session of the same family, after
T-629's partial mutation and T-630's model that omitted the step creating the failure
mode.

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

### 2026-08-29T15:16:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-631-is-the-tier-0-approval-command-reachable.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c843ed5d
- **Timestamp:** 2026-08-29T15:21:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T15:21:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
