# T-781 — RCA: the BVP estimator's cost model is blind to un-started work

**Date:** 2026-09-21 · **Origin:** T-778/T-779/T-780, three rounds of autonomous selection
under the procAsFit mandate · **Subject:** `agents/termlink/bvp-estimator/estimator.py` and
`lib/bvp.sh`, vendored from 999-AEF at v1.6.354.

Every number below was produced by a command over the **population** — all 780 task files, 150
active and 630 completed — not by reading the estimator and reasoning forward (PL-162).

---

## 0. Why this is written for transmission

The estimator is AEF's code, vendored. If the calibration is off it is off for every consumer
that vendors it. One finding in particular (RC-7) **cannot be diagnosed from a single corpus**,
and that is the collaboration ask at the end.

---

## 1. Summary of the chain

> The cost model has three terms, two of which are near-constant on real data, so cost is an
> affine function of `blast_radius` alone. `blast_radius` is derived from **prose** in ~79% of
> cases, and is absent for **58% of un-started tasks** — precisely the population autonomous
> selection must choose from. Quadrants are then a **median split over whatever remains**, so
> "high value" is a relative label being consumed as an absolute eligibility gate.

---

## 2. RC-1 — the cost composite has one effective degree of freedom

`cost = 0.6·blast_radius + 0.3·tier + 0.1·effort` (F8).

Measured over 778 tasks carrying a cost proposal:

| term | distinct values | modal value | share at mode |
|---|---|---|---|
| `tier` | 1, 2, 3, 4 | **2** | 668/778 = **86%** |
| `effort` | 3–8 | **8** | 681/778 = **87.5%** |
| `blast_radius` | 0–9 | varies | — |

For the ~86% of tasks where `tier=2, effort=8`, the last two terms sum to a constant `1.4`, so:

```
cost = 0.6 · blast_radius + 1.4
```

Verified against observed costs rather than asserted:

| blast_radius | computed | observed in `fw bvp` |
|---|---|---|
| 1 (T-779) | 2.0 | **2.0** |
| 3 | 3.2 | **3.2** |
| 5 (T-344) | 4.4 | **4.4** |

Exact, three for three. **The 0.3 and 0.1 terms are decorative in practice.** A weighted
composite that looks like it balances three signals is, on this data, one signal.

## 3. RC-2 — `effort` measures document length, and saturates

```python
raw = body_lines // 50 + ac_count
v   = max(1, min(8, raw))          # clamped to [1, 8]
```

A task body of 400+ lines reaches the ceiling on the line-count term **alone**, before any AC is
counted. 87.5% of the corpus sits at the clamp. So `effort` does not measure work; it measures
how much prose the task file contains, and for most tasks it is pinned at maximum.

This is partly **ours** — see §8 — but the clamp behaviour is upstream.

## 4. RC-3 — the one live term is derived from prose

`blast_radius` has three sources, most explicit first: `components:`, an inception's
`target_blast_radius:`, then **source paths named in the body**.

| source | count |
|---|---|
| `components:` declared | 102 |
| body-paths / inception target | 592 |
| **tasks with non-empty `components:`, whole corpus** | **102 of 780 (13%)** |

So for roughly **79% of tasks that have a cost at all, the dominant cost term is a function of
documentation density** — whether someone happened to name file paths in the description.

The measured pair, both with `components: []`:

- **T-344** — body names four real paths → `blast_radius 5` → cost 4.4 → `hv-hc`, **selectable**
- **T-241** — body names none → `absent` → cost `-` → quadrant `-`, **invisible**

Neither number reflects a judgement about the work.

## 5. RC-4 — the blindness tracks lifecycle, not scope

| status | n | blast_radius present |
|---|---|---|
| work-completed | 671 | 631 (**94%**) |
| started-work | 34 | 31 (91%) |
| **captured** | **74** | **31 (42%)** |

`components:` is resolved from git history **at completion**. So a task's cost is most knowable
once the work is done, and least knowable while it is still only captured. **A task cannot have
its cost known until after it has been done** — and un-started work is exactly what a selection
mechanism exists to choose among. This is the circularity, now quantified.

## 6. RC-5 — CORRECT behaviour with an unintended consequence (do not "fix" this)

`score_blast_radius` returns `None` rather than a default, and the docstring is explicit:

> `None` propagates to an ABSENT `blast_radius` key … → `quadrant: '-'` → excluded from the
> ranking. **Declining to rank is honest; ranking it cheapest is not.**

This is right, and it was earned: a blind `0` on the 0.6-weight term made unmeasured tasks look
**cheapest**, which an HV/LC filter then promotes. T-2189 fixed it for inceptions, T-542
generalised it. **Nothing here argues for re-opening that.**

The consequence, which is separable from the decision: the exclusion is **silent**. Nothing in
`fw bvp` output says "45 tasks could not be ranked"; they are simply not there. And it
propagates upward — see RC-6b.

## 7. RC-6 — quadrants are a median split over a biased, shifting sample

```python
bvp_median  = statistics.median(bvp_vals)
cost_median = statistics.median(cost_vals)   # only rows WHERE cost is not None
hv = bvp_norm >= bvp_median
lc = cost <= cost_median
```

Three consequences:

1. **"High value" is relative, not absolute.** By construction roughly half the rankable set is
   high-value. A mandate that says *"low-value tasks are out of scope regardless of how cheap"*
   is therefore discarding **the bottom half of whatever is rankable today**, not a class of
   genuinely low-value work.
2. **The sample is biased.** The medians are computed over rows that *have* a cost — i.e.
   excluding the prose-thin, mostly un-started population from §5. The yardstick is built from
   elaborated, already-worked tasks.
3. **The boundary moves.** Scoring any task can reclassify others across the median. Observed
   live this session: hv-quadrant membership went 31 → 35 → 36 → 35 across three rounds.

**RC-6b — it propagates to arc level.** `fw bvp arcs` returned **two** arcs; three exist and all
three are `in-progress`. The missing one is arc-002 `ewcr-governed-delivery` — *the focused arc*,
holder of the Arc-0 exit clauses. Cause: arc BVP is a rollup over constituent tasks; arc-002's
only two live tasks (T-681, T-732) both carry `blast_radius: absent`, so the rollup has no
rankable constituent and the arc is dropped **without a marker**. The output shows two arcs and
looks complete.

## 8. RC-7 — D2 (Reliability) is undetected 84% of the time — and this one needs a second corpus

Per-driver, over 625 scored tasks:

| driver | weight | `no-signal` rate | scored zero |
|---|---|---|---|
| D1 Antifragility | 9 | 7% | 1% |
| **D2 Reliability** | **7** | **84%** | **77%** |
| D3 Usability | 5 | 22% | 16% |
| D4 Portability | 3 | 8% | 2% |
| F2 | 6 | 92% | 86% |
| F-RECALL | 6 | 58% | 52% |

**D2 is one of the four Constitutional Directives**, weight 7 — second-heaviest — and the
heuristic reports no signal for it on 522 of 625 tasks. Its contribution to the ranking is close
to nil, which means value ranking systematically under-weights reliability work.

**This is the finding a single corpus cannot resolve.** 84% is consistent with two very
different causes:

- the D2 detector is too narrow, or
- *our* task prose simply does not describe reliability in the vocabulary it looks for.

We cannot tell which from inside one repository. **AEF has an independent corpus.**

## 9. Local vs upstream

| finding | upstream (AEF) | local (832) |
|---|---|---|
| RC-1 one degree of freedom | ✅ F8 weights + ladders | — |
| RC-2 effort saturates | ✅ the `//50` ladder and clamp | ⚠️ our task bodies are unusually long, which pins it |
| RC-3 prose-derived cost | ✅ source precedence | ⚠️ our `components:` hygiene is poor — 13% |
| RC-4 lifecycle blindness | ✅ structural | — |
| RC-5 silent exclusion | ✅ reporting only — **decision is correct** | — |
| RC-6 median split | ✅ `lib/bvp.sh` | — |
| RC-6b arc drop | ✅ rollup has no unrankable marker | — |
| RC-7 D2 blindness | **undetermined — needs a second corpus** | **undetermined** |
| RC-8 dry-run preview | ✅ `estimate-cost all --dry-run` | — |

**RC-8:** `fw bvp estimate-cost all --dry-run` printed `777 tasks: 0 wrote, 777 skipped`; the
immediately following real run wrote **214**. The preview's summary is identical whether or not
work is pending. The per-task dry-run does **not** share the defect. Advisory — misleads a
reader, does not corrupt state.

## 10. What this does not claim

- It does not claim the estimator is wrong to decline to rank. It is right (RC-5).
- It does not claim the numbers are miscomputed. They are computed exactly as specified;
  verified to the decimal in §2.
- It does not propose weight changes. BVP calibration parameters are the operator's, and an
  agent that retunes the instrument ranking its own work has certified its own work.

The defect is not in the arithmetic. It is that **a relative ordering, built from a biased
sample, with one live term derived from prose, is being consumed as an absolute eligibility
gate for autonomous work selection.**
