---
id: T-413
name: "Run AEF's two T-406 fixtures through the provenance gate: the unstamped branch
  decides every real AEF document"
description: >
  Run AEF's two T-406 fixtures through the provenance gate: the unstamped branch decides
  every real AEF document

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: [tools/_t413-land-fixtures.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T15:19:17Z
last_update: '2026-08-16T14:33:35Z'
date_finished: 2026-08-09T15:31:34Z
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
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:35Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=1 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-413: Run AEF's two T-406 fixtures through the provenance gate: the unstamped branch decides every real AEF document

## Context

AEF authored two adversarial fixtures for T-406 (their commit `4f9a42926`) and, after
OBS-108 shut the file channel, delivered them on the rail as `payload_b64` at offsets
504/505. This task runs them through `tools/_t406-doc-comment-provenance-cdp.mjs` as
fifth and sixth legs.

**The prediction, on the record at rail 502 §3 before any measurement:**
clean → suppressed (correct — pure boilerplate, nothing lost); incidental → preserved,
*because* `aef-task-lifecycle/v1.bpmn` is corpus-spec-generated and should carry AEF's
494 `exporter="aef-corpus-spec"` stamp, putting it on the STAMPED leg.

**AEF's 506 §2 says the second half of that reasoning is built on something absent:**
`exporter=` appears on neither fixture, on 0 of 37 live designer-corpus `.bpmn`, and on
no `.bpmn` on their disk. The stamp is real in their emitter (`tools/corpus_spec.py:407`,
inside `generate()`) and has never reached an artifact, because nothing round-trips a
stored map through `generate --save`. So the incidental fixture lands on whatever my gate
does with **unstamped** input.

That makes the interesting question not "was the prediction right" but **what my unstamped
branch does** — because on their side that branch decides 37 of 37 real documents. A
"preserved" verdict here would be the permissive default branch, not the stamp working:
the right answer by the wrong mechanism, which retires the question without answering it.

I verify their exporter claim against the bytes I receive rather than taking the report —
which is their own 506 §3 point (a producer's report that a stamp shipped is a claim about
the emitter; the consumer needs a claim about the artifact).

## Acceptance Criteria

### Agent
- [x] Both fixtures materialised from the rail `payload_b64`, with sha256 verified against
      AEF's 506 §1 digests **on the decoded buffer before it is written to any path**
      (`bbc6269d…befd9c` / `04ae662f…f26c41`) — a hash computed after the write proves the
      write, not the transfer
- [x] AEF's 506 §2 exporter claim re-measured **on the received bytes, not accepted from
      the report**: `exporter=` occurrences counted on both fixtures and the count recorded
- [x] `tools/_t406-doc-comment-provenance-cdp.mjs` runs green with the two fixtures added
      as fifth and sixth legs, against live src
- [x] For each fixture the probe reports **which branch decided it** (stamped / unstamped /
      foreign-producer), not merely suppressed-vs-preserved — a verdict without its branch
      cannot distinguish the gate working from the default being permissive
- [x] The 502 §3 prediction is recorded in this file against its measured outcome, stated
      as right or wrong, with the mechanism named either way
- [x] Fixtures committed under a path that carries their provenance (source commit + sha256
      + rail offsets in a README), so the T-365 defect — a fixture directory whose name
      asserts a provenance it does not have — is not reproduced here

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
# --- T-413 ---
# The bytes AEF sent are what is on disk. Digests are AEF's, from rail 506 §1.
echo "bbc6269dacc06991c5ab8df6e7231f7e58f5882605d7475dbdd81d4c27befd9c  tests/fixtures/aef-inbound/t406-clean-leading-boilerplate.bpmn" | sha256sum -c -
echo "04ae662f09ef27d19bbf4968219e3a4cf5beb7b4e94209c086928ae043f26c41  tests/fixtures/aef-inbound/t406-incidental-leading-boilerplate.bpmn" | sha256sum -c -
# The exporter claim, re-measured on the received bytes rather than trusted from the report.
test "$(cat tests/fixtures/aef-inbound/*.bpmn | grep -c 'exporter=')" = "0"
# Both fixture legs ran AND are branch-attributed AND landed on the default branch — which
# is the finding, not an incidental detail of the output.
#
# This line first read `test "$(grep -c 'branch:' …)" = "6"` and the P-011 gate rejected it:
# T-414 added a seventh leg minutes later and the count went stale the moment the file it
# measures was extended. The count was never what mattered. A gate keyed on the size of a
# collection fails when the collection grows for a good reason, and passes when the two
# members it actually cares about are swapped out for others.
mkdir -p .context/working/t413 && node tools/_t406-doc-comment-provenance-cdp.mjs > .context/working/t413/probe.out 2>&1 && grep -q 'AEF-CLEAN.*branch: UNSTAMPED (default)' .context/working/t413/probe.out && grep -q 'AEF-INCIDENTAL.*branch: UNSTAMPED (default)' .context/working/t413/probe.out
# The first run is kept verbatim as the defect witness; a later fix makes the live probe
# green and this file is then the only record that the incidental leg was ever red.
grep -q "FAIL AEF-INCIDENTAL" tests/fixtures/aef-inbound/_t413-first-run.txt

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

## Measured outcome — the prediction was wrong, in both halves

    ok   CONTROL  peer, plain rationale      [UNSTAMPED (default)] want=preserve got=preserved
    ok   STAMPED  peer, colliding comment    [FOREIGN "camunda modeler"] want=preserve got=preserved
    ok   OURS     boilerplate hoisted to top [OURS] want=suppress got=suppressed
    ok   UNKNOWN  no producer identity       [UNSTAMPED (default)] want=suppress got=suppressed
    ok   AEF-CLEAN    trailer only, real bytes  [UNSTAMPED (default)] want=suppress got=suppressed
    FAIL AEF-INCIDENTAL rationale after trailer [UNSTAMPED (default)] want=preserve got=suppressed

**Predicted (rail 502 §3):** clean → suppressed; incidental → **preserved**, *because* the
document is corpus-spec-generated and should carry AEF's 494 `exporter` stamp, putting it
on the STAMPED leg.

**Measured:** clean → suppressed (right, and for the right reason — the comment is nothing
but the trailer, nothing is lost). Incidental → **suppressed**. Wrong outcome, and the
mechanism was wrong too: there is no stamp on the bytes, so it was never going to reach the
STAMPED leg. It took `UNSTAMPED (default)`, and seven lines of real `aef-task-lifecycle`
rationale were destroyed on import.

Being wrong about the mechanism matters more than being wrong about the outcome. Had the
result come back "preserved" for some unrelated reason, I would have banked the prediction
as confirmation that the stamp works, and retired a question that is wide open. That is why
the probe now prints the deciding branch next to every verdict — AEF's 506 §2(a).

## What the branch column showed that I had not expected

I went in believing my four original legs simply never exercised the branch AEF's documents
take. **That was wrong and the column disproved it on the spot:** CONTROL and UNKNOWN both
run through `UNSTAMPED (default)`. The branch was covered twice over.

What no leg crossed it with was the **shape** of the comment. Every existing leg carries a
comment that is either *nothing but* the trailer or has *no* trailer. The mixed shape —
trailer, then genuine rationale, one block — appears on no leg at any branch. So the hole
was not an untested branch; it was an untested **axis**, and coverage of the branch is what
made it invisible.

That is the second time this pair of projects has hit the same shape from opposite sides:
AEF's L-560 says a detector's scope note reads as coverage; T-411 found a schema's field
presence reading as content. Here a **branch's presence in the test matrix reads as coverage
of that branch's behaviour**, when the behaviour varies on a dimension the matrix holds
constant.

## The consequence I wrote into src, and its exit path, are both spent

`readDocComment` (src/aef-workflow-designer.html:9493-9496) states the residual plainly:

> *AEF do not stamp an exporter today (their rail 491), so their documents are still
> affected. Closing it for them depends on them adopting the producer field … not on
> further work here.*

AEF adopted it at rail 494. Measured now: it reached their emitter and **0 artifacts** —
0 of 37 live `.bpmn`, 0 on their disk, 0 on either fixture. The exit path I named has been
taken by the other side and the outcome did not move, because a stamp emitted by a function
nothing calls is not a stamp on the wire.

So "still a hypothetical with no live witness" — the argument in T-406's Decisions for
leaving the identity-less case under T-311's rule — no longer holds. The clean fixture is
real corruption that reached AEF's promoted corpus, and AEF measured real rationale loss in
their own corpus from the incidental shape (their T-2895). The fix is a separate task
(**T-414**), on the shape axis rather than the identity axis: suppress only when the leading
comment is *nothing but* the trailer.

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

### 2026-08-09T15:19:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-413-run-aefs-two-t-406-fixtures-through-the-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-89f1a613
- **Timestamp:** 2026-08-09T15:31:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T15:31:34Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
