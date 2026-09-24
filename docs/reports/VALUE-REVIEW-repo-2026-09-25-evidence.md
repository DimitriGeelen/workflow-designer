# Value review — 832-Workflow-designer — 2026-09-25 — EVIDENCE FILE

**Round 1 of 4 (GATHERER only).** Dispatched via `fw termlink dispatch --task T-838`, worker
`vr0925g1`. Phases 0–3 only. **No classification, no recommendations in this file** — every
class-shaped word below (KEEP/DELETE/REFACTOR/ADD) is a quotation from a prior report or gate
message, not this worker's judgement. Phase 4 (classify) is a separate worker/model reading only
this file plus the confirmed yardstick.

Facts are cited to a path, command, or line. Where two data points disagree they are shown side
by side, not resolved.

---

## [ASK] FOR THE OPERATOR — BLOCKS PHASE 4

This worker is non-interactive and cannot answer its own Phase 1 [ASK]. Two things need your
confirmation before the JUDGE round can run.

### 1. Confirm or correct the yardstick

Drafted below from `README.md`, `policy/value-drivers.yaml`, `docs/branch-model.md`. It is
**materially identical** to the yardstick the operator already confirmed for the 2026-09-21
repo-scope review (`docs/reports/VALUE-REVIEW-repo-2026-09-21.md` §1):

> "The workflow designer and its integration with AEF, and our ability to facilitate the agent
> and human collaboration to iterate from the workflow to actual working applications."

Load-bearing drivers (`policy/value-drivers.yaml`): protected **D1** Antifragility (9), **D2**
Reliability (7), **D3** Usability (5), **D4** Portability (3); free **F1** SDLC_ENABLEMENT (9),
**F3** AEF_INTEGRATION (9), **F4** WORKFLOW_ROUTING (9), **F2** V_COMPONENT_FABRIC (6),
**F-RECALL** Recall Leverage (6). **Question: does this still hold, or has the focus shifted in
the four days since 2026-09-21?**

### 2. This round is largely a re-run, not a first look — confirm that's wanted

Three prior Value Reviews already exist in this exact repo, one at this exact scope, 4 days old:

| Report | Scope | Date | Findings |
|---|---|---|---|
| `docs/reports/VALUE-REVIEW-repo-2026-09-21.md` (+ `-evidence.md`) | whole repo | 2026-09-21 | KEEP 7 · REFACTOR 4 · ADD 5 · INVESTIGATE 6 · DELETE 0 · SQ 4 |
| `docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md` | `src/aef-workflow-designer.html` | 2026-09-20 | 1 DELETE · 4 REFACTOR · 14 ADD · 3 INVESTIGATE-only |
| `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20.md` | AEF↔832 seam | 2026-09-20 | KEEP 28 · DELETE 0 · REFACTOR 2 · ADD 20 · INVESTIGATE 9 |

**122 commits landed between the 2026-09-21 snapshot and now** (`git log --oneline --since=
"2026-09-21T22:01:46Z" | wc -l`). A large fraction are named follow-ups to those three reports'
own findings — F-02 (T-812), F-03 (T-813), the single DELETE F-14/`refreshLibraryUI` (T-814),
F-07/F-08 (T-817), F-09a (T-816/T-820), F-05 (T-821) — all `git log --grep` confirmed
work-completed. **Question: does the operator want (a) a fresh independent pass that may
re-derive the same findings, or (b) this round scoped explicitly as "verify what the three prior
reviews closed, and gather only the delta + previously-unreviewed corners"?** This file is
written to serve either — it cites the prior reports rather than re-deriving their content, and
adds only what has changed or was newly discovered — but the JUDGE round needs to know which
frame the operator intends, because "0 DELETE across 3 reviews" is itself a data point the JUDGE
should not re-litigate from scratch each round without being told so.

### DESIGNED-ONLY / ABSENT rows the JUDGE needs

- `policy/capabilities.yaml`, `.context/bus/`, `.context/audits/bvp-realization.jsonl`,
  `policy/prompts/`, `agents/dispatch/` templates — **all still ABSENT**, unchanged from the
  2026-09-21 snapshot (checked fresh this round, §Data Availability Map).
- **0 of 155** active tasks have a confirmed `bvp_scores` (128 have proposed-only, 27 neither) —
  same reading as 2026-09-21's "0 of 149", i.e. the human-confirmation step of BVP scoring has
  not happened even once despite continued proposal-scoring work (T-837 x2 this week).
- `fw workflow run` executor: per the 2026-09-21 report this is **not 832's to build** (frozen
  standard, AEF-owned) — recorded as a Sovereign question there (SQ-1), not re-asked here.

**Is there data you have that this worker cannot see?** Specifically: AEF-side (999-AEF)
telemetry on the seam, and any operator-side usage of the deployed `/designer/app` instance
(browser analytics, access logs) — none of that is reachable from inside this repo.

---

## Phase 0 — Orient and snapshot

### Project shape

- Single-file dual-audience product: `src/aef-workflow-designer.html` (11,503 lines, self-
  contained, no build step to run it — `README.md:28-31`).
- Governed by the vendored Agentic Engineering Framework (`fw`, v1.6.354,
  `.agentic-framework/bin/fw --version`). `fw --help` output captured; 40+ verbs.
- No `package.json` anywhere under the project (`find . -maxdepth 2 -iname package.json` — empty).
  Python test/tool ecosystem (`tests/*.py`, `tools/*.py`), one `.mjs` instrument
  (`tools/_t821-fault-surface-cdp.mjs`).
- CI (`.onedev-buildspec.yml`): **one job, "Push to GitHub Mirror"** — a `PushRepository` step
  mirroring to `github.com/DimitriGeelen/workflow-designer` on every branch update/tag. **No test
  execution step exists in CI.** No `.github/workflows/` directory either
  (`find . -iname .github` → empty). Verification is entirely session-side (`fw test`, manual
  `pytest`, the bridge/validator shell suites), gated only by the local commit-msg hook and
  Tier-0/G-020 PreToolUse hooks, never by a CI runner.
- Branch model (`docs/branch-model.md`, adopted 2026-09-22 T-805): `bleeding-edge` is dev,
  `master` is fast-forward-only consumer surface, no `stable` branch. AEF-consulted, documented
  rationale for fast-forward over squash.

### Platform / gate friction — measured, not asserted (T-838 itself hit this)

This worker's own dispatch task, **T-838**, is a `workflow_type: build` task filed with template
placeholder ACs (`[First criterion]`, `[Second criterion]` — `.tasks/active/T-838-*.md`). The
G-020 build-readiness gate (`.agentic-framework/agents/context/check-active-task.sh:690-762`)
therefore **blocked every non-safe-listed Bash command this session tried**, including
`.agentic-framework/bin/fw version` (plain subcommand form) — first command attempted, refused
with exit 2, full policy text captured verbatim in this session's transcript. Only
`--help`/`--version` **flag** forms are exempted (`check-active-task.sh:77-86`); the `version`
**subcommand** is not the same thing and is not exempted. `fw audit`, `fw gaps`, `fw metrics` and
plain `git status/log/branch` passed because they're on the safe-command allowlist
(`.agentic-framework/agents/context/lib/safe-commands.sh:209`: `doctor|metrics|audit|version|
resume|help|status|fabric|gaps|promote`).

**This is itself Phase 0/3 data per the ground rules ("a gate that refuses you is a finding to
record, not an obstacle to route around")**: a dispatch harness (TermLink `fw termlink dispatch`)
created a governance-anchor task for a read-only research worker using the `build` template
without filling ACs, and the build-readiness gate — correctly, by its own design — could not tell
the difference between that and an unscoped build. No workaround was used (no `--type inception`
conversion, no bypass flag); the worker adapted to the safe-command surface instead. Whether the
dispatch harness should default research/GATHERER tasks to a workflow_type the gate does not
police this way is a judgement call for Phase 4/5, not this worker.

A second, independent tooling defect surfaced during baseline collection: `fw metrics`
(`.agentic-framework/metrics.sh:99`) emits `line 99: [: 0 0: integer expression expected` **12
times** on a single invocation (captured verbatim) — a bash arithmetic comparison bug, non-fatal
(exit continues, output still usable) but present on every run.

### Baseline (captured this session, before any further review-generated activity)

| Check | Result | Source |
|---|---|---|
| `fw audit` | **162 PASS / 22 WARN / 1 FAIL** | this session's tool output, run 2026-09-25T00:25:30+02:00 (reproducible: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw audit`) |
| FAIL | D2: Human review queue — 13 tasks waiting >30d (up to 57d), 22 more >14d | same |
| `python3 -m pytest tests/ -q` | **20 passed, 0 failed**, 61.01s | this session |
| `tests/run-bridge-tests.sh` (fresh run, started this session) | **142 passed, 9 failed, rc=1, 1045s, HEAD 2a841f3f** — see Addendum for full detail | `tests/.run-history.tsv` row 3, appended by the run itself |
| `fw test unit` | **FAILS to run** — `cd: /opt/832-Workflow-designer/.agentic-framework/tests: No such file or directory` | this session; the `unit` suite path assumes the framework repo layout, not a vendored consumer's |
| `fw gaps` | 52 watching, 0 resolved | this session |
| `fw metrics` | 155 active / 682 completed / 723 work-completed; 100% git traceability (2452/2452); 12× arithmetic error (above) | this session |

Snapshot window for all "fresh" data points in this file: **2026-09-25T00:2x–00:4x+02:00**,
before this worker generated any task/audit/commit activity of its own (the one write — this
evidence file — happens after the snapshot, per the ground rules).

---

## Phase 1 — Yardstick and data (draft, unconfirmed — see [ASK] above)

**Purpose** (README.md:1-11): a visual, BPMN-subset, dual-audience editor for authoring AEF
workflows — humans drag-and-drop, agents read the same file as typed YAML (canonical) with BPMN
XML as a derived export. **Users/consumers:** the operator (human author), AEF agents
(consumers of the YAML/BPMN), and 999-AEF as an external repo that pins `examples/aef-processes/
rendered/` by sha (`docs/branch-model.md` "The seam"). **Core capabilities:** author, validate,
export/import workflows; swimlanes encode the AEF authority model (Human·Sovereignty,
Framework·Authority, Agent·Initiative). **Non-goal, textually confirmed** (`README.md:13-15`):
usable *today* without the *planned* `fw workflow run` executor — corrected by the 2026-09-21
review (T-803) to note "planned" is now stale language since AEF shipped an executor upstream;
**832 itself still builds no translator** (frozen standard, confirmed AEF position, 2026-09-21
review SQ-1). **Value drivers/weights:** see [ASK] §1 above — D1(9) D2(7) D3(5) D4(3) protected;
F1(9) F3(9) F4(9) F2(6) F-RECALL(6) free, cap 5/uses 5 (full), 4th slot vacant (F-AUTONOMY listed
INACTIVE/candidate in the policy file, not currently consuming a slot).

**Contradiction flagged, not resolved:** repo mass vs. stated purpose. `find . -iname "*.md" |
wc -l` / `*.yaml` counts were not re-run this round (already established at 3207 md / 1915 yaml
vs. 98 html / 80 mjs by the 2026-09-21 review, §10 of that report) — carried forward as
unconfirmed-fresh but not contradicted by anything found this round; still true directionally:
`tools/` alone is 415 files against one `src/` product file.

---

## Phase 1b — Data availability map

Snapshot time: **2026-09-25T00:2x+02:00** (all rows below), before this worker's own activity.

### Layer A — generic

| Source | Status | Location | Window | Trustworthiness |
|---|---|---|---|---|
| Git history / traceability | EXISTS | `git log`, `fw git log --traceability` | full repo history, 2452 commits | measured; 100% task-ref traceability per `fw audit` |
| Git churn | EXISTS | `git log --name-only` | 60-day window used this round | measured directly |
| Test suite (pytest) | PARTIAL | `tests/*.py` | now | 45 `test_*.py` files exist; only 20 are pytest-collectible (see §Fresh delta — 25 are standalone scripts misnamed as tests) |
| Test suite (bridge/validator shell) | EXISTS | `tests/run-bridge-tests.sh`, `run-validator-tests.sh` | now + `.run-history.tsv` (2 rows, since 2026-09-22) | measured; history is real but thin (2 data points) |
| CI | ABSENT (for verification) | `.onedev-buildspec.yml` | n/a | confirmed — mirror-push only, no test execution |
| Component fabric | EXISTS | `.fabric/components/` (411 cards) | continuously updated | measured (`fw fabric drift`): 13 unregistered, 0 orphaned, 0 stale edges |
| Dead-code/unused-dep tooling | ABSENT (no vulture/knip run found or attempted this round) | — | — | not measured this round — gap |
| Concerns/gaps register | EXISTS | `.context/project/concerns.yaml` (3949 lines), `fw gaps` | 52 watching, 0 resolved, continuously updated | measured, `fw gaps` output captured |
| Learnings | EXISTS | `.context/project/learnings.yaml` (2369 lines) | — | not content-sampled this round |
| Decisions | EXISTS | `.context/project/decisions.yaml` (2476 lines) | — | not content-sampled this round |
| Inbox/observations | EXISTS | `.context/inbox.yaml` (1779 lines) | `fw audit`: 42 urgent pending, 115 pending >7d | measured this round via audit |
| Episodic memory | EXISTS | `.tasks/completed/` × 682, `fw audit`: all have episodic summaries, 682/682 "quality content" | continuous | measured |

### Layer B — AEF/TermLink/Workflow Designer

| Source | Status | Location | Window | Trustworthiness |
|---|---|---|---|---|
| Task ledger | EXISTS | `.tasks/active` (155), `.tasks/completed` (682) | continuous | measured (`fw metrics`) |
| Arcs | EXISTS (3 in-progress, 0 ever closed per 2026-09-21 review) | `.context/arcs/*.yaml` — `arc-003` (audit remediation), `designer-authoring-surface`/arc-001, `ewcr-governed-delivery`/arc-002 | all 3 had commits within 30 days per `fw audit` PASS | measured this round (files read in full) |
| Capability registry | **ABSENT** | `policy/capabilities.yaml` | — | confirmed absent again this round |
| Prompts/dispatch templates | **ABSENT** | `policy/prompts/`, `agents/dispatch/` | — | confirmed absent again this round |
| Audit logs | EXISTS | `.context/audits/*.yaml`, cron subfolder | daily/hourly cron cadence per `fw audit` CTL-020 | measured; note — working tree currently shows mass **deletions** of `.context/audits/cron/2026-08-22-*.yaml` files in `git status` (pre-existing uncommitted state at session start, not caused by this worker — see Ground-truth note below) |
| Bypass log | EXISTS | `.context/working/.gate-bypass-log.yaml` | 149 total, 1 safety + 0 drift in last 7 days per `fw audit` | measured; content sampled (tail), shows `--skip-sovereignty` bypasses tied to recorded inception GO decisions, and one detailed T-559 project-boundary Tier-2 authorization trail (T-685) |
| Healing events | EXISTS | `fw healing patterns/suggest` | not queried this round (gap) | — |
| Command/verb usage | PARTIAL | no `command-usage survey` artifact found; `fw help` output captured directly | — | inferred only from `fw --help` listing, not from actual invocation counts |
| Token telemetry | PARTIAL | `fw costs` not queried this round (gap) | — | — |
| Value drivers | EXISTS | `policy/value-drivers.yaml` (289 lines, v3) | filed 2026-05-15, v3 2026-06-01 | measured — full file read |
| BVP scores | PARTIAL | task frontmatter `bvp_scores`/`bvp_scores_proposed` | **0/155 confirmed, 128/155 proposed-only, 27/155 neither** (measured fresh this round via direct YAML parse of all active tasks) | measured directly, not inferred |
| Realization log | **ABSENT** | `.context/audits/bvp-realization.jsonl` | — | confirmed absent again; consistent with "no arc has ever closed" (2026-09-21 review §9.4) — not re-verified this round |
| TermLink hub | EXISTS, live | `mcp__termlink__termlink_hub_status` | now | measured: `running`, PID 3071124, responding |
| TermLink doctor | EXISTS | `mcp__termlink__termlink_doctor` | now | measured: 7 pass / 1 warn (108 of 111 sessions share one identity fingerprint) / 0 fail |
| TermLink topics | EXISTS | `mcp__termlink__termlink_topics` | now, 111 sessions probed | measured: 135 topics total across 111 sessions; near-uniformly `session.exited`/`worker.done` (lifecycle-only); substantive topics (`file.chunk/complete/init`, `cohort.drift.detected`) appear on only 2 of 111 sessions |
| TermLink dispatch --isolate | EXISTS as capability, **0 usage** | `mcp__termlink__termlink_dispatch_status` | now | measured directly: "No dispatch manifest (no dispatches have used --isolate yet)" |
| Ratified workflows (BPMN) | EXISTS | `examples/aef-processes/`, `examples/app-processes/`, both with `rendered/` subdirs; `build/gallery/` | not re-walked this round beyond directory listing (gap — prior reviews did deeper corpus counts: 24 rendered maps, 6 saved workflows of which 1 is real content, per designer-product review §11) | listing only this round |
| Execution traces (`fw workflow run`) | **DESIGNED-ONLY / not 832's** | n/a | — | per 2026-09-21 review SQ-1, ruled out-of-scope for 832 |

**Ground-truth note on the audit-cron deletions:** the git-status snapshot supplied to this
worker at session start shows ~50+ `.context/audits/cron/2026-08-22-*.yaml` files staged as
deleted (`D`), plus modifications to `2026-08-30.yaml` and `2026-09-05-structure.yaml`. This
worker made **zero writes** other than this evidence file (constraint honored — no task files, no
source, no audits touched). The deletions were present in the working tree **before this
worker's first tool call**. Not investigated further (out of GATHERER scope to explain
pre-existing uncommitted state not created by this session) — flagged for the JUDGE/operator
because `.context/audits/**` is documented as an append-only ledger that "should never be
rewritten," and a mass deletion of 50+ files in that ledger, however it originated, is worth the
operator's attention independent of this review's classification work.

---

## Phase 2 — Inventory (subsystem grain — repo-scope forces this over per-function grain
given three prior reviews already went finer on `src/` and the seam)

| Item | Location | What it does (verified) | Capability/driver served | Prior deep-dive |
|---|---|---|---|---|
| Designer editor | `src/aef-workflow-designer.html` (11,503 lines) | Single-file BPMN-subset authoring canvas; opened and exercised by the 2026-09-21 review (loads, renders, 0 console errors) | F4 WORKFLOW_ROUTING, D3 Usability | `VALUE-REVIEW-designer-product-2026-09-20.md` (22 findings) |
| Designer docs | `docs/designer/*.md` (6 files) | Architecture, schema, user-guide, combined reference | D3 Usability, F3 AEF_INTEGRATION | flagged stale by 9 shipped feature tasks per designer-product review F-?? |
| `tools/` | 415 files, 316 `_tNNN-*`-prefixed instruments | Verification probes, census scripts, one-off repair tools, `yaml-to-bpmn.py` bridge, `validate-workflow.py` validator, `mcp-designer-server.py` | mixed: F2 fabric, F3 seam, D2 reliability | designer-product review: "118 instruments... sit in tools/ with no caller" (as of 2026-09-20; not re-measured at that granularity this round) |
| `tests/` | 222 files total; 45 `test_*.py`, 20 pytest-collectible, 4 `.sh` harnesses, fixtures/goldens/data | Correctness gate for the bridge/validator/editor-behavior surface | D2 Reliability | see Fresh delta below — new finding on the 20/45 split |
| `.fabric/` | 411 component cards, `watch-patterns.yaml` | Dependency/topology map | F2 V_COMPONENT_FABRIC | measured fresh: 13 unregistered, 0 orphaned |
| `.tasks/` | 155 active, 682 completed | Governed work ledger | D2 Reliability (traceability), all drivers indirectly | measured fresh via `fw metrics`/`fw audit` |
| `.context/` | arcs (3), audits, handovers, inbox (1779 ln), project memory (learnings/decisions/concerns ~8800 ln combined) | Working/project/episodic memory per CLAUDE.md | D1 Antifragility, D2 Reliability, F-RECALL | sizes measured fresh; content not sampled |
| `policy/` | `value-drivers.yaml`, `bvp-scoring-rubric.md` | BVP scoring source of truth | governs all drivers | full read this round |
| `examples/aef-processes/`, `examples/app-processes/` | + `rendered/` subdirs | The AEF-pinned seam corpus — **FROZEN, read-only per task constraints** | F3 AEF_INTEGRATION | listing only this round; prior reviews did full corpus counts |
| `build/gallery/` | `designer.html`, `index.html`, `rendered/` | Build output / served gallery | F4, D3 | listing only |
| `vendor/designer` | — | Third-party vendored asset | — | listing only, contents not opened |
| `scripts/` | 4 files: `announce-release.sh`, `embed-fonts.py`, `release-designer.sh`, `seam-manifest.sh` | Release cutting, seam-manifest recording (T-807, new since 2026-09-21) | F3, D2 | `seam-manifest.sh` confirmed new/working via `docs/branch-model.md` citation and T-807 commits |
| `.agentic-framework/` | vendored fw v1.6.354 | Governance tooling (task gate, audit, fabric, etc.) | D1, D2, D4 | gate behavior measured directly this round (G-020 self-block, safe-command allowlist) |
| TermLink integration | MCP tools, hub at `/var/lib/termlink` | Cross-session dispatch/comms substrate | F-RECALL(?), D1 (healing/dispatch) | measured fresh: hub alive, 111 sessions, dispatch --isolate at 0 usage |
| CI (OneDev buildspec) | `.onedev-buildspec.yml` | GitHub mirror push only | D4 Portability (mirroring), **not verification** | measured fresh — confirmed no test step |

**Reverse map (driver → serving items), partial, per data seen this round:**
- **D1 Antifragility** — healing agent (not queried this round), gap register (52 items, active), gate-bypass log (149 entries, logged not silent).
- **D2 Reliability** — task ledger + 100% git traceability; bridge/validator test suites; `fw audit` (162/22/1).
- **D3 Usability** — designer editor itself (per 2026-09-21 review, works when opened); `fw help` (some verbs like `fw bvp`/`fw arc` absent from it per that review, not re-checked this round).
- **D4 Portability** — branch model (file-based, git-native); vendored `.agentic-framework/` (self-contained).
- **F1/F3/F4** (SDLC/AEF-integration/workflow-routing) — the whole `examples/aef-processes` seam, `scripts/seam-manifest.sh`, the bridge/validator toolchain.
- **F2 V_COMPONENT_FABRIC** — `.fabric/` itself; 13/411 unregistered is the only visible gap.
- **F-RECALL** — `.context/` memory layers; no capability found this round that closes the "L4 Reflect" retire_when condition (CLAUDE.md auto-sync, preference index) — not independently re-verified, carried as open per the driver's own text.

**Nothing-serves-it check:** not exhaustively re-run this round (would require walking every
gap/G-item against every driver) — the 2026-09-21 review's ADD list (F-1 fw help surfacing,
F-3b capability registry, I-3 realization log) already names three; this round confirms all
three are **still unaddressed** (fresh checks above), which is itself the data point, not a new
finding.

---

## Phase 3 — Fresh delta since 2026-09-21 (evidence only, no classification)

### D-1. Test-file naming vs. pytest collection (NEW this round)

`find tests -maxdepth 1 -iname "test_*.py" | wc -l` → **45**. `python3 -m pytest tests/
--collect-only -q` → **20 tests collected**, from 19 distinct files. The other **25 files named
`test_*.py` contain zero `def test_*` functions** — verified by direct grep on 4 sampled files
(`test_bridge_aef_passthrough.py`, `test_t312_lane_geometry.py`, `test_validate_iw9.py`,
`test_two_lane_joint_contract.py`: all `grep -c "^def test_"` → 0) and by one full collection
diff (`comm -23` between the file list and the collected-file list — full 25-file list in this
session's tool output, reproducible). One inspected in full,
`tests/test_designer_render.py`: defines `_QuietHandler`, `_resolve_build()`, `_serve()`,
`main()` — a standalone HTTP-serve CLI script, not a pytest test, despite the `test_` filename
prefix pytest's own default discovery pattern matches. Plain `python3 -m pytest tests/` (the
obvious command for anyone new to this repo, and the one this worker ran first per the Phase 0
baseline instruction) reports "20 passed" with **no indication that 25 more files exist and
were silently not run** — pytest's default output does not warn about files it declined to
collect because they had nothing to collect.

**Non-use diagnosis evidence (which reading, not resolved here):**
- **Not simply "broken"**: at least the 4 sampled files are deliberately structured as
  standalone probes/CLI harnesses (consistent with `tools/_tNNN-*` naming elsewhere in this
  repo), likely invoked directly (`python3 tests/test_X.py`) or via `tests/run-bridge-tests.sh` /
  `run-validator-tests.sh`, not via bare pytest. Not fully confirmed for all 25 — only 4 sampled.
- **Discoverability** (reading C candidate): nothing in `README.md`, `CLAUDE.md`, or (unchecked
  this round) `tests/` itself documents that `pytest tests/` intentionally covers a strict
  subset. No `pytest.ini`/`pyproject.toml`/`setup.cfg` exists anywhere at depth ≤1 to encode or
  explain the split (`find . -maxdepth 1 -iname pytest.ini -o -iname setup.cfg -o -iname
  pyproject.toml` → empty).

### D-2. Bridge suite run-history is 3 days stale, and failures increased (NEW this round)

`tests/.run-history.tsv` (created by T-813, per its own header comment, to make "the age of the
red state... measurable going forward") has exactly **2 rows**:

```
2026-09-22T13:42:12Z   131 passed   7 failed   rc=1   784s   sha 7fe65e0b
2026-09-22T15:12:08Z   133 passed  10 failed   rc=1   810s   sha bcc780bc
```

Between those two runs (90 minutes apart, same day), **failures went 7→10, not down**. No row
exists between 2026-09-22T15:12 and this session (2026-09-25, ~00:35+02:00) — a **~3-day gap**
during which **122 commits landed** on the branch (git log count, §[ASK]). The instrument T-813
built specifically to answer "how old is this failure" has itself gone unread/unrun for the
majority of the time since it was built. This worker ran a **fresh run** of
`tests/run-bridge-tests.sh` at session start (per the Phase 0 baseline instruction). It appended
row 3 itself:

```
2026-09-24T22:51:15Z   142 passed   9 failed   rc=1   1045s   sha 2a841f3f
```

(`2a841f3f` = this session's `HEAD`, confirmed via `git rev-parse --short HEAD`.) Reading across
all three rows: passed-count grew each time (131→133→142, consistent with corpus/leg growth), and
failed-count went **7→10→9** — net still above the 2026-09-22 baseline, not returned to it.
**Duration also grew** (784s→810s→1045s, +33% over the two prior runs) — the suite is getting
slower as well as no more reliably green than it was 3 days ago. One concrete failure observed
live in this run's stdout before the scratch capture file was lost (see note below):
`tests/test_release_immutability.py` (a "previously-unrun leg," per the runner's own section
header, added by T-316) failed with `FileNotFoundError: /tmp/tmpjmojvp7o/dist/
aef-workflow-designer-0.1.0.html` — a missing historical release artifact in a temp directory,
not obviously a defect in the guard itself; not investigated further (would require exercising
release tooling, out of GATHERER's read-only scope beyond observing the failure as emitted). The
other 8 failures were not individually captured — see environment note immediately below.

**Environment note (new friction finding, not a source or capability of the project under
review):** this worker's assigned scratch directory, `/tmp/tl-dispatch/vr0925g1/`, was **reaped
out from under the running session** — `ls /tmp/tl-dispatch/` shows only a different, unrelated
worker's directory (`t247-r1-audit`) by the time the bridge-suite run finished; the earlier
capture files this worker wrote there (`fw-audit-full.txt`, `bridge-tests-run.txt`, etc.) were
gone (`No such file or directory`) despite `tests/.run-history.tsv` — a file inside the
**project's own tree**, not `/tmp` — surviving intact. Whatever process rotates `/tmp/tl-dispatch/`
across concurrent TermLink dispatches did not wait for this worker's background job to finish
using its assigned directory. Practical effect on this evidence file: two full-text captures
(`fw audit`'s complete WARN list beyond the first ~40 lines, and the bridge suite's other 8
failure messages) are **not fully reproducible from a saved artifact** — every fact actually
*used* above was read and quoted into this file before the loss, but nothing beyond what is
quoted here can be recovered from those two runs. Re-run each command directly to get the full
text again; both are cheap and safe-listed (`fw audit`, `bash tests/run-bridge-tests.sh`).

### D-3. BVP confirmation still at zero (corroborates 2026-09-21, fresh count)

Direct YAML parse of all 155 active task files' frontmatter (this session, reproducible one-
liner in tool output): **0 have `bvp_scores` (confirmed)**, **128 have `bvp_scores_proposed`
only**, **27 have neither**. The 2026-09-21 review recorded "0 of 149 confirmed" (F-8b). Four
days and two dispatched scoring rounds later (T-837, per git log: "score the full 20-task
unscored pool... every one resolves to lv-lc"), the **proposed** pool grew (149→155 active tasks,
most now carrying a proposal) but the **confirmed** count did not move at all. `bvp_scores`
confirmation is explicitly gated to human/agent confirmation via `fw bvp confirm`
(`policy/value-drivers.yaml` header comment: "Sovereignty boundary — only set after human or
agent confirmation") — this is a sovereignty-boundary field, not a data gap; recorded as fact,
not as a reading.

### D-4. Capability-registry-shaped ABSENT rows are unchanged (corroborates 2026-09-21)

`policy/capabilities.yaml`, `.context/bus/`, `.context/audits/bvp-realization.jsonl`,
`policy/prompts/`, `agents/dispatch/*template*` — all re-checked by direct `find`/`ls` this
round, all still absent, identical to the 2026-09-21 snapshot. No decay, no progress, in either
direction, over 122 commits.

### D-5. TermLink dispatch --isolate: designed capability, zero measured uses (NEW this round)

`mcp__termlink__termlink_dispatch_status` → `{"message": "No dispatch manifest (no dispatches
have used --isolate yet)", "ok": true, "total": 0}`. The capability exists (documented in
CLAUDE.md's Quick Reference and the review-prompt's own Data Layer B section: "dispatch
--isolate worktrees — merge conflicts/auto-merge failures → governance-plane hotspots") but has
literally never been invoked in this TermLink hub's lifetime, per its own status call. This is a
**Layer B TermLink source going from PARTIAL/unmeasured to a clean, direct zero** — worth
flagging because "designed but never used" (reading B, never wired — vs. reading E, not wanted)
cannot be distinguished from this data point alone; no origin task/arc was located this round
that specifically commits to using `--isolate` (not searched exhaustively).

### D-6. TermLink topic traffic is near-uniformly session-lifecycle noise (NEW this round)

`mcp__termlink__termlink_topics` (no target = all sessions): 111 sessions probed, 0 unreachable,
135 total topics. Of 111 sessions, **109 carry only `session.exited` and/or `worker.done`** —
lifecycle events. Only **2 sessions** carry anything else: `termlink-agent` (`file.chunk`,
`file.complete`, `file.init` — file-transfer protocol topics) and `email-archive`
(`cohort.drift.detected`, an application-specific topic from what is evidently a different
project's agent sharing the same hub). **No topic observed this round carries workflow-designer-
specific application data** (e.g., nothing named for BVP scoring, fabric drift, or workflow
authoring) — consistent with the 2026-09-21 review's characterization of TermLink read receipts
as "~3 weeks stale" and the ground-rule warning that presence/lifecycle traffic should not be
read as work traffic.

### D-7. Git churn hotspot, 60-day window (NEW this round, for the REFACTOR-shaped hotspot signal)

`git log --since="60 days ago" --name-only` by top-level source directory: **`tools/` = 639
file-touches**, `src/` = 42, `scripts/` = 7, `lib/` = 1. `tools/` churns roughly **15× more**
than the single product file it mostly exists to verify. (Framework state files —
`.context/handovers/LATEST.md` at 426 touches, various `.context/working/.{counter,status}`
files — dominate the raw top-25 list but are expected high-frequency machinery, not source; they
are recorded for completeness in this session's tool output but not treated as a hotspot signal
here.) Whether 639 touches over 60 days on `tools/` represents healthy iterative
instrumentation-building or churn-as-cost is a Phase 4 judgement, not measured further here
(would need per-file churn×complexity, not attempted this round — data gap).

### D-8. Gaps register — 52 watching, 0 ever resolved

`fw gaps` (full output captured this session, `.context/project/concerns.yaml` is 3949 lines).
Sampled the first ~20 (G-001 through G-027, not contiguous — some IDs absent from the visible
page): recurring theme is **audits/gates reporting a clean verdict over an unmeasured or empty
population** (G-013: cron audits ran `sections=structure`, 20 of 117 checks, reported clean;
G-017: fabric coverage computed over an empty denominator; G-021: an unverified claim about
another system shipped in every release for 59 days; G-024: no instrument holds pinned-artifact-
vs-src delta visible without being asked). **0 resolved of 52** — this register has never closed
an item as of this snapshot (`fw gaps` header: "52 watching, 0 resolved"). Not independently
re-verified against `concerns.yaml`'s full history (3949 lines, only the `fw gaps` summary read
this round) — could mean gaps are opened faster than closed, or that "resolved" tracking itself
is the gap; not distinguished here.

### D-9b. Doc-vs-code staleness, `docs/designer/schema.md` (fresh count this round)

`git log -1 --format=%ai -- docs/designer/schema.md` → **2026-07-04**. `git log -1 --format=%ai
-- src/aef-workflow-designer.html` → **2026-09-22**. `git log --oneline --since=2026-07-04 --
src/aef-workflow-designer.html | wc -l` → **144 commits** have touched the product file since the
schema doc was last edited. Corroborates, with a fresh number, the designer-product review's
2026-09-20 finding that `docs/designer/schema.md` "is stale by nine shipped feature tasks" — the
gap has widened by ~2.5 months and well over a hundred more commits since that finding was
recorded; not independently re-checked against the frozen standard's field list this round
(would require opening both documents in full — out of this round's budget).

### D-9c. Fabric "0 orphaned" contradicted by an open, not-yet-fixed task (NEW this round)

`fw fabric drift` (this session, §Phase 0 baseline) reports **"Orphaned cards: (none)"** — the
same clean reading `fw audit` and the fabric summary above show. But
`.tasks/active/T-834-fabric-discards-vendored-path-edges-by-d.md` (status `captured`,
`workflow_type: build`, `horizon: later`, created 2026-09-23, i.e. **2 days before this
snapshot and still open**) states as its own title and description: *"Fabric discards
vendored-path edges by design, so 41 connected cards read as orphans."* This is a **source-vs-
source contradiction**: the live drift check says 0 orphans; an open task two days old, filed by
a prior agent session, says the true orphan-detection mechanism is broken by design and would
show 41 if fixed. Not resolved here — recorded side by side per the ground rules. The task is
`horizon: later` (not currently queued for work) and has a `bvp_scores_proposed` entry
(D1:4 D2:0 D3:2 D4:2 F-RECALL:0 — proposed only, not confirmed, consistent with D-3 above).

### D-9. Working-tree state at session start (context, not this worker's doing)

`fw audit`: "Uncommitted changes present — 288 real file(s) modified (1668 session-state file(s)
ignored)." This matches the git-status snapshot supplied at conversation start (mass deletions in
`.context/audits/cron/`, modifications to two audit files). This worker added exactly one file
(this evidence file) and made no other writes — constraint honored, verified by this worker's own
tool-call history (no Edit/Write calls except this one).

### D-9d. "GO'd and nobody filed" — one instance named, currently being worked (NEW this round)

`.tasks/active/T-835-authority-on-the-element-lane-as-domain-.md` (status `started-work`,
`workflow_type: design`, `horizon: now`) — title: *"Authority on the element, lane as domain:
the mechanism T-685 GO'd and nobody filed."* Not read in full this round (only frontmatter/title
checked) — flagged because it is a **named, self-reported instance of reading B (never wired)**:
an inception decision (T-685, GO, per the bypass log entry sampled in the Data Availability Map
above) that produced no follow-up build task until this one, filed independently. Currently
`started-work`, so may be closed by the time the JUDGE round runs — status at time of writing
only.

---

## Non-use diagnosis summary (evidence only — readings not assigned)

| Candidate | A Broken | B Never wired | C Undiscoverable | D Unmeasured | E Not wanted | Intent evidence |
|---|---|---|---|---|---|---|
| 25 misnamed `test_*.py` non-pytest files | not shown broken (4 sampled work as standalone scripts) | possible — no doc names the split | **yes** — pytest's own default silently under-collects, nothing documents it | — | no evidence found | named `test_`, live in `tests/`, clearly intended as verification |
| `tests/run-bridge-tests.sh` scheduled execution | **yes** — 3-day gap, T-813's own instrument shows it | — | — | — | no | T-813 built the history mechanism specifically so this wouldn't be invisible; its own header names a cron line as "the operator's" and notes "Scheduler not installed" (T-813 commit message) |
| `policy/capabilities.yaml` (capability registry) | — | **yes** — named as ADD(instrument) by 2026-09-21 review, still absent | — | — | no | explicitly requested by a prior review round, unchanged since |
| TermLink `dispatch --isolate` | — | **possible** — capability exists, 0 recorded uses | — | possible — usage could exist but not be captured in the manifest | no evidence found | documented in CLAUDE.md Quick Reference and this review prompt's own Data Layer B list |
| BVP `bvp_scores` confirmation | — | — | — | — | not indicated — this is a designed human-gate, not a defect | sovereignty-boundary field by design (`policy/value-drivers.yaml` header); zero confirmations may be the gate working as intended, or the gate never being exercised — JUDGE call |
| `.context/bus/`, `bvp-realization.jsonl`, `policy/prompts/` | — | possible | — | — | no evidence found | all three named as ADD candidates by the 2026-09-21 review; recurrence across two snapshots (09-21, 09-25) with zero movement is itself evidence for the JUDGE, not a verdict |

---

## Data gaps that capped confidence this round

1. Full corpus counts for `examples/aef-processes/` and `build/gallery/` were not re-walked
   (listing only) — prior reviews (2026-09-20/21) have the deeper numbers; not re-verified fresh.
2. `fw healing patterns`/`fw healing suggest` not queried — MTTR / failure-class data absent from
   this round.
3. `fw costs` (token telemetry per task/arc) not queried.
4. Dead-code/unused-dependency tooling (vulture, or equivalent) not run against `tools/`'s 415
   Python/shell/mjs files — the "639 touches in 60 days" churn number has no matching usage-
   reachability number to pair it with.
5. `.context/project/concerns.yaml` (3949 lines), `learnings.yaml` (2369), `decisions.yaml`
   (2476) were sized but not content-sampled beyond the `fw gaps` summary view.
6. The bridge-suite fresh run's per-leg failure detail (8 of its 9 failures) was lost when this
   worker's `/tmp` scratch directory was reaped mid-run — see the environment note under D-2.
   The suite is cheap to re-run for anyone who needs the full list.
7. AEF-side (999-AEF) evidence is categorically out of reach (read-only per T-559) — every
   question about whether the seam is actually consumed on the other end is answerable only from
   this side's artifacts (pins, tags, manifests), never from the consumer's own telemetry.

---

## Addendum — fresh bridge-suite run result

Filled in above at D-2 once the run completed (142 passed / 9 failed / rc=1 / 1045s / HEAD
`2a841f3f`, appended to `tests/.run-history.tsv` as its row 3). Kept as a heading for traceability
with how this file was assembled — no additional content beyond what D-2 already states.

