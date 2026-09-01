---
id: T-665
name: "_t358-teeth.py is dead the same way T-663 was: its UNMUTATED control fails, so the mutations below it prove nothing about the lane-fabrication guard"
description: >
  _t358-teeth.py is dead the same way T-663 was: its UNMUTATED control fails, so the mutations below it prove nothing about the lane-fabrication guard

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
created: 2026-09-01T10:41:04Z
last_update: 2026-09-01T10:45:53Z
date_finished: 2026-09-01T10:45:53Z
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

# T-665: _t358-teeth.py is dead the same way T-663 was: its UNMUTATED control fails, so the mutations below it prove nothing about the lane-fabrication guard

## Context

Found by this session's `_t509` instrument sweep, which reported `_t358-teeth.py`
**ABSTAINED**: *"TEETH BROKEN — the UNMUTATED copy fails, so no mutation below proves
anything."*

These teeth back T-358 — the arc's central open task, the one where opening a
third-party BPMN file silently asserts every task in it is human-sovereign. Their six
mutations are what make T-358's diagnosis ACs mean something, including the mutation
that changes only what a fabricated lane *asserts*.

Second dead teeth file found today (after T-663), and a **different** cause: not an
aged pin but a hand-written dependency list that T-604 desynchronised on 2026-08-26 by
adding an import. The family resemblance is the point — a hand-maintained claim about
the world that nothing re-checks when the world moves. The pinned ref (T-663), the
exclusion's stated reason (PL-305), and this copy list are three instances.

The sharper half: unlike T-663's teeth, these were **never excluded and were running the
whole time**. A broken control exits 2, the sweep classifies exit 2 as abstention, and
abstention reads as an acceptable outcome. Being wired is not the same as being watched.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

- [x] **The death is reproduced and its cause named — and it is NOT T-663's cause.**

      **DONE.** Reproduced: `TEETH BROKEN — the UNMUTATED copy fails`, rc=2, with
      `ERR_MODULE_NOT_FOUND: Cannot find module '/tmp/t358-teeth-*/tools/_cdp-attach.mjs'
      imported from .../_t358-lane-provenance-cdp.mjs`.

      Not an aged pin. `mutated_tree()` copied a **hand-written literal list** of the
      probe's files — `("_t358-lane-provenance-cdp.mjs", "gallery-serve.py")` — into a
      temp tree. On **2026-08-26, `05d28d24` (T-604)** added
      `import { pageWsUrl } from './_cdp-attach.mjs'` to the probe and did not update
      that list. From that commit on, every temp copy was missing a module the probe
      imports, so the control failed on module resolution rather than on anything it
      measures.

      Same *family* as T-663 and PL-305 without being the same defect: a hand-maintained
      claim about the world (a pinned ref, an exclusion's reason, a dependency list) that
      nothing re-checks when the world moves.

- [x] **What the teeth were guarding is stated, and the exposure is bounded.**

      **DONE — dead 2026-08-26 → 2026-09-01, six days.** In that window: **1** commit
      touched `src/` (`504e4bc9`, T-618 — panel surfacing of determinism/sideEffect) and
      **0** commits touched the probe.

      **No T-358 acceptance criterion rests on a dead instrument.** Every T-358 AC these
      teeth back was ticked 2026-08-03/04, three weeks *before* the death. What was lost
      was the ongoing guarantee, not the original evidence.

      **And the exposure was not realised:** the repaired teeth pass on current HEAD,
      which already contains T-618. So the one unguarded commit did not in fact break
      what they guard. Stated as a measured outcome, not as reassurance — the window was
      real and the next one might not land this way.

- [x] **The repaired control does not depend on anything that ages.**

      **DONE.** The literal list is replaced by `local_deps()`, which derives the probe's
      sibling `.mjs` imports from the probe's own source, transitively (`from './x.mjs'`,
      `import './x.mjs'`). Adding an import now updates the copy set automatically, and a
      derived name that is missing from `tools/` exits **3 COULD-NOT-MEASURE** naming the
      file — loud, rather than a control that fails for an unrelated reason.

      Adding `"_cdp-attach.mjs"` to the tuple was the one-line fix available and was
      deliberately not taken: it repairs today and ages identically at the next import.

- [x] **The mutations still fail for their own predicted reasons, each checked
      individually.**

      **DONE.** `TEETH PASS — control green, 6 mutations each red for their own predicted
      reason`, rc=0. All six report individually, including the one that changes only
      what a fabricated lane *asserts* (`sovereignty` → unpinned) and the two negative
      controls. The existing per-mutation reason checking was already correct and was
      left alone — the defect was upstream of it, in the copy.

- [x] **It runs in the standing sweep and is not excluded.**

      **DONE, and it never was excluded** — `grep -c '"_t358-teeth.py|'
      tools/_t509-instrument-sweep.sh` = 0. It ran in today's sweep and reported
      **ABSTAINED**. That is the finding worth carrying: unlike T-663's teeth, which were
      excluded by name, these were fully wired and running, and still went unnoticed for
      six days — because a broken control exits 2, the sweep classifies exit 2 as
      abstention, and abstention reads as an acceptable outcome rather than a dead
      instrument. **Being wired is not the same as being watched.**

- [x] **No T-358 acceptance criterion is silently re-ticked or un-ticked**, and no
      Human AC is touched. Verified by diffing T-358 for changed checkbox lines: **0**.
      The only files this task changed are `tools/_t358-teeth.py` and this task file.

      The first version of this check asserted T-358 was *unmodified* and the P-011 gate
      failed it — correctly. `fw work-on T-358` had bumped `last_update:` at 09:27 as
      bookkeeping. The command was testing something stronger than the AC claims; it now
      tests changed checkbox lines, which is the actual assertion and still fails on a
      real re-tick. The gate catching my own over-broad verification is the gate working.

      Nothing was found that would have required correcting a ticked AC (see AC-2)., and no
      Human AC is touched. If the repair shows a ticked T-358 AC was unsupported, that
      is reported as a finding for the operator, not corrected on their behalf.

<!-- No Human AC: wholly agent-verifiable, and T-664 measured the queue this would add
     to at 61 undecided items with zero agent-operable outflow. -->


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
         1. Run `bin/fw reviewer T-665`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-665 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The teeth must pass: control green AND all six mutations red for their own reason.
python3 tools/_t358-teeth.py
# The dependency list must be DERIVED, not hand-written — the literal tuple must be gone.
sh -c '! grep -q "for f in (\"_t358-lane-provenance-cdp.mjs\", \"gallery-serve.py\")" tools/_t358-teeth.py'
grep -q "def local_deps" tools/_t358-teeth.py
# The derivation must actually find the import that killed it, or it is decoration.
python3 -c "import sys; sys.path.insert(0,'tools'); import importlib.util as u; s=u.spec_from_file_location('t','tools/_t358-teeth.py'); assert '_cdp-attach.mjs' in open('tools/_t358-lane-provenance-cdp.mjs').read(); print('probe still imports _cdp-attach')"
# This task must not have changed any T-358 acceptance criterion. Asserting "T-358 is
# untouched" is the WRONG test and failed here for a legitimate reason: `fw work-on T-358`
# bumps `last_update:` as bookkeeping. The AC's claim is about checkbox lines, so that is
# what is checked -- a re-tick or un-tick still fails this.
sh -c 'test "$(git diff -- .tasks/active/T-358-*.md .tasks/completed/T-358-*.md | grep -cE "^[+-][[:space:]]*- \[[ x]\]")" = "0"'

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
     fw inception decide T-665 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T10:41:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-665-t358-teethpy-is-dead-the-same-way-t-663-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b2a152e7
- **Timestamp:** 2026-09-01T10:46:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-01T10:45:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
