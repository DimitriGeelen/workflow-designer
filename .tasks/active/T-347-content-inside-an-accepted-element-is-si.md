---
id: T-347
name: "Content inside an ACCEPTED element is silently dropped on import: documentation,
  foreign extensionElements children, property, loop characteristics and unknown attributes"
description: >
  parseBpmnXml reaches into each allowlisted element for ~10 named children and 2
  attributes; anything else in that element is never read, and export writes only
  from state. Measured over 24 corpus maps (T-346): 5 non-derivable content shapes
  dropped 15/15 applied maps each — bpmn:documentation, a foreign child inside extensionElements
  (the T-259 shape), bpmn:property, multiInstanceLoopCharacteristics, and an unknown
  namespaced attribute. conditionExpression is preserved (positive control), and incoming/outgoing
  are dropped correctly since they are derivable. Node/flow/lane counts are unchanged
  throughout, which is why every existing instrument is green.

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:34:19Z
last_update: '2026-08-16T14:33:02Z'
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
  - ts: '2026-08-16T12:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:02Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-347-accepted-element-content.md,docs/reports/T-397-import-repair-semantics-brief.md,tests/run-bridge-tests.sh,tools/_t338-input-fidelity-cdp.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-347: Content inside an ACCEPTED element is silently dropped on import: documentation, foreign extensionElements children, property, loop characteristics and unknown attributes

## Context

> ### 2026-08-03 — T-356 did NOT make this task capable of failing, and the halo is the risk
>
> T-356 added five provably third-party fixtures and 5 of 5 lose content, which made
> **T-340** (DI), **T-348** (two-pool, first-only roots) and **T-358** (fabrication)
> witnessable on real documents for the first time. It is tempting — and it would be
> wrong — to read that as "the import-loss class now has a real population".
>
> Censused against **this** task's five shapes:
>
> | shape | occurrences across all 5 third-party fixtures |
> |---|---|
> | `documentation` | **0** |
> | foreign `extensionElements` children | **0** |
> | `property` | **0** |
> | `*LoopCharacteristics` | **0** |
> | unknown namespaced attributes | present (`exporter=`, dropped 5/5) |
>
> **Four of the five shapes are exactly as unreachable as they were before T-356.**
> Only the attribute class is exercised, and only incidentally — by the very
> attribute T-356 uses to prove foreignness.
>
> **Capability is per-QUESTION, not per-POPULATION.** T-356's headline ("this
> repository has never been tested against a third-party document") was true and is
> now false; but "the corpus can exhibit real-world import defects" is true of some
> questions here and false of others, and the sentence does not distinguish. A
> remedy that genuinely fixes a capability zero casts a halo over every neighbouring
> question, and the halo is *produced by the fix* — the same
> measurement-promoted-past-its-scope shape, one level up.
>
> **Consequence for this task:** its verdicts remain synthetic-only. Do not cite the
> existence of `tests/fixtures/third-party/` as evidence that T-347 has real-world
> coverage. Closing it needs fixtures that actually carry documentation, foreign
> extension children, `property` and loop characteristics — a *different* fixture
> hunt, not a re-use of this one.

Found by T-346. `parseBpmnXml` reaches into each allowlisted element for the specific
children and attributes it knows about — `aef:uid`, `aef:position`, `aef:meta`,
`aef:endpoint`, `aef:contextReads`, `aef:artifactsWrites`, `aef:decisionInput`,
`aef:decisionOutputs`, `aef:link`, `aef:eventDef`, plus `id` and `name`. Anything else
inside that element is not rejected; it is never read. Export writes only from `state`,
so it is gone on the next save.

Same mechanism as T-337, one level further in: T-337 is an unknown **tag**, T-340 an
unknown **branch**, this is unknown **content inside a tag we accept**.

Measured over the 24 rendered corpus maps (`tools/_t338-input-fidelity-cdp.mjs`, leg 6):

| shape | verdict | applied |
|---|---|---|
| `bpmn:documentation` | **CONTENT-DROPPED** | 15/24 |
| foreign child in `bpmn:extensionElements` | **CONTENT-DROPPED** | 15/24 |
| `bpmn:property` | **CONTENT-DROPPED** | 15/24 |
| `bpmn:multiInstanceLoopCharacteristics` | **CONTENT-DROPPED** | 15/24 |
| unknown namespaced attribute | **CONTENT-DROPPED** | 15/24 |
| `bpmn:incoming` | CONTENT-DROPPED *(derivable — correct)* | 15/24 |
| `bpmn:conditionExpression` | CONTENT-PRESERVED *(positive control)* | 24/24 |

The last two rows are why the result means something. `conditionExpression` is read
(`src:9855`) and re-emitted (`src:9540`), so it comes back — the probe therefore
discriminates rather than reporting that everything injected disappears. `incoming` is
derivable from the sequenceFlows, so dropping it is correct and it is flagged benign.

**Why nothing caught this.** Node, flow and lane counts are identical before and after —
an element that survives with its body stripped keeps all three. The corpus-loss leg,
the byte-identity instrument and the validator all stay green. Same shape as T-341:
green because the measure was about the wrong property.

**This class already shipped once.** T-259 was exactly this defect for one child element
(`<aef:eventDef>` destroyed by a layout-only open→save — the rail-201 field defect). That
fix resolved one child and nobody asked which others were in the same position. Six were.

**Severity.** Occupancy is not zero the way T-337's and T-340's are: `documentation` is
the standard BPMN element for human-authored prose about a step, and a foreign
`extensionElements` child is how every other BPMN tool stores its own data. Any file
arriving from a third-party modeller carries both. Within our own corpus the shapes are
absent, so nothing is being lost today — but the exposure is on the import path from
peers, which is the T-559 seam.

> **CORRECTION 2026-08-03 — the sentence above that reads "Any file arriving from a
> third-party modeller carries both" is now MEASURED FALSE.** Five real third-party
> files, from Camunda Modeler and bpmn-js: **0 carry `documentation`, 0 carry a
> foreign `extensionElements` child.** The claim was reasoned from what such tools
> *can* store, not from what they *do* emit — the same move that produced the
> unreachable census this arc has been unpicking all week, made in the opposite
> direction. There it undercounted a defect; here it overcounted one.
>
> **The severity conclusion survives and its justification does not.** These shapes
> are optional and author-driven: a modeller emits `documentation` when a human
> typed a note, and a foreign `extensionElements` child when a *platform* (Camunda
> execution properties, Zeebe bindings) is in play — neither is present in generic
> test diagrams. So the honest severity is **"latent but with genuinely non-zero
> occupancy in the wild, unquantified here"**, not "any file carries both". Five
> fixtures is far too small a sample to put a rate on it, and saying so is the
> point: the previous sentence put a rate of 100% on it from no sample at all.

## Addendum — T-348 folds into this decision (2026-08-02)

T-348 measured the granularity **above** this one: `bpmn:definitions`' children other than
the single process the importer reads. `parseBpmnXml` takes `processes[0]`,
`participant[0]` and `laneSets[0]` — first-only, no complement branch — so seven further
shapes are silently dropped, 24/24 across the corpus:

`second-process`, root `message`, root `signal`, root `error`, `dataStore`,
`second-participant`, `messageFlow`.

**Why it folds rather than forking.** The dangling-reference hypothesis — that dropping a
referent while keeping its reference would emit *invalid* BPMN, a worse outcome than
merely lossy BPMN — was tested and is **false**. `buildBpmnXml` emits a fixed root
skeleton and copies no references from the input, so the output is always internally
consistent. The repair question is therefore identical to this task's: **(a)
preserve-and-re-emit, (b) consume-as-typed, (c) refuse.** Answering it here answers it
there; opening a parallel decision would put the same question in front of the operator
twice.

**The one row that may not want the same answer.** `second-process` is not equivalent in
weight to the others. A two-pool collaboration opened and saved returns as a one-pool
document — an entire pool's nodes gone — while node/flow/lane counts *of the surviving
pool* are unchanged, so every count-based instrument and the validator stay green. Option
**(c) refuse** is far more defensible for that row than for a `documentation` string. If
this task is answered uniformly, `second-process` is the row most likely to make the
uniform answer wrong, and is worth an explicit sentence in the decision either way.

## Measured 2026-08-03 — this task is now CAPABLE OF FAILING, and it fails on every shape

Last session I recorded here that T-356 did **not** make this task capable of failing:
its five fixtures censused all-zero against these five shapes, and only the
unknown-attribute class was exercised — incidentally, by `exporter=` itself. That
required a **different** fixture hunt, which is now done.

**Five more fixtures** (survey of 467 `.bpmn` across three upstream repos; 288 carried
an `exporter=` signature), chosen for vendor spread the first intake lacked — Camunda
Modeler 5.16 and 4.8, **Zeebe Modeler**, **Enterprise Composer**, **Bizagi**. New
instrument `tools/_t347-accepted-element-content-cdp.mjs`. Control clean.

| shape | carriers losing it | witnesses |
|---|---|---|
| `documentation` | **2/2** | `bizagi-nested-ns`, `i18n-documentation` |
| foreign `extensionElements` children | **6/6** | all six carriers |
| spec `property` | **2/2** | `caseagile-local-ns`, `kitchen-sink` |
| loop characteristics | **2/2** | `caseagile-local-ns`, `kitchen-sink` |
| unknown (foreign-ns) attributes | **3/3** | `i18n-documentation`, `kitchen-sink`, `zeebe-service-task` |

Always to **exactly zero**, never a reduction. Report:
`docs/reports/T-347-accepted-element-content.md`.

**Severity restated a second time, and this is the version the evidence supports.**
The pre-T-356 rating was "latent", drawn from a population that could not exhibit the
defect. I then overcorrected to "any file from a third-party modeller carries both",
which I retracted last session as measured false. The measured profile is **low
incidence, total loss**: only 2 of 10 fixtures carry `documentation` and 6 of 10 carry
a foreign extension child — but *every* carrier loses *all* of it. Neither previous
wording described that.

**The near-clean verdict is the trap.** `caseagile-local-ns.bpmn` loses exactly one
thing under the structural census (`_t356`: `exporter`) and **451** under this one.
Whatever repair is chosen, note that a structure-counting suite will go green over a
document that is being gutted — which is why this needed its own instrument rather
than a widened leg on an existing one.

> **The bridge suite is RED on master because of this intake, and deliberately left so.**
> `bizagi-nested-ns.bpmn` exposed a pre-existing validator false positive: legal
> non-flow-node children of `<process>` are enumerated as flow nodes and reported as
> `E-XML-NODE-TYPE`. The id-less `<documentation>` case anchors to `'?'`, which fails the
> T-335 anchorability guard — **68 passed, 1 failed** (was 69/0).
>
> Filed as **T-359**. Not silenced, and the fixture was not withdrawn: removing the
> document that makes a defect visible is how a population loses the ability to fail,
> which is the error this whole intake exists to correct. Adding `UNRESOLVED` to the
> `ANCHOR` table would have been the same move in a different costume.
>
> **RESOLVED same session — T-359 is fixed and complete, bridge back to 69/0.** The
> exclusion set in `validate-workflow.py` held only the three non-flow-node children
> *our own emitters* produce, so it was complete for the population that wrote it and
> wrong for BPMN — the same defect shape this intake exists to correct, found one
> layer down. Teeth proven by mutation: removing a single exclusion turns the
> anchorability guard RED. The `ANCHOR` table was not touched.
>
> **T-347 itself remains blocked on the Human `[REVIEW]` above** — the repair-semantics
> choice. That is unchanged by any of today's work; what changed is that the choice is
> now made against real witnesses instead of injected probes.

## Acceptance Criteria

### Agent
- [ ] Repair semantics are recorded in `## Decisions` before any code changes — see the
      Human AC below. The three candidates are the same set T-337 faces: (a) preserve
      unconsumed content verbatim and re-emit it, (b) consume it into `state` as typed
      fields, (c) refuse the document.
- [ ] Whichever is chosen, `tools/_t338-input-fidelity-cdp.mjs` leg 6 reflects it and
      `EXPECTED_CONTENT` is updated **deliberately** — the guard fails on an improvement it
      is not told about, which is the mechanism that stops this becoming a permission list.
- [ ] The T-259 carrier (`aef:eventDef`) is covered by the same mechanism rather than
      remaining a special case — a fix that resolves one granularity without asking about
      the others is a fix, not a remedy.
- [ ] Bridge suite `0 failed` and the widened instrument green after the change.

### Human
- [ ] [REVIEW] Choose repair semantics for unconsumed element content

      > **Consolidated view: `docs/reports/T-397-import-repair-semantics-brief.md`.** One of
      > four open rulings, all four stated there in current form. Two things from it bear on
      > this one: **T-337 is completed and ruled `(a)` at the granularity directly above this
      > task** (unknown tag), which the text below anticipated but could not yet cite; and the
      > brief's **competing-carrier rule** explains why `(a)` is right here and *not* right for
      > T-340 — no rival carrier exists for element content, so preservation cannot
      > self-contradict.
      >
      > ### 2026-08-09 — AEF measured; it resolves the seam question, not this ruling (rail 487, T-403)
      >
      > Their round-trip importer **also drops loose text inside a node, silently** — our exact
      > shape. So the behaviour is a property of **the seam**, not a defect peculiar to us, and
      > our ruling here is not a defect confession. That was the question asked at rail 484.
      >
      > **It does not strengthen the case for `(a)`, and should not be read as doing so.**
      > *"Both sides do it"* is a description, not a justification — if anything it is the
      > argument for `(b)`, since preservation is only end-to-end when both ends preserve, and
      > today neither does. The case for `(a)` still rests where it rested before their reply:
      > our own T-337 precedent, and the absence of a competing carrier. Nothing was added to
      > it; one counter-argument (*"we are uniquely lossy"*) was removed.
      **Steps:**
      1. `cd /opt/832-Workflow-designer && timeout 300 node tools/_t347-accepted-element-content-cdp.mjs`
      2. Read the `PER-SHAPE VERDICT` block. Each denominator is the number of files that
         actually CARRY that shape — `n/a` files are excluded, never counted as agreement.
      3. Decide (a) preserve-and-re-emit, (b) consume-as-typed-fields, or (c) refuse.
      **Expected:** a choice recorded in `## Decisions` with its rationale.
      **If not:** leave filed. Nothing in our own corpus loses content today; the exposure
      is on files arriving from peers.

      **Evidence changed under your feet (2026-08-03) — read this before deciding.** These
      steps used to point at `_t338`'s `content:` block, which is SYNTHETIC: it splices a
      probe into a document we wrote. There are now ten real third-party fixtures and a
      dedicated instrument, and **all five shapes are lost on 100% of the files that carry
      them, always to exactly zero.** Full table: `docs/reports/T-347-accepted-element-content.md`.
      Two things there bear directly on the choice:
      - `caseagile-local-ns.bpmn` loses **one** thing under the structural census (`_t356`)
        and **451** under this one. A structure-counting instrument returns a near-clean
        verdict on a document being gutted — so "our suites are green" is not evidence here.
      - `bizagi-nested-ns.bpmn` loses its **entire task graph** (`nodes 3→0`, `flows 2→0`)
        because its namespace is declared on an inner element rather than the root.

      Note (a) matches the T-259 precedent and the ratified "diagram XML is never silently
      migrated" (`src:9656`), and is the only option that also covers content we have not
      thought of. It also changes what we emit for AEF's content, which is why this is
      yours and not mine — same disposition as T-337, T-340 and T-341.

## RCA

**Symptom:** author-supplied content inside an element the importer accepts disappears on
open→save, with every count unchanged and every existing instrument green.

**Root cause:** the importer enumerates the children and attributes it knows by name and
has no complement branch; export reconstructs the element from `state` alone, so anything
not lifted into `state` has no carrier.

**Why structurally allowed:** the identical defect was fixed at T-259 for a single child
element and the fix was not generalised. Every instrument in the tree measured either
*counts* (blind to a stripped body) or *version-vs-version* (blind to a defect both
versions share, G-016). The class sat in the intersection.

**Prevention:** leg 6 of `tools/_t338-input-fidelity-cdp.mjs`, in the gating runner, with
teeth that flip both verdict buckets by mutating the designer — so the result is not a
pair of readings in buckets nobody has shown can fill.

### Human
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

**Recommendation:** GO on **(a) preserve and re-emit** unconsumed content inside an
element we accept.

**Rationale:** It matches T-337 at the granularity directly above (unknown *tag*, ruled
`(a)` and now completed) and T-259 directly below, so ruling `(a)` here makes three
adjacent granularities consistent rather than inventing a policy. It is the only option
that also covers content nobody has thought of yet — the shapes below are the ones we
found, not the ones that exist. And **no competing carrier exists** for element content,
so preservation cannot self-contradict; that is precisely why this ruling can be `(a)`
while T-340 is `(b)`, and why "different answers" here is principled rather than
arbitrary (brief §255).

**Evidence — probe re-run today, 2026-08-12, `node tools/_t347-accepted-element-content-cdp.mjs`, rc 0.**
Positive control (`arc-lifecycle`, designer-produced) loses no shape, so the round-trip
path is sound and the subject results are real:

    documentation  2/2 carriers LOSE it   witnesses: bizagi-nested-ns, i18n-documentation
    extChildren    6/7 carriers LOSE it   witnesses: bizagi-nested-ns, caseagile-local-ns,
                                          i18n-documentation, kitchen-sink,
                                          multiple-diagrams, zeebe-service-task
    property       2/2 carriers LOSE it   witnesses: caseagile-local-ns, kitchen-sink
    loopChars      2/2 carriers LOSE it   witnesses: caseagile-local-ns, kitchen-sink
    unknownAttrs   3/3 carriers LOSE it   witnesses: i18n-documentation, kitchen-sink,
                                          zeebe-service-task

Every loss is **to exactly zero, never a reduction** — `caseagile-local-ns` drops
`405 -> 0` extension children and `45 -> 0` properties.

**One number has changed since the brief, and it is worth the sentence.** The brief
recorded `extChildren 6/6`; it is now **6/7**. The new denominator is
`aef-draft-inception-readiness-v2`, which keeps `87 -> 87` — and it survives because its
extension children are **`aef:uid` / `aef:position` / `aef:meta`, our own namespace, which
the importer enumerates**, whereas the loser's are `zeebe:`. So the one survivor is not a
counterexample to the rule; it is the mechanism stated exactly: *what the importer
enumerates survives, what it does not enumerate goes to zero.* A rule that had held 6/6
would have been weaker evidence than one that holds 6/7 for a reason you can point at.

**The trap this ruling protects you from.** `caseagile-local-ns` loses **one** thing under
a structural census and **hundreds** under the content census. Node, flow and lane counts
are unchanged throughout — an element that survives with its body stripped keeps all
three. Every count-based instrument in this tree stayed green over documents being gutted,
for the entire time the defect existed. *"Our suites are green"* is not evidence here, and
that is the reason this ruling should not wait on more of them.

**Seam context, recorded as a fact and not as an argument:** AEF's round-trip importer
also drops loose text inside a node, silently (rail 487, their T-2882) — our exact shape.
That settles the question asked at rail 484: the behaviour is a property of the seam, not
a defect peculiar to us. It **does not strengthen the case for `(a)`** and should not be
read as doing so. *"Both sides do it"* is a description; if anything it argues for `(b)`,
since preservation is only end-to-end when both ends preserve and today neither does. One
counter-argument was removed ("we are uniquely lossy"), nothing was added.

**The row most likely to make a uniform answer wrong.** The T-348 fold-in includes
`second-process`: a two-pool collaboration opened and saved returns as a **one-pool
document** — an entire pool's nodes gone — while every count on the surviving pool stays
green. Option `(c) refuse` is far more defensible for that row than for a `documentation`
string. If you rule Q1a uniformly, that row deserves an explicit sentence either way,
rather than being swept in.

**What your ruling unblocks:** T-347's four Agent ACs, plus the T-348 fold-in covering
seven further shapes.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

# --- T-347 commands (added 2026-08-03) ---
# The fixtures are INPUTS ONLY and `exporter=` does not survive the round trip
# (measured: dropped on all ten). If someone ever round-trips a fixture back over
# itself, the population silently reverts to designer-authored and every verdict
# below becomes vacuous while still reading green. The digests are the only detector,
# so they are checked FIRST and unpiped — `sha256sum -c | tail` returns tail's exit
# status, which is how this check passed against a deliberately corrupted digest
# during T-356 (L-387 class: an instrument that discards what it is verifying).
cd tests/fixtures/third-party && sha256sum -c --quiet --ignore-missing <(grep -A99 'Pinned digests' PROVENANCE.md | grep -E '^[0-9a-f]{64}  ')
# The census must still run and must still find carriers. A run where every shape
# reports NO CARRIER is not a pass — it means the fixtures stopped carrying the
# shapes, which is exactly the unreachable-witness state this task was stuck in.
out=$(timeout 300 node tools/_t347-accepted-element-content-cdp.mjs 2>&1); echo "$out" | grep -q 'PER-SHAPE VERDICT'
out=$(timeout 300 node tools/_t347-accepted-element-content-cdp.mjs 2>&1); ! echo "$out" | grep -q 'NO CARRIER'
# Harness integrity: the positive control is designer-produced and must stay clean.
out=$(timeout 300 node tools/_t347-accepted-element-content-cdp.mjs 2>&1); echo "$out" | grep -q 'round-trip path sound'
bash tests/run-bridge-tests.sh

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

### 2026-08-02T11:34:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-347-content-inside-an-accepted-element-is-si.md
- **Context:** Initial task creation

### 2026-08-03T16:56:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
