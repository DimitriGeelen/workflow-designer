---
id: T-561
name: "Completion crashes on inception tasks: update-task.sh derives sys.path from __file__ inside a python3 - heredoc, where __file__ is '<stdin>'"
description: >
  Completion crashes on inception tasks: update-task.sh derives sys.path from __file__ inside a python3 - heredoc, where __file__ is '<stdin>'

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
created: 2026-08-20T09:22:33Z
last_update: 2026-08-20T09:22:33Z
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

# T-561: Completion crashes on inception tasks: update-task.sh derives sys.path from __file__ inside a python3 - heredoc, where __file__ is '<stdin>'

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `update-task.sh`'s `inception_decisions` reachability gate resolves the framework
      root from `$FRAMEWORK_ROOT` (which the shell already computes one line above, to
      stat `lib/inception_decisions.py`) instead of from `__file__`, which under
      `python3 -` is the literal string `<stdin>`.
- [x] A reproduction is recorded showing what the original line actually computed, not
      what it was meant to compute: `os.path.abspath('<stdin>')` resolves against the
      CWD, so three `dirname` calls up from `/opt/832-Workflow-designer/<stdin>` give
      `/`. Measured, not reasoned.
- [x] `fw task update T-501 --status work-completed` reaches a real verdict instead of a
      `ModuleNotFoundError` traceback. (Running it is the operator's — T-501 is
      `owner: human` — so this AC is satisfied by the gate executing, not by completion.)
- [x] The vendored divergence is DECLARED in `.vendor-divergence.yaml` with the upstream
      debt written out, not silently carried. G-008 permits the in-tree fix; the manifest
      is what stops it becoming an undocumented local fork (T-557/T-558 precedent).
- [x] The same defect is searched for elsewhere in the vendored tree rather than assumed
      unique — any other `python3 -` heredoc deriving a path from `__file__` — and the
      result is recorded whichever way it comes out.

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
#
# ── T-561 legs ───────────────────────────────────────────────────────────────────
# No absence assertion here, deliberately. The obvious leg is "the broken
# abspath(__file__) derivation is gone", and T-560 (committed an hour ago) is about
# exactly why that leg would be worth little: it passes when the pattern is mis-quoted
# just as readily as when the code is fixed, and it would have needed a positive control
# to mean anything. Leg 3 asserts the POSITIVE fact instead — the mechanism the fix
# depends on actually resolves the module — which the old code could not have satisfied.
grep -qF 'FW_ROOT_FOR_PY="$FRAMEWORK_ROOT" python3 -' .agentic-framework/agents/task-create/update-task.sh
grep -qF 'os.environ.get("FW_ROOT_FOR_PY", "")' .agentic-framework/agents/task-create/update-task.sh
FW_ROOT_FOR_PY="$PWD/.agentic-framework" python3 -c "import sys,os; sys.path.insert(0,os.environ['FW_ROOT_FOR_PY']); from lib.inception_decisions import parse_inception_decisions; print('IMPORT_OK')" > /tmp/.t561-imp 2>&1 && grep -q "IMPORT_OK" /tmp/.t561-imp
python3 tools/_t517-vendor-divergence.py > /tmp/.t561-vendor 2>&1 && grep -q "every diverged path is declared" /tmp/.t561-vendor
python3 tools/_t560-absence-assertion-census.py > /tmp/.t561-abs 2>&1 && grep -q "PASS: no increase in uncontrolled absence assertions" /tmp/.t561-abs

## RCA

**Symptom:** `fw task update T-501 --status work-completed` passed every gate it has —
verification 5/5, disposition ✓, inception decision ✓ — and then died on
`ModuleNotFoundError: No module named 'lib.inception_decisions'`. Nothing was mutated:
T-501 stayed `started-work` in `active/` with no episodic written, so the failure was
clean, but the operator saw a task clear every check and still not complete.

**Root cause:** `update-task.sh:595` runs its reachability helper as `python3 -`, and set
`sys.path` from `os.path.dirname(...×3, os.path.abspath(__file__))`. Code read from stdin
has `__file__` set to the literal string `<stdin>`. Measured: `abspath('<stdin>')`
resolves against the CWD, so from `/opt/832-Workflow-designer` the three `dirname` calls
yield `/`. The framework root was never added and the next statement raised.

**Why structurally allowed:** the expression is *correct* for a script at
`<framework>/agents/task-create/` — it is dead-right code in the wrong execution mode, so
it reads as fine on every review. The block is also reached only by an inception task
whose gates have all passed AND whose frontmatter carries a populated
`inception_decisions:` field; T-501 is the first task in this project to satisfy both,
and the grandfather guard above it (`[ -f "$lib_py" ] || return 0`) means a project
without the helper skips silently. The bug therefore fires only where the feature is
fully installed and fully exercised — the least-tested corner by construction.

**Prevention:** the value was already in hand. The shell computes `$FRAMEWORK_ROOT` one
line above to stat `lib/inception_decisions.py`, so the fix is to pass it through the
environment rather than re-derive it. Population checked rather than assumed unique: one
other `abspath(__file__)` root derivation exists in the vendored tree
(`agents/audit/audit.sh:5624`) and is guarded by `os.environ.get("PROJECT_ROOT", …)`, so
it is latent, not firing, and left alone as a second bug in a second file.

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

### 2026-08-20T09:22:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-561-completion-crashes-on-inception-tasks-up.md
- **Context:** Initial task creation
