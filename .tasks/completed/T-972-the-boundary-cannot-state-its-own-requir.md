---
id: T-972
name: "The boundary cannot state its own requirements: no rule fires on absent laneMeta or workflowMeta, so 26 maps with no authority-of-record passed 130 saves silently"
description: >
  The boundary cannot state its own requirements: no rule fires on absent laneMeta or workflowMeta, so 26 maps with no authority-of-record passed 130 saves silently

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-01T16:51:54Z
last_update: 2026-10-01T17:23:49Z
date_finished: null
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
---

# T-972: The boundary cannot state its own requirements: no rule fires on absent laneMeta or workflowMeta, so 26 maps with no authority-of-record passed 130 saves silently

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

**Purpose correction from the operator, 2026-10-01, verbatim:** *"you making beautiful drawings
is worth shit… Your value and your brilliance is in creating the structure for that and the
mechanism and learning from that and improving and enabling other projects and other agents to
do the same."*

That changes this work. I had planned to send the Evergreen agent a bespoke instruction naming
the attributes its generator should emit. That fixes one project and transfers nothing — the
next greenfield deployment repeats it exactly. **If the mechanism has to be hand-delivered, the
mechanism is not finished.**

### What the boundary failed to say

`aef-greenfield-test` pushed **130 saves** of **26 maps** through `POST /api/save` in which:

- **all 32 lanes carry no `aef:laneMeta`** — so there is no authority-of-record anywhere, and
  per mapping-v1 §3 *no task in the entire corpus has a derivable owner*
- **no map carries `aef:workflowMeta`** — no id, no `kind`

and the validator reported **zero** findings about either. `W-LANE-NO-OWNER` only fires when
`authority == "none"` **literally**; absence is not checked at all. So a map that omits the
field entirely is quieter than one that honestly declares it unknown — the omission is rewarded.

That is the third silenceable rule found in this corpus, after `W-XML-UNREACHABLE` (skipped
entirely when a document has no start events) and `W-XML-DISCONNECTED` (silenced by giving each
fragment its own start).

### My own defect, which blocks the fix

T-970 made plain `<task>` valid without adding it to `TYPE_PERFORMER` (`{userTask, serviceTask,
scriptTask}`). Every ownership check keys on that set, so plain tasks are now **silently
unexamined** — I converted a loud rejection into a quiet blind spot. Any completeness rule added
before this is fixed will skip their corpus for the same reason.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **My T-970 defect is fixed first:** plain `task` participates in ownership checks rather
      than being skipped. Proven by a case where a plain task in a no-owner lane produces a
      finding — before this, it produced silence.
- [x] `W-XML-LANE-NO-AUTHORITY` fires on a lane with **no `aef:laneMeta` at all**, naming what
      cannot be derived. Absence must not be quieter than a declared `authority="none"`.
- [x] `W-XML-NO-WORKFLOWMETA` fires on a document with no `aef:workflowMeta`, because without
      it there is no id and no `kind` — and `kind` is what would stop an overview map being
      judged as an executable process.
- [x] **Measured against the real corpus, not a fixture:** the Evergreen maps go from 16
      findings to a number that includes one lane-authority finding per lane and one
      workflowMeta finding per map. The whole point is that their 130 silent saves would have
      spoken on the first one.
- [x] **No regression on ours:** our own 25 maps still produce 8 findings, because they carry
      both attributes. If our corpus lights up, the rules are wrong rather than the corpus.
- [x] Both rules classified in `tests/test_rule_dialect_axis.py` on the way in, derived rather
      than asserted.
- [x] WARN, not ERROR, and no conformance clause cited beyond §3's own words — the operator's
      advisory-plus-friction ruling, and the 47-of-48 lesson about asserting house convention
      as spec.

**Evidence (2026-10-01, measured HEAD vs tree on both corpora, same harness):**
- Ours, 25 maps: **8 → 8** (`W-LANE-NO-OWNER` 7, `W-XML-DISCONNECTED` 1). Unchanged.
- Evergreen, the 26 current maps (`docs/views/bpmn` + `soll-offertes-zonder-novis`):
  **22 → 26 of 26 maps speak; 46 → 138 findings** = +26 `W-XML-NO-WORKFLOWMETA` (one per map)
  +66 `W-XML-LANE-NO-AUTHORITY` (one per lane). The AC's "16" was the 13-map rendered subset,
  and so was my 32-lane estimate. Real figure recorded, not the forecast.
- Each rule has a single-rule warn fixture that fires ONLY that rule.
- Dialect axis 57 → 59. `W-XML-LANE-NO-AUTHORITY` derives **UNIVERSAL** (REQUIRES over the
  SEMANTIC_MUST lane-authority carrier). `W-XML-NO-WORKFLOWMETA` derives **DIALECT-RELATIVE**:
  the standard names workflowMeta 0 times, so a conformant document may omit it. Declared as
  the 5th unratified carrier and behaviourally probed (adding the element silences it).
- Two `valid/` goldens drew the new warnings and were COMPLETED rather than the rule softened:
  `investigate.bpmn` had dropped the workflowMeta its own YAML sibling carries.
- Form parity: both PAIRED with existing YAML ERRORs (REQUIRED_TOPLEVEL / REQUIRED_LANE_FIELDS).
  The YAML form already refused what the BPMN form, the one vendors save through, let pass.
- Also paid: `W-XML-DISCONNECTED` (T-967, mine) sat unclassified in both the parity and the
  anchorability guards since it shipped; now GAP / DOC. Anchor classes for all three rules were
  checked against 105 real documents, 0 disagreements. The anchorability guard was already red
  over four older rules and stays red; filed separately, not fixed here.
- **Where the hole actually was:** the designer's exporter writes workflowMeta unconditionally
  (src:11205) and maps absent laneMeta to authority="none" on import (src:11598). Evergreen's
  maps never passed through either: their generator posted bytes and the server stored them
  unexamined. The boundary that must speak is `/api/save`.

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

## Verification

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

python3 tests/test_rule_dialect_axis.py
python3 tools/validate-workflow.py tests/fixtures/valid/investigate.bpmn
python3 tools/validate-workflow.py tests/fixtures/valid/gw-single-default.xml
python3 -c "import json,subprocess as s;f=json.loads(s.run(['python3','tools/validate-workflow.py','--json','tests/fixtures/warn/W-XML-LANE-NO-AUTHORITY.xml'],capture_output=True,text=True).stdout)['findings'];assert [x['rule'] for x in f]==['W-XML-LANE-NO-AUTHORITY'],f"
python3 -c "import json,subprocess as s;f=json.loads(s.run(['python3','tools/validate-workflow.py','--json','tests/fixtures/warn/W-XML-NO-WORKFLOWMETA.xml'],capture_output=True,text=True).stdout)['findings'];assert [x['rule'] for x in f]==['W-XML-NO-WORKFLOWMETA'],f"
# invariant, not a count (T-3326): no map we author draws either rule, because ours carry both carriers
python3 -c "import glob,json,subprocess as s;b=[(p,x['rule']) for p in glob.glob('examples/*/rendered/*.bpmn') for x in json.loads(s.run(['python3','tools/validate-workflow.py','--json',p],capture_output=True,text=True).stdout)['findings'] if x['rule'] in ('W-XML-NO-WORKFLOWMETA','W-XML-LANE-NO-AUTHORITY')];assert glob.glob('examples/*/rendered/*.bpmn') and not b,b"

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-01T16:51:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-972-the-boundary-cannot-state-its-own-requir.md
- **Context:** Initial task creation
