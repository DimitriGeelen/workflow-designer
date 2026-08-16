---
id: T-386
name: "Focus-drift block message recommends a command the gate now refuses (T-381
  follow-on)"
description: >
  T-381 made fw context focus refuse completed task ids. The focus-drift block message
  at check-active-task.sh:364 still prints 'fw context focus $TARGET_TASK' as remedy
  1, and the drift target is a completed task in the common case (a follow-up commit
  naming a closed task). The gate therefore recommends, first, a command it will itself
  reject. Flagged by AEF at rail 465 as a sharp edge from shipping our fix.

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
created: 2026-08-08T17:10:35Z
last_update: '2026-08-16T14:33:32Z'
date_finished: 2026-08-08T17:22:45Z
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
  - ts: '2026-08-16T12:33:54Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 0
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/check-active-task.sh,tools/_t352-p011-errexit-probe.sh,tools/_t386-drift-remedy-reachable.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/check-active-task.sh,tools/_t386-drift-remedy-reachable.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-386: Focus-drift block message recommends a command the gate now refuses (T-381 follow-on)

## Context

T-381 scoped `fw context focus` to `active/`, so it now refuses any completed task id —
correctly, since the gate that reads focus back requires an active task. Nothing updated
the message that recommends focusing one. `check-active-task.sh:364` still prints
`fw context focus $TARGET_TASK` as remedy 1 of the focus-drift block.

The drift target is a **completed task in the common case** — the archetypal trigger is a
follow-up `git commit -m "T-XXX: ..."` naming a task that has closed. So remedy 1 is
unreachable exactly when the gate fires most, and the operator's first move is a refusal
from the same subsystem that just blocked them. Options 2 and 3 work, so this is a loop
with an exit, not a wedge.

Flagged by AEF at rail 465 as a sharp edge from shipping the fix; they called it cosmetic.
It is a defect **my own T-381 fix created**: the behaviour and the text advertising it live
in different files and nothing joins them. Same shape as the unread-key finding at rail 462
— a remedy that has stopped being true and a remedy that was never true are indistinguishable
at the only place anybody reads it. [[remedy-and-verifier-keyed-differently]].

## Acceptance Criteria

### Agent
- [x] When the drift target is a COMPLETED task, the block message does not present `fw context focus <target>` as a working option — it is either omitted or explicitly marked unavailable **with the reason**, so the operator is not left guessing why the recommendation failed
- [x] When the drift target is an ACTIVE task, the message is unchanged — remedy 1 still offered, same wording; the case that works must not regress
- [x] Completed-detection uses the same scope the focus writer now enforces (a `completed/` lookup), not a heuristic on the id or on task-file contents
- [x] Bypass mechanisms are untouched: options 2 and 3 still present in both branches, exit code still 2, and the `--switch-focus` / `FW_SWITCH_FOCUS=1` paths still log and allow
- [x] Probe measures BOTH branches against the REAL hook — completed target and active target — and asserts the two messages differ in the required way rather than merely that each is non-empty
- [x] **Anti-vacuity control:** the probe proves it reaches the focus-drift gate specifically (not some earlier block), since every earlier gate also exits 2 and would satisfy a naive rc check
- [x] **Teeth by mutation of LIVE source, not a git ref:** reverting the fix in a working copy must turn the probe RED. Adopting AEF's rail-463 lesson — their `git show HEAD~1` teeth leg skipped while reporting ok once the fix landed one commit earlier; a git-ref check has an expiry date set by the next commit and nothing announces it
- [x] Diff sent to AEF, since the hook is theirs and I told them at rail 466 I would not rewrite their wording unilaterally

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

# Exits 3 (COULD-NOT-MEASURE) if it never reaches the focus-drift gate, so a green
# total also certifies the legs were asserting about the right gate.
bash tools/_t386-drift-remedy-reachable.sh > /tmp/.t386-out 2>&1 && grep -q "PASS=11 FAIL=0" /tmp/.t386-out
# The teeth must have RUN, not merely not-failed. A mutation that silently fails to
# apply leaves every behavioural leg green and certifies nothing (AEF rail 463).
grep -q "teeth: mutant RE-OFFERS the refused command" /tmp/.t386-out
# The discriminator leg: an earlier gate must NOT produce the drift banner, else
# every branch assertion is satisfied by a block that never reached this code.
grep -q "no-focus case takes a different branch" /tmp/.t386-out
# Regression control for the case that already worked.
grep -q "active target: remedy 1 unchanged" /tmp/.t386-out
# The hook must still parse — it gates every Write/Edit in the project.
bash -n .agentic-framework/agents/context/check-active-task.sh

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

**Symptom:** The focus-drift gate blocks, then prints as its first remedy
`fw context focus T-<completed-id>` — a command the same subsystem refuses. Reported by
AEF at rail 465 after they shipped our T-381 fix.

**Root cause:** T-381 narrowed what `fw context focus` ACCEPTS (active/ only). The block
message that RECOMMENDS focusing lives in a different file and was not part of that
change. Nothing connects a behavioural narrowing to the text advertising the old behaviour,
so the message kept describing a capability that had been removed underneath it.

**Why structurally allowed:** the remedy is prose inside an `echo`, and no gate reads it.
The framework can tell whether a command exists, whether a task exists, whether a file
parses — it has no notion of "a command this message recommends must succeed in the
situation that produced the message". A recommendation that has stopped being true and one
that was never true are byte-identical to every check we run. Same family as the rail-462
finding where a written closure condition under an unread key was indistinguishable from
an absent one: both are content nobody's instruments can see.

**Prevention:** `tools/_t386-drift-remedy-reachable.sh` measures both branches against the
real hook and has teeth by live-source mutation, so a revert goes red. That covers THIS
message. It does not generalise — the broader class ("gate messages whose remedies are
never executed") is not closed by this task, and is worth a register entry only if a
second instance appears; one occurrence is a bug, and I have no evidence yet that it is a
pattern.

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

### 2026-08-08T17:10:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-386-focus-drift-block-message-recommends-a-c.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-329e4c85
- **Timestamp:** 2026-08-08T17:22:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T17:22:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
