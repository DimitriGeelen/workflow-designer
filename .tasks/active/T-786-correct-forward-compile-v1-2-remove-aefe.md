---
id: T-786
name: "Correct forward-compile-v1 §2: remove aef:endpoint from the semantic list,
  per the frozen parent and AEF's ruling"
description: >
  AEF answered our @1613 at @1616 and the conflict is resolved against our document.
  Q2: their Child-2 translator tools/bpmn_to_tasks.py does NOT read aef:endpoint -
  they grepped it and listed every aef: attribute it does read. Q1: the frozen parent
  governs, so aef:endpoint is PRESENTATIONAL and a change to it must be a no-op for
  the task graph. By our own pre-commitment in @1613, that makes forward-compile-v1
  §2 the document that drifted. They also reported a fact that assigns ownership:
  aef-bpmn-forward-compile-v1.md does not exist in their tree at all - they hold only
  the frozen Part I - so the drifted document lives only with us and the §2 list is
  ours to correct. Their stated direction: remove aef:endpoint from the semantic list,
  which is the option consistent with the code that exists. Scope is that single correction
  plus its provenance. The frozen mapping-v1 Part I is NOT touched - it is frozen
  and is not ours to edit, and no Part I amendment is proposed here.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [aef-seam, standards, workflow-designer]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T22:51:38Z
last_update: '2026-09-21T22:54:06Z'
date_finished:
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
  - ts: '2026-09-21T22:54:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 4
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=3 (prose:process-conformance)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T22:54:06Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/standards/aef-bpmn-forward-compile-v1.md,docs/standards/aef-bpmn-mapping-v1.md,tests/test_forward_fixtures.py,tools/_t400-schema-teeth.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-786: Correct forward-compile-v1 §2: remove aef:endpoint from the semantic list, per the frozen parent and AEF's ruling

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Moved, not merely deleted.** `aef:endpoint` now sits in forward-compile-v1 §2's
      **presentational** list — where the frozen parent puts it — rather than being dropped
      from the document. Its §3.3 carry-over claim (*"`aef:endpoint` → the command/pointer"*)
      is removed, because that sentence asserted the compiler consumes a field the compiler
      does not read.

      Provenance is inline in the v1.2 note, not behind a citation: the frozen class, AEF's
      grep of `tools/bpmn_to_tasks.py` (`aef:boundaryPos, aef:constituent(s), aef:eventDef,
      aef:laneMeta, aef:link, aef:meta, aef:uid` — *"no occurrence of the string 'endpoint'
      anywhere in the translator"*), and the rail offset **@1616** / their **T-3409**.

- [x] **Frozen Part I byte-identical**, proven: `git diff --stat
      docs/standards/aef-bpmn-mapping-v1.md` returns **empty**. Only the derived document
      moved — 26 insertions, 4 deletions in `aef-bpmn-forward-compile-v1.md` alone.

- [x] **Version bumped 1.1 → 1.2 (2026-09-21)** with a dated correction note in the header, so
      a reader who opens only the top of the file sees that §2 changed and why.

- [x] **Reference corpus untouched.** `python3 tests/test_forward_fixtures.py` exits 0 over all
      19 fixtures after the edit. This was a documentation conformance fix; AEF's translator
      test input did not move.

- [x] **The 264 corpus values were NOT "repaired", deliberately.** AEF ruled them cosmetic
      annotation and said so explicitly: *"11% of 264 refs resolving is consistent with the
      field being cosmetic annotation that accreted prose, commands and citations because
      nothing ever read it back. That is the presentational reading behaving exactly as
      documented, not a defect in it."*

      Recorded here because the census output looks like a defect report and a later reader —
      or a later me — would otherwise "fix" 120 unresolved references that a ruling we asked
      for has already declared fine. The cost of that mistake is silent; the cost of this note
      is four lines.

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
         1. Run `bin/fw reviewer T-786`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-786 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

test -z "$(git diff --stat docs/standards/aef-bpmn-mapping-v1.md)"
python3 tests/test_forward_fixtures.py > /dev/null 2>&1
python3 -c "import sys; s=open('docs/standards/aef-bpmn-forward-compile-v1.md',encoding='utf-8').read(); sem=s[s.index('- **Structured semantic elements**'):s.index('- **Presentational elements**')]; sys.exit(0 if 'aef:endpoint' not in sem else 1)"
python3 -c "import sys; s=open('docs/standards/aef-bpmn-forward-compile-v1.md',encoding='utf-8').read(); p=s[s.index('- **Presentational elements**'):]; sys.exit(0 if 'aef:endpoint' in p[:400] else 1)"
grep -q 'Version:.*1\.2' docs/standards/aef-bpmn-forward-compile-v1.md
bash tools/_t400-schema-teeth.sh > /dev/null 2>&1

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
     fw inception decide T-786 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T22:51:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-786-correct-forward-compile-v1-2-remove-aefe.md
- **Context:** Initial task creation
