---
id: T-809
name: "Corpus conformance census for the frozen governance meta-keys (F-06)"
description: >
  Value review T-742 finding F-06: the frozen standard says a conformant editor MUST emit horizon, workflowType, tier and agentType on task-like nodes, and tests/test_mapping_standard_conformance.py reports OK exit 0 while comparing KEY LISTS and never opening a corpus document. Re-measured per-node: horizon 0/165, workflowType 0/165, tier 74/165, agentType 17/165 — all four short, not the two the review recorded. Build the check that opens the documents. Whether the corpus must comply or the standard should change is the operator's ruling (sovereign, SQ 12-Q3) and this task does not make it.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t809-census-controls.sh, tools/_t809-frozen-meta-census.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T12:58:14Z
last_update: 2026-09-22T13:04:17Z
date_finished: 2026-09-22T13:04:17Z
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

# T-809: Corpus conformance census for the frozen governance meta-keys (F-06)

## Context

Value review T-742 finding **F-06**. The frozen standard, `docs/standards/aef-bpmn-mapping-v1.md`
§2: *"A conformant editor MUST emit each on task-like nodes, and the bridge MUST round-trip
each"* — `horizon`, `workflowType`, `tier`, `agentType`.

`tests/test_mapping_standard_conformance.py` prints *"OK: all 4 frozen governance meta-keys …
present in both editor metaKeys and bridge META_KEYS"* and exits 0. **It compares two Python
lists.** Confirmed by grep and by running it: neither it nor `test_editor_bridge_meta_parity.py`
opens a corpus document. So a MUST about what is *emitted* has never been mechanically checked.

Second recorded instance of that shape here. The first is in
`test_editor_bridge_meta_parity.py`'s own docstring: green for **47 days** while nine keys were
destroyed on every save, *"because check() was never looking (PL-034)"*.

**Measured per node, all four keys are short — the finding said two.** See Decisions.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A census instrument OPENS every corpus document and counts, per frozen key, how many task-like nodes carry it — the thing `test_mapping_standard_conformance.py` does not do
- [x] It parses XML rather than grepping: a bare `grep tier` matches prose and attribute values in unrelated elements, and the first measurement of this finding was wrong for exactly that reason
- [x] A ratchet baseline records coverage as found. Coverage may RISE freely; a FALL exits non-zero (the T-560 pattern, direction inverted because here the number is the good thing)
- [x] CANNOT-MEASURE IS NOT A PASS: a parse failure, a missing corpus, or zero task-like nodes found exits non-zero rather than reporting clean
- [x] CONTROL: the ratchet is proven to FAIL on a regression, by actually stripping a key from a throwaway copy of the corpus
- [x] CONTROL: the census is proven to SEE a key it should — a node given the key in a throwaway copy raises the count
- [x] The frozen standard is NOT edited, and no corpus file is modified — the ruling on which side must move is the operator's (SQ 12-Q3)
- [x] The finding's own numbers are corrected where measurement disagrees with them, rather than restated


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-809 legs. Each line's exit code is its own verdict; no chaining. ---
python3 tools/_t809-frozen-meta-census.py
test -s tools/_t809-frozen-meta-baseline.txt
# The frozen standard must be byte-unchanged by this task. Controlled: the file must EXIST,
# so a path typo cannot read as "no diff" (grep exit 2 vs 1, the T-804 confusion).
test -f docs/standards/aef-bpmn-mapping-v1.md
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md
git diff --quiet HEAD -- examples/aef-processes/rendered/
# The controls live in their own probe (four branches: ratchet has teeth / census is not
# vacuous / empty corpus fails / untouched corpus passes). One leg, because a three-line
# inline mutant is unreadable and an unreadable leg is one nobody maintains.
./tools/_t809-census-controls.sh
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

### 2026-09-22 — A ratchet, deliberately not a conformance gate

- **Chose:** a census that parses the corpus and ratchets per-key node coverage. Coverage may
  rise freely; a fall exits non-zero.
- **Why:** F-06's recommendation is explicit that the *check* is the finding and the *ruling*
  is not: *"Do not weaken §2 to make the corpus conformant — whether the corpus must comply or
  the standard should change is sovereign → §12 Q3."* A ratchet makes the condition mechanically
  visible and stops it widening, without deciding which side moves.
- **Rejected — a pass/fail conformance gate:** it would be red from the first run, and a gate
  that is permanently red is one the next reader switches off. The corpus is not *defective*
  until the operator rules; it is non-conformant with a standard whose applicability is open.
- **Rejected — mass-editing the corpus to add the keys:** that would settle the sovereign
  question by action. 165 nodes across 24 files, and the values are governance data
  (`horizon`, `workflowType`) that nobody has authored — I would be inventing them.
- **Rejected — relaxing §2:** the frozen standard is not editable under agent control at all.

### 2026-09-22 — the anti-vacuity control failed first, and it was the control that was wrong

- **What happened:** Control B asserts the census can SEE a key that is present — without it, a
  census that counted *nothing* (wrong namespace, wrong element list, a typo in the key names)
  would pass the regression and empty-corpus branches for free and sit in the suite looking like
  a guard forever. Its first draft injected `horizon` into the first `<aef:meta>` in a file.
  That landed on a `<bpmn:startEvent>`, which is not task-like, so the census correctly ignored
  it and the control went red.
- **The census was right; the stimulus was wrong.** PL-206, second instance: *"a control that
  CAN fail is still worthless if its STIMULUS was built so it never fires."* Here the stimulus
  fired into a place the subject does not look.
- **Fix:** the injection is anchored to a task-like open tag, and the branch fails loudly if it
  cannot find one — so a future corpus without such a node reports *"could not find a task-like
  node to inject into"* rather than quietly passing.
- **Worth recording because the failure was the useful part:** had Control B been written to
  pass first time, it would have proved nothing and I would not have learned that the injection
  point and the counting point must be the same kind of node. A green control on the first run
  deserves suspicion, not satisfaction.
- **Also why the controls moved into `tools/_t809-census-controls.sh`:** they began as inline
  `bash -c` one-liners in the Verification block. At three nested quoting levels they were
  unreadable, and an unreadable leg is one nobody maintains or trusts — the same decay that
  produced the 118 uncallable instruments in `tools/` (F-08).

### 2026-09-22 — The finding's own numbers were wrong, and I corrected them

- **Chose:** re-measure by parsing XML, and write the correction into the value review itself.
- **What was wrong:** F-06 recorded `tier` 74 occ / 14 files **✓** and `agentType` 17 / 7 **✓**,
  concluding two keys failed. Those are *occurrence* and *file* counts; the MUST is
  **per task-like node**. Parsed per node: `horizon` 0/165, `workflowType` 0/165,
  `tier` **74/165**, `agentType` **17/165**. **All four are short.** The "306 nodes" figure was
  the `aef:position` count, not task-like nodes — there are 165.
- **Why grep produced it:** bare `grep tier` matches prose and unrelated attribute values. My
  own first pass hit this too, and a wrong namespace URI on the second, before the third
  measurement agreed with itself.
- **Why correct the report rather than only the task:** the review is not archived, and T-803
  established that the document which introduced an error is the one to fix. The conclusion and
  the recommendation are unchanged — the gap is simply larger than stated.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-809 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T12:58:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-809-corpus-conformance-census-for-the-frozen.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6d562b63
- **Timestamp:** 2026-09-22T13:04:19Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T13:04:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
