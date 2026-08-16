---
id: T-359
name: "Validator reports legal non-flow-node children of process as E-XML-NODE-TYPE
  errors"
description: >
  Process-level <documentation>, <ioSpecification> and <dataObject> are enumerated
  as flow nodes by validate-workflow.py and reported as ERROR E-XML-NODE-TYPE on legal
  BPMN. The documentation case has no id, so the finding anchors to '?' and breaks
  the T-335 anchorability guard.

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
created: 2026-08-03T17:34:57Z
last_update: '2026-08-16T13:58:53Z'
date_finished: 2026-08-03T17:42:49Z
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
  - ts: '2026-08-16T12:33:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:tests/fixtures/third-party/bizagi-nested-ns.bpmn,tests/fixtures/third-party/caseagile-local-ns.bpmn,tests/fixtures/third-party/kitchen-sink.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/fixtures/third-party/bizagi-nested-ns.bpmn,tests/fixtures/third-party/caseagile-local-ns.bpmn,tests/fixtures/third-party/kitchen-sink.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-359: Validator reports legal non-flow-node children of process as E-XML-NODE-TYPE errors

## Context

`validate-workflow.py` enumerates children of `<process>` as flow nodes without
excluding the legal non-flow-node children, and emits **ERROR `E-XML-NODE-TYPE`** for
each one. On a legal BPMN document this is a **false positive** — the document is
valid and the validator says otherwise.

Found 2026-08-03 during T-347's fixture hunt, by `tests/fixtures/third-party/bizagi-nested-ns.bpmn`:

```
ERROR [E-XML-NODE-TYPE] node '?': unknown flow-node element 'documentation'
```

`<documentation>` is legal as a direct child of `<process>` (it is on `BaseElement`).
`bizagi-nested-ns.bpmn` carries two; `i18n-documentation.bpmn` carries one but only
under `<startEvent>`, which is why only the former trips it.

**Two distinct consequences, and the second is why the suite went red:**

1. **False-positive ERROR on legal input.** Also confirmed on
   `caseagile-local-ns.bpmn`, where `<ioSpecification>` and `<dataObject>` — both
   legal children of `<process>` — are reported the same way.
2. **An unanchorable finding.** `<documentation>` has no `id`, so the finding
   interpolates `node '?'` and resolves to `UNRESOLVED`. `tests/test_finding_anchorability.py`
   declares `E-XML-NODE-TYPE: "NODE"` and now observes `['UNRESOLVED', 'node']`,
   failing the T-335 guard.

**The bug is older than the fixture that exposed it.** `ioSpecification` and
`dataObject` have ids, so they anchored to `node` and never disturbed the table — the
defect was firing on every document that carried them and was invisible for exactly
that reason. Only the id-less `documentation` case made it observable. A defect
detectable only through one of its instances was still present in all of them.

**Do NOT fix this by adding `UNRESOLVED` to the `ANCHOR` table.** That records the
false positive as expected behaviour and permanently retires the guard that caught it
— the table is not wrong, the enumeration is.

**Not to be confused with the genuine vocabulary gap in the same rule.**
`E-XML-NODE-TYPE` also fires on `task`, `businessRuleTask`, `manualTask`,
`receiveTask` — real flow-node types outside our vocabulary. Those reports are
correct and are T-355/T-347 territory. This task is only about elements that are not
flow nodes at all. Any repair must keep the two populations separate.

## Acceptance Criteria

### Agent
- [x] The legal non-flow-node children of `<process>` are excluded from flow-node
      enumeration in `tools/validate-workflow.py`, from an explicit list rather than
      a `documentation`-shaped special case — at minimum `documentation`,
      `extensionElements`, `ioSpecification`, `dataObject`, `dataObjectReference`,
      `dataStoreReference`, `property`, `laneSet`, `sequenceFlow`, `association`,
      `textAnnotation`.
- [x] `bizagi-nested-ns.bpmn` and `caseagile-local-ns.bpmn` no longer report
      `E-XML-NODE-TYPE` for any of those elements.
- [x] The genuine vocabulary gap still fires: `kitchen-sink.bpmn` continues to report
      `E-XML-NODE-TYPE` for `businessRuleTask`/`manualTask`/`receiveTask`. A fix that
      silences both populations has broken the rule rather than corrected it, so this
      AC is the one that separates repair from suppression.
- [x] `tests/test_finding_anchorability.py` passes with `E-XML-NODE-TYPE` still
      declared `NODE` — the table unchanged, the tree corrected to match it.
- [x] Teeth: re-introducing the defect (deleting one exclusion) turns the
      anchorability test RED, demonstrated by mutation rather than by reading.
- [x] `bash tests/run-bridge-tests.sh` reports `0 failed`.

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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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


# --- T-359 commands ---
# The false positive must be gone on the two witnesses...
out=$(python3 tools/validate-workflow.py tests/fixtures/third-party/bizagi-nested-ns.bpmn 2>&1); ! echo "$out" | grep -q "unknown flow-node element 'documentation'"
out=$(python3 tools/validate-workflow.py tests/fixtures/third-party/caseagile-local-ns.bpmn 2>&1); ! echo "$out" | grep -q "unknown flow-node element 'ioSpecification'"
# ...and the GENUINE vocabulary gap must still fire. Without this line a fix that
# disables the rule entirely would pass every other check in this block.
out=$(python3 tools/validate-workflow.py tests/fixtures/third-party/kitchen-sink.bpmn 2>&1); echo "$out" | grep -q "unknown flow-node element 'businessRuleTask'"
# NOT `pytest tests/test_finding_anchorability.py` — that file has no pytest-style
# test functions, so pytest collects nothing (exit 5, which at least fails loudly
# rather than passing vacuously). run-bridge-tests.sh:577 invokes it directly.
python3 tests/test_finding_anchorability.py
bash tests/run-bridge-tests.sh

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

### 2026-08-03T17:34:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-359-validator-reports-legal-non-flow-node-ch.md
- **Context:** Initial task creation

### 2026-08-03T17:39:18Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-01f1dd0c
- **Timestamp:** 2026-08-03T17:44:25Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 51
     - evidence: `out=$(python3 tools/validate-workflow.py tests/fixtures/third-party/bizagi-nested-ns.bpmn 2>&1); ! echo "$out" | grep -q "unknown flow-node element 'documentation'"`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 52
     - evidence: `out=$(python3 tools/validate-workflow.py tests/fixtures/third-party/caseagile-local-ns.bpmn 2>&1); ! echo "$out" | grep -q "unknown flow-node element 'ioSpecification'"`

### 2026-08-03T17:42:49Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
