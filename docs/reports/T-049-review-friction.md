# T-049 — Friction-dry analysis: review-emission (fw review / emit_review)

**Subject:** `examples/aef-processes/review-emission.workflow.yaml`
**Ground truth:** `.agentic-framework/lib/review.sh` (`emit_review`, L.77-272)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and record
where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #16.

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps.** The review-emission flow
mapped faithfully: resolve → found gate → advisory arc check → inception/standard type switch
→ hard link-homework gate → card/QR (best-effort) → mark-reviewed side effect → handoff. It
surfaced one strong new candidate about *what a process is for* (FC-7) and reinforced the
inter-process-signal and Tier-2-bypass ideas.

## New candidate frictions

### FC-7 — the handoff-emitter process  ⭐ headline
`emit_review` exists to put a task in front of **human sovereignty** — a Human-AC approval or
an inception go/no-go decision. But that review happens **out-of-band on Watchtower**, in a
separate process, after this script has returned. The mapped flow therefore *terminates at
"handoff emitted"* — the sovereignty act the whole process exists to enable is **not a node in
it**. The schema (single pool, sequence flow, no message flow) cannot express "this terminal is
a message handed to a participant whose response is a different process."

This is a distinct shape from the maps so far:
- inception-review / promotion **contain** the human sovereignty node (the decision is in-flow).
- cross-host-dispatch **contains** the external participant as a lane (the receive is in-flow).
- review-emission **emits** to a participant whose action is entirely out-of-flow.

**Why it matters:** a reader of just this diagram sees an agent+framework automation and might
miss that its entire reason to exist is a sovereignty handoff. The `aef.handoffTo` annotation
on the terminal carries it in text, but there is no visual "→ hand to sovereignty" marker.
**Recommendation:** document a `handoffTo` terminal convention now; a rendered handoff marker
(e.g. an arrow to a named participant outside the pool) is a possible later enhancement. This
is the first corpus instance — register, don't build (PD-002).

### Marker-as-inter-process-signal
The `.reviewed-<id>` touch (L.258-267) is a side effect whose purpose is to **unblock a
different process** — `fw inception decide` refuses to run until this marker exists (T-973
gate). So a filesystem write here is a *control signal* to another workflow. The schema models
it as an ordinary `aef.sideEffect`; the cross-process control meaning is invisible. Related to
T-047's FC (side effects lose locality) — here they also lose *downstream control semantics*.

### Tier-2-bypassable hard gate
The T-2139 link-homework gate (L.164-179) BLOCKS the handoff (`return 2`) when the agent left
unresolved Watchtower links — but a human may override via `FW_ALLOW_REVIEW_LINK_HOMEWORK=1`
(logged Tier-2). So the gate's "off" branch is **human-authorized**, not data-driven. The
schema draws it as a plain `exclusiveGateway`; the fact that one branch requires sovereignty
authorization is carried only in the decisionInput/label. Candidate: an `aef.bypass` axis on
gateways (who may override, and at what tier).

## Recurrences

- **FC-1 (advisory).** Three warn-but-continue steps: the arc-parent check, the inception
  recommendation WARN, and the QR/artifacts block. All `aef.softFail: advisory`. Recurs
  strongly — advisory is now the single most common non-happy-path shape across the corpus.
- **F3 (determinism).** All `deterministic`; the sovereignty is out-of-band (FC-7), so unlike
  inception/promotion there is no in-flow `human` node — despite the process being *about*
  human review. A subtle F3 data point: "no human node" does NOT mean "no human involvement."
- **Type-switch routing.** The `inception?` gateway adds inception-only steps (URL path,
  recommendation check, CLI hint) that rejoin the standard path — the same
  branch-and-rejoin idiom as promotion's advisory gate, used here for a mode switch.

## Product finding (feeds T-043)
One end-label ("Handoff emitted ✓ → human review (out-of-band)") overflowed the viewBox by
14px and was trimmed — the same fit-to-view-ignores-label-text issue now recorded in T-046,
T-048, and here (**third occurrence**). Captured as a learning this session; the short-label
workaround remains reliable, but three votes make the T-043 follow-up (measure text extent, or
a symmetric contentLeftEdge/contentRightEdge padded by max label half-width) a clear
next-session candidate.

## Outcome
Review emission mapped, validated, geometry-clean, round-trips (bridge suite 17/17), renders
faithfully and legibly (Playwright-verified — type-switch branch rejoins above the spine, both
error terminals below, marker side effect and handoff terminal clear). No schema changes
(PD-002 holds). Registered: FC-7 (handoff-emitter — headline), marker-as-inter-process-signal,
Tier-2-bypassable gate, plus FC-1/F3/type-switch recurrences and the third fit-to-view vote.
