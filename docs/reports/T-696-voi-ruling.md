# T-696 — advisory for the `voi_score` ruling, and the bandwidth question behind it

**Status:** advice, not a decision. The ruling is the operator's.
**Written:** 2026-09-26, run 9 of the procAsFit mandate, at operator request.
**Decision required:** one letter — A / B / C / D / no-repair — recorded in T-696 `## Decision`.

---

## 1. The defect, measured

`int(round(0.5 * 5)) = 2`, and an absent `voi_score` also returns 2 via the grandfathered
path (`estimator.py:2441-2450`). So **"nobody assessed this"** and **"judged exactly mid"**
are the same number. Both land in `hv-lc` — Q1 — which a work-Q1-first rule drains *before*
any measured high-value task.

The recurrence instrument (`tools/_t696-voi-recurrence.py`) over 28 days:

| date | at template default | ratio |
|---|---|---|
| 2026-08-29 (T-624 filed) | 38/41 | 93% |
| 2026-09-19 (baseline recorded) | 40/43 | 93% |
| 2026-09-26 (today) | 42/45 | 93% |

The population grew by four; **all four arrived at the default.** 16 active inceptions.

T-624's chosen prevention was a warning in the template, directly above the field —
emphatic, correct, and it has moved the number by **zero** in 28 days. That is the finding
T-696 was retargeted onto: *a comment is not a gate.*

---

## 2. The structural point that reorders the menu

**A is not a competitor to B, C and D. It is a precondition for them.**

B changes the *grandfathered* path, which fires only when `voi_score` is **absent**. The
template pre-fills `0.5`, so almost nothing is absent — **B without A is close to a no-op.**
D must detect "unassessed" in order to bucket it. C must know which tasks to propose for.
All three need absence to mean absence, and only A delivers that.

This was not visible in the menu as written. The decision is therefore not "one of five" but
**"A, plus what"**.

---

## 3. Strawman / steelman

### A — stop shipping `voi_score` pre-filled
- **Strawman:** deleting a default. The 42 existing tasks keep their stale `0.5`, the 93%
  does not move, and we have achieved cosmetics.
- **Steelman:** 93% is an **inflow** problem — every inception created in the last 7 days
  arrived at the default. A pre-filled field is the system answering on the author's behalf
  and then recording it as their judgement. Removing it turns a silent fabrication into an
  honest gap, and unlocks the other three options.

### B — unassessed ranks 0
- **Strawman:** bury work nobody scored; cruel, and it hides urgent things.
- **Steelman:** unmeasured work should not outrank measured work, and neglect should carry a
  visible cost.
- **Decisive objection:** **B repeats the exact error T-3068 diagnosed, mirrored.** T-3068
  found that scoring unknown as `0` on a *cost* term made it read as *attractive*; scoring
  unknown as `0` on a *value* term makes it read as *worthless*. Same conflation of "no
  evidence" with "evidence of none", opposite sign. That shape has already been ruled on once.

### C — a `_proposed:` lane for `voi_score` and `target_blast_radius`
- **Strawman:** let the robot score its own homework.
- **Steelman:** it is precisely the pattern already ratified for the D-drivers and for cost —
  estimator proposes, human confirms, proposal clears on confirm. Best ergonomics of the five:
  review a number rather than invent one.
- **Objection that moved this session:** C's safety rests on `confirm` being a *human* gate.
  With `BVP_AUTO_CONFIRM=1` (operator ruling, T-856) it is not, for `bvp_scores`. A
  `_proposed` lane for `voi_score` most likely becomes *the agent sets `voi_score`* — on a
  field CLAUDE.md names operator-only. **C now silently answers a second sovereignty
  question.** It is a good design whose premise changed underneath it.

### D — unassessed as a distinct state, outside the quadrant grid
- **Strawman:** add a bucket nobody looks at; work vanishes from the board.
- **Steelman:** this is **T-3105**, the project's own ratified pattern — `NOT EVALUATED`
  rather than a vacuous PASS. `fw audit` already does exactly this ("the check ran and found
  nothing, because there was nothing to look at; a PASS would assert coverage the check does
  not have"). Applying it to `voi_score` is *consistency, not novelty*. It neither inflates to
  2 nor deflates to 0 — it declines to rank on absent data.
- **Requires:** the bucket must be counted somewhere, or it rots unseen.

### No repair
- **Strawman:** do nothing.
- **Steelman:** `0.5`-as-mid is a defensible prior, and the tie only bites under a strict
  Q1-first rule — a property of *the mandate*, not of the project. Changing the prompt is
  cheaper than changing the scoring model, and T-624 already burned one premature repair.
- **Objection:** "tell the mandate to treat `hv-lc` inceptions as unranked" **is** a repair —
  one living in prompt text rather than in code, which is strictly worse for auditability.
  And 28 days flat at 93%, with the warning in place, is evidence the inflow will not
  self-correct.

---

## 4. Ranked against the four directives

Scores are the author's judgement on 0-5, weighted by the project's ratified driver weights
(`policy/value-drivers.yaml`): D1 9, D2 7, D3 5, D4 3. **Judgement, not estimator output.**

| option | D1 Antifragility ×9 | D2 Reliability ×7 | D3 Usability ×5 | D4 Portability ×3 | weighted / 120 |
|---|---|---|---|---|---|
| **D** | 5 | 5 | 4 | 3 | **109** |
| **A** | 4 | 5 | 3 | 3 | **95** |
| C | 4 | 3 | 4 | 3 | 86 |
| B | 3 | 2 | 2 | 3 | 60 |
| no repair | 1 | 2 | 2 | 3 | 42 |

D and A lead on **D2** for the same reason: *"no silent failures"* is that directive's literal
text, and both replace a fabricated number with a visible absence. D takes **D1** because a
countable gap is a learning surface, where A alone only stops the bleeding. B loses D2
precisely because it substitutes one silent misrepresentation for another.

---

## 5. Advice

**Take A + D as a single change.**

- **A** stops the inflow and makes absence mean absence.
- **D** makes absence visible and unrankable, using the abstention pattern this project has
  already ratified (T-3105) and already runs in `fw audit`.

Together they are that pattern applied end to end. Both are reversible. Neither decides
anything else.

- **Do not take B** — it re-commits T-3068's error in the mirror.
- **Defer C** until the `BVP_AUTO_CONFIRM` interaction is settled. Good design, moved premise.

---

## 6. Why this decision is smaller than it looks — the bandwidth question

The ranking that `voi_score` feeds is **already blind on the axes that matter most to the
stated objective.**

`policy/value-drivers.yaml` declares 63 weight units. Three free drivers have neither a
handler nor a scoring spec, so the estimator emits `unscored … not counted` for each and
drops them from the denominator (T-3427):

| driver | weight | scoreable |
|---|---|---|
| D1 Antifragility | 9 | yes |
| D2 Reliability | 7 | yes |
| D3 Usability | 5 | yes |
| D4 Portability | 3 | yes |
| F-RECALL Recall Leverage | 6 | yes |
| F2 V_COMPONENT_FABRIC | 6 | yes |
| **F1 V_SDLC_ENABLEMENT** | **9** | **NO** |
| **F3 V_AEF_INTEGRATION** | **9** | **NO** |
| **F4 V_WORKFLOW_ROUTING** | **9** | **NO** |

**27 of 63 units — 43% — cannot be scored.** Verified from live output, not inferred: T-862's
own rationale reads `F4=? (unscored…); F3=? (unscored…); F1=? (unscored…)`, and its
BVP of 97 over a denominator of 180 (= 36 × 5) reproduces the printed NORM of 0.54 exactly.

Now read the two lists against the yardstick — *"the workflow designer and its integration
with AEF, and our ability to facilitate agent and human collaboration to iterate from the
workflow to actual working applications."*

- The **six drivers that score** are framework-internal quality axes: antifragility,
  reliability, usability, portability, recall, component fabric.
- The **three that do not** are SDLC enablement, AEF integration, and workflow routing —
  precisely the axes on which *product* work would earn its rank.

**So the ranking is structurally incapable of seeing product value.** Remediation work scores
on axes that work; designer and AEF-integration work would score on axes that are dead. This
is not a preference anyone expressed and not a bias in the scorer — it is an artefact of three
unimplemented handlers, and it has been silently shaping every selection decision.

It also explains an observed pattern rather than leaving it as an impression: **three
consecutive runs of this mandate have terminated in Q1 remediation without touching designer
code.** Each selection was correct given the ranking. The ranking was measuring 57% of the
model.

### The Sovereign question this raises (filed as OBS-397)

Two parts, and the second is the one that needs a human:

1. **Mechanical:** give F1, F3 and F4 scoring specs, so the model measures what it declares.
   The audit already prints the remedy (`bin/fw bvp driver --validate-scoring <file>`).
   Drafting the rubric for a value driver is a definition of what the project values, so it
   is proposed here, not performed.
2. **Portfolio:** **how much bandwidth should structural remediation get, against product
   work?** Today the answer is emergent — an artefact of which handlers happen to exist —
   rather than chosen. 196+ pending observations and a 60-task remediation arc compete with
   the designer for the same runs, and nothing anywhere states the intended split.

Until (1) lands, any `voi_score` repair sharpens a lens that is missing 43% of its aperture.
That is an argument for doing A + D anyway — they are cheap and reversible — and against
expecting them to change what the autonomous runs actually pick up.
