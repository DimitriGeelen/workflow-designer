# Value review — the Workflow Designer product itself (Phase 0–1)

**Scope (operator, 2026-09-20):** option 3 — *the Workflow Designer product itself: `src/`, the
editor, chain stage 1.* Explicitly NOT the AEF seam (T-740 covered that; parked unruled at
`/review/T-740`). Carrying task: **T-742**.

**Defaults taken, operator-approved by selecting "3" against a stated default list:**
purpose source = the yardstick T-740 already confirmed; external data = `none` (T-559 blocks
999-AEF, and T-740 §11 already records their side as unreviewed by construction); budget =
dispatch gatherers as workers and hand back whatever remains unreviewed.

## Purpose (carried forward from T-740, re-confirmed for this scope)

**One sentence:** `832-Workflow-designer` is the source of truth for a dual-audience, single-file
BPMN-subset editor that lets a human draw an AEF process on a swimlane canvas and lets agents
read the same file as typed, schema-validated YAML.

**Users/consumers:** the **operator** (draws processes, holds sovereignty); **999-AEF** (vendors
a *pinned build artifact*, never a fork); **agents** in both repos.

**Core capabilities in scope here** — authoring surface, import/export fidelity, the BPMN-subset
schema, the render/round-trip contract, and the release path that turns `src/` into bytes a
consumer pins. Chain stage 1 (workflow authoring) only; stages 2–3 belong to T-740.

**Non-goals (stated):** AEF never edits its vendored copy; `docs/standards/aef-bpmn-mapping-v1.md`
Part I is frozen and not agent-editable; `examples/aef-processes/rendered/` is a seam artefact
not regenerated on agent initiative; `build/gallery/` is never rebuilt (T-102/T-105 blocked on
mirror drift by design).

**Value drivers (`policy/value-drivers.yaml` v3):** D1 Antifragility 9 · D2 Reliability 7 ·
F-RECALL 6 · D3 Usability 5 · D4 Portability 3.

## Shape of the subject (Phase 0, measured 2026-09-20)

- **The product is one file:** `src/aef-workflow-designer.html` — 997,254 bytes, 254 `function`
  declarations, 3 `<script>`/`<style>` blocks. No `package.json`, no `Makefile`, no bundler.
- **Churn:** 144 commits touch `src/`; **161 touch `tests/`** — the tests churn *more* than the
  thing they test. Single author on `src/` (144/144). Last `src/` change `66e04cff`, 2026-09-09.
- **Tests:** 49 files under `tests/` (`.py`/`.mjs`/`.sh`) plus `fixtures/`, `goldens/`, `data/`.
- **Ledger slice:** 23 active + 173 completed tasks name `aef-workflow-designer.html`. (Filtering
  on the word "designer" is useless here — it matches 127/601, i.e. the whole ledger.)

## Data availability map (verified against the live tree)

| Source | Status | Location / note |
|---|---|---|
| Product source | **EXISTS** | `src/aef-workflow-designer.html`, single file |
| Test corpus | **EXISTS** | `tests/`, 49 runners + fixtures/goldens |
| **Test pass state** | **UNKNOWN** | T-740 §11 recorded this as data gap DG-8 and it is still open — the baseline is part of this review |
| **CI** | **EXISTS but runs zero tests** | `.onedev-buildspec.yml`: one job, `!PushRepository` to the GitHub mirror. No test invocation anywhere |
| Component fabric | **EXISTS** | **118** cards reference the product file (contrast: 8/379 cover the vendored tree) |
| Task ledger, scoped | **EXISTS** | 23 active / 173 completed naming the file |
| Git churn / authorship | **EXISTS** | full history |
| Ghost registry | **EXISTS** | `.context/designer/registry.yaml` + `projects/` |
| Release manifest | **EXISTS** | `dist/MANIFEST.yaml` 0.12.0, sha `2b448b61b7fa6c33` |
| **Product usage telemetry** | **ABSENT** | no `designer-usage.jsonl`, no `.context/telemetry/`, no `logs/`. **No data is not zero use** — nothing about operator usage is knowable from here |
| **Per-item coverage** | **expected ABSENT** | no coverage tooling detected; to be confirmed by a gatherer |
| Execution traces per node | **ABSENT** | needs `fw workflow run`; T-740 established it does not exist |
| BVP realization log | **ABSENT** | `.context/audits/bvp-realization.jsonl` — "did it deliver?" data has never existed |
| Watchtower | **EXISTS** | `http://192.168.10.107:3013`, serving |

## Contradiction found at Phase 0 (carried into the review, not yet classified)

**The release-lag audit check passes over a four-release gap.** Measured today:

| Thing | Version | sha256 (16) | Bytes |
|---|---|---|---|
| `src/` + `dist/MANIFEST.yaml` | 0.12.0 | `2b448b61b7fa6c33` | 997,254 |
| peer pin `.agentic-framework/policy/designer-pin.yaml` | **0.8.0** | — | — |
| what `/designer/app` serves | **0.8.0** | `cab3c75183979b0e` | 903,600 |

This morning's `fw audit --section structure` printed `[PASS] Release lag: src, released artifact
and peer pin are in step`. T-740 recorded the same gap; it is unchanged and the check still
passes over it. **A green check over a false condition is worse than no check** — it actively
suppresses the signal. Flagged here as a Phase-0 observation; classification is the JUDGE's.

**A channel cannot report its own failures:** the audit is the only mechanical reader of release
alignment, and it is the thing that is wrong. There is no out-of-band observer. Standing data gap.

**Pollution disclosure:** this session ran `fw task create`, `fw work-on`, `fw bvp estimate`,
`fw review-queue`, `fw audit --section structure` and three commits before this snapshot.
Counters are read after that activity, not from a clean baseline.

## Role separation

**GATHERER** — dispatched TermLink workers, read-only, Phases 2–3, each writing evidence into
this directory and returning summaries only. **JUDGE** — a separate worker whose only inputs are
the evidence files and this yardstick (Phase 4–5). **HUMAN** — decides Phase 5, authorises
Phase 6. Nothing is executed under T-742.
