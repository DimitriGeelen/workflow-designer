---
id: T-357
name: "Adopt BPMN DI as the designer geometry and retire aef-position"
description: >
  Inception: Adopt BPMN DI as the designer geometry and retire aef-position

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-03T13:14:20Z
last_update: 2026-08-03T15:58:04Z
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

# T-357: Adopt BPMN DI as the designer geometry and retire aef-position

## Problem Statement

The designer stores node geometry in `aef:position`, a proprietary extension, and
neither reads nor writes standard BPMN Diagram Interchange (`bpmndi:`). The whole
`bpmndi` sub-tree is dropped on import (T-340) and never emitted on export.

The consequence is **symmetric and measured**, and it is a rendering defect rather
than a metadata one:

- **Inbound:** `src:9742` takes position from `aef:position` *if present, else lays
  out automatically*. A third-party file has no `aef:position` by construction, so
  opening a real BPMN document replaces the author's arrangement with our
  auto-layout on LOAD, made permanent on save.
- **Outbound:** our exports carry no DI at all, so bpmn.io, Camunda, or any
  standard viewer auto-layouts *our* maps exactly as we auto-layout theirs.

Portability is the fourth constitutional directive. `aef:position` is a proprietary
re-implementation of a standard that already exists and is strictly richer: DI
carries shape bounds, edge waypoints and label positions against our single x/y
pair. Adopting DI retires the "two contradictory geometries" question permanently
instead of managing it forever.

**Why now:** T-340 forces a ruling on DI handling anyway. Deciding it as an
isolated import repair, without asking whether the extension should exist at all,
is how a proprietary format becomes permanent. The operator asked the question
directly ("why not just adopt the standard?") and my T-340 option set had no slot
for it.

## Assumptions

Registered via `fw assumption add`:

- **A-1 (load-bearing, UNVALIDATED):** `aef:position` exists for a recorded reason
  — a bridge constraint, or a judgement that DI was too heavy for the yaml round
  trip — rather than because DI was overlooked. **If A-1 validates, the recorded
  constraint may still hold and the recommendation can flip to NO-GO.** I have not
  checked and will not assert it was an oversight.
- **A-2:** DI can express everything `aef:position` expresses. (Strongly expected —
  DI is a superset — but "expresses" must be checked against what the *designer*
  consumes, not against the spec.)
- **A-3:** No consumer outside this repo reads `aef:position` as a contract. The
  known consumers are `tools/yaml-to-bpmn.py` and the bridge parity assertions;
  AEF pins `source_bpmn_sha` over whole files, not over this element.

## Open Questions

- **IW-1: Why does `aef:position` exist instead of `bpmndi`?**
  confidence: 2
  disposition: answered
  rationale: `src:9406-9407,9582` — a deliberate demo-stage deferral with a named
  downstream owner: every export carries `<!-- BPMN DI (visual layout) omitted in
  this demo; AEF generates it from node coordinates -->`. Neither of the two causes
  I registered (bridge constraint / too heavy for yaml), and not an oversight.
  Entered the tree wholesale at `61242508` (T-012, 2026-06-05). See
  `docs/reports/T-357-di-adoption.md` §Spike 1.

- **IW-1b: Does AEF actually generate DI from `aef:position`, as our exported bytes have asserted since 2026-06-05?** *(spawned by IW-1; now the load-bearing question)*
  confidence: 0
  disposition: <!-- pending — asked on the rail at offset 418; only AEF can answer -->
  rationale: <!-- unverifiable from here under the T-559 boundary. Both prior
  investigations of this comment (our T-311 guard, their T-2682/T-2683 corpus
  incident) examined the comment's POSITION and left its CLAIM unexamined. -->

- **IW-2: Does anything outside `src/` read or write `aef:position`?**
  confidence: 3
  disposition: answered
  rationale: `tools/yaml-to-bpmn.py` (writes it) and — the finding —
  `docs/standards/aef-bpmn-mapping-v1.md:42-45`, the FROZEN two-party standard,
  which names it. The standard declares the whole presentational family "derived,
  never authoritative" and a no-op for the task graph, which *ratifies* A-3; but it
  enumerates `aef:position` by name, so adoption requires a **v1.1 standard
  revision**, agent-uneditable and two-party. My filed rationale undercounted this.

- **IW-3: Can DI carry everything the designer currently persists as geometry, including lane bands and edge waypoints?**
  confidence: 2
  disposition: <!-- PARTIAL — leaning no; anchors/aef:waypoint unclassified -->
  rationale: The question is the standard's **eight-element** presentational family,
  not `aef:position` alone, and all are live in `src` (`routingHint` 22,
  `anchors` 19, `forceStraight` 12, `loopDetour` 9). DI maps *results* richly
  (`dc:Bounds`, `di:waypoint`, label bounds) but has no vocabulary for layout
  **intent**, which is what `forceStraight`/`routingHint`/`loopDetour` are. Recorded
  as bounding adoption's scope, explicitly NOT as disqualifying it — the last time a
  maximal variant's property settled an option here, it was wrong (RAIL-416).

- **IW-4: Is rewriting 126 existing files' geometry on first save compatible with the T-225 ratification that "diagram XML is never silently migrated" (`src:8201`)?**
  confidence: 3
  disposition: answered (for the *adopt* half) / escalated (for the *retire* half)
  rationale: **The principle splits the task in two.** ADOPT (emit DI, read DI when
  `aef:position` is absent) adds a representation and rewrites nothing — not a
  migration. RETIRE (stop writing `aef:position`) is exactly one: a file comes back
  carrying DI and no `aef:position` on a save made for unrelated reasons. Only
  *retire* meets T-225, and the two verbs are independently decidable.
  **Second finding:** T-225 is invoked at four sites (`8201`, `9301`, `9681`,
  `9777`) and **all four are semantic; zero are presentational.** It was
  established over semantic cases and *worded* ("diagram XML") over a wider
  population — a declaration scoped by its fixture, carried this time by a
  *ratified principle* rather than a measurement, which is worse because a
  principle is quoted rather than re-derived. Meanwhile the frozen standard
  pre-authorises presentational rewrites. The two point opposite ways on the same
  act and only conflict if T-225 reaches presentational content, which it never
  has. **The retire half needs an explicit operator ruling on T-225's scope — an
  ambiguity that is live now, not created by this task.**
  See `docs/reports/T-357-di-adoption.md` §Spike 4.

<!-- Original template guidance retained below. -->

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

## Exploration Plan

All spikes are **read-only research**. No build artifact is produced under this
task ID; on GO, implementation is filed as separate build tasks.

- **Spike 1 — archaeology (IW-1), 30 min.** Git history, decision records,
  standards docs, AEF rail history for any recorded reason `aef:position` exists.
  **Stopping rule:** if no record is found, the honest disposition is *"no recorded
  reason found"* — NOT *"it was an oversight"*. Absence of a record is absence of a
  record. (See the standing lesson that a lookup miss cannot carry a decision.)
- **Spike 2 — consumer census (IW-2), 20 min.** Grep the whole tree, not just
  `src/`, for `aef:position` readers and writers; name each one.
- **Spike 3 — expressiveness (IW-3), 30 min.** Enumerate what the designer
  persists as geometry today and map each to a DI construct. Failure to map even
  one is a finding.
- **Spike 4 — migration argument (IW-4), 20 min.** Read `src:8201` and the T-225
  ratification; state whether adoption is a silent migration (prohibited) or a
  deliberate versioned one (permitted, with what evidence).

## Technical Constraints

- **Reading must stay dual indefinitely.** 126 existing `.bpmn` files carry
  `aef:position` and no DI. An adoption that drops the `aef:position` reader
  stops all of them loading. Retirement is of the *writer*, not the reader.
- **The seam.** All 24 corpus maps change bytes if we emit DI, so AEF's pinned
  `source_bpmn_sha` fixtures need coordinated re-pinning — a two-party event, not
  an operator's call alone. (This constraint applies to *adoption*; it does NOT
  apply to T-340's scoped option (b), which is byte-neutral.)
- **Blast radius exceeds the editor.** `tools/yaml-to-bpmn.py` and the bridge
  parity assertions both sit on this geometry.
- **T-225.** `src:8201` ratifies that diagram XML is never silently migrated.

## Scope Fence

**IN:** whether to adopt DI as the geometry of record; what adoption costs; what
the migration path for 126 existing files is; the answer to IW-1.

**OUT:** implementing any of it. Also out: T-340's scoped option (b) — it is a
strict subset of adoption, byte-neutral, needs no AEF coordination, and ships on
the operator's T-340 ruling whether this inception says GO or NO-GO. This task
must not become T-340's blocker.

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

**Rationale:**

Portability is the fourth constitutional directive and aef:position is a proprietary re-implementation of a standard that already exists and is strictly richer (DI carries bounds, waypoints and label positions against our x/y). The injury is symmetric and measured: we auto-layout a third-party author's diagram on import because src:9742 falls back to auto-layout when aef:position is absent, and our own exports carry no DI, so bpmn.io scrambles our files exactly as we scramble theirs. Adoption retires the two-geometries question permanently rather than managing it. Recommending GO on exploring rather than on executing, because one assumption is unchecked and could flip it: WHY aef:position exists at all. There may be a recorded bridge constraint or a judgement that DI was too heavy for the yaml round trip, and I have not looked - that check is the inception's first spike, not a detail. Real costs to scope: it reaches tools/yaml-to-bpmn.py and the bridge parity assertions, not just the editor; all 24 corpus maps change bytes so AEF's pinned source_bpmn_sha fixtures need coordinated re-pinning; reading must stay dual indefinitely or 126 existing files stop loading; and rewriting every file on first save must be argued against the T-225 ratification 'diagram XML is never silently migrated' as a deliberate versioned migration rather than assumed exempt. Not blocking T-340: scoped option (b) is a strict SUBSET of adoption, byte-neutral, and is the first increment either way.

**Evidence:**

Research artifact: `docs/reports/T-357-di-adoption.md` (C-001).

**Recommendation still GO on exploring. The useful result of spikes 1-4 is that
the single question turned out to be three nested ones, each a strict subset of
the next, so no work is thrown away whichever depth is chosen:**

1. **Read DI when `aef:position` is absent.** = T-340 scoped (b). Byte-neutral, no
   standard revision, no T-225 question, no seam event. Fixes the user-facing
   defect: a third-party author's diagram survives being opened.
2. **Emit DI additively, keep writing `aef:position`.** No T-225 question (adds a
   representation, rewrites nothing) and no intent-expressiveness problem (the
   extensions stay). Costs: 24 corpus maps change bytes → coordinated re-pin with
   AEF; the standard gains a carrier it does not enumerate, which is additive
   rather than contradictory.
3. **Retire `aef:position`.** Needs a T-225 scope ruling, a v1.1 revision of the
   frozen two-party standard, and an answer to the intent gap in IW-3.

- `src:9406-9407`, `src:9582` — the DI trailer; IW-1; **G-021 [high]**, A-020,
  PL-102. Asked on the rail at offset 418.
- `src:9409-9421` — our half of the AEF corpus incident (their T-2682/T-2683):
  the guard that made this string a two-party subject **without anyone asking
  whether its sentence is true**.
- `docs/standards/aef-bpmn-mapping-v1.md:42-45` — frozen standard; ratifies A-3,
  and names `aef:position`, which is what makes step 3 a two-party revision.
- `src:8201`, `src:9301`, `src:9681`, `src:9777` — all four T-225 invocation
  sites, all semantic, none presentational.
- Commits: `fe35c6fa` (spikes 1-3), `2b81a929` (G-021).

**What would still flip this to NO-GO:** AEF answering A-020 with "yes, we generate
DI from your coordinates". That would mean the pipeline works as designed, step 1
remains worth doing on its own merits, and steps 2-3 become duplication of a stage
that already exists downstream. **Unanswered, and I am not treating the silence as
a no** — see G-021 on absence.

## AEF's answer — rail 417, received 2026-08-03 (decisive input, no decision taken)

The question this inception was blocked on is **answered**, and it changes the shape of
the go/no-go. Recorded here rather than left in a rail backlog.

1. **AEF never parses DI and never emits it.** Measured on their own source: `bpmndi`
   occurs **exactly once**, `tools/corpus_spec.py:347`, a namespace declaration with no
   reader and no writer behind it. Their round-trip table maps `aef:position → pos` and
   has **no DI row at all**. So DI adoption is not "switch the carrier" — on their side
   it is **net-new capability**, and nothing of theirs currently consumes DI.
2. **There is no record of why `aef:position` exists.** They searched decisions, reports
   and completed tasks: it appears as an established fact in the corpus format spec and
   nowhere as a choice with a rationale. Explicitly *not* claimed to be an oversight —
   absence of a record is absence of a record.
3. **On a document carrying BOTH geometries, they would not use a precedence rule.**
   Precedence says which field is more important; the real question is *which writer
   touched it last*, which the fields cannot answer. Their proposal: resolve by
   **provenance** (our fingerprint `aef:uid` present → `aef:position` authoritative and
   the DI is stale inbound; absent → DI is the author's arrangement and `aef:position`
   cannot legitimately be there), and **announce the collision either way** rather than
   resolve it silently — because that is precisely the case where someone's layout is
   about to be discarded. A silent precedence rule makes the contradictory-geometry state
   unobservable.
4. **Cost was undercounted twice, in both directions** (from our 418, still standing):
   the frozen standard `docs/standards/aef-bpmn-mapping-v1.md:42-45` *pre-authorises* the
   class of change (presentational, "derived, never authoritative") — but it **enumerates
   `aef:position` by name**, so adoption is a **v1.1 revision of a frozen two-party
   artifact**, not a fixture re-pin. And the scope is the **eight-element family**, not
   one field: `routingHint` (22 uses), `anchors` (19), `forceStraight` (12), `loopDetour`
   (9). **DI has no vocabulary for layout INTENT by design** — it records where an edge
   landed, not that it must stay straight. So maximal adoption cannot be a drop-in.

**What this does not do:** it does not decide anything. `fw inception decide` is
operator-only. My reading is that (3) is adoptable *independently* of the go/no-go — the
collision-announcement rule is worth having whichever way T-357 lands — and that (4)
bounds adoption's scope without disqualifying it.

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

### 2026-08-03T13:26:34Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
