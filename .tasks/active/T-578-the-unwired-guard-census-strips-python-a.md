---
id: T-578
name: "The unwired-guard census strips Python and shell comments but not JavaScript block comments"
description: >
  T-495 eliminated prose false-edges for Python (tokenize + ast) and shell (word-aware hash), leaving .mjs/.js untouched. Consequence measured under T-423: tools/_t423-carrier-agreement-guard.py is counted WIRED solely because a JSDoc comment in its sibling .mjs spells out the path; reword that comment and a live guard reports unwired. The census LIMIT paragraph enumerates heredocs, md/yaml/json roots and multi-line shell strings, and does not name this one - so the blindness is not merely present, it is absent from the list that exists to state it.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [guards, fabric]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-23T20:55:19Z
last_update: 2026-08-23T21:49:59Z
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

# T-578: The unwired-guard census strips Python and shell comments but not JavaScript block comments

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The size of the prose-edge surface is measured, not estimated.** An instrument
      reports, over `tools/`, how many files have at least one EXECUTABLE-CODE reference
      versus how many are referenced only from prose (`.md`, `.yaml`, JS comments), and
      names where that prose lives. **DONE 2026-08-23:**
      `tools/_t578-js-comment-edge-census.py` — 239 files, 237 referenced, **127 with a code
      edge, 110 prose-only (46%)**. The JS-comment question that opened this task is
      answered at **0** tools held by a JS comment alone; the surface it sits inside is the
      finding. Uncertainty is reported rather than hidden: 71 files contain a construct the
      hand-written JS stripper cannot resolve, and they are named.
- [x] **`_t451`'s LIMIT paragraph states the SCALE, not only the kind.** It currently
      discloses that `.md`/`.yaml`/`.json` roots are read whole; it does not say this decides
      reachability for nearly half the population, so the disclosure reads as an edge case.
      Adding JS to the list is part of this and is the smaller part.
      **DONE, `_t451-unwired-guard-census.py:510-522`.** Each false-negative entry now carries
      its size: the prose-root entry is marked THIS IS THE BIG ONE with 110 of 237 (46%) and
      the per-source breakdown; JS is added and marked small with its 5 refs and its 0; the two
      shell forms are labelled `unmeasured` rather than left to read as measured-and-small.
      The closing line says why the quantification was added — the previous wording was true
      sentence-by-sentence and misleading in aggregate, which is a subtler way for a disclosure
      to fail than being wrong.
- [x] **A decision is recorded on what the ratchet's baseline should mean** before any
      stripping change lands. Teaching the census to ignore prose roots would move a
      committed baseline of 66 against 110 prose-only tools; re-cutting it around a number
      nobody examined is the failure this line of work keeps finding. Measure first — done
      above — then decide, and record the decision here.

      **DECISION: the ratchet keeps counting what it counts today. The baseline stays 66 and
      is NOT re-cut.** Recorded as a project decision, rationale below.

      * **What the 66 means, stated so it cannot be misread later:** "tools with no live
        caller *under the current reachability rule*" — executable position, Python and shell
        comments stripped, prose roots read whole. It has never meant "tools nothing runs",
        and the LIMIT paragraph now carries the number that proves the difference.
      * **Why not re-cut it to the prose-only population.** The ratchet's job is to detect
        MOVEMENT — a standing guard losing its last live caller between two commits — and it
        does that correctly whether or not prose counts as an edge, because both runs use the
        same rule. Redefining it to ~110+ would convert a movement detector into a backlog
        gauge measuring a debt nobody can drain in one pass, and a number that is always large
        and never actionable is a number people learn to skip. That is how this suite's legs
        stop being read.
      * **Why not the reverse either — the disclosure is not a substitute for the fix.** If
        the prose-only population is to be driven down it needs its OWN ratchet with its own
        baseline, so the two questions ("did a guard go dark this week?" and "how many guards
        are held up by a sentence?") stay separable. Not built here: that is a second
        instrument and a second deliverable, and this task's whole argument is against
        bundling a measurement change into a commit that also moves what is measured.
      * **The concrete evidence for the ordering:** this very census shipped unwired in
        `34ac6287` and became the 67th entry — the ratchet caught it, at 66-vs-67 resolution,
        precisely because the baseline was small enough for one new entry to be visible. At a
        baseline of 110+ that signal would have been one part in a hundred.

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

# The census holds its invariant: no tool is reachable only through a JS comment.
# rc 1 = a tool now is; rc 2 = REFUSED (no tool referenced from JS at all).
timeout 300 python3 tools/_t578-js-comment-edge-census.py > /tmp/t578-verify.out 2>&1

# It reports the large number too, and does not gate on it. Both halves must survive:
# quoting the small one without the large one is how the first measurement misled.
grep -qE "PROSE-ONLY — no code edge anywhere +110" /tmp/t578-verify.out

# The census is WIRED, which is the defect this task shipped and then repaired: it was
# committed unwired in 34ac6287 and became the 67th entry in the backlog it measures.
grep -q '_t578-js-comment-edge-census.py' tests/run-bridge-tests.sh

# The ratchet is back to no movement WITHOUT being re-baselined — 66, the committed value.
timeout 300 python3 tools/_t451-unwired-guard-census.py --ratchet > /tmp/t578-ratchet.out 2>&1
grep -q "baseline 66, current findings 66" /tmp/t578-ratchet.out

# The LIMIT paragraph states SCALE, not only kind (AC 1). A disclosure that names a blind
# spot without its size reads as an edge case, and this one decides 46% of the population.
grep -qE "THIS IS THE BIG ONE: 110 of the 237" /tmp/t578-ratchet.out
grep -q "JavaScript comments were never stripped" /tmp/t578-ratchet.out
grep -q "unmeasured" /tmp/t578-ratchet.out

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

### 2026-08-23T20:55:19Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-578-the-unwired-guard-census-strips-python-a.md
- **Context:** Initial task creation

### 2026-08-23T21:16:57Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Findings - 2026-08-23, measured not estimated

`tools/_t578-js-comment-edge-census.py`. Two numbers; the one I went looking for is the small one.

**The JS question: effectively nil.** 239 files in `tools/`, 52 referenced from `.mjs`/`.js`
at all, 11 of those from executable JS. Tools whose ONLY edge is a JavaScript comment: **0**.
The carrier guard that prompted this task is rescued by references elsewhere. 71 files carry a
construct the hand-written stripper cannot resolve (a regex literal can desynchronise quote
state) and are named rather than silently trusted.

**The surface it sits inside:** 237 referenced, 127 with an executable-code edge, **110
prose-only**. That prose lives in task files (214 refs), handovers (206), episodic YAML (130),
other .yaml (38), other .md (24), JS comments (5). `_t451` reads `.md` and `.yaml` whole, so
any of those mentions makes a tool count WIRED. For 110 tools, reachability is a fact about
what a handover once said, not about what runs.

**Disclosed in kind, not in scale.** `_t451`'s LIMIT paragraph does say those roots are read
whole - it exists so a clean run cannot imply coverage it lacks. It does not say this decides
nearly half the population, and a limitation whose size is unstated reads as an edge case.

**Relation to G-042.** The baseline is 66 unwired against 110 prose-only. That gap is where a
retired instrument stays green. G-042 asks whether an instrument's claim is still true; this
asks whether the edge that made it look watched is a call or a sentence.
