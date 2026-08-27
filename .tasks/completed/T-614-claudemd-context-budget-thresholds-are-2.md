---
id: T-614
name: "CLAUDE.md context-budget thresholds are 200K-calibrated while budget-gate.sh runs on 300K: the doc told me to stop working at 51 percent"
description: >
  CLAUDE.md context-budget thresholds are 200K-calibrated while budget-gate.sh runs on 300K: the doc told me to stop working at 51 percent

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
created: 2026-08-27T08:38:52Z
last_update: 2026-08-27T08:42:16Z
date_finished: 2026-08-27T08:42:16Z
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

# T-614: CLAUDE.md context-budget thresholds are 200K-calibrated while budget-gate.sh runs on 300K: the doc told me to stop working at 51 percent

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

The operator asked why a budget warning fired when the limit is 300K. It should not have,
and the fault is mine before it is the doc's.

**Measured:** `budget-gate.sh:100-105` reads `CONTEXT_WINDOW` (default **300000**) and derives
`TOKEN_URGENT` at 85% (255K) and `TOKEN_CRITICAL` at 95% (285K). At 154,476 tokens the gate
computed **51%** and wrote `"level": "ok"` — correctly.

CLAUDE.md's §Context Budget Management still carries a hard-coded 200K-calibrated ladder:
120K / 150K / 170K, with percentages ("60%", "75%", "85%") that only line up against a 200K
window. So the doc and the gate disagree by a factor of ~1.7.

**What I actually did with that, which is the part worth recording.** I read
`.budget-status`, saw `{"level": "ok", "tokens": 154476}`, and said out loud that the level
and the token count "disagree at the 150K threshold". I then resolved that contradiction **in
favour of the prose** — declared the session urgent, refused to start T-200, and generated a
handover at 51% of budget. The cached level was the gate's own verdict and I overrode it with
a number I had read in a document.

This is the same defect I spent the session naming in other people's systems: *verify against
the thing that acts, not the thing that describes it.* The gate acts. CLAUDE.md describes.
PL-142 states it exactly — a rule and the fact it rests on are different artifacts with
different lifetimes — and `fw work-on` surfaced PL-142 unprompted when this task was created.

**Cost:** one session stopped at roughly half budget, and T-200 deferred for no reason.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every stale absolute threshold in CLAUDE.md's context-budget sections is replaced with
      the **percentage** the gate actually computes, plus the derived value at the default
      window shown as illustrative rather than normative. No absolute token number may appear
      as the rule, because an absolute number is what went stale.
      <br>**Evidence:** three sites corrected — `### Work Proposal Rule` (the 60/75/85 ladder),
      `### Automated Monitoring` (the "120K/150K/170K" escalation line), and the
      "Structural enforcement (T-139)" paragraph under `### Commit Cadence and Check-In`
      (">=150K tokens, ~75%"). The ladder now reads 75 / 85 / 95 percent, with "225K / 255K /
      285K at the 300K default. Illustrative, not normative."
      <br>Two rules added that the old text lacked: **the percentages are the rule, the
      absolutes are not**, and **read `level` from `.budget-status`, do not recompute it — if
      `level` and your arithmetic disagree, `level` wins.** The second is the one that would
      have prevented the incident: I had the correct verdict in hand and overrode it.
- [x] The numbers written into CLAUDE.md are **read out of `budget-gate.sh`**, not copied from
      this task description. Deriving them a second time by hand is how the two drifted apart
      in the first place.
      <br>**Evidence:** `budget-gate.sh:100-106` read directly —
      `CONTEXT_WINDOW=$(fw_config_int "CONTEXT_WINDOW" 300000)`, `TOKEN_WARN` 75%,
      `TOKEN_URGENT` 85%, `TOKEN_CRITICAL` 95%. `checkpoint.sh:31-36` carries the identical
      derivation, so the two enforcement paths agree with each other and only the doc was out.
      `fw config get CONTEXT_WINDOW` returns empty — no override, the 300000 default is live.
- [x] A guard exists that fails when CLAUDE.md names a token threshold the gate does not
      compute, so the next drift is caught mechanically rather than by an operator noticing a
      spurious warning. Proven failable, not merely green.
      <br>**Evidence:** `tools/_t614-budget-threshold-drift.py`. It parses the percentages and
      default window **out of the script** and compares against the doc, so it cannot drift
      from the gate the way the doc did — there is no second hand-maintained copy of the
      numbers anywhere in it.
      <br>**Arm 1** — reinstating the literal old line `- Below 60% (120K tokens)` reddens it
      on *both* axes: `names 120K … gate derives [225000, 255000, 285000]` and `names 60% …
      gate computes only [75, 85, 95]`. Exit 1. File restored, guard green again.
      <br>**Arm 2** — the third site armed independently: restoring `(>=150K tokens, ~75%)`
      reddens with `names 150K`. Exit 1, restored, green again. Armed separately because a
      guard proven only on the site you happened to look at is the partial-coverage shape.
- [x] The guard is pointed at the **rule text**, not the whole file — a threshold quoted
      inside a worked example or an RCA narrative is a MENTION, not a rule, and a file-wide
      scan would flag this very task's own description.
      <br>**Evidence:** the scan is scoped to three named headings (2,904 bytes of rule text).
      This task file, the guard's own docstring and the commit message all name 120K/150K/170K
      freely and none is flagged. The third heading was added *after* the first green run:
      guarding only the two sections where the ladder obviously lived would have left the
      site that was also wrong unguarded.
      <br>**Vacuity guards:** if `budget-gate.sh`'s shape changes so the percentages cannot be
      parsed, or if a heading is renamed so the rule text comes back empty, the guard exits
      **2 (cannot measure)** rather than passing on having found nothing to compare.

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

# --- T-614 --- own exit code is the verdict (T-352), no chaining.
python3 tools/_t614-budget-threshold-drift.py
# The gate and the fallback must not drift from EACH OTHER either — the doc was out, but
# two enforcement paths silently disagreeing would be worse and nothing was checking it.
python3 -c "import re,sys,pathlib; g=lambda p: sorted(re.findall(r'TOKEN_(\w+)=\\\$\(\(CONTEXT_WINDOW \* (\d+) / 100\)\)', pathlib.Path(p).read_text())); a=g('.agentic-framework/agents/context/budget-gate.sh'); b=g('.agentic-framework/agents/context/checkpoint.sh'); sys.exit(0 if a and a==b else 1)"

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

**Symptom:** the agent declared the context budget urgent at 154,476 tokens, refused to start
T-200, and generated a handover — at **51%** of a 300,000-token window. The operator asked why
a warning fired when the limit is 300K. No warning had fired. The agent produced it.

**Root cause:** CLAUDE.md's budget ladder was a hard-coded 200K-era calibration
(120K/150K/170K, "60%/75%/85%") while `budget-gate.sh` and `checkpoint.sh` both derive
75%/85%/95% from a configurable `CONTEXT_WINDOW` that defaults to 300000. The doc and the two
enforcement paths disagreed by a factor of ~1.7.

**Why structurally allowed:** two reasons, and the second is the real one.

1. Nothing compared the prose against the script. The thresholds existed in two places with
   different lifetimes — PL-142, which `fw work-on` surfaced unprompted when this task was
   created — and only one of them was executable.
2. **The agent had the correct answer and discarded it.** `.budget-status` carried
   `{"level": "ok", "tokens": 154476}` — the gate's own verdict, computed by the code that
   enforces. The agent read it, stated aloud that `level` and the token count "disagree at
   the 150K threshold", and resolved the contradiction in favour of the document. A stale doc
   is a maintenance defect; overriding a live verdict with a remembered number is the
   session's own recurring failure — *verify against the thing that acts, not the thing that
   describes it* — applied to itself and got wrong. It was named three times this session in
   other systems (rail 604, 607, T-611) while being committed here.

**Prevention:** distinct from the fix, which was editing three lines of prose.

- `tools/_t614-budget-threshold-drift.py` parses the percentages **out of `budget-gate.sh`**
  and fails when CLAUDE.md's rule text names a threshold the gate does not compute. It holds
  no second copy of the numbers, so it cannot drift the way the doc did. Both arms proven.
- A parity check in `## Verification` asserts `budget-gate.sh` and `checkpoint.sh` still
  derive identical percentages. They agree today and nothing was checking that they would.
- CLAUDE.md now states the operative rule that was missing: **read `level`, do not recompute
  it; if `level` and your arithmetic disagree, `level` wins.** The guard catches stale
  numbers; that sentence catches the reasoning error that made the stale numbers costly.

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

### 2026-08-27T08:38:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-614-claudemd-context-budget-thresholds-are-2.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fc49cc1f
- **Timestamp:** 2026-08-27T08:42:17Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-27T08:42:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
