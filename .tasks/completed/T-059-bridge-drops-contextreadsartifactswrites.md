---
id: T-059
name: "Bridge drops contextReads/artifactsWrites/io/link — emit at parity with editor read shapes"
description: >
  Bridge drops contextReads/artifactsWrites/io/link — emit at parity with editor read shapes

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
created: 2026-07-03T14:30:33Z
last_update: 2026-07-03T14:30:33Z
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

# T-059: Bridge drops contextReads/artifactsWrites/io/link — emit at parity with editor read shapes

## Context

The YAML→BPMN bridge (`tools/yaml-to-bpmn.py`) emits only uid/position/meta/
decisionInput/decisionOutputs. It has **no emit** for `aef.contextReads`,
`aef.artifactsWrites`, node-level `io` (inputs/outputs), or `aef.link`
(targetWorkflow/linkId) — yet the editor's `parseBpmnXml` reads all of them and
the editor's own `buildBpmnXml` emits all of them. So YAML→bridge→editor
**silently drops** those fields. Confirmed present in the corpus: `contextReads`
(2 maps), `artifactsWrites` (7 maps), `io.inputs/outputs` (7+ maps). Verified
empirically: task-lifecycle YAML has 3 such fields; its bridge BPMN retains 0.
Same seam-drift class as T-053/[[G-002]] but materialized as the bridge
**under-emitting** whole fields (vs. shape mismatch). `endpoint` is NOT affected
(it is a `META_KEYS` attribute the editor reads generically). Fix = bring the
bridge emit to parity with the editor read shapes.

## Acceptance Criteria

### Agent
- [x] Bridge emits `contextReads`/`artifactsWrites` as `<aef:contextReads paths="…"/>` / `<aef:artifactsWrites paths="…"/>` (matches editor `getAttribute('paths')`), only when present.
- [x] Bridge emits node `io` as `<aef:io><aef:input name type [required="true"]/>…<aef:output name type/></aef:io>` (matches the editor io reader: required only when true, output has no required), only when inputs/outputs present.
- [x] Bridge emits `<aef:link targetWorkflow="…" linkId="…"/>` when either is present (matches editor link reader).
- [x] New coverage test `tests/test_editor_bridge_field_coverage.py`: every node-level aef field the editor reads via `byAef(el, …)` is either bridge-emitted as a dedicated `<aef:FIELD>` OR a `META_KEYS` attribute; has a self-test proving it FLAGS an editor-read field the bridge never emits (would have caught this bug). Wired into `run-bridge-tests.sh`.
- [x] Full bridge suite passes (20/20); all 16 emitted BPMNs still validate clean; namespace + shape + coverage tests all green.
- [x] The 6 committed `examples/aef-processes/rendered/*.bpmn` goldens are regenerated (unchanged — none use at-risk fields) and remain namespace/validate-clean; a golden-sync check is in `## Verification`.
- [x] Round-trip proof (Playwright): bridge BPMN of task-lifecycle (`contextReads` + `io`) and audit-process (`artifactsWrites`), opened via the editor's `parseBpmnXml`, recovers those fields on the correct nodes (were empty pre-fix). See `## Visual Verification`.

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

python3 tests/test_editor_bridge_field_coverage.py
bash tests/run-bridge-tests.sh
# task-lifecycle bridge BPMN now retains contextReads + io (was 0):
python3 tools/yaml-to-bpmn.py examples/aef-processes/task-lifecycle.workflow.yaml --out /tmp/.t059.bpmn && grep -q "aef:contextReads" /tmp/.t059.bpmn && grep -q "aef:io" /tmp/.t059.bpmn
# an artifactsWrites-bearing map retains it:
python3 tools/yaml-to-bpmn.py examples/aef-processes/audit-process.workflow.yaml --out /tmp/.t059b.bpmn && grep -q "aef:artifactsWrites" /tmp/.t059b.bpmn
# committed goldens are in sync with the bridge (regenerate produces no diff):
for f in cross-host-dispatch harvest-pipeline inception-review promotion-pipeline release-pipeline review-emission; do python3 tools/yaml-to-bpmn.py examples/aef-processes/$f.workflow.yaml --out /tmp/.g-$f.bpmn && diff -q /tmp/.g-$f.bpmn examples/aef-processes/rendered/$f.bpmn >/dev/null || { echo "GOLDEN STALE: $f"; exit 1; }; done

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

## Visual Verification

Serialization-fidelity fix — authoritative proof is a **behavioral** round-trip
through the editor's own `parseBpmnXml`, run live in-browser (Playwright,
HTTP-served, editor loaded; only console error = benign `favicon.ico` 404).

Evidence (bridge BPMN → editor parse):

| Field | Map / node | Pre-fix | After fix (measured) |
|-------|-----------|---------|----------------------|
| `contextReads` | task-lifecycle / `n_work` | dropped (`""`) | `".tasks/active/${task_id}.md"` ✓ |
| `artifactsWrites` | audit-process / `n_aggregate` | dropped | `"['.context/audits/${date}.yaml', 'LATEST-CRON.yaml']"` ✓ |
| `io.outputs` | task-lifecycle / `n_file` | dropped | `[{task_id, task_id}, {owner, string}]` ✓ |
| `io.inputs` | task-lifecycle / `n_start` | dropped | `[{task_id, task_id, required:true}]` ✓ (required flag + types preserved) |

Coverage test measured **34 dropped-field instances** across the corpus pre-fix;
**0** post-fix. The 6 committed `rendered/*.bpmn` goldens were regenerated and
unchanged (none of those maps use the at-risk fields), so they stay in sync.

## RCA

**Symptom:** A canonical workflow YAML with `contextReads`, `artifactsWrites`, or
node `io` (inputs/outputs), rendered to BPMN by the bridge and opened in the
editor, shows those fields **empty** — the data-contract/context-flow annotations
vanish. `artifactsWrites` alone affects 7 of 16 corpus maps.

**Root cause:** The bridge's node-emit only ever handled a subset of the aef
schema (uid/position/meta-scalars/decisionInput/decisionOutputs). Fields added to
the schema and to the editor's read+write paths (contextReads, artifactsWrites,
io, link) were never given emit code in the bridge. The `meta_attrs` builder even
explicitly skips dict/list values, so `io` could never ride along as a meta attr.

**Why structurally allowed:** The bridge suite asserts only that emitted BPMN
*validates clean* (bridge→validator, Python↔Python) — never that it *retains the
YAML's data*. A bridge that drops half the aef payload still emits valid BPMN, so
every test passed. The T-053 shape test closed the attr-vs-element seam for the
two element-text fields but did not assert field *coverage* (that every
editor-read field is emitted at all). The JS↔Python seam had a coverage blind
spot on top of the shape blind spot. Matches [[G-002]] exactly.

**Prevention:** `tests/test_editor_bridge_field_coverage.py` — self-maintaining
cross-check that every node-level aef field the editor reads via `byAef` is
emitted by the bridge (as a dedicated element or a META_KEYS attribute). Any
future editor-read field the bridge forgets to emit now fails the suite. Plus the
`## Verification` golden-sync check keeps `rendered/*.bpmn` from drifting.

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

### 2026-07-03 — Scope: element fields here, meta-key divergence as a separate task
- **Chose:** Fix the four dedicated-element drops (contextReads, artifactsWrites, io, link) under T-059; file the `<aef:meta>` key-list divergence (bridge `META_KEYS` excludes `agentType`/`triggeredBy`/`emits`, which the editor writes to meta and shows in the inspector — dropped in 4/9/10 corpus maps) as a **separate task**.
- **Why:** "One bug = one task." Distinct mechanism and distinct fix: T-059 adds missing *element emitters*; the meta divergence is a *scalar allow-list mismatch* (editor metaKeys ⊄ bridge META_KEYS). The T-059 coverage test cleanly covers the byAef element-field class; the meta class needs its own parity test.
- **Rejected:** Folding both into T-059 → conflates two mechanisms, bloats the fix, and couples two independent regression tests into one task.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-03T14:30:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-059-bridge-drops-contextreadsartifactswrites.md
- **Context:** Initial task creation
