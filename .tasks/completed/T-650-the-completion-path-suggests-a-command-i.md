---
id: T-650
name: "the completion path suggests a command it then forbids (OBS-331)"
description: >
  the completion path suggests a command it then forbids (OBS-331)

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
created: 2026-08-31T12:34:20Z
last_update: 2026-08-31T12:44:07Z
date_finished: 2026-08-31T12:44:07Z
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

# T-650: the completion path suggests a command it then forbids (OBS-331)

## Context

`fw task update T-XXX --status work-completed` prints a LEARNING PROMPT —
`Consider: fw fix-learned T-XXX "what was learned"` (update-task.sh:2428) — and the
same transition nulls focus. With focus null, check-active-task.sh refuses
`fw fix-learned` outright. The tool contradicts its own advice one line later.

The decisive fact is not the deadlock, it is what the gate is discriminating on.
`fw fix-learned` is a **pure alias**: bin/fw:5206 is
`exec "$AGENTS_DIR/context/context.sh" add-learning "$fl_text" --task "$fl_task" --source P-001`.
It is not *similar to* `fw context add-learning` — it **is** that command, reached by a
different spelling. And `context add-learning` is already exempt, on grounds recorded in
safe-commands.sh:225-236 (writes only under `.context/`, cannot author source, `--task`
preserves attribution). Every one of those grounds holds verbatim for the alias, because
it is the same process.

So the gate admits a program under one name and refuses the identical program under
another. That is the defect: an allowlist keyed to spelling rather than to effect. Unlike
G-047's commit case, no cadence avoids it — the prompt is what tells you to run it, and it
only prints after the transition that forbids it.

Fourth instance of the deadlock shape in this file, after T-2052 (`task create`),
T-2054 (`git commit`) and T-390 (`note`/`context add-*`/`handover`).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] With focus null, the REAL hook admits `fw fix-learned T-1 "text"` — driven via the
      same JSON-on-stdin contract Claude Code uses, against a throwaway PROJECT_ROOT.
- [x] The alias is exempt at BOTH sites, because they answer different questions:
      `_sc_simple_is_safe` (is this verb safe with no task?) and
      `_sc_is_framework_prose_verb` (does this verb take free prose that must not be read
      as shell?). `fix-learned` takes free prose in `$2`, so omitting the second site
      would admit the command and then trip on its own argument.
- [x] ADMIT controls still pass — `fw context add-learning "x" --task T-1`, `fw note "x"`,
      `git commit -m "T-1: x"`. **This half is not optional** (see Decisions): a mutant
      that fails to parse blocks everything and would otherwise look like a clean fix.
- [x] BLOCK controls still blocked with focus null: `rm -rf f`, `echo hi > f`,
      and `fw fix-learned T-1 "x" && rm -rf f` (prose exemption must not cover a
      destructive verb OUTSIDE the quotes — safe-commands.sh:504).
- [x] `tools/_t650-an-alias-is-the-command-it-aliases.sh` passes, and its teeth leg
      reverts exactly the two tokens this fix introduces and shows the admit legs go red.
- [x] No regression: `tools/_t392-safelist-shadow-gate.py` and
      `.agentic-framework/web/test_safe_commands.py` still pass (the latter holds the
      perf contract `_sc_is_framework_prose_verb` runs under on EVERY Bash call).
- [x] OBS-331 flipped `pending` → `resolved` with `promoted_to: T-650`, and
      `.context/inbox.yaml` still parses at 142 entries.
      **AC corrected mid-task, recorded rather than quietly reworded:** this originally
      read "marked resolved with the commit ref". The inbox schema has no field for a
      commit — `promoted_to` is the link it can carry, and the task holds the ref. Writing
      an unsatisfiable AC and then inventing a field to satisfy it would have been worse
      than admitting the AC was over-specified against a schema I had not checked.

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

bash tools/_t650-an-alias-is-the-command-it-aliases.sh
python3 tools/_t392-safelist-shadow-gate.py
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q > /tmp/.t650-perf.out 2>&1 && grep -qE '[0-9]+ passed' /tmp/.t650-perf.out
bash -n .agentic-framework/agents/context/lib/safe-commands.sh

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

**Symptom:** Completing a task prints `Consider: fw fix-learned T-XXX "..."`, and running
that exact command immediately after returns `BLOCKED: No active task ... Policy: P-002`.
Measured 2026-08-31 straight after completing T-649.

**Root cause:** The no-task allowlist in safe-commands.sh enumerates *verb spellings*
(`note`, `context add-learning|add-pattern|add-decision`, `task create`, `handover`,
`git commit`). `fw fix-learned` execs `context.sh add-learning` — the same program with
the same writes — but its spelling is not on the list, so it is refused. The allowlist's
own stated justification is about EFFECT ("writes only under `.context/`, cannot author
source"); its implementation keys on NAME. Wherever those two diverge, a command is judged
by what it is called rather than by what it does.

**Why structurally allowed:** Nothing ties the two together. `fw fix-learned` was added as
an ergonomic shortcut (G-016) long after the exemption list, and no test asserts the
invariant "an alias is admitted exactly when its target is". The prompt suggesting it was
added in a third place again (update-task.sh). Three files each locally sensible; the
contradiction only exists in the path that crosses all three, which nothing walks. It is
also *invisible in green*: the gate never errors, it refuses — and a refusal at the very
end of a completed task reads as normal governance, not as a bug.

**Prevention:** `tools/_t650-an-alias-is-the-command-it-aliases.sh` drives the REAL hook
and asserts the alias and its target get the SAME verdict — so if a future alias is added
without an exemption, or an exemption is removed from one spelling only, the leg goes red.
The generalisation is written into the prober header: *the allowlist is a claim about
effects, so every entry needs to name the effect it admits, not the string it matches.*

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

### 2026-08-31 — the teeth leg must assert BOTH halves, not just the bypass half

- **Chose:** The mutation leg requires three facts together: the mutant refuses the alias,
  the mutant STILL admits the target, and the live lib admits the alias. Not just the first.
- **Why:** 001-CashWeb reported this at @851 against their own detector, and it cost them a
  cycle. Their first mutant had a bash syntax error, so the file failed to parse, so the
  predicate blocked *everything* — and against bypass probes alone, **a mutant that cannot
  parse is indistinguishable from a correct fix**. Only an ADMIT control separates them.
  The same asymmetry applies to my T-640 no-widening sweep: that leg asks "does the fix
  refuse anything the old version allowed"; the symmetric question is "does it still allow
  what it was supposed to". Both halves or neither.
- **Rejected:** Asserting only that the mutant blocks the alias. That is the leg I would
  have written a week ago, and it passes against a broken mutant.
- **Earned immediately:** the leg's first run reported `neutralised 1` of 2. My sed anchored
  on `$`, and the two entries have different shapes — one a block, one an inline
  `fix-learned) return 0 ;;`. Asserting the mutation COUNT is what turned a half-mutation
  into a visible failure instead of a green leg testing one site.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T12:34:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-650-the-completion-path-suggests-a-command-i.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6259dd5f
- **Timestamp:** 2026-08-31T12:44:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-31T12:44:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
