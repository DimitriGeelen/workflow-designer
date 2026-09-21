---
id: T-777
name: "Autonomous selection is structurally blocked: every high-value task is human-owned
  or gate-blocked, and cost is unmeasurable before execution"
description: >
  Autonomous selection is structurally blocked: every high-value task is human-owned
  or gate-blocked, and cost is unmeasurable before execution

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T15:12:15Z
last_update: '2026-09-21T20:25:10Z'
date_finished: 2026-09-21T15:17:02Z
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
  - ts: '2026-09-21T15:13:20Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 3
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=3 
      (prose:routing-defect-class); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T15:13:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-21T20:25:10Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/inbox.yaml,.context/project/concerns.yaml,.fabric/components/tools-_t777-selection-eligibility-census.yaml,tools/_t777-selection-eligibility-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-777: Autonomous selection is structurally blocked: every high-value task is human-owned or gate-blocked, and cost is unmeasurable before execution

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The eligibility census is reproducible, not a narrative.**
      `tools/_t777-selection-eligibility-census.py`, fabric-registered. It enumerates every
      active task, classifies it against the predicate autonomous selection actually needs,
      and joins the result to the scorer's own quadrant output — so the numbers below can be
      re-derived rather than trusted.

      Five refusal classes, kept separate because they have different owners and different
      remedies: `owner-human`, `no-open-ac`, `placeholder`, `ac-blocked`, `verb-gated`. The
      last is the quiet one — the task looks workable and its ACs look ordinary, and the
      block only appears when you read what the criterion asks you to RUN.

- [x] **The blocking claim is stated as a measurement with a negative control.**

      ```
      active tasks                      : 150
      placed in a high-value quadrant   : 31
      of those, agent-executable        : 0
      agent-executable overall          : 22
      ...but outside every hv quadrant  : 22
      ```

      The 31 resolve as **27 `owner: human`**, **3 agent-owned with every open AC marked
      BLOCKED** (T-341, T-358, T-696 — each established by a prior session as downstream of
      a Human ruling), and **1 verb-gated** (T-155, whose remaining criterion requires
      `fw inception decide`).

      **The control.** A census whose predicate rejected everything would print the same
      headline. It prints instead that the executable set is **non-empty at 22**, so the
      predicate demonstrably admits work and the zero is a measurement rather than an
      artefact of an over-strict filter. The script refuses to report a headline at all if
      the executable set is empty — it exits 2 with `INCONCLUSIVE` and says the result is
      unmeasured.

      `--self-test`: **8 fixtures, 8 pass**, one per refusal class plus **two that must
      classify as EXECUTABLE** — including a task that names `fw inception decide` in its
      RCA prose but not in any criterion, which must NOT be called gated.

- [x] **The cost circularity is demonstrated, not asserted.**

      ```
      estimator on an unstarted task        : blast_radius=absent (no-signal)
      active tasks with non-empty components: 7 of 149
      active tasks with no quadrant at all  : 106 of 150
      ```

      F8 is `0.6*blast_radius + 0.3*tier + 0.1*effort`; `blast_radius` comes from
      `components:`; `components:` is resolved **from git history at completion** — observed
      live four times today, emitted by `fw task update --status work-completed`.

      **Demonstrated on this task.** T-777 was scored through the estimator before execution,
      exactly as the mandate requires, and returned `tier=2 effort=8 blast_radius=absent`
      — BVP 100, quadrant `-`. The task documenting the circularity reproduced it on itself.

      The consequence is sharper than "some tasks lack a quadrant": the 31 that HAVE one are
      not the most valuable 31, they are the ones that happened to accumulate components.
      Quadrant-ordered selection is ordering a biased sample, and nothing says so at the
      point of use. Registered as **G-073**.

- [x] **Each blocker is registered where an instrument can see it.**

      - **G-072** — the value ranker has no notion of executability, so quadrant-ordered
        selection is guaranteed to select unworkable tasks. Closure explicitly excludes
        re-owning tasks: that would change the backlog to fit the instrument.
      - **G-073** — cost is only computable after completion. Closure requires a quadrant
        assigned to a task with zero commits.
      - **OBS-366 (urgent)** — the `fw` MCP surface resolves against a **different project**.
      - **OBS-367 (urgent)** — there is no Sovereign-question register at all; SQ-9 exists
        only as prose inside two gap entries and an episodic, which is PL-145 firing on the
        SQ mechanism itself.

- [x] **Nothing here is presented as a ruling.** No quadrant was re-derived, no BVP
      adjusted, no task re-owned, no gate routed around. Where a gate refused me — G-020 on
      the scorer, P-002 on a foreign-focus commit, the `--i-am-human` boundary, the
      `fw inception decide` boundary — the refusal is recorded as a finding and the work
      stopped there.

      The run's actual result is that **the gates held and the backlog was honestly
      unavailable**, which is a different outcome from "found nothing to do" and is worth
      distinguishing: an autonomous run that manufactured low-value work to look productive
      would have produced more commits and less information.

- [x] **The gap ids were checked for collision before use.** G-062..G-071 are all vendored
      AEF ids already cited in this tree; G-072 and G-073 were chosen by the zero-reference
      scan recorded in G-061's `id_note`.

      **This is the third consecutive task to need that scan** (G-055 first, G-061 second).
      Recorded in G-072's `id_note` as recurrence evidence rather than stepped around a third
      time in silence — three independent incidents is no longer a tidiness concern, and
      SQ-9 still has no containment beyond a documented workaround.

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
         1. Run `bin/fw reviewer T-777`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-777 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 tools/_t777-selection-eligibility-census.py --self-test
python3 tools/_t777-selection-eligibility-census.py --brief
python3 -c "import yaml; c=yaml.safe_load(open('.context/project/concerns.yaml'))['concerns']; ids={x['id'] for x in c if isinstance(x,dict)}; assert {'G-072','G-073'} <= ids, 'gaps missing'"
grep -q 'OBS-366' .context/inbox.yaml
grep -q 'OBS-367' .context/inbox.yaml
test -f .fabric/components/tools-_t777-selection-eligibility-census.yaml

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

**Symptom:** an autonomous run directed to select work top-down by BVP quadrant had no legal
move. Every one of the 31 high-value tasks was refused by a gate that was working correctly.

**Root cause:** two independent instrument gaps, neither of which is visible from the ranking
the run is told to consult.

1. **G-072 — the ranker cannot see executability.** `fw bvp` answers "what is most
   valuable?". Nothing answers "what can an agent legally execute?". 27 of the 31 are
   `owner: human`, which may be entirely correct — they are ratifications, taste judgements
   and scope decisions — but the instrument used to order autonomous work cannot see that
   property, so it can neither route around it nor report it.
2. **G-073 — cost is computed from an input that only exists after completion.** So the
   quadrant axis cannot order unstarted work, and the subset that does carry a quadrant is
   selected by "has accumulated components", not by anything meaningful.

**Why this went unnoticed until an autonomous run:** interactively, the operator names the
task and neither gap is in the path. The quadrant discipline is only load-bearing when
nobody is choosing, and that is exactly when nothing reports that it is not working.

**Why it is silent:** each refusal is individually correct and individually legible. G-020
blocks an unscoped build, P-002 blocks a commit under foreign focus, the sovereignty
boundary blocks `--i-am-human`. Read one at a time they are a working governance system.
Only the census makes the totality visible, and before this task nothing computed it.

**A near-miss worth recording separately.** The first ranking I pulled came from the `fw` MCP
surface and listed another project's backlog — CashWeb, Ecwid, Azure DevOps. It was caught
because the ids contradicted the filesystem I had read directly this session, not because any
check flagged it. Had the run begun by trusting that ranking, it would have selected and
executed another project's tasks, and the id collision (foreign `T-041` vs local `T-041`)
would have made the mistake look ordinary for some time. OBS-366, urgent.

**Prevention:** the census, runnable from any task's `## Verification`. It is an instrument,
not a gate — nothing runs it before a selection, and saying that plainly is the point:
G-072's closure condition requires executability to reach the ranking itself, which is where
a selecting agent actually looks.

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
     fw inception decide T-777 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T15:12:15Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-777-autonomous-selection-is-structurally-blo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ef184bb2
- **Timestamp:** 2026-09-21T15:17:25Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T15:17:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
