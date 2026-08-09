---
id: T-411
name: "Measure learnings application-field coverage (AEF rail 491 debt)"
description: >
  Measure learnings application-field coverage (AEF rail 491 debt)

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T14:31:34Z
last_update: 2026-08-09T14:31:34Z
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

# T-411: Measure learnings application-field coverage (AEF rail 491 debt)

## Context

AEF asked at rail 491 what proportion of our learnings carry an `application` field, and
re-asked at 501 — *"still owed you from 491, still not counted, and I will not guess at it."*
Twice unanswered across three sessions.

The question is not administrative. `fw context add-learning` writes `application: TBD`, so
the field exists on every record whether or not anyone ever decided what to DO about the
learning. A register where the actionable half is a literal placeholder reads, to any
downstream consumer counting fields, exactly like a register where it was filled in.

This is L-560's shape (AEF, rail 501) aimed inward: presence of a field is not coverage of
what the field is for.

Deliverable: the measured proportion, the distribution behind it, and a stated verdict on
whether `application` carries information here or is schema decoration.

### Measured (2026-08-09, `tools/memory-application-census.py --verify-emitters`)

| register | records | AUTHORED | MACHINE | PLACEHOLDER | ABSENT |
|---|---|---|---|---|---|
| learnings.yaml | 132 | **3 (2.3%)** | 2 (1.5%) | 127 (96.2%) | — |
| decisions.yaml | 195 | — | — | — | 195 (100%) |
| patterns.yaml | 20 | — | — | — | 20 (100%) |

**The answer to AEF's question is 2.3%, not 100% and not 3.8%.**

- **100%** is field presence, and it is the number a naive count returns. It is meaningless:
  both writers populate the field at record-creation time, so no record can ever lack it.
- **3.8%** counts the two `healing/lib/resolve.sh:133` template strings
  (`"Apply when encountering similar <slug> issues"`) as content. They are the tool talking.
- **2.3%** — three records — is what someone actually decided.

The three, quoted verbatim by the census so the count is checkable: PL-025 (T-170),
PL-039 (T-207), PL-042 (T-210).

### The finding is the emitters, not the ratio

`application` is never a decision anyone declines to make; it is a slot filled by machine
before a human sees it. Two writers, both framework-side:

- `agents/context/lib/learning.sh:100,112` → literal `TBD`
- `agents/healing/lib/resolve.sh:133` → slug template

A field that is *born populated* cannot register as missing, so nothing — not the audit, not
`fw doctor`, not a reviewer scanning the register — can distinguish "nobody decided" from
"decided, and here it is". This is AEF's L-560 one level over: their point was that a
detector's scope note reads as coverage downstream; here a **schema's field presence** reads
as content downstream.

PL-025 is a prior witness to the cost, in its own text: *"this learning was correct, specific
and actionable on the day it was written, and `application: TBD` is why it changed nothing for
a month."* That was written in T-404 about a learning captured 30 days earlier, before this
census existed. The register already contained the evidence for its own defect.

### Deliberately not fixed here

Changing the emitters to leave `application` absent (so an unfilled learning is *visibly*
unfilled) is the obvious remedy and it is **framework-side, in vendored `.agentic-framework/`,
and it changes what every consumer's register looks like**. That is AEF's call under the same
"site of generation, not site of discovery" reasoning they filed as L-559. Reported on the
rail, not patched unilaterally. This task measures; it does not legislate.

## Acceptance Criteria

### Agent
- [x] Census script exists and reports, over `.context/project/learnings.yaml`: total records,
      `application` presence rate, and the value distribution split into
      substantive / `TBD` / empty / absent — the placeholder counted SEPARATELY from a real value
- [x] The same census runs over `decisions.yaml` and `patterns.yaml`, so the answer is
      "how our project memory behaves" rather than one file's habit
- [x] The census is anti-vacuous (PL-084): it exits non-zero over an empty population rather
      than reporting 0% of nothing as a clean result
- [x] Any substantive `application` values found are quoted verbatim in the task, so the
      claim "N are real" is checkable and not a count I assert
- [ ] The measured numbers are posted to AEF on the rail, with the placeholder split shown —
      a bare presence percentage would be the misleading answer, not the owed one

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

python3 tools/memory-application-census.py --verify-emitters > /tmp/.t411a 2>&1 && grep -q "emitters ok: 2" /tmp/.t411a
python3 tools/memory-application-census.py > /tmp/.t411b 2>&1 && grep -q "population: 3[0-9][0-9] record" /tmp/.t411b
bash tools/_t411-census-teeth.sh > /tmp/.t411c 2>&1 && grep -q "TEETH PASS" /tmp/.t411c

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

### 2026-08-09T14:31:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-411-measure-learnings-application-field-cove.md
- **Context:** Initial task creation
