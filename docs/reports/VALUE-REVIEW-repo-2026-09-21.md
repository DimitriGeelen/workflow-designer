# Value review — 832-Workflow-designer — 2026-09-21

**Phase 5 report.** Evidence: `VALUE-REVIEW-repo-2026-09-21-evidence.md` (F-1 … F-11).
Classification by a separate JUDGE agent whose only inputs were that file and the confirmed
yardstick.

## 1. Yardstick (confirmed by the operator)

> "The workflow designer and its integration with AEF, and our ability to facilitate the agent
> and human collaboration to iterate from the workflow to actual working applications."

This **overrode** the draft yardstick's centre of mass. Governance/meta work is judged only by
whether it serves that path. Load-bearing drivers: **F3** AEF_INTEGRATION (9), **F4**
WORKFLOW_ROUTING (9), **F1** SDLC_ENABLEMENT (9), **D1** Antifragility (9), **D2** Reliability
(7), **D3** Usability (5).

## 2. Data availability map

Snapshot **2026-09-21T22:01:46Z**, taken before the review generated any usage data.
149 active / 634 completed tasks · 77+741 audit records · 654 handovers · inbox 134 (46 urgent).

**ABSENT (verified):** `policy/capabilities.yaml` · `.context/audits/bvp-realization.jsonl` ·
`fw workflow` verb · dispatch templates · `policy/prompts` · `.context/bus`.
**PARTIAL:** BVP scores (119 proposed, **0 confirmed**) · TermLink traffic (`read_complete:
false`) · read receipts (~3 weeks stale — a channel cannot report its own failures).

## 3. Role setup

GATHERER and JUDGE **separated**. JUDGE ran as an independent agent with no access to the
gathering context. Confidence levels are therefore **not** reduced by the self-judgement
penalty. Both roles are the same model family — recorded as a residual limitation.

## 4. Baseline

| suite | state |
|---|---|
| `tests/run-validator-tests.sh` | **54 passed, 0 failed** |
| `tests/test_forward_fixtures.py` | **19 fixtures conformant, exit 0** |
| `tools/_t400-schema-teeth.sh` | was rc=1 → **fixed this session, 10/10** |
| `tools/_t560-absence-census-teeth.py` | **RED** — ratchet 78 → 112, blocked (see SQ-2) |

## 5. Summary

**KEEP 7 · REFACTOR 4 · ADD 5 · INVESTIGATE 6 · DELETE 0 · Sovereign questions 4**

**Nothing qualifies for DELETE.** Every low-use item resolves to reading A/B/C/D. No item has
a cited positive reason its purpose is no longer needed — and absence of use is never that
reason.

**Top ADD:** surface `fw bvp`/`fw arc` in `fw help` · capability registry · drift check so a
derived standard cannot silently reclass a frozen field.
**Top REFACTOR:** widen `fw verify-acs`'s population · isolate the bridge failure (raise the
280s bound) · the `_t560` ratchet (blocked on SQ-2).

## 6. Findings

| ID | Item | Class | Reading | Conf. | Proposal | Size | Reversible |
|---|---|---|---|---|---|---|---|
| F-1 | `fw bvp`/`fw arc` absent from `fw help` | **ADD(SURFACE)** | C | HIGH | add both to help | S | yes |
| F-2 | `fw verify-acs` vs T-783 tool | **REFACTOR** | C | HIGH | widen verb population beyond `work-completed`; absorb the tool's executed checks, keep its 20 NUDGEs | M | yes |
| F-2b | T-783 tool as standing tool | INVESTIGATE | C | MED | delete only *after* coverage lands in the verb | S | — |
| F-3 | rebuild-what-exists ×2 in one session | **ADD(instrument)** | D | MED | measure recurrence; cause is tooling, not discipline | M | yes |
| F-3b | capability registry absent | **ADD(instrument)** | D | MED | `policy/capabilities.yaml` | M | yes |
| F-4 | 264 `aef:endpoint` refs, 45% unresolved | **NOT WORK — settled** | — | HIGH | do nothing; AEF ruled it cosmetic-as-documented | — | — |
| F-4b | no executor (`fw workflow` absent) | **not 832's** → SQ-1 | B | HIGH | do not build; define consumer-side slice | — | — |
| F-5 | derived doc reclassed a frozen field | **KEEP(fixed)** + ADD | — | HIGH | mechanize the drift check | S | yes |
| F-6/11 | Child-2 is AEF-led and specified | **KEEP** | — | HIGH | — | — | — |
| F-7 | AEF ruling + T-786 correction | **KEEP** | — | HIGH | — | — | — |
| F-8 | every free driver dark (F1 93%, F3 93%, F-AUTONOMY 99%) | **ADD(REPAIR, upstream)** | A | HIGH | AEF's T-3410; locally, stop reading BVP totals as composites | — | — |
| F-8b | 0 of 149 confirmed BVP scores | INVESTIGATE | D | HIGH | G-076 | — | — |
| F-9a | `_t400` schema teeth | **KEEP(fixed)** | — | HIGH | — | — | — |
| F-9b | `_t560` ratchet 78→112 | **REFACTOR (blocked)** | A | HIGH | blocked on SQ-2 | S | yes |
| F-9d | `_t509` exceeds 280s | INVESTIGATE | A | MED | raise/remove the bound so the suite names a cause | S | yes |
| F-10 | 832's 4 bridge deliverables | **KEEP** | — | HIGH | the load-bearing F3 asset, intact | — | — |
| I-1 | bridge baseline red | **REFACTOR** | A | HIGH | compare per-suite, not one aggregate flag | S | yes |
| I-2 | inbox 134 / 46 urgent | INVESTIGATE | D | MED | age-distribution of the urgent 46 | S | — |
| I-3 | realization log absent | INVESTIGATE + ADD | D | HIGH | one closed arc with before/after scores | M | yes |
| I-4 | TermLink receipts dead | INVESTIGATE | A+D | MED | out-of-band probe from a second host | M | yes |

**Expected effects (pre-registered).** F-1: the two verbs appear in help; recurrence of
rebuild-what-exists measurable thereafter. F-2: the 77-AC/62-task queue gains ≥2 auto-evidenced
items without losing the 20 NUDGEs. F-9b: ratchet returns to ≤78 with no baseline raise.

## 7. KEEP

F-5 (corrected), F-6, F-7, F-9a, F-10, F-11, the validator suite.

## 8. INVESTIGATE

F-2b, F-3, F-8b, F-9d, I-2, I-3, I-4 — each with its unlocking datum in §9.

## 9. Data gaps that capped confidence

1. Is AEF's Child-2 translator scheduled or hypothetical? → ask AEF for a delivery position.
2. Which instrument fails in the bridge suite? → one sweep run with the 280s bound removed.
3. Is the 134-item inbox live or abandoned? → age distribution of the 46 urgent.
4. Do arcs deliver? → **no arc has ever closed**; realization log absent. One closed arc with
   before/after driver scores.
5. Does TermLink silence mean anything? → out-of-band probe from a second host.
6. Are `verify-acs`'s 49 REVIEW items unautomatable or unattempted? → sample 5 with their
   Expected clauses.

## 10. Contradictions

- **README vs repo mass** — an editor described; 3207 md / 1915 yaml against 98 html / 80 mjs.
  Resolved by the operator's yardstick; the *allocation* question remains (SQ-3).
- **README's non-goal vs the confirmed yardstick** — "usable without `fw workflow run`" is an
  accepted non-goal in the README; under the yardstick the executor is central. Resolved by
  SQ-1: it is real, and it is AEF's to build.
- **forward-compile §2 vs frozen Part I** — resolved and corrected (T-786).

## 11. Not reviewed

`src/aef-workflow-designer.html` (997 KB) was **never opened or exercised** — the product
itself is unreviewed. `examples/`, `build/gallery/`, `vendor/`, `scripts/`, and the ~90
`tools/_tNNN-*` instruments were inventoried only by name.

> **Superseded for the product, T-789 (2026-09-22).** The editor has now been opened and
> exercised at `/designer/app`. Three things were measured, and they change the shape of this
> review's central worry rather than confirming it:
>
> 1. **It works.** A saved workflow loads, the canvas renders it with lanes, and the console
>    reports **0 errors and 0 warnings**. The palette encodes the authority model directly —
>    Service Task *agent · Initiative*, User Task *human · Sovereignty*, Script Task
>    *fw · Authority* — so the governance model is not bolted on, it is the vocabulary.
> 2. **The corpus is almost entirely fixtures.** 6 saved workflows, of which 4 are
>    `t101-review-*` and 1 is `t293-retest-*`. **One** (`audit-process`) is real content.
> 3. **There is no execution affordance, and that is correct rather than missing.** Every
>    control the editor exposes, enumerated from the DOM: Open project, Pending refs, zoom,
>    Add Lane, Reset, Clean layout, View XML, Settings, Load, Versions, Save to project, Save.
>    Nothing advances a diagram toward executable work. Confirmed at source level — the only
>    two occurrences of `execute` in 997 KB are inside a code comment. This is exactly what
>    the frozen standard specifies (*"No translator is built here"*), so the product is
>    **scoped as designed**, and the yardstick's second half is upstream. That is the question
>    T-788 now has on the wire at `agent-chat-arc` @1630.
>
> One defect found and reproduced: the tab title is a hardcoded literal (`investigate.bpmn`)
> and `document.title` is never assigned anywhere in the file — **OBS-371**. One suspected
> defect was checked and **dissolved**: `t293-retest-harvest` displaying the ID
> `harvest-pipeline` is correct, because the stored bytes genuinely carry that internal id.
>
> The rest of this section stands — `examples/`, `build/gallery/`, `vendor/`, `scripts/` and
> the instruments are still inventoried only by name.

## 12. Sovereign questions

**SQ-1 — Does 832 build any part of the workflow→application executor?**
*Recommendation:* no. The frozen spec is explicit — AEF owns translator, enrichment and gate;
"No translator is built here." Ask AEF for a Child-2 delivery position and define 832's
consumer-side slice instead, which F-10 says is already intact. *Decides:* operator + AEF.

**SQ-2 — May an agent edit a `## Verification` block in `.tasks/completed/`?**
The unchecked `[REVIEW]` on T-353, now load-bearing: `_t560` stays RED until ruled, and a
proven patch set sits unapplied.

> **Correction, T-787 (2026-09-22).** This section said "a proven **16/16** patch set". Run
> on 2026-09-22 `tools/_t353-repair-probe.sh` reported **12 passed, 1 failed** — its fourth
> target was a path in
> an ephemeral scratchpad, copied faithfully from T-299's own archived Verification line, and
> the file had been reaped. The probe was right to refuse (it will not measure the load-error
> path and call it a pattern result); the *citation* was the thing that decayed, having been
> recorded as durable while resting on a file outside the repository. Repaired in T-787: the
> target is now the committed `context-memory.bpmn`, which reproduces the same condition
> (`WARN … 0 error(s)`, zero occurrences of `VALID`), and the probe gained portability,
> substitution and provenance legs. **The honest headline is now 23/23, not 16/16** — the
> instrument changed, so the number had to. The ruling below is unaffected: it was never a
> question about the patch set's correctness.
>
> A second measurement in the same pass: the `_t560` ratchet reads **113**, not the 112
> recorded earlier, and **96 of the 113 are in `.tasks/completed/`**. Only 17 are in
> `active/`. So the ratchet cannot return to its 78 baseline by any edit an agent is
> currently permitted to make — 113 − 17 = 96 > 78. That makes SQ-2 *necessary* to closing
> `_t560`, not merely helpful, which is stronger than this report originally claimed.

*Recommendation:* rule narrowly — permit appending
sibling control legs when a teeth instrument requires it, logged as Tier 2. *Decides:* human
only; no evidence is offered that T-353's Human AC is satisfied.

**SQ-3 — Is the governance centre of mass retained, frozen, or trimmed?**
*Recommendation:* freeze — retain, stop growing, judge each item by whether it serves the
workflow→application path. *Decides:* operator.

**SQ-4 — Are free-driver weights meaningful while detectors are 93–99% dark?**
*Recommendation:* keep the weights as declared intent; suspend treating any BVP total as a
composite until AEF's T-3410 lands. *Decides:* operator.

## 13. Where the JUDGE disagreed with the GATHERER

Recorded because the separation was the point of running it.

1. **F-4's headline over-reached.** "The workflow→application path has no mechanical link at
   any point" assumed `aef:endpoint` was the intended link. It never was. The measurement
   stands; the framing does not. **Accepted — the headline is withdrawn.**
2. **"Baseline is RED" conflates two very different surfaces.** The validator suite is 54/54
   green — that is the Designer's own correctness surface, and it is healthy. The red is
   confined to governance instrument-teeth, two of which reddened on legs this agent added
   today. **Accepted — Phase 6 must compare per-suite, not one aggregate flag.**
3. **F-3 pointed at the agent; the measured cause is the tooling.** `fw help` shows 0
   occurrences of two working verbs. That is a discoverability defect (reading C) and a Level C
   escalation, not agent indiscipline. **Accepted.**
