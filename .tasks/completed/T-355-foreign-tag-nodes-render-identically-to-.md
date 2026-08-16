---
id: T-355
name: "Foreign-tag nodes render identically to service tasks (no visual marker)"
description: >
  T-337 preserves an out-of-allowlist BPMN flow node by importing it with foreignTag
  and re-emitting that tag verbatim, but the canvas draws it with the ordinary task/gateway
  shape. The author cannot tell a callActivity from a serviceTask, so a node whose
  semantics the designer does not implement looks like one it does. Preservation is
  correct and shipped; DISCLOSURE is the missing half. T-233 (ghost cards) is the
  house precedent for a visually-distinct entry.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-03T11:45:58Z
last_update: '2026-08-16T12:33:52Z'
date_finished: 2026-08-14T18:28:36Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-355: Foreign-tag nodes render identically to service tasks (no visual marker)

## Context

T-337 made the importer *preserve* an out-of-allowlist BPMN flow node: the element is
imported carrying `foreignTag` (`src:10213`) and re-emitted verbatim on export
(`src:9685`). Preservation shipped and is not in question here.

The canvas then draws it with an ordinary shape, because `foreignDisplayTag()`
(`src:10027`) maps any unknown local name to `serviceTask`, or to `exclusiveGateway` when
it ends in `Gateway` — purely so there is something to draw. Its own comment is explicit
that this is *"presentation only"* and *"moves no bytes"*, which is true of the export and
false of the reader: the serviceTask branch stamps a blue service dot on it (`src:2982`)
and the gateway branch stamps the exclusive `X` (`src:3002`). Those marks are not neutral
padding — they are the BPMN convention for *"this is a service task"* and *"this is an
exclusive gateway"*. So a `callActivity` is drawn asserting a semantics the document never
claimed and the designer does not implement.

**Preservation is correct and shipped; DISCLOSURE is the missing half** — the task's own
framing, and the reason this is additive rather than a repair.

**Precondition, checked rather than assumed (the T-424 lesson):** the description names
T-337's `foreignTag`. Verified present at both ends — written at `src:10213`, consumed at
`src:9685`. Nothing here is waiting on an operator ruling, unlike its neighbours T-341 and
T-358, which are explicitly blocked on one.

**House precedent, named in the description:** T-233's ghost cards. Same rule applies —
more than one signal, and no signal that a greyscale reader loses.

## Acceptance Criteria

### Agent
- [x] A node carrying `foreignTag` is drawn by its own branch, placed **before** every
      type branch, so the misleading marks are never painted rather than painted and
      covered
- [x] The shape is neutral and dashed, in the muted palette (`--text-dim`) — the T-308
      precedent, where a bare catch event reads as "an event of unspecified kind" instead
      of a specific kind it is not
- [x] Neither the serviceTask service-dot nor the gateway `X` appears on a foreign node
- [x] **The actual tag name is displayed** (`⟨callActivity⟩`), because "this is not a
      serviceTask" is only half the disclosure — the author still needs to know what it is
- [x] An SVG `<title>` states that the element is preserved verbatim on export and that
      its semantics are not implemented
- [x] A long foreign tag is truncated, never wrapped, and does not change node geometry
- [x] Round-trip is untouched: a foreign node still exports its original tag verbatim, and
      `tools/_t308-export-byte-identity-cdp.mjs` stays 24/24 identical
- [x] `bash tests/run-bridge-tests.sh` passes with 0 failures
- [x] `node tools/_t355-foreign-tag-render-cdp.mjs` passes, and fails against the
      pre-change source (negative control), with no leg passing on an empty population

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

bash tests/run-bridge-tests.sh
node tools/_t355-foreign-tag-render-cdp.mjs
node tools/_t308-export-byte-identity-cdp.mjs

## Recommendation

**Recommendation:** GO

**Rationale:** Additive disclosure only — no import path, no export byte, no other node type
changed. `_t308` still reports 24/24 identical, and the probe asserts the export still
re-emits all three foreign tags verbatim, so T-337's preservation is demonstrably intact.
The one thing I cannot settle is whether the disclosure is *loud enough* for an author
skimming a large map, which is a judgment about your eye.

**Evidence:** probe 10/10 on the working tree, 7 of 10 FAIL on the pre-change source;
suite 75 passed / 0 failed; `_t308` 24/24 identical / 0 drifted; screenshots below, read in
colour and desaturated.

## Visual Verification

Served surface (`gallery-serve.py 3099`), fixture imported through `adoptImportedXml`, one
foreign element of each shape placed **next to its native counterpart in the same document**
— a `callActivity` beside a real `serviceTask`, an `inclusiveGateway` beside a real
`exclusiveGateway` — because "looks different" is only meaningful against the thing it is
supposed to differ from.

- `.playwright-mcp/t355-foreign-vs-native.png` — the real serviceTask keeps its solid blue
  outline and service dot; the `callActivity` is dashed, muted, dotless, and captioned
  `⟨callActivity⟩`. The real exclusiveGateway keeps its orange diamond and `X`; the
  `inclusiveGateway` is a dashed muted diamond with no `X`, captioned `⟨inclusiveGateway⟩`.
- `.playwright-mcp/t355-foreign-vs-native-greyscale.png` — desaturated. Every signal
  survives: solid vs dashed, dot present vs absent, `X` present vs absent, and the caption.
  Nothing here depends on colour, which is why the muted palette was chosen over a new
  accent.

**Known limit, seen rather than inferred:** the caption sits above the shape and can cross
an edge routing line — visible in the colour frame where `⟨callActivity⟩` overlaps a routed
edge. It stays legible, and the alternatives (inside the shape, or below) collide with the
node label, the I/O badge and the id badge respectively. Left as-is and recorded rather than
quietly accepted; if it bothers you in a dense map, that is a real finding, not a nitpick.

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

### 2026-08-03T11:45:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-355-foreign-tag-nodes-render-identically-to-.md
- **Context:** Initial task creation

### 2026-08-14T17:34:51Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-08-14T17:34:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-32e1776e
- **Timestamp:** 2026-08-14T18:30:24Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T18:28:36Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
