# T-110 — Corpus routing-debt sweep

**Task:** T-110 (Test) · **Date:** 2026-07-05 · **Harness:** Playwright MCP against the
served gallery (`tools/serve-gallery.sh`, :8834), driving the live editor. Read-only
w.r.t. the corpus — all actions mutate in-editor geometry only, `examples/**` is never
written (PD-044).

## Purpose

Quantify and regression-check this session's shipped routing one-shot actions —
**Clean layout** (T-095 composite), **Align columns** (T-107), **Distribute evenly**
(T-109) — across the T-092 survey's highest-debt maps plus the `release-pipeline`
control. Two questions:

1. **Do the actions improve routing debt?** (Do they do what they claim.)
2. **Do they ever make it worse?** (Non-regression — the whole point.)

## Metrics

Measured from live editor `state` at each step:

- **mess** — `mapMessiness()`, the **editor's own** validated "genuine visual mess"
  signal (same-lane node overlaps + wavy rows, *excluding* by-design branch-stack
  pitch offsets, T-102). Using the editor's function rather than a re-implementation
  is deliberate — see the Methodology note.
- **col** — column doglegs: edge-connected node pairs whose centre-x differ 1–14px
  (the hidden doglegs Align columns removes; T-092 finding 4).

## Results (corrected methodology: base → Clean → Align columns)

| Map | base mess/col | after Clean mess/col | after Align-cols mess/col | col fixed |
|-----|:---:|:---:|:---:|:---:|
| audit-process | 0 / 0 | 0 / 0 | 0 / 0 | — |
| harvest-pipeline | 0 / **5** | 0 / 5 | 0 / **0** | **5** |
| task-lifecycle | 0 / 0 | 0 / 0 | 0 / 0 | — |
| verification-gate | 0 / **2** | 0 / 2 | 0 / **0** | **2** |
| error-escalation-ladder | 0 / **1** | 0 / 1 | 0 / **0** | **1** |
| release-pipeline (control) | 0 / **3** | 0 / 3 | 0 / **0** | **3** |
| **Aggregate** | **0 / 11** | **0 / 11** | **0 / 0** | **11** |

## Findings

1. **Align columns is the corpus win.** It clears **all 11** residual column doglegs
   across the swept maps (harvest 5, release 3, verification 2, error-esc 1) and is a
   no-op on the already-straight maps (audit, task-lifecycle). This is the single
   biggest measured routing-quality gain of the shipped set.

2. **Clean layout is non-regressing.** `mapMessiness()` stays **0** on every map
   through Clean — it re-tidies (moved 5–7 nodes on audit/harvest) **without ever
   introducing visual mess**. Clean does not, by itself, remove column doglegs
   (`col` unchanged base→Clean) — that is Align columns' job, by design.

3. **Distribute evenly is mess-safe but trades column-alignment.** On
   `release-pipeline` it moved **10** nodes with **zero** mess or col impact. On
   `error-escalation-ladder`, applied *after* Align columns, it re-introduced **2**
   column doglegs (col 0→2). Root cause: distribute equalises a row's horizontal
   rhythm, and on that map a row-mate is *also* a column-mate — evening the row pulls
   the node off its column. This is a genuine **goal conflict** (row rhythm vs column
   straightness), not a bug: the two actions optimise orthogonal properties. It is
   exactly why the T-092 survey and T-109 kept Distribute a **separate, selective
   one-shot action and did NOT wire it into the Clean composite**. The sweep confirms
   that decision was correct.

## Methodology note (PL-005 reaffirmed)

The first sweep pass used a **hand-rolled** row-near-miss metric that **drifted** from
the editor's `mapMessiness()` — it counted branch-stack pitch offsets that
`mapMessiness()` correctly excludes (T-102). That drift produced a **phantom
"cleanLayout regression"** (row-near 3→7 on error-escalation-ladder) that vanished
the moment the sweep used the editor's own `mapMessiness()` (steady 0). Reaffirms
**PL-005**: measure with the editor's own functions; a re-implemented metric silently
diverges and manufactures false findings. The regression gate did its job — it flagged
an anomaly, which on investigation was a measurement artifact, not a code defect.

## Verdict

- **Non-regression: PASS.** No shipped action raises `mapMessiness()` on any swept map.
- **Improvement: PASS.** Align columns removes 11/11 column doglegs corpus-wide.
- **Distribute trade-off: documented, by design** — selective action, not chained into
  Clean; use it when row rhythm matters more than column straightness on that row.

No code changes required. The one actionable follow-up is a *documentation* one:
surface the distribute↔align-columns trade-off in the button tooltip or settings help
so operators know the two can undo each other on shared row/column nodes.
