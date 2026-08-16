---
id: T-494
name: "T-420 gate: agent_send_auto_discover posts content under key 'message' and
  is allowed at exit 0"
description: >
  CONTENT_KEYS is (payload,payload_b64,text); agent_send_auto_discover carries content
  in 'message', so decide() finds carried empty and returns 0. It drives channel.post
  to a dm:* topic and its schema says WRITES state, so an unattributed content envelope
  reaches a shared topic silently. Also in the same re-measure: emit_to is missing
  from Rule 0 beside its sibling emit; channel_edit, agent_edit and chat_arc_broadcast
  are blocked with a remedy naming metadata=/project=, neither of which exists on
  their schemas (T-426 unfollowable-remedy class). The gate's DECLARED lists are dated
  2026-08-10/11 and the docstring asks for exactly this re-measure. Found via T-492.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t420-rail-attribution-gate.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-14T06:59:46Z
last_update: '2026-08-16T14:33:42Z'
date_finished: 2026-08-14T07:17:55Z
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
  - ts: '2026-08-16T12:34:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=1 (prose:AEF 
      seam-incidental); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-494: T-420 gate: agent_send_auto_discover posts content under key 'message' and is allowed at exit 0

## Context

`tools/_t420-rail-attribution-gate.py` labels both its DECLARED lists as facts dated
2026-08-10/11 and instructs a future reader to re-measure rather than trust them. T-492
took that instruction four days later. Result:

    tool                        content key   attribution param        verdict
    agent_send_auto_discover    message       (none)                   ALLOW ← silent
    emit_to                     payload       (none)                   not in Rule 0
    channel_edit                text          (none)                   unfollowable remedy
    agent_edit                  text          (none)                   unfollowable remedy
    chat_arc_broadcast          payload       from (unknown to gate)   unfollowable remedy

**The severe one is `agent_send_auto_discover`.** `CONTENT_KEYS` is
`("payload","payload_b64","text")`; its content parameter is `message`, so `carried` is
empty and `decide()` returns 0. Its own schema says WRITES state and it drives
`channel.post` to a `dm:*` topic. That is an unattributed content envelope on a shared
topic at exit 0 — the direction the gate's author called unrecoverable, because *an
absent label cannot be reconstructed later*.

The other three are T-426's unfollowable-remedy class recurring: blocked by Rule 1 with
a message naming `metadata=` and `project=`, **neither of which exists on their
schemas**. T-426 established that an unfollowable remedy is not a smaller version of a
correct one — its only exits are abandon-the-tool or bypass-the-gate, and neither leaves
a record.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `agent_send_auto_discover` is refused by Rule 2 with a remedy that names a tool
      that can actually carry attribution. Rule 2 is checked BEFORE Rule 1, so the fix
      does not depend on `message` being added to `CONTENT_KEYS` — closing it by content
      key alone would leave the next content-key spelling open.
- [x] `channel_edit`, `agent_edit` and `chat_arc_broadcast` are refused with **followable**
      remedies — each naming a compliant alternative that exists on the current schema.
      For the two edit verbs the honest remedy is a correction post referencing the
      offset, because the edit envelope has no attribution channel at all.
- [x] **`emit_to` is NOT added to Rule 0.** Its sibling `emit` is excused as
      session-local, but `emit_to`'s own description says "via the hub", and I cannot
      determine from outside whether that produces a hub envelope. Adding it would be
      LOOSENING on an uncertainty, against the gate's own stated asymmetry: an unknown
      tool must be treated as a possible producer, because a false positive is loud and
      fixable while an unattributed envelope is silent and unrecoverable. Recorded as an
      open question with the evidence needed, not resolved by guessing.
- [x] **Teeth:** a driver proves the gate returns 2 for `agent_send_auto_discover`, and
      that the SAME driver returned 0 against the pre-change file. A block that was never
      observed as an allow proves nothing about the fix.
- [x] Every remedy string is checked against the tool's live schema — no remedy names a
      parameter that does not exist, which is the defect being repaired.
- [x] `_t420-gate-mutation-check.sh` and `_t426-gate-misfire-matrix.sh` still pass, and
      the bridge suite is green.


## Results

    case                        OLD    NEW    meaning
    agent_send_auto_discover      0      2    THE FIX — the silent miss is closed
    channel_edit                  2      2    still refused, remedy now followable
    chat_arc_broadcast            2      2    still refused, remedy now followable
    compliant channel_post        0      0    no regression
    unlabelled channel_post       2      2    still caught
    read-side channel_state       0      0    still not treated as a producer
    agent_contact(body_file)      -      2    class closed by shape, not by name

`_t420-gate-mutation-check.sh` 15/15, `_t426-gate-misfire-matrix.sh` pass=23 fail=0,
bridge suite 73 passed / 0 failed.

## The finding that outlived the fix

`_t426-gate-misfire-matrix.sh` printed this in its LIMIT block on **every run** since
2026-08-11:

    agent_contact is caught by name (Rule 2), not by content key. A future tool using
    `message`/`body_file` would be a fresh false negative — the FN class is not closed,
    only this instance of it.

That is a correct, specific, written-down prediction. `agent_send_auto_discover` is
exactly the tool it predicted, it was live, and it was allowed at exit 0. Nothing was
missed by anyone's reading — the class was **named, printed, and left without a task
id**. PL-139 (from T-418, the same lineage) says a remedy keyed to the value in hand
closes the member and leaves the class; this is the sharper case, because the author
*knew* and said so.

**A known-open class recorded only in a LIMIT string is a prediction with no schedule.
If it is worth printing on every run, it is worth a task id.** Both halves are now
closed: the members are in Rule 2, and `message`/`body_file` are in `CONTENT_KEYS`.

## A control that was passing for the wrong reason, caught mid-task

The first teeth run reported `compliant channel_post: OLD 2 → NEW 0`, which reads as
"the old gate blocked valid posts" — a dramatic and false finding. Cause: the gate
derives `EXPECTED_LABEL` from `basename(dirname(dirname(__file__)))`, and I had copied
the pre-change file into the scratchpad, so it expected the session UUID as the project
label. The comparison was real; its subject was not. Re-run from a path shaped
`.../832-Workflow-designer/tools/`, and the row became `0 → 0`.

Third instance this week of a control producing a confident result through a mechanism
unrelated to its subject — and this one would have been *published* as a regression.

## Deliberately not done

`termlink_emit_to` is **not** excused in Rule 0 beside its sibling `emit`. `emit` is
session-local; `emit_to` says it pushes "via the hub", and whether that yields a hub
envelope cannot be settled from the schema. Excusing it would be loosening on an
uncertainty, against the gate's own asymmetry: a false positive is loud and fixable, an
unattributed envelope is silent and unrecoverable. It stays blocked, and the open
question is recorded in the source rather than resolved by guessing.

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
# ── T-494 ─────────────────────────────────────────────────────────────────────
python3 -c "import ast; ast.parse(open('tools/_t420-rail-attribution-gate.py').read())"
bash -n tools/_t426-gate-misfire-matrix.sh
bash tools/_t420-gate-mutation-check.sh
bash tools/_t426-gate-misfire-matrix.sh
# The fix itself: the previously-allowed producer is now refused (exit 2).
sh -c 'printf %s "{\"tool_name\":\"mcp__termlink__termlink_agent_send_auto_discover\",\"tool_input\":{\"to_agent_id\":\"p\",\"message\":\"m\"}}" | python3 tools/_t420-rail-attribution-gate.py >/dev/null 2>&1; test $? -eq 2'
# No regression: a compliant, correctly-labelled post is still allowed (exit 0).
sh -c 'printf %s "{\"tool_name\":\"mcp__termlink__termlink_channel_post\",\"tool_input\":{\"topic\":\"t\",\"payload\":\"x\",\"metadata\":{\"from_project\":\"832-Workflow-designer\"}}}" | python3 tools/_t420-rail-attribution-gate.py >/dev/null 2>&1; test $? -eq 0'
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

### 2026-08-14T06:59:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-494-t-420-gate-agentsendautodiscover-posts-c.md
- **Context:** Initial task creation

### 2026-08-14T07:12:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-09abc28a
- **Timestamp:** 2026-08-14T07:17:59Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T07:17:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
