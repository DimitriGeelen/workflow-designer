---
id: T-475
name: "The false re-pin cost has document-layer carriers including the arc's parent
  GO decision"
description: >
  T-473 fixed the false coordinated-re-pin premise in T-423 and T-474 fixed its five
  code-layer carriers. A census of .tasks/active and docs/ finds nine more, of which
  T-423/T-340/T-469/T-471 are already annotated and the rest are not: T-357 (the arc's
  PARENT GO decision), T-309, and the T-357/T-173/T-309 reports. Having just written
  a task about the fix-one-of-N failure mode, stopping at the code layer would be
  that error. Annotate the unannotated carriers with the rail-584 measurement, preserving
  the original wording as evidence. Does not re-open any GO decision and does not
  touch corpus bytes.

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
created: 2026-08-12T21:02:04Z
last_update: '2026-08-16T14:33:40Z'
date_finished: 2026-08-12T21:05:01Z
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
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:40Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md,docs/reports/T-173-aef-integration-inception.md,docs/reports/T-309-validator-surfacing.md,docs/reports/T-357-di-adoption.md);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-475: The false re-pin cost has document-layer carriers including the arc's parent GO decision

## Context

T-473 fixed the false "coordinated re-pin" premise in T-423; T-474 found it had five
code-layer carriers and fixed the four T-473 had missed. Both tasks are about incomplete
propagation, so stopping at the code layer would have been the error they document.

**Census of `.tasks/active/` + `docs/`: nine files matched, two are live carriers.**

| file | verdict |
|---|---|
| **`T-357.md:71, :187`** | **false — and it is the arc's PARENT GO decision.** Corrected. |
| **`docs/reports/T-357-di-adoption.md:83, :235`** | **false — the arc's design report.** Corrected. |
| `T-423`, `T-340`, `T-469`, `T-471` | already annotated — they match only because their own corrections quote the false claim |
| `T-309:119`, `docs/reports/T-309-validator-surfacing.md:325` | **TRUE, untouched** — that is the released **dist HTML** artifact AEF pins, an entirely different pin |
| `docs/reports/T-173-aef-integration-inception.md:40` | **TRUE, untouched** — a *rejected* submodule hosting model, about pinning a git commit |

The last two rows are the same discipline T-474 applied to `source_bpmn_sha` in the
promote-contract tests: a phrase that is false in one context is exactly right in another,
and only reading each occurrence separates them. Seven of nine "hits" needed no edit.

### The census missed three, and the verification leg found them

**This census was itself a first-form measurement.** It used `grep -n … | head -3`, saw the
two occurrences it expected in T-357, and stopped. Three more sat at lines 289, 413 and 468
— the GO rationale reproduced verbatim in three record blocks, each carrying *"all 24 corpus
maps change bytes so AEF's pinned `source_bpmn_sha` fixtures need coordinated re-pinning"*
among its "Real costs to scope".

They surfaced because leg 1 asserted **no unannotated occurrence** and went red. The task
whose subject is incomplete propagation was itself incompletely propagated, and the only
reason it did not ship that way is that the leg checked the claim instead of the intent.
Fifth instance this session of a first-form measurement that read like a result.

**They are left unedited on purpose.** A decision record rewritten to match later knowledge
destroys the evidence of how the decision was reached — and this session has repeatedly
needed the wrong version to trace how a belief spread. A `DECISION-RECORD CORRECTION` block
sits adjacent instead, and the leg now pins the count at **3** so a fourth copy cannot
appear unnoticed.

**The GO is unaffected:** it rests on portability (fourth constitutional directive) and the
symmetric-injury measurement, with the re-pin listed as a cost *to scope* rather than a
reason against. A cost that shrank cannot weaken a GO.

### Why T-357 mattered more than the others

The other carriers are reading hazards inside finished documents. T-357 is the **GO the
whole arc descends from**, and its seam bullet called the 24-map byte change *"a two-party
event, not an operator's call alone"* — a claim about **who is entitled to decide**, not
just about cost. Left standing, it says the operator cannot settle this alone. Measured,
they can: AEF pins none of the 24 and holds no copy of the corpus.

**No GO was re-opened and no recommendation altered.** The correction is explicit that it
fixes an *input*, not a conclusion — the three-step ordering stands, and T-357's
parenthetical that T-340's scoped (b) is byte-neutral was correct then and now.

One passage got *stronger* under correction rather than weaker: assumption A-3 ("no consumer
outside this repo reads `aef:position`") offered AEF's pin as its supporting reason. The
reason was wrong and the assumption holds more firmly without it — there is no such pin, so
there is not even a hypothetical outside reader.

### Original wording preserved throughout

Every correction strikes the claim rather than deleting it. A retraction that removes the
text leaves a later reader unable to distinguish a corrected document from one that never
erred — and in this session the *wrong* version has repeatedly been the evidence for how a
belief propagated (T-473 traced a three-week-old false cost to a diagnostic string only
because the wording survived).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The census is complete before any edit, and separates already-annotated carriers
      from live ones.** T-423/T-340/T-469/T-471 match the search only because their
      corrections quote the false claim — counting those as findings would inflate the work
      and understate the remainder.
- [x] **Each live carrier is classified by what it would change if believed**, not merely
      listed. A false cost inside a completed report is a reading hazard; a false cost
      inside the arc's parent GO decision is an input to a decision that is still being
      executed. They do not deserve the same treatment.
- [x] **The original wording is preserved wherever it is corrected.** A retraction that
      deletes the claim leaves a reader unable to tell a corrected document from one that
      never erred — and the wrong version is the evidence for how it propagated.
- [x] **No GO decision is re-opened and no recommendation is altered.** T-357's GO and
      T-340's pending ruling stand; this records that one input was mismeasured and states
      whether the conclusion depended on it.
- [x] **Verification legs are quote-aware from the outset.** Every correction here quotes
      the phrase it retracts, so a naive absence leg would go red on its own fix — the
      fourth-instance lesson from T-473, applied before writing rather than after.
- [x] **No corpus byte is written.** Tree hash pinned in Verification.

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

# Quote-aware FROM THE OUTSET (the T-473 lesson applied before writing, not after): every
# correction here quotes the phrase it retracts, so `! grep -q '<phrase>'` would go red on
# its own fix. Predicate is "no occurrence outside a corrected/struck line", with a
# positive control so deleting the passage cannot green it.

# Pinned at 3, not 0: the three surviving occurrences are the GO rationale reproduced
# verbatim in three record blocks, left UNEDITED on purpose (a decision record rewritten to
# match later knowledge destroys the evidence of how the decision was reached). They are
# covered by an adjacent DECISION-RECORD CORRECTION instead. The count is pinned so a
# FOURTH copy cannot appear unnoticed, and the marker leg below is what makes 3 acceptable
# rather than merely tolerated.
test "$(awk '/AEF.s pinned/ && !/CORRECTED|T-475|~~/' .tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md | wc -l)" = "3"
/usr/bin/grep -q 'DECISION-RECORD CORRECTION (T-475)' .tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md
test "$(awk '/coordinated re-pin with AEF/ && !/CORRECTED|T-475|~~/' docs/reports/T-357-di-adoption.md | wc -l)" = "0"
test "$(awk '/AEF pins by sha/ && !/T-475|~~/' docs/reports/T-357-di-adoption.md | wc -l)" = "0"
/usr/bin/grep -q 'CORRECTED 2026-08-12 (T-475)' .tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md
/usr/bin/grep -q 'T-475' docs/reports/T-357-di-adoption.md
/usr/bin/grep -q 'What does NOT change' .tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md
/usr/bin/grep -q 'artifact AEF pins and opens from' docs/reports/T-309-validator-surfacing.md
python3 -c "import yaml,sys; yaml.safe_load(open('.tasks/active/T-357-adopt-bpmn-di-as-the-designer-geometry-a.md').read().split('---')[1])"
git diff --quiet HEAD -- examples/aef-processes/rendered tests/fixtures/aef-bpmn

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

### 2026-08-12T21:02:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-475-the-false-re-pin-cost-has-document-layer.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-aafac92e
- **Timestamp:** 2026-08-12T21:05:02Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T21:05:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
