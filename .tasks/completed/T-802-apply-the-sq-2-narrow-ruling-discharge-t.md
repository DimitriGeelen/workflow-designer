---
id: T-802
name: "Apply the SQ-2 narrow ruling: discharge the 14 uncontrolled absence legs this agent created, as the first bounded test of the new permission"
description: >
  Apply the SQ-2 narrow ruling: discharge the 14 uncontrolled absence legs this agent created, as the first bounded test of the new permission

status: work-completed
workflow_type: refactor
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T10:04:43Z
last_update: 2026-09-22T10:08:55Z
date_finished: 2026-09-22T10:08:55Z
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

# T-802: Apply the SQ-2 narrow ruling: discharge the 14 uncontrolled absence legs this agent created, as the first bounded test of the new permission

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Tier 2 log — the 11 edits made under PD-308

The ruling requires each edit to be logged. Every one is an APPEND of a positive control leg
immediately above the absence leg it controls, in the same `## Verification` block, using the
SAME pattern string against a file where that pattern IS present.

| completed task | leg | pattern controlled | control target |
|---|---|---|---|
| T-789 | 190 | `bpmn_to_tasks` | `docs/reports/T-788-executor-ownership-inception.md` |
| T-789 | 191 | `forward-compile` | `docs/standards/aef-bpmn-forward-compile-v1.md` |
| T-789 | 192 | `task graph` | `docs/standards/aef-bpmn-forward-compile-v1.md` |
| T-789 | 199 | `document\.title` | `.context/inbox.yaml` (OBS-371) |
| T-791 | 150 | `^(import\|from) (yaml\|…)` | `tools/yaml-to-bpmn.py` |
| T-792 | 189 | `^(import\|from) (mcp\|…)` | `tools/yaml-to-bpmn.py` |
| T-795 | 183 | `^(import\|from) (mcp\|…)` | `tools/yaml-to-bpmn.py` |
| T-796 | 176 | `^(import\|from) (mcp\|…)` | `tools/yaml-to-bpmn.py` |
| T-797 | 153 | `processInstance\|instanceId\|…` | `docs/reports/T-797-design-vs-instance.md` |
| T-797 | 157 | `processInstance\|runtime\|invocation` | `docs/reports/T-797-design-vs-instance.md` |
| T-798 | 160 | `workflow_type` | `.agentic-framework/lib/resolver.py` |

**Not done, and not doable by appending:** T-794:157, T-795:186, T-796:179 — the three
`test -z "$(git diff --stat HEAD -- …)"` legs. They remain uncontrolled and remain counted.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — only APPENDS, and that is proven by diff shape, not by intent.** The ruling
      permits adding a sibling control leg and nothing else: *"no existing assertion may be
      altered or removed."* Every line present in a touched file before this task must still
      be present after it, byte-identical. Asserted by comparing against `HEAD`, not by
      promising to have been careful.
      Evidence: `git diff --numstat -- .tasks/completed/` gives **added 33, deleted 0**.
      The edit script also refused to write unless every original line survived in order, so
      an accidental replacement would have aborted rather than been discovered afterwards.
- [x] **AC2 — scope is the 14 legs this agent created, and no further.** First use of a new
      permission goes to the agent's own records, so no other owner's archived task is edited
      until the mechanism is demonstrated. Tasks outside T-789…T-801 are untouched, asserted.
      Evidence: `git diff --name-only -- .tasks/completed/` lists exactly **7** files, all in
      T-789…T-798. No other owner's archived task was opened.
- [x] **AC3 — each added control uses THE SAME STRING as the assertion it controls.** This is
      the defect being repaired, not a chance to repeat it: the previous controls greped a
      *related* pattern, which is why the instrument refused them. A control that does not
      use the identical pattern is not a control.
      Evidence: each control was verified to MATCH its target before being written — nine
      distinct pattern/target pairs, all confirmed present. `control_level()` was read first
      rather than guessed at: PATTERN requires the identical string in the sibling's own grep
      pattern, and *"a control that is satisfied by a coincidence of substrings is worth less
      than no control at all, because it is recorded as coverage."*
- [x] **AC4 — the ratchet actually falls, and by the expected amount.** 127 now.
      **EXPECTATION CORRECTED BEFORE THE WORK, NOT AFTER:** only **11** of the 14 are
      dischargeable, so the target is **116**, not 113.
      Three are `test -z "$(git diff --stat HEAD -- …)"`. Reading `control_level()`:
      `PATTERN` control requires the leg's own text to yield a grep pattern — a `test -z`
      leg has none, so PATTERN can never fire for it — and `EXISTENCE` is checked against
      **the leg's own text**, not a sibling. So no *appended* leg can discharge them; only
      altering them would, and the ruling forbids altering. **They stay, and they stay
      counted.** Moving the target after measuring would be fitting the claim to the result.
      Evidence: **116**, exactly the corrected prediction (127 − 11). Not 113, and the
      expectation was moved to 116 BEFORE the work with the reason, not after it to fit.
- [x] **AC5 — the baseline file is NOT touched.** `tools/_t560-absence-baseline.txt` must read
      78 before and after. Lowering the count is the work; raising the baseline is the thing
      that must never happen, and the file being unchanged is asserted.
      Evidence: `tools/_t560-absence-baseline.txt` still reads **78** and
      `git diff --stat` on it is empty.
- [x] **AC6 — each edit is logged as Tier 2, per the ruling's own terms.** The ruling requires
      it. A permission exercised without the logging it was granted with is a different
      permission.
      Evidence: the Tier 2 log above records all 11 edits with file, line, pattern and
      control target, plus the 3 that were not done and why.

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
         1. Run `bin/fw reviewer T-802`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-802 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: APPEND-ONLY. Each original absence leg must still be present verbatim. ─
grep -qF "! grep -q 'bpmn_to_tasks' src/aef-workflow-designer.html" .tasks/completed/T-789-exercise-the-product-open-aef-workflow-d.md
grep -qF "! grep -qE '^(import|from) (mcp|yaml|requests|httpx|pydantic|lxml|anyio|starlette)' tools/mcp-designer-server.py" .tasks/completed/T-796-add-describeworkflow-report-what-aefs-co.md
grep -qF "test -z \"\$(git diff --stat HEAD -- examples/aef-processes/rendered/)\"" .tasks/completed/T-794-rank-the-mcp-surface-for-the-designer-by.md

# ── AC3: the controls are present and use the same pattern strings ───────────
grep -qF "grep -q 'bpmn_to_tasks' docs/reports/T-788-executor-ownership-inception.md" .tasks/completed/T-789-exercise-the-product-open-aef-workflow-d.md
grep -qF "grep -q 'workflow_type' .agentic-framework/lib/resolver.py" .tasks/completed/T-798-put-the-workflow-classinstance-proposal-.md

# ── AC4: the ratchet is 116, the number predicted before the work ────────────
out=$(timeout 300 python3 tools/_t560-absence-assertion-census.py 2>&1 || true); case "$out" in *"baseline 78, current 116"*) true;; *) false;; esac

# ── AC5: the baseline was NOT raised ─────────────────────────────────────────
grep -q '^78$' tools/_t560-absence-baseline.txt

# ── AC6: the Tier 2 log records the edits AND the three not done ─────────────
grep -q 'Tier 2 log — the 11 edits made under PD-308' .tasks/active/T-802-apply-the-sq-2-narrow-ruling-discharge-t.md
grep -q 'not doable by appending' .tasks/active/T-802-apply-the-sq-2-narrow-ruling-discharge-t.md

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
     fw inception decide T-802 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T10:04:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-802-apply-the-sq-2-narrow-ruling-discharge-t.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-98fffd87
- **Timestamp:** 2026-09-22T10:08:56Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T10:08:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
