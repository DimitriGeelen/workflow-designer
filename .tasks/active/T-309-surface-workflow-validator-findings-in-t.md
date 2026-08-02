---
id: T-309
name: "Surface workflow validator findings in the designer"
description: >
  Inception: Surface workflow validator findings in the designer

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-29T20:09:10Z
last_update: 2026-08-02T10:58:07Z
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

# T-309: Surface workflow validator findings in the designer

## Problem Statement

We wrote a semantic workflow validator and then never showed it to the people who author
workflows. `tools/validate-workflow.py` carries roughly a dozen rules across two classes — a
`Validator` for the YAML form and an `XmlValidator` for the BPMN form — covering gateway structure
(`E-GW-OUTGOING`, `W-GW-AMBIGUOUS`), parallel fork/join sanity (`W-PGW-CONDITION`, `W-PGW-NOOP`,
`W-PGW-UNBALANCED`), graph reachability (`W-UNREACHABLE`, `W-DEADEND`), constituents, and required
I/O inputs. Its own suite is green at 34 passed, 0 failed. It runs in the bridge suite and from the
CLI. A grep of `src/aef-workflow-designer.html` for any validation surface returns nothing.

So the feedback exists and arrives in the wrong place at the wrong time: in CI, to whoever reads the
log, after the map is already authored — never on the canvas, to the person making the mistake, while
they are making it.

**Why now:** the operator brought four screenshots of AEF-authored maps this session. One
(`fw_3_failure`) shows an `exclusiveGateway` fanning six labelled branches — external, dependency,
unknown, design, environment, code — into a single shared target. Exclusive is semantically correct
there (a failure has one type; parallel would fire all six), but six branches that reconverge
immediately with no intervening difference is a decision without consequence: it is a data field
wearing a gateway's clothes. No current rule covers it, and nothing in the editor would have raised
an eyebrow. The operator spotted it by eye — which is precisely the work the validator was written
to stop doing by eye.

**For whom:** map authors on both sides of the seam. Note the screenshots were AEF's maps
(`aef-task-lifecycle`, `aef-tier0-escalation`, `draft-knowledge-leveling` — none in our corpus, which
has the unprefixed `task-lifecycle`/`tier0-escalation`), so anything surfaced here will fire on peer
content and is therefore a rail conversation, not only a local feature.

## Assumptions

- **A-1:** The existing rule set is broadly right, so the work is plumbing rather than new
  intelligence. Evidence for: 34/0 suite, rules mirrored across both validator classes. Evidence
  against: the six-way-XOR case shows at least one real smell uncovered — the set is good, not
  complete.
- **A-2:** Authors want this feedback live. Untested, and the most likely thing to be wrong: an
  editor that nags while you are mid-thought is worse than one that stays quiet. The `W-*` rules are
  advisory by design, and a warning that cannot be dismissed becomes noise the author learns to
  ignore.
- **A-3:** Validation can run client-side. The rules are pure graph/structure analysis over the
  parsed model with no `aef:`-semantics lookups and no I/O — but they are written in Python, and the
  designer is a single self-contained HTML file. This is the load-bearing feasibility question.
- **A-4:** Surfacing findings changes no exported bytes. Should hold by construction (display only),
  and T-308 just established the measurement technique for proving it —
  `tools/_t308-export-byte-identity-cdp.mjs <ref>`.

## Open Questions

- **IW-1: Where do findings surface — live gutter markers on the canvas, an on-demand panel, or a
  save-time gate?**
  confidence: 3
  disposition: PRICED, NOT DECIDED — anchorability measured over all 23 XmlValidator rules
    (2026-08-02, spike 3); the choice among the three surfaces is a product call reserved to the
    operator.
  rationale: Two of the three options require every finding to name something that exists on the
    canvas at a position, which is a property of the emitter and the renderer, not a preference.
    15 of 23 rules are gutter-able (12 NODE, 3 LANE); 8 are not (3 DOC, 2 VALUE, 1 REFERENT,
    1 DROPPED, 1 LANE-PAIR). Split by severity the gutter INVERTS coverage: it would show 91% of
    WARNs and only 40% of ERRORs, because a finding is anchorable when the document is well-formed
    enough to contain the element it is about, and the ERRORs are what fires when it is not. So a
    panel is the only surface that can carry the whole set; a save-time gate covers exactly the six
    structural ERRORs the gutter cannot show, making IW-1 and IW-3 complements rather than rivals.
    Note `E-XML-FLOW-DANGLING`: the id RESOLVES in the document and the edge is still absent from
    the canvas because renderEdges skips it (src:3501-3504) — resolving against the document scores
    it anchorable and is wrong. Verification: 22 of 23 rows confirmed against real documents,
    0 disagreements — 9 from on-disk BPMN, 3 from scratch probes, 10 more from the BRIDGED
    documents the cross-form harness materialises in memory on every gating run. (My first pass
    said "11 unverified" because its denominator was BPMN files ON DISK — the same
    scoped-by-the-artifact-that-was-lying-around error as E-XML-FLOW-DANGLING, committed inside
    the instrument that found it.) The one row still unmeasured is E-XML-STRUCTURE, and it is
    unreachable rather than merely unwitnessed: no emitter produces a wrong root element.
    Full working in docs/reports/T-309-validator-surfacing.md.
  <!-- Not decided by this spike: live-vs-on-demand (A-2 still untested) and whether a gate blocks
       or advises (Authority Model — operator's call). The corpus cannot answer any of it: 25
       documents, 7 findings, 1 of 23 rules, 24/25 clean. -->

- **IW-1 addendum: the `location` field is prose, not a reference.** `"node 'wrk_2_context'"`,
  `"lane '%s' -> lane '%s'"`, `"<bpmn:laneSet>"` — any surface that points at something must parse
  the id back out of a sentence, and two rules (`E-XML-NODE-TYPE`, `E-XML-AUTHORITY`) degrade to
  `'?'` for exactly the malformed element the author most needs pointed at. If a surface other than
  the panel is chosen, a structured `location` is a prerequisite, not a nicety.

- **IW-2: How do the Python rules reach the browser — port them to JS in the designer, call the
  existing validator over HTTP via the gallery sidecar, or compile/share a single rule spec?**
  confidence: 3
  disposition: PRICED, NOT DECIDED — the routes carry measured costs (2026-08-02, spike 2); the
    choice between them is an architecture call reserved to the operator.
  rationale: Port surface is XmlValidator alone — 681 lines / 20 rule ids, not 1636 / 46 — and the
    rules are pure (one open() in the file, at the CLI entry; no os/subprocess/network), with the
    editor already building the tree at src:9596. Route (c) cannot express the traversal and
    geometry predicates and decays into route (a) with an extra artifact. Route (b) is cheapest but
    structurally absent in the standalone single-file artifact AEF pins — so it withholds the
    feature from the only population measured to fire. Route (a)'s real cost is a third
    implementation of a rule set whose second implementation shows 11/46 coverage drift and whose
    behavioural agreement NO instrument in the tree can observe. Full working in
    docs/reports/T-309-validator-surfacing.md.
  <!-- The portability question underneath: two implementations of one rule set is how they drift
       (PL-002 is exactly this class — the editor's namespace drifting from the canonical). A shared
       declarative spec avoids the drift but costs more up front. An HTTP call keeps one
       implementation but makes validation unavailable in the standalone/file:// designer, which is
       a real usage mode. -->

- **IW-3: Are findings ever blocking, or always advisory?**
  confidence: 3
  disposition: PRICED, NOT DECIDED — blocking vs advisory is an Authority Model call reserved to the
    operator (2026-08-02, spike 4). What is now measured is what a gate would actually police.
  rationale: Only ERROR rules are blocking candidates, so the prior question is whether a document
    violating each can reach the editor at all. Measured over three channels (editor operation /
    direct state write / import), every case starting from a real corpus map and exporting through
    the real serializer, verdicts three-way so a silent guard is distinguishable from a silent
    validator. VALIDATOR-BLIND = 0. Results: a gate would fire on 5 of 10 ERROR rules, and **all 5
    of those can arrive by import** (only 2 can be authored) — so a blocking gate would mostly
    refuse a save over a defect that was in the opened map beforehand. First stated as 4 of 5;
    measuring the two cells the table marked "not measured" moved it to 5 of 5, corrected in the
    report rather than absorbed. E-XML-STRUCTURE is now confirmed unreachable from EVERY channel
    (import silently repairs a wrong root, preserving all counts across 24 maps), which independently
    reproduces T-335's unreachable-not-unwitnessed row. Separately, 3 ERROR rules
    (LANEREF-DANGLING, ID-DUP, LANES-EMPTY) are repaired inside parseBpmnXml and therefore cannot be
    surfaced by ANY surface — that constrains IW-1 as much as IW-3. Import verdicts hold across all
    24 corpus maps; widening from one map caught a MIXED reading that turned out to be a probe
    artifact. Full working in docs/reports/T-309-validator-surfacing.md.
- **T-349 (2026-08-02): the whole import-loss class is invisible to all three priced surfaces,
    and the surface that could show it is not on the list.** The three ERROR rules repaired inside
    `parseBpmnXml` were the first instance of this constraint; T-347 and T-348 make it a much larger
    population — 5 content shapes and 7 root-level shapes, plus T-337's tags and T-340's DI sub-tree.
    Located from source rather than memory: loss happens *inside* `parseBpmnXml` (src:9595+), and
    the two sites that populate `state` — src:9124 (import) and src:6911 (`_restoreSnapshot`, the
    undo path) — are both downstream of a `parseBpmnXml` call, so this is a property of every route
    into `state`, not just of import. Every priced surface reads at or after that point — a panel
    and a gutter render from `state`, and a save-gate runs over what `buildBpmnXml(state)` produces.
    **Content that never entered `state` cannot appear in any of them, by construction, no matter
    how the rules are delivered (IW-2).** Note also that the designer runs *no* validator today:
    `XmlValidator` is `tools/validate-workflow.py`, a separate CLI, so all three surfaces are
    prospective and none of them inherits an existing import-time view.

    **Counter-example attempt, per the method — and it succeeds, which is the useful part.** One
    mechanism *does* reach this class: `adoptImportedXml(text, opts)` (src:9101) holds the original
    `text` in scope and calls `parseBpmnXml(text)` on the very next line. An input-vs-re-export
    comparison at that moment would see every one of these losses — it is exactly what
    `tools/_t338-input-fidelity-cdp.mjs` already does out-of-band. The original `text` is simply
    **discarded when the function returns**; nothing retains it. So this is not an impossibility, it
    is an unbuilt **fourth surface — an import-time fidelity report** — which is architecturally
    unlike IW-1a/IW-2/IW-3: it needs no rule engine, no port-to-JS decision, and no severity model,
    because it compares two documents rather than evaluating predicates. **It should be priced
    alongside the other three rather than assumed to be covered by them**; on current evidence it is
    the only one of the four that can address the T-337/T-340/T-347/T-348 class at all.

  <!-- Correction recorded: an earlier Recommendation paragraph claimed IW-3 "no longer needs a
       separate ruling" because the universal/dialect class decides the channel. That was a sentence
       promoted past its measurement — the class decides WHERE a finding goes, not WHO may override
       it. Authority was never in scope for IW-1b. -->
  <!-- Spike 4 also surfaced a defect that is not a pricing input: E-XML-NODE-TYPE loses a node on
       import (15/15 affected corpus maps, 15 nodes) and the export then validates clean. Filed as
       its own build task per one-bug-one-task; it is upstream of every surfacing decision. -->
  <!-- Leaning advisory-only: the validator already grades its own findings ERROR vs WARN, and
       authority over what gets saved belongs to the human (Authority Model). A designer that
       refuses to save is the tool overriding the author. But E-GW-OUTGOING is an ERROR for a
       reason, and shipping a map that cannot execute has a downstream cost too. -->

- **IW-4: Does the rule set need the missing XOR-with-identical-targets rule before or after the
  surfacing work?**
  confidence: 3
  disposition: RESOLVED — NO. Closed as T-319, DECLINED (not deferred) on measurement, not taste.
  rationale: Predicate questions were posed on the rail before any source edit; AEF measured their
    live corpus at 2 strict hits, both already caught by W-XML-GW-AMBIGUOUS, so T-319-unique = 0.
    Their keeper: a predicate that only pays off in the form you cannot justify is a predicate to
    leave alone. The motivating instance was also misremembered — draft-knowledge-leveling is not a
    reconvergence case. Consequence: the rule set needs no addition before the surfacing work.
  <!-- The triggering example is not currently caught, so surfacing alone would not have helped the
       operator with THIS map. Suggests the rule is part of the deliverable, not a follow-up — but
       it is also independently useful and separately shippable. -->

- **IW-5: What happens when the corpus already violates the rules?**
  confidence: 3
  disposition: RESOLVED — nothing lights up. 112 maps measured (24 rendered BPMN + 25 YAML sources
    + 63 .editor-versions snapshots), zero findings on both paths. No alarm-fatigue risk.
  rationale: Measured 2026-07-29, recorded in docs/reports/T-309-validator-surfacing.md. The green
    is falsifiable, not a broken harness — control injections fire (dropping a sequenceFlow gives
    W-XML-DEADEND + W-XML-UNREACHABLE; dropping a flowNodeRef gives W-XML-NODE-UNASSIGNED, both
    exit 1). Bounded honestly: all three populations are committed/saved states, clean by selection
    bias. The mid-authoring population a designer-side validator actually sees is NOT sampled, so
    this rules out noise on finished work only.
  <!-- Unmeasured, and it gates everything: if opening ordinary maps lights up warnings, the feature
       is dead on arrival regardless of how well it is built. Must be measured FIRST — run the
       validator across all 24 corpus maps plus the reachable AEF maps and count findings before
       designing any UI. -->


## Exploration Plan

Ordered so the cheapest thing that can kill the idea runs first.

1. **Baseline the corpus (IW-5) — 30 min.** Run both validator paths across all 24 corpus maps and
   the reachable AEF maps; tabulate findings by rule and severity. If ordinary maps light up, that
   result reshapes or kills the feature and everything downstream is wasted effort. Deliberately
   first.
2. **Price the three delivery routes (IW-2) — 60 min.** For each of port-to-JS / sidecar-HTTP /
   shared-spec: what changes, what can drift, and does it survive the standalone `file://` designer.
   Read the rule implementations to judge how mechanical a port would actually be.
3. **Sketch the surfaces (IW-1, IW-3) — 45 min.** Not code — describe where a finding appears, how
   it is dismissed, and what happens with 40 of them. Weigh against the existing nudge precedent
   ("This map could use Clean layout"), which is the house pattern for advisory feedback and is
   already proven not to annoy.
4. **Price the missing rule (IW-4) — 20 min.** Write the XOR-identical-targets predicate against the
   real gateway data and check it against the corpus for false positives. Cheap, and it tells us
   whether the rule set needs work before the surface does.

Time-box: one session. Deliverable is `docs/reports/T-309-validator-surfacing.md`, written
incrementally per C-001 — the thinking trail is the artifact.

## Technical Constraints

- **The designer is one self-contained HTML file** served both from the gallery sidecar and opened
  directly as a file. Any surfacing that requires a server makes validation silently absent in the
  standalone mode rather than degraded — a failure mode worth naming before it is designed in.
- **The rules are Python** and the editor is browser JS. There is no shared runtime, which is what
  makes IW-2 the real cost driver rather than a detail.
- **Zero export surface is mandatory.** Display-only by construction, and provable —
  `tools/_t308-export-byte-identity-cdp.mjs <ref>` (built this session) measures it across the whole
  corpus.
- **Peer content.** The maps that triggered this are AEF's. Anything that fires on their maps is a
  rail conversation; the 832↔AEF seam is contract+fixture based (T-559) and their tooling is not
  ours to invoke.
- **Advisory authority only.** Under the Authority Model the framework enforces and the human
  decides. A validator that refuses to save inverts that — which is IW-3, and it is a governance
  question before it is a UX one.

## Scope Fence

**IN:** where and how existing validator findings reach a map author in the designer; whether they
are advisory or blocking; the delivery mechanism for the rules; and the one missing rule the
triggering example exposed (XOR with identical targets).

**OUT:**
- Rewriting or re-grading the existing rule set beyond that single addition.
- Auto-fixing anything. Detection and correction are separate problems; bundling them is how a
  narrow, shippable feature turns into an unbounded one.
- The layout/lane-fitting complaints from the same batch of screenshots. Those are T-125 (lane
  compaction), T-105 (edge-label collision) and T-101 (bake Clean into the corpus), all already
  active. Same screenshots, different defect class — not this task's problem.
- Whether cross-process relationships should be modelled edges rather than prose comments (the
  T-307 corpus-composition finding). Upstream of T-280/T-281 and unowned, but not this either.

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
- The corpus baseline is quiet enough that surfacing findings would not train the operator to
  ignore them — **MET**: 112 maps, 0 findings, both paths, green proven falsifiable by injection.
- At least one rule that already exists and is already tested would have caught a defect the
  operator hit in real use — **MET (conditionally)**: `W-XML-NODE-UNASSIGNED` covers the
  `pen_inbound_classifier` unlaned-node block *if* the cause is lane membership rather than lane
  geometry. Discriminating test needs the map bytes, which are not reachable from here.
- The delivery route is bounded and survives the standalone `file://` designer — **NOT PRICED**
  (IW-2 not run).

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

The rules already exist and are already trusted — tools/validate-workflow.py carries ~12 semantic rules across both a YAML Validator and an XmlValidator (E-GW-OUTGOING, W-GW-AMBIGUOUS, W-PGW-CONDITION/NOOP/UNBALANCED, W-UNREACHABLE, W-DEADEND, constituents, required-inputs) and its own suite is green at 34 passed, 0 failed. What is missing is reach: a grep of src/aef-workflow-designer.html finds no validation surface at all, so the checks run only in the bridge suite and from the CLI and never reach the person drawing the map, which is where the mistake is actually made. Operator evidence arrived this session as four screenshots of AEF-authored maps; the modelling smell in one of them (an exclusiveGateway fanning six labelled branches into a single shared target) is real but slips through today because no rule covers XOR-with-identical-targets. This is plumbing an existing, tested capability to an existing UI rather than new intelligence, so the cost is bounded; the exploration should price WHERE findings surface (live gutter markers vs an on-demand panel vs save-time gate) and settle the sovereignty question of advisory-vs-blocking, not whether the rules are worth having.

**Revision after spike 1 (2026-07-29) — recommendation stands at GO, but the SHAPE changed.**

The exploration ran one of four spikes before the inception commit gate required convergence
(2 exploration commits, no decision). IW-5 was sequenced first precisely because it could kill
the idea; it did not, but it moved a prerequisite into the critical path that the filing-time
recommendation above did not know about.

The filing-time rationale says the rules "carry ~12 semantic rules across both a YAML Validator
and an XmlValidator" and that "what is missing is reach". Counted rather than inferred, that is
too generous: **only 7 rule ids are shared between the two classes**, and `W-GW-AMBIGUOUS` —
exclusive gateway with more than one unconditioned outgoing edge — exists on the **YAML path
only**. Confirmed empirically: stripping every `conditionExpression` out of a corpus BPMN map
fires nothing (exit 0). The designer speaks BPMN. So surfacing "the validator" in the editor
today would surface the weaker rule set, and would specifically NOT answer the gateway question
that prompted this inception.

That makes rule parity a **prerequisite of the first slice, not a follow-up**. It also makes the
first slice smaller and more certain than the filing-time framing implied: port/expose the XML
rule set, close the `W-GW-AMBIGUOUS` gap, and surface the result — with `W-XML-NODE-UNASSIGNED`
as the lead-value rule, because it is the one with a live operator defect behind it.

**Evidence:**

- Baseline: 24 rendered BPMN + 25 YAML + 63 editor snapshots = **112 maps, 0 findings**, both paths.
- Falsifiability control: drop a `sequenceFlow` → `W-XML-DEADEND` + `W-XML-UNREACHABLE`, exit 1;
  drop a `flowNodeRef` → `W-XML-NODE-UNASSIGNED`, exit 1. The zero is a measurement (PL-061).
- Rule-parity count: 7 shared ids; `W-GW-AMBIGUOUS` YAML-only; `W-XML-NODE-UNASSIGNED` and
  `W-TYPE-LANE-MISMATCH` XML-only. `tools/validate-workflow.py:302` vs `:773` / `:957`.
- Live operator defect (`pen_inbound_classifier`, screenshot 2026-07-29): ~14 nodes below all lane
  bands. Map not reachable — absent from our corpus, our gallery (`/api/list`, 6 maps) and AEF's
  (11 maps) — so this is read off the screenshot, NOT validated.
- Full trail: `docs/reports/T-309-validator-surfacing.md`.

**Unpriced — carried into the build task's design phase if this goes GO:**

- IW-2 (delivery route: port-to-JS vs sidecar-HTTP vs shared spec; `file://` survival) — not run.
- IW-1 / IW-3 (where findings surface; advisory vs blocking) — not run.
- IW-4 (the XOR-identical-targets rule) — not run. Note it is now a *second* missing rule
  alongside `W-GW-AMBIGUOUS`, not the only one.

**Confidence:** high that the feature is worth building and will not be noisy; low on cost,
because the delivery route is the expensive unknown and it is exactly what has not been priced.
A NO-GO here is entirely defensible on "not yet priced" grounds — the honest read is that spike 1
established the value and left the cost open.

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

**Rationale**: Recommendation: GO

Rationale:

The rules already exist and are already trusted — tools/validate-workflow.py carries ~12 semantic rules across both a YAML Validator and an XmlValidator (E-GW-OUTGOING, W-GW-AMBIGUOUS, W-PGW-CONDITION/NOOP/UNBALANCED, W-UNREACHABLE, W-DEADEND, constituents, required-inputs) and its own suite is green at 34 passed, 0 failed. What is missing is reach: a grep of src/aef-workflow-designer.html finds no validation surface at all, so the checks run only in the bridge suite and from the CLI and never reach the person drawing the map, which is where the mistake is actually made. Operator evidence arrived this session as four screenshots of AEF-authored maps; the modelling smell in one of them (an exclusiveGateway fanning six labelled branches into a single shared target) is real but slips through today because no rule covers XOR-with-identical-targets. This is plumbing an existing, tested capability to an existing UI rather than new intelligence, so the cost is bounded; the exploration should price WHERE findings surface (live gutter markers vs an on-demand panel vs save-time gate) and settle the sovereignty question of advisory-vs-blocking, not whether the rules are worth having.

Revision after spike 1 (2026-07-29) — recommendation stands at GO, but the SHAPE changed.

The exploration ran one of four spikes before the inception commit gate required convergence
(2 exploration commits, no decision). IW-5 was sequenced first precisely because it could kill
the idea; it did not, but it moved a prerequisite into the critical path that the filing-time
recommendation above did not know about.

The filing-time rationale says the rules "carry ~12 semantic rules across both a YAML Validator
and an XmlValidator" and that "what is missing is reach". Counted rather than inferred, that is
too generous: only 7 rule ids are shared between the two classes, and `W-GW-AMBIGUOUS` —
exclusive gateway with more than one unconditioned outgoing edge — exists on the YAML path
only. Confirmed empirically: stripping every `conditionExpression` out of a corpus BPMN map
fires nothing (exit 0). The designer speaks BPMN. So surfacing "the validator" in the editor
today would surface the weaker rule set, and would specifically NOT answer the gateway question
that prompted this inception.

That makes rule parity a prerequisite of the first slice, not a follow-up. It also makes the
first slice smaller and more certain than the filing-time framing implied: port/expose the XML
rule set, close the `W-GW-AMBIGUOUS` gap, and surface the result — with `W-XML-NODE-UNASSIGNED`
as the lead-value rule, because it is the one with a live operator defect behind it.

Evidence:

- Baseline: 24 rendered BPMN + 25 YAML + 63 editor snapshots = 112 maps, 0 findings, both paths.
- Falsifiability control: drop a `sequenceFlow` → `W-XML-DEADEND` + `W-XML-UNREACHABLE`, exit 1;
  drop a `flowNodeRef` → `W-XML-NODE-UNASSIGNED`, exit 1. The zero is a measurement (PL-061).
- Rule-parity count: 7 shared ids; `W-GW-AMBIGUOUS` YAML-only; `W-XML-NODE-UNASSIGNED` and
  `W-TYPE-LANE-MISMATCH` XML-only. `tools/validate-workflow.py:302` vs `:773` / `:957`.
- Live operator defect (`pen_inbound_classifier`, screenshot 2026-07-29): ~14 nodes below all lane
  bands. Map not reachable — absent from our corpus, our gallery (`/api/list`, 6 maps) and AEF's
  (11 maps) — so this is read off the screenshot, NOT validated.
- Full trail: `docs/reports/T-309-validator-surfacing.md`.

Unpriced — carried into the build task's design phase if this goes GO:

- IW-2 (delivery route: port-to-JS vs sidecar-HTTP vs shared spec; `file://` survival) — not run.
- IW-1 / IW-3 (where findings surface; advisory vs blocking) — not run.
- IW-4 (the XOR-identical-targets rule) — not run. Note it is now a second missing rule
  alongside `W-GW-AMBIGUOUS`, not the only one.

Confidence: high that the feature is worth building and will not be noisy; low on cost,
because the delivery route is the expensive unknown and it is exactly what has not been priced.
A NO-GO here is entirely defensible on "not yet priced" grounds — the honest read is that spike 1
established the value and left the cost open.

**Date**: 2026-07-29T22:41:32Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-29T20:10:39Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-29T22:41:32Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale:

The rules already exist and are already trusted — tools/validate-workflow.py carries ~12 semantic rules across both a YAML Validator and an XmlValidator (E-GW-OUTGOING, W-GW-AMBIGUOUS, W-PGW-CONDITION/NOOP/UNBALANCED, W-UNREACHABLE, W-DEADEND, constituents, required-inputs) and its own suite is green at 34 passed, 0 failed. What is missing is reach: a grep of src/aef-workflow-designer.html finds no validation surface at all, so the checks run only in the bridge suite and from the CLI and never reach the person drawing the map, which is where the mistake is actually made. Operator evidence arrived this session as four screenshots of AEF-authored maps; the modelling smell in one of them (an exclusiveGateway fanning six labelled branches into a single shared target) is real but slips through today because no rule covers XOR-with-identical-targets. This is plumbing an existing, tested capability to an existing UI rather than new intelligence, so the cost is bounded; the exploration should price WHERE findings surface (live gutter markers vs an on-demand panel vs save-time gate) and settle the sovereignty question of advisory-vs-blocking, not whether the rules are worth having.

Revision after spike 1 (2026-07-29) — recommendation stands at GO, but the SHAPE changed.

The exploration ran one of four spikes before the inception commit gate required convergence
(2 exploration commits, no decision). IW-5 was sequenced first precisely because it could kill
the idea; it did not, but it moved a prerequisite into the critical path that the filing-time
recommendation above did not know about.

The filing-time rationale says the rules "carry ~12 semantic rules across both a YAML Validator
and an XmlValidator" and that "what is missing is reach". Counted rather than inferred, that is
too generous: only 7 rule ids are shared between the two classes, and `W-GW-AMBIGUOUS` —
exclusive gateway with more than one unconditioned outgoing edge — exists on the YAML path
only. Confirmed empirically: stripping every `conditionExpression` out of a corpus BPMN map
fires nothing (exit 0). The designer speaks BPMN. So surfacing "the validator" in the editor
today would surface the weaker rule set, and would specifically NOT answer the gateway question
that prompted this inception.

That makes rule parity a prerequisite of the first slice, not a follow-up. It also makes the
first slice smaller and more certain than the filing-time framing implied: port/expose the XML
rule set, close the `W-GW-AMBIGUOUS` gap, and surface the result — with `W-XML-NODE-UNASSIGNED`
as the lead-value rule, because it is the one with a live operator defect behind it.

Evidence:

- Baseline: 24 rendered BPMN + 25 YAML + 63 editor snapshots = 112 maps, 0 findings, both paths.
- Falsifiability control: drop a `sequenceFlow` → `W-XML-DEADEND` + `W-XML-UNREACHABLE`, exit 1;
  drop a `flowNodeRef` → `W-XML-NODE-UNASSIGNED`, exit 1. The zero is a measurement (PL-061).
- Rule-parity count: 7 shared ids; `W-GW-AMBIGUOUS` YAML-only; `W-XML-NODE-UNASSIGNED` and
  `W-TYPE-LANE-MISMATCH` XML-only. `tools/validate-workflow.py:302` vs `:773` / `:957`.
- Live operator defect (`pen_inbound_classifier`, screenshot 2026-07-29): ~14 nodes below all lane
  bands. Map not reachable — absent from our corpus, our gallery (`/api/list`, 6 maps) and AEF's
  (11 maps) — so this is read off the screenshot, NOT validated.
- Full trail: `docs/reports/T-309-validator-surfacing.md`.

Unpriced — carried into the build task's design phase if this goes GO:

- IW-2 (delivery route: port-to-JS vs sidecar-HTTP vs shared spec; `file://` survival) — not run.
- IW-1 / IW-3 (where findings surface; advisory vs blocking) — not run.
- IW-4 (the XOR-identical-targets rule) — not run. Note it is now a second missing rule
  alongside `W-GW-AMBIGUOUS`, not the only one.

Confidence: high that the feature is worth building and will not be noisy; low on cost,
because the delivery route is the expensive unknown and it is exactly what has not been priced.
A NO-GO here is entirely defensible on "not yet priced" grounds — the honest read is that spike 1
established the value and left the cost open.
