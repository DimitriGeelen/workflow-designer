---
id: T-644
name: "fw ask crashes in a vendored install: PROJECT_ROOT overrides ask.py's correct __file__ default"
description: >
  lib/ask.py:22 does sys.path.insert(0, os.environ.get('PROJECT_ROOT', dirname(dirname(abspath(__file__))))). The __file__ default is CORRECT (it resolves to FRAMEWORK_ROOT); the PROJECT_ROOT env var that bin/fw exports overrides it with the project root, where web/ does not exist in a vendored install. Measured: PROJECT_ROOT=/opt/832-Workflow-designer python3 -c 'sys.path.insert(0,PROJECT_ROOT); import web.embeddings' -> ModuleNotFoundError: No module named 'web'. Unlike T-643's review-queue site there is no fallback, so this is a loud crash, not a silent substitution. Found by T-643's audit of every 'from web.' import site.

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
created: 2026-08-30T18:08:43Z
last_update: 2026-08-30T18:21:10Z
date_finished: 2026-08-30T18:21:10Z
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

# T-644: fw ask crashes in a vendored install: PROJECT_ROOT overrides ask.py's correct __file__ default

## Context

Found by T-643's audit of every `from web.` import site. Sibling defect, different file,
different failure mode — hence a separate task (one bug, one task).

`lib/ask.py:22`:

```python
PROJECT_ROOT = os.environ.get("PROJECT_ROOT", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, PROJECT_ROOT)
from web.embeddings import rag_retrieve, build_index
```

The `__file__` default is **correct** — it resolves to `FRAMEWORK_ROOT`, where `web/`
actually lives. The `PROJECT_ROOT` environment variable that `bin/fw` exports overrides
it with the project root, where in a vendored install `web/` does not exist. The fallback
is right and the primary is wrong.

Measured:

```
$ PROJECT_ROOT=/opt/832-Workflow-designer python3 -c \
    "import sys; sys.path.insert(0, '/opt/832-Workflow-designer'); import web.embeddings"
ModuleNotFoundError: No module named 'web'
```

Unlike T-643's site there is no `except ImportError`, so this fails loudly rather than
substituting a different program. Loud is better. It is still broken.

## Acceptance Criteria

### Agent
- [x] `web.embeddings` and `web.ask` resolve for `lib/ask.py` in a vendored install, and
      the fix does not depend on the `PROJECT_ROOT` env var being correct — the framework
      root is derived from `__file__`, which is right in both layouts.
      → `lib/ask.py:31-35`. Both roots inserted; `PROJECT_ROOT` stays first-searched so a
      project may still shadow a module deliberately, `FRAMEWORK_ROOT` is the backstop.
- [x] Proven by **executing** the import path, not by reading it: a probe imports the two
      modules through ask.py's own preamble under the environment `fw` actually exports
      (`PROJECT_ROOT` set to the project, not the framework).
      → `tools/_t644-ask-imports-survive-a-wrong-project-root.sh`, 5/5. It reads ask.py,
      splits at the first `from web.` line and `exec`s the real preamble — it does not
      retype it, because a retyped preamble tests a model of the file (T-635).
      Second leg points `PROJECT_ROOT` at an empty temp dir and the imports still resolve:
      the env var is no longer able to decide the outcome.
- [x] Measured against the real entry point: `fw ask` no longer terminates with
      `ModuleNotFoundError: No module named 'web'`. If it then fails for an unrelated
      environmental reason (no ollama daemon, no model pulled), that is recorded as a
      distinct outcome and **not** claimed as success.
      → Before: `fw ask "what is a task"` → traceback, `ModuleNotFoundError: No module
      named 'web'` at `ask.py:24`. After: no traceback; the command proceeds past the
      import into RAG/LLM work.
      **Stated plainly rather than rounded up:** an end-to-end answer was NOT observed.
      `fw ask --concise` ran past 240s without returning (index build and/or model load
      on this host). What is verified is the import barrier, which is what this task is
      about. Whether `fw ask` produces a good answer here is a separate question and is
      not claimed.
- [x] A prober with an inversion (the defect's precondition still holds — `PROJECT_ROOT`
      alone does not resolve `web`) and a teeth leg (revert the fix, the prober goes red).
      → Both present. The teeth leg rebuilds the shipped two-line preamble into a mutant
      copy and shows it still reporting `MISSING-WEB` — so the fix, not the environment,
      is what changed the outcome.
- [x] Every remaining `sys.path` insertion under `.agentic-framework/lib` is checked for
      the same `PROJECT_ROOT`-derived defect; findings fixed if in this file, filed if not.
      → Surveyed all 10 `sys.path.insert` sites under `lib/*.py`. **ask.py was the only
      one** that took its root from the environment; every other derives from `__file__`
      (`Path(__file__).resolve().parents[1]`, `_LIB_DIR`, `fw_lib_dir`). Nothing to file.
      The prober keeps the *shape* from returning; it does not re-run the survey, and the
      leg says so in its own comment rather than implying more coverage than it has.

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

bash tools/_t644-ask-imports-survive-a-wrong-project-root.sh
python3 -c "import os,sys;f='.agentic-framework/lib/ask.py';h=open(f).read().partition(chr(10)+'from web.')[0];ns={'__file__':os.path.abspath(f)};exec(compile(h,f,'exec'),ns);import web.embeddings,web.ask"
python3 -c "import ast,sys; ast.parse(open('.agentic-framework/lib/ask.py').read())"

## RCA

**Symptom:** `fw ask <anything>` terminates immediately with
`ModuleNotFoundError: No module named 'web'` at `lib/ask.py:24`. The command has never
worked in this project.

**Root cause:** `ask.py:21` read its module root as
`os.environ.get("PROJECT_ROOT", <__file__-derived>)`. The `__file__`-derived default is
correct — it resolves to `FRAMEWORK_ROOT`, where `web/` lives. `lib/ask.sh:32` exports
`PROJECT_ROOT` unconditionally, so the default never applied, and in a vendored install
the exported value points at a directory with no `web/` in it.

**A default that is right does not help when the override is always set.** The correct
value was sitting in the file, in the position that never runs.

**Why structurally allowed:** the same reason as T-643 — the framework's own repo layout
puts `web/` under the project root, so `PROJECT_ROOT` and `FRAMEWORK_ROOT` are the same
directory there and the two spellings are indistinguishable. Every consumer install
separates them. The framework tests itself in the one layout where the bug is invisible.

**Prevention:** `tools/_t644-ask-imports-survive-a-wrong-project-root.sh`. The
load-bearing leg is the second one: it points `PROJECT_ROOT` at an empty directory and
requires the imports to resolve anyway. That asserts the property that actually matters —
*the env var cannot decide this* — rather than the weaker "it works right now".

**Not prevented:** the next module to reach for `PROJECT_ROOT` when it means
`FRAMEWORK_ROOT`. Two instances in two files in one session is a pattern; the fix for a
pattern is a convention or a lint, not a third prober. Recorded as a learning.

## Recommendation

**Recommendation:** CLOSE — agent-verifiable throughout, nothing here needs your ruling.

**Rationale:** A one-line class of defect with a measured before/after on the real entry
point and a prober whose teeth leg reproduces the failure. No taste, no policy, no
sovereignty question. The one honest gap — that an end-to-end `fw ask` answer was never
observed on this host — is recorded in AC 3 rather than papered over, and it is a
question about ollama throughput, not about this fix.

**Evidence:**

- Before: `fw ask "what is a task"` → `ModuleNotFoundError: No module named 'web'`.
- After: no traceback; execution proceeds past the import.
- `tools/_t644-ask-imports-survive-a-wrong-project-root.sh` — 5/5, including a mutant
  that restores the shipped preamble and still reports `MISSING-WEB`.
- Survey: 10 `sys.path.insert` sites under `lib/*.py`; ask.py was the only env-derived
  one. Nothing further to file.

**Captured learning:** `PROJECT_ROOT` and `FRAMEWORK_ROOT` are the same directory in the
framework's own repo and different everywhere else, so the framework's self-tests cannot
distinguish them. Any code that says one and means the other is correct at home and
broken at every consumer — T-643 and T-644 are the same bug in two files, found on the
same afternoon.


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

### 2026-08-30T18:08:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-644-fw-ask-crashes-in-a-vendored-install-pro.md
- **Context:** Initial task creation

### 2026-08-30T18:14:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ea5fe244
- **Timestamp:** 2026-08-30T18:21:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **cross-project-blast** (medium) — Cross-project or cross-repo change
     - matched: `vendored install`

### 2026-08-30T18:21:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
