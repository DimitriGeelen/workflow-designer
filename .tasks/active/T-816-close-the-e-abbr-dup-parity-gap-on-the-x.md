---
id: T-816
name: "Close the E-ABBR-DUP parity gap on the XML path (T-309 prerequisite, F-04)"
description: >
  T-309's GO carries a revised shape the value review's F-04 did not capture: only 7 rule ids are shared between the YAML Validator and the XmlValidator, and the designer speaks BPMN — so surfacing 'the validator' in the editor today would surface the WEAKER rule set. Parity is the prerequisite, measured by tests/test_rule_form_parity.py: 49 rules classified, 11 gaps. E-ABBR-DUP is the highest-carrier one — lane abbr is carried by 96/96 BPMN maps and NO XML rule checks its uniqueness, while the YAML path has checked it since the beginning. aef:laneMeta already carries abbr and XmlValidator already reads laneMeta, so the predicate has everything it needs. Close this one gap properly rather than half-closing five.

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
created: 2026-09-22T14:20:37Z
last_update: 2026-09-22T14:20:37Z
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

# T-816: Close the E-ABBR-DUP parity gap on the XML path (T-309 prerequisite, F-04)

## Context

Value review **F-04** calls in-editor schema validation *"the largest capability gap against
the stated purpose."* Its remedy is not "port the validator" — **T-309's GO carries a revised
shape the review did not capture**, found when its first spike ran:

> "only 7 rule ids are shared between the two classes… The designer speaks BPMN. So surfacing
> 'the validator' in the editor today would surface the weaker rule set, and would
> specifically NOT answer the gateway question that prompted this inception."

**Parity is the prerequisite**, and it is already measured: `tests/test_rule_form_parity.py`
reported 49 rules, **11 gaps**. `E-ABBR-DUP` is the one with the highest carrier count in the
whole table — lane `abbr` carried by **96/96** bpmn maps, and nothing on that form checked it,
while the YAML path has since the beginning.

`aef:laneMeta` already carries `abbr` and `XmlValidator` already walks `laneMeta`, so the
predicate had everything it needed. One gap, closed properly.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `XmlValidator` emits `E-XML-ABBR-DUP` when two lanes carry the same `aef:laneMeta abbr`, matching the YAML path's long-standing `E-ABBR-DUP`
- [x] It reads `abbr` from the `laneMeta` element the validator already walks — no second lane traversal, and no duplicated vocabulary constant (the mistake `E-XML-AUTHORITY`'s comment names)
- [x] The parity table moves `E-ABBR-DUP` from GAP to PAIRED, and `test_rule_form_parity.py` stays green
- [x] The whole 24-map corpus still validates clean: closing a parity gap must not manufacture findings on maps that were always valid
- [x] CONTROL: the rule is proven to FIRE, by injecting a duplicate abbr into a throwaway copy of a real corpus map — a rule that never fires is indistinguishable from an absent one
- [x] CONTROL: the rule is proven NOT to fire on distinct abbrs, so it is discriminating rather than merely noisy
- [x] A lane with no `abbr` at all is silent, not an error — absence of an optional carrier is not a violation


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-816 legs. Each line's exit code is its own verdict; no chaining. ---
grep -q 'E-XML-ABBR-DUP' tools/validate-workflow.py
# Both classification axes must accept the new rule. Each REFUSED it at first — see Decisions.
python3 tests/test_rule_form_parity.py
python3 tests/test_rule_dialect_axis.py
# Fires on a duplicate, silent on distinct abbrs, silent when the carrier is absent.
./tools/_t816-abbr-dup-controls.sh
# Closing a parity gap must not manufacture findings: no corpus map may report the rule.
bash -c 'n=0; for f in examples/aef-processes/rendered/*.bpmn; do n=$((n + $(python3 tools/validate-workflow.py "$f" 2>&1 | grep -c "E-XML-ABBR-DUP"))); done; test "$n" -eq 0'
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

### 2026-09-22 — close ONE gap properly rather than start the editor surface

- **Chose:** implement `E-XML-ABBR-DUP` and stop there.
- **Why:** F-04's headline remedy ("ADD the surface") is a multi-session build — the validator
  is 1773 lines and 50 rule codes, and the designer is standalone HTML that cannot call a
  Python CLI. Task sizing says split at 3+ sessions. More importantly **T-309 already
  identified the real critical path**: the editor would surface the weaker XML rule set, so
  parity comes first. This is that path, not a detour from it.
- **Why this gap first:** highest carrier count in the table (96/96), and the carrier and the
  walk both already existed, so the change is a predicate rather than an architecture.
- **Rejected — implementing all 8 XML-path gaps:** five have live carriers and three have
  zero authored carriers. Doing five at 60% context risks finishing none. Three of the five
  (`E-CONST-DUP`, `E-CONST-SHAPE`, `W-CONST-FIELD`) share one carrier and are a coherent next
  unit.
- **Rejected — duplicating the vocabulary:** the rule reads `abbr` from the `laneMeta` the
  authority walk already resolved, in the same pass. `E-XML-AUTHORITY`'s comment names the
  alternative as the defect: *"a second copy of the vocabulary is how the one-form-only family
  reproduces itself one level down."*

### 2026-09-22 — both classification guards refused the rule, and both were right

- **`test_rule_form_parity.py`:** *"rule 'E-XML-ABBR-DUP' is emitted by the validator but has
  no parity classification… Adding a rule to one form without deciding whether the other form
  needs it is exactly the T-317 class."* Then, once classified, it refused again — the gap
  count moved 11 → 10 and the guard said **"do not adjust the constant to match"**, requiring
  the arithmetic be re-derived in `docs/reports/T-320-rule-form-parity-census.md`. Done there:
  abbr was a one-id family, so families fall 7 → 6 and ids 11 → 10.
- **`test_rule_dialect_axis.py`:** *"declares no carrier in RULE_CARRIERS. Until it does,
  nothing knows whether surfacing it to an author states a correctness fact or a house
  convention."* Declared `aef:laneMeta/@abbr` + `CONSTRAINS`, matching the YAML rule exactly —
  the pair must agree on the axis or the two forms classify one fact two ways.
- **Worth recording:** two independent guards each caught the same omission from a different
  angle, and neither could be satisfied by editing a number. That is what the T-317/T-320
  machinery was built for, working.

### 2026-09-22 — what I did NOT touch

- **`context-memory.bpmn` still exits 1**, and that predates this change — 0 errors, 7
  `W-LANE-NO-OWNER` warnings on `authority="none"`. Verified by stashing the change and
  re-running. It is the file we predicted to AEF would be refused; leaving it is correct.
- **Pyright reports 10 issues in `validate-workflow.py`** at lines 1359–1504 (`max`/`min` over
  a key returning `float | None`). All pre-existing geometry code — my diff touches only
  ~1573–1607. Surfaced by re-analysis, not introduced. Not fixed here: unrelated to this
  task, and silently touching geometry while closing a parity gap is how one change becomes
  two.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-816 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T14:20:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-816-close-the-e-abbr-dup-parity-gap-on-the-x.md
- **Context:** Initial task creation
