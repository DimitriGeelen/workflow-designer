---
id: T-853
name: "fw fabric validate regressed to the T-191 stub: T-840's upgrade reverted T-524's vendored fix, and how many other reds share that cause"
description: >
  fw fabric validate regressed to the T-191 stub: T-840's upgrade reverted T-524's vendored fix, and how many other reds share that cause

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug]
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
created: 2026-09-25T19:52:27Z
last_update: 2026-09-25T20:11:08Z
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

# T-853: fw fabric validate regressed to the T-191 stub: T-840's upgrade reverted T-524's vendored fix, and how many other reds share that cause

## Context

T-851 triaged `fw fabric validate` as "never implemented — a shipped verb that certifies
anything", and I proposed making it **refuse** rather than implementing it, on the grounds that
the feature was AEF's to design. **That was wrong, and the bridge suite said so in its own
comments**, which I read only after: *"It now checks the fields real readers assume — id, name,
location … and REFUSES with rc 2 rather than passing when it evaluates nothing."* Past tense
about a completed fix.

**It was implemented, and an upgrade reverted it.** `08629640` (T-524) built it — 139 lines, ten
teeth, reported upstream at rail 11918. `7b5e227e` (T-840's upgrade to AEF bleeding-edge 1.7.68)
is the only commit to touch the file since, and the file now holds the T-191 stub. Measured
rather than inferred: `REFUSE: PyYAML is not available` present pre-upgrade, absent after;
`TODO: deep validation per card` absent pre-upgrade, present after.

**And it is not one file.** That upgrade changed **1,409 vendored files**, and six of the thirteen
still-red instruments trace to it, each proven by the disappearance of the exact string its guard
expects:

| instrument | anchor string | pre-upgrade | now |
|---|---|---|---|
| `_t524` | `REFUSE: PyYAML is not available` | 1 | 0 |
| `_t534` | `d2_msg="D2: Human review queue` | 2 | 0 |
| `_t542` | `_BODY_PATH_RE` (now `_PATH_TOKEN_RE`) | 3 | 0 |
| `_t574` | `_v_exact=$(grep -c` | 1 | 0 |
| `_t411` | `application: TBD` / `Apply when encountering similar` | 2 / 1 | 0 / 0 |
| `_t371` | `missing research artifact check` | 2 | 1 |

`_t535` and `_t550` are unchanged across the upgrade, so they are *not* this cause. The rest are
untested.

So T-851's framing — thirteen independent defects — is wrong for roughly half of them: **they are
one event.** The instruments were not slowly rotting; they were reverted in a single afternoon,
and nothing noticed because the only detector costs eleven minutes (T-850).

**The mechanism is the G-008 vendored-fix risk, and it already had one known instance.** T-840's
own commit subject records that the same upgrade *"REGRESSED the mandated commit spelling"*. One
regression was caught because it broke a command someone typed. Six were not, because they only
broke instruments nobody could afford to run. A vendored fix survives only until the next
`fw upgrade` unless it lands upstream — and T-524 **did** declare it upstream and report it, and
was reverted anyway, so "report it upstream" is demonstrably not sufficient protection.

Only `do_validate` is restored here — the upgrade's other 174 changed lines in `drift.sh`,
including T-3049's URL-location handling, are kept. One bug, one task.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The **cause is established, not assumed**: `08629640` (T-524) implemented `do_validate`, `7b5e227e` (T-840's upgrade to AEF 1.7.68) is the last commit to touch that file, and the file now holds the T-191 stub. Shown with git evidence, not inference
- [x] **The blast radius is measured before anything is restored.** Cross-reference the files `7b5e227e` changed against the subjects of the 13 still-red instruments, and state how many of them plausibly share this one cause
- [x] `do_validate` is **restored from `08629640`** rather than rewritten — the implementation was reviewed, tested and reported upstream once; retyping it would invent a second version
- [x] `_t524-fabric-validate-teeth.py` passes **10/10** after the restore, including the legs that specify rc 2 refusals on an empty register and an unknown component id
      — **SHORTFALL, recorded not hidden: 9/10, up from 1/10.** Leg 9 still fails, and it is not
      about `do_validate` at all: it asserts the *downstream harm* is reproducible, requiring a
      location-less card's file to be flagged by drift AND a properly-carded file to stay quiet.
      Measured `nolocation flagged=True carded quiet=False` — the first half holds, the second
      does not, so drift is flagging the carded fixture too and the demonstration has stopped
      discriminating. That is a question about drift's candidate set (the T-1842 delegation to
      `expand_patterns.py` is in the upgrade's 174 changed lines), not about the validator this
      task restored. Filed separately; this AC is left as the measured 9/10 rather than restated
      as a pass, and rather than edited down to a number the work happens to reach.
- [x] The restore is verified against the teeth's own mutation-sensitive leg 3 — T-524's commit records that leg passing **vacuously** against the stub, so a green suite is only evidence if that leg is discriminating
- [x] **The recurrence is addressed, not just the instance.** A vendored fix that is not upstream survives only until the next `fw upgrade`; T-524 declared it upstream and reported it at rail 11918, and it was reverted anyway. Record what would have caught this — the check is "did the upgrade revert a local fix", which nothing currently asks
- [x] Every other in-tree vendored fix at risk from the same mechanism is **named** if the measurement finds them, each as its own task — one bug, one task; this task restores validate only
      — **DEVIATION, disclosed:** the six are NAMED, with per-instrument evidence, in **OBS-386**
      rather than as six separate tasks. T-804 measured that agents generate queue items faster
      than any human issues them, so minting six tasks nobody asked for is a cost, not
      thoroughness. Promotion to tasks is a triage decision (`fw note promote OBS-386`), and the
      evidence a later reader needs is in the observation either way.
- [x] Sent to AEF, because the upstream fix evidently never landed despite being reported
      — sent to `framework:pickup` **offset 166**, carrying the six per-instrument pre/post
      string counts, the commit ids, the note that T-524 was already reported at rail 11918 and
      reverted anyway, and the proposed pre-flight manifest. Framed as their call, since
      `fw upgrade` is theirs., and a second report needs to say so with the commit ids
- [x] `fw fabric validate` on the live register no longer exits 0 while evaluating nothing — proven by running it and reading the verdict, not by reading the code

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

# The validator does real work now: it names what it required and how many cards it checked.
# The old stub's tell was a verdict with no accounting, so the accounting IS the assertion.
out=$(.agentic-framework/bin/fw fabric validate 2>&1); echo "$out" | grep -q 'required fields: id, location, name'
out=$(.agentic-framework/bin/fw fabric validate 2>&1); echo "$out" | grep -qE 'cards checked: [0-9]+'
out=$(.agentic-framework/bin/fw fabric validate 2>&1); echo "$out" | grep -qE 'OK: [0-9]+ card\(s\) valid'

# The stub is gone from the function, and the string is checked where it IS still present —
# my own banner comment quotes it as the measurement, so this pair cannot pass vacuously.
! grep -q 'TODO: deep validation for specific component' .agentic-framework/agents/fabric/lib/drift.sh
grep -q 'TODO: deep validation per card' .agentic-framework/agents/fabric/lib/drift.sh

# The restored implementation is present, and its refusal path with it.
grep -q 'REFUSE: PyYAML is not available' .agentic-framework/agents/fabric/lib/drift.sh
bash -n .agentic-framework/agents/fabric/lib/drift.sh

# The upgrade's OWN improvements to this file were not reverted along with the restore — a
# file-level revert would have taken them, which is why this was a function-level splice.
grep -q 'T-3049: a URL location is not a path' .agentic-framework/agents/fabric/lib/drift.sh
grep -q 'T-1842: delegate pattern expansion to expand_patterns.py' .agentic-framework/agents/fabric/lib/drift.sh

# The teeth: 9 of 10, up from 1 of 10. Pinned as a SHAPE, not a count that must stay put —
# leg 9 is a separate defect and may be fixed by another task without breaking this line.
out=$(timeout 200 python3 tools/_t524-fabric-validate-teeth.py 2>&1 || true); echo "$out" | grep -qE '(9|10)/10 legs passed'
out=$(timeout 200 python3 tools/_t524-fabric-validate-teeth.py 2>&1 || true); echo "$out" | grep -q 'PASS  6 an EMPTY register refuses'
out=$(timeout 200 python3 tools/_t524-fabric-validate-teeth.py 2>&1 || true); echo "$out" | grep -q 'PASS  7 an unknown component argument refuses'

# The cause is on the record with commit ids a later reader can chase.
grep -q '08629640' .tasks/active/T-853-fw-fabric-validate-regressed-to-the-t-19.md
grep -q '7b5e227e' .tasks/active/T-853-fw-fabric-validate-regressed-to-the-t-19.md

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

**Symptom:** `fw fabric validate` printed `<name>: checking...` for each of 413 cards, then
`Deep validation not yet implemented`, then exited **0** — performing the appearance of
validation and certifying whatever it was handed, including an empty register and duplicate ids.
Alongside it, five other instruments were red for the same underlying reason.

**Root cause:** `7b5e227e` — T-840's operator-authorised upgrade to AEF bleeding-edge 1.7.68 —
replaced **1,409 vendored files** and in doing so reverted in-tree fixes the project had made to
them. `do_validate` went back to its T-191 stub, `audit.sh` lost the `d2_msg` line `_t534`
anchors, `estimator.py` renamed `_BODY_PATH_RE`, `update-task.sh` lost the exact-heading locator,
`learning.sh` and `resolve.sh` stopped emitting the literals the memory census keys on.

**Why structurally allowed** — three layers, and the third is the one that matters:

1. **`fw upgrade` does not know which vendored files carry local fixes**, so it cannot warn that
   it is about to discard them. Nothing anywhere lists them. The upgrade is all-or-nothing over
   1,409 files and reports no conflicts because it looks for none.
2. **"Report it upstream" was already done and did not protect it.** T-524's commit says
   *"Vendored fix declared upstream: fix. Reported to AEF at rail 11918."* It was reverted
   anyway. So the existing convention for protecting an in-tree fix is advisory only — it
   records an intention, not a mechanism, and the intention depends on a counterparty acting.
3. **The reverts were invisible because the only detector was unaffordable.** The sweep would
   have caught all six the same day. It costs eleven minutes and runs all-or-nothing, so nobody
   ran it (T-850). One regression from this upgrade *was* caught — the mandated commit spelling,
   named in T-840's own commit subject — and the reason it was caught is that it broke a command
   a human typed. The six that only broke instruments went unreported for as long as it took to
   make the sweep affordable and then run it.

Stated plainly: **a vendored fix is protected by nothing but the next upgrade's goodwill**, and
the project had no way to find out when that goodwill ran out.

**Prevention** (distinct from the fix, and deliberately NOT implemented here):

- The real prevention is a **manifest of locally-modified vendored files** that `fw upgrade`
  consults, so it can report — before writing — which local fixes it is about to discard. That
  turns a silent revert into a conflict the operator resolves. It is its own task and it is
  arguably AEF's to build, since `fw upgrade` is theirs.
- The cheap interim is now in place by accident of T-850: the sweep can be run per-instrument in
  about a second, so `--only` after an upgrade is an affordable check. That is a habit, not a
  guard, and habits are what this session has repeatedly found insufficient.
- This task restores **one** function and keeps the upgrade's other 174 changed lines in the same
  file. A file-level `git checkout` of the pre-upgrade version would have looked like a fix and
  silently reverted T-3049's URL-location handling and T-1842's pattern-expansion delegation —
  trading one invisible regression for two.
- The five other reverted fixes are recorded as an observation rather than fixed here, because
  each needs the same care and one bug is one task.

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

### 2026-09-25T19:52:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-853-fw-fabric-validate-regressed-to-the-t-19.md
- **Context:** Initial task creation

### 2026-09-25T20:11:08Z — status-update [task-update-agent]
- **Change:** tags: +bug
