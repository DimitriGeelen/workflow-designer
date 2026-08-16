---
id: T-273
name: "Rail drain: AEF T-270 triage receipt, IW-marker grammar sweep, concern evidence"
description: >
  Rail drain: AEF T-270 triage receipt, IW-marker grammar sweep, concern evidence

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
created: 2026-07-28T08:06:50Z
last_update: '2026-08-16T12:33:47Z'
date_finished: 2026-07-28T08:11:24Z
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
  - ts: '2026-08-16T12:33:47Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-273: Rail drain: AEF T-270 triage receipt, IW-marker grammar sweep, concern evidence

## Context

AEF answered all three T-270 upstream reports on the rail (offsets 258, 259, their T-2645/T-2646/T-2647):
G-004 fix shipped (plus two sibling sites we missed: approvals.py:23, orchestrator.py:434), G-008 fix
already canonical their side (T-2218 RC5, vintage snapshot), G-001 secret-scan half vintage + silent-no-op
fixed loud, mcp-baseline half confirmed real and fixed (exit 3 / audit INFO), sim teeth landed 7/7.
All three concerns close on our next re-vendor; zero items owed either direction.

One migration caveat needs local action BEFORE re-vendor: AEF's canonical disposition-gate grammar does
NOT accept `* IW-N` / `# IW-N` marker forms (our local regex did). Any task body using asterisk-list
question markers would fail OPEN under the canonical gate (question unseen, no block). This task sweeps
the tree and reformats any such markers to `- IW-N` / `### IW-N`.

## Acceptance Criteria

### Agent
- [x] IW-marker grammar sweep: whole-tree grep over .tasks/ (active + completed) for `* IW-N` / `# IW-N`
      (asterisk-list or single-hash question markers) — every hit reformatted to `- IW-N` or `### IW-N`,
      or documented as a non-marker false positive. Sweep result recorded in ## Updates. (G-009: whole-tree
      sweep, not single-site.)
- [x] concerns.yaml G-004, G-008, G-001 updated with AEF triage evidence (rail 258/259, their
      T-2645/T-2646/T-2647) — each now states "closes on re-vendor, confirmed by AEF"; status fields
      untouched (operator flips).
- [x] Rail hygiene: receipt reply posted in thread T-270 (incl. IW-sweep result), acked through 259;
      rail memory updated to new frontier.

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

# No asterisk-list or single-hash IW/Q markers remain anywhere in .tasks/ (canonical grammar caveat, rail 258)
out=$(grep -rEn '^[[:space:]]*(\*|#)[[:space:]]+\*{0,2}(IW-[0-9]+|Q-?[0-9]+)' .tasks/ 2>/dev/null; true); test -z "$out"
# concerns.yaml still parses and carries the AEF triage evidence
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
grep -q "T-2645" .context/project/concerns.yaml

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

### 2026-07-28 — dash+bold IW markers: ask, don't mass-edit
- **Chose:** Leave the pervasive `- **IW-N: …**` dash+bold markers untouched (17 tasks, ~60 questions;
  incl. 3 live in active T-155) and pose a precision question to AEF (rail 260) on whether canonical
  update-task.sh:792 tolerates the bold `**` between `- ` and `IW-N`.
- **Why:** The dash+bold shape is prescribed by AEF's OWN vendored inception-template comment (T-2190
  block) — if canonical rejected it, every inception both sides would fail open and they'd have noticed.
  Their caveat named only genuinely different list styles (`* IW-N` / `# IW-N`), of which we have zero.
  Completed-task markers are inert anyway (gate runs only at completion).
- **Rejected:** Preemptive mass-reformat to plain `- IW-N` — edits archived history on a speculative
  grammar reading, and would desync our tasks from the template AEF itself ships. If AEF answers
  "not tolerated", the actual fix is 3 markers in T-155 + the template shape, one small task.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-28T08:06:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-273-rail-drain-aef-t-270-triage-receipt-iw-m.md
- **Context:** Initial task creation

### 2026-07-28 — rail drain executed
- **Inbound processed:** AEF 258 (reports 1/3+2/3: T-2645 shipped w/ 2 sibling sites approvals.py:23 +
  orchestrator.py:434; T-2646 already-canonical/vintage + grammar caveat) and 259 (report 3/3: T-2647 —
  F4 vintage + loud-fail shipped, F2 real gap fixed exit-3/INFO, sim tests 6+7 landed 7/7).
- **IW-marker sweep result:** ZERO `* IW-N` / `# IW-N` hits across .tasks/ (active+completed+templates).
  Broad non-canonical filter also clean. Live population = dash+bold `- **IW-N:` template shape
  (17 tasks; only T-155's 3 markers sit on an active gate path). Precision question posed at rail 260.
- **Outbound:** receipt reply offset 260 (thread T-270, incl. sweep result + bold-tolerance question +
  re-vendor-is-operator-gated note); ack through 259 at offset 261. Rail memory frontier → read from 262.
- **Standing:** G-001/G-004/G-008 now single-action concerns (re-vendor, operator-gated); zero owed either side.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e16eae39
- **Timestamp:** 2026-07-28T08:11:25Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-28T08:11:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
