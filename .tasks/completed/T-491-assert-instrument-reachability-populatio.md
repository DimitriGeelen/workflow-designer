---
id: T-491
name: "Assert instrument REACHABILITY population-wide: PL-148's remedy has never been
  built and the class has recurred five times"
description: >
  PL-148 (T-426) prescribes: assert an instrument's REGISTRATION as a separate verification
  command from its behaviour, and state reachability as an explicit LIMIT in the instrument's
  own output so a green run cannot imply coverage it does not have. PL-004 (T-052)
  prescribes wiring every gate into CI over its full subject set with a legacy allowlist.
  Neither has been built as a population-wide check, and the class has now recurred
  five times across two projects: AEF check-onboarding-gate (38 green legs, unregistered
  in every consumer), 832 T-420 gate (inert to the session that registered it), 832
  T-421 detector (only call site was its own completion block, exiting 1 into a void),
  T-490 _roundtrip-serialization-cdp.mjs (claimed to close G-002, invoked by no runner
  since T-187, sharpened four times on hand-run greens), T-448 bake-clean-layout --check
  (documented corpus gate, invoked by nothing, red on all 24 maps and silently so).
  Every instance was repaired by hand for that one instrument and NO repair made the
  next one detectable — which is precisely the fix-on-discovery pattern PL-145 identifies
  as what keeps a class open. Deliverable is a standing check over the POPULATION
  of declared instruments (not one more per-instrument verification leg) that answers:
  which things in this tree claim to guard something and are reached by nothing. Note
  the population trap measured in T-490: a census scoped to tools/_*.mjs answered
  0 of 27, and T-448 is a real instance that lives outside that glob, so the population
  must be derived from what CLAIMS to guard, not from a file extension.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t451-unwired-guard-census.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-13T11:59:31Z
last_update: '2026-08-16T12:34:03Z'
date_finished: 2026-08-14T06:14:10Z
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
  - ts: '2026-08-16T12:34:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-491: Assert instrument REACHABILITY population-wide: PL-148's remedy has never been built and the class has recurred five times

## Context

**The premise this task was filed on is WRONG, and finding that out is the deliverable.**

T-491 was captured saying PL-148's remedy "has never been built as a population-wide check".
It was built — `tools/_t451-unwired-guard-census.py`, by T-451, and it is better than the
replacement I started writing before checking. It already knows every distinction I was
rediscovering: that a `## Verification` block is a one-shot which becomes unrunnable once its
task completes (PL-161); that `*-teeth.sh` / `*-mutation-check.sh` are one-shot BY DESIGN and
excusing them by naming convention beats guessing intent; that both sides must be derived from
the tree with no literal counts (PL-158); and it states its own reachability LIMIT in its
output, which is PL-148's second half.

I got two population definitions wrong before finding it — `closes G-NNN` in a header matched
1 file, `guard`/`gate` in a header matched 138 — and my draft's first run produced "115
orphans", a headline of exactly the shape T-490 taught me to distrust. The existing census
answers 37 with the one-shot probes correctly separated out.

**What is actually true, measured:**

| | |
|---|---|
| census exists, correct, derives both sides | `tools/_t451-unwired-guard-census.py` (T-451) |
| its only live caller | the G-034 gap gauge in `lib/gaps.py` — runs when somebody asks |
| its verdict today | exit 1: population 166, live-callable 94, **37 standing guards with no live caller** |
| scheduled to run | nothing |

So the census is one step milder than the class it measures: not unrunnable, just **unwatched**.
It has been measuring a real backlog since T-451 and telling nobody. T-490 and T-448 are two
instances found by hand during that interval — the census had both the whole time.

**Why the raw exit code cannot simply be wired.** It exits 1 on the pre-existing backlog, so a
direct wiring paints the suite permanently red and the red carries no information. PL-004 named
the alternative in the same sentence it named the class — *"wire every gate into CI over its
full subject set, with a legacy allowlist (with stale-entry detection)"* — and only the
allowlist half has ever been built anywhere in this tree. The stale-entry half is the one that
matters over time: without it a baseline decays into a permanent amnesty and stops describing
the tree, which is a hand-typed denominator wearing a different hat (PL-181).

**Reintroduction, avoided by one grep.** AEF reported at rail 611 that they found this exact
shape in their own tree — a fix present in one reader, dropped 4,400 lines away by a later
rewrite that did not carry it, with the fixed one's comment explaining why it was necessary.
Keeping my draft alongside T-451's census would have been the same shape at file scale: two
censuses of one population, diverging silently. It was deleted, not merged.

## Acceptance Criteria

### Agent
- [x] The premise is VERIFIED against the current tree before building — the existing instrument is found, read, and run, rather than a second one shipped beside it (PL-023)
- [x] The reimplementation is DELETED, not kept "for comparison" — two censuses of one population is the reintroduction shape, and the second one is always the one that rots
- [x] The census's true reachability is established by measurement: its only live caller is the on-demand gap gauge, so it is unwatched rather than unrunnable, and that distinction is stated rather than flattened
- [x] A ratchet gates on MOVEMENT rather than on the count, so a real pre-existing backlog can be wired without painting the suite permanently red
- [x] The ratchet fails when the backlog GROWS — a standing guard that loses its last live caller is detected
- [x] The ratchet fails when the backlog SHRINKS — a stale baseline entry is refused, because an allowlist without stale-entry detection becomes an amnesty (PL-004's unbuilt half)
- [x] The baseline is DERIVED from the census's own `--json`, never hand-typed, and the tool REFUSES to mint a baseline on the fly rather than silently recording whatever today happens to be
- [x] Wired into `tests/run-bridge-tests.sh` over the full population, with a failure message that names the direction and forbids silent re-baselining
- [x] Negative controls prove both directions bite, and the restored baseline returns to green
- [x] Full bridge suite green; zero bytes changed in `src/`, `docs/standards/`, `examples/`, `.agentic-framework/`, or any AEF digest-pinned fixture

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
# PL-161 applies to this block itself: these run ONCE, at completion. The standing guard is
# the suite leg below — that is the one that keeps running after this task is archived.

# The census parses and the ratchet is clean against the committed baseline
python3 -c "import ast;ast.parse(open('tools/_t451-unwired-guard-census.py').read())"
python3 tools/_t451-unwired-guard-census.py --ratchet > /dev/null

# The ratchet is INVOKED BY THE SUITE — the leg this whole task exists to add
grep -q '_t451-unwired-guard-census.py' tests/run-bridge-tests.sh
grep -q -- '--ratchet' tests/run-bridge-tests.sh

# The baseline is derived, non-empty, and carries its provenance header
test -s tools/unwired-guard-baseline.txt
grep -q 'DERIVED from tools/_t451-unwired-guard-census.py --json' tools/unwired-guard-baseline.txt

# The reimplementation is gone (two censuses of one population is the reintroduction shape)
test ! -e tools/check-instrument-reachability.py

# NEGATIVE CONTROL A — backlog GROWS. Drop a real finding from the baseline; must exit non-zero.
# The grep guards the control: if the entry were absent the sed would change nothing and this
# leg would pass while testing nothing, which is the failure mode the task is about.
bash -c 'set -e; cp tools/unwired-guard-baseline.txt /tmp/t491b.bak; trap "cp /tmp/t491b.bak tools/unwired-guard-baseline.txt; rm -f /tmp/t491b.bak" EXIT; grep -q "_undo-verify-cdp.mjs" tools/unwired-guard-baseline.txt; grep -v "_undo-verify-cdp.mjs" /tmp/t491b.bak > tools/unwired-guard-baseline.txt; python3 tools/_t451-unwired-guard-census.py --ratchet > /dev/null 2>&1 && exit 1 || exit 0'

# NEGATIVE CONTROL B — baseline STALE. Add an entry that is not a finding; must exit non-zero.
bash -c 'set -e; cp tools/unwired-guard-baseline.txt /tmp/t491b.bak; trap "cp /tmp/t491b.bak tools/unwired-guard-baseline.txt; rm -f /tmp/t491b.bak" EXIT; echo "_t491-not-a-real-finding.py" >> tools/unwired-guard-baseline.txt; python3 tools/_t451-unwired-guard-census.py --ratchet > /dev/null 2>&1 && exit 1 || exit 0'

# NEGATIVE CONTROL C — a missing baseline is REFUSED (rc 2), never minted on the fly.
# NO `set -e` here, deliberately: the command under test is EXPECTED to exit non-zero, and
# under set -e the shell aborts at that line before `test $? -eq 2` ever runs. Written that
# way first, it exited 2 — the right-looking outcome for a reason unrelated to the assertion,
# which is the exact failure this task is about, reproduced inside its own control.
bash -c 'mv tools/unwired-guard-baseline.txt /tmp/t491b.bak; python3 tools/_t451-unwired-guard-census.py --ratchet > /dev/null 2>&1; rc=$?; mv /tmp/t491b.bak tools/unwired-guard-baseline.txt; test $rc -eq 2'

# Protected paths untouched
git diff --quiet HEAD -- src/ docs/standards/ examples/ .agentic-framework/
git diff --quiet HEAD -- tests/fixtures/aef-bpmn/typed-events.bpmn tests/fixtures/aef-bpmn/boundary-events.bpmn
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

### 2026-08-14 — the thing I was asked to build already existed and was better

- **What changed:** T-491 was filed on the claim that PL-148's remedy "has never been built as a
  population-wide check". `tools/_t451-unwired-guard-census.py` is that check, built by T-451,
  and it already contained every distinction I was rediscovering — the one-shot Verification
  semantics, the teeth/mutation naming convention, derived-not-restated denominators, and its
  own stated LIMIT. I found it only because my draft's orphan list printed its filename.
- **Plan impact:** the entire deliverable inverted. Not "build the check" but "the check exists,
  is correct, reports 37, and nothing schedules it". I deleted my reimplementation rather than
  keeping it — AEF reported the reintroduction shape in their own tree at rail 611 (a fix present
  in one reader, dropped 4,400 lines away by a rewrite that did not carry it), and two censuses
  of one population is that shape at file scale.
- **Triggered:** PL-023 earned its keep again. The cost of not checking first was two wrong
  population definitions and a "115 orphans" headline; the cost of checking was one grep.

### 2026-08-14 — unwatched is a distinct state from unrunnable, and it needed naming

- **What changed:** the census's only live caller is the G-034 gap gauge in `lib/gaps.py`, which
  executes when somebody asks to close that gap. That is a genuine call path — strictly better
  than a completed task's Verification block, which nothing can re-run — but it is not a
  schedule. My first checker modelled reachability as a binary and would have called this either
  "reached" (hiding that nobody watches it) or "unreached" (false, there is a live caller).
- **Plan impact:** the finding is not that the census is dead. It is that it has been measuring a
  real, growing backlog since T-451 and reporting to nobody. T-490 and T-448 were both found by
  hand during that interval and the census had both the whole time.
- **Triggered:** the ratchet gates on MOVEMENT rather than the count, which is what makes a
  pre-existing backlog wirable at all.

### 2026-08-14 — my own negative control passed for the wrong reason

- **What changed:** control C asserts that a missing baseline is REFUSED with rc 2. I wrote it as
  `set -e; ...; python3 ...; test $? -eq 2`. Under `set -e` the shell aborts at the python line —
  which is expected to exit non-zero — so `test` never ran. The leg exited 2: non-zero, wrong
  reason, asserting nothing.
- **Plan impact:** none to the deliverable, but it is the third instance this week of a control
  that produces the right-looking outcome through a mechanism unrelated to its subject (PL-179's
  shape). It happened inside the task whose entire subject is instruments that report without
  doing their job, roughly an hour after I wrote that sentence down.
- **Triggered:** the fix is one line, and the comment above it now says why `set -e` is wrong
  here, because the next person will write it the same way.

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

### 2026-08-13T11:59:31Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-491-assert-instrument-reachability-populatio.md
- **Context:** Initial task creation

### 2026-08-14T06:01:33Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fe828efb
- **Timestamp:** 2026-08-14T06:14:12Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** yes
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 10
     - evidence: `python3 tools/_t451-unwired-guard-census.py --ratchet > /dev/null`

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -f`

### 2026-08-14T06:14:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
