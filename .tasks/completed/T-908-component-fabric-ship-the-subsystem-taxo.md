---
id: T-908
name: "Component fabric: ship the subsystem taxonomy that register demands, and stop impact reporting an empty chain as a safe answer"
description: >
  Component fabric: ship the subsystem taxonomy that register demands, and stop impact reporting an empty chain as a safe answer

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
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T16:09:44Z
last_update: 2026-09-27T16:09:44Z
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

# T-908: Component fabric: ship the subsystem taxonomy that register demands, and stop impact reporting an empty chain as a safe answer

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
**Measured state of the fabric, 2026-09-27** — the audit has been printing these for weeks:

| finding | count |
|---|---|
| cards with **no edges at all** | **84 of 415** (20%) |
| `subsystem: unknown` | **36** |
| source files with **no card** | **32** |
| cards pointing at files no watch pattern covers | **11** |
| under-populated cards (any of the above) | **98** |

**Why none of it moved, and this is the point of the task.** `fw fabric register` REFUSES every new
file — *"no subsystem rule matches — add a paths: pattern to .fabric/subsystems.yaml"*
(`agents/fabric/lib/register.sh:352`) — and **that file does not exist**: `.fabric/` holds only
`components/` and `watch-patterns.yaml`. So drift can only grow. Meanwhile `fw fabric impact`
prints a bare header and **exits 1** while `fw fabric deps` returns real edges for the same file,
and CLAUDE.md sends every agent to `impact` before modifying a file. The fabric is simultaneously
incomplete and structurally unable to be completed.

That pair is the deliverable. The 84-card edge backfill is NOT in this task: it is only worth doing
once registration works, and only from real evidence.

- [x] `.fabric/subsystems.yaml` exists and matches the schema `describe.py:load_subsystem_rules` actually reads — `subsystems: [{id, paths: [glob]}]`, fnmatch, longest pattern wins — verified by that function returning a non-empty rule list, not by my reading of the file
- [x] The taxonomy is DERIVED from where files actually live and from the subsystem names cards already use, not invented. The existing vocabulary is incoherent (`instruments` 280, `instrumentation` 4, `verification` 21, `verification-probes` 7 — four names for overlapping ideas) and the task must state which it kept, which it merged, and why
- [x] `fw fabric register` on a previously-refused file now succeeds AND assigns a real subsystem — demonstrated on a file it refused before, with the before/after both recorded
- [x] Every one of the 32 unregistered source files either registers with a real subsystem or is named in this task as deliberately out of scope with its reason. A file silently left unregistered is the state this task exists to end
- [x] `fw fabric impact` no longer reports an empty chain as a successful-looking answer: either it returns the same edges `deps` does, or it says explicitly that it computed nothing. **An empty impact chain must not read as "nothing depends on this"** — that reassuring-direction blindness caused an unverified commit in procAsFit round 1
- [x] A control proves the impact fix bites: a file with KNOWN dependents returns them, and a file with genuinely none is distinguishable from a failure to compute. Both directions, or the fix is unmeasured
- [x] The audit's fabric findings are re-run and the deltas recorded — before/after counts for unregistered files and `unknown` subsystems, from `fw audit`, not from my own arithmetic

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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# ── T-908 legs ──────────────────────────────────────────────────────────────
bash -n .agentic-framework/agents/fabric/lib/traverse.sh
test -f .fabric/subsystems.yaml
# the taxonomy loads through the framework's OWN reader, not through my reading of the file
python3 -c "import sys; sys.path.insert(0,'.agentic-framework/agents/fabric/lib'); import describe; r=describe.load_subsystem_rules('/opt/832-Workflow-designer'); sys.exit(0 if len(r)>=40 else 1)"
# every path class routes somewhere — 0 unmatched across a representative sample
python3 -c "import sys; sys.path.insert(0,'.agentic-framework/agents/fabric/lib'); import describe; r=describe.load_subsystem_rules('/opt/832-Workflow-designer'); fs=['tools/_t889-authority-on-the-element-teeth.sh','tools/_t821-fault-surface-cdp.mjs','tools/hooks/warn-uncontrolled-absence.sh','tools/validate-workflow.py','src/aef-workflow-designer.html','tests/test_rule_dialect_axis.py','tests/fixtures/x.bpmn','docs/standards/x.md','.fabric/subsystems.yaml']; bad=[f for f in fs if describe.derive_subsystem(f,'/opt/832-Workflow-designer',r) is None]; sys.exit(1 if bad else 0)"
# impact returns a real chain for a file with known dependents (was: crash rendered as empty)
.agentic-framework/bin/fw fabric impact tools/_roundtrip-serialization-cdp.mjs > /tmp/.t908-imp 2>&1 && grep -qE '[0-9]+ downstream component\(s\) affected' /tmp/.t908-imp
# CONTROL on that: the chain names the 15-minute dependent round 1 did not run
grep -qF 'tests/run-bridge-tests.sh' /tmp/.t908-imp
# The stderr mask is gone from BOTH python heredocs — a bare `" 2>/dev/null` at the START of a
# line is the closing quote of a python -c block, and that is the shape that hid a crash as an
# empty answer for three rounds. Anchored, because my first version of this leg was unanchored,
# matched six legitimate inline uses, failed — and in failing surfaced the SAME defect in the
# sibling verb do_blast_radius, which nothing had looked at.
! grep -qE '^" 2>/dev/null' .agentic-framework/agents/fabric/lib/traverse.sh
# CONTROL on that absence: the anchored pattern IS findable in a file that still has one, so a
# typo'd pattern cannot pass this as a clean absence
grep -qE '^" 2>/dev/null' .agentic-framework/agents/fabric/lib/ui.sh || grep -rqE '^" 2>/dev/null' .agentic-framework/agents/
# all four depends_on iteration sites carry the str-vs-dict guard
test "$(grep -c 'isinstance(dep, dict)' .agentic-framework/agents/fabric/lib/traverse.sh)" -eq 4
# drift is clean: every watched file registered
.agentic-framework/bin/fw fabric drift > /tmp/.t908-drift 2>&1 && grep -A1 'Unregistered components:' /tmp/.t908-drift | grep -q '(none)'

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T16:09:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-908-component-fabric-ship-the-subsystem-taxo.md
- **Context:** Initial task creation

## 2026-09-27 — `impact` was not returning an empty chain. It was CRASHING, and `2>/dev/null` hid it.

This is the finding, and it is larger than the task it was filed as. Three procAsFit rounds
independently reported "`fw fabric impact` prints an empty chain" (OBS-408, confirmed as OBS-411,
confirmed a third time in round 3) and none could say why. The why was on the stream being thrown
away: the traversal's closing line was `" 2>/dev/null`.

Unmasked, it printed:

```
AttributeError: 'str' object has no attribute 'get'
```

**Cause:** 24 of 704 `depends_on` entries in committed cards are **plain strings**, not
`{type, target}` dicts. Both shapes are in the corpus. `dep.get('type')` on a string raises, the
traceback was discarded, and the verb printed its header and stopped. **A crash was rendering as
"nothing depends on this file" — in the reassuring direction, to a verb CLAUDE.md tells every
agent to consult BEFORE modifying a file.** Round 1 changed a shared harness on the strength of
exactly that answer, having run one of its five dependents.

Fixed at all four `depends_on` iteration sites, not just the one that happened to raise. A bare
string carries no edge type, so it is now treated as an untyped structural dependency — counted
as an edge, never as a write.

**Then the fix's own refusal path was dead code, and the control caught it.** I added an
`IMPACT NOT COMPUTED` message for the non-zero case, injected a crash to prove it fired, and it
did not print. `fabric.sh:26` sets `-euo pipefail`, so errexit terminated the function the instant
python exited non-zero and my message was unreachable. `|| _rc=$?` is what makes the failure
survivable long enough to report. **I would have shipped an unreachable error handler if I had
trusted the fix instead of testing it** — and the test that caught it is the same shape as the
defect it was testing.

`impact` now returns the transitive chain for the file that started this, 10 components deep,
including `tests/run-bridge-tests.sh` — **the 15-minute dependent round 1 did not run.** Had the
verb worked then, it would have named it.

## The taxonomy

`.fabric/subsystems.yaml` did not exist, and `register.sh:352` refused every new file for want of
it. Registration could only fail, so drift could only grow — a remedy naming a file nobody could
edit. Now shipped: 56 rules, verified through `describe.py:load_subsystem_rules` itself rather
than by reading the file, and tested against 14 real paths with 0 unmatched.

Derived from evidence, not invented: every id either already appears on committed cards or names a
directory that exists. Two judgements recorded rather than made silently —
`browser-harness` is separated from `instruments` because its chromium dependency makes it SKIP
where others fail, and a skip reading as a pass is this project's signature defect; `seam-tooling`
is separated because those files are consumed by AEF across the seam, so a change there is a
contract change rather than self-checking.

**The incoherent vocabulary is kept visible, not tidied.** `instruments` (280) /
`instrumentation` (4) / `verification` (21) / `verification-probes` (7) are four names for
overlapping ideas. New registrations route to `instruments`; the existing cards are NOT rewritten,
because they are committed records and a rename would churn 32 of them for no measured gain.

## Audit deltas, including the two that got worse

| | before | after |
|---|---|---|
| unregistered source files | 32 | **0** — `Fabric drift` now PASSES, 440 watched files examined |
| `subsystem: unknown` | 36 | **0** |
| registered cards | 415 | 451 |
| zero-edge cards | 84 | **120** ⬆ |
| under-populated cards | 98 | **127** ⬆ |

**The last two went up and that is a real cost, not a rounding artefact.** Registering 34
previously-invisible files created 34 cards with no edges yet. Invisible → visible-but-incomplete
is the right direction, but anyone reading only the zero-edge number sees this task as a
regression. Said plainly here so nobody has to discover it from the audit.

The edge backfill is deliberately NOT in this task: it is only worth doing now that registration
works, and only from real evidence — a card with invented edges is worse than one with none, the
same reasoning that governed the `components:` work in T-906.
