---
id: T-604
name: "Chromium-driven verification legs fail nondeterministically on unchanged code, reddening the P-011 gate"
description: >
  Chromium-driven verification legs fail nondeterministically on unchanged code, reddening the P-011 gate

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T19:52:53Z
last_update: 2026-08-26T20:11:15Z
date_finished: null
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

# T-604: Chromium-driven verification legs fail nondeterministically on unchanged code, reddening the P-011 gate

## Context

OBS-313: `fw task update T-603 --status work-completed` failed the P-011 gate on
`node tools/_t603-multiprocess-import.mjs --self-test` (exit 2), then passed on immediate
re-run, standalone, under the gate's exact subshell form, and back-to-back. Identical bytes,
two verdicts. I recorded the cause as "the second Chromium appears to hit the fixed 25s
timeout under contention" — an APPEARANCE, not a measurement, and I closed the question on it.

010-termlink @546 handed back the general shape from a different substrate: a stale bytecode
cache served an unmutated module, so a poison arm reported green without ever executing.
"Same bytes, two verdicts, decided by whether a cache directory existed." Their rule —
AN ARM THAT NEVER EXECUTED IS PERFECTLY FAITHFUL AND STILL PROVES NOTHING — is what sent me
back to my own unexplained instance rather than leaving it filed.

The suspected mechanism is NOT the load timeout. Every CDP driver does:

    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    client = cdpClient(targets.find(t => t.type === 'page').webSocketDebuggerUrl);

`DevToolsActivePort` is written when the BROWSER is listening, which is not the same instant
the PAGE target is registered in `/json`. In that window `find()` returns `undefined` and the
property access throws a bare `TypeError`, surfacing as `DRIVER ERROR ... exit 2` — the exact
observed symptom, and nondeterministic exactly as observed. If that is the cause, the fix I
had written down (raise the timeouts) would have changed nothing and the flake would have
persisted while looking addressed.

Direction matters: this fails CLOSED, which is the safe direction. But a gate that
intermittently reddens correct work is precisely the pressure that trains `--skip-verification`
into an operator's fingers, so an unexplained flake is a governance defect, not just a bug.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The race is REPRODUCED and measured before any fix is written: a recorded run that
      catches `/json` returning no page target, with counts and the port-ready timing window.
      If it does not reproduce, the hypothesis is discarded and re-formed rather than assumed
- [x] Every CDP driver that resolves a page target from `/json` retries within a bounded
      budget instead of dereferencing an unguarded `find()`
- [x] A driver that genuinely cannot attach fails with a message NAMING the cause, not a bare
      `TypeError` — the failure is distinguishable from a real leg failure at a glance
- [x] Determinism is asserted on the OUTCOME, not on the instrument's belief: N consecutive
      runs of a real self-test under deliberate CPU contention return the SAME verdict on
      unchanged code, and the run count and verdicts are recorded
- [x] A poison arm restores the unguarded `find()` and drives the attach legs RED, proving
      they can fail; controls unrelated to attach stay green under the same arm
- [x] The fix is applied to every affected driver in `tools/`, enumerated by a scan rather
      than by memory, and the scan is part of the verifier so a new driver cannot regress it
- [x] `.context/inbox.yaml` OBS-313 records the measured cause, and explicitly corrects the
      timeout guess if the measurement disproves it

### Human

None. Every criterion here is a determinism measurement with a numeric outcome — there is no
taste call to make, so routing one to the operator would be manufactured review load.

<!-- template guidance retained below, intentionally inert
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

### 2026-08-26T19:52:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-604-chromium-driven-verification-legs-fail-n.md
- **Context:** Initial task creation

## Verification (T-604 legs)

node tools/_t604-cdp-attach-race.mjs
node tools/_t604-cdp-attach-race.mjs --self-test

## Decisions

- **One shared definition, not a pattern to re-type.** OBS-304 named this race and it was
  fixed at four call sites. Seventy-three others kept the defect and _t366 documented it in
  prose as a "remaining unguarded race" without fixing it. A guard that exists in four copies
  and is absent from seventy-three is not a guard, it is a coincidence. So the retry lives in
  tools/_cdp-attach.mjs and every driver imports it.
- **The hypothesis was tested and the first repro LIED.** A standalone probe reproducing the
  driver's spawn sequence reported NOT REPRODUCED across 26 spawns, quiet and under 2x CPU
  load, because it killed each browser before starting the next. The real failure needs the
  SECOND browser of a self-test, spawned during the first's lifetime. An unfaithful repro
  yields a false NEGATIVE — the mirror of an unfaithful poison arm's false positive, same
  root: the test and its subject must be the same object.
- **The timeout diagnosis in OBS-313 was wrong and is corrected, not quietly dropped.** The
  failing run took 3s against 5-6s for passing runs. It failed FASTER, so a 25s load timeout
  could never have been the cause. Raising the timeouts would have changed nothing while
  looking addressed.
- **Two poison arms, because one cannot reach both defects.** The helper's retry and the call
  sites are different code. Arm A restores the pre-fix helper (single unretried read) and
  drives L2/L3 red; arm B restores a hand-rolled deref in one driver COPY and drives L1 red.
  A single arm would have left the other leg asserting nothing.
- **L2 is the discriminator, L5 is the faithful check.** L5 spawns a real Chromium, but a real
  browser attaches successfully most of the time — it passed 26/26 before the fix too, so it
  cannot discriminate on its own. L2 uses a stub /json that withholds the page target for four
  polls, which makes the race deterministic and the poison signal reliable.
- **execFile, not execFileSync, inside the poison arm.** The stub server lives in the same
  process, so a synchronous child blocks the event loop that must answer it. The first arm
  deadlocked rather than reporting. A poison arm that hangs proves as little as one that never
  executed.
- **The verifier is excluded from its own scan by NAME, in a fixed two-entry set.** Its job is
  to contain the pre-fix shape. The exemption is a literal list rather than a pattern so a new
  driver cannot quietly qualify for it.
