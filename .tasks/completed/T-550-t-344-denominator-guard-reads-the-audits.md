---
id: T-550
name: "T-344 denominator guard reads the audit's TREND ANALYSIS echo of its own superseded message as today's coverage line and reports a disagreement that does not exist"
description: >
  T-344 denominator guard reads the audit's TREND ANALYSIS echo of its own superseded message as today's coverage line and reports a disagreement that does not exist

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T19:27:28Z
last_update: 2026-08-16T19:37:07Z
date_finished: 2026-08-16T19:37:07Z
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

# T-550: T-344 denominator guard reads the audit's TREND ANALYSIS echo of its own superseded message as today's coverage line and reports a disagreement that does not exist

## Context

`tools/_t344-watch-set-denominator.sh` leg 8 re-asserts T-345's finding: the audit's two
fabric coverage checks must agree on the unregistered count. It reads both numbers out of
`fw audit --section structure` with `sed` and `head -1`.

Its anchor for the first number is the literal `unregistered (of N watched)`. T-525 changed
that message to `unregistered (of N watched — P% covered, <direction note>)`, so the anchor no
longer matches the finding it was written for.

It did not stop matching. The audit ends with a **TREND ANALYSIS** section that re-prints
recurring findings from the last 14 days verbatim — including `Fabric: 40 registered, 185
unregistered (of 222 watched) (7 times)`, which is the *old* message shape preserved in the
historical record. `head -1` therefore binds to a 14-day-old aggregate and compares it against
today's drift count.

Measured just now:

| | value | source |
|---|---|---|
| what the guard read as "today" | 185 unregistered, 222 watched | line 50, TREND ANALYSIS, `(7 times)` |
| today's actual coverage finding | 199 unregistered, 255 watched | line 21, `[WARN]` |
| today's drift count | 199 | parsed correctly |

So the guard reports `the two coverage checks DISAGREE (185 vs 199)` when today they agree at
199 and 199. The disagreement is manufactured entirely by the parse.

**Why this is more than a stale regex.** The guard's author explicitly handled the case where
the anchor finds nothing — the comment reads *"distinguish that from a parse failure rather
than reading an absent match as agreement"*. The anticipated failure was silence. What
actually happened is that the report contains a **historical echo of the very sentence the
anchor was written against**, so a stale anchor does not go quiet, it rebinds onto the archive
of its own past. Any report that summarises its own history offers a stale parser something
to match, and the match looks like data.

Note also the direction of the error: it produced a FALSE RED here, but the same mechanism
produces a false GREEN whenever the historical aggregate happens to equal today's drift count.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The guard parses today's coverage finding, not a historical echo: leg 8 reports the same
      unregistered/watched pair that appears on the live `[WARN]`/`[PASS]` fabric line, verified
      against the numbers `fw audit --section structure` prints on the same run
- [x] The parse is **anchored to the findings region**, so a line in TREND ANALYSIS (or any
      other section that quotes past findings) cannot satisfy it — the fix is not merely a
      widened regex that happens to match both shapes
- [x] The guard **fails loudly if its anchor ever stops matching a current finding**, rather
      than falling through to whatever else in the report looks similar. Absence of a current
      match is an abstention, not a comparison
- [x] `bash tools/_t344-watch-set-denominator.sh` exits 0 with all legs green, and leg 8 states
      the numbers it compared so the next reader can check them against the audit
- [x] A teeth probe drives the guard against a **synthetic audit transcript** containing a
      trend-echo line that differs from the current finding, and requires the guard to read the
      current one — proving the defect cannot return silently
- [x] The teeth probe has a standing caller (bridge suite), because the defect survived weeks
      precisely by having none

## Measured

**Before.** `fw task verify T-344` → `1/2 passed`; the guard exited 1 with

```
FAIL  the two coverage checks DISAGREE (185 vs 199, denominator 222)
```

**Where those numbers came from,** by grepping the same report the guard read:

```
line 21: [WARN] Fabric: 59 registered, 199 unregistered (of 255 watched — 23% covered, ...)
line 50:   - Fabric: 40 registered, 185 unregistered (of 222 watched) (7 times)
```

Line 50 is TREND ANALYSIS — a 14-day recurring-issue aggregate, preserved in the pre-T-525
wording. It is the *only* line in the report matching the guard's anchor, because T-525 added
`— P% covered, …` between `watched` and the closing paren on the real one.

**After.** `bash tools/_t344-watch-set-denominator.sh` → `8 passed, 0 failed`, leg 8:

```
PASS  audit's two coverage checks agree: 199 unregistered of 255 watched
```

199 and 199 — they had been agreeing the whole time.

**Anti-vacuity, measured not asserted.** The pre-T-550 parse was reconstructed into a temp copy
of the guard and the probe run against it via `T550_GUARD`: legs 1–4 all go **RED**, and only
leg 5 stays green (it checks the live audit's message shape and does not depend on the parse).
So the probe's green is a classification and not an absence.

## Not fixed here, deliberately

**Leg 2 flaked once during this work** — `src/aef-workflow-designer.html is NOT watched` — and
then passed 8/8 across two full runs, with the expander returning the file 3/3 and the leg's
own pipeline returning 0 eight times. It is a third sighting of the standalone-green class, and
this one has a named candidate mechanism: `python3 … | grep -qx` under `set -o pipefail`, where
`grep -q` closes the pipe on match and a still-writing producer takes SIGPIPE, which pipefail
then promotes to the verdict (L-387). Registered with its population — 26 files, ~100 such
pipelines — rather than repaired inside this task, because choosing a remedy across 100 sites
is a task and not an aside.

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

# The guard itself is green, all eight legs, against the live tree.
bash tools/_t344-watch-set-denominator.sh
# And it reads today's finding rather than the report's summary of its own past — driven over
# recorded transcripts that contain both, including a trend echo that disagrees.
python3 tools/_t550-audit-parse-anchor-teeth.py
# The anchor is confined to severity-marked findings. A bare `.*` search over the whole report
# is what bound to TREND ANALYSIS in the first place, so its return is worth failing on.
test "$(grep -cF 'PASS|WARN|FAIL|INFO' tools/_t344-watch-set-denominator.sh)" = "1"
# The probe has a standing caller. The defect survived because nothing ran the guard.
grep -q '_t550-audit-parse-anchor-teeth.py' tests/run-bridge-tests.sh

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

**Symptom:** `fw task verify T-344` reported `1/2 passed`; the guard claimed the audit's two
fabric coverage checks disagreed at 185 vs 199 on a day both reported 199.

**Root cause:** the guard's anchor (`unregistered (of N watched)`) was superseded by T-525,
which inserted `— P% covered, <direction>` before the closing paren. The anchor then matched
nothing among the live findings — but the report's TREND ANALYSIS section reprints recurring
findings from the previous 14 days *in the wording they had when recorded*, so `head -1` over
the whole report bound to a fortnight-old aggregate instead.

**Why structurally allowed:** three things had to line up.
1. **A report that quotes its own history is a parsing hazard.** A stale anchor over such a
   report does not fail to match; it rebinds onto the archive of the sentence it was written
   for. The guard's author anticipated *silence* — the comment says so explicitly — which is
   the failure mode that does not occur here.
2. **The search was unscoped.** `sed` ran over the entire report with `head -1`, so the
   findings section and the trend section were equally eligible.
3. **Nothing ran the guard.** Its only caller is T-344's own `## Verification`, and T-344 is
   `owner: human` and open, so the guard executes only when someone runs `fw task verify
   T-344`. `_t509`'s sweep did not cover it either — the sweep's population is `ls tools/ |
   grep -Ei 'teeth'`, and this file is a `-denominator.sh`. That is PL-192's naming-convention-
   as-classifier again, and it is why a red guard sat unread while T-525 shipped through it.

**Prevention:** the parse now requires a severity-marked finding, so no trend echo can satisfy
it; a stale anchor abstains with a message naming the trap rather than falling through; and
`tools/_t550-audit-parse-anchor-teeth.py` drives the guard over recorded transcripts containing
both a live finding and a disagreeing trend echo, wired into the bridge suite so it has a
standing caller. Mutation-verified: legs 1–4 go red against the pre-T-550 parse.

**Not claimed:** this fixes one instrument, not the class. 121 non-`teeth` instruments live in
`tools/`, and whether the rest have standing callers is unmeasured here.

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

### 2026-08-16T19:27:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-550-t-344-denominator-guard-reads-the-audits.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ef97653d
- **Timestamp:** 2026-08-16T19:37:49Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T19:37:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
