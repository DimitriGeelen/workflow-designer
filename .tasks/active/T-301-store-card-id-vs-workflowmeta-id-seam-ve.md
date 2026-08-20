---
id: T-301
name: "Store-card id vs workflowMeta id seam: Versions panel empty and save forks
  a new project"
description: >
  Operator field observation (2026-07-29, 0.8.0, T-101 review): loading store card
  t101-review-audit-process (2 versions) showed an EMPTY Versions panel, and Save
  to project created a NEW project audit-process v1 - the editor keys versions+save
  to workflowMeta.id, not the loaded store id. T-264-adjacent save-target class. One
  question: which identity should the Versions panel and save target adopt when a
  store project id differs from the map internal id?

status: started-work
workflow_type: inception
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-29T08:45:56Z
last_update: 2026-08-20T01:12:46Z
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
  - ts: '2026-08-16T12:33:27Z'
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
  - ts: '2026-08-16T14:33:01Z'
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
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=6 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-301: Store-card id vs workflowMeta id seam: Versions panel empty and save forks a new project

## Problem Statement

Two identities name the same map and only a convention keeps them equal.

The **store card id** is the file stem: the project browser fetches `rendered/<m.id>.bpmn`
and `/api/version?id=<m.id>`, and the server keys versions by it. The **document id** is
`state.workflowMeta.id`, derived inside `parseBpmnXml` from the document's own bytes.

`openProjectMap(m)` (`src/aef-workflow-designer.html:8756`) fetches by the card id and then
hands the bytes to `adoptImportedXml(text, {replace:true, userImport:true})`, which re-derives
the id from the document and sets `activeKey` to *that*. From then on the card id is gone:

- `openVersionsModal` (`:8588`) fetches `/api/versions?id=state.workflowMeta.id` → **empty panel**
- `saveToProject` (`:8467`) POSTs `{id: state.workflowMeta.id}` → **a new project record**

One divergence, both reported symptoms, and nothing in between notices. T-264's load-source
mismatch confirm does not fire here: it is guarded by `_loadSrcKey != null`, which the `?load`
deep-link path sets and this path does not (`tests/test_t264_save_target_guards.py:19` covers
the deep-link stem mismatch only).

**But it is not currently reachable, and that is the finding.** Measured over both served
corpora — `examples/aef-processes/rendered` (24) and `build/gallery/rendered` (25) — **zero
documents have `workflowMeta.id != stem`.** One gallery document, `customer-refund.bpmn`, has
no `<aef:workflowMeta>` at all and derives its id from `<bpmn:process name>`; it comes out as
`customer-refund`, equal to its stem by luck.

So the invariant `stem == workflowMeta.id` is load-bearing, currently true, and **asserted
nowhere.**

## Coupling to T-501 — the proposed fix there would activate the defect here

T-501's remediation proposal derives identity via `deriveSlug(procId)`.
`deriveSlug('customer-refund') === 'customer'` (verified). That single gallery document is
the only one whose id is not pinned by a `workflowMeta` element, so under the T-501 proposal
its document id becomes `customer` while its store card stays `customer-refund` — and the
chain above fires for the first time: Versions panel empty, save forks `customer`.

Neither task's write-up mentions the other. T-501 is triaged as an import-path defect and
T-301 as a store-seam defect; the corpus is one file away from them being the same incident.
This is why T-501's revised recommendation replaces that transform, and it is an independent
second reason to.

## Assumptions

- **A1 — The card id and the document id can diverge.** TESTED, HOLDS structurally: the open
  path discards the card id and re-derives from bytes. No code keeps them in step.
- **A2 — They currently DO diverge somewhere in the store.** TESTED, **FALSIFIED — but only
  after I corrected the population I was measuring.** First pass measured the two `rendered/`
  roots (49 documents, 0 divergent) and I was ready to write "not reachable". This task's own
  2026-08-14 recommendation names a live instance I had not looked for: store card
  `t101-review-audit-process`, 2 versions, opening with an empty Versions panel and forking
  `audit-process v1`. That is a card in `.editor-versions/`, not in `rendered/` — a different
  population, and the one the symptom actually lives in. Re-measured: **24 store cards, 0
  divergent**, and no `t101-review-audit-process` card exists any more. So the answer survives
  the correction, and the correction is recorded because a measurement that scopes the wrong
  population and comes out clean is indistinguishable from one that scoped the right one.
- **A2b — Nothing can produce the divergence.** **FALSIFIED, by the instance above.** The
  editor cannot create it: every path that writes a card writes `workflowMeta.id` as the key.
  A *store-level* copy or rename can, and did — `t101-review-audit-process` was a review copy
  of `audit-process` whose stored bytes still said `audit-process`. The workaround the
  2026-08-14 note recommends (rename review-copy store ids to match) is what removed it. So
  the reachable population is "cards created outside the editor", which is exactly the
  population no editor-side guard can constrain.
- **A3 — The two symptoms have one root cause.** TESTED, HOLDS. Both read
  `state.workflowMeta.id` after `adoptImportedXml` has overwritten it.
- **A4 — T-264's guard already covers this.** TESTED, **FALSIFIED.** It is gated on
  `_loadSrcKey`, which only the `?load` deep-link path sets.

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

<!-- Filed 2026-08-20 BEFORE any investigation, because the G-067 gate blocked Bash until
     they existed. That ordering is the point: these are what the title asserts, written
     down as questions so the answers can contradict them. The title states two symptoms
     and one cause; whether the cause is one cause or two is IW-3. -->

- **IW-1: Is the Versions panel empty because the store card's id differs from `workflowMeta.id`?**
  confidence: 3
  disposition: answered
  rationale: YES structurally — `openVersionsModal` (`:8588`) queries
    `/api/versions?id=state.workflowMeta.id`, which `openProjectMap` → `adoptImportedXml` has
    already re-derived from the document bytes, discarding the `m.id` it fetched by. But 0 of
    49 served documents currently diverge, so the panel is not empty for anyone today.

- **IW-2: Does saving fork a NEW project record rather than updating the existing one, and if so at which write?**
  confidence: 3
  disposition: answered
  rationale: YES, at `saveToProject` (`:8467`), which POSTs `{id: state.workflowMeta.id}`.
    Same divergence, same moment. Not reachable today for the same reason as IW-1.

- **IW-3: Are these one defect or two?**
  confidence: 3
  disposition: answered
  rationale: ONE. Both read `state.workflowMeta.id` after `adoptImportedXml` overwrote it with
    a value derived from bytes rather than from the card that was opened. One build task, not
    two — the title's two symptoms are one line of causality.

- **IW-4: Is there a second identity authority, contrary to the T-263 ruling?**
  confidence: 3
  disposition: answered
  rationale: YES, and naming it is the useful output of this inception. T-263 ruled
    `workflowMeta.id` is the save target and there is no second identity authority. In practice
    the file stem IS one: the server keys versions by it, the browser fetches
    `rendered/<stem>.bpmn` by it, and the delete/thumb/list surfaces all use it. The ruling
    holds only while `stem == workflowMeta.id`, an invariant that is currently true across all
    49 served documents and **asserted nowhere.** T-263 did not create a single authority; it
    declared which of two wins, and left the agreement between them unguarded.

- **IW-5: Does the T-501 remediation proposal change the answer to IW-2?** (filed during exploration)
  confidence: 3
  disposition: answered
  rationale: YES. `deriveSlug('customer-refund') === 'customer'`, and `customer-refund.bpmn` is
    the single served document with no `<aef:workflowMeta>` to pin its id. Adopting T-501's
    drafted `deriveSlug` fix makes this defect reachable for the first time, on that file,
    silently. The two tasks are coupled and neither write-up said so.

## Exploration Plan

Executed 2026-08-20, ~35 min, static analysis only. No source edited.

1. Trace both symptoms to the id they read. DONE — `:8588` and `:8467`, same expression.
2. Establish where the card id is lost. DONE — `openProjectMap` (`:8756`) fetches by `m.id`
   then lets `adoptImportedXml` re-derive.
3. Check whether an existing guard covers it. DONE — T-264's does not (`_loadSrcKey` gate).
4. **Measure reachability before recommending anything.** DONE — 0 of 49. This is the step
   that changed the recommendation from "fix the bug" to "assert the invariant".

## Technical Constraints

- Static analysis only. Nothing here drove the editor in a browser; the causal chain is read
  from source and the corpus figures are read from files. A build task owes a CDP probe that
  opens a card whose stem differs from its `workflowMeta.id` and observes both symptoms —
  and no such document exists today, so the probe must synthesise one.
- The invariant is enforceable cheaply on the *corpus* (a file check) and expensively in the
  *editor* (a browser probe). Those are different guarantees and a build task should not
  claim the second by shipping the first.

## Scope Fence

IN: asserting `stem == workflowMeta.id` across the served corpora; deciding whether
`openProjectMap` should carry the card id forward.

OUT: changing the T-263 ruling (that is a standard question, not a bug fix); the T-501
derivation change, which is its own task and its own operator decision.

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
#
# Leg 1 — the divergence census the recommendation rests on. Prints the three populations and
# the divergent count; the grep pins ZERO. If a divergent card appears between now and the
# ruling, this goes red rather than letting "not reachable today" stand unexamined. Note it
# is deliberately NOT the corpus gate the recommendation proposes building — that gate belongs
# to the build task and must fail the SUITE, not one task's completion.
python3 -c "import os,glob,xml.etree.ElementTree as ET; wid=lambda p:(lambda m:(m[0].get('id') if m else None))([e for e in ET.parse(p).getroot().iter() if e.tag.endswith('workflowMeta')]); R=[(os.path.basename(p)[:-5],wid(p)) for r in ['examples/aef-processes/rendered','build/gallery/rendered'] for p in sorted(glob.glob(os.path.join(r,'*.bpmn')))]; C=[(d,wid(sorted(glob.glob(os.path.join('.editor-versions',d,'*.bpmn')))[-1])) for d in sorted(os.listdir('.editor-versions')) if os.path.isdir(os.path.join('.editor-versions',d)) and not d.startswith('_') and glob.glob(os.path.join('.editor-versions',d,'*.bpmn'))]; bad=[x for x in R+C if x[1] is not None and x[1]!=x[0]]; print('RENDERED=%d CARDS=%d DIVERGENT=%d %s' % (len(R),len(C),len(bad),bad))" > /tmp/.t301-census 2>&1 && grep -q "DIVERGENT=0 \[\]" /tmp/.t301-census
# Leg 2 — the coupling to T-501 is still live: the one served document with no workflowMeta
# is still there, and the transform T-501 proposes still collapses its stem. If either stops
# being true, IW-5's rationale is stale and the recommendation's point 4 must be re-argued.
test -f build/gallery/rendered/customer-refund.bpmn && ! grep -q "workflowMeta" build/gallery/rendered/customer-refund.bpmn
node -e "const d=s=>{if(!s)return 'node';const w=s.toLowerCase().replace(/[^a-z0-9\s\-]/g,' ').split(/[\s\-]+/).filter(x=>x.length>1);return (w[0]||'node').slice(0,16)}; process.exit(d('customer-refund')==='customer'?0:1)"
# Leg 3 — the read and write sites still read the document id, which is what makes them one
# defect (IW-3). If either is changed to carry the card id, this inception is answered by code.
grep -qF 'fetch(`/api/versions?id=${encodeURIComponent(id)}`)' src/aef-workflow-designer.html && grep -qF 'JSON.stringify({ id, bpmn, png, note })' src/aef-workflow-designer.html
#
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO, but on a smaller and different thing than the title asks for — assert
the invariant, do not chase the symptom.

> Supersedes the 2026-08-14 DEFER, preserved verbatim below. That DEFER was correct on
> urgency and its named instance is now gone; what it did not have is the reachability
> measurement or the T-501 coupling, and the second one changes the urgency.

**Rationale:**

1. **The causal chain is real and complete** — `openProjectMap` fetches by card id, then lets
   `adoptImportedXml` re-derive the id from bytes; `openVersionsModal` and `saveToProject`
   both read the re-derived value. One divergence, both symptoms (IW-3).
2. **It is not reachable today.** 0 divergences across 49 rendered documents and 24 store
   cards. The named instance has been cleaned up.
3. **The editor cannot produce it; the store can.** Every editor write path keys the card by
   `workflowMeta.id`. `t101-review-audit-process` was made by copying at the store level. So
   an editor-side fix guards the path that was never the source, and the honest guard is a
   corpus check: `stem == workflowMeta.id` for every card and every rendered document. That
   check would have caught the reported instance the day it appeared, costs one file walk,
   and is the only thing here that is cheap *and* catches the real producer.
4. **T-501 makes it reachable, silently** (IW-5). `deriveSlug('customer-refund') === 'customer'`
   and `customer-refund.bpmn` is the one served document with no `workflowMeta` to pin its id.
   If T-501's drafted fix ships, this defect fires on that file for the first time. That is
   the argument for landing the invariant check *before* any T-501 build task, not after.
5. **The T-263 question is real but is not a bug** (IW-4). The file stem is a second identity
   authority in practice. T-263 declared which one wins; it did not remove the other or
   require them to agree. Reopening that is a standard-level decision and belongs in its own
   inception, not smuggled into a fix for an empty panel.

**Proposed build scope (one deliverable):** a corpus check asserting `stem == workflowMeta.id`
across `examples/aef-processes/rendered`, `build/gallery/rendered` and `.editor-versions/*/`,
wired into `tests/run-bridge-tests.sh`, with a fixture that synthesises a divergent card and
requires it to be caught. Explicitly NOT: changing `openProjectMap`, changing T-263, or
carrying the card id through `adoptImportedXml` — all three are larger, and none of them
addresses the producer.

**Evidence:**

- `src/aef-workflow-designer.html:8756` `openProjectMap` fetches `m.id`, adopts, discards it.
- `:8588` versions read, `:8467` save write — both `state.workflowMeta.id`.
- `:9214` `adoptImportedXml` sets `activeKey` from the document, not from the caller.
- T-264's guard is gated on `_loadSrcKey`, unset on this path; `tests/test_t264_save_target_guards.py:19` covers the deep-link case only.
- Divergence census: 24 + 25 rendered documents, 24 store cards, **0 divergent**.
- `deriveSlug('customer-refund') === 'customer'` (node, verified); `build/gallery/rendered/customer-refund.bpmn` has no `<aef:workflowMeta>`.

---

**Superseded 2026-08-14 recommendation, preserved verbatim:**

> **Recommendation:** DEFER
>
> Real coherence gap, low urgency: the editor keys Versions+save to workflowMeta.id, so a store card whose id differs (t101-review-audit-process, 2 versions) opens with an empty Versions panel and Save forks a new project (audit-process v1, byte-equal modulo one aef:anchors line — no data loss). Workaround exists (name review-copy store ids to match the map id); operator review queue is already deep; decide identity semantics when the next save-target round (T-264 class) opens.

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

## Reviewer Verdict (v1.5)

- **Scan ID:** R-93a094a2
- **Timestamp:** 2026-07-29T13:13:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-6922acf5
- **Timestamp:** 2026-07-29T13:13:46Z
- **Overall:** CONFIRMED
- **Claims:** 1

| Claim | Type | Status |
|-------|------|--------|
| `T-264` | task | ✓ pass |

### 2026-08-20T01:12:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-08-20T01:12:46Z — status-update [task-update-agent]
- **Change:** horizon: now → now
