---
id: T-509
name: "Every teeth script but one is unwatched, and the census cannot see them: *teeth*
  is excused as one-shot by design, an assumption T-508 disproved by wiring one"
description: >
  Every teeth script but one is unwatched, and the census cannot see them: *teeth*
  is excused as one-shot by design, an assumption T-508 disproved by wiring one

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T05:39:57Z
last_update: '2026-08-16T13:58:57Z'
date_finished: 2026-08-15T06:04:59Z
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
  - ts: '2026-08-16T12:34:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t509-instrument-sweep.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/run-bridge-tests.sh,tools/_t509-instrument-sweep.sh); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-509: Every teeth script but one is unwatched, and the census cannot see them: *teeth* is excused as one-shot by design, an assumption T-508 disproved by wiring one

## Context

T-508 wired one teeth script into the bridge suite and noted, in a comment that runs, that
it was the only one. This is that note cashed out.

**Measured:** 24 `tools/*teeth*` scripts exist. **22 had no standing caller.** Running all
24 left `git status` byte-identical, so they are hermetic — and **19 pass today**. The
naming convention by which `_t451-unwired-guard-census.py` excuses every `*teeth*` file as
"one-shot by design" is therefore false for 19 of 24: they are re-runnable and were simply
never called. PL-192 (T-495) already stated the principle — *an instrument excused by its
own watchdog's naming convention must be scheduled deliberately* — and applied it to the one
probe that prompted it. This applies it to the population.

**What the unwatched state was hiding, found in the first sweep:**
`_t364-t308-teeth.py`'s control leg is red — `maps=24 identical=0 drifted=24`. The gate it
tests is fine (`_t308-export-byte-identity-cdp.mjs` exits 0 today); it is the **teeth
script's own stored reference shas that went stale**. A pinned reference decaying silently,
inside the instrument whose job is to prove another instrument works — PL-200's class, one
level further in than where T-508 found it, and unobservable for the same single reason:
nothing ran it.

> **CORRECTION 2026-08-15 (T-510) — the sentence in bold above is wrong, and it is left
> standing so the correction has something to point at.** `_t364-t308-teeth.py` stores no
> reference shas. Its `run()` passes `REF = "3bf37909~1"` to `_t308`, so the comparison is
> **current build vs a pinned git ref**, not build vs stored digest. Reproduced properly:
> all 24 maps drift, and every one by **exactly +51 bytes** — commit `4c40414c` (T-399)
> adding `exporter="aef-workflow-designer"` to every export, 18 spaces + 32 chars + newline.
> That uniformity is the tell; decay is never uniform, a shipped line always is.
>
> Two consequences. **(1)** The red is **expected, not a regression** — the control's
> `identical=24` became false by design the moment T-399 landed. **(2)** The remedy stated
> below ("a re-pin") is wrong too: moving `BASELINE_REF` past the T-364 repair makes the
> injected third-party fixture byte-comparable on *both* sides, so `unusable` goes to 0 and
> the teeth go red for the *opposite* reason. The script's docstring already says so and
> prescribes a new genuinely-unstable injection instead.
>
> How the wrong claim was reached: I ran `_t308` **without** the `REF` argument, saw rc=0,
> and concluded "the gate is fine, so the teeth's own baseline is stale" — inferring a
> tool's failure mechanism from an exit code obtained by invoking it differently than its
> caller does. The conclusion *a pinned baseline decayed silently* survived; the mechanism
> published for it did not. See **PL-204**.

**Not the same finding as T-508.** There the instrument was correct and unread. Here the
population was assumed one-shot by a naming rule that nobody re-checked after the files
stopped being one-shot. Reachability was not the question; the *category* was.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The population is established before anything is built.** Every `tools/*teeth*`
      script is enumerated, and for each one it is stated whether a ROOT_SOURCE
      (`tests/**`, `.context/cron/*`, `.claude/settings.json`,
      `.agentic-framework/agents/**/*.sh`) reaches it. A count with no denominator is the
      failure T-505's census exists to avoid.
- [x] **PL-192 is read and its verdict honoured before I write a line.** T-495 already
      learned "an instrument excused by its own watchdog's naming convention must be
      scheduled" — if PL-192 (or T-495's delivered work) already prescribes or implements
      the remedy, this task ADOPTS it rather than re-deriving it. T-491 and T-508 were both
      cases of building a replacement for something better that already existed; two in
      four days makes checking first a rule, not a courtesy.
- [x] **The exemption is proven wrong on evidence, not on principle.** At least one
      currently-excused teeth script is shown to be genuinely re-runnable (it passes today
      when run), which is what makes "one-shot by design" false for it. A blanket claim
      that the convention is wrong, with no instance, is not a finding.
- [x] **Whatever is wired does not go red on a pre-existing backlog.** Any new standing leg
      gates on movement or on a green-today subset, never on a count the operator alone can
      drain — the T-491 rule, restated because T-508 needed it again.
- [x] **Cost is measured, not assumed.** Wall-clock of every teeth script proposed for the
      suite is recorded; anything that would make the bridge suite materially slower is
      reported as a trade-off for the operator rather than silently added.
- [x] **The census's own blind spot is addressed or explicitly deferred with a reason.**
      `_t451-unwired-guard-census.py` excuses `*teeth*` by naming convention, so wiring
      teeth is invisible to the very instrument that watches wiring. Either the exemption
      is narrowed, or the decision to leave it is recorded as a decision.
- [x] Bridge suite green; both existing ratchets (G-015 hygiene, T-451 unwired) still green.

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

# ── PL-200 APPLIED TO THIS BLOCK ─────────────────────────────────────────────────────
# `bash tools/_t509-instrument-sweep.sh` is deliberately NOT a leg here, and neither is the
# unwired ratchet. Both assert global, always-moving state: the sweep goes red when ANY of
# 19 instruments regresses for ANY reason, none of which is T-509's doing. Under a
# CTL-013-style daily re-runner they would fail with this task's id attached to somebody
# else's change — G-015 shape (a), the reason T-093 sat red for 35 days. They are wired into
# the bridge suite by this change, which is the durable home for a global assertion.
# What is below are properties of THIS change, plus the sweep's own controls, which are
# hermetic (they mutate a scratch copy or a file they restore, and assert on the message).
#
# `- [ ]` counts are also avoided: this task's population (24 teeth scripts) is exactly the
# kind of literal T-508 added a detector for. The gate would flag it, correctly.

test -f tools/_t509-instrument-sweep.sh
grep -q '_t509-instrument-sweep.sh' tests/run-bridge-tests.sh
# The exclusion list must stay REASONED: every entry carries a '|' and a non-empty reason.
python3 -c "import re,sys; s=open('tools/_t509-instrument-sweep.sh').read(); m=re.search(r'EXCLUDE=\((.*?)\n\)', s, re.S); ls=[l for l in m.group(1).strip().splitlines() if l.strip()]; bad=[l for l in ls if '|' not in l or len(l.split('|',1)[1].strip(' \"'))<40]; sys.exit(1 if (bad or len(ls)<5) else 0)"
# Each excluded script must still EXIST — the stale-exemption check, asserted independently
# of the tool so a bug in the tool cannot certify its own exclusion list.
python3 -c "import re,os,sys; s=open('tools/_t509-instrument-sweep.sh').read(); m=re.search(r'EXCLUDE=\((.*?)\n\)', s, re.S); ns=[l.strip().lstrip('\"').split('|')[0] for l in m.group(1).strip().splitlines() if l.strip()]; missing=[n for n in ns if not os.path.isfile('tools/'+n)]; sys.exit(1 if missing else 0)"
# The stale branch must exit BEFORE the run loop, or its exit is unreachable whenever any
# script also fails — the control-passes-for-the-wrong-reason trap, caught here in the act.
python3 -c "import sys; s=open('tools/_t509-instrument-sweep.sh').read(); i=s.index('stale exclusion(s)'); j=s.index('for f in \"\${ALL[@]}\"'); sys.exit(0 if i<j else 1)"
# The sweep refuses rather than passing when it can do nothing — abstention is not a verdict.
grep -q 'A sweep over nothing is not a pass' tools/_t509-instrument-sweep.sh
grep -q 'every script was excluded' tools/_t509-instrument-sweep.sh
# The suite leg states the MEASURED suite delta, not the tool's standalone stopwatch.
grep -q '103s -> 168s' tests/run-bridge-tests.sh

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

### 2026-08-15 — the census exemption is left in place, deliberately

- **Chose:** wire the runnable teeth scripts into the bridge suite, and LEAVE
  `_t451-unwired-guard-census.py`'s `*teeth*`/`*probe*`/`*mutation*` exemption exactly as
  it is.
- **Why:** the two remedies solve different halves and only one is mine to take. Wiring
  makes the instruments RUN. Narrowing the exemption would make their unwatched state
  VISIBLE — it would move ~22 files into the census findings, which is a **+22 movement on a
  ratchet that fails in both directions**, forcing a same-change re-baseline of a register
  whose entire value is that it is not re-baselined casually. That is a change to the
  project's backlog accounting, not a bug fix, and the file says in its own header: "THIS IS
  NOT AN APPROVAL LIST." After this change the practical gap is much smaller anyway — 19 of
  24 now have a live caller, so the exemption is hiding 5 files, all of them named with
  reasons in the sweep's own exclusion list.
- **Rejected:** narrowing the exemption in this task. It would have discharged AC6 more
  literally while making the census noisier and the baseline weaker, and it bundles a
  register-accounting decision into a wiring task. One task, one deliverable.
- **Left for the operator:** whether `_t350-teeth.sh` and `_t351-teeth.sh` should ever run
  unattended. Both drive live servers; `_t350`'s own header records that an earlier mutant
  with a silently-failed safety stub **deleted this repository** (recovered from origin).
  That is not a risk an agent should wire into a suite on initiative.
- **Also left for the operator:** `_t364-t308-teeth.py`'s ~~stale reference shas~~ pinned
  `BASELINE_REF`. Its control reports `identical=0 drifted=24` while the gate it tests
  passes rc=0 today, so the repair is ~~a re-pin of the teeth's stored baseline~~ **a new
  genuinely-unstable injection** — a decision about what the reference SHOULD be, not a
  mechanical fix. **Corrected 2026-08-15 (T-510)** — see the correction block above: there
  are no stored shas, the ref is the git ref `3bf37909~1`, the drift is T-399's +51 bytes
  on every document, and a bare re-pin makes the teeth red for the opposite reason.

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

### 2026-08-15T05:39:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-509-every-teeth-script-but-one-is-unwatched-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c2bcba74
- **Timestamp:** 2026-08-15T06:05:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T06:04:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
