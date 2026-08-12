---
id: T-209
name: "832-side compile->promote->create producer-contract test (AEF rail offset 78 proposal)"
description: >
  AEF (rail offset 78) proposes a 832-side integration test mirroring their tests/unit/bpmn_promote_e2e.bats contract (manifest shape, promote CLI output, owner: agenthuman+captured forcing, aef_provenance block, reconcile states, gate refusal, inception-node DEFER-materialization leg). SCOPE ASSESSMENT NEEDED (G-020: this is a PROPOSAL, not authorization): T-559 symmetric boundary means 832 CANNOT run AEF tooling, so this is a PRODUCER-CONTRACT test on our side (assert our .bpmn serialization + manifest projection meet the pinned contract), NOT a live e2e. We already have tests/test_promote_contract.py + tests/test_two_lane_joint_contract.py asserting producer inputs; determine whether this is an extension of those or a genuinely new test before building. If serialization diverges, AEF offered byte-exact cross-validation (T-2535/T-2536 pattern).

status: started-work
workflow_type: test
owner: human
horizon: now
tags: [aef, arc, seam, producer-contract]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-19T15:42:35Z
last_update: 2026-08-10T20:01:29Z
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

# T-209: 832-side compile->promote->create producer-contract test (AEF rail offset 78 proposal)

## Context

AEF (rail offset 78) proposed a 832-side test mirroring their
`tests/unit/bpmn_promote_e2e.bats` contract. **Scope assessment (G-020 — this is a
PROPOSAL, not authorization):** decompose the proposal by the T-559 symmetric boundary
(832 cannot run AEF's `fw bpmn compile`/`promote`/gate) into producer INPUTS (832's side)
vs AEF OUTPUTS (AEF's side), then map the input half against what
`tests/test_promote_contract.py` (T-206) + `tests/test_two_lane_joint_contract.py`
(T-208) already assert.

### Proposal item → side → coverage
| AEF offset-78 item | Side (T-559) | 832 coverage today |
|---|---|---|
| manifest shape `{name, owner, workflow_type}` | producer INPUT | ✅ `extract_manifest` + failures() check (3) pins the EXACT tuple |
| owner `agent` + `human` (lane-derived) | producer INPUT | ✅ human via T-206 (sovereignty), agent via T-208 (initiative serviceTask) |
| uid totality / `source_bpmn_sha` (reconcile KEYS) | producer INPUT | ✅ check (2) uid totality + teeth (5b); check (4) pinned sha |
| inception-node → DEFER-materialization **input** | producer INPUT | ✅ check (3) pins `workflow_type: "inception"`; teeth (5a) rejects inception out of the sovereignty lane |
| promote CLI output | AEF OUTPUT | n/a — AEF's bats (T-559) |
| `aef_provenance` block | AEF OUTPUT | n/a — AEF's bats |
| `captured` forcing (`status: captured`) | AEF OUTPUT | n/a — not a 832 producer field |
| reconcile STATES | AEF OUTPUT | n/a — 832 owns only the reconcile KEYS (uid + sha), covered |
| gate refusal | AEF OUTPUT | n/a — AEF's bats |

### Finding
Every producer-INPUT item AEF's proposal names is **already covered** by T-206 + T-208
(one canonical contract, two fixtures, shared helpers — PL-005). The remaining items are
AEF OUTPUTS that, per the symmetric boundary, 832 must NOT assert (asserting them here
would build against the wrong contract — the exact inversion `test_promote_contract`'s
header warns against). There is **no new producer-input surface** in the offset-78
proposal for the promote/manifest contract.

The one genuinely-new 832 producer artifact since the proposal is the **typed-event**
serialization (T-204: `typed-events.bpmn` / `boundary-events.bpmn`) — a DIFFERENT contract
surface (typed-event encoding), already in motion on the rail (AEF shipped a WARN detector
T-2552; byte-exact cross-validation pending a fixture delivery, rail offsets 82–83). Track
it as its own producer-contract concern, not folded into T-209's promote/manifest scope.

### Recommendation (needs human/AEF confirmation — declining a peer proposal)
**DEFER — do NOT build a new promote/manifest producer-contract test.** The contract is
covered by T-206 + T-208. Suggested dispositions:
1. Reply to AEF on the rail that the offset-78 producer-input contract is already met by
   T-206 + T-208 (cite the tuple-pin at check (3) incl. `workflow_type: "inception"`, the
   agent+human derivations, and the pinned reconcile keys); the AEF-OUTPUT half correctly
   lives in their bats.
2. If a gap is desired, the only candidate is **typed-event byte-exact cross-validation**
   (separate surface) — file that as its own task, not under T-209.
3. Close T-209 as satisfied-by-T-206+T-208 once confirmed.

This is a decision to decline/defer a peer's proposal → left for human (Dimitri)
confirmation before closing or replying. Assessment only — no source written (budget-wrap).

## Re-Measurement (2026-08-10) — the premise, not the conclusion

The finding above is ~2 months old. Its conclusion ("already covered") is a rule; its
basis ("these tests assert these rows") is a fact about files on a given day. Only the
second can dissolve without a symptom, and the first keeps reading as true when it does
(PL-142). So it was re-run, not re-read.

**Both suites executed today, both green:**

    $ python3 tests/test_promote_contract.py                       exit 0
    OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)
      manifest owner-bearing uids: n_inception {owner:human←sovereignty,
      workflow_type:inception}; uid totality + byte-determinism + teeth verified

    $ python3 tests/test_two_lane_joint_contract.py                exit 0
    OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)
      owner-bearing uids: n_inception {owner:human←sovereignty, wf:inception};
      n_plan {owner:agent←initiative, wf:build}; uid totality + byte-determinism
      + teeth verified

Row by row, against the current files rather than the old table:

| producer-INPUT row | asserted today by | evidence |
|---|---|---|
| manifest tuple `{name, owner, workflow_type}` | `extract_manifest`, both suites | tuple printed per owner-bearing uid in both runs |
| owner `human` ← sovereignty lane | both | `owner:human←sovereignty` in both outputs |
| owner `agent` ← initiative lane | joint only | `n_plan {owner:agent←initiative}`; joint check (3) asserts the owner SET is exactly `{human, agent}` |
| uid totality (reconcile key 1) | both | "uid totality … verified" |
| `source_bpmn_sha` (reconcile key 2) | both | fixture sha pinned in the output line itself |
| inception-node → `workflow_type: inception` | both | `workflow_type:inception` / `wf:inception` |
| teeth (each suite can fail) | both | "teeth verified"; joint (5b) blanks the initiative lane's authority and requires owner derivation to break |

**Side-split re-checked by measuring the exporter, not by re-reading the partition.**
`src/aef-workflow-designer.html` emits 23 distinct `aef:*` markers today
(`aef:uid`, `aef:position`, `aef:meta`, `aef:laneMeta`, `aef:workflowMeta`, `aef:io`,
`aef:routing`, …). None of the four AEF-OUTPUT rows appears among them:

    aef_provenance      0 occurrences
    status="captured"   0 occurrences
    provenance          2 — both inside comments
    reconcile           6 — all inside comments
    promote             5 — all inside comments

So no row has crossed the T-559 boundary since the assessment. For one to cross, 832
would have to start EMITTING the field (a provenance block, a `status`, a reconcile
state) rather than merely mentioning it — and it emits none.

**Verdict: the original finding survives re-measurement.** The recommendation below now
rests on a dated measurement rather than a dated reading.

## Acceptance Criteria

### Agent
- [x] **The coverage table is RE-MEASURED, not re-read.** The assessment above concluded
      "already covered by T-206 + T-208" and is ~2 months old. That conclusion is a
      RULE; "these tests assert these rows" is a FACT about the test files on the day it
      was written, and only the fact can expire silently (PL-142). Each producer-INPUT
      row is re-checked against the current `tests/test_promote_contract.py` and
      `tests/test_two_lane_joint_contract.py`, and both suites are RUN, not just read.
      A green table asserted from a stale reading is exactly what would make us decline
      a peer's proposal on a premise that has since dissolved.
- [x] **The T-559 side-split is re-checked against the CURRENT seam.** The assessment
      partitions AEF's offset-78 proposal into producer-INPUT (ours) and AEF-OUTPUT
      (theirs). If any row has since moved sides — e.g. a field we now emit that we did
      not then — the "no new producer-input surface" finding does not hold. Verified by
      naming, for each AEF-OUTPUT row, what in 832 would have to change for it to become
      ours.
- [x] Whatever the re-measurement finds is written into the task as a dated result with
      the command output, replacing the undated claim. If it confirms the original
      finding, that is a measurement; if it does not, the recommendation below is
      withdrawn before the operator is asked to act on it.

### Human
- [ ] [REVIEW] Decline AEF's offset-78 producer-contract proposal as already satisfied?

  **This ruling has existed since the task was filed — as prose in `## Context`, not as
  an AC.** So a task waiting on your decision has been reading as in-progress agent
  work, invisible to `fw task verify` and to the review queue. That is the fourth
  instance of this mis-filing (T-340 AC1, T-341 AC1, T-358), and it is filed here rather
  than fixed silently.

  **What is being decided:** whether to tell a cooperating peer that the test they
  proposed we build is unnecessary. That is a seam ruling about a peer's work, not an
  implementation choice, which is why it is yours.

  **What the measurement says (re-run today, not inherited):** every producer-INPUT row
  in AEF's offset-78 proposal is asserted by `tests/test_promote_contract.py` +
  `tests/test_two_lane_joint_contract.py`, both green, both with working teeth. The
  remaining four rows are AEF OUTPUTS which, under T-559, 832 must NOT assert — building
  them here would test our guess at their behaviour and call it a contract. Our exporter
  emits none of the four fields, so nothing has crossed the boundary since.

  **Options:**
  - **A — Decline as satisfied.** Reply on the rail citing the two suites and the
    tuple-pin, note the AEF-OUTPUT half correctly lives in their bats, close T-209.
  - **B — Build it anyway.** Cost: a third suite asserting what two already assert, plus
    the standing risk that its AEF-OUTPUT half encodes our assumption about their side.
  - **C — Decline the promote/manifest half, open the real gap.** As A, and additionally
    file typed-event byte-exact cross-validation (`typed-events.bpmn` /
    `boundary-events.bpmn`, rail offsets 82–83) as its own task — a genuinely uncovered
    producer surface that the offset-78 proposal did not name.

  **Recommendation: C.** A is correct and incomplete: it closes the item and leaves the
  one real gap unfiled, which is how a satisfied-contract finding turns into a blind
  spot. The typed-event surface is a different contract, and AEF already shipped a WARN
  detector for it (T-2552) — so declining the proposal while filing that gap answers
  their proposal in the spirit it was made.

  **Steps:**
  1. `python3 tests/test_promote_contract.py && python3 tests/test_two_lane_joint_contract.py`
  2. Confirm both print `OK:` and exit 0
  3. Record the decision:
     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-209 offset-78 proposal: C" --task T-209 --rationale "producer-input contract already met by T-206+T-208, re-measured green; AEF-OUTPUT half stays in their bats per T-559; file typed-event byte-exact cross-validation as its own task"`

  **Expected:** a decision recorded against T-209. The agent then posts the rail reply
  and files the typed-event task; T-209 closes.

  **If not:** if you want the reply worded differently, or want the typed-event gap left
  unfiled for now, say so in the rationale — the agent will not send a rail message
  declining a peer's proposal without this decision recorded.


## Recommendation

**Recommendation:** GO on **option A — decline AEF's offset-78 proposal as already satisfied.**

> This verdict has existed since the task was filed, as a `### Recommendation` sub-heading
> inside `## Context`. `tools/_norec-verify.py` anchors on `^## Recommendation`, so it could
> never see it, and your queue has shown this task as having nothing to act on. Promoted to a
> real section 2026-08-12 (T-454); the analysis below is re-measured, not inherited.

**Rationale:** Every producer-INPUT row of AEF's proposal is already asserted by two green
suites with working teeth. Building a third would assert what two already assert, and its
AEF-OUTPUT half would necessarily encode *our guess at their behaviour* and call it a
contract — the exact inversion the T-559 symmetric boundary exists to prevent. Declining is
not "no test"; it is "the test exists, on the correct side of the seam."

**Evidence — re-run today, 2026-08-12, not read off a checkbox:**
- `python3 tests/test_promote_contract.py` → rc 0:
  `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)`
  `manifest owner-bearing uids: n_inception {owner:human←sovereignty, workflow_type:inception};`
  `uid totality + byte-determinism + teeth verified`
- `python3 tests/test_two_lane_joint_contract.py` → rc 0, covering the second derivation:
  `n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}`
- The AEF-OUTPUT half has not crossed the seam since the proposal:
  `grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html` → **0**.
  Our exporter emits none of those fields, so no row has moved from their side to ours.

**What your ruling unblocks:** a reply on the rail telling a cooperating peer their proposed
test is unnecessary. That is a statement about *their* work, which is why it is yours and not
mine — I can measure that our side is covered, but declining a peer's offer is a seam
relationship call. Ruling A closes T-209; ruling B (build it anyway) re-opens the three
Agent ACs.

**Known limit:** this covers the promote/manifest contract only. The typed-event
serialization (T-204) is a different producer surface, still in motion on the rail, and is
deliberately not folded in here.

## Verification

python3 tests/test_promote_contract.py
python3 tests/test_two_lane_joint_contract.py
test 0 -eq "$(grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html)"

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

### 2026-07-19T15:42:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-209-832-side-compile-promote-create-producer.md
- **Context:** Initial task creation

### 2026-07-27T22:14:59Z — status-update [task-update-agent]
- **Change:** owner:  → human

### 2026-08-10T19:40:56Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
