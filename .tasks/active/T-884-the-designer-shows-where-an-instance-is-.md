---
id: T-884
name: "The designer shows where an instance is: current node, completed nodes, and
  the node a refusal fired on"
description: >
  arc-005 S4/B10. CONTINGENT on T-878 and T-879. This is the half that makes the other
  three visible and it is the demo that closes arc-005 (A4). Must render the refusal,
  not only progress.

status: work-completed
workflow_type: build
current_node: frw_8_partial
owner: human
horizon: now
tags: [arc:process-instances]
components:
  - tools/instance-node.py
  - tools/gallery-serve.py
  - src/aef-workflow-designer.html
  - tools/_t884-instance-overlay-cdp.mjs
  - tools/_t884-live-proof-cdp.mjs
  - tests/t884-instance-overlay-state.test.mjs
  - tests/test_gallery_instances_api.py
related_tasks: [T-878, T-880, T-882, T-883, T-923, T-893]
arc_id: process-instances
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-26T22:43:26Z
last_update: 2026-09-29T07:34:48Z
date_finished: 2026-09-29T07:34:48Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed: []
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 1
  F3: 0
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T07:22:57Z'
cost_estimate_proposed:
  - ts: '2026-09-29T07:22:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (6-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=298,acs=13)
    rubric_sha: e4a00f38e801
---

# T-884: The designer shows where an instance is: current node, completed nodes, and the node a refusal fired on

## Context

**arc-005 S4/B10 — the half that makes S2 and S3 visible, and the arc's A4 demo.** T-880 records a position, T-923 makes the framework write it, T-882 refuses an illegitimate move, T-883 lands every refusal in `.context/audits/instance-refusals.jsonl` naming the rule. None of that can be *seen*: an operator opening `task-lifecycle` in the designer sees a template and nothing else. The arc's exit (A4) is "a recorded run showing the template marker read, an instance created against a real task id, at least one legitimate advance accepted, and at least one illegitimate advance refused with its audit-log line" — this task is the picture of that run.

**What the designer shows, per instance:** the **current node** (recorded `current_node:`), the **completed nodes** (derived, see Decision: the sequenceFlow path from the template's startEvent to the current node — the prefix `walk` took from NO-POSITION; history is not persisted, T-878), and the **node a refusal fired on** (the latest audit line for that task whose `node` is in the template, with its `rule`; the refused `target`, when present, marked too). "Must render the refusal, not only progress" — the refusal marker is the load-bearing half.

**Data path.** A `snapshot <template-id>` verb on `tools/instance-node.py` emits one JSON document — `{template, generated, state, instances:[{task, state, node, status, owner}], refusals:[…audit lines for those tasks…]}` — computed over the task corpus and the audit log, no index (T-881's reverse resolution plus T-883's reader). The project's own server (`tools/gallery-serve.py`) answers `GET /api/instances?template=<id>` by running that verb. The designer fetches it for the loaded template; if the endpoint is absent (static hosting, 404, network error) the picker says so and the map renders exactly as before — the overlay is additive and never a precondition.

**Designer surface.** A header `<select id="instancePicker">` lists the loaded template's instances (`T-885 · frw_6_run · started-work`), `?instance=T-XXX` pre-selects one (the deep-link the demo and the driver use), and the overlay is drawn in `renderNodes()` beside the T-893 marker: `data-instance="current|done|refused|refused-target"` on `g.node`, a badge `● T-XXX` on the current node, `⛔ <rule>` on the refused node. Tokens, never literals (`--accent`, `--red`, `--text-faint`). The state is computed by a pure function `instanceOverlayState(nodeIds, flows, startIds, instance, refusals)` so `tests/t884-instance-overlay-state.test.mjs` runs it without a browser (the T-893 shape). The overlay **writes nothing**: `buildBpmnXml(state)` and every node's `aef` bag are byte-identical with and without an instance selected.

**Known limits, stated.** Completed nodes are *derived*, not recorded — a loop back through `agt_2_perform` (T-883 took one) is invisible; the marker is labelled "derived" in the picker's title. Only the latest refusal per task is drawn. Inception instances (two bound templates, T-923 Evolution) are drawn on whichever template is loaded — the snapshot is per template, so an inception on a shared node id shows on both.

**Live proof:** T-885 is a real instance at `frw_6_run` with a real R-033 refusal at `frw_9_human` (T-883 leg 2). `snapshot task-lifecycle` lists it; the designer opened on task-lifecycle with `?instance=T-885` shows it. Screenshot read, pasted in Updates.

## Acceptance Criteria

### Agent
- [x] **`snapshot` emits the instance picture for a template.** `instance-node.py snapshot task-lifecycle` prints one JSON document with keys `template generated state instances refusals`; `state` is `INSTANCES` or `NO-INSTANCES` (never a bare empty list — T-878 IW-5); each instance carries `task state node status owner` with `state` in `NODE | NO-POSITION | STALE`; `refusals` carries the audit lines (T-883 shape) of those tasks; an unbound template id exits 3 with `TEMPLATE-UNKNOWN`. Control: T-882 AC 8 still holds — no lane-prefixed node id in the tool's code.
- [x] **The project server answers `/api/instances`.** `tools/gallery-serve.py` answers `GET /api/instances?template=task-lifecycle` with that JSON (`application/json`, 200); a missing/invalid `template` is 400, an unknown one 404; the handler is pinned by `tests/test_gallery_instances_api.py` against a server on a free port.
- [x] **Overlay state is pure and tested without a browser.** `instanceOverlayState(nodeIds, flows, startIds, instance, refusals)` returns `{current, done, refused}`: `done` is the shortest sequenceFlow path from a startEvent to `current`, excluding `current`, `[]` when the instance is NO-POSITION or STALE; `refused` is `{node, rule, target}` from the latest refusal whose `node` is a template node, else `null`; `tests/t884-instance-overlay-state.test.mjs` pins these including a loop case, a NO-POSITION case, a refusal whose node is not in the template, and a refusal with no target — `PASS n / FAIL 0`.
- [x] **The designer draws the four states and nothing else.** With an instance selected: exactly one `g.node[data-instance="current"]` carrying a `● T-XXX` badge, `|done|` nodes with `data-instance="done"`, the refusal node with `data-instance="refused"` and a `⛔ <rule>` badge, the target with `data-instance="refused-target"`. Control: with no instance selected there are zero `[data-instance]` attributes.
- [x] **Picker and deep link.** The header `<select id="instancePicker">` lists the loaded template's instances from `/api/instances`; `?instance=T-XXX` pre-selects it; an unknown id shows an "instance not found" option and draws nothing; when the endpoint is unavailable the picker reads "instances: unavailable" and the map renders as before (control: DOM node count unchanged).
- [x] **The overlay writes nothing.** `buildBpmnXml(state)` and `JSON.stringify(state.nodes.map(n => n.aef))` are byte-identical before and after selecting an instance, and after selecting none again.
- [x] **Driver and teeth.** `tools/_t884-instance-overlay-cdp.mjs` runs the above in an isolated headless Chromium (own user-data-dir, static server, a fixture snapshot served at `api/instances`), legs L1–L6, exit 0; `node tools/_roundtrip-serialization-cdp.mjs --denominators-only` still reports `computed sources 3 verified`; the T-880/881/882/883/923 suites stay green.
- [x] **Visual verification, read not measured.** Element-level screenshots of the current, done, refused and refused-target nodes at label sizes `s`/`m`/`l` (12) plus the picker (1) under `docs/reports/t884-shots/`, each READ back, the table in `## Visual Verification`.
- [x] **Live: the real instance, the real refusal.** `snapshot task-lifecycle` on the corpus lists `T-885` at `frw_6_run` with its `R-033 / frw_9_human` audit line; the designer opened on task-lifecycle with `?instance=T-885` (through `gallery-serve.py`) draws current=`frw_6_run`, refused=`frw_9_human` with `⛔ R-033`; screenshot read; pasted in `## Updates` (not P-011 — PL-285).
- [x] **Registered.** Fabric cards exist for the driver, the test, and the python test.

### Human
- [ ] [REVIEW] The picture answers "where is T-885 and why was it refused" without reading a task file
  **Steps:**
  1. `cd /opt/832-Workflow-designer && python3 tools/gallery-serve.py` (note the URL it prints)
  2. Open `<url>/designer.html?load=rendered/task-lifecycle.bpmn&instance=T-885` in a browser
  **Expected:** the "Run completion gate battery" node carries `● T-885`; the nodes from "Task captured" up to it are shaded as done; the "Human-owned with unchecked Human ACs?" gateway carries `⛔ R-033`; the header picker shows `T-885 · frw_6_run`
  **If not:** run `python3 tools/instance-node.py snapshot task-lifecycle` — if T-885 is not listed at `frw_6_run` the corpus moved (re-run T-883's leg 2 to recreate the refusal); if it is listed, the designer overlay is the defect: screenshot and note the console error

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Visual Verification

Element-level screenshots (scale 2) by `tools/_t884-instance-overlay-cdp.mjs` in an isolated headless Chromium on the REAL `task-lifecycle` artefact with a fixture snapshot (T-9991 on `agt_2_perform`, refusal `template-flow` fired on `frw_7_all` toward `frw_10_finalize`; T-9992 on `frw_6_run` with `R-033` fired on that same node), plus the live T-885 shots by `tools/_t884-live-proof-cdp.mjs` through `gallery-serve.py`. The designer has one theme, so the modes that can affect the marker are the three label sizes. All 17 READ back on 2026-09-29, twice: the first set showed the 8px badges struck through by incoming edge lines ("⛔ template-flow" on the gateway, "✗ refused target" on Finalize) — fixed by drawing each badge on a surface-coloured pill, then re-shot and re-read.

| state | s | m | l | what I saw (second set) |
|---|---|---|---|---|
| current | `docs/reports/t884-shots/current-s.png` | `current-m.png` | `current-l.png` | accent (yellow-green) 2px halo around "Perform the work"; pill `● T-9991` above the top-right corner, legible over the edge that crosses there; label wrapping changes with size, halo and pill do not |
| done | `done-s.png` | `done-m.png` | `done-l.png` | thin green halo around "Start work", small `✓` pill top-right; deliberately quiet — the I/O badge `1→0` and the id badge read as before |
| refused | `refused-s.png` | `refused-m.png` | `refused-l.png` | red 2px halo around the "All gates pass?" diamond; pill `⛔ template-flow` above it, no longer crossed by the incoming edge |
| refused-target | `refused-target-s.png` | `refused-target-m.png` | `refused-target-l.png` | red DASHED 1px halo around "Finalize"; pill `✗ refused target`; distinct from the solid refused halo at a glance |
| current + refused on one node | `current-and-refused-m.png` | | | two stacked pills `⛔ R-033` over `● T-9992` on "Run completion gate battery", both legible; halo stays the accent (current wins the halo, the refusal keeps its badge) |
| picker | `picker.png` | | | header `<select>` reads `T-9991 · agt_2_perform · started-work` |
| live T-885 | `live-T-885-current-m.png`, `live-T-885-refused-m.png`, `live-T-885-map.png` | | | real corpus through the real server: `● T-885` on the battery node, `⛔ R-033` on the "Human-owned with unchecked Human ACs?" gateway, picker `T-885 · frw_6_run · started-work`; the whole map (map.png) shows the done path from "Task captured" to the battery in green |

No regression seen on the nodes themselves in any size: labels, I/O badges, id badges and the T-893 authority markers (top-left) render as before; the instance pill sits top-right, clear of them.

## Verification

# T-884 — pure overlay state (no browser), the server route, the DOM legs + screenshots in an isolated Chromium.
node tests/t884-instance-overlay-state.test.mjs > /tmp/.t884a 2>&1 && grep -qE '^PASS [0-9]+ / FAIL 0$' /tmp/.t884a
python3 tests/test_gallery_instances_api.py > /tmp/.t884b 2>&1 && grep -q '^8/8 checks passed' /tmp/.t884b
timeout 240 node tools/_t884-instance-overlay-cdp.mjs > /tmp/.t884c 2>&1 && grep -q '^6/6 legs passed' /tmp/.t884c
test "$(ls docs/reports/t884-shots/*.png | wc -l)" -ge 14
# snapshot: a state, never a bare list; unknown template exits with TEMPLATE-UNKNOWN.
out=$(python3 tools/instance-node.py snapshot task-lifecycle 2>&1); echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d['state'] in ('INSTANCES','NO-INSTANCES') and isinstance(d['instances'], list) and 'refusals' in d else 1)"
out=$(python3 tools/instance-node.py snapshot no-such-template 2>&1); echo "$out" | grep -q '^TEMPLATE-UNKNOWN'
# The designer's other invariants hold.
node tools/_roundtrip-serialization-cdp.mjs --denominators-only > /tmp/.t884d 2>&1 && grep -q 'computed sources 3 verified' /tmp/.t884d
node tests/t893-authority-marker-state.test.mjs > /tmp/.t884e 2>&1 && grep -qE '^PASS [0-9]+ / FAIL 0$' /tmp/.t884e
grep -q "function instanceOverlayState(nodeIds, flows, startIds, instance, refusals)" src/aef-workflow-designer.html
grep -q 'id="instancePicker"' src/aef-workflow-designer.html
grep -qE '\.node-instance-halo \{ fill: none; stroke: var\(--accent\)' src/aef-workflow-designer.html
grep -q "route == '/api/instances'" tools/gallery-serve.py
python3 -m py_compile tools/gallery-serve.py
python3 -m py_compile tools/instance-node.py
# Earlier arc-005 suites unchanged in verdict.
out=$(bash tools/_t883-refusal-audit-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t882-advance-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t923-framework-writer-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t880-instance-node-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t881-resolution-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
# The tool still carries no node id in code (T-882 AC 8): control in the artefact first.
grep -qE 'id="(frw|agt|hum)_[0-9]+_[a-z]+"' examples/aef-processes/rendered/task-lifecycle.bpmn
out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))"); ! echo "$out" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b'
# Registered.
test -f .fabric/components/tools-_t884-instance-overlay-cdp.yaml && test -f .fabric/components/tools-_t884-live-proof-cdp.yaml && test -f .fabric/components/tests-t884-instance-overlay-state.test.yaml && test -f .fabric/components/tests-test_gallery_instances_api.yaml

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

### 2026-09-29 — a measured badge and a read one are different things; "unavailable" is not "not found"
- **What changed:** (1) The first screenshot set passed every DOM leg and was still wrong: the 8px badges sat exactly where incoming edges cross the top-right corner, and two of the four ("⛔ template-flow" on the gateway, "✗ refused target" on Finalize) were struck through by an edge line. Only reading the PNGs showed it; the counts could not. Fixed by drawing each badge on a surface-coloured pill. (2) L6 (endpoint absent) failed on first run because `?instance=T-9991` with no endpoint produced "instance not found" — a claim the corpus had been read and lacked the id, when in fact nothing had been read. `selectInstance` now refuses a selection while `available !== true`, and the picker says "unavailable". (3) The live corpus has 170 task-lifecycle instances and 2 with a position; the picker sorts positioned first so the demo does not start with 168 NO-POSITION rows.
- **Plan impact:** none to the arc; the A4 demo path is `gallery-serve.py` + `?load=rendered/task-lifecycle.bpmn&instance=T-885`. The AEF-served designer (`.agentic-framework/web/blueprints/designer.py`) has no `/api/instances`; there the picker reads "unavailable" by design — the overlay is additive. Named here, not wired: that is AEF's surface.
- **Triggered:** nothing filed. `fw fabric register` printed REFUSED ("describes itself nowhere") for three files that open with a `// T-884 —` header comment and wrote their cards anyway — the OBS-435 shape again (third task in this run to see it).

## Recommendation

**Recommendation:** GO
**Rationale:** Every Agent AC is closed by a check that re-runs: the pure state (17 cases), the server route (8 checks), six DOM legs in an isolated Chromium, 17 screenshots read twice, and the live T-885 picture through the real server. The one Human AC is the arc's A4 demo seen by a human — genuinely a review, not a grep.
**Evidence:**
- `tests/t884-instance-overlay-state.test.mjs` PASS 17 / FAIL 0; `tests/test_gallery_instances_api.py` 8/8; `tools/_t884-instance-overlay-cdp.mjs` 6/6 legs
- `tools/_t884-live-proof-cdp.mjs http://127.0.0.1:8917 T-885 frw_6_run frw_9_human R-033` → `LIVE PASS`
- `## Visual Verification` table above, 17 PNGs under `docs/reports/t884-shots/`

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
-->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-29 — completed nodes are derived, the data path is a snapshot, the overlay is view state
- **Chose:** (a) "completed nodes" = the shortest sequenceFlow path from a startEvent to the current node, computed in the designer from the loaded template — labelled DERIVED in the picker's title; (b) one `snapshot` verb on the tool, served by the project's own `gallery-serve.py` at `/api/instances?template=`, fetched by the designer with graceful absence; (c) the overlay lives in `instanceView` (view state), never in `state`, so export and autosave cannot carry it.
- **Why:** (a) T-878 decided position is one recorded field in the entity's frontmatter and no history file exists; `walk` (T-923) prints the hops it takes but persists nothing — so the only honest "completed" picture is the prefix `walk` would have taken, and saying so in the UI beats inventing a history. (b) The tool is already the one reader of corpus + audit log (T-881, T-883); a route that runs it keeps one reader, and a static server (tests, standalone) can drop a file at `api/instances` — which is exactly how the driver isolates. (c) T-892's "never re-stamps" and this task's L3 are the same invariant: a picture must not become bytes in the map.
- **Rejected:** persisting a transition history (`.context/working/workflow-instances/<task>.yaml`, the July SD-10 shape) — a second store of instance state beside the frontmatter, out of T-878's decision; deriving instance state client-side from `.tasks/` files — the browser has no corpus; a Watchtower page instead of the designer — the arc's A1 is "watches that instance advance node by node" *in the designer*.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-26T22:43:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-884-the-designer-shows-where-an-instance-is-.md
- **Context:** Initial task creation

### 2026-09-29 — live evidence for AC 9: the real instance through the real server [agent]
```
$ python3 tools/instance-node.py snapshot task-lifecycle | python3 -c "…print state, examined, positioned, refusals…"
INSTANCES 170 [{'task': 'T-884', 'state': 'NODE', 'node': 'frw_3_start', …}, {'task': 'T-885', 'state': 'NODE', 'node': 'frw_6_run', 'status': 'started-work', 'owner': 'human'}]
  refusals: [{'ts': '2026-09-29T07:14:02Z', 'task': 'T-885', 'case': 'skipped-human-gateway', 'rule': 'R-033', 'node': 'frw_9_human', …, 'actor': 'framework'}]
$ python3 tools/gallery-serve.py 8917 --docroot /tmp/t884-docroot --repo /opt/832-Workflow-designer --bind 127.0.0.1   # docroot = current src as designer.html + rendered/ symlink
$ curl -s 'http://127.0.0.1:8917/api/instances?template=task-lifecycle'   # same document as above, live
$ node tools/_t884-live-proof-cdp.mjs http://127.0.0.1:8917 T-885 frw_6_run frw_9_human R-033
  "done": ["frw_1_task","frw_2_build","frw_3_start","agt_2_perform","frw_5_outcome","agt_3_request"]
  "refused": {"node": "frw_9_human", "rule": "R-033", "target": null}
LIVE PASS  T-885: current=frw_6_run refused=frw_9_human badge="⛔ R-033" picker="T-885 · frw_6_run · started-work"
```
Screenshots `docs/reports/t884-shots/live-T-885-{current-m,refused-m,map}.png`, read (see Visual Verification).

### 2026-09-29T07:19:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7e7da2e5
- **Timestamp:** 2026-09-29T07:35:16Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#1 (Human)** — [REVIEW] The picture answers "where is T-885 and why was it refused" without reading a task file
  - **human-ac-mechanical-signal** (partial, heuristic) — `matched='shows `' in Expected: the "Run completion gate battery" node carries `● T-885`; the nodes from "Task captured" up to it are shaded as done; the "Human-owned with `

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 26
     - evidence: `out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];prin`

### 2026-09-29T07:34:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
