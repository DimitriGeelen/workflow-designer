---
id: T-421
name: "Enforcement claim drift: gates the tree asserts are live are not registered"
description: >
  Enforcement claim drift: gates the tree asserts are live are not registered

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
created: 2026-08-10T19:30:28Z
last_update: 2026-08-10T19:30:28Z
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

# T-421: Enforcement claim drift: gates the tree asserts are live are not registered

## Context

Structural half of T-420 (G-019: after fixing a problem, ask why the framework allowed it).

T-420 built a gate and then discovered it could not verify the gate fires. Pulling that
thread: **the framework ships 38 hook scripts and this project has 17 registered.** Of
the 21 unregistered, some are opt-in by design and correctly off — but at least two are
asserted as ACTIVE by text in this tree:

- `check-arc-id` — every task file's frontmatter carries the comment *"PreToolUse hook
  (check-arc-id) blocks save under agent control if it doesn't resolve"*. It is not
  registered. That claim ships in the template, so it is in ~420 task files.
- `check-settings-edit` — a PostToolUse *nudge* on edits to `.claude/settings.json`
  (it prompts an enforcement-baseline refresh). Not registered. It would not have
  stopped T-420 deleting the Tier 0 hook from that file by hand today — it is a
  reminder, not a guard — but it is the only thing in the tree that watches that file
  at all, and it is off. Measured, not assumed: the detector below finds no *claim*
  that it is active, so it is drift of a milder kind (a capability nobody turned on)
  rather than a false promise.

This is the G-013/G-022 shape again — a claim about enforcement that nobody measured —
except one level up: not "the audit reported a subset as the whole" but "the tree
asserts a gate is live and it is not installed anywhere".

Scope fence: this task builds the INSTRUMENT and produces the disposition. Turning
individual gates on is a follow-up per gate — registering 21 hooks in one commit is how
you wedge a session, and each one needs its own blast-radius judgement.

## Acceptance Criteria

### Agent
- [x] A drift detector exists that compares three sets and reports the gaps:
      (a) hook scripts that EXIST in the framework tree, (b) hooks REGISTERED in
      `.claude/settings.json`, (c) hooks the tree CLAIMS are active (grep of CLAUDE.md,
      `.tasks/templates/`, and framework docs for hook names in an asserting context).
      The interesting set is **claimed ∧ ¬registered** — a promise with no mechanism.
- [x] The detector distinguishes **claimed-active** from **merely mentioned**. A hook name
      appearing in `fw hook-enable` usage text or in a list of available hooks is not a
      claim that it is on; a sentence saying it *blocks*, *refuses*, *enforces* or *is
      installed* is. Without that split the detector reports 21 false positives and gets
      ignored, which is worse than not having it.
- [x] Every one of the 21 unregistered scripts is **dispositioned**, and the DETECTOR
      prints the classification rather than the task file asserting it. Buckets as built:
      REFERENCE-ONLY (self-declared in the script's own header, 5), off-with-no-claim
      (15), CLAIMED-BUT-OFF (1). The filed AC guessed OPT-IN-BY-DESIGN / NOT-A-HOOK /
      CLAIMED-BUT-OFF; the tree turned out to carry its own marker for the first bucket
      (T-1459's `REFERENCE ONLY` header), so the detector reads that instead of me
      maintaining a parallel list that can disagree with it.
- [x] Mutation check proves the detector can fail: (a) inject a fake claimed-active hook
      name into a scratch copy of the input → detector reports it; (b) register a
      currently-claimed-but-off hook in a scratch settings file → detector stops reporting
      it; (c) the real tree today → reports the CLAIMED-BUT-OFF set and not the opt-ins.
      A detector only ever seen finding the bug it was written for is not an instrument.
- [x] Each CLAIMED-BUT-OFF finding gets a follow-up task or an explicit recorded reason
      for leaving it off. **This task does not register any hook** — the fence above.
- [x] Detector wired into `## Verification` so the claimed∧¬registered set cannot grow
      silently after this task closes.

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

## Disposition — all 21 unregistered scripts

38 hook scripts ship; 17 are registered here. Every one of the other 21 is classified
below. An unclassified script would be the same absent measurement this task exists to
end, so the detector prints this table itself rather than trusting the task file.

**REFERENCE-ONLY, self-declared (5)** — `pl007-scanner`, `session-end`,
`session-silent-scanner`, `stop-guard`, `subagent-stop`. Each carries
`REFERENCE ONLY — not registered in .claude/settings.json` in its own header (T-1459).
The detector reads that marker rather than keeping a second list; a copy of a
disposition, stored away from the artifact that owns it, is the PL-142 shape.

**Off, no claim found (15)** — `bus-handler`, `chat-bare-path-scan`,
`chat-bare-path-warn`, `check-active-completed-dup`, `check-dispatch-pre`,
`check-heredoc-cmd-sub`, `check-inception-decisions`, `check-inception-recommendation`,
`check-inception-schema`, `check-settings-edit`, `check-task-ac-structure`,
`check-visual-verification`, `context`, `revisit-due-scan`, `session-metrics`.
Capabilities this project has not enabled. `check-visual-verification` is documented
opt-in in CLAUDE.md and is the detector's most important negative case (see mutation
check N2). The rest are silently-off rather than deliberately-off, which is worth
knowing but is not a false promise — nothing in the tree says they run.

**CLAIMED-BUT-OFF (1)** — `check-arc-id`.

    .tasks/templates/default.md:14-15
      # arc_id: ... PreToolUse hook
      #        (check-arc-id) blocks save under agent control if it doesn't resolve.

This sentence ships in the task template, so it is in every task file this project has
ever created. It has never been true here. Remedy is a follow-up (T-422) per the scope
fence: either register the hook or delete the sentence — and those are different
decisions, because one adds enforcement and the other admits its absence.

## What The First Run Got Wrong

Recorded because the corrections are the design, and the first version would have
shipped as an instrument nobody reads:

1. **9 findings, 6 of them false.** The initial scan included
   `.agentic-framework/docs/`. A generated component catalogue enumerating 38 scripts
   is not a claim that this project installed them. The distinction the detector needs
   is not mention-vs-assertion alone but *whose configuration is being asserted* — only
   project-owned prose (CLAUDE.md, FRAMEWORK.md, the task templates) speaks about the
   gates running here.
2. **`context` matched three times, all English.** It is a dispatchable hook
   (`fw hook context` resolves) and the most common noun in the codebase — it hit
   "context explosion", "pollutes context", and a `.context/` path. Fixed by requiring
   an un-hyphenated name to appear as an identifier (backticked, parenthesised, quoted,
   or `.sh`-suffixed), since prose asserting a hook names it as a thing rather than a
   word. A stopword list containing `context` was rejected: one entry today, silent on
   the next hook named `audit` or `resume`.
3. **Line-scoped matching found nothing.** The motivating claim is split across two
   lines of a YAML comment — hook name on one line, verb on the one before. A
   line-scoped detector reports a clean tree, which is the exact failure mode being
   detected, reproduced inside the detector. Window is ±2 lines.
4. **A "does this script speak the hook protocol?" signal was measured and dropped.**
   It classified `check-arc-id` and `block-plan-mode` — a real finding and a working
   registered hook — as non-hooks. Recorded so it is not re-attempted.


## Verification

bash tools/_t421-drift-mutation-check.sh
python3 tools/_t421-enforcement-claim-drift.py --baseline .context/project/enforcement-claim-baseline.txt --quiet
bash tools/_t420-gate-mutation-check.sh

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

**Symptom:** the task template tells every task file that a PreToolUse hook
(`check-arc-id`) blocks saves with an unresolvable `arc_id`. The hook is not registered
in this project and never has been.

**Root cause:** enforcement has two artifacts — the script and the registration — and
only the script had a home in prose. A sentence describing a gate is written next to
the gate's *purpose*, not next to its *installation*, so nothing connects the claim to
`.claude/settings.json`.

**Why structurally allowed:** prose has no exit code. `fw doctor` verifies the
enforcement baseline HASH — that the registered set has not CHANGED — which is a
different question from whether the registered set matches what the tree promises. A
tree can be perfectly self-consistent under that check while promising gates it never
installed. Nothing in the audit compared the two vocabularies.

**Prevention:** `tools/_t421-enforcement-claim-drift.py`, pinned to a committed
baseline, in `## Verification`. A NEW claimed-but-unregistered hook fails the gate; the
one known finding stays visible without blocking every future commit.

**Not claimed as prevention:** that off-but-unclaimed gates are correctly off. 15
scripts sit in that bucket and the detector is deliberately silent about them — nothing
in the tree promises them, so there is no drift to measure, only a decision nobody has
revisited. That is a different task and it needs a human.

## Evolution

### 2026-08-10 — the detector's first run was 67% noise
- **What changed:** 9 findings, 6 false. Scanning the framework's own generated docs
  treated a catalogue of what the framework CONTAINS as a claim about what this project
  INSTALLED. The needed distinction was not mention-vs-assertion but
  whose-configuration-is-asserted.
- **Plan impact:** claim sources narrowed to project-owned prose. AC2 was written about
  mention-vs-assertion and is satisfied, but it under-specified the real axis.
- **Triggered:** the exclusion is documented in the source with the measured number,
  because a future reader will otherwise re-add the docs directory as an obvious
  improvement.

### 2026-08-10 — a hook whose name is an English word
- **What changed:** `context` is a dispatchable hook and the most common noun in the
  codebase. It matched "context explosion" and "pollutes context".
- **Plan impact:** un-hyphenated names must appear as identifiers. Derived rule, not a
  stopword list — a stopword list would be one entry today and silent on the next hook
  named `audit`.
- **Triggered:** nothing; recorded because the rejected alternative is the tempting one.

### 2026-08-10 — a signal measured and thrown away
- **What changed:** "does this script speak the hook protocol (`tool_name`,
  `hook_event_name`)?" looked like a clean derivation of hook-ness. Measured across all
  38: it classifies `check-arc-id` (the finding) and `block-plan-mode` (a registered,
  working hook) as non-hooks.
- **Plan impact:** dropped before it reached the detector.
- **Triggered:** written into the task so it is not re-attempted as an improvement.

## Decisions

### 2026-08-10 — baseline containment rather than exit-1-on-any-finding
- **Chose:** pin the known set; fail only when it GROWS.
- **Why:** the one finding is a follow-up decision (register vs delete the sentence),
  not a one-line fix. A gate that fails until someone makes that decision gets bypassed,
  and a bypassed gate measures nothing. Same shape T-408 already uses here for the
  G-015 carrier census.
- **Rejected:** hard fail on any finding — honest, and it would have been switched off
  within a day.

### 2026-08-10 — the detector prints the disposition; the task file does not own it
- **Chose:** classification is computed at runtime from the scripts' own headers and the
  registration file.
- **Why:** a disposition table written into a task file is accurate on the day it is
  written and silently wrong afterwards — PL-142 exactly. The tree already carries
  T-1459's `REFERENCE ONLY` markers next to the scripts they describe.
- **Rejected:** maintaining the 21-row table by hand in this task.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-10T19:30:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-421-enforcement-claim-drift-gates-the-tree-a.md
- **Context:** Initial task creation
