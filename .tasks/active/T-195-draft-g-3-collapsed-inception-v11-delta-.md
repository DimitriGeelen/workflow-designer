---
id: T-195
name: "Draft G-3 collapsed-inception v1.1 delta proposal + reconcile forward-compile §8"
description: >
  Ratified G-3 form (collapsed subProcess, go/no-go gateway IMPLIED at boundary, no child gateway, sovereignty-lane owner) supersedes the old exclusiveGateway-terminal strawman still in mapping-v1 Part II (:133) and forward-compile §8 (:164). No G-3 v1.1 delta exists (parallel gap to the T-189 IW-9 delta). Deliver: (1) a proposal doc docs/reports/T-195-g3-collapsed-inception-delta.md with exact before->after edits for BOTH standards (frozen mapping-v1 Part II bullet + forward-compile §8 open item), graduation held for Dimitri; (2) reconcile forward-compile §8's stale open-item line to match §5's already-updated ratified framing (support-deliverable status maintenance, non-normative). Do NOT edit the frozen mapping-v1 standard under agent control — the proposal proposes; Dimitri graduates.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-12T19:38:17Z
last_update: 2026-07-12T20:19:32Z
date_finished: null
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

# T-195: Draft G-3 collapsed-inception v1.1 delta proposal + reconcile forward-compile §8

## Context

The ratified G-3 inception form — a **collapsed `subProcess`** with `aef:meta workflowType="inception"`, the
go/no-go gateway **implied at the boundary** (T-081 phase-1, no child gateway), owner derived from a
**sovereignty** lane — supersedes the old **exclusiveGateway-terminal strawman** still carried in two frozen
docs: `docs/standards/aef-bpmn-mapping-v1.md:133` (Part II G-3 bullet) and
`docs/standards/aef-bpmn-forward-compile-v1.md:164` (§8 open item). No G-3 v1.1 delta exists — a gap parallel
to the T-189 IW-9 delta. My T-194 edit already moved forward-compile **§5** (:104/:115) to the ratified
framing, so §5 now contradicts §8 within the same doc. This task drafts the graduation proposal (Dimitri's
call) and reconciles the §8 support-doc status. Frozen mapping-v1 is NOT edited under agent control.

## Acceptance Criteria

### Agent
- [x] Proposal doc `docs/reports/T-195-g3-collapsed-inception-delta.md` created, capturing: the problem (old strawman vs ratified collapsed form + provenance on the rail), the exact **ratified G-3 form definition** (§2), the **exact before→after edit** for the frozen mapping-v1 Part II G-3 bullet (§3A), the **exact before→after edit** for forward-compile §8 (§3B), graduation blast-radius §4 (fixtures/tests/editor/bridge all conformance-safe), and a §5 sign-off-boundary section (graduation is Dimitri's, not transferable from AEF's operator ratification)
- [x] forward-compile **§8** open-item line reconciled to the ratified framing — the stale "subProcess-with-decision vs. single-node-with-marker" open-question phrasing is gone (grep count 0); marks G-3 RESOLVED ratified-AEF-side pending v1.1 graduation, consistent with §5. Single diff hunk at §8; §2/§3 untouched
- [x] Frozen `docs/standards/aef-bpmn-mapping-v1.md` **NOT modified** under agent control — `git diff --exit-code` clean (zero change)
- [x] `tests/test_forward_fixtures.py` green (`OK: 5 fixture(s) ... conformant`) — the form the delta proposes is exactly what `inception-gonogo.bpmn` already embodies (delta is implementation-consistent)

### Human
- [ ] [REVIEW] Graduate (or rule on) the G-3 collapsed-inception v1.1 delta
  **Steps:**
  1. Read `docs/reports/T-195-g3-collapsed-inception-delta.md` (the before→after for both standards is in §3).
  2. Decide: GO to graduate the collapsed form into v1.1 of both standards (I then apply the frozen edits under your authorization), or NO-GO/amend.
  3. If GO: reply here or run `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-195 --status work-completed` after the frozen edits land.
  **Expected:** A recorded graduation decision; on GO, mapping-v1 Part II G-3 bullet + forward-compile §8 updated to the collapsed form under v1.1.
  **If not:** Leave partial-complete; the proposal stays as the batchable input for the v1.1 graduation (alongside the T-189 IW-9 delta).

## Verification

# Proposal doc exists and carries the ratified-form + before/after content.
test -f docs/reports/T-195-g3-collapsed-inception-delta.md
grep -qi "collapsed" docs/reports/T-195-g3-collapsed-inception-delta.md
grep -qi "implied at the boundary" docs/reports/T-195-g3-collapsed-inception-delta.md
grep -qiE "before|after" docs/reports/T-195-g3-collapsed-inception-delta.md
# Frozen mapping standard NOT edited under agent control (must be unchanged vs HEAD).
git diff --exit-code docs/standards/aef-bpmn-mapping-v1.md
# forward-compile §8 reconciled: the stale open-question phrasing is gone.
out=$(grep -c "subProcess-with-decision vs. single-node-with-marker" docs/standards/aef-bpmn-forward-compile-v1.md); test "$out" = "0"
# Fixture the delta describes is still conformant.
python3 tests/test_forward_fixtures.py

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

### 2026-07-12 — Split the delta: apply §8 (support-doc) now, hold §3A (frozen) for Dimitri
- **Chose:** Author the full proposal doc (both before→after edits), but *apply* only the forward-compile §8 reconcile (3B) under agent control; hold the frozen mapping-v1 Part II edit (3A) for Dimitri's v1.1 graduation.
- **Why:** §8 is a stale open-item line on the 832-owned support deliverable that already contradicted §5 (post-T-194) — reconciling it is non-normative maintenance, un-gated. The mapping-v1 Part II bullet is the *frozen standard*; graduating it is sovereignty (same boundary as T-189 IW-9). AEF's operator ratification clears the AEF side only.
- **Rejected:** (a) applying 3A too (would edit the frozen standard under agent initiative — a sovereignty breach); (b) holding 3B as well (leaves §5-vs-§8 self-contradiction sitting in a 832 doc I own and just touched); (c) folding G-3 into the T-189 delta (violates one-task-one-deliverable — G-3 shape and IW-9 authority are independent clauses).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-12T19:38:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-195-draft-g-3-collapsed-inception-v11-delta-.md
- **Context:** Initial task creation
