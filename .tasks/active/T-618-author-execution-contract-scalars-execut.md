---
id: T-618
name: "author execution contract scalars: execution, verify, idempotent on task-like nodes"
description: >
  author execution contract scalars: execution, verify, idempotent on task-like nodes

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
created: 2026-08-27T12:35:29Z
last_update: 2026-08-27T12:37:53Z
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

# T-618: author execution contract scalars: execution, verify, idempotent on task-like nodes

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
Authorised by T-617's GO decision (2026-08-27T12:34:03Z). Scope is the AUTHORING half only:
the three scalars become editable fields and survive a save/load round trip. Nothing in this
task executes anything — IW-3 (what a recovery agent may DO at runtime) is unresolved, and
until it is, a runtime that acts on these fields would be unsafe. Fields are inert metadata here.

SCOPE CORRECTED BY MEASUREMENT. The field is NOT invented — it is authored. Census of
`examples/*/*.yaml`: `determinism` appears on **207 nodes across 24 workflow files**, values
`deterministic` (161), `stochastic` (39), `human` (7). `sideEffect` appears **39** times.
The editor mentions `determinism` in exactly two places, both COMMENTS (`src/…:5287`, `:9798`)
— it is in no `AEF_FIELDS` list, so the operator cannot see or edit any of the 207 values.
Pre-T-570 the editor silently DESTROYED them on save; post-T-570 it carries them invisibly.

- [x] `determinism` is offered as an editable field with the corpus vocabulary
      (`deterministic` | `stochastic` | `human`) — the existing key and existing values, not
      an invented `execution` axis. Rendered as `special: 'select'` over exactly those three,
      so the vocabulary is constrained rather than free text.
- [x] It is offered on the node types the CORPUS actually annotates — all 7:
      `scriptTask` 105, `serviceTask` 42, `startEvent` 19, `exclusiveGateway` 19,
      `userTask` 13, `endEvent` 13, `subProcess` 4. Events and gateways included, which a
      task-like-only guess (my first draft of this AC) would have missed.
- [x] `sideEffect` is offered as an editable field (40 authored uses, 3 task-like types)
- [x] `metaKeys` count is UNCHANGED (20) — measured, list unchanged, neither new key present.
      T-570's carriage (`carriedKeys`, `src/…:9837`) round-trips any scalar outside
      `scalarHandled`, so nothing is ratified with 999-AEF and
      `docs/standards/aef-bpmn-mapping-v1.md` is untouched (`git status docs/standards/` clean)
- [ ] Round trip verified on a real corpus file: `customer-refund.bpmn` imported, exported,
      and re-imported yields all 8 of its `determinism` values unchanged on the same node ids
      NOT TICKED, AND NOT VERIFIED. `tools/_roundtrip-serialization-cdp.mjs` returns
      `pass: true` on that fixture, but its fixed point projects a FIXED 36-key `KEYSPEC`
      that does not contain `determinism` — the green is adjacent to the change, not over it.
      Growing `KEYSPEC` was rejected here: `METAKEYS` is derived from it (`:134`) and a key
      that rides carriage rather than the whitelist would show up as a denominator orphan,
      i.e. reshaping the shared instrument to score this task's own change. Needs its own
      harness. Carried to a follow-up rather than ticked on adjacent evidence.
- [x] No new BPMN node type is introduced, and no new key is invented in this task
- [x] A guard script proves the above and is proven to go RED before it is trusted GREEN.
      `tools/_t618-determinism-census.py`, two independent arms both demonstrated:
      (a) reverting `exclusiveGateway` alone → red on that one type (partial fix caught);
      (b) deleting the `determinism` FIELD_META entry → red naming the TypeError.
      Arm (b) guards the defect this task nearly shipped: `AEF_FIELDS` → `FIELD_META` is
      dereferenced unguarded at `src/…:5936`, so a field added to one list and not the other
      takes the whole properties panel down for that node type. The guard asserts the
      RELATION over every field, not a count, and not only the two fields touched here.

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

python3 tools/_t618-determinism-census.py
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_bridge_field_coverage.py
python3 tests/test_designer_export_contract.py
python3 tests/test_designer_render.py
python3 tests/test_editor_behavior.py
git diff --quiet -- docs/standards/ && echo "frozen standard untouched"

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

### 2026-08-27T12:35:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-618-author-execution-contract-scalars-execut.md
- **Context:** Initial task creation
