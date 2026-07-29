---
id: T-296
name: "Cut designer release 0.8.0 (T-286 badge z-order + T-293 endpoint-handle layer) and announce for AEF re-pin — operator's only reachable designers serve pinned 0.7.1"
description: >
  Cut designer release 0.8.0 (T-286 badge z-order + T-293 endpoint-handle layer) and announce for AEF re-pin — operator's only reachable designers serve pinned 0.7.1

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
created: 2026-07-29T06:16:47Z
last_update: 2026-07-29T06:24:17Z
date_finished: 2026-07-29T06:24:17Z
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

# T-296: Cut designer release 0.8.0 (T-286 badge z-order + T-293 endpoint-handle layer) and announce for AEF re-pin — operator's only reachable designers serve pinned 0.7.1

## Context

T-293's field failure was root-caused as environmental: every designer the
operator can reach serves the pinned 0.7.1 release (our Watchtower :3000/designer
and AEF's :3001 both vendor it), which predates T-286 AND T-293; the only serve
of current src (:8834) has no ufw allow rule (T-253 class). Remedy rail 1: cut
0.8.0 so the fixes reach ufw-allowed ports via the normal pull-at-tag re-pin
(T-247/D-335). Bundles everything on src since designer-v0.7.1: T-264
save-target guards, T-125 lane compaction, T-286 badge z-order, T-293 endpoint
handle layer — all ZERO seam surface (no BPMN serialization, aef:* vocabulary,
or consumer-API change). Release note must state the 0.7.1 annotate-intake
alias is NOT retired in 0.8.0 (AEF's operator-sequenced retirement stays open).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Full suite green before cutting: tests/run-bridge-tests.sh 42/42 + corpus
      geometry sweep clean on the exact src being released
- [x] VERSION bumped 0.7.1 -> 0.8.0; scripts/release-designer.sh run: render
      gate PASS, immutability guard green (0.7.1 and earlier dist bytes
      untouched), dist/aef-workflow-designer-0.8.0.html + MANIFEST.yaml written
      (sha cab3c751…, 903600 B)
- [x] Annotated tag designer-v0.8.0 created carrying artifact sha256 + bytes;
      master + tag pushed to origin (pull-at-tag intake source)
- [x] Rail announce posted at offset 308 (version, sha256, bytes, tag — the
      T-247 trigger + verdict handshake), explicitly noting: zero seam surface,
      alias intake NOT retired, and that re-pin closes the operator's
      T-293/T-286 retest gap
- [x] MANIFEST capabilities block still present (annotation_seam: 1) and
      0.7.1-and-earlier pins byte-untouched (0.7.1 sha d2bf0d63… spot-checked)
- [x] BONUS (operator-reachability, same task motive): our own vendored pin
      updated 0.7.1→0.8.0 + `fw designer sync --from-tag` run (MANIFEST + pin
      anchors verified) — :3000/designer/app now serves 0.8.0 on a ufw-allowed
      port; harvest map saved to the store as t293-retest-harvest and the full
      operator path (real click-select + endpoint drag, scrolled + unscrolled)
      re-verified green through :3000 (8/8 legs)

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

test -f dist/aef-workflow-designer-0.8.0.html
out=$(sha256sum dist/aef-workflow-designer-0.8.0.html); echo "$out" | grep -q cab3c75183979b0e15e23192518f9360ea12fe33b6a4f78641d7e264f6110935
out=$(git tag -l designer-v0.8.0); [ -n "$out" ]
grep -q 'latest: "0.8.0"' dist/MANIFEST.yaml
grep -q 'annotation_seam: 1' dist/MANIFEST.yaml
out=$(sha256sum dist/aef-workflow-designer-0.7.1.html); echo "$out" | grep -q d2bf0d633e9e347b3429f8c22f194d27d673d05e11650d32c1cb6a71359ca353
out=$(curl -sf http://127.0.0.1:3000/designer/app); test $(echo "$out" | grep -c "g-handles") -eq 3

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

### 2026-07-29T06:16:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-296-cut-designer-release-080-t-286-badge-z-o.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-51e7ac65
- **Timestamp:** 2026-07-29T06:24:18Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#1 (Agent)** — Full suite green before cutting: tests/run-bridge-tests.sh 42/42 + corpus
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/run-bridge-tests.sh in: Full suite green before cutting: tests/run-bridge-tests.sh 42/42 + corpus`
- **AC#2 (Agent)** — VERSION bumped 0.7.1 -> 0.8.0; scripts/release-designer.sh run: render
  - **AC-verify-mismatch** (narrow, heuristic) — `path=scripts/release-designer.sh in: VERSION bumped 0.7.1 -> 0.8.0; scripts/release-designer.sh run: render`

### 2026-07-29T06:24:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
