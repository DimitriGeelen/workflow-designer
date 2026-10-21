---
id: T-1249
name: "Designer slice 1 (T-1242 GO): read, show and keep every mapping v1.1 io construct,
  read-only"
description: >
  AEF T-4415 GO, ruled DRAFT 2 at AEF f1f7c30dd. The designer reads fieldRef/typeRef/schemaRef/conceptRef,
  role, operation, cardinality, sourceSystem/targetSystem, aef:field, aef:expect,
  aef:example, aef:prefixes and mappingVersion, shows each in the io panel read-only,
  and saves byte-exactly. Success: greenfield VZN-T1 v29 (43 io) and the 54 tracked
  v1 maps save with 0 bytes changed; a v1.1 example map with every construct round-trips
  with 0 bytes changed. Screenshots at 1024/1440/1920 plus an independent reviewer;
  release to AEF.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-1242]
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
#                                 # `fw work-on T-1249` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-21T17:12:23Z
last_update: 2026-10-21T18:37:37Z
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
  - ts: '2026-10-21T18:17:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 0
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1249: Designer slice 1 (T-1242 GO): read, show and keep every mapping v1.1 io construct, read-only

## Context

Slice 1 of T-1242 (GO 2026-10-21). The standard is AEF's mapping v1.1 io text (AEF T-4548,
`policy/standards/aef-bpmn-mapping-v1.1-io.md` at AEF 29adf17f4, sha256 691fd2ed…, received verified, kept outside git
in `.context/working/intake-t4415/v11/`); its section-11 worked examples are the cases AEF's corpus_spec round-trips
(`test_t4549_aef_io_v11_roundtrip.py`, sha256 81d95937…). Preservation already exists (T-1220 attributes, T-1243
children); this slice makes the designer SHOW them, read-only. Editing is slices 2-3.

## Acceptance Criteria

### Agent
- [x] The io panel shows, read-only, every v1.1 construct on an `aef:input`/`aef:output`: fieldRef, typeRef or
  schemaRef, conceptRef, role, operation, cardinality, sourceSystem/targetSystem (with the step default and a
  prefix-derived system marked as derived), and the `aef:field` / `aef:expect` / `aef:example` children; the process
  `aef:prefixes` and `mappingVersion` are shown in the workflow panel. Unknown attributes and children still appear
  as they do today (T-1220/T-1243). No io field becomes editable in this slice.
  **Evidence (2026-10-21):** `ioV11Block` / `wfV11Section` in the designer; `_t1249` leg d asserts 40 DOM strings
  (every attribute, `derived · step default`, `derived · prefix sfdc`, field/when/expect keywords incl. enum and
  ruleRef, example) on 7 v1.1 io and the workflow Mapping section, with 0 input/select inside the v1.1 display; leg e: a
  v1 io has no v1.1 block and its row keeps [3, 2] controls. Also shown: 2.3 `ref` read as fieldRef (`derived · from
  ref`) when a non-v1.1 map declares the prefix `kind="field"`. `ref`/`dataType`/other unknowns stay unshown, as today.
- [x] Byte-exact round trip: every section-11 worked example of the v1.1 text, wrapped in a minimal map, opens and
  saves with 0 bytes changed in its io; the 54 tracked v1 maps that carry io and greenfield's VZN-T1 v29 (43 io, kept
  outside git) save with 0 bytes changed in their io. A CDP harness (`tools/_t1249-v11-io-cdp.mjs`) asserts this and
  the display, is red against the pre-change source, and runs as a bridge leg.
  **Evidence (2026-10-21):** leg a: 5 maps (the 4 section-11 examples + AEF's FULL case, with the process `aef:meta`
  mappingVersion + prefixes): io and process meta 0 bytes changed, second save identical. Leg b: every tracked .bpmn
  with aef:input/output (84 files, 45 distinct contents, 136 io blocks; the "54" was the T-1242 type census): 0 changed,
  none needs the new state. Leg c: VZN-T1 17 io blocks / 43 io: 0 changed (counts only, nothing printed). Red on the
  pre-change source (legs a, c, d: nameless io dropped, process meta dropped, VZN's one-line io re-laid out) and with
  `T1249_BITE=display` (leg d). Bridge leg added after T-1243 in `tests/run-bridge-tests.sh` (suite run by the orchestrator).
- [ ] Screenshots of the io panel (a v1.1 step with fields and expectations; a v1 step; an empty step) at 1024, 1440
  and 1920, read control by control in `## Visual Verification`, and an independent reviewer judges them (`[REVIEW]`
  below) before close.
- [ ] Full bridge suite green; the release that carries it goes to AEF the day it is tagged.

### Human
- [x] [REVIEW] The read-only v1.1 io display is legible, compact and consistent with the panel at every width
  **Why you:** render-surface judgement on new UI; reviewer-judged per AEF routing (PD-357), may escalate.
  **Steps:**
  1. Open the screenshots in `docs/reports/T-1249-evidence/`: `v11-step-{1024,1440,1920}-panel.png` (and
     `v11-step-1024-panel-end.png`), `v1-step-*-panel.png`, `empty-step-*-panel.png`, `workflow-*-panel.png`, and the
     full views without `-panel`.
  2. Read the `## Visual Verification` table in this task.
  3. Check per shot: every v1.1 attribute and child is visible and unclipped; derived systems are labelled as derived;
     a v1 io and an empty step look as before (no v1.1 block); the workflow panel's Mapping section shows
     mappingVersion and the prefixes; nothing overlaps; the toolbar is unchanged. Note one known slice-1 limit: a
     nameless v1.1 io still shows an empty name field and a `string` type select (editing is slice 2); judge whether
     that misleads enough to fix now.
  **Expected:** green, or amber naming the control and width that needs work.
  **If not:** list each problem with the screenshot name; the agent fixes and re-shoots.
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
         1. Run `bin/fw reviewer T-1249`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1249 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
  **Reviewer verdict:** green V-20261021-e7c2ac2c — reviewer-judge-t-1249-r3-e9a86f1be12a:reviewer (rung rung-3-termlink-single-reviewer), digest e8d5cc334aeb; dispatch judge-t-1249-r3-e9a86f1be12a; evidence: .context/reviews/evidence/T-1249/AC1-judge-t-1249-r3-e9a86f1be12a.md, .context/reviews/evidence/T-1249/v11-step-1024-panel-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/v11-step-1024-panel-end-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/v11-step-1440-panel-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/v11-step-1920-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/workflow-1920-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/v1-step-1440-judge-t-1249-r3-e9a86f1be12a.png, .context/reviews/evidence/T-1249/empty-step-1024-panel-judge-t-1249-r3-e9a86f1be12a.png; ledger .context/reviews/verdicts.jsonl

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
#     bin/fw vendor self --check --task T-1249X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
node tools/_t1249-v11-io-cdp.mjs > /tmp/.t1249-verify 2>&1 && head -2 /tmp/.t1249-verify | grep -q '"ok": true'
node tools/_t1176-toolbar-reach-cdp.mjs > /tmp/.t1249-t1176 2>&1 && tail -2 /tmp/.t1249-t1176 | grep -q '"pass": true'

## Visual Verification

Screenshots: `docs/reports/T-1249-evidence/<state>-<width>.png` (full viewport) and `<state>-<width>-panel.png` (the
properties panel scrolled to the section; `v11-step-1024-panel-end.png` is the rest at 1024x768), made by
`node tools/_t1249-v11-io-shots.mjs` from AEF's section-11 examples + its FULL case only (no client material).
States: **v11-step** (a step with 2 inputs + 3 outputs carrying fields, when, expect, example, explicit/derived systems),
**v1-step** (plain v1 io), **empty-step** (no io), **workflow** (no selection: the new Mapping section). Widths
1024x768, 1440x900, 1920x1080; the properties panel is 320 px wide at all three, so its content is laid out identically.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| toolbar | Open project / Pending refs / instances / zoom / fit / view toggles | ok | ok | ok | two rows at 1024, one at 1440/1920 |
| toolbar | Add Lane, Reset, Clean layout, View XML, Settings, Load | ok | ok | ok | |
| toolbar | Check, Versions, Save to project, Save | ok | ok | ok | all visible and unclipped; _t1176 toolbar guard 22/22 pass |
| v11-step | input row `opp` (name, type select, req, ×) | ok | ok | ok | unchanged editable row |
| v11-step | v1.1 block under `opp`: typeRef, conceptRef, cardinality, sourceSystem (explicit) | ok | ok | ok | key faint, value bright, pairs never split |
| v11-step | `field LineItems[] cardinality many` + indented `when Kind const TradeIn` | ok | ok | ok | |
| v11-step | `expect Status enum Won, Closed Won`; `expect Amount minimum … exclusiveMaximum … pattern …` | ok | ok | ok | second expect wraps to 2 lines at a pair boundary |
| v11-step | `example Amount = 12500` | ok | ok | ok | |
| v11-step | nameless input: `fieldRef sfdc:Opportunity.Id role read`, `sourceSystem sys:crm-default derived · step default` | ok | ok | ok | "derived · step default" italic, wraps under |
| v11-step | outputs ×3: typeRef/operation, fields with role, `targetSystem sys:salesforce derived · prefix sfdc`, explicit targetSystem, `expect StageName const Closed Won` | ok | ok | ok | long fieldRefs push `role match` to the next line (whole pair) |
| v11-step | + add input / + add output | ok | ok | ok | reachable; at 1024 + add output is in the -panel-end shot |
| v11-step | no input/select inside any v1.1 block | ok | ok | ok | harness leg d: 0 editable controls |
| v1-step | inputs owner/team, output assignment: name, type, req, × | ok | ok | ok | identical to before: no v1.1 block (leg e) |
| empty-step | (no inputs) / (no outputs), + add input / + add output | ok | ok | ok | unchanged |
| workflow | Workflow fields (ID … Kind) | ok | ok | ok | unchanged |
| workflow | Mapping section: `mappingVersion 1.1`; `sfdc https://example.org/sfdc# · system sys:salesforce · kind field`; `tacton … · kind type` | ok | ok | ok | name column aligned, IRI wraps within its column |
| workflow | Recently opened, Tips | ok | ok | ok | unchanged, below Mapping |

Noted, not changed (existing behaviour, editing is slices 2-3): a v1.1 io with no `name`/`type` shows an empty name
field and the type select at `string`; the step-level `aef:meta sourceSystem` also appears under Other extensions (T-1126).

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
     fw inception decide T-1249 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-21T17:12:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1249-designer-slice-1-t-1242-go-read-show-and.md
- **Context:** Initial task creation

### 2026-10-21T18:17:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
