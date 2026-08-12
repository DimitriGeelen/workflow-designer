---
id: T-480
name: "Project aef:endpoint in the round-trip semantic fixed point so a future drop cannot be silent"
description: >
  Project aef:endpoint in the round-trip semantic fixed point so a future drop cannot be silent

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
created: 2026-08-12T22:28:00Z
last_update: 2026-08-12T22:32:20Z
date_finished: 2026-08-12T22:32:20Z
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

# T-480: Project aef:endpoint in the round-trip semantic fixed point so a future drop cannot be silent

## Context

Closes OBS-041. T-479 measured that `aef:endpoint` — the executable command a task node
runs — survives the editor round trip today (155 endpoints, 30 documents, 0 lost). It also
measured that **nothing is watching it**: `tools/_roundtrip-serialization-cdp.mjs` is our
only true semantic fixed-point guard, and the string `endpoint` appears **nowhere** in it.
Its projection is a fixed `METAKEYS` list, and presentational content is excluded by
design — *because the harness conforms to the standard*, which misfiles `aef:endpoint` as
presentational (OBS-039).

So a future regression that drops or mangles `aef:endpoint` would leave every test green.
The value is preserved today by luck of implementation, not by a guard.

**The fix-one-of-N trap is live in this file.** `METAKEYS` is defined **twice** — once in
`PREFLIGHT_EXPR` (the self-test that proves the guard can detect drift) and once in
`ROUNDTRIP_EXPR` (the guard itself). Patching only the second would leave the self-test
blind to endpoint drift while the guard claims to check it: the guard would assert a
property its own teeth-proof never exercises. AEF shipped exactly this failure two rounds
ago (their T-2948, one of four sites) and reported it at rail 588. Both copies change, or
neither does.

**Not in scope:** the standard (frozen, two-party — the v1.2 reclassification is the
operator's and AEF's), `src/`, and the other structured semantic elements. If the census
below finds more unprojected fields, they are reported for a follow-up task, not folded in
(one bug = one task).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `endpoint` is projected by the round-trip semantic fixed point, and **both**
      `METAKEYS` definitions are updated — verified by count, not by inspection
- [x] The guard has **teeth on this specific field**: falsified by mutation — an emitted
      `aef:endpoint` whose value is altered must make the projection comparison go RED,
      demonstrated by running it, not argued (PL-095)
- [x] The existing suite still passes — `test_roundtrip_serialization.py` green, and the
      guard's own preflight self-test still fires (a green that cannot go red is worthless)
- [x] The remaining structured semantic elements are **censused** — which of
      `contextReads`, `artifactsWrites`, `decisionInput`, `decisionOutputs`, `io`,
      `constituents`, `link` are projected and which are not, stated as a full list, so the
      follow-up is scoped rather than guessed (PL-172)
- [x] The comment at the projection records **why** `endpoint` is there despite the
      standard calling it presentational, and cites OBS-039 — otherwise a future reader
      conforming to the standard removes it again

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
# --- T-480 legs ---
# BOTH METAKEYS copies carry the key — counted structurally (list entry, not a comment
# mention), so a patch to only one goes red. This is the fix-one-of-N guard.
test "$(/usr/bin/grep -cE "^ *'endpoint'" tools/_roundtrip-serialization-cdp.mjs)" = "2"
# The harness still parses — the first form of the comment used dollar-brace INSIDE a JS
# template literal and killed it before evaluation.
node --check tools/_roundtrip-serialization-cdp.mjs
# The guard itself is still green over the real fixtures.
timeout 300 python3 -m pytest tests/test_roundtrip_serialization.py -q > /tmp/.t480suite 2>&1 && grep -q "1 passed" /tmp/.t480suite
# The comment tells a future reader why the key is there and not to conform it away.
/usr/bin/grep -q 'DO NOT REMOVE THIS KEY' tools/_roundtrip-serialization-cdp.mjs
/usr/bin/grep -q 'OBS-039' tools/_roundtrip-serialization-cdp.mjs
# The census of what is still unprojected is recorded, so the follow-up is scoped.
/usr/bin/grep -q 'six structured semantic elements the editor parses and re-emits' docs/reports/T-357-di-adoption.md
# The falsification result is recorded with the signal it was read off.
/usr/bin/grep -q 'PRE-change    projEqual = True' docs/reports/T-357-di-adoption.md
# Scope held: no src, no standard, no corpus bytes.
test -z "$(git diff --name-only HEAD -- src/ docs/standards/ examples/)"
# No mutant probe left behind in the tree.
test ! -f tools/_t480-mutant.mjs
test ! -f tools/_t480-premutant.mjs
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

### 2026-08-12T22:28:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-480-project-aefendpoint-in-the-round-trip-se.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-782ce3ef
- **Timestamp:** 2026-08-12T22:32:23Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T22:32:20Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
