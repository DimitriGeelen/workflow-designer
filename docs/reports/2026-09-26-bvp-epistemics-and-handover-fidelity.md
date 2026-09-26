# 2026-09-26 — making the value model able to be wrong

**Scope:** one day's work across two themes that turned out to be the same theme.
**Status:** shipped and pushed. Three items await human validation and are marked as such.
**Shared with AEF:** `framework:pickup` offsets 180, 181, 185, 190.

---

## 1. The through-line

Everything below is one defect wearing different clothes: **a mechanism that produces
confident output while having nothing to be wrong about.**

- A handover whose only authored section was overwritten every run — present, complete-looking, empty.
- Three value drivers carrying 27 of 63 weight that could not be scored, silently omitted from every ranking.
- Inception scores where "nobody assessed this" and "judged mid" were the same number.
- Support scores that pattern-match text with no claim behind them.

The last is the root. The BVP method this project scores with pairs every value-driver
table with a **hypothesis**; the framework implemented the arithmetic and not the
epistemics. A support score with no hypothesis can rank, but it **cannot be wrong**,
because there is no claim for it to be wrong about.

---

## 2. What shipped

### 2.1 Handover fidelity — T-862

**Defect (OBS-383, four instances in one day).** `handover.sh` generated the Suggested
First Action as one line and overwrote whatever was there. Hand-enrichment had a shelf
life of exactly one regeneration. Cleanest evidence: commits `cfc7e9ed` → `f98bf459`, one
apart, focus unchanged, **4,982 chars replaced by 7 lines**.

**Fix.** Carry the predecessor's section forward when the focus task is unchanged,
labelled with origin **and age**. Refuses to carry when focus changed or provenance is
unknowable — unknown provenance fails closed.

**Verified in production:** the next real regeneration preserved 4,907 chars under the
banner *"Carried forward from `S-2026-0926-0201` — focus T-737 unchanged, 42m old."*

`.agentic-framework/agents/handover/handover.sh` · `tools/_t862-handover-carry-teeth.sh`

### 2.2 The ranking could not see product value — T-864

**Defect.** F1 `V_SDLC_ENABLEMENT`, F3 `V_AEF_INTEGRATION`, F4 `V_WORKFLOW_ROUTING` — added
by operator directive 2026-08-16 with weight 9 each — carried only a `rationale`. No
rubric, no scorer. The estimator emitted `unscored … not counted` and T-3427 dropped them
from the denominator.

**Every ranking was computed over 36 of 63 weight units — 57%.** The six drivers that did
score are framework-internal quality axes; the three that did not are precisely the axes on
which product work earns its rank. So the model was **structurally incapable of seeing
product value**, and three consecutive autonomous runs ending in framework remediation were
each *correct* against a model measuring 57% of itself.

**Fix.** Declarative `scoring:` specs (T-3428 mechanism, no framework code change) plus the
`rubric:`/`polarity:`/`guardrails:` blocks F2 and F-RECALL already had.

**Measured discrimination** — a scorer firing on everything adds weight without signal:

| task | F1 | F3 | F4 | kind |
|---|---|---|---|---|
| T-358 importer/routing | 3 | 4 | 4 | product |
| T-101 clean layout | 2 | 3 | 2 | product |
| T-341 flowNodeRef | 3 | 0 | 4 | product |
| T-863 fabric subsystems | 1 | 0 | 0 | remediation |
| T-737 handover | 1 | 0 | 0 | remediation |

**Effect after corpus re-score (117 tasks, 72 written):** the top of the ranking went from
four-of-six remediation tasks to designer work — T-309, T-357, T-155, T-358.

`policy/value-drivers.yaml`

### 2.3 Automatic scoring with sticky human overrides — T-865

**Operator direction:** rank everything automatically, take the human out of scoring, keep
a feedback signal — *"but if I want to override it then it should not be overwritten by an
automatic ranking."*

**Defect.** `_score_inception_voi` returned a neutral 2 for an absent `voi_score`, and the
template shipped `0.5`, which also maps to 2. **42 of 45 inceptions ranked on a number no
person chose**, flat at 93% across 28 days despite a warning printed directly above the
field. It also explains the 126/0.40 cluster exactly: an inception scores one value on every
driver, 2 × 63 = 126, ÷315 = 0.40.

**Fix.** Estimated unless a human said otherwise. Two states, no third:

| flag | meaning | auto-overwritable |
|---|---|---|
| `estimated` | machine worked it out | yes, freely |
| `human` | you decided | **never** |

Sticky is what makes re-scoring **safe to run often**, and running it often is the only way
estimates improve. Every human-vs-estimate divergence writes `{human, estimate, delta}`.

**Also fixed here, and it mattered more than the feature:** `_template_lines()` read only
`default.md`, so `inception.md`'s boilerplate was never stripped. A VoI signal keyed on
`'go/no-go'` — a phrase that template ships — scored **11 of 14 inceptions identically**.
Now reads every template, which also silently repaired T-864's specs.

`.agentic-framework/agents/termlink/bvp-estimator/estimator.py` · `tools/_t865-sticky-scoring-teeth.sh`

### 2.4 arc-004 — hypothesis-first inceptions

The canonical form, from the source BVP material:

> *"We believe that **&lt;change&gt;**, we will achieve **&lt;outcome&gt;**. We will know that we are
> successful when we see **&lt;measurable signal&gt;**."*

**S1 (T-866) — the form and the gate.** A fill-in shape in the inception template; a GO
refuses without a hypothesis whose success clause names something checkable.

- Fires on **GO only**. NO-GO and DEFER take on no claim; gating them is bureaucracy, and
  bureaucracy is how a gate loses the legitimacy it needs to refuse the case that matters.
- The observability check is a **stated proxy**: it cannot decide "is this observable", only
  "does this contain anything a person could look at". Foolable deliberately; not foolable
  by the sincere vague clause, which is the failure that occurs.
- **Research exemption** (`inception_kind: research`), because "research how X works"
  produces understanding, not an outcome. Three properties keep it from becoming a hole:
  declared at creation not at decision time; the **field, not the word**; and it announces
  itself so it stays countable.

`.agentic-framework/lib/task-audit.sh` · `.agentic-framework/lib/inception.sh` ·
`.tasks/templates/inception.md` · `tools/_t866-hypothesis-form-teeth.sh`

**S2 (T-867) — drafted, corrected, sticky.** Measured first: of 14 active inceptions ~11
were delivery-shaped and **none** had a hypothesis, so S1 alone was a gate with no ramp.

**The rule:** the drafter must not invent a success clause. A plausible invented metric is
worse than a blank — it satisfies the gate, reads as considered, and commits the project to
a claim nobody made. So the machine does the mechanical two-thirds and **names the gap**
with `[NEEDS YOU: …]`, and the gate still refuses that draft.

`tools/_t867-hypothesis-draft-teeth.sh`

**S3 (T-868) — a score that says what it argues about.** Citation counts **only** for
`hypothesis_source: human`. Once a drafter exists most hypotheses are machine drafts, and a
score citing a draft is the machine citing itself — indirection that reads as provenance and
is none. Every score now states its basis, including:

> `basis: task body — no hypothesis, so this score has no claim to be wrong about`

That sentence is true of every score this project has ever produced. It is now printed.

Verified additive: **483 driver evaluations, 0 score differences** between cited and uncited
paths. Slice boundary recorded in code — D1–D4 keep hand-written handlers.

`tools/_t868-cited-support-teeth.sh`

**T-870 — the backfill.** All 14 active inceptions now carry a hypothesis: **7 with a
proposed observable, 7 honestly marked `[NEEDS YOU]`**. 119 tasks re-scored afterwards, 0
written, ranking byte-identical — fourteen machine-written claims moved zero scores, because
S3 refuses to cite a draft.

**S4 (T-869) — not started.** Measuring the success clause after delivery needs hypotheses
to exist (they now do), something shipped against one, and weeks to pass. Parked openly.

### 2.5 Also shipped

- **T-861** — the instrument sweep detects self-declared broken guards instead of filing
  them as regressions. `tools/_t509-instrument-sweep.sh` · `tools/_t861-selfdeclare-teeth.sh`
- **T-863** — scored Q1, **parked Sovereign-blocked**. `.fabric/subsystems.yaml` can express
  only path globs, but subsystem here is not a function of path (`_tNNN-*.py` spans six
  subsystems), so no admissible rule set exists. The control criterion killed the task during
  read-only discovery for ~25k instead of ~100k.
- **T-696** — partial-complete, recommending closure as **superseded**; its recurrence
  instrument now reports a **false RED** (96%, up from 93%) because it counts frontmatter
  presence rather than effect. Marked superseded in the tool's header; the append-only ledger
  untouched. Successor guard `--prevention-check` is **watched failing** (self-test 10/10).
  `tools/_t696-voi-recurrence.py` · `docs/reports/T-696-voi-ruling.md`

---

## 3. What went wrong, because that is the useful half

Five self-inflicted false greens, all caught before release:

1. **A regex fabricated what the rule forbids.** The drafter's first extraction returned
   `"80% of the"` — meaningless, but it *contains a digit*, so the gate would have accepted
   it. Found by printing all 14 drafts, not by reasoning about the code.
2. **Evidence emitted alongside a value can contradict it.** A mutant changed the signal and
   left the adjacent `ev.append` intact, so the evidence claimed `NEEDS-YOU` while the clause
   carried an invented metric. Now derived from the value.
3. **A test passed on a grep usage error.** A pattern beginning with `-` made grep exit
   non-zero; a leading `!` turned that into a PASS.
4. **A vacuous assertion.** "Human value is never overwritten", proven by byte-identity —
   which passed under the mutant, because nothing writes those fields at all.
5. **A 14-line deletion that was not one.** The backfill diff showed 14 removals on an
   additive-only change. Chased it: 13 `## Assumptions` headings re-emitted one line lower.
   Verified by counting sections, 13 → 13.

**And the pattern worth more than any of them:** *five times in one day a mutation control
set caught a misclassification in the suite rather than a defect in the subject.* The reflex
"a surviving case means missing coverage" was wrong more often than right. Better first
hypothesis: **this case is in the wrong bucket.**

---

## 4. Not validated by a human

Stated plainly because the ratio drifted today — four mechanisms shipped, all verified by
tests the author wrote.

1. **T-866's gate, end to end.** The agent is Tier 0 on the inception decision verb, so the
   teeth prove the predicate and not the plumbing. Three-step Human AC on the task.
2. **The F1/F3/F4 rubric content.** Approved as *checkable*, not as known-correct:
   discrimination is measured, correct ordering among product tasks is not.
3. **Any hypothesis.** All 14 are machine drafts. Until one is corrected and marked
   `hypothesis_source: human`, S3's citation has never fired on real content.

---

## 5. Open Sovereign questions

| | question | why it is not the agent's |
|---|---|---|
| **OBS-398** | Inceptions outrank builds *by construction* — one flat value across all nine drivers gives 3 distinct scores vs 28 for builds, and no build can pass the top inception tier | scoring-model decision |
| **OBS-397** | Remediation vs product bandwidth. The mechanical half is fixed; the portfolio split is not stated anywhere | priority decision |
| **OBS-396** | Fabric taxonomy: make it path-determined, stop deriving it from path, or accept `unknown` forever | architectural |
| **OBS-395** | Should `blast_radius` fall back to body path-tokens? Partially reverses T-3068's deliberate choice | reverses a recorded ruling |
| **OBS-394** | `check-active-task` blocks pure reads whose leading token is `for`/`while` — after any close, the agent cannot enumerate candidates to pick the next focus | the gate's own message asked for it |
| **Q1 (arc-004)** | One ranking list or two | deferred until real hypotheses exist |
| **Q2 (arc-004)** | Source drivers are *outcomes*; D1–D4 are *system properties*, and nothing marks the distinction | touches the constitutional directives |

---

## 6. File manifest

**Framework (vendored, in-tree per G-008 — upstream candidates)**
```
.agentic-framework/agents/handover/handover.sh                 T-862
.agentic-framework/agents/termlink/bvp-estimator/estimator.py  T-865, T-867, T-868
.agentic-framework/lib/task-audit.sh                           T-866
.agentic-framework/lib/inception.sh                            T-866
```

**Policy and templates**
```
policy/value-drivers.yaml                                      T-864
.tasks/templates/inception.md                                  T-865, T-866
```

**Instruments (all carry `--mutation` with a control set)**
```
tools/_t861-selfdeclare-teeth.sh          tools/_t866-hypothesis-form-teeth.sh
tools/_t862-handover-carry-teeth.sh       tools/_t867-hypothesis-draft-teeth.sh
tools/_t865-sticky-scoring-teeth.sh       tools/_t868-cited-support-teeth.sh
tools/_t509-instrument-sweep.sh (T-861)   tools/_t696-voi-recurrence.py (T-696)
```

**Reports**
```
docs/reports/arc-004-scope.md
docs/reports/T-696-voi-ruling.md
docs/reports/2026-09-26-bvp-epistemics-and-handover-fidelity.md   (this file)
```

**Tasks:** closed — T-861, T-862, T-864, T-865, T-867, T-868, T-870. Partial-complete —
T-866, T-696. Parked — T-863 (Sovereign), T-869 (needs elapsed time).
**Arc:** arc-004 `hypothesis-first-inceptions`, in-progress, 3 of 4 slices shipped.
