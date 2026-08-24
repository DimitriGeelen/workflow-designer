---
id: T-560
name: "Verification legs that assert ABSENCE cannot distinguish a satisfied assertion from a broken pattern (OBS-297)"
description: >
  Verification legs that assert ABSENCE cannot distinguish a satisfied assertion from a broken pattern (OBS-297)

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
created: 2026-08-20T06:56:14Z
last_update: 2026-08-20T21:53:02Z
date_finished: 2026-08-20T21:53:02Z
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

# T-560: Verification legs that assert ABSENCE cannot distinguish a satisfied assertion from a broken pattern (OBS-297)

## Context

A P-011 Verification leg that asserts something is ABSENT is satisfied by silence. If the
pattern is broken — mis-quoted, shell-expanded before `grep` sees it, or simply wrong — the
leg returns "not found" and goes green for the wrong reason. The assertion and its own
failure are the same observable. This is PL-219 ("a negative assertion is satisfied by
silence") landing in the one place the framework treats as mechanical proof.

OBS-297 was filed after two legs in a single session were caught mis-quoted:

* T-501 leg 2 — `grep -c "…replace(/\[^a-z0-9_"`. In the file the pattern reads as a literal
  `[`; by the time `eval` (update-task.sh:1018) hands it to `grep` as a BRE it matches
  nothing. The leg asserted a count of **3**, got 0, and failed LOUD. Caught.
* T-301 leg 4 — `grep -q "fetch(\`/api/versions?id=\${encodeURIComponent(id)}\`)"`. Double
  quoted, so the shell expanded `${encodeURIComponent(id)}` to the empty string before grep
  ran. Existence leg, so it also failed LOUD. Caught.

Both were caught **because they asserted presence**. The same two defects in a leg asserting
absence would have passed, silently, and been read as evidence. That asymmetry — not the
quoting itself — is what this task instruments.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The corpus is **measured before the detector is designed**: how many `## Verification`
      legs across `.tasks/{active,completed}/` assert absence, by which syntactic form
      (`test 0 -eq …grep -c…`, `! grep -q`, `grep -qv`, `test -z`). The number goes in
      `## Evolution` whatever it turns out to be, including if it is zero — a corpus zero is
      a finding about reachability, not a reason to drop the task (T-337 precedent).
- [x] A detector at `tools/_t560-absence-assertion-census.py` reports every absence-asserting
      Verification leg with `file:line`, the leg text, and which form matched.
- [x] The detector distinguishes an absence leg that carries a **positive control** (a
      companion leg proving the same pattern CAN match something) from one that does not.
      Only the second kind is a finding — an absence assertion with a control is exactly the
      correct construction and must not be reported as a defect.
- [x] Teeth at `tools/_t560-absence-census-teeth.py`, planted-mutant style (T-558 shape):
      a real uncontrolled absence leg must be FLAGGED, a controlled one must NOT be, a
      presence-only leg must NOT be, and the mutants must not survive the run.
- [x] The teeth are wired into `tests/run-bridge-tests.sh` **and the suite is run**, with its
      pass/fail counts recorded — not merely `grep`-ed for the probe's own registration.
      (T-558: three tasks shipped green through a red suite by asserting registration.)
      **Run 2026-08-20: `bridge round-trip: 115 passed, 0 failed`**, up from the 114
      floor T-558 left. Run twice — once on first registration and again after the
      classifier refinements below moved the baseline 81 → 78 — because the first run
      measured a census that no longer exists.
- [x] The detector reports its own denominator: how many Verification legs it examined and
      how many it could not parse. A census that silently skips what it cannot read is the
      defect this task exists to catch.

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
#
# ── T-560 legs ───────────────────────────────────────────────────────────────────
# Every leg below asserts a POSITIVE fact, and that is deliberate rather than tidy: a
# task about absence assertions verified by absence assertions would be flagged by its
# own census, and would deserve to be. Leg 5 is the suite itself, not a grep proving
# this probe is registered — T-558 is the whole reason (three tasks shipped green
# through a red suite by asserting their own registration and never running the host).
python3 tools/_t560-absence-census-teeth.py > /tmp/.t560-teeth 2>&1 && grep -q "5/5 legs passed" /tmp/.t560-teeth
python3 tools/_t560-absence-assertion-census.py > /tmp/.t560-census 2>&1 && grep -q "PASS: no increase in uncontrolled absence assertions" /tmp/.t560-census
grep -q "absence legs whose pattern the parser could not extract" /tmp/.t560-census
grep -qx "78" tools/_t560-absence-baseline.txt
bash tests/run-bridge-tests.sh > /tmp/.t560-suite 2>&1 && python3 -c "import re,sys; m=re.search(r'(\d+) passed, 0 failed', open('/tmp/.t560-suite').read()); sys.exit(0 if m and int(m.group(1)) >= 115 else 1)"

## RCA

**Symptom:** Two `## Verification` legs written in a single session were mis-quoted in
ways that made their `grep` patterns match nothing — `\[` as a BRE in T-501 leg 2, an
unescaped `${encodeURIComponent(id)}` inside double quotes in T-301 leg 4. Both were
caught. The symptom that matters is the one that was *not* observed: the same two
mistakes in a leg asserting absence would have passed and been recorded as evidence.

**Root cause:** A negative assertion is satisfied by silence (PL-219). `! grep -q P F`
exits 0 both when `P` is genuinely absent from `F` and when `P` can never match anything
— a broken pattern, a path that does not exist, a variable the shell emptied. The two
states are the same observable, so no amount of care at the gate can separate them. The
gate is not wrong; the leg carries no information.

**Why structurally allowed:** P-011 treats a zero exit as proof, which is what makes it
a structural gate rather than agent self-assessment — and that is exactly why a leg whose
zero exit is unconditional is worse here than anywhere else. Nothing in the framework
distinguishes assertion direction. `grep -q` and `! grep -q` are the same shape to the
gate, and the corpus has 99 legs of the second kind (81 with no control at all) that no
instrument has ever looked at. The pattern-hygiene guidance in the template is extensive
— errexit, SIGPIPE, pipefail, toolchain hints — and none of it mentions direction.

**Prevention:** `tools/_t560-absence-assertion-census.py` classifies every absence leg by
whether anything establishes the search *could* have succeeded (PATTERN control, EXISTENCE
control, or none) and ratchets on the uncontrolled count, so leg 82 goes red. The
distinction is the prevention, not the count: an absence assertion with a companion leg
proving the pattern matches somewhere is the correct construction and must stay cheap to
write. `tools/_t560-absence-census-teeth.py` pins both edges so the tool cannot decay into
either "flag everything" or "flag nothing" while still reporting a plausible number.

**Not prevented, and stated rather than implied:** this catches legs at census time, not
at authoring time. A leg written and run in the same session still goes green before the
suite sees it. An authoring-time warning is a completion-gate change and is its own task.

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

### 2026-08-20 — the corpus, measured before the detector was designed (AC1)

Across `.tasks/{active,completed}`: **478** files carry a `## Verification` block,
**2316** executable legs in total, **92** of which assert absence.

By form on the first survey (legs may match more than one): `test -z "$(…)"` 37,
`! grep` 33, count-compared-to-zero 29, `grep -v` as the assertion 14.

By control, after both tightenings described below: **4** PATTERN-controlled, **10**
EXISTENCE-controlled, **78** with no control at all. Two absence-shaped legs have a
pattern the parser cannot extract; they are counted and reported rather than dropped.

The 78 are overwhelmingly historical — the largest single cluster is
`test -z "$(git status --porcelain -- .agentic-framework)"`, repeated across a dozen
completed dogfood tasks. That is a real instance of the defect (a mistyped path yields
empty output and passes) and it is also not worth 12 retroactive edits. Hence a ratchet
rather than a gate: the point is to stop the 79th, not to burn down the 78.

### 2026-08-20 — dogfooding moved the number, and the tool flagged its own task first

Writing this task's own `## Verification` block exposed an over-flag. The suite leg ends
`… passed, 0 failed …`, and the first classifier read every `-eq 0` as an absence
assertion — so the census flagged T-560 itself, and would have counted 7 corpus legs of
the same kind.

They are not the same defect. Those zeros come from a **parsed number**, not from an
empty search result: if the parse breaks the variable is empty, `test "" -eq 0` errors,
and the leg fails **loud**. Loud-versus-silent is the entire distinction the tool draws,
so counting them would have inflated the population with legs carrying none of the risk.
`count-eq-zero` now fires only when the line also runs a search (`grep`, `find`, `ls`,
`git diff/status/ls-files`). Corpus went 99 → 92 absence legs, uncontrolled 81 → 78.

Both refinements this session moved the number in opposite directions and for opposite
reasons — the control tightening **raised** uncontrolled 74 → 81 by removing false
coverage, the search-sourcing tightening **lowered** it 81 → 78 by removing false
findings. Neither was visible from the first plausible-looking output.

### 2026-08-20 — the control detector over-credited, in the direction that hides findings

First implementation accepted a sibling leg as a positive control if the sibling's TEXT
CONTAINED the pattern. That scored **13** legs PATTERN-controlled. Requiring the string to
BE one of the sibling's own extracted grep patterns dropped it to **4**.

So the loose rule was reporting nine uncontrolled legs as covered. The example that
exposed it is this week's shape exactly: T-301:283, `test -f X && ! grep -q "workflowMeta" X`,
was called PATTERN-controlled because a neighbouring census leg happened to contain the
word `workflowMeta` inside a Python snippet. **Mention is not invocation** — the same
distinction T-558 hit with docstrings and T-501 hit with a regex-vs-XML-parser census.

The four survivors were read individually rather than trusted: T-455 and T-459 assert
`^## Recommendation` gives 0 in `default.md` **and** ≥1 in `inception.md`; T-465 greps the
witness key positively before asserting its removal; T-313 pins the warning code against a
fixture that carries it. All four are the construction this tool is meant to encourage,
which is the evidence that leg 2 of the teeth is testing something real.

### 2026-08-20 — why mutants are planted outside `.tasks/`, against T-558 precedent

T-558's teeth plant mutants in the directory the scanner reads, on the grounds that a
mutant the scanner never reads makes the leg run no code (PL-206). Correct there. Here the
scanned directory is `.tasks/active/`, which a 15-minute audit cron and every task-counting
artifact also read, so planting fabricated tasks there would put them in front of live
tooling for the duration of the run. The census takes `T560_TASK_ROOT` instead, and the
door is closed from the other side: teeth leg 5 runs with no override and requires the real
corpus (2316 legs) back, so a leaked override cannot pass unnoticed.

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

### 2026-08-20T06:56:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-560-verification-legs-that-assert-absence-ca.md
- **Context:** Initial task creation

### 2026-08-20T07:05Z — renumbered T-559 → T-560 before any work was done [agent]
- **Action:** `fw work-on` minted **T-559**, which is not a free id in this project's prose:
  `T-559` is **999-AEF's** task ("Project Boundary Enforcement"), cited unqualified **154
  times** across `.tasks/`, `.context/` and `docs/` as *"the T-559 boundary"* — the rule that
  Bash may not write outside `/opt/832-Workflow-designer` and that we never invoke AEF's
  tooling. It is also baked into vendored source (`.agentic-framework/agents/context/`
  `check-project-boundary.sh:25,103,378`, which prints `Policy: T-559`).
- **Why it mattered:** minting it locally would have made those 154 citations ambiguous
  between a boundary policy and a build task about grep quoting, with no marker anywhere
  saying which was meant. Renamed before the first commit, so no history carries the
  collision.
- **How T-560 was chosen:** measured, not assumed — citations *in our own authored corpus*
  (`.tasks .context docs`, excluding vendored `.agentic-framework/**` which mentions hundreds
  of AEF ids in AEF's own reports): T-559 → 154, **T-560 → 0**, T-561..T-565 → 1 each (all the
  same harmless vendored-path entry in `.context/episodic/T-001.yaml`).
- **Filed separately:** the id-minting gap itself, which is not this task's scope.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-736781de
- **Timestamp:** 2026-08-20T22:02:47Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-20T21:53:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
