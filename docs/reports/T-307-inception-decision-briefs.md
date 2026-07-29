# T-307 — Decision briefs for the open inception tasks

**For:** Dimitri (operator) · **Prepared:** 2026-07-29 · **Supersedes:** the "Inception decisions (10)" section of `docs/reports/T-302-reviewer-sweep.md`

This document replaces a defective handoff. The T-302 report offered ten commands shaped
`fw inception decide T-XXX go --rationale "<why>"` — a placeholder rationale in a permanent
sovereignty record, with `go` pre-filled as the default verb, and no evidence presented before the
decision was requested. All three are wrong (CLAUDE.md §Inception Discipline step 2; T-609/T-325 on
copy-pasteable commands without placeholders). What follows is the evidence, so you can decide.

---

## Read this first — four facts that change the shape of the ask

**1. It is nine decisions, not ten.** T-155 (tree grouping) already has a DEFER recorded in its
`## Decision` section from 2026-07-29. It does not need a decision; it needs closing. See §11.

**2. Every one of the nine carries an agent recommendation of DEFER. Not one is a GO candidate.**
So the question in front of you is not "build or don't build, nine times." It is: *do you ratify
nine 'not now' calls, or do you disagree with any of them?* If you agree with all nine, this is nine
ratifications. I have flagged the two I think deserve the most scrutiny (T-184 and T-279).

**3. The CLI command is not the sanctioned route — Watchtower is.** `fw inception decide` refuses to
run inside an agent session by design (T-679/T-1259); the canonical flow is `fw task review T-XXX`
→ the Watchtower `/inception/T-XXX` page → record the decision there. A human pasting the CLI form
inside an agent session must add `--i-am-human`. Both routes are given below. My earlier bare CLI
suggestion was off-protocol as well as placeholder-ridden.

**4. None of the nine has `revisit_at` or `revisit_evidence_needed` set — so a DEFER ratified today
would rot invisibly.** The G-053 daily scan (`agents/context/revisit-due-scan.sh`) surfaces deferred
tasks only when frontmatter carries a real `revisit_at: YYYY-MM-DD`. Every recommendation below
names a revive trigger in prose, but prose is not scanned. **A defer without a revisit trigger is
not a decision to wait — it is a decision to forget.** Each brief therefore proposes both fields.
There is no CLI flag for these; they are frontmatter edits I can apply once you decide.

---

## How to act on each brief

Canonical (recommended) — opens the Watchtower page with recommendation, assumptions and artifacts:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-184
```

CLI fallback — three complete commands per task below, one per verb, each with a rationale drafted
from that task's own findings. **They are drafts, not defaults.** Edit any of them; the rationale is
your record, not mine. Add `--i-am-human` only if pasting inside an agent session.

---

## 1. T-184 — Child-3: Reverse discovery (AEF record → editable process map)

**The question:** Is AEF's own process record (tasks, fabric, decisions, episodic) structured enough
to deterministically reconstruct a child-1-conformant BPMN map — lanes as owners, subProcess as arc,
gateway as decision?

**Evidence state:** Nothing explored. Status `captured`, 0 of 3 agent ACs checked, file untouched
since it was filed on 2026-07-11 (18 days). All findings come from the parent decomposition
`docs/reports/T-175-child-decomposition.md`, not from this task.

**What the parent decomposition established:**
- The identity hinge is already solved — the editor consumes arbitrary `aef:uid` unchanged
  (verified), so a reverse render needs **zero editor change** for identity.
- The expensive part is a record→BPMN renderer plus auto-layout, and that is **AEF-side** (AEF owns
  the record); only the BPMN-emission spec is ours.
- Readiness graded LOW-MEDIUM. Ranked 3rd of 5 children, in the "DEFER 3-5" group.
- Value is complementary, not blocking — the forward path (child-2) was always the value path.

**Why this one deserves scrutiny:** its revisit trigger was "after child-1 and child-2 land." Both
landed on 2026-07-11 (T-182, T-183, both work-completed). **Half the trigger has already fired.**
The unfired half is demand: nothing in the record shows anyone actually wanting to edit an existing
task graph as a map. So this is a defer on demand grounds, not readiness grounds — and it is the one
most likely to be wrong if you have a use for reverse rendering in mind that I cannot see.

**My recommendation:** DEFER — but consciously, not by default.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-184 defer --rationale "Dependency half of the revisit trigger is met — child-1 (T-182) and child-2 (T-183) both completed 2026-07-11 — but the demand half has no evidence: nothing has asked to edit an existing AEF task graph as a map. Deferring costs little structurally because the identity hinge is already solved (editor passes aef:uid through unchanged, verified); the unbuilt part is the record-to-BPMN renderer plus auto-layout, which is AEF-side work we cannot start unilaterally. Revisit on a concrete reverse-render request."

# GO — authorizes a further exploration of the reverse renderer, not a build
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-184 go --rationale "Child-1 and child-2 have landed, so the dependency trigger has fired and the identity hinge is proven (aef:uid passes through the editor unchanged). Exploring the record-to-BPMN renderer now, jointly with AEF who owns the record side, gets the reverse direction moving while the forward contract is fresh rather than waiting for demand to appear."

# NO-GO — retires reverse discovery from the arc
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-184 no-go --rationale "Reverse discovery is complementary, not on the value path: the forward direction (diagram to governed work) is what the arc exists for. The renderer and auto-layout are AEF-side and unbuilt, and no demand to edit existing task graphs as maps has materialised in 18 days. Retire it from the arc rather than carry an indefinite placeholder."
```

**If DEFER:** `revisit_at: 2026-10-01` · `revisit_evidence_needed: "A concrete request (ours or AEF's) to render an existing AEF task record as an editable map"`

---

## 2. T-185 — Child-4: Collaboration and concurrency (per-element claim/lease)

**The question:** Can termlink's agent-side claim primitive be bridged to the browser as a
server-mediated per-node/lane/subProcess lease with TTL, without adopting a heavyweight realtime
collaboration stack (OT/CRDT)?

**Evidence state:** Nothing explored. Same signature as T-184 — `captured`, 0 of 3 agent ACs, file
untouched since 2026-07-11.

**What the parent decomposition established:**
- The browser↔termlink lease bridge is **unproven** — that is the named blocker.
- Readiness graded LOW; explicitly "the most architecturally-open child" of the five.
- Ownership is split: AEF would host the lease service, 832 only adds lease-aware UI. **832 cannot
  resolve this alone**, so a spike here would be half-blind.
- Demand is currently zero — single-author authoring works today.
- OT/CRDT is fenced out unless proven necessary.

**My recommendation:** DEFER. This is the strongest defer of the nine: no demand, unproven bridge,
and the substrate belongs to the other project.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-185 defer --rationale "Single-author authoring works today and concurrent multi-party editing has never occurred, so there is no demand to serve. The load-bearing question — whether termlink's claim primitive can be bridged to the browser as a TTL lease — is unproven, and the lease service would be AEF-hosted, so a 832-side spike would be half-blind. Graded LOW readiness and the most architecturally-open of the five children in the T-175 decomposition. Revisit when concurrent editing becomes a real workflow."

# GO — authorizes a feasibility spike on the lease bridge, not a build
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-185 go --rationale "This is the architecturally-openest child and the one most likely to invalidate assumptions late. A bounded feasibility spike on the browser-to-termlink lease bridge, run jointly with AEF who would host the lease service, de-risks it now rather than when concurrent editing is already needed and the answer is urgent."

# NO-GO — retires per-element leasing from the arc
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-185 no-go --rationale "Concurrent multi-party map editing is not a workflow this project has or expects; single-author authoring plus version history covers the real use. The lease bridge is unproven, the service would be AEF-hosted, and OT/CRDT is already fenced out. Retire rather than carry an indefinite placeholder for a demand that has never appeared."
```

**If DEFER:** `revisit_at: 2027-01-15` · `revisit_evidence_needed: "Two parties needing to edit one map concurrently — e.g. a collaborative inception session that single-author editing blocks"`

---

## 3. T-186 — Child-5: Hosting and tenancy (tenant-neutral, multi-tenant)

**The question:** How should the designer be hosted so it is tenant-neutral and can serve multiple
tenants?

**Evidence state:** Nothing at all. Every substantive section is empty template boilerplate — no
problem statement, no assumptions, no open questions, no exploration plan. Status `captured`,
0 of 3 agent ACs, untouched since 2026-07-11. Its own recommendation block says as much: "no
artifacts produced under this task ID."

**Honest framing:** a DEFER here does not mean "explored and decided not to build." It means "not
exploring this now." There is no finding to weigh, because no exploration ran. Deployment today is a
single-tenant local serve and no second tenant is in sight.

**My recommendation:** DEFER — with the caveat that this is the emptiest of the nine, so if
multi-tenancy matters to you on any horizon, that intent exists only in your head, not in the record.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-186 defer --rationale "No exploration has run — the task file is an unfilled template (0/3 agent ACs, untouched since filing 2026-07-11), so there is nothing to weigh. Deployment today is single-tenant local serve and no second tenant exists or is planned. Deferring records that we are deliberately not exploring hosting and tenancy now, rather than leaving it ambiguous."

# GO — authorizes the exploration itself
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-186 go --rationale "Hosting and tenancy shape decisions that are expensive to reverse once maps and stores accumulate under single-tenant assumptions. Running the exploration now — while the corpus is 24 maps and the store layout is still cheap to change — is worth the time even though no second tenant exists yet."

# NO-GO — retires multi-tenancy from the arc
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-186 no-go --rationale "This designer serves one operator and one project; multi-tenancy solves a problem we do not have and would not adopt. Retire the child so the arc's remaining scope is honest, and re-file fresh if the deployment picture ever changes."
```

**If DEFER:** `revisit_at: 2027-01-15` · `revisit_evidence_needed: "A second tenant or a non-local deployment requirement"`

---

## 4. T-244 — Bare catch-event rendering: neutral glyph instead of dead link-catch UI

**The question:** Should a bare `intermediateCatchEvent` (no `aef:link`, no `aef:eventDef`) render as
the link-catch UI with an empty, never-bindable target, or as a neutral untyped glyph?

**Evidence state:** Thin but real. No exploration plan or assumptions were filled in, but the
recommendation is grounded in actual cross-project dialogue (AEF rail offsets 174 and 176). Blast
radius 3 (small), VOI 0.5.

**Findings:**
- Real symptom: the empty link-catch UI was misread by AEF's operator as a broken connector.
- Preliminary lean, explicitly unratified: render a neutral untyped glyph.
- **Zero live exposure** — AEF fixed their corpus side (typed the event, added the missing handoff),
  so no map in either corpus now contains a bare `intermediateCatchEvent`.
- A commitment exists to notify the AEF rail if the rendering changes.

**The tension worth naming:** this one *satisfies both written GO criteria* — root cause identified,
fix bounded, testable and reversible. It is deferred purely because the triggering case was
eliminated upstream, so the fix would serve nobody today. That is a legitimate reason, but it is a
different reason than the criteria measure. If you would rather fix a known-confusing rendering
while it is cheap and understood, GO is defensible here.

*(Note: this task's automated Recommendation Verdict shows CONTRADICTED because it cites AEF's
T-2613, which does not resolve in our task tree. That is a cross-project false positive — their ID,
not ours — not a real defect. T-280 has the same artifact.)*

**My recommendation:** DEFER, weakly.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-244 defer --rationale "The fix is bounded, testable and reversible (blast radius 3) and would satisfy both GO criteria on paper, but live exposure is now zero: AEF fixed the triggering case upstream by typing the event, and no map in either corpus contains a bare intermediateCatchEvent. Deferring costs nothing and the analysis is preserved. Revisit if a bare catch event reappears in authoring or in a corpus import."

# GO — fix the rendering now while it is cheap and understood
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-244 go --rationale "Root cause is identified with a bounded, testable, reversible fix path and a small blast radius — this meets the stated GO criteria. The empty link-catch UI actively misled an operator into reading a healthy map as broken; fixing the rendering now, while the analysis is fresh, prevents the next reader making the same misread, and the AEF rail gets notified per the standing commitment."

# NO-GO — keep current rendering
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-244 no-go --rationale "The case that produced the confusing rendering was eliminated upstream and bare untyped catch events are not part of how maps are authored. Changing glyph rendering for a state that should not occur adds a rendering branch to maintain for no live benefit. Keep current behaviour and treat a recurrence as a corpus defect rather than a rendering defect."
```

**If DEFER:** `revisit_at: 2026-11-01` · `revisit_evidence_needed: "A bare intermediateCatchEvent appearing in an authored or imported map"`

---

## 5. T-277 — Ratify process-level conformance key and stateKind carrier (AEF T-2652)

**The question:** Should 832 ratify two additive schema keys — `conformance=` on `aef:workflowMeta`
and `stateKind=` on node `aef:meta` — so AEF's map-conformance work can declare in-map?

**Evidence state:** The best-evidenced of the nine. Full problem statement with source line
references, a research artifact (`docs/reports/T-277-conformance-statekind-ratification.md`), rail
dialogue, and a documented external resolution.

**Findings:**
- Technical facts already established and answered on-rail: `aef:workflowMeta` import reads a fixed
  8-key allowlist (src:9263) and export re-synthesizes from known keys (src:9111), so an unratified
  attribute **silently drops on the first editor save**. Node `aef:meta` ingests all attributes
  verbatim (src:9341) but exports from a 17-key allowlist (src:8979) — `state=` round-trips, a new
  `stateKind=` would drop.
- **The external question resolved itself.** AEF's T-2652 went GO *registry-operative* (rail 272);
  their T-2654 shipped `tools/conformance-registry.yaml` with primitive dispatch. AEF stated
  explicitly: *"keep T-277 PARKED — current direction needs zero 832-side work."*
- If it ever revives, the path is known and cheap: one additive key into both allowlists, following
  the `kind=` (T-213), `uuid` (T-224), `pageWidth` (T-255) precedent — absent means not emitted, so
  untouched maps still export byte-identically.

**My recommendation:** DEFER. This is the cleanest defer of the nine — the counterparty explicitly
asked for it, and there is nothing to build.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-277 defer --rationale "AEF's T-2652 went GO registry-operative (rail 272, their T-2654 shipped conformance-registry.yaml with primitive dispatch) and they explicitly asked to keep T-277 parked because the chosen direction needs zero 832-side change. The 832 technical facts are already answered on-rail: workflowMeta drops unratified attributes on the first editor save (8-key allowlist), node meta exports from a 17-key allowlist. Ratifying keys nobody will emit would add schema surface for nothing. Revisit only if AEF pings the T-2652 thread with a GO for in-map declaration."

# GO — ratify both keys now, ahead of need
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-277 go --rationale "Both keys are additive and follow a proven precedent (kind= T-213, uuid T-224, pageWidth T-255): one key into the import and export allowlists, absent means not emitted, so untouched maps export byte-identically. Ratifying now means AEF's slice 5 is unblocked the moment they want it, instead of waiting on a round trip through our decision process."

# NO-GO — decline in-map declaration as a direction
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-277 no-go --rationale "Conformance and state-carrier semantics belong in AEF's registry, which is where their T-2654 put them and where they operate without touching our schema. Declaring them in-map duplicates the source of truth inside the document and grows the round-trip allowlist surface we have to keep byte-stable. Decline the direction rather than leave it open."
```

**If DEFER:** `revisit_at: 2026-12-01` · `revisit_evidence_needed: "AEF pings the T-2652 thread with a GO for in-map declaration (their slice 5)"`

---

## 6. T-279 — Guided-mode procedural guardrail (package P3, Locks 3+6): revive or retire

**The question:** Should the shelved enforcement-ladder feature (advisory/guided/strict modes,
`fw workflow bind/advance`, caged instance state, humanTouchpoint, workflow-scoped tier envelopes)
be revived, or formally retired?

**Evidence state:** Verification done, exploration not. It was confirmed absent on both sides — no
`lib/workflow.sh` and no `workflow` verb family in AEF v1.6.763 — and it has never been raised on
the rail.

**Findings:**
- The enforcement half of packages P3/P4 was never built by either project.
- The surface is mostly AEF-side, so 832 cannot revive it unilaterally.
- **The underlying P4 diagnosis is still unanswered:** prose processes get stochastically
  re-interpreted, and fixes never lock in. That is a real problem, not a hypothetical one.

**Why this one deserves scrutiny:** its revive trigger is *"when the operator wants it raised with
AEF"* — pure operator will, with no external event that can fire it. That makes it the defer most
likely to become permanent silence by default rather than by decision. The diagnosis it addresses is
arguably live in this very project. If you think the problem is real, "defer" needs a date on it, or
it needs raising with AEF now.

**My recommendation:** DEFER, with a dated revisit — or GO to the extent of *raising it with AEF*,
which costs one rail message.

```
# DEFER (recommended, with a dated revisit)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-279 defer --rationale "The P3/P4 enforcement half was never built on either side — verified absent from AEF v1.6.763 (no lib/workflow.sh, no workflow verb family) — and has never come up on the rail. The surface is mostly AEF-side, so 832 cannot revive it alone. The underlying P4 diagnosis, that prose processes get stochastically re-interpreted and fixes never lock in, remains real and unanswered: this parks the question, it does not dismiss it. Revisit on a dated checkpoint rather than waiting for it to resurface on its own."

# GO — raise it with AEF and decide revive-vs-retire jointly
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-279 go --rationale "The P4 diagnosis it addresses — prose processes stochastically re-interpreted, fixes never locking in — is live in our own practice, not hypothetical. Since the enforcement surface is mostly AEF-side, the bounded next step is raising it on the rail and deciding revive-versus-retire jointly, which costs one message and converts an indefinite park into an actual answer."

# NO-GO — retire the enforcement ladder
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-279 no-go --rationale "Neither project built the enforcement half in the time since it was specified, and neither has missed it on the rail. The governance we actually rely on — task gates, P-010/P-011, tier enforcement — addresses the same failure mode without a workflow-instance state machine. Retire the package so it stops presenting as pending scope."
```

**If DEFER:** `revisit_at: 2026-09-15` · `revisit_evidence_needed: "Operator decision to raise the enforcement ladder with AEF, or a third instance of a prose process being re-interpreted and a fix not locking in"`

---

## 7. T-280 — Workflow Fabric (SD-15): process-dependency graph

**The question:** Should we build a queryable process graph (flow / call / handoff / component /
path / inferred-dataflow edges) supporting role-level workload queries and process blast-radius?

**Evidence state:** Scoped, not explored. The package definition is known (INSTRUCTIONS §2.6), and
the current state of both sides was checked.

**Findings:**
- Nothing exists on either side. AEF's conformance registry (their T-2654) covers only a narrow
  conformance slice, not a dependency graph.
- The surface is AEF-side — it is the peer of their Component Fabric.
- 832's exposure is limited to addressing and uid conventions **already frozen in mapping-v1**, so
  deferring creates no drift risk on our side.

*(This task's automated verdict also shows CONTRADICTED for citing AEF's T-2654 — same cross-project
false positive as T-244.)*

**My recommendation:** DEFER.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-280 defer --rationale "Nothing exists on either side and the surface is AEF-side — the peer of their Component Fabric — while AEF's shipped conformance registry covers only a narrow conformance slice, not a dependency graph. 832's exposure is addressing and uid conventions already frozen in mapping-v1, so deferring creates no drift risk here. Revisit when a real cross-process query arises that nobody can answer."

# GO — explore the process-dependency graph now
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-280 go --rationale "The corpus is now 24 maps with handoff edges between them, which is exactly the scale where cross-process questions — what breaks if this process changes, who carries which workload — stop being answerable by reading. Exploring the graph while the addressing conventions are frozen and fresh is cheaper than reconstructing intent later."

# NO-GO — retire the Workflow Fabric package
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-280 no-go --rationale "The queryable process graph is AEF-side scope that AEF has not pursued, and the cross-process questions it would answer have not been asked in practice. Our addressing and uid conventions are frozen in mapping-v1 and would support such a graph later if anyone builds one. Retire the package rather than carry it as indefinite shared scope."
```

**If DEFER:** `revisit_at: 2026-12-01` · `revisit_evidence_needed: "A real cross-process query nobody can answer — e.g. which processes break if this one changes"`

---

## 8. T-281 — Audience render lenses (SD-14 / §2.2)

**The question:** Should the designer render audience-filtered views — business, logical, technical,
plus a one-way derived pseudocode lens?

**Evidence state:** Scoped, not explored.

**Findings:**
- No counterpart exists: the designer has view controls (density, label visibility) but no
  audience-filtered rendering.
- The V2/V8 business-legibility criteria this would serve were **never formally tested**.
- This is a **pure 832-side surface** — unlike most of the others, we could do it unilaterally.
- The 24-map corpus would be the natural test bed.
- What is missing is a consumer: no business stakeholder is currently asking for a filtered view.

**My recommendation:** DEFER. Buildable, but building a view for an audience that does not exist
means guessing at what that audience needs.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-281 defer --rationale "This is a pure 832-side surface we could build unilaterally, but there is no consumer: no business stakeholder is asking for a filtered view, and the V2/V8 business-legibility criteria it would serve were never formally tested. Designing lenses for an audience that does not exist means guessing at what they need. The 24-map corpus is the natural test bed once a real reader appears."

# GO — build the lenses now
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-281 go --rationale "Audience legibility is the point of a visual authoring surface, and this is one of the few remaining packages we own end to end with no cross-project dependency. The 24-map corpus gives an immediate test bed, and the business-legibility criteria that were never formally tested become testable the moment the lenses exist."

# NO-GO — retire audience lenses
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-281 no-go --rationale "The designer's readership is the operator and the agents, both of whom want the full technical view; the existing density and label controls already cover legibility for that audience. Maintaining four render lenses against an evolving dialect is ongoing cost for a stakeholder group that does not exist. Retire rather than carry indefinitely."
```

**If DEFER:** `revisit_at: 2027-01-15` · `revisit_evidence_needed: "A non-technical reader who needs to read a map and cannot"`

---

## 9. T-282 — callActivity node type (SD-9): sync sub-workflow call with ioMapping

**The question:** Should the dialect gain `callActivity` — a synchronous call-with-return node with
explicit ioMapping?

**Evidence state:** Well-scoped, not explored. The semantic distinction is clearly established.

**Findings:**
- `callActivity` is genuinely distinct from what exists: link events are asynchronous with no
  return; the shipped collapsed subProcess (T-081) is **containment, not invocation**.
- It is in neither the editor nor mapping-v1.
- Adding it means schema plus mapping-standard ratification (the additive `kind=`/`uuid`/`pageWidth`
  pattern) **plus** resolution and acyclicity validator rules — the validator work is the real cost.
- No corpus map and no AEF compile case currently needs call-with-return semantics that link events
  cannot express.

**My recommendation:** DEFER.

```
# DEFER (recommended)
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-282 defer --rationale "callActivity is a real gap in the dialect — synchronous call-with-return with explicit ioMapping, genuinely distinct from link events (async, no return) and from the shipped collapsed subProcess (T-081, containment not invocation) — but nothing needs it yet: no corpus map and no AEF compile case requires call-with-return semantics that link events cannot express. The cost is schema plus mapping-standard ratification plus resolution and acyclicity validator rules. Revisit when a real map needs the semantics."

# GO — add callActivity to the dialect now
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-282 go --rationale "The dialect currently forces authors to express sub-workflow invocation as async link events, which loses the call-and-return semantics and the ioMapping contract. Adding callActivity while the additive-key ratification pattern is proven (kind=, uuid, pageWidth) and the validator is actively maintained is cheaper than retrofitting it after maps have encoded workarounds."

# NO-GO — keep the dialect without callActivity
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-282 no-go --rationale "Link events plus the collapsed subProcess have expressed every corpus map and every AEF compile case so far. callActivity would add a node type, two allowlist keys, and resolution plus acyclicity validator rules to maintain for semantics nothing has needed. Keep the dialect minimal and re-file if a concrete map cannot be expressed without it."
```

**If DEFER:** `revisit_at: 2026-12-01` · `revisit_evidence_needed: "A corpus map or AEF compile case needing call-with-return semantics that link events cannot express"`

---

## 10. Not a decision — T-155 needs closing

T-155 (hierarchical tree grouping for the Open-project map browser) **already has a DEFER recorded**
in its `## Decision` section, dated 2026-07-29, pending your input on two questions the agent cannot
settle by research: which grouping key (IW-1) and tree-versus-sections (IW-2). The full design
survey is in `docs/reports/T-155-tree-grouping-inception.md`; the recommended shape was
derive-only grouping by source class with collapsible sections over the existing grid — no schema
change, no server change.

It does not need a decision command. It needs either closing, or your answers to IW-1/IW-2 if you
want it to move. It also has no `revisit_at`, so it has the same rot problem as the nine.

---

## Summary table

| Task | What it is | Agent rec | Confidence | Note |
|---|---|---|---|---|
| T-184 | Reverse discovery (record → map) | DEFER | Medium | Dependency trigger already fired; demand half has not |
| T-185 | Per-element claim/lease | DEFER | High | No demand, unproven bridge, AEF-hosted substrate |
| T-186 | Hosting and tenancy | DEFER | High | Zero exploration — "not exploring now", not "explored" |
| T-244 | Bare catch-event glyph | DEFER | Low | Meets both GO criteria; deferred only for zero live exposure |
| T-277 | conformance= / stateKind= ratification | DEFER | Very high | AEF explicitly asked to keep it parked |
| T-279 | Guided-mode guardrail | DEFER | Medium | Trigger is operator-will only; risks permanent silence |
| T-280 | Workflow Fabric (process graph) | DEFER | High | AEF-side surface, nothing exists either side |
| T-281 | Audience render lenses | DEFER | High | Ours to build, but no consumer exists |
| T-282 | callActivity node type | DEFER | High | Real dialect gap, no current need |

**If you ratify all nine as DEFER,** tell me and I will apply the `revisit_at` /
`revisit_evidence_needed` frontmatter from each brief, so the G-053 daily scan can surface them when
they ripen instead of them sitting at `horizon: later` forever. The decisions themselves stay yours
to record — via `fw task review T-XXX` and the Watchtower page, or the CLI forms above.
