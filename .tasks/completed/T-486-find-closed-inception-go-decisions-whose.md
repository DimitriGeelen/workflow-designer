---
id: T-486
name: "Find closed inception GO decisions whose build slices were never created (mirror
  of AEF T-2925)"
description: >
  Find closed inception GO decisions whose build slices were never created (mirror
  of AEF T-2925)

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
created: 2026-08-13T07:28:06Z
last_update: '2026-08-16T14:33:41Z'
date_finished: 2026-08-13T07:30:52Z
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
  - ts: '2026-08-16T12:34:02Z'
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
  - ts: '2026-08-16T14:33:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/_t486-orphaned-go-scan.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:tools/_t486-orphaned-go-scan.py); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-486: Find closed inception GO decisions whose build slices were never created (mirror of AEF T-2925)

## Context

AEF at rail 601 §1 found their T-2925 closed as an inception with a GO **whose build slices
were never created** — so the generator they diagnosed is byte-identical to the diagnosis,
and their 597 §3 was a symptom report against their own unbuilt fix. Their stated cause:
*"a closed task archives and stops being visible, and the gap went with it. The GO felt like
the finish because the decision was the deliverable of the task in front of me."*

We run the identical rule (CLAUDE.md: gaps persist in the register, completed tasks archive
and become invisible) and the identical inception lifecycle, in which `fw inception decide
T-XXX go` is the closing act. I told AEF at 602 that I had no structural reason to think we
are better at this than they were, and that it warranted a check here rather than a comment
on their tree. This is that check.

The failure is specifically NOT "an inception that decided NO-GO" (nothing owed) or "a GO
whose build tasks exist and are open" (visible, tracked). It is a GO with **no successor
task at all** — the decision recorded, the work authorised, and nothing carrying it.

## Acceptance Criteria

### Agent
- [x] AC1 — Enumerate every completed inception task and its recorded decision, measured
      from the task files rather than recalled. Denominator stated (PL-084): how many
      completed inceptions, how many GO, how many NO-GO/DEFER/absent.
- [x] AC2 — For each GO, determine whether a successor task exists — by reference in either
      direction (the inception naming a follow-up, or any task naming the inception).
      Classification is by SEARCH over the task corpus, not by reading the inception's own
      prose claim that follow-ups were filed. A task file asserting "filed as T-NNN" is a
      claim; the existence of T-NNN is the evidence.
- [x] AC3 — Each GO classified CARRIED (successor exists) / ORPHANED (no successor found) /
      SELF-CONTAINED (the inception's own deliverable was the artefact, so no build slice was
      ever owed) with the reason. SELF-CONTAINED must be justified per instance, not used as
      a catch-all for anything inconvenient.
- [x] AC4 — Any ORPHANED GO is registered as an observation with the specific unbuilt thing
      named, and filed as its own task if the work is still wanted. Not built here.
- [x] AC5 — The result is reported whichever way it comes out, with its denominator. Zero
      orphans is a real answer and is reported as one — this task settles the question,
      it does not need to find a defect. If zero, the structural reason we are protected
      is stated, since AEF was not.
- [x] AC6 — Read-only: `git diff` empty on `src/`, `tools/`, `docs/standards/`,
      `examples/`, `tests/fixtures/`, `.agentic-framework/`.

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

### AC1/AC2/AC3 — 18 GO decisions, 18 carried, zero orphaned

    inception tasks (completed + active)   36
      GO                                   18
      NO-GO                                15
      DEFER                                 3
    GO decisions with >=1 referencing task                18/18
    GO decisions with >=1 IMPLEMENTATION successor        18/18
      (workflow_type in build / test / refactor / decommission)
    ORPHANED (GO, no successor carrying the work)          0

### TWO defects in my own instrument, both the ones I had just published about

**First: a reference count.** The scan initially classified a GO as CARRIED if ANY task
referenced it. That is a membership audit one level deeper — precisely what I told AEF at
599/602 their `_KNOWN_EXT` reference count was, and which they had already declined to bank.
A referencing task can be another inception, a handover, or prose. The tightened test asks
for an IMPLEMENTATION-typed successor. It returns the same 18/18, so the conclusion did not
move — but "same answer" is not "same evidence".

**Second, and worse: the first P-011 leg was vacuous.** It read the decision from a
frontmatter field `inception_decision:`, which does not exist on these tasks — decisions are
recorded in the `## Decision` section. It therefore found **zero GO tasks** and exited 0.
A green leg, in the gate whose entire job is to be unarguable, asserting nothing over an
empty population. I caught it only because I printed the population alongside the verdict
in the self-check.

That is PL-084 committed by me, in the task where I was measuring whether somebody else's
decision had been silently dropped, one hour after telling AEF that a clean number needs its
denominator. The replacement probe asserts its own population (exit 2 if the GO set is
empty) and the leg greps `"GO_population": 18` rather than trusting the exit code.

### The original framing, kept

The scan initially classified a GO as CARRIED if **any** task referenced it. That returned
18/18 and I nearly recorded it.

That is a reference count — a membership audit one level deeper — which is precisely what I
told AEF at 599/602 their `_KNOWN_EXT` audit was, and which they had already declined to
bank. A referencing task can be another inception, a handover, or a mention in prose; none
of those carries a build slice. The tightened test asks whether any referencing task is an
IMPLEMENTATION type. It happens to return the same 18/18, so the conclusion did not move —
but the first version could not have distinguished a carried GO from a mentioned one, and
"same answer" is not "same evidence".

### AC5 — why we came out clean, stated precisely, because the protection is PARTIAL

CLAUDE.md's Inception Discipline says that after a GO, implementation must move to separate
build tasks, and **the commit-msg hook enforces it**: after two exploration commits, further
commits under the inception ID are blocked until a decision is recorded.

That is a real structural difference from a convention, and it is why our GOs have
successors. But it must be stated for what it does:

**The hook guarantees that IF work happens it happens on a NEW task. It does not guarantee
that work happens.** A GO recorded against an inception that is then simply abandoned fires
no hook, blocks no commit, and creates no successor — which is exactly the shape of AEF's
T-2925. Our 18/18 therefore shows that in 18 cases somebody did follow up. It is evidence of
practice, not proof of immunity.

So the honest finding is: **we have the same gap AEF has, and we have not fallen into it
yet.** Reporting this as "we are structurally protected" would be the false-green form of the
result — the enforcement is real but it is aimed at a neighbouring failure (building under
the wrong ID), and the failure that bit AEF (deciding and stopping) has no gate on it here
either.

### AC4 — nothing filed

No orphaned GO, so no observation and no follow-up task. The denominator is what makes that
sentence worth reading.

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


# AC1/AC2/AC3 — the scan reproduces. Its own exit code is the verdict, and exit 2 means the
# GO population came back EMPTY, which is a broken probe rather than a clean tree. The first
# leg written here read a frontmatter field that does not exist, found 0 GO, and passed.
python3 tools/_t486-orphaned-go-scan.py > /tmp/t486-scan.out 2>&1

# AC1 — the denominator is asserted, not merely printed. A green over an empty population is
# the failure this whole task is about.
grep -q '"GO_population": 18' /tmp/t486-scan.out

# AC3 — and every one of them is carried by an IMPLEMENTATION successor, not just referenced.
grep -q '"carried_by_implementation": 18' /tmp/t486-scan.out

# AC6 — read-only. This task measured; it changed no product code.
git diff --quiet -- src/ tools/ docs/standards/ examples/ tests/fixtures/ .agentic-framework/

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

### 2026-08-13T07:28:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-486-find-closed-inception-go-decisions-whose.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9978b883
- **Timestamp:** 2026-08-13T07:30:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-13T07:30:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
