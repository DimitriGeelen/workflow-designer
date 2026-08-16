---
id: T-053
name: "Editor drops decisionOutputs from bridge-generated BPMN (attr vs element-text
  mismatch)"
description: >
  Editor drops decisionOutputs from bridge-generated BPMN (attr vs element-text mismatch)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tests/test_editor_extension_shape_consistency.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-03T13:55:44Z
last_update: '2026-08-16T12:33:33Z'
date_finished: 2026-07-03T14:10:21Z
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
  - ts: '2026-08-16T12:33:33Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-053: Editor drops decisionOutputs from bridge-generated BPMN (attr vs element-text mismatch)

## Context

The editor serializes/parses `aef:decisionOutputs` as a `values="…"` **attribute**
(src/aef-workflow-designer.html:4280 write, :4527 read), but the bridge
`tools/yaml-to-bpmn.py:136` emits it as **element text**
(`<aef:decisionOutputs>go, no-go, defer</aef:decisionOutputs>`) — the same shape
it (correctly) uses for `decisionInput`. Consequence: a BPMN generated from
canonical YAML by the bridge, opened in the editor, **silently loses** its
decision outputs (`getAttribute('values')` → null). Editor→editor round-trips
fine (self-consistent attr), so the gap only shows on the YAML→bridge→editor
path — the exact dogfooding path. Same class as T-042 (editor import diverging
from the bridge); see [[PL-002]]. Fix aligns the editor to element text
(the bridge/`decisionInput` convention); no schema or validator change (free
`aef:` passthrough).

## Acceptance Criteria

### Agent
- [x] Editor **writes** `decisionOutputs` as element text (`<aef:decisionOutputs>…</aef:decisionOutputs>` via `escText`), matching `decisionInput` and the bridge — no `values=` attribute on the write path.
- [x] Editor `parseBpmnXml` **reads** `decisionOutputs` from element `.textContent`, and stays tolerant of the legacy `values=` attribute form (previously-exported files still load — no silent data loss).
- [x] New regression test `tests/test_editor_extension_shape_consistency.py` discovers every field the bridge emits as a dedicated `<aef:FIELD>` element and asserts the editor reads each via `.textContent` (element shape); it has a self-test proving it FLAGS an attribute-shaped read (would have caught this bug).
- [x] The new test is wired into `tests/run-bridge-tests.sh`; the full suite passes (round-trip + namespace + geometry + shape).
- [x] Behavioral proof: bridge-generated BPMN from `inception-lifecycle.workflow.yaml` (`decisionOutputs: go, no-go, defer`), opened in the editor, yields node `aef.decisionOutputs == "go, no-go, defer"` (Playwright evidence in `## Visual Verification`).

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

python3 tests/test_editor_extension_shape_consistency.py
bash tests/run-bridge-tests.sh
# Editor write path is element-text, not attribute:
out=$(grep -n "aef:decisionOutputs" src/aef-workflow-designer.html); echo "$out" | grep -q "<aef:decisionOutputs>" && ! (echo "$out" | grep -q 'decisionOutputs values=')
# Editor read path recovers element text (tolerant of legacy attr):
grep -q "decOutEl.textContent" src/aef-workflow-designer.html

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

This is a serialization-fidelity fix, not a layout/CSS change — the authoritative
proof is a **behavioral** round-trip through the editor's own `parseBpmnXml` /
`buildBpmnXml`, run live in the browser (Playwright, HTTP-served, editor loaded
with 0 console errors).

Evidence (all against bridge output of `inception-lifecycle.workflow.yaml`, node
`n_dcsn01`, `decisionOutputs: go, no-go, defer`):

| Path | Before fix | After fix (measured) |
|------|-----------|----------------------|
| Bridge BPMN (element text) → editor parse | `""` (dropped) | `"go, no-go, defer"` ✓ |
| Legacy `values="…"` attr form → editor parse | `"go, no-go, defer"` | `"go, no-go, defer"` ✓ (tolerant fallback) |
| Editor export (`buildBpmnXml`) shape | `<aef:decisionOutputs values="…"/>` | `<aef:decisionOutputs>…</aef:decisionOutputs>` ✓ (no `values=`) |
| Full editor round-trip (parse→export→re-parse) | value survives | `"go, no-go, defer"` ✓ |

Console errors on editor load: **0**.

## RCA

**Symptom:** A workflow authored in canonical YAML with `decisionOutputs`, rendered
to BPMN by `tools/yaml-to-bpmn.py`, then opened in the editor, shows an **empty**
Decision-outputs field — the enum silently vanishes. (Editor→editor round-trips are
unaffected, which masked it.)

**Root cause:** Serialization-shape divergence for one field. The bridge emits
`decisionOutputs` as element text `<aef:decisionOutputs>…</aef:decisionOutputs>`
(consistent with `decisionInput`), but the editor both wrote and read it as a
`values="…"` **attribute**. `getAttribute('values')` on an element-text node
returns null → `''`. Editor and bridge were each internally consistent, so neither
side's own tests failed — the mismatch lived only in the cross-artifact seam.

**Why structurally allowed:** The bridge suite tested only bridge→validator
(Python↔Python). The editor namespace test (T-044) pinned the aef: *namespace URI*
across editor and bridge but not the per-field *serialization shape* (attribute vs
element text). No test crossed the JS↔Python seam on field shape, so a field could
drift shape undetected — the identical structural blind spot as T-042 ([[PL-002]]),
one layer down (URI was covered; shape was not).

**Prevention:** `tests/test_editor_extension_shape_consistency.py` — self-maintaining
cross-check that discovers the fields the bridge emits as dedicated `<aef:FIELD>`
elements and asserts the editor reads each via `.textContent`. Wired into
`run-bridge-tests.sh`. Any future field that drifts shape (either direction) now
fails the suite. This closes the shape half of the seam that T-044 closed for the URI.

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

### 2026-07-03T13:55:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-053-editor-drops-decisionoutputs-from-bridge.md
- **Context:** Initial task creation

### 2026-07-03T14:10:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
