---
id: T-470
name: "T-209 offers the operator two different recommendations"
description: >
  T-209's operator-facing brief contradicts itself: the ## Recommendation section
  (read by the review queue via _norec-verify.py's ^## Recommendation anchor) says
  GO on option A; the ### Human AC the operator must actually tick says 'Recommendation:
  C'. A and C differ substantively — C is A plus filing the typed-event byte-exact
  cross-validation gap. Measure whether C's extra step is still open before the operator
  rules, and make the two sections name the same option. Does NOT make the ruling:
  the decline-vs-build choice stays the operator's.

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
created: 2026-08-12T20:19:19Z
last_update: '2026-08-16T14:33:39Z'
date_finished: 2026-08-12T20:23:25Z
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
  - ts: '2026-08-16T12:34:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:39Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 
      (no-signal); F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.tasks/active/T-209-832-side-compile-promote-create-producer.md,.tasks/completed/T-212-pin-shared-aef-bpmn-fixture-shas-t-559-8.md,tests/run-bridge-tests.sh,tests/test_typed_event_fixture_contract.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-470: T-209 offers the operator two different recommendations

## Context

T-466 recorded T-209 as "the one ruling of the five with no brief" and deferred writing
one. Opening it to write that brief showed it already had two — disagreeing.

| where | says | read by |
|---|---|---|
| `T-209.md:210` `## Recommendation` | **GO on option A** | the review queue (`_norec-verify.py` anchors `^## Recommendation`) |
| `T-209.md:188` `### Human` AC | **Recommendation: C** | the operator, at the box they tick |

A and C differ by exactly one action: C additionally files the typed-event byte-exact
cross-validation gap. **Measured: that action was taken on 2026-07-19 as T-212**
(`work-completed`, `39f69bcb`), five hours after the paragraph recommending it was written.
`python3 tests/test_typed_event_fixture_contract.py` → rc 0, wired into
`tests/run-bridge-tests.sh:203`. C prescribes no remaining work; it collapses into A.

So the operator was being offered a fork whose second branch had been spent for 24 days,
and the queue and the checkbox pointed at different branches of it.

**What the 2026-08-10 re-measurement missed, and why that is the interesting part.** That
pass was titled "the premise, not the conclusion" and it did re-run both suites. But it
re-measured the *finding's* evidence — "already covered by T-206+T-208" — which had not
moved. The thing that had moved was the *recommendation's* premise. A re-measurement is
scoped to whatever its author suspects, and suspicion here pointed at the durable claim
and away from the action item that had quietly been executed. **Re-measuring the part you
doubt is not the same as re-measuring the part that can expire.**

Neither section was right by derivation. `## Recommendation` says A — the correct letter —
while its own "Known limit" paragraph still described C's action as pending work. It
arrived at A without noticing C was spent.

### The tick script broke on the string this task is named after

Ticking the Agent ACs corrupted this file: the script sliced between `s.index("### Agent")`
and `s.index("### Human")`, and **this task's own frontmatter `description:` contains the
literal `### Human`** — because the bug being described *is* a `### Human` AC. The anchor
matched inside the frontmatter, before `### Agent`, so `s[:a]+blk+s[h:]` duplicated 36
lines including a second `---` block. Repaired by line number; frontmatter re-parsed as a
post-condition rather than assumed.

That is the fourth instance this session of **producer and consumer composed in the same
file** (T-468's leg matching its own comment; the stale-phrase leg here, caught *before*
being written; now this). The shape is stable enough to name: a search anchor that
describes a defect will be found in the artifact that documents the defect. The remedy is
the one already in use for P-011 legs — anchor on structure (the heading, after the
frontmatter) rather than on a bare string that prose is free to contain.

**Scope boundary:** this task does not rule. Options A, B and C all remain in the file, the
`[REVIEW]` box is untouched, and the AEF-side half of the cross-validation is explicitly
not claimed closed — T-212 pins the bytes we hold, which is producer-side self-consistency
(PL-033/PL-034), not confirmation from across the seam.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The contradiction is established as fact, not impression.** Both recommendation
      strings are quoted with `file:line`, and the two sections are shown to name
      *different letters* for the same ruling. If they turn out to be reconcilable as
      written, this task withdraws rather than editing an operator brief to fix a
      disagreement that was mine to misread.
- [x] **Option C's premise is RE-MEASURED, not re-read (PL-142).** C prescribes an action —
      "file typed-event byte-exact cross-validation as its own task". Whether that task
      exists, its status, and whether its guard runs green *today* are facts that can
      dissolve silently while the recommendation restating them keeps reading as true.
      Answered with command output and dates, not by reading the brief again.
- [x] **The two sections are reconciled to name the same option, as a MEASUREMENT and not
      a ruling.** What changed, and when, is stated. The operator's choice set is
      preserved intact — B stays available, no option is deleted, and the ruling itself
      is untouched.
- [x] **The stale claim in `## Recommendation`'s "Known limit" is corrected.** It describes
      the typed-event surface as "still in motion on the rail... deliberately not folded
      in here". If that describes completed work, it is a dated correction in the file,
      not a silent deletion.
- [x] **The AEF-side half is explicitly NOT claimed closed (PL-033/PL-034).** A sha pin on
      our fixtures is producer-side self-consistency; whether AEF's cross-validation is
      green is not observable from here and is not asserted.
- [x] **No `### Human` AC is ticked and no ruling is made.** The decline-vs-build decision
      on a peer's proposal stays the operator's. This task removes a stale fork from the
      choice; it does not choose.

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

# GNU-spelled (/usr/bin/grep) throughout — G-037 axis 1: the gate shell is GNU grep 3.11,
# the agent tool shell is ugrep 7.5.0, and legs run in the former. All paths are scoped
# below .git/ (T-468): a repo-root recursive sweep would count this task's own commit
# message.
#
# Leg 2 is quote-aware BY MEASUREMENT, not by style. The obvious form
#   ! /usr/bin/grep -q 'still in motion on the rail' <T-209>
# goes RED — because the correction block QUOTES the stale phrase it removed. Producer and
# consumer composed in a file again (T-468 "the leg that found itself", AEF T-456). The
# assertion that is actually meant is "no occurrence OUTSIDE a quote block", and 2b is its
# positive control (PL-084): without it, deleting the paragraph turns leg 2 green.

test "$(/usr/bin/grep -c '^[^>]*still in motion on the rail' .tasks/active/T-209-832-side-compile-promote-create-producer.md)" = "0"
test "$(/usr/bin/grep -c 'still in motion on the rail' .tasks/active/T-209-832-side-compile-promote-create-producer.md)" = "1"
/usr/bin/grep -q '^ *\*\*Recommendation: A\*\*' .tasks/active/T-209-832-side-compile-promote-create-producer.md
test "$(/usr/bin/grep -c '^ *\*\*Recommendation: C\.\*\*' .tasks/active/T-209-832-side-compile-promote-create-producer.md)" = "0"
test "$(/usr/bin/grep -cE '^  - \*\*[ABC] —' .tasks/active/T-209-832-side-compile-promote-create-producer.md)" = "3"
/usr/bin/grep -q '^- \[ \] \[REVIEW\] Decline AEF' .tasks/active/T-209-832-side-compile-promote-create-producer.md
/usr/bin/grep -q 'not observable from' .tasks/active/T-209-832-side-compile-promote-create-producer.md
/usr/bin/grep -q 'Re-measuring the part you doubt' .tasks/active/T-209-832-side-compile-promote-create-producer.md
/usr/bin/grep -q '^status: work-completed' .tasks/completed/T-212-pin-shared-aef-bpmn-fixture-shas-t-559-8.md
python3 tests/test_typed_event_fixture_contract.py
/usr/bin/grep -q 'test_typed_event_fixture_contract' tests/run-bridge-tests.sh

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

### 2026-08-12T20:19:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-470-t-209-offers-the-operator-two-different-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2beb6739
- **Timestamp:** 2026-08-12T20:23:26Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T20:23:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
