---
id: T-508
name: "Verification legs pin corpus cardinality: 24 population-counting legs are contingent
  on a corpus designed to grow, and adopting AEF's daily re-runner would import them
  all red"
description: >
  Verification legs pin corpus cardinality: 24 population-counting legs are contingent
  on a corpus designed to grow, and adopting AEF's daily re-runner would import them
  all red

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
created: 2026-08-15T05:16:25Z
last_update: '2026-08-16T14:33:43Z'
date_finished: 2026-08-15T05:38:39Z
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
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=1 (body/components:prompt-incidental); F1=0 (no-signal); 
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t408-hygiene-teeth.sh,tools/_t451-unwired-guard-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-508: Verification legs pin corpus cardinality: 24 population-counting legs are contingent on a corpus designed to grow, and adopting AEF's daily re-runner would import them all red

## Context

PL-200, captured 2026-08-14 from the AEF exchange: a `## Verification` block is a
**one-shot completion gate** here — it runs once, at `work-completed`, and never again.
On AEF's side `CTL-013` **re-runs verification on completed tasks daily**. Same line,
mirror-image failure modes: ours goes stale silently, theirs goes red spuriously. The
rule that falls out is *never assert transient state in a verification line*.

I wrote four such legs in T-506 the same day I captured the rule, which is what prompted
measuring the class rather than repairing my own four.

**The measurement (2026-08-14, `.tasks/*/*.md`):** 119 verification legs pin a literal
count. They split cleanly and only one half is defective:

| class | shape | count | verdict |
|---|---|---|---|
| B — invariant | `grep -c 'cleanLayout()' src/…` = `2` — occurrences of a token in a **named file** | 95 | **correct as written.** "Exactly one call site" IS the assertion. Not in scope. |
| A — population | `ls examples/aef-processes/rendered/*.bpmn \| wc -l` = `24` — members of a **population** | 24 | **defective.** True only while the corpus never grows, and the corpus is designed to grow. |

The literal `24` is replicated across seven task files (T-041, T-191, T-469, T-478,
T-479, T-506 and, as `47`, T-471). One corpus addition turns all of them false at once.

> **CORRECTION 2026-08-15 — the number above is 24 and the delivered figure is 17.** The
> task name still says 24 and is left alone; renaming a task to match its own result is how
> a record stops being a record. The first count was taken before the classifier existed,
> so it folded in two shapes that are **not** defective and were split out once the
> discriminator was written: legs pinned to `= 0` (emptiness — "none of these exist" does
> not go stale as a corpus grows) and one leg whose population is built under `mktemp` in
> the same breath (hermetic — it cannot drift). 24 → 17 is the classifier doing its job, not
> a shrinking problem. It also makes the point the task is about: **24 was a number I
> produced by grepping and believed**, and it was wrong in the direction that made my
> finding look bigger.

**Why this is not already visible.** 23 of the 24 sit in `.tasks/completed/`, which never
re-runs here — so the staleness is unobservable by construction. The class has still been
hit twice and repaired by hand: T-095 and T-096 both carry `-ge N  # was =N; call sites
grew legitimately`. That is PL-145's fix-on-discovery shape — repaired locally, never made
detectable — and PL-148 is the standing instruction to capture it at class level instead.

**The AEF-integration stake, which is why this is worth building now rather than noting.**
Adopting a CTL-013-style daily re-runner is the obvious thing to take from yesterday's
exchange. Doing it against the tree as it stands would import **24 immediately-red legs**
on day one and read as "the re-runner is broken". That is a cost worth quantifying before
the adoption decision, not after it.

**Scope boundary.** This task builds the detector and reports the population. It does
**not** rewrite the 23 completed tasks' verification blocks: those are archived records of
what was true when the work closed, and silently editing closed records to make a future
gate green is the AC-laundering this project keeps catching. Which of them to repair, and
whether to adopt CTL-013 at all, is the operator's call and is put to them as one.

## Acceptance Criteria

> **THE DELIVERABLE CHANGED, 2026-08-15, and the reason is the finding.** The ACs below
> were written for a standalone detector (`tools/_t508-population-pinned-verification-census.py`).
> That tool was built, run, and then **deleted before commit**, because
> `tools/verification-hygiene.py` already existed and already implements this exact
> concept: G-015 records *"lines asserting a GLOBAL, always-moving property instead of a
> property of the task that carries them"*, which is PL-200's class under an older name,
> with two carrier shapes already on record. Its baseline design is also strictly better
> than the one I had written — hash-keyed per carrier line, where mine was count-keyed, and
> its docstring rejects count-keying with the concrete failure my `--ratchet` would have
> had (a file cleaned 1→0 can go 0→1 again and still satisfy `<= 1`).
>
> This is **T-491 repeating**: build a replacement, discover the real instrument is better,
> delete the replacement. Found the same way, too — by the draft printing a filename I then
> had to look up. What survives from the draft is the classifier, which is the genuinely new
> part; it landed as a third carrier kind in the real tool. ACs rewritten to the delivered
> shape rather than left describing an artifact that does not exist.

### Agent
- [x] `population-pinned` lands as a **third carrier kind in `tools/verification-hygiene.py`**,
      not as a parallel instrument, and the parallel draft is gone from the tree.
- [x] The discriminator is mechanical and separates four look-alike shapes that all pin a
      literal count and are all **correct as written**: token-in-a-named-file invariants
      (`grep -c 'cleanLayout()' src/…` = 2), emptiness pins (`… | wc -l` = 0), hermetic
      fixtures (the leg builds its corpus under `mktemp` in the same breath), and the `-ge`
      remedy shape T-095/T-096 already carry. A detector that flags these is worse than
      none — it would push authors to weaken real invariants to get green.
- [x] Teeth prove the new kind FIRES and that the discriminator HOLDS (PL-070), including
      an **anti-vacuity** leg: the four look-alikes passing must be shown to be about
      classification and not about the files never having been scanned.
- [x] End-to-end mutation on the REAL tree, not only the teeth's synthetic one: a
      population-pinned leg added to `.tasks/active/` turns the gate red, names the file
      and names the kind, and the tree is restored.
- [x] The instrument is **wired to a standing caller**, which is the substantive half of
      this task: it was line 130 of `tools/unwired-guard-baseline.txt` — correct, tested,
      and called by nothing since 2026-08-09.
- [x] Its **teeth are wired too**. A guard whose teeth never run is a guard nobody has
      checked, and shipping that would be the exact defect this task diagnosed.
- [x] The gate is on **movement, not on the count** — the 105 grandfathered carrier lines
      must not paint the suite red while they await the operator's G-015 leg-1 ruling.
      What it catches is the next one written.
- [x] Drift that accumulated while the instrument was unwatched is **named before it is
      grandfathered**, so adoption records it rather than laundering it.
- [x] Both ratchets end green and the `T-451` baseline movement is **recorded before the
      regeneration** (the file's own standing rule), with the removed-set taken from
      `--json` rather than from my prediction of it.
- [x] This task's own `## Verification` contains **no population-pinned leg** — the gate
      must not flag T-508 itself (T-420/PL-147: an enforcement artifact that commits the
      defect it enforces against).
- [x] Bridge suite green.

<!-- ORIGINAL ACs, kept because a rewritten AC set that hides its own supersession is the
     laundering this project keeps catching. These describe the deleted standalone tool.
- [ ] The two classes are separated **mechanically**, not by eye: the detector
      distinguishes population-counting legs (`ls`/`find`/`git ls-files`/`grep -rl`
      over a directory or glob) from token-in-a-named-file invariant legs, and reports
      each count. Class B must come back non-empty, because a detector that flags all
      119 has not made the distinction the task exists to make.
- [ ] The denominator is printed on every run — legs scanned, task files scanned, and
      legs skipped with the reason. `0 population-pinned legs` is only a verdict if the
      denominator is non-zero (the `every()`-over-empty shape that made three legs of
      T-233's guard report PASS while rendering zero cards).
- [ ] Abstention is a distinct exit code from a verdict: a scan that cannot establish a
      population exits 2, never 1 (T-430 abstention discipline; the failure T-495 hit
      twice, and PL-193).
- [ ] Negative controls, run and recorded: (a) a synthetic Class-A leg is detected,
      (b) a synthetic Class-B leg is NOT detected, (c) the population-establishing
      refusal fires and returns 2 when pointed at a tree with no task files. Each
      control must be shown to fail for the reason claimed, not merely to exit non-zero.
- [ ] The detector is wired to a standing caller **in the same change** that creates it,
      so the T-451 unwired-guard census does not gain a row (PL-148: an instrument's
      registration must be asserted by something other than the instrument; T-491 is the
      precedent where the ratchet stayed flat because wiring landed with the tool).
- [ ] The standing leg gates on **movement, not on the count** — it must not assert the
      backlog is zero. 24 is a pre-existing backlog only the operator can drain, and
      gating on zero would paint the suite permanently red, which is exactly the mistake
      T-491 solved for the unwired-guard backlog.
- [ ] This task's own `## Verification` block contains **no Class-A leg** — the detector
      run against this repo must not flag T-508 itself. A guard against a defect whose
      own verification commits the defect is the T-420/PL-147 shape.
- [ ] Bridge suite green, and the T-451 ratchet unchanged at 69/69.
-->


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

# ── TWO LEGS ARE DELIBERATELY ABSENT, and this task is the reason ──────────────────
# The obvious legs to write here are `python3 tools/verification-hygiene.py` and
# `python3 tools/_t451-unwired-guard-census.py --ratchet` — "the gate I wired is green".
# Both are exactly the defect this task adds a detector for. Each asserts a GLOBAL,
# ALWAYS-MOVING property: the hygiene gate goes red the moment ANY author writes a new
# carrier in ANY task, and the unwired ratchet moves whenever ANY instrument gains or
# loses a caller. Neither is a property of T-508. Under a CTL-013-style daily re-runner
# they would go red for someone else's change with T-508's name attached to the failure —
# G-015's shape (a) precisely, which is how T-093 sat red for 35 days for reasons
# unrelated to T-093.
# Both ARE run, and their results are recorded in ## Evolution as measurements taken on
# 2026-08-15. They are also both wired into the bridge suite by this very change, which is
# the durable place for a global assertion. A leg here would add nothing except a future
# false red.
# What remains below are properties of THIS change: structural facts about files this task
# edited, plus the teeth, which are hermetic (they build their own tree under mktemp and
# cannot drift with the repo).

test ! -f tools/_t508-population-pinned-verification-census.py
grep -q 'KIND_POP = "population-pinned"' tools/verification-hygiene.py
grep -q 'def is_population_pinned' tools/verification-hygiene.py
grep -q 'tools/verification-hygiene.py' tests/run-bridge-tests.sh
grep -q '_t408-hygiene-teeth.sh' tests/run-bridge-tests.sh
grep -q 'population-pinned' tools/_t408-hygiene-teeth.sh
# The four look-alike shapes each have a named control leg in the teeth.
grep -q 'T-909-invariant' tools/_t408-hygiene-teeth.sh
grep -q 'T-910-emptiness' tools/_t408-hygiene-teeth.sh
grep -q 'T-911-hermetic' tools/_t408-hygiene-teeth.sh
grep -q 'T-912-remedy' tools/_t408-hygiene-teeth.sh
# Anti-vacuity leg for the discriminator control, and the derived (not hand-typed) tally.
grep -q 'T-913-poppin-again' tools/_t408-hygiene-teeth.sh
grep -q 'TEETH PASS — \$legs/\$legs legs' tools/_t408-hygiene-teeth.sh
# Hermetic: builds its own tree, so this is not a claim about the repo's moving state.
bash tools/_t408-hygiene-teeth.sh > /dev/null 2>&1
# The instrument left the unwired backlog. A property of this change, not of the tree.
# NOT `grep -qxv`: -v inverts PER LINE, so it succeeds whenever any OTHER line differs —
# always true, a permanent false green. Written that way here first (PL-151's neighbour).
! grep -qx 'verification-hygiene.py' tools/unwired-guard-baseline.txt
grep -q 'SHRANK by 2' tools/unwired-guard-baseline.txt

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

**Measurements taken 2026-08-15.** These are the two legs deliberately kept out of
`## Verification` because they assert global, always-moving state (see the note there).
Recorded here as dated observations, which is what they actually are.

```
python3 tools/verification-hygiene.py --census
  files=508  with-block=508  lines=2088
  serve-root-diff=76  hardcoded-port=12  population-pinned=17  carrier-files=94
python3 tools/verification-hygiene.py            -> rc=0 (no carrier outside the 94-file baseline)
python3 tools/_t451-unwired-guard-census.py --ratchet -> rc=0 (baseline 67, findings 67)
bash tools/_t408-hygiene-teeth.sh                -> 15/15 legs
bash tests/run-bridge-tests.sh                   -> 79 passed, 0 failed  (was 77)
```

**Four things were not known at filing.**

1. **The instrument already existed.** The task was filed to build a detector; the class
   was already registered as G-015 with a better-designed ratchet. The build turned into an
   extension. This is the second time in three days (T-491) that the thing I set out to
   build was already here and better — and both times I found out by following a filename
   my own draft printed. That is not a coincidence worth ignoring: the draft's output is
   currently a more reliable index of this repo than my search of it.

2. **The instrument was unwired, and that was the real defect.** It sat at line 130 of
   `tools/unwired-guard-baseline.txt` — correct, covered by teeth, called by nothing since
   2026-08-09. Adding a carrier kind to an unread instrument would have grown a list nobody
   reads. The substantive deliverable became the caller, not the classifier.

3. **`RE_PORT` was matching non-ports, and only running it revealed that.** Three of the
   four carriers accumulated while unwatched were `[:400]` slices and a `T-2553:101` rail
   reference. `hardcoded-port` fell 20 → 12 once the regex required a host qualifier or a
   non-word character before the colon. A gate cannot be wired while three quarters of its
   recent output is noise, so this was a prerequisite rather than scope creep.

4. **Wiring the teeth discharged a second baseline entry through a path I did not choose.**
   The measured movement was `SHRANK by 1`; the regeneration removed two, because the
   teeth's cross-tool agreement leg calls `_t350-verification-hygiene.py` and wiring the
   teeth pulled it live as well. Caught only because the regenerator prints its own
   removed-set rather than being trusted to match the prediction. Recorded in the baseline
   header, where the wrong number had already been written.

**One finding is named and deliberately not fixed here.** `tests/run-bridge-tests.sh` runs
**no other teeth script**. Every other `tools/_t*-teeth.sh` is in the same unwatched state
this task found `verification-hygiene.py` in, and the T-451 census cannot see them: it
excuses anything named `*teeth*` as "one-shot by design", an assumption this change
contradicts by wiring one. One task, one deliverable — but it is now written into a file
that runs, and it wants its own task.

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

### 2026-08-15T05:16:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-508-verification-legs-pin-corpus-cardinality.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2da89187
- **Timestamp:** 2026-08-15T05:38:44Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 81
     - evidence: `bash tools/_t408-hygiene-teeth.sh > /dev/null 2>&1`
  2. **mock-only-integration** (partial, heuristic) @ AC vs Verification cross-check
     - evidence: `grep -q 'tools/verification-hygiene.py' tests/run-bridge-tests.sh`

### 2026-08-15T05:38:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
