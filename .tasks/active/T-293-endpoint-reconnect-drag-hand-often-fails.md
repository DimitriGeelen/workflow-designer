---
id: T-293
name: "Endpoint reconnect drag (hand) often fails after T-286, worst at frw_11_harvest"
description: >
  Endpoint reconnect drag (hand) often fails after T-286, worst at frw_11_harvest

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-28T21:00:16Z
last_update: 2026-08-29T11:13:04Z
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
  - ts: '2026-08-16T12:33:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 2
      F3: 1
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=2 (prose:routing-single-element); F3=1 
      (prose:AEF seam-incidental); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:src/aef-workflow-designer.html,tests/run-bridge-tests.sh,tests/test_t293_endpoint_reach.py,tools/_t293-endpoint-reach-cdp.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-293: Endpoint reconnect drag (hand) often fails after T-286, worst at frw_11_harvest

## Context

Operator field report (2026-07-28, right after T-286 shipped): dragging an edge
endpoint to change its connection ("the hand") often does not start/work, worst
around node `frw_11_harvest` (harvest-pipeline map on :8834). Timing implicates
the recent canvas work: T-286 badge re-layering (badges+halos moved out of
#g-nodes into pointer-events:none layers) and/or T-249/T-251 zoom+pan (pointer
coordinate transforms, capture-phase preempt). Hypothesis-driven debugging, max
3 hypotheses, then escalate.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Failure reproduced headlessly (CDP, real Input.dispatchMouseEvent) on
      harvest-pipeline at frw_11_harvest: all 4 endpoint-handle centres of
      e_16/e_22 shadowed — 3 by node-shape (mousedown started a NODE drag),
      1 by the active port-indicator dot (fully dead). edgeDrag never started
- [x] Root cause established with before/after evidence (see RCA): pre-fix
      repro fails (e2e reconnect leaves edge.target unchanged), post-fix passes
      (edge.target n_h_claude → n_join by real mouse drag)
- [x] Fix applied: new interactive #g-handles layer above #g-nodes (below
      #g-preview); selected edge's endpoint halos/dots + port indicators render
      there; port dots prepended so the active-port dot can never shadow the
      grab halo. All 4 handle centres now hit the handle; edgeDrag starts 4/4
- [x] No regression: full suite 42/42 (was 41 + new T-293 leg), geometry sweep
      24 clean, node-cut sweep 0 (baseline 0); T-286 layer order asserted incl.
      new layer, badge raise/deselect round-trip 1→0 verified
- [x] Gallery :8834 relaunched serving the fix (g-handles ref-count matches
      src); verification screenshot read (endpoint dots + port ring visibly
      above node bodies at frw_11_harvest) and published as
      t293-handles-selected.png on :8834
- [x] Prevention (G-003 class): standing suite leg added —
      tools/_t293-endpoint-reach-cdp.mjs + tests/test_t293_endpoint_reach.py,
      wired into tests/run-bridge-tests.sh; TEETH proven (fails loudly against
      the pre-fix editor). Pre-existing port-pin click defect found during
      verification filed separately as T-294 (one bug = one task)

### Human
- [x] [REVIEW] Endpoint reconnect drag feels right at frw_11_harvest
      **Steps:**
      1. Open http://192.168.10.107:3000/designer and click the **t293-retest-harvest** card
         (:3000 is ufw-allowed and now serves the 0.8.0 bundle with this fix; the old
         :8834 link is LAN-blocked — no ufw rule, T-253 class — do NOT use it)
      2. Click the edge from the "Fan out" gateway into "Harvest CLAUDE.md additions" (frw_11_harvest)
      3. Grab the green endpoint dot at the node border and drag it onto another Harvest node, then undo (Ctrl+Z)
      4. Repeat from the other side (the edge out of frw_11_harvest into the Join gateway)
      **Expected:** The grab starts a reconnect from anywhere on the dot — including the half overlapping the node body; the node itself never starts moving when you grab a dot
      **If not:** Note which edge/endpoint and whether the node moved or nothing happened; screenshot t293-handles-selected.png on :8834 shows the intended state

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
         1. Run `bin/fw reviewer T-293`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-293 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

grep -q 'id="g-handles"' src/aef-workflow-designer.html
grep -q "test_t293_endpoint_reach" tests/run-bridge-tests.sh
python3 tests/test_t293_endpoint_reach.py
# L-387 AMENDED HERE (T-293, 2026-08-29). The capture-then-grep pattern this block
# recommends above is NOT safe for large payloads, and this leg was the counterexample:
# it exited 141 (SIGPIPE) for weeks while `g-handles` was present in the served page 3x.
# The hint's stated rationale is `echo "$out"` is small and immediate — the served
# designer is 900,930 bytes, so echo is still writing when `grep -q` matches and closes
# stdin. Capturing first moves the SIGPIPE from curl to echo; it does not remove it.
# Use a pipeline-free test instead. 79 active tasks use the capture-then-grep pattern;
# 6 of those pipe a curl payload and carry this same latent false-red.
#
# MEASURED PRECISELY (720KB fixture, this session): the fault needs BOTH a large capture
# AND an EARLY match. early-match exit=141 / late-match exit=0 / absent exit=1. So the leg
# fails exactly when its evidence appears SOONEST, and a green run proves nothing about
# safety — greenness depends only on where the match happens to land. That is why the 6
# sibling tasks do not trip today: each greps a summary line at the END of its test output.
# Here the token appeared near the top of a 900,930-byte page, which is the worst case.
out=$(curl -sf "$(cat .context/working/watchtower.url)/designer/app"); case "$out" in *g-handles*) true;; *) false;; esac  # port 8834 retired (T-253 ufw RCA); triple file is source of truth, T-305
# G-015: the previous leg here was `ls build/gallery/t293-handles-selected.png` — a
# screenshot taken during the original verification session. It was NEVER COMMITTED
# (no object for it in any ref), so it could only ever pass on the machine that made it,
# and it asserted an artifact OF the verification rather than anything the task DELIVERED.
# build/gallery/ may not be rebuilt to satisfy it (tools/_t350-build-only-probe.sh).
# Replaced with the actual root-cause fix: #g-handles must paint AFTER #g-nodes, which is
# the whole content of T-293 — endpoints were unreachable because they sat below the nodes.
# Quoting form is deliberate (agent-chat-arc @750 999-AEF, @751 577-CashWeb, 2026-08-29).
# `bash -n` PASSES a python3 -c "..." whose payload contains an unescaped quote that closed
# the shell string early — the outer syntax check cannot see the inner language at all, and
# reports success either way. 577's structural answer is to pick a form where the failure
# mode is ABSENT rather than checked: a quoted heredoc (<<'PY') bash never parses inside.
# P-011 runs one line per leg, so a heredoc is unavailable here. This is its one-line cousin:
# the outer string is SINGLE-quoted and the payload contains NO single quote anywhere (the
# double quotes it needs are built with chr(34)), so nothing in it can terminate the string.
# Teeth confirmed by mutation, not by reading: exit 0 on HEAD, exit 1 on dab0b9f5~1.
python3 -c 'import io,sys; s=io.open("src/aef-workflow-designer.html",encoding="utf-8").read(); q=chr(34); sys.exit(0 if s.index("id="+q+"g-nodes"+q) < s.index("id="+q+"g-handles"+q) else 1)'

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

**Symptom:** Dragging an edge endpoint to reconnect ("the hand") often did not
start — the node moved instead, or nothing happened; worst at frw_11_harvest.

**Root cause:** The selected edge's endpoint grab halos and port-indicator dots
rendered inside #g-edges, which paints BELOW #g-nodes. T-168 anchors endpoints
ON the node border, so the node body covered the border-side half of every r11
grab halo (mousedown → node drag), and where the active-port dot coincided with
the endpoint, the dot (appended after the handles within #g-edges) covered the
halo centre entirely (mousedown → nothing). T-286 did not cause this — it
removed the badge/halo blocker that had masked it: with badges click-transparent,
users could finally aim at handles and hit the next blocker down.

**Why structurally allowed:** No trusted-input test asserted endpoint-handle
REACHABILITY — G-003's exact gap (pointer-interaction paths, zero trusted-input
coverage). T-286's own hit-test evidence recorded handles resolving to
"pre-existing node-shape" without any gate treating that as a failure:
reachability was never an asserted invariant, so paint-order shadowing was
invisible to every suite.

**Prevention:** Standing suite leg (tools/_t293-endpoint-reach-cdp.mjs via
tests/test_t293_endpoint_reach.py in run-bridge-tests.sh) drives real CDP mouse
input and asserts: layer order, handle-centre hit-tests, endpoint-drag start on
press+move, and a full reconnect rewiring state. Proven non-vacuous against the
pre-fix editor. This is the third field-found pointer bug under G-003 — the leg
pattern (real-input reachability assertions) is now reusable for the rest of
that concern's surface.

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

**[GO]** — the field symptom is mechanically eliminated (12/12 leg assertions,
e2e reconnect proven by real mouse input, before/after evidence), no suite
regression (42/42), and the fix is the same layering principle the operator
already approved in T-286, extended to the interactive chrome.

## Decisions

### 2026-07-28 — where the reconnect chrome lives
- **Chose:** New interactive #g-handles layer above #g-nodes; port dots prepended
  below the grab halos within it.
- **Why:** Handles must both PAINT and HIT-TEST above node bodies (T-168 puts
  endpoints on the border); the badge layers (pointer-events:none) cannot host
  interactive chrome. Prepending port dots keeps the active-port dot from
  shadowing the halo — the pre-existing dead-click case.
- **Rejected:** Raising the whole selected edge group above #g-nodes (would put
  the LINE over node bodies — visual regression); pointer-events tricks on
  node shapes (would break node dragging near borders).

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

### 2026-07-29 (later) — FIELD FAILURE ROOT-CAUSED: environmental, not a code defect [status → started-work]
- **Hypothesis 2 (zoom) DISPROVED:** scratchpad/t293-zoom.mjs — at zoom 1.0/1.4/0.75
  both e_16 endpoint halos win the hit-test and endpoint drag starts (6/6, real
  CDP mouse input, node never moves).
- **Hypothesis 3 (selection path) DISPROVED:** scratchpad/t293-served-click.mjs —
  the EXACT operator path (served http://127.0.0.1:8834/designer.html?load=
  rendered/harvest-pipeline.bpmn, REAL click on the edge line to select, real
  mousedown on the green dots, scrolled + unscrolled): 8/8 drag-start, e_16 + e_22.
- **ACTUAL ROOT CAUSE (T-253 class):** the operator cannot reach the fixed code
  at all. Two converging facts:
  1. `ufw status` has NO allow rule for 8834 (default-deny inbound) — the :8834
     retest link is dead from the LAN, as it has been since day one (T-253).
  2. Every designer the operator CAN reach serves the pinned **0.7.1 release**
     (our Watchtower :3000/designer → vendor/designer/aef-workflow-designer-0.7.1.html,
     0 g-handles refs; AEF's :3001/designer same pin) — 0.7.1 was cut BEFORE
     T-286 and T-293 landed. On 0.7.1 the endpoint-drag defect reproduces
     exactly as reported. The "field failure" was a faithful test of old code.
- **Remedy (two rails):**
  1. Release 0.8.0 bundling T-286 + T-293 → rail announce → AEF re-pins →
     :3000/:3001 designer serve the fix on ufw-allowed ports (follow-up task).
  2. Operator option for direct src retest: single ufw allow for 8834
     (operator-only — agent must not modify ufw).
- **G-019 note:** framework blindness = a Human-AC retest link on a NEW port has
  no reachability check from the tester's vantage; T-253 already registered this
  class (agent-side probes bypass inbound filtering).

### 2026-07-29 — FIELD FAILURE REPORT: fix does not work for the operator [status → issues]
- **Report:** Operator retested on :8834 harvest-pipeline per the Human AC steps —
  "not working". No further detail yet (unknown whether node moves, nothing
  happens, or dots are not visible).
- **Verified so far this morning:** :8834 serves the CURRENT code (3 g-handles
  refs, matches src) — not a stale-serve problem server-side.
- **Open hypotheses (in order):**
  1. STALE TAB / browser cache — a tab opened before last night's relaunch still
     runs pre-T-293 JS. Operator should hard-reload (Ctrl+Shift+R) and retry.
  2. ZOOM state — agent verification ran ONLY at 100% zoom; T-249 zoom (setZoom,
     src line ~2321) may break handle hit/drag coordinates at zoom != 1.
     READY TO RUN: scratchpad/t293-zoom.mjs (tests reach at 1.0/1.4/0.75) —
     blocked by context-budget gate at 293K; run first thing next session.
  3. Interaction-path difference — operator may fail at edge SELECTION near the
     node (edge line also below node body — pre-existing), not at handle grab;
     or uses a pointer path the CDP repro doesn't model.
- **Next session:** run t293-zoom.mjs; ask operator: does the NODE move, does
  NOTHING happen, or are the green dots absent? Hard-reload result?

### 2026-07-28T21:00:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-293-endpoint-reconnect-drag-hand-often-fails.md
- **Context:** Initial task creation

### 2026-07-28T21:17:34Z — status-update [task-update-agent]
- **Change:** owner: agent → human

### 2026-07-29T06:09:00Z — issue-resolved [healing-agent]
- **Action:** Issue resolved via healing loop
- **Output:** Pattern FP-009 recorded
- **Mitigation:** Field failure was environmental: operator-reachable designers all serve pinned 0.7.1 (predates fix) and :8834 has no ufw allow rule (T-253 class). Code fix verified 12/12 zoom legs + 8/8 served real-click legs. Remedy: cut 0.8.0 + rail announce for re-pin; ufw allow is operator-only.
- **Context:** Resolution logged for future reference

## Reviewer Verdict (v1.5)

- **Scan ID:** R-02102b4d
- **Timestamp:** 2026-07-29T13:13:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-23T10:24:10Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)

### 2026-08-29T10:26:00Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)
