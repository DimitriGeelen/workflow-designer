---
id: T-845
name: "Census control recogniser under-credits: test -x unrecognised, 3-char pattern floor silently refuses valid controls, and no reason is reported"
description: >
  Census control recogniser under-credits: test -x unrecognised, 3-char pattern floor silently refuses valid controls, and no reason is reported

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
created: 2026-09-25T10:47:39Z
last_update: 2026-09-25T10:47:39Z
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

# T-845: Census control recogniser under-credits: test -x unrecognised, 3-char pattern floor silently refuses valid controls, and no reason is reported

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **`test -x`, `-e` and `-r` are recognised as existence controls.** `EXIST_CTRL` matches
      only `-[fsd]`. `test -x` proves a file exists **and** is executable — strictly stronger
      than `test -f`, which it implies — and is not credited at all. Measured under T-843: an
      `-x`-guarded leg was flagged, and adding a redundant `test -f` beside it cleared the flag
      with no change in what the leg establishes. That is the instrument teaching authors to
      write weaker assertions.

- [x] **The 3-character pattern floor is removed, and the reason it was safe to remove is
      stated.** `control_level()` drops candidate patterns shorter than 3 characters, so `^_`
      can never earn PATTERN credit. The floor was guarding against a control satisfied by a
      **substring coincidence** — but the same-string rule already handles that: credit requires
      the pattern to *be* one of the sibling's own grep patterns (`if p in sib_pats`), not to
      appear within its text. That exactness makes the length floor redundant for the risk it
      was added for.

- [x] **A leg that is NOT credited says WHY.** The cheaper half of OBS-379 and the half that
      matters most. Today an author controls a leg, sees it still reported as uncontrolled, and
      has nothing to distinguish "your control is wrong" from "your pattern was too short to
      consider". I made exactly that mistake and reported 16 of 17 legs drained when it was 14.
      Each uncontrolled row gains a short reason: no sibling asserts the pattern, no existence
      guard on the line, or pattern unreadable.

- [x] **DIFFERENTIAL recognition is DEFERRED, with the reason recorded rather than omitted.**
      OBS-377 asks for it and it is genuinely the strongest control, but every definition I can
      write is fuzzy enough to over-credit — and an over-broad control recogniser produces
      FALSE NEGATIVES in a classifier that now gates closes, which is the trade T-844 has just
      shown to be the wrong one. It needs its own measurement of what shapes would newly
      qualify, before any code. Deferring it is the finding, not a gap.

- [x] **Tests first, red first.** Written and run before the change and recorded failing for the
      right reason. Fixtures: a `test -x` guarded leg (must become controlled), a `^_`
      two-character same-string companion (must become PATTERN), a substring-coincidence sibling
      (must STILL be refused — the floor's original purpose must survive its removal), and an
      uncredited leg (must carry a reason).

- [x] **EVERY leg whose classification changes is listed individually, before and after.** A net
      count is not evidence: a change that credits two real controls and one bogus one improves
      the number and degrades the instrument. The corpus is re-run and the diff enumerated.

- [x] **NO leg loses its flag for a bad reason.** This change makes the census see *fewer*
      uncontrolled legs, which is the false-negative direction. For each newly-credited leg the
      control it is credited for is named and checked by hand. Any leg that becomes controlled
      without an identifiable control is a defect in this change, not a win.

- [x] **Both consumers still pass.** T-843's unit suite (12) and integration probe (16) read this
      classifier through `--block`; the gate's behaviour on a known-offending block is unchanged.

- [x] **The baseline moves only if the count genuinely falls, in the same commit, and the cause
      is labelled.** A fall here is the recogniser seeing more controls — **not legs repaired.**
      Recorded explicitly so no future reader counts it as a drain. Raising stays forbidden.

#### Recorded result — and it is smaller than the task expected

**THE UNCONTROLLED COUNT DID NOT MOVE. 103 before, 103 after.** Both defects were real and both
are fixed, and neither freed a single leg. What changed: **PATTERN 32 → 34, EXISTENCE 24 → 22** —
two legs *upgraded* their credit, nothing gained it. The reason is that the only legs these
defects were blocking were T-155's, and T-844 had already hand-guarded around them with
`test -d`. So the fixes were validated against a corpus that had already been worked around.

Recorded plainly because the tempting write-up is "fixed two classifier defects" next to a
102-line diff, and a reader would reasonably infer the number moved. It did not. The value here
is **prospective** (a short pattern or an `-x` guard will now be credited when someone writes
one) plus one thing that does change behaviour today:

**THE `WHY NOT CREDITED` LINE IS THE REAL DELIVERABLE, AND IT IMMEDIATELY TAUGHT ME SOMETHING
I HAD WRONG.** With reasons printed, the dominant uncontrolled shape in the corpus is visible
for the first time: `test -z "$(git status --porcelain -- <path>)"`, reported as *"no grep
pattern to control (zero comes from a command's output, not a match)"*. **Those legs have no
grep pattern at all**, so the same-string companion route — the remedy I have been applying all
session and the one the close gate's message names first — **is not even applicable to most of
the 103.** They need an existence guard or a differential. I had been assuming the remaining
population looked like the legs I happened to repair. It does not.

**AC "every leg whose classification changes is listed" — the list is empty, and that IS the
finding.** `comm` over the before/after uncontrolled lists: zero added, zero removed.

**AC "no leg loses its flag for a bad reason" — vacuously satisfied, and worth flagging as
such.** No leg lost its flag at all, so there was nothing to check by hand. The AC could not
fail here; it would have mattered had the count moved.

**Two of my own legs failed first rehearsal, both on documented traps.** One asserted
`! grep -qF 'len(p) >= 3'` — defeated by my own new comment, which quotes the construct while
explaining its removal. The other spanned nine lines, and P-011 is line-oriented: the lines
below the first are not shell and get eval'd anyway (T-2991 — that shape put 56MB of PostScript
into this repo's root across four incidents). Both fixed, both reasons left in the file.

**DIFFERENTIAL recognition remains deferred**, recorded in the census header rather than only
here, so the next reader of the code finds the gap where the gap is.


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

# ── T-845 legs ────────────────────────────────────────────────────────────────
# All positive assertions, as in T-844: verifying absence-assertion work with a fresh absence
# assertion would be self-defeating.

# The suite passes AND the three fixes are individually named in its output — without the second
# line, "no not ok" is satisfied by a suite that stopped exercising them.
out=$(bash tools/_t845-control-recogniser-tests.sh 2>&1); echo "$out" | grep -q '^# passed ' && ! echo "$out" | grep -q '^not ok'
out=$(bash tools/_t845-control-recogniser-tests.sh 2>&1); echo "$out" | grep -q 'test -x is an existence control' && echo "$out" | grep -q '2-character same-string companion earns PATTERN' && echo "$out" | grep -q 'uncredited leg carries a reason'

# THE OVER-CREDITING GUARDS STILL BITE. This is the false-negative direction and the only way
# this change could be harmful: a mention must never be credited as a control, at two characters
# as at ten. Both guards asserted by name.
out=$(bash tools/_t845-control-recogniser-tests.sh 2>&1); echo "$out" | grep -q 'a pattern MENTIONED but not grepped is still refused' && echo "$out" | grep -q 'a 2-char pattern MENTIONED but not grepped is still refused'

# The two fixes are present in the source, not merely in the tests.
# NOTE: this does NOT assert `len(p) >= 3` is absent from the FILE — my own comment quotes
# that construct while explaining its removal, so the negative grep was self-defeating and
# failed on first rehearsal. The floor's removal is proven behaviourally instead, by the
# suite's 2-character PATTERN test asserted two legs above.
C=tools/_t560-absence-assertion-census.py; grep -qF -- '-[fsdxer]' "$C" && grep -qF 'pats = patterns_in(text)' "$C"

# The reason function exists and its output actually reaches the report.
C=tools/_t560-absence-assertion-census.py; grep -q 'def control_reason' "$C" && grep -q 'WHY NOT CREDITED' "$C"
out=$(python3 tools/_t560-absence-assertion-census.py 2>&1); echo "$out" | grep -q 'WHY NOT CREDITED'

# T-155's two legs now earn PATTERN credit — the legs whose mis-crediting produced T-843's
# false claim. Asserted through the classifier, not by reading the file.
# ONE LINE. The first draft of this leg spanned nine, and P-011 is line-oriented: the lines
# below the first are not shell and get eval'd anyway (T-2991 — that shape put 56MB of
# ImageMagick PostScript into this repo's root across four incidents). Caught by rehearsal.
python3 -c "import importlib.util as i; s=i.spec_from_file_location('c','tools/_t560-absence-assertion-census.py'); c=i.module_from_spec(s); s.loader.exec_module(c); L=c.verification_legs('.tasks/active/T-155-hierarchical-tree-grouping-for-open-proj.md'); T=[t for _,t in L]; g=[c.control_level(t,[x for x in T if x!=t]) for _,t in L if '^_' in t and c.classify(t)]; assert g and all(v=='PATTERN' for v in g), g"

# DEFERRAL RECORDED IN THE TOOL, not just in this task — a gap named only in a closed task is
# invisible to the next reader of the code.
grep -q 'DEFERRED: no notion of a DIFFERENTIAL control' tools/_t560-absence-assertion-census.py

# THE HONEST RESULT IS WRITTEN DOWN: the count did not move, and the header says so, so nobody
# reads this change as a reduction it did not produce.
grep -q 'the uncontrolled count did NOT move' tools/_t560-absence-assertion-census.py

# Both consumers of the classifier still pass.
out=$(bash tools/_t843-absence-gate-tests.sh 2>&1); echo "$out" | grep -q '^# passed ' && ! echo "$out" | grep -q '^not ok'
out=$(bash tools/_t843-absence-gate-integration.sh 2>&1); echo "$out" | grep -q '^# passed ' && ! echo "$out" | grep -q '^not ok'

# Baseline untouched. The count did not fall, so there was nothing to lower.
grep -qx '78' tools/_t560-absence-baseline.txt

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

### 2026-09-25T10:47:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-845-census-control-recogniser-under-credits-.md
- **Context:** Initial task creation
