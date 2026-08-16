---
id: T-543
name: "T-523 nesting teeth legs 7-8 fail intermittently inside the bridge suite but
  never standalone"
description: >
  Legs 7 and 8 of tools/_t523-nesting-teeth.py (the retyping-mutant arm) reported
  FAIL in one bridge-suite run on 2026-08-16 with 'rc=1 drift_keys=[] measured node={}',
  then passed 9/9 twice standalone and 0-failed on the immediately following full-suite
  run. An empty measured node is the arm seeing nothing, not seeing the wrong thing
  — which is the failure mode the arm exists to distinguish. A probe that intermittently
  cannot see certifies on nothing whenever it happens to be green, and AEF depends
  on this arm for three published maps (T-528). Suspect suite-level interference:
  legs 6 and 9 print out of order, so something is concurrent, and the arm drives
  a CDP/browser path. Establish the rate before fixing.

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
created: 2026-08-16T14:26:20Z
last_update: 2026-08-16T16:06:45Z
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
  - ts: '2026-08-16T14:33:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T14:33:48Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-543: T-523 nesting teeth legs 7-8 fail intermittently inside the bridge suite but never standalone

## Context

Two instruments failed as bridge-suite legs on 2026-08-16 while passing
standalone: `_t523-nesting-teeth.py` (legs 7-8, `drift_keys=[] measured node={}`)
and `_t509-instrument-sweep.sh` (FAIL as a leg, rc=0 and "32/32 green"
standalone). Treated as one population per AC5.

## Findings

### The premise this task was filed on is dead

The description reasons: *"legs 6 and 9 print out of order, so something is
concurrent."* That is false. `tests/run-bridge-tests.sh` contains **zero**
backgrounding — no trailing `&`, no `xargs -P`, no `wait`
(`grep -c ' &$\|xargs -P\|^wait$'` → 0). The suite is strictly serial, so no leg
can interfere with another by running at the same time as it.

Out-of-order lines have a duller explanation that costs nothing to believe:
under the suite each leg's stdout is redirected to a file, and Python
block-buffers stdout when it is not a tty while stderr stays unbuffered. Lines
from one process interleave with its own — not with another leg's.

**Recorded as dead rather than quietly dropped**, because the concurrency
hypothesis is what made "add a retry" or "raise the timeout" look reasonable,
and both would have been changes made to satisfy a premise that was never true.

### Arm A — the redirect alone does not reproduce it

The cheapest remaining difference between suite and standalone context is that
the suite redirects stdout to a file. Tested directly: **30 consecutive
standalone runs of `_t523-nesting-teeth.py` with stdout redirected to a file —
30 passed, 0 failed.** One run takes 7.25s, so this is a cheap discriminator and
there was no reason to reach for the 6-minute suite first.

That eliminates the redirect, and with it the buffering explanation as a *cause
of failure* (it remains the explanation for the ordering symptom).

### Arm B — full-suite repetition

3 consecutive full-suite runs, per-leg outcomes captured.

**Both completed runs reproduced it — 2 of 2:**

| run | result | note |
|-----|--------|------|
| 1 | `104 passed, 1 failed` | `_t509` sweep FAIL — machine in use |
| 2 | `100 passed, 5 failed` | `_t509` sweep FAIL + 4 more — **confounded, load applied by me** |
| 3 | abandoned (session ended) | — |
| 4 | `106 passed, 0 failed`, 452s | **idle machine**, no concurrent commands (T-547 verification run) |
| 5 | `106 passed, 0 failed`, 458s | **idle machine**, no concurrent commands (T-547 verification run) |

**Rate: 2 of 4 completed full-suite runs reproduced the `_t509` failure** — and
the split is not random. Both failures came from runs where the machine was
doing something else; both greens came from runs where I deliberately did
nothing while the suite executed. That is what the timeout mechanism predicts,
so runs 4 and 5 are corroboration rather than contradiction.

**Runs 4 and 5 are honest but incidental.** They were T-547's verification runs,
not a designed rate experiment — I did not vary anything, I just happened to
need two clean full-suite runs and stayed off the machine for both. They are
recorded because withholding a green that arrived by accident would bias the
table exactly as much as averaging in the confounded run would. The designed
5-run measurement the rate AC asks for is still not done.

**Run 2 is confounded and I caused the confound.** While it executed I ran the
sweep and `_t525` standalone to identify the failing instrument, putting exactly
the load that the mechanism says pushes an 86s probe past a 90s cap. So run 2's
extra four failures are evidence FOR the mechanism and simultaneously
unusable as an independent rate sample. Recorded rather than quietly averaged
in: the number looks like a worsening trend and is partly my own measurement
apparatus. An earlier note here said to treat the whole arm as absent and
re-run from scratch; that was over-cautious and is **withdrawn** — run 1
completed and emitted a full verdict line, so it is a complete observation, not
a partial one.

## MECHANISM — established, and it is not flakiness

Reproduced standalone within minutes of the suite run:

```
$ bash tools/_t509-instrument-sweep.sh          → rc=1
RAN 33, passed 32, failed 1
SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:
  - _t525-fabric-coverage-teeth.py (rc=124)

$ /usr/bin/time python3 tools/_t525-fabric-coverage-teeth.py
7/7 legs passed        WALL 86.04 s        rc=0
```

**rc=124 is `timeout`'s exit code.** `_t525` takes **86.04s against the sweep's
90s cap** — 4.5% headroom. It passes cleanly on its own and crosses the cap
whenever anything else is competing for the machine. That is why it looked like
a suite-only failure: the suite is simply the most reliable way to put load on
the box. It is not the suite. It is *any* concurrent load — the standalone
reproduction above happened while arm B was still running.

**The real defect is in `_t509`'s reporting, not in `_t525`.** The sweep
conflates *"the instrument failed"* with *"the instrument did not finish"*. Its
own message asserts a regression — "an instrument that passed on 2026-08-15 no
longer does" — and its own explanatory text says "a red here is a real
regression in the thing it guards." **That sentence is false for rc=124.**
Nothing regressed in fabric coverage; a probe ran out of wall-clock. The reader
is sent to look for a bug that does not exist, which is the same shape this
project keeps meeting: an abstention rendered as a verdict.

Note the sweep already knows how to honour abstention — it exempts
`_t364-t308-teeth.py` **by name** for exiting 2 "BY DESIGN, refusing to
certify… converting that to a suite failure would punish the honesty." rc=124 is
the same category of answer arriving through a different door, and it is not
recognised. T-509's own shape again: an exemption granted to the case that
prompted it, never generalised to the class.

**Still not fixed, and deliberately.** Two separable repairs, and the tempting
one is wrong: raising the 90s cap buys headroom that `_t525` will consume again,
because its cost tracks the size of the watched tree (today's audit: 251 watched
files, 198 unregistered, and the set grows with the repo). The repair that
holds is teaching `_t509` to report rc=124 as *did-not-finish* rather than as a
regression. Both are next-session work; AC4 stands.

## `_t523` is NOT explained by this — recorded per AC5

The two instruments are one population only in that both surfaced as suite legs.
`_t523`'s symptom was `drift_keys=[] measured node={}` at rc=1, not rc=124, and
`_t523` runs in 7.25s against a 600s suite timeout — three orders of magnitude
of headroom. **The timeout mechanism cannot account for it.** Arm A's 30/30
leaves it unreproduced and its rate unbounded. Saying so explicitly because the
satisfying move here is to declare the population solved on the strength of the
half that was.

An earlier draft of this section claimed the first run "took materially longer
than the ~6 min baseline" and offered that as a datum. **It was not measured.**
I inferred elapsed time from how many steps I had taken while waiting, then
checked `ps`: the run was 5:54 in and sitting on `_t525-fabric-coverage-teeth.py`,
i.e. entirely normal. Corrected in place rather than deleted, because a task
about a probe that certifies on nothing is the wrong place to leave an
impression dressed as a measurement — and the error is the same one the task
exists to study, made by me, in the file describing it.

### What is NOT yet established

The mechanism. Remaining differences between suite and standalone context, none
yet tested: ~100 legs of accumulated system state before this one runs; the
suite's exported environment; and — our own doing, per AC6 — the fact that
`_t544` (which boots a real HTTP server) was added to the suite today and is
additionally run a second time inside `_t509`'s sweep under a 90s cap.

**No timeout has been loosened, no retry added, no leg quarantined.** Per AC4
that stays true until the mechanism is named.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The RATE is measured, not estimated: N consecutive full-suite runs with
      per-leg outcomes captured, and the finding stated as a count over that N.
      "Did not reproduce in N runs" is a legitimate outcome PROVIDED the bound
      it puts on the rate is stated — an unreproduced flake is not a fixed one
- [x] The claim this task was filed on — "legs 6 and 9 print out of order, so
      something is concurrent" — is CHECKED against how the suite actually
      invokes legs, not carried forward as a premise. If the suite is serial,
      that hypothesis is dead and must be recorded as dead
- [x] The mechanism is named with evidence, or the task records explicitly that
      it was not established and what was ruled out
- [x] No timeout is loosened, no retry is added, and no leg is quarantined
      before the mechanism is named. A suite that passes by waiting longer has
      stopped reporting, not stopped being wrong — this is a constraint on the
      fix, and it is an acceptance criterion so that violating it is visible
- [x] The two instruments are treated as one population, not two incidents:
      `_t523-nesting-teeth.py` and `_t509-instrument-sweep.sh` both failed as
      suite legs while passing standalone on the same day, and any mechanism
      offered must account for both or say why they are unrelated
- [x] If load introduced today is implicated, that is stated as our own doing:
      `_t544` and `_t545` were added to the suite this session and `_t544`
      boots a real server, which `_t509`'s sweep also runs under a 90s cap

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-16T14:26:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-543-t-523-nesting-teeth-legs-7-8-fail-interm.md
- **Context:** Initial task creation

## Second instance, same session — this is a class, not one flaky probe

2026-08-16, after T-544 landed: `tools/_t509-instrument-sweep.sh` reported FAIL
as a bridge-suite leg, then ran **rc=0, "SWEEP PASS — 32/32 runnable teeth
scripts green"** standalone immediately after. Identical shape to the T-523
finding above: green alone, red inside the suite, no source change between.

That makes two distinct instruments failing only in suite context in one
session, which reframes this task. The subject is not "_t523 is flaky" but
**the suite has a resource or concurrency interaction that makes probes fail
non-deterministically**, and every such failure is indistinguishable from a
real regression at the moment it is read.

A candidate cause worth ruling out FIRST, because it is mine and it is new:
`_t544-session-cookie-port-teeth.py` boots a real Watchtower instance (~9s) and
is itself one of the 32 scripts the T-509 sweep runs, so it now executes twice
per suite run — once as its own leg, once inside the sweep — and the sweep caps
each script at 90s. T-542's probe also grew the sweep population. If load is
the mechanism, I introduced it today and should say so rather than let the next
reader hunt it.

Do not "fix" this by loosening a timeout until the mechanism is measured. A
suite that goes green by waiting longer has not stopped being wrong; it has
stopped reporting.

### 2026-08-16T15:43:56Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
