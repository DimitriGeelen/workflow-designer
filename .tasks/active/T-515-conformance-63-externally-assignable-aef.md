---
id: T-515
name: "conformance 6.3 externally-assignable aef-uid is unguarded"
description: >
  conformance 6.3 externally-assignable aef-uid is unguarded

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
created: 2026-08-15T09:36:37Z
last_update: 2026-08-15T09:36:37Z
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

# T-515: conformance 6.3 externally-assignable aef-uid is unguarded

## Context

`aef-bpmn-mapping-v1.md` §6 lists four conformance requirements. Requirement **3** is:

> *"It carries a stable, externally-assignable `aef:uid` on every node and edge (§5)."*

and §5 states the property AEF's reverse path is built on:

> *"`aef:uid` is **externally assignable** — the reference editor's import path honors
> arbitrary `aef:uid` values, so a reverse renderer needs no editor change for identity."*

That last clause is a claim **about our editor**, written in a co-designed standard, that
licenses AEF to build a reverse renderer without asking us for anything. `T-182` built
`tests/test_mapping_standard_conformance.py` — but it guards **§2 only**, the frozen
governance meta-key list. Requirement 3 has no machine check on either side.

T-513 measured the case where `aef:uid` is **absent** (it gets minted, deterministically).
It did not measure the case where a uid is **present and not ours** — an AEF-shaped
`T-042` rather than an editor-shaped `n_0fa0f56f`. Those are different code paths:
absent takes the FNV-1a derivation branch, present takes the honour-what-you-were-given
branch, and only the second is what §5 promises AEF.

This is the same shape as T-511 and T-513 — a claim a peer project depends on, with
nothing re-checking it — except this one is written into a standard rather than a rail
post, which makes it worse rather than better: a standard reads as settled.

Arc: `designer-authoring-surface`, the reverse half of the headline mechanic.

## Acceptance Criteria

### Agent
- [x] A probe round-trips a document whose `aef:uid` values are all **externally assigned
      and AEF-shaped** — task ids on nodes (`T-042`), deterministic-hash ids on edges per
      §5 — through the real save path, and asserts every one comes back byte-identical.
      Nodes AND edges, because §6.3 says "every node and edge" and they are emitted by two
      different code paths.
      → `tools/_t515-external-uid-conformance.mjs`. **27 externally-assigned uids —
        14 nodes (`T-4200`…), 13 edges (`AEF-DEP-1000`…) — `missing: []`, and
        `unexpected: []`, which is the separate claim that the editor minted none of its
        own alongside them.** Built by externalising a live corpus map (`arc-lifecycle`)
        rather than authoring one, so the structure around the uids is one the editor
        round-trips today and identity is the only thing changed.
- [x] Anti-vacuity: the probe REFUSES if the fixture's uids are editor-shaped (`n_…`/`e_…`
      with hex), since those would be indistinguishable from values the editor could have
      minted itself, and the whole question is whether it honours values it did NOT mint.
      → rc 2 with a named reason. A second refusal covers the other vacuous shape: a corpus
        map carrying zero node uids or zero edge uids cannot test "every node AND edge",
        so it refuses rather than passing over an empty half.
- [x] Idempotence: a second round-trip is byte-identical to the first. §5's reverse clause
      promises "re-rendering the same record is byte-stable"; an editor that honours a uid
      once but perturbs the document on every save breaks the reverse path just as surely.
      → `idempotent: true`, 12385 bytes both times.
- [x] Negative control cutting on the SAME identity the comparator reads (PL-205, PL-206):
      one externally-assigned uid is altered in the output and the comparator MUST report
      it — and the stimulus must actually differ in the compared field, not merely somewhere
      in the file.
      → victim `T-4200`, `stimulus_really_differs: true`, `fired: true`. The
        `stimulus_really_differs` leg is PL-206 applied on the day it was filed: it asserts
        the mutation changed the *parsed uid list*, not just some bytes in the file.
- [x] Anti-overfit: a benign edit leaves the verdict green.
      → nudging one `aef:position` by 7px — presentational-only, a task-graph no-op under
        §6.4 — leaves the uid set unchanged. `quiet: true`.
- [ ] Whatever the answer, it is reported to AEF with producer attribution. If it passes,
      §6.3 is a claim they can now rely on with a named guard behind it; if it fails, they
      are told before they build on it.
- [x] Wired into `tests/run-bridge-tests.sh` so the guarantee is re-checked rather than
      remembered.
      → suite **84 passed / 0 failed**.
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

# The probe's own exit code is the verdict: 0 only when every externally-assigned uid
# survived on nodes AND edges, the second round-trip was byte-identical, and both controls
# fired. Single command — a chained line would be judged on its last segment alone (T-352).
timeout 300 node tools/_t515-external-uid-conformance.mjs > /dev/null

# Wired, so §6.3 is re-checked rather than remembered.
grep -q '_t515-external-uid-conformance.mjs' tests/run-bridge-tests.sh

# The fixture is BUILT by externalise() rather than authored, so there is no literal to
# grep. What must be pinned instead is the runtime refusal: if a later edit weakens
# externalise() so editor-shaped uids survive into the fixture, the probe must REFUSE rather
# than pass, because it would then be measuring the editor against values it could have
# minted itself — the one case §5 promises nothing about. This asserts the refusal exists.
grep -q 'fixture still contains editor-shaped uids after externalising' tools/_t515-external-uid-conformance.mjs

# §6.3 says "every node AND edge". A corpus map with zero of either cannot test it, and the
# probe must refuse rather than report a pass over an empty half.
grep -q 'cannot test it' tools/_t515-external-uid-conformance.mjs

# The negative control must cut on aef:uid — the field the comparator reads (PL-205).
grep -q 'NEGATIVE CONTROL CUTS ON aef:uid' tools/_t515-external-uid-conformance.mjs

# The standard this task reads must be byte-identical to its committed state — it is frozen
# under agent control and this task only measures against it.
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md

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

### 2026-08-15T09:36:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-515-conformance-63-externally-assignable-aef.md
- **Context:** Initial task creation
