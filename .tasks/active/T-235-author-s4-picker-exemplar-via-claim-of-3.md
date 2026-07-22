---
id: T-235
name: "Author S4 picker exemplar via claim of 3ceaf02d and deliver b64+sha to AEF T-2593 intake"
description: >
  Author the S4 picker exemplar for AEF T-2593 intake: via the RUNNING :8834 picker, claim ghost 3ceaf02d (claim-smoke-legacy, referrer claim-smoke-ref — 832-owned fixture); author 3 aef:link legs in the adopted map per AEF spec (rail 149): (a) RESOLVED workflowRef=1f9b5f0c (aef-task-lifecycle, now LIVE after AEF re-verify), (b) GHOST workflowRef=fresh uuid not in store (save-rescan mints it), (c) LEGACY targetWorkflow=review-map name-only. Save (claim fires via:ui). Deliver like pair-draft-3: b64 chunks on the DM + sha256 + version note; AEF drops at tests/fixtures/832/s4-exemplar.{bpmn,sha256} and flips 2 skips in test_s4_exemplar_intake.py. Do NOT touch remaining AEF fixture adb0e0f2.

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
created: 2026-07-22T06:46:37Z
last_update: 2026-07-22T11:02:50Z
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

# T-235: Author S4 picker exemplar via claim of 3ceaf02d and deliver b64+sha to AEF T-2593 intake

## Context

AEF-accepted delivery spec (rail offsets 149/152, their T-2593 intake): author the S4
picker-claim EXEMPLAR — the first real map born through the T-228 "create from pending
ref" picker — and deliver it byte-pinned so AEF drops it at
`tests/fixtures/832/s4-exemplar.{bpmn,sha256}` and flips the 2 skips in their
`test_s4_exemplar_intake.py`. Vehicle: pending ghost **3ceaf02d** (name
`claim-smoke-legacy`, referenced by claim-smoke-ref) — the fixture AEF reserved for this.
The map must exercise the 3 off-page legs in picker-authored form: **resolved** →
`1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7` (aef-task-lifecycle, NOW LIVE post-claim),
**ghost** → a fresh unresolved uuid, **legacy** → bare `targetWorkflow="review-map"`.
Save through /api/save so the claim fires server-side ({via:ui} — the picker path IS the
exemplar's provenance). Do NOT touch AEF's fixture ghost **adb0e0f2** (review-map,
stays untouched). Delivery: b64 chunks + sha256 pin, concat-verified BEFORE posting
(PL rail-delivery lesson, offsets 96-101), plus the saved version note.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The exemplar map is born via the REAL picker path on the served :8834 editor (open "create from pending ref" → click the 3ceaf02d card → map adopts uuid 3ceaf02d), not via hand-authored XML — the provenance IS the deliverable
- [ ] The authored map carries the 3 off-page legs (resolved → 1f9b5f0c live uuid; ghost → fresh unresolved uuid; legacy → bare targetWorkflow="review-map") plus enough surrounding structure to validate clean (validate-workflow.py no findings)
- [ ] Save-to-project fires the server claim: registry.claims gains {uuid: 3ceaf02d..., project: <exemplar id>, via: ui}; ghost 3ceaf02d drops from /api/list ghosts[]; the claim-smoke-ref referrer resolves; AEF's adb0e0f2 ghost is UNTOUCHED
- [ ] The saved .bpmn bytes are sha256-pinned and the pin is wired into tests/test_corpus_fixture_pins.py (or a sibling standing guard) so drift is caught our side
- [ ] Delivery posted on the rail: b64 chunks concat-verified to the pin BEFORE posting, sha256 + version note + intended AEF path (tests/fixtures/832/s4-exemplar.{bpmn,sha256}) — sized per the 12KB-per-message chunking lesson
- [ ] Registry + list verifiers still green after the claim (tools/_gallery-list-verify.py, tools/_gallery-registry-verify.py, tools/_gallery-claim-verify.py)

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

### 2026-07-22T06:46:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-235-author-s4-picker-exemplar-via-claim-of-3.md
- **Context:** Initial task creation

### 2026-07-22T11:02:50Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
