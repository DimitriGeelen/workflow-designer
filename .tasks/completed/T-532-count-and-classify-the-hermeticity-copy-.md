---
id: T-532
name: "count and classify the hermeticity copy-family across the teeth population:
  how many legs assert whole-tree state instead of their own subject"
description: >
  count and classify the hermeticity copy-family across the teeth population: how
  many legs assert whole-tree state instead of their own subject

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
created: 2026-08-15T22:02:21Z
last_update: '2026-08-16T13:58:58Z'
date_finished: 2026-08-15T22:06:25Z
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
  - ts: '2026-08-16T12:34:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/_t532-hermeticity-scope-census.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:58Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:tools/_t532-hermeticity-scope-census.py); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-532: count and classify the hermeticity copy-family across the teeth population: how many legs assert whole-tree state instead of their own subject

## Context

OBS-259 asserted the whole-tree hermeticity defect found under T-527 was "probably a POPULATION
rather than an instance — the sweep runs 26 teeth scripts and the leg shape was copied between
them", and said the count was the first thing a fixing task should produce.

## Findings

**The population is 2, not 26.** Census over 238 files in `tools/` and `tests/`:

| class | n | |
|---|---|---|
| WHOLE-TREE (defective) | **2** | `_t524-fabric-validate-teeth.py`, `_t525-fabric-coverage-teeth.py` |
| SCOPED (correct) | 0 | |
| FIXTURE / unasserted (correct, never flagged) | 6 | `_t392`, `_t402`×3, `_t404`, `_t509` |

**My OBS-259 estimate was wrong in the direction that made it look bigger** — the third time
today, after T-527's "62 legs" (real: 23) and T-530's 15.06 MB (real: 14.96). In all three the
inflated figure was the one I published first.

**The 6 non-hits are the harder half.** In each, `git status` is a literal string under test —
a command-classifier fixture — not a tree read. Flagging them would push authors to weaken real
tests. AEF found the identical class on their tree (rail 11945): all 25 of their `git status`
callers were classifier fixtures.

**AEF's copy-family reframing is CONFIRMED, and the family is tight.** They argued the unit of
infestation is the copy-family, not the script. Evidence:

- `_t524-fabric-validate-teeth.py` created **2026-08-15 17:09:08**
- `_t525-fabric-coverage-teeth.py` created **2026-08-15 17:37:46** — **28 minutes later**
- leg title byte-identical: `hermetic — the working tree is byte-identical after the run`
- failure message opens with the same sentence in both: `git status changed across the run.`

One family, two instances, source `_t524`, propagated in under half an hour. That supports their
"fix 26 and the template still emits the 27th" argument at a scale small enough to act on: the
template here is *the previous task's teeth script*, and the copy window is minutes.

**The census caught itself being wrong, twice, before it was believed.** Its first run reported
**0** whole-tree assertions against a hand-derived ground truth of 2 — a false clean, in the
flattering direction:

1. `\b(==|!=)\b` can never match: `\b` asserts a word/non-word boundary and `==` is followed
   by a space, both non-word. Every real assertion fell through to "unasserted".
2. The census matched its own source, because it quotes the patterns it searches for and scans
   the directory it lives in. T-527 avoided this by putting the checker in a different file from
   its subject; here the subject IS that directory, so it must exclude itself explicitly.

Both are fixed, and a `GROUND_TRUTH` self-test now makes the census exit **2 (REFUSE)** rather
than 0 if it ever stops agreeing with the reading it was built from. A census that silently
disagrees with its own source reading converts an unknown into a wrong known.

**Not fixed, and not wired.** See `## Decisions`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The population is counted over the whole teeth corpus, not the sweep's 26.** OBS-259
      guessed "probably a population" from the fact that the leg shape was copied. The sweep runs
      26 scripts but `_t509-instrument-sweep.sh` reports 31 on disk with 5 excluded by name, and
      the corpus that can carry the shape is every script that snapshots state around a run —
      not only the ones currently wired. Counting the wired subset would reproduce this project's
      own recurring defect (PL-223) inside the task filed to measure it.
- [x] **Every hit is CLASSIFIED by what it actually asserts, not counted as one bucket.** The
      discriminating question is whether the snapshot is scoped to the paths the subject writes
      or to the whole repository. A leg comparing `git status` over the tree is defective; a leg
      comparing a named file, a `mktemp` dir, or a fixed write-set is correct and must not be
      "fixed". Flagging the correct ones would push authors to weaken real invariants — the same
      false-positive risk T-508's discriminator was built to avoid.
- [x] **AEF's reframing is applied and tested, not just quoted.** They argued (rail 11945) that
      the unit of infestation is the COPY-FAMILY, not the script: 26 scripts sharing one copied
      leg is one defect with 26 instances, and fixing 26 still leaves the template emitting the
      27th. So the deliverable includes how many distinct families exist and, where determinable,
      each family's source — the earliest instance by git history. If the copy hypothesis is
      wrong (legs written independently), that is reported as the finding.
- [x] **The count is reproducible by someone else.** The classifier is a committed script, not a
      grep pasted into a task body, so the next count is a re-run rather than a re-derivation.
      It is wired or its non-wiring is deliberate and stated (PL-182, T-509).
- [x] **Nothing is "fixed" in this task.** OBS-259 names three candidate remedies and one of them
      (serialising the suite against a lock) touches cron and the handover agent, which is
      operator territory. This task produces the count and the classification that make the
      remedy choice decidable; it does not choose.

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

# The census legitimately exits 1 (it found 2 real defects), so rc is not the verdict here.
# What must hold is that it did not ABSTAIN (rc 2 = it disagrees with its own ground truth),
# and that it still names both known instances. If the fixing task repairs one, line 2 fails
# loudly rather than the count drifting unnoticed.
python3 tools/_t532-hermeticity-scope-census.py > /tmp/t532-verify.out 2>&1; test $? -ne 2
grep -q "_t524-fabric-validate-teeth.py" /tmp/t532-verify.out
grep -q "_t525-fabric-coverage-teeth.py" /tmp/t532-verify.out

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

### 2026-08-16 — the census is deliberately NOT wired, and the ratchet moves 67 → 68

- **Chose:** leave `_t532-hermeticity-scope-census.py` unwired, accept the T-451 unwired-guard
  ratchet moving 67 → 68, and record the movement rather than avoid it.
- **Why:** the census is currently RED (rc 1) because the two defects it measures are real and
  this task is scoped not to fix them. Wiring a red check into the bridge suite would take the
  suite from 95/0 to 94/1 for a known-unfixed defect, which trains exactly the reflex T-526
  documented — "the cheapest reading of a lone red is 'flake'". The wiring belongs to the fixing
  task, as its prevention, which is the shape T-527 used.
- **Rejected:** naming the file to match the `teeth/probe/mutation` convention that the T-451
  census excuses. That would silence the ratchet by pattern-match, and T-509's whole finding was
  that a naming convention used as a CLASSIFIER is an assumption with an expiry date that
  nothing re-checks. Buying a green ratchet with the exact defect this tree just catalogued is
  not a trade worth making.
- **Rejected:** fixing the two instances here to make wiring possible. One task, one
  deliverable; and the remedy is a genuine choice (scope to the subject's write-set, snapshot
  only tracked state, or serialise the suite) whose third option touches cron and the handover
  agent — operator territory per OBS-259.
- **Closing condition, so the +1 is not open-ended:** the ratchet returns to 67 when the fixing
  task wires this census. Filed as T-533.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-15T22:02:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-532-count-and-classify-the-hermeticity-copy-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4ecf0a1f
- **Timestamp:** 2026-08-15T22:06:26Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T22:06:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
