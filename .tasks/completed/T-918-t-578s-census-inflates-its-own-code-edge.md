---
id: T-918
observation: OBS-306
name: "T-578's census inflates its own code-edge bucket the way AEF's baseline did,
  and I published the number before checking. tools/_t578-js-comment-edge-census.py
  strips JS comments before deciding a JS reference is a code edge, but for .sh and
  .py it does a bare substring match with NO comment stripping at all (lines 194-202,
  the trailing else) - even though the instrument it audits, _t451, DOES strip both
  via tokenize/ast and a word-aware hash. Consequence, direction certain and size
  UNMEASURED: a tool referenced only inside a Python docstring or a shell comment
  is counted as having an EXECUTABLE-CODE edge. So 127 with-a-code-edge is inflated
  and 110 prose-only is a floor for a second reason I had not named - I called it
  a floor only for the JS regex-vs-division ambiguity. Same shape as AEF's own correction
  at rail 315 ('we built the baseline with the same shape of shortcut the bug is made
  of: a pattern that looks like it measures the relationship and actually measures
  a spelling'), and they asked me directly to check mine before trusting it. Checked,
  from source, not from memory. Not fixed under T-578: the ACs are closed and the
  fix changes what the number means, which is the ordering PD-253 just argued for.
  Needs its own task and a re-measurement using _t451's existing strippers rather
  than a second hand-written one."
description: >
  Promoted from observation OBS-306

status: work-completed
workflow_type: build
owner: agent
horizon: null
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
created: 2026-09-28T13:27:46Z
last_update: 2026-09-28T22:39:41Z
date_finished: 2026-09-28T22:39:41Z
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
  - ts: '2026-09-28T22:29:35Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-918: T-578's census inflates its own code-edge bucket the way AEF's baseline did, and I published the number before checking. tools/_t578-js-comment-edge-census.py strips JS comments before deciding a JS reference is a code edge, but for .sh and .py it does a bare substring match with NO comment stripping at all (lines 194-202, the trailing else) - even though the instrument it audits, _t451, DOES strip both via tokenize/ast and a word-aware hash. Consequence, direction certain and size UNMEASURED: a tool referenced only inside a Python docstring or a shell comment is counted as having an EXECUTABLE-CODE edge. So 127 with-a-code-edge is inflated and 110 prose-only is a floor for a second reason I had not named - I called it a floor only for the JS regex-vs-division ambiguity. Same shape as AEF's own correction at rail 315 ('we built the baseline with the same shape of shortcut the bug is made of: a pattern that looks like it measures the relationship and actually measures a spelling'), and they asked me directly to check mine before trusting it. Checked, from source, not from memory. Not fixed under T-578: the ACs are closed and the fix changes what the number means, which is the ordering PD-253 just argued for. Needs its own task and a re-measurement using _t451's existing strippers rather than a second hand-written one.

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**The defect, confirmed at `tools/_t578-js-comment-edge-census.py:192-203`:** `stripped` is computed
`if is_js` only. The trailing `else:` — which covers `.sh`, `.py`, `.yaml`, `.bats`, `.toml` — does
a bare `"tools/" + name in t` substring match with **no comment stripping at all**. So a tool
referenced only inside a Python docstring or a shell comment is counted as having an
**EXECUTABLE-CODE edge**. Direction certain, size unmeasured: `have at least one EXECUTABLE-CODE
edge` is inflated and `PROSE-ONLY — the real number` is a floor.

**And the fix already exists in this tree.** `tools/_t451-unwired-guard-census.py` has
`strip_prose(path, text)` — a documented dispatcher that strips Python comments via `tokenize` and
bare string statements via `ast`, shell via `_strip_hash`, and C-style via `_strip_cstyle`, blanking
with spaces so offsets compose. Writing a second stripper here is the T-322 defect.

**One stale premise found while reading:** `_t578`'s own comments assert *"_t451 does not strip
JS"* (`:234`, `:246`). `_t451` dispatches `js/mjs/cjs` to `_strip_cstyle`. That claim has expired
and it is part of `_t578`'s stated reason for existing.

- [x] The non-JS branch **strips prose before deciding code-vs-prose**, using `_t451`'s existing `strip_prose` rather than a second implementation — and the import is by file path, since the module name is not a legal identifier
- [x] **`_t451` importing cleanly is verified, not assumed.** If importing it executes a census, that is a side effect this tool must not inherit; establish it before depending on it
- [x] **The before/after numbers are both reported.** "Inflated" is a direction; this task turns it into a magnitude. The count that moves is the evidence, and a fix that moves nothing means the defect was not where it was thought to be
- [x] A **parse failure is not silently treated as "no references"** — `_t451` returns `None` on unparseable Python for exactly that reason, and the caller must not collapse it into an empty result
- [x] **The stale `_t451 does not strip JS` claims are corrected**, not left contradicting the tree
- [x] Proved by **fixture, not by the corpus number alone**: a `.py` file whose only reference is in a docstring, and a `.sh` file whose only reference is in a `#` comment, must both be classified PROSE-ONLY — and a genuine call in each must still be classified CODE. Without the second half this is a fix that could be achieved by returning nothing

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

# The census still runs and reports its two counts.
python3 tools/_t578-js-comment-edge-census.py > /tmp/.t918.out 2>&1; grep -q 'PROSE-ONLY' /tmp/.t918.out
# The stripper LOADED. Without this the counts are the pre-fix numbers wearing the post-fix label,
# which is the exact failure the tool's own subject is about.
grep -q 'PROSE STRIPPING UNAVAILABLE' /tmp/.t918.out && exit 1 || true
# CONTROL for that negation (PL-328): the same string must be findable where it IS emitted.
grep -q 'PROSE STRIPPING UNAVAILABLE' tools/_t578-js-comment-edge-census.py
# No file fell back to the unstripped path in the live corpus.
grep -q 'could not be stripped' /tmp/.t918.out && exit 1 || true
grep -q 'could not be stripped' tools/_t578-js-comment-edge-census.py
# The fix is the SHARED stripper, not a second copy (T-322).
grep -q 'STRIP_PROSE = _load_strip_prose()' tools/_t578-js-comment-edge-census.py
grep -q "getattr(mod, \"strip_prose\", None)" tools/_t578-js-comment-edge-census.py
# _t451 really does export it — the dependency is checked, not assumed.
grep -q '^def strip_prose' tools/_t451-unwired-guard-census.py
# Fixture teeth: two trees, differential, 6 assertions including the load-bearing CALL tree.
timeout 300 bash tools/_t918-prose-edge-teeth.sh > /tmp/.t918t.out 2>&1 && grep -q '^FAIL: 0' /tmp/.t918t.out
grep -qE '^PASS: [1-9]' /tmp/.t918t.out
grep -q 'never a real call' /tmp/.t918t.out
# The stale claim is RETRACTED. Asserted POSITIVELY, on the corrected sentence the tool now
# prints. The first version of this leg greped for the absence of 'does not strip JS' and
# failed at the gate — because the retraction QUOTES the phrase it retracts. A grep cannot
# tell an assertion from a quotation of one, which is the same shape as every other
# 'mention is not invocation' finding in this corpus.
grep -q '_t451 strips JS since T-495 but' tools/_t578-js-comment-edge-census.py
grep -q 'T-918 CORRECTION' tools/_t578-js-comment-edge-census.py

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

### 2026-09-29 — the magnitude, which the observation could only call "inflated"
- **What changed:** OBS-306 established the direction and said the size was UNMEASURED. Measured:
  **code-edge 175 → 144, prose-only 219 → 250.** Thirty-one of 175 claimed executable-code edges —
  **18%** — were comments or docstrings.
- **Plan impact:** none; this is what the task was for. Worth stating as a number because
  "inflated" is not actionable and "31 tools are wired by a sentence" is.

### 2026-09-29 — the fix was an import, not an implementation
- **What changed:** `_t451` already had `strip_prose()` — Python via `tokenize`+`ast`, shell via a
  quote-aware `#` stripper, C-style for JS, blanking with spaces so offsets compose. Writing a
  second stripper in `_t578` would have been the T-322 defect, and it would have been the copy that
  drifts, because `_t578` is not where anyone looks for stripping semantics.
- **Plan impact:** import by path (the module name is not a legal identifier), with import-safety
  established first rather than assumed — `_t451` guards its entry point and its only top-level
  expression is its docstring.
- **Triggered:** nothing; but the unavailable-stripper path **announces** that its numbers are
  pre-fix rather than silently producing them, because a count produced without the stripper is
  the old count wearing the new label.

### 2026-09-29 — my teeth were wrong twice, in opposite directions
- **What changed:** first version asserted on **tool names**; the census reports **counts**. Second
  version asserted a delta of exactly 2 and measured 3 — because `_t578`'s own new comment names
  `_t451` in prose, so `_t451` itself moves when stripping is on.
- **Plan impact:** rewritten as a **difference of deltas** across two trees (prose fixtures vs call
  fixtures), which cancels the shared census-copy noise exactly. The CALL tree is the load-bearing
  half: a stripper that ate everything passes the prose tree and fails that one.
- **Triggered:** nothing. Both errors were caught by the suite failing, which is the suite working.

### 2026-09-29 — a third stale claim, left for its own task
- **What changed:** `_t451:519` **prints** *".mjs/.js are read whole too — JavaScript comments were
  never stripped"*, while `:271-286` dispatches JS to its C-style stripper and `:356` calls it.
  That is not a comment — it is the LIMIT paragraph, output to whoever runs the census, and it
  overstates its own blindness.
- **Plan impact:** the two copies of that claim inside `_t578` are corrected here. `_t451:519` is
  **not** touched: changing a census's printed output can move a committed baseline or a ratchet.
- **Triggered:** **OBS-431**.

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

### 2026-09-28T13:27:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-918-t-578s-census-inflates-its-own-code-edge.md
- **Context:** Initial task creation

### 2026-09-28T22:29:35Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-85469a6d
- **Timestamp:** 2026-09-28T22:40:07Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-28T22:39:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
