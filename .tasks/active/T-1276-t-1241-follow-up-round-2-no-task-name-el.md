---
id: T-1276
name: "T-1241 follow-up round 2: no task name ellipsized on corpus maps; flow-label contrast AA"
description: >
  Codex amber on T-1241 AC1 (judge-t-1241-r5-codex-094a2e6d84f5, rev 1fdffed4): t1241-*-1920-panel.png cut 'completion gates ... Verification comman...' and 'partial-complete ... tick, compl...' (T-087 fit ladder ellipsizes at the floor), and flow labels are low contrast. Fix render-side without changing saved bytes; re-shoot; rerun the judge.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: [designer, ui, T-1241]
components: []
related_tasks: []
# write_set:                      # T-3512: optional — globs (relative to PROJECT_ROOT)
#                                 # naming the files this task intends to write. Declared
#                                 # at CAPTURE, unlike components: which the framework
#                                 # resolves from git history at close. Feeds TWO things:
#                                 #   1. `fw write-set check T-A T-B` — without it the
#                                 #      comparison has nothing to compare and every real
#                                 #      pair exits 2 (undecidable). 0 of 3032 tasks
#                                 #      declared it, so that gate has never had an input.
#                                 #   2. BVP blast_radius before close — the 0.6-weighted
#                                 #      cost term, unavailable for 85% of rankable tasks
#                                 #      because components: only exists once the task is
#                                 #      finished (T-3471).
#                                 # Example: write_set: ["lib/bvp.sh", "tests/unit/t*_bvp*"]
#                                 # An EMPTY list is a real declaration ("writes nothing"),
#                                 # which is not the same as omitting the field. Omitted
#                                 # means unknown, and unknown must never score as cheap.
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-1276` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-22T19:05:48Z
last_update: 2026-10-22T19:06:56Z
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

# T-1276: T-1241 follow-up round 2: no task name ellipsized on corpus maps; flow-label contrast AA

## Context

Second follow-up from T-1241's AC1 review (the first was T-1274). At revision 1fdffed4, the claude-code seat judged
green and the codex seat amber (evidence: `.context/reviews/evidence/T-1241/AC1-judge-t-1241-r5-codex-094a2e6d84f5.md`).
1. **Cut names.** In `docs/reports/T-1241-evidence/t1241-*-1920-panel.png`, two task names on `aef-task-lifecycle` end
   in "…": "completion gates: Agent ACs (P-010) + ## Verification comman…" and "partial-complete: review Human ACs
   (Watchtower /review), tick, compl…". This is T-087's fit ladder (`fitNodeLabels`): when a name overflows the rect
   one font step down, it is clamped to the line budget, ellipsized, and given a `<title>` tooltip. The criterion says
   "nothing clipped", and a cut name is clipped.
2. **Contrast.** Codex calls the flow labels low contrast.
3. **Not in scope.** Codex also finds the canvas text small at 1920. That is the fit zoom of a wide map, the user can
   zoom in, and it is answered in Decisions, not changed.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **No task name is ellipsized on any corpus map** at the default label size, in all four lenses, at 1024, 1440
      and 1920. Saved bytes are unchanged: render-only, and the rect geometry in the DI is not mutated. A new harness
      leg counts the `fitNodeLabels` floor hits per map. It is red on the 0.25.0 source (lifecycle ≥ 2) and 0 after.
      Any render-only growth of a rect never overlaps another node, label or lane edge; this is counted by the
      existing T-1256 legs, which stay green.
      **Evidence (2026-10-22):** `tools/_t1276-name-fit-cdp.mjs` leg 1 covers lifecycle + 24 corpus maps × 4 lenses ×
      1024/1440/1920, 2076 task names measured. On 0.25.0: red, 204 floor hits (17 names; lifecycle `tl_verify` +
      `tl_human_review` = 2 per lens per width, 8 per width). Now: **0** hits on every map. Every line is inside its rect
      (0 misfits); the smallest name font is 9px (≥ 8). Name lines under an in-rect badge went 51 -> 42, all of them
      pre-existing short names. No rect grows: the fix is a third in-rect ladder step (Decisions). Bytes: leg 3, 25/25
      maps unchanged; `_t1256` leg 3 25/25 unchanged. The T-1256 legs are green: crossings 134->1, flow labels crossed
      or clipped 3->2, near 31->10, label/label 20->0, the same as T-1274.
- [x] **Flow-label text meets WCAG AA (≥ 4.5:1)** against the canvas background in every theme the designer ships.
      This is measured from computed styles by a harness leg that is red on 0.25.0 where the ratio is below 4.5.
      **Evidence:** leg 2 of `_t1276-name-fit-cdp.mjs`. The designer ships one theme (`:root`; no `data-theme` or
      `prefers-color-scheme` is styled; the leg finds and walks any that appear). Worst flow label: rgb(139,145,163) on
      its halo rgb(13,15,19) = **6.1:1**, both before and after (0.25.0 is not below 4.5, so the leg is green there
      and no token changed; see Decisions).
- [x] **No guard regresses:** the 12 T-1274 guards plus `_t1274-note-box` stay green, run one at a time under nice 19.
      **Evidence:** final source, one at a time under `nice -n 19`, every one exit 0, with no reruns needed:
      `_t600 --self-test` (7 live / 4 failable, 2 poison arms), `_t601 --self-test` (6 live / 4 failable),
      `_t1068 --self-test` (5 live / 6 failable, 4 arms), `_t1067` 6/6, `_t1078` 8, `_t1241-business-lens`, `_t1176`,
      `_t1249-v11-io`, `_t1256` (all legs; 1024 min text 7.02px ≥ 7), `_editor-behavior-verify`, `_t1091` 31/31,
      `_endpoint-overlap-verify`, `_t1274-note-box`.
- [x] **Shots:**
  - re-shoot all 48 T-1241 lens shots;
  - make 2x crops of both named nodes and a flow-label run in each lens at 1920 into
    `docs/reports/T-1276-evidence/`;
  - fill the `## Visual Verification` table control by control;
  - the orchestrator then reruns `fw reviewer judge T-1241 --criterion 1`.
  **2026-10-23, met:** the rerun at 6d03c1b9 was amber from the codex seat on a new point, the arrowhead crossing,
  handled by T-1277. After T-1278, the rerun at fc2c7339 was green on all three seats (claude-code, codex, opencode),
  applied as V-20261022-73c28dd4.

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
         1. Run `bin/fw reviewer T-1276`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1276 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

<!--
  Render-touching build tasks (web/templates, web/static, web/blueprints, web/shared.py,
  web/app.py …) add a section headed "Visual Verification" (level-2 heading) after
  Verification, with one checklist table — the check-visual-verification gate reads it
  at commit time (T-4213; T-4202 GO):

    | state | control | 1024 | 1440 | 1920 | note |
    |-------|---------|------|------|------|------|
    | toolbar | Load | ok | ok | ok | |

  Cells: ok / clipped / hidden / overlap / unreachable (non-ok needs a note). Each
  listed state needs screenshots at every UX_SHOT_WIDTHS width:
  fw ux shots <T-ID> <state>=<URL>. This comment is inert: the gate ignores it.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
# Build/refactor/decommission tasks with NO command here are refused. If nothing can be
# run, add the line `# verification: none — <why nothing can be run>`; it is serviced
# (queued for review: add a check / other evidence / accept). See docs/reports/T-4024-servicing-loop.md.
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
# Vendored-path hint (T-3236, T-4419): if you edited bin/fw, lib/, agents/, policy/,
# web/, tools/ or .tasks/templates/, run `bin/fw vendor self` and add
#     bin/fw vendor self --check --task T-1276X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
node tools/_t1276-name-fit-cdp.mjs
node tools/_t1256-label-clearance-cdp.mjs
node tools/_t1274-note-box-cdp.mjs
test -s docs/reports/T-1276-evidence/name-verify-2x-business-1920.png && test -s docs/reports/T-1276-evidence/name-human-review-2x-business-1920.png

## Visual Verification

Shots: the 48 T-1241 lens shots were re-shot on this source (`tools/_t1241-lens-shots.py` →
`docs/reports/T-1241-evidence/t1241-{business,logical,technical,all}-{1024,1440,1920}-{panel,panel-bottom,details,details-bottom}.png`,
12/12 lens-select ok). True 2x crops (device_scale_factor 2, the lens-shot load: adopt, openingZoom, lens, `tl_create`
selected; temp script, deleted) are in `docs/reports/T-1276-evidence/`:
`name-verify-2x-{lens}-1920.png`, `name-human-review-2x-{lens}-1920.png`, `flow-labels-2x-{lens}-1920.png` (12).
At 1024 and 1440 the two named nodes are right of the opening viewport (the canvas scrolls). There the harness (leg 1,
every width) is the measure, and the cells say so.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| canvas, every lens | "completion gates: Agent ACs (P-010) + ## Verification commands (P-011)" (`tl_verify`) | ok | ok | ok | 1920 crops: whole name in 4 lines at 9px ("completion gates: Agent / ACs (P-010) + ## / Verification commands / (P-011)"), inside the rect, no "…"; technical/all: `agt_6_completion` caption right of the bottom flow, clear of it. 1024/1440: off the opening view, harness 0 floor hits |
| canvas, every lens | "partial-complete: review Human ACs (Watchtower /review), tick, complete" (`tl_human_review`) | ok | ok | ok | 1920 crops: whole in 4 lines ("partial-complete: / review Human ACs / (Watchtower /review), / tick, complete"), the user glyph top-left is clear; technical/all `hum_1_partial` below the rect. Also whole in `t1241-business-1920-panel` |
| canvas, every lens | flow labels: "blocked — unchecked AC / non-zero Verification; fix and retry", "no", "pass", "no — all ACs / agent-verifiable", "yes — status: issues", "resolved — back to work", "resolved at gate — complete directly (…)", "yes — partial-complete (owner: human)" | ok | ok | ok | 1920 crops: each label whole on its halo, none on a line, an arrow head or another label; the grey on near-black reads clearly at 2x (6.1:1). "heavy sub-work → dispatch" and the left task are cut only by the crop's edge. 1024/1440: `_t1256` leg 5 (0 crossed/clipped/near on lifecycle) |
| canvas, technical/all | gateway names + id captions beside the run (`agt_gw_issues`, `agt_gw_gates`, `agt_gw_unchecked`) | n/a | n/a | ok | above or below their diamond, none on a flow label's row |
| full shot, business 1920 | toolbar (Business lens, Check, Versions, Save to project, Save), side panel Name/Lane/Note/Owner | ok | ok | ok | t1241-business-1920-panel: one toolbar row complete; Note shows all three lines; both named nodes whole on the canvas. 1024 technical and 1440 all panels: toolbar wraps to two rows, every button visible |

Review of these screenshots by an independent agent: rerun of `fw reviewer judge T-1241 --criterion 1` (criterion 4,
left to the orchestrator).

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

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-10-22 — how a long task name fits without the floor ellipsis
- **Chose:** a third fit-ladder step inside the same rect (`fitNodeLabels`, T-087): at the default size 9px / 10.5px line
  pitch, five lines in the 64px rect where step 2 (10px / 12px) had four. Its lines are wrapped by **measured** width
  rather than the char estimate, and a token wider than the rect breaks after a separator inside it (`/ | , ; > )`), the
  way CSS `overflow-wrap` does. Five of the 17 cut names were single tokens such as `(--host/--task/--agent/--summary/--result)`,
  which no font size or extra line could fit. The `s` and `l` sizes get the same step (8px / 9.5, 10px / 11.5). The floor
  (ellipsis + `<title>`) stays as the last resort for a pathological name; no corpus name reaches it.
- **Why:** this is the only candidate that touches nothing outside the rect, so it cannot add an overlap, a crossing or a
  lane-edge hit that the T-1256 legs count. It needs no new obstacle model, and it is a few lines in the one function
  that already owns the fit. Measured: 0.25.0 had 204 floor hits (17 names × 4 lenses × 3 widths; lifecycle 2 per lens);
  this source has 0. The smallest name font is 9px (≥ 8). Every line stays inside the rect (0 misfits). Name lines under
  an in-rect badge went from 51 to 42, every remaining one a short default-step name that already overlapped in 0.25.0.
- **Rejected:** (a) growing the rendered rect downward: it needs free-space search against the flows, labels, id
  captions and lane edges below it, the flows' endpoints would no longer meet the drawn edge, and a rect that differs
  from the DI misleads anyone reading the shape as the stored geometry. (b) The label strip below the rect: that is where
  the id caption and bottom-centre flows sit (T-1090), so it creates the same near/overlap pairs T-1256/T-1274 just
  removed. A name split between inside and below reads as two labels.

### 2026-10-22 — flow-label contrast and canvas text size
- **Chose:** no colour change. Measured from computed styles (`tools/_t1276-name-fit-cdp.mjs` leg 2): flow-label fill
  `--text-dim` rgb(139,145,163) on its halo pad `--bg` rgb(13,15,19) = **6.1:1** in the one theme the designer ships
  (`:root`; the source styles no `data-theme` and no `prefers-color-scheme`). That is the same on 0.25.0, so the leg is
  green there: it is ≥ 4.5 and the instruction was to change the token only below AA.
- **Why:** the reviewer's "low contrast" at 1920 is the fit zoom of a wide map. The 10px mono label renders at about
  7px, and antialiasing thins it; the ratio itself is AA. Codex's "canvas text small at 1920" is out of scope per Context
  §3: it is the fit zoom, and the user can zoom in.
- **Rejected:** brightening `--text-dim` anyway: it is used by ~30 chrome controls, so it would shift the whole UI's
  hierarchy to answer a size complaint, not a contrast failure.

### 2026-10-22 — side effect on the opening zoom (orchestrator's review)
- **Observed:**
  - The re-shot `t1241-*-1920-*.png` open at **78%**, no longer at fit. `openingZoom()` (T-1256) measures the
    smallest node-name font. The new 9px step brings fit at 1920 below `OPEN_MIN_TEXT_PX` (7), so the map opens at
    the readable zoom, scrolled to the top-left.
  - The pool's right edge, past the end event, is then reached by scrolling: it sits under the side panel and is
    not hidden.
- **Chose:** keep it.
  - It is T-1256's designed behaviour: open readable, and Fit still shows the whole map.
  - It answers the other half of codex's amber (canvas text too small at 1920) without a separate change.
- **Rejected:** excluding the step-3 names from `openingZoom`'s minimum. The map would then open at fit, with those
  names drawn below 7px, exactly what T-1256 set out to prevent.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1276 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-22T19:05:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1276-t-1241-follow-up-round-2-no-task-name-el.md
- **Context:** Initial task creation

### 2026-10-22T19:06:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
