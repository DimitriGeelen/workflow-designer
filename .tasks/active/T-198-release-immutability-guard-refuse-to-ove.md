---
id: T-198
name: "Release immutability guard: refuse to overwrite an already-released VERSION with different bytes (G-007)"
description: >
  scripts/release-designer.sh:29 does an unconditional cp of src over dist/aef-workflow-designer-$VERSION.html. Re-running at an already-released VERSION silently mutates the artifact AEF has pinned (0.2.0 @ e301986b, cited in mapping-v1:164) and rewrites MANIFEST.yaml's sha to match the mutation — every existing guard stays green because they check internal self-consistency (artifact==src, manifest==artifact), never immutability-vs-history. Add a fail-closed guard: if the target artifact already exists AND its bytes differ from src, abort with an actionable message (bump VERSION, or set an explicit deliberate-recut bypass). Land BEFORE T-197, the first src change since 0.2.0 shipped, whose render gate forces a build and puts the unguarded cp on the happy path. Register: G-007.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [release, arc:designer-authoring-surface]
components: []
related_tasks: [T-197, T-178, T-174]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-16T05:26:33Z
last_update: 2026-07-16T05:27:08Z
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

# T-198: Release immutability guard: refuse to overwrite an already-released VERSION with different bytes (G-007)

## Context

A release is a promise: version X means these exact bytes, forever. AEF vendors
`dist/aef-workflow-designer-0.2.0.html` and verifies it by sha256 (`e301986b…`,
cited in `docs/standards/aef-bpmn-mapping-v1.md:164`). Nothing enforces the
promise — `scripts/release-designer.sh:29` is an unconditional `cp "$SRC"
"$ARTIFACT"`. The script's own post-cp `diff -q "$SRC" "$ARTIFACT"` compares the
copy to its source and so can never fail; `MANIFEST.yaml`'s sha is regenerated
from the (possibly mutated) artifact, following the mutation rather than
catching it. Every guard is internally self-consistent and none checks
immutability-vs-history. Full register entry: **G-007**.

Filed now because the hazard is on the *next* task's path: T-197 is the first
`src` change since 0.2.0 shipped, and its render gate
(`tests/test_designer_render.py:_resolve_build()`) resolves the artifact from
`VERSION` with no override — so verifying T-197 requires cutting a build. Today
`src == dist/0.2.0` byte-for-byte, so 0.2.0 is still reproducible and the
mutation has not occurred. The guard wants to land before the first src change,
not after.

## Acceptance Criteria

### Agent
- [x] `scripts/release-designer.sh` aborts (non-zero exit, no artifact write, no manifest write) when the target `dist/aef-workflow-designer-$VERSION.html` already exists AND its bytes differ from `src/aef-workflow-designer.html`
- [x] The abort message is actionable: it names the version, states that it is already released and pinned, and gives the two real options (bump `VERSION`, or set the explicit bypass) as copy-pasteable commands
- [x] Re-running at an already-released VERSION whose bytes are UNCHANGED still succeeds (idempotent re-cut stays green — determinism is the script's contract, per its own header)
- [x] A deliberate re-cut is possible but never silent: an explicit env bypass (mirroring `RELEASE_SKIP_RENDER_CHECK`'s loud-opt-out idiom) overwrites, printing a WARNING to stderr naming the old and new sha256
- [x] Cutting a NEW version (VERSION not yet in `dist/`) is unaffected — no existing artifact, no guard fires
- [x] Guard fires BEFORE the render gate and before any write, so a blocked release leaves `dist/` and `MANIFEST.yaml` byte-identical to their pre-run state
- [x] `tests/test_release_immutability.py` covers all five paths above (blocked-mutation, unchanged-idempotent, bypass-overwrites, new-version, dist-untouched-on-block) against a temp `dist/`, never mutating the real `dist/aef-workflow-designer-0.2.0.html`
- [x] Regression proof: `dist/aef-workflow-designer-0.2.0.html` still hashes to `e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a` after the full test run — AEF's pin is intact

**Evidence.** All 8 verified 2026-07-16.

*The test is a real test.* Run against the pre-guard script from git HEAD
(`git show HEAD:scripts/release-designer.sh`), it reports 9 failures including
`(3) MUTATION OF A RELEASED VERSION WAS ALLOWED — guard did not fire`,
`(4) BLOCKED RUN STILL MUTATED THE ARTIFACT`, and `(4) blocked run rewrote
MANIFEST.yaml`. The hazard in G-007 is reproduced, not theorised: the old script
did silently rewrite a released artifact and follow it with a rewritten manifest
sha. Against the guarded script: `OK: release immutability guard (G-007) — 5
paths pass`.

*No regression.* Full suite green (12/12): validate_iw9, mapping_standard_
conformance, editor_bridge_meta_parity, editor_bridge_field_coverage,
editor_bridge_structured_parity, editor_extension_shape_consistency,
editor_namespace_consistency, forward_fixtures, roundtrip_serialization,
bridge_aef_passthrough, bridge_seam_roundtrip, release_immutability.

*Pin intact.* `dist/aef-workflow-designer-0.2.0.html` → `e301986b993baf58d5ed…`
after the full run; `git status dist/ VERSION` clean (only `scripts/` modified +
the new test added).

## Evolution

### 2026-07-16 — the guard was found by scoping T-197, not by planning
- **What changed:** G-007 was not on any roadmap. It surfaced while mapping T-197's
  scope: the render gate resolves its artifact from `VERSION` with no override, so
  any `src` change is only verifiable by cutting a build — which put the
  unguarded `cp` directly on T-197's happy path, with AEF pinned downstream. The
  hazard had existed since T-174 but was invisible because nothing had changed
  `src` since 0.2.0 shipped; it was a trap armed and waiting for the next task.
- **Plan impact:** T-197 grew a hard prerequisite (this task) and a real open
  question it cannot answer alone — whether retiring the owner field warrants
  cutting 0.3.0 (a release + re-pin decision, human sovereignty), or whether the
  render test should gain an artifact override so `src` changes are verifiable
  pre-release. T-197 is blocked on that fork, not on effort.
- **Triggered:** G-007 registered; T-198 filed and completed ahead of T-197.

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

bash -n scripts/release-designer.sh
python3 tests/test_release_immutability.py
sha256sum dist/aef-workflow-designer-0.2.0.html | grep -q e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a

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

### 2026-07-16T05:26:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-198-release-immutability-guard-refuse-to-ove.md
- **Context:** Initial task creation

### 2026-07-16T05:27:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
