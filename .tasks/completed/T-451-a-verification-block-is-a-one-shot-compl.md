---
id: T-451
name: "A `## Verification` block is a one-shot completion gate, not a standing guard:
  30 instruments have no live caller"
description: >
  A `## Verification` block is a one-shot completion gate, not a standing guard: 30
  instruments have no live caller

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
created: 2026-08-12T10:44:58Z
last_update: '2026-08-16T13:58:55Z'
date_finished: 2026-08-12T10:51:16Z
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
  - ts: '2026-08-16T12:33:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,tools/_norec-verify.py,tools/_t352-p011-errexit-probe.sh,tools/_t451-unwired-guard-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:55Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/concerns.yaml,tools/_norec-verify.py,tools/_t451-unwired-guard-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-451: A `## Verification` block is a one-shot completion gate, not a standing guard: 30 instruments have no live caller

## Context

P-011 executes a task's `## Verification` block on the `--status work-completed`
transition and at no other time. An instrument whose only call site is a Verification
block therefore runs **exactly once**, at that task's completion, and never again —
but it still reads as a wired guard to anyone who greps its name and finds the line.

PL-148 (T-426) already names this mechanism, from three anecdotes, one of which it
describes as *"its only call site was its own task's P-011 block, which stops running
at completion; it has been exiting 1 into a void."* T-450 hit the fourth: the
operator's approvals-queue guard `_norec-verify.py`, whose only caller is
`.tasks/completed/T-236-*.md`. It last ran on **2026-07-22**, at which point the queue
was 0 NO-REC. It is now **14 NO-REC out of 32 handed-over tasks**, and nothing in the
tree was in a position to notice.

**Nobody had counted the class.** PL-148 asserts a mechanism from three instances and
prescribes a remedy; no instrument derives how many instruments are in this state, so
the remedy has never been applied anywhere but the three files that motivated it.
That is the same shape as the defect: a claim about coverage with no denominator.

**My first count was 39 and it was drawn from the wrong side.** I enumerated from the
CALLER side — tools named in some completed task's Verification block, minus those with
a live caller — which structurally cannot see an instrument that no task references at
all. The census derives from the POPULATION side (`tools/*` on disk) and finds twelve
more, invisible to the first query by construction. Same defect as the subject, one
level out: a denominator taken from the wrong authority. The tool's numbers stand; the
39 does not.

Measured by `tools/_t451-unwired-guard-census.py`, cross-checked against every
non-Verification invocation path (hook, cron, `tests/`, tool-invokes-tool, framework
agent script, gap closure condition) so "no caller" means no caller and not "I looked
in one place":

    population (tools/*.{py,sh,mjs,js} on disk)            154
    live-callable                                           92
    pending one-shot (ACTIVE task Verification only)        11   ← will join the set below
    NO live caller                                          51
      one-shot BY DESIGN (teeth/mutation-check/probe)       20   ← legitimately complete
      FINDINGS — read as standing guards                    31
        never referenced by ANY task at all                 12

That is the reading BEFORE the remedy. Wiring the census into G-035's
`closure_check_command` moves one file from unwired to live-callable, so the current
reading is 93 / 50 / **30** / 11 — the census counts itself by the same rule it counts
everything else, which is the point of leg 7. The table above is kept as the
pre-remedy measurement rather than overwritten, so the delta stays visible.

Deliverable is the census that derives those numbers, plus the class registered where
it survives this task's archival — not a wiring campaign across 39 files, which is
separate work and partly an operator decision (cron deployment writes outside the
project boundary).

## Acceptance Criteria

### Agent
- [x] A census instrument derives BOTH sides from the tree — population from `tools/*`,
      live callers from an explicit list of paths that re-execute without a task
      completing — and the number 39 appears nowhere in it (PL-158)
- [x] It refuses at **rc 2** when a side cannot be enumerated (no `tools/`, or a missing
      task directory), rather than reporting 0 unwired over a corpus it never read —
      G-034 applied to the new instrument, so this repair does not commit the defect
      it is measuring
- [x] It separates one-shot-BY-DESIGN (`*-teeth`, `*-mutation-check`, `*-probe`) from
      standing guards, reports both counts, and does not guess intent per file
- [x] It states its reachability LIMIT in its own output (textual reference only), so a
      clean run cannot imply coverage it does not have — PL-148's own prescribed remedy
- [x] A tool referenced ONLY by an active task's Verification block is NOT counted live;
      proven behaviourally on a throwaway tree, because that self-exclusion is precisely
      how the class stayed invisible
- [x] The class is registered in `concerns.yaml` with a closure condition that RUNS
      (the T-440/G-034 precedent), so it survives this task's archival
- [x] The census itself has a live caller — it is named by its own gap's closure
      condition, which is one of the paths it counts as live (asserted, not assumed)

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
#
# Every rc below is read directly from the process, never through a pipeline.
#
# NOTE ON LEG 7 AND THE IRONY IT IS GUARDING AGAINST: these legs run once, at this
# task's completion, and then stop — this Verification block is itself an instance of
# the class. That is why the census is wired to G-035's closure_check_command, which
# re-executes, and why leg 7 asserts the wiring rather than trusting it.

# 1. Refuses (rc 2) when there is no tools/ population to range over.
D=$(mktemp -d); mkdir -p "$D/.tasks/active" "$D/.tasks/completed"; (T451_ROOT="$D" python3 tools/_t451-unwired-guard-census.py > /tmp/.t451-1 2>&1); test $? -eq 2
# 2. Refuses (rc 2) when a task directory is missing — every tool would read as unwired.
D=$(mktemp -d); mkdir -p "$D/tools" "$D/.tasks/active"; touch "$D/tools/x.py"; (T451_ROOT="$D" python3 tools/_t451-unwired-guard-census.py > /tmp/.t451-2 2>&1); test $? -eq 2
grep -q "task directory\|.tasks/completed is missing" /tmp/.t451-2
# 3. A tool named ONLY by an ACTIVE task's Verification block is NOT counted live — it is
#    a pending one-shot. Counting it live is precisely how this class stayed invisible.
D=$(mktemp -d); mkdir -p "$D/tools" "$D/.tasks/active" "$D/.tasks/completed"; printf 'x\n' > "$D/tools/standing-guard.py"; printf -- '---\nid: T-999\n---\n## Verification\npython3 tools/standing-guard.py\n' > "$D/.tasks/active/T-999-x.md"; T451_ROOT="$D" python3 tools/_t451-unwired-guard-census.py > /tmp/.t451-3 2>&1; grep -qE "live-callable +0 " /tmp/.t451-3
grep -qE "pending one-shot .*  +1 " /tmp/.t451-3
# 4. Teeth/mutation-check are excused separately and reported, not silently folded in.
grep -qE "one-shot BY DESIGN .*[0-9]+" /tmp/.t451.out
# 5. The reachability LIMIT is stated in the tool's own output (PL-148's remedy).
grep -q "LIMIT: reachability is decided by TEXTUAL reference" /tmp/.t451.out
# 6. No count is restated as a literal: the population derives from tools/ on disk.
#    Behavioural, not a grep for a number — add a file, watch the population follow.
D=$(mktemp -d); mkdir -p "$D/tools" "$D/.tasks/active" "$D/.tasks/completed"; for n in 1 2 3; do printf 'x\n' > "$D/tools/z$n.py"; done; T451_ROOT="$D" python3 tools/_t451-unwired-guard-census.py > /tmp/.t451-6 2>&1; grep -qE "population +3 " /tmp/.t451-6
# 7. The census has a LIVE caller — G-035's closure_check_command — and is therefore not
#    in its own findings list. Asserted, because a census that reports everything but
#    itself is the self-certifying shape PL-148 warns about.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[c for c in d['concerns'] if c['id']=='G-035'][0]; sys.exit(0 if 'tools/_t451-unwired-guard-census.py' in g.get('closure_check_command','') else 1)"
python3 tools/_t451-unwired-guard-census.py > /tmp/.t451-7 2>&1; test $? -eq 1
grep -q "_t451-unwired-guard-census" /tmp/.t451-7 && exit 1 || true
# 8. The gauge envelope: --json exits 0 for BOTH verdicts so NOT_READY is distinguishable
#    from a broken gauge, and still exits 2 on a refusal (which maps to UNKNOWN).
python3 tools/_t451-unwired-guard-census.py --json > /tmp/.t451-8 2>&1; test $? -eq 0
python3 -c "import json,sys; d=json.load(open('/tmp/.t451-8')); sys.exit(0 if d['verdict'] in ('READY','NOT_READY') and d['population'] > 0 else 1)"
D=$(mktemp -d); (T451_ROOT="$D" python3 tools/_t451-unwired-guard-census.py --json > /dev/null 2>&1); test $? -eq 2
# 9. The class is registered where it survives this task's archival, with a trigger that runs.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); sys.exit(0 if any(c['id']=='G-035' and c['status']=='watching' for c in d['concerns']) else 1)"
# 10. G-034's retracted T-101 claim is gone from the register too — a register outlives
#     the task that corrected it, so a false claim left there is worse than in a task file.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[c for c in d['concerns'] if c['id']=='G-034'][0]; sys.exit(1 if 'open arc task T-101 reads its exit code' in g['context'] else 0)"

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

**Symptom:** `tools/_norec-verify.py` — the operator's approvals-queue guard — has run
exactly once since it was written, on 2026-07-22, and cannot be run again by anything
in the tree. Its only call site is the `## Verification` block of
`.tasks/completed/T-236-*.md`. It last reported 0 NO-REC; the queue is now 14 NO-REC
out of 32 handed-over tasks, and no instrument was in a position to say so.

**Root cause:** a `## Verification` block is executed by P-011 on the
`--status work-completed` transition and at no other time. Putting a standing guard
there wires it to a **one-shot event**, not to a schedule. The moment the task
completes, the block stops running and the file moves to `.tasks/completed/`, where it
still reads to any grep as a live call site. Both halves of the failure are silent: the
guard cannot go red, and its not-going-red looks like evidence that nothing is wrong.

**Why structurally allowed:** nothing distinguishes, at authoring time, between "this
command proves my change works" (correct use of a Verification block) and "this command
must keep being true" (a standing guard, which needs a schedule). The framework offers
one slot and it means the first. PL-148 identified this exactly, from three instances,
and prescribed asserting registration separately — but a learning with no denominator
cannot say how much of the corpus is affected, so the remedy stayed on the three files
that motivated it. Measuring it was never anyone's task until it broke something.

**Prevention — and the honest limit of what was done here.** Registering G-035 and
building the census is *mitigation with a gauge*, not prevention: it makes the number
visible and re-derivable, and it does not stop the 32nd instrument being authored the
same way tomorrow. G-035's closure condition says so explicitly and refuses to close on
the wiring campaign alone. Two further guards against fake progress are built in: the
census excuses teeth/mutation-check by naming convention, so the FINDINGS count can be
lowered by *renaming* rather than wiring — the trigger therefore requires any drop in
FINDINGS to be matched by a rise in live-callable. And a tool named only by an ACTIVE
task's Verification block is counted in its own `pending one-shot` column rather than
as live, because folding those into "wired" is how every instrument in this census
looked wired on the day it was written.

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

### 2026-08-12T10:44:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-451-a-verification-block-is-a-one-shot-compl.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bcd63c84
- **Timestamp:** 2026-08-12T10:51:19Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T10:51:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
