---
id: T-1446
name: "PDF export: wide maps print too small on one A4 page (A3 / fit-to-width across
  pages)"
description: >
  T-1440 reviewer note (green, non-blocking, 2026-11-19): arc-lifecycle (2100 px wide)
  printed on one A4 landscape page puts box text at about 4.5 pt — crisp on screen,
  small on paper. Options: offer A3, or tile a wide map across pages at a readable
  minimum text size. Measure text size in the PDF as the test.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: []
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh]
related_tasks: [T-1440]
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
created: 2026-11-19T11:26:47Z
last_update: 2026-11-20T17:34:39Z
date_finished: 2026-11-20T17:34:39Z
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
  - ts: '2026-11-20T09:18:40Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 0
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=2 (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body
      — no hypothesis, so this score has no claim to be wrong about,L1:keyword=lane);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=2 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L2:keyword=import)'
    rubric_sha: e4a00f38e801
---

# T-1446: PDF export: wide maps print too small on one A4 page (A3 / fit-to-width across pages)

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** T-1440's reviewer (green, non-blocking, V-20261119-0a064daf): Export → PDF puts the whole map
on one A4 landscape page, so arc-lifecycle (2100 px wide) prints its box text at about 4.5 pt: crisp on screen,
too small on paper. The operator wants PDF "to hand to people" (T-1093).

**Problem / hypothesis:** one page, fitted to width, scales text down with the map's width: box text is 11 px, A4
landscape holds 277 mm, so any map wider than ~1200 px prints below 8 pt. A bigger sheet (A3) helps up to ~1700 px;
beyond that only more pages keep the text readable.

**Goal:** Export offers, besides today's one A4 page, one A3 page, and A4 pages at a readable size: the map cut into
pages so box text stays at 8 pt or more, cut between steps (never through a step box), each page saying which
part it is.

**Expected outcome:** a wide map prints readably on ordinary A4 paper; a small map still gives one page; the one-page
A4 export is unchanged.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Export has "PDF, one page A4" (today's, unchanged), "PDF, one page A3" and "PDF, A4 pages (readable)";
      each prints the map alone (no editor controls in the PDF's text), on the stated paper size (pdfinfo).
      Evidence: `_t1446` M1/A1/B1 on 4 maps: 842x595 pt (A4) and 1191x842 pt (A3), one page each, editor words none.
      A3 is set by a temporary @page rule (76c0b90e5): the first version's named page printed TWO A3 pages on the
      pool's Chromium (pool RED, here green); green on both since.
- [x] On arc-lifecycle and audit-process, the readable A4 pages print step names at 8 pt or more and A3 at a larger
      size than one A4 page, measured from the PDF's word boxes (pdftotext -bbox), not from the code.
      Evidence: P1 smallest step name 8.4 / 8.1 pt (A4 one page 4.1 / 5.0 pt, A3 6.0 / 7.2 pt); probed on all 24
      corpus maps: every one >= 8.0 pt. The scale follows the smallest box text DRAWN (the lane-fit ladder shrinks long
      names; a fixed 11 px first gave 6.4 pt).
- [x] The readable pages together hold every step name, every step box prints whole on at least one page (checked in
      the page geometry the export computes), and each page's heading names its part ("page 2 of 3"); a map that
      fits at 8 pt on one page gives exactly one page.
      **Amended 2026-11-20:** first written as "no step box is cut by a page edge". On cross-host-dispatch the wide
      gateway labels and the events under them overlap into one unbroken run from x 116 to 1074, wider than a
      readable page, so no straight cut avoids every box. Where no gap leaves 60% of a page, a part ends at the
      page edge and the next part starts where the first cut step begins (overlap): the step prints whole there.
      Also learned: no corpus map fits one readable page (the pool keeps an authored minimum width), so the pages end
      40 px after the last step, and the one-page case is a 3-step map made through Import -> CSV.
      Evidence: P2 on arc-lifecycle (3 pages), audit-process (4), cross-host-dispatch (2; the overlap case), the 3-step
      map (1 page, 16 pt): every name on some page, 0 boxes not whole on any page, headings "page k of N (row, column)";
      P3 both cases covered.
- [x] A CDP harness covers the three exports on three corpus maps and a small one, is a browser-tier leg, and fails
      on the 0.44.0 designer; T-1440's PDF leg still passes.
      Evidence: `tools/_t1446-pdf-pages-cdp.mjs` (17 legs), leg `test_t1446_pdf_pages`; on 0.44.0 13 legs fail (the A4
      ones pass, as they must); `_t1440` D1/D2 still pass.
- [x] `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green.
      Evidence: person-sees exit 0 (2026-11-20 on 44d7d11a0, and on 5b6dad258, the designer unchanged since); browser tier for 30a2041d7 green on the
      pool as two shards (pool-w1 78/0, pool-w2 73/0) and here 151/0 (build/tiergate/tier-browser.runs.log 14:53Z).

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
- [x] [REVIEW] The PDF pages are a readable paper version of a wide map, and the Export menu with three PDF entries fits.
  **Why you:** whether a page reads well on paper, and whether the parts are easy to follow, is a judgement on images.
  **Judged by:** the independent reviewer on the images (`fw reviewer judge T-1446 --criterion 1`), who may escalate.
  **Steps:**
  1. `docs/reports/T-1446-shots/{1024,1440,1920}-export-open.png`: Export lists 11 entries, the three PDF ones
     ("PDF, one page A4", "PDF, one page A3", "PDF, readable pages A4") readable and told apart; the menu inside the
     window and on top.
  2. `docs/reports/T-1446-shots/pdf/arc-lifecycle-{a4-1,a3-1,pages-1,pages-2,pages-3}.png` and
     `cross-host-dispatch-{a4-1,a3-1,pages-1,pages-2}.png`: on the readable pages the step names are clearly larger
     than on the one A4 page; each page's heading says which part it is; a step cut at a page's edge is whole on the
     next page; the lane names are on the first column of pages.
  **Expected:** the readable pages could be handed to a person and followed; the menu reads cleanly.
  **If not:** name the file and what is wrong; the agent fixes and re-shoots.
  **Reviewer verdict:** green V-20261120-242ee8c5 — reviewer-judge-t-1446-r1-20c8ae1f9c8b:reviewer (rung rung-1-same-vendor-independent), digest 323ed65c6910; dispatch judge-t-1446-r1-20c8ae1f9c8b; evidence: .context/reviews/evidence/T-1446/AC1-judge-t-1446-r1-20c8ae1f9c8b.md, .context/reviews/evidence/T-1446/1024-export-open-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/1440-export-open-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/1920-export-open-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/arc-lifecycle-a3-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/arc-lifecycle-a4-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/arc-lifecycle-pages-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/arc-lifecycle-pages-2-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/arc-lifecycle-pages-3-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/cross-host-dispatch-a3-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/cross-host-dispatch-a4-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/cross-host-dispatch-pages-1-judge-t-1446-r1-20c8ae1f9c8b.png, .context/reviews/evidence/T-1446/cross-host-dispatch-pages-2-judge-t-1446-r1-20c8ae1f9c8b.png; ledger .context/reviews/verdicts.jsonl

## Verification

node tools/_t1446-pdf-pages-cdp.mjs
grep -q "test_t1446_pdf_pages" tests/run-bridge-tests.sh

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

## Visual Verification

Shots: `docs/reports/T-1446-shots/` (`shots.mjs`; fresh storage per shot, cleared after leaving the previous page;
the PDFs' pages rendered at 50 dpi under `pdf/`; measurements in `measure.json`).

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| Export menu open | 11 entries incl. PDF one page A4 / A3, readable pages A4 | ok | ok | ok | every item inside the window and on top (measured) |
| PDF readable pages | headings, parts, step names | ok | ok | ok | paper output, independent of window width; arc-lifecycle 3 pages, cross-host-dispatch 2 |

Read by the agent: the three PDF entries are told apart by label (one page / readable pages) and hint (A4 / A3);
on the readable pages the step names are clearly larger than on the one-page A4 (8-10 pt measured against 4-5 pt),
each heading says "page k of N (row, column)", the lane names print on the first column, arrowheads render on every
page (each page repeats the SVG; its markers resolve). cross-host-dispatch page 1 shows the start of "ERROR (exit 1)"
at its right edge: that step prints whole on page 2 (the overlap rule).

## Decisions

### 2026-11-20 — Readable pages: one common scale, cuts between steps, overlap where none fits
- **Chose:** three PDF entries (one page A4 as before, one page A3, readable A4 pages); the readable pages share one
  scale set by the smallest box text actually drawn (>= 8 pt), end between steps where a gap leaves 60% of a page,
  and otherwise overlap so a cut step prints whole on the next page; pages stop 40 px after the last step.
- **Why:** one scale keeps the parts the same size to fit together; measured on all 24 corpus maps, every step name
  printed at 8 pt or more; overlapping labels leave some maps without any clean gap (cross-host-dispatch).
- **Rejected:** choosing the paper automatically (a person knows their printer; three explicit entries are clearer);
  a fixed 11 px text size (the lane-fit ladder shrinks long names, which then printed at 6.4 pt); strict "never cut
  a step" (impossible on cross-host-dispatch at 8 pt).

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

### 2026-11-19T11:26:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1446-pdf-export-wide-maps-print-too-small-on-.md
- **Context:** Initial task creation

### 2026-11-20T09:18:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-11-20T09:18:57Z — status-update [task-update-agent]
- **Change:** horizon: now → now

### 2026-11-20T17:34:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0e44abb4
- **Timestamp:** 2026-11-20T17:35:03Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#5 (Agent)** — `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green.
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/person-sees-gate.sh in: `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green.`
