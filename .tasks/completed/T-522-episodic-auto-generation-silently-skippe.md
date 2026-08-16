---
id: T-522
name: "episodic auto-generation silently skipped for T-520 and T-521 — no episodic
  and no diagnostic log despite the T-1860 log-every-invocation guarantee"
description: >
  episodic auto-generation silently skipped for T-520 and T-521 — no episodic and
  no diagnostic log despite the T-1860 log-every-invocation guarantee

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t522-episodic-reachability-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T14:08:28Z
last_update: '2026-08-16T14:33:44Z'
date_finished: 2026-08-15T14:23:07Z
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
  - ts: '2026-08-16T12:34:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 3
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 1
      F1: 1
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F-AUTONOMY=0
      (no-signal); F3=1 (body/components:prompt-incidental); F1=1 
      (body/components:context-fabric-incidental); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 3
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 1
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-522: episodic auto-generation silently skipped for T-520 and T-521 — no episodic and no diagnostic log despite the T-1860 log-every-invocation guarantee

## Context

The S-2026-0815-1552 handover flagged `⚠ EPISODIC CONTEXT GAPS DETECTED — T-520: Missing
episodic summary; T-521: Missing episodic summary`. Both were closed with
`fw task update --status work-completed`, both are `workflow_type: build`, `owner: agent`,
`status: work-completed`, both carry `date_finished` and both were moved to `.tasks/completed/` —
structurally indistinguishable from T-519, which got its episodic normally in the same session
19 minutes earlier.

What makes this worth a task rather than a manual backfill is the SECOND absence.
`update-task.sh:2091` (T-1860) writes `.context/working/episodic-gen/<TASK_ID>.log` on
*every* invocation — the comment says so explicitly: "Log every invocation (not only on
failure) so the forensic context is captured when the next silent failure occurs." The
directory holds one log per task through T-519 and has none for T-520 or T-521. So the
generator did not fail; the block was never reached. T-1169's silent-failure detector
(`if [ ! -f "$EPISODIC_FILE" ]` → WARNING) sits INSIDE the same block, which means it cannot
fire for the one failure mode where the block is skipped. Two guards, one blind spot, and
the same shape as the defect T-509 and PL-206 keep finding: a control placed downstream of
the branch that fails.

Backfilling the two episodics is the cheap half and does not close anything. The task is to
name the branch that was taken, from the script's own control flow rather than by inference,
and to put the absence-detection somewhere it can observe a skip.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The completion path actually taken by T-520/T-521 is identified by file:line in
      `update-task.sh`, with the specific condition that routed them away from the episodic
      block named — not "probably the partial-complete branch"
- [x] The identification is demonstrated, not asserted: the branch is exercised and observed
      (trace, instrumented run, or a reproduction on a throwaway task), and the observation is
      recorded in the RCA
- [x] Episodics for T-520 and T-521 exist, are non-empty, parse as YAML, and carry the real
      task content (not a stub)
- [x] Every completion path that can move a task to `completed/` either writes the
      `episodic-gen/<id>.log` invocation record or emits a visible warning — the T-1860
      guarantee holds on all of them, not only the one it was written for
- [x] A teeth script proves the fix rather than the fix proving itself: it goes RED for the
      NAMED REASON (a completion that skips episodic generation is reported) when the fix is
      reverted, and it distinguishes "no episodic" from "detector dead" (PL-205)
- [x] The vendored fix is registered in `.agentic-framework/.vendor-divergence.yaml` with
      `upstream: fix` — this is framework code and upstream lacks it (G-008)
- [x] Bridge suite green and the T-451 unwired-guard ratchet unmoved at 67

<!-- No Human ACs: every criterion above is a deterministic shell check on framework
     tooling. Removed per the template's own instruction ("Remove this section if all
     criteria are agent-verifiable") rather than left as unchecked boilerplate.

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

# The teeth are the load-bearing check: 5 legs, two of them mutation legs that put the
# unguarded grep back and require the run to lose its episodic AND be reported by name.
# rc 2 is a refusal (mutation target absent), not a pass.
python3 tools/_t522-episodic-reachability-teeth.py
# The two lost episodics are back, non-empty, and parse.
test -s .context/episodic/T-520.yaml
test -s .context/episodic/T-521.yaml
python3 -c "import yaml; yaml.safe_load(open('.context/episodic/T-520.yaml')); yaml.safe_load(open('.context/episodic/T-521.yaml'))"
# The trigger itself is gone: both hand-written cards now carry `location:`, so the corpus
# no longer contains the stimulus. This is belt-and-braces — the script fix is what matters,
# since the next location-less card is a matter of time.
grep -q '^location: tools/_t520-xml-read.py$' .fabric/components/tools-_t520-xml-read.yaml
grep -q '^location: tools/_t520-uid-xml-safety.mjs$' .fabric/components/tools-_t520-uid-xml-safety.yaml
# The vendored fix is declared (G-008) — a re-vendor would otherwise silently restore the bug.
python3 tools/_t517-vendor-divergence.py
# Deliberately NOT verifying "the bridge suite is green": that is global moving state and
# would go red for someone else's change under a daily re-runner (T-508's learning).

## RCA

**Symptom:** T-520 and T-521 were completed normally — `date_finished` set, moved to
`.tasks/completed/`, no error printed — and neither produced an episodic summary. Neither
produced the per-task invocation log either, which is what made it a defect rather than a
generator failure: `update-task.sh` promises to log *every* invocation (T-1860), so an absent
log means the generator was never called.

**Root cause:** `update-task.sh` runs under `set -euo pipefail` (line 14). Its component
auto-populate block (T-224) builds a location→id lookup over every card in
`.fabric/components/` with

    c_loc=$(grep "^location:" "$card" 2>/dev/null | sed ... | head -1)

A card with no `location:` key makes `grep` exit 1; `pipefail` propagates that through the
pipe; and under `errexit` a failing **command substitution in an assignment** terminates the
script outright. Execution left `update-task.sh` mid-loop with exit 1 — *after* the task file
had been moved to `completed/` and rewritten, so completion looked successful — and everything
below that point never ran: decision auto-capture, outcome back-prop, and the Episodic
Generation block ~110 lines further down.

**Demonstrated, not inferred.** Three independent confirmations:
1. The exact assignment, run standalone under `set -euo pipefail` against
   `tools-_t520-xml-read.yaml`, aborts before the next statement (rc=1, no output).
2. The verbatim loop from `update-task.sh:1953-1960`, run against the *real*
   `.fabric/components/` directory, exits 1 partway through — i.e. every task completion in
   this project was dying before the episodic block, not just the two observed.
3. The timeline discriminates rather than merely fits. The two cards lacking `location:` are
   the two I hand-wrote during T-520; they landed at 12:13:39Z. T-520 completed at 12:13:59Z
   (20 seconds later) and T-521 at 13:34:03Z — both lost. T-519 completed at 11:53:42Z, before
   the cards existed — not lost. The `.fabric/` corpus contains exactly two location-less
   cards and exactly two tasks lost their episodics.

**Why structurally allowed:** two controls for this precise outcome already existed and
neither could fire. T-1169 warns when the generator produces no file; T-1860 logs every
generator invocation. Both live **inside** the block that never executed. A control placed
downstream of the branch that fails cannot report that failure — it can only certify a line
that never ran. This is the same shape as PL-206 and the T-509 finding, now in framework code.

Worse, this is the **third** instance of one bug in one block. T-1374 (G-054) fixed exactly
this abort — its comment reads *"prevents the pipeline's grep-no-match exit 1 (under pipefail)
from killing the script via set -e, which otherwise aborted before the Episodic Generation
block ran"* — and applied `|| true` to the two greps forty lines below while leaving these two
untouched. The fix was made at the site where the failure was observed rather than at the
mechanism, which is the learning T-521 recorded one day earlier, arrived at again from the
opposite direction.

**Prevention (distinct from the fix):** an EXIT-trap watchdog in `update-task.sh`, placed
*outside* the block it guards. When a work-completed transition begins but execution leaves
the script before the episodic stage, it writes a `NOT REACHED` record to
`.context/working/episodic-gen/<id>.log` — honouring the T-1860 promise on the one path where
the logging code itself never runs — and prints a named error. It is silent on the designed
partial-complete skip (T-1160/T-1103), because a watchdog that cries on a legitimate skip gets
muted and then it is gone.

`tools/_t522-episodic-reachability-teeth.py` proves the fix by mutation rather than by
assertion: it copies the framework, puts the unguarded grep back, and requires that run to
lose the episodic **and** be reported by name. Leg 5 guards the guard — bash silently replaces
an EXIT trap when a second one is installed, so a later cleanup handler would delete the
watchdog with no error anywhere.

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

### 2026-08-15T14:08:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-522-episodic-auto-generation-silently-skippe.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-77f8d48a
- **Timestamp:** 2026-08-15T14:23:12Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T14:23:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
