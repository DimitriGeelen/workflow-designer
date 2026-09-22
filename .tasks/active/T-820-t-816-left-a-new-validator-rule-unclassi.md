---
id: T-820
name: "T-816 left a new validator rule unclassified on two of four axes"
description: >
  Found by running the full suite after T-816 completed. Adding E-XML-ABBR-DUP requires classifying it on FOUR independent axes, and T-816's verification legs ran only two. Missed: (1) tests/test_finding_anchorability.py ANCHOR — 'an unclassified rule is measured against the wrong population and manufactures a false answer'; (2) tests/test_harness_cross_form_agreement.py PAIRS — 'a rule added to the parity table without a behavioural decision would be reported as agreeing by a guard that never compared it'. Both are exactly right and both caught a real hole: marking a rule PAIRED in the parity table is a CLAIM that the two forms agree, and nothing had compared them on a document. T-816's own legs passed because they asserted the two axes I knew about — the legs were as incomplete as the work. Classified ANCHOR=LANE (the duplicated thing is an attribute, not an id, so the location names a unique resolvable lane) and PAIRS E-ABBR-DUP<->E-XML-ABBR-DUP; cross-form now reports 21 pairs, 18 agree, OK.

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
created: 2026-09-22T15:11:08Z
last_update: 2026-09-22T15:11:08Z
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

# T-820: T-816 left a new validator rule unclassified on two of four axes

## Context

Found by running the full 810s suite *after* T-816 was completed and committed.

Adding one validator rule requires satisfying **five** independent axes, maintained in five
separate files. **T-816 satisfied two** — form parity and the dialect axis — wrote its
verification legs for exactly those two, and passed its own gate. **The legs were as
incomplete as the work**, which is why a task-scoped gate could not catch it.

The three missed, each demanding something genuinely different:

| axis | what it asks | its own words |
|---|---|---|
| anchorability | can the canvas point at it? | *"measured against the wrong population and manufactures a false answer"* |
| cross-form agreement | do the two forms actually AGREE on a document? | *"would be reported as agreeing by a guard that never compared it"* |
| pass reachability | has anyone ever SEEN it fire? | *"a rule nobody has ever seen fire is a rule nobody has shown to work"* |

The second is the sharpest: marking a rule **PAIRED** is a *claim* that two implementations
agree, and nothing had compared them on a real document until this axis refused.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `E-XML-ABBR-DUP` is classified on the anchorability axis, with the LANE-vs-VALUE choice reasoned from what the canvas can actually point at
- [x] `E-ABBR-DUP` ↔ `E-XML-ABBR-DUP` is entered in the cross-form `PAIRS` table, and the behavioural comparison actually runs and reports AGREE on real documents
- [x] ~~ALL FOUR axes~~ **ALL FIVE** axes pass, run together. Written as four; a fifth (`test_check_pass_reachability.py`) was found by the suite *after* this AC was written and after the tool listing four had been built. Corrected in place — the miscount is the finding restating itself.
- [x] A single command exists that runs every axis, so the next rule author cannot repeat this by knowing only the axes they happened to meet
- [x] CONTROL: that command is proven to fail when any one axis is unsatisfied, not merely when all four are


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-820 legs. Each line's exit code is its own verdict; no chaining. ---
# ONE command, all five axes. This is the leg T-816 should have had.
./tools/_t820-rule-axes.sh
# The witness fixture must exist AND fire exactly the rule it witnesses — a fixture that
# fires two rules witnesses neither cleanly.
test -s tests/fixtures/invalid/E-XML-ABBR-DUP.xml
bash -c 'out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-ABBR-DUP.xml 2>&1); echo "$out" | grep -q "E-XML-ABBR-DUP"'
bash -c 'out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-ABBR-DUP.xml 2>&1); echo "$out" | grep -q "1 error(s), 0 warning(s)"'
# CONTROL: the axis runner must FAIL when any ONE axis is unsatisfied, not only when all are.
./tools/_t820-axes-controls.sh
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

### 2026-09-22 — a fixture, not a declaration

- **Chose:** write `tests/fixtures/invalid/E-XML-ABBR-DUP.xml`, derived from a
  bridge-generated sibling by collapsing the second lane's abbr onto the first.
- **Why not declare it never-witnessed:** that escape exists for rules no document can reach
  (`E-LOAD` fires on file-not-found). This rule is trivially witnessable, so declaring it
  would be using the exemption to avoid the work it exists to make unnecessary.
- **Why my control probe did not satisfy the axis, and shouldn't have:**
  `_t816-abbr-dup-controls.sh` does prove the rule fires — in a throwaway temp copy that no
  other instrument can see. The axis wants a witness that **outlives the run that made it**.
  Both are right and they are not the same guarantee.
- **The fixture witnesses ONE rule:** the source carried `authority="overlord"`, which would
  have fired `E-XML-AUTHORITY` too. Restored to a valid value, so the document says exactly
  one thing. Verified: 1 error, 0 warnings.

### 2026-09-22 — the tool I built to prevent this repeated the mistake while I built it

- `tools/_t820-rule-axes.sh` was written listing **four** axes, because four was what the
  suite had shown me. The fifth surfaced minutes later, from the same suite.
- **That is the argument for the tool, not against it.** The list belongs somewhere a reader
  can extend rather than in the head of whoever last added a rule. The header now says so and
  tells the next person to add to `AXES` — *"and it is a when."*
- The stale "four" claims in the header were corrected rather than left. A comment whose
  central claim has quietly stopped being true is the T-361 defect, and I fixed that exact
  shape in T-808 this morning.

### 2026-09-22 — what this says about task-scoped verification

- T-816's legs were green and its work was incomplete, and **no task-scoped gate could have
  told the difference** — the legs asserted what their author knew. Only the suite, which
  knows things no single task does, caught it.
- That is the strongest argument this session has produced for F-03's remedy: the suite is
  the only thing holding knowledge no individual task carries, and **nothing schedules it**.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-820 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T15:11:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-820-t-816-left-a-new-validator-rule-unclassi.md
- **Context:** Initial task creation
