---
id: T-925
name: "tools/yaml-to-bpmn.py drops document-level aef:workflowMeta entirely, so no
  cross-form rule on any of its ten attributes can ever be compared"
description: >
  MEASURED under T-826, not read: a YAML document carrying workflowMeta.kind='overlord'
  fires E-WORKFLOW-KIND on the YAML form; bridged through tools/yaml-to-bpmn.py the
  output contains ZERO 'workflowMeta' occurrences (grep -c) and the XML form is silent.
  grep -n 'aef:workflowMeta' tools/yaml-to-bpmn.py returns nothing: emit() reads meta
  = workflow.get('workflowMeta') at :141 and uses it ONLY for wid/process_id derivation.
  So all ten document-level attributes the designer emits (id, uuid, version, schemaVersion,
  title, description, source, tier_default, pageWidth, kind) are LOST across the bridge.
  WHY IT MATTERS BEYOND kind: tests/test_harness_cross_form_agreement.py compares
  the two validator forms by driving YAML fixtures THROUGH this bridge, so a document-level
  rule can never be compared on a bridged document. The bridged doc is clean because
  the carrier was ERASED, not because the value became legal — and that harness's
  own docstring forbids inferring BRIDGE_REPAIRED from 'XML said nothing': 'Inferring
  it is how a real hole gets absorbed as a repair.' T-826 declares E-WORKFLOW-KIND
  a KNOWN disagreement citing THIS task rather than absorbing it. SAME CLASS AS T-885,
  one instrument over: T-885 found document-level workflowMeta outside the round-trip
  guard's denominator BY CONSTRUCTION; this is document-level workflowMeta outside
  the BRIDGE's output entirely. NOT IN SCOPE HERE: whether the bridge SHOULD emit
  workflowMeta is a seam question (the corpus is pinned by AEF and 24/24 rendered
  maps are bridge-produced, so emitting it changes bytes AEF pins against) — that
  is the first thing this task must settle, before any code.

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: human
horizon: null
tags: [bridge, cross-form, false-green]
components: [tests/fixtures/invalid/E-XML-WORKFLOW-KIND.bpmn, tests/test_finding_anchorability.py, tests/test_harness_cross_form_agreement.py, tools/_t301-known-divergences.txt, tools/_t820-rule-axes.sh, tools/_t826-kind-rule-axes-teeth.sh, tools/yaml-to-bpmn.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-29T07:57:12Z
last_update: 2026-09-30T22:40:55Z
date_finished: 2026-09-30T22:40:55Z
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
bvp_scores_proposed: []
cost_estimate_proposed:
  - ts: '2026-09-29T08:35:02Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius:
      tier: 2
      effort: 8
    rationale: blast_radius=? (no-components-UNMEASURED-not-zero); tier=2 
      (workflow:build); effort=8 (lines=269,acs=4)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 0
  F3: 4
  F1: 1
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T08:35:03Z'
---

# T-925: tools/yaml-to-bpmn.py drops document-level aef:workflowMeta entirely, so no cross-form rule on any of its ten attributes can ever be compared

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**SLICE 1 — settle the seam question. No emitter change in this slice.** T-925's own
description says so: *"whether the bridge SHOULD emit workflowMeta is a seam question … that
is the first thing this task must settle, before any code."* The ruling is the operator's;
this slice's job is to make it decidable and to correct one record that currently misdirects.

- [x] **The blast radius is MEASURED, not asserted.** T-925's cost argument rests on
      *"24/24 rendered maps are bridge-produced, so emitting it changes bytes AEF pins
      against."* Measured instead: which rendered documents would change bytes if the bridge
      emitted `aef:workflowMeta`. Method is re-render-and-diff into a scratch path — never
      over the committed corpus — because only a diff distinguishes "the bridge made this"
      from "a bridge-shaped file exists here".
- [x] **The 24 AEF-process renders' actual producer is identified.** They carry no
      `Generated from … by tools/yaml-to-bpmn.py` header (only customer-refund does, ×2) yet
      they DO carry `aef:workflowMeta`, which the bridge provably cannot emit
      (`grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py` = 0). Both facts cannot be true of
      one producer, so one of them names the wrong tool.
- [x] **A decision brief in `docs/reports/T-925-workflowmeta-bridge-seam.md`** stating: the
      measured byte-change count, what AEF pins and whether these files are in it, the ten
      attributes currently lost, and the options with their consequences. Written so the
      operator can rule without re-deriving any of it.
- [x] `tools/_t301-known-divergences.txt` **cites T-925 as the cause.** Its current reason
      says the divergence *"may be a deliberate metadata-less import fixture — operator
      decision"*. That is wrong and actively misdirects: the source YAML declares
      `workflowMeta.id: customer-refund` and the bridge erased it. Corrected in place, with
      the wrong reading left visible.
- [x] **No emitter change, and no corpus bytes moved.** Asserted structurally, not promised:
      `git diff --stat` over `examples/*/rendered/` and `tools/yaml-to-bpmn.py` is empty at
      close. If the seam ruling is GO, the emitter lands as a separate slice.

### Human
- [x] [REVIEW] **Rule the seam question: should `yaml-to-bpmn.py` emit
      `<aef:workflowMeta>`?** This is a sovereignty call, not a review of my work — T-925
      deferred itself on this exact question and slice 1 exists only to make it decidable.

  **Steps:**
  1. Read the brief — it is short and every number in it is measured:
     `docs/reports/T-925-workflowmeta-bridge-seam.md`
  2. Run the decision script and pick an option. Recommendation is shown first; `1`/`2`/`3`
     acts immediately, arrows + Enter also work:
     `bash /opt/832-Workflow-designer/runme.sh`

  **Expected:** Your choice is recorded as a decision on T-925 and the script prints where.
  The three options are:
  - **A — emit all ten attributes** (my recommendation). 1 tracked file changes bytes, no
    pin is affected, no test is expected to break, and one KNOWN-disagreement entry in
    `test_harness_cross_form_agreement.py` becomes retireable.
  - **B — emit `id` only.** Closes the visible symptom, leaves nine attributes destroyed and
    the cross-form hole intact.
  - **C — rule the bridge is deliberately lossy.** Then the T-301 divergence is expected
    behaviour, the baseline entry becomes a permanent accepted limitation, and every
    document-level validator rule keeps a permanent known-disagreement.

  **If not:** If none of the three fits, the thing to say is which claim in the brief you
  doubt — the load-bearing one is that the bridge produced **1** of the 25 served renders,
  not 24, which is what T-925's original deferral assumed.

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

# --- T-925 slice 1: the seam question, priced --------------------------------
# The brief exists and carries the measurement the ruling depends on.
test -f docs/reports/T-925-workflowmeta-bridge-seam.md
grep -q 'That premise is false' docs/reports/T-925-workflowmeta-bridge-seam.md
grep -q 'Pool_task_lifecycle' docs/reports/T-925-workflowmeta-bridge-seam.md
test "$(grep -rl 'by tools/yaml-to-bpmn.py' examples/ build/ 2>/dev/null | wc -l)" -ge 2  # T-1015: was =2; G-015, the population grows
# The source DID declare the id — the fact that made this a renderer bug rather than an
# authoring mistake, and the reason the ruling went the way it did. Unchanged by the fix.
grep -q 'id: customer-refund' examples/app-processes/customer-refund.workflow.yaml
grep -q 'aef:workflowMeta' examples/aef-processes/rendered/task-lifecycle.bpmn

# --- REWRITTEN BY T-959. SUPERSEDED BY T-953, BY THIS TASK'S OWN PLAN --------
#
# Four lines here asserted THE BUG, and P-011 runs this block on the work-completed
# transition and at no other time (PL-161), so they had to be true at the moment the
# operator closes the task. Measured 2026-10-01: three of them were FALSE.
#
#   line 189  test "$(grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py)" -eq 0       rc=1
#   line 194  ! grep -q 'aef:workflowMeta' .../rendered/customer-refund.bpmn         rc=1
#   line 198  grep -q 'CAUSE IS T-925' tools/_t301-known-divergences.txt             rc=1
#
# All three were true when slice 1 closed. All three are false now because the operator
# ruled A (PD-351) and T-953 shipped the emitter fix — which is EXACTLY the "separate
# slice" the Agent AC above said would follow a GO. The ACs predicted this; what nobody
# did was re-read the gate afterwards. Left as it was, `runme.sh` would have ticked the
# Human AC and then been refused by this gate: box ticked, task still open.
#
# The superseded form is printed above each replacement rather than deleted. A completion
# gate that quietly reflows to match the tree stops being a gate, and "the tree changed
# and here is why" is the part worth keeping.
#
# was: test "$(grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py)" -eq 0   (pre-T-953)
test "$(grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py)" -ge 1
# was: ! grep -q 'aef:workflowMeta' .../customer-refund.bpmn              (pre-T-953)
# Now a PRESENCE assertion, which needs no control — and it carries the authored id, not a
# sanitised fallback, which is the whole substance of the ruling.
grep -q 'aef:workflowMeta id="customer-refund"' examples/app-processes/rendered/customer-refund.bpmn
# was: grep -q 'CAUSE IS T-925' tools/_t301-known-divergences.txt         (pre-T-953)
# The baseline no longer names a live cause because it no longer HAS an entry. Assert the
# retirement record positively; the stale-entry leg in the invariant is what would catch a
# silent re-appearance, and it is run two lines below.
grep -q 'CURRENTLY EMPTY, AND THAT IS THE POINT' tools/_t301-known-divergences.txt
grep -q 'retired the same day by' tools/_t301-known-divergences.txt
#
# was: ! grep -q 'may be a deliberate metadata-less import fixture' <same file>
# DROPPED, not reworded. It was an UNCONTROLLED absence assertion (T-843): nothing greps
# that string where it IS present, so it cannot distinguish "the wrong reason is gone"
# from "my pattern never matched anything". It is also now vacuous — the entry it
# described was deleted outright, so the check has nothing left to be wrong about. The
# positive assertions above say the same thing without the blind spot.

# T-301's instruments, which is where the real teeth are: the invariant across all four
# roots, and its own prober. The invariant's stale-entry leg is what reported the baseline
# entry had stopped diverging in the first place.
python3 tools/_t301-id-stem-invariant.py > /tmp/.t925-inv.out 2>&1 && grep -q '0 divergent' /tmp/.t925-inv.out
bash tools/_t301-invariant-teeth.sh
# was: test -z "$(git diff --stat -- examples/ tools/yaml-to-bpmn.py)"
# DROPPED. That is PL-365 — a check whose truth depends on WHEN it runs. `git diff` with no
# ref compares the working tree to the index, so it goes vacuously true the moment the work
# is committed, and it passed at close for that reason rather than for its stated one. Its
# replacement is the time-independent form of what it was reaching for: the committed
# render is byte-reproducible from its source by the CURRENT emitter, so the bytes and the
# source cannot drift apart unnoticed.
python3 tools/yaml-to-bpmn.py examples/app-processes/customer-refund.workflow.yaml --out /tmp/.t925-rr.bpmn && diff -q /tmp/.t925-rr.bpmn examples/app-processes/rendered/customer-refund.bpmn

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
-->

## Decisions

### 2026-09-30 — the seam question (PD-351)
- **Chose:** Option A — `tools/yaml-to-bpmn.py` emits `<aef:workflowMeta>`, all ten attributes.
- **Authority:** the operator. A sovereignty call, not a review of agent work — which is why
  the Human AC above is `[REVIEW]` and why no agent could tick it.
- **Why:** the four-month deferral rested on "24 of 24 rendered maps are bridge-produced", so
  an emitter change would move the whole corpus. Measured in
  `docs/reports/T-925-workflowmeta-bridge-seam.md`: the bridge produced **1 of 25** served
  renders. The brief's headline is "That premise is false." Also measured — customer-refund is
  in no AEF pin manifest, the 10 bridge tests hold no golden-byte comparison, and the cross-form
  harness carried a KNOWN disagreement citing T-925 that a fix would retire.
- **Rejected:** narrower emission, or none. Their whole case was the corpus-wide cost, and the
  measurement removed it.
- **Consequence:** shipped under **T-953** as a separate slice, exactly as the Agent AC above
  said it would on a GO. 128/128 documents across four roots now derive from an authored id
  (was 126); a document with no workflowMeta is byte-identical to the previous emitter.

<!-- T-959: this section was EMPTY when T-925 closed, and the episodic generator reads it
     rather than .context/project/decisions.yaml — so T-925's long-term memory recorded
     "Mechanical task — no decisions to record" about a task that existed to make one
     decision. Written in so a regeneration is correct at the source. OBS-458. -->

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

### 2026-09-29T07:57:12Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-925-toolsyaml-to-bpmnpy-drops-document-level.md
- **Context:** Initial task creation

### 2026-09-30T19:38:41Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-30T19:45:48Z — status-update [task-update-agent]
- **Change:** owner: agent → human
- **Reason:** Slice 1 complete: the seam question is priced and decidable. The ruling is a sovereignty call — see the [REVIEW] Human AC and bash /opt/832-Workflow-designer/runme.sh

## Reviewer Verdict (v1.5)

- **Scan ID:** R-99fdf2f3
- **Timestamp:** 2026-09-30T22:40:58Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-30T22:40:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Completed via Watchtower UI (human action)
