---
id: T-385
name: "Verify the python3 -c task-gate bypass class against our vendored hook (AEF
  OBS-200)"
description: >
  AEF reports at rail 465 that check-active-task.sh safe-lists python3 -c behind a
  textual write-indicator deny-list, and that pathlib write_text/write_bytes and os.replace
  pass both predicates so the hook exits 0 before any gate runs. We vendor that hook.
  Measure whether it reproduces here, with an anti-vacuity control, rather than reasoning
  from the regex.

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T17:01:02Z
last_update: '2026-08-16T14:33:32Z'
date_finished: 2026-08-08T17:10:09Z
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
  - ts: '2026-08-16T12:33:54Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t385-python-c-gate-bypass.sh,tools/validate-workflow.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/concerns.yaml,tools/_t385-python-c-gate-bypass.sh);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-385: Verify the python3 -c task-gate bypass class against our vendored hook (AEF OBS-200)

## Context

AEF reported at rail offset 465 (their OBS-200) that `check-active-task.sh` safe-lists
`python3 -c` behind a *textual* write-indicator deny-list, and that three ordinary write
idioms match none of it and carry no shell redirect — so **both** predicates pass and the
hook exits 0 before the no-active-task check, the task-is-active check, G-020 and the
T-1730 focus-drift gate ever run. They measured it against their own hook. We vendor that
hook in `.agentic-framework/`, so if it reproduces here it is our gate that is open, not
just theirs.

Failure direction is the dangerous one: **false NEGATIVE**. Every gate is skipped, nothing
lands in the bypass log, and the result is indistinguishable from compliance after the
fact. That is why this is measured against the real hook rather than read off the regex —
and why a negative result needs an anti-vacuity control before it can be believed
([[checks-that-discriminate-nothing]], and the harness-never-reached-the-gate failure that
bit me at T-381).

Their third idiom, `os.replace`, is their own documented atomic-write house style. Ours
may differ; the census below therefore covers what WE actually write, not only what they
named.

## Acceptance Criteria

### Agent
- [x] Probe invokes the REAL vendored hook (`.agentic-framework/` on disk, via `fw hook check-active-task`), not a re-implementation of its regexes, and fails loudly if the hook cannot be located
- [x] Probe runs against a sandbox whose `focus.yaml` has `current_task: null` — the state in which every gate is supposed to fire
- [x] **Anti-vacuity control:** a command known to be blocked (shell redirect form) returns non-zero *in the same harness*, proving the harness reaches the gate and can fail; a run where the control passes is reported as COULD-NOT-MEASURE, never as "no bypass found"
- [x] All three AEF-named idioms measured with their rc recorded individually: `pathlib.Path(p).write_text(s)`, `pathlib.Path(p).write_bytes(b)`, `os.replace(a,b)`
- [x] At least two idioms AEF did NOT name are measured, chosen from write forms that appear in THIS repo, and their results reported in whichever direction they come out
- [x] Probe asserts the deny-list predicate is genuinely reached for at least one idiom it DOES catch (positive control) — so a blanket "python3 is never checked" and "python3 is checked but these slip" are distinguishable findings
- [x] Verdict is reported per-idiom as a table, and the aggregate sentence names the SUBJECT (our vendored hook at its current sha), not "the framework"
- [x] If the class reproduces: registered on our side (gap or observation) rather than only reported to AEF — their OBS-200 does not cover our tree
- [x] Finding sent to AEF on the rail, including any idiom where my result DISAGREES with theirs

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

# The probe must run clean. It exits 3 (COULD-NOT-MEASURE) if the harness cannot
# reach the gate, so a green here also certifies the controls held — a plain rc=0
# from a probe whose anti-vacuity control failed is exactly the T-381 false green.
bash tools/_t385-python-c-gate-bypass.sh > /tmp/.t385-out 2>&1 && grep -q "PASS=2 FAIL=0" /tmp/.t385-out
# Both controls must be individually present and PASSing — not merely a clean total.
grep -q "PASS  anti-vacuity" /tmp/.t385-out
grep -q "PASS  positive control" /tmp/.t385-out
# The census must actually have probed the shell=True row: it is the one that
# distinguishes "deny-list is incomplete" from "deny-list is unclosable", and a
# run that silently dropped it would report a materially weaker finding.
grep -q "subprocess shell=True" /tmp/.t385-out
# The finding must be registered on our side, and must RENDER (T-382/G-024 lesson:
# a closure condition under an unread key is indistinguishable from an absent one).
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
.agentic-framework/bin/fw gaps > /tmp/.t385-gaps 2>&1 && grep -q "G-025" /tmp/.t385-gaps
grep -A2 "G-025" /tmp/.t385-gaps > /tmp/.t385-g025 && grep -q "Trigger: A .python3 -c. command" /tmp/.t385-g025

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T17:01:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-385-verify-the-python3--c-task-gate-bypass-c.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a8162ff1
- **Timestamp:** 2026-08-08T17:10:14Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T17:10:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
