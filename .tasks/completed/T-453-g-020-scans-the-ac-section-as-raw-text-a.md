---
id: T-453
name: "G-020 scans the AC section as raw text: a quoted placeholder token blocks a
  real AC, and the templates commented Human examples make the zero-AC half inert"
description: >
  G-020 (check-active-task.sh:584) decides build-readiness with two greps over the
  raw AC section, with no structural parse and no HTML-comment stripping. Two consequences
  from one root. FALSE POSITIVE: the placeholder token quoted inside a genuine acceptance
  criterion counts as a placeholder, so a task describing this gate cannot be filed
  (hit live at T-452). FALSE NEGATIVE, the serious one: the task template ships two
  commented example checkboxes under Human, they match REAL_AC_COUNT, so every template-created
  task starts at REAL_AC_COUNT=2 and the zero-AC half of the gate can never fire.
  Deleting the two placeholder lines - the literal instruction in the block message
  - leaves the gate passing with zero acceptance criteria. Measured with the gates
  own two commands: HAS_PLACEHOLDER=0 REAL_AC_COUNT=2 ALLOWED. The remedy already
  exists sixty lines above in the same file: the G-067 Open Questions gate strips
  HTML comments before counting (line 539, T-2554). Vendored AEF tooling, so the fix
  is theirs and upstreamable under G-008; reported over the rail with the reproduction.

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
created: 2026-08-12T10:55:55Z
last_update: '2026-08-16T13:58:56Z'
date_finished: 2026-08-12T12:26:15Z
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
  - ts: '2026-08-16T12:33:59Z'
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
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.tasks/templates/default.md,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.tasks/templates/default.md);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-453: G-020 scans the AC section as raw text: a quoted placeholder token blocks a real AC, and the templates commented Human examples make the zero-AC half inert

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The false negative is measured against the SHIPPED template, not a fixture.** The
      real-AC count and the placeholder count over `.tasks/templates/default.md` are both
      asserted by command in `## Verification`. The claim that matters — *delete the two
      placeholder lines, which is the literal instruction in the gate's own block message,
      and the gate passes over zero acceptance criteria* — must be reproducible by the
      operator from the template the framework actually ships.
- [x] **The false positive is stated as a workaround, never as a fix.** Hit a THIRD time
      this window, filing these very criteria — the gate blocked T-453's own ACs. A genuine AC that
      quotes the gate's block message is counted as a placeholder, so a task describing
      this gate cannot be filed. It was hit live twice: filing T-452, and filing this
      task's own criteria. Recorded as the workaround it is — I avoid reproducing the
      token — with no pretence that avoiding a string repairs a classifier.
- [x] **The remedy is named from the same file, not designed.** `G-067`'s Open Questions
      gate sixty lines above strips HTML comments before counting (`:539`, their T-2554).
      The fix is to apply the sibling's existing treatment, so the report carries a
      one-line remedy rather than a defect and a shrug.
- [x] **Reported upstream; no local patch.** AEF rail offset **561**, restated at **564**
      §4 paired with T-455 as one class. Vendored under `.agentic-framework/`, so a
      local fix is silently reverted by the next bump and reads as fixed meanwhile — the
      disposition ruled for T-402/T-422/T-345/T-455. Verified by an empty `git diff` over
      the hook path at completion.

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

# 1. THE FALSE NEGATIVE, read off the template the framework SHIPS. G-020 counts 4 lines
#    matching its real-AC pattern; only 2 survive comment-stripping, and those 2 ARE the
#    placeholders it blocks on. The other 2 are the commented [REVIEW]/[REVIEWER] examples
#    at :58 and :67 inside the Human guidance block.
test 4 -eq "$(grep -cE '^[[:space:]]*- \[ \]' .tasks/templates/default.md)"
# NOTE — this leg builds the HTML comment markers from chr() codes on purpose, and the
# reason is a defect discovered by this very line. P-011's extractor strips HTML comments
# from the COMMAND TEXT before executing it (update-task.sh:981,
# `re.sub(r'<!--.*?-->', '', text, DOTALL)`). The sed form of this check therefore ran as
# `sed -E 's///g' ... | sed '//d'` and failed, while passing standalone — the gate deleted
# the middle of my regex. Filed as T-456. Writing the markers as chr(60)+chr(33) keeps the
# literal out of the command so the extractor has nothing to eat.
test 2 -eq "$(python3 -c "import re; s=open('.tasks/templates/default.md').read(); s=re.sub(chr(60)+chr(33)+'--.*?--'+chr(62),'',s,flags=re.S); print(sum(1 for l in s.splitlines() if re.match(r'\s*- \[ \]',l)))")"
# 2. Consequence, stated as arithmetic rather than prose: delete the 2 placeholders — the
#    literal instruction in G-020's own block message — and 2 pattern-matching lines remain,
#    every one of them a comment. The ==0 half can never fire, so the gate passes over zero
#    acceptance criteria.
# 3. The remedy already exists SIXTY LINES UP in the same file: G-067's Open Questions gate
#    strips HTML comments before counting (:539, their T-2554). This is "apply the sibling's
#    existing treatment", not a design question.
grep -q 'OQ_STRIPPED' .agentic-framework/agents/context/check-active-task.sh
# 4. NO local patch to the vendored hook. Empty diff is the deliverable.
test -z "$(git diff --name-only -- .agentic-framework/agents/context/check-active-task.sh)"

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

### 2026-08-12T10:55:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-453-g-020-scans-the-ac-section-as-raw-text-a.md
- **Context:** Initial task creation

### 2026-08-12T11:00:26Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ae8d8cd1
- **Timestamp:** 2026-08-12T12:26:16Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T12:26:15Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
