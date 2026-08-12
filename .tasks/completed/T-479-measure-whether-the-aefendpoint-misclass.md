---
id: T-479
name: "Measure whether the aef:endpoint misclassification causes real data loss on round-trip"
description: >
  Measure whether the aef:endpoint misclassification causes real data loss on round-trip

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T22:20:32Z
last_update: 2026-08-12T22:26:10Z
date_finished: 2026-08-12T22:26:10Z
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

# T-479: Measure whether the aef:endpoint misclassification causes real data loss on round-trip

## Context

T-477 found that the frozen two-party standard files `aef:endpoint` under the
**presentational** class ("diagram cosmetics", "derived, never authoritative", "a change
alone MUST be a no-op for the task graph") while it actually carries the **executable
command a task node runs** (`fw context build --task ${task_id} --depth 2`). Registered as
OBS-039.

That finding stops at an **entitlement**: a conforming consumer *may* discard it. Whether
any consumer *does* is a different question, and it is the one that decides whether the
v1.2 correction is urgent or cosmetic:

- If `aef:endpoint` survives every round trip we control, the defect is **latent** — a
  trap for a future conformant implementer, worth fixing calmly at v1.2.
- If anything already drops or mangles it, the defect is **live** — commands are being
  lost from real maps today, and the standard is licensing it.

**This is a measurement, not a fix.** No change to the standard (frozen, two-party, not
agent-editable), no change to `src/`, no change to the bridge. If loss is found, it is
filed as its own task with the evidence.

**PL-084 discipline applies hard here:** a "no loss found" verdict is worthless without
its denominator — how many carriers were exercised, and whether any node in the corpus
actually has an `endpoint` to lose. A clean result over an empty population is the
vacuity trap, not a safety result.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The population is established first: how many nodes across the corpus and examples
      actually carry an `endpoint`, stated as a count — if the answer is zero, that is
      reported as vacuity and the round-trip result is explicitly labelled unproven
- [x] Round-trip behaviour is **executed**, not inferred from reading the code: a real
      document carrying `aef:endpoint` is passed through each consumer we control and the
      output compared for presence AND value
- [x] Every consumer is enumerated rather than sampled — the exporter, the bridge, and the
      validator — with any consumer that cannot be exercised named as untested rather than
      silently omitted (PL-172)
- [x] A positive control proves the probe can detect loss (an endpoint deliberately removed
      must be reported as lost), so a clean verdict is not vacuous (PL-095)
- [x] Verdict recorded in `docs/reports/T-357-di-adoption.md` under the existing standard
      defect section — latent or live, with the numbers — and OBS-039 updated by reference
      so the operator/AEF ruling has the severity attached

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
# --- T-479 legs ---
# The probe runs green, over a real (non-empty) population, with its control firing.
node tools/_t479-endpoint-roundtrip-cdp.mjs > /tmp/.t479leg.json 2>&1
python3 -c "import json,sys; d=json.load(open('/tmp/.t479leg.json')); sys.exit(0 if d.get('pass') and d.get('population',0)>=25 and d.get('totalIn',0)>=150 and (d.get('control') or {}).get('fired') else 1)"
# Population is not vacuous — measured independently of the probe (PL-084 denominator).
test "$(/usr/bin/grep -rl '<aef:endpoint>' examples/ tests/fixtures/ 2>/dev/null | wc -l)" = "30"
# The finding: the round-trip guard does not project endpoint at all.
test "$(/usr/bin/grep -c 'endpoint' tools/_roundtrip-serialization-cdp.mjs)" = "0"
# The probe decodes entities before comparing — the fix for the false positive that
# nearly became a false alarm about a fixture AEF pins.
/usr/bin/grep -q 'function decodeEntities' tools/_t479-endpoint-roundtrip-cdp.mjs
# The corpus DI claim measured: namespace declared, zero DI elements (OBS-042).
test "$(/usr/bin/grep -rl 'xmlns:bpmndi' examples/aef-processes/rendered/ | wc -l)" = "24"
test "$(/usr/bin/grep -rl 'bpmndi:BPMNDiagram' examples/aef-processes/rendered/ | wc -l)" = "0"
# Verdict recorded with its severity, and scope held (no src, no standard edits).
/usr/bin/grep -q 'LATENT, not live' docs/reports/T-357-di-adoption.md
test -z "$(git diff --name-only HEAD -- src/ docs/standards/)"
/usr/bin/grep -q 'OBS-041' .context/inbox.yaml
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

### 2026-08-12T22:20:32Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-479-measure-whether-the-aefendpoint-misclass.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cad78fcd
- **Timestamp:** 2026-08-12T22:26:12Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T22:26:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
