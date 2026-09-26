# arc-004 — Hypothesis-first inceptions

**Status:** scoped 2026-09-26. Operator-directed, option 4 of 4 (all pieces, including
post-delivery measurement). Announced to AEF ahead of the work at `framework:pickup`
offset 185.

---

## 1. Why this arc exists

The BVP method this project scores with pairs every value-driver table with a **hypothesis**,
written in a fixed three-part form:

> *"We believe that **&lt;change&gt;**, we will achieve **&lt;outcome&gt;**. We will know that we are
> successful when we see **&lt;measurable signal&gt;**."*

Worked example from the source material, verified against its own arithmetic:

| # | Value Driver | Support | Weight | BVP |
|---|---|---|---|---|
| 1 | Increase efficiency / lower cost | 1 | 3 | 3 |
| 2 | Enhances Experience | 0 | 5 | 0 |
| 3 | Benefits everyone | 5 | 3 | 15 |
| 4 | Legal or Regulatory requirements | 5 | 9 | **45** |
| 5 | Needed to keep the lights on | 0 | 7 | 0 |
| 6 | Enhances Agility | 0 | 5 | 0 |
| | **TOTAL** | | | **63** |

Support 0–5 ("does not support" → "fully supports") × Weight 0–9 ("weightless" → "ultra
heavy"). That is exactly what the framework implements.

**The framework implements the arithmetic and not the epistemics.**

There is no hypothesis field in the task schema, no gate requiring one, and nothing that
could check one. That is not a documentation gap. In the source method a support score is
an **argument about a stated claim**: "support 5 on Legal/Regulatory" means something only
because the hypothesis says *"we will know we are successful when we see inspection-free
approval of the fire department for all equipped sites."*

Without the hypothesis, a support score is a number with no referent. It can rank. **It
cannot be wrong** — there is no claim for it to be wrong about.

## 2. The evidence that this is real, produced while scoping this arc

The four slices below were scored by the current estimator immediately after being written.
They came back **identical**:

```
T-866  D1=4 D2=4 D3=3 D4=2 F-RECALL=2 F2=0 F4=0 F3=0 F1=1   106 / 0.34 / hv-lc
T-867  D1=4 D2=4 D3=3 D4=2 F-RECALL=2 F2=0 F4=0 F3=0 F1=1   106 / 0.34 / hv-lc
T-868  D1=4 D2=4 D3=3 D4=2 F-RECALL=2 F2=0 F4=0 F3=0 F1=1   106 / 0.34 / hv-lc
T-869  D1=4 D2=4 D3=3 D4=2 F-RECALL=2 F2=0 F4=0 F3=0 F1=1   106 / 0.34 / hv-lc
```

S1 is a template change that unblocks everything else. S4 cannot start for weeks and is
`horizon: later` by construction. A human ranks those nowhere near each other. The scorer
cannot separate them, because all four are "build tasks about BVP scoring" and it is matching
vocabulary rather than reasoning about a claim.

This is the **third** instance of the same signature in one day:

1. A VoI signal keyed on `'go/no-go'` scored 11 of 14 inceptions at an identical 0.6 — the
   phrase came from the inception template.
2. Inceptions scored a flat value across all nine drivers, giving exactly three distinct
   scores for fourteen tasks (OBS-398).
3. These four slices, above.

Uniformity is the signature of a scorer with nothing to reason about. Every mitigation so far
has been a better pattern; the hypothesis is the first thing that would give it a subject.

## 3. Slices

| id | slice | horizon | depends on |
|---|---|---|---|
| **T-866** | S1 — the Hypothesis section and its form | now | — |
| **T-867** | S2 — agent drafts, human corrects, correction is sticky | now | S1 |
| **T-868** | S3 — support scores cite the hypothesis | now | S1, S2 |
| **T-869** | S4 — measure the success clause after delivery | later | S1–S3 + elapsed time |

### S1 — the form is the discipline
A blank required field would be a gate that blocks rather than helps: the operator's own
words were that formulating a hypothesis is difficult. A prompted three-part shape makes a
vague hypothesis *hard to write*, which is the opposite failure from T-624's warning, which
made a vague one easy to ignore. Gate at the GO decision when the third clause names nothing
observable.

**Constraint:** the agent must never invoke the inception decision verb (Tier 0, fires on the
phrase in any command text). The gate is implemented and tested against fixtures; the live
exercise is the operator's.

### S2 — drafted, corrected, sticky
Reuses the provenance mechanism shipped in T-865: two states, `human` is sticky, no third
"unknown" state. Every human-vs-draft divergence emits telemetry, because that delta is the
only evidence available for improving the drafter.

### S3 — a cited score can be wrong
Each driver's support cites the hypothesis clause it reacted to, and the evidence line quotes
it. Falls back to body matching while a task has no hypothesis, so the transition is not a
cliff. **The goal is not accuracy — it is correctability.**

### S4 — the only feedback that teaches the model about reality
Current telemetry records when a human overrode an estimate. That teaches the estimator to
predict *the human*. Checking whether the predicted signal actually appeared teaches it to
predict *reality*. Longest pole; cannot be rushed; needs hypotheses to exist and something to
have shipped against one.

## 4. Open questions this arc must resolve, and has NOT decided

**Q1 — two ranking lists, or one? (option C, left open deliberately.)**
Builds produce 28 distinct scores across 0.16–0.57; inceptions produce 3 (0.40/0.60/0.80) and
no build can outrank a top-tier inception. The operator leaned toward two lists. The hypothesis
work reframes it rather than settling it: an inception hypothesis and a build hypothesis have
genuinely different shapes —

- *Inception:* "We believe answering X lets us decide Y; we'll know when the decision is
  recorded and N tasks unblock."
- *Build:* "We believe shipping X achieves Y; we'll know when we see Z."

— which is C's argument made concrete. Deciding it before the hypotheses exist would be
guessing. Revisit after S2.

**Q2 — driver shape: outcomes vs system properties.**
The source method's drivers are outcomes (*increase efficiency, enhances experience, legal or
regulatory, keep the lights on, enhances agility*). D1–D4 are properties of the system
(*antifragility, reliability, usability, portability*). Those are not the same kind of thing
and nothing marks the distinction.

Measured consequence: the outcome-shaped drivers (F1/F3/F4) are the ones that distinguished
product work from framework maintenance; while they had no scorers, the ranking was
structurally incapable of seeing product value and three consecutive autonomous runs ended in
framework remediation, each correct against a model measuring 57% of itself.

**Not proposing a change to D1–D4** — they are the constitutional directives and that is a
different argument at a different level. Recorded because a value model made of system
properties will systematically rank maintenance above delivery, and the source method avoided
that by asking about outcomes.

## 5. What "done" looks like

The arc's headline mechanic, verbatim:

> A maintainer opening an inception cannot record a GO decision until it carries a hypothesis
> whose success clause names something observable, and some weeks after a build ships against
> that hypothesis they can ask the framework whether the predicted signal actually appeared
> and get a yes or no — without re-reading the task or trusting anyone's recollection.

Closing evidence must be wire-level: a real inception refused for a vague success clause, and
a real realisation check returning a verdict against a real shipped build.

## 6. Relationship to AEF

Announced at `framework:pickup` offset 185 **before** starting, explicitly so it does not
arrive as a surprise diff and so they can object early. Trial happens in the vendored install
first. If the hypothesis field works, the schema change belongs upstream and should be
designed with them rather than handed to them. Their view on where a hypothesis lives in the
task schema was invited at the cheap moment.
