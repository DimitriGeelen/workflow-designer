---
id: T-654
name: "CTL-030: two completed tasks kept horizon:now and got no episodic — find the finalization path that skipped both"
description: >
  CTL-030: two completed tasks kept horizon:now and got no episodic — find the finalization path that skipped both

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
created: 2026-08-31T14:53:51Z
last_update: 2026-08-31T14:53:51Z
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

# T-654: CTL-030: two completed tasks kept horizon:now and got no episodic — find the finalization path that skipped both

## Context

Two audit FAILs (CTL-030) on T-542 and T-574: both in `.tasks/completed/` while storing
`horizon: now`. The same two tasks also carried the only two `no episodic summary` WARNs.
Two anomalies landing on the same two records out of ~250 is a shared cause, not a
coincidence — that is what made this worth investigating rather than editing two fields.

**Two mechanisms, not one.**

1. **The horizon (live defect, fixed).** `update-task.sh` has two branches that move a
   file into `completed/`. Only one nulled the stored horizon. Their entry conditions are
   exact complements — `OLD_STATUS != work-completed` (Trigger 2, ~2064, nulls) versus
   `OLD_STATUS == work-completed` (the partial-complete recheck, ~1541, did not) — so no
   widening of the first site could ever reach the second. T-2300 had already widened that
   site once, after **eight** CTL-030 instances, aiming at the site where the symptom
   showed rather than at the invariant. `fw task archive-eligible` re-invokes
   `--status work-completed` and therefore drives **exclusively** through the unfixed
   branch: the sweep `fw audit` recommends for stuck partial-complete tasks was the thing
   that manufactured the CTL-030 FAILs the same audit then reported.

2. **The episodic (detected 9 days ago, recovered).** Not the same mechanism. The T-522
   completion watchdog caught both aborts *as they happened* on 2026-08-22, wrote the
   correct diagnosis and the exact recovery command to
   `.context/working/episodic-gen/T-542.log` and `T-574.log`, and printed to stderr.
   It has fired exactly twice in this project's history and **both detections were still
   unactioned nine days and twelve audits later** — a 100% loss rate for a detector that
   was working perfectly. The gap was never detection. It was delivery.

**Falsification en route, kept because it is the transferable part.** The first prober
went green on the claim and the claim was still wrong: a partial-complete run leaves
`status: started-work`, so ticking the human box and re-running is an *ordinary*
transition and never enters the recheck branch at all. The green was real and about the
wrong branch. Leg 3 exists because the rig was made to assert **which** branch archived
the file, not merely that the field came out right.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Root cause identified: an explanation of why exactly T-542 and T-574 kept `horizon: now`
      through completion when the other completed tasks did not, stated as a mechanism in the
      code (file:line), not as a guess. If the mechanism turns out to be "the finalizer never
      clears horizon and these two are simply the only ones that ever HAD it set", say that —
      it is a different defect from "the finalizer was skipped" and picks a different fix.
- [x] The correlated `no episodic summary` WARN on the SAME two tasks is either shown to
      share the root cause or shown to be independent. Two anomalies on the same two records
      out of ~250 is not a coincidence to be waved past.
- [x] `fw audit` reports 0 CTL-030 FAILs (both records corrected, by whatever the root cause
      indicates is the correct correction).
- [x] Prevention, or an honest statement that prevention is out of scope with the gap
      registered. Correcting two frontmatter fields is mitigation; it is not prevention.

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

# The two probers. Each drives the REAL subject (update-task.sh / audit.sh), not a copy,
# and each carries a teeth leg that must go red when the fix is reverted.
bash tools/_t654-archiving-a-partial-complete-task-must-null-its-horizon.sh
bash tools/_t654-watchdog-detections-must-be-surfaced.sh

# The records themselves: no task in completed/ may still store a live horizon.
# This is CTL-030's own predicate, checked directly rather than through `fw audit` —
# calling the audit from inside a P-011 block hangs on the transition's lock FDs (OBS-332).
test "$(grep -l '^horizon: \(now\|next\|later\)$' .tasks/completed/*.md 2>/dev/null | wc -l)" -eq 0

# Both watchdog detections are recovered — the episodics exist.
test -f .context/episodic/T-542.yaml && test -f .context/episodic/T-574.yaml

# The fix is declared as vendored divergence (G-008): two T-654 entries, both upstream: fix.
test "$(grep -c 'task: T-654' .agentic-framework/.vendor-divergence.yaml)" -eq 2

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

### 2026-08-31T14:53:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-654-ctl-030-two-completed-tasks-kept-horizon.md
- **Context:** Initial task creation
