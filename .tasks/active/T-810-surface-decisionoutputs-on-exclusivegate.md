---
id: T-810
name: "Surface decisionOutputs on exclusiveGateway — 17 authored values the panel cannot show (F-11)"
description: >
  Value review T-742 F-11: the corpus carries aef:decisionOutputs on exclusiveGateway 17 times and userTask 6 times. The editor offers the field on userTask only, so 17 of 23 authored values can be neither seen nor edited. FIELD_META, the exporter and the importer all already handle the field type-agnostically — the only gap is AEF_FIELDS.exclusiveGateway. Third recorded instance of 'authored values the panel could not show' after T-566 (305) and T-618 (215), and T-618 set the precedent: offer the field on exactly the types the corpus annotates.

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
created: 2026-09-22T13:10:08Z
last_update: 2026-09-22T13:10:08Z
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

# T-810: Surface decisionOutputs on exclusiveGateway — 17 authored values the panel cannot show (F-11)

## Context

Value review T-742 finding **F-11**. The corpus carries `<aef:decisionOutputs>` on
`exclusiveGateway` **17×** and `userTask` **6×**. The panel offered the field on `userTask`
only, so **17 of 23 values a human had authored could be neither seen nor edited.**

Nothing was lost — `FIELD_META` (line 2008), the exporter (9900) and the importer (10820) all
handle the field type-agnostically, and T-570's carriage preserves unknown keys on save. The
values round-tripped invisibly. The operator simply had no way to know they were there.

**Third recorded instance of this exact shape**: T-566 (305 values), T-618 (215 values), this.
T-618 also set the precedent, in its own comment: *"It is offered on exactly the types the
corpus annotates — including events and gateways, which is where a guess would have missed
it."*

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `AEF_FIELDS.exclusiveGateway` includes `decisionOutputs`, positioned with the other decision fields and above `note` (the ordering rule the table states)
- [x] A census instrument reports, per aef field, how many corpus values sit on a node type whose panel does not offer that field — so "authored but unreachable" is a number, not an anecdote
- [x] The census confirms the 17 unreachable `decisionOutputs` values become reachable, measured before and after rather than asserted
- [x] Round-trip is byte-identical across all 24 corpus maps: making a field visible must not change a single exported byte
- [x] Visual verification: a gateway carrying authored `decisionOutputs` shows the value in the panel, screenshotted and read
- [x] The remaining unreachable fields (`multiInstance`, `aggregation`, `compensates`, `timer` — no `FIELD_META` at all) are filed as their own task, not half-done here


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-810 legs. Each line's exit code is its own verdict; no chaining. ---
# The panel must offer decisionOutputs on exclusiveGateway. Anchored to the declaration line
# so a match in prose or in another type's list cannot satisfy it.
grep -qE "^  exclusiveGateway: \[.*'decisionOutputs'.*\]," src/aef-workflow-designer.html
python3 tools/_t810-unreachable-values-census.py
# The count must be AT MOST 30 — the measured post-fix residue (T-811 carries the rest).
# A ratchet, not an equality: fixing more must not fail, but regressing must.
bash -c 'n=$(python3 tools/_t810-unreachable-values-census.py | sed -n "s/^TOTAL_UNREACHABLE=//p"); test -n "$n" && test "$n" -le 30'
# CONTROL: the census must SEE the field go unreachable again if the panel drops it — else
# the leg above is satisfied by a census that counts nothing.
bash -c 'd=$(mktemp -d); mkdir -p "$d/src" "$d/tools" "$d/examples/aef-processes/rendered"; cp tools/_t810-unreachable-values-census.py "$d/tools/"; cp examples/aef-processes/rendered/*.bpmn "$d/examples/aef-processes/rendered/"; sed "s/^  exclusiveGateway: \[.*$/  exclusiveGateway: ['"'"'determinism'"'"', '"'"'note'"'"'],/" src/aef-workflow-designer.html > "$d/src/aef-workflow-designer.html"; n=$(T810_REPO_ROOT="$d" python3 "$d/tools/_t810-unreachable-values-census.py" | sed -n "s/^TOTAL_UNREACHABLE=//p"); rm -rf "$d"; test "$n" -gt 30'
# Round-trip must be untouched: making a field visible must not change one exported byte.
python3 tests/test_roundtrip_serialization.py
python3 tests/test_bridge_seam_roundtrip.py
git diff --quiet HEAD -- examples/aef-processes/rendered/
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

### 2026-09-22 — build the general census first, fix the specific field second

- **Chose:** write `tools/_t810-unreachable-values-census.py` before touching `AEF_FIELDS`.
- **Why:** this is the *third* time the same defect was found by a human reading files, and
  each previous remedy was specific to the field that happened to be noticed. Nothing counted
  the general case, so a fourth instance was guaranteed to be found the same way.
- **It paid immediately.** The census found **47** unreachable values where F-11 named 24, and
  **three groups the finding never mentioned**: `endpoint` on `exclusiveGateway` (11),
  `endpoint` on `startEvent` (7), `emits` on `scriptTask` (5). Those would not have been found
  by fixing only what F-11 listed.
- **It reads `AEF_FIELDS` out of the editor** rather than keeping its own copy: a census
  measuring a stale copy of the thing it audits is the defect it is auditing (PL-181).

### 2026-09-22 — fix only `decisionOutputs`; DEFER the other 30 to T-811

- **Chose:** one line in `AEF_FIELDS.exclusiveGateway`. 47 → 30 unreachable, measured.
- **Why this one is safe:** the field is already fully plumbed (FIELD_META, exporter,
  importer), and `decisionInput`/`decisionOutputs` are the two halves of one gateway decision
  — offering one without the other was always the odd shape. T-618's principle applies
  cleanly.
- **Rejected — fixing all 30 in this task:** *"the corpus authored it"* evidences that the
  value **exists**, not that the field **belongs** on that type. `endpoint` on a gateway may be
  a corpus mistake rather than a panel gap, and that judgement touches the frozen mapping
  standard where AEF is the counterparty. T-618's precedent was safe for `determinism` because
  determinism is semantically type-neutral; `endpoint` is not. Filed as **T-811**, inception,
  recommendation DEFER pending AEF's ruling.
- **Rejected — treating the four FIELD_META-less fields as the same job:** `multiInstance`,
  `aggregation`, `compensates` and `timer` have no field definition at all, so each needs a
  label, hint and render type. That is a different deliverable (task sizing: one task, one
  deliverable).

## Visual Verification

Screenshot: `.playwright-mcp/t810-gateway-decisionoutputs.png`, read with the Read tool.

Corpus gateway `g_capture` in `context-memory.bpmn`, authored value
`learning, pattern, decision`. The panel renders **Decision outputs · enum, comma-separated**
between *Decision input* and *Decision owner*, carrying the value in an editable field —
correct position per the table's ordering rule (structured fields above `note`). The blue
outline in the image is a scroll-and-highlight added by the verification script, not a style
change.

Single-appearance product (established in T-808: one theme, no density or font modes), so one
screenshot is the full matrix.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-810 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T13:10:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-810-surface-decisionoutputs-on-exclusivegate.md
- **Context:** Initial task creation
