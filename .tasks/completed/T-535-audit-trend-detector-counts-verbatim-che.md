---
id: T-535
name: "Audit trend detector counts verbatim check strings, so an issue is only 'recurring'
  while its numbers stop moving"
description: >
  audit.sh:5520-5535 extracts each WARN/FAIL 'check:' string verbatim and aggregates
  with sort|uniq -c, firing at count>=3. Any check that embeds its measurement therefore
  produces a fresh string per run and can never aggregate. Measured over this project's
  41 daily audits: the fabric COVERAGE warn appears in 37 audits and its largest identical-string
  group is 1 - never once reported as recurring. The fabric EDGES warn appears in
  10 and is reported as 3, and only because the counts held still for three consecutive
  days. So the detector fires on STASIS while labelled recurrence, and is least sensitive
  exactly when a problem is progressing. Vendored .agentic-framework/agents/audit/audit.sh
  - fix in-tree per G-008 and report upstream. Found while acting on the audit's own
  'candidates for practice' trend line under T-432.

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
created: 2026-08-16T06:49:21Z
last_update: '2026-08-16T12:34:06Z'
date_finished: 2026-08-16T08:59:22Z
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
  - ts: '2026-08-16T12:34:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
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

### CORRECTION 2026-08-16 — the filed numbers were measured against a corpus the detector never reads

The table below originally read *"measured over this project's 41 daily audit records"* with
counts of **37** and **10**. That was wrong, and wrong in the direction that made the finding
look larger. Re-measured against the corpus the reader actually consumes:

`audit.sh:5484` globs `"$AUDITS_DIR"/*.yaml` — **not recursive** — then `continue`s on any
basename that is not date-named, then drops anything outside a **14-day rolling window**
(`FW_AUDIT_TREND_WINDOW_DAYS`, default 14) and today's own file. On 2026-08-16 that resolves to
**9 files**, holding **25** WARN/FAIL check lines between them. Not 41 files, and nothing close
to 37 occurrences of anything. The `.context/audits/cron/` subdirectory holds **703** further
audit records with **13,202** check lines, and the reader cannot see a single one of them.

The original figures are preserved here rather than silently swapped, because the error is the
instructive part: I measured the *available* records instead of the *consumed* ones. The
conclusion survives — it is sharper against the real corpus, not weaker.

<details><summary>Original (incorrect) table as filed</summary>

| check | audits containing it | largest identical-string group | reported as recurring |
|---|---|---|---|
| fabric **coverage** warn | **37** | **1** | **never** |
| fabric **edges** warn | **10** | 3 | 3 |

</details>

### Measured over the 9 audits the detector actually reads

| check | audits containing it | largest identical-string group | reported as recurring |
|---|---|---|---|
| fabric **edges** warn | **9 of 9** | 3 | **3** |
| fabric **drift** warn | **8 of 9** | 1 | never |
| fabric **coverage** warn | **8 of 9** | 1 | never |

Three issues, each present in essentially every audit in the window. **Exactly one is reported,
and only for the three consecutive days its reading stood still at `36/40` (08-12, 08-13,
08-14).** Seven distinct readings for the edges issue across nine audits; seven for drift; eight
for coverage.

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

### A second defect found in the same block

`audit.sh:5531` read the check text out of `uniq -c` output with `cut -d' ' -f2-`. `uniq -c`
right-pads its count, so the leading spaces become empty fields and the count survives into the
text. That is why every trend line this project has ever printed reads

    -      3 Fabric: 36/40 cards have no edges (3 times)

with the count rendered twice. Fixed as a side effect of keying on a tab-delimited pair; asserted
by leg 3 so it cannot come back.

### Found while measuring, deliberately NOT folded into this task

The 703 records in `.context/audits/cron/` are invisible to the trend reader (non-recursive glob
plus a date-named-basename filter). They hold 13,202 WARN/FAIL lines against the window's 25 —
so the detector runs on roughly 0.2% of the recorded evidence. Excluding a 15-minute cron cadence
from a detector calibrated at "3 occurrences" is defensible design, not obviously a bug, so it is
**not** claimed as one here. Filed separately as an observation. Folding it in would have made
this task a second thing and copied the same mistake T-534 recorded a learning about.

That corpus also shows what the blindness costs: `CTL-028` naming four tasks in
`.tasks/completed/` with `status='started-work'`, and `CTL-029` naming nineteen with all Agent
ACs ticked but still `started-work`, each repeated 263 times and never once surfaced by a trend
line. Those are separate findings and get separate handling.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The aggregation key is separated from the rendered message.** An issue recurring with
      changing numbers aggregates; the printed line still shows a concrete instance, because a
      normalised key like `Fabric: N/M cards have no edges` is a worse thing to show an
      operator than a real reading.
      → `audit.sh:5526-5580`: key = normalised text, rendered value = **most recent** raw reading
      (glob order is chronological, last write wins). Leg 2 fails if a `N` placeholder ever
      reaches the rendered line.
- [x] **Measured before/after on this project's real audit corpus**, not on a fixture.
      ~~the fabric coverage issue must move from *never reported* to reported with a count near
      37, and the edges issue from 3 to near 10~~ — those targets were derived from the wrong
      corpus; see the CORRECTION above. Re-stated against the 9 audits the reader consumes, and
      as a **direction**, not a pinned count, because the corpus grows daily and pinning an
      exact number is the G-015 defect this tree keeps finding:

      | | before | after |
      |---|---|---|
      | issues promoted | **1** | **3** |
      | `Fabric: …/… cards have no edges` | 3 (a stale `36/40`) | **9**, shown as `37/56` |
      | `Fabric drift: … source file(s)` | never reported | **8**, shown as `189` |
      | `Fabric: … registered, … unregistered` | never reported | **7**, shown as `40/185/222` |

      Run on the live tree via the seam: `AUDITS_DIR=<copy of the 9 window files> fw audit
      --section structure`.
- [x] **Normalisation does not over-merge.** Two genuinely different checks whose text differs
      only in digits must not collapse into one. Demonstrated with a concrete pair from the
      real corpus, or the absence of such a pair reported as a measurement.
      → Concrete pair found, not absent: `CTL-028: T-901 …` vs `CTL-029: T-901 …` in the cron
      corpus differ **only** in digits. Under the naive `s/[0-9]+/N/` they fuse into one entry
      reported at `10 x CTL-029` — a recurrence that does not exist, attributed to one control,
      with the other erased. The shipped normaliser protects `[A-Za-z]{1,6}-[0-9]+` tokens and
      keeps them distinct. Red arm B below drives exactly this.
- [x] **Teeth drive the real trend analysis** against a controlled corpus of audit records
      (seam: the `past_audits` source directory), with a red arm proving the pre-fix code
      scores a numbered recurring issue at 1.
      → `tools/_t535-trend-key-teeth.py`, 7 legs, 13s. Seam added: `AUDITS_DIR` is now
      env-overridable (`audit.sh:22`, matching the `TASKS_DIR` idiom) so the corpus **and** the
      run's output land in a sandbox. Corpus dates are computed from today, never pinned.
- [x] **The teeth REFUSE (rc 2) if the corpus yields no trend section at all** — otherwise a
      broken reader renders as "no repeated issues", which is indistinguishable from health.
      → Proven twice: an empty corpus exits **rc 2** with `REFUSE: trend section rendered but
      reported nothing`, and `parse_trend()` returns `present=False` for output carrying no
      trend section, which is a separate refuse branch.
- [x] **Reported upstream to AEF** — vendored `.agentic-framework/agents/audit/audit.sh`,
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

# The edited file is bash with an embedded python3 heredoc — parse both, not just one.
bash -n .agentic-framework/agents/audit/audit.sh
# The teeth. rc 0 = 7/7 green; rc 1 = a named leg is red; rc 2 = REFUSE (stimulus not established).
# Deliberately NOT `| grep -q green` — the script's own exit code is the verdict, so no chaining
# question arises (P-011 errexit note above).
python3 tools/_t535-trend-key-teeth.py
# The teeth are actually called by something. An unwired instrument is the T-451/T-509 class.
grep -q '_t535-trend-key-teeth.py' tests/run-bridge-tests.sh
# The seam is env-overridable rather than hardcoded — this is what makes the teeth hermetic.
grep -q 'AUDITS_DIR="${AUDITS_DIR:-\$CONTEXT_DIR/audits}"' .agentic-framework/agents/audit/audit.sh

## RCA

**Symptom:** every audit printed `Repeated issues detected … -      3 Fabric: 36/40 cards have
no edges (3 times)` while the same audit's body reported `Fabric: 37/56 cards have no edges` —
a trend line quoting a count that no longer existed, and quoting it twice.

**Root cause:** the recurrence counter's identity key was the *rendered sentence*
(`audit.sh:5520` — `sed 's/.*check: "//'`, then `sort | uniq -c`). Any check that embeds its own
measurement therefore mints a fresh key on every run and can never reach the `count -ge 3`
threshold. The counter measured **string stability**, not persistence.

**Why structurally allowed:** nothing distinguished *what an issue is* from *what an issue
currently reads*, and no test drove the trend block at all — it had no seam to drive it through
(`AUDITS_DIR` was hardcoded off `CONTEXT_DIR`). The block's only observable output is a
human-facing paragraph nobody diffs, and its failure mode is **silence**: an issue that never
aggregates produces "No repeated issues", which is indistinguishable from health. A detector
whose failure looks exactly like success will not be reported by its users.

**The inversion is the real damage:** the threshold was reachable *only* by an issue whose
numbers stopped moving. The one line this project ever promoted crossed the bar because
`36/40` held still on 08-12/13/14. An issue recurring daily *and steadily worsening* scored 1
forever — so the instrument was least sensitive exactly when a problem was progressing, and the
framework's downstream "consider creating a practice" prompt was routed by string stability
rather than by persistence.

**Prevention:** `tools/_t535-trend-key-teeth.py`, wired into the bridge suite, drives the real
`audit.sh` through the new `AUDITS_DIR` seam. Leg 1 fails if a numbers-moving issue stops
aggregating (red arm A: reverting the key to the verbatim string makes the mover vanish
entirely). Leg 4 fails if two controls differing only in digits fuse (red arm B: the naive
`s/[0-9]+/N/` reports `10 x CTL-029` and erases CTL-028). Leg 5 fails if the threshold stops
discriminating, so green is a classification rather than an absence. Both arms were run against
the live binary and the file restored to its baseline sha256.

## Decisions

### 2026-08-16 — how much to normalise

- **Chose:** fold only free-standing numbers; preserve identifier tokens matching
  `[A-Za-z]{1,6}-[0-9]+` (CTL-028, T-901, G-015, D2).
- **Why:** the two available errors are not symmetric. Under-merging leaves an issue counted
  per-subject, which is honest and merely conservative. Over-merging **fabricates** a recurrence
  across unrelated checks and prints it under one of their names while hiding the other — the
  measured red arm B output is `10 x CTL-029`, a number describing nothing real. A recurrence
  detector that invents recurrences is worse than one that misses them.
- **Rejected:** naive `s/[0-9]+/N/` (fuses CTL-028 with CTL-029 — demonstrated, not theorised);
  and normalising prose as well as digits, which would have merged the pre- and post-T-525
  coverage wordings. T-525 genuinely rewrote that sentence, so restarting its count is correct
  behaviour and its 8th occurrence legitimately sits under a separate key. That is a real
  residual limitation — a check that rewrites its own prose still resets its count — but it is a
  one-time reset on a deliberate wording change, not a per-run reset, and it is stated here
  rather than papered over.

### 2026-08-16 — where the teeth get their corpus

- **Chose:** make `AUDITS_DIR` env-overridable and point the teeth at a temp dir.
- **Why:** it is the same idiom `lib/paths.sh` already uses for `TASKS_DIR`, it is one line, and
  it makes the probe hermetic in both directions — the real `.context/audits` is neither read nor
  written, and the audit's own output file lands in the sandbox.
- **Rejected:** re-implementing the aggregation in the test (would assert a copy, not the
  subject — the defect this project keeps finding); and overriding `CONTEXT_DIR`, which would
  have moved every other path the audit resolves.

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

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c2938468
- **Timestamp:** 2026-08-16T08:59:35Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T08:59:22Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
