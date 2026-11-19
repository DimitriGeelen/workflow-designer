---
id: T-1447
name: "Show imported text annotations (and their associations) on the canvas — Greenfield's
  workshop maps"
description: >
  Greenfield T-436 (sidecar msg dc28399b, 2026-11-19): a real Camunda workshop map
  (4 lanes, 23 nodes, 12 textAnnotations, 10 associations) imports cleanly into 0.38.0,
  but the annotations are 'kept but not shown' (T-1326/T-1327), and for workshop maps
  the notes ARE the content. Build: draw textAnnotation boxes at their DI position
  with their text and the association lines to their nodes, read-only first (editing
  later); keep the byte-identical save-back. Also noted in the same report: original
  pool/lane outlines are not kept (T-1264 known), and a server-side /api/save makes
  no thumbnail. Scope added by Greenfield (msg ef63bb29): associations BETWEEN TASKS
  (associationDirection=One, a dotted status sync, e.g. Opportunity/Solution -> Product,
  Open Order -> Sales Order) are not drawn either, which leaves the target tasks looking
  unconnected; draw those too, not only annotation associations. Routing findings
  on the same map are T-1449. TEST MAP (Greenfield owner consented 2026-11-19, no
  personal names, company name may stay): sidecar msg 4f533a0a, between '-----BEGIN
  BPMN-----' and '-----END BPMN-----', exactly 22903 bytes, sha256 c9afe963aad9f4b93ea3ca3cb8bc21e3423de38c606d4b793229a54581f71a0c
  (verified 2026-11-19). SAVED 2026-11-19 to tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn
  (22903 bytes, sha256 matches; 12 textAnnotations, 10 associations, 4 lanes).

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: []
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tools/_t1327-comments-and-notice-cdp.mjs]
related_tasks: [T-1326, T-1327]
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
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-11-19T13:05:22Z
last_update: 2026-11-19T20:07:26Z
date_finished: 2026-11-19T20:07:26Z
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
  - ts: '2026-11-19T14:50:19Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 2
      F3: 0
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=2 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=2 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L2:keyword=import)'
    rubric_sha: e4a00f38e801
---

# T-1447: Show imported text annotations (and their associations) on the canvas — Greenfield's workshop maps

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** Greenfield T-436 (msg dc28399b, 2026-11-19): their Camunda workshop map imports cleanly, but
its 12 text annotations and 10 associations are "kept but not shown" (T-1326/T-1327). For workshop maps the notes are
the content. Msg ef63bb29 adds: task-to-task associations (associationDirection=One, a dotted status sync) are not
drawn either, so target tasks look unconnected. Test map: `tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn`.

**Problem / hypothesis:** the importer keeps annotations and associations as raw XML with their DI in
`state.procKept.artifacts` (`captureProcessLevelKept`), with association ends mapped to node uids; nothing draws them.
Drawing them read-only from that record touches no save path, so byte-identical save-back holds by construction.

**Goal:** a person opening a workshop map sees its notes where the author put them, connected to their steps, and
sees which tasks are linked to which.

**Expected outcome:** annotations draw as BPMN text-annotation boxes (open bracket, text wrapped inside) at their DI
bounds; associations draw as dotted lines (an arrowhead when associationDirection is One or Both); save is unchanged.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] On the Greenfield fixture all 12 annotations draw at their DI bounds with their full text, and all 10 associations
      draw as dotted lines between the right ends (annotation-to-node and node-to-node); a one-way association has an
      arrowhead at its target. Measured in a CDP harness against the file's own DI and ids. (`_t1447-notes-cdp.mjs` N1, N2)
- [x] An association whose end node the person moves follows the node (its line is redrawn to the node's new place);
      an unmoved one keeps the file's waypoints. (N3)
- [x] The drawing is read-only: annotations and associations are not selectable, draggable or deletable, and draw
      under nodes and flows (never covering a step's name). (N4; layer pointer-events none, below g-edges and g-nodes)
- [x] Save writes the same bytes as before this task for the fixture and for every corpus/third-party golden
      (byte-identity goldens unchanged); the import notice stops saying "not shown yet" for what is now drawn.
      (N5 against 0.44.0 with the import-minted uuid masked; goldens green in the browser tier; N6; _t1327 leg3 updated)
- [x] SVG/PNG/PDF export include the annotations and associations (paper palette). (N7 on the SVG; the PNG is drawn
      from that SVG and the PDF sheet clones the same canvas; `greenfield-export.png` shows them)
- [x] The harness is wired as a browser leg; with the drawing removed it fails (bites). (`test_t1447_notes`;
      `T1447_EDITOR=dist/aef-workflow-designer-0.44.0.html … --expect-red`: N1 N2 N3 N6 N7 red)
- [x] `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green (pool and here). (2026-11-19 on 258abb19:
      person-sees exit 0; browser tier HERE 147/0. The POOL gave no result: the job failed before any test,
      "File size limit exceeded" joining the repo bundle on the worker — a pool-input defect, not a test result, so the
      gate's rule applied (no pool result: the local run decides, and it says so). Bundle defect: own task.)

### Human
- [x] The workshop map's notes and links read well and look like BPMN text annotations, at three widths.
  **Judged by:** the independent reviewer on the images (`fw reviewer judge T-1447 --criterion 1`), who may escalate.
  **Steps:**
  1. `docs/reports/T-1447-shots/{1024,1440,1920}-greenfield.png`: the opening view (fit) at each width.
  2. `docs/reports/T-1447-shots/1024-notes-*.png` and `1440-notes-*.png`: the whole map at 100% in tiles, side panels
     hidden, notices dismissed; `1920-closeup.png`. Every note readable, beside the step it belongs to, its dotted line
     reaching that step; dotted task-to-task links visible with their arrowheads.
  3. `docs/reports/T-1447-shots/greenfield-export.png`: the same on paper.
  Round 1 (amber, V on 2026-11-19) asked for: readable close-ups at 1024/1440; note 7 visibly reaching Open Order; note
  8's line visible and its bracket clear of `tac_6_order`; note 5's line clear of the flow label "wel". All four are
  addressed (re-attach to a clear side when a line's end touches another step; notes are obstacles for id captions and
  flow labels).
  Round 2 (amber, V-20261119-8ed2891f) confirmed those four and asked: the "Restored your unsaved work" notice off the
  1440 tiles (each width now starts with fresh browser storage), and the bottom row of notes clear of the "Mode" chip
  at full scroll (zoomed views now scroll 48px past the lowest content; the fit view is unchanged).
  Round 3 (amber, V-20261119-59397bd0) confirmed all of that and asked: (1) note 2's line visibly reaching Knop "Tacton"
  past the id caption sal_2_knop — fixed: a note line's end that runs through a caption in its last 30px slides along
  the step's edge clear of it (fitNoteEnds, after the captions are placed); (3) tiles overlapping by more than the
  pinned lane-name column — now 200px across, 120px down. (2) sal_6_opportunity over the "(task)" tag is NOT a note
  matter: the same caption placement predates T-1447 (identical in the pre-T-1447 export) and is Greenfield's own
  finding (8); it is routed to T-1449 (caption-over-type-tag), not widened into this task. Note: the caption positions
  are the same at every width in the fit view (measured 1024 vs 1920); the 1024 tiles differ because zooming re-renders.
  Round 4 (amber, V-20261119-60f6cafe) found note 2 still unchanged at 1440/1920/paper: the two places beside the caption
  both still crossed it (the line arrives at a slant), so nothing moved. Fixed: every place along the edge, 4px apart,
  nearest first; greenfield-export.png and 1920-closeup.png re-shot and changed (sha256 75966ec8… -> a8f19ae5…).
  **Expected:** the notes read as the map's content, nothing covers a step's name or a flow label it should not.
  **If not:** name the file and the note; the agent fixes and re-shoots.
  **Reviewer verdict:** green V-20261119-8d4410ec — reviewer-judge-t-1447-r3-573595b7a785:reviewer (rung rung-3-termlink-single-reviewer), digest 407b664f4003; dispatch judge-t-1447-r3-573595b7a785; evidence: .context/reviews/evidence/T-1447/AC1-judge-t-1447-r3-573595b7a785.md, .context/reviews/evidence/T-1447/1024-greenfield-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-01-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-02-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-03-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-04-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-05-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-06-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-07-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1024-notes-08-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-greenfield-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-01-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-02-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-03-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-04-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-05-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1440-notes-06-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1920-closeup-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/1920-greenfield-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/export-crop-notes-1-2-3-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/export-crop-notes-4-5-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/export-crop-notes-7-8-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/greenfield-export-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/zoom-1024-02-notes-5-6-7-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/zoom-1024-03-note7-end-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/zoom-1440-01-note2-end-judge-t-1447-r3-573595b7a785.png, .context/reviews/evidence/T-1447/zoom-1440-02-note7-end-judge-t-1447-r3-573595b7a785.png; ledger .context/reviews/verdicts.jsonl

### Human (template guidance)
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
#     bin/fw vendor self --check --task T-XXXX
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
-->
node --check tools/_t1447-notes-cdp.mjs
grep -q 'test_t1447_notes' tests/run-bridge-tests.sh
test "$(sha256sum tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn | cut -c1-64)" = c9afe963aad9f4b93ea3ca3cb8bc21e3423de38c606d4b793229a54581f71a0c
grep -q 'function renderNotes' src/aef-workflow-designer.html && grep -q 'function fitNoteEnds' src/aef-workflow-designer.html
python3 tools/_t821-swallowed-failure-census.py > /tmp/t1447-census.out 2>&1 && grep -q 'FINDINGS *0' /tmp/t1447-census.out

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

### 2026-11-19T13:05:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1447-show-imported-text-annotations-and-their.md
- **Context:** Initial task creation

### 2026-11-19T14:50:18Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-11-19T20:07:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6e99114d
- **Timestamp:** 2026-11-19T20:07:32Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#7 (Agent)** — `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green (pool and here). (2026-11-19 on 258abb19:
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/person-sees-gate.sh in: `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green (pool and here). (2026-11-19 on 258abb19:`
