---
id: T-493
name: "unwired-guard census computes liveness one-hop, so dead tools vouch for each other"
description: >
  tools/_t451-unwired-guard-census.py unions every tool named inside any tool into the live set instead of computing reachability from non-tool roots. 22 tools are counted live only because a DEAD tool references them; 10 are standing instruments, not one-shots. Separately its LIVE_SOURCES greps concerns.yaml whole-file while its comment says 'gap closure conditions that RUN', so a tool named in a prose narrative reads as wired. Discovered via T-492. Fixing it grows the finding set, so suite leg 73's ratchet fires and the T-491 baseline must be regenerated deliberately.

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
created: 2026-08-14T06:58:01Z
last_update: 2026-08-14T07:11:21Z
date_finished: 2026-08-14T07:11:21Z
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

# T-493: unwired-guard census computes liveness one-hop, so dead tools vouch for each other

## Context

`tools/_t451-unwired-guard-census.py` decides "has a live caller" by unioning every
`tools/<name>` reference found in `LIVE_SOURCES`, and `LIVE_SOURCES` includes `tools/*`
itself. So liveness is a **one-hop union**, not a reachability closure: a tool
referenced only by another *dead* tool reads as wired. Reachability is not transitive
through dead nodes, and the census treats it as though it were.

Measured under T-492 (population 165):

    roots (named by a source that is NOT itself a tool)          40
    live by CLOSURE from those roots                             49
    live by FLAT one-hop union (what the census does today)      71
    counted live ONLY because a DEAD tool references them        22

Twelve of the 22 are `-teeth`/`-probe` one-shots the census excuses anyway. **Ten are
standing instruments** currently reported as wired. The clearest specimen is
`_t400-schema-teeth.sh`: nine dead teeth scripts reference it, so nine dead things make
one dead thing look alive.

Second, independent defect in the same definition: `LIVE_SOURCES` lists
`.context/project/concerns.yaml` with the comment *"gap closure conditions that RUN"*,
but `read_refs()` greps the **whole file**. `lib/gaps.py:78` executes exactly one field
— `closure_check_command:` — and only 4 of 34 concerns have one. So a tool named
anywhere in 2,362 characters of narrative prose reads as wired. That is how
`tools/_t418-producer-attribution.py` (T-492 F3) appeared reachable: its name occurs in
`.concerns[25].context`, a paragraph *describing a measurement it once performed*. **A
record of a past measurement was counted as the capacity to measure.**

Same defect as AEF's `next_id()` grepping `OBS-[0-9]+` over message bodies, which I
reported to them at rail 607 — in our own file, one day later.

**Why this matters more than the count.** T-491 generated
`tools/unwired-guard-baseline.txt` from this census's `--json` and wired `--ratchet` as
suite leg 73. The baseline header argues that deriving beats hand-typing. It does — but
deriving faithfully from an instrument whose definition is wrong launders the error into
a file that then reads as authoritative. Fixing the census **grows** the finding set, so
leg 73's ratchet fires in the GREW direction on its first real firing. That is the
ratchet working, and the baseline must be regenerated deliberately with the reason
recorded — not quietly refreshed.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Liveness is a **closure from roots outside the population**, not a one-hop union:
      `tools/*` is removed from the root set and becomes a traversal edge instead, so a
      tool is live only if some non-tool source reaches it, directly or through other
      **live** tools. The census's own docstring is updated to say so — it currently
      claims both sides are derived from the tree, which was true and incomplete.
- [x] The `concerns.yaml` source is **field-scoped to `closure_check_command`**, the
      field `lib/gaps.py` actually executes, with the field name derived from that file
      rather than guessed. A tool named only in prose no longer reads as wired.
- [x] **Negative controls, each proving the new logic can go red for its own reason:**
      (a) a tool referenced only by a dead tool is reported as a finding, where the old
      logic reported it live; (b) a tool named only in a `context:`/prose field of
      concerns.yaml is reported as a finding; (c) a tool named in a real
      `closure_check_command` is still live; (d) a tool reached through a *chain* of
      live tools is still live — the closure must not collapse to roots-only.
- [x] The baseline is **regenerated from `--json`, never hand-edited**, and its header
      records that it moved, by how much, and why — the ratchet firing is the event
      being documented, not a nuisance to silence.
- [x] `--ratchet` is confirmed to have actually FIRED in the GREW direction against the
      old baseline before regeneration, and the output is recorded here. A ratchet whose
      first real movement is absorbed by a same-commit baseline refresh has never been
      shown to work.
- [x] Bridge suite green after the change (legs 72 and 73 included), and the new finding
      count is reported with its denominator (PL-084).

## Results

    population                                        165
    roots (hook, cron, tests/, agent, gap gauge)       29   NOT itself a tool
    live-callable (closure from roots)                 38   9 reached only via a live chain
    NO live caller                                    105
      one-shot BY DESIGN (excused by naming)           39
      FINDINGS — read as standing guards               66   (was 37)

**The ratchet fired, and that is the result worth recording**, because leg 73 had never
moved before:

    RATCHET: baseline 37, current findings 66
      GREW by 29 — a standing guard lost its last live caller
      rc=1

Nothing went dark. The instrument got better at seeing, and the ratchet cannot tell those
apart — nor should it: both mean *the set changed and a human owes it a look*. Among the
29 now correctly reported: `rail-sweep.py`, `_t421-enforcement-claim-drift.py`,
`_t429-abstention-census.py`, `concerns-schema.py`, `memory-application-census.py`,
`verification-hygiene.py`, `bpmn-cli.py`.

**Negative controls — and each was checked against the OLD logic, not just asserted.**
Built a 7-tool miniature tree under `T451_ROOT`:

    (a) referenced only by a dead tool     -> FINDING     old logic: reported LIVE
    (b) named only in concerns.yaml prose  -> FINDING     old logic: reported LIVE
    (c) named in closure_check_command     -> live        (field scoping works)
    (d) reached via a 2-hop live chain     -> live        (closure ≠ roots-only)

(a) and (b) are the ones that matter, and running the pre-change file from
`git show HEAD:` on the same tree returned findings `['dead_voucher.sh']` only — so both
controls go red for their own reason and not by accident. That check exists because
yesterday's control C passed under `set -e` without ever running its assertion.

## A third defect found, named, and deliberately NOT fixed here

`_t418-producer-attribution.py` — the detector T-492 established has not run since
2026-08-09 — **still reports live after this fix.** Not through a dead tool and not
through prose: it is reached from `_t420-rail-attribution-gate.py`, a genuine root
(`.claude/settings.json`), by the docstring sentence *"the miss is visible afterwards to
tools/_t418-producer-attribution.py"*. Prose about a compensating control, counted as a
call.

So the census's LIMIT — "reachability is decided by TEXTUAL reference" — was stated in
one direction only, warning about false positives while the false-negative half went
unmentioned. **A limit statement that names one direction has the same shape as the
defect it is warning about.** Measured: 46 of 115 tool-to-tool reference lines (40%) open
as comments. Both directions are now in the docstring and in the printed output.

Filed as T-495 rather than fixed: stripping comments per language is a change of
definition, and moving this count a third time in one day would make the baseline's
provenance unreadable.

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
# ── T-493 ─────────────────────────────────────────────────────────────────────
python3 -c "import ast; ast.parse(open('tools/_t451-unwired-guard-census.py').read())"
# Set equality between baseline and findings — strictly stronger than a count check,
# and it is what proves the baseline was regenerated rather than nudged.
python3 tools/_t451-unwired-guard-census.py --ratchet
# The gap register is field-scoped to the field lib/gaps.py actually executes.
grep -q "GAUGE_FIELD = 'closure_check_command'" tools/_t451-unwired-guard-census.py
# The LIMIT is stated in BOTH directions (the T-493 finding about the finding).
grep -q "FALSE NEGATIVE" tools/_t451-unwired-guard-census.py
# The successor for the comment-edge defect exists as a task, not just as prose.
ls .tasks/active/T-495-*.md
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

### 2026-08-14T06:58:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-493-unwired-guard-census-computes-liveness-o.md
- **Context:** Initial task creation

### 2026-08-14T07:03:12Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4462a609
- **Timestamp:** 2026-08-14T07:11:22Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T07:11:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
