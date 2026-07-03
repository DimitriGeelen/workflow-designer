---
id: T-054
name: "Dogfooding coverage audit: vendored AEF processes vs examples/aef-processes corpus"
description: >
  Dogfooding coverage audit: vendored AEF processes vs examples/aef-processes corpus

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
created: 2026-07-03T14:19:33Z
last_update: 2026-07-03T14:26:54Z
date_finished: 2026-07-03T14:26:54Z
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

# T-054: Dogfooding coverage audit: vendored AEF processes vs examples/aef-processes corpus

## Context

Dogfooding-mission audit: does the `examples/aef-processes/` corpus (16 maps)
faithfully cover the vendored framework's canonical governance processes, or are
there framework lifecycles/loops with no diagram yet? Produces a cited coverage
matrix and files follow-up mapping tasks for worth-mapping gaps. This is an
**analysis deliverable** — it does not itself add maps (each new map is its own
small build task, per Task Sizing Rules).

## Acceptance Criteria

### Agent
- [x] `docs/reports/T-054-coverage-audit.md` exists with a **coverage matrix**: each canonical framework process → its corpus map file, OR `GAP`, OR `excluded` (with a one-line reason).
- [x] The canonical process inventory is **sourced from the vendored framework** (`.agentic-framework/FRAMEWORK.md`, `CLAUDE.md` lifecycles, `.agentic-framework/agents/*/AGENT.md`) and cited — not invented.
- [x] Every one of the 16 existing corpus maps is accounted for in the matrix (no orphan map left unlisted).
- [x] Gaps are ranked by governance-centrality; each worth-mapping gap has a **filed follow-up task ID** in the report (or an explicit stated reason it is excluded rather than mapped).

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

test -f docs/reports/T-054-coverage-audit.md
# Every one of the 16 corpus maps is named in the report (no orphan):
for m in arc-lifecycle assumption-validation audit-process cross-host-dispatch harvest-pipeline healing-loop inception-lifecycle inception-review promotion-pipeline release-pipeline review-emission revisit-due-scan session-handover task-lifecycle tier0-escalation upgrade-process; do grep -q "$m" docs/reports/T-054-coverage-audit.md || { echo "MISSING from report: $m"; exit 1; }; done
# The matrix and a gaps section are present:
grep -qi "coverage matrix" docs/reports/T-054-coverage-audit.md
grep -qi "gap" docs/reports/T-054-coverage-audit.md

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

### 2026-07-03 — How many gap tasks to file
- **Chose:** File only the 4 Tier-1 "constitutional" gaps (T-055–T-058); catalogue the 11 Tier-2 operational gaps as DEFERRED (promote on demand); exclude Tier-3 utilities with reasons.
- **Why:** "One map = one task" plus proportionality. Filing 15+ backlog tasks would be task sprawl that nobody actions; the report itself is the durable catalogue, and the 4 filed tasks are the genuinely highest-value, directive-central additions.
- **Rejected:** (a) filing a task per diagrammable gap → sprawl; (b) filing zero and leaving all in the report → violates the AC's "filed follow-up task ID" for worth-mapping gaps and loses momentum on the constitutional four.

### 2026-07-03 — What counts as a "gap"
- **Chose:** Report that lifecycle coverage is complete (16/16) and the real gap is a *category* — enforcement/memory/antifragility machinery — not a missing lifecycle.
- **Why:** Every named framework lifecycle already has a map; framing the gap as "N missing processes" would misrepresent the corpus. The honest finding is that the corpus shows happy-path lifecycles but not the governance gates underneath them.
- **Rejected:** Counting each agent script as a "missing process" → inflates the gap with non-diagrammable utilities (metrics, docgen, monitor).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-03T14:19:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-054-dogfooding-coverage-audit-vendored-aef-p.md
- **Context:** Initial task creation

### 2026-07-03T14:26:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
