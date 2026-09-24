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

---

## Round 2 — full-pass coverage

**Round 2 of 4 (GATHERER only), worker `vr0925g2`, dispatched via `fw termlink dispatch --task
T-838`.** Same role constraints as round 1: Phases 0–3 only, no classification, no
recommendations, class-shaped words below are quotations. This section **extends** the file above
— round 1's content is left unchanged. Where this round's findings sit alongside round 1's, they
are cross-referenced, not merged.

**Mandate for this round, per the operator's correction relayed in this worker's dispatch:**
*"process all again and scan all folders"* — a full pass, not a delta, with specific instruction
to close round 1's coverage gap: **`.claude/` received zero references in round 1's evidence
file**, despite being explicitly named in the review prompt's Phase 2 inventory list (gates) and
being the actual hook/enforcement wiring the whole CLAUDE.md governance model depends on.

### Folder-by-folder coverage this round

| Folder | Examined this round | Depth |
|---|---|---|
| `.claude/` | **Yes — new this round** | full: `settings.json` (all hook entries), `settings.local.json`, `commands/resume.md`, git-tracked status of each file |
| `.fabric/` | Yes | targeted: searched for any `.claude`-named component card (see D-11) |
| `dist/` | Yes — new this round | full file listing, sizes, `MANIFEST.yaml` read in full |
| `vendor/designer/` | Yes — new this round | full listing + git log for both files |
| `build/` | Yes — new this round | full recursive listing (27 files: 24 `.bpmn` + `customer-refund.bpmn` + `designer.html` + `index.html`) |
| `.editor-versions/` | Yes — new this round | listing + tracked/untracked split (181 tracked, 15 untracked `vN.png` files pending) |
| `.playwright-mcp/` | Yes — new this round | full listing, size, age range, cross-repo reference count |
| root-level loose PNGs | Yes — new this round | tracked/untracked status, reference search, per-file git log |
| `.mcp.json` | Yes — new this round | full read |
| `.framework.yaml` | Yes — new this round | full read (surfaced D-12) |
| `policy/` | Re-confirmed | listing only (2 files, matches round 1) |
| `examples/` | Re-confirmed | directory-depth listing only (51 files, 4 top subdirs) — full corpus counts still not re-walked (carried gap from round 1) |
| `tools/` | Sampled | 15-file random reference-count sample (see D-13); not a full orphan sweep |
| `scripts/`, `src/`, `tests/`, `.tasks/`, `.context/`, `.agentic-framework/` | Not independently re-examined this round | round 1's coverage stands; see "Not reviewed" below |

### D-10. `.claude/` — the enforcement wiring, inventoried for the first time in this review series

`.claude/` contains exactly 3 files, 2 git-tracked:

- **`.claude/settings.json`** (tracked) — the hook wiring CLAUDE.md's entire "Automated
  Monitoring" and gate sections describe in prose. Verified by direct read, not by CLAUDE.md's
  description of it:
  - `PreCompact` → `fw hook pre-compact`
  - `SessionStart` (matcher `compact`, matcher `resume`) → `fw hook post-compact-resume` (both)
  - `PreToolUse`, 9 matcher blocks: `EnterPlanMode`→`block-plan-mode`; `Write|Edit|Bash`→
    `check-active-task`; `Write|Edit`→`check-human-ac-tick`; `Bash`→`check-tier0`; `Agent`→
    `check-agent-dispatch`; `Write|Edit|Bash`→`check-project-boundary`; `Write|Edit|Bash`→
    `budget-gate`; `TodoWrite|TaskCreate|TaskUpdate|TaskList|TaskGet`→`block-task-tools`;
    `mcp__termlink__.*`→ **not an `fw hook` call at all** — it invokes
    `tools/_t420-rail-attribution-gate.py` directly, a project-local script outside the
    `.agentic-framework/` vendored tree, on every TermLink MCP call.
  - `PostToolUse`, 7 matcher blocks: two empty-matcher (`""`, i.e. all tools) entries —
    `checkpoint post-tool` and `loop-detect` — plus `Bash`→`error-watchdog`, `Task|TaskOutput`→
    `check-dispatch`, `Write`→`check-fabric-new-file`, `Write|Edit`→`commit-cadence`, and a
    second empty-matcher entry → `audit-task-tools`.
  - `permissions.deny`: `EnterWorktree`, `ExitWorktree`, `Bash(git worktree:*)` — git worktree use
    is denied project-wide at the settings layer, independent of any `fw` gate.
- **`.claude/commands/resume.md`** (tracked) — the `/resume` slash command definition. Text
  differs from the `resume` **skill** listed in this session's system reminder (same name,
  different source — the skill list shows a plugin/skill named `resume-full` too, "Pick Up Where
  We Left Off"). Not cross-checked for behavioural drift between the command file and the skill
  this round (gap).
- **`.claude/settings.local.json`** (present on disk, confirmed **not git-tracked** — matched by
  a rule in `/root/.config/git/ignore` at the *global* gitignore level, not this
  project's `.gitignore`, per `git check-ignore -v`) — a permissions allowlist (58 entries, mostly
  `mcp__termlink__*` read verbs and `mcp__playwright__*` browser verbs) plus
  `enabledMcpjsonServers: [context7, playwright, termlink]`. Machine-local by design (global
  ignore rule, not a project decision) — recorded for completeness, not a repo item to classify.

**Why this matters as a coverage finding, not yet a verdict:** every Tier-0/G-020/budget-gate
behaviour round 1 observed directly (T-838's own G-020 block, the `check-active-task.sh` line
numbers cited) is *triggered* from this file. Round 1 read the downstream script
(`.agentic-framework/agents/context/check-active-task.sh`) but never the dispatcher that wires it
to specific tool matchers. No behavioural gap was found this round (the wiring matches what round
1 observed happening) — the gap was purely in round 1's evidence file having zero citations to the
file that causes it.

### D-11. Component fabric has zero cards for `.claude/`, corroborating and extending the round-1 gap

`find .fabric/components -iname "*claude*"` → **empty, 0 results**. `.fabric/` (411 component
cards, per round 1's Phase 1b table) — the project's own "structural topology map of every
significant file" (CLAUDE.md, Component Fabric section) — has **no card for `.claude/settings.json`
or any file under `.claude/`**. This is not just round 1's evidence-file blind spot; it is the same
blind spot in the project's own self-maintained structural map. `fw fabric drift` (round 1's Phase
0 baseline) reported 13 unregistered files and 0 orphaned — not independently re-checked this round
whether `.claude/settings.json` is among those 13 "unregistered" (would require reading the drift
tool's unregistered-file list in full, not captured verbatim by round 1 or this round — data gap).

### D-12. `CONTEXT_WINDOW` is configured to 800000, not the 300000 CLAUDE.md calls "default"

`.framework.yaml:9` → `CONTEXT_WINDOW: 800000`. CLAUDE.md's own "Context Budget Management (P-009)"
section states the escalation thresholds "at the default 300K window" (225K/255K/285K) and
explicitly warns "any absolute number written here is a derived illustration that goes stale the
moment the window changes — which is exactly what happened (T-614)." This project's actual
configured window (800000) is 2.67× that illustrative default. The section is self-aware of this
exact failure mode (T-614 is cited as a prior instance) but the illustrative numbers are still the
only concrete numbers printed in the file — an agent skimming CLAUDE.md rather than running
`checkpoint.sh budget` would compute thresholds against the wrong base by construction. Not a new
class of defect (the section already names the risk), but this round confirms the risk is live
right now in this project's own config, not hypothetical.

### D-13. `dist/` — 17 releases kept, 13.5MB, no pruning mechanism found

`dist/` holds every released version from 0.1.0 through 0.13.0 (17 `.html` files, 13,527,127 bytes
total, `du`/`ls -la` this round) plus `MANIFEST.yaml`. `MANIFEST.yaml` (full read) records
`latest`, `artifact`, `sha256`, `version`, `released`, `src_commit`, `supersedes` for the *current*
release only — it has a `supersedes` chain field but **no retention or pruning instruction**; nothing
in `docs/` found this round documents whether old `dist/*.html` files are meant to be pruned,
archived elsewhere, or kept forever (searched `docs/**/*.md` for "retention"/"prune" — the 4 hits
found are all *other* topics' retention policies — TermLink message retention, T-530 handover
growth, T-617/T-762 unrelated — not one is about `dist/`). Growth is monotonic and unbounded on
current evidence: 17 versions in ~2.5 months (`0.1.0` release date not captured this round;
`0.13.0` released 2026-09-22 per MANIFEST). `dist/` is git-tracked (`git ls-files dist | wc -l` →
17, confirmed earlier in this session) so every historical `.html` is also permanently in git
history in addition to the working tree.

### D-14. `vendor/designer/` — the local "consumer intake" pin is one release behind `dist/`'s latest

`vendor/designer/` holds exactly 2 files: `aef-workflow-designer-0.8.0.html` and
`aef-workflow-designer-0.12.0.html`. Git log on the 0.12.0 file shows it was added 2026-09-21 by
T-743 ("our own Watchtower now serves 0.12.0 — consumer intake"). `dist/MANIFEST.yaml` (D-13)
shows `dist/`'s actual latest is **0.13.0**, released 2026-09-22 — one day after the vendor pin was
last updated. Whether this is "normal lag before the next consumer-intake pass" (reading D,
unmeasured/not-yet-run) or something further behind cannot be determined from this evidence alone
— no task was found this round committing to a cadence for re-running consumer intake after each
release (not searched exhaustively).

### D-15. `.playwright-mcp/` — 7.2MB of git-tracked verification screenshots, referenced by ~30 task files, inconsistent destination

`.playwright-mcp/` holds 76 git-tracked PNG files (`git ls-files .playwright-mcp | wc -l` → 76),
7.2MB total (`du -sh`), spanning **2026-07-05 to 2026-09-22** (`git log --diff-filter=A` first/last
commit dates, ~2.5 months). These are **not orphaned** — `grep -rl "playwright-mcp/"` across `.md`/
`.py`/`.sh` files (excluding the directory itself) finds 78 hits, including `.tasks/active/` and
`.tasks/completed/` files citing specific screenshots as Human-AC or visual-verification evidence
(e.g. `T-233`, `T-589`, `T-756`), consistent with CLAUDE.md's "Visual Verification for UI Changes"
protocol requiring a screenshot reference before a CSS/HTML commit. **Destination is inconsistent**,
however (new finding, cross-referenced with D-16 below): some screenshots land in
`.playwright-mcp/` (tracked), some in `docs/screenshots/` (tracked, 20 files per the earlier `git
ls-files "*.png"` listing), some in `docs/reports/<task>-evidence/` or `docs/reports/assets/`
(tracked), and some are dumped loose at repo root and **never committed at all** (D-16). No single
documented convention for "where does a verification screenshot go" was found this round (not
exhaustively searched — CLAUDE.md's Visual Verification section says to take and read screenshots,
not where to save them).

### D-16. Loose, untracked PNGs at repo root — screenshot destination has no enforced convention

Of the 6 `.png` files sitting at the repository root (`designer-initial.png`, `t233-gallery.png`,
`t589-populated.png`, `t598-light.png`, `t646-after.png`, `t808-header-default.png`), **only
`t233-gallery.png` is git-tracked** (`git ls-files "*.png"` this round). The other 5 are untracked
working-tree files (`git status --porcelain` shows `?? designer-initial.png` etc.) — never
committed, sitting in the live working tree of the project under review. `t233-gallery.png`
itself, the one tracked exception, was swept into an unrelated commit (`b4a783cc`, 2026-08-15,
commit message describes a PreCompact handover, not this PNG) and has **zero references** in any
`.md` file in the repo (checked this round). 3 of the 5 untracked files (`t589-populated.png`,
`t598-light.png`, `t646-after.png` — each with 2 `.md` references per this round's grep) are
referenced from `.md` files despite
being uncommitted, meaning the *committed* documentation points at images that exist only in this
one working tree and would 404/break for anyone who clones the repo fresh. `designer-initial.png`
and `t808-header-default.png` have zero references anywhere and are also untracked. Alongside
`.editor-versions/`'s 15 untracked `vN.png` files (D found in the folder-by-folder pass above) and
`.playwright-mcp/t258-annotation-badges.png` showing as locally-modified (`M`, not committed) plus
3 more untracked `.playwright-mcp/page-*.png` timestamped files, this round's git-status scan shows
a **recurring pattern of screenshot artifacts generated during sessions that never reach a commit**
— consistent with, but broader than, the pre-existing mass-deletion state in `.context/audits/cron/`
that round 1 flagged as present at session start and not this worker's doing.

### D-17. `tools/` reference sampling — no clean orphans found in a 15-file random sample, but the metric is weak

A random 15-file sample of `tools/*.py` (fixed seed, reproducible) cross-referenced against
`.md`/`.py`/`.sh`/`.yaml` files repo-wide (excluding the file's own path) found every sampled file
mentioned **at least 5 times** elsewhere (range 5–314; the top of the range,
`tools/yaml-to-bpmn.py` at 314 and `tools/_t358-teeth.py` at 214, are the bridge tool and a
frequently-cited test-hygiene gate respectively). **This is a discoverability/mention count, not a
call-graph or execution-reachability measurement** — a task file that merely *discusses* a tool
counts the same as a CI job or test that *invokes* it. The 2026-09-20 designer-product review's
"118 instruments... sit in `tools/` with no caller" finding (round 1's Phase 2 table, citing that
report) was **not reproduced or falsified this round** — this sample used a different, weaker
method (string mention, not caller analysis) and a small random sample (15 of ~415 files), so it
neither confirms nor contradicts that finding; a proper orphan sweep (e.g. grep for each filename
used as a **subprocess/import target**, or a `vulture`-class tool per the Data Layer A row round 1
recorded as ABSENT) remains undone across both rounds.

### DELETE-relevant evidence gathered independently this round

Per the operator's explicit instruction not to treat "0 DELETE across 3 prior reviews" as settled,
this round looked specifically for references/supersession/staleness signals, independent of the
prior reports' conclusions:

| Candidate | References found | Superseded by | Activity window | Note |
|---|---|---|---|---|
| `designer-initial.png` (root) | 0 | — | untracked, mtime not captured | never committed; D-16 |
| `t233-gallery.png` (root) | 0 | — | tracked since 2026-08-15, 41 days idle | committed incidentally alongside unrelated content; D-16 |
| `t808-header-default.png` (root) | 0 | — | untracked | never committed; D-16 |
| `dist/aef-workflow-designer-0.1.0.html` … `0.12.0.html` (16 superseded releases) | each superseded per `MANIFEST.yaml`'s `supersedes` chain | `dist/aef-workflow-designer-0.13.0.html` (current `latest`) | releases span the full project history to date | D-13 — intent evidence (release-history/audit trail value) not ruled out; `MANIFEST.yaml`'s own `src_commit`/`released` fields suggest these are meant as an audit trail, which is a reason *for* keeping them, not against |
| 25 of 45 `test_*.py` files (not pytest-collectible) | referenced by pytest's own default collection as 0 test functions (round 1, D-1) | — | — | carried from round 1, not re-verified this round; included here because it is the clearest existing DELETE-shaped-or-REFACTOR-shaped candidate already on record (misnamed, not necessarily unused) |
| `vendor/designer/aef-workflow-designer-0.8.0.html` | superseded within its own 2-file set by 0.12.0 | `vendor/designer/aef-workflow-designer-0.12.0.html` | added 2026-06 era (T-296 commit, per round 1's git log sample `405a39d9`) | D-14 — a "consumer intake" simulation artifact; whether keeping the oldest historical pin has test/regression value not determined this round |

No item in this table clears the DELETE CHECKS (Phase 4 gate) on this evidence alone — in
particular, checks 2 (readings A–D ruled out) and 5 (no external consumer) are not established for
any row here; this is deliberately left as raw material for the JUDGE, not a proposal.

### Non-use diagnosis additions (Round 2)

| Candidate | A Broken | B Never wired | C Undiscoverable | D Unmeasured | E Not wanted | Intent evidence |
|---|---|---|---|---|---|---|
| `.claude/settings.json` hook wiring | no evidence of breakage found (round 1 observed its effects firing correctly — G-020 block, budget-gate) | no — actively firing | **yes, of the file itself** — the project's own structural map (`.fabric/`) and this review series (round 1) both missed it; CLAUDE.md describes its *effects* in prose but never names the file | — | no | it is the literal mechanism CLAUDE.md's entire "Enforcement Tiers" and "Automated Monitoring" sections describe; high intent evidence |
| Root-level untracked PNGs (5 of 6) | not applicable — not a capability | not applicable | not applicable | not applicable | possible — could be pure session litter with no one intending to keep them | mixed: 3 of 5 are referenced from committed `.md` files (broken links for fresh clones — itself an A-shaped defect in the *documentation*, not the image); 2 of 5 have zero references anywhere |
| `dist/` old-version retention | not applicable | possible — no pruning mechanism ever built despite unbounded growth | no — `dist/` and `MANIFEST.yaml` are named in `docs/aef-designer-integration-protocol.md` per the manifest's own header comment (not independently opened this round to confirm) | — | possible — if the audit-trail read is correct, "no pruning" may be intentional, not missing | `MANIFEST.yaml`'s structured `supersedes`/`released`/`src_commit` fields look deliberately built for an audit trail, which argues for intent over neglect |
| `vendor/designer/` 0.8.0 (older of 2 pinned files) | no | possible | no | possible — could be a deliberate "first release" baseline kept for regression comparison, not measured | no evidence found | not determined this round |

### Not reviewed (Round 2 — in addition to round 1's data gaps, still standing)

1. `scripts/`, `src/`, `tests/`, `.tasks/`, `.context/`, `.agentic-framework/` content were not
   independently re-opened this round beyond what round 1 already captured — this round trusted
   round 1's readings there and spent its budget on the folders round 1 missed or under-covered.
2. `tools/` orphan analysis remains a sample (15 of ~415 files), not a sweep; no `vulture`-class
   tool was run (round 1's Data Layer A gap, still open).
3. `.claude/commands/resume.md` vs. the `resume`/`resume-full` skills' actual current text —
   named as a possible drift pair (D-10) but not diffed this round.
4. `docs/aef-designer-integration-protocol.md` — cited by `dist/MANIFEST.yaml`'s header comment as
   the protocol document for the release manifest, but not opened this round to confirm it
   documents (or fails to document) `dist/` retention.
5. `.fabric/`'s 13 "unregistered" files (per round 1's `fw fabric drift` output) were not
   individually listed this round to confirm whether `.claude/settings.json` is one of them (D-11).
6. Full corpus counts for `examples/aef-processes/` and `build/gallery/` — still not re-walked
   (carried forward from round 1's own open gap #1).
7. All of round 1's own "Data gaps that capped confidence" (healing patterns, `fw costs`,
   `.context/project/*.yaml` content sampling, the lost bridge-suite failure detail, AEF-side
   telemetry) remain open — not attempted again this round.

