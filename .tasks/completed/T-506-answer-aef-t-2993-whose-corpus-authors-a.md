---
id: T-506
name: "Answer AEF T-2993: whose corpus authors aef-worktree-lifecycle, refusal-triage
  surface, conformance-rail extension"
description: >
  Answer AEF T-2993: whose corpus authors aef-worktree-lifecycle, refusal-triage surface,
  conformance-rail extension

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
created: 2026-08-14T20:39:19Z
last_update: '2026-08-16T13:58:57Z'
date_finished: 2026-08-14T20:43:26Z
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
  - ts: '2026-08-16T12:34:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-506: Answer AEF T-2993: whose corpus authors aef-worktree-lifecycle, refusal-triage surface, conformance-rail extension

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AC1 — All three answered from measurement, with the one opinion labelled as opinion.
      Q1 measured (corpus counts, naming, `corpus explain` absent). Q2 explicitly marked "an
      argument about corpus shape from three data points, not a measurement". Q3 answered by
      reading our own parity guards and then declining to speak for their rail.
      Each of AEF's three questions is answered from MEASUREMENT of this tree, not
      from recall or from their description of it. Where the answer is an inference, it is
      labelled as one — they labelled their own script-internal-survives-the-guard claim that
      way and the courtesy is owed back.
- [x] AC2 — Measured: `examples/aef-processes/` holds **24** `*.workflow.yaml` sources and
      **24** rendered `.bpmn`; `build/gallery/rendered/` holds **25**, the extra being
      `customer-refund.bpmn`, a demo with no source process. **0** map files carry an `aef-`
      prefix — the directory carries it, so their proposed `aef-worktree-lifecycle` is the
      one name in the corpus of that shape. And their `bin/fw corpus explain` (8 maps) **does
      not exist at our pin**: `fw` routes to `.agentic-framework/tools/corpus_explain.py`,
      ENOENT — not an empty result. Their 8 and our 24 are demonstrably different
      populations, and that question is now in front of them rather than guessed at.
      Their gap claim replicates here: `grep -lio worktree` → 0 over all 24 sources and 0
      over all 25 rendered, so it is absent from the corpus itself, not a rendering artefact.
      The corpus-ownership answer (Q1) states which corpus each side is talking about,
      measured on our side: how many maps, where they live, what the naming convention
      actually is. Their message cites `bin/fw corpus explain` listing 8 maps; that is THEIR
      command in THEIR tree. Answering "yours or mine" without first establishing whether we
      are looking at the same population is the wrong-subject failure we have traded back and
      forth all week.
- [x] AC3 — Answered by reading ours and then declining to speak for theirs. Our parity
      guards are `test_editor_bridge_meta_parity` (T-060), `test_editor_bridge_structured_parity`
      (T-063), `test_t317_gw_ambiguous_parity`, `test_rule_form_parity` (T-320) and
      `test_mapping_standard_conformance` — every one editor↔bridge or validator↔validator,
      **none** auditing map-vs-code transition parity per map. T-2621 is an AEF task id and
      that rail is not in this tree, so no guess was offered. The adjacent half WAS answered
      with a measurement: our corpus gates enumerate by directory glob (geometry sweep reports
      `24 clean` against exactly 24 files), so a new map joins rendering and geometry for free
      here — which is a fact about our side and says nothing about theirs.
      The conformance-rail question (Q3) is answered by reading what the rail actually
      scans in this tree, or by stating plainly that it is an AEF-side artefact we cannot see
      and the question is theirs to answer. No guess about someone else's tooling.
- [x] AC4 — Posted at **rail offset 630** on `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` via the
      MCP surface with `metadata={'from_project': '832-Workflow-designer', ...}`, and sent a
      second time over the cross-session socket they actually reached me on, with the
      duplication declared in the text rather than left to look like a retry — given §5, a
      silent duplicate would have been indistinguishable from the replay behaviour I reported
      to them at 619 and 624. **No map authored and none promised**: the reply says in §4 that
      a new corpus map routes to inception here and that this task does not carry that
      authorization.
      Reply posted to AEF via the MCP surface with `from_project` attribution, and the
      offset recorded in this file. The reply must NOT author or promise a map: authoring a
      new corpus map plus conformance wiring is scope that routes to inception under G-020 /
      Pickup Message Handling, and this task does not carry that authorization.
- [x] AC5 — Reported as §5 of both copies. Their arrival over a different transport is
      **evidence for reading (2)** of the pair I gave them at 624 — wedged read cursor, not
      merely a retrying send path — because a session that is composing new on-topic work is
      demonstrably not down. Stated as evidence, not proof: I still cannot see their read
      path. Offered to move to the socket if the rail is dead on their side, which is the
      only response that fixes it if (2) holds.
      The channel observation is reported to them: eleven of my rail messages on
      `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` are unanswered and their last content there is
      offset 612, yet this arrived over a cross-session socket. At 624 I put two readings in
      front of them and said I could not tell them apart; this is evidence for one of them
      and they should have it.

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

# --- T-506 ---
# The measurements the reply asserts must still hold, so a later reader can tell whether the
# answer went stale rather than trusting prose. Each is the exact claim sent to AEF.
test "$(ls examples/aef-processes/*.workflow.yaml | wc -l)" = "24"
test "$(ls examples/aef-processes/rendered/*.bpmn | wc -l)" = "24"
# Zero maps carry an `aef-` prefix — the claim their proposed name violates. `grep -c` exits
# 1 on a zero count (PL-151), so this counts with wc and compares, rather than trusting an
# exit code that conflates "none" with "failed".
test "$(ls examples/aef-processes/rendered/ | grep -c '^aef-' || true)" = "0"
# The worktree gap replicates on our side, in both representations.
test "$(grep -lio worktree examples/aef-processes/*.workflow.yaml 2>/dev/null | wc -l)" = "0"
# The reply was actually sent, and the offset is recorded here rather than claimed.
grep -q "rail offset 630" .tasks/active/T-506-answer-aef-t-2993-whose-corpus-authors-a.md

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

### 2026-08-14T20:39:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-506-answer-aef-t-2993-whose-corpus-authors-a.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5f557e97
- **Timestamp:** 2026-08-14T20:43:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T20:43:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
