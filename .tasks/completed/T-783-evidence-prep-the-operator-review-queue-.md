---
id: T-783
name: "Evidence-prep the operator review queue: turn 36 GO-marked Human ACs from investigations
  into decisions"
description: >
  The review queue holds 36 [GO], 2 [DEFER], 1 [NO-GO] and 2 [?] tasks with unchecked
  Human acceptance criteria. Each currently costs the operator an investigation before
  it can cost them a decision. CLAUDE.md sanctions exactly this prep and no more:
  an agent MAY suggest closing a human-owned task IF it cites specific evidence that
  the Human ACs are already satisfied, and MUST NOT suggest closing without it - no
  batch-close, no --force, no treating Human ACs as administrative overhead. This
  task triages every unchecked Human AC in the live queue into four classes: EVIDENCED,
  where the Expected clause is demonstrably already true and the check plus its output
  is attached so the operator ticks in seconds; DETERMINISTIC, where the Expected
  clause is grep-able or structural and the criterion was mis-prefixed as Human when
  T-1811/T-1878 route it to an Agent AC with a reviewer command; TASTE, where the
  criterion genuinely needs human judgement and no evidence can substitute, which
  is reported as such rather than evidenced away; and UNACTIONABLE, where the AC cannot
  be executed as written. The agent does not tick a single Human AC and does not change
  any ownership away from human. The deliverable is a triaged report, not a cleaned
  task list.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [review-queue, governance, human-ac]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T21:26:24Z
last_update: '2026-09-21T21:31:07Z'
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
  - ts: '2026-09-21T21:31:07Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 3
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=3 
      (prose:routing-defect-class); F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T21:31:07Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-783-review-queue-triage.md,docs/research/executable-workflow/operator-decisions.yaml,tools/_t586-worktree-denial-guard.py,tools/_t783-human-ac-queue-extract.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-783: Evidence-prep the operator review queue: turn 36 GO-marked Human ACs from investigations into decisions

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Enumerated from the task files: 77 criteria across 62 tasks.** The handover renders
      **41**, and the gap reconciles exactly: `62 − 4 (owner: agent) − 17 (horizon: later) = 41`.

      The `later` exclusion is by design. **The `owner: agent` exclusion is not**, and it
      deadlocks four tasks — **T-341, T-358, T-695, T-696** — each blocked on a `[REVIEW]`
      criterion only the operator can answer, none of which appears in the operator's queue.
      T-341 and T-358 sit in the high-value quadrant and the selection census classified both
      `ac-blocked`. The agent waits on a ruling; the ruling is not in the queue; nobody is
      waiting on anything they can see. Reported as a queue-filter finding, not registered as a
      gap — that call is the operator's.

- [x] **Triaged into four classes with the rule stated per item**, in
      `docs/reports/T-783-review-queue-triage.md`: TASTE ~71, **EVIDENCED 2**, STALE 1,
      POINTER 1. Auditable per item rather than as a total.

      **One self-correction recorded rather than buried:** my first heuristic bucketed 17
      criteria as "possibly unactionable". Reading them — *"is the right field name"*, *"is the
      right scope"*, *"rule which definition this table ratifies"* — they are plainly judgement
      calls the regex missed. They are TASTE. The scan under-classified and the report says so.

- [x] **Both EVIDENCED items carry the command and its actual output.**

      **T-586 — already done, only the tick is missing.** Two independent instruments agree:
      `tools/_t586-worktree-denial-guard.py` prints `[denied]` on all three routes and
      *"All worktree routes are denied."*, exit 0; and a direct read gives
      `permissions.deny = ['EnterWorktree', 'ExitWorktree', 'Bash(git worktree:*)']`. That is
      exactly the AC's Expected, so step 1 does not need running.

      **T-580 — the check passes.** Its Expected is *"step 1 prints 0"*; it prints **0**. Its
      own *If not* caveat is carried forward in the report: closing T-580 is not an argument
      about the vendor bump.

      **T-596 flagged STALE rather than evidenced.** It asks the operator to confirm H1 and H3
      read as **open**. Measured now: H1 **resolved** (ruled 2026-09-21), H3 still open. Ticking
      it as written would record a confirmation of something false, so the recommendation is to
      rewrite it to H3 alone or close it as overtaken — a scope call left to the operator.

- [x] **Zero ticked, zero ownership moved — proven, not asserted.** Unchecked Human AC count
      identical before and after (**77 criteria / 62 tasks**); `owner:` diffed against HEAD for
      every active task with result **NONE**; and the set of task files touched this session
      (`T-737, T-778…T-783` — my own work and framework stamps) has **zero overlap** with the
      62 queue tasks.

- [x] **TASTE reported as TASTE, and its size IS the negative control.** 71 of 77 are
      `[REVIEW]` and no evidence can substitute for any of them. A triage returning EVIDENCED
      for everything would be indistinguishable from one that had not done the work; 2 of 77
      is the honest shape of this queue.

      Two sizing aids carried into the report: **nine** TASTE items are one repeated boilerplate
      criterion across `horizon: later` inceptions and can be decided as a batch; and **T-732
      holds H3, H5 and H6** — the only three open blocking Arc-0 rulings — so if the object is
      to move Arc-0, those three are the queue, not the other 74. H3's filed recommendation is
      flagged **superseded**: it cites "the two values already in use" where there are now
      three.

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
         1. Run `bin/fw reviewer T-783`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-783 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

test -f docs/reports/T-783-review-queue-triage.md
python3 tools/_t783-human-ac-queue-extract.py > /dev/null 2>&1
python3 -c "import json,subprocess,sys; r=json.loads(subprocess.run(['python3','tools/_t783-human-ac-queue-extract.py','--json'],capture_output=True,text=True).stdout); sys.exit(0 if len(r)==77 and len({x['task'] for x in r})==62 else 1)"
python3 tools/_t586-worktree-denial-guard.py > /dev/null 2>&1
python3 -c "import yaml,sys; d=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml')); q={x['id']:x['status'] for x in d['questions']}; sys.exit(0 if q['H1']=='resolved' and q['H3']=='open' else 1)"

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
     fw inception decide T-783 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T21:26:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-783-evidence-prep-the-operator-review-queue-.md
- **Context:** Initial task creation
