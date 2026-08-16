---
id: T-256
name: "Release designer 0.6.0 (T-255 pool right-edge resize) + rail announce per pull-at-tag
  contract"
description: >
  Release designer 0.6.0 (T-255 pool right-edge resize) + rail announce per pull-at-tag
  contract

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
created: 2026-07-26T20:22:46Z
last_update: '2026-08-16T12:33:46Z'
date_finished: 2026-07-26T20:26:00Z
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
  - ts: '2026-08-16T12:33:46Z'
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

# T-256: Release designer 0.6.0 (T-255 pool right-edge resize) + rail announce per pull-at-tag contract

## Context

Operator authorized 2026-07-26/27 ("releae" after T-255 ship + their "works confirmed" on the live gallery). Content since 0.5.0 = exactly T-255 (pool right-edge resize: authored page-width floor, additive-only `pageWidth` on aef:workflowMeta) — zero seam surface. 0.5.0 was ACCEPTED by AEF at rail offset 202 (pin live, sha confirmed) minutes before this cut, so the pin ladder is clean: 0.5.0 787e4025… → 0.6.0. T-248/T-254 release pattern under the pull-at-tag contract.

## Acceptance Criteria

### Agent
- [x] VERSION bumped 0.5.0 → 0.6.0; scripts/release-designer.sh runs clean (render gate PASS) producing dist/aef-workflow-designer-0.6.0.html + MANIFEST.yaml with latest=0.6.0 and matching sha256/bytes — Evidence: "Released designer 0.6.0", sha256 c2aceff44a2cdf91dd2dfefb8c12db1550bfed2b40a4e62cdf7b145ba3a97e57, bytes 882944, "PASS: designer render-check (0.6.0)"
- [x] Immutability preserved: 0.5.0 artifact still sha256 787e40251f624bb39532be096232f4e25ea9014fe7dc0da0bc46285e140e025e and 0.4.0 still ea47db53a55be41df7ee6a2ff934146eeeed9f247b4a9bb1db9bcc152c3880d7; all older dist artifacts byte-untouched — Evidence: post-cut sha256sum matches both pins; commit 5e4cb13 touched only VERSION, MANIFEST.yaml, and the new 0.6.0 artifact
- [x] Annotated tag designer-v0.6.0 exists; at-tag freeze verified: sha256 of `git show designer-v0.6.0:dist/aef-workflow-designer-0.6.0.html` equals the sha256 in MANIFEST.yaml at the same tag — Evidence: both = c2aceff44a2cdf91dd2dfefb8c12db1550bfed2b40a4e62cdf7b145ba3a97e57
- [x] master + designer-v0.6.0 tag pushed to origin (ssh remote only — github is mirrored, never pushed directly) — Evidence: push output "c91eb61..5e4cb13 master -> master" + "[new tag] designer-v0.6.0"
- [x] Rail announce posted on dm:0e7ee6cad65137fc:6a646ce8b1bc6560 with version/sha256/bytes/tag, content summary (= exactly T-255, zero seam surface), grep markers with counting method stated; AEF 201 (eventDef defect) and 202 (0.5.0 verdict) acked with the defect captured as its own task per one-bug-one-task — Evidence: defect reply at offset 203 (T-257 filed, T-237 lineage stated, v1/v2 fixture accepted), announce at 204 (markers pool-resize-handle=5 / pageWidth=7 / contentRightEdgeNatural=3, grep -c = LINES), ack at 205

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

grep -q "^0.6.0$" VERSION
grep -q 'latest: "0.6.0"' dist/MANIFEST.yaml
test "$(sha256sum dist/aef-workflow-designer-0.6.0.html | awk '{print $1}')" = "$(awk -F'"' '/^sha256:/{print $2; exit}' dist/MANIFEST.yaml)"
# immutability: pinned prior releases untouched
test "$(sha256sum dist/aef-workflow-designer-0.5.0.html | awk '{print $1}')" = "787e40251f624bb39532be096232f4e25ea9014fe7dc0da0bc46285e140e025e"
test "$(sha256sum dist/aef-workflow-designer-0.4.0.html | awk '{print $1}')" = "ea47db53a55be41df7ee6a2ff934146eeeed9f247b4a9bb1db9bcc152c3880d7"
# at-tag freeze
git show designer-v0.6.0:dist/aef-workflow-designer-0.6.0.html > /tmp/.t256art && git show designer-v0.6.0:dist/MANIFEST.yaml > /tmp/.t256man && test "$(sha256sum /tmp/.t256art | awk '{print $1}')" = "$(awk -F'"' '/^sha256:/{print $2; exit}' /tmp/.t256man)"
# tag pushed to origin
git ls-remote origin refs/tags/designer-v0.6.0 > /tmp/.t256rem 2>&1 && grep -q designer-v0.6.0 /tmp/.t256rem
# render gate green on released source
python3 tests/test_designer_render.py > /tmp/.t256render 2>&1

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

### 2026-07-26T20:22:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-256-release-designer-060-t-255-pool-right-ed.md
- **Context:** Initial task creation

### 2026-07-26T20:26:00Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
