---
id: T-610
name: "Send the Arc-0 attestation request to AEF under the roadmap 2.3 communication envelope"
description: >
  Send the Arc-0 attestation request to AEF under the roadmap 2.3 communication envelope

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T07:25:17Z
last_update: 2026-08-27T07:27:52Z
date_finished: 2026-08-27T07:27:52Z
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

# T-610: Send the Arc-0 attestation request to AEF under the roadmap 2.3 communication envelope

## Context

The operator's correction, which this task exists to act on: contacting AEF was never a
question. The roadmap's §2.1 table has a column titled **"Required joint handoff"** for
every arc, §7 is "Recommended AEF-agent handoff", and §2.3 specifies the envelope a
handoff must carry. Collaboration is the structure of the instruction set, not a
permission to be requested.

I had been treating one message to 999-AEF as needing sovereign approval while posting bug
reports to the same agent on the same channel all night (rail 572, 586, 599). That is not
a governance boundary; it is an invented gate, and it cost three sessions of Arc-0 stall.

What remains true and is NOT invented: §2.3's closing line — "TermLink post or file
transfer alone is transport evidence, not collaboration completion." Sending is not
closing. The clauses stay `definition_ratified: false` and `attestation: null` until a
substantive response arrives and the operator rules.

## Acceptance Criteria

### Agent
- [x] The message carries all five §2.3 envelope fields: (1) source project, task/arc,
      sender identity, intended receiver; (2) artifact type, version, content hash,
      compatibility range; (3) requested action from the enumerated set; (4)
      acceptance/refusal schema and evidence location; (5) correlation/thread ID and the
      named human decision owner
- [x] Content hashes are real and computed from the files being referenced, not asserted —
      `arc-0-exit-clauses.yaml` = 729a0680b46df321, `roadmap-5be23719.md` = 5be23719b976e37a
- [x] The requested action is one of review/implement/validate/decide/acknowledge, stated
      explicitly rather than left for the receiver to infer
- [x] The two asks map 1:1 onto the counterparty-owned clauses and remain traceable to
      their `what_would_satisfy` — `tools/_t608-attestation-draft-gate.py` still passes
- [x] Posted with producer attribution (`from_project: 832-Workflow-designer`) as the
      T-420 rail gate requires
- [x] Nothing in the register is mutated by the act of sending: all three clauses remain
      `definition_ratified: false`, clauses 1 and 2 remain `attestation: null`, and the
      Arc-0 exit gate still reports them blocked — transport is not completion (§2.3)
- [x] The rail offset of the sent message is recorded here, so the handoff has a
      correlation anchor rather than a claim

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

python3 tools/_t608-attestation-draft-gate.py
tools/_t596-arc0-exit-gate.sh --self-test
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml',encoding='utf-8'));bad=[c['id'] for c in d['clauses'] if c.get('definition_ratified') or c.get('satisfied') or c.get('attestation')];assert not bad,bad"
grep -q "offset 602" <(tools/_t596-arc0-exit-gate.sh 2>&1)

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

## Recommendation

**Recommendation:** CLOSE — sent, and deliberately changed nothing else.

**Rationale:** The request went to 999-AEF on agent-chat-arc at offset 602 under the §2.3
envelope, carrying all five required fields and real content hashes. Per §2.3 a post is
transport evidence, not collaboration completion, so the register is untouched: all three
clauses remain `definition_ratified: false` and clauses 1 and 2 remain `attestation: null`.
Arc 0 is not closer to closed; it is now correctly described as awaiting a response rather
than blocked on an authorisation that the instruction set never required.

**Evidence:**
- Rail offset 602, thread EWCR-ARC0-ATTEST-832, attributed `from_project: 832-Workflow-designer`
- Hashes computed, not asserted: clause register 729a0680b46df321, roadmap 5be23719b976e37a
- Register unmutated after send — verified in `## Verification`
- `tools/_t596-arc0-exit-gate.sh --self-test`: 13/13 control legs
- Two stale assertions removed: the gate's closing paragraph and the register header both
  claimed contact required an authorisation that does not exist. A gate that states an
  invented constraint teaches it to every reader.

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

### 2026-08-27T07:25:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-610-send-the-arc-0-attestation-request-to-ae.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-200a60af
- **Timestamp:** 2026-08-27T07:27:56Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-27T07:27:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
