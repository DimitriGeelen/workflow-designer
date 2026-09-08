---
id: T-689
name: "Arc-2 isolation proof measures execution and secret but never ledger — one of the three authorities the roadmap column names"
description: >
  Arc-2 isolation proof measures execution and secret but never ledger — one of the three authorities the roadmap column names

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t682-boundary-inventory.py]
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-08T20:41:34Z
last_update: 2026-09-08T20:49:48Z
date_finished: 2026-09-08T20:49:48Z
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

# T-689: Arc-2 isolation proof measures execution and secret but never ledger — one of the three authorities the roadmap column names

## Context

Found while disposing T-681's IW-1, not by a check. Arc 2's clause
(`docs/research/executable-workflow/roadmap-5be23719.md:66`) requires proving the browser/editor
cannot reach **execution / secret / ledger** authority. The shipped inventory measured execution
and secret. Its own module docstring said "mutation, execution, secret" — substituting a fourth
authority of its own invention for the roadmap's third — and ledger was never searched for behind
that substitution.

The omission was compounding: I disposed IW-1 `answered` at confidence 3 on that two-of-three
basis and committed it (`8a5950cf`) before noticing. So the same class of error appeared twice —
once in the instrument, once in the disposition written from the instrument's output.

Measuring ledger then turned up a second, independent defect: the inventory's `/api/save` row
claimed **5** write targets. There are **6**. The sixth is `.context/designer/registry.yaml`,
written via `write_registry` from `sync_registry_after_save` and `claim_ghost_after_save`
(`gallery-serve.py:726,729`). It was missed because T-683's containment work enumerated the
*id-derived* targets — the ones a hostile id can steer — and the registry is a fixed path. That
framing is right for containment and wrong for an authority inventory: the question is what the
editor can **write**, not what an id can **move**.

Deliberately filed as a separate build task rather than patched under T-681, which is an
inception under a recorded GO (Inception Discipline §5).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `LEDGER_PATTERNS` added to `tools/_t682-boundary-inventory.py` alongside the existing
      `EXECUTION_PATTERNS` and `SECRET_PATTERNS`, and the regenerated report carries a
      **§ Ledger authority** section built by the same `scan()` mechanism — so the third
      authority is measured by the same instrument as the other two, not argued in prose.
- [x] The ledger section states what was **searched for** (the pattern list, printed) and what
      was **found** (line numbers), obeying the absence-symmetry rule T-682 established: an
      empty row must be distinguishable from a place nobody looked.
- [x] Every ledger-shaped artifact the server can write is named with its route and its
      containment, specifically `.editor-versions/<id>/index.json` (written by `/api/save`)
      and the ghosts/claims registry (`write_registry`, 3 call sites) — or the report states
      explicitly that a candidate was considered and rejected, with the reason.
- [x] The report distinguishes **ledger authority the editor holds over its own store** from
      **ledger authority over governed records** (`.context/**` append-only registers, audit
      ledgers). These are different claims; conflating them would let a true statement about
      one read as a true statement about the other.
- [x] `python3 tools/_t682-boundary-inventory.py` exits 0 after regeneration (no drift), and
      `--self-test` still exits 0 — the added section must not disable the existing control.
- [x] The ledger scan is proven capable of red: a `--self-test` leg demonstrates the ledger
      section going non-empty / failing when a ledger write is injected. A pattern list that
      has only ever matched zero lines asserts nothing (PL-206).
- [x] T-681's IW-1 disposition updated to state what is now measured, replacing the version
      committed at `8a5950cf` which claimed confidence 3 while one of the three named
      authorities was unsearched.
- [x] Scope recorded: Arc-2's binding clause is roadmap line 66 (execution / secret / ledger).
      Line 254's four-item form (shell / credential / ledger / **action**) belongs to **Arc 4**
      and "action authority" is therefore out of scope here — noted, not measured.

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
         1. Run `bin/fw reviewer T-689`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-689 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
# The inventory regenerates and agrees with the server (no drift), with the ledger section present.
python3 tools/_t682-boundary-inventory.py
# The instrument can move: route deriver red on an added route, ledger scan blinded/planted,
# and the WRITE/READ/DECL classifier pinned against the nested-paren open(...,'w') it once missed.
python3 tools/_t682-boundary-inventory.py --self-test
# The ledger section exists, states its patterns, and separates the two claims.
grep -q "## 4. Ledger authority" docs/reports/T-682-arc-2-boundary-inventory.md
grep -q "Two different claims that must not be conflated" docs/reports/T-682-arc-2-boundary-inventory.md
# Negative leg 1: the save row must NOT still claim 5 targets — that was the undercount.
test 0 -eq "$(grep -c 'WRITES 5 targets' docs/reports/T-682-arc-2-boundary-inventory.md)"
# Negative leg 2: the registry must be named as a save target, not merely mentioned in prose.
grep -q 'registry.yaml' docs/reports/T-682-arc-2-boundary-inventory.md
# Negative leg 3: the ledger row must not be reported as absent. This authority IS present,
# and a zero-match ledger scan means a broken instrument, not a clean bill.
test 0 -eq "$(grep -c 'Ledger authority — ABSENT' docs/reports/T-682-arc-2-boundary-inventory.md)"
# The two sibling Arc-2 controls must not regress behind this change.
python3 tools/_t683-save-containment-verify.py
python3 tools/_t684-mutation-control.py
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

### 2026-09-08 — the task was filed for one omission and found two more

- **What changed:** Filing assumed a single gap: ledger unmeasured. Measuring it surfaced a
  second, independent defect the ledger question had no obvious connection to — the inventory's
  `/api/save` row claimed 5 write targets and there are 6. The sixth,
  `.context/designer/registry.yaml`, is written on both mutating routes. Root cause was not
  carelessness but a frame mismatch: T-683 enumerated the *id-derived* targets, correct for a
  containment fence, wrong for an authority inventory that reused the same list.
- **Plan impact:** The ACs as written covered the ledger section only. Correcting the mutation
  row was added mid-build because leaving it would have shipped a report whose §1 contradicted
  its own §4.
- **Triggered:** No new task — both defects were in scope for one deliverable. PL-323 and FP-019
  recorded; FP-019 names this as the third instance in this arc.

### 2026-09-08 — my own classifier failed in the direction that matters

- **What changed:** The WRITE/READ/DECL tagger I added to make the ledger list legible tagged
  `open(os.path.join(d, 'index.json'), 'w', ...)` as READ. The mode lookahead `[^)]*` halted at
  the paren closing the nested `join(...)` and never reached `'w'`. So a fresh instrument, built
  in a task about under-reporting, under-reported — 4 writes shown where there were 5.
- **Plan impact:** "Add a classifier" turned out to need its own test. An unpinned heuristic
  inside an authority document is the same hazard as the paraphrase that caused the parent bug.
- **Triggered:** Self-test phase 3 added — 7 cases pinning the classifier, including the exact
  nested-paren line that failed.

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
     fw inception decide T-689 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-08T20:41:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-689-arc-2-isolation-proof-measures-execution.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9a8a5c7c
- **Timestamp:** 2026-09-08T20:49:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-08T20:49:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
