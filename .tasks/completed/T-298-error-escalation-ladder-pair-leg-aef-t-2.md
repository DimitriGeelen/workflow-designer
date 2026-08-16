---
id: T-298
name: "Error-escalation-ladder pair leg (AEF T-2665 round): code-truth verify the
  ladder article, report on rail"
description: >
  Second pairing leg promised at rail 306/311: trace error-escalation-ladder.workflow.yaml
  against diagnose.sh ladder block + CLAUDE.md ladder definition, rev if code-truth
  mismatch, report on rail (healing-loop leg done in T-297 at rail 310)

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
created: 2026-07-29T06:31:57Z
last_update: '2026-08-16T14:33:25Z'
date_finished: 2026-07-29T07:49:55Z
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
  - ts: '2026-08-16T12:33:48Z'
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
  - ts: '2026-08-16T14:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 2
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=2 (prose:seam-namespace); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:examples/aef-processes/error-escalation-ladder.workflow.yaml,examples/aef-processes/rendered/error-escalation-ladder.bpmn,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-298: Error-escalation-ladder pair leg (AEF T-2665 round): code-truth verify the ladder article, report on rail

## Context

Second pairing leg of the AEF T-2665 exception-handling round (promised at rail 306/311;
healing-loop leg closed in T-297 at rail 310, confirmed both sides at their 313). Trace
examples/aef-processes/error-escalation-ladder.workflow.yaml node-by-node against code
truth in the vendored v1.6.763 framework: the ladder render block (diagnose.sh:157-204),
the CLAUDE.md Error Escalation Ladder definition (A/B/C/D + Proactive Level D), and any
trigger/endpoint pointers. Same honesty standard as T-297: determinism tags, advisory
vs enforced reachability, exact line pointers. Rev to v2 (both YAML and rendered BPMN,
hand-edited in-dialect per T-288 lesson) ONLY if mismatches are found; report either
way on the rail.

## Acceptance Criteria

### Agent
- [x] Every node/edge of error-escalation-ladder.workflow.yaml traced to a code-truth source — verified correct: per-rung pointers 164-195/197-199/201-203, menu 156-204, promote 3+ threshold (promote.sh:147, harvest.sh:10), doctrine matches CLAUDE.md; stale: classify L113 (actual L23), lookup L147 (actual L55), diagnose span 113-204 (actual 23-204), lib/ path ambiguity, n_done automatic-resume claim
- [x] Mismatches found → article revved to v2 in BOTH forms (YAML + rendered hand-edited in-dialect, no regen); v2 provenance comment names all five corrections; n_resolve gained x-advisory-reachability (G-016 class, consistent with healing-loop v2)
- [x] Post-rev validation: validate-workflow.py VALID zero findings on rendered BPMN; YAML parses; pytest suite 11/11 green
- [x] Ladder-leg report posted at rail 317 (reply to their 313, T-2652-slices thread); memory rail frontier updated — T-2665 round now fully closed our side

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

out=$(python3 tools/validate-workflow.py examples/aef-processes/rendered/error-escalation-ladder.bpmn 2>&1); echo "$out" | grep -q "VALID"
python3 -c "import yaml; yaml.safe_load(open('examples/aef-processes/error-escalation-ladder.workflow.yaml'))"
grep -q 'version: 2' examples/aef-processes/error-escalation-ladder.workflow.yaml
grep -q 'version="2"' examples/aef-processes/rendered/error-escalation-ladder.bpmn
grep -q "diagnose.sh:23-204" examples/aef-processes/rendered/error-escalation-ladder.bpmn
grep -q "x-advisory-reachability" examples/aef-processes/error-escalation-ladder.workflow.yaml

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

**Symptom:** error-escalation-ladder.workflow.yaml (v1) carried stale whole-function line pointers — classify_failure "L113" (actual L23), find_similar_patterns "L147" (actual L55), n_diagnose span "113-204" (actual 23-204) — plus a path ambiguity (bare "lib/" claiming promote.sh/harvest.sh live beside resolve.sh) and an over-claim that n_done automatically returns the task to started-work.

**Root cause:** the article was authored against an older vendored framework revision and pinned FUNCTION-START line numbers, which drift on any upstream edit above them; the per-rung MENU pointers survived because that block sat below all subsequent edits. The resume over-claim came from reading the printed NEXT-STEPS menu as behavior instead of as advice.

**Why structurally allowed:** nothing re-checks corpus line pointers against the vendored code after a re-vendor — the validator checks dialect shape, not endpoint truth; pointer claims are free text inside aef: keys, invisible to every gate.

**Prevention:** the pair-round protocol itself is the check (this is the second of two loop articles audited node-by-node this round; both caught real drift). Pattern for authors, stated in the v2 provenance comment: cite BLOCK ranges near file bottoms or function NAMES, not function-start line numbers; re-verify all `endpoint:` pointers on every framework re-vendor.

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

### 2026-07-29T06:31:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-298-error-escalation-ladder-pair-leg-aef-t-2.md
- **Context:** Initial task creation

### 2026-07-29T07:43:14Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-88f390de
- **Timestamp:** 2026-07-29T07:49:56Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T07:49:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
