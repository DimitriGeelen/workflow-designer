---
id: T-276
name: "Execute framework re-vendor to v1.6.763 + post-vendor checklist"
description: >
  Execute framework re-vendor to v1.6.763 + post-vendor checklist

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
created: 2026-07-28T09:33:02Z
last_update: '2026-08-16T14:33:24Z'
date_finished: 2026-07-28T10:00:23Z
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
  - ts: '2026-08-16T12:33:47Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:24Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/git/lib/secret-scan.sh,.agentic-framework/agents/task-create/update-task.sh,.agentic-framework/policy/anti-patterns.yaml,.agentic-framework/policy/escalation-patterns.yaml);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-276: Execute framework re-vendor to v1.6.763 + post-vendor checklist

## Context

Operator GO (2026-07-28, in-session: "go" to option 1). Execute the re-vendor per
docs/reports/T-274-revendor-readiness.md: pin upstream to the AEF GitHub mirror, update
.agentic-framework/ to tag v1.6.763 (sha 28c7a1bd3f070bb090f6890fb0a20081afe4c3e8), run the
post-vendor checklist (shim/shadow cleanup, gate verification), confirm to AEF on the rail.
Concern status flips remain the operator's (offered separately).

## Acceptance Criteria

### Agent
- [x] Upstream pinned + tag pre-verified: `upstream_repo` line in .framework.yaml; ls-remote sha
      for v1.6.763 == 28c7a1bd3f070bb090f6890fb0a20081afe4c3e8 (exact match).
- [x] Re-vendor executed: `fw update --branch v1.6.763` clean (vdev → v1.6.354, HEAD 28c7a1b);
      vendored tree carries review.py/approvals.py/orchestrator.py FRAMEWORK_ROOT fixes, canonical
      `\*?\*?` disposition regex at update-task.sh:792, secret-scan.sh in payload; policy/ catalogues
      hand-completed from the sha-verified clone (old do_vendor include list predates policy —
      new tree's includes has it for future updates); rollback backup at .agentic-framework.rollback (71M).
- [x] Post-vendor checklist green: fw doctor 0 failures; shim deleted + Watchtower restarted on new
      code — /, /review/T-125, /review/T-200, /approvals, /orchestrator all 200; policy shadows
      deleted, reviewer smoke PASS (R-f8b854c7); canonical disposition gate PASS on T-190; secret
      scan REPAIRED (exec bit + patterns file, see Updates) and proven — planted AWS key detected
      exit 1, clean commit passes silently; fw audit 160/21/0 (zero FAILs, +6 passes vs pre-vendor).
- [x] Rail confirmation posted to AEF (thread T-274) with post-vendor gate results + 3 upstream
      findings (644 mode bits, patterns file not vendored, old-do_vendor chicken-and-egg); rail
      memory updated. (Posted at 269; their 268 = new T-2652 design thread, handled separately.)

## Updates (execution log)

### 2026-07-28 — re-vendor executed + 3 payload defects found and repaired in-tree
- **Vendor:** upstream pinned (GitHub mirror), ls-remote sha exact, `fw update --branch v1.6.763`
  clean, rollback at .agentic-framework.rollback. All T-270-class fixes verified present in-tree.
- **Defect 1 (found live):** first post-vendor commit printed "secret-scan: scanner not found …
  (skipping)" — upstream git stores secret-scan.sh/master-guard.sh as 100644; installed hook
  requires -x. Repaired: exec bits restored (5 previously-755 files + scanner/guard); hooks
  reinstalled from v1.2 templates.
- **Defect 2 (found by negative check):** scanner then ran PATTERNLESS (exit 0, stderr note only) —
  `.secret-scan-patterns` is not in do_vendor's includes. Repaired: installed from sha-verified
  clone at the scanner's fallback path; planted-AWS-key probe now detected (exit 1).
- **Defect 3:** `fw update` executes the OLD do_vendor, so the new version's `policy` include didn't
  apply on the upgrade introducing it. Repaired: policy/ hand-copied from the same clone
  (catalogue shas: anti-patterns 04f89678 identical to shadow; escalation d98f2cd0 = T-2643
  v1.4-header successor of our 86383a96).
- **Cleanup:** dispatch_pause shim deleted (Watchtower restarted, 5 routes 200), policy shadows
  deleted, orphaned fabric card removed (drift 0/0/0).
- **Upstream:** all three defects reported with fix proposals at rail 269 (thread T-274).

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

grep -q "^upstream_repo: https://github.com/DimitriGeelen/agentic-engineering-framework.git" .framework.yaml
grep -q 'FRAMEWORK_ROOT / "lib"' .agentic-framework/web/blueprints/review.py
out=$(grep -cF '\*?\*?IW-[0-9]+' .agentic-framework/agents/task-create/update-task.sh); test "$out" -ge 1
test -x .agentic-framework/agents/git/lib/secret-scan.sh
test -f .agentic-framework/.secret-scan-patterns
test -f .agentic-framework/policy/anti-patterns.yaml
test -f .agentic-framework/policy/escalation-patterns.yaml
test ! -f lib/dispatch_pause.py
test ! -f policy/anti-patterns.yaml
curl -sf -o /dev/null http://192.168.10.107:3000/review/T-125
curl -sf -o /dev/null http://192.168.10.107:3000/approvals
test -d .agentic-framework.rollback

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

### 2026-07-28T09:33:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-276-execute-framework-re-vendor-to-v16763--p.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-89b2d9b2
- **Timestamp:** 2026-07-28T10:00:25Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-28T10:00:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
