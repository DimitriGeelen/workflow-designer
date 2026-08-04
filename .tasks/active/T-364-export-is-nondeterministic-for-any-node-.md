---
id: T-364
name: "Export is nondeterministic for any node lacking aef:uid: a fresh uid is minted per parse, so third-party documents never round-trip byte-stably"
description: >
  Found under T-358 while measuring repair candidates. buildBpmnXml emits a fresh randomly-minted aef:uid for every node that did not arrive with one, so two consecutive parse->emit cycles of the SAME third-party input produce different bytes (kitchen-sink.bpmn: 81 lines differ). Designer-produced maps carry uids and are stable (audit-process 13563 bytes, arc-lifecycle 12270). Two consequences: (1) opening a third-party file twice yields two different documents, and any consumer keying on aef:uid sees a new identity per open; (2) the _t308 byte-identity gate (24/24 identical) is sound only for the designer-produced population that happens to carry uids, and is structurally incapable of reporting on the third-party population every repair in this arc targets. Evidence: tools/_t358-export-determinism.mjs (exit 1 today, 4 of 6 documents unstable).

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
created: 2026-08-04T10:33:42Z
last_update: 2026-08-04T13:39:04Z
date_finished: null
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
---

# T-364: Export is nondeterministic for any node lacking aef:uid: a fresh uid is minted per parse, so third-party documents never round-trip byte-stably

## Context

Found under T-358 while measuring repair candidates, and found only because a probe
was made to check its own instrument (emit the same document twice in the same build)
rather than trusting a cross-build comparison.

`buildBpmnXml` emits a freshly minted `aef:uid` for every node that did not arrive
carrying one. Two consecutive parse->emit cycles of the **same** third-party input
therefore differ: `kitchen-sink.bpmn` on 81 lines, `simple.bpmn` on 7. Designer-
produced maps carry uids in their bytes and are stable (`audit-process` 13563 bytes,
`arc-lifecycle` 12270).

Two consequences, and the second is why G-023 exists:

1. **Identity churn.** Open a third-party file twice and you have two documents that
   disagree on every node identity. Anything keying on `aef:uid` — ours or a
   consumer's — is tracking a value we re-roll per open. Flagged to AEF at RAIL-430.
2. **An instrument scoped by its population without saying so.** `_t308` byte-identity
   ("24/24 identical, 0 drifted") can only compare documents that emit deterministically,
   which is exactly the designer-produced set. It is structurally incapable of ranging
   over third-party documents — the population every repair in this arc targets — and
   nothing in its output says so. I cited that number as "this change moves no bytes",
   including to AEF at RAIL-427.

Related: G-023 (registered), T-358 (where it surfaced), PL-110.

## Acceptance Criteria

### Agent
- [x] **The nondeterminism is reproduced and its site named**, anchored on a function
      and not a line number. Required: the specific expression that mints a uid during
      import for a node that arrived without one, plus evidence that the same input
      emits differently twice in one page.

      **Site.** `generateUid(prefix)` (`src` ~1644) is
      `Math.floor(Math.random() * 16)` — pure randomness, no seed, no derivation from
      the document. `parseBpmnXml` falls back to it at two places:
      `const uid = uidEl?.getAttribute('value') || generateUid('n')` (nodes, ~9799)
      and the same with `'e'` for edges (~9976). Anchor on those two `|| generateUid(...)`
      fallbacks inside `parseBpmnXml`, not the line numbers.

      **Reproduction** (`tools/_t358-export-determinism.mjs`, two consecutive
      parse→emit cycles of the same input in the same page):

      ```
      lane-provenance/authored-lanes.bpmn   NOT STABLE —  5 lines differ
      third-party/simple.bpmn               NOT STABLE —  7 lines differ
      third-party/kitchen-sink.bpmn         NOT STABLE — 81 lines differ
      corpus/audit-process.bpmn             stable (13563 bytes)
      corpus/arc-lifecycle.bpmn             stable (12270 bytes)

      run 1: <aef:uid value="n_49d94bba"/>
      run 2: <aef:uid value="n_1c40c938"/>
      ```

      The split is exactly "did the document arrive carrying uids": designer maps did,
      third-party documents did not.

- [x] **`_t308` states the population it ranges over, and cannot silently range over
      less than it claims.**

      **Done.** `_t308` now exports every map **twice in the same build** and reports a
      third outcome: a document that is not byte-stable with itself is `unusable` —
      never `identical`, never `drifted` — and an unusable map **fails the run** (`ok:
      false`). The gate exists to answer "did any byte move?"; for a document it cannot
      compare it has no answer, and a green with a silent hole is the failure G-023
      records. Its JSON now carries a `population` block naming the source, why that
      population is comparable at all (it carries `aef:uid`), and what it does not cover,
      pointing at `tools/_t358-byteid-thirdparty.mjs` for third-party fidelity.

      Current run vs `3bf37909~1`: **24 identical, 0 drifted, 0 unusable, ok true.**

      **That zero is only worth something because the bucket was shown to fill.**
      `tools/_t364-t308-teeth.py` runs the gate against a temp corpus (the real one is
      never touched — `_t308` takes `T308_CORPUS`):

      ```
      control : rc=0 maps=24 identical=24 drifted=0 unusable=0
      teeth   : rc=1 maps=25 identical=24 drifted=0 unusable=1
      ```

      The injected document is a real third-party fixture — the population the gate was
      silently omitting, so it is the honest thing to inject. The load-bearing assertion
      is the middle column: `identical` stays **24**. Had the unstable document been
      counted identical, or dropped from every count, the gate would be overstating or
      quietly shrinking its own denominator — the two failure modes G-023 exists for.
      The teeth also assert the run names the population it cannot cover, so deleting
      that statement goes red.

      Not wired into `tests/run-bridge-tests.sh`: the teeth run the full CDP gate twice
      over 25 maps, and `_t308` is itself an on-demand instrument rather than a bridge
      leg. Stated rather than left as a silent omission.

      This is G-023's prevention half. Mitigation would be making export deterministic;
      prevention is a gate that cannot overstate its reach even after that fix, because
      the next nondeterministic field will not announce itself either.

- [x] **Export is deterministic for third-party input**, i.e.
      `tools/_t358-export-determinism.mjs` exits 0 with every document stable — OR the
      repair is deliberately deferred and this AC records the measured reason, since a
      stable uid must come from somewhere and inventing one is how T-358 started.

      **DONE — repair (a) implemented 2026-08-04.** `deriveUid` in `parseBpmnXml`
      (FNV-1a 32-bit over the BPMN element id, `prefix_8hex` shape unchanged, collisions
      salted in document order). Both mint fallbacks now derive; the random
      `generateUid` path remains only where the editor creates genuinely new nodes,
      which is authored data with no document to derive from.

      ```
      lane-provenance/authored-lanes.bpmn    stable   (2930 bytes)
      lane-provenance/no-laneset.bpmn        stable   (3157 bytes)
      third-party/simple.bpmn                stable   (3705 bytes)
      third-party/kitchen-sink.bpmn          stable   (25442 bytes)
      corpus/audit-process.bpmn              stable   (13563 bytes)
      corpus/arc-lifecycle.bpmn              stable   (12270 bytes)
      All documents emit deterministically.                       (exit 0, was exit 1)
      ```

      The trap analysis below is kept because it is the reasoning the ruling acted on,
      not because it is still pending. Read it as the record of what was decided.

      > **WAS NOT STARTED when this AC was written — the trap, flagged before anyone
      > walked into it.**
      > The obvious fix is to derive the uid from data the document already carries (its
      > BPMN element `id`, which is required and unique per document) instead of
      > `Math.random()`. That is deterministic and involves no invention beyond a hash.
      >
      > But it does not answer the prior question, and the prior question is **T-358's
      > question wearing different clothes**: *should we emit `aef:uid` at all for a node
      > that arrived without one?* Emitting it adds our metadata to a third-party
      > document that never had it. Deterministic fabrication is still fabrication — it
      > merely stops churning. The lane case and this case share one shape, and I got the
      > lane case wrong for months by treating "what value should the default be" as the
      > whole question.
      >
      > A uid asserts nothing about governance, so this is materially less loaded than
      > `human · sovereignty` — that is an argument about severity, not about kind. Two
      > candidates, to be MEASURED and not chosen here:
      >   (a) derive from element id — stable, still additive
      >   (b) omit `aef:uid` for nodes that arrived without one — additive-free, but every
      >       downstream consumer of `node.uid` must be checked first (T-358's F1 was
      >       exactly a downstream guard disagreeing about what "absent" means)
      >
      > Deferring on purpose at 68% context: this is a seam-visible emission change, not
      > a small bounded unit, and it should be measured the way T-358's candidates were.
      >
      > **Consumer enumeration 2026-08-04 — and it reshapes (b) before any probe is
      > written.** `uid` is not a decoration on the side of a node, it is the node's
      > identity inside the editor. Imported nodes are built as
      > `nodes.push({ uid, id: uid, slug, type, name, lane: laneId, ... })`, so:
      >
      >   - `data-id` on the rendered `<g>` is `n.id`, i.e. the uid — it is the DOM key
      >   - `findNode` / `findEdge` / `findNodeByUid` resolve identity by uid
      >   - `_displayIdCache` is keyed on uid
      >   - `computeDisplayId` **sorts by it**:
      >     `.sort((a, b) => a.x - b.x || a.uid.localeCompare(b.uid))`
      >
      > **So (b) cannot mean "no uid".** It can only mean *do not PERSIST the uid*. The
      > editor still mints one on open, so **(b) does not fix identity churn at all** —
      > reopening still produces different identities. It only stops our invented
      > metadata reaching the bytes. That is a narrower benefit than the AC's phrasing
      > implies, and (a) fixes both halves. The options are not symmetric and I would
      > have measured them as though they were.
      >
      > **Latent hazard, worth naming even though it did not fire.** Because uid is the
      > tie-breaker in the displayId sort, a random uid can in principle permute
      > **emitted** displayIds for nodes that tie on `x` within one lane — and displayIds
      > are emitted (`flowNodeRef`, element ids). The nondeterminism would then not be
      > confined to `aef:uid` values. `tools/_t358-byteid-thirdparty.mjs` normalised
      > *only* `aef:uid` and still got 10/10 identical, which is evidence no tie occurred
      > in those ten fixtures — **not** evidence that ties cannot occur. A determinism
      > repair should pin that explicitly rather than inherit it from a lucky corpus.
      >
      > **Measured 2026-08-04, and it bounds the defect.** `_t358-export-determinism.mjs`
      > now classifies every differing line as an `aef:uid` line or something else,
      > because "all differing lines are uid lines" is precisely the claim that confines
      > this defect to uid values:
      >
      > ```
      > authored-lanes.bpmn    5 differ ->  5 aef:uid,  0 other
      > no-laneset.bpmn        5 differ ->  5 aef:uid,  0 other
      > simple.bpmn            7 differ ->  7 aef:uid,  0 other
      > kitchen-sink.bpmn     81 differ -> 81 aef:uid,  0 other
      > ```
      >
      > **Zero non-uid drift.** So the uid-only normaliser in
      > `tools/_t358-byteid-thirdparty.mjs` is *justified* for this corpus rather than
      > assumed, and the 10/10 result I put on the rail at RAIL-430 rests on a measured
      > property. The probe now prints that conclusion — and prints the wider warning
      > instead if a non-uid line ever moves, naming the uid-only normaliser as
      > insufficient and the claims resting on it as needing a re-run.
      >
      > The residual stays stated rather than quietly dropped: this is a property of
      > these six documents, not a proof that a displayId tie cannot permute emitted ids
      > on some other document. AC3's repair should pin it directly.
      >
      > ---
      >
      > **The residual was load-bearing. Measured 2026-08-04 (post-compact), and it
      > inverts the ranking of (a) and (b).**
      >
      > I had this filed as a "latent hazard, worth naming even though it did not fire".
      > It did not fire because the population could not make it fire. Two new
      > instruments, `tools/_t364-x-tie-census.py` and `tools/_t364-tie-permutes-ids.mjs`:
      >
      > **1. Ties are ordinary, not exotic — 19 of 24 corpus maps** hold at least one
      > same-lane `x` collision (306/306 nodes carry `aef:position`). The tie-break branch
      > of the sort is exercised constantly. It is harmless *today* only because those
      > maps carry `aef:uid` in their bytes, which pins the resolution across parses.
      >
      > **2. Today's third-party fixtures cannot tie AT ALL, and that is why they were
      > clean.** None carries `aef:position`, so the importer's fallback layout assigns
      > `x = POOL_X + LANE_HEADER + 30 + sameLane.length * 90` — strictly increasing per
      > lane. A tie is *structurally unreachable* for that population. The "0 non-uid
      > drift over 10 fixtures" result above is therefore a **capability zero**, exactly
      > the shape this task was opened about. It was correct and it could not have come
      > out any other way.
      >
      > **3. The mechanism is real, demonstrated end-to-end, with a discriminating
      > control.** Strip `aef:uid` from a shipped corpus map and emit twice:
      >
      > ```
      >   audit-process       2 tie groups /8 nodes   ids PERMUTED   (frw_12_audit <-> frw_10_audit)
      >   harvest-pipeline    2 tie groups /9 nodes   ids PERMUTED   (frw_22_dry   <-> frw_21_dry)
      >   arc-lifecycle       2 tie groups /4 nodes   ids PERMUTED   (frw_2_close  <-> frw_1_close)
      >   context-memory      1 tie group  /2 nodes   ids PERMUTED   (prj_4_add    <-> prj_5_add)
      >   healing-loop        0 tie groups           ids STABLE      <- negative control
      >   verification-gate   0 tie groups           ids STABLE      <- negative control
      > ```
      >
      > Every map's *unstripped* control emitted identical ids twice, and the two tie-free
      > maps held still under the identical strip. That is what makes this causal rather
      > than correlational — the first version of this probe had no genuine tie-free row
      > (I picked `context-memory` believing it was tie-free; it holds a tie), so it
      > confirmed four times and discriminated nothing until a census chose the controls.
      >
      > What permutes is **`flowNodeRef`, and with it `id=`, `sourceRef`/`targetRef`,
      > `attachedToRef`, `incoming`/`outgoing`** — the document's identity graph, not our
      > private metadata.
      >
      > **Consequence for the (a)/(b) choice, which is the point of measuring:**
      > **(b) "mint but do not persist" is not the conservative option — it is the
      > destructive one.** A (b) save produces precisely the documents above: no
      > `aef:uid`, real colliding `x`. It would introduce identity churn into the 19 of 24
      > corpus maps that are stable today *because* their uids are in the bytes. My earlier
      > note said (b) "does not fix identity churn at all"; that was too kind. It creates
      > it, in the population that currently has none. **(a) derive-from-element-id remains
      > viable and is now the only candidate that does not regress the corpus.**
      >
      > **Consequence for T-357 (adopt BPMN DI as designer geometry), which is an open
      > inception decision.** Reading the same fixtures through their DI — the coordinates
      > those nodes *would* have under T-357 — `boundary-events.bpmn` (2 groups/4 nodes)
      > and `kitchen-sink.bpmn` (11 groups/52 nodes) already hold collision groups whose
      > members carry no `aef:uid`. Adopting DI supplies the missing ingredient (real,
      > colliding `x`) to documents that still have no stable identity in their bytes. The
      > protection we enjoy today is an accident of the fallback layout, and T-357 removes
      > it. **T-364's repair is a prerequisite of T-357, not parallel to it** — that is a
      > sequencing input the inception decision did not have.
      >
      > Residual, stated: the census reads DI x for population 3 but the T-357 import path
      > does not exist yet, so that row is a forecast from the input bytes, not a
      > measurement of a built importer.
      >
      > **Second residual, now recorded as a debt rather than closed.** Adopting AEF's
      > RAIL-432 counter (compute the population two independent ways and diff before
      > reading the result), the census reports **34 examined of 141 `.bpmn` in the tree**.
      > The unexamined 107 include **18 peer-authored maps under `tests/fixtures/aef-bpmn`
      > never measured for ties or uid coverage**, and `.editor-versions/*` — the
      > dot-directory shape that cost AEF a 32-file denominator error. This census scopes
      > to named populations on purpose, so the gap is not a bug; but *deliberately
      > scoped* and *accidentally truncated* produce identical output unless the
      > unexamined space is printed beside the examined one, so it now prints it.
      >
      > **RETRACTED at RAIL-438 — the corroboration claim was wrong; the measurement was not.**
      > AEF answered: `tests/fixtures/aef-bpmn` holds **5 files on their side, 18 on ours**,
      > same path, same name, and their `git log --diff-filter=D` over it is empty (no drift
      > there). I checked the add-commit for all 18: **every one arrived via an 832 task
      > commit** (T-183/192/204/208/214/215/219/235/308/310/311/312/313). Three are labelled
      > pair-draft; the rest are ours outright. `session-lifecycle-d3`, one of their five,
      > is absent from our tree entirely.
      >
      > So the directory does not mean "AEF's BPMN". It means **"BPMN fixtures about the AEF
      > seam, authored here"** — the name asserts a provenance it never had, and I read it as
      > provenance and said "18 of your maps" to the peer. The measurement was careful and
      > the NOUN was wrong. **149/149 stands as a fact about our own fixtures; it is not
      > independent confirmation of AEF's 424/424 and never could have been** — their figure
      > ranges over 32 maps under `.context/designer/projects/`. Two individually-correct
      > numbers over populations neither side had checked were the same, about to become an
      > "independent confirmation" worth nothing and raising both sides' confidence.
      >
      > **Debt closed same session — population 4 added (original claim, now corrected).** The 18
      > peer-authored maps under `tests/fixtures/aef-bpmn` are **149/149 uid-covered**, and
      > 7 of 18 carry same-lane x collisions — harmless for exactly the corpus reason:
      > every tied node's uid is in the bytes. AEF reported their live corpus at 424/424;
      > our copies agree. So the peer-authored population is safe today and safe for the
      > same accidental reason as ours, which is the finding, not the zero. (Two of 149
      > nodes lack `aef:position` and would take the fallback layout; both carry uids.)
      >
      > The census now reports uid coverage on every population, because the tie count
      > alone cannot tell a safe population from an exposed one — only the conjunction
      > of *tie* and *uid-less* permutes ids, and reporting either ingredient by itself
      > invites reading a scary tie count as a hazard or a clean one as safety.
      >
      > ---
      >
      > **RAIL-432 answered by measurement: all 12 of AEF's `aef:*` kinds survive an
      > open→save.** Separate from the determinism question but discovered under it, so
      > recorded here. AEF asked which of their eleven non-contract extension kinds
      > `parseBpmnXml` names — their worry being that a round-trip strips their whole
      > governance overlay (state, lane authority, event typing, anchors) while node/flow/
      > lane counts stay identical, i.e. the RAIL-399 shape from the other end.
      >
      > `tools/_t364-aef-ext-roundtrip.mjs`: one fixture carrying every kind, in the
      > shapes this build emits, at the carrier each belongs on. **All 12 PRESERVED**
      > (kind present after round-trip AND every attribute value intact); invented kind
      > `aef:notAThing` **DROPPED** as the negative control, which is what makes the
      > PRESERVEDs mean *named* rather than *blind passthrough*.
      >
      > Two errors of mine on the way, both caught before the answer was sent:
      >   - The grep form (`byAef(el, '<name>')` call sites) said **10 of 12**, missing
      >     `constituents`/`constituent` because they go through the `structItemList`
      >     list-of-dicts path and never appear in a `byAef(el, <literal>)` site — wrong
      >     by exactly the two kinds the question was sharpest about, while reading as a
      >     careful enumeration. **Naming is not preserving** either: a kind can be read
      >     into a local that never reaches the node object, or reach it and never be
      >     emitted. Only the round-trip answers what was asked.
      >   - The first fixture reported `aef:link DROPPED (12 instances)`. Both causes were
      >     mine: `aef:link` shared a node with `aef:eventDef` (mutually-exclusive typing
      >     extensions `adoptImportedXml` disambiguates between), and it used a bare
      >     `name=`, a shape the emitter never writes — `linkAttrs` only fills from
      >     `workflowRef`/`targetWorkflow`/`linkId`. On its own node with the real shape:
      >     PRESERVED. Sending that would have spent the peer's attention on a bug of mine.
      >
      > Scope stated in the tool's own output: measured on ONE synthetic document, in the
      > shapes THIS build emits. It does not prove fidelity for attribute names we do not
      > emit, kinds absent from their census, or nesting this fixture does not reach.

- [x] **No emitted byte moves for the existing corpus.** Any repair must keep
      `_t308` byte-identity green over the designer-produced maps, whose uids are real
      authored data and must not be renumbered by a determinism fix.

      **Green after the repair, both populations:**

      ```
      _t308 vs 3bf37909~1   ok true, 24 identical, 0 drifted, 0 unusable, 24 maps
      _t358-byteid-thirdparty vs 3bf37909~1
                            10 identical, 0 drifted, 0 unusable, PRECONDITION HOLDS
      ```

      The corpus result is the load-bearing one and it is green for the reason it
      should be, not by luck: all 306 corpus nodes carry `aef:uid` in their bytes
      (census P1), so the derivation path never executes for them. `audit-process`
      13563 and `arc-lifecycle` 12270 — the same byte counts recorded in AC1 before
      the change.

      **The third-party 10-identical is the weaker claim and is stated as such.** That
      run normalises `aef:uid` values in document order, so what it certifies is "no
      byte *other than the uid values themselves* moved". The uid values did move —
      random → derived — and that is the whole point of the repair.

- [x] Bridge suite green (`tests/run-bridge-tests.sh`), no leg lost.

      `bridge round-trip: 71 passed, 0 failed`; geometry sweep 24 clean, 0 new-fail.

      **A leg was regained rather than merely held.** The suite was at 70/1 before this
      session: `_t364-byteid-precondition-teeth.py` (added last session) synthesised
      `<bpmn:task>`, which neither emitter can produce, and the T-327 harness-fidelity
      gate failed it. That failure was mine, it was correct, and the previous session
      recorded 7/7 P-011 green without re-running the suite that would have caught it —
      a verification block is not the suite. Fixed by crafting the teeth document out of
      `<bpmn:serviceTask>`: the tag was incidental, the tie is the property under test,
      so declaring a tolerance would have been buying an exemption for an accident.

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

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Final test IS the verdict (errexit-safe form) — see T-353.

# the two import-side mint fallbacks AC1 named are now the repair, and the random mint
# is gone from the import path. Re-pointed at the fix rather than deleted when (a) landed:
# these lines asserted "the defect site is here", so on repair they must assert
# "the repair site is here" or the anchor stops describing anything.
out=$(grep -c "deriveUid('n', displayId)" src/aef-workflow-designer.html); [ "$out" = "1" ]
out=$(grep -c "deriveUid('e', el.getAttribute('id') || '')" src/aef-workflow-designer.html); [ "$out" = "1" ]
out=$(grep -c "|| generateUid('n')" src/aef-workflow-designer.html || true); [ "$out" = "0" ]
out=$(grep -c "|| generateUid('e')" src/aef-workflow-designer.html || true); [ "$out" = "0" ]

# export is deterministic for third-party input — AC3's own gate, green in both eras
# (stable = good before and after the repair), so it is the one safe to keep forever
node tools/_t358-export-determinism.mjs > /dev/null 2>&1
# the tie no longer reaches the emitted identity graph (guard, post-repair polarity)
node tools/_t364-tie-permutes-ids.mjs > /dev/null 2>&1
# and that guard goes RED when the random mint is put back — proven by mutation, not by
# reading it; its failure branch is new and an unproven red is not a guard
python3 tools/_t364-tie-guard-teeth.py > /dev/null 2>&1

# the byte-identity gate states its population and holds out what it cannot compare
out=$(node tools/_t308-export-byte-identity-cdp.mjs 3bf37909~1); echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if (d['ok'] and d['unusable']==0 and d['population']['does_not_cover']) else 1)"

# and that unusable bucket can actually fill — a zero from a check that cannot fire is a constant
python3 tools/_t364-t308-teeth.py > /dev/null 2>&1
# the third-party byte-identity run holds its stated precondition (no tie among uid-less nodes)
out=$(node tools/_t358-byteid-thirdparty.mjs 3bf37909~1 2>&1); echo "$out" | grep -q "PRECONDITION HOLDS"
# and that precondition can actually FIRE — a HOLDS from a check that cannot fire is a constant
python3 tools/_t364-byteid-precondition-teeth.py > /dev/null 2>&1
# the aef:* seam census keeps both controls behaving (uid PRESERVED, unknown kind DROPPED);
# this is the answer given to AEF at RAIL-434 and it must not rot silently
node tools/_t364-aef-ext-roundtrip.mjs > /dev/null 2>&1
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

### 2026-08-04 — uid determinism: operator ruling

- **Chose:** **(a) derive the `aef:uid` from the element id.** Ruled by the operator
  (human) after the measurement was presented. Agent recommendation matched.
- **Why:** the element `id` is required and unique per BPMN document, so a derived uid is
  deterministic without inventing data. It fixes BOTH halves — no churn in the bytes and
  no churn in the editor's internal identity — which (b) does not.
- **Rejected: (b) mint but do not persist.** Measured as *destructive, not conservative*.
  A (b) save produces documents with no `aef:uid` and real colliding `x`; 19 of 24 corpus
  maps hold a same-lane x tie and are stable ONLY because their uids are in the bytes, so
  (b) would introduce identity churn into a population that has none today. It also fails
  to stop churn on reopen, since the editor still mints on open.

**Implementation notes for whoever picks this up — three traps already identified:**

1. **`tools/_t358-byteid-thirdparty.mjs` becomes OVER-STRICT the moment this lands.** Its
   precondition test approximates "uid is nondeterministic" with "the source carries no
   `aef:uid`". Under (a) a uid-less source mints STABLE uids, so the check will refuse a
   run that is actually sound. **Narrow the predicate to "minted nondeterministically" —
   do NOT delete the check.** A guard that starts crying wolf after a repair looks
   identical to one that was always wrong, and removal is the cheap answer to both. This
   is written into the file itself as well.
2. **`tools/_t364-tie-permutes-ids.mjs` is an EXPERIMENT, not a gate.** It exits 0 when
   the defect is present and will report PREDICTION REFUTED (exit 1) once (a) lands. That
   red is the success signal. It is deliberately not wired into P-011.
3. **Deterministic fabrication is still fabrication.** (a) emits our `aef:uid` into
   third-party documents that never carried one. That is the T-358 question wearing
   different clothes and it is NOT settled by this ruling — it is a separate call about
   whether we write our metadata into someone else's bytes at all. AEF confirmed at
   RAIL-432 that `aef:uid` is ratified and in the seam contract, which is why this is
   materially less loaded than T-358's `human · sovereignty` fabrication, but the kind is
   the same. Do not let (a) silently answer it.

**Gates that must stay green:** AC4 (`_t308` byte-identity over the 24 corpus maps —
their uids are real authored data and must NOT be renumbered by a determinism fix) and
AC5 (bridge suite, no leg lost).

### 2026-08-04 — implementing (a): the predicted narrowing was the wrong narrowing

- **Chose:** narrow the `_t358-byteid-thirdparty.mjs` precondition to **"the uid that
  breaks this tie is not the same value on both sides of the comparison"** — measured per
  run (uid vector per build, plus a second parse per build for within-build stability) —
  rather than to "this build mints nondeterministically" as trap 1 instructed.
- **Why:** trap 1 predicted the guard would go over-strict because a derived uid resolves
  a tie identically every parse. That is true and it is not sufficient. **This tool is a
  cross-build diff.** A uid-less node gets a random uid in the baseline build and a derived
  one in the current build; if those two orders disagree at a tie, the emitted element ids
  permute *between the builds* no matter how deterministic either side is on its own. A
  within-build predicate would have declared such a run sound and let a real permutation
  through as "identical". The measured predicate also **self-heals**: once `BASELINE_REF`
  moves past the repair, both sides derive identically, the vectors match, and it stops
  firing without anyone editing it.
- **Rejected:** deleting the check (trap 1's named failure mode), and the literal
  within-build narrowing (unsound for this tool, per above).
- **Kept honest:** the old predicate was not wrong, it was *narrower than its subject* —
  "source carries no aef:uid" is a special case of the measured one. Both earlier forms
  are subsumed rather than contradicted.

**A prediction written into a guard is still a prediction.** Trap 1 was right that the
guard would need narrowing and right that removal was the danger; it was wrong about which
predicate to narrow to, because it reasoned about the defect and not about what the
instrument compares. Recorded because the note read as an instruction and was one step
from being followed literally.

### 2026-08-04 — the tie probe's polarity, and why it is now a gate

- **Chose:** invert `_t364-tie-permutes-ids.mjs` to a regression guard (exit 0 = repair
  holds, exit 1 = a map permuted), measure per run which side of the repair the build is
  on, and prove the new red branch by mutation (`_t364-tie-guard-teeth.py`: revert the two
  `deriveUid` calls in a temp copy → rc=1 "REGRESSION"; real source → rc=0 "REPAIR HOLDS").
- **Why:** trap 2 was right that its red was the success signal, but left the file saying
  *"the reading of computeDisplayId is wrong — find what else orders them"* on that red.
  That sentence would send the next reader to debug working code. An experiment whose
  question has been answered either gets a new polarity or gets deleted; leaving it with a
  stale verdict is the worst of the three.
- **Noted, not hidden:** under a stable mint the **tie-free negative control has gone
  inert**. Nothing permutes now, so a tie-free map holding still is guaranteed and
  discriminates nothing. The run prints this instead of counting it as corroboration. What
  carries the guard is the per-build mint measurement and the tie counts (the tied maps
  still have their ties — the hazard population still exists to be protected).

### 2026-08-04 — STILL OPEN after (a): should we emit `aef:uid` into third-party bytes?

Trap 3 said (a) must not silently answer this, so it is recorded as unanswered.
**(a) did not settle it and this task does not close it.** Every third-party document we
open and save still leaves with our `aef:uid` on nodes that never carried one — the
values are now derived instead of random, which stops the churn and changes nothing about
whether they belong there. It is T-358's question about the lane default wearing different
clothes: *what value should this be* is not *should this be here at all*.

Materially less loaded than T-358's `human · sovereignty` (a uid asserts nothing about
governance, and AEF ratified `aef:uid` in the seam contract at RAIL-432) — that is an
argument about severity, not about kind. Carried forward on T-358, not re-filed here.


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

### 2026-08-04T10:33:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-364-export-is-nondeterministic-for-any-node-.md
- **Context:** Initial task creation

### 2026-08-04T10:54:14Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
