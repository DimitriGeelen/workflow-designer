---
id: T-1369
name: "B1 (T-1363 GO): draw documents — BPMN data objects with their state and associations
  on the canvas, save unchanged"
description: >
  Data objects (dataObjectReference + dataState + data input/output associations)
  from another tool's file are kept on save but not drawn. Draw them, with their state,
  linked to the steps that make and use them. Display only.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-1363, T-1361, T-1096]
origin: {kind: "operator"}
# write_set:                      # T-3512: optional — globs (relative to PROJECT_ROOT)
#                                 # naming the files this task intends to write. Declared
#                                 # at CAPTURE, unlike components: which the framework
#                                 # resolves from git history at close. Feeds TWO things:
#                                 #   1. `fw write-set check T-A T-B` — without it the
#                                 #      comparison has nothing to compare and every real
#                                 #      pair exits 2 (undecidable). 0 of 3032 tasks
#                                 #      declared it, so that gate has never had an input.
#                                 #   2. BVP blast_radius before close — the 0.6-weighted
#                                 #      cost term, unavailable for 85% of rankable tasks
#                                 #      because components: only exists once the task is
#                                 #      finished (T-3471).
#                                 # Example: write_set: ["lib/bvp.sh", "tests/unit/t*_bvp*"]
#                                 # An EMPTY list is a real declaration ("writes nothing"),
#                                 # which is not the same as omitting the field. Omitted
#                                 # means unknown, and unknown must never score as cheap.
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-1369` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-11-02T13:27:46Z
last_update: '2026-11-02T13:29:09Z'
date_finished:
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
  - ts: '2026-11-02T13:29:09Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L2:keyword=canvas)'
    rubric_sha: e4a00f38e801
---

# T-1369: B1 (T-1363 GO): draw documents — BPMN data objects with their state and associations on the canvas, save unchanged

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** Operator decided T-1363 GO on 2026-11-02 (job 118), for 832's part. This is build **B1**,
need 1 in the T-1363 report: documents as first-class items with their state. In greenfield's WT-01 the signed order
confirmation is the binding moment of the sale, and the quote PDF explicitly is not. The map models each as a
`bpmn:dataObjectReference` with a `bpmn:dataState` ("sent", "signed", "firm"), linked to the steps that make and use
it by `dataInputAssociation` / `dataOutputAssociation`. wt01-io-v12 carries 5 such references.

**Problem / hypothesis:** The designer keeps data objects and their associations on save (T-1096) but does not draw
them (measured by greenfield on 0.31.0, still true in 0.36.0). A person reading the map cannot see which document a
step produces or needs, nor in which state. That is the trigger point the operator named ("a state creates a state
change, it's a trigger point").

**Goal:** Draw each data object reference on the canvas as BPMN draws it: a page with a folded corner, its name, its
state in brackets, and a dotted association to each step that produces or uses it. Display only.

**Expected outcome:** WT-01's "Orderbevestiging [sent]" and "[signed]" appear under the steps that make them and are
linked to the steps that use them. A map without data objects looks and saves exactly as before.

**Operator's choice (2026-11-02, option 1: "let the lane grow"):** found while building, all 5 of WT-01's documents
lie outside every lane in the file's own DI, so "draw at the file's position" read as broken. Three options were put:
1. the lane grows to hold its documents;
2. small badges on the task;
3. draw where the file says.
The operator chose 1: each document under its producing task, inside its lane, which grows. So a map WITH documents
saves with taller lanes, and the lanes below move down with their nodes. No ids and no content change. The criteria
below are revised to match.

**Conditions from the GO:** tested on a synthetic map that is not WT-01. Client data stays out of the repo.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
<!-- Revised 2026-11-02 for the operator's option 1 (see Context): placement by one rule, the lane grows. -->
- [x] On a synthetic fixture (`tests/fixtures/t1369/documents.bpmn`, made up, not WT-01: one quote in two states, three
  tasks, four associations), each reference is drawn as a BPMN data-object shape with its name and `[state]`. It sits
  centred under its producing task (the stated rule, in the code comment), with a dotted association line and an open
  arrowhead per direction (output: task → document; input: document → task).
- [x] The anchor task's lane grows to hold its documents and their labels (130 → 186 on the fixture), the lanes below
  move down with their nodes, and a reopened save is identical (nothing grows twice). Checked on WT-01 too (not
  committed: client data): all 5 documents inside their lanes.
- [x] The save keeps every data element and association (T-1096 round trip, `_t1222`, `_t1264`, `_t1119`,
  `_roundtrip-serialization`, `_t1350` all green). Data objects are not editable in this task.
- [x] A map without data objects draws nothing in the data layer and its lanes do not change.
- [x] `tools/_t1369-documents-cdp.mjs` asserts the above (leg 224, browser tier) and is red on the 0.36.0 source.
- [x] `bash tools/person-sees-gate.sh` exits 0, and screenshots at 1024/1440/1920 are read in `## Visual Verification`.

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
         1. Run `bin/fw reviewer T-1369`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1369 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

<!--
  Render-touching build tasks (web/templates, web/static, web/blueprints, web/shared.py,
  web/app.py …) add a section headed "Visual Verification" (level-2 heading) after
  Verification, with one checklist table — the check-visual-verification gate reads it
  at commit time (T-4213; T-4202 GO):

    | state | control | 1024 | 1440 | 1920 | note |
    |-------|---------|------|------|------|------|
    | toolbar | Load | ok | ok | ok | |

  Cells: ok / clipped / hidden / overlap / unreachable (non-ok needs a note). Each
  listed state needs screenshots at every UX_SHOT_WIDTHS width:
  fw ux shots <T-ID> <state>=<URL>. This comment is inert: the gate ignores it.
-->
- [ ] [REVIEW] A person reading the map can see which document each step makes or needs, and in which state
  **Steps:**
  1. Compare `docs/reports/T-1369-evidence/docs-1920-zoom-before.png` (0.36.0: documents kept but not drawn) with
     `docs-1920-zoom.png` (this change).
  2. Look at `docs/reports/T-1369-evidence/docs-{1024,1440,1920}.png` and `docs-{1024,1440}-zoom.png`.
  **Expected:**
  - Under "Send the quote" stands a page with a folded corner labelled "Quote" and "[sent]"; under "Customer signs",
    "Quote" "[signed]".
  - A dotted line with an open arrowhead runs from each task to the document it produces, and from each document to the
    task that uses it.
  - Both documents sit inside the Sales lane, which is taller than in the before shot. Nothing overlaps a task or
    another label, apart from the short line from a task to its document crossing that task's id caption, which stays
    readable.
  - The toolbar and both side panels are complete at all three widths.
  **If not:** name the screenshot and what is wrong (unreadable, misleading direction, overlap, clipped).
  For the independent reviewer: `fw reviewer judge T-1369 --criterion 1`

## Verification

<!-- T-4906: guidance is an HTML comment so GitHub does not render its `#` lines as
     headings; the completion gate strips HTML comments before running anything.
     Write your commands BELOW this comment, one per line.
# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
# Build/refactor/decommission tasks with NO command here are refused. If nothing can be
# run, add the line `# verification: none — <why nothing can be run>`; it is serviced
# (queued for review: add a check / other evidence / accept). See docs/reports/T-4024-servicing-loop.md.
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
# THE EXCEPTION — capture first, grep the capture with a HERE-STRING:
#     out=$(cmd 2>&1); grep -q "PATTERN" <<<"$out"
# No pipe, so no SIGPIPE at any size. Do NOT write `echo "$out" | grep -q PAT`:
# it is not safe "below 64 KB" as this file used to say (T-4921, 832 T-1340). The
# builtin writes a multi-line value line by line, so grep -q can exit before the
# last write at ANY size (measured 4 in 3,000 for a 40-line value), and above the
# pipe buffer it fails every time (T-2743: 146,366-byte page, 3/3). In a gate that
# allows on "no match" that is a fail-OPEN (T-4920: the Tier 0 pre-filter).
# The capture still discards cmd's exit code, so a 404 yields an empty capture that
# grep merely fails to match rather than a failed line — prefer THE DEFAULT above.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); grep -q passed <<<"$out" && ! grep -q failed <<<"$out"
#     out=$(bats <file> 2>&1); grep -q '^ok 1 ' <<<"$out" && ! grep -q '^not ok' <<<"$out"
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
#
# Vendored-path hint (T-3236, T-4419): if you edited bin/fw, lib/, agents/, policy/,
# web/, tools/ or .tasks/templates/, run `bin/fw vendor self` and add
#     bin/fw vendor self --check --task T-1369X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
-->
grep -q "^function growLanesForDocuments(s)" src/aef-workflow-designer.html
grep -q 'leg browser "_t1369-documents" _leg_224' tests/run-bridge-tests.sh
test -f tests/fixtures/t1369/documents.bpmn
export PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH"; node tools/_t1369-documents-cdp.mjs >/dev/null
export PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH"; node tools/_t1096-data-objects-roundtrip-cdp.mjs >/dev/null
test -f docs/reports/T-1369-evidence/docs-1920-zoom.png && test -f docs/reports/T-1369-evidence/docs-1920-zoom-before.png

## Visual Verification

Screenshots by `node tools/_t1369-shots.mjs` (with `T1369_BEFORE` = the 0.36.0 source) of the made-up fixture
`tests/fixtures/t1369/documents.bpmn`, in `docs/reports/T-1369-evidence/`. Each one was read.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| canvas, opening | "Quote [sent]" under "Send the quote", "Quote [signed]" under "Customer signs" | ok | ok | ok | docs-{W}-zoom.png |
| canvas, opening | dotted associations with open arrowheads: task → document, document → next task | ok | ok | ok | |
| canvas, opening | the Sales lane grown to hold both documents and their labels | ok | ok | ok | compare docs-1920-zoom-before.png |
| canvas, opening | the line from a task down to its document crosses the task's id caption | ok | ok | ok | the caption paints on top and stays readable; noted, not changed |
| window | toolbar, both side panels | ok | ok | ok | docs-{W}.png |

What was read:
- **docs-1920-zoom-before.png (0.36.0):** three tasks in a 130 px lane, no documents.
- **docs-1920-zoom.png:**
  - two document shapes with folded corners, centred under their producing tasks, each labelled "Quote" with
    "[sent]" / "[signed]" in the muted mono style;
  - the outputs as short dotted lines down from the task, the inputs as diagonal dotted lines up to the next task's
    lower left, arrowheads open and pointing at the receiver;
  - the lane grown to 186 px with the labels inside.
- **WT-01** (not committed: client data): geometry checked by script. All 5 references sit inside their anchor's lane:
  Klant/dealer 216, Verkoper 194 and Tacton CPQ 206, from 130.

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

### 2026-11-02 — where documents stand (operator's choice, option 1)
- **Chose:** one placement rule: under the producing task (else the first task that uses it), inside its lane, side by
  side when several. The lane grows at import to hold them, and the lanes below move down with their nodes, keeping
  their layout.
- **Why:**
  - All 5 of greenfield's WT-01 documents lie outside every lane in its own DI, so the file's positions could not be
    trusted to read as "this step's document".
  - The rule reads the same on every map.
  - Growing at import (not on every render) makes a reopened save identical.
- **Rejected (put to the operator):**
  - Badges on the task: not standard BPMN, and a shared document would show twice.
  - Drawing at the file's position: WT-01's documents would float above and between lanes.
- **Consequence:** a map with documents saves with taller lanes. No id and no content changes. To be named in the
  release notes for AEF.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1369 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-11-02T13:27:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1369-b1-t-1363-go-draw-documents--bpmn-data-o.md
- **Context:** Initial task creation

### 2026-11-02T13:29:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
