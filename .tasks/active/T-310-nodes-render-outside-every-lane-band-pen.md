---
id: T-310
name: "Nodes render outside every lane band (pen_inbound_classifier): long trunk edges are the symptom, lane membership/height the cause"
description: >
  Operator field report (2026-07-29 screenshot, map pen_inbound_classifier, ~53 nodes / 5 lanes): roughly 14 nodes render below every lane band, in unlaned space past the 'Add another lane' strip. Long trunk edges spanning the full canvas width are the visible symptom, not the cause. Two candidate causes: (a) nodes absent from any lane's flowNodeRef, which tools/validate-workflow.py already detects as W-XML-NODE-UNASSIGNED; (b) nodes assigned to a lane but positioned outside its y-band because lane height is not grown to fit content, which no rule covers. Map bytes not reachable from the agent side - absent from our corpus, our gallery /api/list and AEF's - so the discriminating test needs the operator to supply the map.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [designer, layout, lanes, routing]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-29T20:38:03Z
last_update: 2026-07-29T20:51:48Z
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

# T-310: Nodes render outside every lane band (pen_inbound_classifier): long trunk edges are the symptom, lane membership/height the cause

## Context

Root cause **identified and independently corroborated** the same day this was filed — the two
candidate causes in the description have collapsed into one mechanism, and it is worse than the
rendering glitch it looks like.

### The mechanism

Three code facts in `src/aef-workflow-designer.html`:

1. **Import keeps two contradictory truths** (`:9607`). A node is pushed as
   `{ ..., lane: laneId, x, y }` — `laneId` from the `<bpmn:laneSet>` membership, `x`/`y` from
   `<aef:position>`. **Nothing reconciles them.** A node declared in lane A whose stored `y` falls
   inside lane B's band is imported as "in lane A, drawn in lane B", and renders where the geometry
   says.
2. **The first interaction silently rewrites the semantic** (`:6250`, `:6271`, `:6624`, `:7835`).
   `laneAtY(centerY)` derives lane from position, and callers assign it to `n.lane`. So the first
   drag of a mispositioned node changes *who is responsible for that step* — no prompt, no notice.
3. **Export believes `n.lane`** (`:9276`) — `flowNodeRef` is written from the rewritten value, so
   the change is durable on the next save.

`laneAtY` (`:2117`) also has a sharp edge of its own: a node below **every** band falls out of the
loop and returns `getLanes()[0]?.id` — the *first* lane. A node dragged into the void under the
pool is silently adopted by the top lane rather than left unassigned.

### Independent corroboration (AEF rail 331, observation (a))

AEF reported that a UI save "flipped lane MEMBERSHIP on 10/12 nodes while only kl_dormant and
kl_healing kept theirs", and asked whether membership is position-derived and whether the 2-node
exception is intent-pinning or a bug. Reproduced here from their served bytes
(`:3001/api/version?id=draft-knowledge-leveling&v=5` and `v=7`), matching nodes on `name` because
their generator emits no `aef:uid`:

| | v5 (agent-authored) | v7 (after UI saves) |
|---|---|---|
| `framework` members | 7 nodes, y 60–240 (**top**) | 5 nodes, y 140–502 |
| `agent` members | 5 nodes, y 440–600 (**bottom**) | 7 nodes, y 87–600 |
| lane order in `laneSet` | agent, then framework | agent, then framework |

Node positions barely moved (60→87, 440→402, 600→600) while membership inverted. **The source map
is internally inconsistent**: it declares `agent` as the first lane — so the designer draws the
agent band on top — while placing the framework-declared nodes at the top y-values. The designer
honours geometry, and the contradiction cashes out as a wholesale membership flip.

**Answer to AEF's question:** the 2-node exception is neither intent-pinning nor a separate bug.
Reassignment fires per-node on drag, not globally at save, so `kl_dormant` and `kl_healing` are
simply the two nodes the operator never dragged. They kept their imported membership; the other
ten did not.

### Relationship to `pen_inbound_classifier`

Same class. Nodes drawn outside every lane band are nodes whose stored position disagrees with
their declared membership — cause (a) and cause (b) from the filing description are the same
defect seen from two ends. The unlaned block in the screenshot is the rendering; the membership
rewrite on the next drag is the damage.

### Why this is ours to fix even though the input is malformed

Accepting a contradictory map is defensible. Silently resolving the contradiction *in favour of
pixels* and then writing the result back as authority is not — lane membership is the `who` in
this dialect (see T-189 on Lane=who). The fix is to detect the disagreement at import and make it
visible or reconcile it deliberately, rather than letting the first mouse gesture decide it.

Note the overlap with T-309: `W-XML-NODE-UNASSIGNED` already exists and would catch the *fully*
unassigned case, but no rule catches "declared in lane A, positioned in lane B" — that needs
geometry, which the structural validator does not see. This defect is not covered by surfacing
the validator.

## Acceptance Criteria

**Design decision (recorded in `## Decisions`): declared membership WINS, and the move is
announced.** Lane membership is the `who` in mapping-v1 (T-189); position is view-layer. When they
disagree the semantic must win and the view must be corrected to match — not the reverse, which is
what happens today. But the framework must not silently rewrite the operator's geometry either, so
the reconciliation is surfaced with a one-shot notice rather than performed invisibly.

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Import reconciles the contradiction: after lane bands are computed, any node whose centre-y
      falls outside its **declared** lane's band is repositioned into that band (x preserved). The
      contradiction therefore cannot survive into `state`, which is what makes the silent-rewrite
      path unreachable rather than merely discouraged.
      → `src/aef-workflow-designer.html` parse tail; harness reports `reconciled: 2` on the
      4-node fixture, and the two nodes that already agreed keep their exact y (110, 310).
- [x] `laneAtY` no longer adopts orphans: a y below every band returns `null` instead of
      `getLanes()[0]?.id`, and every caller (`:6250`, `:6271`, `:6624`, `:7835`) leaves `n.lane`
      unchanged when it gets `null`. Dragging into the void under the pool must not silently
      reassign a node to the top lane.
      → harness `laneAtVoid: null` (pre-fix build returns `agent`). Drag callers were already
      written `if (newLane) …` so they now no-op; `laneRowYs(null)` returns `[]`; `createNodeAt`
      carries its own explicit fallback. No caller needed changing — verified, not assumed.
- [x] The move is announced, not silent: a one-shot notice naming the count of repositioned nodes
      appears on load (house pattern — the existing Clean-layout nudge / T-264 collision notice).
      No notice when nothing was repositioned.
      → `#lane-fix-notice`, dismissible, reuses `.clean-nudge` chrome; renders
      "⚠ 2 nodes were drawn outside their declared lane — moved back into place".
- [x] **Zero export surface on well-formed maps, proven not argued:**
      `node tools/_t308-export-byte-identity-cdp.mjs <pre-change-sha>` reports
      `"drifted": 0` across all 24 corpus maps. Positions may only change for maps that were
      already internally inconsistent.
      → against `df5f5b6`: **24 maps, 24 identical, 0 drifted, 0 errors.**
- [x] A fixture reproducing the defect exists (`tests/fixtures/.../lane-position-conflict.bpmn`:
      declared membership deliberately disagreeing with `aef:position`, mirroring the AEF v5
      shape), and a CDP harness leg asserts the node lands in its **declared** lane after load and
      that a subsequent drag does not invert membership.
      → 8 legs in `tools/_t310-lane-position-conflict-cdp.mjs`, all green. **Teeth proven
      (PL-061):** run against the pre-fix source the same harness goes red on 6 real assertions,
      including the exact AEF inversion (`n_check: centre falls in agent, declared framework`)
      and the orphan adoption (`laneAtY(below all bands) = agent, expected null`).
      The fixture validates **clean** under `tools/validate-workflow.py` — deliberate, and the
      point: this class needs geometry, so no structural rule can see it.
- [x] The new leg is wired into `tests/run-bridge-tests.sh` and the suite reports `0 failed`.
      → **bridge round-trip: 45 passed, 0 failed** (44 before this leg); geometry sweep 24 clean.
- [x] Validator suite still reports `0 failed` (no regression to the structural checkers).
      → **34 passed, 0 failed.**
- [x] Regression guard against the original mechanism: a check asserts no caller assigns the result
      of `laneAtY` to `n.lane` without a null guard.
      → `## Verification` asserts `grep -c '\.lane = laneAtY('` is 0 and that `laneAtY`'s body
      still contains `return null`.

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

- [ ] [REVIEW] The reconciliation reads as a repair, not as the editor moving your work around
  **Steps:**
  1. Open the designer and load `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn`
     (📂 Open project… → or drag the file in).
  2. Read the notice at the top of the canvas and look at where the four nodes sit.
  3. Compare against `docs/screenshots/t310-both-before.png` (the same map on the old build).
  **Expected:** "framework validates the request" sits in **Framework · Authority** and "agent
  carries out the work" sits in **Agent · Initiative** — on the old build they were in each
  other's lanes. The notice says 2 nodes were moved back.
  **If not:** note which node is in the wrong lane and whether the notice count matches.

- [ ] [REVIEW] Judgement call worth your eyes: is "declared membership wins" the right default?
  **Steps:**
  1. Consider the alternative — keep the operator's pixels and instead flag the conflict, leaving
     the node visually where the author put it.
  2. Weigh it against what shipped: the node jumps to its declared lane on load, which changes
     the picture the author last saw.
  **Expected:** you agree the semantic (`Lane = who`, T-189) should outrank the geometry, so a map
  that says "framework owns this" draws it in the framework lane even if that moves it.
  **If not:** say so — the reconciliation is one `if` in the parse tail and the opposite policy
  (flag, don't move) is a small change from here.

- [ ] [REVIEW] Cosmetic: the stacked Clean nudge overlaps top-lane content
  **Steps:**
  1. In `docs/screenshots/t310-both-after.png`, look at the second banner ("This map could use
     Clean layout") sitting below the lane-fix notice.
  **Expected:** you're satisfied this is acceptable. **Known and not hidden:** when BOTH advisories
  show, the lower one sits at y=52px and can cover a node in the top lane (it covers
  `agt_2_agent` in that shot). The single nudge already overlapped canvas content at 12px, so this
  is the same behaviour one row down, and both banners are dismissible — but it is a real overlap
  and it is your call whether it needs solving.
  **If not:** the fix is either a canvas top-padding when advisories are visible, or docking them
  outside the canvas entirely — both are follow-up tasks, not this one.

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

# The T-310 contract itself: declared lane wins, agreements untouched, move reported,
# void no longer adopts, nothing leaks to the export, repair is idempotent.
out=$(timeout 300 node tools/_t310-lane-position-conflict-cdp.mjs 2>&1); echo "$out" | grep -q '"ok": true'
# Zero export surface on WELL-FORMED maps, against the explicit pre-change ref.
# Pinned to df5f5b6 deliberately, NOT HEAD — a HEAD-relative check compares the
# change against itself once committed and can never go red (PL-061 / T-307 class).
out=$(timeout 300 node tools/_t308-export-byte-identity-cdp.mjs df5f5b6 2>&1); echo "$out" | grep -q '"drifted": 0'
out=$(timeout 900 bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
out=$(timeout 600 bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
# The mechanism itself must stay dead: no caller may assign laneAtY's result to a
# node's lane without a guard, and laneAtY must still be able to answer "no lane".
test "$(grep -c '\.lane = laneAtY(' src/aef-workflow-designer.html || true)" = "0"
out=$(sed -n '/^function laneAtY/,/^}/p' src/aef-workflow-designer.html); echo "$out" | grep -q 'return null;'
# The fixture must stay structurally VALID — if a future rule starts catching it,
# this defect class stopped being geometry-only and the framing here needs revisiting.
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/lane-position-conflict.bpmn --format xml > /dev/null
# The reconcile counter must never become part of the document (T-308 discipline).
test "$(grep -c 'state\.laneReconcile\|n\.laneReconcile\|aef:laneReconcile' src/aef-workflow-designer.html || true)" = "0"

## Visual Verification

CSS and HTML changed, so DOM measurement is not sufficient (the harness proves the *numbers*;
these prove the *rendering*). Captured from the real editor in isolated headless chromium against
the conflict fixture, and **read**, not just taken. This designer has a single theme, so the
modes that exist here are the notice states and the canvas result — there are no light/dark/
density variants to sweep.

- `docs/screenshots/t310-both-before.png` — the defect on the pre-fix build: "framework validates
  the request" sitting in the **Agent · Initiative** band and "agent carries out the work" sitting
  in **Framework · Authority**. The operator's `pen_inbound_classifier` symptom in miniature.
- `docs/screenshots/t310-both-after.png` — same map, same fixture: both nodes now in the lane they
  declare. Lane-fix notice in the top slot, Clean nudge stacked below it, no collision between
  the two banners.
- `docs/screenshots/t310-notice-after.png` — element-level shot of the notice chrome; reads
  "⚠ 2 nodes were drawn outside their declared lane — moved back into place".

**Regression found by looking rather than measuring, and NOT hidden:** in the both-visible state
the stacked Clean nudge (y=52px) covers a node in the top lane. Pre-existing class — the single
nudge already floats over canvas content at 12px — but it is one row lower now and it is real.
Recorded as a `[REVIEW]` AC rather than quietly accepted.

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

**Symptom:** operator screenshot of `pen_inbound_classifier` — ~14 nodes drawn below every lane
band, with long trunk edges running the canvas width to reach them. Independently, AEF reported a
UI save "flipping lane membership on 10/12 nodes" in `draft-knowledge-leveling`.

**Root cause:** the designer imported two contradictory truths about every node and never
reconciled them — membership from `<bpmn:laneSet>`, geometry from `<aef:position>`. When a map
declared a node in lane A but positioned it in lane B's band, both survived into `state`. The
first drag then resolved the contradiction in favour of PIXELS (`laneAtY` → `n.lane`), and export
wrote the result back. Lane membership is the `who` in mapping-v1 (T-189), so an incidental mouse
gesture was silently rewriting who is accountable for a step. A second, narrower cause sat in
`laneAtY` itself: a y below every band returned `getLanes()[0]?.id`, so the void adopted nodes
into the top lane instead of admitting there was no lane.

**Why structurally allowed:** the defect is a disagreement between *semantics* and *geometry*, and
every checker we have is structural. `tools/validate-workflow.py` has both a YAML and an XML path
and the conflict fixture passes **clean** on the XML one — as does `W-XML-NODE-UNASSIGNED`, which
only catches a node in *no* lane, never a node in the *wrong* lane. AEF's lint missed it for the
same reason and said so on the rail. Both toolchains were blind to the same class simultaneously,
which is why it survived long enough to reach two operators independently. Geometry is not in
either checker's model, so no amount of rule-adding on the current architecture would have found
it — this needed a browser-level test.

**Prevention** (distinct from the fix): the contradiction is now made *unrepresentable* rather
than merely discouraged — reconciliation happens at parse, so no contradictory state exists for a
later gesture to resolve. Beyond that: (a) `tests/test_t310_lane_position_conflict.py` in the
bridge suite, whose harness is teeth-proven to go red on the pre-fix build; (b) two `##
Verification` greps pinning the mechanism dead — no unguarded `.lane = laneAtY(`, and `laneAtY`
must still be able to answer "no lane"; (c) a Verification line asserting the fixture stays
structurally valid, so if a future rule ever *does* catch it, the "geometry-only" framing here is
forced to be revisited rather than quietly going stale.

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

### 2026-07-29T20:38:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-310-nodes-render-outside-every-lane-band-pen.md
- **Context:** Initial task creation

### 2026-07-29T20:51:48Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
