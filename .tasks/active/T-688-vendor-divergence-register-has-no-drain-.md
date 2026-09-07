---
id: T-688
name: "Vendor-divergence register has no drain metric: 46 fixes queued for upstream, delivery unmeasurable"
description: >
  Vendor-divergence register has no drain metric: 46 fixes queued for upstream, delivery unmeasurable

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
created: 2026-09-07T20:26:45Z
last_update: 2026-09-07T20:26:45Z
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

# T-688: Vendor-divergence register has no drain metric: 46 fixes queued for upstream, delivery unmeasurable

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_t688-divergence-drain-ratchet.py` exists and counts entries with `upstream: fix`
      that carry no terminal state, against a bare-number baseline in
      `tools/_t688-divergence-drain-baseline.txt` (T-560 idiom). RED when the count RISES above
      baseline: divergences may not be added faster than they are delivered.
- [x] The terminal-state vocabulary is defined and the tool honours it: an entry counts as drained
      when it carries `delivered:` with one of `reported` / `accepted` / `rejected` / `superseded`.
      `reported` is NOT `accepted` — sending a patch upstream is transport, not acceptance
      (§2.3: "TermLink post or file transfer alone is transport evidence, not collaboration
      completion").
- [x] Both verdicts reachable, proven by `--self-test`: RED when the undrained count exceeds
      baseline, GREEN when it equals or falls below, and a `delivered:` entry is excluded from the
      count. A ratchet with one reachable outcome is not a ratchet (PL-317).
- [x] Baseline is seeded at the MEASURED current value (46) and never hand-raised — the tool
      refuses `--seed` when a baseline already exists, so the ratchet cannot be loosened silently
      the way `_t560-absence-baseline.txt` must not be raised.
- [x] The register itself is NOT edited in this task. Adding `delivered:` to 46 entries is a claim
      about upstream state we have not verified; the schema is defined and honoured, and the data
      is filled in when a delivery actually happens. Recorded in `## Decisions`.

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
         1. Run `bin/fw reviewer T-688`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-688 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 -m py_compile tools/_t688-divergence-drain-ratchet.py
# Both verdicts reachable, and a delivered entry drops out of the count.
python3 tools/_t688-divergence-drain-ratchet.py --self-test
# The live ratchet holds at the measured baseline.
python3 tools/_t688-divergence-drain-ratchet.py
# Baseline is the measured value, not a guess.
test "$(cat tools/_t688-divergence-drain-baseline.txt)" -eq 46
# NEGATIVE LEG: the vendored register must be untouched by this task.
test -z "$(git diff --name-only HEAD -- .agentic-framework/.vendor-divergence.yaml)"
# The register still parses.
python3 -c "import yaml; yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml'))"

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

### 2026-09-07 — Ratchet the queue's growth; do not backfill 46 delivery states we cannot verify

**Alternatives considered:**

1. **Backfill `delivered:` across the 46 existing entries.** REJECTED. We do not know which ever
   reached upstream — that is the entire defect. Writing a state we have not verified would
   convert an honestly-unmeasurable register into a confidently-wrong one, which is worse: the
   first can be fixed by looking, the second looks fixed. Same failure as reading a stale record
   for a live one (T-680 / PL-316).
2. **Age-based check** (red when an undelivered fix passes N days). REJECTED FOR NOW: entries carry
   `task:` but no date, so age must be derived from task files or git — real work, and it would
   have made this task unbounded at a warn-level context budget. The ratchet is the weaker claim
   that is still a claim, and it does not preclude adding age later.
3. **Require the queue to empty.** REJECTED as unachievable and therefore inert — a bar nobody can
   clear gets bypassed, and a bypassed control is PL-317 again.
4. **Bare-number ratchet on undrained count.** CHOSEN. Divergences may not be added faster than
   they are delivered. It cannot be silently loosened (`--seed` refuses when a baseline exists,
   matching the `_t560-absence-baseline.txt` rule that a baseline must never be hand-raised).

**Terminal-state vocabulary:** `reported` / `accepted` / `rejected` / `superseded`. `reported` is
deliberately NOT `accepted` — a TermLink post or file transfer alone is transport evidence, not
collaboration completion. Treating "I sent it" as "it landed" would build a second landfill inside
the first.

**Not closed by this task:** the register still has 46 undrained fixes. This makes the queue
measurable and non-worsening; it does not drain it. Mitigation is not prevention (G-019).

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
     fw inception decide T-688 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-07T20:26:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-688-vendor-divergence-register-has-no-drain-.md
- **Context:** Initial task creation
