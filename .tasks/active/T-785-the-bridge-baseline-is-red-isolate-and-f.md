---
id: T-785
name: "The bridge baseline is red: isolate and fix the TEETH regression blocking verification
  of the AEF reference corpus"
description: >
  tests/run-bridge-tests.sh fails with 'TEETH FAIL - 1 leg(s) failed' and reports
  'an instrument that passed on 2026-08-15 no longer does, or an exclusion went stale'.
  Its own message states these instruments are hermetic and leave the repo untouched,
  so this is a real regression in whatever that teeth script guards, not harness noise.
  This blocks the confirmed yardstick directly: tests/fixtures/aef-bpmn is 832's contractual
  reference corpus for AEF's AEF-led Child-2 forward bridge, and with a red baseline
  no change to that corpus can be shown safe. A first isolation attempt via tools/_t509-instrument-sweep.sh
  exceeded a 280s foreground bound and was not completed. Scope is isolate, diagnose,
  and fix the single failing instrument, or record why it cannot be fixed. Scope explicitly
  excludes weakening, deleting or excluding the failing check to make the suite green
  - the ground rule is that lines removed is not success and a check is never weakened
  to look cleaner.

status: issues
workflow_type: build
owner: agent
horizon: now
tags: [baseline, tests, aef-seam]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T22:35:07Z
last_update: 2026-09-21T22:40:19Z
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
  - ts: '2026-09-21T22:40:12Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T22:40:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tests/test_forward_fixtures.py,tools/_t353-repair-probe.sh,tools/_t509-instrument-sweep.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-785: The bridge baseline is red: isolate and fix the TEETH regression blocking verification of the AEF reference corpus

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Named: `_t560-absence-census-teeth.py`, rc=1, leg 5.** Legs 1–4 PASS
      (uncontrolled absence flagged · controlled absence not flagged · presence not
      misclassified · exceeding the ratchet exits 1). Leg 5:

      ```
      FAIL: leg 5: unoverridden run gave rc=1 over 3157 legs
            — either the live corpus regressed or T560_TASK_ROOT leaked
      ```

      **CORRECTION — this AC first claimed the isolation was complete, and it was not.**
      Reading the bridge suite's captured tail named `_t560` only. The full sweep, run to
      completion in the background, names **two** regressed instruments:

      ```
      SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:
        - _t400-schema-teeth.sh          (rc=1)
        - _t560-absence-census-teeth.py  (rc=1)
      ```

      I had written that reading the capture was "cheaper and more reliable" than re-running
      the sweep. It was cheaper; it was **not** more reliable — it under-reported by one
      instrument, because the capture is a last-40-lines tail and the earlier failure had
      scrolled off. The sweep is the authority; the tail is a convenience. Recorded rather
      than silently amended, because the wrong half of that sentence is the instructive half.

      (Two further instruments ABSTAINED at rc=2 — `_t581-byteid-baseline-teeth.py` and
      `_t588-differential-teeth.sh`, "declined to certify". Not failures, and not passes
      either; left as observed.)

- [x] **SECOND INSTRUMENT FIXED: `_t400-schema-teeth.sh` now 10/10, rc=0.** Its failing leg
      was RECIPROC — *"the real register must pass. A guard that reds on the live file gets
      reverted rather than obeyed."* It red because 7 field names in `concerns.yaml` were
      accounted for by nothing: the **G-027 shape**, *"a plausible, readable field name that
      no code reads. The entry looks complete and the tooling behaves as if it is empty."*

      **Two of the seven were mine, added to G-076 earlier today** —
      `escalation_arc_level` and `escalation_closure_addendum`. Same defect shape as the
      T-560 one: I wrote something that reads like a record and is invisible to every
      instrument.

      The `escalation_closure_addendum` case is the sharper one. It **was a closure
      condition**, and `decision_trigger` is *"THE rendered closure condition"* that `bin/fw`
      and `audit.sh` read. By carrying it under an invented name I hid a closure requirement
      from the renderer and the audit — which is precisely the cost G-027 describes. Folded
      into `decision_trigger`; the arc narrative folded into `evidence`. Both by textual edit,
      not a YAML re-dump, so the other 55 entries keep their bytes. Verified: 56 entries
      intact, both invented names gone, neither narrative lost.

      The remaining five (`id_note` ×6, `sovereignty_note` ×4, `containment`,
      `not_a_finding_about`, `why_this_run_did_not_move_it`) are pre-existing conventions this
      register uses and the schema never learned. Taking the tool's own second remedy — *"if
      it is genuinely human-only prose, add it to PROSE in this file with a one-line note"* —
      **after verifying the premise**: zero field-level reads for all five
      (`containment`'s nine grep hits are the English word in prose, not a field access).

      **This is documentation, not defanging, and the check itself proves it:** leg (b)
      *"arbitrary unaccounted field → rc=1, names the field"* still PASSES, so a newly invented
      field still reds. The PROSE list's own docstring is the warrant — *"Listing them is the
      point: it is the difference between 'we know this is prose' and 'we assumed something
      read it'."*

- [x] **Root cause, and the evidence chooses between the two readings.** Leg 5 offers "the
      live corpus regressed" OR "T560_TASK_ROOT leaked". An unoverridden run of
      `tools/_t560-absence-assertion-census.py` settles it:

      ```
      RATCHET       baseline 78, current 112
      FAIL: uncontrolled absence assertions ROSE from 78 to 112.
      ```

      **The corpus regressed.** No environment leak. Structurally: a `## Verification` leg
      asserts something is absent while nothing establishes the search could have found it —
      so the leg is green whether the property holds or the pattern is simply wrong.

      **Not a new finding, and deliberately not re-filed.** T-669 already carries this
      condition ("uncontrolled absence assertions rose 78 to 90"). It has since risen to 112.
      Filing a second task would manufacture a duplicate of a filed defect — the T-738 lesson
      from earlier today.

- [ ] **BLOCKED by an open Sovereign question — and I am part of the regression.** Of the 112,
      **2 are mine from today**, both in T-778, plus 1 in T-774:

      ```
      .tasks/completed/T-778-...md:183  [bang-grep]
          ! grep -rlE '^cost_estimate:' .tasks/active/
      ```

      The census's rule is precise (`control_level`, line 134): an absence leg is PATTERN-
      controlled only when a **sibling leg in the same Verification block** uses the *same
      string as its own grep pattern*, proving the pattern matches where the thing IS present.
      So the repair is to add companion legs to T-778's block.

      **T-778 is in `.tasks/completed/`.** Whether an agent may edit `## Verification` blocks
      there is the exact open `[REVIEW]` criterion on **T-353** — `owner: human`, unchecked:
      *"Ruling: may an agent edit `## Verification` blocks inside `.tasks/completed/`?"*, which
      its own text calls "a convention question about other owners' archived records".

      I did not decide it to clear my own mess. Marked BLOCKED rather than left looking undone.

      **The operator-facing consequence, which is the useful output of this task:** T-353 is
      not one of 71 interchangeable review items. Its ruling is the unblocker for the red
      baseline — and T-353 records that *"the patch set is already built and proven, and no
      part of it has been applied"* (`tools/_t353-repair-probe.sh`, 16/16). One ruling releases
      a proven repair for the pre-existing 31 **and** permits the 3 I introduced to be fixed.

- [x] **Nothing was weakened, excluded or deleted — proven by the diff.** No entry was added
      to any exclusion list, `tools/_t560-absence-baseline.txt` was **not raised** (it still
      reads 78), and no check was edited. The ratchet remains red and correctly so: it is
      reporting a real condition, and making it green by moving the baseline is the one
      prohibited move.

      Also left untouched on purpose: the sweep's excluded instrument whose header records
      that an earlier mutant "DELETED THIS REPOSITORY". Its exclusion is deliberate and, in
      the sweep's own words, "not an agent's call".

- [x] **Contractual corpus unaffected — re-verified after the investigation.**
      `python3 tests/test_forward_fixtures.py` exits 0 over all **19** fixtures: every flow
      node and sequence flow carries `aef:uid`, all 20 `aef:meta` keys are within the bridge
      whitelist, governance exercised via lanes. 832's deliverable to AEF's Child-2 bridge is
      unchanged by this work.

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
         1. Run `bin/fw reviewer T-785`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-785 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

bash tools/_t400-schema-teeth.sh > /dev/null 2>&1
bash tools/_t400-schema-teeth.sh 2>&1 | grep -q 'arbitrary unaccounted field'
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[x for x in d['concerns'] if isinstance(x,dict) and x.get('id')=='G-076'][0]; sys.exit(0 if 'escalation_arc_level' not in g and 'ranked 0' in g['decision_trigger'] else 1)"
python3 tests/test_forward_fixtures.py > /dev/null 2>&1
grep -qx '78' tools/_t560-absence-baseline.txt
test -f tools/_t560-absence-census-teeth.py
python3 -c "import subprocess,sys; o=subprocess.run(['python3','tools/_t560-absence-assertion-census.py'],capture_output=True,text=True).stdout; sys.exit(0 if 'baseline 78' in o else 1)"

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
     fw inception decide T-785 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T22:35:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-785-the-bridge-baseline-is-red-isolate-and-f.md
- **Context:** Initial task creation

### 2026-09-21T22:40:19Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** Blocked by T-353's open operator ruling: the repair requires adding sibling control legs to T-778's Verification block, and T-778 is in .tasks/completed/. Whether an agent may edit Verification blocks there is exactly what T-353 asks. 4 of 5 ACs met; the 5th is BLOCKED, not failed.
