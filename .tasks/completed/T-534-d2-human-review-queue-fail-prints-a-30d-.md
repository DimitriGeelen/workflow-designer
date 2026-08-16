---
id: T-534
name: "D2 human-review-queue FAIL prints a >30d count against a >14d list"
description: >
  The D2 control accumulates d2_details in BOTH the >=720h (fail) and >=336h (warn)
  branches, then the fail message prints the fail-tier COUNT against the union LIST:
  'D2: Human review queue - 2 task(s) waiting >30d: T-093(41d) T-178(36d) T-308(17d)
  T-310(17d) T-325(14d)'. Count 2, list 5, three of them below the stated threshold.
  Invisible unless both tiers are populated, which is why it survived. Vendored .agentic-framework/agents/audit/audit.sh:3966,3969,3984
  - fix in-tree per G-008 and report upstream. Found while correcting T-432.

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
created: 2026-08-15T22:47:15Z
last_update: '2026-08-16T14:33:45Z'
date_finished: 2026-08-15T23:15:56Z
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
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:45Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 
      (no-signal); F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/audit/audit.sh,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t534-d2-queue-tier-teeth.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:58Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/audit/audit.sh,tests/run-bridge-tests.sh,tools/_t534-d2-queue-tier-teeth.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-534: D2 human-review-queue FAIL prints a >30d count against a >14d list

## Context

Found while correcting T-432, whose open operator ruling (c1/c2) is entirely about this
one line. Reported by the audit as:

    [FAIL] D2: Human review queue — 2 task(s) waiting >30d: T-093(41d) T-178(36d) T-308(17d) T-310(17d) T-325(14d)

Count **2**, list **5**, three of them under the threshold the sentence states.

## Findings

### The mechanism

`audit.sh` appended to a single `d2_details` from **both** tier branches:

    if   [ "$age_hours" -ge 720 ]; then d2_fail=…; d2_details="$d2_details …"   # >30d
    elif [ "$age_hours" -ge 336 ]; then d2_warn=…; d2_details="$d2_details …"   # >14d

…and the FAIL message then printed the **fail-tier count** against that **shared list**.
This is PL-159 (T-445) in its purest form: *a bar stated in a failure-message string is not
a bar the instrument holds.*

### Why it survived — the part worth keeping

**The defect is unobservable unless both tiers are populated at once.** With only fail-tier
entries present, the shared list is exactly the fail list and every reading of the line
agrees with itself. So a test built from one aged task passes against the broken code —
PL-206, a stimulus built so it cannot fail. The teeth therefore drive **all three tiers**
(40d / 20d / 5d), which is also what makes leg 6 meaningful.

Second reason: **nobody reads this line.** D2 renders under `--section discovery`, and the
only audit anyone runs routinely is the push gate's `--section structure`. Cron has been
rendering the wrong sentence roughly daily into `.context/audits/cron/` since the tiers
first co-populated.

### Correction to the filing — D2 is not an `oe-daily` check

This task was filed believing D2 lived in `oe-daily`, inherited from T-432's breakdown.
Measured: D2 sits inside `if should_run_section "discovery"` (`audit.sh:3915`), and the
report prints it under `=== DISCOVERY: OMISSION DETECTION ===`. That is what makes the
teeth affordable — `--section discovery` reaches the line in ~8s where a full audit needs
81s (216s against a synthetic `TASKS_DIR`). The wider consequences of that mis-attribution
belong to T-432 and OBS-027, not here.

### The fix

Two accumulators, one per tier. The `>14d` tier is **appended with its own count and
label** rather than dropped — deleting it would reconcile count with list by hiding a real
queue, which is a worse line than the one we started with. Result on the live tree:

    [FAIL] D2: Human review queue — 2 task(s) waiting >30d: T-093(41d) T-178(36d); 3 waiting >14d: T-308(17d) T-310(17d) T-325(14d)

### Evidence the teeth discriminate

Both arms, on the **real binary** rather than a replay:

| arm | result |
|---|---|
| mutate `audit.sh` to re-merge the tiers | legs **2, 3 and 7** red, naming `T-902(20d)` |
| restore | sha256 byte-identical, 8/8 green |

Leg 7 ("no task appears in both lists") went red unprompted — it was written as a
consistency check and turned out to be a second independent detector for this mutation.

Suite **96 → 97 passed, 0 failed** (313s; the familiar "168s" is T-509's stale figure,
corrected to ~309s by T-526). T-451 unwired-guard ratchet unmoved at **67**, since the
tool is wired rather than added to the shelf.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Every task named under a threshold label actually satisfies that threshold.** This is
      the defect stated as a property rather than as a diff: today the `>30d` FAIL names
      `T-308(17d)`. The property must hold for each element of the list, not merely for the
      count — a fix that made the *count* 5 would also reconcile count with list and would be
      wrong in the other direction.
- [x] **No information is lost.** The three `>=14d` tasks currently surfaced (however
      mislabelled) are still reported after the fix, under their own predicate and their own
      count. Deleting them would "fix" the mismatch by hiding a real queue.
- [x] **The `info` tier still does not appear in either list** — a task under 14d is not
      named. Guards against a fix that reconciles the lists by printing everything.
- [x] **Teeth exist and are proven red for the named reason**, driving the REAL `audit.sh`
      against a synthetic queue populating all three tiers via the `TASKS_DIR` seam — not a
      reimplementation of the branch logic in the test, which would assert a copy. Red arm
      demonstrated against the pre-fix binary, naming the offending token.
- [x] **The teeth REFUSE (rc 2) rather than pass when no D2 line is emitted or it no longer
      parses.** "No usable line" is the single most likely way this test goes vacuously green
      (PL-205), and it is not hypothetical: an empty review queue renders
      `[PASS] D2: Human review queue — no pending items`, which does not parse. Demonstrated
      by mutating the fixture's `owner: human` → `agent` so nothing enters the queue → rc 2,
      teeth restored byte-identical.
      *(This AC was filed citing OBS-027's "`--section oe-daily` never emits D2" as evidence
      of a run-context effect. That inference is dissolved — D2 was never an oe-daily check.
      The AC stands on its own ground; the citation was wrong and is removed rather than
      left to propagate.)*
- [x] **Reported upstream to AEF**, since the defect is in vendored
      `.agentic-framework/agents/audit/audit.sh` and the fix is in-tree per G-008.
- [x] **The push gate's section list is NOT touched.** That is T-432's open operator ruling;
      this task fixes what the D2 line *says*, and must not pre-empt whether it gates.

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
#
# T-534: the teeth are the verdict — a single command whose own exit code decides, so no
# errexit-context question arises. rc 2 is a REFUSAL (no D2 line emitted / no longer parses)
# and is correctly non-zero: nothing was evaluated is not a pass.
# The second line asserts the instrument is still WIRED. This tree's recurring defect is not
# broken guards, it is correct guards nobody calls (T-451 census: 67 standing guards with no
# live caller), so a teeth script that silently leaves the suite is the likely regression.
python3 tools/_t534-d2-queue-tier-teeth.py
grep -q '_t534-d2-queue-tier-teeth.py' tests/run-bridge-tests.sh

## RCA

**Symptom:** the D2 audit line named five tasks under a `>30d` predicate while counting two,
three of the named being 17d, 17d and 14d old.

**Root cause:** one shared `d2_details` accumulator written by two branches with *different*
thresholds (`>=720h` and `>=336h`), consumed by a message that states only one of them. Not
"the code was wrong" — the variable had no owner, so whichever branches wrote to it silently
redefined what the message meant.

**Why structurally allowed:** two independent reasons, and both had to hold.
1. **The defect is invisible with one tier populated** — the shared list then equals the fail
   list, and the line is internally consistent. Any test, or any human reading, that happened
   to catch a single-tier queue would confirm correctness.
2. **Nothing reads the line.** D2 renders under `--section discovery`; the push gate runs
   `--section structure` only (T-432). The full audit is run by cron into
   `.context/audits/cron/`, which T-529 measured as a corpus no tool reads.

**Prevention** (distinct from the fix): `tools/_t534-d2-queue-tier-teeth.py`, wired as a
standing leg in `tests/run-bridge-tests.sh`, driving the **real** `audit.sh` through the
`TASKS_DIR` seam against a queue that populates **all three tiers** — so the condition that
made the defect observable is now guaranteed on every run rather than left to the live
queue's shape. The fix itself is also structural: separate per-tier accumulators mean the
message *cannot* interpolate the wrong list, so a future edit reintroducing it would have to
be deliberate.

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

### 2026-08-15T22:47:15Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-534-d2-human-review-queue-fail-prints-a-30d-.md
- **Context:** Initial task creation

### 2026-08-15T22:51:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-24834d39
- **Timestamp:** 2026-08-15T23:16:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T23:15:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
