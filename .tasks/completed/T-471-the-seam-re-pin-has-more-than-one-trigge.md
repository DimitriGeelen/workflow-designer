---
id: T-471
name: "The seam re-pin has more than one trigger and I named only the blocked one to AEF"
description: >
  Rail 581 asked AEF what a coordinated re-pin costs them, attributing the trigger to T-423 (arc step 2, emit BPMN DI) — which is BLOCKED behind T-340's ruling. T-101 (started-work, horizon now, NOT blocked) runs cleanLayout() over the same 24 examples/aef-processes/rendered/*.bpmn and mirrors to build/gallery/rendered/. Same bytes, unblocked, could land first. Measure the full inventory of active work that moves seam-exposed corpus bytes, then correct the rail post so AEF is costing the right change. Does not run T-101 or T-423.

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
created: 2026-08-12T20:25:45Z
last_update: 2026-08-12T20:29:16Z
date_finished: 2026-08-12T20:29:16Z
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

# T-471: The seam re-pin has more than one trigger and I named only the blocked one to AEF

## Context

Full analysis: `docs/reports/T-471-seam-repin-trigger-inventory.md`.
Rail correction posted at **offset 582** (reply to 581).

Rail 581 asked AEF to cost a coordinated re-pin and attributed the trigger to **T-423** —
which is blocked behind T-340 and cannot move a byte. Measured across all active work
rather than just the arc, T-423 is the only one of three triggers that *cannot* fire:

| task | change kind | can fire now? |
|---|---|---|
| **T-101** | moves bytes on all 24 rendered maps (`cleanLayout()` + gallery mirror) | **yes** — `started-work`, `now`, unblocked |
| **T-423** | moves bytes (DI emission) | no — blocked on T-340 |
| **T-443** | **path identity** — renames `tests/fixtures/aef-bpmn/` | no — blocked on AEF's DM 548 §5 |

**T-041 read like a trigger and is not** — its rendered artifact already exists and its
Agent AC is checked; only the operator's fidelity verdict remains. Checked rather than
assumed, which is the only reason it is not in the table above.

**Two threads, one corpus.** T-443's stated trigger is "AEF answers DM 548 §5", so the rail
was carrying 548 §5 (may the path be renamed?) and 581 (what does a re-pin cost?) as if
they were unrelated conversations about different files. Linked at 582.

### The finding that did not reach its own instrument

T-469's headline was that a shell glob does not descend, and had hidden
`t257-eventdef-roundtrip/` from its corpus count (18→20). **The verification leg written in
that same task then pinned the corpus with the same glob** — 42 of 47 paths. The five it
missed: both halves of the round-trip pair T-469 had just called the most seam-relevant
artifact in its analysis, `PROVENANCE.md`, and two READMEs.

The prose was corrected; the instrument was not. The stopping point is legible in
hindsight — once the sentence reads correctly the finding *feels* discharged, and the guard
written three sections later inherits the habit rather than the correction. Sibling of
PL-169 (anchor on structure, not on a string prose may contain): both are cases where the
fix landed in the narrative and not in the mechanism. T-471 pins the recursive form,
`882ce395ad5d00b6` over 47 paths.

**Scope boundary:** nothing here runs T-101, starts T-423, or renames anything. Legs 1–4
pin both corpora and the two standards as unchanged, so this task cannot quietly become the
change it describes.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The trigger inventory is measured over ALL active work, not just the arc.** Rail
      581 named T-423. The question "what else, right now, would move bytes AEF may pin"
      is answered by scanning every active task against both corpora — the T-469 analysis
      scoped itself to the arc, and an arc-scoped answer to a seam-wide question is the
      same category error as the T-466 five-blockers claim.
- [x] **Each candidate is classified MOVES-BYTES vs MENTIONS-ONLY, by reading it.** A task
      naming a path is not a task writing to it. The classification is stated per task
      with the evidence line, so a later reader can check the call rather than inherit it.
- [x] **Path-identity changes are looked for separately from byte changes.** A rename or
      relocation of `tests/fixtures/aef-bpmn/` breaks a path named NORMATIVELY in a frozen
      two-party standard — a different and larger seam event than bytes moving underneath
      a stable path. Byte-diffing cannot see it.
- [x] **The rail correction is posted, and it corrects rather than supplements.** AEF is
      currently costing a change attributed to a blocked task. The post states plainly
      that the attribution was wrong and gives the corrected inventory, with producer
      attribution metadata (T-420 gate).
- [x] **No corpus byte is written and no blocked task is started.** T-101, T-423 and any
      rename remain exactly as they are; this task measures and communicates only. The
      pre-task tree hash of both corpora is pinned in Verification so this cannot silently
      become the change it is describing.
- [x] **Where the inventory changes T-469's conclusions, T-469's document is corrected in
      place** rather than left to read as current. Its §4 asks AEF four questions on a
      premise this task may narrow.

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

# Rail correction posted at offset 582 (reply to 581), producer attribution present.
#
# Leg 1 pins the corpora RECURSIVELY (47 paths), not by `*.bpmn` glob. T-469 pinned the
# glob form — 42 paths — and the 5 it missed were the round-trip pair it had just called
# the most seam-relevant artifact in its own analysis, plus PROVENANCE.md. The glob is the
# construct T-469's headline finding is ABOUT, and it survived into that task's own leg.
# Leg 2 is the denominator (PL-084): without it, leg 1 stays green if both directories are
# deleted, since a hash over nothing is stable.

test "$(git ls-files -s examples/aef-processes/rendered tests/fixtures/aef-bpmn | sha256sum | cut -c1-16)" = "882ce395ad5d00b6"
test "$(git ls-files examples/aef-processes/rendered tests/fixtures/aef-bpmn | wc -l)" = "47"
git diff --quiet HEAD -- examples/aef-processes/rendered tests/fixtures/aef-bpmn
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md docs/standards/aef-bpmn-forward-compile-v1.md
test "$(/usr/bin/grep -cE '^\| \*\*T-(101|423|443)\*\* \|' docs/reports/T-471-seam-repin-trigger-inventory.md)" = "3"
/usr/bin/grep -q 'path identity' docs/reports/T-471-seam-repin-trigger-inventory.md
/usr/bin/grep -q '^## 5. Correction 2026-08-12 (T-471)' docs/reports/T-469-t423-seam-repin-blast-radius.md
test -f examples/aef-processes/rendered/inception-review.bpmn
/usr/bin/grep -q '^status: started-work' .tasks/active/T-101-bake-clean-layout-into-the-rendered-corp.md

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

### 2026-08-12T20:25:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-471-the-seam-re-pin-has-more-than-one-trigge.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0bd6aabe
- **Timestamp:** 2026-08-12T20:29:17Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T20:29:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
