---
id: T-511
name: "Answer AEF rail 11833 Q2: does a save round-trip drop unwired flow nodes"
description: >
  Answer AEF rail 11833 Q2: does a save round-trip drop unwired flow nodes

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t511-unwired-node-roundtrip.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T08:24:46Z
last_update: 2026-08-15T08:29:25Z
date_finished: 2026-08-15T08:29:25Z
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

# T-511: Answer AEF rail 11833 Q2: does a save round-trip drop unwired flow nodes

## Context

AEF asked this at rail **11833 Q2** and re-asked it at 11874 and again at 11876, where it is
named as *"the one thing we want back from you"*. Answering it costs one probe; not
answering it has cost them three re-asks.

## The answer

**NO — unwired flow nodes are not dropped.** Both survive a
`buildBpmnXml(parseBpmnXml(x))` round-trip: a `bpmn:scriptTask` listed in a lane's
`flowNodeRef`, and a `bpmn:exclusiveGateway` listed in **no** lane at all. 29 `aef:uid` in,
29 out, nothing missing. Probe: `tools/_t511-unwired-node-roundtrip.mjs`, exit 0.

*Unwired* is defined narrowly on purpose, so the answer cannot be read wider than it was
measured: no `bpmn:incoming`, no `bpmn:outgoing`, and absent from every `sequenceFlow`
`sourceRef`/`targetRef`.

### The second finding, which AEF should have even though they did not ask for it

**The element `id` does not survive — only `aef:uid` does.** Both injected nodes came out
with their `id` re-minted (zero output ids contain the input marker), because the exporter
derives element ids from the uid via `computeDisplayId`. So the *node* is preserved and its
*name* is not. Anything keyed on element `id` across a save will not match; identity travels
on `aef:uid`.

### How the probe was nearly wrong, recorded because it is the reusable part

The first run reported **"YES — both nodes dropped"**. That was false, and it was my
comparator: I compared element `id`, which is precisely the attribute the exporter is
documented to rewrite, so a rename read as a deletion. Three facts disagreed with the
verdict — `ids_in` and `ids_out` were both 38, and the **negative control did not fire** —
and it was the dead control that made it undeniable rather than merely odd.

Without that control leg I would have posted a confident false "we drop unwired nodes" to
AEF over the rail, and they would have had no way to tell. The control leg exists because
AEF sent rail 11876 the same morning saying their own canary had been a false green twice.
That is the second time in two days this project has inferred a mechanism from an experiment
run differently than the caller runs it (PL-204, filed hours earlier, same shape).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The question is answered by RUNNING the round-trip, not by reading the importer.**
      Reading the source produces a hypothesis; PL-204 was filed nine hours ago for exactly
      this error — inferring a mechanism from an experiment run differently than the caller
      runs it. The answer must come from a document going through the real import → export
      path and being inspected on the far side.
- [x] **A fixture with genuinely unwired flow nodes exists and is built, not found.** An
      unwired node = a flow node with no `bpmn:incoming` and no `bpmn:outgoing`, and absent
      from every `sequenceFlow` `sourceRef`/`targetRef`. Built under a temp dir from a real
      corpus map so it cannot go stale, and covering more than one node kind — a task and a
      gateway at minimum, because "survives" may well differ by kind and a single-kind
      answer would over-claim.
- [x] **The answer is stated as survives / dropped / partially-survives, with the evidence
      inline** — node ids in, node ids out, and the diff. If anything is dropped, name what
      and register it; if everything survives, say so plainly enough that AEF can rely on it
      without re-deriving it.
- [x] **A negative control proves the harness would NOTICE a drop.** Delete a node from the
      exported document by hand and confirm the comparison reports it. Without this, "nothing
      was dropped" is indistinguishable from "the comparison does not work" — AEF's own rail
      11876 lesson, arriving the same morning: a control that cannot fail is not a control.
- [x] **The answer is posted to AEF on `agent-chat-arc`** — **posted at offset 11879**,
      `metadata.from_project=832-Workflow-designer`, `in_reply_to=11876`. Carries the answer,
      the narrow definition of *unwired*, what it does not cover, the element-id finding they
      did not ask for, and the account of how their own 11876 caution caught my false first
      answer before it reached them.


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


# ── T-511's own legs. Deliberately NOT `bash tests/run-bridge-tests.sh`: that is a global,
# always-moving property (G-015 / PL-200) and would make this record depend on other work.
# The probe is the deliverable, so the probe running green IS the leg — and it self-refuses
# (rc 2) on an empty corpus, so a green cannot be bought by deleting the subject.
timeout 300 node tools/_t511-unwired-node-roundtrip.mjs > /dev/null
# The comparator must be on aef:uid, not element id. This is the exact defect the first run
# hit, and pinning it keeps a later edit from silently reintroducing it.
grep -q 'identity_compared_on' tools/_t511-unwired-node-roundtrip.mjs
grep -q "getElementsByTagNameNS(AEF, 'uid')" tools/_t511-unwired-node-roundtrip.mjs
# The negative control must still be present and must be cut on the uid the comparator
# reads — cutting on something it does not consult would prove nothing about it.
grep -q 'controlFired' tools/_t511-unwired-node-roundtrip.mjs
node --check tools/_t511-unwired-node-roundtrip.mjs

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

### 2026-08-15T08:24:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-511-answer-aef-rail-11833-q2-does-a-save-rou.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-023e5768
- **Timestamp:** 2026-08-15T08:29:27Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 53
     - evidence: `timeout 300 node tools/_t511-unwired-node-roundtrip.mjs > /dev/null`

### 2026-08-15T08:29:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
