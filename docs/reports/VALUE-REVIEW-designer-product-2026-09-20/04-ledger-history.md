# 04 — Ledger History (GATHERER evidence)

**Leg:** history evidence for the Workflow Designer product value review (T-742).
**Role:** GATHERER. Facts only. No classification, no recommendation. A JUDGE classifies later.
**Tree state:** HEAD `12ad8f9f` (2026-09-20), 2265 commits on `master`. All measurements taken 2026-09-20/21.
**Telemetry:** there is NO product usage telemetry in this repo (operator-confirmed). Every "not observed" below is **UNMEASURED**, never "unused".

---

## 0. Scope filter, and its two measured defects

The brief specifies "the 23 active + 173 completed tasks that name `aef-workflow-designer.html`". Reproducing that filter against the live tree:

```
grep -rl 'aef-workflow-designer.html' .tasks/active     -> 24
grep -rl 'aef-workflow-designer.html' .tasks/completed  -> 173
```

**Conflict recorded, not averaged:** active is **24**, not 23. The extra file is `T-742` (this review's own task), created 2026-09-20, i.e. after the brief's count was taken. Completed matches at 173. Corpus used throughout = **197 tasks**.

Two measured limits of this filter, both of which bound every number below:

| Defect | Measurement | Effect |
|---|---|---|
| **Filter over-includes** | 76 of 197 corpus tasks (39%) never produced a single commit touching `src/aef-workflow-designer.html`. Concentrated in gates/verification infra (23), export/DI (8), other/meta (6), release (6). | A task can name the file in a verification command or an evidence line without changing the product. |
| **Filter under-includes** | 12 tasks produced src commits but are NOT in the corpus: T-062, T-063, T-228, T-258, T-261, T-340, T-355, T-358, T-575, T-601, T-602, T-618. That is 12 of 144 src commits (8%). | Per-area commit counts below undercount by ~8%; the miss is concentrated in 2026-08/09 work. |

**Correction to my own first pass:** an earlier run of the co-change measurement used `git log --name-only -- <path>`, which pathspec-filters the *displayed* file list and reported 0/144 commits touching tests. That number is wrong and is not used. All coupling figures below come from `git show --name-only` per commit, which lists the full commit.

---

## 1. Evidence table

| Item | Source | Status of source | Data point (with citation) | Window | Kind |
|---|---|---|---|---|---|
| Corpus size | `.tasks/active`, `.tasks/completed` | EXISTS | 197 tasks name the product file: 24 active + 173 completed | 2026-06-04 → 2026-09-20 | structure |
| Task status split | frontmatter `status:` across corpus | EXISTS | work-completed 183, started-work 11, captured 3 | whole life | structure |
| Workflow type split | frontmatter `workflow_type:` | EXISTS | build 173, inception 13, test 5, design 4, specification 1, refactor 1 | whole life | structure |
| Owner split | frontmatter `owner:` | EXISTS | agent 110, human 81, claude-code 6 | whole life | structure |
| **Structural reopens** | git path timeline over `.tasks/` (A/M/R events per task, chronological) | EXISTS | **0** tasks ever moved `completed/ → active/`. Also 0 rename-detected reopens (`git log --diff-filter=R`). | whole life | structure |
| "reopen" as a word | `grep -ril reopen .tasks/` | EXISTS | 16 files repo-wide; 9 in the corpus (T-096, T-229, T-257, T-286, T-301, T-324, T-364, T-423, T-501) | whole life | friction |
| **Partial-complete backlog** | `.tasks/active/*.md` frontmatter | EXISTS | **10 tasks sit in `active/` with `status: work-completed`** — T-233, T-308, T-310, T-368, T-423, T-579, T-589, T-590, T-600, T-671. All `owner: human`. | 2026-07-22 → 2026-09-09 | friction |
| Oldest stuck partial-complete | frontmatter `last_update` | EXISTS | T-233/T-308/T-310/T-368 all last touched `2026-08-16T14:3X:XXZ` → **1290 repo commits have landed since** | 36 days / 1290 commits | friction |
| **Agent vs human AC completion** | `## Acceptance Criteria` parse, 23 open product tasks (T-742 excluded) | EXISTS | **Agent ACs 120/127 = 94% ticked. Human ACs 7/60 = 12% ticked.** | as of 2026-09-20 | friction |
| Fully agent-verified, zero human ACs | same parse | EXISTS | **13 of 23** open tasks are agent-complete with 0 human ACs ticked (T-233, T-308, T-310, T-368, T-209, T-286, T-579, T-344, T-589, T-671, T-600, T-590, T-423) | as of 2026-09-20 | friction |
| All ACs ticked, still open | same parse | EXISTS | **T-105** (agent 6/6, human 1/1) and **T-309** (agent 3/3, human 1/1) are fully ticked and still in `active/` | as of 2026-09-20 | friction |
| **Handover carry-forward** | `grep -l '^### T-0XX:' .context/handovers/S-*.md`, N=640 files, span 2026-06-04 → 2026-09-20 | EXISTS | T-041 carried in **625/640 handovers (97%)**; T-102 576 (90%); T-105 574 (89%); T-125 550 (85%); T-209 478 (74%); T-264 420 (65%); T-286 408 (63%); T-293 407 (63%); T-309 396 (61%); T-341 345 (53%); T-344 343 (53%) | 640 handovers | friction |
| Recurring blocker phrase | `grep -hiE 'blocked (on\|by\|at)' .context/handovers/S-*.md` | EXISTS | **"blocked on one ruling" x320**; "blocked on an operator decision written as an agent AC is invisible to every review surface" x62; "blocked on A-020" x59; "blocked on the operator ruling" x18 | 640 handovers | friction |
| **src commit count** | `git log -- src/aef-workflow-designer.html` | EXISTS | **144 commits**, 2026-06-05 (`61242508`) → 2026-09-09 (`66e04cff`) | 96 days | structure |
| **Knowledge concentration** | `git log --format='%an <%ae>' -- src/...` | EXISTS | **144/144 commits (100%) by Dimitri Geelen `<dimitri@geelenandcompany.com>`.** Zero other committers on the product file across its entire history. *(Recorded, not editorialised.)* | whole life | structure |
| src churn | `git log --numstat -- src/...` | EXISTS | **+11,957 / −709** lines across 144 commits. Current file **11,248 lines**. Deleted-to-added ratio **5.9%**. | whole life | cost |
| Seeding commit | `61242508` 2026-06-05 | EXISTS | The single largest commit is the initial promote (T-012) at 4,618 lines changed — 39% of all churn. Post-seed development ≈ +7,300 / −709 over 143 commits. | 2026-06-05 | structure |
| **True reverts on src** | `git log --format='%h %s' -- src/... \| grep -i revert` | EXISTS | 4 subject-line matches, **0 are git reverts**. `8eb16dd8` (T-125 "lane revert"), `e41e8686` (T-148 revert-toast fix), `a34daeaf` (T-131 version-revert UI), `3f03a543` (T-079 Ctrl+Z revert). All are the product's own *revert feature*, not history reversal. **Fix/revert ratio: 38 fix-shaped subjects / 144 commits (26%); revert ratio 0/144.** | whole life | structure |
| **Test coupling** | `git show --name-only` per src commit | EXISTS | 27/144 (19%) also touched `tests/`; 62/144 (43%) also touched `tools/`; 65/144 (45%) touched either; 13/144 (9%) touched `docs/`; 4/144 (3%) touched `examples/`. **75/144 (52%) shipped with no test, tool or doc change at all.** | whole life | cost |
| Strongest single co-change | same | EXISTS | `tests/run-bridge-tests.sh` co-changes with src in **19/144 commits (13%)** — the only non-bookkeeping file above 6 | whole life | structure |
| Bookkeeping co-change | same | EXISTS | `.context/project/decisions.yaml` 15; `.context/working/.hook-counter` / `.edit-counter` / `.budget-status` / `.budget-gate-counter` 10 each; `.context/project/learnings.yaml` 7 | whole life | structure |
| **Probe-per-task tooling** | `ls tools/` | EXISTS | **215 of 331 files in `tools/` (65%) are `_`-prefixed one-offs**, largely `_t<NNN>-*-cdp.mjs` named for a single task (`_t308-`, `_t310-`, `_t311-`, `_t361-`, `_t406-`, `_t338-`, `_t258-`, `_t259-`…) | whole life | cost |
| Standing test suite | `ls tests/` | EXISTS | 51 files. 18 are `test_t<NNN>_*.py` — named for one originating task (t125, t258, t259, t264, t293, t308, t310–t317) | whole life | structure |
| **src commits per month** | `git log --date=short -- src/...` | EXISTS | 2026-06: **1**; 2026-07: **118**; 2026-08: **24**; 2026-09: **1**. Distinct tasks landing on src: Jun 1, Jul 107, Aug 24, Sep 1. | 96 days | usage |
| Last src commit | `66e04cff` | EXISTS | 2026-09-09 (T-690). **12 days with no product-file commit as of 2026-09-21.** | current | usage |
| **Gate bypasses** | `.context/working/.gate-bypass-log.yaml` (1011 lines, 148 entries, 2026-06-05 → 2026-09-08) | EXISTS | **72/148 entries (49%) belong to corpus tasks.** Flags, corpus-only: `FW_SWITCH_FOCUS=1` **58**, `--skip-sovereignty` **14**. | 95 days | friction |
| Bypass concentration | same | EXISTS | **T-041 alone accounts for 28 bypasses** (19% of the whole log). Then T-155 x7, T-112 x6, T-105 x3, T-501 x3. | 95 days | friction |
| **Completion gates never bypassed** | same | EXISTS | **0 `--force` entries, 0 AC-gate bypasses, 0 verification-gate (P-011) bypasses** in the entire 148-entry log. Every corpus bypass is focus-drift (58) or inception-GO sovereignty (14). | 95 days | value |
| Note on the brief's path | — | EXISTS | The brief names `.context/working/.gate-bypass-log.yaml` (43,446 bytes, 148 entries) — correct. A second, near-empty `.context/bypass-log.yaml` (9 lines) also exists; not used here. | — | structure |
| **Concerns naming the product** | `.context/project/concerns.yaml` (3413 lines, 48 concerns) | EXISTS | **32 of 48 concerns (67%)** cite a corpus task or name designer/editor/canvas/gallery. Status: **watching 28, prevention-in-place 2, resolved 2.** Severity: high 17, medium 15. | whole life | friction |
| G-005 (no document autosave) | `.context/project/concerns.yaml` G-005 | EXISTS | `severity: high`, `status: watching`, detected 2026-07-06, origin T-126. `closure_evidence.verified: '2026-07-28 (T-271)'`, `status_note: "READY FOR CLOSURE — operator to flip watching→resolved. Trigger is met verbatim."` **Still `watching` 55 days later.** | 2026-07-28 → now | friction |
| G-003 (pointer paths untested) | concerns.yaml G-003 | EXISTS | `watching`, medium: "Editor pointer-interaction paths have zero trusted-input test coverage — 2 field-found bugs in one day". Cites T-069, T-070, T-071, T-074, T-076, T-077. | open | cost |
| G-015 (verification blocks assert a moving global) | concerns.yaml G-015 | EXISTS | `watching`: "75 verification blocks assert a GLOBAL, always-moving property — `diff src/aef-workflow-designer.htm…`". Cites T-093, T-102, T-105, T-152, T-165, T-252, T-309. | open | friction |
| G-024 (pinned artifact vs src) | concerns.yaml G-024 | EXISTS | `watching`, high: "No instrument holds the pinned artifact and src at the same time — a consumer-visible fix can sit un[shipped]". Cites 7 corpus tasks (T-310, T-311, T-315, T-337, T-361, T-364, T-368). | open | friction |
| G-027 (done-but-not-closed invisible) | concerns.yaml G-027 | EXISTS | `watching`: "No instrument detects a task that is fully verified and one command from done: all ACs ticked + owner…". Matches the measured T-105 / T-309 state above. | open | friction |
| G-044, G-046, G-051 | concerns.yaml | EXISTS | G-044 high: "The only place 5 gating guards are evaluated is a 13-minute suite nothing schedules" (cites T-155, T-293). G-046 high: operator DECISION filed as an Agent AC is invisible to every review surface (T-155, T-423, T-510). G-051 high: a recorded DEFER deletes an inception from the surface (T-155). | open | friction |
| **Healing patterns** | `.context/project/patterns.yaml`; `fw healing patterns` | EXISTS | 17 failure_patterns, 5 success_patterns, 1 antifragile, 4 workflow. **4 failure patterns originate in corpus tasks:** FP-006 (T-112, premature closure), FP-007 (T-118, silent error bypass), FP-009 (T-293, retest-link-unreachable), FP-012 (T-399, authorship inferred from content). FP-013 (from T-409) cites T-399. **1 success pattern** (SP-002, T-002). | whole life | value |
| FP-009 detail | `fw healing patterns` | EXISTS | "Field failure was environmental: operator-reachable designers all serve pinned 0.7.1 (predates fix) and :8834 has no ufw allow rule… Code fix verified 12/12 zoom legs + 8/8 served real-click legs." | 2026-07/08 | friction |
| **Episodic coverage** | `.context/episodic/` (612 files) | EXISTS | 173 of 183 completed corpus tasks have an episodic record. **The 10 missing are exactly the 10 partial-complete tasks stuck in `active/`** (T-233, T-308, T-310, T-368, T-423, T-579, T-589, T-590, T-600, T-671). | whole life | structure |
| Episodic challenges density | episodic `challenges:` field | EXISTS | Only **52 of 173 (30%)** carry a non-empty `challenges` block. Densest: gates/verification infra 10, export/DI 8, persistence 8. | whole life | structure |
| **Corrupt episodic durations** | episodic `duration_days:` | EXISTS | Of 173: **135 record `0` (78%), 2 record a negative value, 36 positive.** `T-093` records **`duration_days: -20637`** (≈ −56 years); `T-163` records `-1`. Positive-only: median 3d, max 25d. | whole life | structure |
| G-040 corroboration | concerns.yaml G-040 | EXISTS | `watching`: "Episodic memory is written and never read again, so a corrupt episodic is invisible from the moment [it is written]" (cites T-562). The T-093 value above is a live instance. | open | friction |
| Audit discoveries | `.context/audits/discoveries/LATEST.yaml` | EXISTS | Zero occurrences of "designer" in the current discoveries record. | current | UNMEASURED |

---

## 2. Rework magnets — which tasks other tasks keep coming back to

Method: for each corpus task, count how many *other corpus tasks* reference it in non-comment body text. Comment lines are stripped first.

**Measured false positive, recorded:** an initial run reported `T-077 x175`. That is boilerplate — `.tasks/templates/default.md:85` contains `# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).`, inherited by every task file. Excluded.

| Task | Refs | Open? | Area | Title |
|---|---|---|---|---|
| T-105 | 10 | **ACTIVE** | gates/verification | Baked corpus regression: aligned gateways collide their edge-labels |
| T-041 | 10 | **ACTIVE** | other/meta | Render inception-review and run operator fidelity pilot |
| T-093 | 9 | done | layout/routing | Branch pitch setting: parallel-block stack spacing |
| T-423 | 8 | **ACTIVE** | export/DI | T-357 step 2: emit BPMN DI additively alongside aef:position |
| T-204 | 7 | done | palette/events | Typed BPMN event palette: error/timer/message + boundary events |
| T-337 | 7 | done | import/parse | Import silently drops flow nodes outside the parseBpmn allow-list |
| T-094 | 7 | done | lanes & pools | Align rows one-shot action |
| T-309 | 6 | **ACTIVE** | validator | Surface workflow validator findings in the designer |
| T-102 | 6 | **ACTIVE** | layout/routing | mapMessiness false-positive: branch-stack pitch fires Clean nudge |
| T-117 | 6 | done | layout/routing | De-jog routed edges |
| T-399 | 6 | done | export/DI | Bridge red: T-361 trailer check treats an AEF fixture as one of ours |
| T-043 | 6 | done | layout/routing | inception-review diagram exceeds canvas viewport |
| T-085 | 6 | done | labels | View density + label visibility/size controls |
| T-107 | 6 | done | layout/routing | Align columns one-shot action |

Two reference clusters dominate, and they barely touch each other:

- **Geometry cluster** — T-093 / T-094 / T-102 / T-105 / T-107 / T-117 / T-085 / T-043. Referenced almost entirely by tasks created in the same 5-day window (see §3).
- **Contract cluster** — T-423 / T-399 / T-361 / T-364 / T-501 / T-570 / T-337. Referenced by tasks spread across 2026-08 and 2026-09, i.e. still generating successors at the end of the window.

---

## 3. Per-area hotspots, cadence and churn

Areas assigned by keyword match on task name (first match wins, ordered list). Churn = `+ / −` lines on `src/aef-workflow-designer.html` attributed via the `T-NNN:` prefix in the commit subject.

| Area | Tasks | Open | Bug-shaped name | src commits | src churn | First task | Last task | Last src commit |
|---|---|---|---|---|---|---|---|---|
| layout/routing engine | 30 | 1 | 13% | 28 | 1,946 | 2026-07-03 | **2026-07-07** | **2026-07-07** (T-139) |
| gates/verification infra | 28 | 5 | 46% | 6 | 193 | 2026-07-05 | 2026-09-03 | 2026-07-27 (T-264) |
| persistence / versioning | 22 | 0 | 23% | 20 | 995 | 2026-07-06 | 2026-08-27 | 2026-07-22 (T-234) |
| export / serialization / DI | 18 | 2 | 28% | 11 | 543 | 2026-07-03 | **2026-09-09** | **2026-09-09** (T-690) |
| lanes & pools | 13 | 3 | 38% | 11 | 966 | 2026-07-04 | 2026-08-26 | 2026-08-26 (T-600) |
| identity / uid / refs | 12 | 0 | 25% | 8 | 244 | 2026-07-20 | 2026-08-26 | 2026-08-24 (T-563) |
| open-project / gallery UI | 11 | 2 | **55%** | 7 | 276 | 2026-07-09 | 2026-08-09 | 2026-08-14 (T-233) |
| other/meta | 10 | 2 | 30% | 4 | 199 | 2026-06-04 | 2026-09-20 | 2026-07-10 (T-168) |
| labels & text fit | 10 | 1 | 10% | 11 | 607 | 2026-07-03 | 2026-07-28 | 2026-07-28 (T-286) |
| canvas view chrome / nav | 9 | 2 | 44% | 7 | 325 | 2026-07-03 | 2026-08-27 | 2026-07-28 (T-293) |
| palette / node & event types | 9 | 1 | 11% | 10 | 649 | 2026-07-04 | 2026-08-27 | 2026-07-29 (T-308) |
| import / BPMN parse | 9 | 1 | **56%** | 4 | 237 | 2026-07-02 | 2026-08-26 | 2026-08-26 (T-603) |
| release / dist / build | 7 | 2 | 14% | 1 | 4,618¹ | 2026-06-05 | 2026-08-27 | 2026-06-05 (T-012) |
| validator surfacing | 5 | 1 | 20% | **0** | **0** | 2026-07-29 | 2026-08-12 | **never** |
| properties panel / inspector | 4 | 1 | 25% | 4 | 234 | 2026-07-09 | 2026-08-25 | 2026-08-26 (T-589) |
| **TOTAL** | **197** | **24** | **29%** | 144 | 11,957/709 | | | |

¹ The 4,618 figure is the single T-012 seeding commit, not release work.

### 3a. The layout/routing burst — verified per task

The largest area by task count was created in **five days and never revisited**. Verified by listing all 30 with `created:`:

```
T-042 2026-07-03 … T-095 2026-07-04 … T-102/T-097/T-098/T-099/T-100/T-106/T-107/T-108/
T-109/T-111/T-112/T-114/T-115/T-116/T-117/T-118/T-119 2026-07-05 …
T-121/T-134/T-137 2026-07-06 … T-139 2026-07-07
```

- 30 tasks created 2026-07-03 → 2026-07-07; **29 closed, 1 open (T-102)**.
- **Zero new layout/routing tasks in the 75 days since 2026-07-07.**
- **Zero src commits in that area since 2026-07-07** (`T-139`, `git log -- src/`).
- Nine of these tasks record `duration_days` of 24–25 in episodic (T-095, T-094, T-087, T-079, T-100, T-099, T-098, T-097, T-096) — the longest durations in the whole corpus.
- **Conflicting signal, recorded side by side:** the handover WIP section currently carries `### T-599: "Manual connector routing: add/remove waypoints and give the operator real control over the path"` (`.context/handovers/LATEST.md:105`). T-599 is **not** in the corpus — its task file does not name the product file — so it is invisible to every per-area count in this table. Its ACs stand at agent 0/5, human 0/2.

### 3b. Test coupling is split by area, not uniform

Share of each area's src commits that also carried a `tests/` or `tools/` change:

| 100% | import/parse (4/4) |
| 82% | export/DI (9/11) |
| 75% | other/meta (3/4) |
| 62% | identity/uid (5/8) |
| 60% | palette/events (6/10) |
| 57% | canvas nav (4/7) |
| 55% | lanes & pools (6/11) |
| 43% | open-project/gallery (3/7) |
| 30% | persistence/versioning (6/20) |
| 18% | layout/routing (5/28) |
| 17% | gates/verification (1/6) |
| **0%** | **labels & text fit (0/11)**, release/dist (0/1) |

The gradient runs data-contract → geometry/visual. G-003 (`concerns.yaml`, `watching`) states the same thing independently for pointer paths.

---

## 4. Tasks in flight, and how long

`status != work-completed` in `.tasks/active/`. Staleness measured in **repo commits since `last_update`**, not calendar.

| Task | Status | Owner | Horizon | Created | Last update | Commits since | Area |
|---|---|---|---|---|---|---|---|
| T-102 | started-work | human | later | 2026-07-05 | 2026-08-23 | 486 | layout/routing |
| T-105 | started-work | human | later | 2026-07-05 | 2026-08-23 | 486 | gates/verification |
| T-125 | captured | human | later | 2026-07-06 | 2026-08-23 | 486 | lanes & pools |
| T-209 | started-work | human | later | 2026-07-19 | 2026-08-23 | 486 | release/dist |
| T-264 | captured | human | later | 2026-07-27 | 2026-08-23 | 486 | gates/verification |
| T-286 | started-work | human | later | 2026-07-28 | 2026-08-23 | 486 | labels & text fit |
| T-344 | started-work | human | later | 2026-08-02 | 2026-08-25 | 458 | canvas nav |
| T-293 | started-work | human | **now** | 2026-07-28 | 2026-08-29 | 295 | canvas nav |
| T-041 | started-work | human | later | **2026-07-03** | 2026-09-01 | 203 | other/meta |
| T-309 | started-work | human | later | 2026-07-29 | 2026-09-01 | 203 | validator |
| T-341 | started-work | agent | **now** | 2026-08-02 | 2026-09-09 | 79 | import/parse |
| T-691 | captured | human | later | 2026-09-09 | 2026-09-09 | 79 | export/DI |
| T-155 | started-work | agent | **now** | 2026-07-09 | 2026-09-20 | 0 | open-project |
| T-742 | started-work | agent | **now** | 2026-09-20 | 2026-09-20 | 0 | (this review) |

**Horizon distribution:** 10 of the 14 in-flight tasks carry `horizon: later`, which per CLAUDE.md excludes them from Suggested First Action. Six of those ten (T-102, T-105, T-125, T-209, T-264, T-286) last moved on the same day, **2026-08-23** — a single batch event, not 6 independent decisions.

**Nothing in this corpus was abandoned in the sense of being deleted, closed empty, or reverted.** 0 reopens, 0 git reverts, 0 tasks removed from the ledger. The observable failure mode is **carry, not abandonment**: tasks stay in `active/`, keep appearing in handovers, and stop being touched.

### T-041 — the single most-carried item in the project

| Signal | Value | Citation |
|---|---|---|
| Created | 2026-07-03T07:58:13Z, still `started-work` | task frontmatter |
| Owner flipped to human | 2026-07-03T08:00:23Z, **2 minutes after creation** | `## Updates` in task file |
| Handovers carrying it | **625 / 640 (97%)** | `grep -l '^### T-041:' .context/handovers/S-*.md` |
| Gate bypasses attributed | **28** (19% of the entire 148-entry log) | `.gate-bypass-log.yaml` |
| Referenced by other corpus tasks | 10 | §2 |
| Agent ACs | **6/6 ticked** | AC parse |
| Human ACs | **1/3 ticked** | AC parse |
| Recorded recommendation | `**Recommendation:** GO` — "All 6 Agent ACs verified… The remaining Human AC is the A-4 fidelity judgment (does the rendered inception-review match the flow you experienced) — genuinely yours, everything needed is one click away." | task `## Recommendation` |
| Recorded evidence of readiness | "Gallery LIVE at http://192.168.10.107:8834/ (re-verified **2026-07-22**) — click **inception-review**"; "24/24 corpus maps rendered warn-free" | same |

---

## 5. Non-use diagnosis evidence (A–E) — evidence only, no reading selected

Per the brief, the evidence separating the readings is recorded side by side. **The JUDGE selects; this section does not.**

### 5.1 validator surfacing — 5 tasks, 0 src commits, 0 churn

| Reading | Evidence for | Evidence against |
|---|---|---|
| **A BROKEN** | G-016 `watching`: "The export-safety instrument is DIFFERENTIAL — it compares two designer versions to each other" (cites T-309, T-337, T-341). G-044 `watching` high: the 5 gating guards are only evaluated in "a 13-minute suite nothing schedules". | No failing test is cited against the validator surface itself. |
| **B NEVER WIRED** | **0 src commits ever attributed to this area** — the surface was never built into the product file. T-309 ("Surface workflow validator findings in the designer") is `started-work`, `horizon: later`, open since 2026-07-29. T-349 is literally titled "Can any T-309 surface ever show the impo[rt]…". | T-309 has **agent 3/3 and human 1/1 ACs ticked** — every box is checked, yet it sits in `active/`. G-027 describes exactly this state. |
| **C UNDISCOVERABLE** | Not measured on this leg (docs/help coverage is another leg's scope). | — |
| **D UNMEASURED** | No product telemetry exists (operator-confirmed). Nothing observes whether a validator finding is ever read. | — |
| **E NOT WANTED** | **No positive recorded reason found.** No DEFER rationale, no NO-GO, no concern saying the need is gone. | T-309 is referenced by 6 later corpus tasks (T-310, T-317, T-337, T-341, T-349, T-350) — continued demand, not withdrawal. |

**INTENT evidence:** referenced by 6 successor tasks; named in G-016 and G-045; carried in 396/640 handovers (61%).

### 5.2 layout/routing engine — 30 tasks, then 75 days of silence

| Reading | Evidence for | Evidence against |
|---|---|---|
| **A BROKEN** | T-102 (`mapMessiness false-positive`) still open. G-015 `watching`: 75 verification blocks assert a moving global, citing T-093, T-102, T-105. T-105 is explicitly blocked on mirror drift **by design** (per the review brief). | 29/30 tasks closed; 0 reverts; 28 src commits landed. |
| **B NEVER WIRED** | — | The area has the **second-highest churn (1,946 lines)** and T-139 explicitly *retired* two toolbar buttons — features reached the UI and were then pruned. |
| **C UNDISCOVERABLE** | T-111 exists: "Surface distribute-align-columns trade-off in editor tooltips" — discoverability was itself a task, and it closed. | — |
| **D UNMEASURED** | No telemetry on whether Clean/Align/Distribute are ever invoked. T-096 ("Density setting has no visible effect") was resolved as a *perception* issue: episodic records "mechanism verified working; fix = [make it] apply live". | — |
| **E NOT WANTED** | **T-139 "Retire Align-columns and Distribute-evenly toolbar buttons"** — closed 2026-07-07. This is a positive recorded decision to remove surface. Scope: 2 buttons, not the area. | The other 28 features carry no such record. |

**Conflicting signals, recorded side by side:** (a) zero new layout tasks and zero src commits for 75 days; (b) T-599 "Manual connector routing… give the operator real control over the path" sits in the current handover WIP at agent 0/5 — live demand for routing control, filed outside the corpus filter.

### 5.3 The 10 partial-complete tasks

| Reading | Evidence |
|---|---|
| **A BROKEN** | None of the 10 has a failing agent AC — all are **agent-AC-complete** (T-590 at 11/11, T-310 and T-423 and T-233 at 8/8). |
| **B NEVER WIRED** | Not applicable — 9 of the 10 produced src commits. |
| **C UNDISCOVERABLE** | **All 10 lack an episodic record** (`.context/episodic/` miss list, §1) — so `fw recall` cannot surface them. G-040 `watching` states episodic "is written and never read again". 4 of the 10 (T-310, T-368, T-308, T-579) appear in **0–6 of 640 handovers**, i.e. they are not carried in the WIP surface either. |
| **D UNMEASURED** | Human ACs are verification steps that were never executed; no instrument records whether they were attempted. |
| **E NOT WANTED** | **No positive recorded reason.** G-027 and G-046 both say the opposite — these tasks are invisible to review surfaces, not declined. |

**INTENT evidence:** human ACs 0/32 across these 10; agent ACs 69/69. G-046 (`high`, `watching`) names the mechanism: "A task blocked on an operator DECISION written as an Agent AC is invisible to every review surface".

---

## 6. Sources expected and found ABSENT or mismatched

| Expected | Found | Status |
|---|---|---|
| `.context/patterns.yaml` (brief's path) | Not at that path. Real path `.context/project/patterns.yaml`. | **path mismatch** — data EXISTS |
| `.context/working/.gate-bypass-log.yaml`, "1011 lines" | EXISTS, 43,446 bytes, 148 YAML entries. Line count not independently reconciled to 1011; entry count is 148. | EXISTS, count recorded as measured |
| Any product usage telemetry | **ABSENT** (operator-confirmed). No event log, no analytics, no instrumentation on any product path. | **ABSENT** |
| Any record of a reopened task | **ABSENT** — 0 across the whole ledger by two independent methods. | **ABSENT** |
| Any `--force` / AC-gate / verification-gate bypass | **ABSENT** — 0 in 148 entries. | **ABSENT** |
| Episodic for 10 partial-complete tasks | **ABSENT** — exactly the 10 stuck in `active/`. | **ABSENT** |
| "designer" in current audit discoveries | **ABSENT** — 0 mentions in `.context/audits/discoveries/LATEST.yaml`. | **ABSENT** |
| A second committer on `src/` | **ABSENT** — 144/144 one author. | **ABSENT** |
| `fw audit` live run | Not run — hangs by known defect (OBS-332/OBS-358), per brief. Saved records under `.context/audits/` read instead. | **not attempted, by instruction** |

---

## 7. Method notes and self-corrections

1. **Area classification is keyword-based on task names**, first-match-wins over an ordered pattern list. It is a heuristic. The `other/meta` bucket (10 tasks) is the residue. Per-area figures should be read as approximate, and the §0 scope defects (39% over-include, 8% under-include) bound them further.
2. **Bug-shaped name %** is a regex over the task *title*, not a classification of the work. It measures how the area was *described*, not what it was.
3. **Two measurement errors were made and corrected before reporting:** the `T-077 x175` template-boilerplate false positive (§2), and the `git log --name-only -- <path>` pathspec-filtering error that produced a false "0/144 commits touch tests" (§0). Neither wrong number is used above.
4. **`duration_days` from episodic is not trustworthy as a metric** — 78% record 0 and 2 record negatives including `T-093: -20637`. Only the 36 positive values (median 3d, max 25d) are cited, and they are cited as recorded values, not as true durations.
5. Commit-to-area attribution relies on the `T-NNN:` subject prefix. 12 src commits (8%) map to tasks outside the corpus and are reported separately rather than dropped.
