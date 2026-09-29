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

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: [baseline, tests, aef-seam]
components: [tests/fixtures/invalid/E-XML-WORKFLOW-KIND.bpmn, tests/test_finding_anchorability.py, tests/test_harness_cross_form_agreement.py, tools/concerns-schema.py, tools/_t560-absence-assertion-census.py, tools/_t785-t859-credit-probe.py, tools/_t820-rule-axes.sh, tools/_t826-kind-rule-axes-teeth.sh, tools/_t845-control-recogniser-tests.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T22:35:07Z
last_update: 2026-09-29T08:14:54Z
date_finished: 2026-09-29T08:14:54Z
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
  - ts: '2026-09-26T09:06:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 2
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=1 
      (L1:keyword=lane,L1:keyword=sequence flow); F3=2 (L2:keyword=aef-bpmn); 
      F1=2 (L1:keyword=designer,L1:keyword=bpmn)
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

- [x] **WAS BLOCKED by an open Sovereign question — and I am part of the regression.** Of the 112,
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


      **RESOLVED 2026-09-29 — the ruling arrived the day after this was marked BLOCKED.**
      PD-308 (operator, 2026-09-22, T-802) is exactly the permission this AC was waiting on:
      an agent may APPEND a sibling control leg to a `## Verification` block inside
      `.tasks/completed/`, additive only, logged Tier 2. The task sat in `issues` for a week
      after its blocker had been lifted, which is the cheap lesson here — a task blocked on a
      ruling has no trigger that fires when the ruling lands.

      **But the corpus had moved further than the unblocking.** T-669 then drained 29 legs
      under that same ruling and lowered the baseline 78 -> 74 in the same commit. The 112
      this AC counted is now 75, and the 3 legs it named (2 in T-778, 1 in T-774) are inside
      the grandfathered 74 — the ratchet does not fail on them. They remain T-669's declared
      population and are deliberately NOT re-filed here (the T-738 duplicate lesson, which
      this task already invoked once).

      **So the 75th leg is the only one this task owed, and it was not in the list above.**
      It is `T-859:296`, created 2026-09-25 22:49 — five hours after T-669's drain commit,
      the single census-listed task newer than the baseline. Its repair is the next AC.

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

- [x] **THE 75th LEG WAS UNCONTROLLABLE, AND THE READER WAS WHY — not the leg, and not a
      missing permission.** `T-859:296` is `test "$(grep -c Traceback /tmp/.t859.out)" -eq 0`.
      The census reported `WHY NOT CREDITED: no grep pattern to control (zero comes from a
      command's output, not a match)`. **That sentence is false about this leg.** The zero comes
      from a match, and the pattern is `Traceback`, in plain sight. `GREP_PAT` required the
      pattern to be QUOTED, so `patterns_in()` returned `[]` — and because PATTERN credit is
      `p in sib_pats` over the leg's OWN patterns, a leg with no readable pattern can never be
      credited by ANY companion. The mis-read did not mislabel it; it made it permanently
      uncontrollable, and T-669 costed it into the "48 BLOCKED, needs an operator ruling
      (OBS-382)" bucket on exactly that basis. Appending under PD-308 would have been a no-op
      that recorded coverage which does not exist — the OBS-379 mistake T-843 was punished for.

      **Same class as the `len(p) >= 3` floor T-845 removed:** a reader limit wearing a rule's
      clothes, silently making a class of valid controls impossible to express. `GREP_PAT` now
      reads a bare pattern too, refusing a `$`-leading token (an interpolated pattern this
      reader cannot know — calling the literal `"$VAR"` its pattern would be
      mention-not-invocation in a new costume).

- [x] **The widening credits NOTHING on its own — measured, not asserted.** Before and after,
      over all 779 files carrying a `## Verification` block: PATTERN 76 / EXISTENCE 27 /
      NONE 75, and the 75 uncontrolled legs are the **identical set** (`diff` of the two
      file:line lists is empty). This matters because every change to this recogniser moves in
      the false-negative direction — it can only ever credit MORE — so "the count did not move"
      is the evidence that nothing was silently drained.

- [x] **Teeth, proven by replaying the pre-fix reader.** Four cases added to
      `tools/_t845-control-recogniser-tests.sh`: a bare pattern is read; a bare-pattern leg is
      creditable by a same-string companion; a `$`-leading token stays unreadable; a MENTIONED
      bare pattern is still refused; quoted extraction is unchanged. **16/16 pass against the
      fixed reader; replayed against the pre-fix reader via `T845_REPO_ROOT`, the two capability
      cases FAIL (12, 13) and all three over-crediting guards still PASS** — which is the split
      that proves the suite tests the change rather than the corpus.

- [x] **Ratchet GREEN, and the baseline was not touched.** One companion leg appended to
      `T-859` under PD-308 (5 insertions, 0 deletions; see `## Tier 2 log` below). Census now
      exits **0**: PATTERN 76 -> 77, NONE 75 -> 74, `RATCHET baseline 74, current 74`.
      `tools/_t560-absence-baseline.txt` still reads **74** — unchanged by this task, which is
      the prohibited move this task's own scope named. `_t560-absence-census-teeth.py` is
      **5/5**, including leg 5 ("with no override the census reads the live corpus (4135 legs)
      and is green") — the leg whose failure opened this task.

- [x] **This task's own Verification block had rotted, and it rotted the way the template
      warns.** Two legs pinned the literal `78` — the baseline on the day of filing. T-669
      lowered it to 74 and both went red for reasons unrelated to this task: T-3326's
      mutable-corpus anchor, found inside the block of the task complaining about a red
      baseline. Replaced with the invariant (census exits green, teeth pass, recogniser suite
      passes, the companion is present), not the number.


- [x] **The ratchet is not this task's to pin, and a concurrent session proved it in twenty
      minutes.** This task's first draft of its own `## Verification` asserted the GLOBAL census
      exits 0 and its teeth report 5/5. Measured: green at 10:01 (`baseline 74, current 74`,
      rc=0), red at 10:09 (`74 / 75`) — because another session added an uncontrolled
      `test -z "$(git log --since=... -- <path>)"` leg to `.tasks/active/T-826` at 10:08:43,
      while this task was being verified. **Nothing about this repair changed in between.**

      That is a **G-015 carrier** by the bridge suite's own definition — *"a line asserting a
      global, always-moving property ... that decays when anyone else edits the tree"* — and
      the second one this task found in its own block within the hour (the first pinned the
      literal `78`). A ratchet is a corpus-wide rise detector owned by no single task; gating one
      task's close on it makes that close a function of every other session's in-flight work.

      Replaced with `tools/_t785-t859-credit-probe.py`, which asserts what T-785 delivered: the
      one leg that had risen above the baseline is READ (bare pattern extractable), CLASSIFIED
      (still an absence assertion, so crediting it is not vacuous) and **PATTERN-credited**.
      **Mutation-proven in both directions** — revert the reader change, rc=1; revert the PD-308
      companion, rc=1; both present, rc=0 — so each half of the repair is independently
      load-bearing, and the probe ABSTAINS at rc=2 rather than passing if the leg moves.

      **Not a weakening, and the scope of this task names that as the prohibited move.**
      `_t560-absence-assertion-census.py` keeps its ratchet, `_t560-absence-baseline.txt` still
      reads **74**, no exclusion list grew, and the census is red on T-826's leg as of this
      writing — correctly, and for its own owner to answer. T-826 is another session's ACTIVE,
      in-flight task: **not edited**, and deliberately not re-filed as a task in someone else's
      lane. Recorded as an observation instead.


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

## Tier 2 log — the 1 edit made under PD-308

PD-308 (operator ruling, 2026-09-22, T-802) permits an agent to **APPEND** a sibling control
leg to a `## Verification` block inside `.tasks/completed/` **only** where a teeth instrument
requires it to discharge an uncontrolled assertion, **additive only**, each edit **logged as
Tier 2**. This is that log, in the format T-669 established.

| # | file | line of the uncontrolled leg | pattern asserted absent | control appended | route |
|---|------|------------------------------|--------------------------|------------------|-------|
| 1 | `.tasks/completed/T-859-t542-cost-axis-guard-raises-attributeerr.md` | 296 | `Traceback` (bare, unquoted) | `python3 -c 'raise RuntimeError("t859 control")' > /tmp/.t859.control 2>&1 \|\| true; grep -q 'Traceback' /tmp/.t859.control` (PATTERN) | companion leg makes a real Python traceback and greps the same string over it |

**The edit is an addition only.** `git diff --numstat` on the file reports **5 insertions, 0
deletions** — the mechanical form of PD-308's additive-only constraint. Nothing above the
appended lines was altered.

**The target block was verified GREEN before the control was appended.** T-669's own drain
recorded the trap: *"14 of the 55 reachable legs were RED when measured and got no companion:
a control over a leg that already fails records coverage that does not exist."* Measured here
first — `_t542-cost-blast-radius-teeth.py` exits 1 as leg 1 requires, `grep -c Traceback` is 0,
the `finding(s):` line is present. The leg this control covers passes today.

**Why one edit and not a drain.** The ratchet is a rise-detector. Exactly one leg had been
added above the baseline since T-669 set it — `T-859:296`, created five hours after that
commit. Draining more would lower the count below the baseline without lowering the baseline,
which banks invisible credit against the next regression; that is the same "leaving it high
silently re-admits exactly that many" argument the baseline header makes, running the other way.

## Verification

# L-387 / SIGPIPE, CAUGHT BY THE GATE AND NOT BY HAND. These two lines were one:
#   bash tools/_t400-schema-teeth.sh 2>&1 | grep -q 'arbitrary unaccounted field'
# It passes in an interactive shell and FAILS under P-011 at exit 141 (128+13, SIGPIPE):
# `grep -q` exits at its first match, closes the pipe, the producer is killed writing to it,
# and the gate runs each leg under `-o pipefail`, so the pipeline reports the producer's death.
# A leg that is green by hand and red under the gate is worse than one that is simply red —
# it was verified by hand in this very task, twice, and reported as passing both times.
# Rewritten to the form the template documents as THE DEFAULT: redirect once, then grep the
# file. Line 1 asserts the teeth pass (rc=0); line 2 asserts the negative-control message is
# really in that output, so line 2 cannot go green against a run that never emitted it.
bash tools/_t400-schema-teeth.sh > /tmp/.t785.t400 2>&1
grep -q 'arbitrary unaccounted field' /tmp/.t785.t400
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[x for x in d['concerns'] if isinstance(x,dict) and x.get('id')=='G-076'][0]; sys.exit(0 if 'escalation_arc_level' not in g and 'ranked 0' in g['decision_trigger'] else 1)"
python3 tests/test_forward_fixtures.py > /dev/null 2>&1
# T-785 CLOSING LEGS. The two legs that stood here pinned the literal 78 — the baseline value
# on the day this task was filed. T-669 later drained the corpus and lowered the baseline to 74
# in the same commit, and both legs went red for a reason that has nothing to do with this task:
# the exact T-3326 mutable-corpus-anchor rot the template warns about, caught in this task's own
# block. Replaced with the INVARIANT that is actually this task's deliverable — the ratchet exits
# green, its teeth pass, and the recogniser change is pinned by its own suite — not the number.
# THE RATCHET IS NOT THIS TASK'S TO PIN, and twenty minutes of measurement proved it. The two
# legs that stood here asserted the GLOBAL census exits 0 and its teeth report 5/5 (leg 5 of
# which asserts the live corpus is green). Both were green at 10:01 — `baseline 74, current 74`,
# rc=0 — and red at 10:09, because a CONCURRENT session added an uncontrolled
# `test -z "$(git log --since=... -- <path>)"` leg to .tasks/active/T-826 at 10:08:43. Nothing
# about this task's repair changed in between. That is a G-015 carrier by the bridge suite's own
# definition — "a line asserting a global, always-moving property that decays when anyone else
# edits the tree" — and it makes this task's close a function of every other session's in-flight
# work. Replaced with a probe that asserts what T-785 DELIVERED: the one leg that had risen above
# the baseline is read, classified and PATTERN-credited. NOT a weakening — _t560 is unchanged,
# its baseline still reads 74, no exclusion list grew, and the ratchet is still red on T-826's
# leg right now, correctly, for its own owner to answer.
python3 tools/_t785-t859-credit-probe.py > /tmp/.t785.probe 2>&1 && grep -q 'CREDIT PROBE: PASS' /tmp/.t785.probe
bash tools/_t845-control-recogniser-tests.sh > /tmp/.t785.t845 2>&1 && grep -qE '# passed [0-9]+, failed 0' /tmp/.t785.t845
grep -q "grep -q 'Traceback' /tmp/.t859.control" .tasks/completed/T-859-t542-cost-axis-guard-raises-attributeerr.md
test -f tools/_t560-absence-census-teeth.py

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

**Symptom:** `tests/run-bridge-tests.sh` red with `TEETH FAIL — 1 leg(s) failed`, tracing to
`_t560-absence-census-teeth.py` leg 5: *"unoverridden run gave rc=1 over 3157 legs — either the
live corpus regressed or T560_TASK_ROOT leaked."* The census read `RATCHET baseline 74, current
75`. With the ratchet red, no change to `tests/fixtures/aef-bpmn` — 832's contractual reference
corpus for AEF's Child-2 forward bridge — could be shown safe.

**Root cause:** Two distinct causes, found in sequence, and only the second is this session's.

1. *The corpus did regress.* One uncontrolled absence-asserting Verification leg was added above
   the baseline after T-669 set it: `T-859:296`, created 2026-09-25 22:49, five hours after the
   drain commit. It is the only census-listed task newer than the baseline.

2. *And that leg could not be repaired through the sanctioned route.* `GREP_PAT` in
   `_t560-absence-assertion-census.py` required a grep pattern to be QUOTED. T-859's leg is
   `test "$(grep -c Traceback /tmp/.t859.out)" -eq 0` — the pattern is unquoted, so
   `patterns_in()` returned `[]`. Because PATTERN credit is `p in sib_pats` over the leg's OWN
   patterns, a leg with no readable pattern can never be credited by ANY companion. The
   instrument reported `WHY NOT CREDITED: no grep pattern to control (zero comes from a
   command's output, not a match)` — a sentence that is FALSE about this leg. So the repair
   PD-308 authorises (append a same-string companion) would have been a silent no-op.

**Why structurally allowed:** Three layers, each one the same shape one level up.

- *The reader was mistaken for the rule.* A quoting convention in a regex became, in effect, a
  rule about which legs are controllable — with no statement anywhere that it was doing so.
  This is the identical defect T-845 fixed when it removed the `len(p) >= 3` floor
  (*"what the floor actually did was make a whole class of valid controls impossible to express,
  and nothing in the output said so"*). The floor was removed; the quoting requirement beside it
  was not examined, because the fix was aimed at the symptom that had been reported.
- *The mis-read propagated into a costing.* T-669 classified this leg family as
  *"48 BLOCKED... they extract no grep pattern, so PATTERN credit is impossible... Unblocking
  them needs an operator ruling (OBS-382)."* True of the instrument as written, and the
  conclusion drawn was that a **sovereign ruling** was required — when what was required was a
  three-line change to a regex. A tool's limitation was escalated as a governance question.
- *The task itself sat 7 days past its own unblocking.* T-785 went to `issues` naming T-353's
  open ruling; PD-308 answered it the next day; nothing connected the two. Registered as
  **G-081** — deliberately NOT closed by this task, because surfacing one instance is mitigation,
  not prevention.

**Prevention:** Distinct from the fix, and in the layer that failed.

- `tools/_t845-control-recogniser-tests.sh` gains four cases pinning the capability AND its
  guards: a bare pattern is read; a bare-pattern leg is creditable by a same-string companion; a
  `$`-leading token stays unreadable; a MENTIONED bare pattern is still refused. **Teeth proven
  by replay** — against the pre-fix reader via `T845_REPO_ROOT`, the two capability cases fail and
  all three over-crediting guards still pass, so the suite is shown to test the change rather
  than the corpus.
- The behaviour-neutrality is itself pinned as evidence, not assertion: PATTERN 76 / EXISTENCE 27
  / NONE 75 before and after, **identical 75-leg set**. Every change to this recogniser can only
  credit MORE, so an unmoved set is the proof that nothing was silently drained.
- `tools/_t785-t859-credit-probe.py` pins the repair itself rather than the corpus-wide
  ratchet, after the ratchet-pinning leg decayed within twenty minutes under a concurrent
  session's edit (OBS-442). Mutation-proven both ways: revert the reader change, rc=1;
  revert the PD-308 companion, rc=1; it ABSTAINS at rc=2 rather than passing if the leg moves.
- **G-081** registered for the class this task's own week-long stall demonstrates, with a
  decision_trigger that demands the census (how many tasks in `issues` name an already-ruled
  blocker?) and explicitly refuses closure-by-instance.
- This task's own Verification block, which had rotted against the literal `78`, now pins the
  invariant. The rot is recorded rather than quietly repaired: T-3326's mutable-corpus anchor
  found inside the block of the task complaining about a red baseline.

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

### 2026-09-29T07:39:14Z — status-update [task-update-agent]
- **Change:** status: issues → started-work

### 2026-09-29T07:41:42Z — status-update [task-update-agent]
- **Change:** status: started-work → issues
- **Reason:** Round 3 census: reopened to started-work at 07:39Z with no work done. AC 4 is BLOCKED on T-353's open [REVIEW] ruling (owner: human) — may an agent edit ## Verification blocks inside .tasks/completed/. Sovereign question, surfaced not resolved; parking back to the state the blocker warrants.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4aec57b9
- **Timestamp:** 2026-09-29T08:14:57Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 14
     - evidence: `python3 tests/test_forward_fixtures.py > /dev/null 2>&1`

### 2026-09-29T08:14:54Z — status-update [task-update-agent]
- **Change:** status: issues → work-completed
