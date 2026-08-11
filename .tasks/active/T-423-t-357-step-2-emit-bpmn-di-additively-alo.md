---
id: T-423
name: "T-357 step 2: emit BPMN DI additively alongside aef:position"
description: >
  Second of the three nested increments under T-357's GO. Emit bpmndi (dc:Bounds for shapes, di:waypoint for edges, label bounds) on export while continuing to write aef:position. Additive: no T-225 silent-migration question because nothing the author wrote is rewritten or dropped, and the intent extensions (forceStraight, routingHint, loopDetour) stay, so the spike-3 intent gap does not bite. Costs: all 24 corpus maps change bytes, so AEF's pinned source_bpmn_sha fixtures need a COORDINATED re-pin — this is the first step in the arc that touches the seam. Blocked on step 1 (T-340 option b) landing. NOT blocked on A-020 — that was answered NO at rail 417 (2026-08-03) and is recorded invalidated: AEF never parsed or emitted DI and holds no record of agreeing to. The consequence sharpens this task rather than gating it — with no downstream DI generator on either side of the seam, emitting DI is NET-NEW CAPABILITY on both sides, not the completion of a handoff someone else was already honouring. Nobody is waiting for these bytes, so the re-pin is the whole cost and the benefit is portability to standard viewers (bpmn.io, Camunda), not AEF interop.

status: captured
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: [T-357, T-340, T-424, T-425]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T20:23:27Z
last_update: 2026-08-10T20:31:12Z
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

# T-423: T-357 step 2: emit BPMN DI additively alongside aef:position

## Context

Step 2 of three under T-357's GO (operator, 2026-08-10). Research: `docs/reports/T-357-di-adoption.md`.

**Not started — this task is scoped, not built.** ACs written now because G-020 requires
real criteria before any source edit, and because writing them is what exposes whether the
step is actually ready. It is not: it sits behind T-340's ruling.

Why this is the first step that touches the seam: steps land in strict subset order, and
step 1 (T-340 scoped `b`) is byte-neutral because the two populations are disjoint —
121 of 126 files carry `aef:position` and none carry DI. Step 2 breaks that: **every**
export gains a `bpmndi` sub-tree, so all 24 corpus maps change bytes and AEF's pinned
`source_bpmn_sha` fixtures go red. That is a coordinated re-pin, not a unilateral change.

What A-020's answer changed: there is no DI generator anywhere — not on AEF's side (rail
417: `bpmndi` occurs once in their source, a namespace declaration with no reader or
writer) and not on ours. So emitting DI is net-new capability, and the beneficiary is any
standard viewer (bpmn.io, Camunda), **not** AEF. Nobody is waiting for these bytes. That
removes the urgency and clarifies the trade: pay a two-party re-pin, buy portability.

## Acceptance Criteria

### Agent
- [ ] **Ordering respected: this task does not start until T-340 is ruled and step 1 has
      landed.** Step 2's precedence rule (`aef:position` → else DI) is step 1's deliverable;
      building step 2 first means writing DI that the importer cannot yet read, which is
      the two-contradictory-geometries state PL-114 exists to prevent, self-inflicted.
- [ ] `bpmndi:BPMNDiagram` / `bpmndi:BPMNPlane` emitted on export with `dc:Bounds` for every
      shape, `di:waypoint` for every edge, and label bounds where a label position is
      persisted. Verified by validating one exported map against the BPMN 2.0 DI schema —
      not by grepping for the element names.
- [ ] `aef:position` is **still written**, unchanged, on every node. This is the property
      that keeps step 2 out of T-225's scope: it adds a representation and rewrites nothing.
      A diff of one round-tripped map shows DI added and no existing element removed or
      reordered.
- [ ] The intent extensions (`forceStraight` 12, `routingHint` 22, `loopDetour` 9,
      `anchors` 19, `aef:waypoint` 1) are untouched. Spike 3 established DI has no
      vocabulary for layout *intent*, only for computed results, so DI cannot carry these
      and must not be treated as having replaced them.
- [ ] Round-trip is lossless in both directions: export → re-import → export produces
      byte-identical output on all 24 corpus maps. A DI emitter that is not idempotent
      makes every save a spurious diff.
- [ ] **Re-pin is coordinated, not announced.** AEF's `source_bpmn_sha` fixtures are pinned
      over whole files; all 24 change. Agreed with AEF on the rail BEFORE the bytes change,
      with the new shas supplied as refs (not via `file_send` — OBS-108 is open on their
      side). Evidence: the rail offsets of the request and their agreement.
- [ ] A competing-carrier guard exists, in AEF's shape rather than ours: they pin
      `test_di_drop_has_a_competing_carrier`, which asserts the rival carrier *exists* —
      delete `aef:position` and the test goes red. Our equivalent must fail loudly the day
      step 3 removes `aef:position`, instead of silently permitting two geometries.
      (Adopting their instrument, not just their answer — T-340's Human AC records why.)

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

### 2026-08-10T20:23:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
- **Context:** Initial task creation

### 2026-08-10T20:29:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-08-10T20:31:11Z — status-update [task-update-agent]
- **Change:** status: started-work → captured
