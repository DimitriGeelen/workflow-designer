---
id: T-666
name: "A dead control and an honest abstention both exit 2, so the sweep tells the reader to trust a dead instrument"
description: >
  A dead control and an honest abstention both exit 2, so the sweep tells the reader to trust a dead instrument

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
created: 2026-09-01T11:52:02Z
last_update: 2026-09-01T12:10:03Z
date_finished: 2026-09-01T12:10:03Z
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

# T-666: A dead control and an honest abstention both exit 2, so the sweep tells the reader to trust a dead instrument

## Context

`_t509-instrument-sweep.sh` sorts every teeth script's exit code into buckets. One bucket is
wrong, and it is wrong because **three different conditions are signalled with two exit
codes.**

    rc 0    passed
    rc 1    REGRESSED  — "a real regression in the thing it guards"
    rc 2    ABSTAINED  — "It refused to certify. Its abstention IS its output; read that
                          output rather than treating this as a regression."
    rc 124  DID NOT FINISH (T-548)

`rc 2` carries two incompatible meanings today:

**(a) an honest refusal.** `_t430-abstention-teeth.sh` and `_t423-additive-export-teeth.py`
are parameterised; run bare they correctly decline rather than invent an input. The sweep's
sentence is exactly right for these.

**(b) a dead control.** Seven scripts print `TEETH BROKEN` and exit 2 when their *unmutated*
control leg fails — the state in which every mutation below is meaningless:

    _t358-teeth.py  _t364-t308-teeth.py  _t364-tie-guard-teeth.py  _t366-uid-shape-teeth.py
    _t367-injection-footprint-teeth.py  _t499-ownership-teeth.py  _t585-census-teeth.sh

For (b) the sweep's sentence is backwards. Nothing regressed in *the thing it guards*; the
**guard itself is dead**, which is a strictly worse finding, and the reader is explicitly
advised not to treat it as a regression.

That is the mechanism PL-306 named, now located precisely. It is *not* that abstention
"reads as acceptable" — T-548 already made abstention exit 3 and print "This is not a
green", and that part of my PL-306 wording was too loose. It is that a **dead control is
filed as an honest abstention**, and an honest abstention is a state that legitimately needs
no action.

Measured cost: `_t358-teeth.py` guards T-358's lane-fabrication diagnosis and sat dead for
six days (T-665). It was never excluded and ran on every sweep. Every one of those runs saw
`rc 2`, printed `ABSTAINED`, and told the reader not to read it as a regression.

**A third inconsistency, in the same file.** `_t358-teeth.py:92` and `:102` raise
`SystemExit("TEETH BROKEN — anchor not found …")`. A *string* `SystemExit` exits **1**. So
one file signals a dead control as 2 in one place and as 1 in another, and the sweep files
those two identical conditions in two different buckets.

**What this task changes.** A dead control gets its own exit code, `4`, and its own bucket.
It is a finding, not an abstention: the sweep exits 1 for it, under its own heading with its
own sentence — never the "regression in the thing it guards" sentence, which is as false for
a dead control as it is for a timeout.

**Not in scope:** `rc 3` (`_t358`'s `COULD-NOT-MEASURE`, added by T-665) falls to the sweep's
`*)` catch-all and is reported as REGRESSED. That is a mislabel too, but it errs *loud*, and
one bug is one task. Filed as a note here, not fixed.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The defect is proven by execution **before** it is fixed: a teeth script whose control
      is deliberately broken is shown, against the PRE-FIX sweep, to be reported as
      `ABSTAINED` carrying the "rather than treating this as a regression" advice. The
      evidence line is recorded in this task.

      **DONE.** A one-line probe printing `TEETH BROKEN …` and exiting 2 was run against the
      unmodified sweep in a throwaway tree. Verbatim:

          RAN 1, passed 0, regressed 0, did-not-finish 0, abstained 1
          SWEEP INCOMPLETE — no regression found, but the sweep did not cover everything
            - ABSTAINED: _zzdead-teeth.sh (rc=2, declined to certify)
                It refused to certify. Its abstention IS its output; read that output
                rather than treating this as a regression in what it guards.
          sweep rc=3

      A dead guard, reported as an honest refusal, with the reader told not to treat it as
      a regression. That is the six days of T-665 reproduced in one command.

- [x] `_t509-instrument-sweep.sh` gains a bucket for rc 4 (`DEAD CONTROL`), documented in its
      `EXIT CODES` header, reported under its own heading with its own sentence, and exiting
      **1** — not 3, because a dead guard is a finding, not merely uncovered ground.

      **DONE.** A `PROBE EXIT CODES` block now documents what a teeth script tells the sweep
      (0/1/2/**4**/124) separately from the sweep's own codes. `DEAD` is its own array, its
      own `case` arm, its own count on the RAN line, and its own report section. Both the
      DEAD and REGRESSED sections now fall through to one combined `exit 1` at the bottom
      rather than exiting inline — PL-203 again: an exit inside the first branch makes the
      second unreachable in exactly the runs where both are true.

- [x] The literal sentence "a real regression in the thing it guards" is NOT printed for a
      dead control, exactly as it is already withheld from timeouts and abstentions. Two
      probes assert that string is withheld; the assertion is extended, never weakened.

      **DONE, and shown to be load-bearing.** `_t548` legs 7 and 8 pass `REGRESSION_PHRASES`
      in `must_not`. Run against the PRE-FIX sweep the new legs go red naming exactly that:
      `dead-control: output asserts 'a real regression in the thing it guards'. That
      sentence is FALSE here`. Legs 1–6 stay green against that same old sweep, so the new
      legs are discriminating rather than riding along.

- [x] All seven scripts that detect a dead control exit 4 for that condition — including the
      two bare-string `SystemExit` sites in `_t358-teeth.py` that exit 1 today. Verified by
      **execution** for at least one, not by reading the diff.

      **DONE — and it turned out to be eight, which is the finding worth keeping.** The
      seven were selected by grepping the *string* `TEETH BROKEN`. That is a
      hand-maintained claim, the same shape as PL-305's stale exclusion and T-665's frozen
      copy list, and it under-selected: running the repaired sweep over the real tree
      surfaced `_t534-d2-queue-tier-teeth.py`, which announces the identical condition in
      different words — *"a D2 line was emitted but did not match the expected shape, so the
      legs below would be asserting against a failed parse"* — and exited 2. Its own regex
      has aged out of agreement with the audit line it parses. Its `refuse()` has three call
      sites with two different meanings; only the stale-anchor one was moved to a new
      `dead()`, leaving "the subject is not here" and "the audit said nothing" correctly at 2.
      Verified by execution: `_t534` rc **2 → 4**, printing `TEETH BROKEN`.

      `_t358`'s two bare-string sites are converted: `SystemExit("…")` exits **1**, so those
      dead-instrument conditions were being reported as regressions in the guarded subject.

- [x] Every one of the seven still passes on the real tree after the change: the new code is
      on the failure path only, and a repair that reds the population is not a repair.

      **DONE. 7/7 green**, run individually: `_t358`, `_t364-t308`, `_t364-tie-guard`,
      `_t366`, `_t367`, `_t499`, `_t585`. `_t534` is legitimately red (rc 4) — that is a
      pre-existing broken instrument now visible, not damage from this change; it was
      reporting rc 2 into the abstained bucket before.

- [x] `_t548-sweep-classification-teeth.py` gains a leg proving an rc-4 probe is filed as DEAD
      and **not** as ABSTAINED, so the next collapse of these two states is a regression
      rather than a comment.

      **DONE — two legs, not one.** Leg 7 drives the real sweep over a synthetic rc-4 probe
      and asserts `DEAD CONTROL`, `SWEEP FAIL`, rc 1, the probe named, and *neither*
      `ABSTAINED` *nor* the regression sentence. Leg 8 puts a dead control and an honest
      abstention in the same run and requires both to be named with the exit code following
      the dead one — the coexistence case, because collapsing the two under load is how this
      defect returns. `_t548` reports **8 legs green**. No separate `_t666` instrument was
      written: `_t548` already owns the question "what does the sweep call this", and a
      second tool answering the same question is how two answers start disagreeing.

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
         1. Run `bin/fw reviewer T-666`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-666 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# 1. The sweep documents the new probe exit code where a reader will find it.
grep -q "4  DEAD CONTROL" tools/_t509-instrument-sweep.sh
# 2. The discrimination itself, DRIVEN rather than read. Legs 7 and 8 of the classification
#    teeth build a synthetic tree, run the REAL sweep in it, and assert that an rc-4 probe
#    is filed as DEAD CONTROL and named, that the sweep exits 1 for it, that an honest
#    refusal in the same run is still reported as ABSTAINED, and that neither the
#    abstention text nor the regression sentence is applied to the dead one.
#    (No separate _t666 instrument: _t548 already owns "what does the sweep call this",
#    and a second tool answering the same question is how two answers start disagreeing.)
python3 tools/_t548-sweep-classification-teeth.py
# 3. No dead-control site in the population still signals with the old codes: rc 2 (which
#    reads as an honest abstention) or a bare-string SystemExit (which exits 1, a claim
#    about the guarded subject). `_t585` line 29 legitimately keeps rc 2 — its tool is
#    missing, so nothing ran; that is a refusal, not a dead control, and is not matched here.
sh -c '! grep -nE "SystemExit\(2\)|SystemExit\(f?\"TEETH BROKEN|sys\.exit\(2\)" tools/_t358-teeth.py tools/_t364-t308-teeth.py tools/_t364-tie-guard-teeth.py tools/_t366-uid-shape-teeth.py tools/_t367-injection-footprint-teeth.py tools/_t499-ownership-teeth.py'
# 4. The population is still green on the real tree. The change is on their FAILURE path,
#    so a red here means the repair broke the thing it was repairing. Each rc is read from
#    the process, never through a pipeline (rail 553/557), and the loop's own verdict is
#    the line's exit code.
sh -c 'b=0; for f in _t358-teeth.py _t364-t308-teeth.py _t364-tie-guard-teeth.py _t366-uid-shape-teeth.py _t367-injection-footprint-teeth.py _t499-ownership-teeth.py _t585-census-teeth.sh; do case "$f" in *.py) r=python3;; *) r=bash;; esac; timeout 300 "$r" "tools/$f" >/dev/null 2>&1 || { echo "NOT GREEN: $f rc=$?"; b=1; }; done; exit $b'
# 4. The classification teeth still pass, including the new DEAD leg.
python3 tools/_t548-sweep-classification-teeth.py

## RCA

**Symptom:** `_t358-teeth.py` — the teeth guarding T-358's lane-fabrication diagnosis, the
arc's central open task — was dead for six days. It was never excluded from the sweep and
ran on every single sweep run in that window. Every run reported it as `ABSTAINED` and
advised the reader that its abstention "IS its output; read that output rather than treating
this as a regression in what it guards."

**Root cause:** one exit code carrying two opposite claims. `rc 2` meant both *"I am
parameterised and correctly decline to invent an input"* (needs no action) and *"my control
leg ran and failed, so nothing below it proves anything"* (the instrument is broken). The
sweep could only see the code, so it applied the first reading to both.

**Why structurally allowed:** the sweep's abstention text was written in T-548 as a *repair*
— generalising an exemption that had been granted to one file by name. The reasoning was
right and the wording was right for the case in hand; it simply covered a second case nobody
had separated out. There was no way to detect this from the sweep's side, because a probe
declining and a probe dying are indistinguishable when both say `2` and the sweep never
reads their words. And `_t548`'s teeth pinned the *wording* precisely — six legs, all green
— which made the file look thoroughly guarded while the missing distinction sat outside
every leg's reach.

**Prevention:** a dedicated code (4) so the two claims cannot be confused by a caller that
reads only the exit status, plus `_t548` legs 7 and 8, which drive the real sweep and assert
the discrimination in both directions — including the coexistence run, where the failure
mode is one state quietly absorbing the other. Both legs are shown red against the pre-fix
sweep, so they are not decorative.

**Second-order finding, kept because it is the more general one.** The population of
affected files was selected by grepping the string `TEETH BROKEN`. That is a hand-maintained
claim — the same shape as PL-305 (a stale exclusion reason), T-663 (an aged pin) and T-665
(a frozen copy list) — and it under-selected by one. The eighth, `_t534`, was found by
*running the repaired sweep over the real tree*, i.e. by the artifact rather than by the
description of it. Third time in two days that deriving from the artifact beat restating it,
and the first time the lesson caught an error inside a task written to apply the lesson.

## Evolution

### 2026-09-01 — the fix's own population was selected by a stale claim
- **What changed:** grepping `TEETH BROKEN` to enumerate dead-control sites is itself the
  hand-maintained-claim antipattern. Running the repaired instrument over the real tree found
  a case the grep missed (`_t534`, same condition, different words).
- **Plan impact:** AC-4 said "all seven"; it is eight, and the AC now records how the eighth
  was found rather than quietly restating the number.
- **Triggered:** `_t534`'s own regex is stale against the audit's current D2 line — a
  genuinely broken instrument, pre-existing, now reported as DEAD instead of hidden in the
  abstained bucket. Filed separately; not fixed here (one bug, one task).

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
     fw inception decide T-666 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T11:52:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-666-a-dead-control-and-an-honest-abstention-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fce93417
- **Timestamp:** 2026-09-01T12:11:05Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-01T12:10:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
