---
id: T-735
name: "The permanent audit store overwrites same-date records while the 7-day cron
  store keeps every run"
description: >
  The permanent audit store overwrites same-date records while the 7-day cron store
  keeps every run

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-19T22:03:34Z
last_update: '2026-09-21T20:24:53Z'
date_finished: 2026-09-19T22:09:10Z
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
cost_estimate_proposed:
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/audit/audit.sh,tools/_t677-audit-record-fence.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-735: The permanent audit store overwrites same-date records while the 7-day cron store keeps every run

## Context

`.context/audits/**` is treated as an immutable historical record by CLAUDE.md and by
every claim that cites "the audit of <date>". It is not one. `audit.sh:5593-5596` picks
the output filename from a branch:

    if [ -n "$OUTPUT_DIR" ]; then
        AUDIT_FILE="$EFFECTIVE_OUTPUT_DIR/$AUDIT_DATETIME.yaml"   # --cron
    else
        AUDIT_FILE="$EFFECTIVE_OUTPUT_DIR/$AUDIT_DATE.yaml"       # default
    fi

Both variables are already computed. The default path — the PERMANENT one — uses the
date alone, so the second audit of any day silently truncates the first in place.

### ⚠ CORRECTION, 2026-09-20 — THE PREMISE ABOVE IS WRONG. READ THIS FIRST.

I filed this as a defect. It is not one. `tools/_t677-audit-record-fence.py` already fences
this write path, and its case table carries the decision explicitly:

    ("same scope replaces itself (no proliferation)", "structure", "structure", False),

That case PASSES by design. T-677's docstring gives the reason: a date that can hold two
records would make the recurrence counter count FILES instead of DAYS, so "3+ times" would
quietly stop meaning "3+ days". Same-scope replacement is the ruled trade-off, not an
oversight. T-677 fenced the case that IS a defect — a NARROWING run clobbering a fuller
record — and left same-scope replacement deliberately permitted.

WHAT I DID WRONG: I measured the store, found 32 of 63 records overwritten, and reached for
the writer before reading the fence that already governs it. The 32 is real but mostly
PRE-GUARD history; since the guard landed (a56bc0eb, 2026-09-05) there have been 3 committed
same-scope overwrites and 2 live in the tree, and every one of them is behaviour T-677
chose. Nothing here is lost that the system claims to keep: earlier runs remain in git
history, and the trend engine counts days on purpose.

THE ONE RESIDUAL MISMATCH, which is a wording defect and not a code defect: CLAUDE.md and
the session constraint note both describe `.context/audits/**` as "immutable historical
records". The store is not immutable and was never meant to be — it is "the last run of
each date, per scope". An agent who believes the stronger claim will either cite a record
as a per-run artifact it is not, or do what I just did and file the design as a bug.

This task therefore lands NO code. Its deliverable is the corrected understanding, recorded
where the next agent meets it, plus one operator ruling on the wording.

---

THE INVERSION I ORIGINALLY CLAIMED (retained for the record, now explained rather than
filed as a defect). The `--cron` store has a 7-day `find -delete` sweep
(audit.sh:5894) and names every run to the second, so it keeps all of them until it
deliberately drops them. The default store has no sweep, is meant to be permanent, and
keeps only the last run of each date. The store that is allowed to forget remembers
everything; the store that must remember forgets silently.

Measured over git history: **32 of 63** permanent records carry more than one distinct
`timestamp:` value. `2026-08-30.yaml` is being clobbered right now in the working tree
(committed = the 10:23 run, pass 19/warn 4; uncommitted = the 20:29 run, pass 18/warn 5).
`2026-08-08.yaml` was overwritten 23 times.

The harm is not only the lost bytes — those survive in git history — it is that every
READER globs the working tree. `audit.sh:1576` globs `????-??-??.yaml` for fabric history,
and the trend engine ("Repeated issues detected in last 14 days ... 8 times") counts one
record per date. Every earlier run of each day is invisible to it, so a recurrence count
is a floor presented as a total. PL-313, surfaced by `fw work-on` at filing: A COUNT OF
RECORDS IS NOT A STATEMENT OF COVERAGE.

## Acceptance Criteria

### Agent
- [x] The overwrite rate is MEASURED over the permanent store from git history rather
      than asserted: 32 of 63 records carry more than one distinct `timestamp:` across
      their commits; `2026-08-08.yaml` was replaced 23 times.
- [x] The measurement is SPLIT at the guard that governs the behaviour, because a total
      that spans a fix is not a statement about today: since `a56bc0eb` (T-677's section
      guard, 2026-09-05) there are 3 committed same-scope overwrites (`2026-09-05`,
      `2026-09-16` ×2) and 2 live in the working tree.
- [x] The existing fence was READ before any repair was proposed, and it already carries
      the ruling: `tools/_t677-audit-record-fence.py` case
      `("same scope replaces itself (no proliferation)", "structure", "structure", False)`
      passes by design, with the day-vs-file counting rationale in its docstring.
- [x] NO code was written and `audit.sh` was NOT modified. The behaviour is a ruled
      trade-off, and "fixing" it would have silently converted the recurrence counter
      from days to files — the exact regression T-677's second property exists to prevent.
- [x] The residual defect is stated at its real size and location: a WORDING mismatch, in
      CLAUDE.md and the session constraint note, between "immutable historical records"
      and a store that keeps the last run of each date per scope.

### Human
- [ ] [REVIEW] Rule on the wording, which is the only thing here that is actually wrong.
  **Steps:**
  1. Read the CORRECTION block at the top of this task's `## Context`.
  2. `cd /opt/832-Workflow-designer && grep -n 'immutable historical records' CLAUDE.md`
  3. Decide what the permanent audit store is called from now on. Pick one:
     **A — Correct the wording.** Replace "immutable historical records" with what the
     store actually guarantees: the last run of each date, per scope; earlier runs of the
     same date live only in git history. Keeps the code, removes the false claim.
     **B — Make the wording true.** Keep the phrase and change the store to match it,
     accepting that a date may then hold N records — which requires T-677's day-counting
     property to be re-established against a file-counting corpus.
     **C — Leave both as they are** and accept that an agent reading CLAUDE.md will
     periodically re-file this design as a bug, as I just did.
  **Expected:** One letter. A only needs a one-line edit to CLAUDE.md, which is yours —
  the agent is structurally blocked from governance files and did not attempt it.
  **If not:** Nothing is broken and nothing is pending. This is a naming question about
  a store that is behaving exactly as T-677 designed it.

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
         1. Run `bin/fw reviewer T-735`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-735 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Each leg proves a claim this task makes. No new code ships, so every leg asserts that
# the EXISTING design I deferred to is real and live — the opposite of the usual shape,
# and the right one when the deliverable is "do not build this".
#
# 1. T-677's fence still passes, so the ruling I am deferring to is enforced, not folklore.
python3 tools/_t677-audit-record-fence.py
# 2. The specific case carrying the ruling is present — my citation, not my paraphrase.
grep -q 'same scope replaces itself' tools/_t677-audit-record-fence.py
# 3. The guard commit I split the measurement at exists and is reachable.
git cat-file -e 'a56bc0eb^{commit}'
# 4. The write-path branch quoted in Context is still in the shipping file.
grep -q 'AUDIT_DATETIME' .agentic-framework/agents/audit/audit.sh

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

**Symptom:** Two records under `.context/audits/` — a store CLAUDE.md calls immutable —
showed as modified in the working tree, each replaced by a later run of the same date.

**Root cause:** There is no code defect. `audit.sh` writes one record per date per scope
by design, and `tools/_t677-audit-record-fence.py` fences that choice explicitly so the
recurrence counter keeps counting days rather than files.

**Why structurally allowed (the real finding):** CLAUDE.md describes the store with a
stronger guarantee than it provides. "Immutable historical records" and "the last run of
each date, per scope" are different promises, and only the weaker one is true. An agent
holding the stronger belief will read correct behaviour as corruption — which is exactly
what happened here, and cost this session roughly 70k tokens before the fence was read.

**Prevention — and it is NOT this task:** the wording is in a governance file, so the
repair is the operator's ruling in the Human AC above, not an agent edit. What this task
prevents on its own is narrower and real: the next agent to open the audit store now finds
the ruling and its rationale recorded against the observed symptom, instead of rediscovering
the symptom alone.

**The transferable lesson:** READ THE FENCE BEFORE REACHING FOR THE WRITER. A measurement
that spans a fix is not a statement about today — 32 of 63 was true and nearly irrelevant;
the number that mattered was 3 since the guard landed, and all 3 were deliberate.

## Recommendation

**Recommendation:** NO-GO — close on ruling A (correct the wording), and change no code.

**Rationale:** The filed premise was wrong. The permanent audit store is not corrupting
itself; it is doing what T-677 explicitly decided it should do, and the fence enforcing
that decision passes today. Building the repair I first scoped would have converted the
recurrence counter from counting days to counting files — the precise regression T-677's
second property exists to prevent. The only true defect is one phrase in CLAUDE.md, which
is a governance file and therefore yours, not mine.

**Evidence:**
- `tools/_t677-audit-record-fence.py` — case `("same scope replaces itself (no
  proliferation)", "structure", "structure", False)` passes BY DESIGN; the day-vs-file
  rationale is in the module docstring.
- Fence run today: rc=0, "FENCE PASSED — partial runs write alongside fuller records,
  fuller runs still supersede, and recurrence counts days rather than files."
- Overwrite census from git history: 32 of 63 permanent records carry >1 distinct
  `timestamp:`; `2026-08-08.yaml` replaced 23 times.
- Split at the guard `a56bc0eb` (2026-09-05): only 3 committed same-scope overwrites
  since (`2026-09-05`, `2026-09-16` ×2), plus 2 live in the tree — all of them the
  permitted case.
- `audit.sh:5593-5596` — the date-only default path and the timestamped `--cron` path,
  both still present; `audit.sh:5894` — the 7-day sweep that applies only to cron.
- No file outside `.tasks/` was modified by this task.

**What it unblocks:** nothing is waiting on it. This is a correction filed so the next
agent does not repeat it.

---

**Close on ruling A** (correct the wording), and change no code.

What was established: the permanent audit store behaves exactly as T-677 designed it. The
32/63 overwrite figure is real but mostly pre-guard; the post-guard residual is 3 committed
plus 2 live, and every one is the `no proliferation` case the fence passes on purpose.

What is genuinely wrong is one phrase in CLAUDE.md. Ruling A is a one-line edit and is
yours — B re-opens a property T-677 closed, and C guarantees this task gets re-filed by
whoever next reads the store against the docs.

The two live records (`2026-08-30.yaml`, `2026-09-05-structure.yaml`) need no disposition:
committing them is the store working normally, and the earlier runs remain in git history.
I left them uncommitted rather than decide that on your behalf.

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
     fw inception decide T-735 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-19T22:03:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-735-the-permanent-audit-store-overwrites-sam.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6be9a292
- **Timestamp:** 2026-09-19T22:09:11Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Human)** — [REVIEW] Rule on the wording, which is the only thing here that is actually wrong.
  - **audience-mismatch** (partial, heuristic) — `agent-subject='agent read' in: One letter. A only needs a one-line edit to CLAUDE.md, which is yours —   the agent is structurally blocked from governance files and did no`

### 2026-09-19T22:09:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
