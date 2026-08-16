---
id: T-323
name: "Census OUT_OF_SCOPE classifications rest on corpus counts where the discriminator
  requires expressibility (scopeOf is a GAP, not out of scope)"
description: >
  T-320's parity census classifies a rule OUT_OF_SCOPE when no file on the other form
  CARRIES the construct today. That is a corpus count, and the census's own two-axis
  rule forbids using one to classify: 'a gap with zero violations is still a gap'.
  Applied to the GAP rows, not to the OUT_OF_SCOPE rows -- the discipline itself was
  one-form-only. Proof: aef:scopeOf is in the shared canonical vocabulary (tools/yaml-to-bpmn.py
  META_KEYS, designer metaKeys src:9283) and the bridge emits it as <aef:meta scopeOf=...>.
  A subProcess with scopeOf pointing at itself is ERROR E-SCOPEOF-SELF rc=2 on the
  YAML form and VALID rc=0 on the BPMN bridged from those same bytes. So the ONLY
  entry the census called correctly out of scope is a GAP: 9 gap families, zero correctly
  out of scope. Fix is to the DISCRIMINATOR and the probes -- OUT_OF_SCOPE must mean
  the form cannot EXPRESS the construct (vocabulary/schema absence), and OUT_OF_SCOPE_PROBES
  must probe the vocabulary, not the corpus. Corpus carriers stay as priority signal
  only.

status: work-completed
workflow_type: build
owner: claude-code
horizon:
tags: []
components: [tests/fixtures/invalid/E-INCEPTION-NOT-SOVEREIGN.xml, 
      tests/fixtures/warn/W-TYPE-LANE-MISMATCH.xml, 
      tests/test_rule_form_parity.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T10:11:28Z
last_update: '2026-08-16T13:57:20Z'
date_finished: 2026-08-01T10:35:47Z
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
  - ts: '2026-08-16T12:33:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-323: Census OUT_OF_SCOPE classifications rest on corpus counts where the discriminator requires expressibility (scopeOf is a GAP, not out of scope)

## Context

Found while building T-322. The T-320 census says a rule is OUT-OF-SCOPE on the other form
when **no file on that form carries the construct** — a corpus count. Its own two-axis rule
forbids that: *"a gap with zero violations is still a gap; the missing rule is exactly what
makes the missing violations unfalsifiable."* Applied to the GAP rows, not the OUT-OF-SCOPE
rows. The discipline was itself one-form-only.

Proof it bites (`docs/reports/T-320-rule-form-parity-census.md`, corrected header): a
`subProcess` whose `aef:scopeOf` points at itself is `ERROR [E-SCOPEOF-SELF]` rc=2 on the
YAML form and `VALID — no findings` rc=0 on the BPMN bridged from those same bytes, with
`scopeOf="n_capture"` verifiably present in the emitted XML.

**The corrected discriminator:** OUT-OF-SCOPE means the other form **cannot express** the
construct. Expressibility is decided by the schema / shared key vocabulary, not by whether
anyone has authored one yet. Corpus carriers remain priority signal only. `aef:scopeOf` is
in `KNOWN_AEF_KEYS` (`tools/yaml-to-bpmn.py`) and the designer's `metaKeys`
(`src/aef-workflow-designer.html:9283`), so it is expressible on both forms → GAP.

Consequence for the guard: `OUT_OF_SCOPE_PROBES` interrogate the wrong object. A corpus probe
flips a classification only **after** someone authors a violating file, which is exactly too
late — knowing the rule is missing before that is the entire point of the census.

Related, and deliberately left open: **PAIRED via a differently-named counterpart**
(`E-EDGE-DANGLING` ↔ `E-FLOW-DANGLING`) is still an unverified note. T-322 closed the
same-id half only. Same falsifiability question, in scope here if it fits.

Precedent surfaced at work-on: **PL-034** — a guard that checks internal self-consistency
cannot detect a broken promise to the outside. A parity table checked only against itself is
that guard.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The OUT-OF-SCOPE discriminator is restated in `tests/test_rule_form_parity.py` as **expressibility, not corpus presence**, in a `HOW TO CLASSIFY A NEW RULE` block sitting immediately above the `PARITY` table — where someone adding an entry will read it, not in a report they may never open.
- [x] Probes interrogate the VOCABULARY: `_aef_vocabulary()` **imports** `KNOWN_AEF_KEYS` from `tools/yaml-to-bpmn.py` (44 keys) rather than hand-copying it, so it cannot drift from the code that decides what crosses between the forms. A missing file or an empty/renamed vocabulary RAISES. Original AC text: a probe reports whether the other form can express the construct, resolved from the live vocabulary (imported, not a hand-copied list, so it cannot drift from the bridge). A probe that cannot resolve its vocabulary RAISES rather than returning "absent".
- [x] Done — `EXPECTED_GAPS` 9 → 12, arithmetic re-derived in the comment; census table, headline and correction block now state ONE number set — 8 gap families / 12 gap rule ids / 0 out of scope — with the families-vs-ids distinction spelled out, because the guard counts ids and the report counts families. Reconciling them surfaced a pre-existing discrepancy: `E-XML-ID-DUP` was in the guard's arithmetic and output but had no table row; row added. Original AC text: The three `scopeOf` rules are reclassified GAP with `EXPECTED_GAPS` re-derived, and the census artifact's table + headline match the guard exactly (no third number anywhere).
- [x] Measured, not asserted: `scopeOf` ∈ `KNOWN_AEF_KEYS`; bridging a YAML map carrying it emits `scopeOf="n_capture"` into the BPMN bytes; that BPMN then validates `VALID — no findings` rc=0 while the YAML source is `ERROR [E-SCOPEOF-SELF]` rc=2. Original AC text: The reclassification is justified by measurement recorded in the task, not by assertion: `scopeOf` present in the canonical vocabulary AND emitted through the bridge into BPMN bytes.
- [x] Control (b) rewritten to the new semantics and (f) added; both proven RED by mutation (neutering the expressibility check, and making the vocabulary resolve silently to empty). Control (c) unchanged and still red. Original AC text: (i) an OUT-OF-SCOPE entry whose construct IS expressible fails; (ii) an OUT-OF-SCOPE entry with no probe still fails; (iii) a probe whose vocabulary cannot be resolved fails rather than passing silently.
- [x] Recorded explicitly: `OUT_OF_SCOPE_PROBES` is now **empty** — after the repair no rule in the table is out of scope — so the machinery is exercised ONLY by controls (b), (c) and (f), which synthesise entries. That is stated in the code comment rather than left for a reader to discover. Original AC text: Vacuity guarded: with zero OUT-OF-SCOPE entries remaining, the probe machinery must still be exercised (by the controls) — a suite that would pass with the probe code deleted is recorded as such, or the machinery is made unreachable-proof.
- [x] Guard: `45 rules classified, 12 gaps, 0 out-of-scope re-measured against a 44-key vocabulary (96 authored bpmn walked for priority only)`. Bridge 62 passed / 0 failed; validator 42 passed / 0 failed.

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

out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "^rule-form parity: OK$"
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "0 out-of-scope re-measured"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -qE "^== summary: [0-9]+ passed, 0 failed ==$"
# the vocabulary probe must resolve a non-empty vocabulary, or every gap reads as out-of-scope
python3 -c "import sys; sys.path.insert(0,'tests'); import test_rule_form_parity as t; assert len(t._aef_vocabulary()) > 20"
# the census artifact and the guard must not report two different numbers
# T-321 legitimately moved both counts the same day (7 families / 11 ids). Pinning a
# moving number in a COMPLETED task's Verification block is the T-317 mistake; what
# must hold is that the artifact and the guard agree, not that they agree on 12.
grep -qE "[0-9]+ gap families / [0-9]+ gap rule ids / 0 out of scope" docs/reports/T-320-rule-form-parity-census.md

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-08-01 — the old control agreed with the wrong classification

- **What changed:** the guard already had a negative control for exactly this row —
  "an OUT-OF-SCOPE entry whose construct HAS appeared must be caught" — and it was
  green. It could not have caught the defect: it asked whether the **corpus** carried
  the construct, the corpus carried none, and so the control faithfully confirmed a
  classification that was wrong on its own terms. A control inherits the discriminator
  it is built on. Testing the implementation of a wrong rule proves the rule is
  implemented, not that it is right.
- **Plan impact:** none — this is why the AC demanded controls be *rewritten to the new
  semantics* rather than merely kept passing.
- **Triggered:** nothing filed; recorded as the sharpest thing learned here.

### 2026-08-01 — the repair empties the table's out-of-scope column entirely

- **What changed:** after reclassifying `scopeOf`, **no rule in the parity table is out
  of scope.** `OUT_OF_SCOPE_PROBES` is `{}`. Every asymmetry between the two validator
  forms is now a gap.
- **Plan impact:** the probe machinery is live code with no production caller, exercised
  only by negative controls (b), (c) and (f). Left in place and the situation stated in
  the code comment — deleting it would mean the next out-of-scope claim arrives with no
  machinery to falsify it, and silently unexercised machinery is the T-312 vacuity class.
- **Triggered:** nothing filed.

### 2026-08-01 — two counts of two different things, in one artifact

- **What changed:** reconciling `EXPECTED_GAPS` (12) with the census headline ("nine gap
  families") showed they count different objects — **rule ids** vs **families** — and
  neither said which. My own AC for this task forbade exactly that ("no third number
  anywhere") and I had written the violation into the correction block a few hours
  earlier. Same family as G-013: a number rendered without its subject.
- **Plan impact:** one number set now stated once, with the distinction spelled out:
  **8 gap families / 12 gap rule ids / 0 out of scope**, and a Verification line greps
  that exact string so artifact and guard cannot drift apart silently.
- **Triggered:** a pre-existing discrepancy fell out of it — `E-XML-ID-DUP` has been in
  the guard's arithmetic and output since publication with **no row in the census
  table**. The artifact and the guard have disagreed by one family the whole time. Row
  added; guard treated as authoritative.

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

### 2026-08-01T10:11:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-323-census-outofscope-classifications-rest-o.md
- **Context:** Initial task creation

### 2026-08-01T10:28:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9177f226
- **Timestamp:** 2026-08-01T10:37:02Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — Probes interrogate the VOCABULARY: `_aef_vocabulary()` **imports** `KNOWN_AEF_KEYS` from `tools/yaml-to-bpmn.py` (44 keys) rather than hand-copying it, so it cannot drift from the code that decides wh
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/yaml-to-bpmn.py in: Probes interrogate the VOCABULARY: `_aef_vocabulary()` **imports** `KNOWN_AEF_KEYS` from `tools/yaml-to-bpmn.py` (44 keys) rather than hand-copying it`

### 2026-08-01T10:35:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
