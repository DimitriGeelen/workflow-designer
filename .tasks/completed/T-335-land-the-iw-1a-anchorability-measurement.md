---
id: T-335
name: "Land the IW-1a anchorability measurement as a gating guard"
description: >
  Land the IW-1a anchorability measurement as a gating guard

status: started-work
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
created: 2026-08-02T08:51:36Z
last_update: 2026-08-02T08:51:36Z
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

# T-335: Land the IW-1a anchorability measurement as a gating guard

## Context

T-309 spike 3 measured whether each validator finding can be pointed at on the canvas, and the
answer decides IW-1a: 15 of 23 `XmlValidator` rules are gutter-able, but split by severity a gutter
would hide 60% of ERRORs and 9% of WARNs. Those numbers currently live in a scratchpad script and a
prose report. **A hand-written classification table that nothing re-runs is exactly the shape this
arc keeps finding** — `KNOWN_DISAGREEMENTS` before T-330, the parity NOTEs before T-331. Add a rule
to `XmlValidator` tomorrow and the table silently stops describing the tree, while the report keeps
quoting a number the operator may act on.

This lands the measurement as a guard so the table is answerable to the tree rather than to itself.
It does NOT build any part of the surfacing feature — T-309 is an inception with no GO, and the
choice among panel/gutter/gate remains the operator's. Same relationship as T-333/T-334 to T-309.

Full working: `docs/reports/T-309-validator-surfacing.md` (2026-08-02 IW-1a section).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tests/test_finding_anchorability.py` exists and exits 0, reporting the anchor class of
      every `XmlValidator` rule id and the ERROR-vs-WARN anchorability cross-tab.
- [x] The rule population is read from SOURCE by `ast` (every `self.err/warn/info` call site),
      not from a corpus run — a rule no document happens to trigger is still in the denominator.
- [x] The `ANCHOR` table is TOTAL and EXPLICIT: a rule id emitted by `XmlValidator` with no entry
      makes the guard exit non-zero naming that id. No silent default.
- [x] The declared anchor class of each rule is CHECKED against what real documents resolve to —
      corpus BPMN, on-disk BPMN fixtures, AND the bridged documents produced by
      `tools/yaml-to-bpmn.py` (the in-memory form; omitting it is what made the first pass
      under-report verification by 2×). Disagreement fails the guard.
- [x] Rows that no document witnesses are REPORTED with their count, not silently absorbed, and
      the count is asserted so a row cannot slip in or out unnoticed.
- [x] The guard runs as a leg of `tests/run-bridge-tests.sh` (the GATING runner) with a failure
      message naming the condition, and the suite is green.
- [x] Teeth prove each assertion CAN fail and fails naming its own condition: at minimum
      (a) an unclassified new rule id, (b) a declared class that disagrees with the documents,
      (c) drift in the never-witnessed count. Each leg mutates the real tree and restores it
      byte-identically (sha-checked).
- [x] `docs/reports/T-309-validator-surfacing.md` points at the landed guard as the thing that
      keeps the IW-1a numbers answerable, replacing the scratchpad script as the source of truth.

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

# The guard itself runs clean and reports its numbers.
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "OK: every XmlValidator rule is classified"
# The headline IW-1a result, asserted so the report and the tree cannot drift apart.
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "15 gutter-able"
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "ERROR  4 anchorable /  6 not"
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "WARN  10 anchorable /  1 not"
# The bridged population is in the denominator — the row that made the first pass wrong.
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "of them bridged from YAML fixtures at run time"
# 22 of 23 verified; the 23rd is unreachable, not merely unwitnessed.
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "22 of 23 rows verified"
out=$(python3 tests/test_finding_anchorability.py 2>&1); echo "$out" | grep -q "unreachable: no emitter produces"
# It is wired into the GATING runner, not merely present (T-316 class).
grep -q "tests/test_finding_anchorability.py" tests/run-bridge-tests.sh
# Whole gating suite green, count-agnostic (T-305).
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
# The report points at the guard rather than at a scratchpad script.
grep -q "tests/test_finding_anchorability.py" docs/reports/T-309-validator-surfacing.md

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

### 2026-08-02T08:51:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-335-land-the-iw-1a-anchorability-measurement.md
- **Context:** Initial task creation
