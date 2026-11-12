---
id: T-976
name: "Import layout ignores flow order: an unpositioned map is laid out in document
  order, so a generator must hand-compute geometry or get End before its tasks"
description: >
  Found under T-975 by importing an Evergreen map with its DI stripped: nodes placed
  in document order (End_12 at x=210 before Assembly at 300), overlapping; Clean layout
  keeps the order. A flow-aware layering (topological by sequenceFlow, within lane
  bands) on import would let any generator omit geometry and still get a readable
  map: the operator's original 'layout is really messy' complaint, at its root.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
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
created: 2026-10-01T18:10:06Z
last_update: '2026-11-12T12:20:32Z'
date_finished:
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
  - ts: '2026-11-12T12:20:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 3
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 2
      F3: 0
      F1: 2
    rationale: 'D1=2 (body:learning-ref); D2=0 (no-signal); D3=3 (body:component-discoverability);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=2 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L1:keyword=lane);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=2 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L2:keyword=import)'
    rubric_sha: e4a00f38e801
---

# T-976: Import layout ignores flow order: an unpositioned map is laid out in document order, so a generator must hand-compute geometry or get End before its tasks

## Context

**Background / trigger:** found under T-975: an Evergreen map with its DI stripped imported with nodes in document
order (End_12 at x=210 before Assembly at 300), overlapping. Greenfield's map is client data, so it is not a fixture.

**Problem / hypothesis:** `parseBpmnXml` gives an unpositioned node `x = POOL_X + LANE_HEADER + 30 + sameLane.length * 90`
(src ~15872): its index in the FILE's list within its lane, 90 px apart, so order follows the file and tasks overlap.

**Goal:** a file that positions none of its nodes is laid out along its flows.

**Expected outcome:** every node right of what leads to it (loop-back flows aside), no overlaps; files with positions
unchanged (corpus bytes identical).

### Prototype (2026-11-11, agent; built and measured in a scratch copy, NOT yet in src)
Synthetic fixture (no DI, elements listed End-first, two lanes Sales/Warehouse, branch "In stock?" yes→Pick→Ship,
no→Reject, merge, end, and a loop "recheck" Reject→Check): TODAY 6 of 9 flows point backwards and 2 pairs overlap;
PROTOTYPE 1 backward flow (the loop), 0 overlaps, order Order received → Check → In stock? → Reject | Pick → Ship → Merge
→ Done. Recreate the fixture under `tests/fixtures/t976/flow-order-no-di.bpmn` from that description.
Change (three edits in `parseBpmnXml` + one helper):
1. after `const nodes = [];` add `const autoPos = new Set();`; in the default-position branch add `autoPos.add(uid);`
2. before `_laneGrowReport = growUnderDeclaredLanes(lanes, nodes);` add
   `if (nodes.length && nodes.every(n => autoPos.has(n.uid))) layoutByFlowOrder(nodes, edges);` (only when NO node has a
   position: a partly positioned file keeps today's placement)
3. helper `layoutByFlowOrder(nodes, edges)` before `function getLanes()`: PITCH 160; forward edges = edges between
   known nodes, not self-loops; DFS from sources (nodes with no incoming; then any unvisited) in file order marks an edge
   to a node still on the stack as a back edge; Kahn's topological order over the rest gives depth = longest path;
   slot = index of the node among nodes of the same lane at the same depth; column width[d] = max slots of any lane at
   d; colX[d] = cumulative width × PITCH; x = POOL_X + LANE_HEADER + 30 + colX[depth] + slot × PITCH. y stays 0 (the
   parse tail puts it at the lane centre).
Still to do: a harness (order + no overlap, red on the source before), `_t308` 24/24 and third-party goldens unchanged
(they carry positions), screenshots at three widths, gate, sweep, reviewer, both tiers.

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A file that positions NONE of its nodes is laid out along its sequence flows: on
      `tests/fixtures/t976/flow-order-no-di.bpmn` every flow except the loop-back ("recheck") points left-to-right, and no
      two nodes overlap. Measured by a CDP harness that is red on the source before the change (6 backward flows,
      2 overlapping pairs) and green after.
- [x] A file that positions any of its nodes is untouched: `_t308` 24/24 and the third-party byte-identity goldens
      unchanged (no re-record), and the harness has a partly-positioned arm that keeps today's placement.
- [x] Lanes keep their members: every node stays in its declared lane band after the layout.
- [ ] The "what a person sees" gate exits 0; screenshots of the fixture at 1024/1440/1920 recorded in
      `## Visual Verification`; advisory sweep run; both suite tiers green.

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
- [x] [REVIEW] A map without positions opens laid out along its flows, readable at three widths
  **Why you:** a render-surface judgement on screenshots (CLAUDE.md "UI changes are reviewed on screenshots"); for the independent reviewer: `fw reviewer judge T-976 --criterion 1`.
  **Steps:**
  1. Open `docs/reports/T-976-evidence/flow-order-no-di-1024.png`, `-1440.png` and `-1920.png`: the synthetic map
     `tests/fixtures/t976/flow-order-no-di.bpmn` (no positions, elements listed End-first, lanes Sales and Warehouse)
     just opened.
  2. At 1920, follow the flows: Order received → Check the order → In stock? → no: Reject and notify / yes: Pick the
     items → Ship the order → Merge → Done, each step right of the one before; the loop "recheck" (Reject → Check) is
     the only flow running back. Check no two nodes overlap, no label collides with another, every node is in its lane.
  3. At 1024 and 1440, check the map's left part is drawn the same way and the rest is reachable by scrolling (it is
     wider than the canvas there, as any long map is).
  **Expected:** the map reads left to right in flow order, uncluttered, in its lanes, at every width.
  **If not:** name the screenshot and what reads wrong (order, overlap, a flow through a node, a label clash), and
  set the task to issues.
  **Reviewer verdict:** green V-20261112-aaf05067 — reviewer-judge-t-976-r3-5ecf4fd18ae9:reviewer (rung rung-3-termlink-single-reviewer), digest 9f94a9f42107; dispatch judge-t-976-r3-5ecf4fd18ae9; evidence: .context/reviews/evidence/T-976/AC1-judge-t-976-r3-5ecf4fd18ae9.md, .context/reviews/evidence/T-976/flow-order-no-di-1024-judge-t-976-r3-5ecf4fd18ae9.png, .context/reviews/evidence/T-976/flow-order-no-di-1440-judge-t-976-r3-5ecf4fd18ae9.png, .context/reviews/evidence/T-976/flow-order-no-di-1920-judge-t-976-r3-5ecf4fd18ae9.png; ledger .context/reviews/verdicts.jsonl

## Verification
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" node tools/_t976-flow-order-cdp.mjs --self-test > /tmp/.t976.out 2>&1 && grep -q "poison arm is caught" /tmp/.t976.out
grep -q "if (nodes.length && nodes.every(n => autoPos.has(n.uid))) layoutByFlowOrder(nodes, edges);" src/aef-workflow-designer.html
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" node tools/_t308-export-byte-identity-cdp.mjs > /tmp/.t976-308.out 2>&1 && grep -q '"identical": 24' /tmp/.t976-308.out
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" node tools/_t358-byteid-thirdparty.mjs > /tmp/.t976-byteid.out 2>&1 && grep -q "PASS" /tmp/.t976-byteid.out
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" bash tools/_t1288-prepush-gate.sh
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" bash tests/run-bridge-tests.sh --tier browser > /tmp/.t976-browser.out 2>&1 || { grep -E '\[FAIL\]|^tier ' /tmp/.t976-browser.out; false; }

## Visual Verification

Screenshots in `docs/reports/T-976-evidence/` (`_t976-flow-order-cdp.mjs --shots`), the fixture just opened, at
1024/1440/1920. The person-sees gate (exit 0, 266 s) runs over the corpus, which all carries positions, so it does not
see this layout; its class checks (overlaps, flows through nodes, label collisions, lanes) are legs F3-F6 of the T-976
harness, each proven to bite by a poison arm (columns 40 px apart).

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| map opened | flow order left to right | ok | ok | ok | at 1024/1440 the right part is under the details panel, reached by scrolling: measured by leg F7 (1024: Done fully visible and clickable at scrollLeft 640 of 1116), added after the advisory sweep said screenshots cannot show it |
| map opened | nodes in their lanes, no overlap | ok | ok | ok | |
| map opened | flow labels (yes / no / recheck) | ok | ok | ok | "recheck" runs along the pool's title border (existing loop routing) |
| map opened | toolbar, palette, details panel | ok | ok | ok | unchanged by T-976 |

Read: `flow-order-no-di-1920.png` — the whole map: Order received, Check the order, In stock?, then Reject and notify
(Sales) and Pick the items (Warehouse) in one column, Ship the order, Merge and Done; "no" and "yes" labels on their
flows; the loop "recheck" goes up over Check and In stock? and back into Check. `-1440.png` shows up to Ship the order,
`-1024.png` up to In stock?; the rest lies under the details panel with a horizontal scrollbar. Trade-off: the layout is
about 1,100 px wide (old: about 700 px, with nodes on top of each other).

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

### 2026-10-01T18:10:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-976-import-layout-ignores-flow-order-an-unpo.md
- **Context:** Initial task creation

### 2026-11-12T12:20:31Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
