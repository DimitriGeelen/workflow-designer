---
id: T-782
name: "Re-send the BVP calibration ask to AEF as an explicit pickup request, framed
  as a proposal and not an instruction"
description: >
  The RCA went to agent-chat-arc at @1606 as a note. A topic post creates no work
  item on the counterparty's side and no delivery receipt, and read receipts on this
  rail are dead (one ack, roughly three weeks old), so it is a message they must choose
  to read rather than a request queued for pickup. The operator chose to re-send it
  in pickup form. This task posts the same ask action-shaped with a named deliverable
  and a self-contained measurement recipe, so their agent can treat it as a work item.
  Two constraints hold in the outbound direction and are stated in the message itself:
  a pickup message is a PROPOSAL and never a build instruction (G-020 applies identically
  outbound), and it grants no escalation - their operator rules on whether it is worth
  their time. The ask is unchanged and deliberately still one measurement: D2 and
  F2 no-signal rates over their own scored corpus, which is the one finding a single
  repository cannot settle.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [aef, termlink, bvp]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T21:17:09Z
last_update: '2026-09-21T21:19:26Z'
date_finished:
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
  - ts: '2026-09-21T21:19:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T21:19:26Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.tasks/active/T-782-re-send-the-bvp-calibration-ask-to-aef-a.md,docs/research/executable-workflow/arc-0-exit-clauses.yaml);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-782: Re-send the BVP calibration ask to AEF as an explicit pickup request, framed as a proposal and not an instruction

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Posted `agent-chat-arc` @1609**, `event_type: pickup_request`,
      `conversation_id: BVP-CALIB-RCA-832`, `in_reply_to: "1606"`, attribution
      `from_project: 832-Workflow-designer`.

      Action-shaped: one named deliverable (the `no-signal` rate for D2 and F2 over their own
      scored corpus), and a **self-contained recipe** — a 20-line script that reads only their
      own task files, writes nothing, and needs no access to our tree and no further
      correspondence. A reply of the form `D2 <n>/<N> (<p>%), F2 <n>/<N> (<p>%)` is stated to
      be a complete answer.

      **"We decline" is named as a complete answer too**, on the record, because the one thing
      this rail is bad at is letting us infer a decision from silence.

- [x] **States its own status in its own body.** Opens with *"This is a PROPOSAL, not a build
      instruction. It grants no escalation and authorises nothing on your side"*, and says
      their operator decides, exactly as ours would for an inbound request. G-020 applies
      identically outbound; a pickup request that reads as an instruction is the defect that
      rule exists to prevent.

      Also carries a **scope note** so they can size it before picking it up — read-only over
      files they already hold, no source touched, no subsystem added, should not need an
      inception — with the explicit rider that *their* assessment governs, not ours.

- [x] **Does not re-send the RCA.** References the correlation already on the rail at @1606
      and says so in the first line. A counterparty made to re-read 4,000 words to locate a
      two-number ask is a counterparty who stops reading.

      **Both outcomes committed in advance**, before the number exists: high rates support a
      narrow detector and it is theirs; low rates mean the finding is about our prose and we
      close it here and stop raising it. That advance commitment is what makes this a
      measurement rather than a search for agreement — the same discipline that made the
      round-2 ask in the previous exchange worth answering.

      **Argued against our own interest where honesty required it:** the message repeats that
      `score_blast_radius` must NOT be changed, and says that if picking this up leads anyone
      toward re-opening it, drop the request instead. Getting the ask answered matters less
      than not causing a fixed defect to be re-opened.

- [x] **Ratifies nothing, verified after posting.** Clause-1 register unchanged:
      `attestation: null`, `definition_ratified: false`, `blocks_arc_0_exit: true`. One round,
      stated as one round — if it does not suit, it lapses, and we do not chase it.

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
         1. Run `bin/fw reviewer T-782`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-782 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 -c "import sys; s=open('docs/research/executable-workflow/arc-0-exit-clauses.yaml').read().lower(); sys.exit(0 if ('blocks_arc_0_exit: true' in s and 'definition_ratified: false' in s) else 1)"
python3 -c "import yaml,sys; d=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml')); c=d['clauses']; sys.exit(0 if len(c)==3 and all(x.get('attestation') is None and x.get('definition_ratified') is False and x.get('blocks_arc_0_exit') is True for x in c) else 1)"
grep -q '@1609' .tasks/active/T-782-re-send-the-bvp-calibration-ask-to-aef-a.md

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
     fw inception decide T-782 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T21:17:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-782-re-send-the-bvp-calibration-ask-to-aef-a.md
- **Context:** Initial task creation
