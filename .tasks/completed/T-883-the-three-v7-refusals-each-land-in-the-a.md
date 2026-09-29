---
id: T-883
name: "The three V7 refusals each land in the audit log"
description: >
  arc-005 S3/B9. CONTINGENT on T-879 GO. V7 verbatim from the July package: an out-of-order
  advance, a skipped human gateway, and an unmet input contract are EACH refused and
  EACH land in the audit log. Three legs, three controls — a refusal nobody can see
  afterwards is the same class of defect as no refusal.

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: [arc:process-instances]
components:
  - tools/instance-node.py
  - .agentic-framework/lib/instance-position.sh
  - .agentic-framework/agents/task-create/update-task.sh
  - tools/_t883-refusal-audit-teeth.sh
related_tasks: [T-879, T-882, T-923, T-884]
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
created: 2026-09-26T22:43:22Z
last_update: 2026-09-29T07:17:04Z
date_finished: 2026-09-29T07:17:04Z
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
  F3: 3
  F1: 3
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T07:08:19Z'
cost_estimate_proposed:
  - ts: '2026-09-29T07:08:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (4-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=330,acs=12)
    rubric_sha: e4a00f38e801
---

# T-883: The three V7 refusals each land in the audit log

## Context

**arc-005 S3/B9, origin V7 (July package) and project goal G4.** T-882 refuses an illegitimate hop; T-923 made the framework the writer of position and left `refuse()` as "the single emission path for every refusal, so the audit-log landing (T-883) has one hook". A refusal that only reaches the terminal of whoever tried it is invisible afterwards — the arc's exit criterion (A4) asks for "at least one illegitimate advance refused **with its audit-log line**", and T-879's hypothesis asks for each of the three V7 cases to leave "a line in the audit log that names which rule refused it".

**The audit log.** `.context/audits/instance-refusals.jsonl` — the framework's own convention for append-only audit records is `.context/audits/*.jsonl` (`arc-abandon.jsonl`, `arc-bypass.jsonl`, `arc-scoped-*.jsonl`), so the refusals go beside them, not into a new home. One line per refusal, JSON, keys `ts task case rule kind node target template detail actor`. One writer: `tools/instance-node.py`. The framework's gates reach it through a `refused` verb so no second serialiser exists in bash.

**The three V7 cases, mapped onto the rules that already refuse them (Decision below):**

| V7 case (`case`) | rule that refuses (`rule`) | template node | where it fires |
|---|---|---|---|
| `out-of-order-advance` | `template-flow` (T-882 guard: no sequenceFlow for the hop) | the current node → the target | `instance-node.py advance` / `walk`, and every framework walk (T-923) |
| `skipped-human-gateway` | `R-033` (sovereignty gate: agent completing a human-owned task) | `frw_9_human` "Human-owned with unchecked Human ACs?" | `update-task.sh check_human_sovereignty` |
| `unmet-input-contract` | `P-010` (unchecked ACs) / `P-011` (verification failed) | `frw_7_all` "All gates pass?" | `update-task.sh check_acceptance_criteria` / `run_verification_commands` |

**Shape.**
- `instance-node.py`: `refuse()` grows structured fields and appends the line (`_audit_append`, the single writer, behind a `MUTATION-ANCHOR refusal-audit`); a new verb `refused <T-XXX> --case C --rule R --node N [--target T] [--detail D] [--actor A]` lets the framework record a refusal the tool did not itself make; a new verb `refusals [T-XXX]` reads the log back as `REFUSAL <ts> <task> <case> <rule> <node>[ -> <target>]` or `NO-REFUSALS`, never a bare empty list (T-878 IW-5). `--log FILE` / `FW_INSTANCE_REFUSAL_LOG` override the file (teeth use `mktemp`).
- `lib/instance-position.sh`: `fw_instance_refused <task> <case> <rule> <node> [detail]` — never fails the caller, silent when the tool or artefact is absent, `actor=framework`.
- `update-task.sh`: the R-033, P-010 and P-011 refusal branches call it before `exit 1`. The `--skip-*` bypass branches do NOT — a bypass is not a refusal and is already logged in `.gate-bypass-log.yaml`.
- A write failure (log dir missing/unwritable) never changes the refusal: exit code and stdout line stand, a `WARNING:` on stderr says the audit line was not written.

**Known limits, stated.** G-020 (`frw_2_build`, placeholder ACs) is also an input contract but fires in the PreToolUse hook (`check-active-task.sh`), not in a transition; it is not wired here and is named as a follow-up in Evolution. Refusals other than these three (sovereignty on inceptions, RCA, evolution, disposition gates) are not V7 cases and are left as they are.

**Live proof is on real tasks:** one line per case — leg 1 on this task (`advance T-883 frw_10_finalize` from `frw_3_start`), leg 2 on T-885 (human-owned, agent attempts the close: refused by R-033 — the attempt is the V7 event and changes nothing but the record), leg 3 on this task (`work-completed` attempted with ACs unchecked: refused by P-010). `refusals` then names all three rules.

## Acceptance Criteria

### Agent
- [x] **One writer, one log.** Every refusal `refuse()` emits appends exactly one line to the log; the line parses as JSON with keys `ts task case rule kind node target template detail actor`; the stdout refusal line and the exit code are unchanged (T-880/T-881/T-882/T-923 suites stay green, T-882 mutation still OK).
- [x] **Leg 1 — out-of-order advance is refused and audited.** A fixture on `frw_3_start` advanced to `frw_10_finalize` exits 1, the record still reads `frw_3_start`, and one line is appended with `case=out-of-order-advance`, `rule=template-flow`, `node=frw_3_start`, `target=frw_10_finalize`, `template` naming `task-lifecycle.bpmn`. **Control:** the same fixture advanced to `agt_2_perform` (legal) exits 0 and appends nothing.
- [x] **Leg 2 — skipped human gateway is audited by the framework.** `fw_instance_refused T skipped-human-gateway R-033 frw_9_human "…"` returns 0 and appends one line with those four values and `actor=framework`; `update-task.sh`'s R-033 refusal branch calls it (pinned: the call sits between the `Sovereignty gate (R-033)` message and its `exit 1`) and the `--skip-sovereignty` branch does not. **Control:** `fw_instance_refused` with an empty case appends nothing and returns 0.
- [x] **Leg 3 — unmet input contract is audited by the framework.** The P-010 and P-011 refusal branches call `fw_instance_refused "$TASK_ID" unmet-input-contract P-010|P-011 frw_7_all …` before their `exit 1` (pinned by grep); the `--skip-acceptance-criteria` / `--skip-verification` branches do not.
- [x] **Every line names its rule, and the log reads back as states.** `refusals` prints one `REFUSAL <ts> <task> <case> <rule> <node>[ -> <target>]` per line (filtered by task when given) and `NO-REFUSALS` (with the task id when given) when there are none; a line whose `rule` is empty cannot be written (the writer refuses it with `WARNING:` and writes nothing).
- [x] **Never fails, never hides.** With the log path pointing into a directory that does not exist and cannot be created (a file in the way), `advance` still exits 1 with its `REFUSED-TRANSITION` stdout line and prints `WARNING: audit line not written` on stderr; `fw_instance_refused` returns 0 in that case too; with the tool absent it prints nothing and returns 0.
- [x] **Log location and override.** Default is `<root>/.context/audits/instance-refusals.jsonl`; `--log FILE` and `FW_INSTANCE_REFUSAL_LOG` override it (flag wins); the teeth never touch the real log (they run with a `mktemp` file and assert the real log's line count is unchanged across the run).
- [x] **No node id enters the tool's code.** T-882 AC 8's control still passes: the lane-prefixed id pattern hits in the artefact and nowhere in the tool's non-docstring code — the `refused`/`refusals` verbs carry node ids as arguments only.
- [x] **Teeth + mutation.** `tools/_t883-refusal-audit-teeth.sh` pins all of the above on `mktemp` fixtures: `PASS n / FAIL 0`; `--mutation` disables the writer at `MUTATION-ANCHOR refusal-audit` and every "line appended" case goes red while every control stays green (`MUTATION OK`).
- [x] **Live: three lines, three rules, on real tasks.** (1) `advance T-883 frw_10_finalize` refused → `out-of-order-advance / template-flow`; (2) `fw task update T-885 --status work-completed` refused → `skipped-human-gateway / R-033`; (3) `fw task update T-883 --status work-completed` with ACs unchecked refused → `unmet-input-contract / P-010`; `refusals` lists all three; outputs pasted in `## Updates`, the three lines in the commit. **Control:** this task's own eventual close appends no line (visible in the commit, not in P-011 — PL-285).

### Human
_None._ Every criterion is a deterministic shell check; the human-visible half is T-884 (the designer renders the node a refusal fired on).

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

## Verification

# T-883 teeth: three legs, three controls, writer, reader, never-fail, mutation — all on mktemp fixtures and a mktemp log (T-3326).
out=$(bash tools/_t883-refusal-audit-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t883-refusal-audit-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# Earlier suites unchanged in verdict.
out=$(bash tools/_t882-advance-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t882-advance-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
out=$(bash tools/_t923-framework-writer-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t880-instance-node-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t881-resolution-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
# Wiring pins: three refusal sites call the audit, parses.
test "$(grep -c 'fw_instance_refused "\$TASK_ID"' .agentic-framework/agents/task-create/update-task.sh)" -ge 3
grep -q 'fw_instance_refused "\$TASK_ID" skipped-human-gateway R-033 frw_9_human' .agentic-framework/agents/task-create/update-task.sh
grep -q 'fw_instance_refused "\$TASK_ID" unmet-input-contract P-010 frw_7_all' .agentic-framework/agents/task-create/update-task.sh
grep -q 'fw_instance_refused "\$TASK_ID" unmet-input-contract P-011 frw_7_all' .agentic-framework/agents/task-create/update-task.sh
bash -n .agentic-framework/agents/task-create/update-task.sh
bash -n .agentic-framework/lib/instance-position.sh
python3 -m py_compile tools/instance-node.py
# The tool still carries no node id in code (T-882 AC 8): control in the artefact first.
grep -qE 'id="(frw|agt|hum)_[0-9]+_[a-z]+"' examples/aef-processes/rendered/task-lifecycle.bpmn
out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))"); ! echo "$out" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b'
# The log's home follows the framework's audit convention and every live line parses and names a rule.
test -f .context/audits/instance-refusals.jsonl && python3 -c "import json,sys; rows=[json.loads(l) for l in open('.context/audits/instance-refusals.jsonl') if l.strip()]; sys.exit(0 if rows and all(r.get('rule') and r.get('case') and r.get('task') for r in rows) else 1)"

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

### 2026-09-29 — once every refusal is audited, every test suite that refuses is a forger
- **What changed:** The first full run wrote 18 lines into the live `.context/audits/instance-refusals.jsonl` — all fixture ids (T-99xx). Not from this task's teeth (they use a `mktemp` log and assert the real log untouched) but from the T-880/T-881/T-882/T-923 suites, which drive `set`/`advance`/`walk` refusals on fixtures and, since `refuse()` now appends, forged live audit lines on every run. Second finding of the same shape: the T-883 mutation run missed the lib leg because `fw_instance_refused` resolves the tool from `$root`, not from the mutant — the mutant was never on the path the lib takes. Third, cosmetic: the P-010 detail string doubled its label (`agent AC acceptance criteria`).
- **Plan impact:** each earlier suite now exports `FW_INSTANCE_REFUSAL_LOG` into its own `mktemp` dir (one line each), the T-883 teeth run all four suites in both modes and assert the real log's line count is unchanged (`earlier_suites_do_not_write_real_log`), and the lib is pointed at the mutant via `FW_INSTANCE_TOOL` in the mutation run. The forged lines were removed from the live log by hand (fixture ids only; the three real lines kept) — recorded here because an audit log edited by hand is exactly the thing this task exists to make unnecessary.
- **Triggered:** Nothing new filed. Worth a line for T-884: `refusals` is the read surface, and the `node`/`target` fields are what the designer should highlight. G-020 (`frw_2_build`) as a fourth audited input contract stays a follow-up (hook-side, not a transition).

## Recommendation

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

### 2026-09-29 — where the audit log lives and what "the three V7 cases" are in this corpus
- **Chose:** `.context/audits/instance-refusals.jsonl`, one JSON line per refusal, written only by `tools/instance-node.py` (the framework's gates reach it through a `refused` verb); the three V7 cases mapped onto rules that already refuse — `template-flow` (T-882) for out-of-order, `R-033` at `frw_9_human` for the skipped human gateway, `P-010`/`P-011` at `frw_7_all` for the unmet input contract.
- **Why:** the framework already keeps append-only audit records under `.context/audits/*.jsonl` (arc-abandon, arc-bypass, arc-scoped-*), so a refusal log beside them is discoverable by the same habit; one serialiser means one shape to read (T-884 will read it). The rule names are the ones the gates already print, so the line "names which rule refused it" (T-879) without inventing a vocabulary. `frw_9_human` is the only human gateway the template has; `frw_7_all` is the node the P-010 hint already names (T-880).
- **Rejected:** (a) a separate per-instance history file (`.context/working/workflow-instances/<task>.yaml`, the July SD-10 shape) — T-878 decided position lives in the entity's own frontmatter and no instance file exists; a refusal log is an audit stream, not instance state; (b) writing the line from bash in `update-task.sh` — a second serialiser, and the tool would no longer be the one writer; (c) G-020 as the "unmet input contract" — it is one, but it fires in a PreToolUse hook, not in a transition, so it is named as a follow-up rather than half-wired.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-26T22:43:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-883-the-three-v7-refusals-each-land-in-the-a.md
- **Context:** Initial task creation

### 2026-09-29T07:04:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-09-29 — live evidence for AC 10: three refusals, three rules, on real tasks [agent]
Leg 1 — out-of-order advance (this task, on `frw_3_start`):
```
$ python3 tools/instance-node.py advance T-883 frw_10_finalize
REFUSED-TRANSITION T-883: frw_3_start -> frw_10_finalize is not a sequenceFlow of examples/aef-processes/rendered/task-lifecycle.bpmn; legal successor(s) of frw_3_start in examples/aef-processes/rendered/task-lifecycle.bpmn: agt_2_perform
rc=1   get T-883 → NODE frw_3_start task-lifecycle (unchanged)
```
Leg 2 — skipped human gateway (T-885 is `owner: human`; the agent attempts the close):
```
$ fw task update T-885 --status work-completed
  position: ... HOP agt_3_request -> frw_6_run   (walked 7 hop(s) from NO-POSITION — the battery started)
ERROR: Cannot complete human-owned task
Sovereignty gate (R-033): owner is human.
  audit: REFUSAL-RECORDED T-885 skipped-human-gateway R-033 frw_9_human
rc=1
```
Leg 3 — unmet input contract (this task, ACs unchecked at the time):
```
$ fw task update T-883 --status work-completed
ERROR: Cannot complete — 10/10 agent AC unchecked: ...
Map: task-lifecycle node frw_7_all (All gates pass?) refuses this — ...
  audit: REFUSAL-RECORDED T-883 unmet-input-contract P-010 frw_7_all
  position: HOP frw_6_run -> frw_7_all / HOP frw_7_all -> agt_2_perform
rc=1
```
Read back:
```
$ python3 tools/instance-node.py refusals
REFUSAL 2026-09-29T07:14:02Z T-883 out-of-order-advance template-flow frw_3_start -> frw_10_finalize
REFUSAL 2026-09-29T07:14:02Z T-885 skipped-human-gateway R-033 frw_9_human
REFUSAL 2026-09-29T07:14:04Z T-883 unmet-input-contract P-010 frw_7_all
```
Side effect stated: T-885's record now carries `current_node: frw_6_run` (the framework wrote it when the battery started, per T-923); its status and owner are unchanged. Control for AC 10 is this task's own close: the log must still have three lines afterwards (see the commit).

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3ecd9b7d
- **Timestamp:** 2026-09-29T07:17:33Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 20
     - evidence: `out=$(python3 -c "import ast,sys;t=ast.parse(open('tools/instance-node.py').read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];prin`

### 2026-09-29T07:17:04Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
