---
id: T-406
name: "readDocComment discards a peer authored doc block whose leading comment opens with our trailer prefix"
description: >
  Third instance of the T-399 authorship-from-prose class, found by that task's census, and it fails in the losing direction. src/aef-workflow-designer.html readDocComment returns null for any LEADING comment whose text starts with DI_TRAILER_PREFIX, on the reasoning that a hand-edit may have hoisted our own boilerplate to the top. A peer authoring to our mapping standard whose rationale opens with those eight words therefore has its doc block silently dropped on import. T-399's instance mislabels a foreign document; this one destroys content, which is the T-347 loss shape arriving from a mechanism we built ourselves. No corpus document triggers it today, which is the same no-live-witness condition under which T-399 sat undetected until the population changed.

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
created: 2026-08-09T09:13:10Z
last_update: 2026-08-09T10:31:43Z
date_finished: 2026-08-09T10:31:43Z
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

# T-406: readDocComment discards a peer authored doc block whose leading comment opens with our trailer prefix

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A leading comment in a document we did NOT produce survives import as the doc block,
      even when it opens with `DI_TRAILER_PREFIX`. Measured through the real editor
      (`parseBpmnXml`), not asserted from source.
      — **Met for a peer that STAMPS its own producer identity** (`STAMPED` case,
      `exporter="camunda modeler"` + the colliding comment → preserved). **Explicitly NOT
      met for an unstamped peer, which is AEF today** — deliberate, argued in `## Decisions`,
      and pinned by the probe's `UNKNOWN` case so the residual cannot be mistaken for
      coverage. It closes when AEF adopt the producer field (recommended at rail 492); no
      further work here closes it.
- [x] The property the suppression exists for is NOT lost: a document we DID produce, with
      our boilerplate hand-hoisted to the top, still has it suppressed rather than promoted
      to rationale. This is the direction that poisoned AEF's corpus, so a fix that only
      satisfies the criterion above has removed the guard rather than repaired it.
      — `OURS` case suppressed; `test_t311_doc_comment_roundtrip.py` green. **This AC did
      real work:** my first fix failed it and the bridge suite caught it (see Decisions).
- [x] Both directions are asserted by ONE probe run, with a control proving the probe
      actually invoked the parser (a probe that never ran reports "preserved" for the same
      reason a working one does).
      — `tools/_t406-doc-comment-provenance-cdp.mjs`, 4/4: control, repair, retained
      property, residual. Plus a PRECONDITION check that the colliding string is still
      present verbatim in AEF's fixture, so the probe cannot quietly degrade into testing
      a straw man of my own writing.
- [x] The known limit is stated in `## Decisions` with its cost named: documents carrying
      no producer identity at all (our own pre-T-399 exports) lose the belt-and-braces. The
      choice of which failure to prefer — silent loss vs visible wrong-promotion — is
      argued, not assumed.
      — argued, and the argument REVERSED mid-task on evidence. See Decisions.
- [x] Bridge suite still green (`0 failed`), and `test_t311_doc_comment_roundtrip.py` in
      particular still passes — it owns the doc-block round-trip this touches.
      — 71 passed, 0 failed, exit 0; geometry 24 clean.

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

# --- T-406 commands ---
# Both directions plus control and residual, through the real parser. Own exit code is
# the verdict, so the errexit note below cannot apply. Exit 2 if its precondition fails.
node tools/_t406-doc-comment-provenance-cdp.mjs
# T-311 owns the doc-block round-trip this touches, and it is what caught my first
# (wrong) fix. Named separately from the suite so a regression here is unmissable.
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
# The suppression must still be gated on identity and not on prefix alone — a revert to
# the unguarded form would leave the probe's OURS/UNKNOWN cases green while re-opening
# the defect for every stamping peer.
grep -q "someoneElsesDocument" src/aef-workflow-designer.html

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

**Symptom:** `readDocComment` returns null for any LEADING comment opening with
`DI_TRAILER_PREFIX`, so a peer whose authored rationale begins with those eight words has
their doc block destroyed on import. No error, no notice.

**Root cause:** the suppression asked "is this our boilerplate?" and answered it from the
comment's TEXT. That is unanswerable from text here, and demonstrably so: the DI comment in
AEF's fixture is byte-identical to the false trailer we shipped for two months — almost
certainly because it was copied from a document we exported. Two parties, one string, and
only provenance separates them.

**Why structurally allowed:** three things.

1. The check was written when the corpus contained only our own output, so "a comment that
   looks like our boilerplate" and "our boilerplate" were the same set. The T-347/T-356/T-372
   intake ended that — the third instance of that shape, after T-359 and T-337, and the
   fourth counting T-399.
2. It was reasoned about as belt-and-braces behind a position rule, which framed its failure
   mode as *redundant safety* rather than as *an independent destructive decision*.
3. **No live witness.** Nothing in either corpus triggers it, so no test could have gone red
   and no user could have reported it. It was found by auditing "where do we infer identity
   from content" — a question, not a symptom. AEF made the sharper version of the point
   (rail 491): the absence of a witness is exactly the condition T-399's own instance sat in
   until the population changed.

**Prevention:** identity now comes from the producer field T-399 added rather than from
content, so the class is answered at its root rather than patched at one site. The probe
pins all four states including the residual, so the boundary is a recorded fact rather than
an assumption. And the finding itself came from a census AC on another task — the practice
that produced it is worth more than this fix: auditing by mechanism found three instances
where auditing by symptom had found one in two months.

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

### 2026-08-09 — suppress unless the document names a DIFFERENT producer (reversed mid-task)

- **Chose:** preserve the leading comment only when the document positively identifies a
  producer that is not us. An UNIDENTIFIED document is still suppressed.
- **Why:** this was the second answer, not the first, and the reversal is the point.
  I initially chose the opposite — suppress only when the document is provably OURS,
  preserving everything unidentified — on the argument that silent loss is worse than
  visible wrong-promotion. **The bridge suite falsified the "visible" half within a minute:**
  `test_t311_doc_comment_roundtrip.py` went red on `hoistedTrailerRefused`. T-311 is not a
  cosmetic UI concern. It is a REAL incident that propagated a false rationale into AEF's
  corpus, and it propagates through save whether or not a human happens to look at the doc
  field — so my "visible failure" was visible only in a place nobody was required to look.
  T-406, by contrast, has no live witness at all: no document in either corpus triggers it.
  Preferring my hypothetical over their measured harm would have been trading a known cost
  for an imagined benefit.
- **Rejected — discriminate on the comment's CONTENT** (exact-match against known trailers
  rather than prefix). Checked, and it cannot work: the DI comment in AEF's fixture is
  **byte-identical** to the false trailer we shipped for two months. There is no string test
  that separates them, which is the whole reason identity is required here.
- **Rejected — preserve everything unidentified** (my first answer). Above.
- **Residual, stated rather than buried:** AEF do not stamp a producer identity (rail 491),
  so their documents remain affected. The fix works for every peer that identifies itself —
  Camunda, bpmn-js, and AEF if they adopt the field. **This is not closable from our side**,
  and the probe's `UNKNOWN` case pins it so it reads as a known boundary rather than as
  coverage. Recommendation sent at rail 492.

### 2026-08-09 — the probe reads the colliding string from AEF's fixture, not from my memory

- **Chose:** assert as a precondition that the colliding string is still present verbatim in
  `tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn`, and exit 2 if not.
- **Why:** the whole hazard is that a specific real string collides with ours. A probe
  carrying its own retyped copy would keep passing after the fixture changed, testing a
  straw man I had written for myself — the failure PROVENANCE.md names in its own words
  ("a population built by imagining what real input looks like is the same defect one level
  up").
- **Note on fixture provenance:** the four probe documents ARE synthetic minimal
  `<definitions>` elements, and the file says so. Offered to AEF at rail 492 that they
  author the adversarial one, since input from the party who would actually write it beats
  input I imagine them writing.

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

### 2026-08-09T09:13:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-406-readdoccomment-discards-a-peer-authored-.md
- **Context:** Initial task creation

### 2026-08-09T10:24:11Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fe9836cf
- **Timestamp:** 2026-08-09T10:33:13Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T10:31:43Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
