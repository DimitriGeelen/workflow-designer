---
id: T-579
name: "The third-party byte-identity gate is RED and no runner has ever seen it"
description: >
  tools/_t358-byteid-thirdparty.mjs exits 1 today: 0 identical / 11 drifted, and it prints PRECONDITION VIOLATED — boundary-events (2 same-lane x tie groups) and kitchen-sink (14) tie among uid-less nodes, so its uid-only normaliser is unsound and it says so. Nothing runs it: run-bridge-tests.sh has no leg, and its only code caller is tools/_t364-byteid-precondition-teeth.py, which _t509-instrument-sweep.sh EXCLUDES by design. T-364 predicted this in writing — 'boundary-events (2 groups) and kitchen-sink (11 groups) already hold uid-less collision groups in their DI, so adopting DI as geometry supplies the missing ingredient' — and T-423 adopted DI. The operator ruling on T-364 also directed narrowing the precondition to 'nondeterministically minted' after repair (a) landed; repair (a) landed, the narrowing did not. Found while measuring T-501 IW-0, whose deferral names this gate as its safety net.

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
created: 2026-08-23T21:44:44Z
last_update: 2026-08-24T17:25:40Z
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

# T-579: The third-party byte-identity gate is RED and no runner has ever seen it

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

**Two failure modes are entangled in one rc=1 and must be separated before either is
touched.** The gate prints `PRECONDITION VIOLATED` *and* `0 identical, 11 drifted`. They
have different causes and different fixes, and a repair aimed at the compound symptom
would "fix" the gate by silencing whichever one it happened to reach.

- [x] **Failure mode A is diagnosed: is the precondition genuinely over-strict now?**
  It refuses when a same-lane x tie coincides with a uid-less source, on the stated
  ground that the tie-breaking uid was "minted nondeterministically". T-364 repair (a)
  landed — uid now derives from the BPMN element id — so that ground may be stale.
  Measure whether a uid-less document now receives a *deterministic* uid; do not infer it
  from the fact that repair (a) was committed. The operator's T-364 ruling already
  prescribes the remedy **if** it is stale: NARROW the predicate to "nondeterministically
  minted", **never delete it** — "a guard that cries wolf after a repair looks identical
  to one that was always wrong, and removal is the cheap response to both."

  **ANSWER: NO, and the assumption behind this AC was wrong — the narrowing already
  happened, and it went further than the operator's ruling prescribed.** Read at
  `_t358-byteid-thirdparty.mjs:160-178`. The author measured the predicted narrowing and
  found it insufficient: this tool is a **CROSS-BUILD** diff, so within-build determinism
  does not settle it. A uid-less node gets a *random* uid in the baseline build and a
  *derived* one in the current build (`deriveUid`, FNV-1a over the element id,
  `src/aef-workflow-designer.html:10227`), and if those two orders disagree at a tie the
  emitted element ids permute regardless of how deterministic either side is alone.
  The shipped predicate is `uidSig` inequality **across the two builds** plus a
  within-build stability probe — strictly more honest than either earlier form, measured
  rather than inferred from source bytes. **It is firing correctly.** There is nothing to
  narrow, and narrowing it as this AC assumed would have broken a working guard.
- [x] **Failure mode B is diagnosed: what is the 11-drift measured against?** The first
  diff line on every fixture is `targetNamespace=…` vs `exporter="aef-workflow-designer"`,
  which looks like a baseline ref predating the exporter attribute rather than a
  regression in what the gate guards. Establish which ref it compares to and whether the
  drift is real or a stale comparand. Report the answer either way — a gate red for a
  boring reason is still a gate nobody can read.

  **ANSWER: a stale comparand.** `_t358-byteid-thirdparty.mjs:48` pins
  `BASELINE_REF = process.argv[2] || '3bf37909~1'` — the commit *before* T-358's own
  lane-provenance work. That designer predates the `exporter` root attribute, T-423's
  unconditional DI, and T-364 repair (a). So "11 drifted" does not mean *regression*; it
  means *time has passed*, and every ratified export change since is counted as drift.

  **THE TWO FAILURE MODES HAVE ONE CAUSE, which is the finding.** The pinned baseline
  predates repair (a), so the baseline build mints random uids while the current build
  derives them — that is precisely why `uidSig` differs across builds and the precondition
  fires. Both symptoms are the stale pin. And the file says so itself, at :173-175: *"it
  self-heals: once BASELINE_REF moves past the repair both sides derive identically, the
  vectors match, and this stops firing without anyone editing it."* The gate is not
  broken. It is correctly reporting that it is being asked an obsolete question.

- [ ] **The pin is moved, and moved by whoever owns that call.** Re-pinning a
  byte-identity baseline is a re-baselining decision, not a bug fix: it declares "the
  export surface as of ref X is the accepted one", and everything between the old pin and
  the new stops being visible to this gate forever. That is the same class of act PD-253
  refused to take unilaterally for the unwired ratchet. Surfaced to the operator on
  `/approvals` with the evidence and the exact command rather than chosen here.
- [ ] **The gate is invoked by something that runs.** Today its only executable-code
  caller is `tools/_t364-byteid-precondition-teeth.py:40`, which
  `_t509-instrument-sweep.sh:66` EXCLUDES by design — so no runner has ever seen it red.
  Either wire it as a suite leg, or record why it must not be one; leaving it as the
  standing evidence for a claim nobody re-runs is what T-565 found and is not an option.
- [ ] **`_t364-byteid-precondition-teeth.py` still passes after any change**, control and
  teeth both. Its whole purpose is to prove the hazard bucket is fillable and does not
  fire on the real set; a precondition edit that quietly breaks its teeth removes the only
  evidence the predicate discriminates.

### Human

- [ ] [REVIEW] **Choose the new `BASELINE_REF` for the third-party byte-identity gate.**
  The gate is red for one reason: its baseline is pinned at `3bf37909~1`, a designer that
  predates the `exporter` attribute, T-423's unconditional DI, and T-364 repair (a). Both
  its symptoms — `PRECONDITION VIOLATED` and `0 identical / 11 drifted` — are that one
  pin. **Nothing about the gate's logic is wrong**; its precondition was already narrowed
  correctly and further than the T-364 ruling asked (see the Agent ACs above).

  **Why this is yours and not mine:** moving the pin declares *"the export surface as of
  ref X is the accepted one"*, and every change between the old pin and the new one stops
  being visible to this gate permanently. That is re-baselining, the same act PD-253
  declined to take unilaterally for the unwired ratchet — and it would silently accept
  T-423's DI adoption as third-party-safe, which no one has verified for that population.

  **Steps:**
  1. The natural candidate is **`652364f1`** — "T-364: implement repair (a)", the commit
     that makes both builds derive uids identically. That is the minimum move that heals
     the precondition. It still counts DI adoption as drift, which may be what you want.
  2. See what the gate says against it before deciding anything, single line, any directory:

     `cd /opt/832-Workflow-designer && node tools/_t358-byteid-thirdparty.mjs 652364f1`

  3. If that reads correctly, pin it by editing `BASELINE_REF` at
     `tools/_t358-byteid-thirdparty.mjs:48`, and record the decision:

     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-579: re-pin third-party byte-identity BASELINE_REF to <ref>" --task T-579 --rationale "<what the ref's export surface is accepted as>"`

  **I RAN STEP 2 FOR YOU. Result: the pin fixes half, and names the other half.**
  Against `652364f1`: **`PRECONDITION VIOLATED` is GONE** — the precondition holds, which
  confirms the diagnosis that the stale pin caused it. Still **0 identical / 11 drifted**,
  rc 1. On all 11 fixtures the **first** differing line is the same one:

      line 8  baseline: targetNamespace="https://aef.anchorpoint.dev/workflows">
              current : exporter="aef-workflow-designer"

  So `652364f1` still predates the `exporter` root-attribute provenance stamp. That stamp
  is a known, ratified addition — T-423's additive-export guard allow-lists exactly it.

  **What this run does NOT tell us, stated because it is easy to assume otherwise:**
  whether T-423's unconditional DI *also* moves third-party bytes. This tool reports only
  the FIRST differing line, and on every fixture that line is the `exporter` attribute, so
  everything after it is unexamined. I am not claiming DI is clean here and I am not
  claiming it is dirty. Nobody has run an additive-export check over the third-party
  population — T-423's guard ran over the rendered 24, which is the same scope mistake
  T-565 found one task ago.

  **Expected:** you pick a ref *after* the `exporter` stamp, re-run step 2, and read a
  verdict that reflects only changes you have ratified.

  **If it is still red after that:** the residue is something later than the stamp, most
  likely DI, and that is a real question about T-423 over a population it never covered —
  not a pin choice. Say so and leave the pin alone. A gate honestly red is worth more than
  a green one bought by moving the line it measures from.

<!-- Original Human template guidance below. -->
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

### 2026-08-24 — this was parked as a sovereignty question and it is not one

- **What changed:** re-examined why this task is blocked. I wrote it up as "the operator
  owns the pin". Nothing structural says so — `BASELINE_REF` is a string literal at
  `tools/_t358-byteid-thirdparty.mjs:48`, there is no `$CLAUDECODE` refusal, no
  `acd_gate`, no Tier-0 pattern anywhere near it. The reason I gave was that moving a pin
  ratifies everything between old and new. That reason is real but it does not make the
  act sovereign, and it argues against the framing anyway: **the gate is red AND invoked
  by nothing, so it is providing zero coverage right now.** Preserving the visibility of
  intervening changes preserves nothing when nothing looks.
- **Plan impact:** the two open ACs are not blocked on a ruling. They are blocked on a
  design question nobody has asked: **what should this gate's baseline BE, if not a
  literal?** `3bf37909~1` was never chosen as a ratification point — it is simply where
  the file sat on 2026-08-04. Any hand-picked successor goes stale the same way, on the
  same clock; picking one is choosing when the next session repeats this task. The
  candidate shapes (a recorded ratification file the gate reads, a merge-base, a
  last-green marker) are a deliverable, not a ruling.
- **Why not started here:** budget. Starting a redesign of a byte-identity gate's
  baseline at 180K is the slice that cannot finish, and a half-moved baseline is worse
  than a stale one. Filed as its own task rather than continued under this ID.
- **Triggered:** the pin decision comes OFF `/approvals` as a sovereignty item. What is
  left for a human here is ordinary review of whatever the redesign proposes, not a
  ruling this task can block on.

### 2026-08-24 — the drift this pin would ratify just grew, and it grew from our own commit

- **What changed:** T-563 landed the T-501 GO item 2 change — documents with no
  `<aef:workflowMeta>` now derive their workflow id through `sanitizeWorkflowId(procId)`
  instead of a display label. Measured through the real page: **all 14** such documents
  derive a different id than before (`Process_1` → `process_1`, `EU Bank` →
  `009164cd-…`, `No lane set` → `proc_nolaneset`). The workflow id reaches the emitted
  XML as `Collaboration_${id}` and `Process_${id}`, so those 14 documents — 10 of which
  are `_t358`'s fixture set — now export different bytes.
- **Plan impact:** none to the diagnosis, which stands: the `PRECONDITION VIOLATED`
  and the 11 drifted both trace to `BASELINE_REF` pinned at `3bf37909~1`. But the
  operator's ruling below is now choosing among MORE accumulated change than when it
  was written. Whatever ref is chosen, moving the pin ratifies the `exporter` provenance
  stamp, T-423's DI adoption, T-364 repair (a), **and now T-563's id derivation** — and
  after the move none of them is visible to this gate again.
- **What has NOT changed and is worth restating:** the change T-563 made was already the
  operator's decision — T-501's GO ratified this exact chain. What is being surfaced
  here is only that the *pin* decision's scope grew, not that a new behaviour needs
  approval.
- **Triggered:** nothing new filed. Recorded here rather than left for whoever reads
  the gate output next and wonders why the drift count moved.

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

### 2026-08-23T21:44:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-579-the-third-party-byte-identity-gate-is-re.md
- **Context:** Initial task creation

### 2026-08-24T17:22:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
