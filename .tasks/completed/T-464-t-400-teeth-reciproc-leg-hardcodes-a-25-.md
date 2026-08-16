---
id: T-464
name: "T-400 teeth RECIPROC leg hardcodes a 25-entry population the register outgrew"
description: >
  T-400 teeth RECIPROC leg hardcodes a 25-entry population the register outgrew

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
created: 2026-08-12T18:37:58Z
last_update: '2026-08-16T12:34:00Z'
date_finished: 2026-08-12T18:44:41Z
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
  - ts: '2026-08-16T12:34:00Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-464: T-400 teeth RECIPROC leg hardcodes a 25-entry population the register outgrew

## Context

`tools/_t400-schema-teeth.sh` RECIPROC leg asserts the real register passes AND that
it passed over the expected population — the anti-vacuity check, and the right idea.
But it spells the population as the literal string `schema ok: 25 entries`. The
register now holds 34. So the leg has been failing on a stale literal, and would have
gone on failing every time a gap was registered.

Found while completing T-463 (which fixed the register's own schema check). The leg
was red BEFORE that fix too, via the other branch — the register genuinely failed —
so T-463 moved it from branch 1 to branch 2 without the count ever being the visible
cause. Both reds look identical from outside the script: `TEETH FAIL — 1 leg(s)`.

The fix is not "update 25 to 34" — that re-arms the same trap for gap 35. Per PL-158
(a guard must DERIVE its checked set from the authority it guards, not restate it),
the expected population must be derived. The subtlety: deriving it from the subject's
own parser would make the leg vacuous — it would compare the subject to itself and
pass over a truncated read, which is the exact hazard the leg's own failure text names.
So the derivation has to be INDEPENDENT of `concerns-schema.py`.

## Acceptance Criteria

### Agent
- [x] The RECIPROC leg carries no hardcoded entry-count literal — the expected
      population is computed from the register at run time. Proven by grep over
      non-comment lines only: the sole surviving `NN entries` string in the file is
      the dated comment recording what the literal used to be.
- [x] The derivation is INDEPENDENT of the subject. It does not invoke
      `concerns-schema.py`, does not parse its stdout for the count, and does not
      reuse the subject's `entries()` traversal — it counts column-0 `- id:` lines
      textually, with no YAML parser in the path. The inline comment names why.
- [x] The leg still has TEETH against truncation — and the mutation is applied to the
      SUBJECT, not the file. Truncating the register would move the subject's count
      and the derived count together and prove nothing; the hazard the leg names is a
      subject that reads FEWER entries than the register holds. `entries()` sliced to
      `[:5]` against an unchanged 34-entry register → leg FAILS, naming the population.
- [x] The leg TRACKS growth: one genuine entry appended → 35, leg stays green and
      reports 35. Both directions measured, plus a third: the historical `25` literal
      restored against 34 entries → red, so the reported defect was real and not an
      artefact of how it was found.
- [x] `tools/_t400-schema-teeth.sh` exits 0 over the live register — 10/10 legs, and
      the RECIPROC line prints the derived count (34) so the denominator is visible
      (PL-084).
- [x] Swept for other stale population literals: **49 harness files / 8280 lines**,
      one candidate found (`_t408-hygiene-teeth.sh:136` asserting `9999`), inspected
      and rejected — it is a port number in a fixture the harness itself writes four
      lines above, so it has an adjacent prompt to update and is not this class.
      `_t400`'s own `$legs/10` is left deliberately: the leg count changes only by
      editing this file, where the literal is visible; the register's count changes
      from outside it, which is the whole defect.
- [x] The proof is durable, not one-shot: `tools/_t464-derivation-probe.sh` runs all
      four mutations in a relocated `$TMP` root and asserts the live register's
      sha256 is unchanged (6/6 legs). A check that damages the artefact it inspects
      will eventually be run by someone who skips the restore.

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

# The harness itself. Its exit code is the verdict — no chaining, no context question.
bash tools/_t400-schema-teeth.sh
# The derivation proof: four mutations in a relocated root, plus a live-register
# integrity leg. Also a single-command verdict.
bash tools/_t464-derivation-probe.sh
# The literal is gone from the CODE. Comments may still quote it — the dated note that
# records what it used to be is the point, not a residue. So strip comments first.
grep -vE '^[[:space:]]*#' tools/_t400-schema-teeth.sh > /tmp/.t464-code.txt && ! grep -qE 'schema ok: [0-9]+ entries' /tmp/.t464-code.txt
# ...and the expectation is spelled as the variable, not merely absent as a literal.
# -F for the same reason as the line below: see the 2026-08-12 note under ## Updates.
grep -qF 'schema ok: $expect entries' tools/_t400-schema-teeth.sh
# The derivation does not ask the subject: the line that computes `expect` is a `grep -c`
# and does not mention $SUBJECT. -F (fixed string) on purpose — the pattern is full of
# regex metacharacters ($ ( ^) whose meaning differs between the agent shell's ugrep and
# the gate's GNU grep (G-037 axis 1). A fixed string has no such axis.
grep 'expect=' tools/_t400-schema-teeth.sh > /tmp/.t464-expect.txt && grep -qF 'expect="$(grep -c ' /tmp/.t464-expect.txt && ! grep -q 'SUBJECT' /tmp/.t464-expect.txt
# The abstention teeth still pass on _t400 now that its baseline verdict moved red->green
# (T-430's probe compares the unmodified verdict against a baseline; a suite going green
# is exactly the kind of change that could have broken it).
bash tools/_t430-abstention-teeth.sh tools/_t400-schema-teeth.sh

## RCA

**Symptom:** `tools/_t400-schema-teeth.sh` exited 1 with `TEETH FAIL — 1 leg(s) failed`.
The failing leg was RECIPROC, whose job is to prove the guard does not red on the live
register.

**Root cause:** the leg spelled its expected population as the literal string
`schema ok: 25 entries`. The register grew to 34. Two independent reds therefore shared
one message: before T-463 the register genuinely failed the schema check (branch 1),
and after T-463 fixed that, the stale literal took over (branch 2). From outside the
script both print the identical line, which is why fixing the first defect did not
reveal the second.

**Why structurally allowed:** the expected population changes from OUTSIDE the file that
asserts it. Registering a gap edits `.context/project/concerns.yaml`; nothing in that
act brings the author anywhere near `tools/_t400-schema-teeth.sh`. Nine consecutive gap
registrations each had a complete, correct reason not to look here. A literal is only
safe when the thing it restates cannot move without the literal coming into view.

Compounding it: nothing runs this harness. It has no hook, cron or audit caller — it is
invoked only from a task's `## Verification` block, and only for the task that wrote it.
So the red had no reporting surface at all between T-400 and T-463. That is G-035's
population (an instrument with no live caller), and it is the reason the interval was
measured in registrations rather than in minutes.

**Prevention:** the literal is replaced by a derivation, and the derivation is itself
proven in both directions by `tools/_t464-derivation-probe.sh` — because "it is derived
now" is a claim, and an unverified claim about a guard is worth exactly what an
unverified claim about a register field is worth (which is what G-027 established).
The probe fails if the expectation stops tracking growth, fails if it stops catching
truncation, and fails if it starts being derived from the subject it guards.

**Not prevented, and stated rather than implied:** the no-live-caller problem. This task
does not wire the harness into anything, so the next red here will still wait for a task
to run it. That is G-035's business, not a thing to fix quietly on the side of a
one-line literal.

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

### 2026-08-12T18:37:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-464-t-400-teeth-reciproc-leg-hardcodes-a-25-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1b1cc676
- **Timestamp:** 2026-08-12T18:44:52Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T18:44:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-08-12 — a G-037 axis-1 instance, found in this task's own Verification block

The leg asserting "the expectation is spelled as the variable" was originally written as
`grep -q 'schema ok: \$expect entries'`. It **passed the P-011 gate** and it **failed when
I replayed the same legs in my own tool shell**. Both runs were correct; the pattern means
two different things depending on which grep reads it.

Measured on a one-line fixture containing `schema ok: $expect entries`:

    grep (agent shell = ugrep 7.5.0)   bare $   -> rc 1, 0 matches   # anchors on mid-pattern $
    grep (agent shell = ugrep 7.5.0)   esc \$   -> rc 0, 1 match
    /usr/bin/grep (GNU grep 3.11)      bare $   -> rc 0, 1 match     # mid-pattern $ is literal
    /usr/bin/grep (GNU grep 3.11)      esc \$   -> rc 0, 1 match

`\$` is the form that agrees. The two runs disagreed only because replaying through
`eval` stripped the backslash, leaving a bare `$` — so the *same written line* reached
ugrep as an anchored pattern and GNU grep as a literal one.

Changed to `-qF`. A fixed string has no pattern language and therefore no axis. This is
the correct general remedy for G-037 axis 1 in verification blocks: **when the thing you
are matching is a literal containing regex metacharacters, do not escape it — stop
treating it as a regex.** Escaping is a per-metacharacter bet on which grep reads the
line; `-F` removes the bet.

Re-measured after the change: `grep -qF` returns rc 0 under both greps.

The AC this leg supports was already independently satisfied (leg 5 proves the derivation
is a `grep -c` that never names `$SUBJECT`), so no criterion's evidence rests on the
version that split.
