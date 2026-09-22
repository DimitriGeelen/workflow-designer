---
id: T-792
name: "Build the designer MCP server: validate_workflow over local stdio, zero dependencies, read-only"
description: >
  Build the designer MCP server: validate_workflow over local stdio, zero dependencies, read-only

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
created: 2026-09-22T08:11:09Z
last_update: 2026-09-22T08:22:01Z
date_finished: 2026-09-22T08:22:01Z
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

# T-792: Build the designer MCP server: validate_workflow over local stdio, zero dependencies, read-only

## Context

Operator said **go** on T-791's recommendation: a narrow, read-only, local-stdio MCP server
exposing the workflow designer, starting with `validate_workflow` alone because it is
stdlib-only and it is the tool AEF actually reached for 32 times over a manual transport.

Binding constraints, carried from T-790/T-791 and the operator's standing ruling:

- **Local stdio only.** Remote HTTP is a load-bearing service dependency and is excluded.
- **Pure functions and reads only.** Nothing writes into a governed tree. Governance does not
  travel over MCP (no `PreToolUse`, no task gate), so the scope fence is what keeps the
  enforcement gap harmless — a pure function has nothing for P-002 to protect.
- **No packaging.** MCPB is deferred until someone asks to install it (G-007).
- **One tool.** `yaml_to_bpmn`, `list_corpus`, `get_workflow` are deliberately out of this
  task; prove the pattern first.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the server speaks MCP over stdio and is proven to do so by being spoken to.**
      Not "the file parses" and not "the code looks right": a subprocess is spawned, the
      `initialize` handshake completes, `tools/list` returns `validate_workflow`, and
      `tools/call` returns a verdict. A server that has never been called is not a server.
      Evidence: `tools/_t792-mcp-server-probe.py` spawns the server as a SUBPROCESS and
      speaks newline-delimited JSON-RPC to it — **21 passed, 0 failed**. Handshake echoes a
      known protocolVersion (2025-06-18) and falls back to 2025-03-26 on an unknown one
      rather than echoing nonsense back; `tools/list` returns the tool; `tools/call` returns
      a verdict; `ping` answers; unknown method -> -32601, unknown tool -> -32602.
- [x] **AC2 — the tool discriminates, proven in BOTH directions.** A valid document must come
      back VALID and an invalid one must come back INVALID, measured in the same run. A tool
      verified only in the passing direction is the untested-direction defect T-353 exists to
      remember — "it returned something" is not evidence that it read anything.
      Evidence: both directions in the SAME run — a valid document returns `valid` with 0
      errors, `E-XML-NODE-TYPE.xml` returns `invalid` with the rule id carried through so the
      caller learns why. A further leg asserts the two verdicts DIFFER, so the tool cannot
      pass by being a constant.
- [x] **AC3 — zero third-party imports, asserted mechanically.** The server imports only the
      standard library, so it satisfies the operator's standalone constraint by construction
      rather than by claim. Asserted with a positive control on the same pattern, so an
      unreadable or moved file cannot score the absence green.
      Evidence: the server imports `json, os, subprocess, sys, tempfile` — stdlib only. The
      `mcp` SDK IS installed here and was deliberately not used; the reasoning is in the
      module docstring and §'Why it is hand-rolled' of the doc. Asserted with a positive
      control on the same pattern in the Verification block below.
- [x] **AC4 — the scope fence is enforced by the code, not just documented.** The server
      exposes exactly one tool, and the path it is asked to validate cannot escape the
      repository. An MCP server carries none of the framework's gates, so a path-traversal
      into an arbitrary file is not a theoretical concern — it is the whole reason the fence
      exists. Proven with a traversal attempt that must be refused.
      Evidence: `tools/list` returns exactly one tool. `_resolve_repo_path` resolves symlinks
      BEFORE the containment test and refuses `../../etc/passwd` and a deep traversal, with a
      refusal message that says why; a positive control proves an in-repo path IS accepted, so
      the refusals are about location rather than breakage. NEGATIVE-CONTROLLED: with the
      containment test replaced by `if False:` the probe reports **18 passed, 3 failed**, and
      restoring it returns 21/21.
- [x] **AC5 — the operator can install it in one copy-pasteable line, and that line is
      accurate.** Documented with the exact `claude mcp add` invocation and the `.mcp.json`
      fragment. NOT wired into the live session config by this task — that changes the
      operator's environment and is their call, not a side effect of a build.
      Evidence: `docs/mcp-designer-server.md` carries the `claude mcp add` line (syntax taken
      from `claude mcp add --help`, not from memory), a DESIGNER_REPO_ROOT variant for a
      checkout elsewhere, and a `.mcp.json` fragment. NOT wired into any live config by this
      task, and the doc says so.

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
         1. Run `bin/fw reviewer T-792`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-792 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1/AC2/AC4: the server, exercised as a SUBPROCESS over real MCP ──────────
# 21 legs incl. both verdict directions and two refused traversals. Negative-
# controlled: disabling the containment test yields 18 passed, 3 failed.
python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 21 passed, 0 failed'

# ── AC3: stdlib only, with the POSITIVE CONTROL on the same pattern ───────────
# Leg (a) proves the import-matching pattern FINDS things in this file, so leg
# (b)'s silence is evidence about dependencies and not about an unreadable path.
grep -qE '^import (json|os|subprocess|sys|tempfile)$' tools/mcp-designer-server.py
# SQ-2 control (PD-308, operator ruling 2026-09-22 — Tier 2, APPEND ONLY). Positive
# control on the SAME pattern string, so the silence below is evidence about the subject.
grep -qE '^(import|from) (mcp|yaml|requests|httpx|pydantic|lxml|anyio|starlette)' tools/yaml-to-bpmn.py
! grep -qE '^(import|from) (mcp|yaml|requests|httpx|pydantic|lxml|anyio|starlette)' tools/mcp-designer-server.py

# ── AC4: exactly one tool is registered, and it is the read-only one ──────────
python3 -c "import json,subprocess,sys; p=subprocess.Popen([sys.executable,'tools/mcp-designer-server.py'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True); p.stdin.write(json.dumps({'jsonrpc':'2.0','id':1,'method':'tools/list'})+chr(10)); p.stdin.flush(); r=json.loads(p.stdout.readline()); p.stdin.close(); sys.exit(0 if [t['name'] for t in r['result']['tools']]==['validate_workflow'] else 1)"

# ── AC5: the install line exists and matches the verified CLI syntax ──────────
grep -q 'claude mcp add aef-workflow-designer -- python3' docs/mcp-designer-server.md
grep -q 'DESIGNER_REPO_ROOT' docs/mcp-designer-server.md

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
     fw inception decide T-792 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T08:11:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-792-build-the-designer-mcp-server-validatewo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-24cf7e09
- **Timestamp:** 2026-09-22T08:22:04Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 51
     - evidence: `python3 tools/_t792-mcp-server-probe.py 2>&1 | grep -q 'probe: 21 passed, 0 failed'`

### 2026-09-22T08:22:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
