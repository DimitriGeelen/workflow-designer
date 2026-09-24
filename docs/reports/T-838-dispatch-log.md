# T-838 dispatch log — value review GATHERER workers

Provenance records for each dispatched GATHERER worker, appended by the worker itself as its last
action (per the T-838 dispatch instructions), because round 1's `/tmp/tl-dispatch/` worker
directory was deleted by `fw termlink cleanup` **while that worker was still running**, destroying
its `result.md`/`exit_code` before they could be read. This file lives in the repo tree
specifically so it survives that failure mode. Anything that exists only under `/tmp` does not
count as evidence for this review.

---

## Worker vr0925g2 — round 2 of 4 (GATHERER, full-pass coverage)

- **Worker name:** `vr0925g2`
- **UTC start:** not captured precisely at invocation time (this worker has no reliable
  self-observed wall-clock start; first substantive tool call — reading the round-1 evidence
  file — landed at approximately 2026-09-24T22:5x UTC, inferred from the end time below and this
  session's tool-call sequence, not measured directly)
- **UTC end:** 2026-09-24T23:02:50Z (`date -u` at time of writing this record)
- **Own prompt file sha256:** not available — this worker's dispatch prompt was delivered inline
  in the invoking message, not as a readable file path on disk; no path to hash was found or
  given. Recorded as a gap rather than fabricated.
- **Dispatch mechanism:** cannot self-determine whether this invocation ran via
  `fw termlink dispatch --task T-838` or was run directly — per the standing instruction in this
  worker's own brief, this fact is not observable from inside the worker and is not claimed
  either way beyond what the brief itself stated.

### What this worker covered

- Extended `docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md` with a new
  `## Round 2 — full-pass coverage` section (round 1's content left untouched).
- Closed the specific coverage gap named in the dispatch brief: **`.claude/` had zero references
  in round 1's evidence file.** Read `.claude/settings.json` in full (all hook matcher entries),
  `.claude/settings.local.json` (confirmed not git-tracked, matched by a global — not
  project-level — gitignore rule), and `.claude/commands/resume.md`.
- Found and recorded that `.fabric/` (the project's own structural map, 411 component cards) has
  **zero cards for anything under `.claude/`** — the same blind spot exists in the project's own
  tooling, not just in this review series.
- Inventoried, for the first time in this review series: `dist/` (17 release files, 13.5MB,
  `MANIFEST.yaml` read in full, no retention/pruning mechanism found), `vendor/designer/` (2
  files, one release behind `dist/`'s latest), `build/gallery/` (27 files, listing only),
  `.editor-versions/` (181 tracked + 15 untracked files), `.playwright-mcp/` (76 tracked files,
  7.2MB, referenced by ~30 task files), 6 root-level loose PNGs (5 of 6 untracked, tracked/
  reference status checked individually), `.mcp.json`, `.framework.yaml` (surfaced that
  `CONTEXT_WINDOW` is configured to 800000, not the 300000 CLAUDE.md's P-009 section calls
  "default").
- Sampled `tools/` (15 of ~415 files, fixed-seed random sample) for reference counts — found no
  clean orphans in the sample, but flagged the method as weak (mention-count, not call-graph) and
  explicitly did not confirm or falsify the 2026-09-20 designer-product review's "118 instruments
  with no caller" finding.
- Gathered DELETE-relevant evidence independently, per the operator's instruction not to treat
  "0 DELETE across 3 prior reviews" as settled: built a small table of reference-count/
  supersession/staleness data for root-level PNGs, superseded `dist/` releases, the misnamed
  test files (carried from round 1), and the older `vendor/designer/` pin. Explicitly did not run
  any item through the DELETE CHECKS (that is Phase 4/JUDGE work) and stated so in the evidence
  file.
- Added non-use diagnosis rows (readings A–E, not resolved) for the new items found this round.

### What this worker did not reach

- `scripts/`, `src/`, `tests/`, `.tasks/`, `.context/`, `.agentic-framework/` — not independently
  re-opened beyond round 1's existing coverage; this worker's budget went to the folders round 1
  missed or under-covered, per the operator's specific complaint about `.claude/`.
- No full `tools/` orphan sweep (sample only, 15/~415 files); no `vulture`-class dead-code tool
  run (round 1's Data Layer A gap, still open both rounds).
- `.claude/commands/resume.md` vs. the `resume`/`resume-full` skills' current text — named as a
  possible drift pair but not diffed.
- `docs/aef-designer-integration-protocol.md` — cited by `dist/MANIFEST.yaml` as the governing
  protocol doc, not opened to confirm what it actually says about `dist/` retention.
- `.fabric/`'s 13 "unregistered" files (per round 1's `fw fabric drift` output) were not listed
  individually to confirm whether `.claude/settings.json` is among them.
- All of round 1's carried-forward data gaps (healing patterns, `fw costs`, `.context/project/*`
  content sampling beyond summary view, the lost bridge-suite per-leg failure detail, AEF-side
  telemetry) — not attempted again this round; see round 1's own "Data gaps" section.

### Gates/friction encountered this round

None — no Bash command was refused this round. This worker's dispatch task (T-838, shared with
round 1) had already been in `started-work`/active state with the G-020 friction documented by
round 1; this round's commands (read-only `find`, `git log`, `git status`, `du`, `grep`, `cat`,
plus `fw` safe-listed subcommands where used) did not trigger any new gate block. No bypass flags
were used.

### Repo writes made by this worker

Exactly two, both append-only, both within the explicit write allowlist in this worker's brief:

1. `docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md` — appended `## Round 2 — full-pass
   coverage` section (plus two small self-corrections to typos introduced within that same
   section, before this record was written).
2. `docs/reports/T-838-dispatch-log.md` — this file, created (did not exist before this round).

No task files, source files, config, or fabric cards were touched.

---

## Orchestrator addendum — provenance the workers could not self-observe

Appended by the dispatching session, not by a worker. Both gaps `vr0925g2` recorded honestly
rather than fabricating are closed here from the dispatch side, which is the only side that holds
the evidence.

**Prompt hashes (sha256).** `fw termlink dispatch --prompt-file X` copies X to
`$WDIR/prompt.md` and then passes it to `claude -p` as an inline string, so a worker sees its
brief as message text with no path to hash — exactly as `vr0925g2` reported. Hashed at the
dispatch source:

| artefact | sha256 |
|---|---|
| review prompt core (operator's, verbatim, placeholders substituted per round) | `fcbe200ee150e39506af315fbdc66f3b7ce980c9e110b721435198ad2d5d741d` |
| `vr0925g1` brief (round 1, delta-scoped) | `c673453d33284b095241fc628411d0e0c68a13ae60980c44df6c844456d12f8e` |
| `vr0925g2` brief (round 2, full-pass) | `b9da13bb41e8893e8b03538ab20de60d0a8652d2ad9b6c3ae2081d752eabade0` |

**Dispatch record, observed externally:**

| worker | round | verb | exit | worker dir fate |
|---|---|---|---|---|
| `vr0925g1` | 1 | `fw termlink dispatch --task T-838` | **unrecorded** | DELETED while running; `result.md` and `exit_code` destroyed |
| `vr0925g2` | 2 | `fw termlink dispatch --task T-838` | **0** | intact at read time; `result.md` copied out immediately |

Round 1's exit code is **permanently unknown**. Its evidence file survived only because it was
committed to the repo (`e1f548be`). That is the whole reason this log exists.

**On self-determination of dispatch mechanism:** `vr0925g2` correctly declined to claim it
either way. Confirmed from outside: both workers were launched by `fw termlink dispatch`, each
verified at launch as a `claude -p` process with `cwd=/opt/832-Workflow-designer` — so both ran
with this project's `.claude/settings.json` hooks loaded. A worker cannot establish this from
inside; a previous worker in this project (`pa0924r1`, T-837) asserted the opposite and was wrong.

---

## Phase 1 [ASK] — ANSWERED BY THE OPERATOR

- **Answered at:** 2026-09-24T23:07:03Z (operator reply in the dispatching session)
- **Q1, yardstick:** **CONFIRMED — "The yardstick holds."** Verbatim operator reply. The
  yardstick is therefore:

  > "The workflow designer and its integration with AEF, and our ability to facilitate the agent
  > and human collaboration to iterate from the workflow to actual working applications."

  Drivers as recorded: protected **D1** Antifragility 9, **D2** Reliability 7, **D3** Usability 5,
  **D4** Portability 3; free **F1** SDLC_ENABLEMENT 9, **F3** AEF_INTEGRATION 9,
  **F4** WORKFLOW_ROUTING 9, **F2** V_COMPONENT_FABRIC 6, **F-RECALL** Recall Leverage 6.

- **Q2, scope frame:** answered earlier in the same session — *"process all again and scan all
  folders"* = a **fresh full pass**, not a delta against the three prior reviews. Round 2 was
  re-scoped on that basis; round 3 completes the coverage.

- **Q3, data the workers cannot see:** **not answered.** Asked twice. AEF-side seam telemetry and
  any access logs / analytics for the deployed `/designer/app` therefore stay recorded as
  **ABSENT**, and the JUDGE must cap confidence accordingly rather than assume no such data exists
  ("no data is not zero" — a ground rule). This is not treated as a negative answer.

**Consequence for the gate:** Phase 4 is now unblocked ("no yardstick, no verdict" is satisfied).
Any JUDGE dispatch recorded below is later than the timestamp above — which is T-838's AC4.

---

## Worker vr0925g3 — round 3 of 4 (GATHERER, orphan census + remaining folder coverage)

- **Worker name:** `vr0925g3`
- **UTC start:** not measured. No wall-clock read was taken before the first substantive tool
  call; the first `date -u` this worker ran (used as an orientation step, not a start marker)
  read `Thu Sep 24 11:08:18 PM UTC 2026`, but that is a first-observation, not a claimed start
  time — recorded as a gap per this worker's own brief ("Do not claim a UTC start you did not
  measure"), not filled in retroactively.
- **UTC end:** `Thu Sep 24 11:24:13 PM UTC 2026` (`date -u`, run immediately before writing this
  record).
- **Own prompt file sha256:** not available. This worker's dispatch prompt arrived inline in the
  invoking message, not as a readable path on disk — same gap round 2 recorded, for the same
  reason. Not fabricated.
- **Dispatch mechanism:** cannot self-determine whether this invocation ran via
  `fw termlink dispatch --task T-838` or directly. Per the standing instruction carried into
  this worker's own brief (and round 2's before it), this fact is not observable from inside and
  is not claimed either way.

### What this worker covered

- **JOB 1 (priority): settled the 118-orphan question with a full census, not a sample.**
  Ran `tools/_t451-unwired-guard-census.py` (the project's own pre-built reachability-closure
  tool for exactly this question, found by reading `tools/README.md` and cross-referencing —
  not reimplemented) against the full 358-file top-level `tools/` population. Result: 174 files
  with no live caller, of which 49 are one-shot-by-design (teeth/probe/mutation-check naming)
  and 125 are findings; of those 125, 112 have run at least once at a completed task's
  Verification block (a real historical caller, now unrunnable) and only **13 of 358 (3.6%)**
  have never been referenced by any task, ever. Cross-checked those 13 (and, via a supplementary
  script reusing T-451's own reference-extraction functions, all 358 files) against docs/**
  mentions, `.fabric/` card existence, and `git log --oneline --all` commit-subject mentions.
  5 of the 13 have zero reference anywhere found by any method this round used. Ran `shellcheck`
  (already installed) and `vulture` (installed into an isolated `/tmp` venv, never added to
  project dependencies) as the real dead-code tools the brief required. Confirmed, via
  `grep -rl "tools/" examples/aef-processes/rendered/*.bpmn`, that **zero ratified workflows**
  reference anything under `tools/` at all. Read (never executed) `tools/_t350-teeth.sh` and
  confirmed it is the excluded repo-deleting instrument via `tools/_t509-instrument-sweep.sh:75`.
  Full per-file table (all 358 rows) and full method writeup appended to the evidence file.
- **JOB 2: opened all six named folders.** `src/` (1 file, the product itself, 149 commits
  all-time — highest churn of any single file measured), `scripts/` (4 files, release/AEF
  pipeline, purposes read from headers), `tests/` (222 files; measured 19/45 `test_*.py`
  pytest-collectible vs. 26 script-style, a 1-file correction against round 1/2's carried "25 of
  45" figure — recorded side by side, not silently fixed), `.context/` (3,750 files, per-subdir
  breakdown with sizes; found `locks/` is 775 files but 0 bytes total, `handovers/` is the
  largest subdir by size at 35M; observed but did not investigate a 744-file git-status
  deletion/on-disk divergence under `.context/audits/cron/`), `.tasks/` (840 files, breakdown
  only — deferred to the brief's own KNOWN EVIDENCE for BVP/VOI detail), `.agentic-framework/`
  (2,562 files, top-level breakdown by subsystem; found and corrected two of the five KNOWN
  EVIDENCE "ABSENT" claims — `policy/prompts/` and `agents/dispatch/` both exist with
  substantive content and live references from framework code; the other three ABSENT claims,
  `policy/capabilities.yaml`, `.context/bus/`, `bvp-realization.jsonl`, were independently
  reconfirmed absent).
- Ran `python3 -m pytest tests/ -q` (20 passed, 58.9s) and `fw audit` (no `--fix`; Pass 175/
  Warn 26/Fail 1, 2m51s wall-clock) as the Phase 0 baseline this worker's brief asked for.

### What this worker did not reach

- `tests/fixtures/`, `tests/data/`, `tests/goldens/` — not opened.
- `.agentic-framework/docs/` (1,643 files) and `.agentic-framework/lib/` (461 files) — not
  opened beyond two specific path checks; no structural survey.
- `.agentic-framework/web/` (261 files) — not opened at all.
- `.context/arcs/`, `.context/cron/`, `.context/designer/projects/` — not opened.
- Full `git log -S<filename>` (content-diff search) for all 358 `tools/` files — only
  commit-subject-line text search was run, a weaker proxy, stated as such in the evidence file.
- Per-active-task cross-tabulation of which tasks carry how many `tools/` "pending" instruments
  as their only live path — named as a pattern in the evidence file, not computed as a table.
- Liveness classification (standing vs. one-shot-historical) for the 26 `tests/` script-style
  files that do have references — reference *counts* were gathered, not a liveness closure like
  the one built for `tools/`.
- Investigation of the `.context/audits/cron/` git-deletion-vs-disk divergence noted above —
  observed and recorded only, to avoid running extra `git log` history digs outside the Phase 0
  snapshot scope.
- Complexity analysis of the embedded JavaScript inside `src/aef-workflow-designer.html` — only
  commit-churn was measured (149 commits), no complexity tool was run against it.
- Full list of the 50 `tools/` files in `pending one-shot` status and the 49 excused
  one-shot-by-design files — counts and the full per-file table are in the evidence file, but no
  separate curated list of just these two categories was written up in prose.

### Gates/friction encountered this round

None refused. No Tier 0 command was attempted; no bypass flag was used; `fw inception decide`
was never run or grepped for (per the brief's explicit hard constraint, including in negated
form). One notable **non-gate anomaly**: `fw audit` (invoked exactly as the brief's own hard
constraints permit — "Read-only `fw audit` is fine") wrote a new file,
`.context/audits/2026-09-25.yaml`, despite the same brief separately stating "READ-ONLY. Your
only repo writes are those two files." This is recorded as a conflict between two clauses of
the brief, surfaced honestly rather than hidden, and resolved in favor of *not* deleting or
reverting the audit's own output — `.context/audits/**` is explicitly an append-only ledger this
worker was told never to rewrite, and deleting a just-written ledger entry to satisfy a literal
reading of "only two files" would itself be a worse violation (a destructive edit to a governed
ledger) than the anomaly it would fix. `fw audit` also took 2m51s wall-clock for what the brief
called read-only — recorded as friction/cost data in the evidence file, not just here.

### Repo writes made by this worker

Exactly two files edited directly, both append-only, both within this worker's explicit write
allowlist:

1. `docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md` — appended `## Round 3 — orphan
   census and remaining coverage` (rounds 1 and 2, including the `## [ASK]` section, left
   untouched).
2. `docs/reports/T-838-dispatch-log.md` — this section, appended.

Plus one **side-effect write this worker did not make directly but caused by running an
explicitly-permitted command**: `fw audit` created `.context/audits/2026-09-25.yaml` — disclosed
above, left in place, not authored or edited by hand.

No task files, source files, config, or fabric cards were touched or edited by hand.

