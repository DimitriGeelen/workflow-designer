---
id: T-535
name: "Audit trend detector counts verbatim check strings, so an issue is only 'recurring' while its numbers stop moving"
description: >
  audit.sh:5520-5535 extracts each WARN/FAIL 'check:' string verbatim and aggregates with sort|uniq -c, firing at count>=3. Any check that embeds its measurement therefore produces a fresh string per run and can never aggregate. Measured over this project's 41 daily audits: the fabric COVERAGE warn appears in 37 audits and its largest identical-string group is 1 - never once reported as recurring. The fabric EDGES warn appears in 10 and is reported as 3, and only because the counts held still for three consecutive days. So the detector fires on STASIS while labelled recurrence, and is least sensitive exactly when a problem is progressing. Vendored .agentic-framework/agents/audit/audit.sh - fix in-tree per G-008 and report upstream. Found while acting on the audit's own 'candidates for practice' trend line under T-432.

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
created: 2026-08-16T06:49:21Z
last_update: 2026-08-16T06:50:24Z
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

# T-535: Audit trend detector counts verbatim check strings, so an issue is only 'recurring' while its numbers stop moving

## Context

Found by taking the audit's own advice. Every run prints:

    === TREND ANALYSIS ===
    Repeated issues detected in last 14 days (candidates for practice):
      -      3 Fabric: 36/40 cards have no edges (3 times)

…while the *same* audit's body reports `Fabric: 37/56 cards have no edges`. The trend line
is quoting a count that no longer exists.

## Findings (measurement complete; fix deliberately NOT attempted in the filing window)

### Mechanism

`audit.sh:5519-5535` reads each WARN/FAIL `check:` string **verbatim** and aggregates with
`sort | uniq -c`, promoting anything at `count -ge 3` (`audit.sh:5532`). So the aggregation
key is the *rendered sentence*, and any check that embeds its own measurement mints a new
key on every run.

### Measured over this project's 41 daily audit records

| check | audits containing it | largest identical-string group | reported as recurring |
|---|---|---|---|
| fabric **coverage** warn | **37** | **1** | **never** |
| fabric **edges** warn | **10** | 3 | 3 |

Seven distinct strings for the edges issue (`36/40`, `37/56`, `33/37`, `31/35`, `26/30`,
`13/17`, `12/16`), and **37 distinct strings for the coverage issue** — one per run.

### The inversion, which is the finding

**The detector fires on STASIS while labelled recurrence.** The single issue it has ever
promoted in this project crossed the threshold *only because its numbers stopped moving for
three consecutive days*. An issue recurring daily while steadily worsening mints a fresh key
every run and scores **1, forever** — so the detector is least sensitive exactly when a
problem is progressing, which is the opposite of what a recurrence detector is for.

Downstream consequence: the framework's remediation prompt ("Consider creating a practice")
is routed by **string stability**, not by persistence. A stable-but-trivial WARN gets
promoted to a practice candidate; a worsening one never does.

### What this is NOT — stated because the tempting claim is wrong

**T-525 did not cause this.** T-525 improved the coverage line by adding a ratio and a
direction note, which makes the string vary *more* — but the pre-T-525 strings
(`Fabric: 40 registered, 185 unregistered (of 222 watched)`) are *also* one-per-run. The
line has never aggregated, before or after. T-525 could not have helped; it is not to blame,
and saying so would be the flattering version of this finding rather than the true one.

### Family

Same class as PL-222 (a metric that is a difference between two independently moving
quantities cannot report direction) and G-015, one level up: here a moving quantity is baked
into an **identity key** rather than into a metric.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] **The aggregation key is separated from the rendered message.** An issue recurring with
      changing numbers aggregates; the printed line still shows a concrete instance, because a
      normalised key like `Fabric: N/M cards have no edges` is a worse thing to show an
      operator than a real reading.
- [ ] **Measured before/after on this project's real audit corpus**, not on a fixture: the
      fabric coverage issue must move from *never reported* to reported with a count near 37,
      and the edges issue from 3 to near 10. Stated as a range, not an exact number, because
      the corpus grows daily and pinning an exact count is the G-015 defect this tree keeps
      finding.
- [ ] **Normalisation does not over-merge.** Two genuinely different checks whose text differs
      only in digits must not collapse into one. Demonstrated with a concrete pair from the
      real corpus, or the absence of such a pair reported as a measurement.
- [ ] **Teeth drive the real trend analysis** against a controlled corpus of audit records
      (seam: the `past_audits` source directory), with a red arm proving the pre-fix code
      scores a numbered recurring issue at 1.
- [ ] **The teeth REFUSE (rc 2) if the corpus yields no trend section at all** — otherwise a
      broken reader renders as "no repeated issues", which is indistinguishable from health.
- [ ] **Reported upstream to AEF** — vendored `.agentic-framework/agents/audit/audit.sh`,
      fixed in-tree per G-008.

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

### 2026-08-16T06:49:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-535-audit-trend-detector-counts-verbatim-che.md
- **Context:** Initial task creation

### 2026-08-16T06:50:24Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
