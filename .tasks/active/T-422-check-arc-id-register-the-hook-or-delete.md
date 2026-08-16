---
id: T-422
name: "check-arc-id: register the hook or delete the promise"
description: >
  T-421 finding. The task template asserts a PreToolUse hook (check-arc-id) blocks
  saves whose arc_id does not resolve. It is not registered in this project and never
  has been, so the sentence ships in every task file and has never been true. Two
  remedies, and they are different decisions: register the hook (adds enforcement
  that will start refusing saves) or delete the sentence (admits the absence). Operator
  call because the first changes behaviour for every future task write.

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T19:36:51Z
last_update: '2026-08-16T12:33:28Z'
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
  - ts: '2026-08-16T12:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
---

# T-422: check-arc-id: register the hook or delete the promise

## Context

T-421's claim-drift detector found that the task template promises a `check-arc-id`
PreToolUse hook that is not registered here. Filed as ours to fix.

**It is not ours.** AEF measured the thing this project has no second population to see
(rail 522 §1, 2026-08-10), on a real `fw init`'d consumer under `env -i`:

    this framework repo   24 hooks
    any fresh consumer    17 hooks

Our 17 is the vendored default, exactly. Seven hooks have never shipped to any consumer:
`check-arc-id`, `check-onboarding-gate`, `check-inception-decisions`,
`check-inception-schema`, `check-active-completed-dup`, `check-heredoc-cmd-sub`,
`check-settings-edit`.

Root cause is on AEF's side and was predicted in their own source: `fw hook-enable`
writes only `.claude/settings.json`, while a consumer's file is generated from a separate
hardcoded list in `lib/init.sh generate_claude_code_config`. `bin/hook-enable.sh:120`
carries the comment *"Mirrors lib/init.sh:generate_claude_code_config; both sites must
change together (L-399 producer/consumer parity)"* — it names the failure and both sites,
and was broken seven times. Filed there as **T-2911** (parity) and **T-2912** (the
`fw upgrade` false-success that reports the seven as fixed and never converges).

AEF's explicit instruction: **do not hand-add the seven.** They would be correct today and
diverge silently at their next hook.

**What this task is now:** not a build. A disposition decision about a promise this
project cannot keep and did not make.

## Acceptance Criteria

### Agent
- [x] Blast radius measured BEFORE registering: how many task files carry an `arc_id`
      that does not resolve, and would therefore become unsaveable. Registering a
      validation hook against a corpus that fails it wedges every subsequent edit — the
      G-026 gate-refuses-its-own-remedy class, self-inflicted.
      **Measured 2026-08-10 across `.tasks/active/` + `.tasks/completed/`: 3 files carry
      an `arc_id`, 0 unresolved.** The only arc on disk is `designer-authoring-surface`.
      Registering would have been safe. Worth stating plainly: the blast-radius check
      cleared option A, and option A is still wrong — for a reason no measurement
      available inside this repo could have produced.
- [ ] Whichever remedy the operator picks is applied, and
      `python3 tools/_t421-enforcement-claim-drift.py` reflects it — **gone** if the
      promise is deleted, **baselined with a dated reason pointing at AEF T-2911** if the
      promise is left standing as theirs to keep. Baselining is only honest here because
      the remedy genuinely sits in another repo; it is not "baselined away".
- [ ] If REGISTER (option A, contraindicated): live interception verified in a session
      started AFTER registration. Hook config is snapshotted at session start (OBS-015),
      so this cannot be confirmed in the session that registers it. Do not tick on the
      strength of the file content. *(Method now proven — see T-420 AC2, verified
      2026-08-10 with a scratch-topic negative, a hub-side `count: 0`, and a positive
      control. The three-leg shape transfers to any gate.)*

### Human
- [ ] [REVIEW] The premise changed after this task was written. Register, delete, or wait?

  **⚠ MY EARLIER RECOMMENDATION (A — register it) IS WITHDRAWN.** If you already acted on
  it, say so and I will unwind it. The evidence that overturned it arrived on the AEF rail
  at offset 522 and could not have been produced from inside this repo — it needed a
  second population. See `## Context`.

  The task template tells every task file:

      # arc_id: ... PreToolUse hook (check-arc-id) blocks save under agent
      #        control if it doesn't resolve.

  The sentence has never been true here — and now we know it has never been true in **any**
  AEF consumer. `check-arc-id` is one of seven hooks that exist in the framework repo and
  are absent from the consumer template. It is AEF's shipping defect (their T-2911),
  reproduced identically in every consumer, and they have asked us not to hand-patch it.

  **A — Register it. NOT RECOMMENDED.** Blast radius is 0, so it would work today. It
  also forks our `.claude/settings.json` from the vendored default, and AEF's next hook
  addition diverges us silently — trading a visible false promise for an invisible one.

  **B — Delete the sentence.** The tree stops promising what it does not do. Cost: our
  `.tasks/templates/` diverges from the vendored default in the other direction, and when
  AEF's parity fix lands and the hook actually ships, our template no longer documents a
  gate that is now real.

  **C — Neither. Record it as theirs, keep it visible, wait for T-2911.** Pin
  `check-arc-id` in the claim-drift baseline with a dated note naming AEF T-2911 as the
  remedy. Nothing in our tree changes. The false promise stays — but it is now a *known,
  attributed, externally-owned* false promise rather than an unexplained one, and the
  detector still fails if a **second** unbacked claim appears.

  **Recommendation: C.**
  Both A and B are local edits to files whose whole value is being the unmodified vendored
  default; each fixes today's sentence by creating tomorrow's divergence. C is the only
  option that leaves the defect where its fix lives. The cost of C is honest and small:
  `arc_id` typos stay unvalidated, against a corpus of 3 files with 0 typos.

  **Steps:**
  1. `cd /opt/832-Workflow-designer && python3 tools/_t421-enforcement-claim-drift.py`
  2. Confirm the CLAIMED-BUT-OFF section names `check-arc-id` and nothing else
  3. Record the decision:
     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "check-arc-id: C" --task T-422 --rationale "AEF T-2911 owns it; hand-patching forks the vendored default and diverges at their next hook"`
     (substitute `A` or `B` with your own rationale to overrule)

  **Expected:** a decision recorded against T-422; the agent then executes it and closes
  the task.

  **If not:** if you want the validation regardless of provenance — a locally-owned
  arc_id check that does not pretend to be the framework's — say so and I will scope it
  as its own task rather than registering theirs.



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

## Recommendation

**Recommendation:** GO on **C — record it as theirs, keep it visible, wait for AEF
T-2911.**

**⚠ This supersedes an earlier recommendation of A (register it), which is WITHDRAWN.**
If you already acted on A, say so and I will unwind it. The evidence that overturned it
arrived on the AEF rail at offset 522 and **could not have been produced from inside this
repo** — it needed a second population.

**Rationale.** Both A and B are local edits to files whose entire value is being the
unmodified vendored default; each fixes today's sentence by creating tomorrow's
divergence. A registers a hook and forks our `.claude/settings.json`, so AEF's next hook
addition diverges us **silently** — trading a visible false promise for an invisible one.
B deletes the promise from `.tasks/templates/`, and then when AEF's parity fix lands and
the hook actually ships, our template no longer documents a gate that has become real.
C is the only option that leaves the defect where its fix lives, and it keeps the claim
under detection rather than under a patch.

**Evidence — AEF measured it on a real `fw init`'d consumer under `env -i`, rail 522 §1,
2026-08-10:**

    this framework repo   24 hooks
    any fresh consumer    17 hooks

Our 17 is the vendored default **exactly**. Seven hooks have never shipped to any
consumer: `check-arc-id`, `check-onboarding-gate`, `check-inception-decisions`,
`check-inception-schema`, `check-active-completed-dup`, `check-heredoc-cmd-sub`,
`check-settings-edit`. Root cause is on their side and was predicted in their own source:
`fw hook-enable` writes only `.claude/settings.json`, while a consumer's file is generated
from a separate hardcoded list in `lib/init.sh generate_claude_code_config`. It is their
shipping defect (T-2911), reproduced identically in every consumer, and they have asked us
not to hand-patch it.

**The cost of C, stated rather than glossed:** `arc_id` typos stay unvalidated. Against a
corpus of 3 arc files with 0 typos, that is a real but small exposure, and the claim-drift
detector still fails if a **second** unbacked claim appears — so C does not blind us, it
attributes one known blindness.

**Note for the record:** this is the second finding in the last week that only existed
because a peer could see a population we cannot. AEF ran our own unwired-instrument census
against their tree and found the mirror of `check-onboarding-gate` — four hook-shaped
scripts in their live hook directory with zero references in `settings.json`. Neither
project could have found its own instance alone.

**What your ruling unblocks:** the disposition is a one-line decision record; I execute it
and close T-422 either way.

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

### 2026-08-10 — a correct instrument produced a confident wrong owner
- **What changed:** T-421's detector was right that the tree asserts something untrue. I
  then attributed it to drift in *this* project, because this project's tree was the only
  population I could measure. AEF measured a second population and the finding inverted:
  never drift, never ours, present in every consumer.
- **Plan impact:** T-422 stops being a build task. Both original options (register /
  delete) are now local edits to vendored-default files, and each buys a correct sentence
  today at the price of silent divergence later. Option C added and recommended.
- **The lesson worth keeping:** the blast-radius check *cleared* option A — 3 files with
  `arc_id`, 0 unresolved. A safe, measured, well-evidenced recommendation was still wrong,
  because every measurement available inside the repo was consistent with both stories.
  **A single-population measurement cannot distinguish "we changed" from "we were never
  given".** Registering would have felt like diligence and would have forked us.
- **Triggered:** rail 523 §1 (withdrawal reported to AEF); recommendation flipped in front
  of the operator *before* they acted on it.
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

### 2026-08-10T19:36:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-422-check-arc-id-register-the-hook-or-delete.md
- **Context:** Initial task creation

### 2026-08-10T20:20:31Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
