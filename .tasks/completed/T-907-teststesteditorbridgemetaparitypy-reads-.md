---
id: T-907
name: "tests/test_editor_bridge_meta_parity.py reads COMMENTS as keys: an apostrophe
  in prose inside the metaKeys literal becomes a parity break"
description: >
  Same defect class as T-904, different instrument. The editor-bridge parity checker
  extracts the editor's metaKeys by regexing the array literal in src/aef-workflow-designer.html
  for quoted strings, WITHOUT stripping comments. The metaKeys literal legitimately
  contains comments between its elements (T-177 and T-889 both annotate their additions
  inline). Consequence measured live during T-904: a comment added inside the literal
  containing two ordinary English apostrophes (guard-apostrophe-s ... T-904-apostrophe-s)
  had the two apostrophes pair as a quoted string, and the checker reported the intervening
  SENTENCE as an editor key the bridge drops - 'aef:meta PARITY BREAK - editor writes
  these keys into aef:meta but the bridge META_KEYS drops them: - s denominator regexed
  comments as code, so this sentence would have masked the ...'. The suite reported
  it as [FAIL] 'bridge META_KEYS drops a scalar key the editor writes to aef:meta',
  which is an accurate symptom pointing at an innocent subject: the editor drops nothing
  and the bridge lacks nothing. The failure was introduced by a COMMENT, and the remedy
  the tool suggests ('Fix: add the key(s) to META_KEYS in tools/yaml-to-bpmn.py')
  would have written a sentence fragment into the bridge's key list. T-904 worked
  around it by moving its comment outside the literal and left a comment saying why
  - that is mitigation, not prevention: the next author annotating a key inline will
  hit it again, and the suggested fix is actively wrong. Deliverable: strip comments
  from the literal region before extracting keys (T-904 added a reusable quote-aware
  stripJsComments to tools/_roundtrip-serialization-cdp.mjs; this checker is Python
  so it needs its own or a shared one), and add a leg that plants an apostrophe-bearing
  comment inside the literal and requires the checker to stay GREEN. Note the family:
  PL-060 (T-302, strip HTML comments before grepping task files), T-578 (bridge-suite
  leg 'No tool is reachable only through a JavaScript comment'), T-904 (round-trip
  denominator), and now this. Four instruments, one class - worth asking whether a
  shared helper or a lint should exist rather than a fourth bespoke fix.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface, false-green]
components: [src/aef-workflow-designer.html, tools/_roundtrip-serialization-cdp.mjs, tools/_t904-denominator-comment-blindness-teeth.sh]
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
created: 2026-09-27T15:04:06Z
last_update: 2026-09-28T23:14:54Z
date_finished: 2026-09-28T23:14:54Z
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
  F4: 0
  F3: 4
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T23:12:58Z'
cost_estimate_proposed:
  - ts: '2026-09-28T23:14:33Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (2-components); tier=2 (workflow:build); effort=8 
      (lines=267,acs=8)
    rubric_sha: e4a00f38e801
---

# T-907: tests/test_editor_bridge_meta_parity.py reads COMMENTS as keys: an apostrophe in prose inside the metaKeys literal becomes a parity break

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `editor_meta_keys()` in `tests/test_editor_bridge_meta_parity.py` strips `//` line comments and `/* */` block comments from the literal region BEFORE extracting quoted strings, and the strip is quote-aware: a `//` inside a real string literal does not start a comment, and an apostrophe inside a comment cannot open a string
- [x] **The defect is reproduced before it is fixed, as a control that must go RED on the pre-fix extractor:** plant a comment with two ordinary apostrophes inside a copy of the live literal and show the unfixed function returns the intervening sentence as a key. That reproduction is the mutation leg's kill case, not a one-off
- [x] Self-test pins BOTH directions: a comment containing a quoted word (`// 'emits' would go here`) yields no key, AND the real keys on either side of an apostrophe-bearing comment are extracted exactly (same list, same order) as from the comment-free literal
- [x] **The live literal agrees with a JavaScript engine's reading of it:** a leg extracts the `metaKeys` literal text from `src/aef-workflow-designer.html`, evaluates it with `node`, and requires the Python extractor's list to be identical — so the extractor is checked against the parser that actually runs the code, not against its own regex
- [x] A teeth script with `--mutation` (disabling the comment strip) reports the planted-comment case RED and the controls GREEN, and prints `MUTATION SETUP BROKEN` rather than scoring kills if a control dies under the mutant
- [x] The parity checker still exits 0 on the live editor and bridge after the change (no key was lost by the strip), stated as a leg with its own control (the key count is greater than zero)

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

# The checker itself, whose self-test now carries the T-907 cases in both directions.
python3 tests/test_editor_bridge_meta_parity.py
# Teeth: controls (engine agreement, // inside a string) then the comment cases; --mutation restores the pre-fix extractor.
out=$(bash tools/_t907-parity-comment-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t907-parity-comment-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# The strip is wired at the call site (anchor the teeth depend on), and it is quote-aware by construction.
grep -q 'RE_EDITOR_METAKEYS.search(_strip_js_comments(text))' tests/test_editor_bridge_meta_parity.py
grep -q '^def _strip_js_comments' tests/test_editor_bridge_meta_parity.py
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

**Symptom:** A comment added inside the editor's `metaKeys` literal containing two ordinary English apostrophes made `tests/test_editor_bridge_meta_parity.py` report the sentence between them as a key the bridge drops, with a printed remedy that would have written that sentence into the bridge's `META_KEYS`.
**Root cause:** `editor_meta_keys()` ran the quoted-string regex over the RAW literal. The bridge side had a `#`-comment strip; the editor side had none, so JavaScript comments were read as code.
**Why structurally allowed:** The checker's self-test covered only the bridge's comment case. Nothing compared the Python extraction with a JavaScript engine's reading of the same literal, so a regex that disagreed with the language it was parsing had no referee. T-904 had already found and fixed the identical class in the round-trip guard and, unable to fix it here, wrote around it by moving prose out of the array — mitigation that left the mechanism intact for the next author.
**Prevention:** (1) quote-aware `_strip_js_comments` at the call site; (2) the self-test now asserts both directions in-file, so the checker refuses to run green on its own pre-fix extractor; (3) `tools/_t907-parity-comment-teeth.sh` pins the planted-comment case and, in `--mutation`, proves the pre-fix extractor is caught; (4) an engine-agreement control: the Python list must equal `node`'s evaluation of the live literal, which is the check the other three instruments in this class (PL-060, T-578, T-904) do not have.

## Evolution

### 2026-09-29 — the mutant corrected a classification, again
- **What changed:** The defect was latent, not live: T-904 had moved its prose out of the literal, so the checker passed on the tree as found. The pre-fix reproduction (a planted comment with two apostrophes → a 22nd "key" reading `s addition, after T-904`) is now the mutation kill case rather than a story in a task description. The strip is a character walk with quote state, not a regex, because the two failure directions are opposite: a `//` inside a real string must survive, an apostrophe inside a comment must not open a string.
- **Plan impact:** `checker_green_with_keys` was filed as a control and died under the mutant — because the checker's own self-test now asserts the comment cases, so the whole checker goes red when the strip is removed. Reclassified as a gate case with the reason in the script; the in-file self-test is the first line of defence and the teeth the second. Fourth instrument in this project with the same comment-as-code class (PL-060, T-578, T-904, this) — the description's question about a shared helper or lint is left open, not answered here.
- **Triggered:** Nothing filed. The engine-agreement control (python list == node's evaluation of the same literal) is the check the other three instruments in the class do not have; worth carrying to them if the class is ever consolidated.

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

### 2026-09-27T15:04:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-907-teststesteditorbridgemetaparitypy-reads-.md
- **Context:** Initial task creation

### 2026-09-28T23:11:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3eacefdf
- **Timestamp:** 2026-09-28T23:14:57Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#4 (Agent)** — **The live literal agrees with a JavaScript engine's reading of it:** a leg extracts the `metaKeys` literal text from `src/aef-workflow-designer.html`, evaluates it with `node`, and requires the Pytho
  - **AC-verify-mismatch** (narrow, heuristic) — `path=src/aef-workflow-designer.html in: **The live literal agrees with a JavaScript engine's reading of it:** a leg extracts the `metaKeys` literal text from `src/aef-workflow-designer.html``

### 2026-09-28T23:14:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
