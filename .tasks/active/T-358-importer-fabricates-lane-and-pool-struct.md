---
id: T-358
name: "Importer FABRICATES lane and pool structure the input never had: every third-party
  document gains 3 lanes and 1 participant on open"
description: >
  Measured T-356: all 5 third-party fixtures come out of open->save carrying lanes
  0->3 and participants 0->1. None of the input documents contains a single lane or
  pool. The catalogued import-loss class (T-337/340/347/348) is subtraction; this
  is the opposite direction and needs a different repair.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-03T16:12:36Z
last_update: 2026-08-27T21:17:35Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:02Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 1
      F4: 3
      F3: 4
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=1 
      (body/components:component-fabric-incidental); F4=3 
      (prose:routing-defect-class); F3=4 (prose:seam-fixture-or-pin); F1=2 
      (prose:process-editor-capability)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 9
    rationale: blast_radius=9 
      (paths:docs/reports/T-356-third-party-fidelity.md,docs/reports/T-397-import-repair-semantics-brief.md,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-358: Importer FABRICATES lane and pool structure the input never had: every third-party document gains 3 lanes and 1 participant on open

## Context

Measured 2026-08-03 by `tools/_t356-third-party-fidelity-cdp.mjs`; full table in
`docs/reports/T-356-third-party-fidelity.md`.

All **five** third-party fixtures gain `lanes 0->3` and `participants 0->1` on
open->save. **None of the input documents contains a single lane or pool.**

The whole import-loss class this arc has catalogued -- T-337 foreign tags, T-340 DI,
T-347 accepted-element content, T-348 root shapes -- shares one sentence: *what the
importer does not enumerate is invisible, and export writes only what `state`
holds*. That sentence describes **subtraction**.

This is the other direction. Export also writes what `state` holds **that the input
never did**, because `state` is initialised into our own lane skeleton and *an
absent lane set is indistinguishable from an empty one*. Same root shape as T-341
(an unresolvable `flowNodeRef` silently reassigns a node to the human lane) and the
same shape as the `n/a`-means-agreement family: a missing thing and a default thing
share one representation.

**Why this is worse than dropping.** A dropped element leaves a gap somebody may
notice. An invented lane assignment is **positively asserted governance metadata**
-- Lane=who, per the frozen mapping standard -- and it reads exactly like the
author's intent. Node counts stay plausible, the validator stays green, and the
document now says a third party's task is owned by a role their tool never
mentioned.

Blocked-adjacent, not blocked: the repair choice interacts with T-341's orphan-lane
ruling (both are "what do we do when lane membership is absent or unresolvable")
and should be decided with it, not before it.

## Acceptance Criteria

### Agent
> ### Investigation 2026-08-03 — site named, and the partition is NOT total
>
> **The site.** In `parseBpmnXml`, immediately after the `laneSet` read loop:
> `if (!lanes.length) lanes.push(...defaultLanes());` (`src` ~9647 — anchor on the
> `defaultLanes()` call inside `parseBpmnXml`, not the line number).
>
> **`defaultLanes()` (`src` ~1620) is not a neutral skeleton — it is the Authority
> Model.** It returns `human / Human · Sovereignty / authority: 'sovereignty'`,
> `framework / Framework · Authority / authority: 'authority'`, and
> `agent / Agent · Initiative / authority: 'initiative'`.
>
> **And every node lands in the first one.** Node lane membership resolves via
> `let laneId = lanes[0]?.id;` then searches `flowNodeRef` entries for a match. A
> document with no lanes has no `flowNodeRef` to match, so the initialiser stands:
> **`lanes[0]` is `human`, `authority: 'sovereignty'`.**
>
> So the accurate statement of this defect is not "three lanes appear". It is:
> **opening a third-party BPMN file silently asserts that every task in it is
> human-sovereign** — the highest authority level in the model, the one that means
> "can override anything, is accountable" — and saving makes that assertion the
> document. The author's tool has no concept of any of this.
>
> **AC2 is NOT satisfied, and that is the result the AC was written to force.**
> There are **three** paths into `!lanes.length`, not the two anticipated:
> (i) the input has no `laneSet` at all; (ii) a `laneSet` exists but yields zero
> `lane` children; (iii) `laneSets[0]` is empty while a *later* laneSet has lanes —
> the T-348 first-only read. **All three produce byte-identical output.** They
> cannot be separated by any current instrument, so per this AC's own terms the
> repair is blocked on making the partition total, not on choosing a default.
>
> Same landing site as T-341 (unresolvable `flowNodeRef` → human lane) reached by a
> different cause, which is why the two must be ruled on together: a fix that only
> changes the default value leaves three causes still sharing one output.

- [x] **The fabrication is reproduced and its SITE named** -- the specific line(s)
      where `state` acquires lanes/participants absent from the input, not "somewhere
      in parseBpmnXml". Anchor on a function signature, never a line number (they
      drift; T-340's filed anchor already did).

- [x] **The two causes are separated before any repair.** "Input had no lane set" and
      "input had a lane set we failed to read" currently produce the same output and
      must not share a verdict. Required evidence: one fixture of each, with
      different measured outcomes. If they cannot be separated, that is the finding
      and the repair is blocked on making the partition total.

      **Done — and the AC's own escape clause is what fired.** The investigation found
      **three** causes, not two, so "separate the two" was not satisfiable as written;
      the partition had to be *made* total first. `parseBpmnXml` now records
      `laneProvenance` over four disjoint values — `authored`, `defaulted:no-laneset`,
      `defaulted:empty-laneset`, `defaulted:later-laneset-ignored` — assigned on every
      path, so no document can leave the function without one.

      Evidence: `tests/fixtures/lane-provenance/` (four independently authored XML
      shapes, one per branch) run through the real importer in headless Chrome by
      `tools/_t358-lane-provenance-cdp.mjs` → **4 fixtures, 4 distinct verdicts**. The
      run fails if any two collide, so "separable" is asserted, not assumed.

      Branch order is load-bearing: (iii) is tested before (ii) because a document
      satisfying (iii) also satisfies (ii)'s surface condition, and reporting it as a
      plain empty laneSet would file **our** T-348 first-only read under **the
      author's** omission — the one case where the data was present and we discarded it.

      This chooses no default and changes no emitted byte: `_t308` byte-identity
      **24/24 identical, 0 drifted**. T-341's ruling is untouched and still the
      operator's.

- [x] **A negative control proves the probe can report NO fabrication.** A designer-
      produced corpus map genuinely has 3 lanes, so a probe that merely counts lanes
      in the output reads "3" for both the honest and the fabricated case and
      discriminates nothing. The control must be input-derived: lanes-in equals
      lanes-out for a map that carried them.

      **Done.** `authored-lanes.bpmn` carries 2 lanes named `Operations` / `Finance`
      and comes back `authored`, **2 in / 2 out**, with those exact names — a count of
      3 could not have distinguished it. Checked as its own assertion (control must be
      the only non-defaulted case, and its lane *names* must be input-derived), so it
      cannot pass by riding on the provenance check.

      `tools/_t358-teeth.py` proves both ACs' instruments can fail: control green plus
      **6 mutations, each red for its own predicted reason** — including one that
      changes only what a fabricated lane *asserts* (`sovereignty` → `none`), since the
      assertion and not the lane count is the defect this task names.

      **The teeth found a real defect in my own probe, which is why they exist.** The
      totality check was written as `seen.some(v => v === undefined)` over an array
      built with `.filter(Boolean)` — which strips exactly the values it looked for, so
      it could never fire. Mutation 3 was green when it should have been red. Totality
      is now tested before anything is filtered. An unreachable check is a constant,
      and a constant discriminates nothing.

> **The three ACs below are REPAIR, and repair needs the fabrication policy — which is
> T-341's open `[REVIEW]` ruling, not this task's.** Diagnosis here is complete (3/3 above).
> Consolidated view of all four open rulings, and why this one follows T-341 rather than
> standing alone: `docs/reports/T-397-import-repair-semantics-brief.md` (§ Q2b).

> ### 2026-08-09 — AEF measured their side, and on this axis we are the outlier (rail 487, T-403)
>
> AEF classify every emitted key as **sourced / derived / fabricated**, with a test
> (`test_fabricated_fields_are_enumerated`) that fails on any key belonging to none of the
> three. Their verbatim position:
>
> > **"We do not invent lanes or participants the input never had."**
>
> They fabricate *scheduling and lifecycle* fields (`workflow_type`, `tier`, `horizon`,
> `status`, `related_tasks`) and **derive** `owner` from the node's **lane** — a structure the
> author actually authored. We fabricate **the structure itself**: 3 lanes and 1 participant
> on every third-party document, on open.
>
> This is the one place their measurement **costs us** rather than confirming us, and it should
> not be softened into a fidelity nit. A fabricated lane asserts *who is accountable for a
> step*. They read accountability off authored structure; we invent the structure and then read
> accountability off our own invention.
>
> Their derivation is also **loud where it is weakest** — a `serviceTask` in a human lane
> resolves lane-wins *with a WARN*, and an `authority`-lane node falls back to `agent` under our
> own ratified wording (*the executor is still the agent; what is lost is provenance*, rail 95).
> Ours announces nothing at all. That contrast is an argument about the *announce* half of
> T-341's ruling independent of which lane policy wins.
>
> **Not independently verified by us** — this is their report of their own code, taken at its
> word. It does not change that our fabrication is measured on our side (3/3 diagnosis above).

- [x] **Repair does not silently reverse into the opposite defect.** Emitting zero
      lanes for a lane-less input must be checked against the corpus: if any existing
      map relies on the fabricated default, that reliance is a finding to file, not a
      reason to keep fabricating.

      **DONE 2026-08-27 — measured, no reliance found.**
      `tools/_t358-corpus-lane-provenance-probe.py`, rc=0. The test is provenance, not
      count: every lane in each rendered BPMN must be declared by name in its source
      `.workflow.yaml` `lanes:` array. Result: **0 of 24 maps carry a lane the source
      never declared.** So the repair changes no bytes for our corpus and cannot reverse
      into the opposite defect here — the corpus is not leaning on the bug.

      Reported but deliberately NOT a finding: 7 lanes hold zero `flowNodeRef`
      (assumption-validation, audit-process, harvest-pipeline, revisit-due-scan ×2,
      session-handover, upgrade-process). **All 7 are declared in source.** An empty
      AUTHORED lane and a FABRICATED lane are different things, and collapsing them
      would be the same missing-versus-default confusion this task exists to fix.

      Two wrong readings were produced before this one and discarded before reporting;
      both are recorded in the probe's docstring. (1) A regex hunting `lane:`/`role:`
      keys called 67 lane names undeclared — the names live in a top-level `lanes:`
      array it never read. (2) A debug dump sliced lists to `v[:2]`, making a 3-lane
      source read as 2 and manufacturing a discrepancy that did not exist; the
      truncation was in my instrument, not the data. Same shape both times, and the
      same shape AEF and I compared notes on at rail 650: searching for the shape you
      expect instead of the place the thing lives.

      > ### Measurement 2026-08-04 — the AC fires. NOT ticked, and that is the result.
      >
      > `tools/_t358-empty-lanes-blast-radius.mjs` — round-trips fixtures through the
      > REAL importer and REAL emitter in headless Chrome, on two builds served side by
      > side: the tree as it stands, and a temp copy with the fabrication suppressed
      > (the real tree is never edited — same discipline as `_t358-teeth.py`).
      >
      > **F1 — the naive repair reverses into the opposite defect, as this AC suspected.**
      > The fabrication sites are guarded by **different predicates**: the importer on
      > *emptiness* (`!lanes.length`, ~9705), every downstream site on *nullishness*
      > (`s.lanes || defaultLanes()` ~9511, `getLanes()` ~2087, `addLane` ~8068). `[]` is
      > truthy, so an empty array flows through all of them untouched and reaches an
      > emitter that opens `<bpmn:laneSet id="LaneSet_1">` unconditionally. Measured:
      > suppressing the importer default gives `lanes=0`, and we emit `laneSet=1,
      > lane=0` — **we would emit cause (ii) "empty laneSet", the exact shape our own
      > partition classifies as a third-party defect**, and our own output then
      > re-imports as `defaulted:empty-laneset`. Rendering survives (`renderAll()` ok on
      > all rows), so the opposite defect is semantic, not a crash — which is worse,
      > because nothing announces it.
      >
      > **F2 — NOT predicted, and it bounds what T-358 shipped: the fabrication
      > LAUNDERS ITSELF in one round-trip.** On the current build, `no-laneset.bpmn`
      > imports as `defaulted:no-laneset` — then our own emitted output re-imports as
      > **`authored`**, 3 lanes, with `authority="sovereignty"` in the bytes. Open a
      > third-party file, save it, reopen it: the second open reports the fabricated
      > assertion as human-authored, **by my own instrument**.
      >
      > So `laneProvenance` is a **parse-time** property, not a **document** property.
      > It survives exactly one hop. Saving is precisely what makes the assertion the
      > document, so the signal dies at the moment it would matter. Consequence for the
      > ruling: **any repair must act at or before the first save — a report-only
      > remedy cannot reach the corpus**, and cannot reach any file already saved.
      >
      > **The corpus half, answered — and the zero is a capability zero.** 141 `.bpmn`
      > in tree: 9 no-laneSet + 1 empty-laneSet = 10 that would import to `lanes=0`.
      > All 10 are test fixtures (8 authored for this defect class) plus one
      > hand-authored e2e probe under `.editor-versions/_trash/`. So **no production map
      > relies on the fabricated default** — but 122/141 carry `aef:position`, our own
      > exporter's fingerprint, and per F2 any third-party file that ever passed through
      > the editor was laundered into the "has lanes" bucket at its first save. The
      > census measures our generator, not the population — the same shape as the T-340
      > DI census (126 files, 0 with DI). Quoted as a bound on the evidence, not as
      > reassurance.
      >
      > This AC stays unticked: the obvious repair fails it. That is the AC working.
      >
      > ### Candidates MEASURED 2026-08-04 — so the ruling is a choice between outcomes
      >
      > `tools/_t358-repair-options-cdp.mjs` applies each candidate to a temp copy and
      > round-trips it through the real importer/emitter. No candidate is applied to
      > the tree; the default choice remains the operator's.
      >
      > | candidate | fabricates | asserts sovereignty | provenance survives save | emits empty laneSet | corpus bytes |
      > |---|---|---|---|---|---|
      > | current (no repair) | yes (3) | **true** | **no** | no | identical |
      > | **A** drop (importer + emitter) | no | false | yes | no | identical |
      > | **B** mark (provenance into the doc) | yes (3) | **true** | yes | no | identical |
      > | **C** neutral default (1 lane, `unassigned`) | yes (1) | false | no | no | identical |
      > | **AB** drop + mark | no | false | yes | no | identical |
      >
      > `renderAll()` ok on every candidate. Reading the table: **A alone ends the
      > fabrication; B alone ends the laundering; neither ends the other.** A's
      > "survives save" is not the signal being preserved — it is the *input property*
      > being preserved, which is the point of A. C keeps a lane for the downstream
      > consumers that assume one, at the cost of still inventing structure. Note A
      > requires BOTH halves: dropping only the importer half emits cause (ii) (F1).
      >
      > ### The probe's own instrument was wrong first, and it exposed a separate defect
      >
      > The first run printed "this candidate also changed the AUTHORED control's
      > output" for **all four** candidates — including ones that touch only the
      > defaulted path. Shape of the result said probe defect, not finding: the base row
      > compared its own sha against itself and so could never fire. Added an instrument
      > self-check (emit the same document twice in the same build). Result: **the build
      > is not byte-stable with itself** on those documents, so the comparison was void
      > rather than the candidates faulty.
      >
      > Diagnosed by `tools/_t358-export-determinism.mjs`: **`aef:uid` is minted fresh
      > per parse for any node that lacks one.** Designer-produced maps carry uids and
      > emit deterministically (`audit-process` 13563 bytes, `arc-lifecycle` 12270 —
      > stable); every third-party fixture is unstable (`kitchen-sink` differs on **81
      > lines** between two consecutive emits of the same input).
      >
      > **Consequence for this arc's main instrument:** `_t308` byte-identity 24/24 is
      > sound, and is sound *only for designer-produced maps* — the population that
      > happens to carry uids. It is structurally incapable of reporting on third-party
      > documents, which is the population every repair in this arc is aimed at. Not a
      > flaw in the 24/24 result; a bound on what it can be cited for, and I have cited
      > it repeatedly without that bound. Filed separately — one bug, one task.
      >
      > ### The claim I put on the rail, re-evidenced over the right population
      >
      > At RAIL-427 I told AEF T-358 "changes no emitted byte", citing `_t308` 24/24.
      > The claim was about third-party documents; the evidence ranged only over
      > designer maps. Built the instrument that can reach the other population:
      > `tools/_t358-byteid-thirdparty.mjs` compares current vs `3bf37909~1` over all
      > 10 third-party fixtures, normalising `aef:uid` in document order (the one field
      > that is legitimately nondeterministic per T-364) and demanding exact equality of
      > everything else.
      >
      > **10 identical, 0 drifted, 0 unusable.** The claim holds; the evidence for it
      > was narrower than the claim until now.
      >
      > The normaliser counts its substitutions and the run **fails** if it matched
      > nothing on every fixture — otherwise this would be the raw comparison it
      > replaced, wearing a normalised label. Cross-confirmation worth recording:
      > `kitchen-sink` normalised **81** uids, exactly the 81 lines the determinism
      > probe found differing between two emits of the same input. Two independent
      > measurements that could each have disagreed, agreeing that the instability is
      > entirely uid-attributable.
      >
      > Deliberately NOT wired into the bridge suite: its baseline is a pinned commit,
      > so as a standing gate it would silently compare against an ever-older tree.
      > It is an on-demand instrument; the standing fix belongs to T-364/G-023.

- [ ] **BLOCKED** — Bridge suite green; `_t308` byte-identity still 24/24 (a repair here
      must not change what we emit for existing maps)

- [ ] **BLOCKED** — `tools/_t356-third-party-fidelity-cdp.mjs` re-run: `lanes` and
      `participants` deltas gone from all five rows, with the other columns unchanged
      (this task repairs fabrication only, not the DI/pool/node losses those rows also
      carry)

Both are downstream of the Human ruling below and are marked **BLOCKED** rather than
left looking merely undone: there is no repair to verify until a candidate is chosen,
and a task whose scope is blocked should look blocked (same convention as T-340). The
diagnosis ACs above are genuinely complete — the block is on the repair, not the
investigation.

**Caveat carried forward when these are eventually run:** `_t308` byte-identity is
sound *only for designer-produced maps*, because `aef:uid` is minted fresh per parse
for any node lacking one, so every third-party fixture emits nondeterministically. A
green 24/24 here says nothing about the population this repair is aimed at — use
`tools/_t358-byteid-thirdparty.mjs` for that half.

### Human

- [ ] [REVIEW] Choose the lane/pool fabrication repair: **A · B · C · AB · no repair**

      **This ruling already existed — it was recorded in prose and never filed as an
      AC.** `## Decisions` says *"the default choice remains the operator's"*, and the
      three remaining Agent ACs are all downstream of it, so the task has read as
      in-progress agent work while actually waiting on a decision nobody was asked for.
      Filed here on 2026-08-10 so it appears in `fw task verify` and the review queue.
      Same mis-filing as T-340's AC1 and T-341's AC1; Agent→Human is the safe conversion
      direction (T-1811/T-1878 restricts Human→Agent, not the reverse). **No measurement
      below is new** — all of it was already in `## Decisions`, gathered here so the
      ruling is decidable without reading the whole task.

      **Why this is not the agent's call:** every candidate changes what we assert about
      a *peer's* document on the sovereignty axis — whether a third-party file that
      names no lanes comes back claiming a `sovereignty` lane it never had. AEF measured
      their own importer and does **not** fabricate (rail 484/486, our T-403), so this is
      also the axis on which we are currently the outlier at the seam.

      **Measured 2026-08-04, `tools/_t358-repair-options-cdp.mjs`** — every candidate
      applied to a temp copy and round-tripped through the real importer/emitter:

      | candidate | fabricates | asserts sovereignty | provenance survives save | emits empty laneSet | corpus bytes |
      |---|---|---|---|---|---|
      | current (no repair) | yes (3) | **true** | **no** | no | identical |
      | **A** drop (importer + emitter) | no | false | yes | no | identical |
      | **B** mark (provenance into the doc) | yes (3) | **true** | yes | no | identical |
      | **C** neutral default (1 lane, `unassigned`) | yes (1) | false | no | no | identical |
      | **AB** drop + mark | no | false | yes | no | identical |

      **Three facts that constrain the choice:**
      1. **A must be taken in BOTH halves or it inverts into a worse defect.** Dropping
         only the importer default yields `lanes=0` while the emitter still opens
         `<bpmn:laneSet>` unconditionally — we would emit the *empty laneSet* shape our
         own partition classifies as a third-party defect, and our output re-imports as
         `defaulted:empty-laneset`. Rendering survives, so nothing announces it.
      2. **A report-only remedy cannot work.** `laneProvenance` is a parse-time property
         that survives exactly one hop: a third-party file imports as `defaulted`, and
         our own saved output re-imports as `authored` with `authority="sovereignty"` in
         the bytes. Saving is what makes the invention the document. **Any repair must
         act at or before the first save**, and none can reach files already saved.
      3. **"No production map relies on the default" is a capability zero, not
         reassurance.** 10 of 141 `.bpmn` would import to `lanes=0` and all 10 are
         fixtures — but 122/141 carry `aef:position`, our own exporter's fingerprint,
         and per (2) any third-party file that ever passed through the editor was
         laundered into the "has lanes" bucket at its first save. The census measures
         our generator, not the population (same shape as T-340's DI census).

      **Steps:**
      1. Read `## Decisions` → *"Candidates MEASURED 2026-08-04"* for the full run.
      2. Choose one. Note that **A and AB are identical on every measured column**, so
         B buys nothing on top of A *as measured* — if you pick AB, pick it for a reason
         the table does not capture, and say so in the rationale.
      3. Record it: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-358 lane/pool fabrication repair: <A|B|C|AB|none>" --task T-358 --rationale "<why>"`

      **Expected:** one option recorded as a decision. The three remaining Agent ACs
      then become executable and the repair ships under this task.

      **If not:** if none fits, the likely reason is that the real question is *"may we
      ever assert structure a peer's document did not contain?"* — which is broader than
      lanes and would want its own inception rather than being settled here.

      **Recommendation: A (drop, both halves).** It is the only candidate that stops us
      inventing a sovereignty assertion on a peer's document, it is byte-identical on the
      corpus, `renderAll()` is ok on it, and no production map depends on the fabricated
      default. It also puts us where AEF already is, which removes the outlier position
      at the seam rather than annotating it. **The honest cost:** downstream consumers
      that assume at least one lane exists now meet `lanes=0` — C exists precisely to
      keep a lane for them at the price of still inventing structure, and if a consumer
      turns up that genuinely cannot take zero, C is the right answer over A.

<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Recommendation

**Recommendation:** ABSTAIN — the choice among A · B · C · AB · no-repair is yours, and
this block exists to make that decidable rather than to pick one.

**Why abstention rather than a preference.** The consolidated brief
(`docs/reports/T-397-import-repair-semantics-brief.md:35,238`) files this as **Q2b, which
follows from Q2a (T-341)**, and files Q2 as *"operator only — no agent recommendation"*:
Q1 (what we do with content we failed to read) has a ratified precedent to reason from,
Q2 (what we are permitted to *invent*) has none, and it should not acquire one from an
agent. Every candidate here changes what we assert about a **peer's** document on the
**sovereignty axis** — whether a third-party file naming no lanes comes back claiming a
`sovereignty` lane it never had. An agent proposing where sovereignty defaults is an agent
proposing its own authority.

**Ruling this without ruling T-341 is the specific hazard.** The brief's constraint §262:
*"Q2a and Q2b must agree — both decide what the importer may invent."* They are one
decision wearing two task IDs, and the way they acquire inconsistent policies is being
ruled on separately, weeks apart.

**One measured EXCLUSION, which is not a recommendation.** Whatever you rule, **option A
cannot be taken in the importer half alone.** Dropping only the importer default yields
`lanes=0` while the emitter still opens `<bpmn:laneSet>` unconditionally, so we emit the
empty-laneSet shape our own partition classifies as a third-party *defect*, and our output
re-imports as `defaulted:empty-laneset`. Rendering survives, so nothing announces it. That
is the task's own established constraint — *"repair must not silently reverse into the
opposite defect"* — and it excludes a half-move without preferring any whole one.

**Evidence:** `tools/_t358-repair-options-cdp.mjs`, measured 2026-08-04 — every candidate
applied to a temp copy and round-tripped through the real importer/emitter. All five leave
**corpus bytes identical**, so byte cost does not discriminate between them and cannot be
used to smuggle in a preference. Diagnosis is complete: 3 of 6 Agent ACs are ticked (the
fabrication reproduced, its site named, the two causes separated, and a negative control
proving the probe can report *no* fabrication). The remaining three are all repair, and
they are BLOCKED on this ruling — not on further measurement.

**Seam context you may want:** AEF measured their own importer (rail 484/486, our T-403)
and does **not** fabricate. On this axis we are currently the outlier at the seam. I record
that as a fact about their position, not as an argument for adopting it — "the peer does
X" is not a reason, and treating it as one would let the seam decide a sovereignty question
by drift.

## Verification

bash tests/run-bridge-tests.sh
node tools/_t356-third-party-fidelity-cdp.mjs
python3 tools/_t358-corpus-lane-provenance-probe.py

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
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

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-03T16:12:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-358-importer-fabricates-lane-and-pool-struct.md
- **Context:** Initial task creation

### 2026-08-03T16:42:23Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-08-08 — population widened 5 → 10 by T-367; the universal quantifier does not hold

Measured by `tools/_t367-aef-injection-footprint.mjs` over all 10 fixtures in
`tests/fixtures/third-party/` (this task's evidence base was 5).

**This task's title says every third-party document gains 3 lanes and 1 participant on
open. On 10 fixtures it is 8/10 for lanes and 6/10 for participants.**

`caseagile-local-ns.bpmn` (2 lanes in → 2 out) and `kitchen-sink.bpmn` (2 → 2) carry
their own lane sets, and the importer **preserves them and fabricates nothing**. The
`!lanes.length` guard is doing exactly what it says; the two documents that reach it
with lanes never enter the branch.

The defect is unchanged and the site is unchanged. What was wrong is the quantifier:
"every" was true of the 5 documents measured and was never true of the class. Same
shape as [[measurement-promoted-past-its-scope]] — an honest measurement carried into
a wider sentence.

**It also sharpens the repair.** A fix that changes what `defaultLanes()` returns would
alter output for 8 of 10 and leave 2 correct documents untouched, so the two preserving
fixtures are the regression control the repair needs: they must stay byte-identical
across any change to the fabrication path, and nothing currently asserts that.

**Participants move in BOTH directions, which a net count would have hidden.** 6
fixtures gain a participant (0 → 1); 3 LOSE one (`bizagi-nested-ns`,
`collaboration-message-flows`, `kitchen-sink`, all 2 → 1) — the two-pool-saves-as-one-pool
collapse from RAIL-400, a different defect sharing the same column. A net participant
delta over the corpus is +3 and means nothing; see [[counts-that-hide-their-distribution]].

**`laneProvenance` classifies all 10 correctly and is silent about the thing that
matters most in one of them.** Verdicts measured, not inferred (the probe now returns
`m.laneProvenance`): 8 `defaulted:*`, and `caseagile-local-ns` + `kitchen-sink` come
back **`authored`** — the two preserving documents, on real third-party bytes rather
than a purpose-built fixture. That is this task's negative control holding up outside
its own corpus.

The exception is `bizagi-nested-ns.bpmn`, and it is not a new cause — I first wrote it
up here as a witness for path (iii) and that was **wrong**. Measured, it is
**`defaulted:empty-laneset`**, path (ii): both its processes carry a self-closing
`<laneSet/>`, so nothing was ignored and the value is accurate.

What the value cannot say is that the document also lost **every node**. Bizagi writes
an empty stub process first and the content second; `parseBpmnXml` reads `processes[0]`
(T-348) and yields **0 nodes, 0 edges from a 9 KB file**. The saved output contains none
of the author's content — three fabricated governance lanes, our namespace,
`isExecutable` flipped to true — and a reader handed `defaulted:empty-laneset` concludes
"the author had no lanes, so we defaulted", which is true, sufficient-sounding, and
attributes the whole event to the author's omission.

**So `laneProvenance` is scoped to laneSet selection while the loss here is process
selection — two axes, one of them unreported.** This does not make the taxonomy wrong;
it makes it non-diagnostic exactly where the outcome is worst. Whatever ruling lands on
the default, the provenance signal should not be the only thing a caller sees, or the
total-loss case will keep reporting as an ordinary default.
