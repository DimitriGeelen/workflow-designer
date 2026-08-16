---
id: T-549
name: "_t525 costs 5 full structure audits (86s of a 90s cap) and its cost tracks the growing watched tree"
description: >
  _t525-fabric-coverage-teeth.py invokes 'fw audit --sections structure' five times (baseline plus four synthetic-history scenarios), measured at 86.04s against _t509's 90s cap and crossing it under any concurrent load. T-548 made the crossing report honestly as DID NOT FINISH rather than as a regression; this task is the cost itself. The tempting repair is raising T509_TIMEOUT and it is wrong: the audit's cost tracks the watched tree (252 watched, 199 unregistered today) so the headroom is consumed again as the repo grows. Parallelising the five audits is NOT obviously safe either - they contend on .context/locks/audit.lock and each writes .context/audits/<date>.yaml, so concurrency needs measuring before it is assumed. Investigate what the five audits actually cost, whether the four scenario audits can share a single structure scan, and whether the probe can assert the same discrimination with fewer full audits. Do not weaken what it discriminates.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t548-sweep-classification-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T17:53:01Z
last_update: 2026-08-16T19:06:07Z
date_finished: 2026-08-16T19:06:07Z
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

# T-549: _t525 costs 5 full structure audits (86s of a 90s cap) and its cost tracks the growing watched tree

## Context

`_t525-fabric-coverage-teeth.py` runs `fw audit --sections structure` five times: once for
the real tree (leg 1, and the baseline warn/fail counts leg 6 compares against) and four
times over synthetic `FABRIC_HISTORY_DIR` values (card-loss / growth / flat / no-history).
The four scenario runs differ from each other in **one environment variable** and in nothing
else, yet each pays for a complete structure audit — every YAML parse, the secret scan, the
cron-registry check, the full fabric drift walk over 254 watched files.

T-543 measured the whole probe at 86.04s against `_t509`'s 90s cap. T-548 made the crossing
report honestly (`DID NOT FINISH`, rc=3) instead of as a false regression. This task is the
cost itself.

Two repairs are ruled out before starting:

- **Raising `T509_TIMEOUT`** buys headroom that the tree consumes again. The audit's cost
  tracks the watched set (254 watched / 199 unregistered today, and both climb).
- **Parallelising the five audits** is not obviously safe: they contend on
  `.context/locks/audit.lock` and each writes `.context/audits/<date>.yaml`. Concurrency here
  needs measuring before it is assumed, and leg 7 asserts that exact write-set is unchanged.

The question to answer with measurement, not intuition: what fraction of a structure audit
does the fabric coverage check actually need, and can the four scenarios share one scan?

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Cost is **decomposed by measurement, not estimate**: total `_t525` wall-clock, the cost of a
      single `fw audit --sections structure`, and which checks inside one audit dominate it —
      each with the command that produced the number recorded in this task
- [x] `_t525` wall-clock is reduced to **at most 50% of `T509_TIMEOUT`** (≤45s), measured 3 times on
      the real tree — OR this task records a measured argument that it cannot be, naming the
      specific irreducible cost and what the residual is
- [x] **Discrimination is not weakened**: all 7 legs still pass, and all five branches
      (baseline / CARD LOSS / growth / flat / abstain) are still each exercised against a real
      audit run — not against a cached or replayed transcript of one
- [x] A **mutation check** proves the cheaper path still fails when the subject breaks: with the
      audit's coverage branch deliberately altered, `_t525` goes red and names the branch
- [x] `T509_TIMEOUT` is unchanged, and `_t525` is not added to `_t509`'s exclusion list — the cost
      is fixed, not the instrument silenced
- [x] Leg 7 still passes: the subject's write-set (`.context/audits`, excluding `cron/`) is
      byte-identical after the run

## Measured

**One `fw audit --sections structure` on this repo — 16.86s** (profiled by timestamping the
`bash -x` trace stream externally; `PS4` is not honoured by the traced shell, so the timestamps
were taken at the reader rather than inside the script). The three costliest steps:

| step | cost | can it depend on `FABRIC_HISTORY_DIR`? |
|---|---|---|
| BVP coherence scan (`python3 - <root> 4 1 0.7`) | 3.93s | no |
| tracked-tree secret scan (`secret-scan.sh scan-tree`) | 3.69s | no |
| concerns walk (`python3 - .../concerns.yaml`) | 2.56s | no |

60% of every branch run was being spent on checks that cannot vary with the one input the
branch legs vary — paid four times over.

**`_t525` wall-clock: 86.04s (T-543) → 24.75 / 25.77 / 25.33s**, three consecutive runs,
`/usr/bin/time -f "%e"`. Mean ~25.3s, a 71% reduction, against a 90s cap and a 45s AC.

**Where it went:** one real-tree audit (16.9s, legs 1/6b/7) plus four fixture audits at ~1.5s
each (legs 2–5, 6a) plus fixture build. The four branch runs went from 67s to 6s.

**The cost no longer tracks this repository.** That was the actual defect named at filing —
raising the cap buys headroom the tree consumes again. The fixture is fixed at 20 watched
files and 8 cards, so the branch legs cost the same in a year as today. Only the single
real-tree leg still scales, and it has to.

**Sweep after the change:** `RAN 36, passed 35, regressed 0, did-not-finish 0` — no timeout,
and no `HEADROOM WARNING`, so `_t525` is now under 75% of budget rather than at 95.6%.

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

# The probe passes every leg on the real tree AND does so inside 45s — half the cap. One
# command asserting both: `timeout` returns the probe's own exit code when it finishes, and
# 124 when it does not, so a red leg and an overrun are both caught here and neither can be
# read as green. Output is deliberately NOT discarded — the gate prints it on failure, and a
# line that throws away the evidence for its own verdict tells the next reader nothing.
timeout 45 python3 tools/_t525-fabric-coverage-teeth.py
# The cheap fixture legs still go red when the coverage check is broken. Without this, the
# first two lines are satisfied by a probe that can no longer fail (PL-206).
python3 tools/_t549-fabric-coverage-mutation-teeth.py
# The cost was fixed, not the instrument silenced: cap unchanged at 90s...
grep -q 'T509_TIMEOUT:-90' tools/_t509-instrument-sweep.sh
# ...and _t525 is not in the sweep's by-name exclusion list.
python3 -c "import sys; s=open('tools/_t509-instrument-sweep.sh').read(); b=s.split('EXCLUDE=(',1)[1].split(')\n',1)[0]; sys.exit(1 if '_t525' in b else 0)"
# Subset mode cannot be mistaken for a pass. Asserted as rc==2 exactly, not as "non-zero":
# a bare `!` would also accept rc=1, so a subset run with a RED leg would satisfy the line
# meant to prove abstention. The chain is deliberate — the last command is the verdict and
# it reads the first command's status, which is the one case chaining is correct.
sh -c 'T525_SCOPE=branches python3 tools/_t525-fabric-coverage-teeth.py > /dev/null 2>&1; [ $? -eq 2 ]'

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

### 2026-08-16 — move the branch legs to a fixture rather than make the audit skippable

- **Chose:** point the four branch runs at a per-run mktemp project via `PROJECT_ROOT`, a seam
  the framework already declares and its own cron entries already use.
- **Why:** it changes the TREE, not the code path. The same `fw audit` binary runs the same
  check through the same branches; there is no cached transcript and no stubbed audit. And it
  removes the growth coupling, which is the part of the defect that would otherwise come back.
- **Rejected — raise `T509_TIMEOUT`:** ruled out at filing and the measurement confirms why.
  The cost tracks the watched tree (254 files and climbing), so the headroom is spent again.
- **Rejected — parallelise the five audits:** they contend on `.context/locks/audit.lock` and
  each writes `.context/audits/<date>.yaml`, which is the exact path leg 7 asserts is
  untouched. Concurrency would have traded a measured cost for an unmeasured race.
- **Rejected — add skip flags to the audit** (`--skip-secret-scan` and friends) to make each of
  the five runs cheaper. This was the tempting one: it attacks the 60% directly. It is wrong
  because it puts a way to make an audit look clean into the audit, permanently, for the
  benefit of one probe. The cost is the probe's problem and belongs in the probe.
- **Rejected — re-section the audit** so fabric checks can be selected alone. Correct diagnosis
  — `structure` is a grab-bag of 20+ unrelated checks — but it changes what the pre-push and
  cron audits run, in vendored AEF code, for a probe's convenience. That is AEF's product
  surface and a much larger blast radius than this task's deliverable.

### 2026-08-16 — leg 6 split rather than relaxed

- **Chose:** 6a asserts severity invariance across branches on the fixture; 6b asserts the
  finding on THIS repo is carried at `WARN`.
- **Why:** the old single leg compared warn TOTALS across five real-tree runs, so an unrelated
  check flapping mid-run moved the number for reasons having nothing to do with the branch —
  the same defect T-533 fixed one leg over, in this same file. On the fixture, history is the
  only variable. 6b then reads the severity off the finding's own `[WARN]` marker instead of
  the report's `Fail:` total, because the total is a global moving property that would turn
  this leg red for somebody else's unrelated failure (G-015).
- **Note:** this is a strengthening, not a relaxation — but it is still a change to what a
  green means, which is why it is recorded rather than left in the diff.

### 2026-08-16 — the mutation probe got a resolution precondition, because the gate caught it lying

- **What happened:** run by hand the mutation probe was 4/4 green. Run by the P-011 completion
  gate it failed, reporting that all three legs *"stayed GREEN against a subject whose branch
  was deliberately broken"* — i.e. accusing three sound legs of having no teeth.
- **Cause:** `fw` exports `FRAMEWORK_ROOT` (`bin/fw:639-640`). Anything invoked from inside a
  framework command inherits a pointer to the real vendored tree, so the copied-and-mutated
  framework was never read. The probe stripped `PROJECT_ROOT` and not its sibling.
- **Chose:** strip both, and add a precondition that ASKS the copied `fw` which framework it
  resolves to before mutating anything — refusing if the answer is not the copy.
- **Why the precondition and not just the fix:** the failure mode here is a probe that says
  "your test cannot fail" when the truth is "I never reached your test". That is worse than
  silence, because it sends someone to rewrite working legs. The variable that caused it is
  one of a family, and the next member will be inherited from somewhere I have not thought of.
- **The precondition was wrong on its first attempt too**, in an instructive way: it asked
  `fw version` from the repo root, where resolution correctly prefers the vendored framework
  (T-498), so it refused a probe whose mutations were in fact landing. It now asks from a
  directory standing in for the fixture — the conditions the audit calls actually run under.
  A control has to be run against the thing it certifies and not against something nearby,
  which is the same sentence this whole probe exists to enforce one level up.
- **Verified both ways:** 5/5 green plain, and 5/5 green with `FRAMEWORK_ROOT` and
  `PROJECT_ROOT` exported as the gate exports them.

### 2026-08-16 — the subset seam exits 2, always

- **Chose:** `T525_SCOPE=branches` abstains with rc=2 whatever its legs say, and prints which
  legs were not evaluated.
- **Why:** the seam exists so the mutation probe can run `_t525` four times at 8s instead of
  25s. A partial instrument that can return the same 0 as the whole one is how "the suite is
  green" stops meaning anything — T-548's finding, applied here before it was discovered the
  expensive way.

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

### 2026-08-16T17:53:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-549-t525-costs-5-full-structure-audits-86s-o.md
- **Context:** Initial task creation

### 2026-08-16T18:30:39Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-09fe2cc6
- **Timestamp:** 2026-08-16T19:07:17Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T19:06:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
