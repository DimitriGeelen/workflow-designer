---
id: T-338
name: "Input-fidelity guard: prove load-save preserves content, over a population that includes documents the corpus cannot express (G-016 prevention)"
description: >
  G-016 prevention leg. The tree's export-safety instrument is differential (working-tree vs git-ref output compared to each other over 24 well-formed maps), so a defect both versions share reports green and malformed input is outside the denominator. This adds the missing direction: compare EXPORTED against INPUT (flow-node/edge/lane counts preserved), over a population that deliberately includes out-of-vocabulary BPMN tags the corpus does not contain. The lossy set is MEASURED each run and compared to an expected set, not declared - so a new vocabulary gap goes red, and so does a gap that closes.

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
created: 2026-08-02T09:38:08Z
last_update: 2026-08-02T09:38:17Z
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

# T-338: Input-fidelity guard: prove load-save preserves content, over a population that includes documents the corpus cannot express (G-016 prevention)

## Context

Prevention leg for **G-016**, registered under T-309 spike 4. Distinct from **T-337**, which fixes
one instance: this makes the next vocabulary divergence visible whether or not T-337 lands.

The existing instrument, `tools/_t308-export-byte-identity-cdp.mjs`, compares
`buildBpmnXml(parseBpmnXml(map))` under the working tree against the same under a git ref — output
vs **output**. Two blind spots follow from that shape and neither is a bug in the tool: a defect
present in both versions is byte-identical (green), and its denominator is 24 well-formed corpus
maps, so defects only malformed input can express are outside the population. T-337 lived in the
intersection.

The missing direction is output vs **input**: does a load→save round trip preserve what it was
given? The population must include documents the corpus cannot express, or it inherits blind spot
two.

**Design note — the lossy set is measured, not declared.** A hand-written "known lossy tags" list
would be a tolerance answerable only to itself. Instead the guard probes a list of standard BPMN
flow-node tags, measures which ones lose content, and compares the resulting SET against an expected
set. A new gap turns it red; a gap that closes also turns it red, saying so explicitly — that
direction matters, because it is how the guard reports that T-337 landed rather than silently
relaxing.

## Acceptance Criteria

### Agent
- [x] A guard exists that round-trips documents through the real `parseBpmnXml`→`buildBpmnXml` and
      compares flow-node / sequenceFlow / lane counts in the EXPORTED document against the INPUT
      document — output vs input, not output vs another output.
- [x] Its population includes both the 24 rendered corpus maps (which must be lossless — any loss is
      a hard fail) and synthetic documents carrying BPMN flow-node tags outside the importer's
      allowlist, which the corpus does not contain.
- [x] The lossy-tag set is MEASURED each run and compared against an expected set. A tag joining the
      set fails; a tag leaving it fails with a message saying the gap closed and the expectation
      needs updating. No hand-declared exemption that cannot itself fail.
- [x] The guard asserts its own population was non-empty and that it actually exercised at least one
      out-of-allowlist tag — it must not be able to pass by testing nothing.
- [x] Runs inside `tests/run-bridge-tests.sh` (the gating runner), and the runner's pass count moves
      accordingly.
- [x] Teeth: a mutation harness proves each assertion CAN fail and fails NAMING its own condition —
      including one leg that empties the out-of-vocabulary population and requires a red (the
      guard's own denominator, not just its subject).

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

# The guard itself: corpus lossless AND lossy set == expected.
node tools/_t338-input-fidelity-cdp.mjs
# Its population is non-empty in BOTH legs — the guard must not pass by testing nothing.
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "24 corpus maps round-tripped"
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "out-of-vocabulary tags probed"
# It actually exercised out-of-allowlist tags (the population the corpus cannot express).
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "callActivity"
# Wired into the GATING runner, not merely present on disk (T-316 class).
grep -q "_t338-input-fidelity-cdp.mjs" tests/run-bridge-tests.sh
# The suite still passes. Deliberately asserts "0 failed" and NOT a pass count:
# pinning "N passed" is the G-015 shape — a global, always-moving property that
# goes red the moment anyone adds leg N+1, converting "nobody has reviewed this"
# into "permanently red". Assert what this task delivered, not the whole tree.
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-08-02T09:38:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-338-input-fidelity-guard-prove-load-save-pre.md
- **Context:** Initial task creation

### 2026-08-02T09:38:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
