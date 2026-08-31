---
id: T-651
name: "three files in the repo root are named after markdown fragments"
description: >
  three files in the repo root are named after markdown fragments

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
created: 2026-08-31T12:45:11Z
last_update: 2026-08-31T13:00:05Z
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

# T-651: three files in the repo root are named after markdown fragments

## Context

Noticed in `git status` while staging T-650: three untracked root files named `**How`,
`**Recommendation:**`, `**their**`. Enumerating properly turned three into 23, spanning
two incidents four and five days old. The title undercounts by design — it is what I could
see at filing, and the first AC is what corrected it. See `## RCA`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The creating mechanism is named with evidence, not guessed. **It was not three files
      — it was 23**, across two incidents (2026-08-26 18:44:15, 2026-08-27 23:44:48-49).
      Both forms reproduced in a sandbox, and the two are distinguishable: argument
      position (`sh -c "echo $BODY"`) leaves the first file holding echo's remaining words;
      command position (`sh -c "$BODY"`, `eval`) leaves every file empty. **All 23 were
      empty**, so the markdown was executed as a script, not passed as an argument.
- [x] Established whether anything was DESTROYED. No. Every 0-byte tracked file in the
      tree is a legitimate `.gitkeep` or `.lock`; no stray name collides with a tracked
      path. Checked with `--literal-pathspecs` — see the correction below.
- [x] The 23 files removed, each guarded individually (0-byte AND untracked re-checked
      per file immediately before `rm`), by explicit name and never a glob — one of them
      was literally named `scope*,`. The three remaining untracked root files are real
      screenshots (`t589-populated.png`, `t598-light.png`, `t646-after.png`), left alone.
      **AC corrected:** this originally specified `git ls-files --error-unmatch` as the
      tracked-check. That command GLOBS its pathspec, so `**their**` matched unrelated
      tracked files and reported a false "TRACKED". The test I wrote into the AC was
      unsound for exactly the filenames the task is about; `--literal-pathspecs` is the
      fix, and the false positive is recorded here rather than quietly corrected.
- [x] Prevention shipped, not just assessed: an audit check (`audit.sh`, T-651 block)
      warning on zero-byte untracked files at the repo root, with
      `tools/_t651-stray-root-files-are-caught.sh` (5/5) holding it — including a teeth leg
      that removes the size test and requires the screenshot control to start firing, and
      a leg that reproduces the mechanism so the comment's provenance claim is tested
      rather than asserted.

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

# The prober EXTRACTS the check out of the real audit.sh by its marker comment and exits 3
# if that anchor is gone, so wiring is proven by extraction succeeding — not assumed.
bash tools/_t651-stray-root-files-are-caught.sh
bash -n .agentic-framework/agents/audit/audit.sh
grep -q '# T-651: zero-byte untracked files at the repo ROOT' .agentic-framework/agents/audit/audit.sh
#
# REPLACED, and the reason belongs here rather than in a silent deletion. This line was:
#   out=$(.agentic-framework/bin/fw audit 2>&1); echo "$out" | grep -q "\[PASS\] Stray root files"
# It failed the gate, and the failure was NOT the check. Three hypotheses, tested in order:
#   1. eval eats the backslashes in `\[PASS\]` -> DISPROVED (eval preserves the match).
#   2. cwd differs so the relative fw path breaks -> DISPROVED (P-011 does `cd "$PROJECT_ROOT"`
#      at update-task.sh:1272).
#   3. The audit does not complete inside the gate -> CONFIRMED. Re-running it in the same
#      subshell form hung until a 5-minute timeout killed it. update-task.sh:1272 runs
#      `eval "$_close_locks_cmd"` before the command precisely because the verification
#      subshell inherits the task update's lock FDs; a full `fw audit` from in there
#      contends with the very transition that invoked it.
# So: never call the whole audit from a task's own completion gate. It is a global,
# minutes-long, lock-taking read of the entire repo being run from inside a transaction on
# that repo, and it makes one task's completion depend on every unrelated warning in the
# tree. Filed as OBS-332.

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

**Symptom:** 23 zero-byte files in the repo root named after fragments of prose —
`DEFER`, `Supersedes`, `rail`, `risk,`, `neither`, `**their**`, `scope*,`, `them.`

**Root cause:** Markdown containing blockquote lines was executed by a shell. In command
position each `> word` is a redirect, so the line stops being text and becomes "truncate a
file named `word`". Two incidents, 2026-08-26 and 2026-08-27.

**Why structurally allowed — two answers, and the second is the real one.**

*(a) Nothing could see them.* They are untracked, so no commit hook inspects them; they
never enter a diff; the audit had no root-level check.

*(b) The blindness was manufactured by a correct rule.* 832's standing constraint is
"never `git add -A`, stage explicit paths" (T-571), and the cron sweep puts ~185 deletions
in `git status` every session. The practical consequence is that every status read in this
project is filtered — `grep -v '^ D .context/audits/cron/'` and friends — and the `??`
block is precisely the region a careful agent learns to skim past. I filtered these files
out of my own view repeatedly. They survived five days and twelve audits not because the
tooling was weak but because the discipline that prevents one accident (staging junk)
trained the eye away from another (junk appearing). **A filter applied to a noisy signal
becomes a blind spot with the same shape as the noise.**

**Prevention:** Audit check on zero-byte untracked root files (`audit.sh`, T-651 block).
It runs where the filtering does not: the audit reads the tree itself rather than my
summary of it. Held by `tools/_t651-stray-root-files-are-caught.sh`, whose teeth leg
removes the size discriminator and requires a legitimate untracked screenshot to start
being flagged — so "no false positives" cannot pass against a check that never fires.

**Not prevented, and stated rather than papered over:** nothing stops the underlying
accident. A guard against "shell executes markdown" would have to sit at the point of
execution, and I cannot identify the invocation — shell history for those sessions is
gone. The check catches the residue within a day instead of five. That is detection, not
prevention, and the difference is the reason G-019 exists.

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

### 2026-08-31T12:45:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-651-three-files-in-the-repo-root-are-named-a.md
- **Context:** Initial task creation
