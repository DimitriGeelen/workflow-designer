---
id: T-474
name: "AEF vendors four of our files by digest and we pin two: the other two can diverge
  silently"
description: >
  Rail 584 Q1 enumerated the six artifacts AEF vendors by byte-digest; four are ours:
  typed-events.bpmn, boundary-events.bpmn, s4-exemplar.bpmn and offpage-seam.bpmn
  (their 832/pair-draft-3). We pin only the first two, via test_typed_event_fixture_contract.py.
  s4-exemplar is export-path output, so T-423 will change it - their guard stays green
  (their copy is untouched), ours says nothing, and the two trees hold different bytes
  with no instrument on either side. T-473 recorded the announcement obligation as
  a SENTENCE; that is mitigation, not prevention (G-019). Build a vendored-artifact
  register plus a guard that fails when one of the four moves, naming the announcement
  shape AEF specified. Does not re-deliver anything and does not touch corpus bytes.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T20:54:09Z
last_update: '2026-08-16T12:34:01Z'
date_finished: 2026-08-12T20:59:48Z
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
  - ts: '2026-08-16T12:34:01Z'
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
---

# T-474: AEF vendors four of our files by digest and we pin two: the other two can diverge silently

## Context

### The premise was false, and it was measured before anything was built

This task was created to build a vendored-artifact register and guard, on the belief that
AEF vendors four of our files by digest while we pin only two — leaving `s4-exemplar`
(export-path output, so T-423 changes it) and `offpage-seam` free to diverge silently.

**Measured first:** `tests/test_corpus_fixture_pins.py` (T-216) already pins all four of
them, and the digests match current bytes exactly:

| file | pinned by | digest |
|---|---|---|
| `typed-events.bpmn` | T-212 `test_typed_event_fixture_contract.py` | `5467071b3a39…` |
| `boundary-events.bpmn` | T-212 | `37eec1b0f10a…` |
| `s4-exemplar.bpmn` | **T-216 `test_corpus_fixture_pins.py`** | `82b6ab78cd5f…` |
| `offpage-seam.bpmn` | **T-216** | `f9422acd330d…` |

So the register would have duplicated a guard shipped months ago, and the "silent
divergence" hazard I raised with AEF at 585 §4 is already instrumented on our side: a local
edit to any of the four turns a guard red, which is precisely what triggers the announcement
obligation T-473 recorded. **The obligation had an instrument; I did not know it did.**

Fourth premise-dissolution this session — and the first caught *before* the work rather
than after. The difference was one measurement that cost two commands. The original ACs are
preserved above rather than deleted: what I was about to build, and why it was unnecessary,
is the finding.

### What was actually wrong: the mislabel had five carriers, and T-473 fixed one

T-473 traced T-423's false "coordinated re-pin" cost to a diagnostic string calling a plain
byte digest `source_bpmn_sha`, and fixed **one** occurrence. Census:

| carrier | verdict |
|---|---|
| `run-bridge-tests.sh:206` | mislabel — fixed by T-473 |
| `run-bridge-tests.sh:224` | mislabel — **fixed here** |
| `test_corpus_fixture_pins.py:117` | mislabel — **fixed here** |
| `test_typed_event_fixture_contract.py:40` | mislabel (the constants' own header comment) — **fixed here** |
| `test_typed_event_fixture_contract.py:153` | mislabel — **fixed here** |
| `run-bridge-tests.sh:176`, `:185`, `test_promote_contract.py:21`, `:245`, `test_two_lane_joint_contract.py:42`, `:124` | **CORRECT — left alone** |

The last row is the point. In the promote-contract tests the term is *right*: those assert
the manifest projection whose reconcile key genuinely is `source_bpmn_sha`, the sha of the
source BPMN being promoted, per our IW-2 contract. **A blanket replace would have destroyed
six true statements to fix four false ones, and would have read in the diff as
thoroughness.** Fixing one of N and replacing all of N are the two failure modes here; the
census is what distinguishes them.

Each corrected message now says what the digest **is**, and carries AEF's announcement shape
(584 Q4) — `path + old -> new`, before the bytes land — with their reason attached: their
guard's message tells a reader that an unexpected digest means someone mutated a fixture
locally, so an unannounced change makes a true event read as tampering.

### Teeth, because I edited code that only runs when something breaks

Failure-path format strings are invisible until they matter; a broken one fails silently in
the direction of passing. Both were fired by corrupting the pin **in memory** — no file on
disk was touched:

```
corpus-pins    clean: 0 failures → corrupted pin: 1 failure, message renders in full
typed-event    clean: 0 failures → corrupted pin: 1 failure, message renders in full
```

The first attempt at this probe reported `(0) s4-exemplar missing — delivered fixture
removed?` — I had invented a dict key (`s4-exemplar`) where the real one is
`s4-exemplar.bpmn`, so I created a new entry pointing at no file and fired the wrong leg.
The probe was wrong in a way that still produced a red line, which is the failure mode that
looks like success. Re-run against the real keys.

Full bridge suite after the edits: **71 passed, 0 failed**, geometry sweep 24 clean.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**ACs REWRITTEN before any code was written — the original premise was false.** They
required building a vendored-artifact register on the belief that only two of the four were
pinned. Measured first: `tests/test_corpus_fixture_pins.py` (T-216) already pins
`s4-exemplar` and `offpage-seam`, both matching current bytes. The register would have been
a duplicate of a guard that has existed since T-216. The original ACs are preserved in
`## Context` rather than deleted, because "what I was about to build and why it was
unnecessary" is the finding.

- [x] **The dissolved premise is recorded with the evidence that dissolved it**, including
      the digests that made it checkable, so the next reader can see this was measured
      rather than abandoned.
- [x] **Every remaining carrier of the `source_bpmn_sha` mislabel is found and fixed.** T-473
      traced the false cost model in T-423 to a diagnostic string and fixed **one**
      occurrence. A census shows how many were left; fixing one of N is the shape of every
      incomplete-propagation failure this session has produced.
- [x] **The legitimate uses are NOT touched, and the distinction is stated.** In
      `run-bridge-tests.sh:176/:185` the term is *correct* — those tests assert the manifest
      reconcile key AEF's promote tool actually writes. A blanket replace would destroy a
      true statement to fix a false one, and would read in the diff as thoroughness.
- [x] **Each corrected message names what it IS, not just what it is not**, and carries the
      announcement shape AEF specified at 584 Q4 (rail post, one line per artifact,
      `path + old → new`, before the bytes change). Their own guard's message is what teaches
      a reader to treat an unannounced change as tampering.
- [x] **The full bridge suite is run after the edits and reported**, not just the touched
      tests — these are diagnostic strings inside guards, and a broken guard fails silently
      in the direction of passing.
- [x] **No corpus byte is written and no digest is altered.** Only message text changes.
      Corpus tree hash and all four pinned digests asserted unchanged in Verification.

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

# Legs 4-5 are negative; leg 6 is their positive control (PL-084). Without it, "the term is
# gone from the byte-pin guards" is satisfiable by deleting every mention everywhere,
# INCLUDING the promote-contract uses where the term is correct — i.e. the tidy-looking
# blanket edit this task exists to avoid.
# Legs 4-5 were checked for self-match before being written (the correction comments say
# "NOT source_bpmn_sha", never "source_bpmn_sha changed"): measured 0 and 0, not assumed.

python3 tests/test_corpus_fixture_pins.py
python3 tests/test_typed_event_fixture_contract.py
bash -n tests/run-bridge-tests.sh
! /usr/bin/grep -q 'source_bpmn_sha changed' tests/test_corpus_fixture_pins.py
! /usr/bin/grep -q 'source_bpmn_sha changed' tests/test_typed_event_fixture_contract.py
test "$(/usr/bin/grep -c 'source_bpmn_sha' tests/test_promote_contract.py)" -ge 2
/usr/bin/grep -q 'path + old -> new' tests/test_corpus_fixture_pins.py
/usr/bin/grep -q 'path + old -> new' tests/test_typed_event_fixture_contract.py
/usr/bin/grep -q 'path + old -> new' tests/run-bridge-tests.sh
git diff --quiet HEAD -- tests/fixtures/aef-bpmn examples/aef-processes/rendered
test "$(git ls-files -s examples/aef-processes/rendered tests/fixtures/aef-bpmn | sha256sum | cut -c1-16)" = "882ce395ad5d00b6"

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

### 2026-08-12T20:54:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-474-aef-vendors-four-of-our-files-by-digest-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-dbd1f56c
- **Timestamp:** 2026-08-12T20:59:50Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `destroy`

### 2026-08-12T20:59:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
