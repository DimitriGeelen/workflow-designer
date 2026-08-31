---
id: T-662
name: "G-047 is recorded as jointly unsatisfiable but its third focus state was never measured"
description: >
  G-047 is recorded as jointly unsatisfiable but its third focus state was never measured

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T19:49:30Z
last_update: 2026-08-31T19:49:30Z
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

# T-662: G-047 is recorded as jointly unsatisfiable but its third focus state was never measured

## Context

G-047 is titled "the completed-task gate and the focus-drift gate are **jointly
unsatisfiable**" and its clause (d) states that under null focus "T-2054 admits git commit
but NOT git add, so anything untracked — a new prober, a newly filed task file — cannot be
staged." Its triggers include changing the status machine to make work-completed
non-terminal.

While committing T-661's completion I did exactly the sequence the gap says is impossible:
under null focus, `git add` staged an UNTRACKED file (`.context/episodic/T-661.yaml`) plus
the active/→completed/ rename, and `fw git commit` then landed it. Two commands, no bypass,
no borrowed focus.

`check-active-task.sh:240` says why, in its own words: "`git add` (task-agnostic, no drift)
stays in is_bash_safe_command." Clause (d) is contradicted by the hook it describes.

My first explanation — "add and commit cannot share one command line" — was ALSO wrong,
and the prober is what said so. They can: `git add x; fw git commit -m "T-1: c"` is
admitted, and so is `echo hi; fw git commit`. What defeats the T-2054 exemption is a
`$(...)` SUBSTITUTION sharing the commit's line: T-638 made `_sc_is_commit_only_command`
judge each clause of the quote-stripped command, and the substitution's contents become a
clause that is not commit-only. Control: the same `$(...)` with `git add` instead of the
commit is admitted, so it is the pairing and not the substitution.

I hit this repeatedly because I habitually write `echo "staged=$(git diff --cached ...)"`
beside the commit as a progress line. Nobody had tested the gate; a message that fires for
many reasons and names none of them was read as an impossibility, and that reading was
quoted forward into the register.

So the gap is real but MISDIAGNOSED twice over: not an unsatisfiability, and not compounds.
It is a discoverability defect, and the fix is to make the gate say which rule it applied.

## Acceptance Criteria

### Agent
- [x] The claim is verified against the code that acts, not only the one incidental
      observation — the hook's own allowlist is cited, with file:line
- [x] G-047's `detail` is corrected in `.context/project/concerns.yaml`: clause (d)'s
      "NOT git add" is replaced with the measured behaviour, the working two-command
      sequence is written out verbatim, and the compound-block is attributed to T-638
      as intended behaviour rather than a defect
      → **The correction itself needed correcting.** My first version said "add and commit
      cannot share one command line". The prober failed that leg: they CAN. The real rule
      is that a `$(...)` substitution sharing the commit's line defeats the T-2054
      exemption, because T-638 judges each clause of the quote-stripped command and the
      substitution's contents become a non-commit clause. Every session that hit this was
      writing `echo "staged=$(git diff --cached ...)"` beside the commit.
- [x] G-047's status is NOT flipped and its severity is NOT changed — concern flips are
      operator authority. A recommendation is surfaced for the operator instead, with the
      evidence needed to act on it
      → status `watching` and severity `medium` verified unchanged after the edit.
- [x] The block message in `check-active-task.sh` names the two-command path, so the next
      agent to hit this is told the way through instead of concluding it is stuck
- [x] The message change is proven to fire: a probe shows the new text appears on the
      compound form and that the two individual commands are still admitted
      → `tools/_t662-null-focus-commit-path-must-be-discoverable.sh`, 9/9, driving the real
      hook through its stdin JSON envelope. Includes the control leg (the same `$(...)`
      without a commit clause is admitted) so the advisory cannot misattribute the cause,
      and a teeth leg that removes the advisory and requires the discoverability leg to
      go red.
- [x] Vendored-file divergence for `check-active-task.sh` is declared in
      `.vendor-divergence.yaml` (G-008), classified `upstream: fix`

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
         1. Run `bin/fw reviewer T-662`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-662 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
bash tools/_t662-null-focus-commit-path-must-be-discoverable.sh
python3 tools/_t517-vendor-divergence.py
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml'))"
# G-047 must remain operator-owned: this task corrects its evidence, never its disposition.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[x for x in d['concerns'] if x['id']=='G-047'][0]; sys.exit(0 if g['status']=='watching' and g['severity']=='medium' else 1)"

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

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
     fw inception decide T-662 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T19:49:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-662-g-047-is-recorded-as-jointly-unsatisfiab.md
- **Context:** Initial task creation
