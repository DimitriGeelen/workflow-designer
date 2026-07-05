# T-112 — Obstacle-avoiding orthogonal edge router (inception)

**Task:** T-112 (inception, owner: human) · **Date:** 2026-07-05 · **Filing recommendation:** DEFER
**Harness:** Playwright MCP against the served gallery (`tools/serve-gallery.sh`, :8834),
driving the live editor read-only. Corpus (`examples/**`) never written (PD-044).

> **C-001 note:** this artifact is created *before* the exploration and updated
> incrementally as findings land. The thinking trail IS the deliverable.

## Question

Is an obstacle-avoiding orthogonal edge router worth building, given the corpus as it
stands *after* the T-101 Clean bake and the Phase-C one-shot actions? The last routing
survey (T-092) counted ~42 node-cuts, but that number predates all of that work.

A **node-cut** = an edge whose orthogonal polyline passes through the rectangle of a node
it does not connect to. Pure legibility defect.

## Method

1. **Measure** — headless probe over all 24 rendered maps: for each edge, test its
   polyline segments against every non-endpoint node rect; count intersections. Per-map
   histogram + corpus total. Uses the editor's own `nodeRect` + rendered edge geometry
   (PL-005 — no re-implemented layout).
2. **Mitigate** — on the worst maps, re-measure after (a) re-run Clean, (b) routing-margin
   (T-106), (c) manual waypoint nudge. Quantify the residue a router would own.
3. **Scope** — read the editor's edge routing path to characterise insertion point +
   regression surface of an obstacle-avoiding step.

## Go/No-Go thresholds (fixed before measuring)

- **GO** if ≥15 cuts corpus-wide (or ≥4 on one map) AND >50% survive the cheapest
  mitigation AND the router has a bounded insertion point.
- **NO-GO/DEFER** if <15 corpus-wide, OR cheap mitigations dissolve most cuts, OR the
  router can't be inserted without corpus-wide perturbation risk (PL-005).

### 1. Corpus cut census (post-Phase-C) — IW-1, IW-2

Probe: for each edge, test its **rendered** polyline (`edge._renderedPolyline`) against
every non-endpoint node rect using the editor's own `polylineCrossesNodes` (boolean, the
authoritative detector) plus an inline distinct-node counter at the same `margin=4`.
Ran over all 24 maps in one in-page pass (`adoptImportedXml` loader; no navigation).

**Corpus total: 21 cut-edges / 27 cut-incidences.** The ~42 figure (T-092) is **stale** —
Phase C + the T-101 bake nearly halved it.

| Map | cut-edges | incidences |
|-----|:---:|:---:|
| harvest-pipeline | 9 | **13** |
| error-escalation-ladder | 5 | **7** |
| audit-process | 2 | 2 |
| inception-lifecycle | 2 | 2 |
| arc-lifecycle | 1 | 1 |
| inception-review | 1 | 1 |
| tier0-escalation | 1 | 1 |
| *17 other maps* | 0 | 0 |

**Concentration confirmed (A-2 validated):** harvest + error-esc hold **20 of 27
incidences (74%)**. 17 of 24 maps are entirely cut-free. The mechanism is dense fan/join
topology (harvest's learnings/patterns/decisions/practices/episodics fan), not a
corpus-wide defect.

### 2. Cheap-mitigation residue — IW-3

Applied each existing bulk action to the two worst maps, re-measured incidences:

| Map | base | re-run Clean | Align cols | Distribute | routing-margin 16 |
|-----|:---:|:---:|:---:|:---:|:---:|
| harvest-pipeline | 13 | **8** (−38%) | 13 | 10 | 13 |
| error-escalation-ladder | 7 | **4** (−43%) | 7 | 7 | 7 |

Two conclusions:

- **No cheap action dissolves cuts.** Align-columns, distribute, and routing-margin leave
  cut counts unchanged (they optimise other properties). Only Clean helps, and it removes
  just **38–43%** — a majority of cuts **survive** (8/13, 4/7 > 50%).
- **Discovered free win: the baked corpus is Clean-stale.** Re-running today's `cleanLayout`
  on the *baked* corpus reduces cuts, which means Clean has **improved since the T-101 bake**
  (align-rows T-094 and later composite changes landed after). A **corpus Clean re-bake**
  (T-101 redux) would harvest ~40% of cuts corpus-wide for near-zero cost/risk — independent
  of any router, and worth doing regardless.

### 3. Regression surface of a router — IW-4

Read the routing path (`routeOrthogonalSegment`, src:3586-3656). **The editor already routes
crossing-aware:** line 3629 sets `needsLoop` when `polylineCrossesNodes(simplePolyline)` is
true, then `orthoLoopBack` (src:3478) picks the detour band "with the fewest node crossings."
The residual 21 cut-edges are exactly the cases where that band heuristic **minimises but
cannot zero** crossings — dense maps where every above/below band within the lane union still
clips a node.

Implications for a build:
- **Not greenfield.** A router replaces `orthoLoopBack`'s band-pick with real pathfinding
  (grid/visibility-graph A* over node obstacles) at **one bounded insertion point** (the
  `needsLoop` branch, src:3636), with a **clean fallback** to today's band route if the
  pathfinder finds nothing better.
- **Blast radius is corpus-wide but measurable.** `_renderedPolyline` feeds label placement,
  segment-drag handles, and badges (src:3699-3703), so a new path shape ripples into those —
  the PL-005 risk is real. **Mitigant: the census probe built here is a ready regression
  harness** — cuts-per-map before/after any router change, all 24 maps in one pass.

## Recommendation

**Revised from filing DEFER → GO (sequenced).** See the task `## Recommendation` block for
the structured GO with rationale + evidence. Summary:

1. **First (cheap, separate task): re-bake Clean into the corpus** (T-101 redux). Harvests
   ~40% of cuts corpus-wide for near-zero risk. Do this regardless of the router.
2. **Then (the router build): obstacle-avoiding orthogonal routing** at the `needsLoop`
   insertion point, clean fallback, validated by the census harness. It owns the post-Clean
   residue (~12+ incidences concentrated in harvest/error-esc), which no cheap action dissolves.

Decision is human-owned — presented via `fw task review T-112`.

## Dialogue Log

_(no human dialogue yet — autonomous exploration under standing mandate "focus on routing
optimisations, proceed as seen fit". Decision remains human-owned.)_
