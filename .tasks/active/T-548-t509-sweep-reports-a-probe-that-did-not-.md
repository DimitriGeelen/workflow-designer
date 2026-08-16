---
id: T-548
name: "_t509 sweep reports a probe that did not finish (rc=124) as a regression"
description: >
  _t509 sweep reports a probe that did not finish (rc=124) as a regression

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T17:23:05Z
last_update: 2026-08-16T17:23:05Z
date_finished: null
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

# T-548: _t509 sweep reports a probe that did not finish (rc=124) as a regression

## Context

T-543 established the mechanism and deliberately left the repair. `_t509`'s
run loop is:

```sh
if timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  rc=$?; fail=$((fail + 1)); FAILED+=("$f (rc=$rc)")
fi
```

Every non-zero exit becomes `fail`, and the verdict then reads:

```
SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:
  - _t525-fabric-coverage-teeth.py (rc=124)
...a red here is a real regression in the thing it guards.
```

`rc=124` is GNU `timeout`'s exit code. `_t525` runs **86.04s against a 90s cap**
and passes 7/7 standalone — nothing regressed in fabric coverage, a probe ran
out of wall-clock, and the reader is sent hunting a bug that does not exist.

`rc=2` is worse in the same direction: the sweep's own exclusion list argues
that `_t364-byteid-precondition-teeth.py` "exits 2 BY DESIGN, refusing to
certify… converting that to a suite failure would punish the honesty" — and
then does exactly that to any *other* probe that abstains, because the
reasoning was written into an exemption keyed on a **filename** rather than
into the classifier. That is T-509's own shape, in T-509's own tool.

## Acceptance Criteria

### Agent
- [x] The run loop classifies by exit code into four outcomes — `0` passed,
      `2` **abstained**, `124` **did not finish**, any other non-zero
      **regressed** — and reports each under its own heading
- [x] No timeout or abstention is ever described as "an instrument that passed
      on 2026-08-15 no longer does" or as "a real regression in the thing it
      guards"
- [x] Exit codes discriminate: `0` all ran and passed, `1` at least one genuine
      regression (or a stale exclusion, unchanged), `3` **incomplete** — no
      regression, but at least one instrument abstained or did not finish
- [x] `tests/run-bridge-tests.sh`'s FAIL text for this leg no longer asserts
      regression for every non-zero, and distinguishes rc 1 / 2 / 3
- [x] **Headroom warning:** every instrument's elapsed time is measured, and any
      using ≥75% of the timeout budget is named with its measurement even on an
      otherwise green run — `_t525` sat at 95.6% and nothing said so until it
      first crossed
- [x] `tools/_t548-sweep-classification-teeth.py` drives the real sweep over
      synthetic probes that exit 0 / 2 / 124 / 1, and asserts both the wording
      and the exit code for each class
- [x] Teeth are mutation-verified and hermetic (synthetic probes live under
      `mktemp`, the repo tree is byte-identical after a run)
- [x] Wired into `tests/run-bridge-tests.sh`, and the suite's remaining red — if
      any — is the sweep reporting INCOMPLETE with accurate wording, not a
      regression claim

**AC amended mid-task, and the reason is the result.** This AC read "full suite
green". On the first suite run after wiring, `_t525` genuinely crossed the 90s
cap and the sweep reported:

```
RAN 35, passed 34, regressed 0, did-not-finish 1, abstained 0
SWEEP INCOMPLETE — no regression found, but the sweep did not cover everything
it names. This is not a green and it is not a regression report:
  - DID NOT FINISH: _t525-fabric-coverage-teeth.py (did not finish within 90s)
      Nothing is claimed about what it guards — it was killed, not failed.
```

That is the repair working on the real failure it was built for, on its first
exposure, rather than on a synthetic one. Keeping "full suite green" as the AC
would have left exactly two ways to satisfy it — raise the cap or retry the leg
— which are the two repairs T-543 ruled out and which this task exists to avoid.
An acceptance criterion that can only be met by doing the wrong thing is the
criterion that is wrong. `_t525`'s cost is filed separately.

**Deliberately out of scope**, carried forward from T-543's AC4: no timeout is
raised, no retry is added, no leg is quarantined. `_t525`'s 86s cost is a real
condition that tracks the growing watched tree; making it invisible by waiting
longer is how an instrument stops reporting.

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

python3 tools/_t548-sweep-classification-teeth.py
bash -n tools/_t509-instrument-sweep.sh
bash -n tests/run-bridge-tests.sh
# The capture invariant, because this task edits a bridge-suite leg and _t527
# caught my first draft of that edit. Cheap, and it is the guard I tripped.
bash tools/_t527-capture-invariant.sh
# NOT listed: the full bridge suite. It is 8 minutes, and its verdict currently
# depends on whether _t525 crosses its 90s cap on that particular run — which is
# T-549's subject, not this task's. Gating this task's completion on that would
# make the gate a coin-flip and would pressure the next person to raise the cap
# to get through it.

## Measured

Mutation results — four mutants, each caught by the leg that owns it:

| Mutant | Behaviour | Result |
|---|---|---|
| 124 counted as a regression | the pre-fix state | `did-not-finish` leg red: exit 1, expected 3 |
| 2 counted as a regression | abstention mislabelled | `abstained` leg red: exit 1, expected 3 |
| incomplete softened to a pass | `exit 0` instead of 3 | `did-not-finish` leg red: exit 0, expected 3 |
| headroom warning removed | `if false` | `headroom` leg red, twice |

**Leg 5 was red on its first run against my own fix.** A regression and a
timeout in the same run reported only the regression, because I exited inside
the regression branch before the uncovered section printed. The louder finding
swallowed the instrument nobody heard from — a quieter version of the same
defect this task exists to fix. The uncovered section now prints first.

**`_t527` caught my first draft of the bridge-suite edit.** I wrapped the
headroom surfacing in `if grep -q ... "$TMP/leg-*"`, which is the shape `_t527`
guards because it is how a leg discards the evidence for its own verdict. My use
surfaced output rather than swallowing it, so the finding was a false positive on
intent — and the guard was still right about the pattern. Restructured to a bare
`sed`, which prints nothing when it matches nothing and never needed the
conditional. Weakening the guard to fit my code was available and would have been
a bad trade.

**The headroom warning was invisible where it mattered, and I only found that by
reading the suite's own output.** The leg redirects the sweep's stdout to a file
shown only on failure, so on precisely the green runs where a leading indicator
is the entire point, nobody saw it. `_t525` was sitting at 81s of 90s and the
suite printed a bare pass.

## RCA

**Symptom.** A green instrument sweep intermittently reported
`SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:
_t525-fabric-coverage-teeth.py (rc=124)`, and added "a red here is a real
regression in the thing it guards." Nothing had regressed in fabric coverage.

**Root cause.** The run loop's verdict was `if timeout … ; then pass else fail`.
A boolean over a value that carries four meanings. `124` (killed) and `2`
(declined to certify) are not failures of the thing measured — they are the
absence of a measurement — and both were reported as findings about a subject
the sweep had never reached.

**Why structurally allowed.** The distinction was *already known and already
written down* — in the exclusion list, keyed on a filename:

> `_t364-byteid-precondition-teeth.py | exits 2 BY DESIGN, refusing to
> certify… Its abstention IS its output; converting that to a suite failure
> would punish the honesty.`

That is a correct argument about a **property**, recorded as an exemption for an
**instance**. Every other probe that abstained kept being called a regression,
and the reasoning that would have prevented it was sitting in the same file. The
knowledge was not missing; it was in a form that could not generalise.

This is T-509's shape — an exemption granted to the case that prompted it and
never extended to the class — occurring **inside T-509's own tool**, which is
also the fifth encounter with that shape in a week. The recurrence is the
finding: the pattern is not "someone forgot", it is that naming an instance is
the cheapest way to discharge a general observation, and it always leaves the
class uncovered while looking like it has been handled.

**Prevention.** Three parts, only the first of which is the fix:

1. The classifier, not the exclusion list, now decides. Adding two more names
   would have been faster and would have left the sixth abstaining probe wrong.
2. `_t548`'s teeth pin **the words**, not only the exit codes. The defect was
   never in the arithmetic — the sweep counted correctly and described the count
   wrongly — so a probe asserting only `rc` would have stayed green through the
   entire period the tool was misreporting.
3. The headroom warning makes the *next* instance visible before it fails.
   `_t525` sat at ~95% of its budget for an unknown period and the first thing
   anyone heard was a false regression report.

**Not claimed.** This does not make `_t525` finish. The sweep will keep reporting
INCOMPLETE whenever it crosses, and that is the correct behaviour, not a
workaround — an instrument nobody heard from is not a green. `_t525`'s cost is
T-549.

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

### 2026-08-16T17:23:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-548-t509-sweep-reports-a-probe-that-did-not-.md
- **Context:** Initial task creation
