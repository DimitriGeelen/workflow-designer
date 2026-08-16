---
id: T-404
name: "check-active-task blocks read-only commands: drifted redirect predicate and
  regex over unparsed shell"
description: >
  has_bash_write_pattern runs before the safe-command allowlist and mis-classifies
  read-only commands as writes. Two defects: (1) the echo/printf branch at safe-commands.sh:221
  uses a redirect regex lacking the stderr and fd-dup exclusions its sibling at line
  252 has - copy drift, so stderr-suppression reads as a file write; (2) has_bash_write_pattern
  regexes the raw command string, so redirect operators inside a QUOTED argument count
  as real redirects. Consequence: compaction nulls focus, and the /resume skill documented
  Step 5 command uses stderr-suppression, so the framework post-compaction recovery
  command is blocked by the framework own gate. Fifth instance of the self-deadlock
  class this file already names (T-2052, T-2054, T-390) - including this task creation,
  blocked because its description quoted the operators.

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
created: 2026-08-09T08:19:08Z
last_update: '2026-08-16T13:57:22Z'
date_finished: 2026-08-09T08:30:26Z
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
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.agentic-framework/agents/context/lib/safe-commands.sh,.context/project/learnings.yaml,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-404: check-active-task blocks read-only commands: drifted redirect predicate and regex over unparsed shell

## Context

The Bash task gate decides "is this command a write?" with a character-level regex over
the raw command string. It over-approximates in two independent ways, and the
over-approximation is invisible while focus is set — it only changes an outcome when
focus is null, which is precisely the state compaction creates.

**This is not a new discovery.** `PL-025` (T-170, 2026-07-10) recorded it 30 days ago,
named both defects, and prescribed the remedy. Its `application:` field still reads `TBD`.
The knowledge was captured correctly and changed nothing. That is the more serious finding
and it is what the RCA below is about.

PL-025 verbatim:

> Detecting shell write-intent with a character-level regex over-approximates: a redirect
> operator only acts OUTSIDE quotes and a redirect to a /dev sink is a discard, not a
> source write. has_bash_write_pattern flagged >/dev/null and quoted <T> as writes. When a
> heuristic reasons about raw characters instead of shell semantics, pin the
> true-positive/false-positive boundary with a test corpus (genuine writes must stay
> caught, benign forms must pass) so over-broad matches surface before they block real
> commands.

## Acceptance Criteria

### Agent
- [x] Redirect operators appearing inside single- or double-quoted arguments are no longer
      counted as writes (PL-025 clause 1: "a redirect operator only acts OUTSIDE quotes")
- [x] A redirect whose target is `/dev/null` is no longer counted as a write, in stdout,
      stderr and combined forms (PL-025 clause 2: "a redirect to a /dev sink is a discard,
      not a source write")
- [x] Genuine writes are still caught — `cmd > f`, `cmd >> f`, `tee f`, `sed -i`, heredoc,
      `rm` — proven by the corpus, not by inspection
- [x] One redirect predicate, one implementation: the drifted duplicate regex in the
      `echo|printf` branch of `is_bash_safe_command` is gone (Level C — the same
      copy-drift remedy T-401 applied to the budget gauges)
- [x] A true-positive/false-positive corpus exists and is green — PL-025's own prescribed
      remedy, applied at last (37/37, `web/test_safe_commands.py`)
- [x] The three commands this session actually blocked are in the corpus as must-pass
      cases (stderr-suppression after `echo`; quoted `>>` in a grep pattern; `count>=50`
      inside a `python3 -c` script)
- [x] End-to-end through `check-active-task.sh` with focus null: a read-only command
      carrying stderr-suppression is ALLOWED, and a genuine source write is still BLOCKED
      (repaired, not removed) — `tools/t404-gate-e2e.sh`, 8/8
- [x] `PL-025.application` no longer reads `TBD` and references this task

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

(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py -q)
(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py::test_genuine_writes_are_still_caught -q)
bash tools/t404-gate-e2e.sh
bash -n .agentic-framework/agents/context/lib/safe-commands.sh
bash -n .agentic-framework/agents/context/check-active-task.sh
# Comment lines excluded on purpose: the fix quotes the retired regex verbatim in a
# comment so the next reader knows what was wrong. Only executable lines can reintroduce it.
python3 -c "import sys; code='\n'.join(l for l in open('.agentic-framework/agents/context/lib/safe-commands.sh').read().splitlines() if not l.lstrip().startswith('#')); sys.exit(0 if '[^>]>[^>]' not in code else 1)"
python3 -c "import sys,yaml; d=yaml.safe_load(open('.context/project/learnings.yaml')); e=[x for x in (d.get('learnings') or d) if isinstance(x,dict) and x.get('id')=='PL-025']; sys.exit(0 if e and 'T-404' in str(e[0].get('application','')) else 1)"

## RCA

**Symptom:** With focus null, the task gate blocked read-only commands — `cat f 2>/dev/null`,
a `grep` whose *search pattern* contained `>>`, and a `python3 -c` containing `count>=50`.
It also blocked `fw task create` for this very task, because the description quoted the
operators. Five self-blocks in one resume sequence.

**Root cause:** two independent over-approximations in one predicate.

1. `has_bash_write_pattern` (safe-commands.sh:252) regexes the *raw* command string, so a
   redirect operator inside a quoted argument is indistinguishable from a real redirect.
   Shell semantics say an operator inside quotes is data; the regex cannot see quotes.
2. The `echo|printf` branch of `is_bash_safe_command` (safe-commands.sh:221) carries its
   **own copy** of the redirect regex, `[^>]>[^>]|>>`, which lacks the `2`/`&` exclusions
   its sibling at line 252 has. Copy drift: line 252 was hardened, line 221 never was. So
   `2>/dev/null` — stderr suppression, the most common read-only idiom in the codebase —
   is read as a file write.

Additionally, a redirect to `/dev/null` is a discard: it creates no artifact and writes
nothing, yet both copies count it.

**Why structurally allowed:** three compounding reasons, in increasing severity.

- `has_bash_write_pattern` runs BEFORE the allowlist (check-active-task.sh:92), by design
  — "even safe commands with redirects are writes". So a false write verdict overrides the
  allowlist entirely; being `grep` or `cat` cannot save you.
- The defect is **state-conditional and therefore self-hiding**: it changes an outcome only
  when focus is null. In steady-state work focus is set, the gate passes for other reasons,
  and the misclassification is never observed. This is the same shape as T-401 (a
  false-positive that self-clears is nearly undetectable) and the same shape as AEF's
  OBS-205 — the guard's *success* is what hides it.
- **The learning already existed and was never applied.** PL-025 recorded both defects on
  2026-07-10 with `application: TBD`. There is no mechanism that ever revisits a learning
  whose application is TBD, so a correct, specific, actionable finding sat inert for 30
  days while the defect it described stayed live. Capture is not application.

**Prevention:** PL-025 already named it — pin the true-positive/false-positive boundary
with a corpus. That corpus (`web/test_safe_commands.py`) is the prevention: it fails if a
benign form starts blocking OR if a genuine write stops being caught, so the next person to
touch the regex learns immediately rather than 30 days later. The Level C consolidation
(one redirect predicate, not two) removes the drift surface that produced defect 2.

The learning-application gap is a separate, larger problem and is registered separately —
fixing this predicate does not fix the mechanism that let PL-025 rot.

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

### 2026-08-09 — quote-stripping applied to redirects only, not to verbs

- **Chose:** judge redirect operators on the quote-stripped command, but keep the
  destructive/writing VERB checks (`rm`, `tee`, `sed -i`, heredoc) scanning the raw string.
- **Why:** the two failure directions are not symmetric. A false positive on a verb costs
  "you need an active task". A false negative would let `sh -c "rm -rf x"` — verb inside
  quotes — past the gate. For operators the observed harm was all in the false-positive
  direction; for verbs the unobserved harm is all in the false-negative direction.
- **Rejected:** applying quote-stripping uniformly. Cleaner to describe, but it silently
  widens the destructive-verb hole to buy a rarer convenience. The accepted price is that
  `grep -n "rm" f` still reads as a write; that is pinned by a test so it cannot drift into
  looking like an accident.

### 2026-08-09 — the /resume Step 5 command is NOT fully unblocked by this fix

- **Chose:** scope T-404 to the redirect predicate and file the remaining blocker separately.
- **Why:** measured, not assumed. After the fix, the `/resume` Step 5 command shape reports
  `write=no` (this defect is gone) but `safe=no` — it is still blocked, by a different
  mechanism: the T-1908 env-prefix stripper matches `WURL=$(cat` as a complete `KEY=VAL`
  prefix, then takes the next word `.context/working/watchtower.url` as the command name,
  which matches nothing in the allowlist. Different code path, different root cause.
- **Rejected:** widening T-404 to cover it. One bug = one task; and claiming T-404 "fixes
  the resume deadlock" would be false. Filed as its own task.

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

### 2026-08-09T08:19:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-404-check-active-task-blocks-read-only-comma.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2e7fc094
- **Timestamp:** 2026-08-09T08:30:32Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T08:30:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
