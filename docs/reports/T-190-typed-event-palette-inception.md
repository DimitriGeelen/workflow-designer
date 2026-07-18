# T-190 — Typed BPMN event palette inception (IW-12: error / timer / message + boundary events)

**Status:** exploration (inception), going-in framing. **Advisory:** GO to explore.
**Decision owner:** Dimitri (832 sovereign). **Arc:** designer-authoring-surface.
**Operator GO to start:** recorded 2026-07-18 (Dimitri).

> C-001: this file is the artifact; the dialogue is ephemeral. Updated incrementally,
> committed per segment. The recommendation here is provisional until exploration closes.
> Spikes are NOT started — this is the going-in framing presented for review first.

## 1. Problem

The 0.2.0 designer palette has only **plain start/end events**. AEF's first-class
concepts map onto BPMN *typed* events but currently can't be expressed:

| AEF concept | BPMN typed event |
|---|---|
| `status:issues` / error path | **error** event (incl. boundary-error on a task/subProcess) |
| `horizon` + cron scheduling | **timer** event |
| `dispatch` / `pickup` / bus hand-off | **message** event |

Without typed events these flatten into plain tasks, **losing exactly the semantics
the mapping contract exists to preserve** (AEF IW-12, rail offset 20; 832 agreed
offset 24; AEF operator ratified offset 25, 2026-07-11).

## 2. Why this is an inception, not a quick build

It is genuinely inception-scale: new node subtypes + `aef:` serialization + bridge
parity (`yaml-to-bpmn.py`) + a mapping-standard row per typed event + DI rendering —
and **boundary events introduce a new topological relation** (an event *attached to a
host*), which the current free-node data model doesn't have. That unknown cost is
what needs an exploration before committing a build.

**Ratified constraint (G-3):** the go/no-go gateway is constitutive; the permitted
lightweight inception carrier is a **collapsed subProcess** with the gateway implied
at the boundary (T-081 `aef:scopeOf`), NOT a gateway-less task-node. Typed-event work
targets that carrier so editor + forward-compiler agree.

## 3. The design questions (core of the exploration)

- **IW-1 — serialization shape:** native BPMN event-definition children
  (`bpmn:errorEventDefinition`, `timerEventDefinition`, `messageEventDefinition`) vs
  `aef:` extension encoding (as link events already do, `aef:link`, src ~7906).
  Portability (Directive 4) favors native BPMN; the `aef:` path has precedent + a
  working round-trip. Load-bearing: it sizes the editor + bridge change and decides
  whether T-187/T-188 guards cover it for free.
- **IW-2 — boundary attachment (likely dominant cost):** how an event anchors to a
  host's boundary in the editor node/edge model (host ref + boundary position +
  interrupting/non-interrupting flag). Additive field, or model redesign?
- **IW-3 — v1 scope:** error/timer/message first; boundary variants in v1 or a
  follow-on, decided by IW-2's cost. One inception, one go/no-go; a boundary split is
  build-decomposition, not a second inception.

### 3a. Spike-1 finding — IW-1 RESOLVED: `aef:`-extension encoding (2026-07-18)

Investigated both sides of the pipeline + the round-trip contract:

- **Bridge (`tools/yaml-to-bpmn.py`) + T-061 passthrough contract** (pinned by
  `tests/test_bridge_aef_passthrough.py`): a scalar `aef.x-<name>` key round-trips
  as `<aef:meta … x-<name>="…">`; an unknown *bare* `aef.<name>` drops **loudly**
  (WARN to stderr, exit 0); known vocabulary unaffected. So the `aef:` extension
  channel is a **guaranteed, tested round-trip path** for new event metadata.
- **Editor + bridge have NO native `bpmn:*EventDefinition` machinery.** Event
  semantics ride `aef:` extension uniformly: link events map to
  `intermediateThrow/CatchEvent` tags (bridge lines 34-35) and carry their
  semantics via `aef:link` (`targetWorkflow`/`linkId`), NOT a native
  `bpmn:linkEventDefinition`. Grep confirms zero `EventDefinition` handling on the
  editor import side. The AEF model is deliberately "BPMN skeleton + `aef:`
  extension carries AEF semantics."

**Decision (IW-1): encode typed events the same way link events already are** — a
BPMN event tag (`startEvent`/`intermediateCatch|ThrowEvent`/`boundaryEvent`) + an
`aef:` extension marker for the type and its AEF binding (e.g.
`aef:eventDef kind="error|timer|message"` + the trigger: `status:issues` / cron
expr / bus topic), riding the proven `aef:`/`x-` channel. Rationale:

- **Least change + guaranteed round-trip:** reuses the existing `aef:link` template
  and the tested passthrough; adding native `bpmn:*EventDefinition` would mean new
  parse+emit branches on BOTH editor sides *and* the bridge, for no functional gain
  the editor consumes.
- **Portability is not sacrificed in substance:** the AEF binding (which concept
  fired) can't live in pure-native BPMN anyway — you'd need `aef:` regardless. A
  native `bpmn:*EventDefinition` child MAY additionally be emitted **write-only** as
  a courtesy for third-party BPMN readers (editor keys off `aef:` on re-import) — an
  optional add, not the primary encoding.

**Cost implication:** because the marginal encoding per event type is small (mirrors
the existing `linkEvent` branch), the dominant cost is confirmed to be **IW-2
(boundary attachment topology)**, not serialization. Spike-1 did not touch
production code (analysis of existing src + bridge + guards only).

### 3b. Spike-2 finding — IW-2 RESOLVED: bounded additive change, NOT a redesign (2026-07-18)

The feared cost was that "event attached to a host" is a new topological relation
the free-node model can't express. Investigation shows the model **already has the
pieces**:

- **Node→node uid references already exist and round-trip.** `aef:scopeOf` (a
  subProcess bound to the node it is the collapsed body of, T-081/FC-15) and
  `aef:constituents` (a list of `{id,name,ref}` children) are both authored fields
  that serialize (metaKeys + the list-of-dicts channel, src ~7934/~7986/~8280) and
  re-import. A boundary event's host binding is the **same shape**: an additive
  `aef` field — `hostRef` (host uid) + `boundaryPos` (perimeter offset) +
  `interrupting` (bool). No new relational primitive.
- **Interaction infra already exists to reuse.** Group-drag (`groupDrag`, src ~5493;
  `node.x = orig.x + dx`, ~5500) already moves multiple nodes by a shared delta —
  the exact mechanic host-follow needs ("host moves ⇒ its boundary events move").
  Edge endpoints already anchor via the T-168 port/anchor machinery, which a
  boundary-origin edge reuses.
- **The one genuinely new piece is host-relative rendering.** Nodes render at
  absolute `n.x/n.y` (renderNodes, ~2354). A boundary event must instead render at
  a point computed from its host's perimeter. That is a **contained new branch** in
  renderNodes (position from `hostRef`, not free x/y), not a model rewrite.

**Verdict:** boundary-event attachment is a **bounded, additive** change (data ref =
free via scopeOf/constituents precedent; drag + edges = reuse existing infra; only a
host-relative render branch is net-new). It does **not** force a data-model redesign,
so the §6 NO-GO trigger ("unbounded editor redesign") does **not** fire. Spike-2 was
analysis-only — no production code.

**Consequence for IW-3 (v1 scope):** since attachment is bounded, boundary variants
**can ship in v1**. Lowest-risk sequencing is still a **two-slice build under one
task** — error/timer/message (non-boundary) first, boundary variants second — but
this is build-decomposition, **not** a separate inception. A3 (T-081 carrier) is
confirmed by the same scopeOf/constituents evidence; Spike-3's mapping-standard rows
are a build-time detail on that carrier, not a go/no-go blocker.

## 4. Assumptions

- **A1:** native BPMN event-definitions are the portability-correct shape and
  round-trip with a bounded change. *(If false → `aef:` ext, per link precedent.)*
- **A2:** boundary attachment is the dominant cost; non-boundary error/timer/message
  are a small lift. *(Sets whether v1 splits.)*
- **A3:** the T-081 collapsed-subProcess carrier is the correct attach target (G-3).

## 5. Exploration plan (spikes — NOT build; each time-boxed)

1. **Spike-1 (serialization, IW-1/A1):** encode one error event both ways, round-trip
   each through `yaml-to-bpmn.py`; pick the smaller-diff shape. *(~½ day)*
2. **Spike-2 (boundary attachment, IW-2/A2):** prototype the editor data-model delta
   for a boundary-error on a serviceTask host; measure additive-field vs redesign.
   *(~1 day)*
3. **Spike-3 (mapping rows, A3):** draft the mapping-standard row per typed event on
   the T-081 carrier; confirm editor + forward-compiler agree. *(~½ day)*

Decompose signal: if Spike-2 shows a model redesign, split boundary events out and
ship error/timer/message first.

## 6. Go / No-Go criteria

**GO if:** serialization (IW-1) resolves to one round-trippable option with a bounded
change; each typed event reduces to a repeatable recipe (palette + subtype +
serialization + mapping row + DI) on the G-3 carrier; boundary attachment (IW-2) is
bounded-additive OR cleanly splittable.
**NO-GO if:** boundary attachment forces an unbounded editor redesign AND can't be
split; no serialization stays round-trippable (breaks the mapping contract); the set
can't live on the collapsed-subProcess carrier.
**DEFER if:** a prerequisite collides (e.g. the write-out arc T-201 serialization work
mid-flight) — sequence, don't cancel.

## 7. Recommendation (provisional)

**GO to build error/timer/message typed events; boundary variants contingent on IW-2**
— likely a clean split (ship non-boundary first) if attachment proves expensive. The
capability is AEF-ratified and on the arc; the only real unknown is boundary-event
cost, and that resolves to a scope decision, not a kill. Flips to NO-GO only if no
serialization round-trips or the set can't live on the G-3 carrier. **Go/no-go is
Dimitri's, after the spikes.**

## 8. Dialogue Log

### 2026-07-18 — operator GO to start (Dimitri)
- **Q (agent→Dimitri):** prioritize the typed-event inception now? (arc-scale; agent
  must not start without operator GO per the ratified framing.)
- **A:** GO — start the inception exploration.
- **Outcome:** T-190 started; going-in framing (this artifact + task scaffold) written
  and presented for review BEFORE any spike (inception discipline). Spikes 1–3 await
  the operator's read of this framing.
