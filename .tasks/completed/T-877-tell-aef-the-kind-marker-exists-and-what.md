---
id: T-877
name: "Tell AEF the kind marker exists and what their promote path can now read"
description: >
  arc-005 S1/B3. AEF proposed this marker (their T-2556, rail offsets 87-125) and
  owns the promote path that carries the defect: fw bpmn promote mints real owner:
  agenthuman tasks from illustrative nodes (their L-504 / T-2548-9). We can ship the
  marker; we cannot make them read it. STATE THAT RATHER THAN CLAIM THE DEFECT CLOSED
  — B3 delivers a notice, and the defect closes only when AEF acts on it. Rail post,
  no code.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:process-instances]
components: [src/aef-workflow-designer.html, tools/validate-workflow.py]
related_tasks: []
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
created: 2026-09-26T22:41:56Z
last_update: 2026-09-28T21:18:30Z
date_finished: 2026-09-28T21:18:30Z
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
  - ts: '2026-09-26T23:10:10Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=3 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-877: Tell AEF the kind marker exists and what their promote path can now read

## Context

arc-005 slice S1, manifest item B3: *"Seam notice to AEF: the marker exists, here is its shape,
their promote path is theirs to change. Rail post, no code."*

T-875 shipped `aef:workflowMeta/@kind` and T-911 made it settable and visible in the designer.
Both touch a seam AEF pins against, so they get told before the corpus changes under them —
**T-876 (backfill across the 24 maps) is deliberately sequenced after this.**

**Three facts the notice has to carry, and the third is the one they cannot get from our tree:**

1. The attribute: closed enum `{documentation, work-plan}`, UNSET legal and the default
   (T-213 IW-3 — an explicit author decision, never a silent reclassification).
2. Today **0 of 24** corpus maps declare it. The marker exists; the corpus has not moved yet.
3. **`kind` is not a unique attribute name in our vocabulary.** `aef:timer/@kind` already exists
   and carries values like `cron`. A promote path matching `kind=` without qualifying the element
   would read a timer's kind as a document kind. Found while writing this notice, by a loose grep
   of my own that reported "1 of 24 maps declare kind" — it was `revisit-due-scan.bpmn`'s
   `<aef:timer kind="cron" …>`. The wrong answer arrived first and looked plausible.

**Not asking them to change anything.** Their promote path is theirs. This is a seam notice, not a
request.

## Rail record

**Posted:** `framework:pickup` offset **226**, 2026-09-28.
**Retrievable by content:** search `framework:pickup` for `kind\` IS NOT A UNIQUE ATTRIBUTE NAME` — 1 hit, offset 226.

## Acceptance Criteria

### Agent
- [x] Rail post to `framework:pickup` carrying: the marker's shape, its closed enum, the UNSET default, and the round-trip guarantee with the control that proves it
- [x] The post states explicitly that **the defect closes when AEF's promote path reads the marker, not when we post** — B3 delivers a notice, not a fix
- [x] The post attributes the marker to AEF's own proposal (their T-2556, rail offsets 87–125) rather than presenting it as ours
- [x] The returned offset is recorded in this task, so the claim "we told them" is checkable and not a memory
- [x] **A5 recorded:** yes/no with reason in `## Decisions`
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

# The rail offset is RECORDED here, so "we told them" is checkable rather than remembered.
# (The previous version of this leg greped the task file for its own id — a tautology that
#  could not fail, written into the task whose whole subject is checkable claims.)
grep -qE '^\*\*Posted:\*\* `framework:pickup` offset \*\*[0-9]+\*\*' .tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md
# The three facts the notice had to carry are stated in this task, so a reader can check the claim
# against the corpus without fetching the rail.
grep -q 'ZERO OF OUR 24 CORPUS MAPS' .tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md || grep -q '0 of 24' .tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md
# Fact 1 re-derived from the corpus rather than quoted: no map declares aef:workflowMeta/@kind.
# CONTROL for the absence leg below (PL-328): the SAME pattern must be findable somewhere, or a
# typo in it satisfies the zero-count over the corpus. The aef:timer leg further down is a
# different string and controls a different claim — it does not cover this one.
grep -qE '<aef:workflowMeta[^>]*kind=' tests/fixtures/aef-bpmn/t875-kind-marker.bpmn
test "$(grep -l '<aef:workflowMeta[^>]*kind=' examples/aef-processes/rendered/*.bpmn 2>/dev/null | wc -l)" -eq 0
# Fact 2: the element-ambiguity is real — aef:timer/@kind exists in the corpus. CONTROL for the
# absence leg above: proves `kind=` IS findable, so that leg cannot pass on a typo'd pattern.
grep -q '<aef:timer[^>]*kind=' examples/aef-processes/rendered/revisit-due-scan.bpmn
# The enum is closed and defined exactly once, as the notice states.
test "$(grep -c '^WORKFLOW_KINDS = ' tools/validate-workflow.py)" -eq 1
# The round-trip guarantee the notice cites is still true.
timeout 300 node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t877.out 2>&1 && python3 -c "import json,sys;d=json.load(open('/tmp/.t877.out'));sys.exit(0 if 'kind' in d['wm_selftest']['live'] else 1)"

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

### 2026-09-28 — a loose grep gave me the wrong answer first, and it became the notice's best content
- **What changed:** checking how many corpus maps declare the marker, my grep reported **1 of 24**
  and named `revisit-due-scan.bpmn`. The hit was `<aef:timer kind="cron" …>` — a *different
  element*. The true answer is **0 of 24**.
- **Plan impact:** none to the deliverable, but it became point 2 of the notice, and it is the item
  AEF could not have derived from our tree: **`kind` is not a unique attribute name in our
  vocabulary**, so a promote path matching `kind=` without qualifying the element reads a timer's
  kind as a document kind. The mistake is more useful to them than the correct number, so the
  notice carries both.
- **Triggered:** nothing filed — the corpus is correct; only my query was wrong.

### 2026-09-28 — the notice found a contradiction between their plan and ours, and T-876 is now held
- **What changed:** reading T-2556 to attribute the proposal correctly (AC3) surfaced its own
  closing line: *"AEF would re-mark the 5 corpus diagrams kind=documentation via normal editor
  saves after ratification — no bulk rewrite."* Our arc-005 has **T-876** filed as a **24-map bulk
  backfill by us**. Different actor, different population, on artifacts AEF **byte-pins**.
- **Plan impact:** T-876 is held pending their answer, and the notice asks the question outright.
  I had recommended T-877 before T-876 on sequencing grounds — tell them before moving their seam —
  and the reason turned out to be stronger than the one I gave: the two plans disagree, and running
  ours would have silently resolved a conflict in our own favour on a pinned interface.
- **Triggered:** nothing new; T-876 stays `captured` with the reason recorded in `## Decisions`.

### 2026-09-28 — two of my own verification legs were the defects this project hunts
- **What changed:** the first leg I wrote greped the T-877 task file for the string `T-877` — a
  tautology that cannot fail, in the task whose entire subject is making a claim checkable. Then
  the close gate refused the next version: my absence leg asserted `<aef:workflowMeta…kind=` is
  absent from the corpus while its "control" greped `<aef:timer…kind=` — a **different string**,
  so a typo in the absence pattern would have passed unnoticed.
- **Plan impact:** both replaced. The offset leg now asserts the recorded offset matches a shape;
  the absence leg now has a same-string control against `t875-kind-marker.bpmn`.
- **Triggered:** nothing filed — PL-328 and the close gate already encode it. Recorded because both
  were written *today*, by me, hours after committing a fix for the identical class in T-915.

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

### 2026-09-28 — A5: does this deliver arc purpose and project purpose? **Yes, and it is the cheapest item in the arc.**

arc-005 S1 exists so a map can declare whether it is illustrative or actionable. T-875 built the
declaration, T-911 made it usable, and **this is the only part that reaches the consumer** — the
marker's whole purpose is to be read by AEF's promote path, and until they know it exists it is a
field nobody reads. The defect is theirs and live (their L-504 / T-2548-2549: documentation nodes
promoted into the task gate as real `owner:human` tasks), so a signal we never announce closes
nothing.

Project purpose: **G3** (an instance knows its class). The marker is that distinction at document
level, and a distinction the other side cannot see is not one.

**No code, by design** — arc-005 filed B3 as "rail post, no code", and it stayed that way.

### 2026-09-28 — T-876 is HELD, and this notice is why
- **Chose:** hold T-876 (backfill `kind` across 24 corpus maps) pending AEF's answer.
- **Why:** their T-2556 proposal says *"AEF would re-mark the 5 corpus diagrams kind=documentation
  via normal editor saves after ratification — no bulk rewrite."* Our T-876 is filed as a 24-map
  bulk backfill. Those are different operations, on artifacts **AEF byte-pins**, differing in both
  actor and population (5 by them vs 24 by us). Discovered by reading their proposal while writing
  the notice, not by reading our own task title.
- **Rejected:** running T-876 as filed. Moving a pinned seam on a guess about which of two
  conflicting plans is current is the one thing worth not doing, and the cost of asking is one
  paragraph in a notice that was being written anyway.

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

### 2026-09-26T22:41:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md
- **Context:** Initial task creation

### 2026-09-28T21:14:30Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-09-28T21:17:29Z — status-update [task-update-agent]
- **Change:** owner:  → agent

## Reviewer Verdict (v1.5)

- **Scan ID:** R-73be9362
- **Timestamp:** 2026-09-28T21:18:34Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 7
     - evidence: `grep -q 'ZERO OF OUR 24 CORPUS MAPS' .tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md || grep -q '0 of 24' .tasks/active/T-877-tell-aef-the-kind-marker-exists-and-what.md`

### 2026-09-28T21:18:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
