---
id: T-669
name: "uncontrolled absence assertions rose 78 to 90 — _t560's ratchet is red and raising the baseline would defeat it"
description: >
  The second of the two sweep regressions. _t560's legs 1-4 pass; leg 5 (the unoverridden run over the live corpus) is red because uncontrolled absence assertions rose from the baseline 78 to 90. Blocks six task closures that run the bridge suite.

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
created: 2026-09-01T21:38:40Z
last_update: 2026-09-01T22:05:52Z
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

# T-669: uncontrolled absence assertions rose 78 to 90 — _t560's ratchet is red and raising the baseline would defeat it

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The **12 new assertions are identified individually** — task id, verification line,
      and the pattern each asserts absent. The census reports a count, not a delta, so this
      requires diffing the census output against the corpus at the commit that last set the
      baseline. A fix applied to "some absence assertions" cannot be shown to have addressed
      the ones that actually moved the number.
- [ ] Each identified assertion is repaired in one of the two ways the census itself names:
      a companion leg greps the same pattern **where it IS present**, or the assertion is
      restated as a positive fact. Recorded per assertion, with which route was taken and why.
- [x] **The baseline file is not raised.** `tools/_t560-absence-baseline.txt` holds a bare
      number and the tool's own header says the ratchet "fails only when it RISES"; editing
      78 to 90 turns the leg green in one keystroke while destroying the only thing measuring
      this class. If the count cannot be brought back to 78, that is a finding to report, not
      a number to edit. (Lowering it *after* a genuine reduction is the sanctioned direction
      and must happen in the same commit as the reduction.)
- [x] Assertions living in **completed** tasks are handled explicitly rather than silently:
      the census names ~88 tasks and only 11 are active, so most offenders sit in
      `.tasks/completed/`. Whether a completed task's `## Verification` block may be edited at
      all is a real question — those blocks are the record of what was verified at completion
      — and this task records the answer it acted on instead of assuming one.
- [ ] `python3 tools/_t560-absence-census-teeth.py` exits 0 with all five legs green, leg 5
      passing because the live corpus is back at or below baseline — not because the leg,
      the baseline, or the census population was weakened. Proven by `git diff` showing no
      change to `tools/_t560-absence-assertion-census.py` or its baseline other than a
      sanctioned lowering.
- [ ] `bash tools/_t509-instrument-sweep.sh` reports `regressed 0`. This is the last of the
      two regressions; `_t400` was cleared by T-668, and clearing this one unblocks the six
      tasks that run the bridge suite (T-041, T-093, T-101, T-125, T-264, T-293).

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
         1. Run `bin/fw reviewer T-669`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-669 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
# ── T-669 legs ──────────────────────────────────────────────────────────────────
# EVERY leg below asserts a POSITIVE fact. T-560's own task made this rule for itself
# and the reason applies with full force here: a task about uncontrolled absence
# assertions, verified by uncontrolled absence assertions, would be flagged by its own
# census and would deserve it. Where the natural phrasing was "nothing changed", it is
# written as a byte-identity equality instead of as an empty `git diff`.

# The control leg added to T-590 matches where the pattern MUST be present. If the
# alternation is ever mistyped, this goes red loudly — which is the entire point of it.
grep -qE "conditionExpression|capability|secret|actionRef|action_ref|retry|compensat" docs/research/executable-workflow/cannot-represent-yet.md

# The control leg is actually present in T-590's Verification block.
grep -q 'T-669: control for the absence assertion below' .tasks/active/T-590-ewcr-arc-0-designer-contract-inventory-a.md

# The baseline was NOT raised. Asserted as an exact-value match, not as "no diff".
grep -qx '78' tools/_t560-absence-baseline.txt

# The census instrument is byte-identical to HEAD's copy — stated as a hash EQUALITY so
# the leg fails loudly if the comparison itself breaks, rather than passing on an empty
# `git diff --name-only`, which is the very construction this task is about.
test "$(git show HEAD:tools/_t560-absence-assertion-census.py | sha256sum | cut -d' ' -f1)" = "$(sha256sum tools/_t560-absence-assertion-census.py | cut -d' ' -f1)"

# The census now reports exactly 89, down from 90: T-590's repair is credited as a
# PATTERN control by the SHIPPED classifier, with no change to the instrument. The
# census exits 1 (still above baseline, correctly) — P-011 neutralises errexit inside
# its `if (...)` subshell (T-352), so that rc is deliberately not the verdict here; the
# grep is. This is the one place that blindness is wanted, so it is named rather than
# relied on silently.
python3 tools/_t560-absence-assertion-census.py > /tmp/.t669-census.out 2>&1; grep -q "RATCHET       baseline 78, current 89" /tmp/.t669-census.out

# T-590's repaired leg classifies as PATTERN. Asserted as an EQUALITY against the
# census's own classifier rather than as "T-590 no longer appears in the output" —
# the latter is an absence assertion and would pass just as well if the census stopped
# producing output at all.
python3 tools/_t669-t590-control-level.py

# The ruling on completed tasks is recorded in this file, not left implicit.
grep -q 'completed tasks. Verification blocks are not edited to clear the ratchet' .tasks/active/T-669-uncontrolled-absence-assertions-rose-78-.md

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** `_t560` leg 5 red — uncontrolled absence assertions rose from baseline 78 to 90,
failing the bridge suite and blocking six task closures.

**Method.** The census reports a count, not a delta, so the 12 were identified by running the
CURRENT census over the corpus as it stood at `86596a34` (the commit that armed the baseline),
extracted with `git archive` into a throwaway root via the sanctioned `T560_TASK_ROOT` door.
The tool is unchanged since that commit (`git log 86596a34..HEAD -- tools/_t560-absence-assertion-census.py`
is empty), so measurement drift is excluded by construction: the entire 78→90 movement is corpus.
The old-corpus run reproduced 78 exactly, which is what makes the diff trustworthy.

**Root cause — the rise is real, but it is not drift in anyone's discipline.**
Splitting the population by stratum, under a classifier repaired for the three defects below:

| stratum | at baseline | today | change |
|---|---|---|---|
| `.tasks/active/` — repairable | 8 | 8 | **0** |
| `.tasks/completed/` — frozen record | 68 | 77 | **+9** |

Membership of the active stratum is not merely flat in count, it is nearly identical in
identity: T-542 left (by completing) and T-590 arrived. So across 13 days exactly **one** new
uncontrolled absence assertion was written into a task anyone may still edit. The other eight
entered the frozen stratum by tasks *completing* — the ratchet fires on throughput, not on
defects.

**Why structurally allowed — two independent omissions.**

1. **The ratchet is not wired anywhere that runs before completion.** `_t560` is invoked only
   by `tests/run-bridge-tests.sh` and `_t509-instrument-sweep.sh`. Neither is a P-011 leg on the
   task being completed, so a task can write an uncontrolled absence leg, pass its own gate, and
   be archived; the census only reddens afterwards, by which time the leg is frozen. The tool's
   stated purpose is "to stop the 79th" and it is, by construction, incapable of stopping any.

2. **The ratchet's population mixes a repairable stratum with an unrepairable one.** A completed
   task's `## Verification` block is the record of what was verified at completion. Adding a
   control leg to it would make that record assert a verification which never ran. So the
   completed stratum can only grow and may never be repaired — which makes this ratchet a
   countdown to permanent redness. That is exactly the OBS-293 failure ("a permanently red leg
   teaches readers to rerun rather than to look") that the tool's own docstring says the ratchet
   design was chosen to avoid. It avoided it for the original 78 and re-created it structurally.

**Three classifier defects found while judging the 12** (each wrong by the tool's own
definitions, independent of any count):

- `EXIST_CTRL` credits capture-then-grep only when the temp file is a **dotfile**
  (`>\s*/tmp/\.[\w.-]+`). T-606:206/209 do `curl > /tmp/t606-approvals.html && grep -q "<code>" F
  && ! grep -q "&lt;code&gt;" F` and score NONE. The property is "output was captured into a file
  this line then greps"; the leading dot is a naming convention. Encoding the convention instead
  of the property is the hand-maintained-claim shape (PL-305/306/308) one level down.
- A same-line **positive** grep on the same file is not credited, though it proves strictly more
  than `test -f` — which is credited. (T-501:296.)
- `count-eq-zero` applies `SEARCH_SOURCED` to the **whole leg** rather than to the comparand, so
  `test "$rc" -eq 0` was classified an absence assertion because the word `grep` appears inside a
  quoted `eval` payload earlier on the line (T-592:205). That is "mention is not invocation" —
  the precise error the docstring says was corrected for the PATTERN control, left uncorrected
  one field over.

Repairing all three moves today 90→85 and the baseline corpus 78→76. **The rise survives the
repair** (+9), which is why the classifier defects are reported as defects and were not used to
argue the alarm away.

**Prevention (not yet built — see Decisions).** Mitigation would be editing eight completed
tasks or raising the baseline; both are refused below. Prevention is (a) wiring the census where
it runs while a task is still editable, and (b) ratcheting the repairable stratum while holding
the frozen stratum as a tamper-evident count. Neither is done under this task.

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

### 2026-09-02 — completed tasks' Verification blocks are not edited to clear the ratchet

- **Chose:** repair the one uncontrolled leg in the repairable stratum (T-590:344) and leave the
  eight in `.tasks/completed/` untouched. The ratchet therefore stays red at 89 and this task
  does NOT reach its own AC 5/AC 6.
- **Why:** a completed task's `## Verification` block records what was verified at completion.
  P-011 ran those legs once, then; adding a control leg now would make the record assert a check
  that never executed. Editing eight of them would buy a green by falsifying eight records while
  leaving intact the reason the framework could not detect the problem — mitigation dressed as
  prevention (G-019). T-560 already ruled on this class in the baseline file's own comment:
  "NOT a backlog anyone committed to burning down — the great majority sit in completed tasks
  and are historical record." That ruling is followed, not overturned.
- **Rejected:** raising the baseline 78→89 (one keystroke, destroys the only instrument measuring
  this class, and the tool header states the sanctioned direction is down); using `--force` on the
  verification gate (not delegated); arguing the alarm away via the classifier defects — measured
  and refused, since the rise survives the repair at +9.

### 2026-09-03 — OPERATOR APPROVED option 1; implementation parked, not abandoned

- **Ruling:** the operator chose to re-scope the ratchet to the **active** stratum (baseline
  measured at the arming commit) and hold the completed stratum as a reported, tamper-evident
  count that fails if it ever FALLS — a fall meaning history was rewritten. This supersedes the
  "reported, not patched" decision below for the census; that decision stands as the record of
  why it was not done under agent initiative.
- **State:** implementation was begun and then reverted to HEAD (hash equality verified) when
  EWCR was made the priority mid-session. A half-wired governance instrument is worse than an
  unmodified red one, so the tree was left clean rather than partially migrated. The census is
  byte-identical to its committed state and still correctly red at 89.
- **What the implementation needs, so it is not re-derived:** the three classifier repairs
  (dotfile-only redirect; same-line positive grep as EXISTENCE, with QUOTE-AWARE `&&`/`||`/`;`
  splitting — a naive split corrupts T-501's pattern, which itself contains `||`); the
  comparand-scoped `zero_from_search`; a two-value baseline file; and teeth legs for BOTH
  directions — the active ratchet biting upward, and the completed floor biting downward.
  Measured targets: active 8 → **7** after T-590's repair; completed floor 77.

### 2026-09-02 — the classifier defects are reported, not silently patched

- **Chose:** document the three defects with evidence and leave `tools/_t560-absence-assertion-census.py`
  byte-identical under this task. The repaired classifier exists only as a scratchpad measurement probe.
- **Why:** AC 5 as written forbids changing the census, and it was written before measurement. The
  honest response to an AC whose premise measurement falsified is to surface the conflict, not to
  rewrite the AC into something that passes. Changing what a governance instrument counts is also
  the "widen the gate until it goes green" class even when each individual change is defensible —
  and here the changes are entangled with a population redesign that alters what the ratchet
  enforces. That is the operator's call.
- **Rejected:** patching the census inside this task (would have moved 90→85 and looked like
  progress while the +9 finding — the thing that actually matters — went unstated).

### 2026-09-02 — per-assertion disposition of the 12

- **1 repaired:** T-590:344 — added a sibling leg grepping the same alternation in
  `cannot-represent-yet.md`, where it IS present. This is the PATTERN route the census docstring
  names, and it is now credited as PATTERN by the **shipped** classifier: 90 → 89, no tool change.
- **3 were never uncontrolled** (classifier defects, evidence in RCA): T-606:206, T-606:209, T-592:205.
- **8 are in the frozen stratum** and are ruled out of bounds above: T-501:296, T-594:175,
  T-626:155, T-627:164, T-648:212, T-654:175, T-659:156, T-661:180. Of these, T-627 and T-626 do
  carry cross-leg controls (sibling legs positively grep the same file) — real controls the
  census cannot see because it only looks same-line for EXISTENCE; T-654, T-659, T-661 and T-648
  are genuinely uncontrolled and would be real findings if they were still editable.

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
     fw inception decide T-669 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T21:38:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-669-uncontrolled-absence-assertions-rose-78-.md
- **Context:** Initial task creation

### 2026-09-01T21:54:24Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
