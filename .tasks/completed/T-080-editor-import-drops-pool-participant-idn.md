---
id: T-080
name: "Editor import drops pool participant id/name — round-trip rewrites Pool_* to
  Process_*"
description: >
  Found during T-079 round-trip verification: parseBpmnXml does not read the bpmn:participant
  id/name; buildBpmnXml then re-emits them derived from workflowMeta (Pool_task_lifecycle/task-lifecycle
  becomes Process_task-lifecycle/Process_task-lifecycle). Single-line XML drift on
  every import→export cycle of the editor's own output; pre-existing (confirmed on
  fresh untidied doc), unrelated to tidy-lane. Same seam class as G-002 — editor-internal
  parse/build asymmetry caught only by a manual round-trip check.

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
created: 2026-07-04T12:54:40Z
last_update: '2026-08-16T12:33:35Z'
date_finished: 2026-07-04T12:59:38Z
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
  - ts: '2026-08-16T12:33:35Z'
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

# T-080: Editor import drops pool participant id/name — round-trip rewrites Pool_* to Process_*

## Context

parseBpmnXml builds `pool` from the process element only (`proc.getAttribute('id')` / process name). The editor's own export puts pool identity on `bpmn:participant` (id="Pool_*" name="…" processRef="Process_*") and names the process "Process_<meta>", so every import→export cycle of editor output rewrites the participant line. Bridge-rendered files carry pool identity on the process element itself and have NO participant — the current fallback is correct for them and must be preserved.

## Acceptance Criteria

### Agent
- [x] parseBpmnXml reads pool id/name from the first `bpmn:participant` when present; when absent (bridge files), current process-element derivation is unchanged. — EVIDENCE: `partEl = byBpmn(doc, 'participant')[0]` with `partEl?.getAttribute(...) ||` fallbacks; bridge-loaded pools keep identity (Pool_arc_lifecycle/arc-lifecycle etc.).
- [x] In-browser round-trip byte-identical — EVIDENCE: all 24 gallery maps buildBpmnXml → parseBpmnXml → buildBpmnXml with 0 diff lines (was 1 participant-line drift per map).
- [x] No regression — EVIDENCE: bridge suite 31 passed 0 failed; corpus geometry sweep (nodes + polylines + node-layer label bboxes + pool label text) 24/24 identical vs HEAD baseline.
- [x] JS syntax check passes (node --check: OK) and gallery copy refreshed (diff -q: IN-SYNC).

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

grep -q "byBpmn(doc, 'participant')" src/aef-workflow-designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/.t080-check.js && node --check /tmp/.t080-check.js
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** Every import→export cycle of the editor's own BPMN rewrote the `bpmn:participant` line — pool id `Pool_task_lifecycle` / name `task-lifecycle` became `Process_task-lifecycle` / `Process_task-lifecycle`.

**Root cause:** parseBpmnXml built `pool` exclusively from the process element, but buildBpmnXml stores pool identity on the participant and names the process `Process_<meta>` — an internal parse/build asymmetry: the exporter writes a field the importer never reads.

**Why structurally allowed:** No round-trip harness exercises the editor's own export→import path (G-002's exact gap, editor-internal variant). Each side is self-consistent; the asymmetry is invisible to per-aspect tests and to the bridge suite, which only covers bridge-produced files (where the fallback happened to be correct).

**Prevention:** Corpus-wide in-browser round-trip check (buildBpmnXml → parseBpmnXml → buildBpmnXml, byte-equality over all 24 maps) now demonstrated twice (T-079 found it, T-080 verified the fix). Evidence added to G-002 — this check is the seed of the standing round-trip harness that concern proposes.

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

## Recommendation

**Recommendation:** GO
**Rationale:** One-line asymmetry fix with corpus-wide proof: participant identity now survives the editor's own round-trip, bridge-file imports are untouched by construction (fallback preserved), and every regression surface checked is clean.
**Evidence:** 24/24 maps round-trip byte-identical (was 1 drift line per map); bridge suite 31/31; geometry + pool-label sweep 24/24 identical vs HEAD baseline; node --check OK; gallery in sync.

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

### 2026-07-04T12:54:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-080-editor-import-drops-pool-participant-idn.md
- **Context:** Initial task creation

### 2026-07-04T12:56:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04T12:59:38Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
