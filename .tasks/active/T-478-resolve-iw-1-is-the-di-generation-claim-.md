---
id: T-478
name: "Resolve IW-1: is the DI-generation claim our exporter ships in every document true?"
description: >
  Resolve IW-1: is the DI-generation claim our exporter ships in every document true?

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T22:05:50Z
last_update: 2026-08-12T22:09:28Z
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

# T-478: Resolve IW-1: is the DI-generation claim our exporter ships in every document true?

## Context

Every `.bpmn` document the designer exports carries this trailer (`src:9406-9407`, emitted
at `:9710`):

    <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->

T-357 spike 1 established that this is **not** an oversight — DI omission was a deliberate
demo-stage deferral with a named downstream owner. It also flagged the part nobody had
checked:

> It is an unverified claim about a peer project, shipped inside our bytes. Every `.bpmn`
> file we have ever exported asserts that AEF generates DI from our node coordinates.
> **I have never checked whether that is true.**

Spike 1 called this *"the sharpest question on this task"* and recorded it as asked on the
rail. It has been shipping for two months across ten releases (`dist/` 0.1.0 → 0.8.0 all
carry the string). **Whether it was ever answered is itself unknown** — that is the first
thing to establish, because "asked on the rail" is a claim about a record, and this arc has
now repeatedly found such claims to have decayed.

Why it matters to the arc: spike 1 states that either answer changes T-357's
recommendation. If AEF **does** generate DI, our exports are DI-less only in transit and
the T-340 defect is narrower than filed. If AEF **does not**, we have shipped a false
statement about a peer project inside our bytes for two months, and the deferral was never
collected — a gap, not just a task.

**Scope: establish the answer and record it. Not fix.** If the claim is false, correcting
the trailer is a src change and gets its own task (one bug = one task).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The rail record is searched for whether IW-1 was ever asked and ever answered, with
      the result stated as offsets — "asked on the rail" is treated as a claim to verify,
      not as evidence (the T-470/T-472 class)
- [x] The exact scope of the shipped claim is measured, not paraphrased: which artifacts
      carry the trailer string and how many, with the denominator stated (PL-084)
- [x] If the rail does not settle it, the question is **posted to AEF** in a form they can
      answer with one measurement, and the task records that the answer is outstanding
      rather than guessing it
- [x] `docs/reports/T-357-di-adoption.md` spike 1 updated with whatever was established —
      including "still unanswered, asked at offset N" if that is the truth
- [x] No change to `src/` or to the trailer under this task; any correction is filed as a
      separate task with the evidence attached

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
# --- T-478 legs ---
# The report no longer leaves IW-1 hanging, and records the answer.
/usr/bin/grep -q '^### IW-1 ANSWERED' docs/reports/T-357-di-adoption.md
# A-020 is invalidated in the register — the answer is recorded structurally, not only in prose.
out=$(.agentic-framework/bin/fw assumption list 2>&1); echo "$out" | /usr/bin/grep -qE 'A-020 +.*invalidated'
# src is already corrected (T-361) — the constant carries the transport wording, not generation.
/usr/bin/grep -q "const DI_TRAILER = .\${DI_TRAILER_PREFIX}; node geometry travels as aef:position" src/aef-workflow-designer.html
test "$(/usr/bin/grep -rl 'AEF generates it from node coordinates' src/ 2>/dev/null | wc -l)" = "0"
# The generated corpus is NOT corrected — the finding of this task. Whole population, no sample.
test "$(/usr/bin/grep -rl 'AEF generates it from node coordinates' examples/aef-processes/rendered/ | wc -l)" = "24"
test "$(find examples/aef-processes/rendered -name '*.bpmn' | wc -l)" = "24"
# ...and the corrected wording has reached zero corpus documents (the gap, stated as a count).
test "$(/usr/bin/grep -rl 'node geometry travels as aef:position' examples/ 2>/dev/null | wc -l)" = "0"
# The emit site interpolates the constant — this is what makes a re-export self-correcting.
# NOTE: pattern deliberately contains NO backticks. P-011 eval-expands each line, and
# backticks are command-substituted even inside single quotes — the first form of this leg
# silently collapsed to `grep -q 'lines.push(  )'` and went red for the wrong reason.
/usr/bin/grep -q 'DI_TRAILER} -->' src/aef-workflow-designer.html
# The T-101 mechanism warning is present — it must not be left for someone to infer.
/usr/bin/grep -q 'if T-101 re-exports the 24' docs/reports/T-357-di-adoption.md
# Scope held: no src change under this task.
test -z "$(git diff --name-only HEAD -- src/)"
# Finding registered where it outlives the task.
/usr/bin/grep -q 'OBS-040' .context/inbox.yaml
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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-12T22:05:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-478-resolve-iw-1-is-the-di-generation-claim-.md
- **Context:** Initial task creation
