---
id: T-414
name: "Leading rationale following our DI trailer is destroyed on import: suppression
  keys on the prefix rather than on the comment being nothing but the trailer"
description: >
  Leading rationale following our DI trailer is destroyed on import: suppression keys
  on the prefix rather than on the comment being nothing but the trailer

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t414-mutation-check.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T15:26:10Z
last_update: '2026-08-16T13:57:22Z'
date_finished: 2026-08-09T15:30:29Z
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
  - ts: '2026-08-16T12:33:57Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-414: Leading rationale following our DI trailer is destroyed on import: suppression keys on the prefix rather than on the comment being nothing but the trailer

## Context

Found by T-413, running AEF's own fixture bytes (their `4f9a42926`, delivered on the rail
at 504/505) through `tools/_t406-doc-comment-provenance-cdp.mjs`.

`readDocComment` (src/aef-workflow-designer.html:9500) suppresses a leading comment when it
*starts with* `DI_TRAILER_PREFIX` and the document does not name a different producer. A
comment that opens with our eight words and then carries seven lines of genuine rationale
satisfies that test, so the rationale is destroyed on import. AEF's real
`aef-task-lifecycle/v1.bpmn` is the witness; they measured the same loss on their own side
and fixed it as their T-2895.

The fix is on the **shape** axis, not the identity axis: suppress only when the leading
comment is *nothing but* the trailer. Prefix matching stays, because the tail genuinely
drifts — three wordings are live in AEF's corpus.

T-406 chose producer identity as the discriminator and was right that no test on the eight
words can separate the two producers. What it missed is that the eight words are not the
whole comment: what separates a false rationale from a real one is whether anything
*follows* them. That question needs no provenance at all, which is why AEF's narrowing
works on both sides of the seam and my gate works only on mine (their rail 501).

## Acceptance Criteria

### Agent
- [x] Suppression narrowed to "the leading comment is nothing but the trailer" — one
      non-blank line, still matched by prefix so the drifting tail keeps matching
- [x] The T-311 property is retained: our own boilerplate hoisted to the top of a document
      with no other content is still suppressed, on both the OURS and the UNSTAMPED branch
- [x] `_t406-doc-comment-provenance-cdp.mjs` green on all six legs, AEF-INCIDENTAL now
      preserving, against live src
- [x] A seventh leg pins the junk-line decision: OUR OWN document, trailer plus real
      rationale in one block, is PRESERVED — with the junk trailer line left visible rather
      than edited out. Content loss is the defect class; a tidier version of it is still it
- [x] The recovered doc comment is verified to contain the peer's actual rationale text
      (`designer-corpus D1 (arc-014, T-2555)`), not merely to be non-empty — a gate that
      only checks non-emptiness passes on a truncated recovery
- [x] The residual is stated in the source where the rule lives: rationale prepended on the
      SAME line as the trailer still suppresses, and is not resolvable from text alone
- [x] Round-trip unaffected: our own export still emits the trailer and still reads back
      with no doc comment (no new false rationale enters the corpus)

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
# --- T-414 ---
# The probe's own exit code IS the verdict here, so no chaining and no context question.
node tools/_t406-doc-comment-provenance-cdp.mjs
# All seven legs ran. A probe that silently lost the two new cases would still exit 0.
node tools/_t406-doc-comment-provenance-cdp.mjs > .context/working/t414-probe.out 2>&1 && test "$(grep -c 'branch:' .context/working/t414-probe.out)" = "7"
# The legs are known to be capable of failing, and only on this change.
bash tools/_t414-mutation-check.sh
# T-311's property is not collateral damage: our own trailer still refused on round-trip.
node tools/_t311-doc-comment-roundtrip-cdp.mjs

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** A leading comment opening with `BPMN DI (visual layout) omitted` and continuing
with real rationale lost the entire block on import. Witness: AEF's real
`aef-task-lifecycle/v1.bpmn`, seven lines of authored rationale, gone silently.

**Root cause:** `readDocComment` tested `data.trim().startsWith(DI_TRAILER_PREFIX)`. The
eight words are a prefix of the trailer *and* a prefix of a rationale that merely begins
with them. The predicate answered "does this comment begin like our boilerplate" and was
read as "is this comment our boilerplate".

**Why structurally allowed — the interesting part.** T-406 asked the right question ("can
this comment be told from our trailer?"), concluded correctly that no test on the eight
words can do it, and reached for producer identity. That reasoning is sound and it is also
where the miss lives: *the eight words are not the whole comment*. What separates a false
rationale from a real one is whether anything **follows** them — a question with no
provenance in it at all.

The test matrix then hid it. T-413's branch column disproved the obvious theory that the
unstamped branch was untested: two of four legs ran through it. Every leg carried a comment
that was either *nothing but* the trailer or had *no* trailer; the mixed shape appeared on
no leg at any branch. **The hole was not an untested branch, it was an untested axis, and
coverage of the branch is exactly what made it invisible.**

Same shape as AEF's L-560 (a detector's scope note reads as coverage) and T-411's PL-132 (a
schema's field presence reads as content), one layer over again: a branch's presence in the
matrix reads as coverage of that branch's behaviour, when the behaviour varies on a
dimension the matrix holds constant.

**Prevention:**
- The rule now keys on comment shape, which needs no provenance and therefore works on both
  sides of the seam — AEF shipped the same narrowing independently as their T-2895.
- Two new probe legs, one of them real peer bytes rather than a document we synthesized to
  be convenient for ourselves.
- `tools/_t414-mutation-check.sh` reverts the fix on a copy and asserts both new legs go red
  *and* the five pre-existing ones stay green — so the legs are known to bite, and known to
  bite on this change rather than on collateral damage.
- Preserve-legs assert the recovered **text**, not non-emptiness: a truncation back to the
  trailer line would satisfy a non-empty check while losing everything the fix protects.

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

### 2026-08-09T15:26:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-414-leading-rationale-following-our-di-trail.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-074c5bd7
- **Timestamp:** 2026-08-09T15:30:35Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T15:30:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
