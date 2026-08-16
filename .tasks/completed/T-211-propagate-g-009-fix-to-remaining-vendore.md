---
id: T-211
name: "Propagate G-009 fix to remaining vendored sites (check-active-task.sh, update-task.sh
  partial-recheck)"
description: >
  Propagate G-009 fix to remaining vendored sites (check-active-task.sh, update-task.sh
  partial-recheck)

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
created: 2026-07-19T20:07:34Z
last_update: '2026-08-16T13:57:18Z'
date_finished: 2026-07-19T20:11:18Z
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
  - ts: '2026-08-16T12:33:43Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.agentic-framework/agents/task-create/update-task.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-211: Propagate G-009 fix to remaining vendored sites (check-active-task.sh, update-task.sh partial-recheck)

## Context

Follow-up to T-210 (G-009). My T-210 fix patched only ONE site of the `>`-mis-parse
defect — `update-task.sh` `check_acceptance_criteria` (line 98). AEF's independent sweep
(rail offset 86, their fix landed AEF master `8c07bb091`) found the SAME broken pattern
`s/<!--[^>]*-->//g` at two more sites, which are still broken in my vendored copy:

- `.agentic-framework/agents/context/check-active-task.sh:490` — inception Open-Questions
  strip. An inception whose OQ comment cites a `<tag>` would mis-strip and mis-count
  filed IW-N entries (could spuriously block or unblock the G-020 inception gate).
- `.agentic-framework/agents/task-create/update-task.sh:1217` — T-193 partial-complete
  re-check. Same shape as the site I fixed: a `>`-bearing AC comment folds the `### Human`
  header into the Agent count, blocking re-archival of a partial-complete task.

Fix is the identical one-liner AEF adopted verbatim from my T-210 relay:
`s/<!--([^-]|-[^-]|--[^>])*-->//g`. This is the G-008 shared-tooling propagation loop —
sanctioned in-tree fix of the vendored framework, tracked under G-009 for upstream parity
(AEF has already merged; this brings my vendored copy level until next `fw upgrade`).

## Acceptance Criteria

### Agent
- [x] `check-active-task.sh:~490` OQ strip uses the `>`-tolerant regex `([^-]|-[^-]|--[^>])*` (not `[^>]*`)
- [x] `update-task.sh:~1217` partial-complete re-check uses the `>`-tolerant regex (not `[^>]*`)
- [x] No `[^>]*-->` broken one-line-comment strip remains anywhere under `.agentic-framework/agents/`
- [x] T-210 regression test (`test_ac_comment_strip.sh`) still green (the first site's fix is not disturbed)

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

# No broken one-line-comment strip pattern remains anywhere in the vendored agents:
! grep -rn '\[\^>\]\*-->' .agentic-framework/agents/
# Both newly-patched sites carry the >-tolerant regex fragment.
# NOTE: the command text itself must NOT contain literal comment delimiters —
# the P-011 runner strips HTML comments from the Verification block, so a pattern
# containing them collapses. Match the distinctive alternation fragment instead.
grep -q '(\[\^-\]|-\[\^-\]|--\[\^>\])' .agentic-framework/agents/context/check-active-task.sh
grep -q '(\[\^-\]|-\[\^-\]|--\[\^>\])' .agentic-framework/agents/task-create/update-task.sh
# T-210 regression test (first site) remains green:
bash .agentic-framework/agents/task-create/tests/test_ac_comment_strip.sh

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

**Symptom:** The `>`-mis-parse defect (G-009) that T-210 fixed at one site persists at two
other sites in the same vendored tree — an inception OQ comment or a partial-complete AC
comment citing an XML/HTML `<tag>` mis-strips, mis-counting entries at gate-decision time.

**Root cause:** The one-line comment strip `sed -E 's/<!--[^>]*-->//g'` stops matching at
the first `>` inside a comment, leaving the comment body in place; the following range strip
`sed '/<!--/,/-->/d'` then deletes from that residual `<!--` to the next `-->` (or EOF),
swallowing real content (e.g. a `### Human` header or filed IW-N entries). Three independent
call sites hand-rolled the same fragile two-step strip.

**Why structurally allowed:** T-210 fixed the site that produced the observed failure but did
not sweep for sibling copies of the identical pattern — a single-site fix for a copy-paste
defect class. PL-042 flagged this class as recurring; the fix was incomplete because the
sweep step wasn't performed. (AEF's parallel fix DID sweep and found all three — the
shared-tooling propagation loop caught 832's omission.)

**Prevention:** The Verification block now greps the WHOLE `.agentic-framework/agents/` tree
for any residual `[^>]*-->` broken pattern — a structural invariant that fails if a fourth
copy of this defect is ever introduced or re-vendored. This is the "pin behavior over
patterns" learning (AEF's offset 86): the guard asserts the class is absent everywhere, not
that one line matches one regex. Also recorded under PL-042 (this is its 3rd instance).

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

### 2026-07-19T20:07:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-211-propagate-g-009-fix-to-remaining-vendore.md
- **Context:** Initial task creation

### 2026-07-19T20:11:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
