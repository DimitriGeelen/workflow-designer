---
id: T-112
name: "Obstacle-avoiding orthogonal edge router for corpus node-cuts"
description: >
  Inception: Obstacle-avoiding orthogonal edge router for corpus node-cuts

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-05T20:38:14Z
last_update: 2026-07-05T20:38:54Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-112: Obstacle-avoiding orthogonal edge router for corpus node-cuts

## Problem Statement

Edges in the rendered corpus sometimes route straight through the box of a node
they are not connected to — a **node-cut**. A cut is a pure visual-legibility defect:
the reader momentarily reads the crossed node as being on the edge's path. The T-092
routing survey counted ~42 cuts corpus-wide, but that count **predates** both the
T-101 Clean bake and the Phase-C one-shot actions (align-rows T-094, align-columns
T-107, distribute T-109, routing-margin T-106). The last routing-quality class we have
not addressed is node-cuts, and the candidate fix — an **obstacle-avoiding orthogonal
edge router** — is design-sized and touches the editor's edge engine, which carries
real regression surface (PL-005: JS editor logic must not be casually reimplemented or
perturbed). Before committing to that build we must know whether the problem is still
big enough to justify it, or whether Phase C already dissolved most of it.

**For whom:** operators reading rendered AEF process maps (legibility).
**Why now:** Phase C just shipped; the corpus has never been re-measured against the
current editor. This is the cheapest moment to decide build-vs-drop with real evidence.

## Assumptions

- **A-1 — VALIDATED.** The ~42-cut figure is stale; current corpus is 27 incidences /
  21 cut-edges (T-112 §1).
- **A-2 — VALIDATED.** Cuts concentrate in fan/join-heavy maps: 74% in harvest + error-esc;
  17/24 maps cut-free (T-112 §1).
- **A-3 — PARTLY REFUTED.** No single cheap action dissolves cuts (align-cols/distribute/
  routing-margin = 0 effect; Clean only −40%). But a *free* Clean re-bake win surfaced —
  the baked corpus is Clean-stale (T-112 §2).

## Open Questions

- **IW-1: How many node-cuts actually remain across the 24-map rendered corpus after the T-101 bake + Phase-C actions?**
  confidence: 3
  disposition: answered
  rationale: measured 21 cut-edges / 27 incidences via editor's own `polylineCrossesNodes` over all 24 maps (docs/reports/T-112 §1). The ~42 figure is stale.

- **IW-2: Are the remaining cuts concentrated in a few maps or spread across the corpus?**
  confidence: 3
  disposition: answered
  rationale: harvest-pipeline (13) + error-escalation-ladder (7) = 20/27 incidences (74%); 17/24 maps cut-free (T-112 §1). Concentrated in dense fan/join topology — A-2 validated.

- **IW-3: Do cheaper existing mitigations (re-run Clean, T-106 routing-margin, manual waypoint drag) already dissolve most cuts, leaving a residue too small to justify a router?**
  confidence: 3
  disposition: answered
  rationale: only Clean helps and only 38–43% (harvest 13→8, error-esc 7→4); align-cols/distribute/routing-margin leave cuts unchanged (T-112 §2). Majority survive → residue is material. A-3 partly refuted (no single cheap action dissolves them) but surfaced a free Clean-rebake win.

- **IW-4: What is the regression surface of adding an obstacle-avoiding router to the editor's edge engine?**
  confidence: 3
  disposition: answered
  rationale: editor already routes crossing-aware (`needsLoop`→`orthoLoopBack` min-crossing band, src:3629-3637); residue = band heuristic can't zero crossings. A router replaces the band-pick at ONE bounded insertion point (src:3636) with clean fallback; blast radius corpus-wide but the census probe is a ready regression harness (T-112 §3).

## Exploration Plan

1. **Measure (time-box 45 min).** Headless Playwright over all 24 rendered maps on the
   gallery (:8834). Define a `nodeCuts()` probe in the live editor: for each edge, test
   its orthogonal polyline segments against every non-endpoint node rect
   (`rectsIntersect`/segment-in-rect), count intersections. Produce a per-map histogram
   and corpus total. **Uses the editor's own geometry (`nodeRect`, edge waypoints) — no
   re-implemented layout logic (PL-005).**
2. **Test cheap mitigations (time-box 30 min).** On the worst maps, measure cut count
   before/after (a) re-running Clean, (b) enabling T-106 routing-margin, (c) a manual
   waypoint nudge on the offending edge. Quantify how much residue a router would own.
3. **Scope the regression surface (time-box 20 min).** Read the editor's edge routing
   code path (`routeEdge` / waypoint construction) to characterise where an
   obstacle-avoiding step would insert and what it could perturb.
4. **Synthesise** into `docs/reports/T-112-node-cut-router-inception.md` and revise the
   filing DEFER into a GO / NO-GO / DEFER recommendation for human decision.

## Technical Constraints

- **Editor-internal only.** All measurement drives the live editor via Playwright and
  reads in-editor geometry; the corpus (`examples/**`) is never written (PD-044).
- **PL-005:** the cut probe must use the editor's own `nodeRect`/waypoint data, not a
  re-derived layout — a re-implemented metric silently drifts (see T-110 phantom regression).
- **Gallery harness:** served file `build/gallery/designer.html` must stay byte-identical
  to `src/aef-workflow-designer.html`; the probe adds no persistent editor code (it runs
  as an ephemeral `browser_evaluate` function, not a committed editor change).
- Any GO build would touch the SVG orthogonal edge engine — no new dependencies, must
  stay within the single-file editor.

## Scope Fence

**IN:** counting and characterising node-cuts in the current corpus; testing whether
existing actions dissolve them; scoping the regression surface of a router; producing a
go/no-go recommendation.
**OUT:** building the router (that is the GO build task, filed separately per inception
discipline); changing the corpus; any editor source change under this inception ID.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Measured post-Phase-C cut count is materially high (heuristic: **≥ 15 cuts** across the
  corpus, or **≥ 4 cuts on a single map**) AND
- The residue after cheap mitigations (Clean re-run, routing-margin, waypoint nudge) is
  still material (heuristic: **> 50% of cuts survive** the cheapest applicable action) AND
- The regression surface is bounded (router inserts at a single identifiable point in the
  edge path with a clean fall-back to today's routing).

**NO-GO / DEFER if:**
- Phase C already reduced cuts below the material threshold (**< 15 corpus-wide**), OR
- Cheap existing mitigations dissolve most cuts (router would own too small a residue), OR
- The router cannot be inserted without perturbing the existing edge engine in ways that
  risk the wider corpus (PL-005) — i.e. cost exceeds the legibility benefit.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO (sequenced — cheap Clean re-bake first, then the router)

**Rationale:**

The exploration answered all four open questions with verified measurement (confidence 3).
Node-cuts remain a **material, concentrated** legibility defect that **no cheap action
dissolves**, and the router has a **bounded insertion point with a ready regression harness** —
this clears the GO bar. Two caveats shape it into a *sequenced* GO rather than a blank one:
(1) the corpus is Clean-stale, so a cheap re-bake harvests ~40% of cuts first, for free; and
(2) the editor already routes crossing-aware, so the build is a targeted heuristic replacement,
not a greenfield router. I therefore recommend GO on the router **after** a separate cheap
Clean-rebake task, with the census probe as the non-regression gate. Decision is human-owned.

**Evidence:**

- **Census (IW-1/IW-2):** 21 cut-edges / 27 incidences across 24 maps — not the stale ~42.
  74% (20/27) concentrated in harvest-pipeline (13) + error-escalation-ladder (7); 17/24 maps
  cut-free. Measured with the editor's own `polylineCrossesNodes`. → docs/reports/T-112 §1.
- **Mitigation (IW-3):** re-run Clean −38–43% only; align-cols/distribute/routing-margin =
  no change. Majority of cuts survive the cheapest action (8/13, 4/7). → T-112 §2.
- **Free win:** re-running today's Clean on the *baked* corpus reduces cuts ⇒ the T-101 bake
  is stale vs current Clean ⇒ a corpus re-bake is a near-zero-risk ~40% reduction. → T-112 §2.
- **Regression surface (IW-4):** editor already diverts crossing paths via `orthoLoopBack`'s
  min-crossing band (src:3629-3637); residue = band can't zero crossings in dense maps. Router
  = replace band-pick at src:3636 with pathfinding + clean fallback; blast radius corpus-wide
  but the census probe is a ready before/after harness. → T-112 §3.
- **GO-threshold check:** ≥15 corpus-wide (27 ✓); ≥4 on one map (13, 7 ✓); >50% survive
  cheapest mitigation (62%, 57% ✓); bounded insertion point (✓). All met.

**Follow-up build tasks a GO would authorise (filed separately, per inception discipline):**
1. *(cheap, do first)* Re-bake Clean into the 24-map corpus (T-101 redux) — harvest the free ~40%.
2. *(the router)* Obstacle-avoiding orthogonal routing at the `needsLoop` branch, clean
   fallback, gated by the census non-regression harness. `target_blast_radius: 3` fits.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-05T20:38:54Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
