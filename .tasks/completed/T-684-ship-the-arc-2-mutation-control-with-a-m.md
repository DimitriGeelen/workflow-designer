---
id: T-684
name: "Ship the Arc-2 mutation control with a meta-assertion, so a red that never fired cannot read as green"
description: >
  T-681 S2 proved the control buildable (prototype at docs/research/executable-workflow/_t681-s2-mutation-control-prototype.py) but its first run reported NO-GO for a broken reason: the mutated guard refused the escape id on grounds unrelated to containment, so phase 2 could not have gone red however broken the fence was (PL-177). The shipped control must assert that the mutated guard ADMITS the escape id, distinguishing 'no breach' from 'never tested'.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [ewcr, arc-2, isolation]
components: [tools/_t684-mutation-control.py]
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-05T17:26:20Z
last_update: 2026-09-07T21:16:32Z
date_finished: 2026-09-07T21:16:32Z
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

# T-684: Ship the Arc-2 mutation control with a meta-assertion, so a red that never fired cannot read as green

## Context

T-683 shipped the containment fence on `/api/save`. This ships the control that keeps it
honest: a mutation control that breaks the fence on purpose, confirms the breach is
*observable*, then confirms the fence refuses it.

The prototype (`docs/research/executable-workflow/_t681-s2-mutation-control-prototype.py`)
reported a verdict for a broken reason. Its baseline phase expected the pristine server to
refuse the escape id — but `ID_RE` rejects `../escaped` on format grounds long before
containment is consulted, so that phase refused whether or not a fence existed. It was
measuring the regex and reporting on the fence (PL-177).

The fix is a third verdict. GREEN requires the manufactured breach in phase A to have
actually escaped; if it did not, the run reports INCONCLUSIVE rather than passing. A
two-valued control that loses the ability to see breaches reports GREEN forever.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The control runs three phases against temp copies of `gallery-serve.py`, never
      mutating the tracked file: **A** guard removed *and* `ID_RE` widened → the save MUST
      escape; **B** `ID_RE` widened, containment guard intact → the save MUST be refused;
      **C** pristine → refused. *(Measured: A HTTP 200 escaped=True; B HTTP 400
      escaped=False; C HTTP 400 escaped=False.)*
- [x] **The meta-assertion:** a GREEN verdict is conditional on phase A having actually
      escaped. If phase A does not escape, the run reports **INCONCLUSIVE**, never GREEN —
      the harness manufactured a breach and could not observe it, so phase B's refusal is
      unevidenced. This is the T-681 S2 failure (PL-177) made structurally impossible.
      *(`if not a_escaped:` precedes the breach check, so INCONCLUSIVE wins over any
      reading of phase B.)*
- [x] Phase C's refusal is reported as **format-grounds, not containment evidence**, and is
      explicitly excluded from the GREEN decision. `ID_RE` rejects `../escaped` before the
      fence is reached, so counting that refusal as a passing fence is the original error.
      *(Phase C's status feeds only the printed line, never the verdict branch.)*
- [x] Distinct exit codes: `0` GREEN (fence proven), `1` BREACH (phase B escaped), `2`
      INCONCLUSIVE (phase A did not escape / harness could not observe).
- [x] `--self-test` proves INCONCLUSIVE is reachable by sabotaging phase A, so the control's
      own refusal-to-conclude is demonstrated rather than asserted. *(Measured: sabotaged
      run returns exit 2. Notably all three phases then read `400/False` — which reads as
      "the fence holds everywhere" and is precisely T-681 S2's false verdict.)*
- [x] The control leaves nothing behind: no mutated server copies, no escape witness inside
      the repo, and `git status` on `tools/gallery-serve.py` is clean after a run.
      *(Verified: empty `git status --short` on the server, no `escaped/` in the tree;
      temp servers removed in a `finally`, temp repos removed per phase.)*
- [x] Runs GREEN against the current tree (T-683's fence in place). *(exit 0.)*

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
         1. Run `bin/fw reviewer T-684`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-684 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 tools/_t684-mutation-control.py
python3 tools/_t684-mutation-control.py --self-test
python3 tools/_t683-save-containment-verify.py
# the control must not mutate the tracked server it inspects
test -z "$(git status --short tools/gallery-serve.py)"
# negative leg: the escape witness must never be left inside the repo tree
test ! -e escaped

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

### 2026-09-07 — the prototype's baseline was measuring the regex, not the fence

- **What changed:** T-681 S2's phases were baseline / mutated / reverted, with baseline
  expected to refuse. But `ID_RE` rejects `../escaped` on FORMAT grounds before containment
  is ever consulted, so that refusal happens whether or not a fence exists. The prototype's
  "fence held" phase was reporting on the regex. That is why its first run produced a
  verdict for a broken reason.
- **Plan impact:** the phase set changed. A pristine run cannot be the control's evidence,
  so phase C is now *reported and explicitly excluded from the verdict*. The evidence-bearing
  pair became A (guard removed AND regex widened, must escape) and B (regex widened only,
  must refuse) — B is the assertion, A is what makes B mean anything.
- **Triggered:** no new task. A third verdict, INCONCLUSIVE, had to exist: with only
  pass/fail, a harness that lost the ability to see breaches reports GREEN forever. The
  self-test demonstrates it, and the sabotaged run is worth keeping in mind — all three
  phases read 400/False, which looks like the strongest possible pass.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-07 — INCONCLUSIVE is a verdict, not an error state

- **Chose:** three exit codes — 0 GREEN, 1 BREACH, 2 INCONCLUSIVE — with INCONCLUSIVE
  checked BEFORE the breach branch.
- **Why:** the failure being defended against is not "the fence broke", it is "the harness
  stopped being able to tell". Those need different exits because they need different human
  responses: a breach is a bug in the product, an inconclusive is a bug in the evidence. A
  two-valued control has to map the second onto one of the first two, and whichever it picks
  is a lie — GREEN hides it, RED cries wolf until someone disables the check.
- **Rejected:** *(a)* treating a failed phase A as a hard error/crash — an error reads as
  infrastructure noise and gets retried past; a verdict gets read. *(b)* Asserting phase A
  inside the self-test only, leaving the live run two-valued — the live run is exactly where
  the harness would silently degrade, so the assertion has to be in the live path.

### 2026-09-07 — mutate copies, never the tracked file

- **Chose:** every phase runs a temp copy of `gallery-serve.py`; the tracked file is read
  and never written, with a P-011 leg asserting `git status` on it stays clean.
- **Why:** a control that edits the file it is testing can leave the repo mutated when it
  crashes mid-run — and the mutation it applies is *removing a security guard*. An
  interrupted run must not be able to leave the fence out of the tree.
- **Rejected:** patch-and-revert in place with a `finally` restore — a `finally` does not
  survive SIGKILL or a machine losing power, and the failure mode is a silently
  guard-less server in a tracked file.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-684 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-05T17:26:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-684-ship-the-arc-2-mutation-control-with-a-m.md
- **Context:** Initial task creation

### 2026-09-07T21:12:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ab9ca1c4
- **Timestamp:** 2026-09-07T21:16:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-07T21:16:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
