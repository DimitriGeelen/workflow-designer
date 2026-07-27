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
  confidence: 1
  disposition:
  rationale:

- **IW-2: Does preserving throw+eventDef reopen the T-237 "invalid hybrid" concern (throw+eventDef was deliberately dropped), or was that concern specific to the link-throw overlap that no longer applies to plain typed throws?**
  confidence: 1
  disposition:
  rationale:

- **IW-3: What is the exact drop site in the save path (parse-time discard vs export-time filter), and does a preservation fix risk emitting eventDef on hosts AEF's compiler rejects?**
  confidence: 1
  disposition:
  rationale: SECOND HALF CLOSED by AEF at rail 215 (verified in their source): aef:eventDef is accepted + round-tripped verbatim on ANY host (corpus_spec.py:212 host-agnostic, no rejection path); lint classifies direction by host tag (throw=throw, start=neutral/no finding), so preservation on both hosts is safe against their intake and restoring throw eventDefs also cures the emitterless-typed-catch lint. FIRST HALF (drop-site localization in our save path) still open — 832-side exploration.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

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

<!-- REQUIRED before fw inception decide. Write your recommendation here (T-974).
     Watchtower reads this section — if it's empty, the human sees nothing.
     Format:
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence from exploration)
     **Evidence:**
     - Finding 1
     - Finding 2
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
