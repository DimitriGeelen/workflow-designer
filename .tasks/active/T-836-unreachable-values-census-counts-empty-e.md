---
id: T-836
name: "Unreachable-values census reports a flat count that hides three repair classes"
description: >
  RENAMED. Filed as "census counts empty elements as authored values (overstates by 6)".
  THAT PREMISE WAS FALSE and the disproof is kept in the ACs and RCA rather than deleted:
  it came from a probe that tested text and attributes and never tested CHILD ELEMENTS, so
  <aef:emits><aef:emit value="pass"/>...</aef:emits> read as empty. Measured: 0 of 30 are
  empty and TOTAL_UNREACHABLE=30 was right all along.
  What is real: the 30 unreachable values ride THREE different carriers - 18 text
  (endpoint), 6 attrs (aggregation over=/reduce=, multiInstance over=, timer
  kind=/cycle=/anchor=) and 6 children (emits -> <aef:emit value=...>, compensates ->
  <aef:compensate ref=...>). The carrier decides whether a repair is an AEF_FIELDS list
  edit or a field design, and one flat integer hid that distinction behind a single number.
  Worse, FIELD_META.emits is a single-line TEXT field sitting over a repeated-child payload
  - a wrong-shaped definition, which is more dangerous than an absent one because it looks
  like it works. Fix is in the census tool only. No panel change, no standard change, no
  AEF seam.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components:
  - tools/_t810-unreachable-values-census.py
related_tasks: [T-811, T-810]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-23T17:00:13Z
last_update: 2026-09-23T17:01:20Z
date_finished:
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
  - ts: '2026-09-23T17:00:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-23T17:00:43Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-23T17:01:07Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-836: Unreachable-values census counts empty elements as authored values (overstates by 6)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
> **THIS TASK'S ORIGINAL PREMISE WAS FALSE AND IS RECORDED, NOT QUIETLY SWAPPED.**
> Filed on the claim that 6 of the 30 unreachable values were EMPTY elements, overstating the
> gap by 6 (PL-332). Measured during the build: **0 of 30 are empty.** The claim came from
> testing text and attributes and never testing CHILD ELEMENTS, so
> `<aef:emits><aef:emit value="pass"/>…</aef:emits>` read as empty. The census's `30` was
> right all along. What IS true and useful is the corrected criteria below: the 30 split by
> **carrier shape**, and the shape decides whether a repair is a list edit or a field design.
> The original ACs are struck through below rather than deleted.

- [x] ~~The census separates content-bearing from empty · expected 24 content, 6 empty~~
      **WITHDRAWN — premise disproved. Measured 30 content, 0 empty.**
- [x] ~~The empty six are named individually~~ **WITHDRAWN — there are no empty six.**

- [x] **The census reports CARRIER SHAPE per group: text / attrs / children / EMPTY.** A value
      is `text` if its element has non-whitespace text, `attrs` if it has attributes,
      `children` if it has child elements — recorded as a combination, `EMPTY` if none.
      `TOTAL_UNREACHABLE` keeps its current meaning so nothing downstream changes under the
      same name. Expected on today's corpus: **text 18, attrs 6, children 6, empty 0.**

- [x] **The output states what each shape implies for the repair**, because the shape is the
      whole reason this split is worth having: a text carrier can go in a text field; an
      attrs or children carrier cannot, and `FIELD_META.emits` is a plain text field sitting
      over a children carrier — offering it would misrepresent the value and may destroy it
      on save.

- [x] **A control proves each branch MOVES, not merely that it printed.** Mutations on a
      throwaway root (`T810_REPO_ROOT`, real corpus never written): a children carrier
      converted to text must shift 18/6/6 → 19/6/5, and an attrs carrier stripped of its
      attributes must fall to 18/5/6/1. A split that cannot report a different number on
      different input is not measuring anything (PL-206).

- [x] **The EMPTY branch is proven reachable.** The real corpus has zero empties, so that
      branch is never exercised by a normal run and a dead branch would be indistinguishable
      from an honest zero (PL-307). The attrs-stripping mutation is the leg that fires it.

- [x] **A regression leg pins the false premise shut:** `emits` must be reported as a
      `children` carrier on the untouched corpus, never as EMPTY. This leg exists solely
      because this task was filed on the claim that it was empty.

- [x] **The prose path is byte-identical for the pre-existing lines**, verified by diffing
      this tool's output against `git show HEAD:<tool>` on the same throwaway root — the
      split is additive output only.

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
         1. Run `bin/fw reviewer T-836`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-836 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

bash tools/_t836-census-empty-split-controls.sh
python3 tools/_t810-unreachable-values-census.py > /tmp/.t836-census.out 2>&1 && grep -q "^UNREACHABLE_CARRIER_TEXT=18$" /tmp/.t836-census.out
python3 tools/_t810-unreachable-values-census.py > /tmp/.t836-c2.out 2>&1 && grep -q "^UNREACHABLE_CARRIER_CHILDREN=6$" /tmp/.t836-c2.out
python3 tools/_t810-unreachable-values-census.py > /tmp/.t836-c3.out 2>&1 && grep -q "^UNREACHABLE_EMPTY=0$" /tmp/.t836-c3.out
python3 tools/_t810-unreachable-values-census.py > /tmp/.t836-c4.out 2>&1 && grep -q "^TOTAL_UNREACHABLE=30$" /tmp/.t836-c4.out

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

## RCA

**Symptom (as filed):** `tools/_t810-unreachable-values-census.py` reports
`TOTAL_UNREACHABLE=30`, of which 6 were believed to be empty elements carrying nothing —
so every reading of this population since T-810 supposedly started from a number wrong by 6.

**Root cause — of the FILING, not of the tool.** The symptom was not real. The claim that 6
were empty came from a measurement (T-811 §S-5) that tested two carriers, text and
attributes, and never tested a third: child elements. `<aef:emits>` carries
`<aef:emit value="pass"/><aef:emit value="warn"/>`; `<aef:compensates>` carries
`<aef:compensate ref="…"/>`. Both read as empty under a text-or-attributes test. Measured
correctly: **30 of 30 carry content, 0 are empty.** The census was right; the probe written
to audit it was wrong.

**Why structurally allowed.** Nothing enforced that a new measurement enumerate the carriers
it could encounter before asserting over them. The failure shape is the one T-811 exists to
document and had *just finished documenting* — reasoning forward from a mechanism without
measuring the population it acts on (PL-288: a chosen-set assertion cannot find what you
forgot to choose; here the chosen set was "text or attributes"). Committing it inside the
task that names the pattern is the sharpest evidence that naming a pattern does not confer
immunity to it.

**Prevention — distinct from the fix.** Two things, both live:
1. The census no longer answers "is there content" (whose answer is always yes and therefore
   carries no information). It answers "what SHAPE is the carrier", which is the question
   that actually decides whether a repair is an `AEF_FIELDS` list edit or a field design.
2. `tools/_t836-census-empty-split-controls.sh` Leg 5 pins the false premise shut: it fails
   if `emits` is ever reported as EMPTY again. Leg 4 proves the EMPTY branch can fire at all
   — the corpus has zero empties, so without a mutation that branch is dead and an honest
   zero is indistinguishable from a broken test (PL-307).

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
     fw inception decide T-836 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-23T17:00:13Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-836-unreachable-values-census-counts-empty-e.md
- **Context:** Initial task creation

### 2026-09-23T17:01:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
