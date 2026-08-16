---
id: T-488
name: "Round-trip harness self-test: give every projected key teeth, and make the
  two METAKEYS copies structurally incapable of diverging"
description: >
  The preflight self-test breaks on the first regex match, so it reports hit='tier'
  on every run and proves the drift mechanism for exactly one key. Every key added
  since — endpoint (T-480) and the eight scalars (T-482) — has teeth only from one-shot
  task probes, not from the standing guard. Compounding it, the two METAKEYS copies
  are already divergent (guard carries errorStatus/timerSpec/busTopic, preflight does
  not), so the teeth-proof exercises a strict subset of what the guard projects. Third
  defect found on reading: the mutation regex assumes key=" attribute form, but endpoint
  rides a standalone element, contextReads/artifactsWrites ride paths= on their own
  elements, decisionInput/decisionOutputs ride text content, and the link keys ride
  aef:link attributes — so several keys could never be perturbed by that regex even
  without the break. OBS-045.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: ["T-480", "T-482", "T-483", "T-484", "T-485"]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-13T08:32:12Z
last_update: '2026-08-16T13:58:57Z'
date_finished: 2026-08-13T09:02:32Z
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
  - ts: '2026-08-16T12:34:02Z'
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
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tools/_roundtrip-serialization-cdp.mjs,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/run-bridge-tests.sh,tools/_roundtrip-serialization-cdp.mjs); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-488: Round-trip harness self-test: give every projected key teeth, and make the two METAKEYS copies structurally incapable of diverging

## Context

`tools/_roundtrip-serialization-cdp.mjs` is our only true semantic fixed-point test across the
editor seam: it parses a document, re-emits it, and compares a per-node projection of the
governance extensions. It is what stops AEF's extension data being silently eaten by a load→save
round trip. It is wired into `tests/run-bridge-tests.sh` as a standing gate.

Its self-test — the thing that proves the guard can go red — is:

    for(var i=0;i<METAKEYS.length;i++){
      var re=new RegExp('('+METAKEYS[i]+'=")([^"]*)(")');
      if(re.test(emit1)){ mutated=emit1.replace(re,'$1__DRIFT__$3'); hit=METAKEYS[i]; break; }
    }

**Three defects, compounding.** The first two are OBS-045; the third was found reading the code
for this task:

1. **`break` on first match.** `tier` is first in the list and present in every document, so the
   self-test reports `hit:'tier'` on every run and proves the mechanism for exactly one key.
   Everything added since — `endpoint` (T-480) and the eight scalars (T-482) — has teeth only
   from **one-shot task probes** (`tools/_t482-…`, `tools/_t483-…`), which are completion-gate
   artifacts, not standing guards. PL-161 exactly: a `## Verification` block is a one-shot gate,
   not a standing guard.

2. **The two METAKEYS copies are already divergent.** The guard copy carries
   `errorStatus`,`timerSpec`,`busTopic` (and further keys) that the preflight copy does not, and
   nothing asserts they agree. So the teeth-proof exercises a strict **subset** of what the guard
   projects — the exact membership-vs-behaviour gap T-483/T-484 were about, in the instrument
   that measures it.

3. **The mutation form assumes one wire shape and the keys have five.** The regex only matches
   `key="…"`. But `endpoint` rides a **standalone `<aef:endpoint>` element**;
   `contextReads`/`artifactsWrites` ride a `paths=` attribute on their own elements;
   `decisionInput`/`decisionOutputs` ride **text content**; the link keys ride `<aef:link>`
   attributes. Those keys could never be perturbed by that regex **even with the `break`
   removed** — they would be reported "not present in the emission" and read as benign.

   This is **PL-176** (surfaced by the focus command, from T-484): *a flat enumeration over
   heterogeneous shapes has nowhere to put the shape.* The wire-form knowledge already exists —
   T-482 built a `WIRE` table for exactly this — but it lives in a one-shot probe rather than in
   the standing guard.

**Why defect 3 is the dangerous one.** Defects 1 and 2 leave keys *unproven*. Defect 3 makes an
unprovable key look **checked**: the loop visits it, finds nothing to mutate, and moves on. A key
absent from the teeth-proof is a known hole; a key that reports "no match" is a hole that
**reports itself closed** — the T-483 `[object Object]` shape again, one layer up.

Scope is `tools/` only. No `src/`, no corpus bytes, no standard, no fixture re-pin.

## Findings

**Result: 34 keys / 26 LIVE / 0 BLIND / 3 DRIFT-ELSEWHERE / 1 NOT-EXERCISABLE / 7 NEVER-PRESENT
over 18 fixtures.** The guard is sound — every key whose carrier the corpus actually exercises
moves the projection when mutated. What the old self-test asserted was `hit:'tier'`.

**The headline number is `proven_fraction: 26/34.` Eight of thirty-four projected keys have never
been proven to detect drift** — not because the guard is broken, but because nothing exercises
them. That was invisible before this task: the self-test reported one key and said nothing about
the denominator, so 8 unproven keys and 33 unproven keys produced identical output.

**Two of my own errors, both caught before publishing, both the window's own class:**

1. **The first run reported `name` BLIND in 18 of 18 fixtures and `workflowType` BLIND in one** —
   and had I stopped there I would have filed a finding against the guard. Both were my probe: a
   bare `name="` matches the first `bpmn:` node or process name, and `workflowType="` matches the
   PROCESS-level `aef:workflowMeta`. Both mutate something real, neither is the key under test,
   and since `proj()` covers nodes only, neither moves the projection — so the key reads BLIND.
   **A too-loose mutation does not fail loudly; it manufactures a finding against the thing it is
   testing.** Fixed by anchoring the mutation inside the named element.

2. **`hostRef` was reported NEVER-PRESENT while `attachedToRef` is present in a fixture.** The
   carrier is there; `boundary-events.bpmn` simply has one activity, so there is no second host to
   re-point at. Filing that beside seven genuinely-absent keys would have sent the next reader to
   write a boundary-event fixture that already exists. Split into a distinct `NOT-EXERCISABLE`
   state, because the three unproven states have three different remedies:
   `NEVER-PRESENT` → author a fixture · `NOT-EXERCISABLE` → enrich one · `BLIND` → fix the guard.

**Evidence the BLIND path has teeth:** it is not asserted, it fired. Run 1 exited 2 with two BLIND
keys and refused to publish. The gate works because it was observed working, not because it was
written to.

**Third time is not the charm.** I broke the harness again with a backtick inside a comment inside
a template literal — the identical hazard documented in a comment two lines from where I typed,
which T-480 hit and T-483 hit. Reading a warning is not the same as being protected by one. The
only thing that has ever caught it is `node --check`.

## Acceptance Criteria

### Agent
- [x] AC1 — **The single-source list.** `METAKEYS` and `STRUCTKEYS` are defined ONCE on the Node
      side and interpolated into both browser expressions, so the two copies cannot diverge —
      structural prevention, not a divergence *detector*. (Interpolation goes at code positions
      only: `${}` and backticks inside comments in these template literals have killed this
      harness twice — T-480's note and again in T-483.) If the reconciliation changes which keys
      the preflight projects, the delta is reported, not silently absorbed.
- [x] AC2 — **Per-key teeth, no `break`.** The self-test attempts every key in the list and
      reports a per-key verdict. Never again a run whose evidence is one key's name.
- [x] AC3 — **Wire-form aware mutation (PL-176).** Each key declares its carrier shape — meta
      attribute · standalone element · `paths=` attribute · element text · `aef:link` attribute —
      and is perturbed in that shape. A key whose declared shape is absent from a document is
      `NOT-PRESENT` for that document; a key whose shape is present but whose mutation does not
      move the projection is `BLIND` and is a finding.
- [x] AC4 — **Corpus-wide denominator, and the vacuity check (PL-084).** Verdicts aggregate over
      the whole fixture corpus, not one document — a key absent from one fixture may be live in
      another. The run prints `keys_total / LIVE / BLIND / NEVER-PRESENT` and **fails** if any key
      is `BLIND`, or if the LIVE count is zero. A green over an empty population is not a result.
- [x] AC5 — **The controls hold.** A positive control (`tier`, known live) must report LIVE and a
      synthetic key in no list must report NEVER-PRESENT. If either control fails the harness
      refuses to publish a verdict and exits non-zero — the T-485 rule: a probe that cannot
      distinguish the two states proves nothing by finding nothing.
- [x] AC6 — **The guard still guards.** `tests/run-bridge-tests.sh` is green and the harness's own
      round-trip verdict over the corpus is unchanged by this task — this changes the self-test,
      not the fixed point it tests.
- [x] AC7 — **Byte-neutral outside `tools/`.** `git diff` is empty for `src/`, `docs/standards/`,
      `examples/`, `tests/fixtures/` and `.agentic-framework/`.

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

# NOTE (OBS-043, live in our vendored pin): the P-011 gate strips HTML comment spans out of this
# block before executing it, with no quote or command-boundary awareness. No leg below carries
# those delimiters as data, deliberately.

# AC1 — ONE definition, interpolated into both browser expressions. Pins the count at 2 (not
# "at least 1"), so deleting an interpolation and re-inlining a hand-copy goes red.
test $(grep -c 'JSON.stringify(METAKEYS)' tools/_roundtrip-serialization-cdp.mjs) -eq 2
test $(grep -c 'JSON.stringify(STRUCTKEYS)' tools/_roundtrip-serialization-cdp.mjs) -eq 2
test $(grep -c '^const METAKEYS = KEYSPEC.map' tools/_roundtrip-serialization-cdp.mjs) -eq 1

# AC2 — the break-on-first-key loop is gone and cannot come back unnoticed.
# NOT 'grep -qv': -v inverts LINE matching, so it succeeds whenever any line differs — which is
# every file. Absence is asserted with a negated grep, and this leg was written the wrong way
# first, inside the task about instruments that report success without doing their job.
! grep -q 'hit=METAKEYS\[i\]; break;' tools/_roundtrip-serialization-cdp.mjs

# AC3 — all seven wire carriers are declared. The old self-test knew only one of these.
test $(grep -o "shape: '[a-z]*'" tools/_roundtrip-serialization-cdp.mjs | sort -u | wc -l) -eq 7

# AC4+AC5 — run the harness and assert the SELF-TEST's own properties, not just its exit code
# (the counterfactual-signal rule, rail 595: judge the specific signal, not the run's status).
# Asserts: controls held, zero BLIND, and a LIVE floor — a green with nothing proven is the
# vacuity PL-084 names, and the floor is what stops the population silently emptying.
T=$(mktemp) && node tools/_roundtrip-serialization-cdp.mjs > "$T" && python3 -c "import json,sys; d=json.load(open('$T')); s=d['selftest']; assert d['pass'], 'harness failed'; assert s['controls']['held'], s['controls']; assert not s['blind'], s['blind']; assert len(s['live']) >= 20, s['live']; print('OK', s['summary'])"

# AC6 — the fixed point this task did NOT change is still green.
bash tests/run-bridge-tests.sh

# AC7 — byte-neutral outside tools/.
test -z "$(git diff --name-only -- src docs/standards examples tests/fixtures .agentic-framework)"

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

### 2026-08-13 — the `break` was the least of it
- **What changed:** Filing blamed two defects (break-on-first, divergent copies). Reading the emitter
  found a third that dominates both: the mutation assumed `key="V"` and **14 of 34 keys do not ride an
  attribute named after themselves** — three ride `<aef:eventDef binding=>`, two ride native
  `bpmn:boundaryEvent` attributes. Removing the break would have left those fourteen visited,
  unmutatable, and recorded as benign.
- **Plan impact:** "Remove the break, sync the lists" was not a fix. The list had to gain a per-key
  wire carrier (PL-176), and the self-test had to gain a third verdict beyond LIVE/absent.
- **Triggered:** the KEYSPEC shape; NOT-EXERCISABLE split out as its own state; T-489 for the fixture
  gap the denominator exposed.

### 2026-08-13 — the probe accused the guard, twice, and was wrong both times
- **What changed:** First run reported `name` BLIND in 18/18 fixtures. Not a finding — a bare `name=`
  regex hitting the first `bpmn:` node name. Second: `hostRef` reported absent while its carrier was
  demonstrably in a fixture. Both were mine.
- **Plan impact:** No AC covered "the probe is innocent until exonerated". The verdict shape had to
  become evidence: 18/18 is a claim of total failure, less likely than a bug in a four-minute-old regex.
- **Triggered:** mutation anchored inside its named carrier; per-key attribution by reading which key's
  value actually moved; the learning recorded under T-488.

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

### 2026-08-13T08:32:12Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-488-round-trip-harness-self-test-give-every-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a471a617
- **Timestamp:** 2026-08-13T09:04:11Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-13T09:02:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
