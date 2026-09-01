---
id: T-663
name: "T-364 teeth are dead: the control pins an emitter baseline 22 commits old, so _t308 unusable:0 is an unproven zero again"
description: >
  T-364 teeth are dead: the control pins an emitter baseline 22 commits old, so _t308 unusable:0 is an unproven zero again

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
created: 2026-09-01T09:31:36Z
last_update: 2026-09-01T09:52:01Z
date_finished: 2026-09-01T09:52:01Z
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

# T-663: T-364 teeth are dead: the control pins an emitter baseline 22 commits old, so _t308 unusable:0 is an unproven zero again

## Context

`tools/_t364-t308-teeth.py` is the instrument that proves another instrument works: it
exists to show that `_t308`'s `unusable` bucket — the one that stops the byte-identity
gate reporting a green over documents it cannot actually compare — can fill. G-023
(severity `high`) is registered precisely because an empty bucket and a bucket that
cannot fill report the same number.

Found while testing whether G-023's closure condition was met: the teeth print
`TEETH BROKEN` and refuse to assert anything. Their control pinned `BASELINE_REF =
3bf37909~1` (2026-08-04) and asserted the 24 designer maps emit byte-identical output
between that build and the tree. **22 commits changed the emitter since** — T-602
(documentation survives), T-603 (multi-process no longer dropped), T-618 — while the
corpus source itself took **zero**. The control was asserting that this arc's own
repair work had not happened.

So `_t308`'s `unusable: 0` went back to being an unproven zero, which is the exact
state G-023 was registered for, reached from the other side: not the gate lying, but
its proof-of-teeth quietly expiring.

Not a diagnosis-only task — the repair is entirely ours and needs no ruling. It matters
to the arc because `_t308` is the instrument every import-repair task cites for "this
moved no bytes", including the two ACs T-358 is holding open pending the operator's
lane-fabrication ruling. When that ruling lands, the verification it triggers should
rest on teeth that are alive.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

- [x] **The death is reproduced and dated, not merely asserted.**

      **DONE 2026-09-01.** Reproduced: `control : rc=1 maps=24 identical=0 drifted=24
      unusable=0` → `TEETH BROKEN — the control corpus does not pass, so nothing below
      proves anything`. The instrument refused to assert anything on a failed control,
      which is why this was recoverable at all.

      Premise invalid by design: **22 commits changed `src/` since `3bf37909~1`**, while
      the corpus source took **0** commits in the same span. So the maps legitimately
      emit ~40% more bytes (audit-process 13563 → 21476) and cross-build byte-identity
      could not have survived this arc's own import-loss repairs.

      **Death date `4c40414c` (T-399, 2026-08-09)** — the producer-identity trailer, the
      first commit after the baseline to change an emitted line. Reached two independent
      ways that agree: a causal scan of each commit's diff for added emit lines, and the
      suite's own T-510 correction at `tools/_t509-instrument-sweep.sh` (*"every one of
      the 24 maps drifts by EXACTLY +51 bytes — T-399's producer-identity line"*).

      **Sub-finding worth its own line: that stale explanation was still on duty.** The
      exclusion said +51 bytes; the drift today is **+7913** on audit-process, because
      20 further emitter commits landed after the diagnosis was written. The exclusion
      outlived its own reason — it was correct when written, never re-checked, and would
      have gone on excusing a red for a cause that had stopped being the cause.

- [x] **The repaired control does not depend on any pinned historical build.**

      **DONE.** `BASELINE_REF` is gone from the file. The control now runs `_t308` with
      no ref argument and no override, so the old side is `HEAD:src` and the new side is
      the working tree — a self-comparison of one build. Measured: `ok=True maps=3
      identical=3 drifted=0 unusable=0`. There is no second build for the emitter to
      drift away from, so this control cannot rot the way its predecessor did.

- [x] **The injection fires the `unusable` bucket in the CURRENT build.**

      **DONE, and the docstring's prescribed fix turned out to be unsatisfiable — for a
      good reason.** It said to find "a NEW injection that is genuinely unstable in both
      builds (a document with a nondeterministic emitted field)". No such document
      exists any more: after T-364 the parse→build path has no nondeterminism left
      (`Math.random`/`Date.now`/`crypto.randomUUID` between the parser and
      `buildBpmnXml` returns only the comment describing the fixed defect). Measured
      directly: `simple.bpmn`, which has no `aef:workflowMeta`, is self-stable under
      this gate.

      Two things follow. (1) The instability must come from a **build**, not a document,
      so `_t308` grew `T308_OLD_SRC` — same shape and same stated purpose as the
      `T308_CORPUS` override T-364 added for exactly this need. Measured: `ok=False
      maps=3 identical=0 drifted=0 unusable=3`. (2) A run using the override **declares
      itself** (`srcOverride`, and `ref` reads `T308_OLD_SRC:<path>`) so it can never be
      quoted as a gate result — G-023's own rule applied to the tool G-023 is about.

- [x] **`identical` neither inflates nor shrinks when the injection is present.**

      **DONE.** Asserted on both runs, not just `unusable`: `identical == 0` (no
      unmeasurable document counted as a match) and `maps == 3` (the denominator did not
      quietly shrink). Those are the two failure modes G-023 was registered for, and
      each now has its own leg rather than being implied by the bucket count.

- [x] **The teeth fail for their own predicted reason, checked per-mutation.**

      **DONE.** The `unusable` detection branch is disabled in a temp copy of `_t308`
      and the same input re-run: `ok=False maps=3 identical=0 drifted=3 unusable=0`. All
      three documents move from `unusable` to `drifted`, so the `fills` result is
      attributable to that branch and not to something incidental (PL-208). A second leg
      asserts that even blunted, nothing unstable is counted `identical` — the
      silent-green failure is reachable in one edit, which is the point.

      Mutations use the T-661 discipline (`before >= 1` else STALE ANCHOR, `after == 0`
      else MUTATION INCOMPLETE; no upper bound). The blunted copy must live in `tools/`
      because `_t308` resolves `_cdp-attach.mjs`, `gallery-serve.py` and `REPO` relative
      to its own directory — a `/tmp` copy dies on import, which is how this was found.
      It is removed in `finally` and the run asserts it is gone rather than trusting.

- [x] **The next death is loud.**

      **DONE — and the surface already existed; the teeth were excused from it.**
      `tools/_t509-instrument-sweep.sh` runs every `tools/*teeth*` script on every bridge
      run (`tests/run-bridge-tests.sh:1053`). It enumerates by `ls tools/ | grep -Ei
      'teeth'`, so this file was always in the population — and was excluded **by name**,
      with a reason ending *"choosing that is a decision"*. That decision is now made and
      implemented, so the exclusion entry is deleted and the script runs. A future death
      arrives as a sweep regression instead of a comment nobody reads.

      The instrument's own refusal stays as the inner layer: a failed control still
      prints *"TEETH BROKEN — the control corpus does not pass, so nothing below proves
      anything"* and refuses to assert. That refusal is why this was recoverable at all.

      **Registered rather than fixed here (one bug, one task).** The sweep checks for a
      *stale exclusion* only in the sense of "the excluded file no longer exists"
      (`_t509:92`). It has no check for the case that actually happened: an exclusion
      whose stated REASON expired while the file stayed put. Ours claimed "+51 bytes,
      T-399" for three weeks after the real drift had grown to +7913. An exclusion is a
      standing claim about why something may be skipped, and nothing re-tests it.

<!-- No Human AC by deliberate choice (T-663). The live operator queue stands at 61
     unticked [REVIEW] items across 55 tasks; ~30 tasks closed in the preceding five
     days each deposited into it. This task is wholly agent-verifiable, so adding a
     rubber-stamp here would be manufacturing operator debt to no end. -->


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
         1. Run `bin/fw reviewer T-663`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-663 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The teeth must pass, and well inside the sweep's 90s per-script ceiling (measured 5s).
python3 tools/_t364-t308-teeth.py
# The gate's DEFAULT behaviour is untouched by the T308_OLD_SRC addition: a bare run
# still ranges over the real corpus and still declares that no override was used.
node tools/_t308-export-byte-identity-cdp.mjs | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['ok'] and d['srcOverride'] is None and d['identical']==d['maps'] and d['unusable']==0, d; print('t308 default clean:', d['identical'], 'of', d['maps'])"
# The sweep exclusion is really gone, not merely reworded.
sh -c '! grep -q "_t364-t308-teeth.py|" tools/_t509-instrument-sweep.sh'
# No mutated copy of the gate was left behind in the tree.
sh -c '! ls tools/ | grep -q BLUNTED'
# The sweep script still parses after the exclusion edit.
bash -n tools/_t509-instrument-sweep.sh

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
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
     fw inception decide T-663 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T09:31:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-663-t-364-teeth-are-dead-the-control-pins-an.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ea6fe955
- **Timestamp:** 2026-09-01T09:52:09Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 9
     - evidence: `sh -c '! ls tools/ | grep -q BLUNTED'`

### 2026-09-01T09:52:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
