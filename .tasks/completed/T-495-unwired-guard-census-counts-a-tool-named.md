---
id: T-495
name: "unwired-guard census counts a tool named in a COMMENT as a live edge, so a discussed tool reads as wired"
description: >
  Reachability is textual, and 46 of 115 tool-to-tool reference lines (40 percent) open as comments. tools/_t418-producer-attribution.py is reached from the live root _t420-rail-attribution-gate.py purely by the docstring sentence naming it as a compensating control — prose about a control, not a call — so an instrument that has not run since 2026-08-09 reports as wired. This is the FALSE NEGATIVE direction of the census LIMIT, which T-493 documented but deliberately did not fix: stripping comments per language (py/sh #, mjs // and /* */) is a change of definition that would move the count a third time in one day. Found via T-493.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t451-unwired-guard-census.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-14T07:08:00Z
last_update: 2026-08-14T07:58:02Z
date_finished: 2026-08-14T07:58:02Z
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

# T-495: unwired-guard census counts a tool named in a COMMENT as a live edge, so a discussed tool reads as wired

## Context

`tools/_t451-unwired-guard-census.py` decides reachability by TEXTUAL reference to
`tools/<name>`, so prose about a tool is indistinguishable from a call to it. T-493
stated this as the false-negative half of the census LIMIT and deliberately did not
fix it. This task fixes it.

**The filed remedy was wrong, and checking it first is the whole reason this task did
not just get implemented.** T-495 was filed saying "stripping comments per language
(py/sh `#`, mjs `//` and `/* */`)". The motivating instance is not a comment:
`_t420-rail-attribution-gate.py:110-111` names `tools/_t418-producer-attribution.py`
inside its MODULE DOCSTRING — a string literal, invisible to any `#`-stripper. A
`#`-only fix would have closed the task, moved the count, and left the one edge the
task exists for standing.

There is a second source of the same edge, and it is worse: the census's OWN docstring
(line 65) names `tools/_t418-producer-attribution.py`, in the LIMIT paragraph that
exists to explain that prose creates false edges. The census is live (gap gauge G-035),
so the paragraph documenting the defect is an instance of it. Two live roots vouch for
t418 by prose; the fix has to remove both, and one of them is in this file.

So the definition change is: an edge counts only from an EXECUTABLE position — not a
comment, and not a bare string-expression statement (docstring). Python is done exactly
via `tokenize` + `ast`, not by regex, because the two prose mechanisms are lexically
different and a regex that "handles" both would be the same guess-shaped instrument this
census exists to count.

## Acceptance Criteria

### Agent
- [x] `read_refs()` strips non-executable text before extracting references, dispatched by
      extension: Python via `tokenize` (COMMENT tokens) + `ast` (bare string-expression
      statements, which is a superset of docstrings); shell via quote-aware `#`; js/mjs via
      quote-aware `//` and `/* */`. Applied to ROOTS and EDGES alike — a tool named only in
      a comment inside a test file is no more called than one named in a comment inside a tool.
- [x] A Python source that fails to tokenize/parse does NOT silently vanish from the graph:
      the file falls back to naive `#`-stripping and is COUNTED, with the count surfaced in
      `--json` and in the printed LIMIT. A parser that quietly drops a file it cannot read
      would remove edges for a reason unrelated to wiring.
- [x] Negative controls prove the stripper does what is claimed, each failing for its own
      reason: (a) the `_t420` docstring edge to `_t418` is gone; (b) the census's own
      docstring edge to `_t418` is gone; (c) a genuine Python call edge expressed as a
      STRING ARGUMENT (`subprocess`/`os.system` style) SURVIVES — this is the direction the
      fix could break, and it must be shown not to; (d) a genuine shell invocation carrying
      a trailing `#` comment survives.
      → `tools/_t495-prose-edge-probe.py`, 15 legs, 0 fail. `--discriminate` re-runs every
      leg against `git show HEAD:` of the census: 7 of 12 go red on the old file, and the
      other 5 are LABELLED INERT in the output rather than counted as evidence — they are
      regression guards for the direction the fix could break, so passing on both files is
      what they are supposed to do.
- [x] `tools/_t418-producer-attribution.py` appears in the census findings after the change.
      It has not run since 2026-08-09; if it still reads live, the fix did not do its job.
- [x] The ratchet FIRES on this change, and the firing is recorded in the regenerated
      baseline header BEFORE regeneration — direction, delta, and cause — per T-493. A
      first movement absorbed by a same-commit refresh leaves no evidence the mechanism
      worked.
      → Fired in BOTH directions: baseline 66 → 69, GREW by 4, SHRANK by 1. Header records
      all five names, both causes, and the probe's self-inflicted regression.
- [x] The census LIMIT is corrected in BOTH the docstring and the printed output: it
      currently says "a reference inside a COMMENT", while its own cited evidence is a
      docstring. The remaining limit (shell heredoc bodies are not detected) is stated
      rather than implied.
- [x] Bridge suite passes with no new failures (73 passed / 0 failed at T-494).
      → 74 passed / 0 failed; the extra leg is the T-495 definition probe.

**Added during the work, because the task as filed was not sufficient:**
- [x] Composed paths are resolved from the AST (`os.path.join(x, 'tools', 'y')` and
      pathlib `x / 'tools' / 'y'`). NOT scope creep — measured necessity. Stripping prose
      alone reported 10 CDP harnesses dead that run on every bridge-suite pass, because
      each test module's docstring named the harness it composes. Two errors of opposite
      sign were cancelling; removing one alone converts silently-wrong to loudly-wrong.
- [x] The probe is wired into `tests/run-bridge-tests.sh`, not left in this Verification
      block. A `## Verification` block is one-shot (PL-161) and the file is named
      `-probe.py`, which the census's own naming convention EXCUSES — so nothing would
      ever have reported it dark. An instrument its own watchdog is built to overlook has
      to be scheduled deliberately.
- [x] Probe leg F1 asserts no fixture name resolves to a real tool, and is shown to go red
      when one is planted (A1 stays green, so it fails for its own reason).

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
# NOTE (PL-161, and the point of this whole task): these four lines run ONCE, here, at
# completion. They are not the guard. The standing guards are the two bridge-suite legs
# added under this task — the ratchet over the count, and the probe over the definition
# the count derives from. What follows is a completion check, not a watch.

python3 tools/_t495-prose-edge-probe.py
python3 tools/_t451-unwired-guard-census.py --ratchet
python3 tools/_t451-unwired-guard-census.py --json > /tmp/.t495-census.json && python3 -c "import json; raise SystemExit(0 if '_t418-producer-attribution.py' in json.load(open('/tmp/.t495-census.json'))['findings_files'] else 1)"
grep -q '_t495-prose-edge-probe.py' tests/run-bridge-tests.sh

## RCA

**Symptom:** `tools/_t418-producer-attribution.py` — the T-418 producer-attribution
detector, which has not run since 2026-08-09 — reported as WIRED in the unwired-guard
census, so the census that exists to find dark instruments could not see the dark
instrument that T-492 had just found by hand.

**Root cause:** reachability was decided by textual reference to `tools/<name>` anywhere
in a file. Prose ABOUT a tool was indistinguishable from a call TO it. Two live roots
vouched for `_t418` by prose alone: `_t420-rail-attribution-gate.py`'s module docstring
naming it as the compensating control the gate defers to when it fails open, and — this
is the part worth keeping — the census's OWN docstring, in the LIMIT paragraph written
under T-493 to explain that prose creates false edges.

**Why structurally allowed:** the false-negative direction was known and written down.
T-493 measured it (46 of 115 tool-to-tool reference lines open as comments), stated it in
the census LIMIT, printed it on every run, and filed T-495. That is a prediction with no
schedule — the same shape as T-426's LIMIT string that predicted T-494's defect four days
early. A LIMIT that prints on every run is not a watch; nothing fails when it comes true.

Underneath that, a second structural fact made the wrongness invisible: **two errors of
opposite sign were cancelling.** Prose counted as a call, and a composed path
(`os.path.join(ROOT, "tools", "<name>")`) did not. Ten CDP harnesses that run on every
bridge-suite pass were held live purely by the docstring in the test module that composes
them. The census produced correct answers for those ten by two wrong mechanisms, which is
why nothing ever looked wrong enough to chase. It also means the defect could not be
fixed by halves: stripping prose alone took findings to 79 and reported ten running
instruments dead.

**Prevention (distinct from the fix):** two standing bridge-suite legs, not one.
`--ratchet` guards the COUNT (already present, T-491); the new `_t495-prose-edge-probe.py`
leg guards the DEFINITION the count derives from. These are different assertions — a bug
in `strip_prose()` moves every number at once and the ratchet would report it as a genuine
backlog movement with a confident cause attached. The probe is wired into the suite
specifically because a `## Verification` block is one-shot (PL-161) and `-probe.py` is
excused by the census's own `ONE_SHOT_BY_DESIGN` convention, so an unscheduled probe would
be invisible to the very instrument it guards.

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

### 2026-08-14 — the filed remedy was checked before it was implemented, and it was wrong
- **Chose:** Strip comments AND bare string-expression statements, via `tokenize` + `ast`
  for Python rather than a regex.
- **Why:** T-495 was filed prescribing `#`/`//`/`/* */` stripping. The instance it was
  filed FOR is a module docstring — a string literal, untouched by any `#`-stripper. The
  filed remedy would have closed the task, moved the count a third time, and left the one
  edge standing. The two prose mechanisms are lexically different, so only a real lexer
  separates them; a regex claiming to handle both would be a guess about lexical structure,
  which is the same shape as the instrument this census counts.
- **Rejected:** Implementing the task as written. Also rejected: stripping ALL Python
  strings — `subprocess.run(["tools/x.py"])` is a real call spelled as a string, so only a
  string that is an entire STATEMENT is prose.

### 2026-08-14 — composed-path resolution ships in the SAME commit, not as a follow-up
- **Chose:** Add `_composed_refs()` (literal `os.path.join` / pathlib components) alongside
  the stripper.
- **Why:** Measured, not assumed. Stripping prose alone moved findings 66 → 79 and orphaned
  10 CDP harnesses that run on every bridge-suite pass, invoked as
  `os.path.join(ROOT, "tools", "<name>")`. Each test module's docstring happened to name the
  harness it composes, so a wrong edge was standing in for a missing one and the answer came
  out right for two wrong reasons. Half the fix reports ten live instruments dead — a worse
  instrument than the one it replaces, in the direction the census is least able to survive.
- **Rejected:** Filing composition as T-496 and shipping the stripper alone. That leaves a
  known-false census running as the standing suite guard for however long the follow-up
  takes, which is the "prediction with no schedule" class this week already cost four tasks.

### 2026-08-14 — the probe is scheduled in the suite, and its fixtures are synthetic
- **Chose:** Wire `_t495-prose-edge-probe.py` into `tests/run-bridge-tests.sh`; name every
  fixture `_t495-fixture-*` so none resolves to a real file.
- **Why:** Two separate traps, both hit. (1) A `## Verification` block runs once (PL-161),
  and the file is named `-probe.py`, which the census's own `ONE_SHOT_BY_DESIGN` convention
  EXCUSES — so an unscheduled probe would never be reported dark by the very census it
  guards. (2) Once wired, the probe is a live root, and its fixtures named real tools; a
  fixture is a string assigned to a name, which the new rule deliberately keeps. The probe
  resurrected `_t418-producer-attribution.py`, `_t418-capture-attribution.sh` and
  `_t445-partial-state-mutation.sh` — it manufactured the exact defect it was built to
  detect, and all 14 legs stayed green while it did.
- **Rejected:** Leaving fixtures realistic for readability. Leg F1 now asserts the property
  and was shown to go red with a real name planted, while A1 stayed green.

### 2026-08-14 — `--discriminate` is authoring-time, and says so when it stops working
- **Chose:** The suite runs the probe in plain mode; `--discriminate` warns when every leg
  is inert.
- **Why:** `--discriminate` diffs against `git show HEAD:` of the census. After this commit
  HEAD contains the change, so the mode compares the file to itself and returns a uniform
  green that asserts nothing. A control that quietly stops discriminating is the same
  failure as one that never did, so it announces the condition instead of passing silently.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-14T07:08:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-495-unwired-guard-census-counts-a-tool-named.md
- **Context:** Initial task creation

### 2026-08-14T07:45:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4b6b1074
- **Timestamp:** 2026-08-14T07:58:06Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#4 (Agent)** — `tools/_t418-producer-attribution.py` appears in the census findings after the change.
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t418-producer-attribution.py in: `tools/_t418-producer-attribution.py` appears in the census findings after the change.`

### 2026-08-14T07:58:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
