---
id: T-257
name: "Typed start/throw eventDef round-trip: save drops aef:eventDef from startEvent and intermediateThrowEvent carriers"
description: >
  AEF field defect (rail 201, their T-2620 report, 2026-07-26): operator opened their draft-trigger-handling v1 (start kind=timer, throw kind=message) in the 0.4.0 editor, made a LAYOUT-ONLY edit, saved -> v2 lost both start/throw eventDefs while the catch kept its. Root lineage: this is the recorded T-237 decision (eventDef override = catch-hosts-only; throw+eventDef payload deliberately dropped as invalid hybrid; typed-THROW named a FUTURE CONTRACT ROUND and offered to AEF at rail 156) now colliding with real corpus usage - the contract round has arrived with field evidence. Impact: save silently strips typed-event semantics -> manufactures emitterless typed catches (the T-2551 lint class both sides pinned). Scope to explore: aef:eventDef preservation/rendering on startEvent + intermediateThrowEvent hosts (round-trip first, palette/UI second); AEF offered the v1/v2 byte-pair as a fixture - accept it. Everything else in their round-trip was clean (19 uids, 20 flows, name->workflowRef auto-resolve held under real operator editing).

status: started-work
workflow_type: inception
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-26T20:24:56Z
last_update: 2026-07-27T16:49:23Z
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

# T-257: Typed start/throw eventDef round-trip: save drops aef:eventDef from startEvent and intermediateThrowEvent carriers

## Problem Statement

The editor's save path silently strips `aef:eventDef` from startEvent and
intermediateThrowEvent carriers (kept only on intermediateCatchEvent — the recorded
T-237 decision: catch-hosts-only, typed-THROW deferred to a future contract round,
offered to AEF at rail 156). AEF's operator hit this in the field (rail 201): a
layout-only edit to draft-trigger-handling v1 in the 0.4.0 editor produced v2 with
both eventDefs gone, manufacturing an emitterless typed catch (the T-2551 lint class
both sides pinned). The deferred contract round has arrived with field evidence and a
byte-pair fixture (rail 208/209, pinned under tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/).

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

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

- **IW-1: Should start/throw eventDef round-trip be preservation-only (parse + re-emit verbatim, no palette/UI), or full typed-event semantics (render glyphs, editable kind) in the same round?**
  confidence: 3
  disposition: answered
  rationale: Preservation-only this round. Full typed start/throw semantics requires a new typed-throw node vocabulary (TYPE_TAG entries, palette items, glyphs, properties UI) — exactly the future contract round T-237 deferred and rail 156 offered. Preservation alone cures the field defect completely (silent data loss + the emitterless-typed-catch lint class, per AEF rail 215: restoring throw eventDefs cures the lint). Semantics can layer on later without reworking the passthrough.

- **IW-2: Does preserving throw+eventDef reopen the T-237 "invalid hybrid" concern (throw+eventDef was deliberately dropped), or was that concern specific to the link-throw overlap that no longer applies to plain typed throws?**
  confidence: 3
  disposition: dissolved
  rationale: T-237's concern was about TYPE-OVERRIDE, not preservation — the src comment (aef-workflow-designer.html:9082-9087) states it: EVENT_KIND types all export as intermediateCatchEvent, so overriding a THROW host's node type would silently mutate its tag to a catch on round-trip; and a link-with-target must stay a link event. A passthrough that leaves node type and host tag untouched triggers neither failure mode. Fixture confirms no aef:link on either dropped carrier (v1 th_obs_fire, th_signal) — no classification interplay.

- **IW-3: What is the exact drop site in the save path (parse-time discard vs export-time filter), and does a preservation fix risk emitting eventDef on hosts AEF's compiler rejects?**
  confidence: 3
  disposition: answered
  rationale: BOTH mechanisms, now localized (2026-07-27 code read). (a) Parse-time discard — adoptImportedXml, aef-workflow-designer.html:9088-9099: eventDefEl is read but consumed only under the `_catchHost` guard (intermediateCatchEvent/linkEventCatch/boundaryEvent); on startEvent and intermediateThrowEvent hosts kind/binding never enter the node model. (b) Export-time absence — aefExtensionXml:8735-8739 emits <aef:eventDef> only when EVENT_KIND[node.type] matches (the three typed-catch types). Fix must touch both. AEF-rejection risk: none — closed at rail 215 (corpus_spec.py:212 host-agnostic accept, lint start=neutral/throw=emitter).

## Exploration Plan

Executed 2026-07-27 (single session, code-read + fixture-diff — no prototype needed):
1. Locate every eventDef touchpoint in the save path (grep src) — DONE: all in
   src/aef-workflow-designer.html (import adoptImportedXml, export aefExtensionXml).
2. Trace the fixture repro through both directions — DONE: v1 start (th_obs_fire,
   kind=timer) keeps node type startEvent, v1 throw (th_signal, kind=message) becomes
   linkEventThrow; neither passes the `_catchHost` guard at :9091, so kind/binding
   never enter the model; export gate at :8735 (EVENT_KIND[node.type]) then has
   nothing to emit. Catch (th_pickup) passes the guard, is type-overridden to
   eventMessage, and re-exports — v2:238 shows the exporter's canonical
   normalization (binding="" added), which AEF's intake accepted, proving canonical
   re-emit (vs byte-verbatim attr preservation) is fine.
3. Peer-intake risk — CLOSED externally at rail 215 (host-agnostic accept, verified
   in AEF source).

## Technical Constraints

None beyond the existing single-file editor architecture. No new APIs, no network,
no schema change on the AEF side (their intake is already host-agnostic, rail 215).

## Scope Fence

**IN (build task on GO):**
- Import: passthrough capture of <aef:eventDef kind binding> on hosts the
  typed-catch override skips (startEvent, intermediateThrowEvent; also
  link-with-target nodes for symmetry) — stored as inert aef fields, no node-type change.
- Export: re-emit the passthrough <aef:eventDef> for nodes carrying it (canonical
  form, binding="" when absent — matches the accepted v2 catch normalization).
- Regression test leg: open fixture v1 → save → assert all 3 eventDefs survive with
  kinds intact (timer/message/message on th_obs_fire/th_signal/th_pickup).

**OUT (explicitly deferred):**
- Typed start/throw palette, glyphs, editable-kind UI (the full-semantics contract
  round — separate future inception).
- Any change to the typed-CATCH override path (T-204/T-237 behaviour unchanged).
- Byte-verbatim attribute preservation (canonical re-emit is ratified by field
  evidence — v2 catch).

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
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

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

**Recommendation:** GO

**Rationale:** The drop is fully localized to two bounded sites in one file, the fix
is a preservation passthrough with zero UI surface and zero risk to the existing
typed-catch behaviour, and the peer side has pre-cleared intake (rail 215,
source-verified). This cures a field defect that silently destroys operator-authored
semantics on every layout-only save — the strongest class of GO evidence (real data
loss, bounded fix, byte-pair fixture already pinned for regression).

**Evidence:**
- Drop site (a): parse-time discard — adoptImportedXml `_catchHost` guard,
  src/aef-workflow-designer.html:9088-9099. startEvent/intermediateThrowEvent hosts
  never get kind/binding into the node model.
- Drop site (b): export-time gate — aefExtensionXml:8735-8739 emits eventDef only
  for the three typed-catch node types.
- Fixture trace matches exactly: v1 th_obs_fire (timer) + th_signal (message)
  dropped, th_pickup (message) survives via the catch override path (v2:238, with
  canonical binding="" normalization AEF accepted — canonical re-emit ratified).
- Peer intake safe: AEF rail 215, corpus_spec.py:212 host-agnostic accept, no
  rejection path; lint start=neutral; restoring throw eventDefs also cures the
  emitterless-typed-catch lint class (T-2551) both sides pinned.
- T-237 "invalid hybrid" concern dissolved: it guarded against TYPE-OVERRIDE tag
  mutation, which a passthrough never performs (IW-2).
- Scope ≈ blast radius 1-2 (single source file + one test leg) vs anticipated 3.

**Fix shape for the build task:** capture kind/binding as inert aef passthrough
fields at import when the catch-override doesn't apply; re-emit canonically at
export; regression leg = fixture v1 open→save keeps all 3 eventDefs.

## Decisions

### 2026-07-27 — Canonical re-emit vs byte-verbatim attribute preservation
- **Chose:** Re-emit passthrough eventDefs in the exporter's canonical form
  (`kind="…" binding=""` when binding absent in source).
- **Why:** The surviving catch in fixture v2 already shows this normalization in
  the wild and AEF's intake accepted it (rail 215 byte-check was on OUR pinned
  copies; their corpus_spec captures verbatim what we emit). Byte-verbatim attr
  preservation would need raw-attr storage for zero consumer benefit.
- **Rejected:** Raw attribute-string passthrough — extra machinery, no gain.

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

### 2026-07-27T16:34:36Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-27 — fixture pair received and pinned
- AEF delivered the v1/v2 byte pair at rail 208/209 (their T-2627); pinned verbatim at
  `tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/` with provenance README.
- sha256 v1 `5845caae2f83479bc7aeb4b97c2db297cb77edca4cf75fcdc1a3db21bbfa293f` (16443 B),
  v2 `7c0bd69a17e1c240771cc4727e403002423e36b2ee03fe6bc97cb8c7c24deb4b` (16675 B); both XML-parse clean.
- Diff confirms the reported repro exactly: start timer + throw message eventDefs dropped, catch message retained.

### 2026-07-27 — drop-site exploration complete, recommendation GO written
- Both drop mechanisms localized in src/aef-workflow-designer.html: parse-time
  `_catchHost` guard (adoptImportedXml :9088-9099) + export-time EVENT_KIND gate
  (aefExtensionXml :8735-8739). Fixture trace matches the field repro exactly.
- IW-1 answered (preservation-only), IW-2 dissolved (T-237 concern = type-override,
  not preservation), IW-3 answered (both halves closed). All dispositions filed.
- Recommendation GO + fix shape + scope fence written; awaiting operator decision
  at /inception/T-257.
