# Value review — 832-Workflow-designer — 2026-09-25 — JUDGE REPORT

**Round 4 of 4 (JUDGE only).** Worker `vr0925j1`, dispatched via `fw termlink dispatch --task
T-838`. Phases 4–5 only. Input: `docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md` (1526
lines, three GATHERER rounds + one orchestrator seam addendum) and the confirmed yardstick below.
No new territory was gathered; three specific evidence rows were re-verified directly against the
repo (marked "verified fresh" below) because the classification hinged on them.

**Nothing in this report is executed.** No task created, no file outside the two allowed deliverables
touched, no status changed. All proposals require operator approval item by item (Phase 6).

---

## 1. Yardstick (confirmed)

> "The workflow designer and its integration with AEF, and our ability to facilitate the agent and
> human collaboration to iterate from the workflow to actual working applications."
> — Operator, verbatim, 2026-09-24T23:07:03Z: **"The yardstick holds."**

Protected drivers: **D1** Antifragility (9) · **D2** Reliability (7) · **D3** Usability (5) ·
**D4** Portability (3). Free drivers (cap 5, 4 in use): **F1** SDLC_ENABLEMENT (9) · **F3**
AEF_INTEGRATION (9) · **F4** WORKFLOW_ROUTING (9) · **F2** V_COMPONENT_FABRIC (6). **F-RECALL**
Recall Leverage (6) is also listed as consuming a slot per the evidence file's Phase 1 read;
F-AUTONOMY sits INACTIVE/candidate, no slot consumed.

Core capabilities: author/validate/export/import AEF workflows in a dual-audience (human-drag,
agent-YAML) editor; swimlanes encode the Human·Sovereignty / Framework·Authority / Agent·Initiative
model. Non-goal (textually confirmed, `README.md:13-15`): 832 does not build the workflow
*execution* runtime — that is AEF's, a standing Sovereign ruling (SQ-1, 2026-09-21 review, not
re-litigated here).

---

## 2. Data availability map (confirmed) + snapshot windows

Full table is in the evidence file's Phase 1b (Layer A + Layer B). Summary of what caps this
round's confidence, carried forward without re-derivation:

| Status | Count of named sources | Representative rows |
|---|---|---|
| EXISTS, measured | ~20 | git history, `.fabric/` (411 cards), `.tasks/` ledger, `fw audit`/`fw gaps`, TermLink hub/topics, `.claude/settings.json` hook wiring, `.agentic-framework/policy/prompts`+`agents/dispatch` (corrected mid-series, see §10) |
| PARTIAL | 3 | command/verb usage (inferred from `--help`, not invocation counts), token telemetry (`fw costs` never queried), test suite (pytest collects 19–20 of 45 `test_*.py`, see §10) |
| DESIGNED-ONLY / ABSENT | 6 | `policy/capabilities.yaml`, `.context/bus/`, `.context/audits/bvp-realization.jsonl`, project-level `policy/prompts/`+`agents/dispatch/` (832's own, distinct from the vendored copies — see §10), AEF-side seam telemetry, `/designer/app` access logs |

Snapshot window: **2026-09-25T00:2x–00:4x+02:00** for rounds 1–2, a fresh re-measurement by round
3 same day, and a live orchestrator-gathered seam exchange dated **2026-09-22 through
2026-09-25** for S-1–S-4. Git-history-based facts (churn, staleness, commit counts) cover full
project history (2,456–2,462 commits) unless a window is stated per row.

---

## 3. Role setup

- GATHERER and JUDGE **were separated**: three independently dispatched GATHERER workers
  (`vr0925g1`, `vr0925g2`, `vr0925g3`) plus one orchestrator-gathered seam addendum, then this
  JUDGE worker (`vr0925j1`) reading only the resulting evidence file and the confirmed yardstick.
  Per the prompt's own rule, the "minus one confidence level for non-separation" **does not
  apply** here.
- **Model family was not varied.** All four GATHERER/JUDGE workers, including this one, run on the
  same model family (Claude, current generation). The role and context separation is real —
  each worker started with a clean context and could not see the others' reasoning, only their
  written output — but a same-family judge reading same-family gatherers' output is a weaker
  independence guarantee than a cross-family setup would be. Stated plainly, not corrected for
  numerically: confidence labels below are not further discounted for this, but the reader should
  weigh it, per the operator's own instruction.
- This round's only repo interaction beyond reading the evidence file was direct verification of
  three specific claims (fabric drift's unregistered-file list, the `t233-gallery.png` reference
  count, and the current `docs/designer/schema.md` mtime) — each cited inline where used.

---

## 4. Baseline

| Check | Round 1 (2026-09-25T00:2x) | Round 3 re-measure (same day) | Direction |
|---|---|---|---|
| `fw audit` | 162 PASS / 22 WARN / 1 FAIL | 175 PASS / 26 WARN / 1 FAIL, 2m51s wall-clock | PASS/WARN both grew — partly explained by `fw audit`'s own snapshot write between runs (self-referential, disclosed in evidence D-JOB0) |
| `python3 -m pytest tests/ -q` | 20 passed, 0 failed, 61.01s | 20 passed, 0 failed, 58.90s | stable |
| `tests/run-bridge-tests.sh` | 142 passed / 9 failed / rc=1 / 1045s (this round's own fresh run, HEAD `2a841f3f`) | not re-run round 3 | red, persistently, for at least 3 days prior (7→10→9 failed across the 3 logged runs since 2026-09-22) |
| `fw fabric drift` | 13 unregistered / 0 orphaned / 0 stale | same, corroborated | stable but see §10 contradiction with T-834 |
| `fw gaps` | 52 watching, 0 resolved | not re-run | stable |
| CI (`.onedev-buildspec.yml`) | mirror-push only, no test execution step | unchanged | — |

The FAIL in every `fw audit` run is the same one: **D2 Human review queue — 13 tasks waiting >30d
(up to 57d), 22 more >14d.**

---

## 5. Summary

| Class | Count |
|---|---|
| KEEP | 11 (named §7) |
| DELETE | 1 |
| REFACTOR | 5 |
| ADD | 6 |
| INVESTIGATE | 7 |

**Top 3 per axis, one line each:**

- **DELETE** — `t233-gallery.png` (repo root): zero references anywhere, accidentally swept into
  an unrelated 2026-08-15 commit about a PreCompact handover, trivially revertible. This axis
  stays thin (only 1 item clears all seven DELETE checks) — every other candidate is blocked on
  DELETE CHECK 5 (no external consumer) by the open AEF seam questions in §12/S-3.
- **REFACTOR** — the `tools/` one-shot-verification lifecycle: 125 of 358 files read as "standing
  guard, no live caller," of which 112 ran exactly once at a now-archived task's completion and
  cannot re-run under the current P-011 design; 639 churn-touches in 60 days on a directory that
  exists to verify one 11,503-line product file; 259 shellcheck findings. No file here clears
  DELETE (historical callers exist, no external-consumer answer), but the accumulation pattern is
  a real, measured, growing cost.
- **ADD** — surface the AEF sidecar inbox: replies to 832's own consults sat **unread for ~2 days**
  across 10 escalating nudges hitting rung 4, blocking a load-bearing decision (T-826) the whole
  time; the counterparty independently logged the mirror-image defect on their own end (their
  OBS-482). `fw sidecar inbox` has no Session-Start-Protocol step and no hook surfacing it.

---

## 6. Findings table

| ID | Item | Location | Class | Non-use reading | Evidence | Counter-evidence | Confidence | Proposal | Size | Reversible? | Risk if wrong | Expected effect |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| F-01 | AEF sidecar inbox unread on both ends | TermLink sidecar, `.context/inbox.yaml` | **ADD (WIRE)** | C (undiscoverable) + D (unmeasured) | S-1a–g: 3 consults, all 3 replies unread ~2 days, 10 nudges to rung 4 across 3 conversations; counterparty independently logged the mirror defect (OBS-482) | Producing side (nudge emission, escalation ladder) works correctly — this is a consumption gap, not a total breakage | HIGH (measured: offsets cited, 2-independent-source corroboration — 832's own ladder + AEF's own OBS-482) | Add a Session-Start-Protocol step (or `SessionStart` hook, matching the existing `post-compact-resume` pattern in `.claude/settings.json`) that surfaces pending sidecar inbox items before other work begins | small | yes — a doc/hook add, easy to remove | if wrong: extra noise at session start, tunable via threshold | metric: median time-to-read for a sidecar reply, measured from next session's `fw sidecar inbox` vs. reply timestamp; direction: down from ~2 days; window: next 10 sidecar exchanges |
| F-02 | `tools/` one-shot verification lifecycle | `tools/` (358 files) | **REFACTOR** | mixed — 112 "historical caller only," 13 never-referenced (of which 5 zero-reference-anywhere) | JOB1 census: 174 no-live-caller, 49 excused-by-design, 125 findings, 112 have a completed-task historical caller; 639 churn-touches/60d (15× `src/`'s 42); 259 shellcheck findings across 113 `.sh` files | Reachability closure (T-451) already exists and is precise — the *tool for measuring this* is not the gap; check 6 (no ratified workflow references `tools/`, confirmed via `grep` against all rendered `.bpmn`) is satisfied for the whole population, which argues these are safely internal, not consumer-facing | HIGH (measured via the project's own purpose-built closure tool, corroborated by shellcheck/vulture) | Define and apply a lifecycle rule: tools referenced only by a *completed* task's Verification block get archived (e.g. `tools/_archive/`) or folded into `tests/run-bridge-tests.sh` if genuinely regression-relevant; decide per-file is a human/domain call, not automatable | needs its own design | yes — archival is non-destructive (git mv) | if wrong: accidentally archive something AEF or a future task still needs — mitigated by keeping archive in-tree, not deleting | metric: `tools/` file count and 60-day churn; direction: down; window: next 60-day period post-change |
| F-03 | G-020 build-readiness gate misclassifies research/GATHERER dispatch tasks | `.agentic-framework/agents/context/check-active-task.sh`, TermLink dispatch harness | **REFACTOR** | — (process gap, not a non-use item) | T-838 itself (this very task) was filed via `fw termlink dispatch` with the `build` template and placeholder ACs; G-020 blocked nearly every command for round 1's worker, forcing reliance on the safe-command allowlist for all 4 dispatched workers in this series | The gate is working exactly as designed for its stated purpose (unscoped builds); the defect is in what workflow_type the dispatch harness assigns, not in the gate's logic | HIGH (measured directly, 4/4 recurrence across this review's own dispatch series) | Give `fw termlink dispatch` a lighter default `workflow_type` (e.g. `inception` or a new `research` type) for read-only/GATHERER-role tasks, so G-020 does not police them as unscoped builds | small–medium | yes | if wrong: a genuine build dispatched under the lighter type slips past G-020 — mitigate by scoping the new type narrowly and keeping G-020's Tier-1 default for anything else | metric: count of G-020 blocks hit by GATHERER-role dispatches; direction: to zero; window: next 5 dispatch rounds |
| F-04 | `.fabric/` has zero cards for `.claude/` | `.fabric/components/`, `.claude/settings.json` | **REFACTOR / ADD(SURFACE)** | C (undiscoverable — even the project's own structural map missed it) | D-10/D-11: `.claude/settings.json` is the literal dispatcher for every hook CLAUDE.md's Enforcement Tiers section describes (9 `PreToolUse` matchers, 7 `PostToolUse` matchers); `find .fabric/components -iname "*claude*"` → 0 results; not among the 13 `fw fabric drift` already flags as unregistered — a deeper blind spot than the tool's own drift check catches | none found | HIGH (measured directly, corroborated: two independent checks — direct grep and `fw fabric drift`'s file list — agree `.claude/` is absent from both) | `fw fabric register .claude/settings.json` (and the 2 other `.claude/` files) | small | yes | none material | metric: `.fabric/` card count for `.claude/`; direction: 0 → 3; window: immediate, one command |
| F-05 | CI has no test execution step | `.onedev-buildspec.yml` | **ADD (NEW)** | B (never wired — verification is entirely session-side) | Confirmed twice (round 1, round 2): one job, "Push to GitHub Mirror," no `.github/workflows/` either | This may be a deliberate choice (fast-forward-only branch model, session-side gates via hooks) rather than an oversight — not established either way | MEDIUM (observed absence, corroborated twice, but no evidence of intent either direction) | Add a CI job running `pytest tests/ -q` (currently green, cheap, 20/20) as a first step; defer wiring the bridge suite into CI until F-02's cleanup reduces its current 9-failure red state | small (pytest-only) to medium (if bridge suite included) | yes | if wrong: a red CI gate blocks pushes for pre-existing bridge-suite failures unrelated to the change — mitigate by starting pytest-only | metric: CI job count with a test-execution step; direction: 0 → 1; window: next release cycle |
| F-06 | `.context/audits/bvp-realization.jsonl` absent — no review's predictions ever checked | `.context/audits/` | **ADD (NEW)** | B (never wired) | Confirmed absent across rounds 1, 2, and again this round (S-4); named as an ADD candidate by the 2026-09-21 review, zero movement in 4 days / 122 commits; consequence stated directly in evidence: "no prior value review's predictions have ever been checked against outcome — four reviews, zero realization checks" | none | MEDIUM (claimed absent 3 times independently, consistent; no direct measurement of *why* it was never built) | Build a minimal realization log: after N weeks, re-check each finding's "Expected effect" prediction (including this report's own, §6) against the metric named, append a jsonl row | needs its own design (what counts as "checked," on what cadence) | yes | if wrong: extra bookkeeping with no one reading it — mitigate by tying it to the existing `fw gaps`/audit cadence rather than a new standalone process | metric: count of `bvp-realization.jsonl` rows; direction: 0 → >0; window: 90 days from next review |
| F-07 | `docs/designer/schema.md` stale by 144 commits | `docs/designer/schema.md` vs `src/aef-workflow-designer.html` | **ADD (REPAIR)** | A (broken — documentation, not code) | Doc last touched 2026-07-04; product file touched 144 times since (measured fresh, `git log --oneline --since=2026-07-04`); corroborates and quantifies the 2026-09-20 designer-product review's "stale by nine shipped feature tasks" finding, gap widened ~2.5 months since | none | HIGH (measured, corroborated across two independent review rounds 5 days apart) | Update `docs/designer/schema.md` against the current schema; scope not fully sized this round (not opened in full) | small–medium | yes | if wrong: doc still imperfect but strictly less stale than today | metric: days since `docs/designer/schema.md` last touched relative to `src/aef-workflow-designer.html`'s last touch; direction: gap shrinks toward 0; window: at next schema-affecting commit |
| F-08 | 25–26 `test_*.py` files are not pytest-collectible, undocumented | `tests/*.py` | **ADD (SURFACE)** | C (undiscoverable) | Round 1: 25 of 45 files have zero `def test_*` functions, confirmed via collection diff; round 3 independently recounted **26**, a 1-file discrepancy neither round's method fully explains (see §10); no `pytest.ini`/`pyproject.toml`/README note documents the split; bare `pytest tests/` (the obvious first command) silently reports "20 passed" with no indication 25–26 more files exist | The 26 script-style files are not broken — they work as standalone CLI harnesses/probes by design, consistent with the `tools/_tNNN-*` naming convention used elsewhere | MEDIUM (measured twice, with an unreconciled 1-file discrepancy between the two measurements) | Add a `pytest.ini`/`conftest.py` note (or rename convention) documenting that `tests/` intentionally mixes pytest-collectible tests with standalone script harnesses, and reconcile the 25-vs-26 discrepancy | small | yes | none material | metric: presence of a documented split; direction: undocumented → documented; window: immediate |
| F-09 | Capability registry (`policy/capabilities.yaml`) still absent | project root `policy/` | **ADD (NEW)** | B (never wired) | Confirmed absent 3 rounds running; named as an ADD candidate by the 2026-09-21 review; CLAUDE.md's own Data Layer B row names it as the source for "every verb/skill/prompt/MCP facade, tier, authority; facade drift" | project-level `policy/prompts/` and `agents/dispatch/` were *also* claimed absent by rounds 1–2 and round 3 found the **vendored** (`.agentic-framework/`) copies of similarly-named paths do exist and are wired — see §10 for why this does not resolve the capability-registry finding, a distinct, still-absent path | MEDIUM (persistent absence across 3 independent checks; no evidence of active work toward it) | Scope as its own inception: what should `policy/capabilities.yaml` enumerate for a project whose own capabilities are mostly consumed via the vendored `fw`/TermLink tooling rather than self-defined verbs | needs its own design | yes | none material — it's additive | metric: file existence; direction: ABSENT → EXISTS; window: next inception cycle |
| F-10 | Screenshot artifact destination has no enforced convention | `.playwright-mcp/`, `docs/screenshots/`, repo-root PNGs | **REFACTOR** | mixed (3 of 5 untracked root PNGs are A-broken from the *documentation's* side — committed `.md` files reference images that don't exist in a fresh clone) | D-15/D-16: 4+ distinct destinations found (`.playwright-mcp/` tracked, `docs/screenshots/` tracked, `docs/reports/<task>-evidence/` tracked, repo-root loose — 5 of 6 untracked, 3 of those 5 referenced from committed docs) | The mechanism (take-and-read screenshots per CLAUDE.md's Visual Verification protocol) works; only the *filing location* is undocumented | HIGH (measured directly via `git status`/`git ls-files`/grep, unambiguous) | Add one line to CLAUDE.md's "Visual Verification for UI Changes" section naming the canonical destination; commit or discard the 5 untracked root PNGs per the human's call on each | small | yes | none material | metric: count of untracked/orphaned screenshot files at repo root; direction: 5 → 0; window: immediate |
| F-11 | `_t350-teeth.sh` — repo-deleting mutation harness, safety precondition unverified | `tools/_t350-teeth.sh` | **INVESTIGATE** | — | File's own header documents an earlier version deleted the entire repository (recovered from origin); excluded from all runs by two independent tools (`_t509-instrument-sweep.sh`, this review); current version has an added `assert_safe()` precondition (lines 17–40), not exercised or verified this round | The exclusion is currently working as a safety measure — nothing is broken today | HIGH that the risk is real (measured: header text, cross-confirmed by the excluding tool's own comment); LOW on whether `assert_safe()` is sufficient (not tested) | Do not lift the exclusion. If ever revisited, verify `assert_safe()` in a fully isolated sandbox only, never against this working tree, with human sign-off before any run — this is exactly the kind of call this review's ground rules reserve for the human | small spike, sandboxed only | N/A — the safe state (excluded) is the default; changing it is the risky direction | **catastrophic if wrong** — documented precedent of deleting the whole repo | metric: n/a — this is a standing risk-acceptance decision, not a metric to move |
| F-12 | `.context/audits/cron/` — 744 files git-deleted (unstaged) but still present on disk | `.context/audits/cron/` | **INVESTIGATE** | — | D-9/JOB2: git status shows ~744 pending deletions of files that are simultaneously still present on disk (confirmed via `find -newermt`); this worker made zero writes to the directory; append-only ledger design (CLAUDE.md, D2 Reliability) means the git-history/disk divergence is itself a reliability-relevant anomaly, not cosmetic | Could be a working, uncommitted retention/rotation mechanism operating as intended — not established either way | LOW (observed once, not diagnosed; no `git log` history dig was run to avoid Phase-0-pollution) | Operator should determine: (a) is a rotation process supposed to be pruning `.context/audits/cron/` and simply hasn't committed yet, or (b) is this an accidental mass-deletion that should be reverted | small — one `git log`/`git blame` investigation | commit vs. revert both reversible individually, but not knowing which is correct risks losing ledger history either way | metric: n/a — resolve the divergence, then re-measure `git status` cleanliness | — |
| F-13 | `CONTEXT_WINDOW` configured 800K, CLAUDE.md's own illustrative numbers still say "default 300K" | `.framework.yaml:9`, `CLAUDE.md` P-009 section | **REFACTOR** | — | D-12: configured value is 2.67× the number CLAUDE.md prints as the base for its 225K/255K/285K escalation thresholds; the section already names this exact failure mode (cites T-614 as a prior instance) but still prints only the stale-base numbers | The section does correctly instruct "read the level, do not recompute" and warns readers not to trust the absolute numbers — the self-awareness is already there | HIGH (measured directly: config value read, compared to doc text) | Replace the printed 225K/255K/285K examples with either the *currently configured* numbers (computed, e.g. via a template) or remove them entirely, leaving only the percentage rule and the `checkpoint.sh budget` pointer | small | yes | none material | metric: whether CLAUDE.md's printed numbers match `fw config get CONTEXT_WINDOW`-derived thresholds; direction: mismatched → matched or removed; window: immediate |

---

## 7. KEEP list (names only)

- Designer editor (`src/aef-workflow-designer.html`) — the product itself, highest all-time churn, directly serves F4/F1/D3, no material finding this round
- `.fabric/` component fabric mechanism (distinct from its `.claude/`-coverage gap, F-04)
- `.tasks/` governed work ledger (100% git traceability, 155 active / 682 completed)
- Branch model (`docs/branch-model.md`) — documented, AEF-consulted rationale
- `examples/aef-processes/` seam corpus (frozen, AEF-pinned; consumption extent is an open question, §8, not a KEEP-vs-DELETE question)
- `scripts/` release pipeline (4 files, each with a clear origin task and purpose)
- TermLink hub (alive, measured, 111 sessions, 0 unreachable)
- `tests/run-bridge-tests.sh` / `run-validator-tests.sh` as a *capability* (their current red state is F-02/INVESTIGATE-adjacent, not a reason to remove the capability)
- `policy/value-drivers.yaml` (the yardstick's own source of truth)
- `.context/` memory layers (arcs, audits, handovers, project memory) as a mechanism, independent of the specific F-12/F-06 gaps
- CI mirror-push job (serves D4 Portability as designed; its *missing* verification role is F-05, not a reason to remove the mirror)

---

## 8. INVESTIGATE list + data needed

| Item | What would resolve it |
|---|---|
| 13 `tools/` files never referenced by any task (5 with zero reference anywhere) | AEF's answer to S-3 Q4: "does anything on AEF's side call into 832's `tools/` instruments?" — currently open, posted 2026-09-25 |
| `examples/aef-processes/rendered/` 24 corpus maps | AEF's answer to S-3 Q1/Q2: which maps/contracts are actually consumed/exercised on their side |
| TermLink `dispatch --isolate` (0 recorded uses ever) | A concrete near-term case where concurrent dispatch actually collided (or didn't) — no origin task committing to its use was found |
| `.context/audits/cron/` 744-file divergence (F-12) | `git log`/`git blame` on the deletion, run deliberately (not as a side effect) |
| `_t350-teeth.sh` `assert_safe()` sufficiency (F-11) | A sandboxed, human-reviewed verification — never against the live working tree |
| BVP `bvp_scores` confirmation at 0/155 | Operator ruling: is proposed-only scoring sufficient for `fw bvp rank` purposes, or should confirmation become a required workflow step? (sovereignty-boundary field — see §12) |
| `vendor/designer/` one release behind `dist/`'s latest (0.12.0 vs 0.13.0) | Whether a consumer-intake cadence is intended after every release — no committing task found |

---

## 9. Data gaps that capped confidence — and what closing each unlocks

1. **AEF-side seam telemetry, categorically unreachable from this repo (T-559 read-side allowlist).**
   Unlocks: the single biggest confidence cap in this whole review — DELETE CHECK 5 (no external
   consumer) cannot be satisfied for `tools/` orphans or the corpus maps without it. This is why
   the DELETE axis stayed at 1 item instead of several plausible candidates.
2. **`/designer/app` access logs or analytics — asked of the operator twice, not answered.**
   Unlocks: real D3 Usability judgment (is the product actually opened by anyone beyond
   session-time verification?) instead of inference from git/task activity alone.
3. **`fw healing patterns`/`fw healing suggest` never queried across all 3 GATHERER rounds.**
   Unlocks: MTTR and failure-class data — directly relevant to D1 Antifragility (weight 9, the
   highest-weighted driver), currently un-evidenced in this review.
4. **`fw costs` (token telemetry per task/arc) never queried.**
   Unlocks: cost-side ranking for the REFACTOR axis (currently ranked by churn/file-count proxies
   only, not actual token spend).
5. **Full `git log -S<filename>` content-diff search not run for the 358 `tools/` files** —
   commit-subject-line search is a weaker proxy and was explicitly flagged as such.
   Unlocks: a stronger "commit mentions" signal for the `tools/` orphan table (F-02).
6. **`.context/project/{concerns,learnings,decisions}.yaml` (≈8,800 lines combined) sized but not
   content-sampled beyond the `fw gaps` summary.**
   Unlocks: whether the 52-watching/0-resolved gap register pattern (D-8) reflects genuine
   under-resourcing or a tracking-discipline gap — currently unclear which.
7. **Bridge suite's other 8 of 9 failures — detail lost when this session's `/tmp` scratch
   directory was reaped mid-run by an external process.**
   Unlocks: whether the 9 current failures are one root cause or nine — needed before F-02's
   REFACTOR can be sized precisely. Cheap to re-run (flagged explicitly in the evidence file).
8. **`.agentic-framework/docs/` (1,643 files) and `lib/` (461 files) never opened beyond two
   path-existence checks.**
   Unlocks: whether the vendored framework itself carries the same kind of orphan/churn cost this
   review found in 832's own `tools/` — currently invisible.
9. **Liveness classification (standing vs. historical-only) not done for the 26 script-style
   `tests/*.py` files**, mirroring the distinction JOB1's census drew for `tools/`.
   Unlocks: whether F-08's "undocumented split" finding also hides an F-02-shaped lifecycle
   question inside `tests/` itself.

---

## 10. Contradictions

1. **Fabric "0 orphaned" vs. an open task calling the mechanism broken by design.**
   `fw fabric drift` reports 0 orphaned cards. `.tasks/active/T-834-*` (filed 2026-09-23, still
   open, `horizon: later`) states in its own title: "Fabric discards vendored-path edges by
   design, so 41 connected cards read as orphans." Not resolved by this JUDGE round — both
   readings are live. **Relying on:** the drift tool's clean output for F-04's proposal (register
   `.claude/`), since that finding is about missing cards, not the orphan-count mechanism T-834
   disputes.
2. **25 vs. 26 non-pytest-collectible test files.** Round 1/2 say 25; round 3's independent
   recount says 26. Neither round documents its method precisely enough for this JUDGE to
   reconcile from the evidence file alone. **Relying on:** neither number specifically — F-08's
   proposal (document the split) is correct regardless of which count is exact.
3. **Fabric card `depended_by` edges vs. reachability closure.** `.fabric/components/
   tools-_t596_arc0_check.yaml` declares a live dependency edge to `_t596-arc0-exit-gate.sh`,
   which the T-451 closure marks as `pending one-shot` (not live) — the two data sources measure
   genuinely different things (declared structural intent vs. current runtime reachability), not
   an error in either. **Relying on:** the reachability closure for F-02 (it is the liveness-aware
   measurement); the fabric graph for F-04 (it is the structural-registration measurement) — using
   each for the question it actually answers.
4. **This JUDGE round's own dispatch brief's KNOWN EVIDENCE was wrong, not just stale.** It claimed
   `policy/prompts/` and `agents/dispatch/` were ABSENT per rounds 1–2; round 3 found the vendored
   copies (`.agentic-framework/policy/prompts/`, `.agentic-framework/agents/dispatch/`) exist,
   are substantive (8 + 8 files), and are referenced from live framework code
   (`lib/bvp.sh`, `check-dispatch.sh`, `orchestrator-graph.py`, the BVP estimator). **This is a
   different path than F-09's still-absent project-root `policy/capabilities.yaml` and project-root
   `policy/prompts/`/`agents/dispatch/`** (832's own capability surface, vs. the vendored `fw`
   tool's internal prompt/dispatch library it uses to run itself) — round 3's correction resolves
   the *vendored-copy* absence claim, but does **not** resolve F-09, which is about content 832
   itself would author, not content the vendored framework ships with. Kept as two separate,
   non-overlapping findings for exactly this reason.
5. **`fw audit`'s "read-only" side effect.** This JUDGE's own predecessor's dispatch brief stated
   both "read-only `fw audit` is fine" and "your only repo writes are these two files" — both
   cannot be literally true, since `fw audit` writes a dated snapshot every run
   (`.context/audits/2026-09-25.yaml`, confirmed new this session). Recorded by round 3 as a
   brief-internal contradiction, resolved in favor of not reverting an append-only ledger write.
6. **Yardstick vs. repo mass.** The confirmed purpose names one product (the Designer, one
   11,503-line file). The repo is ~30:1 tooling/docs/config by file count around it (3,207 `.md` +
   1,915 `.yaml` + 415 `tools/` files vs. 98 total `.html`). Not inherently wrong — a governed
   framework needs supporting material — but worth the operator's explicit awareness given F-02
   independently found the `tools/` slice of that mass churns 15× more than the product it exists
   to verify.
7. **CLAUDE.md warns about its own failure mode and still exhibits it.** The P-009 section
   explicitly names T-614 as a prior instance of "illustrative numbers going stale when
   `CONTEXT_WINDOW` changes" — and the configured value (800K) has since drifted 2.67× from the
   300K the section still prints as its worked example (F-13).

---

## 11. Not reviewed

Carried forward verbatim from the evidence file's per-round "Not reviewed" lists (not
independently re-attempted by this JUDGE round, which read evidence only):

- `tests/fixtures/`, `tests/data/`, `tests/goldens/` — contents never enumerated
- `.agentic-framework/docs/` (1,643 files), `lib/` (461 files), `web/` (261 files) — not opened
  beyond two path checks
- `.context/arcs/*.yaml` content (beyond title/status/description already summarized),
  `.context/cron/`, `.context/designer/projects/` (18 BPMN working copies)
- Full corpus counts for `examples/aef-processes/` and `build/gallery/` — listing only, all three
  rounds
- Complexity analysis of the embedded JavaScript inside `src/aef-workflow-designer.html` — only
  commit-churn (149 commits) was measured
- Per-active-task cross-tabulation of which tasks carry how many `tools/` "pending" instruments as
  their only live path
- Full `git log -S<filename>` (content-diff) search for all 358 `tools/` files
- Shell HEREDOC / multi-line string false-negative reference edges in the T-451 closure tool's own
  stated open limitation
- This JUDGE round did not re-open any of the 358-row per-file `tools/` table beyond the aggregate
  counts and the named 5-file zero-reference set already surfaced in the evidence file

---

## 12. Sovereign questions

Each surfaced with a recommendation; none decided here.

1. **BVP `bvp_scores` confirmation stuck at 0/155.** This is explicitly a sovereignty-boundary
   field (`policy/value-drivers.yaml` header: "only set after human or agent confirmation").
   *Recommendation:* the operator should rule whether proposed-only scores are sufficient for
   ranking purposes as currently used, or whether confirmation should become a required workflow
   step. Left unruled, this field will likely stay at 0 indefinitely regardless of how much
   proposal-scoring work continues (it already didn't move across 2 dispatched scoring rounds this
   week per the evidence file).
2. **`.context/audits/cron/` 744-file git/disk divergence (F-12).** Touches ledger integrity for
   D2 Reliability, a protected driver. *Recommendation:* investigate before the next `fw audit`
   run further muddies the picture; do not let this JUDGE round's classification (INVESTIGATE)
   stand in for the operator's own look.
3. **`dist/` retention policy — 17 releases, 13.5MB, unbounded, git-tracked forever, no documented
   rule either way.** *Recommendation:* rule explicitly: keep-forever-as-audit-trail (consistent
   with `MANIFEST.yaml`'s structured `supersedes`/`released`/`src_commit` fields, which read as
   deliberately built for exactly that) or prune/archive outside git. Either is defensible; the
   gap is the absence of a ruling, not the current state being wrong.
4. **`_t350-teeth.sh` (F-11) — do not lift its exclusion without explicit human sign-off.** This is
   already how it is being treated (excluded by two independent tools); this JUDGE round simply
   confirms that stance should not change without a sandboxed, human-reviewed verification first.
5. **Whether 832 patches its own vendored copy of `.agentic-framework/metrics.sh`'s arithmetic bug**
   (12× `[: 0 0: integer expression expected` per `fw metrics` run, non-fatal but present every
   run) **or waits for an upstream fw release.** Touches the vendoring/portability boundary (D4).
   *Recommendation:* consistent with the standing SQ-1 precedent (`fw workflow run` is "not 832's
   to build"), default to reporting upstream and waiting, unless the fix is trivial and isolated
   enough to patch locally without diverging from the vendored baseline.
6. **Whether `fw termlink dispatch` should get a lighter-weight `workflow_type` for
   research/GATHERER tasks (F-03).** This changes what G-020, a Tier-1 gate, polices — an
   authority-adjacent change even though the current friction is real and measured 4/4 times in
   this very review series. *Recommendation:* yes, add the lighter type, but treat the gate-policy
   change itself as needing explicit operator approval, not silent agent action.

---

**End of report.** Proposed tasks above are not created. Ranking within each axis (§6 row order)
is by measured cost/risk against value per unit effort, per the review's own instructions; the
operator should treat row order as a suggestion, not a queue.
