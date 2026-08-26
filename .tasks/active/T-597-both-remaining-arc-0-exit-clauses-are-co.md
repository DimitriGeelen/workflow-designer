---
id: T-597
name: "Both remaining Arc-0 exit clauses are counterparty-owned and nothing said so, so Arc 0 cannot be closed from this side"
description: >
  Both remaining Arc-0 exit clauses are counterparty-owned and nothing said so, so Arc 0 cannot be closed from this side

status: work-completed
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
created: 2026-08-26T16:26:20Z
last_update: 2026-08-26T16:30:53Z
date_finished: 2026-08-26T16:30:53Z
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

# T-597: Both remaining Arc-0 exit clauses are counterparty-owned and nothing said so, so Arc 0 cannot be closed from this side

## Context

T-596 made the Arc-0 exit gate's third clause checkable and left clauses 1 and 2 marked
`NOT-CHECKED — no executable definition`. This task went looking for those definitions.
They exist, in `roadmap-5be23719.md` §6:

| Clause | Fence (§6) | Evidence owner (§6) |
|---|---|---|
| 1 | Component Fabric non-empty, enriched, validated | Arc 0 task owner |
| 2 | Contract/refusal matrix complete | architecture task owner |

And §2.1 line 64 says who that is. For Arc 0 the **AEF agent owns** "Runtime schemas,
invariants, **refusal matrix**, task/evidence contracts, **AEF topology**". The Workflow
Designer column owns "Inventory visual/mapping schema, stable IDs, import/export and
round-trip constraints" — which is what T-590 delivered, in full.

So the finding is not that clauses 1 and 2 are unchecked. It is that **they are not ours
to check.** Both remaining Arc-0 exit clauses are counterparty-owned, and the artifact
clause 2 depends on — the consolidated refusal/threat matrix from the Claude, Z.ai,
DeepSeek and Mistral findings — does not exist anywhere in this repository. It is named
as a requirement in six places and was never built, because building it was never our
job.

**Consequence, stated plainly: Arc 0 cannot be closed from this side.** Not by more work
here, not by any gate we write. It needs an attestation from a counterparty we have not
been authorised to contact. That makes send-authorisation and H6 not merely the next
item but the only remaining path, which is worth the operator knowing before any further
Designer-side effort is spent.

**PL-034 is the trap this task must not fall into:** a guard that checks internal
self-consistency cannot detect a broken promise to an external party. A gate that
evaluated only what is visible from here would report Arc 0 as fine.

## Acceptance Criteria

### Agent
- [x] `docs/research/executable-workflow/arc-0-exit-clauses.yaml` exists and parses, holding
      all three Arc-0 exit clauses with, for each: the §6 fence text, the owning side, an
      `evaluation` method, and whether its definition has been ratified
- [x] Each clause's `owner` is corroborated against the roadmap's own §2.1 ownership table by
      a check that reads `roadmap-5be23719.md` — the register may not self-assert ownership
      any more than it may self-assert a resolution (PL-148)
- [x] Every clause definition the agent wrote carries `definition_ratified: false` and
      `proposed_by: agent`; no agent-proposed definition may be recorded as ratified
- [x] The gate reports all three clauses, and reports clauses 1 and 2 as blocked on a named
      counterparty attestation rather than as satisfied, unchecked, or ours to fix
- [x] A clause marked satisfied while its definition is unratified is an INTEGRITY VIOLATION
      (exit 2), not a pass — proven by a poison arm
- [x] A counterparty-owned clause marked satisfied with no `attestation` is an INTEGRITY
      VIOLATION (exit 2) — proven by a poison arm (PL-034: internal consistency cannot
      certify an external promise)
- [x] An `owner` that contradicts the roadmap §2.1 table is an INTEGRITY VIOLATION (exit 2)
      — proven by a poison arm that reassigns the refusal matrix to the Designer side
- [x] `tools/_t596-arc0-exit-gate.sh --self-test` still passes end to end with the clause
      arms added, and the accept path remains reachable

### Human

- [ ] [REVIEW] Ratify the clause definitions, or correct them

  **Steps:**
  1. Run: `cd /opt/832-Workflow-designer && cat docs/research/executable-workflow/arc-0-exit-clauses.yaml`
  2. Each clause carries `proposed_by: agent` and `definition_ratified: false`. The agent
     read the definitions out of roadmap §6's fence table; it did not invent them, but it
     did choose how to make them executable, and that choice is yours to accept.
  3. Check the ownership reading in particular: clauses 1 and 2 are recorded as AEF-owned
     on the strength of roadmap §2.1 line 64, which puts "refusal matrix" and "AEF topology"
     in the AEF column. If you read that boundary differently, the gate is wrong.

  **Expected:** Three clauses, all `definition_ratified: false`, none `satisfied`, clauses
  1 and 2 owned by `aef`, clause 3 `shared`.

  **If not:** Name which clause is mis-defined or mis-owned and the agent will correct it.
  Do not set `definition_ratified: true` to move things along — the gate treats an
  unratified definition as unable to certify anything, which is the point of the field.

- [ ] [REVIEW] Decide whether to authorise contact with AEF — this is the EWCR critical path

  **Steps:**
  1. Run the gate: `cd /opt/832-Workflow-designer && tools/_t596-arc0-exit-gate.sh`
  2. Read the closing paragraph. Two of Arc 0's three exit clauses need an attestation from
     the AEF agent, and the consolidated refusal/threat matrix that clause 2 depends on does
     not exist in this repository — it was never the Designer side's to build.
  3. Weigh the consequence: **no further Designer-side work closes Arc 0.** T-590 delivered
     the whole Designer column. What remains is a conversation with a counterparty we have
     never been authorised to contact.

  **Expected:** A decision on one of — (a) authorise a scoped send to AEF under a new task
  so the attestation can be requested, (b) hold, and accept that Arc 0 stays open and Arc 1
  cannot start, (c) something else you can see that the agent cannot.

  **If not:** If you want option (a), say so and the agent will create the send-authorisation
  task with real ACs and bring the envelope and transport back for your approval before
  anything leaves this machine. The agent will not send on its own initiative under any
  reading of "proceed as you see fit".

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

python3 -c "import yaml;yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml',encoding='utf-8'))"
tools/_t596-arc0-exit-gate.sh --self-test
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml',encoding='utf-8'));ids=[c['id'] for c in d['clauses']];assert ids==['clause-1','clause-2','clause-3'],ids"
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml',encoding='utf-8'));bad=[c['id'] for c in d['clauses'] if c.get('proposed_by')=='agent' and c.get('definition_ratified')];assert not bad,bad"
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml',encoding='utf-8'));bad=[c['id'] for c in d['clauses'] if c.get('satisfied')];assert not bad,bad"
python3 -c "l=open('docs/research/executable-workflow/roadmap-5be23719.md',encoding='utf-8').readlines()[63];c=[x.strip() for x in l.split('|')];assert 'refusal matrix' in c[2].lower() and 'aef topology' in c[2].lower(),c[2];assert 'refusal matrix' not in c[3].lower(),c[3]"
python3 -c "import glob;m=[f for f in glob.glob('docs/**/*.md',recursive=True)+glob.glob('docs/**/*.yaml',recursive=True) if 'refusal-matrix' in f or 'threat-matrix' in f];assert not m,m"

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

**Symptom:** T-596 left two of the three Arc-0 exit clauses marked "no executable
definition", implying the definitions were missing and that writing them was the next
Designer-side job.

**Root cause:** the definitions were never missing. They are in roadmap §6's fence table,
and §2.1 line 64 assigns both to the AEF agent. What was missing was anyone asking *who
owns the clause* before asking *how to check it*. An unowned clause reads as unassigned
work; a counterparty-owned clause reads as a dependency. Same text, opposite consequence.

**Why structurally allowed:** every instrument this project has built points inward. The
H-register, the provenance guard, the envelope checks — all of them verify things visible
from inside this repository. There was no shape for "this is real, it is required, and it
is not ours", so a counterparty obligation had nowhere to be recorded except as silence,
and silence reads as absence. PL-034 names the general case: a guard that checks internal
self-consistency cannot detect a broken promise to an external party.

**Prevention:** `counterparty-attestation` is now an evaluation method, and a clause using
it is satisfiable only by a recorded `attestation` naming who attested and when. Three
integrity rules back it: a clause cannot be satisfied while its definition is unratified,
a counterparty clause cannot be satisfied without an attestation, and a clause's owner must
agree with the roadmap's own ownership table — derived by reading the table, not by
trusting the register. The poison arm that reassigns the refusal matrix to the Designer
side is the important one: it is the exact edit a future agent would make to turn a
dependency back into actionable work.

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

## Recommendation

**Recommendation:** GO — accept the finding, and authorise a scoped request to AEF.

**Rationale:** This is the one that changes what "push EWCR through to success" means.
Arc 0 has three exit clauses. T-590 delivered the entire Designer column of Arc 0 and
T-596 made the third clause checkable. The other two belong to the AEF agent — roadmap
§2.1 line 64 puts "refusal matrix" and "AEF topology" in their column — and the refusal
matrix does not exist in this repository at all. It is named as a requirement in six
places and was never built here, because it was never ours to build.

So the honest position is that **no further Designer-side work closes Arc 0**, and Arc 1
cannot start until it does. Every remaining path runs through a counterparty we have never
been authorised to contact. Continuing to build instruments here would produce more green
checks over the same standstill — which is precisely the failure this project has spent
the week learning to see.

What I am asking for is narrow: authorisation to prepare a request for attestation, under
a new task, with the envelope and transport brought back for your approval before anything
leaves this machine. Not authorisation to send. I will not send on my own initiative under
any reading of "proceed as you see fit", and the send stays a separate act under a separate
task either way.

**Evidence:**
- `tools/_t596-arc0-exit-gate.sh` → clause-1 BLOCKED awaiting attestation from aef;
  clause-2 BLOCKED awaiting attestation from aef; clause-3 BLOCKED on open H-questions
- Ownership is derived by reading roadmap line 64's table columns, not asserted by the
  register — the poison arm that moves the refusal matrix to the Designer column is caught
  with `register says owner='designer' but the roadmap's own ownership table puts
  'refusal matrix' in the 'aef' column`
- `--self-test` 13/13: five H-register arms (T-596) plus four clause arms, each required to
  return exit code 2 specifically, plus both accept paths and both clean-block checks
- The refusal matrix's absence is verified by a P-011 leg, not assumed
- All three clauses carry `definition_ratified: false`. That includes clause 3, which I had
  initially recorded as ratified by T-596 — an error caught while writing this task, since
  T-596's own Human AC is still unticked and a task existing is not the operator agreeing
- P-011 7/7; legs 4, 5 and 6 poison-tested by hand and confirmed red for the stated reason

## Updates

### 2026-08-26T16:26:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-597-both-remaining-arc-0-exit-clauses-are-co.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5469d73e
- **Timestamp:** 2026-08-26T16:30:58Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Human)** — [REVIEW] Ratify the clause definitions, or correct them
  - **audience-mismatch** (partial, heuristic) — `agent-subject='agent\n     read' in: Three clauses, all `definition_ratified: false`, none `satisfied`, clauses   1 and 2 owned by `aef`, clause 3 `shared`.`

### 2026-08-26T16:30:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
