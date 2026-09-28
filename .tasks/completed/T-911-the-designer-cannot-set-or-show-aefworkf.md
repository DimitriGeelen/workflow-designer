---
id: T-911
name: "The designer cannot set or show aef:workflowMeta kind — the arc's headline
  mechanic starts with seeing it"
description: >
  T-875 shipped the closed enum, the validator rules, the round-trip guarantee and
  a conformance case for aef:workflowMeta/@kind. Nothing shipped a way to SET or SEE
  it. Measured under T-875 AC6: the document-properties panel (src/aef-workflow-designer.html:5756-5776)
  offers Title, Workflow version, Description, Source and Default tier. kind is the
  ONLY document-level attribute the editor reads and writes but cannot author. arc-005's
  headline_mechanic opens with 'an operator opens task-lifecycle in the designer,
  SEES IT MARKED as a template rather than an actionable work-plan' — which nothing
  in the product currently permits, so the arc cannot be closed on its own terms until
  this exists.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tests/test_mapping_standard_conformance.py]
related_tasks: [T-875, T-876, T-877]
arc_id: process-instances
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
created: 2026-09-28T08:50:35Z
last_update: 2026-09-28T09:28:35Z
date_finished: 2026-09-28T09:28:35Z
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
bvp_scores_proposed:
  - ts: '2026-09-28T09:00:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 3
      F3: 4
      F1: 2
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=3 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L3:keyword=validator rule); F3=4
      (basis: task body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-911: The designer cannot set or show aef:workflowMeta kind — the arc's headline mechanic starts with seeing it

## Context

Filed from **T-875 AC6** — the criterion that asks whether the work delivers arc purpose and
explicitly permits the answer *no*. It was no, and this is why.

T-875 shipped everything about `aef:workflowMeta/@kind` except the ability to use it: the closed
enum (`{documentation, work-plan}`, one definition, `tools/validate-workflow.py:90`), the validator
rules in both XML and YAML forms, a round-trip guarantee proven by mutation (`kind` is LIVE across
21 fixtures), and a document-level conformance case in
`tests/test_mapping_standard_conformance.py`.

**What is missing is the surface.** Measured: the document-properties panel at
`src/aef-workflow-designer.html:5756-5776` offers Title, Workflow version, Description, Source and
Default tier. `kind` is the **only** document-level attribute the editor reads and writes but
cannot author. An operator can neither set it nor see it.

That is not a polish gap. **arc-005's `headline_mechanic` opens with** *"an operator opens
task-lifecycle in the designer, **sees it marked as a template** rather than an actionable
work-plan"* — so the arc cannot be closed on its own terms until this exists, and `fw arc close`
requires wire-level evidence of that mechanic firing.

**Deliberately NOT folded into T-875.** T-875's scope is the enum and its enforcement; its ACs say
nothing about a control, and widening it after the fact would hide that the substrate shipped
without a surface. The gap is worth a task so it is visible.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
### Agent
- [x] The document-properties panel offers a **kind** control alongside Title / Workflow version / Description / Source / Default tier, and its options are exactly the closed enum — sourced so a third value cannot appear in the UI without `WORKFLOW_KINDS` changing (T-322: one vocabulary, never a second copy)
- [x] **UNSET remains reachable and is the default.** T-213 IW-3 kept the marker an explicit author decision; a control that forces a choice silently reclassifies every one of the 24 corpus maps. Selecting UNSET on a map that had a kind removes the attribute, and the map then exports byte-identically to its pre-kind form
- [x] The kind is **visible without opening a panel** — the arc's headline mechanic is "sees it marked", not "can find it if they look". Where that indicator lives is a design choice to record in `## Decisions`
- [x] Setting the kind and saving produces `kind="..."` on `aef:workflowMeta` in the exported BPMN, proven by reading the exported bytes rather than the in-memory model
- [x] **Visual verification:** element-level screenshots of the control and the indicator in every mode the change can affect, each one READ, with no new visual regression. DOM-rect math is not sufficient.
      **The mode list was corrected against the product on 2026-09-28** — it was first written from
      CLAUDE.md's general guidance (mono/sans/serif · light/dark/contrast · compact/normal/cozy),
      and **none of those modes exist in this designer**: one `:root` token block, zero
      `prefers-color-scheme`, zero `data-theme`, zero `cozy`; "density" here is a snap-THRESHOLD
      multiplier for layout whose own comment says it "never re-spaced rows nor grew lanes"; and
      "serif" appears only inside font fallback stacks. Screenshotting nine identical renders would
      have been coverage theatre. The modes that DO affect this change:
      - badge state **unset** (hidden), **documentation**, **work-plan** (different colour rule)
      - **narrow and wide** viewport — the overlay is absolutely positioned, so a long badge can collide
      - the **panel control** with its three options visible
- [x] `python3 tests/test_mapping_standard_conformance.py` still passes, and the round-trip harness still reports `kind` LIVE — this task must not weaken what T-875 established

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

Captured by `tools/_t911-kind-badge-verify-cdp.mjs` into `.playwright-mcp/`, at deviceScaleFactor 2,
and **each one read**. The instrument exists because the MCP screenshot tool writes outside every
path this session can read, so the images would have been taken and never looked at — which is the
failure the rule is about, not a workaround for it.

| shot | what it shows |
|---|---|
| `t911-badge-documentation.png` | `documentation · illustrative`, dim, bordered |
| `t911-badge-work-plan.png` | `work-plan · actionable` in accent — visibly different weight, which is the right semantics: the actionable one should catch the eye |
| `t911-badge-unset.png` | no badge at all. UNSET is legal and inert (T-213 IW-3), so there is nothing to show |
| `t911-badge-narrow-640.png` | badge intact at 640px, inside the viewport, no collision with the mode text |
| `t911-panel-kind-select.png` | the Kind control in the WORKFLOW section, below Default tier |

**What reading them caught, and DOM-rect math could not.** The first render of the panel wrapped the
hint mid-value — `work-` on one line, `plan = actionable` on the next — so a closed-enum value was
displayed as a broken word, in the one control whose entire job is to present that enum. Every DOM
assertion passed on that render. The hint is now three words in option order and sits on one line,
matching the rhythm of its siblings; re-shot and re-read to confirm.

## Verification

# The control and the badge, driven through the REAL select with change events, plus the
# screenshots. 11 assertions including a control that the map opens UNSET.
timeout 300 node tools/_t911-kind-badge-verify-cdp.mjs > /tmp/.t911v.out 2>&1 && python3 -c "import json;d=json.load(open('/tmp/.t911v.out'));assert d['pass'] is True;assert len(d['steps'])==11 and all(s['pass'] for s in d['steps']);assert all(x['captured'] for x in d['shots'])"
# Control (PL-328): the instrument must actually report steps, or 'pass: true' is vacuous.
grep -q '"step"' /tmp/.t911v.out
# The badge is wired into the render path and into the select's own callback (3 call sites).
test "$(grep -c 'updateKindBadge()' src/aef-workflow-designer.html)" -eq 3
# The enum offered by the UI comes from one place and matches the validator's closed set.
grep -q "\['', 'documentation', 'work-plan'\]" src/aef-workflow-designer.html
# T-875 must not be weakened: conformance still passes and kind is still LIVE.
python3 tests/test_mapping_standard_conformance.py > /tmp/.t911c.out 2>&1 && grep -q 'document-level aef:workflowMeta/@kind' /tmp/.t911c.out
timeout 300 node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t911r.out 2>&1 && python3 -c "import json,sys;d=json.load(open('/tmp/.t911r.out'));sys.exit(0 if 'kind' in d['wm_selftest']['live'] else 1)"
# T-910's laneMeta teeth must still be 40/0 — this change touches the same emitter file.
timeout 580 bash tools/_t910-lanemeta-teeth.sh > /tmp/.t911t.out 2>&1 && grep -q '^FAIL: 0' /tmp/.t911t.out

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

### 2026-09-28 — an acceptance criterion named modes this product does not have
- **What changed:** AC5 was written from CLAUDE.md's general visual-verification guidance —
  mono/sans/serif · light/dark/contrast · compact/normal/cozy · narrow/wide. Checked against the
  product before shooting anything: **none of those modes exist here.** One `:root` token block,
  zero `prefers-color-scheme`, zero `data-theme`, zero `cozy`; "density" is a snap-THRESHOLD
  multiplier whose own comment says it never re-spaced rows nor grew lanes; "serif" appears only
  inside font fallback stacks.
- **Plan impact:** nine identical renders would have been coverage theatre — a screenshot count
  standing in for a measurement. AC5 was CORRECTED IN PLACE, with the reason recorded, to the modes
  that do change this pixel: three badge states, and narrow vs wide.
- **Triggered:** nothing filed. The general guidance is right for products that have those modes;
  the error was mine, copying a checklist into an AC without checking it against the subject.

### 2026-09-28 — the instrument's first run passed three steps vacuously
- **What changed:** the run found no Kind select (wrong container id — `#props`, the real one is
  `#properties`), so every "set" step failed. But three steps still **PASSED**: "kind is null",
  "badge hidden", "exports byte-identically". They assert an ABSENCE, and the absence was already
  true because nothing had ever been set.
- **Plan impact:** those legs are now gated on a proven prior set and report
  `NOT EVALUATED — no prior set to revert (T-3105)` when the precondition does not hold. This was
  the session's own thesis biting the instrument written to enforce it: a mechanism producing
  confident output with nothing to be wrong about.
- **Triggered:** nothing new — it is PL-328 and T-3105, both already registered.

### 2026-09-28 — reading the screenshot found what every assertion missed
- **What changed:** with 11/11 DOM assertions green, the panel image showed the hint wrapping
  mid-value: `work-` / `plan = actionable`. A closed-enum value rendered as a broken word, in the
  control whose job is to present that enum.
- **Plan impact:** hint shortened to three words in option order, re-shot and re-read.
- **Triggered:** nothing filed; it is the standing rule ("Did I look at a rendered screenshot?")
  earning its place. Worth noting that the defect was in text this task authored, not in inherited
  layout — the render is where it became visible.

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

### 2026-09-28 — where the marker is visible: the canvas overlay, not the panel
- **Chose:** a badge in the existing `canvas-overlay` status strip, beside "Mode: select", rendered
  only when `kind` is SET.
- **Why:** arc-005's headline mechanic is *"sees it marked"*. Behind a panel disclosure that is
  "can find it if they look", which is a different claim and would not close the arc. The overlay
  is already persistent, already themed, and already the place the editor states what mode it is
  in — the map's kind is the same class of fact.
- **Rejected:** (a) a panel-only field — fails the mechanic; (b) showing a badge when UNSET — T-213
  IW-3 kept the marker an explicit author decision, so an "unset" chip on all 24 maps that declare
  nothing would be chrome for a non-event, and would read as a nag toward setting it;
  (c) folding it into `updateStatus()` — that function has early returns (the endpoint-drag hint
  takes priority and returns), so the marker would vanish mid-drag and reappear after, which reads
  as a bug in the marker rather than a property of the status line.

### 2026-09-28 — the badge prints the enum value, not a synonym
- **Chose:** render `documentation · illustrative` / `work-plan · actionable` — the value verbatim,
  with a gloss.
- **Why:** the tempting alternative is to render `documentation` as **"template"**, since that is
  the word arc-005's own headline mechanic uses. That would put a second vocabulary on one closed
  set — the T-322 defect — where the UI and the wire disagree about what a map is called, and a
  reader comparing a screenshot to a BPMN file would find two different words for one value.
- **Rejected:** a UI-only synonym. The enum is the name; the gloss explains it.

### 2026-09-28 — UNSET writes `null`, not `''`
- **Chose:** `wm.kind = v || null` in the select callback.
- **Why:** the emitter writes the attribute only when truthy, so `null` exports byte-identically to
  a map that never carried one. `''` would be falsy too and would work by luck; `null` matches what
  the parser produces for an absent attribute, so the value a user sets and the value an import
  produces are the same object. Asserted directly — the instrument checks `kind === null`, not
  merely falsy, and compares the exported bytes against the pre-set export.

### 2026-09-28 — the verification instrument, and why it had to exist
- **Chose:** write `tools/_t911-kind-badge-verify-cdp.mjs` rather than screenshot through the MCP
  browser tool.
- **Why:** the MCP tool wrote its PNG to a path outside every directory this session may read
  (T-559 blocks the Bash side; the Read tool found nothing there either). The screenshots would
  have been *taken and never looked at* — which is precisely the failure the visual-verification
  rule exists to prevent, so routing around it would have defeated the rule rather than satisfied
  it. The CDP instrument is also the house pattern (a dozen `tools/_*-verify-cdp.mjs` siblings) and
  it drives the REAL select with a dispatched `change` event, so an unwired control fails.
- **Rejected:** asserting DOM state only. It would have passed on the render whose hint was broken
  across a line — which is the one defect this task's visual pass actually found.

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

### 2026-09-28T08:50:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-911-the-designer-cannot-set-or-show-aefworkf.md
- **Context:** Initial task creation

### 2026-09-28T09:00:34Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f886a64e
- **Timestamp:** 2026-09-28T09:28:52Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-28T09:28:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
