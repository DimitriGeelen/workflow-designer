---
id: T-624
name: "Inception ranking carries no information: the template default is indistinguishable from an unscored task"
description: >
  Inception ranking carries no information: the template default is indistinguishable from an unscored task

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
created: 2026-08-29T13:59:52Z
last_update: 2026-08-29T14:06:45Z
date_finished: 2026-08-29T14:06:45Z
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

# T-624: Inception ranking carries no information: the template default is indistinguishable from an unscored task

## Context

For inception tasks the BVP estimator does not run its nine per-driver scorers at
all. `_score_inception_voi` (estimator.py:2429) short-circuits every driver to a
single value derived from the `voi_score:` frontmatter field, because for an
exploration the value IS the information the exploration buys — a deliberate and
defensible design (T-2188).

The consequence is not deliberate. `voi_score: 0.5` ships in
`.tasks/templates/inception.md:22`, so every inception is born at the midpoint,
and 38 of our 41 inceptions still carry it (1 deliberately scored, 2 with the
field absent). `fw bvp --quadrant hv-lc` therefore
prints **thirteen active tasks at an identical BVP 126 / norm 0.40**, ordered by
tiebreak, while the other three quadrants spread normally (hv-hc runs 118→167).
The quadrant the operator is asked to rule on is the one quadrant that is not
ranked.

Found while answering "what's needed to bring the outstanding inceptions
forward". The answer turned out to be upstream of every individual task: nothing
ranks them, so there is no defensible order in which to bring them forward.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A measurement tool reports, per inception, whether `voi_score:` has ever been
      changed from the value the template shipped, using the file's own git history
      (PL-149: a population contains its own provenance). Distinguishing "scored 0.5
      on purpose" from "never scored" is impossible from the value alone and trivial
      from the history.
- [x] The inception-schema gate stops teaching the midpoint. Its remediation text
      currently reads "so the BVP estimator can rank them against build tasks" and
      then hands the author `voi_score: 0.5` as the worked example — the stated
      purpose and the supplied value contradict each other in the same message.
- [x] The gap is registered in `.context/project/concerns.yaml` with the measured
      chain, and the register still parses with no duplicate ids.
- [x] **No task's `voi_score:` is written by this task.** `voi_score` IS the composite
      for an inception, which makes it the sovereignty equivalent of confirmed
      `bvp_scores:`. Unlike `bvp_scores`/`cost_estimate` it has no `_proposed:` lane,
      so there is no legitimate way for an agent to contribute one. That absence is
      itself part of the finding, not a licence to write the field.

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
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.
#
# Every leg below greps a FILE directly rather than a pipeline. L-387's capture-then-grep
# remedy is unnecessary here and, per our own correction on rail @755, would itself be
# unsound for an early match: `grep -q PAT file` never has an upstream writer to SIGPIPE.
python3 tools/_t624-voi-provenance.py --self-test
python3 tools/_t624-voi-provenance.py --assert-scored 1
# The count above is the sovereignty leg, not a statistic: it fails if any agent writes a
# voi_score, which is the operator's field and has no _proposed: lane. AC-4 in machine form.
grep -q "NOT 0.5 unless you mean it" .agentic-framework/agents/context/check-inception-schema.py
grep -q "CHANGE THIS (T-624)" .tasks/templates/inception.md
python3 -c 'import yaml; c=yaml.safe_load(open(".context/project/concerns.yaml"))["concerns"]; g=[x for x in c if x["id"]=="G-045"]; raise SystemExit(0 if g and g[0].get("decision_trigger") else 1)'
# The template still SHIPS voi_score: 0.5 and must — removing it re-breaks PL-167 and would
# fail every new inception at the schema gate. This leg pins that we warned rather than deleted.
grep -q "^voi_score: 0.5" .tasks/templates/inception.md

## RCA

**Symptom:** `fw bvp --quadrant hv-lc --include-proposed` returns 13 active tasks
at an identical BVP 126 / norm 0.40. `fw bvp estimate` on any two of them returns
byte-identical driver vectors (`D1=2 D2=2 D3=2 D4=2 F-RECALL=2 F2=2 F4=2 F3=2 F1=2`)
for tasks with nothing in common — T-184 (reverse discovery from AEF records) and
T-501 (map ID round-trip triage). Latency gives it away before the scores do: the
flat tasks return in ~0.024s against ~0.08–0.11s for differentiated ones, because
the nine scorers never run.

**Root cause:** a chain in which *every link behaves as designed*.
1. `.tasks/templates/inception.md:22` ships `voi_score: 0.5`.
2. `check-inception-schema.py` requires the field present and in 0..1 — `0.5` passes,
   and its own remediation text (line 172) offers `voi_score: 0.5` as the example.
3. `_score_inception_voi` (estimator.py:2429) makes that single field the entire
   composite for inceptions, bypassing per-driver scoring.
4. The estimator *does* carry a branch for the unscored case — `voi is None` returns
   `→2 (voi-absent-grandfathered)`. It is unreachable for any template-created task,
   because step 1 guarantees the field is never `None`. Measured: 38/39 inceptions
   report `→2 (voi:0.50)`; the grandfathering branch fires for exactly one (T-155).
5. Both branches yield 2, and the ranking table prints neither evidence string.

**Why structurally allowed:** the two states the estimator carefully distinguishes —
"deliberately scored 0.5" and "never scored" — are collapsed by the surface that
consumes them. The distinction exists in code, is computed correctly, is emitted in
`evidence`, and is dropped before it reaches any reader. Nothing is red anywhere:
schema gate green, estimator green, table green, and the ranking it produces has no
discriminating power over the quadrant it ranks.

This is the inverse of PL-167 ("when a gate demands a shape, the SHIPPED template
must supply it"). PL-167 is right; the shadow is that once the template supplies the
shape, the gate can no longer detect its *absence* — it can only ever confirm the
default it planted. A pre-filled required field converts a gate for presence into a
gate that is structurally incapable of failing.

**Prevention:** the fix is not to empty the template — that would re-break PL-167 and
fail every new inception at creation. It is to make "never deliberately scored"
*measurable* from the file's own history, so the state that is currently invisible
becomes a number someone can be accountable for. Scoring the 13 is the operator's
act, not this task's.

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

### 2026-08-29T13:59:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-624-inception-ranking-carries-no-information.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9d6584b3
- **Timestamp:** 2026-08-29T14:06:52Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T14:06:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
