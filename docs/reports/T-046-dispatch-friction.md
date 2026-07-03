# T-046 — Friction-dry analysis: cross-host-dispatch (fw dispatch send)

**Subject:** `examples/aef-processes/cross-host-dispatch.workflow.yaml`
**Ground truth:** `.agentic-framework/lib/dispatch.sh` (`do_dispatch_send`, L.54-129)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and
record where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #13.

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps.** The dispatch flow mapped
cleanly: 3 authority lanes, 2 guard gateways (validation, connectivity), 1 exit-code gateway,
3 terminal error exits, and a cross-host service hand-off. Two firsts for the corpus:

1. **First use of the `external` authority lane** — the remote host runs its own `fw bus
   receive` outside this system's authority. Validated first-try (`AUTHORITIES.external`).
2. **First workflow with NO human/sovereignty node AND no stochastic node** — purely
   agent-initiated, framework-executed, one external participant. A stronger negative case
   than promotion-pipeline (which had no stochastic but did have a human sovereignty gate).

But the cross-host boundary produced the **sharpest new candidate friction to date** (FC-3):
a genuine BPMN *participant* is flattened into a *lane*.

## Recurrences (frictions seen before, seen again)

- **F3 (determinism marker).** Every node is `deterministic`. No `human`, no `stochastic`.
  Second consecutive negative data point — determinism distribution is workflow-specific and
  tooling must not assume all three values appear. Here only ONE value appears.
- **F7 (side-effect annotation).** Two side effects: the local network send (`n_pipe`) and
  the remote bus write (`n_receive`). Both carried as free-text `aef.sideEffect`. Recurs.

## Sharpenings (a known friction took a new shape)

### F7 (side-effect) — side effects now span a HOST boundary
Previous maps' side effects were all local file writes (`practices.yaml`, task files). Here the
two side effects are on **different machines**: `n_pipe` sends bytes over the network from the
local host; `n_receive` writes `.context/bus/` on the *remote* host. The free-text
`aef.sideEffect` string cannot express *where* a side effect lands — locality is lost. A
structured side-effect record (`{host, resource, verb}`) would capture "remote write vs local
write"; the current bag flattens them into indistinguishable prose. Sharpening, not a new gap.

## New candidate frictions

### FC-3 — cross-participant boundary flattened to a lane  ⭐ headline
In BPMN, a remote system that runs *its own* process is a separate **participant** (its own
pool), and messages between pools are **message flows** (dashed connectors), not **sequence
flows** (solid). The Workflow Designer schema has exactly **one pool** subdivided into
*authority lanes*. So the remote host is modelled as an `external` **lane inside the same
pool**, and the SSH hand-off (`n_pipe → n_receive`) as an ordinary **sequence edge**.

This is expressive enough to draw and validate, but it conflates two distinct BPMN concepts:
- (a) authority lanes *within one participant* (agent / framework), and
- (b) a genuinely *separate participant* (the remote host, under its own framework install).

**Consequence:** the diagram reads as though the local orchestrator "sequences into" the
remote's receive step as if it owns it — when in truth it fires an envelope across a **trust
boundary** and only observes an exit code. The `external` authority tag is the schema's
pragmatic marker for "this lane is really a different participant."

**Recommendation (two-tier, PD-002-consistent):**
- **Now (cheap, no schema change):** document the convention *`authority: external` lane ⇒
  separate participant; edges crossing into/out of it are message hand-offs, not ownership.*
- **Parked enhancement:** a real multi-pool + message-flow construct if cross-host / multi-
  participant maps become common. Not warranted on one instance.

### FC-4 — fire-and-read-exit-code, not request-response
The local side sends an envelope and observes only the remote **exit code** (`n_receive →
n_exit_gate`, "exit code"), never a returned *payload*. This is a one-way message + status,
not an RPC. The schema draws async-notify and request-response identically (sequence edges);
distinguishing them is semantic, not a construct gap. Note, don't fix.

## Product finding (feeds T-043, not the schema)

**Fit-to-view sizes the viewBox from node *boxes*, not *label text*.** Two over-long end
labels ("Agent runs `fw dispatch send --host … --summary …`" and "Dispatched ✓ (task, agent,
summary echoed back)") overflowed the viewBox — bbox `x=-38` on the left, `+14` past the right
edge — and **clipped in the editor**, even though `check-lane-bands.py` passed clean. The
geometry gate and the editor's `contentRightEdge()` fit-to-view **share the same blind spot**:
both measure node boxes, neither measures rendered text extent. Mitigated here by trimming the
two labels to sensible node names (the flag detail already lives on `n_parse` and the
`endpoint` aef field); after trimming, bbox is `x=30 … right=1576`, fully inside viewBox
`[0,1606]`, and Playwright confirms both end labels render whole. But the underlying product
gap is real. **Candidate T-043 follow-up:** pad the viewBox by the max label half-width, or
measure text extents in both `contentRightEdge()` and a symmetric `contentLeftEdge()`.
Recorded so it is not lost as folklore.

## Outcome

Cross-host dispatch mapped, validated, geometry-clean, round-trips (bridge suite 14/14),
renders faithfully **and legibly** in the editor (Playwright-verified — both end labels whole,
SSH hand-off dips correctly into the `external` lane and returns to the exit-code gate). First
`external`-lane corpus member. No schema changes required (consistent with PD-002). One
headline candidate (FC-3 participant-flattened-to-lane), one semantic note (FC-4 fire-and-read),
one F7 sharpening (cross-host side effects), and one product follow-up for T-043 (fit-to-view
ignores label text) recorded for the friction register.
