---
id: T-382
name: "G-024 prevention: instrument reporting consumer-visible fixes sitting in src
  but not in the artifact AEF has pinned"
description: >
  G-024 prevention: instrument reporting consumer-visible fixes sitting in src but
  not in the artifact AEF has pinned

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T16:05:42Z
last_update: '2026-08-16T14:33:32Z'
date_finished: 2026-08-08T16:13:33Z
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
  - ts: '2026-08-16T12:33:54Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:dist/MANIFEST.yaml,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:dist/MANIFEST.yaml); tier=2 (no-signal); 
      effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-382: G-024 prevention: instrument reporting consumer-visible fixes sitting in src but not in the artifact AEF has pinned

## Context

G-024 is registered `high`. *(Filed believing its trigger was empty, read off `fw gaps`.
**That was wrong** — see AC-7: the trigger was written under a key the renderer ignores.
The real defect was better than the one I filed.)* The gap: *no instrument
holds the pinned artifact and src at the same time, so a consumer-visible fix can sit
unreleased indefinitely with nothing reporting it.* It has already happened — a peer
waited 9 days for a fix that was in src the whole time, because every gate we run is
scoped to src and the consumer runs the artifact.

**Why the obvious instrument is worthless.** `diff src dist` is G-015: 75 verification
blocks assert exactly that, it is a global always-moving property, it is permanently red,
and it is therefore ignored. "src differs from the release" is true five minutes after any
release. The measurable quantity is **age**, not difference.

**Three points on the seam, not two:**
`src` → (we cut a release) → `dist/MANIFEST latest` → (peer re-pins) → AEF's pin.
Build lag and adoption lag are independent, and collapsing them lets either hide the
other: from the consumer's seat, a current release they never adopted is indistinguishable
from no release at all.

## Acceptance Criteria

### Agent
- [x] **AC-1 — both lags measured separately.** The instrument reports (a) build lag:
      commits touching the product source since the tag named by `dist/MANIFEST.yaml`
      `latest:`, with the age of the OLDEST; and (b) adoption lag: the peer's pinned
      version vs our latest. Neither is derived from the other and each has its own line
      in the output.
- [x] **AC-2 — leg 2's bound is printed, not buried.** The peer pin is read from a
      VENDORED copy, so it reports what the peer had pinned at our last re-vendor, not
      now. The output states this next to the number, states the direction of the error
      (it can only UNDER-report lag), and names what would resolve it (ask on the rail).
      A bound that lives only in a source comment is not stated.
- [x] **AC-3 — thresholds chosen from the incident, not the tree.** WARN/FAIL day counts
      are justified against the recorded 9-day harm and written down BEFORE the current
      value is read into the decision. If today's tree fails its own gate, that is the
      finding and it is reported, not tuned away.
- [x] **AC-4 — unmeasured is never reported as ok.** A missing release tag, an
      unreadable peer pin, or a MANIFEST sha that does not match the artifact on disk
      each produce a non-ok result with its own exit code / reason. A lookup miss must
      not be able to mean "clean".
- [x] **AC-5 — teeth prove the gauge moves in BOTH directions.** Legs establish that the
      clean state (lag 0) is reachable, that the dirty state is reachable, that an older
      baseline reports monotonically >= lag than a newer one, and that sha-mismatch and
      unreadable-pin each escalate on their own. A gauge that can only say "behind" would
      report lag on a freshly cut release; one that can only say "ok" IS this gap.
- [x] **AC-6 — the current reading is reported to the operator and to AEF**, including
      which unshipped commits are consumer-visible, with the bound on leg 2 stated.
- [x] **AC-7 — REWRITTEN: the premise was wrong, and the real defect is better.**
      As filed this AC said "G-024's trigger is empty, fill it in", read off `fw gaps`
      printing `Trigger: ` for it. **G-024's trigger was never empty — it is 587
      characters, written under `trigger:`, and the renderer (`bin/fw`) reads
      `decision_trigger:` and nothing else.** 18 of 21 watching gaps use the rendered
      key; G-024 alone used the other; only G-022 and G-023 are genuinely empty.
      Delivered instead: (a) G-024's key renamed, text unchanged, so the written
      condition is visible where people look; (b) its closure state updated to record
      what T-382 meets and what it does not; (c) a standing audit check separating
      "no closure condition" from "closure condition under an unread key", because a
      field that exists but never renders is indistinguishable from an absent one in
      the only place anybody reads. G-022/G-023 now surface as genuinely unclosable —
      filed as follow-up, not rushed here.

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
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.


# Instrument's own teeth: prove the gauge moves BOTH ways (clean state reachable,
# dirty state reachable, monotonic in baseline age) and that each escalation fires
# alone. Own exit code is the verdict — no capture/grep chain (T-352, L-387).
python3 /opt/832-Workflow-designer/tools/_t382-release-lag.py --teeth
# The instrument must be reachable from the standing audit, not just by hand: an
# instrument nobody runs cannot report the silence this gap is about.
grep -qF 'check_release_lag' /opt/832-Workflow-designer/.agentic-framework/agents/audit/audit.sh
grep -qF 'check_gap_triggers' /opt/832-Workflow-designer/.agentic-framework/agents/audit/audit.sh
# G-024's closure condition must render in `fw gaps`, i.e. live under the key the
# renderer actually reads. -F: the text contains backticks and regex metacharacters.
python3 -c "import yaml,sys; g=[x for x in (yaml.safe_load(open('/opt/832-Workflow-designer/.context/project/concerns.yaml')).get('concerns') or []) if x.get('id')=='G-024']; sys.exit(0 if g and (g[0].get('decision_trigger') or '').strip() else 1)"

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

### 2026-08-08T16:05:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-382-g-024-prevention-instrument-reporting-co.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9e18b861
- **Timestamp:** 2026-08-08T16:13:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T16:13:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
