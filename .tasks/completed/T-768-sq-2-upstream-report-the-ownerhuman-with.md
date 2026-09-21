---
id: T-768
name: "SQ-2 upstream: report the zero-Human-AC ownership fault to AEF for remediation"
description: >
  Operator instructed that the structural fault be reported upstream to the agentic
  framework side, not only fixed locally. Transport alone is not completion.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T10:36:57Z
last_update: 2026-09-21T10:46:26Z
date_finished: 2026-09-21T10:46:26Z
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
      D4: 3
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=1 (prose:AEF 
      seam-incidental); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
---

# T-768: SQ-2 upstream: report the owner:human-with-zero-Human-ACs fault to AEF for remediation

## Context

### The instruction

Operator, 2026-09-21, verbatim: *"And we also need to fix it upstream, tell our
agentic handling agent that that's a structural fault it needs to remediate."*

Read as: report the fault to the AEF side, not merely patch it locally. Contacting
999-AEF is mandated rather than discretionary, and **transport is not completion** —
a post or a file transfer is evidence that something was sent, not evidence that the
counterparty accepted it as a fault to remediate.

### What is being reported

An agent-produced task can be born `owner: human` with zero Human acceptance criteria.
Such a task is unclearable by the agent that created it: completing an `owner: human`
task is not delegated, so the creating agent manufactures work it is structurally
forbidden to finish, and the task accumulates in a human review queue carrying nothing
to review.

This is a framework-level fault, not a project-level one — which is precisely why it
goes upstream rather than being absorbed as local usage.

### Evidence to carry

Four instances, all reported by the framework's own CTL-029 check as
*completable, not closed*: T-702, T-703, T-708, T-723 — owned respectively by T-747,
T-748, T-749, T-750. They are arc-003's own remediation tasks, so the framework
generated, detected, and could not clear the same condition.

### Constraints on how this is sent

- Post through the MCP surface, never via Bash `termlink channel post`.
- Every content post carries producer attribution
  (`metadata={'from_project': '832-Workflow-designer', ...}`); the attribution gate
  blocks posts without it, and session messages are not covered by the gate so
  attribution is written by hand.
- The parameter is `payload` / `payload_b64`, not `message`; `in_reply_to` is a string.
- This is a **report of a fault**, not a build instruction to the counterparty. A
  pickup message is a proposal in the outbound direction exactly as in the inbound
  one (G-020).

### Root-cause links

Local fix: T-767. Instances: T-747…T-750. Ruling: SQ-2, recorded by T-766. Governance: contacting 999-AEF is mandated; transport alone is not collaboration completion.

### Transport record — what was sent, and where

| | |
|---|---|
| Topic | `aef-operator-notices` |
| Offset | **3** |
| msg_type | `note` |
| Attribution | `from_project: 832-Workflow-designer`, `event_type: framework-fault-report`, `conversation_id: 832-T-768` |
| Surface | MCP `termlink_channel_post` — not Bash `termlink channel post` |

Rail timestamps are not evidence; the offset and the content are what is citable.

**Why this topic.** `aef-install-findings` holds 38 envelopes but **none are content
msg_types** — it is meta traffic, not a prose rail, and a prose fault report there
would be unreadable. `aef-operator-notices` is where the AEF framework session posts
prose, and its offset 1 carries a standing invitation: *"If you are the workflow
agent, reply here with your ownership split and the Designer→runtime interface
owner."* The report answers that invitation in passing.

### What was reported

Two faults, sent as one report because the second was found while filing the first:

1. **A task can be born `owner: human` with zero Human ACs** — unclearable by the
   agent that created it. Four instances cited as evidence (T-702, T-703, T-708,
   T-723 → T-747…T-750), with the point that these are arc-003's *own* tasks: the
   framework generated the condition, detected it with its own check, and could not
   clear it.
2. **`create-task.sh` sets the owner field by first-match substitution** — a task
   whose *name* contains that field's text has its name rewritten and its real owner
   left empty. Measured on this very task; held locally as OBS-363.

Framed throughout as a fault for AEF to triage, explicitly not as a build instruction
and not as a proposed patch to their tree (G-020 applies outbound as well as inbound).

### Acceptance — OPEN as of 2026-09-21

**No response has arrived.** This is recorded as an open state, not smoothed into
"reported and resolved".

The distinction this task exists to hold: **the post is evidence that something was
sent. It is not evidence that AEF accepted either item as a fault to remediate.** What
would close the collaboration is a triage verdict on either fault — *including*
"not a fault, here is why".

This task is completable because its deliverable was *the report*. The collaboration
it opens stays open, and nothing downstream waits on it: T-767 fixes our side under
the vendored-tree allowance regardless of what AEF decides.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The fault is reported to the AEF side with the four instances cited as evidence, through the MCP surface, carrying `from_project` attribution.
- [x] The report is framed as a fault for the counterparty to triage, not as an instruction to build a specific fix. What AEF does about it is AEF's call.
- [x] Transport evidence and acceptance are recorded separately. The offset or id of what was sent is captured, and the task does NOT claim completion of the collaboration on the strength of having sent something.
- [x] If no response has arrived, that is recorded as an open state with the date, not smoothed into 'reported and resolved'.

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
         1. Run `bin/fw reviewer T-768`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-768 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
test -f .tasks/active/T-767-sq-2-fix-an-agent-produced-task-must-nev.md || test -n "$(ls .tasks/completed/ | grep '^T-767-')"
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-768-*.md' | xargs grep -l 'aef-operator-notices' | wc -l)" -eq 1
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-768-*.md' | xargs grep -l 'Acceptance — OPEN as of' | wc -l)" -eq 1
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-768-*.md' | xargs grep -l 'not evidence that AEF accepted' | wc -l)" -eq 1

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

### 2026-09-21 — the act of filing the report produced a second fault

- **What changed:** At filing, this task carried one fault: a task can be born
  `owner: human` with zero Human ACs. Creating the task to report it **produced a
  second, independent fault in the same code path** — `create-task.sh` sets the owner
  field by first-match substitution, so this task's own name (which contained that
  field's text) was rewritten and its real `owner:` field left empty. The report had
  to grow from one fault to two, and the second one carries stronger evidence than the
  first because it was reproduced accidentally rather than argued for.
- **Plan impact:** The single-fault framing in the original Context is now incomplete;
  a "What was reported" section was added rather than editing the original framing,
  so the growth is visible. The one-task-one-deliverable rule still holds — the
  deliverable is *the report*, and both faults belong in one report because a reader
  triaging the creation path needs both.
- **Triggered:** OBS-363 (urgent) for the substitution bug, held separately because
  one bug is one task and the generator is still unfixed. T-767 remains scoped to
  Fault 1 only; the substitution bug needs its own record and does not silently
  expand T-767.

### 2026-09-21 — the obvious rail was the wrong rail

- **What changed:** `aef-install-findings` looked like the correct destination by
  name, with 38 envelopes. It holds **no content msg_types at all** — every envelope
  is meta. A prose fault report there would have been technically delivered and
  practically invisible, which is the exact failure mode PL-242 already names: a
  control can be correct, firing, and stranded where no reader looks.
- **Plan impact:** Destination selection became part of the work rather than an
  assumption. `aef-operator-notices` was chosen because the AEF session demonstrably
  posts prose there and its offset 1 carries a standing invitation to the
  workflow/designer agent.
- **Triggered:** Nothing filed. Recorded here so the next outbound report checks
  whether a rail carries readable content before using it, instead of matching on the
  topic name.

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
     fw inception decide T-768 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T10:36:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-768-sq-2-upstream-report-the-ownerhuman-with.md
- **Context:** Initial task creation

### 2026-09-21T10:43:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-eca991b7
- **Timestamp:** 2026-09-21T10:46:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T10:46:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
