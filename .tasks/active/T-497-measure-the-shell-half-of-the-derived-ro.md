---
id: T-497
name: "measure the shell half of the derived-root harness population (T-496 stated hole)"
description: >
  measure the shell half of the derived-root harness population (T-496 stated hole)

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
created: 2026-08-14T08:19:19Z
last_update: 2026-08-14T08:19:19Z
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

# T-497: measure the shell half of the derived-root harness population (T-496 stated hole)

## Context

T-496 measured the python half of the derived-root harness class — 70 harnesses derive a
root from their own location and resolve a subject beneath it, 42 verify the subject
exists, 28 do not — and said in the same breath that **the shell half is UNMEASURED**.
That sentence was deliberate (stating a hole rather than implying zero, per AEF rail 617
§2's exclusion-vs-hole distinction). This task converts the stated hole into a number.

Scope is MEASUREMENT, not a population-wide guard. T-496 rejected the guard on the
grounds that deciding per file whether a resolved path is a SUBJECT or an optional
output is intent, and guessing at intent produces the confident-but-unfounded verdict
T-440 was about. That reasoning is unchanged and this task does not revisit it.

Shell is not merely "the other half" — it has a distinct hazard python does not:
an empty `ROOT` composes silently (`"$ROOT/tools/x.py"` → `/tools/x.py`) and the
resulting failure exit code (127 from the shell, or the interpreter's own code) is
drawn from the SAME small set a real verdict uses. The abstention/verdict collision
T-496 fixed with exit 2 is therefore sharper here, not softer.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The shell population is enumerated by a tool whose DEFINITION of "derives a root
      and resolves a subject beneath it" is stated in its own source, in terms a reader
      can check against a file by hand
      → `tools/_t497-derived-root-census.py` docstring, "WHAT IS BEING COUNTED"
- [x] The denominator is DERIVED (from a glob over the tree) and never typed — no
      hand-entered population count appears in the tool or in the reported result
      → `population()` globs; 162 scanned, printed with the counts
- [x] Every member is classified verifies / does-not-verify, and the rule for "verifies"
      is stated explicitly rather than implied by the code
      → TWO rules stated, STRICT and LOOSE, because they are wrong in opposite
        directions and one number would have picked a side by accident
- [x] The tool names its own LIMIT — the shell shapes it cannot see — in its source,
      so the number is not read as full coverage
      → LIMIT section, incl. the dot-name blind spot proven by the controls
- [x] Negative controls: a planted shell harness that derives-and-does-not-verify is
      flagged, and one that derives-and-verifies is not. Both controls run in place
      (not from a scratchpad — T-496's own finding) and are removed afterwards
      → `tools/_t497-census-controls.sh`, 3/3, A and C flip while B holds
- [x] The measured shell number is recorded where the next reader meets the class, so
      "70 python / shell unmeasured" becomes a stated pair rather than a half-answer
      → learning captured under T-497; census is the reproducible instrument T-496 did
        not leave behind
- [x] Bridge suite still green (no regression in pass count)
      → 75 passed, 0 failed (was 74; the new control is the +1)

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

# The census runs and refuses correctly (exit 0 in place; the refusal path is exit 2).
python3 tools/_t497-derived-root-census.py > /dev/null
# The census emits parseable JSON with a derived denominator.
python3 -c "import json,subprocess,sys; d=json.loads(subprocess.run(['python3','tools/_t497-derived-root-census.py','--json'],capture_output=True,text=True).stdout); sys.exit(0 if d['scanned']>0 and d['shell']['members']>0 else 1)"
# The controls discriminate — 3/3, run in place, fixtures removed on exit.
bash tools/_t497-census-controls.sh > /dev/null
# The control leg is wired into the suite, not left here (T-495/PL-161).
grep -q "_t497-census-controls.sh" tests/run-bridge-tests.sh
# Bridge suite green.
bash tests/run-bridge-tests.sh > /tmp/.t497-suite.out 2>&1 && grep -q "0 failed" /tmp/.t497-suite.out

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** T-496 reported "70 python harnesses, 28 do not verify; the shell half is
UNMEASURED". The shell number did not exist, and the python number had no instrument —
it was produced by hand and could not be re-derived the next day.

**Root cause (of the measurement gap):** nothing in the tree enumerated the class. But
the deeper finding is that the CLASS itself was not new: `tools/_t429-zero-leg-probe.sh`
stated it, diagnosed it and prescribed the remedy on 2026-08-11, in its file header —
three days before T-494 hit it, and four rediscoveries before T-496 named it as a class.

**Why structurally allowed:** the knowledge was stored as prose in a comment block. That
is precisely the location T-495 established is invisible to every instrument here — the
census strips prose before counting, nothing greps headers for lessons, and a comment
cannot go dark in a way anything reports. `_t429` also had no reason to file a learning:
it was solving a different problem and mentioned this one in passing, correctly, as a
justification for where it put a temp file. A lesson recorded only as the rationale for
a local decision is invisible outside that decision.

**Prevention:** the class now has (a) a reproducible instrument with a derived
denominator, (b) three controls wired into the bridge suite that fail if the census
stops discriminating, and (c) three learnings in the register rather than in a header.
NOT prevented: the general case of a lesson living only in a comment. That is a real
remaining hole and is stated rather than claimed closed — see Decisions.

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

### 2026-08-14 — report an interval, not a number

- **Chose:** print STRICT and LOOSE unverified counts and the gap between them.
- **Why:** the first classifier credited any `[ -f ]` in the file (mention-vs-instance,
  T-429 defects 1-2). Fixing it to match the operand introduced the opposite error —
  argparse-default indirection reads as unguarded. Hand-reading found real members on
  BOTH sides. One number would have been a side picked by accident, with no mark on the
  artifact saying which.
- **Rejected:** picking STRICT and calling the rest a limit. That is the shape T-495
  showed is worst — a false positive standing in for a false negative, with the total
  looking plausible.

### 2026-08-14 — measure both halves, not just the shell one

- **Chose:** one census covering python and shell, superseding T-496's hand count.
- **Why:** T-496's 70/42/28 left no instrument. A shell-only tool would have created two
  readers of one population — AEF's line-5245 shape, where the second reader rots and
  nobody re-reads it because re-reading finds what is there.
- **Rejected:** a shell-only census. Cheaper, and it builds the known failure.

### 2026-08-14 — do not close the "lesson lives only in a comment" hole

- **Chose:** state it as open in the RCA rather than claim prevention.
- **Why:** `_t429` recorded this class correctly and nothing surfaced it for three days
  across four rediscoveries. The fix for THIS class is done; the fix for "knowledge
  parked in a header" is not, and mitigation is not prevention (G-019). Building a
  header-mining tool now would be a fourth census over `tools/*` on a guess about what
  counts as a lesson — T-491's reintroduction shape, and intent-guessing (T-440).
- **Rejected:** a "lessons in comments" scanner. Filed as the honest open item instead.

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

### 2026-08-14T08:19:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-497-measure-the-shell-half-of-the-derived-ro.md
- **Context:** Initial task creation
