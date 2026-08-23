---
id: T-501
name: "Map ID round-trip defect triage (AEF consumer)"
description: >
  Inception: Map ID round-trip defect triage (AEF consumer)

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-14T16:55:53Z
last_update: 2026-08-20T09:17:18Z
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
  - ts: '2026-08-16T12:33:30Z'
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
  - ts: '2026-08-16T14:33:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=6 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-501: Map ID round-trip defect triage (AEF consumer)

## Problem Statement

A BPMN document that carries no `<aef:workflowMeta>` element gets its map identity from
`<bpmn:process name="...">` — a **display name** used as a **machine identifier**
(`src/aef-workflow-designer.html:9950`). Reported by the 001-CashWeb consumer against
their hand-authored BPMN; confirmed here at v0.10.0.

Who it is for: any producer of BPMN that our editor did not write. That is the whole
third-party import surface, and it is the surface the AEF seam sits on.

Why now: measured on our own corpus, **14 of 60 documents reach that fallback and all 14
of 14 derive an id the save validator rejects** (`:8433`). The failure is total on the
path, not occasional. The operator meets it as "your save failed" after they have already
been editing.

Two further defects travel with it and were reported together: the sanitizer and the
validator disagree on the leading-character rule, so the field can hand you a value the
save path will refuse; and validation happens at save rather than at load, which is what
turns a bad byte in a file into a surprise ten minutes later.

## Assumptions

- **A1 — The fallback path is actually reached in practice.** TESTED, HOLDS. 14 of 60
  corpus documents carry no `<aef:workflowMeta>` (census in the report, §0.1).
- **A2 — `deriveSlug()` is a suitable transform for identity.** TESTED, **FALSIFIED.**
  It is a summariser (first word >1 char, truncated to 16), not a slugifier. Over the
  same 14 documents it yields 4 distinct ids, all of which pass the validator.
- **A3 — Fixing derivation is sufficient; collisions are out of scope.** TESTED,
  HOLDS BUT ONLY BECAUSE OF EXISTING CODE. `loadBpmnIntoLibrary` already appends
  `_v<n>` until unique (`:9214`) and writes it back to `workflowMeta.id`. The policy is
  downstream of the transform, which is precisely why the transform choice matters.
- **A4 — The sanitizer fix has to be written.** TESTED, **FALSIFIED.** It exists at
  `:9162` (`createFromPendingRef`) and is correct. The work is to lift and share it.
- **A5 — There are two sanitizer sites.** TESTED, **FALSIFIED.** There are three:
  `:2685` (`renameActiveWorkflow`), `:5223` (properties panel), `:9162`.
- **A6 — The consumer-corpus figures in the proposal (126 of 145) are usable evidence
  here.** NOT TESTABLE. That tree is behind the T-559 boundary. Excluded from evidence.

## Exploration Plan

Executed 2026-08-20. Time-box 90 min; actual ~60 min. No build artifacts written.

1. **Locate the three reported sites in current source** — the proposal's line numbers
   predate v0.10.0. DONE: all three present, drifted by ~40–105 lines, code identical.
2. **Read `deriveSlug()` rather than trusting its name.** DONE — and this is where the
   proposal broke.
3. **Run both transforms over the corpus and count distinct ids and validator
   failures.** DONE (census is re-runnable, expected output pinned).
4. **Find every site that mints or rewrites a library key**, so "unify the sanitizer"
   is scoped by grep and not by memory. DONE: `library.set/has/delete` × 16 sites.
5. **Establish whether import has a collision policy** before proposing one. DONE — it
   has, at `:9214`.

## Technical Constraints

- The editor is one 10,612-line self-contained HTML file; there is no module boundary to
  hide a shared helper behind. A "shared validation function" is a function in the same
  script, and the only thing keeping the four call sites in step is the test.
- Behaviour is only observable through a headless browser: the corpus census above is
  static analysis of the *inputs*, not of the running derivation. A build task must drive
  `parseBpmnXml` via CDP (the `tools/_*-cdp.mjs` pattern) to claim the fix works.
- v0.8.0 is vendored downstream; source fixes do not reach the consumer until a release.

## Scope Fence

IN: the derivation transform at `:9950`; unifying the three sanitizer sites plus a new
load-time one; load-time normalisation with a visible notice.

OUT: changing the validator regex (it is correct); renaming existing valid ids; the
always-emit-`workflowMeta` round-trip closure — see IW-0 below, it is a byte-identity
change and does not belong in the same task as a derivation change.

## Open Questions

- **IW-0: Should export always emit `<aef:workflowMeta>`?**
  confidence: 2
  disposition: deferred
  rationale: The proposal bundles it as "round-trip closure" and rates it low risk. It is
    the only item in the package that changes bytes the editor already writes correctly,
    and T-308/T-358 byte-identity gates exist precisely there. Separable, and separating
    it is the reason the recommendation below is conditional rather than a flat GO.
    DEFERRED, NOT ANSWERED — 2026-08-20, on the operator's GO. The GO is on the narrowed
    package, and this item is the part that was narrowed OUT; it is carried forward
    undecided rather than resolved here. Recording it as `answered` would convert a
    carve-out into a ruling nobody made, which is the same substitution §0 of the report
    was written to undo. What makes it decidable later, stated so the deferral has an
    exit: measure whether emitting `<aef:workflowMeta>` on every export changes the bytes
    of any of the 24 rendered corpus maps, and run T-308/T-358's byte-identity gates
    against the result. If nothing moves, the risk that motivated the carve-out is not
    there and the item is cheap; if something moves, the gate failure is attributable to
    this change alone — which is exactly what bundling it into the GO would have destroyed.
    Needs its own build task, not a line in this one.

    **EXIT CONDITION EXECUTED 2026-08-23 by T-565. DISPOSITION UNCHANGED — still `deferred`,
    because flipping it is the operator's, and the measurement below does not make the
    ruling, it makes it cheap.** Three things were measured
    (`tools/_t565-workflowmeta-emission-census.mjs`, wired as a bridge-suite leg):

    1. **The exit condition names a population that cannot execute it.** All 24 rendered
       maps already carry `<aef:workflowMeta>`, so an always-emit rule cannot move one byte
       of any of them. A clean result there would have been a no-op reported as a safety
       proof — the same population-pin as T-423's `aef:forceStraight` and G-015. The 14
       documents that CAN move are the ones this task's own IW-1 already found: 10 under
       `tests/fixtures/third-party`, 4 under `lane-provenance`. Their per-document cost is
       101–131 bytes, the `<aef:workflowMeta …/>` block only — a whole-document diff is
       dominated by the 2012 DI elements T-423 made unconditional.

    2. **Always-emit is already the behaviour.** Round-tripping all 14 through the real
       designer: 14 of 14 lack the element on input and carry it on output. IW-0 asks
       whether export *should* always emit. It already does, unconditionally. So this is not
       a proposed byte change to weigh against a risk — it is a description of shipped
       behaviour, and the ruling available is whether to keep it, not whether to make it.

    3. **The safety net this deferral named does not cover it.** `_t308` passes 24/24 and
       its own emitted metadata says `does_not_cover: third-party documents`; its corpus
       holds zero movers. `_t358-byteid-thirdparty` — which does reach 10 of the 14 — exits
       **1** today, reporting 0 identical / 11 drifted and `PRECONDITION VIOLATED`, and **no
       runner invokes it**: no suite leg, and its only code caller is a teeth script the
       T-509 sweep excludes by design. T-364 predicted exactly this failure in writing when
       DI became geometry. Filed as **T-579**. The remaining 4 movers, under
       `lane-provenance`, are watched by neither gate.

- **IW-1: Can ID derivation use deriveSlug() without breaking existing round-tripped workflows?**
  confidence: 4
  disposition: answered
  rationale: **NO — measured, and the answer flipped.** The 2026-08-14 rationale said
    "existing exports carry explicit `<aef:workflowMeta id>`, so the fallback chain never
    executes". True of *our* exports and false of the corpus: 14 of 60 documents have no
    such element and reach the fallback. Over those 14, `deriveSlug` yields 4 distinct
    ids — `process` ×8, `proc` ×4, `id` ×1, `009164cd` ×1 — every one of them valid, so
    nothing complains. The question was answered by reasoning about which documents were
    thought to exist; it is now answered by counting them.

- **IW-2: Will sanitizer/validator unification cause user-facing behavior change?**
  confidence: 2
  disposition: answered
  rationale: Current state: sanitizer produces invalid output. Proposed state: sanitizer produces only valid output. Net effect is UX improvement, not breakage. Phase 3 testing confirms.

- **IW-3: Does corpus contain any existing workflows that depend on leading-dash IDs?**
  confidence: 4
  disposition: answered
  rationale: No. The 2026-08-14 rationale reasoned from the validator regex
    `/^[a-z0-9][a-z0-9_-]*$/` and deferred the check to "Phase 2". The sweep has now been
    run: of the 46 corpus documents carrying `<aef:workflowMeta>`, none has a leading-dash
    id. Note the regex argument alone was not sufficient — it constrains what `saveToProject`
    accepts, not what a hand-authored file may contain, and the 14 documents in this same
    corpus that violate the regex are the proof of that gap.

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
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
#
# WHY AN INCEPTION HAS EXECUTABLE LEGS HERE (usually it does not).
# The recommendation above is a claim about source that the operator has not read and about
# a corpus nobody re-counts. T-189 spent five weeks being one signature away from a ruling on
# a delta the world had moved past, and OBS-291 records that nothing checks whether a document
# behind an unchecked [REVIEW] AC still describes the tree. These legs are the cheap version of
# that check for this task: if the derivation, the sanitizers or the corpus change between now
# and the decision, this gate goes red rather than letting a stale ruling land quietly.
#
# Leg 1 — D1 is still present and unfixed. If someone fixes it before the ruling, the
#         recommendation is moot and should not pass silently.
grep -q "id: aefMetaEl?.getAttribute('id') || procName || 'imported'," src/aef-workflow-designer.html
# Leg 2 — there are still exactly THREE sanitizer sites (2685, 5223, 9162). The proposal found
#         two. A fourth appearing, or one being unified away, changes the scope above.
test 3 -eq "$(grep -cF "trim().toLowerCase().replace(/[^a-z0-9_" src/aef-workflow-designer.html)"
# Leg 3 — deriveSlug is still the SUMMARISER. The census in leg 4 reimplements it in python;
#         if the real function changed, that reimplementation would silently stop matching it.
grep -q "function deriveSlug(displayName) {" src/aef-workflow-designer.html && grep -q ".filter(w => w.length > 1)" src/aef-workflow-designer.html
# Leg 4 — the corpus census still produces the numbers the recommendation is built on. Every
#         figure cited in Evidence is in this one line, so a corpus change cannot leave the
#         rationale standing on counts that are no longer true.
python3 -c "import os,re,xml.etree.ElementTree as ET; B='{http://www.omg.org/spec/BPMN/20100524/MODEL}'; ok=lambda s: bool(re.fullmatch(r'[a-z0-9][a-z0-9_-]*', s or '')); ds=lambda s:(([x for x in re.split(r'[\s\-]+',re.sub(r'[^a-z0-9\s\-]',' ',(s or '').lower())) if len(x)>1] or ['node'])[0])[:16]; sl=lambda s: re.sub(r'[^a-z0-9_\-]','-',(s or '').strip().lower()).strip('-_') or 'workflow'; F=[os.path.join(dp,f) for rt in ['examples/aef-processes/rendered','tests/fixtures/aef-bpmn','tests/fixtures/third-party','tests/fixtures/lane-provenance'] for dp,_,fs in os.walk(rt) for f in fs if f.endswith(('.bpmn','.xml'))]; R=[ET.parse(p).getroot() for p in F]; N=[x for x in R if not any('workflowMeta' in e.tag for e in x.iter())]; P=[[e for e in x.iter(B+'process')] for x in N]; D=[(((p[0].get('id') if p else None) or 'imported'), (p[0].get('name') if p else None)) for p in P]; D=[(i,(n or re.sub(r'^Pool_','',i))) for i,n in D]; print('META=%d FALLBACK=%d CURRENT_INVALID=%d PROPOSED_DISTINCT=%d CORRECTED_DISTINCT=%d CORRECTED_INVALID=%d' % (len(R)-len(N), len(D), sum(1 for i,n in D if not ok(n or i)), len(set(ds(i) for i,_ in D)), len(set(sl(i) for i,_ in D)), sum(1 for i,_ in D if not ok(sl(i)))))" > /tmp/.t501-census 2>&1 && grep -q "META=46 FALLBACK=14 CURRENT_INVALID=14 PROPOSED_DISTINCT=4 CORRECTED_DISTINCT=10 CORRECTED_INVALID=0" /tmp/.t501-census
# Leg 5 — the report still carries its §0 currency warning. Deleting §0 would restore a
#         document whose Executive Summary recommends the fix leg 4 measures as harmful.
grep -q "WHAT THIS DOCUMENT GOT WRONG" docs/reports/T-501-map-id-remediation-proposal.md
#
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO on a NARROWED package — three fixes, with D1's proposed fix replaced.
The fourth item (always-emit `workflowMeta`) is carved out and remains undecided (IW-0).

> Supersedes the 2026-08-14 DEFER, preserved verbatim at the end of this section. That
> DEFER was right to hesitate and wrong about why: it cites unscoped cost and vendored-build
> risk, when the actual blocker was that nobody had run the derivation against a corpus.
> It has now been run.
>
> It also supersedes the **GO** in `docs/reports/T-501-map-id-remediation-proposal.md`,
> which was written the same day and disagreed with this field. Both are dated 2026-08-14,
> neither cited the other, and the operator would have read them side by side at this gate.
> That report now carries a §0 saying so; nothing under its §0 was edited.

**Rationale:**

The three reported defects are real and still present at v0.10.0, verified line by line.
The reason this is a GO rather than the original GO is that one of the four proposed fixes
would have made things worse, and that only became visible by running it.

1. **D1's fix must not use `deriveSlug()`.** It is a summariser written for node labels —
   first word longer than one character, truncated to 16 — not a slugifier. Over the 14
   corpus documents that actually reach the fallback it produces **4 distinct ids**
   (`process` ×8, `proc` ×4, `id` ×1, `009164cd` ×1), **all of which pass the save
   validator**. Today those same 14 produce 14 ids and all 14 are rejected. The proposed
   fix therefore converts a loud, total, save-time failure into a silent, near-total
   collision — the failure would render as health. Three of the four branches in the
   proposed line are also unreachable: `deriveSlug` is total and never returns falsy.
2. **The correct transform is already in the tree**, at `:9162` in `createFromPendingRef`.
   Applied to the identifier it gives 10 distinct ids and 0 invalid over the same 14. The
   build work is to lift it into a shared helper and call it from all four sites — not to
   author it, which is what the proposal budgeted 30 minutes for.
3. **D2 has three sites, not two** (`:2685`, `:5223`, `:9162`). Unifying two of three
   leaves `renameActiveWorkflow` still able to mint `-cash-sync`.
4. **Collisions are already handled** and stay out of scope: `:9214` appends `_v<n>` and
   writes it back. But that policy is downstream of the transform, so a lossy transform
   turns eight distinguishable documents into `process`, `process_v2` … `process_v8`.
   That is the whole argument for point 1 in one sentence.
5. **The round-trip closure is carved out.** It is the only item that changes bytes the
   editor already writes correctly, and T-308/T-358 byte-identity gates live exactly
   there. Bundling a byte-identity change with a derivation change means one gate failure
   cannot be attributed. IW-0 stays open.

Cost is lower than the proposal estimated for D2 (the function exists) and higher for
verification: the census below is static analysis of *inputs*. Nothing here has driven
`parseBpmnXml` in a browser, so the build task owes a CDP probe over the 14 documents
before any AC is ticked — asserting a fix in source is what this project has spent the
week learning is not the same as asserting it runs.

**Evidence:**

- `src/aef-workflow-designer.html:9950` — `id: aefMetaEl?.getAttribute('id') || procName || 'imported'`. D1 present at v0.10.0.
- `:5223`, `:2685` — the two unguarded sanitizers; `:8433` — the validator they disagree with; `:9162` — the correct rule, already shipping.
- `:1658` — `deriveSlug()`. `deriveSlug('proc_stock_sync') === 'proc'`; `deriveSlug('Cash to Ecwid stock sync') === 'cash'`; `deriveSlug('') === 'node'` (total ⇒ the proposed `||` chain is dead after its first operand).
- Corpus census over 60 documents in `examples/aef-processes/rendered`, `tests/fixtures/aef-bpmn`, `tests/fixtures/third-party`, `tests/fixtures/lane-provenance`: 46 carry `<aef:workflowMeta>`, 14 do not. Current rule → 14 distinct / **14 invalid**. Proposed `deriveSlug` → **4 distinct / 0 invalid**. In-tree `:9162` rule → **10 distinct / 0 invalid**, the only collision being five files that genuinely all declare `<bpmn:process id="Process_1">`.
- Of the 46 documents that do carry `workflowMeta`, **0** have an id failing `/^[a-z0-9][a-z0-9_-]*$/` and **0** have a leading dash or underscore (IW-3, measured rather than reasoned).
- Script and pinned expected output: `docs/reports/T-501-map-id-remediation-proposal.md` §0.1.
- NOT evidence, and excluded: the proposal's "126 of 145" and "145-file sweep" describe the 001-CashWeb tree, which is behind the T-559 boundary and was not read.
- A measurement error of my own is recorded at §0 C-7: the first census pass used a regex instead of an XML parser and under-reported 14 invalid as 7. Re-run with `xml.etree` before any conclusion was drawn.

**If this is a GO, the build work decomposes as (one deliverable each):**

1. Lift `sanitizeWorkflowId()` / `isValidWorkflowId()` into shared helpers; call from `:2685`, `:5223`, `:9162`. No behaviour change intended at `:9162`.
2. Replace the `:9950` derivation with `workflowMeta id → slugify(procId) → slugify(procName) → 'imported'`, plus a CDP probe over the 14 fallback documents asserting distinct-id count and validator pass.
3. Load-time normalisation + one-time notice (D3).

IW-0 (always-emit `workflowMeta`) is not in that list and needs its own decision first.

---

**Superseded 2026-08-14 recommendation, preserved verbatim:**

> **Recommendation:** DEFER
>
> Consumer defect report with three separable root causes well-diagnosed. Need to scope implementation cost and risk to existing exports/vendored builds before recommending GO. The fallback-to-display-name issue is a category error; the sanitizer/validator mismatch affects user-facing behavior; late validation creates poor UX. Evidence: hand-authored BPMN is a real corpus path. Decision depends on testing impact on v0.8.0 already in the wild and round-trip behavior for v0.9+ exports.

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

**Rationale**: Recommendation: GO on a NARROWED package — three fixes, with D1's proposed fix replaced.
The fourth item (always-emit `workflowMeta`) is carved out and remains undecided (IW-0).

> Supersedes the 2026-08-14 DEFER, preserved verbatim at the end of this section. That
> DEFER was right to hesitate and wrong about why: it cites unscoped cost and vendored-build
> risk, when the actual blocker was that nobody had run the derivation against a corpus.
> It has now been run.
>
> It also supersedes the GO in `docs/reports/T-501-map-id-remediation-proposal.md`,
> which was written the same day and disagreed with this field. Both are dated 2026-08-14,
> neither cited the other, and the operator would have read them side by side at this gate.
> That report now carries a §0 saying so; nothing under its §0 was edited.

Rationale:

The three reported defects are real and still present at v0.10.0, verified line by line.
The reason this is a GO rather than the original GO is that one of the four proposed fixes
would have made things worse, and that only became visible by running it.

1. D1's fix must not use `deriveSlug()`. It is a summariser written for node labels —
   first word longer than one character, truncated to 16 — not a slugifier. Over the 14
   corpus documents that actually reach the fallback it produces 4 distinct ids
   (`process` ×8, `proc` ×4, `id` ×1, `009164cd` ×1), all of which pass the save
   validator. Today those same 14 produce 14 ids and all 14 are rejected. The proposed
   fix therefore converts a loud, total, save-time failure into a silent, near-total
   collision — the failure would render as health. Three of the four branches in the
   proposed line are also unreachable: `deriveSlug` is total and never returns falsy.
2. The correct transform is already in the tree, at `:9162` in `createFromPendingRef`.
   Applied to the identifier it gives 10 distinct ids and 0 invalid over the same 14. The
   build work is to lift it into a shared helper and call it from all four sites — not to
   author it, which is what the proposal budgeted 30 minutes for.
3. D2 has three sites, not two (`:2685`, `:5223`, `:9162`). Unifying two of three
   leaves `renameActiveWorkflow` still able to mint `-cash-sync`.
4. Collisions are already handled and stay out of scope: `:9214` appends `_v<n>` and
   writes it back. But that policy is downstream of the transform, so a lossy transform
   turns eight distinguishable documents into `process`, `process_v2` … `process_v8`.
   That is the whole argument for point 1 in one sentence.
5. The round-trip closure is carved out. It is the only item that changes bytes the
   editor already writes correctly, and T-308/T-358 byte-identity gates live exactly
   there. Bundling a byte-identity change with a derivation change means one gate failure
   cannot be attributed. IW-0 stays open.

Cost is lower than the proposal estimated for D2 (the function exists) and higher for
verification: the census below is static analysis of inputs. Nothing here has driven
`parseBpmnXml` in a browser, so the build task owes a CDP probe over the 14 documents
before any AC is ticked — asserting a fix in source is what this project has spent the
week learning is not the same as asserting it runs.

Evidence:

- `src/aef-workflow-designer.html:9950` — `id: aefMetaEl?.getAttribute('id') || procName || 'imported'`. D1 present at v0.10.0.
- `:5223`, `:2685` — the two unguarded sanitizers; `:8433` — the validator they disagree with; `:9162` — the correct rule, already shipping.
- `:1658` — `deriveSlug()`. `deriveSlug('proc_stock_sync') === 'proc'`; `deriveSlug('Cash to Ecwid stock sync') === 'cash'`; `deriveSlug('') === 'node'` (total ⇒ the proposed `||` chain is dead after its first operand).
- Corpus census over 60 documents in `examples/aef-processes/rendered`, `tests/fixtures/aef-bpmn`, `tests/fixtures/third-party`, `tests/fixtures/lane-provenance`: 46 carry `<aef:workflowMeta>`, 14 do not. Current rule → 14 distinct / 14 invalid. Proposed `deriveSlug` → 4 distinct / 0 invalid. In-tree `:9162` rule → 10 distinct / 0 invalid, the only collision being five files that genuinely all declare `<bpmn:process id="Process_1">`.
- Of the 46 documents that do carry `workflowMeta`, 0 have an id failing `/^[a-z0-9][a-z0-9_-]$/` and 0 have a leading dash or underscore (IW-3, measured rather than reasoned).
- Script and pinned expected output: `docs/reports/T-501-map-id-remediation-proposal.md` §0.1.
- NOT evidence, and excluded: the proposal's "126 of 145" and "145-file sweep" describe the 001-CashWeb tree, which is behind the T-559 boundary and was not read.
- A measurement error of my own is recorded at §0 C-7: the first census pass used a regex instead of an XML parser and under-reported 14 invalid as 7. Re-run with `xml.etree` before any conclusion was drawn.

If this is a GO, the build work decomposes as (one deliverable each):

1. Lift `sanitizeWorkflowId()` / `isValidWorkflowId()` into shared helpers; call from `:2685`, `:5223`, `:9162`. No behaviour change intended at `:9162`.
2. Replace the `:9950` derivation with `workflowMeta id → slugify(procId) → slugify(procName) → 'imported'`, plus a CDP probe over the 14 fallback documents asserting distinct-id count and validator pass.
3. Load-time normalisation + one-time notice (D3).

IW-0 (always-emit `workflowMeta`) is not in that list and needs its own decision first.

---

Superseded 2026-08-14 recommendation, preserved verbatim:

> Recommendation: DEFER
>
> Consumer defect report with three separable root causes well-diagnosed. Need to scope implementation cost and risk to existing exports/vendored builds before recommending GO. The fallback-to-display-name issue is a category error; the sanitizer/validator mismatch affects user-facing behavior; late validation creates poor UX. Evidence: hand-authored BPMN is a real corpus path. Decision depends on testing impact on v0.8.0 already in the wild and round-trip behavior for v0.9+ exports.

**Date**: 2026-08-20T09:15:09Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-08-14T16:57:57Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-08-20T09:15:09Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO on a NARROWED package — three fixes, with D1's proposed fix replaced.
The fourth item (always-emit `workflowMeta`) is carved out and remains undecided (IW-0).

> Supersedes the 2026-08-14 DEFER, preserved verbatim at the end of this section. That
> DEFER was right to hesitate and wrong about why: it cites unscoped cost and vendored-build
> risk, when the actual blocker was that nobody had run the derivation against a corpus.
> It has now been run.
>
> It also supersedes the GO in `docs/reports/T-501-map-id-remediation-proposal.md`,
> which was written the same day and disagreed with this field. Both are dated 2026-08-14,
> neither cited the other, and the operator would have read them side by side at this gate.
> That report now carries a §0 saying so; nothing under its §0 was edited.

Rationale:

The three reported defects are real and still present at v0.10.0, verified line by line.
The reason this is a GO rather than the original GO is that one of the four proposed fixes
would have made things worse, and that only became visible by running it.

1. D1's fix must not use `deriveSlug()`. It is a summariser written for node labels —
   first word longer than one character, truncated to 16 — not a slugifier. Over the 14
   corpus documents that actually reach the fallback it produces 4 distinct ids
   (`process` ×8, `proc` ×4, `id` ×1, `009164cd` ×1), all of which pass the save
   validator. Today those same 14 produce 14 ids and all 14 are rejected. The proposed
   fix therefore converts a loud, total, save-time failure into a silent, near-total
   collision — the failure would render as health. Three of the four branches in the
   proposed line are also unreachable: `deriveSlug` is total and never returns falsy.
2. The correct transform is already in the tree, at `:9162` in `createFromPendingRef`.
   Applied to the identifier it gives 10 distinct ids and 0 invalid over the same 14. The
   build work is to lift it into a shared helper and call it from all four sites — not to
   author it, which is what the proposal budgeted 30 minutes for.
3. D2 has three sites, not two (`:2685`, `:5223`, `:9162`). Unifying two of three
   leaves `renameActiveWorkflow` still able to mint `-cash-sync`.
4. Collisions are already handled and stay out of scope: `:9214` appends `_v<n>` and
   writes it back. But that policy is downstream of the transform, so a lossy transform
   turns eight distinguishable documents into `process`, `process_v2` … `process_v8`.
   That is the whole argument for point 1 in one sentence.
5. The round-trip closure is carved out. It is the only item that changes bytes the
   editor already writes correctly, and T-308/T-358 byte-identity gates live exactly
   there. Bundling a byte-identity change with a derivation change means one gate failure
   cannot be attributed. IW-0 stays open.

Cost is lower than the proposal estimated for D2 (the function exists) and higher for
verification: the census below is static analysis of inputs. Nothing here has driven
`parseBpmnXml` in a browser, so the build task owes a CDP probe over the 14 documents
before any AC is ticked — asserting a fix in source is what this project has spent the
week learning is not the same as asserting it runs.

Evidence:

- `src/aef-workflow-designer.html:9950` — `id: aefMetaEl?.getAttribute('id') || procName || 'imported'`. D1 present at v0.10.0.
- `:5223`, `:2685` — the two unguarded sanitizers; `:8433` — the validator they disagree with; `:9162` — the correct rule, already shipping.
- `:1658` — `deriveSlug()`. `deriveSlug('proc_stock_sync') === 'proc'`; `deriveSlug('Cash to Ecwid stock sync') === 'cash'`; `deriveSlug('') === 'node'` (total ⇒ the proposed `||` chain is dead after its first operand).
- Corpus census over 60 documents in `examples/aef-processes/rendered`, `tests/fixtures/aef-bpmn`, `tests/fixtures/third-party`, `tests/fixtures/lane-provenance`: 46 carry `<aef:workflowMeta>`, 14 do not. Current rule → 14 distinct / 14 invalid. Proposed `deriveSlug` → 4 distinct / 0 invalid. In-tree `:9162` rule → 10 distinct / 0 invalid, the only collision being five files that genuinely all declare `<bpmn:process id="Process_1">`.
- Of the 46 documents that do carry `workflowMeta`, 0 have an id failing `/^[a-z0-9][a-z0-9_-]$/` and 0 have a leading dash or underscore (IW-3, measured rather than reasoned).
- Script and pinned expected output: `docs/reports/T-501-map-id-remediation-proposal.md` §0.1.
- NOT evidence, and excluded: the proposal's "126 of 145" and "145-file sweep" describe the 001-CashWeb tree, which is behind the T-559 boundary and was not read.
- A measurement error of my own is recorded at §0 C-7: the first census pass used a regex instead of an XML parser and under-reported 14 invalid as 7. Re-run with `xml.etree` before any conclusion was drawn.

If this is a GO, the build work decomposes as (one deliverable each):

1. Lift `sanitizeWorkflowId()` / `isValidWorkflowId()` into shared helpers; call from `:2685`, `:5223`, `:9162`. No behaviour change intended at `:9162`.
2. Replace the `:9950` derivation with `workflowMeta id → slugify(procId) → slugify(procName) → 'imported'`, plus a CDP probe over the 14 fallback documents asserting distinct-id count and validator pass.
3. Load-time normalisation + one-time notice (D3).

IW-0 (always-emit `workflowMeta`) is not in that list and needs its own decision first.

---

Superseded 2026-08-14 recommendation, preserved verbatim:

> Recommendation: DEFER
>
> Consumer defect report with three separable root causes well-diagnosed. Need to scope implementation cost and risk to existing exports/vendored builds before recommending GO. The fallback-to-display-name issue is a category error; the sanitizer/validator mismatch affects user-facing behavior; late validation creates poor UX. Evidence: hand-authored BPMN is a real corpus path. Decision depends on testing impact on v0.8.0 already in the wild and round-trip behavior for v0.9+ exports.
