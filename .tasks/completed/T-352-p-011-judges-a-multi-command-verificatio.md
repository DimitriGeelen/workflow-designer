---
id: T-352
name: "P-011 judges a multi-command verification line on its last command alone (set
  -e suppressed in the gate's if-condition)"
description: >
  update-task.sh:1018 runs each verification command as 'if ( ...; eval "$cmd" );
  then' — the subshell is the CONDITION of an if, so set -e (set at line 14) is suppressed
  inside it. A line of the form 'a; b' is therefore judged on b alone: a's failure
  is swallowed. The capture-then-grep shape the task template PRESCRIBES as the L-387
  SIGPIPE remedy ('out=$(cmd 2>&1); echo "$out" | grep -q PAT') is exactly this shape,
  so the framework teaches it. PROVEN live: 'out=$(python3 tools/validate-workflow.py
  BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"' returns PASS under the gate's
  own construct on a document the validator exits 2 on and labels INVALID — grep -q
  VALID matches INVALID as a substring. Structural population: 332 of 1318 verification
  lines contain a top-level ';'. That is an upper bound, NOT a finding — most greps
  pin a zero-failure token and are safe. Members must be measured individually, not
  counted. Reported to AEF as their own finding reproducing here (their RAIL-403).

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [arc:designer-authoring-surface, tooling, verification-gate]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T23:59:29Z
last_update: '2026-08-16T13:58:53Z'
date_finished: 2026-08-03T10:34:26Z
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
  - ts: '2026-08-16T12:33:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.tasks/templates/default.md,docs/reports/T-352-member-scan.md,docs/reports/T-352-remedy.md,tools/_t352-member-scan.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.tasks/templates/default.md,docs/reports/T-352-member-scan.md,docs/reports/T-352-remedy.md,tools/_t352-member-scan.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-352: P-011 judges a multi-command verification line on its last command alone (set -e suppressed in the gate's if-condition)

## Context

Found while writing T-351's verification block, and confirmed against AEF's RAIL-403 which
reported the same mechanism in their tree independently.

`update-task.sh:1018` runs each verification command as
`if ( unset …; cd "$PROJECT_ROOT" && eval "$cmd" ); then`. The subshell is the **condition of
an `if`**, so the `set -euo pipefail` at line 14 is suppressed inside it. A line of the form
`a; b` is therefore judged on `b` alone — `a`'s exit code is discarded.

This is not an exotic shape. The task template's own L-387 SIGPIPE hint **prescribes it**,
listed first and labelled "Safe pattern":
`out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"`. The framework teaches the defect.

**Proven live, through the gate's own construct** — not reasoned, and not by hand:
`out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"`
returns **PASS** on a document `validate-workflow.py` exits 2 on and labels `INVALID`, because
`grep -q "VALID"` matches `INVALID` as a substring. Two independent defects stacked; either
alone would have been survivable.

**The intuitive fix is a non-fix** (measured, with a positive control alongside):

| form | verdict on `a` fails / `b` succeeds | |
|---|---|---|
| `if ( eval "$cmd" )` | PASS | today's behaviour, wrong |
| `if ( set -e; eval "$cmd" )` | PASS | **still wrong** — the suppressed context is inherited |
| `if bash -c "set -eo pipefail; $cmd"` | FAIL | correct |

A line that *should* pass still passes under all three, so the third discriminates rather
than merely being stricter.

**Population sizing, deliberately not inflated:** 332 of 1318 verification lines carry a
top-level `;` and are structurally judged on their last command alone. **That is an upper
bound, not a finding.** Most pin a zero-failure token (`passed, 0 failed`) and are safe.
4 lines are proven false-green by execution so far. Counting the 332 as findings would be
an 80× overclaim.

**Why this is not fixed here:** the gate lives in `.agentic-framework/` (vendored). Changing
how every verification line in the project is evaluated is a framework-wide behaviour change
— G-008 upstream territory and the operator's ruling, not an agent's.

## Acceptance Criteria

### Agent
- [x] **AC1 — the false green is reproduced by a committed harness, not by a paragraph.**
      A script constructs a document the validator rejects, runs the offending verification
      line through the gate's *own* construct (copied from `update-task.sh`, not
      approximated), and asserts the verdict is PASS. If the gate is later fixed, this
      harness must go red — it is the regression witness, so it must fail on the fix.
- [x] **AC2 — the members are enumerated, not the count.** Every verification line whose
      grep clause can match its own command's failure output is listed by task id and line,
      with the failing output that satisfies it. Lines that merely *have* the `a; b` shape
      but pin a zero-failure token are reported separately and explicitly as NOT findings.
      The report states both numbers and says which is the finding.
- [x] **AC3 — the non-fix is recorded with its control.** The `set -e`-in-subshell form is
      shown to still pass, beside a positive control proving the accepted form is not merely
      stricter. Without the control, "form C fails more" is not evidence that it is right.
- [x] **AC4 — the point of teaching is fixed, or the reason it was not is written down.**
      The template hint that prescribes the capture-then-grep shape either gains a warning
      naming this behaviour, or the task records that the template is vendored and the
      change is the operator's. A defect the documentation teaches regenerates faster than
      it can be remediated.
- [x] **AC5 — remedy proposed, not applied.** The `bash -c` wrapper is written up with its
      blast radius (every verification line in every task re-evaluated under real errexit;
      expect currently-green lines to go red, and that is the point). No edit to
      `.agentic-framework/` under agent authority — G-008 upstream, operator's call.

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

# Every line below is a SINGLE command whose own exit code is the verdict — deliberately.
# This task exists because `a; b` is judged on `b` alone under the gate, so a task ABOUT
# that defect must not contain an instance of it. (T-351 did the same, for the same reason.)
bash tools/_t352-p011-errexit-probe.sh
bash tools/_t352-teeth.sh
bash -n tools/_t352-p011-errexit-probe.sh
bash -n tools/_t352-teeth.sh
python3 -c "import ast; ast.parse(open('tools/_t352-member-scan.py').read())"
grep -q 'ERREXIT WARNING' .tasks/templates/default.md
test -f docs/reports/T-352-remedy.md
test -f docs/reports/T-352-member-scan.md

## RCA

**Symptom:** a verification line whose first command exits 2 and prints `INVALID` is
recorded as PASS by the P-011 completion gate.

**Root cause:** two independent defects stacked, either survivable alone.
1. `update-task.sh:1018` evaluates each line inside a subshell that is the **condition of an
   `if`**. Bash suppresses `errexit` in that position, so the `set -euo pipefail` at line 14
   does not reach `$cmd` and `a; b` is judged on `b` alone.
2. The line's own pattern, `grep -q "VALID"`, matches `INVALID` as a substring — so even the
   surviving command agreed with a document that had been rejected.

**Why structurally allowed:** the framework *taught* the shape. The task template listed
`out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"` first and labelled it "Safe pattern". It
was introduced for a real reason (L-387, SIGPIPE) and does fix SIGPIPE — while converting a
single command into `a; b`. A defect the documentation prescribes regenerates faster than it
can be remediated, so counting or repairing instances could never converge.

Compounding it: the template's claim "P-011 runs each command under `set -eo pipefail`" is
**half true**. `pipefail` really is in effect; `errexit` is not. A half-true statement about an
execution context is worse than none, because it answers the question that would otherwise
have been asked.

**Prevention (distinct from the fix):**
- The point of teaching is corrected: the template now leads with the errexit warning and
  promotes the `&&` file form, whose immunity is *asserted in the probe* rather than assumed.
- `tools/_t352-p011-errexit-probe.sh` **extracts** the gate's construct at runtime instead of
  copying it, so it fails when the gate is fixed and cannot drift into describing a past.
- `tools/_t352-teeth.sh` leg (a) applies the remedy and requires the probe to go red, which is
  the only thing that makes "this is the regression witness" a measurement rather than a claim.

## Evolution

### 2026-08-03 — the population number was wrong twice, in opposite directions

- **What changed:** the figure I reported to AEF at RAIL-405 (332 of 1318) came from a naive
  `grep ';'`, which also counts semicolons inside quotes, inside `sed 's/a;b/c/'`, and in
  `find … \;`. Replacing it with a quote/paren-aware parser returned **26** — and that was
  wrong too, in the other direction: it incremented nesting depth on `$` *and* again on the
  following `(`, so `$(…)` never returned to depth 0 and every top-level `;` after a command
  substitution was invisible. The sound number is **322**.
- **Plan impact:** a confident undercount reads exactly like a careful one. The parser now
  carries a **self-test in both directions that must pass before any number is produced** — a
  test with only positives passes for a parser that answers True to everything, which is the
  mirror of the bug that actually occurred.
- **Triggered:** no new task. Recorded because the near-miss is the lesson: I would have
  reported 26 as a *correction* to 332, with a plausible story about over-broad matching.

### 2026-08-03 — "vendored, operator's call" was wrong about the template

- **What changed:** I filed this task recording that the point of teaching was vendored and
  therefore not mine to fix. `create-task.sh:447` resolves the template through `TASKS_DIR`,
  which is the **project's** `.tasks/templates/default.md`. The vendored copy is never read
  when creating tasks here.
- **Plan impact:** AC4 was written to allow "record why it was not fixed" as an out. It was
  fixable all along, so it is fixed. Deferring under a constraint I had not checked would have
  parked a one-file change behind an operator decision that was never needed.
- **Triggered:** none. The vendored copy still carries the old text and is left alone — that
  half really is G-008 upstream.

### 2026-08-03 — the measuring tool reproduced the class it measures, twice

- **What changed:** (a) the scan's runner used `subprocess.run(timeout=…)`, which kills only
  the direct child and then blocks in `communicate()` waiting for a stdout EOF the surviving
  grandchild subshell still holds — it leaked runner processes for minutes past their timeout
  and never finished. Same defect class as T-351: a stop path that assumes cooperation from
  the thing it is stopping. (b) A wait loop written as
  `until … ! pgrep -f '_t352-member-scan'` could never exit, because its own argv contains the
  pattern — so it waited for a condition it was itself keeping true.
- **Plan impact:** the runner now uses an explicit process group and `killpg`; kill patterns
  are split so they cannot match the invoking shell.
- **Triggered:** none — (b) is the third instance of prose/argv sharing a byte-space with the
  thing it names on this arc, and the first that is a *liveness* bug rather than a false
  reading. Recorded to [[prose-in-exported-bytes]] territory rather than filed.

### 2026-08-03 — the measurement inverted the recommendation

- **What changed:** the scan's `PASS today / FAIL under the remedy` predicate was labelled
  "PROVEN — this is the finding". It is not. **That predicate aggregates two causes pointing in
  opposite directions**: a false green the remedy *fixes*, and a correct failure-path test the
  remedy *breaks*. Reading the 19 members showed they are almost entirely the second —
  `validate-workflow.py` on an invalid fixture exits non-zero *by design*, and `grep -c` exits 1
  when it counts zero matches, which is the condition being asserted. Renamed to DIVERGENT and
  documented as the **blast radius**, not a defect count.
- **Plan impact:** the honest result is **0 currently-manifesting false greens**, **4 latent**
  (all `grep -q "VALID"`, and all in *archived* tasks that will never re-run), and **19 correct
  lines the remedy would break**. So applying the gate change today buys ~0 and costs 19 working
  lines across other owners' tasks. My recommendation reversed: land the template fix (done —
  it stops new instances), leave the gate change proposed until the 19 are converted.
- **Triggered:** none. Third instance on this arc of a difference spanning every cause while
  being reported as one (T-343's `len(raw) − len(resolved)`, T-341's baseline). The predicate was
  right; the noun attached to it was not. See [[differences-aggregate-every-cause]].

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

### 2026-08-02T23:59:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-352-p-011-judges-a-multi-command-verificatio.md
- **Context:** Initial task creation

### 2026-08-03T00:17:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-94ebc3d3
- **Timestamp:** 2026-08-03T10:34:30Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-03T10:34:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
