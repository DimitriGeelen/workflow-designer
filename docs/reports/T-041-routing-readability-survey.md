# T-041 — Routing readability survey (operator-driven)

**Trigger:** Operator observation during first gallery dogfooding (2026-07-04): routing
should be controllable, goal = readability and calmness; requested a check of how routing
turns out on the current corpus.

**Method:** Element screenshots of the four edge-densest rendered maps (healing-loop,
audit-process, task-lifecycle, inception-review) via the T-041 gallery; each screenshot
read and assessed for edge/label/node interference.

## Findings (ranked by harm to calmness)

### R-1 — Edge labels sit directly on the line, colliding with edges, badges, other labels
Worst case task-lifecycle around the `Outcome?` gateway: "resume after healing",
"work done", "gate failed — resume" all overlap each other, the edges they name, and
node id badges. Every dense map shows at least one label-on-line collision.
No label offset, no background halo, midpoint placement even on vertical segments.

### R-2 — Long return/loop edges cut through the diagram body
task-lifecycle "gate failed — resume" runs horizontally through the middle band where
labels live; healing-loop's advisory drop passes through the gateway's own label.
Loops route point-to-point instead of around the content's periphery.

### R-3 — Parallel bundles share channels with no separation (fork/join wireframe)
audit-process fork→5 checks→join: vertical runs overlap and hug task borders,
producing a wireframe corridor that boxes the tasks in. No channel spacing / nudging
between edges sharing a corridor.

### R-4 — Anchor points land at corners/odd points on the node boundary
Arrowheads enter at box corners or clip past label badges (nearest-port pinning after
drag; auto-anchor picks nearest tip). Entries/exits are unpredictable, which is what
the operator's "snap to middle of object by default" targets.

### R-5 — Node-adjacent text (name overflow + display-id badge) collides with edges
Start-event labels clip at the pool edge (healing-loop "Auto-trigger…"); id badges below
nodes sit in the natural incoming-edge channel. Interacts with PL-003 (labels wider than
node boxes).

## Clean signals
- Lane-band discipline holds everywhere (geometry gate doing its job).
- inception-review reads well overall — density, not topology, is the problem.
- Corner staircase routing is consistent; the issue is where corners/labels land, not
  the orthogonal style itself.

## Implication for the routing-controls task (T-070, to be filed)
Operator-facing routing defaults should start with:
1. **Centre-anchor default** (edge aims at node centre, arrowhead at boundary
   intersection; explicit port pin remains as override) — directly addresses R-4.
2. **Label offset + halo** (lift labels off the line, dark backing box) — R-1.
3. **Channel spacing** for parallel runs sharing a corridor — R-3.
4. **Periphery routing for loop-backs** (already partially exists as detourY) — R-2.
Controls surface: a small "Routing" section with global defaults; per-edge overrides
persisting via existing aef routing hints.
