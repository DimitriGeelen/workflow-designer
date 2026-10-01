---
id: T-962
name: "T-309 slice 3: show findings ON the map — node badges for anchorable findings, a list for the rest, and 'not yet checked' as its own state"
description: >
  T-309 slice 3: show findings ON the map — node badges for anchorable findings, a list for the rest, and 'not yet checked' as its own state

status: work-completed
workflow_type: build
current_node: frw_8_partial
owner: human
horizon: now
tags: []
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tests/test_t962_findings_on_map.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-01T06:57:15Z
last_update: 2026-10-01T08:39:28Z
date_finished: 2026-10-01T08:39:28Z
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

# T-962: T-309 slice 3: show findings ON the map — node badges for anchorable findings, a list for the rest, and 'not yet checked' as its own state

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

T-961 gave the designer `validateCurrentWorkflow()`; nothing shows the answer. The operator
ruled the shape on 2026-10-01: *"a check that shows the errors and also makes it visibly in the
flow so we can remediate it"* — findings on the map, not only in a list — with auto-fix as a
later ideal (slice 4, T-963) and the operator interacting rather than being blocked.

Priced in `docs/reports/T-309-iw1-where-findings-surface.md`. Two measurements constrain this:

1. **Markers need a per-rule list, not a severity gate.** `W-XML-GW-AMBIGUOUS` fires on 47 of
   AEF's 48 live gateways and 0 of ours (T-325) — it reports which toolchain wrote the file.
   It is a `WARN`, and so are the genuinely valuable "the picture disagrees with the file"
   rules (`W-XML-LANE-GEOMETRY`, `W-XML-LANE-CAPACITY`). Severity cannot separate them.
2. **Not every finding can be a marker.** `location` names a node for node-anchored rules, but
   lane- and document-level rules (geometry, overflow, parse, structure) have no node to sit
   on. Those must reach the operator by another route or they are silently lost.

`gBadges` / `gBadgesTop` are `pointer-events:none`, so a marker there cannot be clicked. This
slice therefore marks the node visually and makes the **list row** the interactive element,
reusing existing selection rather than adding an interactive SVG layer.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A **Check** action runs `validateCurrentWorkflow()` and renders its result. Hidden when
      the API is unavailable, following the existing `detectSaveApi()` gating, so the
      standalone `file://` build does not offer a button that cannot work.
- [x] **Node-anchored findings put a marker on the offending node.** The node id is parsed
      from `location`, and the parse is **verified against real validator output** rather than
      assumed from the rendered message text — I have not yet read the raw `location` value
      and will not design the parse before I do.
- [x] **Nothing is silently dropped: `markers + list rows == total findings`,** asserted in the
      test. This is the false-green shape at this layer — a finding whose location does not
      resolve to a node must appear in the list, never vanish because it had nowhere to sit.
- [x] **Three states are visually distinct, never conflated:** `not yet checked`,
      `checked — no findings`, and `could not check` (validator unavailable / unreachable).
      T-961 made that distinction true at the function boundary; it dies here if an unchecked
      map renders the same as a clean one.
- [x] **A declared per-rule marker allowlist in one place**, with `W-XML-GW-AMBIGUOUS`
      excluded and the 47-of-48 measurement stated as the reason in the code. The comment
      names `tests/test_rule_dialect_axis.py` as the mechanism that should replace the hand
      list (currently `grep -c dialect tools/validate-workflow.py` → 0).
- [x] Clicking a list row **selects the node** so the operator can act on it — the
      "so we can remediate it" half of the request.
- [x] **Visual verification per CLAUDE.md**, not DOM math: element-level Playwright
      screenshots of the marker and the list, read back with the Read tool, across the modes
      this can affect (theme, density, font) — recorded in `## Visual Verification` below.

### Human
- [ ] [REVIEW] **One judgement call: does the finding marker duplicate the existing
      "⚠ no authority" label, and should it?**

  Narrowed on the reviewer's `human-ac-mechanical-signal` finding, and it was right: the
  version of this AC asked you to confirm that markers appear and that the state line is
  never blank — both of which `tests/test_t962_findings_on_map.py` now asserts mechanically
  (9 legs, including the three states staying distinct). Asking a human to re-verify a
  green test is how a Human AC becomes administrative overhead. What is left is the part no
  test can settle.

  **Steps:**
  1. `bash /opt/832-Workflow-designer/runme.sh` — rebuilds from the working copy and serves
     it, then prints the URL. (Your usual `/designer/app` cannot show this: it serves a
     pinned, sha256-verified bundle, and the pin is currently broken — OBS-463.)
  2. Open a map, drag a step below every lane band, press **✓ Check**.
  3. Look at that step. It will often carry BOTH a red `✖` finding marker (bottom-right)
     and the older `⚠ no authority` label (top-left).

  **Expected:** your call on one of three — leave both (they are different conditions:
  "no lane, so no authority derivable" vs "authority not stated"), suppress the finding
  marker when the authority label is already showing, or merge them into one mark.

  **If not actionable:** if the two never appear together on your maps, say so and I will
  drop the question rather than engineer for a case that does not occur.

## Visual Verification

Captures in `docs/reports/t962-shots/`. Read back with the Read tool, not inferred from DOM
measurements — and reading them is what found both defects below.

| shot | what it showed |
|---|---|
| `t962-drawer-findings.png` | **DEFECT 1, found by looking.** `3 findings · … · 0 on the map`, every row saying *"not on the map"*. Markers silently placed nowhere. Cause: the validator reports the **exported** BPMN id, and I resolved against the internal `n.id`. T-884's instance overlay already knew this and uses `displayIdOf(n)`. Every DOM assertion would have passed — the drawer rendered perfectly and told the truth about a wrong computation. |
| `t962-drawer-fixed.png` | After the fix: `3 findings · 3 errors, 0 warnings · 3 on the map`. |
| `t962-marker-clear.png` | The marker itself, zoomed: `✖` in a red pill at the node's bottom-right, legible on a circle shape and clear of the label. |
| `t962-marker-zoomed.png` | **DEFECT 2, found by looking.** The floating drawer sat on top of the diagram — covering the very map you are meant to remediate, and potentially covering a node that clicking a row had just selected. Re-docked to the bottom of the canvas column. |
| `t962-docked-1600.png` | Final state at 1600×1000: dock spans exactly the canvas column (220→1280), diagram unobstructed, three readable rows, markers visible on all three offending nodes. |

**Mode matrix, scoped to what exists.** CLAUDE.md names theme/density/font/language modes
generically; this designer **has none of them** — the settings modal carries only geometry and
routing controls, and there is no theme switcher (`grep` for `data-theme` /
`prefers-color-scheme` → nothing). The modes that do apply are the layout variants, which is
exactly where I had written untested CSS. Measured:

| variant | drawer left→right | display |
|---|---|---|
| default | 220 → 1280 | flex |
| `vc-no-palette` | 0 → 1280 | flex |
| `vc-no-props` | 220 → 1600 | flex |
| `vc-focus` | — | **none** (focus mode strips chrome; a dock is chrome) |

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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.
#
# ── T-962 ─────────────────────────────────────────────────────────────────────
# Each line rehearsed under `bash -c 'set -o pipefail; <line>'`. No `git diff`
# line (PL-365: it goes vacuously true once committed) and no global count
# (G-015): every line asserts a fact about this slice's own artefacts.

grep -q 'async function validateCurrentWorkflow' src/aef-workflow-designer.html && grep -q 'FINDING_MARKER_RULES' src/aef-workflow-designer.html
timeout 240 python3 tests/test_t962_findings_on_map.py > /tmp/.t962-t.out 2>&1 && grep -q 'allowlist quiets the canvas without hiding a row' /tmp/.t962-t.out
# The two legs that guard defects already made once here, named individually so a
# suite that silently stopped running them cannot pass this gate.
grep -q 'the displayIdOf regression' /tmp/.t962-t.out
grep -q 'test_t962_findings_on_map.py' tests/run-bridge-tests.sh
bash -n tests/run-bridge-tests.sh
grep -q "data-state=.unchecked." src/aef-workflow-designer.html

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
-->

**Recommendation:** GO

**Rationale:** The slice is complete and mechanically guarded. Validator findings now reach
the author: a marker on each offending node, a dock listing every finding, and three states
that stay distinct. The one open item is a taste question about visual duplication that does
not block the mechanism and cannot be settled by a test — if the answer is "leave both", no
code changes at all.

**Evidence:**
- `tests/test_t962_findings_on_map.py` — **9/9**, driving the real editor in headless chromium
  against the real `gallery-serve.py`, from a docroot asserted byte-identical to `src/`.
- Two legs guard defects already made once in this slice: markers resolve by `displayIdOf`
  (the exported id the validator names — matching `n.id` placed **zero** markers while the
  dock said "3 findings, 0 on the map"), and `W-XML-GW-AMBIGUOUS` is asserted **listed (1)
  and marked (0)**, so the allowlist quiets the canvas without hiding a row.
- Teeth: `T962_DESIGNER_SRC` pointed at the pre-change designer exits **3**, refusing.
- Wired into `tests/run-bridge-tests.sh`, so it has a scheduled reader rather than a one-shot
  Verification block (PL-161).
- Visual verification: 7 captures in `docs/reports/t962-shots/`, read back — and **reading
  them is what found both defects**, neither of which any DOM assertion would have caught.
- Four layout variants measured, including focus mode correctly suppressing the dock.
- Reviewer: **PASS**, no findings.

**What this slice deliberately does not do:** propose or apply fixes (slice 4, where
`laneAtY` returning `null` is what separates a derivable fix from inventing an owner), and
consume `tests/test_rule_dialect_axis.py` — which would let the hand-written
`FINDING_MARKER_RULES` list be deleted rather than extended.

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

### 2026-10-01T06:57:15Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-962-t-309-slice-3-show-findings-on-the-map--.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2210b8a7
- **Timestamp:** 2026-10-01T08:39:32Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-10-01T08:39:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
