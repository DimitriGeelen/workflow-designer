---
id: T-303
name: "Round #4 pair review: draft-knowledge-leveling v2 verdict (AEF T-2667)"
description: >
  Round #4 pair review: draft-knowledge-leveling v2 verdict (AEF T-2667)

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
created: 2026-07-29T13:20:00Z
last_update: '2026-08-16T12:33:48Z'
date_finished: 2026-07-29T13:25:06Z
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
---

# T-303: Round #4 pair review: draft-knowledge-leveling v2 verdict (AEF T-2667)

## Context

Dogfood round #4 of 4 (AEF T-2667, rail 321/322): AEF seeded draft-knowledge-leveling v2 (8ccdd5a5d, 16 nodes / 14 flows / 2 lanes, four manual-entry strands) mapping the capture→promote→practice machine. Our leg per the T-297/T-298/T-299 pattern: independent validator pass + structure re-count + doctrine cross-check, then rail verdict answering their three taste questions (Q1 four disconnected strands in one map vs separate maps; Q2 refusal-end as plain endEvent+state; Q3 dead-but-reachable legs drawn live with honesty notes vs a visual marker convention). Addendum 322: two of the five dead legs already fixed upstream (T-2676 harvest sub-stages, T-2677 audit graduation counter) — notes flip at v3; still dead: 2+/3+ classification, candidates tier, consolidate caller, no-ratification.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Draft fetched from AEF's served designer (sanctioned HTTP), sha recorded (d3b83078, 16810 B), structure independently re-counted — 16 nodes (4 starts + 6 serviceTasks + 1 XOR + 5 ends) / 14 flows / 2 lanes, gateway fan 4-way: MATCH vs claimed 16n/14f/2 — and validator run: `VALID — no findings`
- [x] Doctrine cross-check vs vendored tree, all CONFIRM: enum ladder promoted|ready≥3|almost=2|building<2 in .agentic-framework/lib/promote.sh (~201-209 our pin vs their 202-208 — pin drift, block matches); already-promoted sole exit-1 (~256); <3 warns-and-proceeds (write path); practice write dict `'status': 'active'`, no ratification; fix-learned bin/fw:5195 (their 5216, drift). One correction sent: `fw consolidate` IS a CLI route (bin/fw:5082) — "no caller" is true only programmatically
- [x] Rail verdict posted at offset 324 (reply to 321, mentions AEF): Q1 ONE map (one artifact lifecycle, disconnection is the finding; 4 starts = new corpus max, validator unions reachability), Q2 plain endEvent + terminalKind="error" (7 corpus precedents, no typed errorEndEvent in dialect), Q3 keep T-2659 honesty notes + adopt grep-able `DEAD:` prefix, visual marker only as future inception. Acked through 322 (receipt 323); next read cursor 325

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

# Round-4 doctrine anchors hold in the vendored tree
out=$(grep -c "'status': 'active'" .agentic-framework/lib/promote.sh); test "$out" -ge 1
out=$(grep -c 'consolidate.py' .agentic-framework/bin/fw); test "$out" -ge 1
# Fetched draft still validates (session artifact)
python3 tools/validate-workflow.py /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/draft-knowledge-leveling-v2.bpmn

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


### 2026-07-29T13:50:00Z — round #4 verdict delivered [agent]
- **Action:** Fetched draft-knowledge-leveling v2 from AEF :3001 (sha d3b83078), validator VALID zero findings (second clean-at-seed draft in a row), structure re-count MATCH, four doctrine claims confirmed against our vendored pin, one precision correction (consolidate has a CLI caller, no programmatic one).
- **Rail:** verdict at offset 324 (reply to 321); their 318-322 read and acked through 322 (receipt 323). Q1: one map. Q2: terminalKind="error" refusal end. Q3: DEAD: note-prefix convention, no visual marker yet.
- **Watch:** their v3 will flip the two upstream-fixed dead-leg notes (T-2676/T-2677); still-dead count then 4. Next read cursor 325.

### 2026-07-29T13:20:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-303-round-4-pair-review-draft-knowledge-leve.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-57c6c1e1
- **Timestamp:** 2026-07-29T13:25:06Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T13:25:06Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
