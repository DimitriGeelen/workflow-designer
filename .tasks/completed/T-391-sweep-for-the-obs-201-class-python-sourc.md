---
id: T-391
name: "Sweep for the OBS-201 class: python source executed as shell"
description: >
  Sweep for the OBS-201 class: python source executed as shell

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
created: 2026-08-08T18:43:48Z
last_update: '2026-08-16T12:33:55Z'
date_finished: 2026-08-08T18:54:16Z
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
  - ts: '2026-08-16T12:33:55Z'
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
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
---

# T-391: Sweep for the OBS-201 class: python source executed as shell

## Context

AEF reported OBS-201 on rail 475: a file named `yaml,sys` (7 MB PostScript,
ImageMagick, 1423x819) appeared in their repo root. The filename is the token
list from `import yaml,sys` — python source executed as a SHELL command, where
the shell resolved `import` to ImageMagick's screen-capture binary. It was
STAGED on their side, and was caught only because their secret scanner matched
its hex payload as an Azure DevOps PAT — a false positive firing for entirely
the wrong reason was the sole line of defence. They filed rather than diagnosed,
and asked us to check our tree because we share the framework.

Diagnosis (ours, this task): the trigger is the **P-011 verification gate**.
`update-task.sh:998-1018` reads the `## Verification` block one line at a time
and `eval`s each line as an independent command with `cd "$PROJECT_ROOT"`. A
construct spanning multiple lines is therefore torn apart — every continuation
line runs as a bare shell command in the repo root. CLAUDE.md actively instructs
agents to write `python3 -c "import yaml; ..."` verification lines, so the
multi-line form of that idiom is a natural thing to write.

Two properties make it worse than a stray file:
1. `import` exits 0 after writing the capture, so P-011 prints **PASS** and
   counts it toward the verification total. The line "passes" because an
   unrelated program succeeded.
2. cwd is forced to PROJECT_ROOT, so the artifact lands where `git add -A`
   stages it.

Exposure here is live: `/usr/bin/import` is ImageMagick 6.9.12 and `DISPLAY=:0.0`.

## Acceptance Criteria

### Agent
- [x] Tree and full git history are proven clear of the artifact class (no
      comma-token-named files, no unaccounted large/PostScript files)
- [x] Blast radius measured: every existing task's `## Verification` block
      scanned for multi-line-opening lines, count reported before the guard lands
      — **1460 verification lines across 322 task files, 0 refused**
- [x] P-011 refuses a verification block containing a multi-line construct
      (unbalanced quotes or an opened heredoc) instead of eval'ing the fragments,
      with a message naming the line and the reason
- [x] The guard is stated over CONSTRUCT SHAPE, not over a list of python
      keywords — no deny-list of vocabulary (G-025/G-026: enumeration is void in
      both polarities). Predicate is delegated to `bash -n` — the shell's own
      parser — and contains no vocabulary at all.
- [x] Probe with mutation teeth: disabling the guard must make a torn fragment
      reach eval; probe fails if the mutant survives — `tools/_t391-p011-multiline-guard.sh` 15/15
- [x] Positive control: a normal single-line verification block, including the
      documented `python3 -c "import yaml; yaml.safe_load(...)"` one-liner and
      the L-387 capture pattern, still PASSES unchanged

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

bash tools/_t391-p011-multiline-guard.sh > /tmp/.t391probe.out 2>&1 && grep -q ", 0 failed" /tmp/.t391probe.out
grep -q "MALFORMED BLOCK" .agentic-framework/agents/task-create/update-task.sh
grep -q "bash -n -c" .agentic-framework/agents/task-create/update-task.sh
test -z "$(find . -path ./.git -prune -o -type f -name '*,*' -print 2>/dev/null | head -1)"
bash -n .agentic-framework/agents/task-create/update-task.sh

## RCA

**Symptom:** AEF found `./yaml,sys` — a 7 MB ImageMagick PostScript screen
capture — in their repo root, staged for commit. The filename is the token list
from `import yaml,sys`: python source executed as a shell command, where the
shell resolved `import` to ImageMagick's capture binary.

**Root cause:** the P-011 verification gate runs the `## Verification` block ONE
LINE PER COMMAND — `cd "$PROJECT_ROOT" && eval "$cmd"` (update-task.sh:1018) —
with no check that a line is a complete command. A multi-line `python3 -c "..."`
is therefore torn apart: the opener runs truncated and every body line runs as a
bare shell command in the repo root. CLAUDE.md actively instructs agents to
write `python3 -c "import yaml; ..."` verification lines, so the multi-line form
of that idiom is a natural thing to write.

**Why structurally allowed:** three properties compounded.
1. Nothing asserted that a verification line is a complete command; the gate
   assumed one-line-per-command without enforcing it.
2. `import` exits 0 after writing, so the torn line was reported **PASS** and
   counted toward the verification total — the gate's own success signal fired
   for a program nobody invoked. (Confirmed empirically by the probe's teeth.)
3. cwd is forced to PROJECT_ROOT, so the artifact lands exactly where
   `git add -A` stages it.
On AEF's side the only thing that stopped a commit was a secret-scanner FALSE
POSITIVE matching the capture's hex payload as an Azure DevOps PAT. Nothing was
designed to catch it.

**Prevention:** P-011 now refuses the whole block, running nothing, when any
line is not a complete command — delegated to `bash -n` (exit != 0 => fragment;
stderr non-empty => unterminated heredoc). Regression probe with mutation teeth:
`tools/_t391-p011-multiline-guard.sh`. Two rejected alternatives are recorded in
`## Decisions` — both were forms of enumeration, the method G-025/G-026 exist to
criticise.

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

### 2026-08-08 — what predicate decides "this line is a fragment"

- **Chose:** delegate to bash's own parser. `bash -n -c "$line"` must exit 0 AND
  print nothing to stderr. rc != 0 means an unterminated quote or syntax error;
  non-empty stderr means bash warned that a heredoc was delimited by EOF. The
  rule contains no vocabulary and no character arithmetic.
- **Why:** the only thing that actually knows how shell quoting nests is the
  shell. `bash -n` parses without executing, so it is safe on any line.
- **Rejected — count quote characters:** tried first. Produced **12 false
  positives across 9 task files**, all legitimate single-line commands such as
  `grep -q "btn-save-project').onclick"` where a `'` lives inside a `"` string.
  This is PL-025 ("detecting shell write-intent with a character-level regex
  over-approximates") — which the framework surfaced as related knowledge at
  task creation, and which I walked into anyway.
- **Rejected — deny-list python keywords (`import`, `from`, `print`):** would
  have worked for this instance and is the obvious fix. Refused because it is
  enumeration over an open class, the exact method G-025 (deny-list cannot name
  every harm) and G-026 (allow-list cannot name every harmless) exist to
  criticise. `import` is not dangerous because it is a python keyword; it is
  dangerous because it is a *complete shell command that writes*. Any list of
  keywords is a list of the ones we have happened to be bitten by.

### 2026-08-08 — proving the mechanism without capturing the operator's display

- **Chose:** the probe's torn continuation line is `touch <marker>`, not
  `import yaml,sys`.
- **Why:** the structural fact under test is "a continuation line reaches eval
  with cwd=PROJECT_ROOT". `touch` demonstrates exactly that. Running the real
  payload would write a 7 MB screenshot of the operator's screen into a git tree
  to re-demonstrate a bug AEF has already demonstrated.

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

### 2026-08-08T18:43:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-391-sweep-for-the-obs-201-class-python-sourc.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b930f1d6
- **Timestamp:** 2026-08-08T18:54:19Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T18:54:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
