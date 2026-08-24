---
id: T-563
name: "T-501 build 2: replace the :9950 id derivation with the shared sanitizer, with a CDP probe over the 14 fallback documents"
description: >
  T-501 GO decomposition item 2. Replace the fallback chain at src/aef-workflow-designer.html:9950 (aefMetaEl id || procName || 'imported' — a display NAME standing in for machine identity) with workflowMeta id -> sanitizeWorkflowId(procId) -> sanitizeWorkflowId(procName) -> 'imported'. Must NOT use deriveSlug: it is a summariser and collapses the 14 fallback documents onto 4 ids that all pass the validator. Owes a CDP probe over those 14 asserting distinct-id count and validator pass. Depends on T-562 (shared helper).

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-501, T-562, T-564]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T09:48:08Z
last_update: 2026-08-24T17:44:46Z
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

# T-563: T-501 build 2: replace the :9950 id derivation with the shared sanitizer, with a CDP probe over the 14 fallback documents

## Context

On import, a document with no `<aef:workflowMeta>` gets its workflow id from a DISPLAY
NAME. The chain is `aefMetaEl?.getAttribute('id') || procName || 'imported'` — and
`procName` is `proc.getAttribute('name')`, falling back to `procId` with a `Pool_`
prefix stripped. A human-readable label therefore becomes machine identity for every
document that reaches it.

The population that reaches it is not hypothetical and is not small: measured today,
14 of the 58 corpus documents carry no `<aef:workflowMeta>` — 10 in
`tests/fixtures/third-party`, 4 in `tests/fixtures/lane-provenance`. The other 44
(24 rendered, 19 aef-bpmn, 1 third-party) carry the element and never reach the
fallback. That 14 is the same population T-565 measured for a different reason
yesterday; it reproduces exactly.

The replacement chain, per T-501 §Decision item 1:

    workflowMeta id -> sanitizeWorkflowId(procId) -> sanitizeWorkflowId(procName) -> 'imported'

Two things about that chain are load-bearing and easy to get wrong:

**The authored id stays RAW.** `aefMetaEl.getAttribute('id')` is not passed through the
sanitizer. It is already machine identity, it already round-trips, and sanitizing it
would move bytes on the 44 documents that carry it — the exact byte-identity surface
`_t308` and `_t358` watch. Only the two FALLBACK legs are sanitized.

**`deriveSlug` must not be used.** It is a summariser for node labels — first word
longer than one character, truncated to 16. `sanitizeWorkflowId`'s own docstring at
:1670 records the measurement: over these same 14 documents `deriveSlug` yields **4**
ids (`process` ×8, `proc` ×4, `id`, a hash) and **all 4 pass the validator**. That is
the worst failure shape available here — a loud save-time rejection converted into a
silent cross-document collision. The probe this task owes exists mainly to make that
substitution impossible to land quietly.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The fallback chain at the import site is `workflowMeta id (raw) ->
      sanitizeWorkflowId(procId) -> sanitizeWorkflowId(procName) -> 'imported'`, the
      authored id is NOT passed through the sanitizer, and `deriveSlug` does not appear
      anywhere on the workflow-id path.
- [ ] A CDP probe drives the real designer over all 14 fallback documents and records,
      per document, the derived id BEFORE and AFTER the change — so the effect is
      measured on the shipped page, not argued from the source.
- [ ] The probe holds two invariants that can each actually go red, and both are stated
      with the failure they catch: (1) every one of the 14 derived ids satisfies
      `isValidWorkflowId` — red if a raw display name returns to the chain; (2) the
      count of DISTINCT ids across the 14 does not fall below a recorded floor — red if
      a summariser (`deriveSlug` or any successor) collapses them.
- [ ] The 44 documents that DO carry `<aef:workflowMeta>` derive exactly their authored
      id, unchanged, and the probe asserts it — this is the guard on the "authored id
      stays raw" decision, and it is the leg that would catch an over-eager sanitize.
- [ ] The probe is invoked by something that runs: wired as a leg in
      `tests/run-bridge-tests.sh`, and the full suite is re-run AFTER the file exists
      (L-—: the T-578 defect was trusting a suite run that predated the new tool).

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

# The probe itself. Its own exit code is the verdict — no chaining, no grep, so the
# errexit and SIGPIPE traps above do not arise. rc 2 is a REFUSAL (no corpus, or no
# document reaches the fallback) and is NOT green.
timeout 400 node tools/_t563-fallback-id-derivation-cdp.mjs

# The probe is reachable from something that runs. A guard nothing invokes is a file
# (PL-182, T-451) — this is the leg T-578 taught us to write down rather than assume.
grep -q '_t563-fallback-id-derivation-cdp.mjs' tests/run-bridge-tests.sh

# The sanitizer is ON the identity path, asserted POSITIVELY.
#
# I wrote this as `test $(grep -c 'deriveSlug(procName)...') -eq 0` first. The T-560
# absence census flagged it as the 79th uncontrolled absence assertion in the corpus and
# took the bridge suite red — correctly. A `-eq 0` over a grep is satisfied identically
# by "the thing is absent" and by "my pattern was wrong", and I had just written the
# pattern from memory in the same edit.
#
# Not re-baselined. Rewritten as the positive fact, which is what I actually wanted to
# know: the sanitizer is on the path. The deriveSlug substitution the absence leg was
# reaching for is already caught BEHAVIOURALLY and better — leg 3 of the probe scores
# deriveSlug at 7 distinct ids against a floor of 10 and goes red, without depending on
# anyone spelling the call site correctly in a grep.
grep -q 'sanitizeWorkflowId(procId' src/aef-workflow-designer.html

# The authored-id byte surface did not move: the 24 rendered maps still export
# byte-identically. This is the gate the "authored id stays raw" decision is answerable
# to, and it runs over a population that all carries <aef:workflowMeta>.
timeout 400 node tools/_t308-export-byte-identity-cdp.mjs

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

**Symptom:** Every document with no `<aef:workflowMeta>` imported with a workflow id
that the designer's own save guard rejects. Measured through the real page before the
change: 14 of 14, no exceptions — `Process_1`, `Hauptprozess`, `EU Bank`, `Empty lane
set`, `No lane set`.

**Root cause:** `procName` sat in the identity slot. It is
`proc.getAttribute('name')`, falling back to procId minus a `Pool_` prefix — a display
label. A label is allowed spaces, capitals and punctuation; a machine id is not. The
chain never asked whether what it returned could be an id.

**Why structurally allowed:** nothing read this population. `isValidWorkflowId` judges
ids at the SAVE boundary and at rename, never at import, so the invalid id existed in
state from the moment of import and only surfaced if the user later tried to save. And
the two byte-identity gates that do cover third-party documents compare exports to
exports; neither asserts anything about the id's shape. The property was true of the
code someone read and false of every document that ran through it.

**Prevention:** `tools/_t563-fallback-id-derivation-cdp.mjs`, wired at
`tests/run-bridge-tests.sh`. Distinct from the fix in the way that matters: leg 5 pins
the OLD chain in-page and requires it to be invalid where the new one is valid, so the
guard cannot go green over a population that stops exercising it — the UNEXERCISED
failure this project hit in T-423 (`aef:forceStraight`, 0 instances) and again in T-501
IW-0 (an exit condition naming 24 documents that all already satisfied it).

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

### 2026-08-24 — the number in our own docstring did not reproduce

- **What changed:** `sanitizeWorkflowId`'s docstring states that `deriveSlug` over these
  14 documents yields "4 ids (`process` ×8, `proc` ×4, `id`, a hash)". Measured through
  the real page: **7 distinct**, `process` ×6, and **no `proc` bucket at all** — because
  `deriveSlug` is applied to procNAME, and the four lane-provenance documents carry real
  names ("Authored lanes" → `authored`), not `Proc_`-prefixed ids. The earlier figure
  looks like it was computed over procId.
- **Plan impact:** none to the fix; the argument rests on the direction (10 distinct
  collapsing to 7) and that direction holds. But the figure was quoted in the tree as a
  measurement, so it is corrected in place rather than dropped. Same shape as this
  week's other corrections: a stated property standing in for a checked one.
- **Triggered:** docstring corrected under this task. No new task — one wrong number
  with the same conclusion is a correction, not a defect class.

### 2026-08-24 — the floor is 10, not 14, and the corpus is the reason

- **What changed:** I wrote `DISTINCT_FLOOR = 14` on the assumption that fourteen
  documents yield fourteen ids. They yield **10, before and after the change** — five
  third-party fixtures each declare `<bpmn:process id="Process_1">`, so they share an
  identifier at the SOURCE.
- **Plan impact:** the AC said "distinct-id count" and it would have been easy to read
  the unchanged 10 as the fix failing. It is not. The chain loses nothing; the documents
  collide. Stated explicitly in the code comment so the next reader does not file it as
  a regression.
- **Triggered:** nothing. Cross-document id collision among fixtures is not a defect in
  a single-document import path. If it ever becomes one it is a corpus question.

### 2026-08-24 — this change moves third-party export bytes, and T-579 is where that lands

- **What changed:** the workflow id reaches the emitted XML —
  `Collaboration_${wm.id}` and `Process_${wm.id}` in `buildBpmnXml`. So all 14 fallback
  documents now export different bytes than they did before this commit.
- **Plan impact:** none here — T-501's GO ratified this chain, so the change itself is
  already the operator's decision. But it is a new input to the OTHER decision currently
  sitting on `/approvals`: T-579 asks the operator to move `_t358-byteid-thirdparty`'s
  `BASELINE_REF`, and the drift that pin would ratify just grew by this commit.
- **Triggered:** noted on T-579 rather than silently left for whoever reads the gate
  next.

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

### 2026-08-20T09:48:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-563-t-501-build-2-replace-the-9950-id-deriva.md
- **Context:** Initial task creation

### 2026-08-20T09:48:26Z — status-update [task-update-agent]
- **Change:** horizon: now → next

### 2026-08-24T17:44:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
