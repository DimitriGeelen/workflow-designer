---
id: T-576
name: "T-423 fallout: the trailer probe asserts a claim T-423 retired, and running it corrupts a fixture two wired teeth depend on"
description: >
  389133c8 stopped emitting the DI trailer. tools/_t361-export-trailer-cdp.mjs still asserts exported bytes CARRY it (PREFIX check, line 91) so it now fails on a correct designer, and its failure reads as 'the designer lost the trailer' rather than 'this probe was superseded'. Worse: it writes tests/fixtures/exported/t361-trailer-witness.bpmn unconditionally BEFORE returning, so running it replaces a trailer-carrying witness with a trailer-free export - and tools/_t361-guard-teeth.py cases 7 and 8 both mutate that witness, case 8 raising 'witness did not carry the current trailer - nothing mutated'. One unwired probe therefore breaks a wired teeth script. Measured: current export carries 0 trailer occurrences, the witness carries 1 and was last written under T-399 at 4c40414c. Root question for the RCA is not the probe but the omission: nothing enumerates the instruments that assert the presence of a thing a change removes.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [bug, instrument, t423-fallout]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-23T19:35:57Z
last_update: 2026-08-24T22:38:41Z
date_finished: 2026-08-24T22:38:41Z
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

# T-576: T-423 fallout: the trailer probe asserts a claim T-423 retired, and running it corrupts a fixture two wired teeth depend on

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**The probe and the corruption are two defects, not one, and they want different fixes.**
The stale assertion makes the probe *wrong*. The unconditional fixture write makes it
*dangerous to run* — including dangerous to run while diagnosing the first. Fixing only the
assertion leaves a probe that still overwrites a fixture two wired teeth cases depend on.

- [x] **The retired claim is settled by asking whether its subject still exists, not by
      repointing it at whatever the exporter emits now.** `389133c8` (T-423) stopped emitting
      the DI trailer, so `_t361-export-trailer-cdp.mjs`'s PREFIX check (`:91`) asserts a
      property the designer is now correct *not* to have. Decide as T-579 decided for
      `_t364-byteid-precondition-teeth.py`: if the subject was **deleted**, retire the probe;
      repointing it at a replacement string restores a green reading for a check that no
      longer exists. If some *part* of its subject survived, keep only that part and say
      which. Record the measurement either way — current export carries **0** trailer
      occurrences, the witness carries **1**, last written under T-399 at `4c40414c`.

- [x] **Running the probe cannot corrupt `tests/fixtures/exported/t361-trailer-witness.bpmn`.**
      Today it writes the witness unconditionally *before* returning, so a superseded probe
      silently replaces a trailer-carrying fixture with a trailer-free export. Whatever the
      first AC decides, the write must not survive as an unguarded side effect: a diagnostic
      that mutates shared state is not safe to run while diagnosing. If the probe is retired
      this is discharged by the retirement; state that explicitly rather than leaving it
      implied.

- [x] **`tools/_t361-guard-teeth.py` passes, and case 8 is shown able to FIRE.** It is wired —
      not by `run-bridge-tests.sh` but by `_t509-instrument-sweep.sh`, which globs `tools/*teeth*`
      and does not exclude it (population 58, 5 excluded, RAN 53 passed 53 measured
      2026-08-24). Cases 7 and 8 both mutate the witness and case 8 raises *"witness did not
      carry the current trailer — nothing mutated"*. A green sweep is **not** evidence those
      cases still discriminate: it is equally consistent with the witness being intact and
      with the case having become a no-op. Mutate the witness in a temp copy and show case 8
      red, or record why it cannot be.

- [x] **The latent-hazard state is named in the record, because "currently green" is why this
      went unnoticed.** The probe is unwired (`tools/unwired-guard-baseline.txt:163`), so
      nothing has run it, so the witness is still intact and the teeth still pass. The defect
      is loaded, not firing. Any claim that the tree is fine must say which of those two it
      means.

- [x] **The root omission is filed as its own task, not fixed here.** The description names it:
      *nothing enumerates the instruments that assert the PRESENCE of a thing a change removes.*
      That is a general instrument over the whole tree and a separate deliverable (one task =
      one deliverable). File it with the two known instances as its evidence — this probe, and
      `_t364-byteid-precondition-teeth.py` retired under T-579 for the identical reason — and
      link it here.

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

# ── T-576 ─────────────────────────────────────────────────────────────────────
# Each line's own exit code is the verdict; nothing is chained.
# The probe is gone. Asserted POSITIVELY over the population, not by grepping for
# an absence: the unwired census derives its own findings and the ratchet compares
# them to the committed baseline, failing in BOTH directions (T-560).
python3 tools/_t451-unwired-guard-census.py --ratchet
# The witness the probe would have corrupted still carries the trailer. Positive count.
test $(grep -c "BPMN DI (visual layout) omitted" tests/fixtures/exported/t361-trailer-witness.bpmn) -eq 1
# The guard that reads that witness.
python3 tests/test_emitted_comment_claims.py
# Its teeth: control green plus 8 mutations. Case 8 RAISES if the witness lost the
# trailer, so a pass here is the evidence that case 8 still discriminates rather than
# having quietly become a no-op.
python3 tools/_t361-guard-teeth.py

## Recommendation

**Recommendation:** close it. All five Agent ACs are ticked on measurement; the stale probe
is retired, the corruption hazard is removed with it, and the wired teeth it endangered are
green with the discriminating case proven to fire.

**Evidence:** `python3 tools/_t451-unwired-guard-census.py --ratchet` → baseline 64, current
findings 64, no movement (a file that fails in both directions). `python3
tools/_t361-guard-teeth.py` → rc 0, control green plus 8 mutations each red on their own
check, including case 8 which raises outright if the witness lost the trailer.
`python3 tests/test_emitted_comment_claims.py` → rc 0. Witness still carries 1 trailer
occurrence.

**Rationale for retiring rather than repointing:** all four of the probe's checks were about
the DI trailer T-423 retired, including the two that do not look trailer-shaped — `PREFIX`
*is* the trailer text and `FALSE_TAIL` only ever appeared inside it, making that check
vacuously true once the trailer went. There was no surviving subject to repoint at, and a
replacement string would have restored a green reading for a check that no longer exists.

**What is NOT fixed here, deliberately:** the root omission is T-583. This task is the second
instance of its class in 24 hours; the first was T-579. Both were found by hand while working
on something adjacent, and neither would have been found by any gate in this tree.

## RCA

**Symptom.** `tools/_t361-export-trailer-cdp.mjs` asserts exported bytes carry the DI trailer.
They do not, and are correct not to. Its failure text reads *"no DI trailer comment found in
exported bytes at all"* — which names the designer as the thing that broke.

**Root cause.** `389133c8` (T-423) stopped emitting the trailer. That was deliberate and
correct. The probe was not updated, and nothing connected the two, because **nothing in this
tree enumerates the instruments that assert the PRESENCE of a thing a change removes.**

**Why it was not caught, which is the part worth keeping.** The asymmetry is structural, not
accidental:

- When a change **adds** something, what breaks is a guard asserting its absence. Those guards
  are the ones that run — that is what an absence guard is for — so they go red and get read.
- When a change **removes** something, what breaks is a guard asserting its presence. Those
  can be unwired, excluded by naming convention, or one-shot. They go **quiet**.

Both retirements this week are that shape. `_t364-byteid-precondition-teeth.py` (T-579) was
invisible because `_t509-instrument-sweep.sh` excludes it by name. This probe was invisible
because it is unwired (`unwired-guard-baseline.txt:163`). In each case "the suite is green"
was true and meant nothing about the instrument in question.

**Second-order defect, worse than the first.** The probe writes the witness fixture
unconditionally *before* returning its verdict. So the act of running it to find out whether
it still works would have destroyed the evidence — replacing a trailer-carrying witness with a
trailer-free export, breaking `tests/test_emitted_comment_claims.py` and `_t361-guard-teeth.py`
case 8, which raises outright when the trailer is missing. A diagnostic that mutates shared
state is not safe to run while diagnosing. Being unwired is the only reason this never fired:
**the defect was loaded, not firing**, and those are different claims about tree health.

**Two checks that did not look like trailer checks.** `PREFIX` *is* the trailer text
(`'BPMN DI (visual layout) omitted'`) and `FALSE_TAIL` only ever appeared inside the trailer,
so with the trailer gone that check was vacuously true. A reader auditing "which checks are
about the retired thing?" by name would have kept two of the four. This is why T-583 must not
assume its answer is a grep: the constant's name does not contain the thing it matches.

**Fix.** Retired the probe. There was no surviving subject to repoint it at, and a replacement
string would have restored a green reading for a check that no longer exists — the error the
T-581/T-579 sequence had just finished removing. Retirement discharges the corruption hazard
as well, rather than guarding the write.

**Prevention, not mitigation.** Retiring two probes is mitigation. Prevention is **T-583**,
which owns the general instrument. This task is deliberately not closing that gap, and says so
rather than letting the local repair read as a systemic one.


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

### 2026-08-23T19:35:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-576-t-423-fallout-the-trailer-probe-asserts-.md
- **Context:** Initial task creation

### 2026-08-24T22:35:02Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cb9b61c5
- **Timestamp:** 2026-08-24T22:38:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-24T22:38:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
