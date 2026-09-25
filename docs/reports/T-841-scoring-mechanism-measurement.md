# T-841 — F1/F3/F4 scoring mechanism: measurement record

**Task:** T-841 · **Date:** 2026-09-25 · **Status:** measurement complete, nothing installed

## The defect, as the audit states it

`lib/bvp-scorability.sh` (AEF 1.7.68, T-3427/T-3428) WARNs three times:

> BVP driver F{1,3,4} has neither a handler nor a scoring spec
> `policy/value-drivers.yaml`: '...' cannot be scored, so it contributes nothing to any
> ranking while its weight and rubric read as a live axis (T-3427 omits it from the
> normalisation denominator)

| id | name | weight | handler | scoring spec | rubric |
|----|------|--------|---------|--------------|--------|
| F1 | V_SDLC_ENABLEMENT | 9 | none | none | **none** |
| F3 | V_AEF_INTEGRATION | 9 | none | none | **none** |
| F4 | V_WORKFLOW_ROUTING | 9 | none | none | **none** |

27 of the model's total weight — the three highest free drivers — has scored a structural 0
on every task in this project and could not have done otherwise. Sourced to "operator
directive 2026-08-16": **40 days.**

The audit says "its weight and rubric read as a live axis". For these three that is
generous: there is no rubric either. F1/F3/F4 carry only `id`, `name`, `weight: 9`,
`protected: false` and one line of `rationale`. F-RECALL and F2 carry `rubric`, `polarity`,
`guardrails` and `retire_when`. So the axes were named at the top weight and never given
levels.

## Corroborating symptom: the model is already visibly not discriminating

BVP values over the 82 tasks that have a quadrant are piled on a handful of points:

| BVP | tasks |
|-----|-------|
| 61 | 18 |
| 99 | 16 |
| 126 | 14 |
| 79 | 8 |

56 of 82 tasks sit on four values. Fourteen tasks tie at exactly 126 / NORM 0.40. That is
what a ranking looks like when three of its highest-weighted axes return a constant.

## What was measured

Three PROPOSED specs (`docs/proposals/T-841-{F1,F3,F4}-*-PROPOSED.yaml`), supplied via
`--scoring-file`, never attached. Each validated:

```
fw bvp driver --validate-scoring docs/proposals/T-841-F1-sdlc-enablement-PROPOSED.yaml  -> OK
fw bvp driver --validate-scoring docs/proposals/T-841-F3-aef-integration-PROPOSED.yaml  -> OK
fw bvp driver --validate-scoring docs/proposals/T-841-F4-workflow-routing-PROPOSED.yaml -> OK
```

### Discrimination: two of the three specs FAIL, and `--validate-scoring` does not notice

Scored across all 44 currently-`lv` tasks (38 lv-lc + 6 lv-hc):

| driver | level distribution (score: count) | modal level | modal share | verdict |
|--------|-----------------------------------|-------------|-------------|---------|
| F1 | 2:1  3:1  **4:41**  5:1 | 4 | **93.2%** | **FAILS** |
| F3 | **0:26**  1:1  2:3  3:12  4:1  5:1 | 0 | 59.1% | **passes** |
| F4 | 0:3  2:1  3:1  4:1  **5:38** | 5 | **86.4%** | **FAILS** |

`--validate-scoring` returned OK for all three. It checks SHAPE, not discrimination — so a
spec that awards the same level to 93% of the corpus is structurally valid and worthless.
That is the template trap the schema warns about, arriving through a different door.

**The asymmetry is the finding.** A spec that saturates at **0** is discriminating: F3
returns 0 for 26 of 44 because most tasks genuinely do not touch the AEF seam, and
`L0: no signal` is an honest measurement that stays in the denominator. A spec that
saturates at **5** is flattering: F4 awards the maximum to 86% of everything. F1 at level 4
for 93% is the same defect one rung down. **Saturation at the floor is a measurement;
saturation at the ceiling is a rubber stamp.**

### Root cause of the two failures — mine, not the schema's

I drew F1's and F4's L4/L5 keywords from my own house vocabulary — `control leg`,
`negative control`, `regression test`, `P-011`, `PreToolUse`, `cdp probe`. Every task I
file contains those words, because I write them. So the spec measures *who authored the
task*, not what it is worth. F3 survived because its signals are domain-bound
(`aef:workflowMeta`, `sidecar:999`, `seam-manifest`) and cannot be written accidentally.

This is a **sibling of the template trap, not an instance of it**: `strip_template: true`
cannot help, because the saturating vocabulary is not in `.tasks/templates/default.md` — it
is in the author. Worth documenting upstream beside the template trap.

**Not tuned away.** Fitting F1/F4 keywords until the 44-task spread looks better would fit
them to this corpus rather than to a meaning, and the next 44 tasks would resaturate.

## Ranking delta from F3 alone (the one spec that discriminates)

F3 scored across all 82 quadranted tasks: `0:45  1:2  2:4  3:20  4:9  5:2`.

Applying `+9 x F3` moves the BVP median, so the hv/lv threshold moves with it. Both numbers:

- **median BVP 80 -> 98**
- migration, median-relative: **4 promoted lv->hv, 4 demoted hv->lv**, 37 stay hv, 37 stay lv

| promoted lv->hv | BVP | F3 |
|-----------------|-----|----|
| **T-826** | 79 -> 106 | 3 |
| T-286 | 79 -> 106 | 3 |
| T-293 | 79 -> 106 | 3 |
| T-769 | 73 -> 100 | 3 |

| demoted hv->lv | BVP | F3 |
|----------------|-----|----|
| T-402 | 90 (unchanged) | 0 |
| T-580 | 98 (unchanged) | 0 |
| T-695 | 82 (unchanged) | 0 |
| T-745 | 94 (unchanged) | 0 |

The four demotions are correct, not collateral: those tasks gained nothing because they
genuinely do not serve F3, and the bar rose around them.

**8 of 82 tasks change quadrant — 10%.** That is what the operator's ruling on F3 buys.

### SQ-6 is confirmed by name

**T-826 is one of the four promoted, 79 -> 106.** It is an AEF-integration task
(AEF's own `kind=documentation|work-plan` ruling) that has been reading `lv` while serving
F3 at weight 9. It moves to hv the moment F3 can score at all. That is the mechanism SQ-6
described, reproduced end to end.

### Honest limit on this delta

The numbers above are computed by me from `--explain` output, not by the ranker. I applied
`+9 x F3` to the raw BVP and re-derived the median. The tool's own normalisation
denominator also changes when a driver becomes scorable (T-3427), so `NORM` and the cost
axis may shift in ways this arithmetic does not capture. **I cannot measure the true
post-attach ranking without attaching**, and attaching is gated — which is itself the
verb-surface gap below. Read the migration as sound in direction and approximate in
magnitude.

## Nothing was installed

- `policy/value-drivers.yaml` — **unmodified** (verified by checksum against HEAD)
- `.context/working/.gate-bypass-log.yaml` — **no entry for T-841**
- no `--i-am-human`, no `--from-watchtower`, no `fw bvp driver --add`

## Two findings for AEF

**1. Verb-surface gap.** The audit WARNs on three EXISTING drivers and names exactly one
remedy — `fw bvp driver --add ... --scoring-file FILE`. But `--add` creates a NEW driver.
There is no verb that gives an existing driver a mechanism. Hand-editing is forbidden by
the schema header ("never hand-edit a spec into this file — the verbs validate"), and
`--add`/`--remove` are §ACD-gated. So the check's own mitigation cannot reach the thing the
check flags. A consumer who follows the advice literally would have to delete and recreate
a protected policy axis.

**2. `--validate-scoring` passes specs that rank nothing.** Shape validation cannot see
saturation. Suggested addition: a `--explain --corpus` mode reporting the level
distribution and modal share over N tasks, so an author sees `modal level 5 = 86%` before
shipping. The discriminator is cheap and it is the only thing that separated F3 from F4
here.

## Sovereign question (open)

**SQ-8 — what do L1..L5 mean for AEF integration, workflow routing, and SDLC enablement?**

Three weight-9 drivers with no levels is not a mechanism gap that a spec fixes. It is an
unfinished policy decision from 2026-08-16 that has silently zeroed 27 of the model's
weight for 40 days. Any ladder I write over it encodes my reading of the operator's intent
— which is what "surfaced, not resolved" exists to prevent. The F3 ladder is tabled as a
proposal with each level citing the clause of the one-line rationale it claims to encode;
F1 and F4 are tabled as **measured failures** rather than as candidates.
