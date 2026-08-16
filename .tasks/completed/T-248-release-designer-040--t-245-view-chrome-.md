---
id: T-248
name: "Release designer 0.4.0 — T-245 view-chrome controls; first pull-at-tag delivery"
description: >
  Operator 'go' 2026-07-23 on AEF's rail-185 request. Content since 0.3.2: exactly
  T-245 (panel toggles + fullscreen focus mode; zero seam surface). Version 0.4.0
  (feature => minor bump; 0.3.1/0.3.2 were fixes). FIRST release under the T-247 pull-at-tag
  contract: announce version/sha/bytes/tag on rail; AEF pulls artifact+MANIFEST at
  tag from LAN origin (file_send fallback only on their request per their 185).

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
created: 2026-07-23T17:03:48Z
last_update: '2026-08-16T14:33:23Z'
date_finished: 2026-07-23T17:06:59Z
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
  - ts: '2026-08-16T14:33:23Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 1
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=1 (prose:AEF seam-incidental); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:dist/MANIFEST.yaml,dist/aef-workflow-designer-0.3.0.html,dist/aef-workflow-designer-0.3.1.html,dist/aef-workflow-designer-0.3.2.html);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-248: Release designer 0.4.0 — T-245 view-chrome controls; first pull-at-tag delivery

## Context

Operator-authorized ("go", 2026-07-23) release cut requested by AEF's operator at rail 185. Content since designer-v0.3.2: exactly T-245 (view-chrome controls — ◧/◨ panel toggles persisted in aefViewPrefs, ⛶ fullscreen focus mode, auto-reveal guard). Zero seam surface: no document/bridge/contract change, so AEF expects pin+sync+e2e only. First release delivered under the T-247 pull-at-tag contract (both-operator-ratified, path validated live at rail 186): rail announce carries version/sha256/bytes/tag; AEF pulls dist artifact + MANIFEST at the tag from read-only LAN origin; file_send only as fallback on their request.

## Acceptance Criteria

### Agent
- [x] Pre-cut gates green at the release commit's content: full bridge suite (round-trip + geometry) AND the standing editor-behavior suite including the t245-view-chrome leg — *bridge 37/37, geometry 24 clean, editor-behavior 5/5 legs, run immediately pre-cut at the same content*
- [x] VERSION bumped to 0.4.0 and `scripts/release-designer.sh` produces `dist/aef-workflow-designer-0.4.0.html` byte-identical to src, with MANIFEST.yaml updated (latest=0.4.0, sha256, bytes) and the render gate passing — *sha ea47db53…80d7, 872147 B, cmp clean, render gate PASS*
- [x] T-245 markers present in the released bundle (btn-focus-mode, vc-exit, revealPropsForSelection); prior-release markers retained — *counts in bundle: 2/6/4; retained: _loadSrcKey x4, EVENT_KIND_TYPE x2, auto-resolved-from-workflow-ref x1*
- [x] Immutability: 0.3.2/0.3.1/0.3.0 dist bytes untouched (shas still 983e0e30…/d99a42da…/36be033d…) and the standalone immutability script passes — *all three re-verified post-cut; guard script 5/5 paths*
- [x] Annotated tag designer-v0.4.0 created on the release commit and pushed to origin; artifact + MANIFEST verifiably frozen AT the tag (at-tag sha == MANIFEST == pin) — *tag on 413e111 pushed; `git show designer-v0.4.0:dist/…0.4.0.html | sha256sum` = ea47db53 = MANIFEST-at-tag sha*
- [x] Release announced on the rail per the T-247 contract (version, sha256, bytes, tag; pull instructions; file_send fallback offer) — *announce = rail offset 190 (reply to their 185 request); no offset gap*

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

# T-248 release verification
test "$(cat VERSION)" = "0.4.0"
grep -q 'latest: "0.4.0"' dist/MANIFEST.yaml
grep -q 'ea47db53a55be41df7ee6a2ff934146eeeed9f247b4a9bb1db9bcc152c3880d7' dist/MANIFEST.yaml
cmp -s src/aef-workflow-designer.html dist/aef-workflow-designer-0.4.0.html
test "$(grep -c 'vc-exit' dist/aef-workflow-designer-0.4.0.html)" -ge 4
# prior releases untouched
out=$(sha256sum dist/aef-workflow-designer-0.3.2.html); echo "$out" | grep -q '983e0e304a3dc12e'
out=$(sha256sum dist/aef-workflow-designer-0.3.1.html); echo "$out" | grep -q 'd99a42da304fc937'
out=$(sha256sum dist/aef-workflow-designer-0.3.0.html); echo "$out" | grep -q '36be033d66aa1c15'
python3 tests/test_release_immutability.py
# tag exists, annotated, and artifact+MANIFEST frozen at-tag with the release sha
git rev-parse designer-v0.4.0 >/dev/null
out=$(git show designer-v0.4.0:dist/aef-workflow-designer-0.4.0.html | sha256sum); echo "$out" | grep -q 'ea47db53a55be41d'
out=$(git show designer-v0.4.0:dist/MANIFEST.yaml); echo "$out" | grep -q 'ea47db53a55be41d'

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

### 2026-07-23T17:03:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-248-release-designer-040--t-245-view-chrome-.md
- **Context:** Initial task creation

### 2026-07-23T17:06:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
