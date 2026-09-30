# T-949 — Triage of the 27 GO-recorded inceptions whose approved work was "never filed"

**Task:** T-949 · **Date:** 2026-09-30 · **Source finding:** `fw audit` →
`.context/audits/go-scope-unpropagated/LATEST.md`

---

## Headline: the premise is wrong, and that is the finding

The audit reports **27 GO-scope-not-propagated inceptions** out of 33 GO-recorded. Read as
prose, that says *"the operator approved 27 pieces of work and 27 were never built."*

Measured, **that is not what happened.** Of the 27:

| verdict | n | meaning |
|---|---:|---|
| `SHIPPED-UNLINKED` | **22** | the approved work was filed AND delivered; only the `related_tasks:` back-link is missing |
| `PARTIAL` | 2 | a slice was filed and is still open — the decision propagated, the delivery did not |
| `UNDONE` | **1** | genuinely nothing filed against the GO |
| `SUPERSEDED-UPSTREAM` | 2 | the approved change is framework behaviour, not workflow-design; not this project's to land |

**One inception in twenty-seven is genuinely un-acted.** The audit's own report predicted
this — *"some may have shipped work that was simply never linked back"* — and it was right.

### So what IS the defect?

Not abandoned decisions. **A 27-item warning with one real item in it.** At that ratio the
check cannot do its job: the next genuinely-abandoned GO arrives into a list already 26/27
false and is invisible. This is the same failure T-945 fixed this morning, where 11 reverted
local fixes were hiding inside a count of 1362 — *a true number that nobody can act on.*

There is also direct precedent that the signal was being ignored: **T-835** exists, is
`work-completed`, and is named *"Authority on the element, lane as domain: the mechanism
T-685 GO'd and nobody filed."* Someone already ran this triage — by hand, for one inception,
15 days after the fact. The check found it; the check's format meant it had to be re-found
manually.

### The mechanical cause

The audit's criterion reads **`related_tasks:` frontmatter only**. Every one of the 22
`SHIPPED-UNLINKED` inceptions *is* referenced — in the child task's prose, in exactly the
form a human would write it:

> `"First build slice authorised by the T-038 GO"` · `"(T-218 GO slice 1)"` ·
> `"Build authorized by T-068 GO (2026-07-04)"` · `"T-257 GO build (operator-ratified 2026-07-27)"` ·
> `"832-side deliverable of T-173 GO"` · `"T-092 GO Phase A option 6"`

The convention in use is a prose citation. The convention the check enforces is a YAML list.
Nobody reconciled them, so the check has been reporting the gap between two conventions and
calling it abandoned work.

**And `fw task update` has no `--related` verb.** The audit asks for a link the CLI provides
no way to write. Backfill here was done with direct file edits because there is no supported
path. Registered separately.

---

## Method

Two passes, both in `scratchpad/t949-{evidence,children}.sh`. Population is read **from the
audit's own report at run time** — never a list typed into this document (PL-181).

For each inception: GO date, whether the inception carries its own post-GO decomposition,
every task file naming it, each referrer's status, and the **line** in which it names the
parent. The mention line is what separates a child slice from an incidental cross-reference;
task-id adjacency (`T-218` → `T-219…T-228`) is suggestive and was never treated as proof.

### One measurement error, corrected

The first pass used `grep -rl "T-173"`, which also matches **`T-1730`**, `T-1738`, `T-2180`.
This project cites framework task ids in exactly that range throughout its prose, so T-173
read as **877 references** and T-218 as **64**. Both were substring collisions, not evidence.
Re-run with `grep -w`, which treats digits as word constituents: T-173 → 5, T-218 → 10.

Every number below comes from the corrected pass. The uncorrected figures never reached a
verdict, but they would have supported any conclusion I wanted, which is the point.

---

## Verdicts

### SHIPPED-UNLINKED (22) — delivered; back-link missing

| inception | GO | delivering evidence (verbatim from the child task) |
|---|---|---|
| T-788 | 2026-09-22 | 8 completed children (T-789, T-794, T-798–T-803) |
| T-681 | 2026-09-05 | 11 completed; `"S1 (T-681) measured the editor's total reachable surface"` (T-682) |
| T-685 | 2026-09-08 | **T-835** `"the mechanism T-685 GO'd and nobody filed"` — completed |
| T-617 | 2026-08-27 | T-618 `"Authorised by T-617's GO decision (2026-08-27T12:34:03Z)"` |
| T-257 | 2026-07-27 | T-259 `"T-257 GO build (operator-ratified 2026-07-27)"` |
| T-250 | 2026-07-27 | T-258 `"(T-250 GO)"`; T-260 `"read-only badge layer, T-250 GO shape A"` |
| T-249 | 2026-07-25 | T-251 `"(T-249 GO)"` |
| T-247 | 2026-07-23 | T-248 `"FIRST release under the T-247 pull-at-tag"` |
| T-244 | 2026-07-29 | T-308 `"Bare catch-event neutral rendering when unbound (T-244 GO, path b)"` |
| T-218 | 2026-07-21 | **10 completed slices**, T-219–T-228; `"(T-218 GO slice 1/2/3)"`, `"S3b"`, `"S4a"` |
| T-213 | 2026-07-21 | T-875 `"ship T-213's ratified enum so a map declares"` |
| T-201 | 2026-07-18 | T-202 `"Post-GO on T-201 write-out inception. Seam resolved"` |
| T-190 | 2026-07-18 | T-204 `"Build authorized by T-190 GO (inception, firm post Spike-1+2)"` |
| T-173 | 2026-07-18 | T-174 `"832-side deliverable of T-173 GO: publish a versioned, pinnable designer"` |
| T-142 | 2026-07-08 | T-143 `"T-142 GO, build task 1 of 2-3"`; T-144 `"build task 2 of 2"` |
| T-112 | 2026-07-05 | T-113, T-114 both completed against the node-cut router |
| T-092 | 2026-07-04 | **10 completed**; `"T-092 GO Phase A option 1/6/9"`, `"Phase B option 10/2"`, `"Phase C option 3/7"` |
| T-068 | 2026-07-04 | T-081 `"Build authorized by T-068 GO (2026-07-04)"` |
| T-038 | 2026-07-03 | T-039 `"First build slice authorised by the T-038 GO"`; T-040 `"Phase P2"` |
| T-020 | 2026-07-02 | **13 completed**; T-021 `"First build slice after T-020 GO"` |
| T-015 | 2026-07-04 | T-091 `"Upstream fix bundle: env-export contamination (T-015 GO)"` |
| T-002 | 2026-06-05 | T-012 `"First build slice of the T-002 GO"` |

Two carry an open tail, which does not change the verdict — the GO propagated:
**T-038** (T-041, phase P4, `started-work`) and **T-685** (T-341/T-358, both blocked on
operator rulings, not on filing).

### PARTIAL (2) — the decision propagated, the delivery did not

- **T-263** — *Save-to-project target binding.* GO approved *"a small, zero-seam-surface
  UX-guard build task"* converting a silent overwrite into an informed choice. The slice
  **was filed**: T-264, `"mismatch confirm (T-263 GO)"` — and is still `captured`. Filed
  2026-07-27, never started. **This is the one on the list most worth a decision.**
- **T-103** — *Adopt the T-101 CDP harness as editor-test substrate.* Slice T-105 is
  `started-work`, and separately carries a 72-day lifecycle anomaly in the audit.

### UNDONE (1) — nothing filed against the GO

- **T-301** — *Store-card id vs workflowMeta id seam.* The GO is explicit and unusual: *"GO,
  but on a smaller and different thing than the title asks for — **assert the invariant, do
  not chase the symptom**."* Every task naming T-301 names it incidentally: a list (T-500), a
  cross-reference (T-362), an unrelated AC (T-306), and its own verification leg quoted by the
  absence-assertion census (T-560). **No task was filed to assert the invariant.** It is also
  the only one of the 27 whose GO supersedes an earlier DEFER — the operator changed their
  mind toward action, and nothing followed.

### SUPERSEDED-UPSTREAM (2) — not this project's to land

- **T-006** — *`fw vendor` should ship `orchestrator-mcp-baseline.yaml` to consumers.*
- **T-007** — *`fw init` seeds `patterns.yaml` with `origin_task` where the template expects
  `learned_from`.*

Both approve a change to **framework behaviour**, not to workflow design. Under the standing
product-boundary rule these are not ours to build; they land upstream or not at all. T-010
added their research artifacts, which satisfied the inception-artifact check and is why they
look partly served. Recorded, not filed.

---

## What this task changed

1. `related_tasks:` backfilled on the 22 `SHIPPED-UNLINKED` inceptions, naming the delivering
   task(s). The link the check looks for now exists, because the delivery it stands for
   already did.
2. **No backfill on the other 5.** `PARTIAL`, `UNDONE` and `SUPERSEDED-UPSTREAM` keep their
   finding — the check should keep reporting them, because for those it is right.
3. `tools/_t949-triage-completeness.py` guards this document: every id in the audit report
   must carry a verdict from the fixed vocabulary, and every verdict must cite an artifact.

## What this task deliberately did NOT do

**No build task was filed.** Converting 27 findings into 27 tasks is forwarding, not triage,
and it is how the operator's docket reached 83 items. The shortlist below is the deliverable;
filing is the operator's call.

### Shortlist, ranked

| | inception | BVP | what the GO approved, in one line |
|---|---|---:|---|
| 1 | **T-263** | — | Warn when a save would overwrite a different project than the one loaded. Slice T-264 filed 2026-07-27, never started. |
| 2 | **T-301** | — | Assert the card-id/workflowMeta-id invariant. GO overturned a prior DEFER; nothing filed since 2026-08-20. |
| 3 | T-103 | — | Finish moving editor tests onto the T-101 harness (T-105, open 72 days). |

T-263 and T-301 are the same seam — document identity on save — and both are small, bounded
and user-visible. If any of this list gets filed, those two are one sitting.
