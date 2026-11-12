---
id: T-1395
name: "CDP harness waits forever when Chrome dies mid-command (_t358-laneless hung
  2 h in T-358's close)"
description: >
  A CDP command's reply promise has no timeout and is not rejected when the socket
  closes. In T-358's close (2026-11-11, load ~45) Chrome died under _t358-laneless-render-cdp.mjs
  and the harness waited 2 h in ep_poll with no Chrome child, holding the whole browser
  tier. The cdp() helper is hand-copied in many tools/*.mjs harnesses, so the class
  is wider than this one file.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: []
components: [tools/_align-distribute-diag.mjs, tools/_autoload-verify-cdp.mjs, tools/_autosave-verify-cdp.mjs, tools/_bridge-seam-roundtrip-cdp.mjs, tools/_cdp-client.mjs, tools/_clean-layout-cdp.mjs, tools/_edge-straighten-verify-cdp.mjs, tools/_editor-behavior-verify-cdp.mjs, tools/_endpoint-hover-verify-cdp.mjs, tools/_endpoint-overlap-verify-cdp.mjs, tools/_horizontal-spacing-verify-cdp.mjs, tools/_label-overlap-probe.mjs, tools/_node-cuts-cdp.mjs, tools/_roundtrip-serialization-cdp.mjs, tools/_saveproject-verify-cdp.mjs, tools/_selection-align-verify-cdp.mjs, tools/_t1091-sticky-lanes-cdp.mjs, tools/_t1154-pool-label-fit-cdp.mjs, tools/_t1158-witness-per-verdict-teeth.sh, tools/_t1164-lane-findings-cdp.mjs, tools/_t1193-slug-readonly-cdp.mjs, tools/_t1194-slug-task-id-cdp.mjs, tools/_t1217-native-link-definition-cdp.mjs, tools/_t1218-unnamed-event-name-cdp.mjs, tools/_t1220-io-extra-attrs-cdp.mjs, tools/_t1243-io-children-cdp.mjs, tools/_t125-lane-compaction-cdp.mjs, tools/_t1265-condition-language-cdp.mjs, tools/_t1268-node-aef-children-cdp.mjs, tools/_t1301-io-edit-cdp.mjs, tools/_t1325-element-passthrough-cdp.mjs, tools/_t1326-process-level-kept-cdp.mjs, tools/_t1327-comments-and-notice-cdp.mjs, tools/_t1327-notice-shots.mjs, tools/_t1350-dense-boundary-cdp.mjs, tools/_t1384-advisory-dock-cdp.mjs, tools/_t1392-settings-reach-cdp.mjs, tools/_t1395-cdp-client-selftest.mjs, tools/_t233-ghost-cards-cdp.mjs, tools/_t249-spike-zoom-cdp.mjs, tools/_t251-visual-shots.mjs, tools/_t253-live-url-probe.mjs, tools/_t255-visual-shots.mjs, tools/_t258-annotation-seam-cdp.mjs, tools/_t259-eventdef-preservation-cdp.mjs, tools/_t263-save-target-cdp.mjs, tools/_t264-save-target-guards-cdp.mjs, tools/_t293-endpoint-reach-cdp.mjs, tools/_t308-bare-catch-render-cdp.mjs, tools/_t308-export-byte-identity-cdp.mjs, tools/_t310-lane-position-conflict-cdp.mjs, tools/_t311-doc-comment-roundtrip-cdp.mjs, tools/_t315-lane-grow-on-import-cdp.mjs, tools/_t338-input-fidelity-cdp.mjs, tools/_t341-orphan-lane-probe.mjs, tools/_t347-accepted-element-content-cdp.mjs, tools/_t355-foreign-tag-render-cdp.mjs, tools/_t356-third-party-fidelity-cdp.mjs, tools/_t358-byteid-thirdparty.mjs, tools/_t358-empty-lanes-blast-radius.mjs, tools/_t358-export-determinism.mjs, tools/_t358-lane-provenance-cdp.mjs, tools/_t358-laneless-render-cdp.mjs, tools/_t358-repair-options-cdp.mjs, tools/_t364-aef-ext-roundtrip.mjs, tools/_t364-tie-permutes-ids.mjs, tools/_t366-uid-shape-agnostic.mjs, tools/_t367-aef-injection-footprint.mjs, tools/_t406-doc-comment-provenance-cdp.mjs, tools/_t407-exporter-passthrough-cdp.mjs, tools/_t423-additive-export-cdp.mjs, tools/_t423-carrier-agreement-cdp.mjs, tools/_t423-di-roundtrip-idempotence-cdp.mjs, tools/_t451-unwired-guard-census.py, tools/_t479-endpoint-roundtrip-cdp.mjs, tools/_t482-scalar-projection-falsify.mjs, tools/_t483-structured-projection-falsify.mjs, tools/_t485-unknown-extension-survival.mjs, tools/_t511-unwired-node-roundtrip.mjs, tools/_t513-thirdparty-identity-roundtrip.mjs, tools/_t515-external-uid-conformance.mjs, tools/_t518-uid-collision.mjs, tools/_t520-uid-xml-safety.mjs, tools/_t523-subprocess-nesting.mjs, tools/_t562-workflow-id-helpers-cdp.mjs, tools/_t563-fallback-id-derivation-cdp.mjs, tools/_t565-workflowmeta-emission-census.mjs, tools/_t566-note-field-cdp.mjs, tools/_t570-meta-carriage-cdp.mjs, tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs, tools/_t573-emits-panel-shape-cdp.mjs, tools/_t589-panel-links-cdp.mjs, tools/_t600-label-wrap.mjs, tools/_t601-lane-boundary.mjs, tools/_t602-documentation-roundtrip.mjs, tools/_t603-multiprocess-import.mjs, tools/_t618-determinism-roundtrip-cdp.mjs, tools/_t821-fault-surface-cdp.mjs, tools/_t884-instance-overlay-cdp.mjs, tools/_t884-live-proof-cdp.mjs, tools/_t889-authority-first-class-cdp.mjs, tools/_t892-lane-default-cdp.mjs, tools/_t893-authority-marker-shots.mjs, tools/_typed-events-cdp.mjs, tools/_undo-verify-cdp.mjs, tools/_versions-verify-cdp.mjs, tools/gen-rendered-thumbs.mjs]
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
#                                 # `fw work-on T-1395` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-11-11T22:30:55Z
last_update: 2026-11-12T11:29:17Z
date_finished: 2026-11-12T11:29:17Z
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
  - ts: '2026-11-11T22:46:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 0
      F1: 0
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=0 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1395: CDP harness waits forever when Chrome dies mid-command (_t358-laneless hung 2 h in T-358's close)

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** T-358's close, 2026-11-11 19:55–22:47 UTC, host load 30–47. Its browser tier ran 8791 s
instead of ~1000. `node tools/_t358-laneless-render-cdp.mjs --self-test` (pid 1334204) sat in `ep_poll` for 2 h 6 min
with no Chrome child and the gallery server still up, until the agent killed it by pid. The same verification line
passed minutes later on its own in the same close, so the product was not at fault. Result: browser 137/2. The other
red was `_t396`'s transient "clone failed"; git's stderr is discarded there, so its cause is unknown (a separate item).

**Problem / hypothesis:** each harness's hand-copied `cdp()` settles a command's promise only when Chrome answers.
When Chrome dies first, the socket closes, nothing rejects the waiting promise, and the process waits for ever. Measured:
133 tools/*.mjs carry the byte-identical one-line client; 9 more carry variants (event lists, `errs`, multi-line).
None listens for `close`.

**Goal:** no CDP wait in tools/ can outlive Chrome or run unbounded.

**Expected outcome:** a Chrome death mid-run turns into a named red leg (`CDP CLOSED: ...`) within seconds, and a
silent hang into `CDP TIMEOUT` after 120 s, instead of a suite stuck for hours.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_cdp-client.mjs` exports `cdp(ws, {cmdMs, onEvent})` with the old `{ready, cmd, close}` interface; a
      waiting command is rejected with `CDP CLOSED` when the socket closes, a later command at once, and a command with
      no answer after `cmdMs` with `CDP TIMEOUT`.
- [x] A self-test (`tools/_t1395-cdp-client-selftest.mjs`) proves all three against a real Chrome: kill Chrome while
      an evaluate waits → rejected within 5 s; a command after that → rejected at once; a never-resolving
      `awaitPromise` evaluate with `cmdMs` 1500 → `CDP TIMEOUT`. A control arm runs the OLD inline client against the
      same kill and shows it still waiting after 5 s (the defect, reproduced).
- [x] Every byte-identical copy of the old client in tools/*.mjs is replaced by the import; the remaining variants
      either import it too or are listed in this task with the reason. `node --check` passes on every changed file.
      Result: all of them import it — 133 identical copies, 10 `function cdp` variants (event lists via `onEvent`), 16
      inline or `cdpClient` clients. The only `new WebSocket` left in tools/ is the self-test's deliberate old copy.
- [x] Both suite tiers green on the change (core and browser), run when load allows. Browser 139/0 (2026-11-12 10:40,
      be.47 tree); core 221/0 (11:05). Two reds the sweep caused were fixed on the way (ba16db4d8: the census's
      missing ES-import edge, and _t1158's copy rewriting imports by name).

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
         1. Run `bin/fw reviewer T-1395`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1395 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

<!-- T-4906: guidance is an HTML comment so GitHub does not render its `#` lines as
     headings; the completion gate strips HTML comments before running anything.
     Write your commands BELOW this comment, one per line.
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
# THE EXCEPTION — capture first, grep the capture with a HERE-STRING:
#     out=$(cmd 2>&1); grep -q "PATTERN" <<<"$out"
# No pipe, so no SIGPIPE at any size. Do NOT write `echo "$out" | grep -q PAT`:
# it is not safe "below 64 KB" as this file used to say (T-4921, 832 T-1340). The
# builtin writes a multi-line value line by line, so grep -q can exit before the
# last write at ANY size (measured 4 in 3,000 for a 40-line value), and above the
# pipe buffer it fails every time (T-2743: 146,366-byte page, 3/3). In a gate that
# allows on "no match" that is a fail-OPEN (T-4920: the Tier 0 pre-filter).
# The capture still discards cmd's exit code, so a 404 yields an empty capture that
# grep merely fails to match rather than a failed line — prefer THE DEFAULT above.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); grep -q passed <<<"$out" && ! grep -q failed <<<"$out"
#     out=$(bats <file> 2>&1); grep -q '^ok 1 ' <<<"$out" && ! grep -q '^not ok' <<<"$out"
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
#     bin/fw vendor self --check --task T-1395X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
-->
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" node tools/_t1395-cdp-client-selftest.mjs > /tmp/.t1395.out 2>&1 && grep -q "^PASS" /tmp/.t1395.out && grep -q "control: the old client still waiting" /tmp/.t1395.out
git show 8da98622b~1:tools/_t358-laneless-render-cdp.mjs | grep -qE "^function cdp\(ws\) \{ const s = new WebSocket\(ws\); let id = 0; const p = new Map\(\); s.addEventListener\('message'"
! grep -qlE "^function cdp\(ws\) \{ const s = new WebSocket\(ws\); let id = 0; const p = new Map\(\); s.addEventListener\('message'" tools/*.mjs
test "$(grep -l "from './_cdp-client.mjs'" tools/*.mjs | wc -l)" -ge 130
for f in $(grep -l "from './_cdp-client.mjs'" tools/*.mjs); do node --check "$f" || exit 1; done
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" bash tools/_t1288-prepush-gate.sh
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" bash tests/run-bridge-tests.sh --tier browser > /tmp/.t1395-browser.out 2>&1 || { grep -E '\[FAIL\]|^tier ' /tmp/.t1395-browser.out; false; }

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1395 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-11-11T22:30:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1395-cdp-harness-waits-forever-when-chrome-di.md
- **Context:** Initial task creation

### 2026-11-11T22:46:42Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-12T11:29:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ee6ca3b2
- **Timestamp:** 2026-11-12T11:49:44Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#1 (Agent)** — `tools/_cdp-client.mjs` exports `cdp(ws, {cmdMs, onEvent})` with the old `{ready, cmd, close}` interface; a
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_cdp-client.mjs in: `tools/_cdp-client.mjs` exports `cdp(ws, {cmdMs, onEvent})` with the old `{ready, cmd, close}` interface; a`

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 138
     - evidence: `git show 8da98622b~1:tools/_t358-laneless-render-cdp.mjs | grep -qE "^function cdp\(ws\) \{ const s = new WebSocket\(ws\); let id = 0; const p = new Map\(\); s.addEventListener\('message'"`
