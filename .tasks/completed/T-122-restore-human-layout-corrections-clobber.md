---
id: T-122
name: "Restore human layout corrections clobbered by corpus re-bake (task-lifecycle
  + audit other re-baked maps)"
description: >
  Operator report (2026-07-06): this session's corpus re-bake (7d4fa0a) overwrote
  the human's manual layout corrections with a worse auto-generated layout — in
  task-lifecycle the AGENT-lane row dropped to y=600, opening a large vertical gap
  and sprawling every cross-lane edge. This is a sovereignty violation (agent
  auto-layout must not clobber human layout). Restore the human layout for every
  map the re-bake changed, and register the bake-tool gap that allowed it.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [ui, editor, corpus, bug, layout, sovereignty]
components: []
related_tasks: [T-101, T-121]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-06T06:39:43Z
last_update: '2026-08-16T14:33:14Z'
date_finished: 2026-07-06T08:19:39Z
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
  - ts: '2026-08-16T12:33:38Z'
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
  - ts: '2026-08-16T14:33:14Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 5
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=5 (prose:routing-engine); 
      F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:16Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/bake-clean-layout.py,tools/yaml-to-bpmn.py); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-122: Restore human layout corrections clobbered by corpus re-bake (task-lifecycle + audit other re-baked maps)

## Context

The operator hand-corrected corpus layouts (compact, calm cross-lane edges). This
session's re-bake `7d4fa0a` ("re-bake corpus with align-columns") ran the editor's
cleanLayout headless and wrote the auto-layout back into the *.workflow.yaml
sources — silently replacing the human's positions. In task-lifecycle the AGENT
row (n_authoring/n_work/n_request) moved to y=600, over-deepening the lane.

The stored geometry is the human's sovereign artifact; the re-bake was an agent
action that overwrote it (PD-044 / sovereignty). Fix = restore the pre-re-bake
(human) geometry for every map 7d4fa0a touched, then register the bake-tool gap.

## Acceptance Criteria

### Agent
- [x] Identify the maps `7d4fa0a` changed (`git show --stat 7d4fa0a`): 10 maps, ±3px
      align-column x-nudges only; task-lifecycle NOT among them. See ## Evolution.
- [x] "Restore human geometry" — RESOLVED BY INVESTIGATION, no restore performed: git
      history proves there is no committed human layout to restore. task-lifecycle agent
      row = y=560 pre-any-bake (`832bc9b^`) → y=600 first bake (`832bc9b`, a 40px shift),
      current == 832bc9b; `7d4fa0a` never touched it. The operator's compact layouts were
      live editor demonstrations, never committed. Reverting recovers ~40px, not the
      demonstrated compaction — a wrong action, correctly NOT taken.
- [x] Track B (learn the rules & encode) — investigated via T-123 (label-on-gateway =
      cramping symptom, wrong locus for a scorer) and T-124 (content-fit fan-spacing =
      measured NO-GO; the pitch lever clears only 1/9 residual overlaps). Corpus is
      objectively clean (0 node-cuts/24; residuals minor & mostly already-handled).
- [x] Bake-guard gap: latent risk noted (bake writes geometry unconditionally, no
      human-lock). NOT registered as a formal concern — no actual undetected incident
      occurred (the "clobber" didn't happen), so a formal G-019 gap would be speculative.
      Prevention (a per-map `layout: manual` lock or diff-warn+confirm before re-bake) is
      a workflow-design choice left to the operator. See ## Decisions.
- [x] No editor JS change; no corpus geometry restored/re-baked — sources untouched.

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

**Symptom:** task-lifecycle (and likely other maps) opens with a sprawled auto
layout — AGENT-lane row at y=600, long cross-lane edges — instead of the operator's
compact hand-corrected layout (their image #9 vs my auto image #10).

**Root cause:** This session's re-bake `7d4fa0a` ran cleanLayout headless and wrote
the auto-positions back into the `*.workflow.yaml` sources, overwriting the human's
manual layout corrections. The bake treats stored geometry as regenerable; but once
a human has hand-corrected a layout, that geometry is a sovereign artifact.

**Why structurally allowed:** `tools/bake-clean-layout.py` has no guard against
clobbering human edits — it re-derives and writes geometry unconditionally. Nothing
marks a map as "human-corrected, do not auto-bake," and no diff-warn surfaces before
overwriting. PD-044 covers render passes but not the bake tool.

**Prevention:** (a) bake must not overwrite a human-corrected map without explicit
re-authorisation (a per-map `layout: manual` lock, or a diff-warn+confirm gate);
(b) register in concerns.yaml. AND (the operator's ask, 2026-07-06) — mine the
before/after correction pairs to extract the *rules* the human applied, then encode
them into cleanLayout so the auto-layout produces the human-preferred result and
stops diverging. See ## Decisions "Forward plan".

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

### 2026-07-06 — Track A premise OVERTURNED by git verification (fresh session)
- **What changed:** Verified the actual commits instead of trusting the budget-ceiling
  narrative. `7d4fa0a` ("re-bake with align-columns") made only **±3px x-nudges** to 10
  maps (e.g. `x:200→197`, `x:200→203`) and **does NOT touch task-lifecycle**. Full
  history: pre-any-bake (`832bc9b^`) agent row = y=560, first bake (`832bc9b`) = y=600 —
  a **40px** shift, and current == 832bc9b. `7d4fa0a` is irrelevant to task-lifecycle.
- **Decisive finding:** the compact hand-corrected layouts the operator showed in the
  before/after images were **never committed to git** — they were live editor
  demonstrations. There is no committed "human layout" to restore; reverting the bakes
  recovers ~40px, not the demonstrated compaction.
- **Plan impact:** Track A ("restore clobbered human layout from git") is **moot**. The
  real ask is fully Track B. Corpus census (headless, this session): **0 node-cuts /
  24 maps**, 1 edge-label∩label, 8 label-on-gateway; lane-waste ~250px/map avg (modest,
  largely structural — lane order, not inflated heights).
- **Triggered:** pivot to Track B scoped tasks — (1) label-on-gateway render-only fix,
  (2) a compaction "fit-spacing-to-content" rule in cleanLayout, tool-only / no re-bake
  so the clobber cannot recur. Track A ACs below are resolved-by-investigation.

## Decisions

### 2026-07-06 — Forward plan (two tracks; execute next session, fresh budget)

**Track A — restore the human layout (this task, T-122):**
1. `git show --stat 7d4fa0a` → list the `*.workflow.yaml` it changed = clobbered maps.
2. For each clobbered map, restore the pre-bake (human) geometry:
   `git checkout 7d4fa0a^ -- examples/aef-processes/<map>.workflow.yaml`
   — BUT do NOT blanket-checkout: inception-review was legitimately changed AFTER by
   T-121 (`c1c47eb`), so EXCLUDE inception-review (keep its T-121 state).
3. Re-render each restored map (`python3 tools/yaml-to-bpmn.py <yaml> --out rendered/<map>.bpmn`),
   mirror to `build/gallery/rendered/`, validate.
4. Verify task-lifecycle AGENT row is back to the compact y (image #9); screenshot + READ.
5. Register the bake-clobbers-human gap in concerns.yaml (G-019).
   NOTE: `7d4fa0a` was MY commit this session; reverting its geometry is correct —
   the human layout is sovereign. Confirm nothing else desirable is lost.

**Track B — learn the human's rules and encode them (the operator's 2026-07-06 ask):**
The operator will feed more before/after pairs (their correction vs my auto-layout).
Approach:
1. For each pair, diff the geometry (which nodes moved, by how much, in what direction)
   and the resulting edge routes — extract the *invariant* the human enforced
   (e.g. "cross-lane sequential nodes share a column", "keep the agent row within
   ~100px of the framework row — don't over-deepen lanes", "align connected nodes by
   centre not top").
2. Generalise each invariant into a cleanLayout / router rule, guarded (no new
   node-cuts / crossings / overlaps), measured corpus-wide before shipping — the
   established T-117/118/119/097 pattern.
3. Ship as separate, scoped tasks (one rule = one deliverable). This makes the
   auto-layout converge to the human's taste so Track A's clobber can't recur in spirit.
- **Why:** Restoring one map (Track A) is necessary but treats the symptom; encoding
  the human's rules (Track B) is the antifragile fix — the corrections become
  training signal for the layout engine. Both are in scope of the operator's ask.
- **Feasibility:** YES, possible. The corrections are concrete geometry deltas; the
  layout engine (cleanLayout) is where align-rows/columns/pitch already live, so new
  rules slot in. The guard harness (crossings/cuts/overlap, render-only measurement)
  already exists from this session's routing work.

## Correction pairs (Track B training data — operator-supplied before/after)

### Pair 1 — task-lifecycle (my auto = before, human = after)
- **Delta:** AGENT-lane row (n_authoring/n_work/n_request) pulled UP; large empty
  vertical band between FRAMEWORK and AGENT lanes removed. Cross-lane edges shortened.
- **Rule signal:** don't over-deepen lanes; keep the agent row snug to the framework row.

### Pair 2 — promotion-pipeline (my auto = before, human = after)
- **Delta (dominant):** aggressive VERTICAL COMPACTION — the after is ~half the
  height. Each lane shrinks to fit its content; the tall empty AGENT band (only the
  start node) and the deep HUMAN band collapse. Start→Load drop shortened.
- **Delta (secondary):** "Warn early promotion" satellite moved UP from below the
  main row (~y480) to roughly inline with it (~y330), so the `<3 (early)` branch
  reads as a horizontal detour around the node rather than a deep drop; `≥3` routes
  over the top, `<3 (early)` under.
- **Node x positions ~unchanged** — the correction is almost entirely vertical.

### Pair 3 — arc-lifecycle (my auto = before, human = after)
- **Delta:** VERTICAL COMPACTION again — after is ~half the height. In my auto-layout
  each lane is inflated to a large ~uniform height, so the AGENT main-flow row sits at
  the BOTTOM of a tall lane (y~530) while HUMAN approvals sit at the TOP of the top
  lane (y~80) → the BVP-rescore→Approve and Approve→Work edges are giant ~450px
  verticals across empty bands. Human shrank every lane to fit its content; the giant
  connectors collapse to short hops. Node x-positions unchanged.
- **Mechanism identified:** the culprit is **lane-height calculation** — my
  auto-layout gives lanes a large/uniform height independent of content, and parks the
  row at the lane edge. Fix: `laneHeight = contentExtent + padding`, and place the row
  within the fitted lane. This is the concrete lever behind rules 1 & 2.

### Pair 4 — assumption-validation (ROUTING-class, not layout)
- **Key distinction:** node positions are ~IDENTICAL between before/after — so this pair
  teaches an EDGE-ROUTING rule, not a node-placement one (unlike pairs 1–3).
- **Delta observed:** the human version routes the branch edges into cleaner, more
  separated channels. Most visible: the `supported` branch (gateway → Mark validated)
  takes a clean high corridor through the empty HUMAN lane band rather than a lower run
  through the congested FRAMEWORK band; the start-edge and the Register→Gather feedback
  are staged so their vertical risers don't stack on one x.
- **Candidate rule (VERIFY before encoding):** route long cross-cutting branch edges
  through empty lane/vertical space as dedicated corridors, and give near-parallel
  risers distinct x-channels — don't stack runs in the busy band.
- **⚠ Needs precise in-browser geometry diff next session** — the before/after
  difference is subtle and routing-rule mistakes can regress other maps, so measure the
  exact polylines (not eyeball) before turning this into a router change. Do NOT encode
  from the screenshot alone.

### Pair 5 — inception-lifecycle (mixed: mild compaction + gateway placement)
- **Delta:** node x-positions ~unchanged; the after is a bit tighter vertically AND
  the `Decision?` gateway MOVED — in my auto-layout it sat up in the HUMAN lane at the
  same height as the "Record decision" node (y~135), forcing long drops down to the
  go/no-go/defer completion nodes in the FRAMEWORK lane; the human moved it DOWN into
  the framework band (y~165), in line with its branch-target column, so the fan is
  short/clean. The human "Record" node stayed high in its lane.
- **Candidate rule:** a routing/decision gateway belongs in the same row-band as its
  branch TARGETS (short fan), not stranded in the lane of its human owner. Separate the
  "who decides" node (human lane) from the "route to outcomes" gateway (target lane).
- **Also reinforces:** compaction + distinct riser channels (near-parallel cross-lane
  edges step to their own x). Measure exact polylines next session before encoding.

### Pair 6 — audit-process (decision-fan outcome spacing; ROUTING/spacing-class)
- **Delta:** structure/nodes ~same; the human gave the three decision outcomes of
  "Worst finding level?" (FAIL up / WARN mid / PASS clean) MORE, more-even vertical
  separation — Audit PASS pushed well down and the `clean` branch given its own clear
  drop-channel instead of crowding the WARN branch. The left fan-out/join comb is ~same.
- **Candidate rule:** a decision gateway's branch endpoints get generous, even vertical
  spacing so the fan reads as N distinct branches; the "straight-through" outcome
  shouldn't sit tight against a neighbouring branch. (Complements pair-5 gateway rule.)
- **Diminishing marginal signal:** pairs 4/5/6 are all routing/spacing variations —
  the DOMINANT rule (compaction via lane-height) is already locked from pairs 1/2/3.
  These three refine the routing family; measure their polylines together next session.

### Pair 7 — error-escalation-ladder (INVERSE case: auto was too CRAMPED)
- **Delta (important — refines the whole model):** here my auto-layout was too DENSE,
  not too sparse. The before is a mess — the `which rung?` gateway sits right on top of
  node A, the `1st occurrence`/`technique gap` labels overlap the gateway and nodes, the
  A/B/C/D branches and their edges collide. The human SPREAD it out: big horizontal run
  from the gateway to the A–D branch column (~400px) so the four fan edges get distinct,
  labelled channels; A/B/C/D evenly separated; and the [CODE] diagnose/resolve nodes
  pulled UP near the partners they connect to (short `auto-trigger diagnose` / `log
  resolution` edges instead of huge verticals down to the far lane).
- **Refined meta-rule:** the auto-layout mis-sizes spacing in BOTH directions — it
  leaves empty bands where content is sparse (pairs 1–3 → shrink) AND crams nodes where
  content is dense (pair 7 → spread). The correct rule is **fit spacing to content:
  enough that edges/labels never overlap, no more.** Not "always compact."
- **Concrete levers:** (a) fan-out gateway needs enough horizontal run to its branch
  column for N distinct labelled edge channels; (b) branch pitch ≥ label height + pad;
  (c) place connected cross-lane nodes near each other (short edges), which is the same
  lane-height/compaction lever viewed per-edge.

### Synthesized rules so far (candidate cleanLayout/router improvements)
1. **Height-fit lanes** — a lane is only as tall as its content + padding; never leave
   large empty vertical bands. (Pairs 1 & 2 — the dominant, repeated signal.)
2. **Minimise inter-lane gap** — sequential cross-lane hops are short; don't stretch
   the vertical distance between a lane's row and the next lane's row.
3. **Branch/satellite nodes align to their source row** where space allows, so a
   branch is a horizontal detour, not a deep vertical drop. (Pair 2 — Warn node.)
4. **Cross-lane sequential nodes share a column** (T-121 — emit/human).
5. **Align connected nodes by centre, not top** (the ±4px straighten hooks).
Unifying theme: the human wants a COMPACT vertical layout (min lane heights, min gaps,
aligned rows); the auto-layout over-inflates vertical space. Each rule ships as its
own scoped task, guarded + measured corpus-wide before merge.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-06T06:39:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-122-restore-human-layout-corrections-clobber.md
- **Context:** Initial task creation

### 2026-07-06T08:19:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
