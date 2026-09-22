---
id: T-795
name: "Add yaml_to_bpmn to the designer MCP server, validating its own output so the silent-broken-diagram path is closed by construction"
description: >
  Add yaml_to_bpmn to the designer MCP server, validating its own output so the silent-broken-diagram path is closed by construction

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
created: 2026-09-22T08:39:48Z
last_update: 2026-09-22T08:44:39Z
date_finished: 2026-09-22T08:44:39Z
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

# T-795: Add yaml_to_bpmn to the designer MCP server, validating its own output so the silent-broken-diagram path is closed by construction

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the tool validates its own output, so the silent-failure path measured in
      T-794 cannot recur through this surface.** A conversion that produces a structurally
      broken diagram must say so in the same response, not hand back bytes and stay quiet.
      T-794 measured exactly that: the converter accepted a diagram whose every node was
      disconnected and reported nothing. Wrapping convert alone would ship that defect to
      every caller.
      Evidence: `tool_yaml_to_bpmn` converts, then writes the result to a temp file and runs
      the validator on it, returning `verdict` + `findings` alongside `bpmn`. When nodes come
      back unreachable it adds a `hint` naming the `flows:`/`edges:` cause.
      **NEGATIVE-CONTROLLED:** replacing the validation with `{"exit_code": 0}` makes the
      broken document report `valid` — the probe drops to **31 passed, 4 failed**. Restored,
      38/38. That is the proof the validation is load-bearing rather than decorative.
- [x] **AC2 — the tool is proven in BOTH directions, in one run.** Good YAML returns BPMN
      with a `valid` verdict; YAML carrying the `flows:`-instead-of-`edges:` mistake returns
      BPMN with an `invalid`/warning verdict naming `W-XML-UNREACHABLE`. The second case is
      the measured, most-likely LLM error and is the reason this AC exists — proving only
      the happy path would prove nothing about the value claim.
      Evidence: the probe converts the SAME document twice, once with `edges:` and once with
      `flows:`. Good -> `valid`, no hint. Bad -> not `valid`, `W-XML-UNREACHABLE` present,
      hint names `flows:`, and the bytes are still returned. A further leg asserts the two
      verdicts DIFFER, so the tool cannot pass by being a constant.
- [x] **AC3 — the tool description names the key that was actually guessed wrong.** A tool
      description is the cheapest available fix for a predictable model error: the schema
      says `edges:` and `flows:` is the natural guess. Stating it in the description costs
      one sentence and prevents the failure T-794 had to discover by running it.
      Evidence: the description carries **"the edge list key is `edges:`, NOT `flows:`"** plus
      the full top-level key list, and a probe leg asserts that string is present — so the
      cheapest fix for the measured error cannot be silently dropped in a later edit.
- [x] **AC4 — the pyyaml dependency is handled honestly rather than hidden.** The server
      stays stdlib-only, but `yaml-to-bpmn.py` imports `yaml`. If it is absent the tool must
      fail with an actionable message naming the missing package — not a traceback, and not
      a claim that the document is invalid. Asserted mechanically that the SERVER's own
      imports are unchanged.
      Evidence: the branch is EXECUTED, not just read. PyYAML is installed here, so the probe
      imports the server module and monkeypatches `subprocess.run` to simulate the converter
      failing with `ModuleNotFoundError: No module named 'yaml'`. Three legs assert the
      message names `pip install pyyaml`, says `validate_workflow` still works, and does NOT
      misreport the situation as the document being invalid. The server's own imports are
      unchanged and the stdlib-only leg from T-792 still passes.
- [x] **AC5 — the existing surface is not regressed.** `validate_workflow` keeps working and
      the scope fence still holds: exactly two tools, both read-only, traversal still
      refused. Adding a tool is the most likely moment to widen a fence by accident.
      Evidence: probe **38 passed, 0 failed** — every T-792 leg still green. `tools/list` is
      asserted as an EXACT two-element list rather than a subset check, so an accidentally
      added third tool fails here instead of passing unnoticed; traversal is refused for the
      new tool as well as the old. One stale assertion was found and fixed rather than
      worked around: T-792's exact single-tool check correctly went red when the second tool
      landed.

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
         1. Run `bin/fw reviewer T-795`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-795 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1/AC2/AC5: the whole surface, exercised as a subprocess over real MCP ───
python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 38 passed, 0 failed'

# ── AC3: the description still names the key that gets guessed wrong ──────────
# The phrase spans a string-literal boundary in the source, so grep the half that
# actually sits on one line. The probe asserts the ASSEMBLED description at runtime,
# which is the stronger check; this leg guards the source text.
grep -qF 'NOT `flows:`' tools/mcp-designer-server.py

# ── AC4: the server itself stays stdlib-only, control then absence ────────────
grep -qE '^import (json|os|subprocess|sys|tempfile)$' tools/mcp-designer-server.py
! grep -qE '^(import|from) (mcp|yaml|requests|httpx|pydantic|lxml|anyio|starlette)' tools/mcp-designer-server.py

# ── AC5: the pinned seam is still untouched by any of this ────────────────────
test -z "$(git diff --stat HEAD -- examples/aef-processes/rendered/)"

# ── docs describe what actually ships ─────────────────────────────────────────
grep -q 'yaml_to_bpmn' docs/mcp-designer-server.md
grep -q '38 passed, 0 failed' docs/mcp-designer-server.md

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

**Symptom.** `tools/yaml-to-bpmn.py` converts a workflow YAML whose edge list is written as
`flows:` instead of `edges:` **without any complaint**, emitting a syntactically well-formed
BPMN document in which every node is unreachable from the start event. Measured in T-794 on a
document I authored from scratch: 2062 bytes out, exit 0, silence. Only running the separate
validator surfaced it — `W-XML-UNREACHABLE` on all three non-start nodes.

**Root cause.** The converter's contract is *render this YAML as BPMN*, and it honours that
contract exactly: an unrecognised top-level key is not a rendering error, it is simply a key it
does not read. Nothing in the chain is broken. The gap is that **the authoring format has a
semantic requirement — nodes must be connected — that no single tool in the chain is
responsible for.** The converter checks syntax; the validator checks semantics; and until this
task nothing obliged a caller to run the second after the first.

**Why structurally allowed.** Two reinforcing reasons.

1. **The two tools have always been separate CLIs, and separation is correct for CLIs** — a
   user who wants only conversion should not pay for validation. That design is fine at the
   command line, where a human sees the output. It becomes a defect the moment the chain is
   exposed to an agent that will act on the bytes without looking at them.
2. **The mistake is not random, it is predictable.** `flows:` is the natural word for a list of
   flows, and BPMN's own vocabulary calls these `sequenceFlow` elements — so the wrong guess is
   the *better*-motivated one. A failure mode that is more likely than the correct behaviour,
   and silent, will occur.

**Prevention** — three layers, deliberately distinct from the fix:

- **Structural, in the tool:** `yaml_to_bpmn` validates its own output and returns the verdict
  in the same response. A caller cannot take the bytes without also receiving the judgement.
  This is the fix, and it is the only layer that cannot be forgotten.
- **Informational, in the description:** the tool description states *"the edge list key is
  `edges:`, NOT `flows:`"* and lists the top-level keys, so the predictable guess is
  pre-empted before it is made. Pinned by a probe leg so a later edit cannot drop it.
- **Diagnostic, in the output:** when nodes come back unreachable, a `hint` names
  `flows:`/`edges:` as the usual cause — so a caller who hits it anyway is told why rather than
  left to rediscover T-794.

**What is NOT prevented, and is left open honestly.** The standalone CLI
`tools/yaml-to-bpmn.py` still converts silently; this task changed the MCP surface, not the
tool. A human running the CLI directly can still produce a disconnected diagram and not be
told. That is a smaller exposure — a human sees the output and the designer renders it
visibly wrong — but it is the same defect and it is untouched here.

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
     fw inception decide T-795 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T08:39:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-795-add-yamltobpmn-to-the-designer-mcp-serve.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-99d40528
- **Timestamp:** 2026-09-22T08:44:42Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 49
     - evidence: `python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 38 passed, 0 failed'`

### 2026-09-22T08:44:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
