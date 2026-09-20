# 05 — Ledger Evidence (Gatherer G5)

Value review of `/opt/832-Workflow-designer`, 2026-09-20. **Evidence only — no classification, no recommendations.**

Ledger size at collection: **128 active + 611 completed = 739 task files** (`ls .tasks/active/*.md | wc -l`, `ls .tasks/completed/*.md | wc -l`).
No project-boundary (T-559) block was encountered; every read was inside the project root.
No `fw audit` was run (OBS-358); audit facts come from saved records under `.context/audits/`.

---

## 0. Membership has two sources of truth, and they disagree

`.context/arcs/designer-authoring-surface.yaml:1` → `id: arc-001`.
`.context/arcs/ewcr-governed-delivery.yaml:1` → `id: arc-002`.

| Membership source | arc-001 | arc-002 | Method |
|---|---|---|---|
| Frontmatter `^arc_id:` (canonical field per T-1849) | **15** | **25** | `grep -rn "^arc_id: <slug>" .tasks/{active,completed}/*.md` |
| `fw arc show <id>` (unions `arc_id:` + legacy `arc:<slug>` tag) | **32** | **27** | `.agentic-framework/bin/fw arc show arc-001 / arc-002` |
| `fw audit` finding, record `.context/audits/2026-09-20.yaml` | 32 (26 complete) | 27 (25 complete) | see §8 |

17 arc-001 tasks are members **only** via the legacy `tags: ["arc:designer-authoring-surface"]` form; their `arc_id:` is empty.

| Task | `arc_id:` | `tags:` |
|---|---|---|
| T-174, T-175, T-176, T-278, T-279, T-280, T-281, T-282, T-283, T-284, T-589 | *(empty)* | `[arc:designer-authoring-surface]` |
| T-198 | *(empty)* | `[release, arc:designer-authoring-surface]` |
| T-199 | *(empty)* | `[arc:designer-authoring-surface, conformance]` |
| T-352 | *(empty)* | `[arc:designer-authoring-surface, tooling, verification-gate]` |
| T-611 | *(empty)* | `[arc:designer-authoring-surface, arc:ewcr-governed-delivery]` — **dual member** |
| T-620 | *(empty)* | `[arc:designer-authoring-surface, arc:ewcr-governed-delivery]` — **dual member** |
| T-623 | `ewcr-governed-delivery` | `[arc:designer-authoring-surface]` — **fields disagree** |

T-611, T-620, T-623 are each listed by `fw arc show` under **both** arcs, so the two arc populations are not disjoint (3 tasks double-counted across the 32+27).

`fw arc --help` documents the cause: the `tag` verb "used to write the T-1851-deprecated `arc:<id>` tag INSTEAD of `arc_id:`… It no longer writes the tag; legacy tags already on a task are left in place and readers still union both forms."

---

## 1. Arc membership roster

### arc-001 — designer-authoring-surface (union set, 32)

anchor_task `T-175`; `status: in-progress`; `created: 2026-07-10T10:43:47Z`; `closed_at: null`; `demo_evidence: null`.

| id | loc | status | owner | date_finished | last_update |
|---|---|---|---|---|---|
| T-174 | completed | work-completed | human | 2026-07-10 | 2026-08-16 |
| T-175 | completed | work-completed | human | *(none)* | 2026-08-16 |
| T-176 | completed | work-completed | human | 2026-07-18 | 2026-08-16 |
| T-187 | completed | work-completed | agent | 2026-07-11 | 2026-08-16 |
| T-188 | completed | work-completed | agent | 2026-07-11 | 2026-08-16 |
| T-198 | completed | work-completed | agent | 2026-07-16 | 2026-08-16 |
| T-199 | completed | work-completed | agent | 2026-07-17 | 2026-08-16 |
| T-278 | completed | work-completed | agent | 2026-07-28 | 2026-08-16 |
| T-279 | **active** | **captured** | human | — | 2026-08-16 |
| T-280 | **active** | **captured** | human | — | 2026-08-16 |
| T-281 | **active** | **captured** | human | — | 2026-08-16 |
| T-282 | **active** | **captured** | human | — | 2026-08-16 |
| T-283 | completed | work-completed | agent | 2026-07-28 | 2026-08-16 |
| T-284 | completed | work-completed | agent | 2026-07-28 | 2026-08-16 |
| T-340 | **active** | **work-completed** | **human** | 2026-08-15 | 2026-08-16 |
| T-350 | completed | work-completed | agent | 2026-08-02 | 2026-08-16 |
| T-352 | completed | work-completed | agent | 2026-08-03 | 2026-08-16 |
| T-423 | **active** | **work-completed** | **human** | 2026-09-09 | 2026-09-09 |
| T-424 | **active** | **captured** | human | — | 2026-08-16 |
| T-425 | completed | work-completed | claude-code | 2026-08-10 | 2026-08-16 |
| T-488 | completed | work-completed | agent | 2026-08-13 | 2026-08-16 |
| T-489 | completed | work-completed | agent | 2026-08-13 | 2026-08-16 |
| T-513 | completed | work-completed | agent | 2026-08-15 | 2026-08-16 |
| T-562 | completed | work-completed | agent | 2026-08-20 | 2026-08-20 |
| T-563 | completed | work-completed | agent | 2026-08-24 | 2026-08-24 |
| T-564 | **active** | **captured** | agent | — | 2026-09-10 |
| T-565 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-08-26 |
| T-589 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-08-26 |
| T-611 | completed | work-completed | agent | 2026-08-27 | 2026-09-03 |
| T-620 | completed | work-completed | agent | 2026-08-27 | 2026-09-03 |
| T-623 | completed | work-completed | agent | 2026-08-27 | 2026-08-27 |
| T-690 | completed | work-completed | agent | 2026-09-09 | 2026-09-09 |

Horizon: `now` on T-340, T-423, T-565, T-589; `later` on T-279, T-280, T-281, T-282, T-424, T-564; blank/`null` on the archived set.

### arc-002 — ewcr-governed-delivery (union set, 27)

anchor_task `T-590`; `status: in-progress`; `created: 2026-09-03T05:18:09Z`; `closed_at: null`; `demo_evidence: null`.

| id | loc | status | owner | date_finished | last_update |
|---|---|---|---|---|---|
| T-587 | completed | work-completed | agent | 2026-08-26 | 2026-08-26 |
| T-590 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-09-03 |
| T-591 | completed | work-completed | agent | 2026-08-26 | 2026-09-03 |
| T-593 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-09-03 |
| T-594 | completed | work-completed | agent | 2026-08-26 | 2026-09-03 |
| T-595 | completed | work-completed | agent | 2026-08-26 | 2026-09-03 |
| T-596 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-09-03 |
| T-597 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-09-03 |
| T-608 | **active** | **work-completed** | **human** | 2026-08-26 | 2026-08-26 |
| T-610 | completed | work-completed | agent | 2026-08-27 | 2026-09-03 |
| T-611 | completed | work-completed | agent | 2026-08-27 | 2026-09-03 |
| T-619 | completed | work-completed | claude-code | 2026-09-05 | 2026-09-05 |
| T-620 | completed | work-completed | agent | 2026-08-27 | 2026-09-03 |
| T-623 | completed | work-completed | agent | 2026-08-27 | 2026-08-27 |
| T-670 | completed | work-completed | agent | 2026-09-05 | 2026-09-05 |
| T-671 | **active** | **work-completed** | **human** | 2026-09-03 | 2026-09-03 |
| T-680 | completed | work-completed | agent | 2026-09-05 | 2026-09-05 |
| T-681 | **active** | **started-work** | **human** | *(null)* | 2026-09-08 |
| T-682 | completed | work-completed | agent | 2026-09-07 | 2026-09-07 |
| T-683 | completed | work-completed | agent | 2026-09-07 | 2026-09-07 |
| T-684 | completed | work-completed | agent | 2026-09-07 | 2026-09-07 |
| T-685 | completed | work-completed | human | 2026-09-08 | 2026-09-08 |
| T-689 | completed | work-completed | agent | 2026-09-08 | 2026-09-08 |
| T-732 | **active** | **captured** | human | *(null)* | 2026-09-16 |
| T-733 | **active** | **work-completed** | **human** | 2026-09-16 | 2026-09-16 |
| T-734 | completed | work-completed | agent | 2026-09-19 | 2026-09-19 |
| T-736 | **active** | **work-completed** | **human** | 2026-09-20 | 2026-09-20 |

Horizon: `now` on all 8 active work-completed + T-681 + T-732; `null` on the archived set.

### Status distribution

| Bucket | arc-001 (32) | arc-002 (27) | Combined (56 distinct; 3 dual-member) |
|---|---|---|---|
| work-completed, archived in `completed/` | 22 | 17 | 36 distinct |
| work-completed, still in `active/`, owner human | **4** | **8** | **12** |
| started-work | 0 | **1** | 1 |
| captured | **6** | **1** | 7 |

---

## 2. The stall pattern

Categories (a)–(e) as requested, over the two union sets. Ages computed against **2026-09-20**.

| Cat | Definition | arc-001 | arc-002 |
|---|---|---|---|
| (a) | work-completed **and** archived in `completed/` | 22 | 17 |
| (b) | work-completed, still in `active/`, owner human — the review queue | **4** | **8** |
| (c) | started-work, **all** Agent ACs ticked | 0 | **1** (T-681) |
| (d) | started-work, open Agent ACs | 0 | 0 |
| (e) | captured | 6 | 1 |

### (b) Review queue — per-task age from `date_finished`

| Task | Arc | date_finished | Age (d) | Agent AC ok/open | Human AC ok/open | Audit D2 age |
|---|---|---|---|---|---|---|
| T-340 | 001 | 2026-08-15 | **36** | 3/0 | 0/1 | 36d (>30d bucket) |
| T-565 | 001 | 2026-08-26 | **25** | 5/0 | 0/1 | 25d |
| T-589 | 001 | 2026-08-26 | **25** | *(not re-measured; in D2 at 25d)* | — | 25d |
| T-423 | 001 | 2026-09-09 | 11 | 8/0 | 0/1 | *(not in D2 >14d list)* |
| T-590 | 002 | 2026-08-26 | **25** | 11/0 | 0/3 | 25d |
| T-593 | 002 | 2026-08-26 | **25** | 7/0 | 0/2 | 25d |
| T-596 | 002 | 2026-08-26 | **25** | 7/0 | 0/1 | 25d |
| T-597 | 002 | 2026-08-26 | **25** | 8/0 | 0/2 | 25d |
| T-608 | 002 | 2026-08-26 | **25** | 7/0 | 0/1 | 24d |
| T-671 | 002 | 2026-09-03 | **17** | 5/0 | 0/1 | 17d |
| T-733 | 002 | 2026-09-16 | 4 | 4/0 | 0/1 | — |
| T-736 | 002 | 2026-09-20 | 0 | 5/0 | 0/1 | — |

**Every one of the 12 has zero open Agent ACs.** The only thing unchecked on each is a Human AC. Method: `awk '/^### Agent/{a=1;next}/^### Human/{a=0}/^## /{a=0}a'` then count `^- \[ \]` vs `^- \[x\]`; same for the `### Human` block.

### (c) started-work with all Agent ACs ticked

| Task | Arc | status | last_update | Age (d) | Agent AC | Human AC |
|---|---|---|---|---|---|---|
| T-681 | 002 | started-work | 2026-09-08 | **12** | 3 ok / 0 open | **1 ok / 0 open** |

T-681 has **all four ACs ticked (Agent and Human) and is still `started-work`** — `date_finished: null`. It is named in the recurring audit finding `CTL-029` (§8) and has its own remediation task T-722 (`RA-026: CTL-029 T-681 has all Agent ACs ticked but…`, `.tasks/active/T-722-*.md:15`, `arc_id: arc-003`).

### (e) captured

| Task | Arc | horizon | last_update | Age (d) | Agent AC ok/open |
|---|---|---|---|---|---|
| T-279, T-280, T-281, T-282 | 001 | later | 2026-08-16 | 35 | — |
| T-424 | 001 | later | 2026-08-16 | 35 | 0/2 |
| T-564 | 001 | later | 2026-09-10 | 10 | 0/2 |
| T-732 | 002 | now | 2026-09-16 | 4 | 4/0 (5 Human open) |

---

## 3. Rework / reopen / correction

Restricted to the two arcs. Cited by file:line.

| Task | Arc | Marker | Evidence |
|---|---|---|---|
| **T-425** | 001 | **WITHDRAWN AS A DUPLICATE** | `.tasks/completed/T-425-*.md:5` — "WITHDRAWN AS A DUPLICATE — no work to do. Filed 2026-08-10 against T-357 spike 1… That string was repaired seven days earlier by T-361 (2026-08-03)". Body `:105`: "The defect was real and was repaired seven days before I filed this". Still carries `status: work-completed`. **0 commits** (§4). |
| **T-733** | 002 | **CORRECTION — premise wrong twice** | `.tasks/active/T-733-*.md:195` — "⚠ CORRECTION 2026-09-19 — READ BEFORE RULING. THIS TASK'S PREMISE WAS WRONG TWICE." `:201-205`: what the task recorded, then OBS-353, then "Both overstated the loss." |
| **T-732** | 002 | self-title correction + 2 superseded recommendations | `.tasks/active/T-732-*.md:52` "Correction to this task's own title, found while assembling the dossier."; `:66` "Two of the four recommendations are **superseded by their own later observations** (H3…"; `:84` AC records H3 and H6 "both carry superseding observations that contradict their own e…" |
| **T-736** | 002 | supersedes a prior RED record | `.tasks/active/T-736-*.md:146` — "The @650 RED record it supersedes is still there — history kept, not replaced."; `:220` "a correction against their own stale figure." |
| **T-734** | 002 | **NEW SCOPE** filed against a defect in the arc's own evidence base | name: "NEW SCOPE: absence claimed from a truncated search — guard the Arc-0 evidence base against the defect that produced OBS-352 and OBS-353" |
| **T-689** | 002 | corrected an omission in T-681's first answer | `.tasks/active/T-681-*.md:69` — "only after T-689 corrected an omission in the first answer"; `:242` "One correction found while disposing these questions (T-689)." |
| **T-623** | 002 | counterparty verdict rebutted with re-measurement | name: "AEF answered clause 1 red; their same-disease verdict on our fabric denominator does not hold - measured **3 of 69 not 749 of 1134**" |
| **T-594** | 002 | corrective follow-on to T-593 | name: "Residual prose still claims the operator resolved H2 **after T-593 cleaned the structured fields**" |
| **T-340** | 001 | filing corrections + superseded step | `.tasks/active/T-340-*.md:107` "Filing corrections (2026-08-03, see `## Decisions`) — left in place rather than rewritten"; `:131` "Superseded 2026-08-14 — kept…"; `:168` "step 3 below is marked superseded" |
| **T-423** | 001 | obligation survived a withdrawn ticket | `.tasks/active/T-423-*.md:210` "withdrawing it retired the ticket and not the obligation, and step 2 is where that…"; `:289` "**Withdrawn as dominated**, not chosen." Commit `afa54dad` restates it: "The task that would have owned this is T-425, closed work-completed as a duplicate… withdrawing the ticket retired the ticket and not the obligation, and step 2 walks into it a month later." |
| **T-278** | 001 | whole task is a supersession ledger | name: "Process-layer package disposition note: map SD-1..15 to **superseded**/delivered/open"; `:6` "was superseded by the T-175 framing" |
| **T-352** | 001 | population number wrong twice | `.tasks/completed/T-352-*.md:281` "the population number was wrong twice, in opposite directions"; `:294` "reported 26 as a *correction* to 332" |
| **T-488** | 001 | probe wrong twice | `.tasks/completed/T-488-*.md:359` "the probe accused the guard, twice, and was wrong both times" |
| **T-513** | 001 | correction issued to counterparty | `.tasks/completed/T-513-*.md:159`, `:334` |
| **T-350** | 001 | retired default port | `.tasks/completed/T-350-*.md:92`, `:327` |
| **T-199** | 001 | counterparty owed a correction notice | `.tasks/completed/T-199-*.md:281` "AEF owed a correction notice on the rail — we vetoed their…" |
| **T-589** | 001 | prior reason retired by T-570 | `.tasks/active/T-589-*.md:94`, `:370` |

Note: the string "**Root cause:** the specific structural/logical gap — not \"the code was wrong\"." appears in ~25 of these files. It is **template boilerplate**, not a finding, and is excluded above. (Corroborated by T-695, `fw bvp` rank 57: "Task-template boilerplate is scored as if it were …".)

---

## 4. Effort — commits per task

Method: `git log --oneline --all --grep="^T-XXX:"`. The anchor `^` restricts to commits whose **subject line owns** the task. Repo has **one branch** (`master`); `--all` and HEAD both report **2253** commits, so no multi-branch inflation. A loose `--grep="T-XXX"` yields higher counts (e.g. T-425: anchored 0, loose 3) because task IDs are cited inside *other* tasks' commit bodies; the anchored figure is the ownership measure.

### Top 10 by commit count (both arcs pooled)

| Rank | Task | Arc | Commits | Last owning commit |
|---|---|---|---|---|
| 1 | **T-423** | 001 | **29** | 2026-09-09 |
| 2 | **T-685** | 002 | **16** | 2026-09-08 |
| 3 | T-340 | 001 | 13 | 2026-08-14 |
| 4 | T-175 | 001 | 9 | — |
| 5 | T-681 | 002 | 8 | 2026-09-08 |
| 6 | T-174 | 001 | 7 | — |
| 7 | T-670 | 002 | 5 | — |
| 8= | T-589 | 001 | 4 | 2026-08-26 |
| 8= | T-352 | 001 | 4 | — |
| 8= | T-689 | 002 | 4 | 2026-09-08 |
| 8= | T-680 | 002 | 4 | — |

### Zero-commit tasks (work recorded, no owning commit)

- arc-001 (6): T-279, T-280, T-281, T-282 *(captured)*, T-424 *(captured)*, T-564 *(captured)*, **T-425 *(work-completed)***
- arc-002 (7): **T-593, T-594, T-595, T-596, T-597, T-608, T-610 — all `work-completed`**

T-593…T-610 is a contiguous run of seven work-completed arc-002 tasks with no owning commit. All seven have `date_finished` on 2026-08-26/27.

### Activity, not calendar — recency per arc

| Arc | Most recent owning commits |
|---|---|
| arc-001 | 2026-09-09 (T-690, T-423), 2026-08-26 (T-589), 2026-08-24 (T-563), 2026-08-23 (T-565), 2026-08-20 (T-562), 2026-08-15 (T-513), 2026-08-14 (T-340) |
| arc-002 | **2026-09-20 (T-736)**, 2026-09-19 (T-734), 2026-09-16 (T-733, T-732), 2026-09-08 (T-689, T-685, T-681), 2026-09-07 (T-684) |

arc-001's last owning commit is **11 days** before collection; arc-002's is **same-day**.

### Directory commit totals

| Path | Commits | First | Last |
|---|---|---|---|
| `docs/research/executable-workflow/` | **16** | 2026-08-26 (`be382259`) | **2026-09-20** (`116cc3b4`) |
| `examples/aef-processes/` | **40** | 2026-07-03 (`006712a0`) | **2026-07-31** (`b9afcfa2`) |

`examples/aef-processes/` has had **no commit in 51 days** (last 2026-07-31). `docs/research/executable-workflow/` was touched on the collection date.

---

## 5. The probe population in `tools/`

### Method

- Population denominator: `find tools -type f | wc -l` → **373**.
- Probe pattern: **`find tools -maxdepth 1 -type f -printf '%f\n' | grep -E '^_t[0-9]+'` → 278.** This is the figure in the brief. It is `tools/` **top level only**, basename **starting** `_t<digits>`.
  - Disambiguation: recursive `_t[0-9]+` anywhere → 310. The extra 32 are `tools/__pycache__` (39 files in that dir), `tools/lib` (1), `tools/schemas/bpmn20` (6). `tools/` top-level holds 327 files total, 278 of them probes.
- Reference tests use exact-string basename matching: `grep -rhoF -f <(probe basenames) <target>`, then `comm` against the sorted probe list.
- Verification-block extraction: per task file, `awk '/^## Verification/{v=1;next} /^## /{v=0} v'` across all 739 task files (34,922 lines), then the same `-F` match.

### The three counts

| Measure | Count | % of 278 |
|---|---|---|
| Referenced inside a `## Verification` block of some task | **255** | 91.7% |
| Referenced **anywhere** in `.tasks/` (any section) | **269** | 96.8% |
| Referenced **nowhere** in `.tasks/` | **9** | 3.2% |
| Registered in `.fabric/components/` | **277** | 99.6% |
| Referenced nowhere in the repo **outside `tools/` itself** | **0** | 0% |

Derived: 269 − 255 = **14 probes** are mentioned in a task body but **not** in any Verification block.

### The 9 probes with no task reference

`_t253-live-url-probe.mjs`, `_t258-annotation-seam-cdp.mjs`, `_t259-eventdef-preservation-cdp.mjs`, `_t315-lane-grow-on-import-cdp.mjs`, `_t402-gate-drive-probe.py`, `_t402-gate-drive-teeth.sh`, `_t429-apply-abstention-guard.py`, `_t596_arc0_check.py`, `_t597_arc0_clauses.py`

Two of these (`_t596_arc0_check.py`, `_t597_arc0_clauses.py`) are named for **arc-002 tasks T-596 and T-597**, both of which sit in the review queue (§2). They use `_` separators where the other 276 use `-`, which is why an exact-basename match finds no citation.

### The 1 probe not in `.fabric/components/`

`_t688-divergence-drain-baseline.txt` — the sole unregistered file. `.fabric/components/` holds **378** cards total.

---

## 6. BVP state

Command (read-only, no subcommand): `.agentic-framework/bin/fw bvp --include-proposed`, exit 0.

| Measure | Value |
|---|---|
| Ranked rows returned | **84** |
| Rows with a real quadrant | **39** (46.4%) |
| Rows with a dash (`-`) quadrant | **45** (53.6%) |
| Rows sourced `confirmed` | **0** |
| Rows sourced `proposed` | **84** (100%) |
| Quadrant split | hv-hc 14, hv-lc 16, lv-hc 5, lv-lc 4, `-` 45 |
| Status of ranked rows | `captured` 59, `started-work` 25 — **no `work-completed` row is ranked** |

### Confirmed vs proposed in frontmatter

| Field | Files |
|---|---|
| `^bvp_scores:` with any content (confirmed; written only by `fw bvp confirm`) | **0** of 739 |
| `^bvp_scores_proposed:` (estimator output) | **596** of 739 (100 of the 128 active) |

**No task in the repository carries a confirmed BVP score.** Every ranking row is estimator output. Arc YAMLs likewise: `bvp_scores: {}` and `scoped_drivers: []` in all three of `designer-authoring-surface.yaml`, `ewcr-governed-delivery.yaml`, `arc-003.yaml`.

### Top 15 rows

| # | Task | BVP | NORM | COST | QUAD | Name (truncated) |
|---|---|---|---|---|---|---|
| 1 | T-344 | 167 | 0.53 | 4.4 | hv-hc | fabric watch-patterns.yaml is the untailored fw co… |
| 2 | T-358 | 157 | 0.50 | 6.8 | hv-hc | Importer FABRICATES lane and pool structure… |
| 3 | T-189 | 151 | 0.48 | 5.6 | hv-hc | IW-9: v1.1 mapping-standard delta… |
| 4 | T-739 | 142 | 0.45 | 2.0 | hv-lc | review-queue DECISIONS drops every inception… |
| 5 | T-101 | 139 | 0.44 | 5.6 | hv-hc | Bake Clean layout into the rendered corpus (24 maps) |
| 6 | T-209 | 128 | 0.41 | 4.1 | hv-hc | 832-side compile->promote->create producer-contract… |
| 7 | T-264 | 127 | 0.40 | 4.4 | hv-hc | Save-target guard set… |
| 8 | T-155 | 126 | 0.40 | 2.6 | hv-lc | Hierarchical tree grouping… |
| 9 | T-184 | 126 | 0.40 | 3.6 | hv-lc | Child-3: Reverse discovery (AEF record -> editable…) |
| 10 | T-185 | 126 | 0.40 | 3.6 | hv-lc | Child-4: Collaboration and concurrency… |
| 11 | T-186 | 126 | 0.40 | 3.6 | hv-lc | Child-5: Hosting and tenancy… |
| 12 | T-277 | 126 | 0.40 | 3.7 | hv-hc | Ratify process-level conformance key… |
| 13 | **T-279** | 126 | 0.40 | 3.6 | hv-lc | **arc-001** Guided-mode procedural guardrail (P3) |
| 14 | **T-280** | 126 | 0.40 | 3.6 | hv-lc | **arc-001** Workflow Fabric (SD-15) |
| 15 | **T-281** | 126 | 0.40 | 3.6 | hv-lc | **arc-001** Audience render lenses (SD-14/§2.2) |

### Where the arcs rank

| Arc | Ranked members | Ranks |
|---|---|---|
| arc-001 (32 members) | **6** | T-279 #13, T-280 #14, T-281 #15, T-282 #16, T-424 #21, T-564 #73 |
| arc-002 (27 members) | **0** | — none appear anywhere in the 84 rows |

All 6 ranked arc-001 members are `captured/later` backlog items. **Not one delivering task in either arc is ranked.**

Cause (verified): the ranking covers only `captured` + `started-work` statuses, so the 12 review-queue tasks are structurally invisible. Additionally, **all 10 arc-002 active tasks carry zero `bvp_scores_proposed` blocks** (`grep -c "^bvp_scores_proposed:"` → 0 for T-590, T-593, T-596, T-597, T-608, T-671, T-681, T-732, T-733, T-736), so even T-681 (`started-work`) and T-732 (`captured`) — which meet the status filter — are unranked for want of scores.

Corroborating ledger entry: **T-738**, rank 78, "46 of 128 tasks carry no BVP quadrant, and 18 of t…".

---

## 7. Realization data — ABSENT

```
$ ls -la .context/audits/bvp-realization.jsonl
ls: cannot access '.context/audits/bvp-realization.jsonl': No such file or directory

$ find . -name "*realization*" -not -path "./.git/*"
(no output)
```

**`.context/audits/bvp-realization.jsonl` does not exist, and no realization artifact of any name exists anywhere in the repository.** There is therefore **no realization data in this repo**, and the question *"did shipped arcs deliver?"* is **unanswerable from it**. Combined with §6 (zero confirmed scores, both arcs `demo_evidence: null` and `closed_at: null`), there is no predicted-value record and no delivered-value record for either arc.

---

## 8. Audit history — findings that recur and never close

Corpus on disk: **74** records in `.context/audits/*.yaml` + **740** in `.context/audits/cron/*.yaml` = **814**. (Note: `git status` at session start showed many `cron/` records staged as deleted; counts above are the working tree.)

Method: `grep -h -A1 "level: \(WARN\|FAIL\)"` across all records → extract `check:` → normalise digits to `N` → `sort | uniq -c`. "Records containing" is `grep -l` on the raw substring.

| Finding (normalised) | Occurrences | Records containing | First record | Last record | Trajectory |
|---|---|---|---|---|---|
| `CTL-029: T-N has all Agent ACs ticked but status='started-work' — completable, not closed` | **4020** | **285** | `2026-06-05.yaml` (T-010) | `LATEST-CRON.yaml` (T-041) | open |
| `Fabric: N/N cards have no edges` | **313** | **313** | `2026-08-02.yaml` — **12/16** | `LATEST-CRON.yaml` — **77/378** | **worsening** (4→77 edgeless) |
| `Release lag EXCEEDED: oldest unshipped product change is Nd old (>= 14d)` | **276** | **276** | `2026-09-06.yaml` — **14d** | `2026-09-20-1800.yaml` — **27d** | **worsening** (14d→27d in 14 days) |
| `Fabric drift: N source file(s) have no fabric card` | **156** | **156** | `2026-08-08.yaml` — **147** files | `2026-09-16-1500.yaml` — **1** file | improving, not closed |
| `Fabric: N registered, N unregistered (of N watched — N% covered, cards flat since …)` | **129 + 18 + 7 + 2 = 156** | — | — | — | open |
| `DN: Human review queue — N task(s) waiting >Nd` (all length-variants pooled) | **277** | — | — | `2026-09-20.yaml` (FAIL, 12 tasks >30d) | open |
| `Arc 'arc-N': N/N tasks completed (N.N) but arc still in-progress` | **10** | **8** | `2026-09-16.yaml` | `2026-09-20-0700.yaml` | open, unchanged |
| `Inception task T-N has no research artifact in docs/reports/` | 16 | — | — | — | open |
| `Watching gap(s) with no closure condition: G-N` | 11 | — | — | — | open |
| `CTL-N: N stuck partial-complete task(s) — all ACs ticked, in active/` | 10 | — | — | — | open |
| `Orchestrator-arc tag-format drift: live sessions carry non-canonical prefixes` | 3 | — | — | — | open |

### The arc finding, verbatim, in the latest record

`.context/audits/2026-09-20.yaml`:

```yaml
  - level: WARN
    check: "Arc 'arc-001': 26/32 tasks completed (0.8125) but arc still in-progress"
    mitigation: "Capture wire-evidence of the arc's headline_mechanic firing, then: fw arc close arc-001 --demo <path"
  - level: WARN
    check: "Arc 'arc-002': 25/27 tasks completed (0.9259) but arc still in-progress"
    mitigation: "Capture wire-evidence of the arc's headline_mechanic firing, then: fw arc close arc-002 --demo <path"
```

Identical text in the first record it appears in (`2026-09-16.yaml`) and the last (`2026-09-20-0700.yaml`) — **the arc-001 ratio 26/32 (0.8125) has not moved across the 8 records spanning 2026-09-16 → 2026-09-20.**

### The D2 FAIL, verbatim, latest record

```
D2: Human review queue — 12 task(s) waiting >30d: 10 awaiting judgement: T-233(37d) T-308(52d)
T-310(52d) T-325(49d) T-340(36d) T-351(48d) T-353(48d) T-368(43d) T-410(42d) T-449(39d);
2 signed off, awaiting only the status flip: T-093(77d) T-178(71d); 23 waiting >14d: T-392(24d)
T-432(29d) T-433(29d) T-537(23d) T-540(23d) T-565(25d) T-579(26d) T-586(23d) T-588(25d)
T-589(25d) T-590(25d) T-592(25d) T-593(25d) T-596(25d) T-597(25d) T-600(24d) T-601(24d)
T-606(24d) T-608(24d) T-609(23d) T-643(20d) T-647(20d) T-671(17d)
```

This is **the only FAIL** in the 2026-09-20 record (`summary: pass 174, warn 27, fail 1`). Arc-001 contributes T-340, T-565, T-589; arc-002 contributes T-590, T-593, T-596, T-597, T-608, T-671 — **9 of the 35 queued tasks (26%)** come from the two in-scope arcs, which together hold 56 of the ledger's 739 tasks (7.6%).

### Governance cost booked against the stall

`arc-003` ("Audit remediation") holds **31 tasks**, of which the CTL-029 class alone accounts for **15** one-per-finding remediation tasks (T-709 through T-722, plus T-708). One of them, **T-722**, exists solely to record that **arc-002's T-681** has all Agent ACs ticked and is not closed. **T-728** exists solely to record that **arc-001 is 26/32 and not closed** (`.tasks/active/T-728-*.md:2`).

---

## 9. Data gaps and caveats

| # | Gap | Impact |
|---|---|---|
| G1 | **No realization data** (§7). No `bvp-realization.jsonl`, no artifact of any name. | "Did shipped arcs deliver?" is unanswerable from the repo. |
| G2 | **Zero confirmed BVP scores** across 739 tasks (§6). | All value figures are estimator proposals; none human-ratified. Value side of the ledger has no ratified input. |
| G3 | **Two membership sources of truth disagree** (§0): 15 vs 32 (arc-001), 25 vs 27 (arc-002). T-611/T-620 are dual-arc; T-623's `arc_id:` and `tags:` name different arcs. | Any per-arc count depends on which reader you use. Tables here state the method per row. |
| G4 | **Commit-per-task counts are a lower bound.** The anchored `^T-XXX:` grep captures subject-owned commits only. Work done under a *different* task's commit (e.g. T-425's obligation absorbed by T-423, commit `afa54dad`) is attributed to the other task. | Effort per task understated where work migrated between tickets. |
| G5 | `git status` at session start showed a large number of `.context/audits/cron/*.yaml` staged as **deleted** plus ~100 modified files. All §8 counts are **working tree**, not HEAD. | Audit recurrence counts could differ against a committed tree. |
| G6 | `fw audit` was **not run** (OBS-358 hang). §8 uses saved records; the newest is `2026-09-20.yaml` @ 18:07:34Z. | No live re-verification of the current finding set. |
| G7 | T-589's Agent/Human AC split was **not** re-measured in §2 (it entered the roster only via the legacy-tag union, after the AC pass). Its D2 age (25d) is from the audit record. | One cell in the §2(b) table is audit-sourced, not file-sourced. |
| G8 | `date_finished` is **absent** on T-175 despite `status: work-completed`. | Age for that task is unavailable from the canonical field. |
| G9 | **Probe reference matching is exact-basename.** A probe invoked via a variable, a glob, or a renamed path would read as unreferenced. The 2 underscore-separated arc-002 probes (§5) illustrate the sensitivity. | The "9 unreferenced" figure is an upper bound on true orphans. |
| G10 | Whether the `## Verification` citation of a probe means the probe **still passes** was not tested — no verification command was executed (read-only mandate). | Reference ≠ working. `CTL-N: T-N verification re-run: N command(s) failing` appears in 3 audit records. |
| G11 | No project-boundary (T-559) block was hit, so **no blocked-read finding to report**. | — |

---

*Collected read-only. One file written: this one. No task, git, bus, termlink, or `fw bvp estimate`/`confirm` mutation performed.*
