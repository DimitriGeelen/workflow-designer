---
id: T-796
name: "Add describe_workflow: report what AEF's compiler would see in a .bpmn, including lane-derived owners and out-of-dialect authorities"
description: >
  Add describe_workflow: report what AEF's compiler would see in a .bpmn, including lane-derived owners and out-of-dialect authorities

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
created: 2026-09-22T08:52:44Z
last_update: 2026-09-22T08:57:34Z
date_finished: 2026-09-22T08:57:34Z
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

# T-796: Add describe_workflow: report what AEF's compiler would see in a .bpmn, including lane-derived owners and out-of-dialect authorities

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the tool answers "what would AEF's compiler see", not "what is in this file".**
      AEF at @1631: *"owner is compiled FROM the lane; node-level owner is ignored."* So every
      task node is reported with its **lane-derived owner**, which is the fact that actually
      governs downstream. A structural dump that leaves the reader to do that derivation has
      answered the easy question.
      Evidence: every task node carries `derived_owner`, mapped from its lane's authority
      (`sovereignty→human`, `authority→framework`, `initiative→agent`). **NEGATIVE-CONTROLLED:**
      collapsing the mapping to all-human turns the probe red at **52 passed, 1 failed** —
      so the derivation is doing work, not decorating a dump.
- [x] **AC2 — the three seam requirements are reported per-document, with coverage.** `aef:uid`
      on task nodes, `aef:laneMeta authority` on lanes, and inception subProcesses. Counts
      AND the nodes that are missing them — "24 of 24 files have uid" is a corpus fact; this
      tool must answer it for one document, including which nodes fall short.
      Evidence: `seam_coverage` reports task-node count, how many carry `aef:uid`, the ids of
      any that do not, lane count, lanes with an authority, **the ids of nodes with no
      derivable owner**, and inception subProcess count. Measured: `task-gate.bpmn` 5/5 uids,
      0 ownerless; `context-memory.bpmn` 7/7 uids but **7 ownerless**.
- [x] **AC3 — out-of-dialect authority values are flagged as OURS to confirm, not as fact.**
      Our corpus emits five values; the three-core dialect is a **prediction** pending AEF's
      answer at @1635. The tool must surface the non-core values without asserting they are
      invalid — labelling a prediction as a verdict is the drift @1616 already caught once.
      Evidence: non-core values surface under `authority_values_to_confirm` with the note
      *"FLAGGED, not judged invalid — the exact AEF lane dialect is unconfirmed here and was
      asked at agent-chat-arc @1635"*. A probe leg asserts the phrase "not judged invalid" is
      present, so a later edit cannot quietly promote the prediction to a verdict.
- [x] **AC4 — proven to DISCRIMINATE, not merely to emit.** Run against a document with only
      core authorities and against the `authority="none"` document, in the same run, and the
      reports must differ in the flagged set. A describe tool that returns plausible JSON for
      every input has not been shown to read its input.
      Evidence: the two documents produce **different** owner-coverage, asserted directly so
      the tool cannot pass by being a constant. Stronger still, a CROSS-CHECK against an
      independent implementation: describe's ownerless-node set is asserted **equal** to the
      set of nodes `validate_workflow` reports `W-LANE-NO-OWNER` for — two separately written
      tools agreeing node-for-node, and they can no longer drift apart silently.
- [x] **AC5 — the surface stays fenced and unregressed.** Exactly three tools, all read-only,
      traversal still refused, and every existing probe leg still green.
      Evidence: probe **53 passed, 0 failed**. The fence is now declared ONCE as
      `EXPECTED_TOOLS` and asserted from all three sections — three separate copies had
      drifted across T-792/795/796 and each had to be chased individually. Still EXACT rather
      than a subset check, so an accidental fourth tool fails here. Traversal, missing-args
      and unparseable-input all refused for the new tool as well.

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
         1. Run `bin/fw reviewer T-796`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-796 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1-AC5: the whole surface, exercised as a subprocess over real MCP ──────
python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 53 passed, 0 failed'

# ── AC1: the lane->owner mapping AEF specified at @1631 ──────────────────────
grep -qF 'AUTHORITY_TO_OWNER = {"sovereignty": "human", "authority": "framework", "initiative": "agent"}' tools/mcp-designer-server.py

# ── AC3: the flag stays a question, not a verdict ────────────────────────────
grep -qF 'not judged invalid' tools/mcp-designer-server.py

# ── AC5: server still stdlib-only, control then absence ──────────────────────
grep -qE '^import (json|os|subprocess|sys|tempfile)$' tools/mcp-designer-server.py
! grep -qE '^(import|from) (mcp|yaml|requests|httpx|pydantic|lxml|anyio|starlette)' tools/mcp-designer-server.py

# ── the pinned seam is untouched ─────────────────────────────────────────────
test -z "$(git diff --stat HEAD -- examples/aef-processes/rendered/)"

# ── docs describe what ships ─────────────────────────────────────────────────
grep -q 'describe_workflow' docs/mcp-designer-server.md
grep -q '53 passed, 0 failed' docs/mcp-designer-server.md

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
     fw inception decide T-796 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T08:52:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-796-add-describeworkflow-report-what-aefs-co.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-28ab5987
- **Timestamp:** 2026-09-22T08:57:37Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 49
     - evidence: `python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 53 passed, 0 failed'`

### 2026-09-22T08:57:34Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
