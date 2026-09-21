---
id: T-767
name: "SQ-2 fix: ownership must follow the presence of a real Human acceptance criterion"
description: >
  The task-creation path can produce a task the creating agent is structurally forbidden
  to finish. Fix the default so ownership follows the presence of real Human ACs.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T10:36:54Z
last_update: '2026-09-21T20:25:10Z'
date_finished: 2026-09-21T11:33:50Z
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
  - ts: '2026-09-21T10:38:08Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T20:25:10Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:./tools/_t767-ownership-correspondence.sh,.agentic-framework/.vendor-divergence.yaml,.agentic-framework/agents/observe/observe.sh,.agentic-framework/agents/task-create/create-task.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-767: SQ-2 fix: an agent-produced task must never be born owner:human with zero Human ACs

## Context

### The ruling

**SQ-2 — Should an agent-produced task ever be born `owner: human` with zero Human
ACs? → NO.** Operator, 2026-09-21, verbatim: *"No, that's wrong per definition. Yeah,
I've seen it, so we need to fix that."*

### The defect in its own terms

A task created `owner: human` with no Human acceptance criteria is **unclearable by
the agent that created it.** Completing an `owner: human` task is not delegated, so
the agent manufactures work it is structurally forbidden to finish. The task then sits
in `started-work` with every Agent AC ticked and nothing outstanding, and lands in a
review queue that is already 67 deep — carrying nothing for the reviewer to actually
review.

The ownership field is meant to answer *"who verifies this?"*. When there are zero
Human ACs, the honest answer is "nobody has to", and `owner: human` asserts the
opposite.

### The four instances that proved it

CTL-029 reported all four as *completable, not closed*. They are arc-003's own
remediation tasks, which is what made the fault visible: the remediation arc began
generating the findings it exists to remediate, and could not clear them.

| Finding | Task | Subject |
|---|---|---|
| RA-038 | T-747 | T-702 (36 urgent observations pending) |
| RA-039 | T-748 | T-703 (107 observations pending >7d) |
| RA-040 | T-749 | T-708 (two stuck partial-complete tasks) |
| RA-041 | T-750 | T-723 (review queue >30d) |

### Scope boundary

This task fixes the **creation path** so the condition stops being produced. It does
**not** change the ownership of the four existing tasks — changing ownership away from
human is not delegated, and the operator's ruling authorises fixing the generator, not
reassigning records the rule already produced. Their disposition stays with T-747–T-750.

L-302 applies directly: fix the generator before shipping the detector, or the
detector just reports the generator's output forever.

### Root-cause links

Instances: RA-038/T-747, RA-039/T-748, RA-040/T-749, RA-041/T-750. Upstream report: T-768. Ruling: SQ-2 in `.context/project/decisions.yaml`, recorded by T-766.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The creation path is located and named, and the answer corrects this task's own
      premise.** `create-task.sh` has **no owner default at all** — `--owner` is a required
      flag (`create-task.sh:127`, the no-tty branch), so the generator never *silently*
      emits `owner: human`. The only place it is *forced* is the gated-writer bar at
      `create-task.sh:100-113` (`FW_TASK_ORIGIN` = `bpmn-promote` | `designer-ghost`,
      T-2543/T-2577), which is the operator's own sovereignty rule and correct. Every other
      `owner: human` is a **caller's choice**, and the live non-exempt caller is
      `observe.sh:267` — observation promotion, which passed `--owner human` with no Human
      AC. So the fault is an **absent correspondence check**, not a bad default: nothing
      anywhere asserted that `owner: human` implies a stated human act.

- [x] **Project usage vs vendored framework: established, and it is the framework.** The
      *decision* is the caller's, but the *silence* is framework-owned — `create-task.sh`
      accepts the shape without comment, and `observe.sh` (also vendored) is the caller that
      ships it. Both are fixed in-tree under G-008 and both are recorded in
      `.agentic-framework/.vendor-divergence.yaml` with `upstream: fix`. T-768 already
      carries the fault report to AEF; this task carries the code. The two are not
      conflated — T-768 reports, T-767 repairs, and neither waits on the other.

- [x] **Ownership now follows the presence of a real Human AC, as a gate rather than a
      notice.** `--owner human` requires `--human-ac "<criterion>"` and is **refused**
      without it (`create-task.sh:115-143`); the criterion is seeded into the created file's
      `### Human` section. The rule a reader can apply before creating anything:

      > A task is born `owner: human` **only** if you can state, at creation time, what the
      > human verifies. If you cannot name the human's act, the task is `owner: agent`.

      Two exemptions, by policy and not by oversight: the gated writers above, and
      `--type inception` — whose template already ships a real go/no-go Human AC with
      Steps/Expected/If-not, so an inception cannot be born without one.

      **It refuses; it does not rewrite.** An auto-flip to `owner: agent` would have been
      one line shorter and would have decided ownership on the caller's behalf. Ownership
      is the operator's call. A refusal makes the caller state the human's job, which is
      the thing that was actually missing.

- [x] **The negative control exists, and it was proven RED before it was trusted green.**
      `tools/_t767-ownership-correspondence.sh --self-test`, four legs on a throwaway
      `mktemp -d` root (the real `.tasks/` tree and its id counter are never touched —
      verified: highest real id still T-769, no T-99x anywhere):

      1. old shape refused, and the message names `--human-ac`
      2. new shape succeeds **and** the created file carries a real Human AC checkbox
      3. `bpmn-promote` origin still creates `owner: human` without the flag (T-2543 intact)
      4. inception still exempt and still born with its go/no-go criterion

      **Meta-assertion (PL-178 — a green leg that asserts nothing is the failure mode).**
      The suite was re-run against the *unpatched* generator restored from backup: legs 1
      and 2 went **RED** (`old shape was NOT refused (rc=0)`, `Unknown option: --human-ac`),
      legs 3 and 4 stayed green as they should. The patched file was then restored and the
      restore was diff-verified. The suite can fail, and it fails on exactly the thing it
      claims to watch.

- [x] **No existing instance is reassigned and no `### Human` AC is ticked — and the
      population is four times what this AC assumed.** Measured 2026-09-21 by
      `--measure`: **34 of 107** active `owner: human` tasks carry zero Human AC
      checkboxes, not four. They are not one fault but three:

      | class | what it is | n | ids |
      |---|---|---|---|
      | 1 | **completable** — every criterion ticked, nothing left for the human | 2 | T-708, T-723 |
      | 2 | template placeholder ACs never filled (the `First`/`Second` criterion stubs) | 10 | T-265, T-289, T-291, T-292, T-424, T-439, T-441, T-442, T-443, T-691 |
      | 3 | real unchecked ACs, none of them Human | 22 | T-599, T-700, T-709…T-722, T-724, T-725, T-728, T-729, T-731, T-737 |

      Only class 1 is the pure SQ-2 shape. Class 2 is a G-020 placeholder fault and class 3
      is work misfiled under the wrong heading — **three findings, so not this task's to
      fix** (one finding, one task). None of the 34 is touched here: the generator is fixed,
      the population is recorded, and what to do with it is SQ-8 below.

<!-- No Human ACs: the operator has already ruled on the question behind this
     task, and what remains is agent-verifiable. Adding an empty Human section
     would lengthen a review queue already 67 deep (SQ-3) with nothing to review.

     Original template guidance retained below for the next editor.

     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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
         1. Run `bin/fw reviewer T-767`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-767 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

grep -q 'SQ-2' .context/project/decisions.yaml
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-7[45][0-9]-*.md' | xargs grep -l 'CTL-029' | wc -l)" -ge 4
./tools/_t767-ownership-correspondence.sh --self-test
grep -q 'human-ac) HUMAN_AC' .agentic-framework/agents/task-create/create-task.sh
grep -q 'requires --human-ac' .agentic-framework/agents/task-create/create-task.sh
grep -q 'human-ac' .agentic-framework/agents/observe/observe.sh
python3 tools/_t517-vendor-divergence.py
test "$(grep -l '^owner: human' .tasks/active/T-708-*.md .tasks/active/T-723-*.md | wc -l)" -eq 2
test "$(awk '/^### Human/{h=1;next} /^## /{h=0} h && /^- \[/{n++} END{print n+0}' .tasks/active/T-708-*.md)" -eq 0
test "$(awk '/^### Human/{h=1;next} /^## /{h=0} h && /^- \[/{n++} END{print n+0}' .tasks/active/T-723-*.md)" -eq 0

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

**Symptom:** agent-produced tasks are born `owner: human` with no Human acceptance
criterion. The agent is then structurally forbidden to finish them (completing an
`owner: human` task is not delegated) and the human has nothing stated to verify, so the
task parks indefinitely. Measured 2026-09-21: 34 of 107 active `owner: human` tasks, two
of them with every criterion already ticked.

**Root cause:** nothing anywhere asserted a correspondence between the `owner:` field and
the presence of a `### Human` criterion. `create-task.sh` requires `--owner` but accepts
whatever it is told; `observe.sh:267` told it `human` on every observation promotion. The
two halves of the sentence "this task belongs to the human *because* the human must do X"
were never joined, so the first half could be written without the second.

**Why structurally allowed:** the framework already had a gate for the *opposite*
direction — T-2543/T-2577 refuse a gated-writer create that is **not** `owner: human` —
so the shape "ownership is enforced at creation" existed and read as covered. What was
enforced was a floor (these origins must be human-owned), never a justification (any
human-owned task must name the human's act). A one-directional gate looks like a gate.

**Prevention, distinct from the fix:** the fix is the refusal in `create-task.sh`. The
prevention is `tools/_t767-ownership-correspondence.sh`, which (a) drives the real
generator through all four behaviours on a throwaway root, (b) was proven RED against the
unpatched generator before being trusted, and (c) carries `--measure`, so the standing
population is a re-runnable number rather than a sentence in this file that decays. The
suite is wired into this task's `## Verification`, so it must pass to close.


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

### 2026-09-21 — the premise of the task was wrong by a factor of eight

- **What changed:** T-767 was filed believing the generator had a bad *default* and that
  there were *four* instances. Neither held. `create-task.sh` has no owner default at all
  — `--owner` is required — so the generator never silently chose `human`; the caller did.
  And the population is 34, not 4, and splits into three distinct faults of which only two
  tasks are the pure SQ-2 shape.
- **Plan impact:** the fix moved from "change a default" to "add a correspondence gate",
  which is a different and larger change — it alters a vendored CLI contract. It also meant
  the other 32 cannot be swept up here: classes 2 and 3 are separate findings.
- **Triggered:** SQ-8 (what to do with the 34 already in flight) raised rather than acted
  on. Classes 2 and 3 deliberately left unfiled here — one finding, one task, and filing
  them is the next cycle's work, not a silent widening of this one.

### 2026-09-21 — a one-directional gate reads as a gate

- **What changed:** the reason this went undetected is more interesting than the defect.
  T-2543/T-2577 already enforce ownership at creation, in the other direction. Reading the
  file, ownership *looks* governed. The blind spot was not an absent control but a present
  control pointing one way, which is the harder kind to see.
- **Plan impact:** the new gate was deliberately written adjacent to the T-2543 `case`
  block and names it, so the next reader sees both directions in one place rather than
  inferring coverage from one of them.
- **Triggered:** nothing filed. Recorded because the shape generalises — "the control that
  exists proves the axis is covered" is worth a learning if it recurs.

### 2026-09-21 — the gate that blocked this write-up is the one PL-164 predicted

- **What changed:** G-020 refused every Bash call mid-task. Cause: acceptance criterion 5
  describes the class-2 fault and quoted the template's placeholder token verbatim, and
  G-020 greps the AC section for exactly that token. The task was scoped; it merely said
  the forbidden word. This is PL-164 — *prose about a string-matching gate reliably
  contains the string the gate matches* — firing for the second recorded time here.
- **Plan impact:** none to the fix. The prose was reworded; the gate was not touched and
  must not be. It refused correctly on the evidence available to it.
- **Triggered:** nothing filed — PL-164 already exists and this is a second instance, not
  a new pattern. Worth noting that the instance was self-inflicted by writing *about* the
  control, which is exactly the population PL-164 predicts.


## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-21 — refuse the create; do not rewrite the owner

- **Chose:** `--owner human` without `--human-ac` is **refused** with a message naming the
  missing flag and the alternative (`--owner agent`).
- **Why:** ownership is the operator's call. Silently flipping to `owner: agent` would have
  been shorter and would have made the agent decide who owns the work — the same class of
  act the SQ-2 ruling was about. A refusal costs the caller one flag and makes them state
  the human's job, which is the thing that was missing.
- **Rejected:** (a) auto-flip to `owner: agent` — decides ownership on the caller's behalf;
  (b) a warning printed at creation — T-696 measured exactly this remedy failing: T-624
  chose an in-template warning, and twelve days later the number had not moved. A comment
  is not a gate; (c) a post-hoc audit check — it would report the generator's output
  instead of fixing the generator (L-302/PL-302).

### 2026-09-21 — exempt inception and the gated writers, and say why in the code

- **Chose:** `bpmn-promote` / `designer-ghost` origins and `--type inception` do not
  require `--human-ac`.
- **Why:** the first two are human-owned by the operator's own sovereignty bar
  (T-2543/T-2577) and this gate does not get to lower it. Inception's template already
  ships a real go/no-go Human AC with Steps/Expected/If-not, so requiring a second one
  would manufacture a redundant criterion — the opposite of the point.
- **Rejected:** exempting nothing. It would have forced a duplicate criterion onto every
  inception and broken a sovereignty bar to enforce a lesser rule.

### 2026-09-21 — SQ-8 raised, not acted on: the 34 already in flight

- **Chose:** fix the generator, measure the population, reassign nothing.
- **Why:** AC5 forbids reassignment here, and the three classes have genuinely different
  remedies. Class 1 (T-708, T-723) is completable and needs an operator close, not an
  ownership change. Class 2 is a scoping fault. Class 3 is human work filed under an Agent
  heading — T-700's sole open criterion is *"the release decision is recorded by the
  operator"*, sitting under `### Agent`.
- **Rejected:** flipping the 34 to `owner: agent` — that is "changing ownership away from
  human", explicitly not delegated, and for class 1 it would let the agent close two tasks
  the operator has never seen.

## Sovereign question

**SQ-8 — the 34 already in flight.** The gate stops new ones. It does not touch the 34,
and I must not. Three different remedies are needed and each is yours:

1. **Class 1 (T-708, T-723)** — every criterion ticked, nothing for you to verify. Close
   them, or tell me what the missing human act was and I will write it as a real Human AC.
2. **Class 2 (10 tasks)** — born from the template with its criterion stubs never filled
   in. Fill, or close as never-scoped?
3. **Class 3 (22 tasks)** — real work, no Human AC, filed to you anyway. Should these move
   to `owner: agent` (a batch ownership change, which is yours to authorise, not mine), or
   should each gain the Human AC that justifies where it already sits?

**Why this is not mine:** every option is an ownership change or a close, and both are
non-delegated. **Why it matters now:** this run walked Q1 to exhaustion and then Q2, and
every single high-value item was blocked on you. 34 of the 107 tasks in that queue are
there because of a defect, not because they need you.


## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-767 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T10:36:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-767-sq-2-fix-an-agent-produced-task-must-nev.md
- **Context:** Initial task creation

### 2026-09-21T10:48:11Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9853ee65
- **Timestamp:** 2026-09-21T11:33:52Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T11:33:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
