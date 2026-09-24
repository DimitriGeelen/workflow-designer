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
