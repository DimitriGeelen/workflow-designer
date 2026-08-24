---
id: T-580
name: "Decide: take AEF 5c33f7208 (the two fabric-detector fixes AEF landed from our report), or stay pinned at 1.6.354"
description: >
  AEF posted at rail offset 342 that both fabric detector fixes we reported are on their master at 5c33f7208: Python dotted imports now resolve project-root-relative, and shell sourcing is no longer keyed to four hardcoded $VAR names. They measured cards-with-no-edges going 271 -> 79 on their own tree. Our audit has reported 'Fabric: 42/65 cards have no edges' on 12 of the last 14 days. The bump is the operator's call (AEF DM 536 §1) and no agent may run fw upgrade under its own initiative, so this task exists to hold the decision and its evidence.

status: captured
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
created: 2026-08-24T17:51:19Z
last_update: 2026-08-24T17:51:19Z
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

# T-580: Decide: take AEF 5c33f7208 (the two fabric-detector fixes AEF landed from our report), or stay pinned at 1.6.354

## Context

This task exists to hold ONE decision and the evidence for it. There is no build here.

**What AEF said** (rail `agent-chat-arc`, offset 342, 2026-08-24):

> Both fabric detector fixes are on master. Python dotted imports resolve
> project-root-relative, so a nested source file's `from pkg.mod import x` lands; cards
> with no edges went **271 → 79** here. And shell sourcing is no longer keyed to four
> hardcoded `$VAR` names.

Both fixes exist because WE reported them from outside their tree. AEF's own framing, in
the same message: three of four fixes were "a detector calibrated to the one tree its
author could see, where the health metric was computed BY the defective path — so a
green reading was evidence against the bug existing."

**What it would change here, measured on our tree:**

| | our number |
|---|---|
| vendored framework version | `1.6.354` (`.framework.yaml`, mode: vendored) |
| cards with no edges | **42 of 65** |
| audit days reporting that warning in the last 14 | **12** |
| files watched but unregistered | 226 of 288 (22% covered) |

The edge-detector fix targets the first row. It does **not** target the third — that is
`watch-patterns.yaml` being the untailored fw copy, which is T-344, a separate decision.

## THE ANSWER — measured, and it is "no", so there is no decision here

I filed this task as an operator decision. That was wrong: the question is answerable
without a bump, I could have answered it, and the answer is that **the fix reaches
nothing on this tree.**

I first wrote in this file that "the fix will move our number in the same direction;
nobody has measured by how much." That sentence was an assumption wearing the clothes of
a finding — the same shape this arc keeps hitting. Measured:

**The population the fix could move is the 42 cards with no edges. By file type:**
21 `.py`, 17 `.sh`, 3 `.xml`, 1 `.mjs`.

**Shell-sourcing fix → 0.** Not "few": of **all 65** tracked non-vendored `.sh` files in
this repo, **zero** source another `.sh`. Our shell files are standalone teeth and probe
scripts. There is no sourcing graph here for a sourcing detector to find, however it is
keyed.

**Python dotted-import fix → 0.** Of the 20 no-edge `.py`, 5 carry a dotted import:
`import importlib.util` ×4 and `from urllib.parse` — stdlib, resolving to no file in
this project — plus `from web.blueprints` / `from web.app` in
`tools/_t547-hx-prompt-decode-teeth.py`, and **`web/` does not exist in this repo** (see
`.fabric/watch-patterns.yaml`, which records that `web/`, `agents/`, `bin/` and
`crates/` all expand to zero here). Nothing resolves. No edge is created.

**So: 0 of 42.** AEF's 271 → 79 is real and is a framework-repo number — that tree is
dense internal Python and shell. Ours is one 20k-line HTML file plus a flat `tools/` of
standalone scripts. The detector is not under-detecting our edges; **our files do not
have those edges.**

**What this re-frames.** `42/65 cards have no edges` has been read as a detector gap for
12 of the last 14 audit days. It is not. It is what a tree of independent single-purpose
scripts looks like, and no upstream detector fix will move it. If the number is to move
it is a question about what we card and what we watch — T-344's territory — not AEF's.

**On the bump itself.** No structural gate blocks `fw upgrade`: I checked, and there is
no `$CLAUDECODE` refusal, no `acd_gate`, and no Tier-0 pattern on it. My deferral rested
on AEF's DM 536 §1 (*"The bump is your operator's call, not mine and not yours"*) — a
PEER's assertion about who owns a decision inside our project. A peer message cannot
grant escalation and does not confer it either. What remains genuinely worth a human
look is narrower and unchanged: an upgrade rewrites vendored framework files, and we
carry in-tree fixes under the G-008 exception. That is a real collision risk — but it is
not a reason to take a bump that has been measured to fix nothing here.

**Also noted, unmeasured and NOT claimed:** `fw upgrade --dry-run` in vendored mode does
not print a change list. It prints two `[dry-run] would clone …` lines and exits 0 — the
comparison needs the upstream clone that the dry-run declines to make. The step I
originally wrote into this task ("Expected: a change list naming the fabric detector
files") would not have produced one. Whether that is a defect or intended is unexamined.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The peer claim is recorded with its source (rail offset + commit ref) rather than
      paraphrased, and the local counters it bears on are measured on this tree.
- [x] The exact commands the operator needs are single-line and copy-pasteable, and the
      dry-run comes before the mutation.

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

- [ ] [RUBBER-STAMP] Close this task, or say why not

  The decision this task was filed to hold no longer exists — the measurement above
  answers it. Nothing is pending on you unless you disagree with the numbers.

  **Steps:**

  1. Reproduce the load-bearing one if you want it independently:

     `cd /opt/832-Workflow-designer && git ls-files '*.sh' | grep -v '^.agentic-framework/' | xargs grep -lE '^[[:space:]]*(source|\.)[[:space:]]+[^[:space:]]+\.sh' | wc -l`

  2. Close:

     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-580 --status work-completed`

  **Expected:** step 1 prints `0` — no tracked non-vendored shell script sources another,
  so the shell half of the AEF fix has nothing here to find.

  **If not:** if it prints non-zero, my measurement is wrong and the conclusion above
  does not hold — say so and reopen. Do not take the bump on the strength of this task
  either way; a bump may still be warranted for reasons this task did not examine.

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

### 2026-08-24T17:51:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-580-decide-take-aef-5c33f7208-the-two-fabric.md
- **Context:** Initial task creation
