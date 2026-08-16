---
id: T-432
name: "Full fw audit reports 60 FAIL across non-structure sections - never assessed"
description: >
  The pre-push gate runs 'fw audit --sections structure' and has read 19 PASS / 3
  WARN / 0 FAIL for weeks. Running the FULL audit during T-431 returned Pass 124 /
  Warn 33 / Fail 60. Nothing in this project has ever looked at the 60, because the
  only audit anyone runs is the narrow one the push hook invokes. Unknown whether
  they are pre-existing, cosmetic, or real. First step is a per-section breakdown,
  not a fix: 'fw audit' section by section, counting FAILs per section, and a statement
  of which sections the push gate never runs. Same family as the T-429/T-431 findings
  - a green that was never the whole question.

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T15:41:06Z
last_update: '2026-08-16T14:33:03Z'
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
  - ts: '2026-08-16T12:33:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 4
      F3: 0
      F1: 1
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=4 
      (body:auto-promote-class-eligibility); F3=0 (no-signal); F1=1 
      (body/components:context-fabric-incidental); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 1
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=1 
      (body/components:component-fabric-incidental); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py); 
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=1 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-432: Full fw audit reports 60 FAIL across non-structure sections - never assessed

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] A per-section breakdown is produced: for every section `fw audit` supports, the
      PASS/WARN/FAIL counts, recorded in the task — the whole point is the denominator, so
      a total without the split repeats the defect that motivated this task
      **DONE** — see `## Findings`. 18 sections emit output; **all 60 FAILs are in one**.
- [x] The set of sections the **push gate** runs is stated explicitly, alongside the set it
      does not, extracted from the hook rather than retyped from memory
      **DONE** — `.git/hooks/pre-push:306` reads `"$AUDIT_SCRIPT" --section structure`.
      One section of nineteen. Note the flag is `--section`, singular; this task's own
      filing said `--sections`, which is the kind of detail that must be extracted.
- [x] Each FAIL is classified as one of: pre-existing (present before this project's first
      commit to the file it names), self-inflicted, or a check that cannot pass in this
      project by design — with the evidence for the classification, not an assertion
      **DONE** — two classes, both with evidence. See `## Findings`.
- [x] Any FAIL that names a file under `.agentic-framework/` is reported upstream rather
      than fixed locally, per the vendored-tree boundary (T-427, DM 522 §1)
      **DONE — vacuously: zero of the 60 name a file under `.agentic-framework/`.** Stated
      as a measurement rather than left silent, because "nothing to report upstream" and
      "I did not look" render identically in a ticked box.
- [x] No `--force`, no `--skip-*`, and no widening or narrowing of the push gate's section
      list under agent initiative — the gate's scope is an operator decision and this task
      only measures it
      **DONE** — nothing was fixed, migrated or re-scoped. The audit ran read-only with
      `--output` pointed at scratch so it did not overwrite the tracked audit record.

<!-- SCOPE NOTE: this task MEASURES. It does not fix the 60. Deciding which of them are
     worth fixing needs the breakdown to exist first, and bundling the fix into the
     measurement is how a task with an unknown denominator becomes a task with an unknown
     size. Fixes get their own tasks, one root cause each. -->

### Human
- [ ] [REVIEW] Whether the push gate should keep running `--sections structure` only
      **Steps:**
      1. Read the per-section breakdown this task writes into `## Findings`
      2. Decide: (a) leave the gate narrow and treat the rest as advisory, (b) widen it to
         the sections whose FAILs turn out to be real, or (c) widen it fully and fix
         whatever blocks the push
      **Expected:** one of a/b/c recorded here, with a one-line reason
      **If not:** the gate stays as it is and the 60 stay unwatched, which is the status
      quo this task exists to make visible rather than to change unilaterally

## Findings

### The headline: 60 FAILs are 2 problems, not 60

    SECTION                     PASS  WARN  FAIL
    structure                     19     3     0   <-- the ONLY section the push gate runs
    task compliance                1     0     0
    task quality                   1     0     0
    git traceability               2     1     0
    enforcement                    4     0     0
    learning capture               2     0     0
    episodic memory                3     0     0
    observation inbox              1     0     0
    concerns register              2     0     0
    graduation pipeline            1     0     0
    inception research             0     3     0
    research persistence oe        5     0     0
    oe-fast: 30-minute control     4     0     0
    oe-hourly: hourly control      2     0     0
    oe-daily: daily control       73    25    60   <-- every FAIL is here
    oe-weekly: weekly control      1     0     0
    orchestrator arc               1     0     0
    arc-completion                 1     0     0
    TOTAL                        123    32    60

**17 of 18 sections are clean.** The alarming number came from reading a total without its
split — which is the same defect the T-429/T-431 work was about, committed by me in this
task's own filing description. "60 FAIL across non-structure sections" implied breadth.
There is none.

### Class 1 — CTL-030 × 59: pre-existing residue, source already plugged

Every one reads: *`T-NNN is in .tasks/completed/ but stored horizon='now'`*.

Evidence for the classification, in order:

1. **The check is sound.** `audit.sh:3665` (CTL-030, T-2162, arc-009 Slice 3) — completed
   tasks must carry null/absent horizon because render derives `past` from `_location`.
2. **The leak has a known source.** `update-task.sh:1613` auto-promotes `horizon: now` on
   `started-work` (the T-1068 invariant). Every task that is worked on gets the field set.
3. **The source is already plugged**, upstream and in this vendored copy:
   `update-task.sh:1896` writes `horizon: null` at completion, with a comment naming this
   exact defect as a prior *8-instance* CTL-030 class (T-2168/T-2180/T-2182/T-2196/…).
4. **The plug is working here, measured today.** T-427, T-429 and T-431 all completed with
   `horizon: null`.
5. **Denominator:** 374 completed tasks, **315 correct, 59 stale** — so this is 16%
   residue, not a systemic failure.

**Verdict: pre-existing, closed at source, mechanically fixable.** The remedy is a
one-time backfill of 59 completed task files. Not done here — this task measures, and
editing 59 completed records is its own task with its own blast radius.

> **SUPERSEDED 2026-08-16 — the backfill happened, and this task did not notice.** T-434
> (`5bf8fb26`, **2026-08-11**) backfilled all 59. Its own commit message reads *"full audit
> 60 FAIL to 1, CTL-030 now PASS"*. Re-measured today: **466 completed tasks, 466 carrying
> `horizon: null`, 0 stale**, and the full audit reports `[PASS] CTL-030: All completed/
> tasks have null/absent stored horizon`. Class 1 is closed.

One nuance worth recording: the 59 are **not** a contiguous historical block. 247 tasks
with *lower* IDs are clean and 68 with *higher* IDs are clean. So "everything before date
X" is the wrong model; what these 59 share is being completed in the window between the
field existing and the plug landing.

### Class 2 — D2 × 1: not a defect, a working signal

    D2: Human review queue — 2 task(s) waiting >30d: T-093(37d) T-178(31d)

This control is *designed* to fail when the queue ages. It is reporting truthfully, and it
clears when the operator reviews T-093 and T-178 — not when anything is fixed.

Counting it alongside the other 59 is itself a category error: one is stale data, the
other is a live queue. A "FAIL count" that sums them answers no question anybody has.

### What this means for the gate decision

Widening the push gate to `oe-daily` today would **block every push** until 59 completed
task files are edited — high cost, and the safety value is near zero because the records
are terminal and the source is plugged. Widening it *after* a backfill would cost nothing
and would catch the next regression of a class that has already recurred 8+ times upstream.

> **SUPERSEDED 2026-08-16 — the prerequisite is already met, so the cost is now zero.**
> The backfill landed under T-434 on 2026-08-11. There is no longer a sequencing question:
> the "widen it *after* a backfill" branch is the one we are standing in.

### Addendum (2026-08-11, OBS-027 folded in here under T-436) — a section list may not reproduce the full run

Measured under T-434, and it bears directly on the option the Human AC is choosing
between: **a section's audit result depends on whether it is run ALONE or inside a
FULL run.**

`fw audit --section oe-daily` reports 61 pass / 25 warn / 0 fail and never emits the
D2 human-review-queue check at all. The same section inside a full run emits D2 and
reports different pass counts.

This nearly produced a false claim in T-434: the before-number (60 FAIL) came from a
full run, and taking the after-number from the section-alone run would have compared
two different instruments and reported 60 → 0 instead of 60 → 1.

**Consequence for option (b), widening the gate to a section list:** a gate built from
sections can be green while the full audit is not. Whatever is chosen, the gate and the
number the project steers by have to be the same instrument, or the gate is measuring
something nobody reads. T-438 sharpened the same point from the other end — the
familiar "Warn: 3" is a `--section structure` figure; the full audit reports 34.

This is context for the decision, not a change to it. The three options stand as written.

### DISSOLVED 2026-08-16 (measured under T-534) — the addendum above is wrong, and it was the ground for rejecting (b)

**D2 is not an `oe-daily` check.** It sits inside `if should_run_section "discovery"`
(`audit.sh:3915`), and the report prints it under `=== DISCOVERY: OMISSION DETECTION ===`
— in the header, plainly, in every full run this task ever read.

Both halves of the claim fail:

| claimed | measured 2026-08-16 |
|---|---|
| "`--section oe-daily` never emits D2" | **true** — because D2 was never an oe-daily check |
| "the same section inside a full run emits D2" | **false** — OE-DAILY is `F=0` inside the full run too |
| "reports different pass counts" | 66 vs 65 — the 66 was a **whole-run total spanning two sections** |

Per-section, `--section oe-daily` alone vs the same sections inside the full run:

    === OE-DAILY: DAILY CONTROL CHECKS ===   (65, 27, 0)   (65, 27, 0)   identical
    === ARC-COMPLETION CHECKS ===            ( 1,  0, 0)   ( 1,  0, 0)   identical

**A section run alone is byte-identical to that section inside a full run.** The instrument
is stable; what moved was the *labelling* of its output. And the "different pass counts"
finding was itself a total read without its split — this task's own subject matter,
committed inside its own addendum.

**Consequence for the ruling, stated but not taken:** option (b) was rejected here "on
measured grounds, not preference". Those grounds are void — a section list containing
`discovery` reaches the D2 FAIL perfectly well. Whether (b) is now preferable to (c) is
yours; I am removing a false objection, not substituting a verdict.

**Also corrected: the breakdown table above.** It has no `discovery` row at all, and
attributes all 60 FAILs to `oe-daily`. 59 were genuinely `oe-daily` (CTL-030,
`audit.sh:3665`, guarded by `compliance || oe-daily`). The 60th — D2, the only one still
failing — was in `discovery` the whole time.

**The general shape, which is the part worth carrying:** *the residue that outlives a
cleanup is disproportionately the mis-classified item.* A remedy aimed at a class cannot
reach the item that was never in the class, so the 59 correctly-filed FAILs were fixed and
the one mis-filed FAIL survived. "What is left after the big fix" is a far better place to
hunt classification errors than the original population was.

**Second witness for OBS-257** (inbox has no cross-referencing), deliberately *not* filed as
a new observation, since inflating the register is the thing OBS-257 is about: OBS-027 is
`status: dismissed` — which reads as *handled* — yet its inference had already been copied
into this Recommendation, where it did load-bearing work for four days with no link back to
the register that would have flagged it when refuted. Folding an observation into a task
copies its **conclusion** and drops the thread.

## Recommendation

**Recommendation:** GO on **(c) widen the push gate fully** — sequenced, and with one
sub-decision that is genuinely yours and that I will not make for you.

### CORRECTION 2026-08-16 — the sequencing below is void, and it was already void when written

**The whole "sequence it" argument rests on a prerequisite that had already been met the
day before this recommendation was written.** The backfill landed under **T-434
(`5bf8fb26`, 2026-08-11)**; this Recommendation is dated 2026-08-12 in its own text (it
cites the D2 ages "as of 2026-08-12") and still presents the backfill as outstanding.

Worse than a stale number: T-434 produced **two** results, and this task folded in exactly
one of them. The `## Addendum` above records T-434's section-alone-vs-full-run discrepancy
— which *supports* the recommendation by killing option (b). T-434's other result, the
backfill, *removes the recommendation's central obstacle*, and it is the one that went
unrecorded. The finding that made the argument sharper was absorbed; the finding that made
it unnecessary was not. Same selection shape as the three inflated figures logged on
2026-08-15: the datapoint that makes the write-up better is the one that survives.

**Re-measured today, directly, not inferred from T-434's commit message:**

| | 2026-08-11 (as filed) | 2026-08-16 (measured) |
|---|---|---|
| completed tasks | 374 | **466** |
| carrying `horizon: now` | 59 | **0** |
| CTL-030 | 59 × FAIL | **PASS** |
| full audit | 123 P / 32 W / **60 F** | 127 P / 40 W / **1 F** |

**What this changes for the ruling — and what it does not.** The cost of option (c) is now
**zero**, not "59 file edits". Options (a)/(b)/(c) stand as written and the recommendation
is unchanged; only its price tag was wrong, and it was wrong in the direction that made the
recommended option look expensive. The one surviving FAIL is D2, so **(c) collapses to
exactly the c1/c2 sub-decision below** — the question of whether operator review latency
should block pushes is now the *entire* content of the choice, rather than a footnote after
a backfill.

**Warn moved 32 → 40 over the same window and nobody has looked at that either.** Stated as
an observation, not folded into this ruling: it is a different denominator and inventing a
verdict for it here would repeat this task's original defect one register over.

<details><summary>Original sequencing argument, preserved (2026-08-12) — void as of 2026-08-16</summary>

1. **Backfill first.** 59 of the 60 FAILs are one class — CTL-030, *"T-NNN is in
   `.tasks/completed/` but stored `horizon='now'`"*. The check is sound
   (`audit.sh:3665`), the leak has a known source (`update-task.sh:1613` auto-promotes
   `horizon: now` on `started-work`), and **the source is already plugged**. These are
   terminal records: editing them is a data fix with no behavioural risk and near-zero
   safety value on its own.
2. **Then widen.** After the backfill, widening costs nothing and starts catching the next
   regression of a class that has already recurred 8+ times upstream.

</details>

~~**Reject (b) — widening to a section list — on measured grounds, not preference.** A
section's audit result **depends on whether it is run alone or inside a full run**:
`fw audit --section oe-daily` reports 61 pass / 25 warn / **0 fail** and never emits the
D2 check at all, while the same section inside a full run emits D2 and reports different
pass counts. So a gate built from a section list can be green while the full audit is not
— the gate and the number the project steers by would be **different instruments**. This
nearly produced a false claim inside this task's own work: the before-number came from a
full run, and taking the after-number from a section-alone run would have reported
60 → 0 instead of 60 → 1.~~

> **WITHDRAWN 2026-08-16 — the "measured grounds" were a mis-attribution.** D2 is a
> `discovery` check, not an `oe-daily` one (`audit.sh:3915`), so `--section oe-daily` omits
> it for the ordinary reason that it is not that section's check. Measured today, a section
> run alone is **byte-identical** to that section inside a full run — OE-DAILY `(65,27,0)`
> both ways. See `## Addendum → DISSOLVED`. **Option (b) is viable**: a section list
> containing `discovery` reaches the D2 FAIL. I am withdrawing a false objection, not
> ranking (b) against (c) — that ranking is the ruling itself.
>
> The paragraph is struck through rather than deleted: it was quoted to you as *measured*,
> and a recommendation that silently loses its rejected option leaves no trace that the
> rejection was ever made on bad evidence.

**The sub-decision I am leaving to you, because it is about you.** The 60th FAIL is D2 —
*"Human review queue: 2 task(s) waiting >30d: T-093, T-178"* (38d and 32d as of
2026-08-12; **41d and 36d as of 2026-08-16**). That control is **designed** to fail as the
queue ages; it is reporting truthfully and it clears when you review those two, not when
anything is fixed. So under full (c), **a stale review queue would block every push** — the
gate would fail on operator latency rather than on code. That may be exactly the pressure
you want, or exactly the pressure you do not. Choose one:

> **2026-08-16 — the D2 line itself has a reporting defect, filed as T-534.** Today it reads
> *"**2** task(s) waiting >30d: T-093(41d) T-178(36d) **T-308(17d) T-310(17d) T-325(14d)**"*.
> The count is fail-tier; the list is fail ∪ warn (`audit.sh:3966,3969,3984` appends
> `d2_details` in both branches). Two of five are over 30 days; three are not. **This does
> not change the c1/c2 choice** — the FAIL still fires on exactly the two genuinely-stale
> items — but it means the line you would be gating on currently overstates its own queue
> 2.5×, so it is worth fixing before it becomes a gate rather than after.

- **c1** — D2 gate-blocking. Pushes stop until the queue is served.
- **c2** — D2 advisory, everything else blocking. Catches code regressions, does not
  hold the repository hostage to review latency.

I have no standing to pick between those: one of them makes the framework enforce a
deadline against its own sovereign.

**Evidence — the headline number was wrong in this task's own filing, and that matters
more than the fix.** "60 FAIL across non-structure sections" implies breadth. There is
none: **17 of 18 sections are clean**, and all 60 FAILs live in `oe-daily`.

    structure                     19 pass   3 warn   0 fail   <- the ONLY section gated
    oe-daily: daily control       73 pass  25 warn  60 fail   <- every FAIL is here
    (16 other sections)                              0 fail
    TOTAL                        123       32       60

The alarming number came from reading a total without its split — the same defect the
T-429/T-431 work was about, committed in this task's own filing description. Related:
the familiar *"Warn: 3"* everyone quotes is a `--section structure` figure; the full
audit reports **34** (T-438).

**What your ruling unblocks:** whether 60 findings a full audit already computes every
run continue to be computed and ignored. Nothing today reads them — the status quo is not
"we decided they are advisory", it is "nobody looked", which is what this task exists to
make visible rather than to change unilaterally.

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
#
# T-432 (2026-08-16): these assert the CORRECTION, not the audit's global verdict.
# "full audit Fail == 1" is deliberately NOT asserted — that is a global always-moving
# quantity (G-015) and would go red for someone else's change. What this task now claims
# is narrower and stable: the CTL-030 residue is gone, and the commit that removed it
# exists. Whole class asserted, not just the backfilled value, per T-434's own reasoning
# — a residue class returns wearing a different label if you guard one value only.
test "$(grep -lE '^horizon: (now|next|later)$' .tasks/completed/*.md 2>/dev/null | wc -l)" -eq 0
git cat-file -e 5bf8fb26^{commit}
# The claim that rehabilitates option (b): D2 IS reachable from a section list. ~8s, against
# 81s for a full run. The `;` is deliberate and is NOT the L-387 mistake — this audit exits 2
# BY DESIGN while the review queue has a >30d entry, so the grep must be the verdict and the
# audit's own exit code must not be. Stated because the errexit warning above says to prefer
# `&&`, and `&&` here would make this line red for the very condition it is checking.
.agentic-framework/bin/fw audit --section discovery --output /tmp/.t432-d2.yaml > /tmp/.t432-d2.txt 2>&1; grep -q "D2: Human review queue" /tmp/.t432-d2.txt

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

### 2026-08-11T15:41:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-432-full-fw-audit-reports-60-fail-across-non.md
- **Context:** Initial task creation

### 2026-08-11T15:41:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
