---
id: T-490
name: "Round-trip guard denominator is hand-derived: 2 emitter-projected keys sit
  outside it"
description: >
  Round-trip guard denominator is hand-derived: 2 emitter-projected keys sit outside
  it

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
created: 2026-08-13T11:25:11Z
last_update: '2026-08-16T13:58:57Z'
date_finished: 2026-08-13T11:51:24Z
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
  - ts: '2026-08-16T12:34:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/boundary-events.bpmn,tests/fixtures/aef-bpmn/typed-events.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/boundary-events.bpmn,tests/fixtures/aef-bpmn/typed-events.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-490: Round-trip guard denominator is hand-derived: 2 emitter-projected keys sit outside it

## Context

T-488 rebuilt `tools/_roundtrip-serialization-cdp.mjs` so the seam's fixed point proves every
projected governance key rather than the first one, and T-489 raised the result to
`proven_fraction: 34/34` over 19 fixtures. Both numbers are correct **about the 34**. Neither
says anything about whether 34 is the right total.

The 34 came from me reading `src/aef-workflow-designer.html` by hand and typing a list. That is
the same construction as AEF's `_KNOWN_EXT` and as the two hand-copied `METAKEYS` arrays T-488
found already divergent (OBS-045). AEF reported the identical shape one level down in their own
probe at rail 609 §2 — 7/7 members, per-attribute denominator unmeasured — having gone looking
for the shape rather than the number after I published mine. This task runs that check on us.

Mechanical extraction of `aef.<scalar>` references from the emitter's extension-projection block
(src:9270-9370) yields 15 identifiers. Three are loop variables (`k`, `key`, `bindField`). Of the
remaining 12, ten are in `KEYSPEC`. Two are not, and — the part that matters — they are not in any
of the three DOCUMENTED exclusions either:

| identifier | status |
|---|---|
| STRUCTKEYS (6) | excluded, reasoned (`[object Object]` compares equal to itself) |
| `aef:io` | excluded, reasoned (built from arrays, no scalar to project) |
| `boundaryPos` | excluded, reasoned (presentational, deliberately not projected) |
| **`eventDefKind`** | **absent — no entry, no exclusion, no reason** |
| **`eventDefBinding`** | **absent — no entry, no exclusion, no reason** |

These two are the T-259 preservation passthrough (`src:9318-9325`), re-emitting an `aef:eventDef`
captured at import for start/throw carriers that the typed-catch override skips. They are written
into the output XML. The probe's projection is built from `METAKEYS`, so a drift or drop in either
moves nothing in the comparison and the run still reports `34/34`.

An exclusion with a reason is a decision. An absence is a hole, and this one is wearing a
coverage number that reads as total. Fixing only the two keys would be fix-on-discovery — the
construction that produced the hole (a hand-typed list) survives the fix — so the denominator
itself has to become derived rather than asserted.

## Acceptance Criteria

### Agent
- [x] The emitter's projected-scalar set is derived MECHANICALLY from `src/aef-workflow-designer.html`, not asserted: a check extracts `aef.<ident>` from the projection block and compares it against `KEYSPEC ∪ STRUCTKEYS ∪ <documented exclusions>`, failing on any identifier in neither
- [x] The check's exclusion list is DATA carrying a reason string per entry, so a future exclusion cannot be added silently — a bare name with no reason fails the check
- [x] `eventDefKind` and `eventDefBinding` are either in `KEYSPEC` with a working wire-form shape, or excluded with a written reason — whichever the measurement supports, decided by evidence not convenience
- [x] Each newly-covered key is classified with T-488's vocabulary (LIVE / BLIND / DRIFT-ELSEWHERE / NOT-EXERCISABLE / NEVER-PRESENT); NOT-EXERCISABLE is reported as unproven, never folded into the proven count
- [x] The reported `proven_fraction` denominator equals the mechanically-derived total, so the number cannot again describe a hand-typed subset
- [x] The new check runs inside the existing suite (`tests/run-bridge-tests.sh`), not as a one-shot script
- [x] Full bridge suite green and the geometry corpus clean; zero bytes changed in `src/`, `docs/standards/`, `examples/`, `.agentic-framework/`, or any AEF digest-pinned fixture

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
# PL-161: these are ONE-SHOT completion legs. The standing guard is the suite leg added by
# this task — see the run-bridge-tests.sh check below, which is the one that keeps running.

# The harness parses (the only thing that has ever caught a backtick inside its template literals)
node --check tools/_roundtrip-serialization-cdp.mjs

# The two previously-absent keys are in KEYSPEC
grep -q "k: 'eventDefKind'" tools/_roundtrip-serialization-cdp.mjs
grep -q "k: 'eventDefBinding'" tools/_roundtrip-serialization-cdp.mjs

# The probe is INVOKED BY THE SUITE. This is the leg that would have caught T-490's own
# discovery: the harness existed, was sharpened three times, and ran in no runner at all.
grep -q '_roundtrip-serialization-cdp.mjs' tests/run-bridge-tests.sh

# Derived denominator agrees with KEYSPEC, no orphans, and every key is proven LIVE
node tools/_roundtrip-serialization-cdp.mjs > /tmp/t490-rt.json 2>&1
python3 -c "import json,sys; d=json.load(open('/tmp/t490-rt.json')); s=d['selftest']; n=s['denominator']; assert d['pass'] is True, 'probe failed'; assert n['problems']==[], n['problems']; assert n['orphans']==[], n['orphans']; assert n['derivedTotal']==n['specSize'], (n['derivedTotal'],n['specSize']); assert s['blind']==[], s['blind']; assert s['proven_fraction']=='36/36', s['proven_fraction']; print('OK', s['summary'])"

# NEGATIVE CONTROL: the denominator check must be able to go red. Removes one key from KEYSPEC
# in a throwaway copy and requires a non-zero exit. The grep guards the control itself — a sed
# that matched nothing would make this leg pass while testing absolutely nothing, which is the
# exact failure mode (a green that cannot go red) this whole task is about.
# (ONE LINE — the gate executes each non-comment line as its own command, so a heredoc here
#  would be split across invocations and the control would silently degrade to nothing.)
bash -c 'cp tools/_roundtrip-serialization-cdp.mjs tools/_t490_ctl.mjs; grep -q "k: .eventDefKind." tools/_t490_ctl.mjs || { rm -f tools/_t490_ctl.mjs; echo "control anchor missing"; exit 1; }; sed -i "s/{ k: .eventDefKind.,    shape: .eventkind.   }, //" tools/_t490_ctl.mjs; grep -q "k: .eventDefKind." tools/_t490_ctl.mjs && { rm -f tools/_t490_ctl.mjs; echo "control mutation did not apply"; exit 1; }; node tools/_t490_ctl.mjs >/dev/null 2>&1; rc=$?; rm -f tools/_t490_ctl.mjs; test $rc -ne 0'

# AEF digest-pinned fixtures are untouched (rail 584: an unannounced change reads as tampering)
git diff --quiet HEAD -- tests/fixtures/aef-bpmn/typed-events.bpmn tests/fixtures/aef-bpmn/boundary-events.bpmn

# Nothing changed in src/, the frozen standard, examples/, or the vendored framework
git diff --quiet HEAD -- src/ docs/standards/ examples/ .agentic-framework/
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

### 2026-08-13 — the task was filed against the wrong defect

- **What changed:** T-490 was filed to close a 2-key hole in a guard's coverage list. The
  serious defect turned out to be one level up and was found only because AC6 made me check a
  claim I had already published as fact: the guard **ran in no test runner at all**. I had
  written "wired into tests/run-bridge-tests.sh:603" into a handover and onto the AEF rail;
  :603 is `_t338-input-fidelity-cdp.mjs`. Every green `_roundtrip-serialization-cdp.mjs` has
  produced since T-187 — through T-480, T-482, T-483, T-488, T-489 — was a hand-run invocation
  that expired when the session did.
- **Plan impact:** the denominator fix stands, but it was the smaller half. Wiring the probe in
  (suite leg 72) is what makes T-488's and T-489's work durable rather than anecdotal.
- **Triggered:** OBS-242. Correction issued to AEF on the rail, since I had cited the false
  wiring to them as evidence.

### 2026-08-13 — an absence is not an exclusion

- **What changed:** three keys sit outside this guard's coverage WITH written reasons
  (STRUCTKEYS, `aef:io`, `boundaryPos`) and two sat outside with none. Only the second kind is a
  defect, and nothing in the file distinguished them — both simply did not appear. So the fix is
  not "add two keys"; it is to make the denominator derived from the emitter and to make every
  exclusion carry a reason string, so removing coverage costs a sentence and stays a decision
  instead of decaying into an absence.
- **Plan impact:** `proven_fraction` now divides by the derived total rather than by
  `KEYSPEC.length`. The old ratio was self-referential — computed from the very list whose
  incompleteness it was supposed to express, so a missing key was invisible to it by construction.
- **Triggered:** three negative controls, all exiting 2 (missing key, exclusion with no reason,
  KEYSPEC key the emitter does not project).

### 2026-08-13 — DRIFT-ELSEWHERE sent the reader to the wrong remedy

- **What changed:** once added, `eventDefBinding` classified DRIFT-ELSEWHERE in all four documents
  that carry an `aef:eventDef`. That verdict says "your mutation hit a different key — aim
  better", and aiming better would never have worked: all 7 eventDef carriers in the corpus are
  catch/boundary hosts, so the typed-catch override consumes every one and the passthrough field
  is never populated. The corpus could not pose the question. T-488 built the
  NOT-EXERCISABLE/NEVER-PRESENT split for exactly this and the new key landed outside it.
- **Plan impact:** made it exercisable rather than reclassifying it — added an unconsumed
  `aef:eventDef` on the throw event in our own unpinned coverage fixture. That shape is also the
  rail-201 defect T-259 was written to fix (layout-only open→save destroying start/throw typed-event
  semantics), which until now nothing in the corpus exercised.
- **Triggered:** 36/36 LIVE, 0 NOT-EXERCISABLE.

### 2026-08-13 — the generalisation did not survive its own census

- **What changed:** OBS-242 asked how many other `tools/_*-cdp.mjs` probes are cited as standing
  evidence but invoked by nothing. First pass: 45 of 55 — alarming. Widening the runner
  denominator from one glob to every tracked text file dropped it to 27 (18 were invoked by
  something I had not looked in). Of those 27, twelve cite a `G-0NN`, but eleven cite **G-006**,
  which is the isolated-browser constraint they COMPLY with, not a gap they close. Filtering on
  the claim verb: **0 of 27** claim to close a gap.
- **Plan impact:** no follow-up task. The unwired 27 are one-shot completion artifacts, which is
  what PL-161 says they legitimately are. `_roundtrip-serialization-cdp.mjs` was singular — the
  only probe claiming to close a gap (G-002) while running nowhere.
- **Triggered:** nothing, deliberately. Publishing "45 unwired probes" would have been the same
  error as `34/34` in the opposite direction — a number whose denominator I had not examined.
  Each refinement shrank it, and the last one shrank it to zero.

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

### 2026-08-13T11:25:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-490-round-trip-guard-denominator-is-hand-der.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-01e1e076
- **Timestamp:** 2026-08-13T11:51:27Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** yes
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — The emitter's projected-scalar set is derived MECHANICALLY from `src/aef-workflow-designer.html`, not asserted: a check extracts `aef.<ident>` from the projection block and compares it against `KEYSPE
  - **AC-verify-mismatch** (narrow, heuristic) — `path=src/aef-workflow-designer.html in: The emitter's projected-scalar set is derived MECHANICALLY from `src/aef-workflow-designer.html`, not asserted: a check extracts `aef.<ident>` from th`

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -f`

### 2026-08-13T11:51:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
