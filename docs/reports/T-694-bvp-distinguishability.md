# T-694 — Does the BVP estimator distinguish tasks?

**Measured 2026-09-10.** Instrument: `tools/_t694-bvp-distinguishability.py`.
Population: all 96 task files in `.tasks/active/`, of which 73 carry a proposed
driver vector.

This report exists because an autonomous run selected work by BVP quadrant and the
quadrant turned out to be load-bearing on a field nobody had set.

---

## 0. The claim I started with was wrong, and the measurement is what corrected it

I filed this task after scoring fifteen tasks in a row and watching the same nine
numbers scroll past. The task name I gave it says the quadrant *"is not a measurement
for most of the backlog."*

**That is false.** Measured:

```
tasks with frontmatter        : 96
tasks carrying a proposed vec : 73
DISTINCT vectors among them   : 48
modal vector covers           : 12 task(s) (16.4% of scored)
```

**48 distinct vectors across 73 tasks is real discriminating power.** The estimator is
not returning a constant. Two clusters of 12 share a vector; the other 49 tasks spread
across 46 distinct vectors.

The correction is left here rather than edited out of the task name, because the gap
between "I saw the same numbers repeatedly" and "16.4% of scored tasks share the modal
vector" is precisely the difference this task was filed to establish, and it ran in the
direction that made my own finding smaller. Eye-count has no denominator.

**What survives the correction is narrower and worse**, and it is below.

---

## 1. Finding A — an empty task scores 4 of 5 on Antifragility

A task file containing **no task content whatsoever** — the shipped template, id and
`workflow_type` filled in, every other field left as the template wrote it — was scored
directly through the estimator:

```
BARE TEMPLATE, no task content whatsoever:
  scores: D1=4 D2=0 D3=2 D4=2 F-AUTONOMY=0 F-RECALL=0 F1=0 F2=0 F3=0

  evidence: D1: ['body:structural-gate',   '→4 (framework-level gate)']
            D3: ['body:default-change',    '→2 (default tuned)']
            D4: ['body:env-class-handled', '→2 (env-class handled)']
```

`D1 = 4 out of 5` on **Antifragility — the first constitutional directive** — awarded to
a file that describes no work.

The cause is that the estimator matches against the file body, and the template's own
boilerplate talks at length about gates, defaults, and environment classes: the P-011
errexit warning, the SIGPIPE hint, the `[REVIEWER]` routing block. Those are instructions
to the author. The scorer reads them as evidence about the task.

**Consequence.** `D1=4 D2=0 D3=2 D4=2` is not a score. It is the **floor every task in
this repository inherits on creation.** Real discrimination happens only in the free
drivers stacked on top of it. The modal build vector —

```
12x  D1=4 D2=0 D3=2 D4=2 F-RECALL=0 F1=1 F2=0 F3=0 F4=0
     T-439 T-442 T-553 T-554 T-555 T-564 T-573 T-577 T-582 T-583 T-584 T-622
```

— is the empty-template floor plus a single point of `F1`. Those twelve tasks were not
scored low. **They were not scored at all**, and the number that came out was the
template's.

Verified identical rationale strings across the cluster:

```
D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 (body:default-change);
D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal);
F4=0 (no-signal); F3=0 (no-signal); F1=1 (prose:process-enablement-incidental)
```

Byte-identical for T-553, T-582 and T-622 — three unrelated tasks about stdout
redirection, byte-identity goldens, and an unattributed Human-AC write.

---

## 2. Finding B — NOT A FINDING. This was already known, and I did not check first.

> ### CORRECTION, added the same session, after the section below was written
>
> **Everything in §2 was already established by T-624 and T-625 and is documented in
> this repository's own inception template.** I did not look before filing it. The
> template I was measuring says, four lines above the field I was measuring:
>
> ```
> voi_score: 0.5    # ⚠ CHANGE THIS (T-624). For an inception voi_score IS the entire
>                   # BVP composite: the estimator skips per-driver scoring and derives
>                   # all nine drivers from this one number (estimator.py
>                   # _score_inception_voi). Leaving 0.5 does not score the task, it
>                   # abstains — and an abstention is printed as a confident BVP 126
>                   # that no reader can tell from a real score. Measured 2026-08-29:
>                   # 38 of 41 inceptions still carried this exact default, so the
>                   # entire hv-lc quadrant ranked as one flat tie.
> ```
>
> That is my §2 and §3, in full, twelve days earlier — including the abstention framing,
> the flat-tie consequence, and the `_score_inception_voi` site. `tools/_t624-voi-provenance.py`
> already exists and already reports it. T-625 covers `target_blast_radius` identically,
> and states the missing-lane point I presented as mine: *"each field IS a composite input
> with no `_proposed:` lane an agent may write into."*
>
> **§2 below stands as written but is not new. Read it as confirmation, not discovery.**
>
> **What IS new, and is worse than a re-discovery:**
>
> | | measured 2026-08-29 (T-624) | measured 2026-09-10 (here) |
> |---|---|---|
> | inceptions at template-default `voi_score` | 38 of 41 — **93%** | 12 of 13 active — **92%** |
> | at template-default `target_blast_radius` | 38 of 41 | 40 of 43 — **93%** (T-624's own tool, run today) |
>
> **T-624 found the defect, chose "write a warning into the template" as its prevention,
> and twelve days later the number has not moved.** The warning is emphatic, correct,
> specific, and sits directly above the field. It is read by every author who creates an
> inception, and it has changed nothing measurable.
>
> That is a finding about *prevention selection*, not about `voi_score`: **a comment is
> not a gate.** It is the FP-011 class — capture-without-application — arriving on a
> mitigation rather than on a learning. Retargeted as T-696; it is the only part of this
> section worth anyone's time.
>
> **Cost of my error:** roughly a third of this unit of work went into re-deriving a
> documented result. The check that would have prevented it — grep the registers and the
> template before filing — costs one command. I did run exactly that check for Finding A,
> which is how I know Finding A is new; I did not run it for Finding B because Finding B
> felt like something I had discovered.

### The re-discovered material, retained for the record

The second 12-task cluster is disjoint from the first and consists **entirely** of
inceptions:

```
all-twos vector : T-155 T-184 T-185 T-186 T-277 T-279 T-280 T-281 T-282 T-309 T-357 T-498
inceptions      : the same 12, plus T-681
modal2 ∩ inceptions : []      (the build cluster contains no inception)
```

Every driver scores exactly **2**. That is by design, and the design is sound. From
`.agentic-framework/agents/termlink/bvp-estimator/estimator.py:2429-2450`, quoted:

```python
def _score_inception_voi(fm: dict, body: str, tags: list[str]) -> tuple[int, list[str]]:
    """T-2189 inception scoring exception (050-Inceptions.md §Scoring Exception).

    Inceptions are evaluated by `voi_score` (T-2188 schema, float 0..1) rather
    than per-driver mechanism rubrics, because the inception's "value" IS the
    expected value of resolving the question, not the build-shaped traits the
    D-handlers measure. Same score is returned for every requested driver —
    rank is determined by voi alone. Build-task scoring is unchanged.

    Missing or malformed `voi_score` returns a neutral mid-score (2) so
    grandfathered inceptions (pre-T-2188) still rank, just not by VoI.
    """
    voi = fm.get("voi_score")
    if voi is None:
        return 2, ["→2 (voi-absent-grandfathered)"]
    ...
    score = int(round(voi_f * 5))
```

**The estimator is behaving correctly.** It is faithfully reporting an operand nobody
set. Three facts stack:

1. The template ships `voi_score: 0.5` **pre-filled**, with its explanatory comment still
   attached. Measured: **12 of 13 inceptions still carry both the value and the comment.**
2. `int(round(0.5 * 5))` = `int(round(2.5))` = **2** under Python's banker's rounding.
3. The grandfathered path for an absent `voi_score` also returns **2**.

So the two states that mean *"nobody has assessed this"* and the one state that would
mean *"an operator judged this exactly mid"* are **indistinguishable in the output.**
T-155 carries no `voi_score` at all; the other eleven carry the template's. All twelve
score 2.

**And the estimator cannot fix this itself.** Every other input it consumes has a
`_proposed:` lane it may write — `bvp_scores_proposed`, `cost_estimate_proposed`.
`voi_score` and `target_blast_radius` have none; they are operator fields with no agent
lane. So the **inception is the one task type the estimator is structurally unable to
assess**, and it is also the task type whose whole purpose is deciding what to build.

---

## 3. Why this was worth stopping a run over

> **Also not new** — T-624 states the same consequence ("the entire hv-lc quadrant ranked
> as one flat tie"). What is specific to this run is that the flat tie was handed to an
> autonomous mandate whose rule is *work Q1 to exhaustion*, so the abstention became a
> work order. That is worth recording as a live demonstration of the documented risk, and
> nothing more than that.

`voi 0.5 → 2 on every driver` produces composite **126 / 0.40**, which lands in **hv-lc**.

Under the selection rule this run was given — *"Q1 (high value / low cost): work first, to
exhaustion"* — **twelve inceptions carrying an unedited template default outrank every
measured high-value build task in the project.** T-344 (167), T-358 (157) and T-189 (151)
all score higher on the composite and all sit in Q2, behind them.

The ranking is not wrong because the numbers are wrong. It is wrong because **a field
that was never filled in is being read as a judgement that was made.** PL-266 states the
class exactly: *a pre-filled required field converts a gate for presence into a gate that
cannot fail.* Here it converts a ranking input into a ranking that cannot be wrong,
because nothing about it was ever asserted.

---

## 4. The instrument was watched reporting both verdicts

A measuring tool that has only ever printed one answer has not been shown to have two.

```
baseline (3 tasks known to share one vector):   scored=3 distinct=1 modal=3
after planting T-901 with D1=5 D3=5:            scored=4 distinct=2 modal=3
```

`distinct` rose by exactly one, `modal` held at 3. Run in a throwaway root under the
scratchpad — no ledger, fixture, or baseline in the repository was written to.

---

## 5. What is NOT decided here

**The repair is not in this task, and not the agent's to choose.** Every candidate
changes the rank order of the whole backlog:

- Stop shipping `voi_score` pre-filled — make its absence visible instead of neutral.
- Give the two inception inputs a `_proposed:` lane so the estimator may assess them.
- Scope the estimator's body match to the authored sections, excluding template comments.
- Treat "unscored" as its own state rather than mapping it onto a mid-score.

Each is defensible; they do not all point the same way, and choosing among them decides
which tasks this project works next. That is a ranking-semantics decision.

**Sovereign question, filed as its own task rather than answered here.**
