---
id: T-518
name: "uid collision: an externally-assigned aef:uid that equals one the editor would
  mint for a different node"
description: >
  uid collision: an externally-assigned aef:uid that equals one the editor would mint
  for a different node

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t518-uid-collision.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T10:23:02Z
last_update: '2026-08-16T14:33:44Z'
date_finished: 2026-08-15T10:33:27Z
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
  - ts: '2026-08-16T12:34:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 3
      F3: 4
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=3 (prose:routing-defect-class); F3=4 
      (prose:seam-fixture-or-pin); F1=3 (prose:process-conformance)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-518: uid collision: an externally-assigned aef:uid that equals one the editor would mint for a different node

## Context

Closes the first of four gaps `_t515` names in its own `does_not_cover`, and the one I told AEF
at rail 11891 I would pick first if it were my call:

> *"uid collision between an externally-assigned value and one the editor would mint"*

Why it matters to them specifically: mapping standard §6.3 lets AEF assign `aef:uid` externally,
and their reverse renderer keys records on uid. If an external assigner picks a value the editor
would independently mint for a DIFFERENT node, two nodes end up sharing one identity — and a
record-keyed consumer collapses them into one with no error anywhere. That is silent data loss
on their side, caused by a document that looks conformant on ours.

The collision is constructible rather than hypothetical because `deriveUid` is deterministic
(FNV-1a over the seed, T-364): compute what the editor WOULD mint for node B, then hand that
exact value to node A as its external uid.

**This is a measurement task and the ACs must not presuppose the answer.** Whatever the editor
does — both survive, one wins, it renames, it merges — the deliverable is the measured fact plus
a standing guard, not a particular verdict. An AC that required "the editor rejects the
collision" would bias the build toward proving it.

## Acceptance Criteria

### Agent
- [x] `tools/_t518-uid-collision.mjs` measures BOTH collision directions, because reading the
      source before building showed they are not symmetric and testing only the first would
      have produced a green "collisions are handled":
      - **D1 — external value equals one the editor would mint for another node.** Expected
        protected: `usedUids` (designer line 9909) is pre-seeded with every `aef:uid` in the
        document before any derivation runs, so the derived node salts away deterministically.
      - **D2 — two nodes carry the SAME external `aef:uid`.** Neither passes through
        `deriveUid` at all (call site 10090 short-circuits on the attribute), so nothing
        consults or updates `usedUids`. This is the direction with no guard, and the one AEF
        can actually trigger, since §6.3 invites them to assign uids externally.
      - The same asymmetry applies to edges (call site 10274); covered or explicitly excluded.
- [x] The collision is verified to be real BEFORE the probe draws any conclusion — the minted
      value is obtained from the editor's own `deriveUid` path, not reimplemented in the probe,
      and the fixture is asserted to contain the same value twice. A fixture that fails to
      collide is a refusal, not a pass (PL-206: a control fed a stimulus built so it cannot
      fire is worthless).
- [x] The probe drives the real save path (`buildBpmnXml(parseBpmnXml(x))` in the loaded
      designer) and REPORTS the observed behaviour as measured output rather than a pass/fail
      on a presupposed outcome: occurrences of the colliding value after the round-trip,
      distinct uid count, and carrier count before vs after (so an element being dropped is
      distinguishable from a surviving duplicate).
      **Amended during build, deliberately.** As written this AC also asked *which node holds
      which*. That is not deliverable and asking for it was the error: T-513 measured that the
      element `id` is re-minted from lane + x-order + name on every save, so there is no stable
      per-element handle across the operation under test. The first implementation tried it
      anyway and returned artifacts — one lookup `null`, another a different element's uid.
      Counts and set differences answer the actual question without needing one. Recorded here
      rather than silently narrowed.
- [x] A negative control proves the comparator can see a uid change at all, so "no collision
      damage" cannot be produced by a dead comparator (PL-205).
- [x] Exits 2 (refusal, distinct from both pass and fail) when the fixture cannot be made to
      collide or the corpus/browser is unavailable — an unmeasurable run must not read as green.
- [x] Wired into `tests/run-bridge-tests.sh` with a real caller; suite passes, 0 failed.
- [x] Result reported to AEF on the rail, including what it does NOT cover, and stating plainly
      whether this is a defect on our side, a constraint they must honour when assigning uids,
      or a non-issue.

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

timeout 300 node tools/_t518-uid-collision.mjs
grep -q "_t518-uid-collision.mjs" tests/run-bridge-tests.sh
grep -q "_t518-uid-collision.mjs" tools/_t515-external-uid-conformance.mjs

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

### 2026-08-15 — measure both collision directions, not the one the gap statement names
- **Chose:** the probe stages D1 (authored value equal to one the editor would mint) AND D2
  (two carriers with the same authored value), after reading the import path rather than
  building straight from `_t515`'s phrasing.
- **Why:** the source shows the directions are not symmetric. `usedUids` is pre-seeded at
  designer.html:9909, so D1 is guarded; the authored-uid call site short-circuits before
  `deriveUid` is ever entered, so D2 has no guard at all. D1 alone would have gone green and I
  would have reported "collisions are handled" — a control fed a stimulus built so it cannot
  fire, which is PL-206 for the third time this week.
- **Rejected:** testing only the direction `_t515`'s does_not_cover literally names, which is
  what a faithful reading of my own earlier note would have produced.

### 2026-08-15 — key the comparison on counts, never on element id
- **Chose:** every verdict is a count of a specific uid value in the output, or a set
  difference; the minted value is recovered by diffing uid sets rather than by looking up an
  element.
- **Why:** the first version tracked carriers across the round-trip by their owning element's
  `id` and produced pure artifacts — one lookup returned `null`, another returned a different
  element's uid. T-513 measured that the element id is a function of lane + x-order + node name
  and is re-minted on every save. I filed that finding and then keyed a before/after comparison
  on precisely the field the operation under test rewrites.
- **Rejected:** adding a stable marker attribute to the fixture, which would have meant testing
  a document shape the editor never actually receives.

### 2026-08-15 — pin the observed behaviour rather than fail on it
- **Chose:** the probe records D2's duplicate-survives result as a pinned expectation and goes
  red on a CHANGE; it does not fail merely because the duplicate survives.
- **Why:** nobody has ratified what should happen. §6.3 invites external uid assignment and
  states no uniqueness requirement — that silence IS the finding. A standing red would assert a
  preference no standard carries, and a test file is not where a co-designed standard gets
  legislated. A change in behaviour, by contrast, is exactly what AEF needs to hear before they
  build a reverse renderer on it.
- **Rejected:** failing on the duplicate (legislates), and asserting nothing (loses the
  regression signal entirely).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-15T10:23:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-518-uid-collision-an-externally-assigned-aef.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3bc233c2
- **Timestamp:** 2026-08-15T10:33:28Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T10:33:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
