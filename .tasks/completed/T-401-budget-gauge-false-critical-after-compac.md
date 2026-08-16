---
id: T-401
name: "Budget gauge false-critical after compaction: a foreign-model usage entry in
  the same transcript is read as this session's context size"
description: >
  budget-gate computed 341880 tokens (critical, BLOCK) on the first tool call of a
  post-compact session whose real size was 84629 (~28%). The gate refused all work
  in a session with ~72% headroom, immediately after a /compact performed to reclaim
  exactly that context.

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
created: 2026-08-09T07:39:33Z
last_update: '2026-08-16T14:33:34Z'
date_finished: 2026-08-09T07:52:32Z
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
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/budget-gate.sh,.agentic-framework/agents/context/checkpoint.sh,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/budget-gate.sh,.agentic-framework/agents/context/checkpoint.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-401: Budget gauge false-critical after compaction: a foreign-model usage entry in the same transcript is read as this session's context size

> **Title corrected mid-task.** It was filed as *"the summarization request's own usage entry is
> read as post-compact context size"* — my opening hypothesis, that `/compact`'s own summarization
> call (whose input is the entire pre-compact conversation) was landing at the boundary and being
> read as the result. The transcript falsified it: the poisoning entry is **18 minutes after** the
> boundary, on a **different model**, and is a **cache-priming call**, not a summarization. The
> filename slug still carries the old wording; the `name:` field is canonical. Recording this
> rather than silently overwriting it — a title that asserts the wrong cause is the defect T-365
> was filed about.

## Context

On the first tool call of a post-compact session, `budget-gate.sh` computed **341880 tokens
(critical → exit 2, BLOCK)** for a session whose real size was **84629 (~28%)**, measured by the
framework's own sanctioned probe (`checkpoint.sh status`). The gate refused all work in a session
with ~72% headroom, immediately after a `/compact` performed to reclaim exactly that context.

The two gauges disagree by **4×** about the same session at the same moment.

**Why this is worse than a wrong number:** the false-critical is a *window*, not a steady state.
It fires while the poisoned `.budget-status` is fresh (`< STATUS_MAX_AGE`, 90s), then self-clears
once the entry ages out and the slow path re-reads. So it blocks precisely the *resumption* work
at the start of a post-compact session — and by the time anyone investigates, the gauge reads
healthy and the evidence is gone. It is a check that erases its own symptom.

Under a plain `claude` launch this is the documented recovery path failing at the one moment it
exists for: `/compact` is what the gate's own block message *tells you to run* ("run '/compact'
before you hit critical"), and running it produces a session the gate then refuses to let work.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Root cause established by direct transcript evidence, not inference.** Identify which
      usage entry supplies 341880 and where it sits relative to (a) the `compact_boundary` marker
      T-2322 keys its reset on, and (b) the `.session-start-ts` value T-1088 filters on. Both
      defenses are present and both were defeated — the fix must name *how*, or it is a guess.
      → Entry dumped field-for-field; see `## RCA`. It post-dates BOTH defenses.
- [x] **The measured divergence is explained.** `checkpoint.sh status` returned 84629 from the
      same session that `budget-gate.sh` scored 341880. Both scan a transcript with near-identical
      Python. Establish whether they read different *files* or the same file differently.
      An unexplained 4× gap between two copies of one algorithm is the actual defect surface.
      → Same file, **different instants**: the gate read at 07:36:33Z when the foreign entry was
      the newest; my probe read at 07:37:28Z after real turns had landed. Not a code difference.
- [x] **Fix applied to every gauge that shares the flaw, not just the one that blocked.**
      `get_context_tokens()` (checkpoint.sh:100-134) carries the T-1088 filter but NOT the
      T-2322 `compact_boundary` reset that budget-gate.sh:309-311 has. Two copies of one
      algorithm drifted; fixing only the copy that happened to fire leaves the other latent.
      → Both now call `lib/context_tokens.py`. No inline copy remains in either file.
- [x] **Regression teeth (T-359 style): prove the check still goes RED.** A fixture transcript
      replaying this exact shape must score `ok` after the fix AND a transcript representing a
      genuinely-oversized session must still score `critical`. A fix that merely lowers the
      number everywhere has removed the gate, not repaired it.
      → `web/test_context_tokens.py` 14/14, incl. `test_old_algorithm_still_fails_the_incident_fixture`
      (asserts the PRE-FIX algorithm still returns 341880 on the fixture, so the fixture cannot
      quietly stop reproducing the bug). End-to-end: oversized fixture still `exit=2 critical`.
- [x] **The allow-regex substring flaw is recorded** (separate finding, see `## Decisions`):
      budget-gate.sh:152 matches the allowlist anywhere in the command string, so a compound
      command like `cat secrets ; git log` is classified `allowed` wholesale. This is how my
      own first call slipped the gate. File separately if it warrants its own fix — do not
      silently widen this task's scope to cover it.
      → Filed as **T-402**. Not fixed here.

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

(cd .agentic-framework && python3 -m pytest web/test_context_tokens.py -q)
(cd .agentic-framework && python3 -m pytest web/test_context_tokens.py::test_old_algorithm_still_fails_the_incident_fixture -q)
(cd .agentic-framework && python3 -m pytest web/test_costs.py -q)
test -z "$(grep -l 'cache_read_input_tokens' .agentic-framework/agents/context/budget-gate.sh .agentic-framework/agents/context/checkpoint.sh 2>/dev/null)"
grep -q "lib/context_tokens.py" .agentic-framework/agents/context/budget-gate.sh && grep -q "lib/context_tokens.py" .agentic-framework/agents/context/checkpoint.sh
python3 -c "import sys; sys.path.insert(0,'.agentic-framework'); from lib.context_tokens import MIN_ENTRIES_TO_JUDGE; sys.exit(0 if MIN_ENTRIES_TO_JUDGE == 2 else 1)"
bash -n .agentic-framework/agents/context/budget-gate.sh
bash -n .agentic-framework/agents/context/checkpoint.sh

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

**Symptom:** On the first tool calls of a post-compact session, `budget-gate.sh` reported
341880 tokens (critical) and blocked every non-allowlisted tool call. The session's real size
was 84629 (~28%), per the framework's own probe. `/compact` — the action the gate's own block
message recommends — produced a session the gate then refused to let work.

**Root cause:** The gauge takes the last usage entry in the transcript as "my context size".
This entry was in the transcript, verbatim:

```
timestamp   2026-08-09T07:26:21.446Z   (18 min AFTER the compact_boundary at 07:08:13)
model       claude-opus-4-8            (the session runs claude-opus-5)
isSidechain False                      (not a subagent)
sessionId   500d44d9-…                 (genuinely this session's file)
usage       input_tokens=2, cache_creation_input_tokens=322661,
            cache_read_input_tokens=19217, output_tokens=347
content[0]  ''                         (empty)
```

`input_tokens=2` with a 322k **one-hour cache write**: a cache-priming call on a *different
model*, logged into this session's transcript. Its prompt genuinely was 341880 tokens, so the
arithmetic was never wrong — the **entry selection** was. Model census for the post-compact
window: `claude-opus-5` n=43 (72268…106228), `claude-opus-4-8` n=1 (341880), `<synthetic>` n=1.

**Why structurally allowed:** Three defenses existed and all three missed it, because **all
three filter by position in the log** and this entry is legitimately positioned —
T-2322's `compact_boundary` reset (entry is 18 min *after* the boundary), T-1088's
`.session-start-ts` filter (entry is *after* session start), and the `<synthetic>` skip (it is
a real model). Position tells you *when* a call happened; it cannot tell you *whose
conversation* it belonged to. Nothing in the gauge had ever needed to ask that question,
because until a second model started writing into the same transcript, every entry belonged to
the conversation by construction.

Two aggravating factors:
1. **The defect erases its own evidence.** The poisoned `.budget-status` blocks only while it
   is fresh (<`STATUS_MAX_AGE`, 90s); then the slow path re-reads, real turns have landed, and
   the gauge reads healthy. So it blocks precisely the *resumption* work at the start of a
   post-compact session and looks fine by the time anyone investigates.
2. **It armed the auto-restart signal.** The block path calls `_write_restart_signal`, and it
   fired for real: `{"timestamp":"2026-08-09T07:36:55Z","reason":"critical_budget_gate_block",
   "tokens":341880}`. Under `claude-fw` supervision that terminates and restarts a *healthy*
   session — and the same foreign entry is still newest after the restart, so it re-arms
   immediately, bounded only by the max-5-consecutive-restarts safety.

**Prevention:** `lib/context_tokens.py` — one implementation, both callers — scopes entries to
the session's own model (frequency, not "the newest entry's model": in this incident the
foreign entry *was* the newest, so a newest-keyed rule reproduces the bug). Below two
conversational entries it returns 0 rather than guess, which is the half that actually covers
the measured incident: at 07:36:33Z there was no conversation volume to scope against.
Regression teeth in `web/test_context_tokens.py` pin both directions — the incident shape must
not block, a genuinely oversized session must still block — and one test asserts the *pre-fix*
algorithm still fails the fixture, so the fixture cannot silently stop reproducing the bug.

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

### 2026-08-09 — Scope by model identity, not by tightening the formula

- **Chose:** Keep the token formula exactly as it was and change which entry is selected.
- **Why:** The poisoning entry's prompt genuinely *was* 341880 tokens. The sum is correct; the
  entry simply is not this conversation. Any formula-level guard (e.g. "ignore entries with
  tiny `input_tokens` and huge `cache_creation`") would be a heuristic aimed at a symptom, and
  would also misfire on ordinary turns, where a small `input_tokens` with a large cached prefix
  is the normal shape.
- **Rejected:** Excluding `cache_creation_input_tokens` from the sum — it is genuinely part of
  the prompt on a normal turn, so this would under-report every session to fix one entry.

### 2026-08-09 — Frequency, not "the model of the most recent entry"

- **Chose:** The conversation is the model with the most entries since the last boundary.
- **Why:** In this incident the foreign entry **was** the most recent one. A rule that trusts
  the newest entry to identify the conversation reproduces the exact bug it is meant to fix.
- **Rejected:** Reading the session model from the hook's stdin payload — it would be exact,
  but it is not guaranteed present across Claude Code versions, and a gauge that silently
  degrades to "no scoping" when a field disappears is how this class of defect returns.

### 2026-08-09 — Fail open below two conversational entries

- **Chose:** Return 0 (→ `ok`) when fewer than two in-scope entries exist.
- **Why:** This is the half that actually covers the measured incident — at 07:36:33Z there was
  no conversation volume to scope against, so frequency alone is a coin-flip exactly at the
  opening calls of a resumed session. A session with under two turns since the last boundary
  cannot have filled its context, so fail-open is also the physically correct direction.
- **Cost, stated plainly:** a genuinely huge resumed session goes unblocked for its first call
  or two before the gauge catches up. That is the right trade against the observed alternative,
  which was a healthy session unable to work at all — and, under `claude-fw`, restarted.

### 2026-08-09 — One implementation, two callers (Level C)

- **Chose:** Extract `lib/context_tokens.py` rather than patch both inline copies.
- **Why:** The two copies had already drifted once — budget-gate gained T-2322, checkpoint.sh
  never did — so the PostToolUse gauge was silently a version behind the PreToolUse gate it
  backs up. Patching both leaves the drift class alive; there would simply be a third divergence
  later. This is the Level C rung: fix the tooling, not the instance.
- **Explicitly NOT unified:** `lib/costs.sh`, `web/blueprints/costs.py`, `web/test_costs.py`
  sum the same three fields for **cost**, where a cache-priming call on another model genuinely
  did cost money and belongs in the total. Same arithmetic, opposite correct answer. A future
  "consistency" refactor that routes cost accounting through this helper would be a regression;
  the helper's docstring says so at the top.

### 2026-08-09 — Second finding split out rather than absorbed

- **Chose:** File the allow-regex substring flaw as **T-402**, fix nothing about it here.
- **Why:** One bug, one task. It has a different root cause (command classification, not token
  measurement) and a different blast radius (it is a gate-*evasion* vector, not a false alarm).
  Folding it in would have made this task's RCA answer two questions and traceability answer
  neither.

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

### 2026-08-09T07:39:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-401-budget-gauge-false-critical-after-compac.md
- **Context:** Initial task creation

### 2026-08-09T07:39:42Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-36fc5f7d
- **Timestamp:** 2026-08-09T07:52:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T07:52:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
