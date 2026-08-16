---
id: T-300
name: "Make bake-clean-layout dialect-preserving (editor-save, not regen) and re-bake
  corpus"
description: >
  G-012 fix: bake-clean-layout.py re-renders via yaml-to-bpmn.py, clobbering the T-288
  editor-saved corpus dialect (ids, bpmndi, hand-carried aef:meta notes). Rework the
  pass to write back the editor's own buildBpmnXml() output for each map, keep the
  YAML geometry patch, then re-bake all 24 maps to a Clean fixpoint under current
  0.8.0-era Clean logic so the T-100 nudge goes quiet on the shipped corpus (unblocks
  T-101 Human AC).

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
created: 2026-07-29T08:05:30Z
last_update: '2026-08-16T14:33:25Z'
date_finished: 2026-07-29T08:20:59Z
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
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 4
      F3: 2
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=4 
      (prose:routing-structural); F3=2 (prose:seam-namespace); F1=2 
      (prose:process-editor-capability)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.context/project/concerns.yaml,examples/aef-processes/error-escalation-ladder.workflow.yaml,examples/aef-processes/rendered/error-escalation-ladder.bpmn,examples/aef-processes/rendered/healing-loop.bpmn);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-300: Make bake-clean-layout dialect-preserving (editor-save, not regen) and re-bake corpus

## Context

G-012 fix (register entry in .context/project/concerns.yaml). tools/bake-clean-layout.py
(T-101, July-5) re-renders rendered/*.bpmn via yaml-to-bpmn.py after patching YAML
geometry — but since T-288 the committed corpus is EDITOR-SAVED dialect (editor ids,
bpmndi DI, hand-carried aef:meta notes like T-297/T-298 v2). Running the documented
re-bake on 2026-07-29 clobbered all 24 maps (+2839/-3904, dialect switch, v2 notes lost);
reverted pre-commit. Meanwhile the corpus has drifted un-Clean under 0.8.0-era logic
(--check 0/24 fixpoints; nudge fires on harvest-pipeline + verification-gate in the
served editor) — the exact regression T-101 exists to prevent. Fix the tool to write
back the editor's own serialized XML (dialect-preserving), then re-bake.

## Acceptance Criteria

### Agent
- [x] Driver (tools/_clean-layout-cdp.mjs) returns the editor's own serialized XML (+post-Clean thumbnail) per map; bake writes THAT byte-verbatim to rendered/*.bpmn + gallery mirror — yaml-to-bpmn.py regen step removed. AMENDED during build: the YAML geometry patch was REMOVED, not retained — since T-125, editor-state y is lane-relative, and patching it into the YAML's absolute-y fields broke check-lane-bands on 2 maps; with regen forbidden (G-012) the YAML patch is no longer load-bearing (see Decisions)
- [x] Re-bake all 24 maps: dialect preserved — bpmndi present, editor id scheme kept, T-297 note + T-298 markers grep-verified in healing-loop.bpmn / error-escalation-ladder.bpmn; 9 laggard maps still carrying the yaml-to-bpmn banner in HEAD normalized into editor dialect (T-288-consistent direction)
- [x] Post-bake: --check 24/24 Clean fixpoints — criterion redefined to the honest file-level contract (post-Clean serialization byte-equals the committed file); in-state moved/netMoved is unreliable because adoptImportedXml normalizes coordinates on import (audit-process + error-escalation-ladder show transient moved>0 with byte-stable output; bake re-run sha-verified identical)
- [x] Semantic parity: validator 24/24 VALID; bridge suite 42/42; corpus-geometry sweep 24 clean / 0 fail; adopt-verify (T-145) all 11 maps rendered == latest store save — bake now mints .editor-versions store versions (with honest thumbnails) on byte change, idempotent (second run mints 0)
- [x] Served-copy proof: t101-review-* store copies re-saved (v2) from re-baked maps; CDP nudge probe 4/4 PASS (nodes>0, #clean-nudge hidden — incl. formerly-failing harvest-pipeline + verification-gate); 3 full-page screenshots taken and READ (tidy rows, no nudge banner)
- [x] G-012 register updated with prevention evidence (status stays watching — operator flips)

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

out=$(python3 tools/bake-clean-layout.py --check 2>&1); echo "$out" | grep -q "24/24 maps are a Clean fixpoint"
out=$(python3 tools/_corpus-adopt-verify.py 2>&1); echo "$out" | grep -q "All 11 maps"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
grep -q "T-297" examples/aef-processes/rendered/healing-loop.bpmn
grep -q "T-298" examples/aef-processes/rendered/error-escalation-ladder.bpmn
grep -q "x-advisory-reachability" examples/aef-processes/error-escalation-ladder.workflow.yaml
! grep -q "yaml-to-bpmn.py. Do not edit by hand" examples/aef-processes/rendered/session-capture.bpmn

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

### 2026-07-29 — YAML geometry patch: remove, don't fix
- **Chose:** The bake no longer touches *.workflow.yaml at all; rendered/*.bpmn (editor-saved) is the sole geometry authority.
- **Why:** Since T-125 lane compaction, editor-state y is lane-relative; patching those values into the YAML's absolute-y convention broke check-lane-bands on error-escalation-ladder + harvest-pipeline. And the patch's only purpose — making a yaml-to-bpmn regen start tidy — is moot because regen is forbidden outright (G-012). YAML stays the semantic source; its geometry fields are historical.
- **Rejected:** (a) converting lane-relative→absolute in the patch — reimplements editor lane-layout math in Python, the exact PL-005 drift class the tool was built to avoid; (b) keeping a known-broken patch behind a flag — latent gate failures (PL-004 class).

### 2026-07-29 — --check criterion: byte-stability, not state movement
- **Chose:** fixpoint ⟺ editor's post-Clean serialization byte-equals the committed file (plus messiness < 3).
- **Why:** adoptImportedXml normalizes coordinates on import, so in-state moved/netMoved can be nonzero while output bytes are stable (proven: sha-identical across repeated bakes of the two "failing" maps). The bake's actual contract is "re-running produces zero diff" — measure that directly.
- **Rejected:** netMoved threshold (still a state-level proxy; false negatives on adopt-normalizing maps).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-29T08:05:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-300-make-bake-clean-layout-dialect-preservin.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f143517e
- **Timestamp:** 2026-07-29T08:21:06Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — Driver (tools/_clean-layout-cdp.mjs) returns the editor's own serialized XML (+post-Clean thumbnail) per map; bake writes THAT byte-verbatim to rendered/*.bpmn + gallery mirror — yaml-to-bpmn.py regen
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_clean-layout-cdp.mjs in: Driver (tools/_clean-layout-cdp.mjs) returns the editor's own serialized XML (+post-Clean thumbnail) per map; bake writes THAT byte-verbatim to render`

### 2026-07-29T08:20:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
