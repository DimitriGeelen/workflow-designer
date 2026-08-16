---
id: T-428
name: "Assumption register never reconciles with owning task completion"
description: >
  Assumption register never reconciles with owning task completion

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
created: 2026-08-11T13:02:18Z
last_update: '2026-08-16T12:33:58Z'
date_finished: 2026-08-11T13:11:59Z
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
  - ts: '2026-08-16T12:33:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-428: Assumption register never reconciles with owning task completion

## Context

OBS-018 recorded one instance: A-020 was answered NO on the rail on 2026-08-03, recorded in
T-357's Open Questions, and the assumption register still read `untested` seven days later —
long enough that I filed a build task (T-425) on the strength of the stale register.

That was treated as a one-off reconciliation miss. It is not. Measured today:

| | count |
|---|---|
| assumptions still `untested` | 16 |
| of those, whose `linked_task` is **completed** | **16** |
| distinct completed owning tasks | 5 (T-020, T-038, T-142, T-175, T-201) |
| rows with `validation_method: TBD` | **20 of 20** — including all four disposed ones |

Every untested assumption in this project belongs to a task that is closed. The register is
asserting sixteen live open questions that no task owns and no gate will ever raise again.
A-020 was not the register being slow; A-020 is the only one that ever got answered at all,
and it got answered because a human asked on the rail, not because anything checked.

Three of the sixteen — **A-012, A-013, A-014** — belong to **T-175**, the anchor task of
`arc-designer-authoring-surface`. The arc's three foundational assumptions read `untested`
with `evidence: []` while their anchor sits in `completed/`.

Related shapes already registered: PL-114 (competing carriers for one fact), PL-127 (a schema
whose field names are obviously right is where silent inertness hides — `validation_method`
is 20/20 TBD), PL-145 (a ruling filed in prose does not reach the register that indexes it).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_t428-assumption-disposition-check.py` classifies every row of the live register
      into exactly one verdict: `dangling` (untested + owning task completed), `live`
      (untested + owning task still active), `disposed` (validated/invalidated **with**
      evidence), `unevidenced` (validated/invalidated with `evidence: []`), `orphan`
      (`linked_task` resolves to no task file)
- [x] The instrument is run against the live register and its verdict recorded in
      `## Findings`: 16 dangling / 0 live / 4 disposed / 0 unevidenced / 0 orphan
- [x] **The printed remedy never offers a status flip.** `fw assumption validate A-XXX` as a
      remedy is the dismissal ritual OBS-017 names: it clears the finding without producing
      the evidence the finding is about. Asserted mechanically — the check's own output is
      grepped for the laundering shape and the assertion fails if it appears
- [x] Mutation check `tools/_t428-disposition-mutation-check.sh` proves the instrument fails
      when it should: a scratch fixture carrying one row of **each** verdict, asserted in a
      single register so an implementation returning a constant per-file cannot pass
- [x] Ambiguity fails **loud**, never silent: unparseable register or missing tasks dir exits
      2 (cannot answer), which must not read the same as exit 0 (nothing found)
- [x] **No assumption status is flipped under agent initiative.** Disposing of an assumption
      is an evidence claim; this task builds the instrument and reports what it found. The
      register is byte-unchanged by this task — asserted in `## Verification`
- [x] The `validation_method` inertness census (20/20 `TBD`) is registered as its own
      observation — it is a register-design finding, not a per-row defect, and folding it
      into the dangling count would hide it

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

## Findings

`python3 tools/_t428-assumption-disposition-check.py` against the live register, 2026-08-11:

```
  dangling     16
  live          0
  disposed      4
  unevidenced   0
  orphan        0

  validation_method still 'TBD': 20 of 20
```

**`live` is zero.** That is the finding, not the 16. A register with sixteen untested
assumptions and a healthy number of live ones would be a project asking questions faster
than it answers them — normal. Sixteen untested and *none* owned by an open task means the
register has no live end at all: every question in it was asked by a task that has since
closed, and the closing never asked what happened to the question.

Distribution — and every one of these tasks passed the completion gate:

| owning task | dangling | state |
|---|---|---|
| T-020 | 3 | completed |
| T-038 | 4 | completed |
| T-142 | 4 | completed |
| T-175 | 3 | completed — **anchor of `arc-designer-authoring-surface`** |
| T-201 | 2 | completed |

### The three arc ones are worse than dangling

**13 of the 16 are mentioned nowhere in the repository outside the register itself** —
not in their owning task, not in a report, not in a decision. Measured by grepping every
assumption ID across `.tasks/`, `docs/` and `.context/project/`.

A-012, A-013 and A-014 are in that thirteen. They are T-175's, and T-175 is the arc anchor.
Its own body says what was supposed to happen to two of the others:

> 2. **Joint design pass with the AEF agent (IN FLIGHT)** — thread T-175 (DM offset 19).
>    Validate A-002/A-003.

Marked IN FLIGHT, in a task that is now in `completed/`. The only surviving mentions of
A-001..A-003 anywhere are *plans to validate them*. Nothing records whether the joint design
pass answered anything.

### This was already noticed once, and noticing did nothing

`T-425` contains the sentence, written before this task existed:

> 16 of 20 assumptions read `untested`, the oldest (`A-001`, `T-020`) since …

The count was correct and visible six days ago. It produced no task, no gate and no change,
because an observation written into the body of a task about something else is indexed by
nothing. That is the same carrier failure the finding is about, one level up: PL-145 says a
ruling filed in prose does not reach the register; this says a *measurement* filed in prose
does not reach anything either.

### What this task deliberately does not do

It disposes of none of them. Sixteen dispositions is sixteen evidence claims, and at least
three (A-012/A-013/A-014) are seam questions that cannot be answered from inside 832 at all
— they are about what AEF's model can receive. Flipping them would be the exact laundering
this instrument is built to refuse to print as a remedy. The arc-relevant three go to AEF on
the rail; the rest need a disposition pass with its own task.

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

# The mutation suite is the real gate: it proves the classifier can still discriminate.
bash tools/_t428-disposition-mutation-check.sh

# AC#6 — this task must not have flipped an assumption status. Byte-level, not a count.
git diff --quiet HEAD -- .context/project/assumptions.yaml

# The live register must stay ANSWERABLE. Exit 1 (findings) and exit 0 (all disposed) are
# both fine and both may become true later; exit 2 is not. No count is pinned here on
# purpose (PL-061) — pinning 16 would make a legitimate disposition look like a regression.
python3 tools/_t428-assumption-disposition-check.py > /tmp/.t428-verify.out 2>&1; test $? -ne 2

# OBS-017 guard, asserted against the LIVE run rather than only the fixture: the report
# must never hand the reader a command that clears the finding without answering it.
#
# NOT `grep -c ... | grep -qx 0` (the first draft, rejected by this gate on 2026-08-11).
# `grep -c` exits 1 when the count is ZERO — it reports "no lines selected" regardless of
# having printed a perfectly good "0" — so under P-011's `-o pipefail` that pipeline fails
# EXACTLY WHEN THE ANSWER IS THE GOOD ONE. An interactive dry-run passes (no pipefail) and
# the gate fails, which is the worst way round to discover it. Same family as L-387, new
# member: L-387 is `cmd | grep -q` dying on SIGPIPE, this is a COUNT whose exit code
# contradicts its own stdout. Rule: never put `grep -c` in a pipeline whose exit code is
# the verdict.
#
# `test -s` first so a missing file FAILS. Bare `! grep -q` on an absent file exits 2,
# which `!` would flip to 0 — a silent pass on nothing having been measured.
test -s /tmp/.t428-verify.out && ! grep -qiE 'run:? *(bin/)?(\.agentic-framework/bin/)?fw assumption validate' /tmp/.t428-verify.out

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

**Symptom:** the assumption register asserts 16 untested assumptions. All 16 belong to tasks
in `completed/`. 13 of them are mentioned nowhere in the repository outside the register.
Acting on one of these stale rows (A-020) produced a whole build task, T-425.

**Root cause:** *an assumption is registered BY a task but is not owned BY it in any way the
completion path can see.* `fw task update --status work-completed` runs P-010 (agent ACs),
P-011 (verification commands), the RCA gate, the Evolution gate, generates an episodic and
captures decisions — and never reads `assumptions.yaml`. `linked_task` is a field the
register keeps and the gate does not consult. So the tie between an assumption and its owner
is one-directional: the assumption knows about the task, and nothing ever asks the reverse.

**Why structurally allowed:** every gate on the completion path asks *"did this task finish
what it said it would do?"* — ACs, verification, RCA, evolution, all internal to the task
file. None asks *"what did this task leave behind that outlives it?"* An assumption is
precisely such a residue: it is created to be answered later, and later is exactly when the
creating task is gone. Six days ago T-425's body recorded the count correctly and it changed
nothing, because a measurement written in prose is indexed by nothing — the same carrier
failure one level up.

**Prevention — partial, and stated as partial (G-019).** What exists now is an instrument
(`tools/_t428-assumption-disposition-check.py`) and a suite that proves it can still
discriminate (16 legs, three mutations). That is *detection built*, not *detection wired*:
nothing runs it on its own, so today this is mitigation. The gap does not close here.

The wiring is deliberately not done under agent initiative, for a measured reason. The
natural home is the audit — and this project's audit already carries designer-specific
checks (`audit.sh:1982`, "Designer ghost registry"), which means the check belongs
**upstream**, in AEF's audit, not in a local edit to a vendored file. Adding it here would be
the fork AEF warned against at DM 522 §1 and that T-422 was withdrawn over. The alternative
home, a Stop hook, is the same registration decision already open under T-426 — and OBS-014
(hook-enable has no inverse) plus OBS-015 (registrations are snapshotted at session start)
make that a decision with real cost, not a formality. Reported to AEF with the instrument as
a reference implementation; the ask is a check on their side, not our bytes on their disk.

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

### 2026-08-11T13:02:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-428-assumption-register-never-reconciles-wit.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ca034fd4
- **Timestamp:** 2026-08-11T13:12:02Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-11T13:11:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
