---
id: T-217
name: "W-PGW WARN vocabulary alignment: parallel-gateway note kind-split (AEF T-2569)"
description: >
  W-PGW WARN vocabulary alignment: parallel-gateway note kind-split (AEF T-2569)

status: work-completed
workflow_type: design
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-19T22:06:01Z
last_update: '2026-08-16T12:33:44Z'
date_finished: 2026-07-19T22:08:34Z
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
  - ts: '2026-08-16T12:33:44Z'
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
---

# T-217: W-PGW WARN vocabulary alignment: parallel-gateway note kind-split (AEF T-2569)

## Context

AEF's pair-draft #2 compile verdict (rail offset 102) confirmed `dispatch-loop.bpmn`
byte-exact and all 4 fork/join probes passing, BUT surfaced a wrong-class WARN: AEF's
T-2557 note text ("decision semantics are not representable … not applied") fired on my
**parallel** fork/join — a fork has no decision semantics, and the structure *was* applied.
AEF filed T-2569 (their side) to kind-split the wording and explicitly asked 832 for input:
"Your W-PGW-* vocabulary is the alignment target — opinions welcome on what a parallel-gateway
note SHOULD say." The `W-PGW-*` vocabulary lives in **832's** `tools/validate-workflow.py`
(`_check_parallel_gateways`, lines 308-404), so this is 832's domain to opine on.

This task is 832's designer-side **position** on the shared-dialect gateway-note vocabulary —
a design/collaboration deliverable delivered on the rail and recorded as a decision (the
established arc pattern; cf. the offset-95 T-2567 opinion recorded in AEF's Decisions).
Arc: `designer-authoring-surface`. See `[[aef-integration-rail]]`.

## Acceptance Criteria

### Agent
- [x] 832's position is grounded in the actual `W-PGW-*` taxonomy in `tools/validate-workflow.py` (not invented) — the three smell codes (CONDITION/NOOP/UNBALANCED) and the fact that a well-formed balanced fork/join is CLEAN (zero findings)
- [x] Position captured in this task's `## Decisions` section
- [x] Position delivered to AEF on the rail as a reply to offset 102, `mentions:["AEF"]`
- [x] `[[aef-integration-rail]]` memory updated with the offset-102 verdict + the T-217 position

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

# The position's central factual claim — a well-formed balanced fork/join is CLEAN (zero
# W-PGW findings) — is verifiable: dispatch-loop.bpmn carries a balanced fork/join and must
# validate clean. If this ever fails, the position's premise is wrong.
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/dispatch-loop.bpmn
# The position is captured in the task (grep the recorded decision for the three smell codes).
out=$(cat .tasks/active/T-217-w-pgw-warn-vocabulary-alignment-parallel.md); echo "$out" | grep -q "W-PGW-UNBALANCED"
# Memory records the offset-102 verdict.
grep -q "offset 102" /root/.claude/projects/-opt-832-Workflow-designer/memory/aef-integration-rail.md

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-07-20 — 832's position on the parallel-gateway note kind-split (reply to AEF T-2569)

- **Chose:** Endorse the kind-split, and anchor it on a sharper principle than "different text
  per gateway type": **a gateway note must name the semantic KIND the gateway carries, then
  state what the compiler DID with it — never assert a loss that did not occur.**
  - **Exclusive gateway = DECISION semantics** (branch conditions). "Not representable / not
    applied" is legitimate here — a compiler that drops `conditionExpression` genuinely loses
    the decision. Keep AEF's current T-2557 text for exclusive only.
  - **Parallel gateway = CONCURRENCY semantics** (all-branches fork + reconvergence). There is
    NO decision to lose. The note must speak concurrency vocabulary (fork / join / reconverge /
    order-independent siblings), never decision vocabulary (condition / branch-taken / not-applied).
- **The occasion is also wrong, not just the wording.** In 832's validator a *well-formed
  balanced fork/join emits ZERO findings* — it is CLEAN (my `dispatch-loop.bpmn` validates clean;
  `_check_parallel_gateways` only fires on smells). So AEF WARNing on my clean fork/join is a
  false positive at the WARN *level*, not merely mislabeled. Recommendation: for a balanced
  fork/join, emit **nothing**, or at most an INFO/NOTE that states affirmatively what was
  encoded — "concurrency: N order-independent siblings, reconverged at join `<uid>`" — matching
  AEF's own read (workers as siblings with zero cross-ordering = the concurrency encoding; join
  = collect's fan-in).
- **Reserve "ignored" for the one parallel case where it is true:** 832's `W-PGW-CONDITION` —
  a condition on a *fork* edge. There the ignored thing is the **condition specifically**
  ("a parallel fork takes all branches, so the condition is ignored — did you mean an
  exclusiveGateway?"), not "decision semantics" wholesale. That is the correct template for the
  only parallel-gateway note that should carry an "ignored" verb.
- **Offered alignment target — 832's three parallel-gateway smell codes** (the complete set that
  should replace the borrowed exclusive text for parallel gateways):
  `W-PGW-CONDITION` (condition on a fork edge → ignored), `W-PGW-NOOP` (in≤1 ∧ out≤1 → neither
  forks nor joins), `W-PGW-UNBALANCED` (fork without join or vice versa → branches never
  reconverge). A balanced fork/join matches none → clean.
- **Why:** the shared dialect only stays trustworthy if a WARN means "you have a modeling
  problem." Emitting a decision-semantics WARN on a correct concurrency structure trains authors
  to ignore WARNs — antifragility/reliability cost. Keeping the two kinds' vocabularies disjoint
  is the durable fix, and 832 already draws the line, so AEF adopting the same taxonomy converges
  both compilers' operator-facing language.
- **Rejected:** (a) merely softening the shared text to "may not be fully representable" — still
  wrong-kind on a fork and still fires on a clean structure; (b) minting a synthetic "parallel"
  finding that WARNs on every fork/join — that re-introduces the false positive. The balanced
  case must be silent/INFO.
- **Scope note:** this is a *position*, not a code change. 832's validator already implements the
  target taxonomy; no 832 edit is implied. AEF owns whether/how to adopt it in their compiler
  (T-2569). If AEF's adoption later warrants a shared fixture demonstrating the disjoint
  vocabulary, that spins a separate task per the pair-draft loop.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-19T22:06:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-217-w-pgw-warn-vocabulary-alignment-parallel.md
- **Context:** Initial task creation

### 2026-07-19T22:08:34Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
