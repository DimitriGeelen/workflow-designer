---
id: T-190
name: "IW-12: inception — typed BPMN event palette (error/timer/message + boundary
  events)"
description: >
  AEF IW-12 design finding (T-2523). 0.2.0 palette has only plain start/end; issues->boundary-error,
  horizon/cron->timer, dispatch/pickup->message are undiagrammable. Inception-scale
  (new node subtypes + aef serialization + bridge parity + mapping rows + DI). Operator
  prioritization (arc-scale).

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-11T16:56:46Z
last_update: '2026-08-16T12:33:42Z'
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-190: IW-12: inception — typed BPMN event palette (error/timer/message + boundary events)

## Problem Statement

AEF design finding IW-12 (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offset 20): the 0.2.0
event palette has only plain start/end. AEF first-class concepts map onto BPMN *typed* events
but can't be expressed: `status:issues` → error / boundary-error event; `horizon` + cron
scheduling → timer event; `dispatch`/`pickup`/bus hand-offs → message event. Without typed
events, AEF error paths, scheduled triggers, and cross-agent hand-offs flatten into plain
tasks — losing exactly the semantics the mapping contract exists to preserve. 832-side read
(offset 24): AGREED, real gap, 832 (SoT) build call; but inception-scale, not a quick build —
new node subtypes + aef: serialization + bridge parity (`yaml-to-bpmn.py`) + a mapping-standard
row per typed event + DI rendering. Initial set: error, timer, message, incl. boundary-on-
task/subProcess. The T-187/T-188 round-trip guards will cover the new serialization the moment
it lands.

**AEF operator RATIFIED this framing** (offset 25, 2026-07-11). Related ratified ruling that
constrains the inception representation: **G-3 — the go/no-go gateway is CONSTITUTIVE, not
decorative**; the permitted lightweight inception form is a COLLAPSED subProcess with the
gateway implied at the boundary (NOT a gateway-less task-node). That collapsed-subProcess
carrier already exists 832-side as T-081 (`aef:scopeOf` marker), so the typed-event work should
target it so editor + forward-compiler agree. **Prioritization is Dimitri's call** (arc-scale);
agent must NOT start the inception without operator GO.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->
- **A1:** Native BPMN event-definition children are the portability-correct serialization and round-trip through `yaml-to-bpmn.py` + T-187/T-188 guards with a bounded change. *(If false → aef:-extension encoding, per link-event precedent.)*
- **A2:** Boundary-event host-attachment is the dominant cost driver; error/timer/message as plain start/intermediate events are a comparatively small lift. *(Sets whether v1 splits.)*
- **A3:** The collapsed-subProcess carrier (T-081 `aef:scopeOf`) is the correct attach target so editor + forward-compiler agree, per the ratified G-3 ruling.

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->
- **IW-1: Serialization shape — do typed events encode as NATIVE BPMN event-definition children (`<bpmn:errorEventDefinition/>`, `timerEventDefinition`, `messageEventDefinition`) or via the `aef:` extension channel (as link events already do, `aef:link`)?**
  confidence: 3
  disposition: answered
  rationale: Spike-1 (§3a). Encode via `aef:` extension (BPMN event tag + `aef:eventDef kind=...` + binding), same as link events. Both editor and bridge have ZERO native `bpmn:*EventDefinition` machinery; the `aef:`/`x-` channel is a tested round-trip path (T-061, test_bridge_aef_passthrough.py). Native `bpmn:*EventDefinition` optional write-only for portability. Marginal per-type cost small ⇒ dominant cost is IW-2, not serialization.
- **IW-2: Boundary events — how is an event ATTACHED to a host (task/subProcess) modeled in the editor's node/edge data model? A boundary event is not a free node; it is anchored to a host's boundary, a new topological relation.**
  confidence: 3
  disposition: answered
  rationale: Spike-2 (§3b). Bounded additive change, NOT a redesign. Node→node uid refs already exist + round-trip (aef:scopeOf/constituents, T-081) → host binding is an additive aef field (hostRef+boundaryPos+interrupting). groupDrag (~5493) + T-168 ports reused for host-follow drag + boundary-origin edges. Only net-new piece: a host-relative render branch in renderNodes (~2354). NO-GO "unbounded redesign" trigger does not fire.
- **IW-3: v1 scope — which typed events ship first (error / timer / message as start+intermediate), and are BOUNDARY variants in v1 or a follow-on?**
  confidence: 3
  disposition: answered
  rationale: Spike-2 shows boundary attachment is bounded, so boundary variants CAN ship in v1. Lowest-risk sequencing = two-slice build under ONE task (non-boundary error/timer/message first, boundary second) — build-decomposition, not a second inception. A3 (T-081 carrier) confirmed by the same scopeOf/constituents evidence.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->
Spikes are NOT started yet — this going-in framing is presented for operator review first
(inception discipline). Planned time-boxed spikes on GO-to-explore:
1. **Spike-1 (serialization shape, IW-1/A1):** encode one error event both ways (native
   `bpmn:errorEventDefinition` vs `aef:` extension) and round-trip each through
   `yaml-to-bpmn.py`; check T-187/T-188 guards. Pick the shape that round-trips with the
   smaller diff. *(~½ day)*
2. **Spike-2 (boundary attachment, IW-2/A2):** prototype the editor data-model delta for a
   boundary-error event attached to a serviceTask host (host ref + boundary position +
   interrupting flag). Measure whether it is an additive field or a model redesign. *(~1 day)*
3. **Spike-3 (mapping-standard rows, A3):** draft the mapping-standard row per typed event on
   the T-081 collapsed-subProcess carrier; confirm editor + forward-compiler agree. *(~½ day)*

Decompose signal: if Spike-2 shows boundary attachment needs a model redesign, split boundary
events into a follow-on build task and ship error/timer/message first (IW-3).

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply? -->
- **BPMN standard fidelity (Directive 4, Portability):** typed events should prefer native BPMN
  event-definition semantics so a third-party BPMN tool can read the export; `aef:` extension is
  the fallback only where native BPMN can't carry the AEF concept.
- **Round-trip parity:** every new serialization must survive `src → export → yaml-to-bpmn.py →
  re-import` unchanged (T-187/T-188 guards) — the mapping contract depends on it.
- **G-3 carrier:** the ratified inception form is the collapsed subProcess (T-081 `aef:scopeOf`),
  not a gateway-less task-node; typed-event attachment targets that carrier.

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->
**IN:** the go/no-go on adding typed events (error, timer, message) + the boundary variants
question; the serialization-shape decision (IW-1); the boundary-attachment cost (IW-2); a v1
scope recommendation (IW-3). **OUT:** building the palette/serialization/DI (that is the
GO-authorized build task, not this inception); non-initial event types (escalation, signal,
compensation, conditional) — explicitly deferred beyond error/timer/message; any change to the
mapping-standard beyond adding rows for the three initial typed events.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The serialization shape (IW-1) resolves to one option (native BPMN or `aef:` ext) that
  round-trips through `yaml-to-bpmn.py` + T-187/T-188 guards with a bounded editor + bridge change.
- Each typed event reduces to a repeatable recipe: palette entry + node subtype + serialization +
  mapping-standard row + DI rendering, on the T-081 collapsed-subProcess carrier.
- Boundary-event attachment (IW-2) is either a bounded additive data-model change, OR cleanly
  splits into a follow-on so error/timer/message ship first.

**NO-GO if:**
- Boundary-event attachment forces an unbounded editor data-model redesign AND can't be split out.
- No serialization shape stays round-trippable through the bridge (breaks the mapping contract).
- The typed-event set can't be expressed on the G-3 collapsed-subProcess carrier (editor +
  forward-compiler would disagree).

**DEFER if:** the capability is sound but a prerequisite is missing (e.g. the write-out arc,
T-201, is mid-flight and would collide with the serialization work) — sequence, don't cancel.

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

<!-- REQUIRED before fw inception decide. Write your recommendation here (T-974).
     Watchtower reads this section — if it's empty, the human sees nothing. -->

**Recommendation:** GO — FIRM (post-Spike-1 + Spike-2)

Both spikes closed favorably and all three §Go/No-Go NO-GO triggers are excluded:
- IW-1 (Spike-1): serialization is a small, round-trip-guaranteed `aef:`-extension change.
- IW-2 (Spike-2): boundary attachment is a BOUNDED ADDITIVE change (node→node uid refs
  scopeOf/constituents already round-trip; groupDrag + T-168 ports reused; only a
  host-relative render branch is net-new) — the feared unbounded redesign does not occur.
- IW-3: boundary variants ship in v1 as a two-slice build under ONE task (non-boundary
  first, boundary second) — not a second inception.
Recommended build scope (blast_radius 3): palette + node subtypes + `aef:eventDef`
serialization + mapping rows + DI on the T-081 carrier, covered by T-187/T-188 guards.
Full evidence: docs/reports/T-190-typed-event-palette-inception.md §3a/§3b/§7.
**Go/no-go remains Dimitri's (Tier-0).**

_(Going-in advisory below was written pre-spike; superseded by the FIRM GO above.)_

**Rationale:**

The gap is real and AEF-ratified: without typed events, AEF's error paths (`status:issues`),
scheduled triggers (`horizon`+cron), and cross-agent hand-offs (`dispatch`/`pickup`/bus) flatten
into plain tasks, losing exactly the semantics the mapping contract exists to preserve. The
capability is squarely on the authoring-surface arc and you prioritized it. The OPEN questions
the inception must resolve before a firm GO are (1) the serialization shape and (2) the
boundary-event attachment cost — the latter is the one that could force a v1 split rather than a
NO-GO. My going-in lean: **GO to build error/timer/message typed events; boundary variants
contingent on IW-2** — likely a clean split (ship non-boundary first) if attachment proves
expensive. This flips to NO-GO only if no serialization stays round-trippable, or the set can't
live on the G-3 collapsed-subProcess carrier.

**Evidence:**

- Problem statement AEF-ratified (rail offset 25, 2026-07-11); G-3 carrier ruling ratified.
- Link-event precedent for `aef:` extension encoding + working round-trip (src ~7906).
- T-187/T-188 round-trip guards already exist to cover the new serialization on landing.

**Advisory only — the go/no-go decision is Dimitri's, after the spikes.**

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

**Decision**: GO

**Rationale**: Recommendation: GO (going-in advisory — to be firmed/revised by the §Exploration Plan spikes)

Rationale:

The gap is real and AEF-ratified: without typed events, AEF's error paths (`status:issues`),
scheduled triggers (`horizon`+cron), and cross-agent hand-offs (`dispatch`/`pickup`/bus) flatten
into plain tasks, losing exactly the semantics the mapping contract exists to preserve. The
capability is squarely on the authoring-surface arc and you prioritized it. The OPEN questions
the inception must resolve before a firm GO are (1) the serialization shape and (2) the
boundary-event attachment cost — the latter is the one that could force a v1 split rather than a
NO-GO. My going-in lean: GO to build error/timer/message typed events; boundary variants
contingent on IW-2 — likely a clean split (ship non-boundary first) if attachment proves
expensive. This flips to NO-GO only if no serialization stays round-trippable, or the set can't
live on the G-3 collapsed-subProcess carrier.

Evidence:

- Problem statement AEF-ratified (rail offset 25, 2026-07-11); G-3 carrier ruling ratified.
- Link-event precedent for `aef:` extension encoding + working round-trip (src ~7906).
- T-187/T-188 round-trip guards already exist to cover the new serialization on landing.

Advisory only — the go/no-go decision is Dimitri's, after the spikes.

**Date**: 2026-07-18T10:31:19Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-18T09:58:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-18T10:31:19Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO (going-in advisory — to be firmed/revised by the §Exploration Plan spikes)

Rationale:

The gap is real and AEF-ratified: without typed events, AEF's error paths (`status:issues`),
scheduled triggers (`horizon`+cron), and cross-agent hand-offs (`dispatch`/`pickup`/bus) flatten
into plain tasks, losing exactly the semantics the mapping contract exists to preserve. The
capability is squarely on the authoring-surface arc and you prioritized it. The OPEN questions
the inception must resolve before a firm GO are (1) the serialization shape and (2) the
boundary-event attachment cost — the latter is the one that could force a v1 split rather than a
NO-GO. My going-in lean: GO to build error/timer/message typed events; boundary variants
contingent on IW-2 — likely a clean split (ship non-boundary first) if attachment proves
expensive. This flips to NO-GO only if no serialization stays round-trippable, or the set can't
live on the G-3 collapsed-subProcess carrier.

Evidence:

- Problem statement AEF-ratified (rail offset 25, 2026-07-11); G-3 carrier ruling ratified.
- Link-event precedent for `aef:` extension encoding + working round-trip (src ~7906).
- T-187/T-188 round-trip guards already exist to cover the new serialization on landing.

Advisory only — the go/no-go decision is Dimitri's, after the spikes.
