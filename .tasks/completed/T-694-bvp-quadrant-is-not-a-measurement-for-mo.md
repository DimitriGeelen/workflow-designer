---
id: T-694
name: "BVP quadrant is not a measurement for most of the backlog: one constant driver
  vector covers 10 tasks and no estimator lane exists for an inception's value inputs"
description: >
  This run's mandate selects work by BVP quadrant. Scoring 15 previously-unscored
  agent-owned tasks produced one identical driver vector for 10 of them, and 12 inception
  tasks all sit at exactly 126/0.40/hv-lc -- the top quadrant -- while carrying unedited
  template defaults for voi_score and target_blast_radius. Deliverable: measure how
  much of the active backlog carries a non-distinguishing score, name the mechanism
  in the estimator, and register the finding. The repair is NOT in scope -- it changes
  ranking semantics and is the operator's call.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t694-bvp-distinguishability.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-10T05:38:23Z
last_update: 2026-09-10T05:48:28Z
date_finished: 2026-09-10T05:48:28Z
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
  - ts: '2026-09-10T05:39:48Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 3
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=3 (prose:routing-defect-class); F3=1 
      (prose:AEF seam-incidental); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
---

# T-694: BVP quadrant is not a measurement for most of the backlog: one constant driver vector covers 10 tasks and no estimator lane exists for an inception's value inputs

## Context

Full measurement: `docs/reports/T-694-bvp-distinguishability.md`.
Instrument: `tools/_t694-bvp-distinguishability.py` (has `--self-test`).
Registered: OBS-339 (template floor), OBS-340 (inception tie, urgent).
Repairs filed, not performed: T-695, T-696 — each carries its own Sovereign question.

Filed mid-run, under a mandate that selects work by BVP quadrant, because the quadrant
turned out to rest on a field nobody had set. Validating the instrument that produces a
stop condition is not adjacent to that mandate — it is the evidence for it.

> ### CORRECTION — the name of this task overstates its own finding
>
> The frontmatter `name` says the quadrant *"is not a measurement for **most** of the
> backlog"* and *"one constant driver vector covers **10** tasks."* Both came from
> watching the same numbers scroll past while scoring fifteen tasks by hand. **Measured,
> both are wrong**, and one is wrong in the direction that made the finding look bigger:
>
> - **48 distinct vectors across 73 scored tasks.** That is real discriminating power.
>   "Most of the backlog" is false — the two tied clusters are 24 of 73, 32.9%.
> - The cluster is **12**, not 10. I had only scored 15 tasks; the other two were already
>   in that state.
>
> The name is left as filed rather than rewritten, so the distance between the eye-count
> and the measurement stays visible. It is the same distance this task exists to close,
> and FP-019 says claims drift in the *safe-looking* direction — this one drifted the
> other way, which is worth having on record as a counter-example.
>
> **What survives is narrower and worse than what I claimed:** an empty task file scores
> 4 of 5 on the first constitutional directive, and 12 of 13 inceptions rank at the top
> quadrant on a template default.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Distinguishability is MEASURED across the whole active backlog, by a tool, not by
      hand.** `tools/_t694-bvp-distinguishability.py` reads every task in `.tasks/active/`,
      extracts the latest `bvp_scores_proposed` driver vector from each, and reports: how
      many tasks carry a proposed vector, how many DISTINCT vectors exist among them, and
      the task count behind the modal vector. A hand-tallied claim does not close this —
      I noticed the collision by eye while scoring, and eye-count is exactly the evidence
      standard this task exists to replace.

- [x] **The mechanism is named at a site in the estimator, quoted, not inferred from the
      output.** It is not enough to show that N tasks share a vector; the code path that
      produces the shared vector must be quoted with its file and line. If the modal
      vector turns out to be a legitimate convergence of independent per-driver decisions
      rather than a fall-through default, **this AC fails and says so** — that is the
      result it is written to force.

- [x] **The inception tie is separated from the free-driver collision — two claims, two
      verdicts.** The 12 inceptions at exactly `126 / 0.40 / hv-lc` and the 10 tasks at
      `61 / 0.19` are asserted here as one symptom. Show whether they share a cause. State
      explicitly whether `voi_score` / `target_blast_radius` have any estimator write path
      at all, and if they do not, say so as an absence that was checked rather than an
      absence that was assumed.

- [x] **A negative control proves the tool can report DISTINGUISHABLE.** Plant a task
      carrying a deliberately different driver vector in a throwaway root, re-run, and
      watch the distinct-vector count rise by exactly one. A measuring instrument that has
      only ever printed one verdict has not been shown to have two.

- [x] **The finding is registered somewhere that outlives this task, and the repair is
      NOT performed here.** Register in the observation/concern register (a completed task
      archives and goes invisible; a register entry does not). File the repair as its own
      task(s) carrying the Sovereign question, because changing how value is scored changes
      the ranking of every task in the project and that is the operator's call, not mine.
      **Making the ranking sharper under my own initiative would also be me re-ranking work
      I selected — the producer-not-judge line.**

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
         1. Run `bin/fw reviewer T-694`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-694 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# 1. The instrument can report BOTH verdicts. Watched red on 2026-09-10 against a
#    blinded copy whose vector extractor returned a constant: "expected 2 distinct,
#    got 1 — the instrument cannot see a difference it was handed", rc=1.
python3 tools/_t694-bvp-distinguishability.py --self-test

# 2. It still measures the live backlog, and reports MORE than one vector — i.e. the
#    finding is "two clusters tie", not "the estimator returns a constant". If this
#    ever collapsed to 1 the report's own §0 correction would be wrong.
python3 tools/_t694-bvp-distinguishability.py --json > /tmp/.t694-live.json 2>&1 && python3 -c "import json;d=json.load(open('/tmp/.t694-live.json'));assert d['tasks_scored']>0 and d['distinct_vectors']>1, d"

# 3. The report quotes the estimator rather than paraphrasing it (PL-323). The quoted
#    evidence string must still exist in the source it claims to quote — a paraphrase
#    is a second, unversioned copy that drifts silently because it never looks wrong.
grep -q 'voi-absent-grandfathered' docs/reports/T-694-bvp-distinguishability.md && grep -q 'voi-absent-grandfathered' .agentic-framework/agents/termlink/bvp-estimator/estimator.py

# 4. The bare-template evidence is in the report, named by the estimator's own token.
grep -q 'body:structural-gate' docs/reports/T-694-bvp-distinguishability.md

# 5. DERIVED, not pinned: the inception count the tool measures must equal the count
#    the report asserts. A literal 12 here would stay green while either drifted.
python3 tools/_t694-bvp-distinguishability.py --json > /tmp/.t694-c.json 2>&1 && python3 -c "import json;d=json.load(open('/tmp/.t694-c.json'));n=d['inceptions_voi_still_template_default'];t=open('docs/reports/T-694-bvp-distinguishability.md').read();assert f'{n} of 13' in t, f'tool measures {n}, report does not say so'"

# 6. The repair is filed, not performed: both follow-ups exist and each carries an
#    unticked Sovereign question rather than an agent decision.
grep -q '\[REVIEW\]' .tasks/active/T-695-*.md && grep -q '\[REVIEW\]' .tasks/active/T-696-*.md

# 7. The finding is registered where it outlives this task file.
grep -q 'OBS-339' .context/inbox.yaml && grep -q 'OBS-340' .context/inbox.yaml

## RCA

**Symptom:** Twelve active tasks share one BVP driver vector and twelve inceptions share
another, so a selection rule that works by quadrant cannot order them. Noticed only
because an autonomous run was told to select by quadrant and the top quadrant filled up
with tasks nobody had assessed.

**Root cause:** Two independent ones, filed separately as T-695 and T-696.
(a) The estimator matches driver rubrics against the whole task-file body, and the
shipped template's instructional comments talk about gates, defaults and environment
classes — so the template scores itself. Measured floor: `D1=4 D2=0 D3=2 D4=2`.
(b) The template ships `voi_score: 0.5` pre-filled; `int(round(0.5*5))` is 2, and the
grandfathered path for an absent `voi_score` also returns 2, so *unassessed* and
*judged-mid* are indistinguishable in the output.

**Why structurally allowed:** Both are presence-gates passing on template content.
PL-266 already names the class — *a pre-filled required field converts a gate for
presence into a gate that cannot fail* — and it was captured under T-624 before this.
The reason it recurred is that nothing checks a scoring instrument against a **null
input**. Every check on the estimator to date asks whether it produces a plausible score
for a real task. None asked what it produces for no task. A meter is calibrated by
reading zero, and this one had never been shown zero.

**Prevention:** `tools/_t694-bvp-distinguishability.py --self-test` asserts the
instrument can report DISTINGUISHABLE, and was watched red against a blinded copy
(rc=1, "the instrument cannot see a difference it was handed"). That prevents the
*measurement* from silently going blind. It does **not** prevent recurrence of the
underlying defects — that needs the repairs in T-695/T-696, which are operator-gated.
Recording the distinction rather than claiming prevention: mitigation is not prevention.

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
     fw inception decide T-694 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-10T05:38:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-694-bvp-quadrant-is-not-a-measurement-for-mo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0d6699a6
- **Timestamp:** 2026-09-10T05:48:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-10T05:48:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
