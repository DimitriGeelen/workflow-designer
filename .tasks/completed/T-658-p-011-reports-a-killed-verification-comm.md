---
id: T-658
name: "P-011 reports a killed verification command as a plain FAIL — 'did not finish' reads as 'your check is wrong'"
description: >
  P-011 reports a killed verification command as a plain FAIL — 'did not finish' reads as 'your check is wrong'

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t658-p011-must-distinguish-killed-from-failed.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T18:39:41Z
last_update: 2026-08-31T18:45:00Z
date_finished: 2026-08-31T18:45:00Z
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

# T-658: P-011 reports a killed verification command as a plain FAIL — 'did not finish' reads as 'your check is wrong'

## Context

OBS-332, part (b). The P-011 verification runner (`update-task.sh`, the loop at ~1272)
reports every non-zero exit identically: `FAIL: <cmd> (exit N)`. A command that RAN and
returned a verdict of "wrong" and a command that never finished at all are rendered in the
same words, so the operator reads "your check is wrong" when the truth is "your check did
not finish". Observed under T-651: a `fw audit` verification line returned on the first
invocation and hung on an immediate second until something external killed it at five
minutes; the gate called that a plain FAIL.

The exit code already carries the distinction and the runner discards it. `timeout(1)`
exits **124**; a process killed by signal N exits **128+N**, so **137** is SIGKILL and
**143** is SIGTERM. These are not failures the operator can act on by fixing their command.

Same missing-third-outcome shape as T-656 (a control that summarised two states needing
different actions into one) and OBS-329 (a surface that cannot distinguish "no verdict"
from "a verdict I cannot parse"). This one is the runner's own version of it.

Part (a) of OBS-332 — advising against whole-audit invocations in P-011 — is not a separate
task: its natural home is the remedy text this task adds to the timeout branch, where the
person who just hit it is actually reading.

**Explicitly out of scope:** imposing a timeout on verification commands. That is a
behaviour change that would kill legitimately long verifications (builds, suites) and needs
its own decision. This task classifies what already happens; it does not add a new way to
die.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The runner distinguishes at least three outcomes: PASS, FAIL (ran, returned
      non-zero), and DID-NOT-FINISH (exit 124, or 128+N signal death). The third is
      labelled in words that do not read as "your command is wrong".
- [x] The distinction survives into the **summary block** the operator actually sees on a
      blocked completion, not only in the per-line output — a per-line label that the
      final message flattens back into "N failed" has not fixed the reported defect.
- [x] A killed command with **no captured output** says so explicitly rather than printing
      an empty evidence block. Silence after a kill is the normal case, and an empty
      `head -5` is exactly what made the original incident unreadable.
- [x] The timeout/kill branch names the `fw audit` hazard from OBS-332(a): a whole-audit
      invocation inside P-011 makes one task's completion depend on every unrelated warning
      in the tree, and contends with the lock FDs the transition itself holds. It points at
      `--section <name>` as the supported form.
- [x] Exit-code classification is correct at the boundaries: 124 → timeout; 128 → not
      treated as signal death (it is not 128+N for any N≥1); 137/143 → killed; 1, 2, 127 →
      ordinary FAIL. Asserted, not asserted-by-inspection.
- [x] A prober drives the **real** runner region extracted from `update-task.sh` (not a
      retyped copy), covers each classification above, and has a mutation leg whose
      substitution count is asserted AND whose unmutated baseline is shown to produce the
      signal first (PL-297 — silence after a mutation means nothing without prior noise).
- [x] `verify_pass + verify_fail == verify_total` reconciliation (T-630) still holds: a
      did-not-finish command must still be COUNTED, not quietly reclassified out of the
      tally. Regression-asserted, because the obvious implementation of a third bucket is
      to stop incrementing the second one.
- [x] The change is declared in `.vendor-divergence.yaml` with an `upstream:` lane (G-008).

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

# The prober over the real runner region: 11 legs, exit code is the verdict.
bash tools/_t658-p011-must-distinguish-killed-from-failed.sh

# The edited gate must still parse. It is the file that runs THIS block, so a syntax
# error here would be discovered by the transition failing in a confusing way.
bash -n .agentic-framework/agents/task-create/update-task.sh

# G-008: the change must be declared. Exit code is the verdict.
python3 tools/_t517-vendor-divergence.py

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

**Symptom:** a verification command that was killed before finishing was reported as
`FAIL: <cmd> (exit 124)` — the same words used for a command that ran and returned a
failing verdict. The operator reads that as "your check is wrong" and starts fixing a
check that never got to say anything.

**Root cause:** the runner branched on `if (...); then PASS else FAIL`, a two-outcome
shape for a three-outcome world. The exit code already distinguished the third case —
timeout(1) exits 124, signal death exits 128+N — and the `else` discarded it into a
single label.

**Why structurally allowed:** the two-outcome shape is correct for the question "did this
command succeed?" and that was the question the runner was written to answer. It becomes
wrong only when the answer is consumed as a diagnosis rather than a verdict, which is what
the summary block does. Nothing in the code marked that transition, so a correct success
test silently became an incorrect explanation. Same family as T-656 (a control that
summarised two states needing different actions) and OBS-329 (a surface that cannot
distinguish "no verdict" from "a verdict I cannot parse").

**Prevention:** `tools/_t658-p011-must-distinguish-killed-from-failed.sh` drives the real
extracted region across 124/137/143 and the 128/127/2 boundary, asserts the distinction
survives into the summary, and asserts the T-630 reconciliation still holds — the obvious
implementation of a third bucket is to stop incrementing the second, which would make the
runner report a defect in itself.

**Known residual:** no timeout is imposed, so an unbounded hang is still unbounded. This
task makes an externally-killed command legible; it does not bound one. Deliberate — see
the scope note in Context.

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

### 2026-08-31 — a killed command still counts as a failure

- **Chose:** did-not-finish increments `verify_fail` exactly as before; only the wording
  changes. The new counter is a subset tracked alongside, not a third bucket taken out.
- **Why:** T-630's reconciliation compares `verify_pass + verify_fail` against
  `verify_total` and hard-fails on a mismatch, deliberately un-bypassable. Peeling
  did-not-finish out of `verify_fail` would have made every killed command trip the
  runner's own defect detector — the fix manufacturing the alarm.
- **Rejected:** a genuine third counter outside the tally, which is the more obvious
  implementation and reads cleaner. The prober asserts against it.

### 2026-08-31 — classify, do not impose a timeout

- **Chose:** classify how commands already die; add no timeout.
- **Why:** OBS-332's incident was killed by something external at five minutes. Adding a
  gate-side timeout would silently kill legitimately long verifications — builds, full
  suites — turning a legibility fix into a new failure mode, and the correct duration is
  not knowable from here.
- **Rejected:** a default timeout with an opt-out. Worth its own task and its own
  evidence about how long real verification blocks actually take.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T18:39:41Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-658-p-011-reports-a-killed-verification-comm.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-04d347d4
- **Timestamp:** 2026-08-31T18:45:02Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-31T18:45:00Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
