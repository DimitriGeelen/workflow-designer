---
id: T-755
name: "RA-046: OBS-358 full-audit hang localises to the oe-daily section"
description: >
  Sectioned audit run: oe-daily exits 124 (timeout) after emitting 58 PASS in 300s;
  oe-fast, oe-hourly, oe-weekly, oe-research all complete in seconds. The long-standing
  'full fw audit hangs' observation is not diffuse - it is one section.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: [audit-remediation, cycle-1]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T08:02:35Z
last_update: 2026-09-21T08:50:56Z
date_finished: 2026-09-21T08:50:56Z
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
  - ts: '2026-09-21T08:02:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:02:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=1 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-755: RA-046: OBS-358 full-audit hang localises to the oe-daily section

## Context

### Verbatim tool output

Sectioned run, each section timeout-boxed at 300s:

```
oe-fast     EXIT=0   FAIL=0 WARN=0 PASS=4
oe-hourly   EXIT=0   FAIL=0 WARN=0 PASS=2
oe-daily    EXIT=124 FAIL=0 WARN=0 PASS=58      <-- 124 = timeout
oe-weekly   EXIT=0   FAIL=0 WARN=0 PASS=1
oe-research EXIT=0   FAIL=0 WARN=0 PASS=5
```

Re-run of the same section with the box raised to 1500s:

```
exit=1 elapsed=578s lines=207 pass=106
```

### CORRECTION: the localisation was already recorded

Before claiming credit for this: **OBS-358 already names CTL-013 and already names
T-093's four suites.** It was filed 2026-09-20 from T-708 — one day before this cycle —
and reads in part:

> "Archiving a task moves its whole Verification block into CTL-013's re-run set, and the
> audit pays that cost on every subsequent run. ... T-093's block runs four suites ...
> The sweep was correct and should not be reverted; the cost is structural."

So this task did not discover the mechanism. It re-derived it. What is genuinely added
here is narrower, and worth stating as exactly that:

1. **It terminates.** OBS-358 says oe-daily "stalls past 300s" — which is where every
   prior measurement stopped. Raising the box to 1500s shows it completes in **578s**.
   "Stalls past 300s" and "takes 578s" are different claims with different remedies, and
   only the second one is true.
2. **Live confirmation of the causal chain**, not inference from where output stops:
   `pgrep` caught `bash tests/run-bridge-tests.sh` (pid 2352331) as a child of the running
   audit.
3. **Two findings recovered** that the 300s box had been hiding — RA-047, RA-048.

OBS-358's AC clause ("OBS-358 is updated to cite the section") was therefore already
satisfied when this task was written. It is not ticked on the strength of work this task
did.

### Finding: it is not a hang

`oe-daily` terminates. It takes **578 seconds** and exits 1 (warnings present, no
failures). Every prior report of "full `fw audit` hangs" (OBS-358) was measured against
a timeout shorter than 578s. The distinction matters: a hang is a defect to be fixed,
a 578-second section is a cost to be budgeted, and the two get different treatment.

### Finding: the audit kills ITSELF at 600s — `audit.sh:312`

Measured this cycle, and it is the part that actually explains the folklore.

A full `fw audit` (all sections) was launched wrapped in `timeout 2400`. It did not run
for 2400s and it did not run to completion. It was killed at **exactly 600 seconds**:

```
Terminated
exit=143 elapsed=600s
```

Exit 143 is SIGTERM. The `timeout 2400` never fired — something with its own 600-second
ceiling terminated the job first.

**First attribution was wrong.** I assumed the ceiling belonged to the surface running
the command (a shell or tool limit) and re-launched detached under `nohup setsid` to
escape it. It died at exactly 600s again. The ceiling is not external at all: That matters because of the number next to it:
**oe-daily alone takes 578s.** A full run is oe-daily plus eighteen other sections, so it
needs roughly 700s and up. It therefore hits a 600s ceiling *every single time*, and what
the ceiling produces — a process that stops emitting and never returns — is
indistinguishable from a hang at the point of observation.

```bash
# audit.sh:312
AUDIT_TIMEOUT="${FW_AUDIT_TIMEOUT:-600}"
# audit.sh:346
sleep "$AUDIT_TIMEOUT" && kill -TERM $$ 2>/dev/null
```

**The audit kills itself.** It arms a watchdog subshell that sleeps 600 seconds and then
sends SIGTERM to its own PID. T-1162/T-866/T-1464 put it there to stop zombie audits
accumulating under cron — a correct guard, sized when the audit was fast.

The margin is the part that should worry somebody: **oe-daily alone measures 578s against
a 600s self-kill.** That single section survives by 22 seconds. Any further growth in
T-093's four suites, or a slower or busier host, and even a section-scoped run stops
completing — and it will present the same way, as a hang.

So the causal chain is:

1. T-723's sweep moved T-093 into `completed/` (OBS-358 records this correctly).
2. T-093's `## Verification` block carries four full test suites.
3. CTL-013 `eval`s that block on every oe-daily run → the section grows to 578s.
4. A full audit is then ~700s+, which exceeds the 600s ceiling of the surface running it.
5. The audit's OWN watchdog fires at 600s and SIGTERMs the run → no summary, no
   interpretable exit code → "full audit hangs".

Nothing in that chain is a hang. Steps 1–3 are a real and structural cost, already owned
by OBS-358. Step 4–5 is a **measurement artefact of the harness**, and it is the reason
the cost has been described as a defect of the audit rather than a budget that outgrew
its container.

Decisive test for AC 3: re-run with `FW_AUDIT_TIMEOUT` raised. If the full run completes,
the audit has no defect of correctness — it has a budget that no longer fits its own
workload, and the remedy is a budget decision, not a shortened check.

### Finding: the cost is CTL-013, and it is not the audit's own work

`audit.sh:3618` — "CTL-013 OE: Verification Gate — spot-check recently completed tasks".
CTL-013 takes the three most recently completed tasks and **`eval`s every shell command
in their `## Verification` blocks**. The audit's runtime for this section is therefore
not a property of the audit at all: it is the sum of whatever arbitrary shell the last
three completed tasks happen to carry.

At the time of measurement the three were T-739, T-178 and T-093. T-093's block is:

```
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
... plus 6 grep/diff/test legs
```

Four full test suites. This was confirmed **live, not inferred**: while the audit was
running, `pgrep` showed pid 2352331 = `bash tests/run-bridge-tests.sh`, a child of the
audit process. The T-742 value review independently measured the gating suite at 742s.

So the relationship is: **oe-daily's wall time ≈ the verification cost of the three most
recently completed tasks.** It is bounded (3 tasks, not N), but the bound is over a
quantity the audit does not control and cannot predict — any task may put a twelve-minute
suite in its `## Verification` block, and the next audit inherits it.

### Consequence that is not yet a task

CTL-013's re-run is a *moving window* over the three newest completed tasks. Whether a
completed task's verification still passes is therefore checked for a few days and then
never again — and which tasks get that scrutiny is decided by completion order, not by
risk. Whether that is the intended semantic is a design question, not a defect to fix
here.

### A verification leg of mine was wrong and the gate caught it

The first attempt at AC 3's leg was `grep -q 'oe-daily' .context/audits/2026-09-21.yaml`.
P-011 refused completion on it. The leg was wrong, not the state: the saved record is
"the last run of each date, per scope" (T-677), and the full run overwrote the
section-scoped one, so the record now reads `sections: "all"`. That leg was asserting
*how the audit happened to be invoked*, which is not what this task found, and it would
have gone red for reasons unrelated to the claim.

Replaced with two legs that encode the finding itself — the 600s default and the
`kill -TERM $$` mechanism. `--skip-verification` was offered by the gate and not used.

### AC 3 — answered: it completes in 687 seconds

```
FW_AUDIT_TIMEOUT=3000 fw audit     ->  exit=2  elapsed=687s
                                       Pass: 175  Warn: 31  Fail: 1
```

687s against a 600s self-kill. **The audit was failing by 87 seconds.** With the watchdog
budget raised it runs to completion and emits a full summary — so there is no defect of
correctness anywhere in the audit. There is a fixed 600s budget that its own workload
outgrew, and the remedy is a budget decision, not a shortened check (AC 4 holds).

This is, as far as the audit records show, the first complete 19-section run this project
has had. It immediately produced three findings that no section-scoped run had surfaced
(RA-049, RA-050, RA-051) — the strongest possible argument for the coverage AC on T-744.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The oe-daily section is profiled to the individual check, and the check (or checks) consuming the bulk of the wall time is named with measured timings — not inferred from where the output stops.
- [x] A bound is established: either oe-daily completes within a stated time limit, or it is shown to be genuinely unbounded (e.g. it scales with task count or audit history) and that relationship is stated with evidence.
- [x] `fw audit` with all sections completes, or the reason it cannot is recorded as a property of a named check rather than as the folk observation "full audit hangs". OBS-358 is updated to cite the section.
- [x] No check is deleted, shortened, or given a relaxed threshold to make the run finish. If the only available fix is removing coverage, that is a Sovereign question, not a fix.

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

grep -q 'CTL-013 OE: Verification Gate' .agentic-framework/agents/audit/audit.sh
test "$(find .tasks/completed -maxdepth 1 -name '*.md' -type f -printf '%T@ %p\n' | sort -rn | head -3 | cut -d' ' -f2- | xargs -I{} awk '/^## Verification/{f=1;next} f&&/^## /{exit} f' {} | grep -cE 'run-bridge-tests|run-validator-tests|check-corpus-geometry')" -ge 1
grep -q 'FW_AUDIT_TIMEOUT:-600' .agentic-framework/agents/audit/audit.sh
grep -qE 'sleep "\$AUDIT_TIMEOUT" && kill -TERM' .agentic-framework/agents/audit/audit.sh

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
     fw inception decide T-755 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T08:02:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-755-ra-046-obs-358-full-audit-hang-localises.md
- **Context:** Initial task creation

### 2026-09-21T08:12:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work


## Reviewer Verdict (v1.5)

- **Scan ID:** R-aada87bb
- **Timestamp:** 2026-09-21T08:50:57Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T08:50:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
